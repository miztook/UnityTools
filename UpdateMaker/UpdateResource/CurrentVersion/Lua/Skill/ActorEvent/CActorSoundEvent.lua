local Lplus = require "Lplus"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"

local CActorSoundEvent = Lplus.Extend(CActorEventBase, "CActorSoundEvent")
local def = CActorSoundEvent.define
def.field("string")._AsName = ""

def.static("table", "table", "=>", CActorSoundEvent).new = function (event, params)
	local obj = CActorSoundEvent()
	obj._Event = event.Audio
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	if self._Params.BelongedSubobject ~= nil then		
		if self._Params.BelongedSubobject._GfxObject then
			local go = self._Params.BelongedSubobject._GfxObject:GetGameObject()	
			if go == nil then return end	
			self._AsName = CSoundMan.Instance():PlayAttached3DAudio(self._Event.AssetPath, go, 0)
		else
			self._AsName = CSoundMan.Instance():Play3DAudio(self._Event.AssetPath, self._Params.BelongedSubobject:GetPos(), 0)
		end		
	elseif self._Params.BelongedCreature ~= nil then	
		self._AsName = CSoundMan.Instance():Play3DAudio(self._Event.AssetPath, self._Params.BelongedCreature:GetPos(), 0)
	end
end

def.override().OnRelease = function(self)
	CSoundMan.Instance():Stop3DAudio(self._Event.AssetPath, self._AsName)
	CActorEventBase.OnRelease(self)
end


CActorSoundEvent.Commit()
return CActorSoundEvent