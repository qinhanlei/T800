local skynet = require "skynet"
-- local log = require "tm.log"

local clientnum = 1

skynet.start(function()
	for i = 1, clientnum do
		skynet.newservice("client", i)
	end
end)
