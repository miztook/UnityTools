local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CFxObject = require "Fx.CFxObject"

local CCameraEffectEvent = Lplus.Extend(CSkillEventBase, "CCameraEffectEvent")
local def = CCameraEffectEvent.define

def.field(CFxObject)._EffectObject = nil 
def.field("number")._EffectType = 0 

def.static("table", "table", "=>", CCameraEffectEvent).new = function(event, params)
	local obj = CCameraEffectEvent()
	obj._Event = event.CameraEffect
	obj._Params = params
	return obj
end

-- required int32 ActorId = 1;
-- required bool IsOtherPlayerShow = 2;  
def.override().OnEvent = function(self)	
	local entity = self._Params.BelongedCreature
	if entity:IsHostPlayer() or (not entity:IsHostPlayer() and self._Event.IsOtherPlayerShow) then
		if  self._Event.HangType == 0 then
			local data  = { ActorId = self._Event.ActorId, HangType = self._Event.HangType}
			game._GUIMan:Open("CPanelBossEffect",data)
		else
			local CElementSkill = require "Data.CElementSkill"
			local actor_template = CElementSkill.GetActor(self._Event.ActorId)
			if actor_template then
				self._EffectObject = CFxMan.Instance():PlayAsChild(actor_template.GfxAssetPath, game._MainCamera, Vector3.zero, Quaternion.identity,-1,false, -1, EnumDef.CFxPriority.Always)
			end
		end
		self._EffectType = self._Event.HangType
	end
end

-- 
def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if self._EffectType == 0 then
		game._GUIMan:Close("CPanelBossEffect")
	else
		if self._EffectObject then
			CFxMan.Instance():Stop(self._EffectObject)
			self._EffectObject = nil
		end
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CCameraEffectEvent.Commit()
return CCameraEffectEvent
