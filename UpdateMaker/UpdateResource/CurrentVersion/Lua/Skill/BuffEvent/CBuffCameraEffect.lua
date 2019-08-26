local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"
local CFxObject = require "Fx.CFxObject"

local CBuffCameraEffect = Lplus.Extend(CBuffEventBase, "CBuffCameraEffect")
local def = CBuffCameraEffect.define

def.field(CFxObject)._EffectObject = nil 

def.static("table", "table", "=>", CBuffCameraEffect).new = function(host, event)
	if not host:IsHostPlayer() and event.CameraEffect.IsOtherPlayerShow then
		return nil
	else
		local obj = CBuffCameraEffect()
		obj._Event = event
		obj._Host = host
		return obj
	end
end

def.override().OnEvent = function(self)	
	local entity = self._Host
	if entity ~= nil and not entity:IsReleased() then
		local event = self._Event
		if event.CameraEffect.HangType == 0 then
			local data  = { ActorId = event.CameraEffect.ActorId, HangType = 0}
			game._GUIMan:Open("CPanelBossEffect",data)
		else
			local CElementSkill = require "Data.CElementSkill"
			local actorTemp = CElementSkill.GetActor(event.CameraEffect.ActorId)
			if actorTemp ~= nil then
				self._EffectObject = CFxMan.Instance():PlayAsChild(actorTemp.GfxAssetPath, game._MainCamera, Vector3.zero, Quaternion.identity,-1,false, -1, EnumDef.CFxPriority.Always)
			end
		end
	end
end

def.override().OnBuffEnd = function(self)	
	local event = self._Event
	if event.CameraEffect.HangType == 0 then
		game._GUIMan:Close("CPanelBossEffect")
	else
		if self._EffectObject ~= nil then
			CFxMan.Instance():Stop(self._EffectObject)
			self._EffectObject = nil
		end
	end

	CBuffEventBase.OnBuffEnd(self)
end

CBuffCameraEffect.Commit()
return CBuffCameraEffect
