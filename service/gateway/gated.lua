-- websocket gate
local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local log = require "tm.log"
local thread = tonumber(skynet.getenv("thread"))

local CMD = {}
local agents

local function pickagent(id)
	log.debug("pick %d ws agent for wsid:%d", (id % #agents) + 1, id)
	return agents[(id % #agents) + 1]
end


function CMD.start(ip, port, protocol)
	if agents then
		log.error("already started!")
		return
	end
	agents = {}
	for i = 1, thread do
		log.debug("launch gateway/agent [%d]", i)
		agents[i] = skynet.newservice("gateway/agent", i)
	end
	log.debug("listen on %s:%s", ip, port)
	local listenid = socket.listen(ip, port)
	socket.start(listenid, function(id, addr)
		log.debug("on connect id:%s addr:%s", id, addr)
		skynet.send(pickagent(id), "lua", "start", id, addr, protocol)
	end)
end


function CMD.pickagent(wsid)
	return pickagent(wsid)
end


skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)
	skynet.register(".gated")
end)
