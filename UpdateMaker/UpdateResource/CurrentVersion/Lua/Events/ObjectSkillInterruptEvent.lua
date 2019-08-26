local Lplus = require "Lplus"

local ObjectSkillInterruptEvent = Lplus.Class("ObjectSkillInterruptEvent")
local def = ObjectSkillInterruptEvent.define

def.field("number")._ObjectID = 0
def.field("number")._SkillID = 0

ObjectSkillInterruptEvent.Commit()
return ObjectSkillInterruptEvent