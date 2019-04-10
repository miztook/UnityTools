local Lplus = require "Lplus"

local GainNewSkillEvent = Lplus.Class("GainNewSkillEvent")
local def = GainNewSkillEvent.define

def.field("number").SkillId = 0

GainNewSkillEvent.Commit()
return GainNewSkillEvent