local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local xdump = require "tm.xtable".dump

local CMD = {}

function CMD.Register(gta, id, msg)
	log.info("ws:%d register msg:%s", id, xdump(msg))
	local ret, err
	--TODO: check account password nickname
	ret = skynet.call(".database/mgr", "lua", "user_query", {account = msg.account})
	if ret then
		log.warn("user account:%s already exist", msg.account)
		return "account already exist"
	end
	ret, err = skynet.call(".database/mgr", "lua", "user_create", msg)
	if not ret then
		log.error("user create failed: %s", err)
		return "register failed!"
	end
	log.debug("register succeed!")
	return "ok"
end

function CMD.Auth(gta, id, msg)
	log.info("ws:%d auth msg:%s", id, xdump(msg))
	local ret = skynet.call(".database/mgr", "lua", "user_query", {
		account = msg.account,
		-- password = msg.password,
	})
	if not ret then
		return "account not exist or invalid password"
	end
	local uagent = skynet.call(".user/mgr", "lua", "new", {
		userid = ret.userid,
		gtagent = gta,
		nickname = ret.nickname,
	})
	log.debug("auth succeed!")
	skynet.send(gta, "lua", "authed", id, ret.userid, uagent)
	return "ok"
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
