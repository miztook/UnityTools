local Lplus = require "Lplus"

local ManualDataChangeEvent = Lplus.Class("ManualDataChangeEvent")
local def = ManualDataChangeEvent.define

def.field("number")._ID = 0
def.field("number")._Type = 0
def.field("table")._Data = nil
ManualDataChangeEvent.Commit()
return ManualDataChangeEvent
