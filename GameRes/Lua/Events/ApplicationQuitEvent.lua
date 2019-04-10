local Lplus = require "Lplus"
local ApplicationQuitEvent = Lplus.Class("ApplicationQuitEvent")
local def = ApplicationQuitEvent.define

def.field("dynamic")._Data = false

ApplicationQuitEvent.Commit()
return ApplicationQuitEvent