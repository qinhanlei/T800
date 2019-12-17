local skynet = require "skynet"
local log = require "tm.log"

local CMD = {}
local usermap = {}

function CMD.new()
end

function CMD.del()
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if f then
			skynet.retpack(f(...))
		else
			log.error("from[%s:%s] cmd:%s not found", session, source, cmd)
		end
	end)
end)
