local Lplus = require "Lplus"

local UISortingChangeEvent = Lplus.Class("UISortingChangeEvent")
local def = UISortingChangeEvent.define

def.field("table")._UIScript = nil

UISortingChangeEvent.Commit()
return UISortingChangeEvent