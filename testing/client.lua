local skynet = require "skynet"
local websocket = require "http.websocket"
local log = require "tm.log"

local parser = require "parser"
parser.register("T800.proto", "./proto")

local GATE_ADDR = "ws://127.0.0.1:10086"

local QUICK_TIME = 50*100
local TICK_INTERVAL = 2*100

local clientid = ...
local ws_id
local counter = 0


local function ticktock()
	while ws_id do
		counter = counter + 1
		local msg = "hello world! " .. counter
		websocket.write(ws_id, msg)
		log.debug("client%d --->> %s", clientid, msg)
		websocket.ping(ws_id)
		skynet.sleep(TICK_INTERVAL)
	end
	log.info("ticktock ended!")
end


local function readloop()
	while ws_id do
		local ok, resp, close_reason = pcall(websocket.read, ws_id)
		if not ok then
			log.error("call websocket read failed!", resp)
			ws_id = nil
			break
		end
		log.debug("client%d <<--- %s", clientid, (resp and resp or "[Close] " .. close_reason))
		if not resp then
			log.error("client%d echo server close", clientid)
			return
		end
		skynet.sleep(1)
	end
	log.info("readloop ended!")
end


local function main()
	clientid = clientid or 0
	log.debug("this is echo client:%d connect to %s", clientid, GATE_ADDR)
	ws_id = websocket.connect(GATE_ADDR)
	skynet.fork(readloop)
	skynet.fork(ticktock)
	skynet.timeout(QUICK_TIME, function()
		websocket.close(ws_id, 0, "client-quit")
	end)
end


skynet.start(function()
	skynet.fork(main)
end)
