local Lplus = require "Lplus"
local ActivityMallDataChangeEvent = Lplus.Class("ActivityMallDataChangeEvent")
local def = ActivityMallDataChangeEvent.define

def.field("dynamic")._Data = false

ActivityMallDataChangeEvent.Commit()
return ActivityMallDataChangeEvent