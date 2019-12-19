local code = {}


-- websocket state
code.WS_STATE = {
	shaked = 0,
	authed = 1,
}


-- T800.proto common `result` coding
code.RESULT = {
	ok = 0,
	err = 1,
}


return code
