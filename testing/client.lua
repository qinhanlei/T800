local skynet = require "skynet"
local websocket = require "http.websocket"
local log = require "tm.log"
local xdump = require "tm.xtable".dump
local msgutil = require "msgutil"

local GATE_ADDR = "ws://127.0.0.1:10086"

local QUIT_TIME = 8*60*100
local TICK_INTERVAL = 3*100

local CMD = {}
local ws_id

local userid
local _account
local _password
local _nickname


local function send(name, msg)
	local data = msgutil.pack("c2s."..name, msg)
	if data then
		websocket.write(ws_id, data, "binary")
	end
end


local function ticktock()
	while ws_id do
		log.info(" --- ping ---> ")
		websocket.ping(ws_id)
		skynet.sleep(TICK_INTERVAL)
	end
	log.info("ticktock ended!")
end


local function readloop()
	while ws_id do
		local ok, resp, close_reason = pcall(websocket.read, ws_id)
		if not ok then
			if ws_id ~= nil then
				log.error("websocket read failed!", resp)
				ws_id = nil
			end
			break
		end
		if not resp then
			log.error("client:%d server close by reason:%s", userid, close_reason)
			ws_id = nil
			break
		end

		local fullname, msg = msgutil.unpack(resp)
		if not fullname then
			log.error("unpack failed:%s", msg)
		else
			local _, name = fullname:match("(.+)%.(.+)")
			local f = CMD[name]
			if not f then
				log.warn("have no CMD for proto:%s", fullname)
			else
				f(msg)
			end
		end
		skynet.sleep(1)
	end
	log.info("readloop ended!")
end


local function auth()
	local msg = {
		account = _account,
		password = _password,
	}
	send("Auth", msg)
end


local function register()
	local msg = {
		account = _account,
		password = _password,
		nickname = _nickname,
	}
	send("Register", msg)
end


function CMD.onRegister(msg)
	log.debug("onRegister msg:%s", xdump(msg))
	auth()
end

function CMD.onAuth(msg)
	log.debug("onAuth msg:%s", xdump(msg))
end


local function main()
	userid = math.floor(skynet.time())
	log.debug("userid:%s %s", userid, type(userid))
	_account = string.format("test%d", userid)
	_password = "123456"
	_nickname = string.format("Tester%d", userid)

	log.debug("this is echo client:%d connect to %s", userid, GATE_ADDR)

	ws_id = websocket.connect(GATE_ADDR)

	skynet.fork(ticktock)
	skynet.fork(readloop)
	skynet.fork(register)

	skynet.timeout(QUIT_TIME, function()
		log.debug("quit timeout!")
		local id = ws_id
		ws_id = nil
		websocket.close(id, 0, "client-quit")
		log.debug("websocket sent close done!")
	end)
end


skynet.start(function()
	skynet.fork(main)
end)
