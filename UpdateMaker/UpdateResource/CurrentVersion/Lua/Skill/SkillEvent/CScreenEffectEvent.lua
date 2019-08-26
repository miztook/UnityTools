local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"

local CScreenEffectEvent = Lplus.Extend(CSkillEventBase, "CScreenEffectEvent")
local def = CScreenEffectEvent.define

def.field("number")._LifeTime = 0

def.static("table", "table", "=>", CScreenEffectEvent).new = function (event, params)
	if params.BelongedCreature == nil or not params.BelongedCreature:IsHostPlayer() then
		return nil 
	end

	local obj = CScreenEffectEvent()
	obj._Event = event.ScreenEffect
	obj._Params = params
	return obj
end

local RuneLevelUpKey = "runelevelup"
def.override().OnEvent = function(self)
	local duration = 1000
	local durationStr = self._Event.KeepDuration
	if string.find(durationStr, RuneLevelUpKey) then
		local levelupId = string.sub(durationStr, string.len(RuneLevelUpKey)-string.len(durationStr))
		levelupId = tonumber(levelupId)
		if levelupId ~= nil then
			local skillId = self._Params.SkillId
			local entity = self._Params.BelongedCreature
			local skillData = entity:GetSkillData(skillId)
			if skillData ~= nil then
				local runeId = 0
		    	local runeLevel = 0
				for _, m in ipairs(skillData.SkillRuneInfoDatas) do
	                if m.isActivity then
	                    runeId = m.runeId
	                    runeLevel = m.level
	                    break            
	                end
	            end

	            --此技能单元通过纹章添加
			    if runeId == 0 or runeLevel == 0 then return end

				local CElementSkill = require "Data.CElementSkill"
				duration = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel)
			end
		end
	else
		local d = tonumber(durationStr)
		if d ~= nil then duration = d end
	end	

	self._LifeTime = duration

	CVisualEffectMan.ScreenColor(true, self._Event.FadeinDuration, duration, self._Event.FadeoutDuration,
		self._Event.ColorR, self._Event.ColorG, self._Event.ColorB, self._Event.ColorA)
end

def.override("=>", "number").GetLifeTime = function(self)
	return self._LifeTime
end

def.override("number", "=>", "boolean").OnRelease = function(self, ctype)	
	self._LifeTime = 0
	local entity = self._Params.BelongedCreature
	if entity == nil or entity:IsReleased() then
		return CSkillEventBase.OnRelease(self, ctype)
	end	

	local stopNow = (ctype == EnumDef.EntitySkillStopType.PerformEnd and self._Event.FinishConditionPerformEnd)
				or (ctype == EnumDef.EntitySkillStopType.SkillEnd and self._Event.FinishConditionSkillEnd)
				or (ctype == EnumDef.EntitySkillStopType.LifeEnd)
				
	if stopNow then
		CVisualEffectMan.ScreenColor(false, 0, 0, 0, 0, 0, 0, 0)				
		return CSkillEventBase.OnRelease(self, ctype)
	else
		return false
	end
end

CScreenEffectEvent.Commit()
return CScreenEffectEvent
