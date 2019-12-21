local skynet = require "skynet"
local websocket = require "http.websocket"
local log = require "tm.log"
local xdump = require "tm.xtable".dump
local msgutil = require "msgutil"

local GATE_ADDR = "ws://127.0.0.1:10086"

local QUIT_TIME = 8*60*100
local TICK_INTERVAL = 3*100

local CMD = {}
local clientid = ...
local ws_id

local _account = string.format("test%03d", clientid)
local _password = "123456"
local _nickname = string.format("Tester%d", clientid)


local function send(name, msg)
	local data = msgutil.pack(name, msg)
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
			log.error("client:%d server close by reason:%s", clientid, close_reason)
			ws_id = nil
			break
		end

		local name, msg = msgutil.unpack(resp)
		if not name then
			log.error("unpack failed:%s", msg)
		else
			local f = CMD[name]
			if not f then
				log.warn("have no CMD for proto:%s", name)
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
	clientid = clientid or 0
	log.debug("this is echo client:%d connect to %s", clientid, GATE_ADDR)

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
