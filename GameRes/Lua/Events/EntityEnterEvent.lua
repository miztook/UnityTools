local Lplus = require "Lplus"

local EntityEnterEvent = Lplus.Class("EntityEnterEvent")
local def = EntityEnterEvent.define

def.field("number")._MapInstanceId = 0

EntityEnterEvent.Commit()
return EntityEnterEvent
