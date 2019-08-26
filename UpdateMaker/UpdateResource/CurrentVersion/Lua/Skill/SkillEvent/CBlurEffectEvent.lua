local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"

local CBlurEffectEvent = Lplus.Extend(CSkillEventBase, "CBlurEffectEvent")
local def = CBlurEffectEvent.define

def.field("boolean")._IsInRadialBlur = false

def.static("table", "table", "=>", CBlurEffectEvent).new = function (event, params)
	local obj = CBlurEffectEvent()
	obj._Event = event.MotionBlur
	obj._Params = params
	return obj
end

local SqrDisLimit = 50 * 50
local function DistanceCheck(entity)
	local ret = false
	local hp = game._HostPlayer
	local hostX, hostY, hostZ = hp:GetPosXYZ()
	local posX, posY, posZ = entity:GetPosXYZ()
	if Vector3.SqrDistance_XYZ(hostX, hostY, hostZ, posX, posY, posZ) < SqrDisLimit then
		ret = true
	end
	return ret
end

def.override().OnEvent = function(self)
	if self._Event.Type == 0 then  -- RadialBlur
		local entity = self._Params.BelongedCreature
		if entity == nil then return end
		local hp = game._HostPlayer
		if entity:IsHostPlayer() or (self._Event.IsOtherPlayerShow and DistanceCheck(hp)) then
			local duration = (self._Event.FadeinDuration + self._Event.KeepMaxDuration + self._Event.FadeoutDuration)
			CVisualEffectMan.StartRadialBlurAtEntity(entity:GetGameObject(), self._Event.HangPoint, self._Event.FadeinDuration/duration, duration/1000, self._Event.FadeoutDuration/duration, self._Event.Level, self._Event.IgnoreRange)
			self._IsInRadialBlur = true
		end
	elseif self._Event.Type == 1 then  -- MotionBlur
		CVisualEffectMan.StartMotionBlur(self._Event.Level, self._Event.FadeinDuration/1000, self._Event.KeepMaxDuration/1000, self._Event.FadeoutDuration/1000)
	else
		--print("error MotionBlur.Type in CBlurEffectEvent")
	end
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return (self._Event.FadeinDuration + self._Event.KeepMaxDuration + self._Event.FadeoutDuration) / 1000
end

def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if self._Event.Type == 0 then
		if not self._IsInRadialBlur then
			CSkillEventBase.OnRelease(self, ctype)
			return true
		end	

		local entity = self._Params.BelongedCreature
		if entity == nil or entity:IsReleased() then
			CSkillEventBase.OnRelease(self, ctype)
			return true
		end

		local stopNow = (ctype == EnumDef.EntitySkillStopType.PerformEnd and self._Event.FinishConditionPerformEnd)
						or (ctype == EnumDef.EntitySkillStopType.SkillEnd and self._Event.FinishConditionSkillEnd)
						or ctype == EnumDef.EntitySkillStopType.LifeEnd
		if stopNow then
			CVisualEffectMan.StopRadialBlurEffect(entity:GetGameObject())
			CSkillEventBase.OnRelease(self, ctype)
			return true
		else
			return false
		end
	else --if self._Event.Type == 1 then
		CSkillEventBase.OnRelease(self, ctype)
		return true
	end
end

CBlurEffectEvent.Commit()
return CBlurEffectEvent
