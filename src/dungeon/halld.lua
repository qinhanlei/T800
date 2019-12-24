-- main system after user login
local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"

local CMD = {}

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("session:%s source:%x cmd:%s nil", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(...))
	end)
	skynet.register(".logic/mgr")
end)
