local crypt = require "skynet.crypt"

local protobuf = require "protobuf"
local parser = require "parser"
parser.register({"c2s.proto", "s2c.proto"}, "./proto")

local msgutil = {}


local function encrypt(data, key)
	return pcall(crypt.desencode, key, data)
end

local function decrypt(data, key)
	return pcall(crypt.desdecode, key, data)
end


function msgutil.pack(name, msg, key)
	if not protobuf.check(name) then
		return nil, "invalid proto name"
	end

	local ok, data = pcall(protobuf.encode, name, msg)
	if not ok then
		return nil, data
	end

	ok, data = encrypt(string.pack(">I2", #name) .. name .. data, key)
	if not ok then
		return nil, data
	end

	return data
end


function msgutil.unpack(data, key)
	if type(data) ~= "string" then
		return nil, "invalid data type: "..type(data)
	end

	if #data < 3 then
		return nil, "invalid data length"
	end

	local ok, msg

	ok, data = decrypt(data, key)
	if not ok then
		return nil, data
	end

	local n = string.unpack(">I2", data)
	local name = data:sub(3, 2+n)
	if not protobuf.check(name) then
		return nil, "invalid proto name"
	end

	data = data:sub(3+n)
	ok, msg = pcall(protobuf.decode, name, data)
	if not ok then
		return nil, msg
	end

	return name, msg
end


return msgutil
