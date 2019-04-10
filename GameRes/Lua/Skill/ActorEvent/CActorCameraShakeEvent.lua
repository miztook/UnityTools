local Lplus = require "Lplus"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"

local CActorCameraShakeEvent = Lplus.Extend(CActorEventBase, "CActorCameraShakeEvent")
local def = CActorCameraShakeEvent.define

def.static("table", "table", "=>", CActorCameraShakeEvent).new = function(event, params)
	local obj = CActorCameraShakeEvent()
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
	if Vector3.SqrDistance_XYZ(hostX, hostY, hostZ, posX, posY, posZ) < SqrDisLimit then
		ret = true
	end
	return ret
end

def.override().OnEvent = function(self)
	local owner = self._Params.BelongedSubobject or self._Params.BelongedCreature  -- 算距离
	local entity = nil
	if self._Params.BelongedSubobject then
	 	entity = game._CurWorld:FindObject(self._Params.BelongedSubobject._OwnerID)
	end
	if owner and entity then
		if entity:IsHostPlayer() or (not entity:IsHostPlayer() and self._Event.IsOtherPlayerShow and DistanceCheck(owner)) then	
			CVisualEffectMan.ShakeCamera( self._Event.FadeinDuration/1000 , self._Event.FadeoutDuration/1000 , self._Event.KeepMaxDuration/1000, self._Event.Magnitude, self._Event.Roughness, tostring(self))		
		end
	end
end

-- 释放屏幕效果
def.override().OnRelease = function(self)
	local owner = self._Params.BelongedSubobject or self._Params.BelongedCreature  -- 算距离
	local entity = nil
	if self._Params.BelongedSubobject then
	 	entity = game._CurWorld:FindObject(self._Params.BelongedSubobject._OwnerID)
	end
	if owner and entity then
		if entity:IsHostPlayer() or (not entity:IsHostPlayer() and self._Event.IsOtherPlayerShow and DistanceCheck(owner)) then
			CVisualEffectMan.StopCameraShake(tostring(self))
		end
	end
	CActorEventBase.OnRelease(self)
end

CActorCameraShakeEvent.Commit()
return CActorCameraShakeEvent
