local skynet = require "skynet"
local socket = require "skynet.socket"
local log = require "tm.log"

local thread = tonumber(skynet.getenv("thread"))
local CMD = {}


function CMD.start(ip, port, protocol)
	local agent = {}
	local balance = 1
	for i = 1, thread do
		log.debug("launch gateway/agent [%d]", i)
		agent[i] = skynet.newservice("gateway/agent")
	end
	log.debug("listen on %s:%s", ip, port)
	local listenid = socket.listen(ip, port)
	socket.start(listenid, function(id, addr)
		log.debug("on connect id:%s addr:%s", id, addr)
		skynet.send(agent[balance], "lua", "start", id, addr, protocol)
		balance = (balance % #agent) + 1
	end)
end


skynet.start(function()
	skynet.dispatch("lua", function(_, _, cmd, ...)
		local f = assert(CMD[cmd], cmd .. " not found")
		skynet.retpack(f(...))
	end)
end)
