local Lplus = require "Lplus"

local DebugModeEvent = Lplus.Class("DebugModeEvent")
local def = DebugModeEvent.define

def.field("boolean")._IsOpenDebug = false

DebugModeEvent.Commit()
return DebugModeEvent