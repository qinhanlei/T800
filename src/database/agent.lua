local skynet = require "skynet"
require "skynet.manager"
local log = require "tm.log"
local xdump = require "tm.xtable".dump
local xmongo = require "tm.db.xmongo"
local xredis = require "tm.db.xredis"
local conf = require "database.conf"


local function getdatabase(dbname)
	return xmongo.use(dbname or "T800")
end

local function getcollection(col)
	return getdatabase()[col]
end


local CMD = {}

function CMD.initialize()
	local misc = getcollection("misc")
	misc:dropIndex("*"); misc:drop()
	local misc_user = {
		collection = "user",
		nextuid = 100000,
		initgold = 99999,
	}
	misc:createIndex({ collection = 1}, {unique = true})
	misc:insert(misc_user)

	local user = getcollection("user")
	user:dropIndex("*"); user:drop()
	user:createIndex({userid = 1}, {unique = true})
	user:createIndex({account = 1}, {unique = true})
end

function CMD.user_query(cond)
	assert(type(cond) == "table" and (cond.account or cond.userid))
	local coll = getcollection("user")
	local cursor = coll:find(cond)
	local result = nil
	while cursor:hasNext() do
		result = result or {}
		table.insert(result, cursor:next())
	end
	if result and #result == 1 then
		result = result[1]
	end
	return result
end

function CMD.user_create(info)
	local ok, err, ret
	local coll = getcollection("user")
	local misc = getcollection("misc")
	ret = misc:findAndModify{query={collection="user"}, update={["$inc"]={nextuid=1}}}
	info.userid = ret.value.nextuid
	info.gold = ret.value.initgold
	if not info.userid then
		log.error("have no valid userid")
		return
	end
	ok, err, ret = coll:safe_insert(info)
	if not ok then
		return nil, err
	end
	return ret
end

function CMD.user_update(userid, info)
	local coll = getcollection("user")
	local ok, err, ret = coll:safe_update({userid = userid}, {['$set'] = info})
	if not ok then
		return nil, err
	end
	return ret
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
	xmongo.init(conf.mongo)
	xredis.init(conf.redis)
end)
