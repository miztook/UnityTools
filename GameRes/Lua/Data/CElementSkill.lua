local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local CElementSkill = Lplus.Class("CElementSkill")
local def = CElementSkill.define

def.static("number", "=>", "table").Get = function(tid)
	return CElementData.GetSkillTemplate(tid)
end

def.static("number", "=>", "table").GetClone = function(tid)
	return CElementData.GetSkillTemplateClone(tid)
end

def.static("number", "=>", "table").GetActor = function(tid)
	return CElementData.GetActorTemplate(tid)
end

def.static("number", "=>", "table").GetState = function(tid)
	return CElementData.GetStateTemplate(tid)
end

def.static("number", "=>", "table").GetLevelUp = function(tid)
	return CElementData.GetSkillLevelUpTemplate(tid)
end

def.static("number", "=>", "table").GetLearnCondition = function(tid)
	return CElementData.GetSkillLearnConditionTemplate(tid)
end

def.static("number", "=>", "table").GetLevelUpCondition = function(tid)
	return CElementData.GetSkillLevelUpConditionTemplate(tid)
end

def.static("number", "=>", "table").GetRune = function(tid)
	return CElementData.GetRuneTemplate(tid)
end

--[[
--获取技能，被动技能的一个结构
def.static('number', 'number', 'boolean', '=>', 'table').GetSkillInfoByIdAndLevel = function(id, level, bIsTalent)
	local template = CElementData.GetTemplate("Talent", id)
	if template == nil then return nil end
	
	local DynamicText = require "Utility.DynamicText"
	local info = {}
	info.ID = id
	info.Name = template.Name
	info.Level = level
	info.Desc = DynamicText.ParseSkillDescText(id, level, bIsTalent)
	
	local propertyId = template.ExecutionUnits[1].Event.AddAttachedProperty.Id
	local fightElement = CElementData.GetAttachedPropertyTemplate(propertyId)
	info.PropertyName = fightElement ~= nil and fightElement.TextDisplayName or ""

	return info
end
]]
	
-- 当前技能段能否移动施法
def.static("number", "number", "=>", "boolean").CanMoveWithSkill = function(skill_id, perform_idx)
	local skill = CElementSkill.Get(skill_id)
	if skill == nil then 
		warn("CanMoveWithSkill: Can not find skill with id = " .. skill_id)
		return false
	end
	local perform = skill.Performs[perform_idx]
	return (perform ~= nil and (perform.MoveCastType == 1 or perform.MoveCastType == 2))
end

-- 移动打断技能
def.static("number", "number","=>", "boolean").CanBeInterrupttedByMoving = function(skill_id, perform_idx)
	local skill = CElementSkill.Get(skill_id)
	if skill == nil then 
		warn("CanBeInterrupttedByMoving: Can not find skill with id = " .. skill_id)
		return false
	end
	local perform = skill.Performs[perform_idx]
	return (perform ~= nil and perform.CanBeInterrupted)
end

-- 技能是否为蓄力技能
def.static("table","=>", "boolean").IsChargeSkill = function(skill)	
	local ret = false
	if skill and skill.Performs then
		for i = 1, #skill.Performs do 
			if skill.Performs[i] and skill.Performs[i].IsChargePerform then
				ret = true
				break
			end
		end
	end
	return ret
end

-- 技能 perform 是否触发进度条
def.static("number", "number", "=>", "boolean", "number").IsShowLoadingBar = function(skill_id, index)
	local state_data = CElementSkill.Get(skill_id)	
	local ret, bar_type = false, -1
	if state_data and state_data.Performs then
		if state_data.Performs[index] then
			if state_data.Performs[index].IsShowLoadingBar then
				ret, bar_type = true, EnumDef.SkillLoadingBarType.Stick
			elseif state_data.Performs[index].ShowRingGuideBar then
				ret, bar_type =  true, EnumDef.SkillLoadingBarType.Circle
			end
		end
	end
	return ret, bar_type
end

-- 技能是否有触发进度条的断
def.static("number", "=>", "boolean", "number").NeedShowLoadingBar = function(skill_id)
	local state_data = CElementSkill.Get(skill_id)	
	local ret, bar_type = false, -1
	if state_data and state_data.Performs then
		for i = 1, #state_data.Performs do 
			if state_data.Performs[i] then
				if state_data.Performs[i].IsShowLoadingBar then
					ret, bar_type = true, EnumDef.SkillLoadingBarType.Stick
					break
				elseif state_data.Performs[i].ShowRingGuideBar then
					ret, bar_type =  true, EnumDef.SkillLoadingBarType.Circle
					break
				end
			end
		end
	end
	return ret, bar_type
end

def.static("number", "=>", "string").GetSkillIconFullPath = function (skill_tid)
	local template = CElementData.GetSkillTemplate(skill_tid)
	if template == nil then
		return ""
	else
		return _G.CommonAtlasDir.."Icon/" .. template.IconName .. ".png"
	end
end

def.static("number", "=>", "string").GetSkillName = function (skill_tid)
	local template = CElementData.GetSkillTemplate(skill_tid)
	if template == nil then
		return ""
	else
		return template.Name
	end
end

local RuneLevelupTemplateKey = "RuneLevelUp"
--[[获取纹章ID 升级等级的数值， 需要遍历]]
def.static("number", "number", "number", "=>", "number").GetRuneLevelUpValue = function(runeId, levelupId, runeLevel)
	if runeLevel == 0 then
		return 0
	end
	local result = 0
	local allRuneLevelUp = CElementData.GetAllTid(RuneLevelupTemplateKey)

	for i, tid in ipairs( allRuneLevelUp ) do
		local runeLevelUp = CElementData.GetTemplate(RuneLevelupTemplateKey, tid)
		if runeLevelUp and runeLevelUp.SkillId == runeId and runeLevelUp.LevelUpId == levelupId then
			if runeLevelUp.LevelDatas[runeLevel] ~= nil then
				result = runeLevelUp.LevelDatas[runeLevel].Value
			end
		end
	end

	if result == 0 then
		warn("缺少正确的纹章升级数据", "runeId: " .. runeId, "levelupId " .. levelupId, "runeLevel " .. runeLevel, debug.traceback() )
	end

	return result
end

def.static("number", "number", "number", "=>", "number").GetTalentLevelUpValue = function(skillId, levelupId, skillLevel)

	local result = 0
	local allSkillLevelUp = CElementData.GetAllTalentOrSkillLevelUpTemplateSimple(true)
	local Tid = 0
	for id, temp in ipairs( allSkillLevelUp ) do
		if temp.SkillId == skillId and temp.LevelUpId == levelupId then
			Tid = id
			break
		end
	end
	if Tid > 0 then 
		local temp = CElementData.GetTemplate( "TalentLevelUp",Tid)
		if temp ~= nil and temp.LevelDatas[skillLevel] ~= nil then 
			result = temp.LevelDatas[skillLevel].Value
		end
	end
	return result
end

--[[获取技能&被动技能的描述]]
def.static("number", "boolean", "=>", "string").GetSkillDesc = function(skillId, bIsTalent)
	return CElementData.GetSkillDesc(skillId, bIsTalent)
end

--[[获取技能ID 升级等级的数值， 需要遍历]]
def.static("number", "number", "number", "boolean", "=>", "number").GetSkillLevelUpValue = function(skillId, levelupId, skillLevel, bIsTalent)
	return CElementData.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent)
end

CElementSkill.Commit()
return CElementSkill