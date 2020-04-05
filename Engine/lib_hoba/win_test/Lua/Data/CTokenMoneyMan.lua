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

def.method("number", "=>", "string").GetIconPath = function(self, id)
	local result = ""
	local MoneyData = CElementData.GetTemplate("Money", id)
	if MoneyData then
		result = MoneyData.IconPath
	end

	return result
end

def.method("number", "=>", "number").GetModelAssetId = function(self, id)
	local result = 0
	local MoneyData = CElementData.GetTemplate("Money", id)
	if MoneyData then
		result = MoneyData.ModelAssetId
	end

	return result
end

--获取类型
def.method("number", "=>", "number").GetType = function(self, id)
	local result = -1 	--EResourceType.ResourceTypeInvalid 无效
	local MoneyData = CElementData.GetTemplate("Money", id)

	if MoneyData then
		result = MoneyData.MoneyType
	end

	return result
end

--[[
	Info = 
	{
		MoneyType = 0,
		MoneyNeed = 0,
	}
]]
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
	return self:GetType(id) == EResourceType.ResourceTypeGold
end

def.method("number", "=>", "boolean").IsAllDiamondType = function(self, id)
	return self:GetType(id) == EResourceType.ResourceTypeAllDiamond
end

def.method("number", "=>", "boolean").IsDiamondType = function(self, id)
	return self:GetType(id) == EResourceType.ResourceTypeDiamond
end

def.method("number", "=>", "boolean").IsBindDiamondType = function(self, id)
	return self:GetType(id) == EResourceType.ResourceTypeBindDiamond
end

CTokenMoneyMan.Commit()
return CTokenMoneyMan