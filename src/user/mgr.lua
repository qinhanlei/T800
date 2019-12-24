local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local timer = require "tm.time".newtimer()

local OFFLINE_TIMEOUT = 5*60*100

local CMD = {}
local user_map = {}
local offlines = {}

local function offline_timeout(userid)
	log.debug("offline_timeout userid:%d", userid)
	if offlines[userid] then
		CMD.delete(userid, "offline timeout")
		offlines[userid] = nil
	end
end

function CMD.new(info)
	if not info then
		log.error("new user info error")
		return
	end
	local userid = info.userid
	if not userid then
		log.error("have no userid!")
		return
	end
	log.debug("new userid:%d", userid, 1)
	local user = user_map[userid]
	if user then
		log.warn("user:%d already exsit!", userid)
		skynet.send(user, "lua", "stop")
	end
	user = skynet.newservice("user/user")
	skynet.call(user, "lua", "start", info)
	user_map[userid] = user
	if offlines[userid] then
		offlines[userid] = false
	end
	return user
end

function CMD.delete(userid, reason)
	log.debug("delete userid:%d reason:%s", userid, reason)
	local user = user_map[userid]
	if user then
		skynet.send(user, "lua", "stop", reason)
		user_map[userid] = nil
	end
end

function CMD.disconnect(userid)
	log.debug("disconnect userid:%d", userid)
	local user = user_map[userid]
	if user then
		skynet.send(user, "lua", "disconnect")
		offlines[userid] = true
		timer.timeout(OFFLINE_TIMEOUT, offline_timeout, userid)
	end
end

function CMD.call(userid, ...)
	local user = user_map[userid]
	if not user then
		log.error("have no user:%d", userid)
		return nil, "user not exist"
	end
	return skynet.call(user, "lua", ...)
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
	skynet.register(".user/mgr")
end)
