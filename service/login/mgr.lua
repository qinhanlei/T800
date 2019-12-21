local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local thread = tonumber(skynet.getenv("thread"))

local agents


local function pickagent(id)
	return agents[(id % #agents) + 1]
end

local function launch()
	agents = {}
	for i = 1, thread do
		log.debug("launch login/agent [%d]", i)
		agents[i] = skynet.newservice("login/agent", i)
	end
end


local CMD = setmetatable({}, {
	__index = function(_, cmd)
		return function(gta, id, msg)
			local agent = pickagent(gta)
			return skynet.call(agent, "lua", cmd, gta, id, msg)
		end
	end
})

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("session:%s source:%x cmd:%s nil", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(source, ...))
	end)
	skynet.fork(launch)
	skynet.register(".login/mgr")
end)
