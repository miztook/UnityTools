local Lplus = require "Lplus"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"

local CActorJudgeEvent = Lplus.Extend(CActorEventBase, "CActorJudgeEvent")
local def = CActorJudgeEvent.define

def.static("table", "table", "=>", CActorJudgeEvent).new = function (event, params)
	local obj = CActorJudgeEvent()
	obj._Event = event.Judgement
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	-- local caster = self._Params.BelongedCreature
	-- if caster ~= nil and caster._SkillHdl ~= nil then
	-- 	if caster:IsHostPlayer() then
	-- 		warn("CActorJudgeEvent attacker._SkillHdl._ClientCalcVictims = nil ")
	-- 	end

	-- end
end

CActorJudgeEvent.Commit()
return CActorJudgeEvent
