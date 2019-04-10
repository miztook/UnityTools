local Lplus = require "Lplus"

local GuideEvent = Lplus.Class("GuideEvent")
local def = GuideEvent.define

def.field("number")._ID = 0
def.field("number")._BehaviourID = 0
def.field("number")._Type = 0
def.field("number")._Param = -1

GuideEvent.Commit()
return GuideEvent
