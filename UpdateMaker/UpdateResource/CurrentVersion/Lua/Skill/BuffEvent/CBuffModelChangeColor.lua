local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"

local CBuffModelChangeColor = Lplus.Extend(CBuffEventBase, "CBuffModelChangeColor")
local def = CBuffModelChangeColor.define

def.static("table", "table", "=>", CBuffModelChangeColor).new = function(host, event)
	local obj = CBuffModelChangeColor()
	obj._Event = event
	obj._Host = host
	return obj
end

def.override().OnEvent = function(self)
	local entity = self._Host
	if entity ~= nil and not entity:IsReleased() then
		local event = self._Event
		local param1 = event.ModelChangeColor.RimColorR/255	
		local param2 = event.ModelChangeColor.RimColorG/255
		local param3 = event.ModelChangeColor.RimColorB/255
		local param4 = event.ModelChangeColor.RimPower	
		CVisualEffectMan.EnableRimColorEffect(entity, true, param1, param2, param3, param4)
	end
end

def.override().OnBuffEnd = function(self)	
	local entity = self._Host
	if entity ~= nil and not entity:IsReleased() then
		CVisualEffectMan.EnableRimColorEffect(entity, false, 0, 0, 0, 0)
	end
	
	CBuffEventBase.OnBuffEnd(self)
end

CBuffModelChangeColor.Commit()
return CBuffModelChangeColor