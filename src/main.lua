local skynet = require "skynet"
local log = require "tm.log"

skynet.start(function()
	log.info("Hi, this is Terminator 1G: T800")

	skynet.uniqueservice("database/mgr")
	skynet.uniqueservice("user/mgr")
	skynet.uniqueservice("dungeon/mgr")
	skynet.uniqueservice("login/mgr")
	skynet.uniqueservice("gateway/mgr")

	skynet.newservice("console")
	skynet.newservice("debug_console", 9601)
	skynet.exit()
end)
