local Lplus = require "Lplus"

local PropertyInfoConfig = Lplus.Class("PropertyInfoConfig")
local def = PropertyInfoConfig.define

local tableInfo = nil

def.static("=>", "table").Get = function()
	if tableInfo == nil then
		local ret, msg, result = pcall(dofile, "Configs/PropertyInfoCfg.lua")
		if ret then
			tableInfo = result
		else
			warn(msg)
		end
	end
	
	return tableInfo
end

def.static("number", "=>", "boolean").IsRatio = function( propertyId )
	local bRet = false

	if tableInfo == nil then
		PropertyInfoConfig.Get()
	end

	for i=1, #tableInfo.RatioIds do
		if tableInfo.RatioIds[i] == propertyId then
			bRet = true
			break
		end
	end
	
	return bRet
end

PropertyInfoConfig.Commit()
return PropertyInfoConfig