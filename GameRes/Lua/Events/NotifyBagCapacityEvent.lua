local Lplus = require "Lplus"

local NotifyBagCapacityEvent = Lplus.Class("NotifyBagCapacityEvent")
local def = NotifyBagCapacityEvent.define

def.field("number").Value = 0

NotifyBagCapacityEvent.Commit()
return NotifyBagCapacityEvent