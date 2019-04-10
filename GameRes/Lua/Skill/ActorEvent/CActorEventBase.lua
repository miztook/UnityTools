local Lplus = require "Lplus"

local CActorEventBase = Lplus.Class("CActorEventBase")
local def = CActorEventBase.define

def.field("table")._Event = nil
def.field("table")._Params = nil
def.field("boolean")._IsToBlockPerformSequence = false 

def.virtual().OnEvent = function(self)
end

def.virtual().OnRelease = function(self)
	self._Event = nil
	self._Params = nil
end

CActorEventBase.Commit()
return CActorEventBase
