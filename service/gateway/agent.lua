local skynet = require "skynet"
local websocket = require "http.websocket"
local log = require "tm.log"
local xdump = require "tm.xtable".dump

local CONN_TIMEOUT = 10*100


local ws_map = {}  -- ws_id -> ws_info:table

local function timeout(id)
	log.debug("ws:%d timeout!", id)
	websocket.close(id, 0, "timeout")
end

local function ticktock()
	local now, count
	while true do
		count = 0
		now = skynet.now()
		for k, v in pairs(ws_map) do
			if now - v.lasttime > CONN_TIMEOUT then
				skynet.fork(timeout, k)
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
	log.info("ws:%s connect", id)
end

function handle.handshake(id, header, url)
	local addr = websocket.addrinfo(id)
	log.debug("ws:%s handshake from url:%s addr:%s", id, url, addr)
	log.debug("header: %s", xdump(header))
	ws_map[id] = {
		status = 0,
		lasttime = skynet.now()
	}
end

function handle.message(id, msg)
	log.debug("ws:%s message:%s", id, msg)
	websocket.write(id, msg)
	ws_map[id].lasttime = skynet.now()
end

function handle.ping(id)
	log.debug("ws:%s ping", id)
	ws_map[id].lasttime = skynet.now()
end

function handle.pong(id)
	log.debug("ws:%s pong", id)
	ws_map[id].lasttime = skynet.now()
end

function handle.close(id, code, reason)
	log.info("ws:%s close code:%s reason:%s", id, code, reason)
	ws_map[id] = nil
end

function handle.error(id)
	log.error("ws:%s error", id)
	ws_map[id] = nil
end


local CMD = {}

function CMD.start(id, addr, protocol)
	log.info("start fd:%d addr:%s protocol:%s", id, addr, protocol)
	local ok, err = websocket.accept(id, handle, protocol, addr)
	if not ok then
		log.error("accept failed:%s", err)
	end
end


skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)
	skynet.fork(ticktock)
end)
