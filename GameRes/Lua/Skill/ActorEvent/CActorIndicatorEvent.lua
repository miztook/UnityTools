local Lplus = require "Lplus"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"

local CActorIndicatorEvent = Lplus.Extend(CActorEventBase, "CActorIndicatorEvent")
local def = CActorIndicatorEvent.define

def.static("table", "table", "=>", CActorIndicatorEvent).new = function(event, params)
	local obj = CActorIndicatorEvent()
	obj._Event = event.SkillIndicator
	obj._Params = params

	return obj
end

def.override().OnEvent = function(self)
	local caster = self._Params.BelongedSubobject
	if caster == nil then return end

	local type = self._Event.IndicatorType
	local duration = self._Event.Duration / 1000
	local param1 = self._Event.Param1
	local param2 = self._Event.Param2

	--warn(string.format("PlaySkillIndicatorGfx, type: %d, duration: %d, param1: %d, param2: %d", type, duration, param1, param2))

	caster:PlaySkillIndicatorGfx(type, duration, param1, param2)
end

CActorIndicatorEvent.Commit()
return CActorIndicatorEvent