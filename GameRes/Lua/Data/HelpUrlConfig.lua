local Lplus = require "Lplus"

local HelpUrlConfig = Lplus.Class("HelpUrlConfig")
local def = HelpUrlConfig.define

local tableInfo = nil

def.static("=>", "table").Get = function()
	if tableInfo == nil then
		local ret, msg, result = pcall(dofile, "Configs/HelpUrlConfig.lua")
		if ret then
			tableInfo = result
		else
			warn(msg)
		end
	end
	return tableInfo
end

HelpUrlConfig.Commit()
return HelpUrlConfig