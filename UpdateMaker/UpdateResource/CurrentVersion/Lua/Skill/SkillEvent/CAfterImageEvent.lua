local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"

local CAfterImageEvent = Lplus.Extend(CSkillEventBase, "CAfterImageEvent")
local def = CAfterImageEvent.define

def.static("table", "table", "=>", CAfterImageEvent).new = function (event, params)
	local obj = CAfterImageEvent()
	obj._Event = event.AfterImage
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	CVisualEffectMan.ScreenGhost( self._Event.IntervalTime/1000 , self._Event.Lifetime/1000 , self._Event.Lasttime/1000 )
end

CAfterImageEvent.Commit()
return CAfterImageEvent
