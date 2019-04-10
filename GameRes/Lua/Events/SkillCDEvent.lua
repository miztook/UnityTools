local Lplus = require "Lplus"

local SkillCDEvent = Lplus.Class("SkillCDEvent")
local def = SkillCDEvent.define

def.field("number")._ID = 0
def.field("number")._AccumulateCount = 0
def.field("number")._Elapsed = 0
def.field("number")._Max = 0

SkillCDEvent.Commit()
return SkillCDEvent
