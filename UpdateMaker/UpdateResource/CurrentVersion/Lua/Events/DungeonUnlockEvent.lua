local Lplus = require "Lplus"
local DungeonUnlockEvent = Lplus.Class("DungeonUnlockEvent")
local def = DungeonUnlockEvent.define

def.field("number")._UnlockTid = 0

DungeonUnlockEvent.Commit()
return DungeonUnlockEvent
