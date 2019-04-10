local Lplus = require "Lplus"
local EntityPKModeChangeEvent = Lplus.Class("EntityPKModeChangeEvent")
local def = EntityPKModeChangeEvent.define

def.field("number")._EntityId = 0

EntityPKModeChangeEvent.Commit()
return EntityPKModeChangeEvent