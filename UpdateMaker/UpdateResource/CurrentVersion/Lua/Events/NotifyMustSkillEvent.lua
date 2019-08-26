local Lplus = require "Lplus"

--必杀技释放事件
local NotifyMustSkillEvent = Lplus.Class("NotifyMustSkillEvent")
local def = NotifyMustSkillEvent.define

def.field("number").ObjID = 0

NotifyMustSkillEvent.Commit()
return NotifyMustSkillEvent
