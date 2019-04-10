local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CStopSkillEvent = Lplus.Extend(CSkillEventBase, "CStopSkillEvent")
local def = CStopSkillEvent.define

def.static("table", "table", "=>", CStopSkillEvent).new = function(event, params)
	local obj = CStopSkillEvent()
	obj._Event = event.StopSkill
	obj._Params = params
	obj._IsToBlockPerformSequence = true
	return obj
end

def.override().OnEvent = function(self)
	local caster = self._Params.BelongedCreature
	if caster ~= nil and caster:IsHostPlayer() then
		caster._SkillHdl:OnSkillEnd(self._Params.SkillId, true, true)
	end
end

CStopSkillEvent.Commit()
return CStopSkillEvent
