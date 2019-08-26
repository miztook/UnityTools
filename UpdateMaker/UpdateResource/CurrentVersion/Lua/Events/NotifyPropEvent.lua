local Lplus = require "Lplus"

local NotifyPropEvent = Lplus.Class("NotifyPropEvent")
local def = NotifyPropEvent.define

def.field("number").ObjID = 0

NotifyPropEvent.Commit()
return NotifyPropEvent