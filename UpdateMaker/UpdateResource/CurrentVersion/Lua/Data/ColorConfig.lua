local Lplus = require "Lplus"

local ColorConfig = Lplus.Class("ColorConfig")
local def = ColorConfig.define

local tableInfo = nil

def.static("=>", "table").Get = function()
	if tableInfo == nil then
		local ret, msg, result = pcall(dofile, "Configs/ColorCfg.lua")
		if ret then
			tableInfo = result
		else
			warn(msg)
		end
	end
	
	return tableInfo
end

def.static("number", "=>", "table").GetColorInfo = function( colorId )
	if tableInfo == nil then
		ColorConfig.Get()
	end

	if tableInfo ~= nil and tableInfo[colorId] ~= nil then
		return tableInfo[colorId]
	end
	
	return nil
end

ColorConfig.Commit()
return ColorConfig