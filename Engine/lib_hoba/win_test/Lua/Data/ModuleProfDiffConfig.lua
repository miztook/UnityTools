local Lplus = require "Lplus"

local ModuleProfDiffConfig = Lplus.Class("ModuleProfDiffConfig")
local def = ModuleProfDiffConfig.define

local tableInfo = nil

def.static("=>", "table").Get = function()
	if tableInfo == nil then
		local ret, msg, result = pcall(dofile, _G.ConfigsDir.."ModuleProfDiffCfg.lua")
		if ret then
			tableInfo = result
		else
			warn(msg)
		end
	end
	
	return tableInfo
end

def.static("string", "=>", "table").GetModuleInfo = function( strType )
	if tableInfo == nil then
		ModuleProfDiffConfig.Get()
	end

	if tableInfo ~= nil and tableInfo[strType] ~= nil then
		return tableInfo[strType]
	end
	
	return nil
end

ModuleProfDiffConfig.Commit()
return ModuleProfDiffConfig