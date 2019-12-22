local skynet = require "skynet"
local codecache = require "skynet.codecache"
local log = require "tm.log"

skynet.start(function()
	codecache.clear()
	log.info("code cache clear done")
	skynet.exit()
end)
