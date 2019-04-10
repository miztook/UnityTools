-- 头饰配置数据相关功能

local Lplus = require "Lplus"
local HeadwearUtil = Lplus.Class("HeadwearUtil")
local def = HeadwearUtil.define

local config = nil
def.static("string", "number", "=>", "dynamic").Get = function(name, profId)
	if config == nil then
		local ret, msg, result = pcall(dofile, "Configs/HeadwearCfg.lua")
		if ret then
			config = result
		else
			warn(msg)
		end
	end
	if config == nil then return nil end

	if config[name] ~= nil and config[name][profId] ~= nil then
		return config[name][profId]
	end

	return nil
end

HeadwearUtil.Commit()
return HeadwearUtil