-- this is all in one node, could be cluster

tmpath = "$TMPATH"
skypath = tmpath.."/skynet"

nodename = "$NODE_NAME"
thread = "$SKYNET_THREAD"
harbor = 0

start = "main"
bootstrap = "snlua bootstrap"
preload = "./lualib/preload.lua"

logpath = "./logs"
logger = "tm/logger"
logservice = "snlua"
lualoader = skypath.."/lualib/loader.lua"

cpath = skypath.."/cservice/?.so;"..
		tmpath.."/cservice/?.so;"
lua_cpath = skypath.."/luaclib/?.so;"..
			tmpath.."/luaclib/?.so;"

luaservice = skypath.."/service/?.lua;"..
			tmpath.."/service/?.lua;"..
			"./service/?.lua;"..
			"./testing/?.lua;"
lua_path = skypath.."/lualib/?.lua;"..
			tmpath.."/lualib/?.lua;"..
			"./lualib/?.lua;"..
			"./testing/?.lua;"
