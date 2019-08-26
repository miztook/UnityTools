local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CAnimationEvent = Lplus.Extend(CSkillEventBase, "CAnimationEvent")
local def = CAnimationEvent.define

def.static("table", "table", "=>", CAnimationEvent).new = function(event, params)
	local obj = CAnimationEvent()
	obj._Event = event.Animation
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	local ani = self._Event.Resource
	local speed = self._Event.PlaySpeed
	
	local caster = self._Params.BelongedCreature
	if caster ~= nil then
		caster:PlayAnimation(ani, 0, false, 0, 1)
	end
end

CAnimationEvent.Commit()
return CAnimationEvent
