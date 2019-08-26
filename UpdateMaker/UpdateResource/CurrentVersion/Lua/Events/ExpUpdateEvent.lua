local Lplus = require "Lplus"
local ExpUpdateEvent = Lplus.Class("ExpUpdateEvent")
local def = ExpUpdateEvent.define

def.field("number")._OriginExp = 0
def.field("number")._CurrentExp = 0

ExpUpdateEvent.Commit()
return ExpUpdateEvent