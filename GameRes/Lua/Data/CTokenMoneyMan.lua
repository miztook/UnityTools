--[[

	代币处理类

]]
local Lplus = require "Lplus"
local CTokenMoneyMan = Lplus.Class("CTokenMoneyMan")
local CElementData = require "Data.CElementData"
local EResourceType = require "PB.data".EResourceType

local def = CTokenMoneyMan.define

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end


local instance = nil
def.static('=>', CTokenMoneyMan).Instance = function()
	if not instance then
        instance = CTokenMoneyMan()
	end
	return instance
end

def.method("number", "=>", "string").GetName = function(self, id)
	local result = ""
	local MoneyData = CElementData.GetTemplate("Money", id)
	if MoneyData then
		result = MoneyData.TextDisplayName
	end

	return result
end

def.method("number", "=>", "string").GetEmoji = function(self, id)
	local result = ""
	return EnumDef.ExchangeMoneyToEmoji[id] == nil and "" or GUITools.GetEmojiByType(EnumDef.ExchangeMoneyToEmoji[id])
end

def.method("number", "=>", "string").GetIconPath = function(self, id)
	local result = ""
	local MoneyData = CElementData.GetTemplate("Money", id)
	if MoneyData then
		result = MoneyData.IconPath
	end

	return result
end

def.method("number", "=>", "string").GetCoinModelPathId = function(self, count)
	if count > 10000 then
		return PATH.Model_Gold_3
	elseif count > 1000 then
		return PATH.Model_Gold_2
	elseif count > 200 then
		return PATH.Model_Gold_1
	elseif count > 0 then
		return PATH.Model_Gold_0
	else
		return ""
	end
end

--检查货币是否满足
def.method("table", "=>", "boolean").CheckMoneyEnough = function(self, info)
	local bRet = true
	if info == nil then return bRet end

	local iHave = game._HostPlayer:GetMoneyCountByType(info.MoneyType)
	if iHave < info.MoneyNeed then
		bRet = false
		local str = string.format(StringTable.Get(268), StringTable.Get(400+info.MoneyType))
		SendFlashMsg(str, false)
	end

	return bRet
end

--方便使用类型，如有需求添加类型，请自行实现
def.method("number", "=>", "boolean").IsGoldType = function(self, id)
	return id == EResourceType.ResourceTypeGold
end

def.method("number", "=>", "boolean").IsAllDiamondType = function(self, id)
	return id == EResourceType.ResourceTypeAllDiamond
end

def.method("number", "=>", "boolean").IsDiamondType = function(self, id)
	return id == EResourceType.ResourceTypeDiamond
end

def.method("number", "=>", "boolean").IsBindDiamondType = function(self, id)
	return id == EResourceType.ResourceTypeBindDiamond
end

CTokenMoneyMan.Commit()
return CTokenMoneyMan