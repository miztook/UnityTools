local Lplus = require "Lplus"

local BreakPointConfig = Lplus.Class("BreakPointConfig")
local def = BreakPointConfig.define

local config = nil

def.static("string", "=>", "dynamic").Get = function(key)
	if config == nil then
		local ret, msg, result = pcall(dofile, "Configs/BreakPointCfg.lua")
		if ret then
			config = result
		else
			warn(msg)
		end
	end
	if config == nil then return nil end

	return config[key]
end

BreakPointConfig.Commit()
return BreakPointConfig