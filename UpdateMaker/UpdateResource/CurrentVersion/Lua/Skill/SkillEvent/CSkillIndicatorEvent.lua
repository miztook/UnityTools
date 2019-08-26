local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CEntity = require "Object.CEntity"

local CSkillIndicatorEvent = Lplus.Extend(CSkillEventBase, "CSkillIndicatorEvent")
local def = CSkillIndicatorEvent.define

def.static("table", "table", "=>", CSkillIndicatorEvent).new = function(event, params)
	local obj = CSkillIndicatorEvent()
	obj._Event = event.SkillIndicator
	obj._Params = params

	return obj
end

def.override().OnEvent = function(self)

	local caster = self._Params.BelongedCreature
	if caster == nil then return end

	-- local radius = caster:GetRadius()
	local type = self._Event.IndicatorType
	local duration = self._Event.Duration / 1000
	local param1 = self._Event.Param1
	local param2 = self._Event.Param2
	local isNotCloseToGround = self._Event.IsNotCloseToGround

	--warn(string.format("PlaySkillIndicatorGfx, type: %d, duration: %d, param1: %d, param2: %d", type, duration, param1, param2))

	caster._SkillHdl:PlaySkillIndicatorGfx(type, duration, param1, param2, isNotCloseToGround)

end

CSkillIndicatorEvent.Commit()
return CSkillIndicatorEvent