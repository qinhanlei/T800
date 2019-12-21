local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"

local CMD = {}
local uid2agent = {}

function CMD.new(u)
	if uid2agent[u.uid] then
		log.warn("user:%d already exsit!", u.uid)
		-- kick out ?
		return
	end
	local uagent = skynet.newservice("user/agent")
	skynet.call(uagent, "lua", "start", u)
	uid2agent[u.uid] = uagent
	return uagent
end

function CMD.delete(uid)
	local agent = uid2agent[uid]
	skynet.send(agent, "lua", "stop")
	uid2agent[uid] = nil
end

function CMD.disconnect(uid)
	--TODO: notify
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
