local Lplus = require "Lplus"

local NotifyChargeEvent = Lplus.Class("NotifyChargeEvent")
local def = NotifyChargeEvent.define

def.field("number").SkillId = 0
def.field("boolean").Is2StartCharging = true
def.field("number").BeginTime = 0
def.field("number").MaxChargeTime = 0

NotifyChargeEvent.Commit()
return NotifyChargeEvent