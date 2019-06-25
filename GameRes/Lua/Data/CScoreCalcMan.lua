--[[

	战斗力计算公式

]]

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CScoreCalcMan = Lplus.Class("CScoreCalcMan")
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"

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

def.method("number", "=>", "boolean").IsRatioValue = function(self, id)
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
	-- if config ~= nil and config.COEFFICIENT ~= nil and config.COEFFICIENT[propertyId] ~= nil then
	-- 	result = config.COEFFICIENT[propertyId][profession]
	-- else
	-- 	local propertyData = CElementData.GetAttachedPropertyTemplate( propertyId )
	-- 	if propertyData then
	-- 		result = propertyData.FightScoreFactor
	-- 	end
	-- end

	local propertyData = CElementData.GetAttachedPropertyTemplate( propertyId )
	if propertyData then
		result = propertyData.FightScoreFactor
	end

	return fixFloat(result,2)
end

-- 属性转换
def.method("number", "number", "number", "=>", "table").ExchangePropety = function(self, profession, propertyId, val)
	local retTable = {}
	local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
	local config = ModuleProfDiffConfig.GetModuleInfo("FightProperty")
	if config ~= nil and config.COEFFICIENT ~= nil and config.COEFFICIENT[propertyId] ~= nil then
		local info = config.COEFFICIENT[propertyId][profession]
		local CSpecialIdMan = require  "Data.CSpecialIdMan"
		for i,v in ipairs(info) do
			local coefficient = CSpecialIdMan.Get(v.SpecialId)

			local data = {}
			data.ID = v.ID
			data.Value = val * coefficient
			--warn("ID = ", data.ID, "coefficient = ", coefficient, "...", debug.traceback())
			table.insert(retTable, data)
		end
	else
		local data = {}
		data.ID = propertyId
		data.Value = val
		table.insert(retTable, data)
	end

	return retTable
end

--装备信息计算公式
def.method("number", "table", "=>", "number").CalcEquipScore = function(self, profession, calcUseInfo)
-- warn("CalcEquipScore-------------------------------")
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
		-- warn("Score = ", info.ID, info.Value, self:IsRatioValue(info.ID))
		local exchangedInfo = self:ExchangePropety(profession, info.ID, info.Value)
		for _,v in ipairs(exchangedInfo) do
			if tmp[v.ID] == nil then
				tmp[v.ID] = 0
			end
			tmp[v.ID] = tmp[v.ID] + v.Value
		end
	end

	--计算 【比率加成】
	for id, val in pairs(tmp) do
		if self:IsRatioValue(id) then
			local targetId = self:GetAddTarget(id)
			if targetId > 0 and tmp[targetId] then
				tmp[targetId] = tmp[targetId] * (1 + val)
			end
		end
	end

	--计算 【分数 = 属性值 * 系数】
	for id, val in pairs(tmp) do
		if not self:IsRatioValue(id) then
			local coefficient = self:GetFightPropertyCoefficient(profession, id)
			local propertyValue = coefficient * val

			-- warn("id = ", id, coefficient, val, propertyValue)
			result = result + propertyValue
		end
	end
	-- warn("math.ceil(result) = ", math.ceil(result))
	return math.ceil(result)
end

--计算被动技能战斗力 公式
def.method("number", "number", "=>", "number").CalcLegendaryUpgradeScore = function(self, id, level)
	local result = 0
	local TalentData = CElementData.GetTemplate("Talent", id)

	if TalentData then
		local lv = level - 1
		if lv <= 0 then
			lv = 0
		end
		result = TalentData.InitFightPower + (TalentData.LevelFightPower * lv)
	end

    return result
end

--计算技能战斗力
def.method( "=>", "number").CalcAllSkillScore = function(self)
	local result = 0
	local hp = game._HostPlayer
	if hp then
	    for i,v in ipairs(hp._UserSkillMap) do
	    	if v.Skill.SkillFightPower and v.Skill.SkillFightPower ~= "" then
				result = result + tonumber(v.Skill.SkillFightPower)
			end
		end
	end
	return math.ceil(result)
end

-- 文章战力
def.method( "=>", "number").CalcSkillRuneScore = function(self)
	local userSkillMap = game._HostPlayer._UserSkillMap
	local score = 0 
	local CElementSkill = require "Data.CElementSkill"
	for i, v in ipairs(userSkillMap) do	
		for k, x in ipairs(v.SkillRuneInfoDatas) do
			local rune = CElementSkill.GetRune(x.runeId)
			if x.isActivity then				
				if x.level == 1 then
					score = score + tonumber(CElementData.GetSpecialIdTemplate(330).Value)
				elseif x.level == 2 then
					score = score + tonumber(CElementData.GetSpecialIdTemplate(331).Value)
				else
					score = score + tonumber(CElementData.GetSpecialIdTemplate(332).Value)
				end
			end			
		end		
	end
	return score
end

--被动技能战斗力计算公式，使用装备tips中战斗公式的计算方式，不同点在属性的获取方式
def.method("number", "number", "number","=>", "number").CalcTalentSkillScore = function(self, profession, talentId, level)
	local result = 0
	local TalentData = CElementData.GetTemplate("Talent", talentId)
	if TalentData == nil then
		warn("CalcTalentSkillScore can't find talentId: ", talentId)
		return result
	end

	local talentDefaultScore = self:CalcLegendaryUpgradeScore(talentId, level)
	local propList = {}
	for _,v in ipairs(TalentData.ExecutionUnits) do
		if v.Trigger.RuneActivity ~= nil and v.Event.AddAttachedProperty ~= nil and v.Event.AddAttachedProperty.Duration == -1 then
			local attachedProperty = v.Event.AddAttachedProperty
			local propertyValue = attachedProperty.Value
			if tonumber(propertyValue) == nil then
				propertyValue = DynamicText.GetSkillLevelUpValue(talentId, 1, level, true)
			end
			local temp =
			{
				ID = attachedProperty.Id,
				Value = propertyValue
			}
			propList[#propList+1] = temp
		end
	end

	local talentPropertyScore = self:CalcEquipScore(profession, propList)

	result = talentPropertyScore + talentDefaultScore
	--warn("CalcTalentSkillScore: ", result, talentPropertyScore, talentDefaultScore)
	return result
end

--[[
	装备战斗力细分类型
    EquipFightScoreType =
    {
        Base        = 0,    -- 基础值
        Inforce     = 1,    -- 强化
        Recast      = 2,    -- 重铸
        Refine      = 3,    -- 精炼
        Talent      = 4,    -- 转化（天赋技能）
    },
]]
def.method("number", "table", "boolean", "=>", "table").CalcEquipFightScore = function(self, profession, item, bIsItemDB)
	local CEquipUtility = require "EquipProcessing.CEquipUtility"
	local baseVal = 0
	local inforceVal = 0
	local recastVal = 0
	local refineVal = 0
	local talentVal = 0
	local enchantVal = 0

	if bIsItemDB then
		local itemTemplate = CElementData.GetTemplate("Item", item.ItemData.Tid)
		if itemTemplate ~= nil then
			do
			-- 基础
				local data = {}
				local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate( item.ItemData.FightProperty.index )
				if attachPropertGenerator ~= nil then
					data.ID = attachPropertGenerator.FightPropertyId
					data.Value = item.ItemData.FightProperty.value
					baseVal = self:CalcEquipScore(profession, {data})
				end
			end

			do
			-- 强化
				local data = {}
				local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate( item.ItemData.FightProperty.index )
				if attachPropertGenerator ~= nil then
					data.ID = attachPropertGenerator.FightPropertyId

					local curLv = item.ItemData.InforceLevel
					local curVal = 0
					if curLv > 0 then
				        local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(itemTemplate.ReinforceConfigId, curLv)
				        if InforceInfoOld ~= nil then
				        	curVal = math.ceil(item.ItemData.FightProperty.value * (InforceInfoOld.InforeValue / 100))
				        end
				    end
					data.Value = curVal
					inforceVal = self:CalcEquipScore(profession, {data})
				end
			end

			do
			-- 重铸
				local info = {}
				for i,v in ipairs( item.ItemData.EquipBaseAttrs ) do
					local data = {}				
					local attrData = CElementData.GetAttachedPropertyGeneratorTemplate( v.index )

					if attrData then
						data.ID = attrData.FightPropertyId
						data.Value = v.value
						table.insert(info, data)
					end
				end
				recastVal = self:CalcEquipScore(profession, info)
			end
		end
	else
		do
		-- 基础
			local data = {}
			data.ID = item._BaseAttrs.ID
			data.Value = item._BaseAttrs.Value
			baseVal = self:CalcEquipScore(profession, {data})
		end

		do
		-- 强化
			local data = {}
			data.ID = item._BaseAttrs.ID

			local curLv = item:GetInforceLevel()
			local curVal = 0
			if curLv > 0 then
		        local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(item._ReinforceConfigId, curLv)
		        curVal = math.ceil(item._BaseAttrs.Value * (InforceInfoOld.InforeValue / 100))
		    end
			data.Value = curVal
			inforceVal = self:CalcEquipScore(profession, {data})
		end

		do
		-- 重铸
			local info = {}
			for i,v in ipairs( item._EquipBaseAttrs ) do
				local data = {}				
				local attrData = CElementData.GetAttachedPropertyGeneratorTemplate( v.index )

				if attrData then
					data.ID = attrData.FightPropertyId
					data.Value = v.value
					table.insert(info, data)
				end
			end
			recastVal = self:CalcEquipScore(profession, info)
		end
	end

	return {
				[EnumDef.EquipFightScoreType.Total] = math.ceil(baseVal+inforceVal+recastVal+refineVal+talentVal+enchantVal),
				[EnumDef.EquipFightScoreType.Base] = baseVal,
				[EnumDef.EquipFightScoreType.Inforce] = inforceVal,
				[EnumDef.EquipFightScoreType.Recast] = recastVal,
				[EnumDef.EquipFightScoreType.Refine] = refineVal,
				[EnumDef.EquipFightScoreType.Talent] = talentVal,
				[EnumDef.EquipFightScoreType.Enchant] = enchantVal,
			}	
end

def.method("table", "=>", "number").CalcFightScoreByItemDB = function(self, itemDB)
	local nRet = 0

	return nRet
end

-- 专精战力计算
def.method("=>", "number").GetSkillMasteryScore = function(self)
	local hp = game._HostPlayer	
	if not hp then return 0 end

	-- 技能专精战力计算由服务器给
	local _, score = hp:GetSkillMasteryInfo()
	
	return score
end

-- 人物 全身装备 战斗力
def.method("=>", "number").GetHostplayerWholeEquipFightScore = function(self)
	local result = 0
	local hp = game._HostPlayer
	local itemSet = hp._Package._EquipPack._ItemSet

	for i,itemData in ipairs(itemSet) do
		if itemData._Tid > 0 then
			result = result + itemData:GetFightScore()
		end
	end

	return result
end

-- 宠物 战斗力
def.method("=>", "number").GetWholePetFightScore = function(self)
	local CPetUtility = require "Pet.CPetUtility"
	local result = 0
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local petList = hp:GetCurrentHelpPetList()
    local addRatio = CPetUtility.GetPetHelpAddPropertyRatio()
    local addFightRatio = CPetUtility.GetPetFightAddPropertyRatio()
    do
        local petId = hp:GetCurrentFightPetId()
        if petId ~= nil then
	        local pet = petPackage:GetPetById(petId)
	        if pet ~= nil then
	            result = result + pet:GetPropertyScore() * addFightRatio + pet:GetSkillScore()
	        end
	    end
    end
    do
        local petId = petList[1]
        if petId ~= nil then
	        local pet = petPackage:GetPetById(petId)
	        if pet ~= nil then
	            result = result + pet:GetPropertyScore() * addRatio + pet:GetSkillScore()
	        end
	    end
    end
    do
        local petId = petList[2]
        if petId ~= nil then
	        local pet = petPackage:GetPetById(petId)
	        if pet ~= nil then
	            result = result + pet:GetPropertyScore() * addRatio + pet:GetSkillScore()
	        end
	    end
    end

	return math.ceil(result)
end

-- 宠物 战斗力
def.method("=>", "number").GetWholePetPropertyFightScore = function(self)
	local CPetUtility = require "Pet.CPetUtility"
	local result = 0
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local petList = hp:GetCurrentHelpPetList()
    local addRatio = CPetUtility.GetPetHelpAddPropertyRatio()
    local addFightRatio = CPetUtility.GetPetFightAddPropertyRatio()
    do
        local petId = hp:GetCurrentFightPetId()
        if petId ~= nil then
	        local pet = petPackage:GetPetById(petId)
	        if pet ~= nil then
	            result = result + pet:GetPropertyScore() * addFightRatio
	        end
	    end
    end
    do
        local petId = petList[1]
        if petId ~= nil then
	        local pet = petPackage:GetPetById(petId)
	        if pet ~= nil then
	            result = result + pet:GetPropertyScore() * addRatio
	        end
	    end
    end
    do
        local petId = petList[2]
        if petId ~= nil then
	        local pet = petPackage:GetPetById(petId)
	        if pet ~= nil then
	            result = result + pet:GetPropertyScore() * addRatio
	        end
	    end
    end

	return math.ceil(result)
end


-- 出战宠物 技能战斗力
def.method("=>", "number").GetFightPetSkillFightScore = function(self)
	local CPetUtility = require "Pet.CPetUtility"
	local result = 0
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage

    do
        local petId = hp:GetCurrentFightPetId()
        local pet = petPackage:GetPetById(petId)
        if pet ~= nil then
            result = result + pet:CalcSkillFightScoreWithoutTalent()
        end
    end

	return result
end

CScoreCalcMan.Commit()
return CScoreCalcMan