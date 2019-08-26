local Lplus = require "Lplus"

local BuffChangeEvent = Lplus.Class("BuffChangeEvent")
local def = BuffChangeEvent.define

def.field("boolean")._IsAdd = false
def.field("number")._EntityID = 0
def.field("number")._BuffID = 0

BuffChangeEvent.Commit()
return BuffChangeEvent