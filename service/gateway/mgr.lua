local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local log = require "tm.log"
local thread = tonumber(skynet.getenv("thread"))

local agents

local ip = "127.0.0.1"
local port = 10086


local function get(id)
	return agents[(id % #agents) + 1]
end


local function launch()
	agents = {}
	for i = 1, thread do
		log.debug("launch gateway/agent [%d]", i)
		agents[i] = skynet.newservice("gateway/agent", i)
	end
	log.debug("listen on %s:%s", ip, port)
	local listenid = socket.listen(ip, port)
	socket.start(listenid, function(id, addr)
		log.debug("on connect id:%s addr:%s", id, addr)
		skynet.send(get(id), "lua", "start", id, addr)
	end)
end


local CMD = {}

function CMD.agent(wsid)
	return get(wsid)
end


skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("session:%s source:%x cmd:%s nil", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(...))
	end)
	skynet.fork(launch)
end)
