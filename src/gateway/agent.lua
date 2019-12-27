-- websocket agent
local skynet = require "skynet"
require "skynet.manager"
local crypt = require "skynet.crypt"
local websocket = require "http.websocket"
local log = require "tm.log"
local xdump = require "tm.xtable".dump
local msgutil = require "msgutil"
local mycode = require "mycode"

local CONN_TIMEOUT = 10*100
local LOGIN_TIMEOUT = 8*60*100
local STATE = mycode.WS_STATE
local DEFAULT_DES_KEY = "abcd1234"

--NOTE: handler API list by websocket.lua, see simplewebsocket.lua
local handle = {}
local ws_map = {}  -- ws_id -> ws_info:table
local serverkey = nil


local function timeout(id, reason)
	log.debug("ws:%d %s!", id, reason)
	websocket.close(id, 0, reason)
end

local function ticktock()
	local now, count
	while true do
		count = 0
		now = skynet.now()
		for k, v in pairs(ws_map) do
			if now - v.lasttime > CONN_TIMEOUT then
				skynet.fork(timeout, k, "ping_timeout")
			end
			if v.state ~= STATE.logined and now - v.shakedtime > LOGIN_TIMEOUT then
				skynet.fork(timeout, k, "login_timeout")
			end
			count = count + 1
			if count > 100 then
				skynet.yield()
			end
		end
		-- log.debug("check ws connections total:%s done", count)
		skynet.sleep(100)
	end
end

local function send(id, name, msg, key)
	key = key or DEFAULT_DES_KEY
	log.debug("send %s msg: %s", name, xdump(msg))
	local data, err = msgutil.pack("s2c."..name, msg, key)
	if not data then
		log.error("pack name:%s failed:`%s` msg:%s", name, err, xdump(msg))
		return
	end
	local ok, ret = pcall(websocket.write, id, data, "binary")
	if not ok then
		log.error("ws:%d write failed:%s", id, ret)
	end
end

local function accept(id, addr, protocol)
	log.info("start fd:%d addr:%s protocol:%s", id, addr, protocol)
	local ok, err = websocket.accept(id, handle, protocol, addr)
	if not ok then
		log.error("websocket error:%s", err)
		handle.error(id)
	end
end

local function dispatch(w, name, msg, key)
	local ret
	local id = w.id

	if w.state ~= STATE.logined then
		ret = skynet.call(".login/mgr", "lua", name, id, msg, serverkey)
	else
		ret = skynet.call(w.uagent, "lua", name, id, msg)
	end

	if type(ret) == "table" then
		send(id, "on"..name, ret, key)
	elseif ret then
		send(id, "on"..name, { result = ret }, key)
	end
end


function handle.connect(id)
	log.info("ws:%s on connect", id)
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	local now = skynet.now()
	log.debug("ws:%s on handshake from url:%s addr:%s", id, url, addr)
	log.debug("header: %s", xdump(header))
	ws_map[id] = {
		id = id,
		userid = nil,
		state = STATE.shaked,
		lasttime = now,
		shakedtime = now,
		secret = nil,
	}
end

function handle.message(id, data)
	log.debug("ws:%s on message", id)
	local w = ws_map[id]
	w.lasttime = skynet.now()

	local key = w.secret or DEFAULT_DES_KEY
	local fullname, msg = msgutil.unpack(data, key)
	if not fullname then
		log.error("unpack data failed: %s", msg)
		if w.state ~= STATE.logined then
			websocket.close(id, 404, "network error, try later.")
		end
		return
	end

	local _, name = fullname:match("(.+)%.(.+)")
	local ok, ret = pcall(dispatch, w, name, msg, key)
	if not ok then
		log.error("dispatch %s failed:%s", fullname, ret)
	end
end

function handle.ping(id)
	log.debug("ws:%s on ping", id)
	ws_map[id].lasttime = skynet.now()
end

function handle.pong(id)
	log.debug("ws:%s on pong", id)
	ws_map[id].lasttime = skynet.now()
end

function handle.close(id, code, reason)
	log.info("ws:%s on close code:%s reason:%s", id, code, reason)
	local w = ws_map[id]
	ws_map[id] = nil
	if w.state == STATE.logined then
		skynet.send(".user/mgr", "lua", "delete", w.userid, "socket close manually")
	end
end

function handle.error(id)
	log.error("ws:%s on error", id)
	local w = ws_map[id]
	ws_map[id] = nil
	if w.state == STATE.logined then
		skynet.send(".user/mgr", "lua", "disconnect", w.userid)
	end
end


local CMD = {}

function CMD.start(...)
	skynet.fork(accept, ...)
end

function CMD.login(id, userid, uagent)
	local w = ws_map[id]
	if w then
		w.userid = userid
		w.uagent = uagent
		w.state = STATE.logined
		log.debug("ws:%d logined! %s", id, xdump(ws_map[id]))
	end
end

function CMD.secret(id, secret)
	local w = ws_map[id]
	if w then
		w.secret = secret
	end
end

function CMD.sendmsg(id, name, msg)
	send(id, name, msg)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("session:%s source:%x cmd:%s nil", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(...))
	end)
	skynet.fork(ticktock)
	serverkey = crypt.randomkey()
	log.info("serverkey : %s", serverkey)
end)
