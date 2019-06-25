local Lplus = require "Lplus"

local CStringTable = Lplus.Class("CStringTable")
local def = CStringTable.define

def.static("number", "=>", "string").Get = function(id)
	local StringList = _G.GameTextTable.CommonString
	if StringList == nil or StringList[id] == nil then return "nil string" end

	return StringList[id]
end

def.static("number", "=>", "string", "string", "number").GetMsg = function(id)
	local msgList = _G.GameTextTable.MsgBoxString
	if msgList == nil or msgList[id] == nil then return "Empety Title", "Empty Msg", 0 end

	return msgList[id][1], msgList[id][2], msgList[id][3] or 0
end

def.static("number", "=>", "string").GetDebug = function(id)
	local StringDebugList = _G.DebugTextTable
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

--接受两个参数的AB
--[[
	20300
	MsgBox 78
]]
def.static("string", "dynamic", "dynamic", "=>", "string").Format_AB_BA = function (str, A, B)
	if _G.UserLanguageCode ~= "KR" then
		return string.format(str, A, B)
	else
		return string.format(str, B, A)
	end
end

--[[
	20301
	MsgBox 77
]]
def.static("string", "dynamic", "dynamic", "dynamic", "=>", "string").Format_ABC_ACB = function (str, A, B, C)
	if _G.UserLanguageCode ~= "KR" then
		return string.format(str, A, B, C)
	else
		return string.format(str, A, C, B)
	end
end

--[[
	MsgBox 4
]]
def.static("string", "dynamic", "dynamic", "dynamic", "=>", "string").Format_ABC_BCA = function (str, A, B, C)
	if _G.UserLanguageCode ~= "KR" then
		return string.format(str, A, B, C)
	else
		return string.format(str, B, C, A)
	end
end

--[[
	20302
	MsgBox 76
]]
def.static("string", "dynamic", "dynamic", "dynamic", "dynamic", "=>", "string").Format_ABCD_BADC = function (str, A, B, C, D)
	if _G.UserLanguageCode ~= "KR" then
		return string.format(str, A, B, C, D)
	else
		return string.format(str, B, A, D, C)
	end
end

CStringTable.Commit()
return CStringTable