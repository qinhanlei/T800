local log = require "tm.log"
local xdump = require "tm.xtable".dump

local protobuf = require "protobuf"
local parser = require "parser"

local PACKAGE = "T800"

parser.register(PACKAGE..".proto", "./proto")

local msgutil = {}


local function encode(name)
	--TODO: ...
	return name
end

local function decode(name)
	--TODO: ...
	return name
end


function msgutil.pack(name, msg)
	local fullname = PACKAGE..'.'..name
	if not protobuf.check(fullname) then
		log.warn("proto name:%s not exist!", name)
		return
	end

	local ok, data = pcall(protobuf.encode, fullname, msg)
	if not ok then
		log.error("encode proto:%s failed:%s msg:%s", name, pb, xdump(msg))
		return
	end

	name = encode(name)
	return string.pack(">I2", #name) .. name .. data
end


function msgutil.unpack(data)
	if type(data) ~= "string" then
		return nil, "invalid data type: "..type(data)
	end

	if #data < 3 then
		return nil, "invalid data length"
	end

	local n = string.unpack(">I2", data)
	local name = data:sub(3, 2+n)

	local fullname = PACKAGE..'.'..name
	if not protobuf.check(fullname) then
		log.warn("proto name:%s not exist!", name)
		return nil, "invalid proto name"
	end

	data = data:sub(3+n)
	local ok, msg = pcall(protobuf.decode, fullname, data)
	if not ok then
		log.error("decode proto:%s failed:%s", name, msg)
		return
	end
	return decode(name), msg
end


return msgutil
