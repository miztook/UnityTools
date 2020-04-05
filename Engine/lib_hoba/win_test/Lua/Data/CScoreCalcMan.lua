--[[

	战斗力计算公式

]]

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CScoreCalcMan = Lplus.Class("CScoreCalcMan")
local CElementData = require "Data.CElementData"

local def = CScoreCalcMan.define

--【属性绝对值ID】
local AbsValue =
{
	3,5,7,9,11,17,19,21,59,61,63,101,104,106,109,111,66,65,79,80,23,25,27,29,31,33,35,37,39,41,43,45,67,68,69,70,71,72,73,74,75,76,77,78,115,117,119,121,123,125,501,502,503,504,505
}
--【属性比率ID】
local RatioValue = 
{
	145,146,147,148,149,150,151,152,153,154,155,156,157,158,159,160,161,162,163,164,165,166,167,168,169,170,171,172,173,174,175,176,177,178
}
--【属性比率ID】 对应加成的 【属性绝对值ID】
local AddTarget = 
{
	[145] = 3,	[146] = 5,	[147] = 7,	[148] = 9,	[149] = 11,	[150] = 19,
	[151] = 21,	[152] = 23,	[153] = 25,	[154] = 27,	[155] = 29,	[156] = 31,
	[157] = 33,	[158] = 35,	[159] = 37,	[160] = 39,	[161] = 41,	[162] = 43,
	[163] = 45,	[164] = 501,[165] = 111,[166] = 115,[167] = 117,[168] = 119,
	[169] = 121,[170] = 123,[171] = 125,[172] = 59,	[173] = 61,	[174] = 63,
	[175] = 101,[176] = 104,[177] = 106,[178] = 109,
}

local instance = nil
def.static('=>', CScoreCalcMan).Instance = function()
	if not instance then
        instance = CScoreCalcMan()
	end
	return instance
end

def.method("number", "=>", "boolean").IsRationValue = function(self, id)
	local bRet = false

	for i=1, #RatioValue do
		if RatioValue[i] == id then
			bRet = true
			break
		end
	end

	return bRet
end

def.method("number", "=>", "number").GetAddTarget = function(self, id)
	local targetId = 0

	for i=1, #RatioValue do
		if AddTarget[id] then
			targetId = AddTarget[id]
			break
		end
	end

	return targetId
end

def.method("number", "number", "=>", "number").GetFightPropertyCoefficient = function(self, profession, propertyId)
	local result = 0

	local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
	local config = ModuleProfDiffConfig.GetModuleInfo("FightProperty")
	if config ~= nil and config.COEFFICIENT ~= nil and config.COEFFICIENT[propertyId] ~= nil then
		result = config.COEFFICIENT[propertyId][profession]
	else
		local propertyData = CElementData.GetAttachedPropertyTemplate( propertyId )
		if propertyData then
			result = propertyData.FightScoreFactor
		end
	end

	return result
end

--装备信息计算公式
def.method("number", "table", "=>", "number").CalcEquipScore = function(self, profession, calcUseInfo)
--[[
	外部接口结构需组织成以下内容：
	{
		ID = 1,
		Value = 1,
	}
]]
	local tmp = {}
	local result = 0

	--计算 【∑同属性】
	for i,info in ipairs( calcUseInfo ) do
		if tmp[info.ID] == nil then
			tmp[info.ID] = 0
		end
		tmp[info.ID] = tmp[info.ID] + info.Value
	end

	--计算 【比率加成】
	for id, val in pairs(tmp) do
		if self:IsRationValue(id) then
			local targetId = self:GetAddTarget(id)
			if targetId > 0 and tmp[targetId] then
				tmp[targetId] = tmp[targetId] * (1 + val)
			end
		end
	end

	--计算 【分数 = 属性值 * 系数】
	for id, val in pairs(tmp) do
		if not self:IsRationValue(id) then
			local coefficient = self:GetFightPropertyCoefficient(profession, id)
			local propertyValue = coefficient * val
			result = result + propertyValue
		end
	end

	return math.ceil(result)
end

--计算被动技能战斗力 公式
def.method("number", "number", "=>", "number").CalcLegendaryUpgradeScore = function(self, id, level)
	local result = 0
	local TalentData = CElementData.GetTemplate("Talent", id)

	if TalentData then
		result = TalentData.InitFightPower + (TalentData.LevelFightPower * (level - 1))
	end

	return math.ceil(result)
end

CScoreCalcMan.Commit()
return CScoreCalcMan