local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local thread = tonumber(skynet.getenv("thread"))

local agents = {}
local balance = 0


local function get()
	balance = (balance % #agents) + 1
	return agents[balance]
end

local function launch()
	for i = 1, thread do
		agents[i] = skynet.newservice("database/agent", i)
	end
end

local function init()
	launch()
	-- initialize mongodb index or something else
	skynet.call(get(), "lua", "initialize")
end


local CMD = setmetatable({}, {
	__index = function(_, cmd)
		return function(...)
			return skynet.call(get(), "lua", cmd, ...)
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
		return skynet.retpack(f(...))
	end)
	skynet.fork(init)
	skynet.register(".database/mgr")
end)
