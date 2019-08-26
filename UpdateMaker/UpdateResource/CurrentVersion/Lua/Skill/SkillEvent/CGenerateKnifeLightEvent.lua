local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CGenerateKnifeLightEvent = Lplus.Extend(CSkillEventBase, "CGenerateKnifeLightEvent")
local def = CGenerateKnifeLightEvent.define

def.field("number")._TimerId = 0

def.static("table", "table", "=>", CGenerateKnifeLightEvent).new = function(event, params)
	local obj = CGenerateKnifeLightEvent()
	obj._Event = event.GenerateKnifeLight
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)	
	local entity = self._Params.BelongedCreature	
	if entity ~= nil then						
		local CVisualEffectMan = require "Effects.CVisualEffectMan"				
		CVisualEffectMan.ShowBladeEffect(entity, true)	
		self._TimerId = entity:AddTimer(self._Event.Duration/1000, true, function()	
				CVisualEffectMan.ShowBladeEffect(entity, false)	
				self._TimerId = 0			
			end )		
	end
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return self._Event.Duration/1000
end

def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	local entity =  self._Params.BelongedCreature
	if self._TimerId and entity then
		local CVisualEffectMan = require "Effects.CVisualEffectMan"
		CVisualEffectMan.ShowBladeEffect(entity, false)	
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CGenerateKnifeLightEvent.Commit()
return CGenerateKnifeLightEvent
