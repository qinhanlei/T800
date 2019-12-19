local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local xdump = require "tm.xtable".dump


local function callws(id, method, ...)
	local agent = skynet.call(".gated", "lua", "pickagent", id)
	log.debug("call ws agent addr:%x", agent)
	return skynet.call(agent, "lua", method, id, ...)
end


local CMD = {}

function CMD.Register(id, msg)
	log.info("ws:%d register msg:%s", id, xdump(msg))
	--TODO: ...
	log.debug("register succeed!")
	return 42
end

function CMD.Auth(id, msg)
	log.info("ws:%d auth msg:%s", id, xdump(msg))
	--TODO: ...
	log.debug("auth succeed!")
	callws(id, "authed")
	return 73
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("from[%s:%s] cmd:%s not found", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(...))
	end)
	skynet.register(".logind")
end)
