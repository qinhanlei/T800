local skynet = require "skynet"
require "skynet.manager"
local crypt = require "skynet.crypt"
local log = require "tm.log"
local xdump = require "tm.xtable".dump

local CMD = {}

function CMD.DHkey(gta, id, msg, serverkey)
	log.info("ws:%d DHkey msg:%s", id, xdump(msg))
	local clientkey = crypt.base64decode(msg.clientkey)
	if #clientkey ~= 8 then
		return "Invalid client key"
	end
	log.debug("got public clientkey:%s", crypt.hexencode(clientkey))
	local secret = crypt.dhsecret(clientkey, serverkey)
	log.debug("got dhsecret:%s", crypt.hexencode(secret))
	skynet.send(gta, "lua", "secret", id, secret)
	return {
		result = "ok",
		serverkey = crypt.base64encode(crypt.dhexchange(serverkey))
	}
end

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

function CMD.Login(gta, id, msg)
	log.info("ws:%d login msg:%s", id, xdump(msg))
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
	log.debug("login succeed!")
	skynet.send(gta, "lua", "login", id, ret.userid, uagent)
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
