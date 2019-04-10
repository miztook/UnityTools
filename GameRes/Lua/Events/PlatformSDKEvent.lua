local Lplus = require "Lplus"
local PlatformSDKEvent = Lplus.Class("PlatformSDKEvent")
local def = PlatformSDKEvent.define

def.field("number")._Type = 0
def.field("dynamic")._Param = true

PlatformSDKEvent.Commit()
return PlatformSDKEvent