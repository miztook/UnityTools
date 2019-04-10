local Lplus = require "Lplus"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"

local CActorCameraBlurEvent = Lplus.Extend(CActorEventBase, "CActorCameraBlurEvent")
local def = CActorCameraBlurEvent.define

def.static("table", "table", "=>", CActorCameraBlurEvent).new = function (event, params)
	local obj = CActorCameraBlurEvent()
	obj._Event = event.MotionBlur
	obj._Params = params	
	return obj
end

def.override().OnEvent = function(self)
	if self._Event.Type ~= 0 then return end

	local entity = self._Params.BelongedCreature
	if entity and not entity._IsReleased then
		if entity:IsHostPlayer() or (not entity:IsHostPlayer() and self._Event.IsOtherPlayerShow) then	
			local base_go = nil
			if self._Params.BelongedSubobject and self._Params.BelongedSubobject._GfxObject ~= nil then		
				base_go = self._Params.BelongedSubobject._GfxObject:GetGameObject()
			else
				base_go = self._Params.ClientActorGfx
			end

			if base_go then		
				local CVisualEffectMan = require "Effects.CVisualEffectMan"
				local duration = self._Event.FadeinDuration + self._Event.KeepMaxDuration + self._Event.FadeoutDuration
				CVisualEffectMan.StartRadialBlurAtActor(base_go, true, self._Event.FadeinDuration/duration, duration/1000, 
					(self._Event.FadeinDuration + self._Event.KeepMaxDuration)/duration, self._Event.Level, self._Event.IgnoreRange)
			end			
		end
	end
end

-- 释放屏幕效果
def.override().OnRelease = function(self)
	if self._Event.Type ~= 0 then return end

	local entity = self._Params.BelongedCreature
	if entity and not entity._IsReleased then
		if entity:IsHostPlayer() or (not entity:IsHostPlayer() and self._Event.IsOtherPlayerShow) then	
			local base_go = nil
			if self._Params.BelongedSubobject and self._Params.BelongedSubobject._GfxObject ~= nil then		
				base_go = self._Params.BelongedSubobject._GfxObject:GetGameObject()
			else
				base_go = self._Params.ClientActorGfx
			end

			if base_go then		
				local CVisualEffectMan = require "Effects.CVisualEffectMan"
				CVisualEffectMan.StopRadialBlurEffect(base_go)
			end			
		end
	end

	CActorEventBase.OnRelease(self)
end


CActorCameraBlurEvent.Commit()
return CActorCameraBlurEvent