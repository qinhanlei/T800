-- websocket agent
local skynet = require "skynet"
local websocket = require "http.websocket"
local log = require "tm.log"
local xdump = require "tm.xtable".dump
local msgutil = require "msgutil"

local CONN_TIMEOUT = 10*100
local AUTH_TIMEOUT = 5*100--5*60*100

local STATE = {
	shaked = 0,
	authed = 1,
}

local ws_map = {}  -- ws_id -> ws_info:table


local function send(id, name, msg)
	local data = msgutil.pack(name, msg)
	if data then
		websocket.write(id, data, "binary")
	end
end


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
				skynet.fork(timeout, k, "activity_timeout")
			end
			if v.state == STATE.shaked and now - v.shakedtime > AUTH_TIMEOUT then
				skynet.fork(timeout, k, "auth_timeout")
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


--NOTE: handler API list by websocket.lua, see simplewebsocket.lua
local handle = {}

function handle.connect(id)
	log.info("ws:%s on connect", id)
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	local now = skynet.now()
	log.debug("ws:%s on handshake from url:%s addr:%s", id, url, addr)
	log.debug("header: %s", xdump(header))
	ws_map[id] = {
		state = STATE.shaked,
		lasttime = now,
		shakedtime = now,
	}
end

function handle.message(id, data)
	log.debug("ws:%s on message", id)
	ws_map[id].lasttime = skynet.now()
	local name, msg = msgutil.unpack(data)
	if name then
		log.debug("recv %s: %s", name, xdump(msg))
		send(id, "on"..name, { result = 42 })
	end
	-- websocket.write(id, msg)
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
	ws_map[id] = nil
end

function handle.error(id)
	log.error("ws:%s on error", id)
	ws_map[id] = nil
end


local function accept(id, addr, protocol)
	log.info("start fd:%d addr:%s protocol:%s", id, addr, protocol)
	local ok, err = websocket.accept(id, handle, protocol, addr)
	if not ok then
		log.error("websocket error:%s", err)
		handle.error(id)
	end
end


local CMD = {}

function CMD.start(...)
	skynet.fork(accept, ...)
end

skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)
	skynet.fork(ticktock)
end)
