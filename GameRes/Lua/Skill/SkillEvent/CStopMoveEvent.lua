local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CStopMoveEvent = Lplus.Extend(CSkillEventBase, "CStopMoveEvent")
local def = CStopMoveEvent.define

def.static("table","table", "=>", CStopMoveEvent).new = function (event, params)
	local obj = CStopMoveEvent()
	obj._Event = event.StopMove
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	warn("skill move end")
end

CStopMoveEvent.Commit()
return CStopMoveEvent
