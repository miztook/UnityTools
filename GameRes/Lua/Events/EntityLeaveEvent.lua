local Lplus = require "Lplus"

local EntityLeaveEvent = Lplus.Class("EntityLeaveEvent")
local def = EntityLeaveEvent.define

def.field("number")._MapInstanceId = 0

EntityLeaveEvent.Commit()
return EntityLeaveEvent