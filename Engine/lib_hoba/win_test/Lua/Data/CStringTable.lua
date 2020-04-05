local Lplus = require "Lplus"

local CStringTable = Lplus.Class("CStringTable")
local def = CStringTable.define

local StringList = nil
local StringDebugList = nil

def.static("number", "=>", "string").Get = function(id)
	if StringList == nil then
		local ret, msg, result = pcall(dofile, _G.ConfigsDir.."game_text.lua")
		if ret then
			StringList = result
		else
			warn(msg)
		end
	end
	if StringList == nil or StringList[id] == nil then return "nil string" end

	return StringList[id]
end

def.static("number", "=>", "string").GetDebug = function(id)
	if StringDebugList == nil then
		local ret, msg, result = pcall(dofile, _G.ConfigsDir.."debug_text.lua")
		if ret then
			StringDebugList = result
		else
			warn(msg)
		end
	end
	if StringDebugList == nil then return "nil string" end

	return StringDebugList[id]
end

def.static("number", "=>", "string").GetGoldString = function(num)
	return CStringTable.Get(400).."x"..tostring(num)
end

def.static("number", "=>", "string").GetDiamondString = function(num)
	return CStringTable.Get(401).."x"..tostring(num)
end

def.static("number", "=>", "string").GetBindDiamondString = function(num)
	return CStringTable.Get(402).."x"..tostring(num)
end

def.static("number", "number", "number", "=>", "string").GetAllMoneyString = function(num_gold, num_diamond, num_bind_diamond)
	local result = ""
	if num_gold > 0 then
		result = CStringTable.GetGoldString(num_gold)
	end
	if num_diamond > 0 then
		result = result..CStringTable.GetDiamondString(num_diamond)
	end
	if num_bind_diamond > 0 then
		result = result..CStringTable.GetBindDiamondString(num_bind_diamond)
	end
	return result
end

CStringTable.Commit()
return CStringTable