local Lplus = require "Lplus"
local SkillTriggerEvent = Lplus.Class("SkillTriggerEvent")
local def = SkillTriggerEvent.define

def.field("number")._StateId = 0
def.field("number")._SkillId = 0
def.field("boolean")._IsBegin = true

SkillTriggerEvent.Commit()
return SkillTriggerEvent
