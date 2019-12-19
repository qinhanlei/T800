local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local xdump = require "tm.xtable".dump

local CMD = {}

function CMD.Register(source, id, msg)
	log.info("ws:%d register msg:%s", id, xdump(msg))
	--TODO: ...
	log.debug("register succeed!")
	return 0
end

function CMD.Auth(source, id, msg)
	log.info("ws:%d auth msg:%s", id, xdump(msg))

	--TODO: ...
	log.debug("auth succeed!")
	local userid = id + 100000

	local uagent = skynet.call(".usermgr", "lua", "new", {
		uid = userid,
		wsagent = source,
		nickname = "nickname"..id,
	})
	skynet.send(source, "lua", "authed", id, userid, uagent)
	return 0
end


skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, ...)
		local f = CMD[cmd]
		if not f then
			log.error("from[%s:%s] cmd:%s not found", session, source, cmd)
			return skynet.retpack()
		end
		return skynet.retpack(f(source, ...))
	end)
	skynet.register(".logind")
end)
