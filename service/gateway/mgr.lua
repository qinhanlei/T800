local skynet = require "skynet"
require "skynet.manager"
local socket = require "skynet.socket"
local log = require "tm.log"
local thread = tonumber(skynet.getenv("thread"))

local agents

local ip = "127.0.0.1"
local port = 10086


local function pickagent(id)
	log.debug("pick %d ws agent for wsid:%d", (id % #agents) + 1, id)
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
		skynet.send(pickagent(id), "lua", "start", id, addr)
	end)
end


local CMD = {}

function CMD.pickagent(wsid)
	return pickagent(wsid)
end


skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)
	skynet.fork(launch)
end)
