local Lplus = require "Lplus"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"

local CActorAdsorbEvent = Lplus.Extend(CActorEventBase, "CActorAdsorbEvent")
local def = CActorAdsorbEvent.define

def.static("table", "table", "=>", CActorAdsorbEvent).new = function (event, params)
	local obj = CActorAdsorbEvent()
	obj._Event = event.Audio
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	--warn("capture target")
end

CActorAdsorbEvent.Commit()
return CActorAdsorbEvent
