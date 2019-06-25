-- 名字检查器

local Lplus = require "Lplus"
local FilterMgr = require "Utility.BadWordsFilter".Filter

local NameChecker = Lplus.Class("NameChecker")
local def = NameChecker.define

-- 去掉首尾所有空格
local function trim(name)
	return string.gsub(name, "^%s*(.-)%s*$", "%1")
end

local function isAllNumber(name)
	return string.match(name, "^[0-9]+$") ~= nil
end

local function hasIllegalWord(name)
	local strMsg = FilterMgr.FilterName(name)
	if strMsg ~= name then
		return true
	end
	if _G.UserLanguageCode ~= "KR" then
		if not GameUtil.CheckName_IsValidWord(name) then
			return true
		end
	else
		if not GameUtil.CheckName_IsValidWord_KR(name) then
			return true
		end
	end
	return false
end

def.static("string", "=>", "number").GetNameLength = function(name)
	-- 不管中文、韩文、英文，一个字占一位
	return GameUtil.GetUnicodeStrLength(name)
end

def.static("string", "=>", "boolean").CheckRoleNameValidWhenCreate = function (name)
	local title = StringTable.Get(8)
	if IsNilOrEmptyString(name) then
		local message = StringTable.Get(34404)
		MsgBox.ShowMsgBox(message, title, nil, MsgBoxType.MBBT_OK)
		return false
	end
	local len = NameChecker.GetNameLength(name)
	local min = GlobalDefinition.MinRoleNameLength
	local max = GlobalDefinition.MaxRoleNameLength
	if len < min then
		local message = string.format(StringTable.Get(34401), min)
		MsgBox.ShowMsgBox(message, title, nil, MsgBoxType.MBBT_OK)
		return false
	end
	if len > max then
		local message = string.format(StringTable.Get(34400), max)
		MsgBox.ShowMsgBox(message, title, nil, MsgBoxType.MBBT_OK)
		return false
	end
	if isAllNumber(name) then
		local message = StringTable.Get(34402)
		MsgBox.ShowMsgBox(message, title, nil, MsgBoxType.MBBT_OK)
		return false
	end
	if hasIllegalWord(name) then
		local message = StringTable.Get(34403)
		MsgBox.ShowMsgBox(message, title, nil, MsgBoxType.MBBT_OK)
		return false
	end
	return true
end

def.static("string", "=>", "boolean").CheckRoleNameValid = function (name)
	local title = StringTable.Get(8)
	if IsNilOrEmptyString(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34404), false)
		return false
	end
	local len = NameChecker.GetNameLength(name)
	local min = GlobalDefinition.MinRoleNameLength
	local max = GlobalDefinition.MaxRoleNameLength
	if len < min then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34401), min), false)
		return false
	end
	if len > max then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34400), max), false)
		return false
	end
	if isAllNumber(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34402), false)
		return false
	end
	if hasIllegalWord(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34403), false)
		return false
	end
	return true
end

def.static("string", "=>", "boolean").CheckGuildNameValid = function (name)
	if IsNilOrEmptyString(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34414), false)
		return false
	end
	local len = NameChecker.GetNameLength(name)
	local min = GlobalDefinition.MinGuildNameLength
	local max = GlobalDefinition.MaxGuildNameLength
	if len < min then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34411), min), false)
		return false
	end
	if len > max then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34410), max), false)
		return false
	end
	if isAllNumber(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34412), false)
		return false
	end
	if hasIllegalWord(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34413), false)
		return false
	end
	return true
end

def.static("string", "=>", "boolean").CheckPetNameValid = function (name)
	if IsNilOrEmptyString(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34424), false)
		return false
	end
	local len = NameChecker.GetNameLength(name)
	local min = GlobalDefinition.MinPetNameLength
	local max = GlobalDefinition.MaxPetNameLength
	if len < min then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34421), min), false)
		return false
	end
	if len > max then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34420), max), false)
		return false
	end
	if isAllNumber(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34422), false)
		return false
	end
	if hasIllegalWord(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34423), false)
		return false
	end
	return true
end

def.static("string", "=>", "boolean").CheckTeamNameValid = function (name)
	if IsNilOrEmptyString(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34434), false)
		return false
	end
	local len = NameChecker.GetNameLength(name)
	local min = GlobalDefinition.MinTeamNameLength
	local max = GlobalDefinition.MaxTeamNameLength
	if len < min then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34431), min), false)
		return false
	end
	if len > max then
		game._GUIMan:ShowTipText(string.format(StringTable.Get(34430), max), false)
		return false
	end
	if isAllNumber(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34432), false)
		return false
	end
	if hasIllegalWord(name) then
		game._GUIMan:ShowTipText(StringTable.Get(34433), false)
		return false
	end
	return true
end

def.static("string", "=>", "string").SubGuildName = function (name)
	local ret = name
	if NameChecker.GetNameLength(name) > GlobalDefinition.MaxGuildNameLength then
		ret = GameUtil.SubUnicodeString(name, 1, GlobalDefinition.MaxGuildNameLength)
	end
	return ret
end

NameChecker.Commit()
return NameChecker