local Lplus = require "Lplus"

local NotifyMoneyChangeEvent = Lplus.Class("NotifyMoneyChangeEvent")
local def = NotifyMoneyChangeEvent.define

def.field("number").ObjID = 0
def.field("string").Type = ""

NotifyMoneyChangeEvent.Commit()
return NotifyMoneyChangeEvent
