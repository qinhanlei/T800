local skynet = require "skynet"
local websocket = require "http.websocket"
local log = require "tm.log"

local parser = require "parser"
parser.register("T800.proto", "./proto")

local GATE_ADDR = "ws://127.0.0.1:10086"


local clientid = ...

local function start()
	clientid = clientid or 0
	log.debug("this is echo client:%d connect to %s", clientid, GATE_ADDR)
	local ws_id = websocket.connect(GATE_ADDR)
	local count = 1
	while true do
		local msg = "hello world! " .. count
		count = count + 1
		websocket.write(ws_id, msg)
		log.debug("client%d >>> %s", clientid, msg)
		local resp, close_reason = websocket.read(ws_id)
		log.debug("client%d <<< %s", clientid, (resp and resp or "[Close] " .. close_reason))
		if not resp then
			log.debug("client%d echo server close", clientid)
			break
		end
		websocket.ping(ws_id)
		skynet.sleep(100)
	end
end

skynet.start(function()
	skynet.fork(start)
end)
