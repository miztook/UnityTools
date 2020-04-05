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
	if skill ~= nil and skill.Performs ~= nil and skill.Performs[1] ~= nil then
		return skill.Performs[1].IsChargePerform
	else
		return false
	end
end

-- 技能是否触发进度条
def.static("table","=>", "boolean").IsShowLoadingBar = function(skill)
	if skill ~= nil and skill.Performs ~= nil and skill.Performs[1] ~= nil then
		return skill.Performs[1].IsShowLoadingBar
	else
		return false
	end
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

CElementSkill.Commit()
return CElementSkill