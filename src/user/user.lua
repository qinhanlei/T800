local skynet = require "skynet"
local log = require "tm.log"
local xtable = require "tm.xtable"
local xdump = xtable.dump

local _u = nil  -- userinfo

local function ticktock()
	while true do
		log.debug("user:%d ticktock ...", _u.userid)
		skynet.sleep(300)
	end
end

local CMD = {}

function CMD.start(info)
	log.debug("start user: %s", xdump(info))
	_u = info
	skynet.fork(ticktock)
end

function CMD.stop(reason)
	log.debug("user:%d stop by reason:%s", _u.userid, reason)
	skynet.exit()
end

function CMD.disconnect()
	log.debug("user:%d disconnect, waitting for reconnect", _u.userid)
	--TODO: ...
end

function CMD.reconnect()
	--TODO: ...
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("session:%s source:%x cmd:%s nil", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(...))
	end)
end)
