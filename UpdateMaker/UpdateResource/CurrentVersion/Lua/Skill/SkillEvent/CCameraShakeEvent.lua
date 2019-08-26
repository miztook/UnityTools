local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"

local CCameraShakeEvent = Lplus.Extend(CSkillEventBase, "CCameraShakeEvent")
local def = CCameraShakeEvent.define

def.field("boolean")._IsShaking = false

def.static("table", "table", "=>", CCameraShakeEvent).new = function(event, params)
	local obj = CCameraShakeEvent()
	obj._Event = event.CameraShake
	obj._Params = params
	return obj
end

local SqrDisLimit = 50 * 50
local function DistanceCheck(entity)
	local ret = false
	local hp = game._HostPlayer
	local hostX, hostY, hostZ = hp:GetPosXYZ()
	local posX, posY, posZ = entity:GetPosXYZ()
	if Vector3.SqrDistance_XYZ(hostX, 0, hostZ, posX, 0, posZ) < SqrDisLimit then
		ret = true
	end
	return ret
end

def.override().OnEvent = function(self)
	-- 淡入时间，淡出时间，持续时间，振幅，频率
	local entity =  self._Params.BelongedCreature
	if not entity then return end
	if entity:IsHostPlayer() or (self._Event.IsOtherPlayerShow and DistanceCheck(entity)) then
		CVisualEffectMan.ShakeCamera( self._Event.FadeinDuration/1000 , self._Event.FadeoutDuration/1000 , self._Event.KeepMaxDuration/1000, self._Event.Magnitude, self._Event.Roughness, tostring(self) )
		self._IsShaking = true
	end
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return (self._Event.FadeinDuration + self._Event.FadeoutDuration + self._Event.KeepMaxDuration)/1000
end

-- 释放屏幕效果
def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if not self._IsShaking then
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
				or (ctype == EnumDef.EntitySkillStopType.LifeEnd)

	if stopNow then
		CVisualEffectMan.StopCameraShake(tostring(self))
		CSkillEventBase.OnRelease(self, ctype)
		return true
	else
		return false
	end
end

CCameraShakeEvent.Commit()
return CCameraShakeEvent
