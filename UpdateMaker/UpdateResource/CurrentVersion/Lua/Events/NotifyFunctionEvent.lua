local Lplus = require "Lplus"

local NotifyFunctionEvent = Lplus.Class("NotifyFunctionEvent")
local def = NotifyFunctionEvent.define

def.field("number").FunID = 0

NotifyFunctionEvent.Commit()
return NotifyFunctionEvent
