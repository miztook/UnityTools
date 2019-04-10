local Lplus = require "Lplus"
local CountGroupUpdateEvent = Lplus.Class("CountGroupUpdateEvent")
local def = CountGroupUpdateEvent.define

def.field("number")._CountGroupTid = 0

CountGroupUpdateEvent.Commit()
return CountGroupUpdateEvent
