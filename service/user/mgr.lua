local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local timer = require "tm.time".newtimer()

local OFFLINE_TIMEOUT = 5*60*100

local CMD = {}
local uid2agent = {}
local offlines = {}

local function offline_timeout(uid)
	log.debug("offline_timeout uid:%d", uid)
	if offlines[uid] then
		CMD.delete(uid, "offline timeout")
		offlines[uid] = nil
	end
end

function CMD.new(u)
	log.debug("new uid:%d", u.uid)
	local uagent = uid2agent[u.uid]
	if uagent then
		log.warn("user:%d already exsit!", u.uid)
		skynet.send(agent, "lua", "stop")
	end
	uagent = skynet.newservice("user/agent")
	skynet.call(uagent, "lua", "start", u)
	uid2agent[u.uid] = uagent
	if offlines[u.uid] then
		offlines[u.uid] = false
	end
	return uagent
end

function CMD.delete(uid, reason)
	log.debug("delete uid:%d reason:%s", uid, reason)
	local agent = uid2agent[uid]
	if agent then
		skynet.send(agent, "lua", "stop", reason)
		uid2agent[uid] = nil
	end
end

function CMD.disconnect(uid)
	log.debug("disconnect uid:%d", uid)
	local agent = uid2agent[uid]
	if agent then
		skynet.send(agent, "lua", "disconnect")
		offlines[uid] = true
		timer.timeout(OFFLINE_TIMEOUT, offline_timeout, uid)
	end
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
