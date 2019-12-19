local skynet = require "skynet"
local log = require "tm.log"
local xtable = require "tm.xtable"
local xdump = xtable.dump

local _u = nil

local CMD = {}

function CMD.start(u)
	log.debug("start user: %s", xdump(u))
	_u = u
end

function CMD.stop()
	log.debug("stop uid:%d", _u.uid)
	skynet.exit()
end

function CMD.disconnect()
	--TODO: ...
	-- waitting for reconnect
end

function CMD.reconnect()
	--TODO: ...
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
