local Lplus = require "Lplus"
local PVEMatchEvent = Lplus.Class("PVEMatchEvent")
local def = PVEMatchEvent.define

def.field("number")._Type = 0
def.field("number")._RoomID = 0
def.field("table")._Data = nil

PVEMatchEvent.Commit()
return PVEMatchEvent