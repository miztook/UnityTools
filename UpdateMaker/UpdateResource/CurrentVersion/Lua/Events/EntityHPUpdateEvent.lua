local Lplus = require "Lplus"
local EntityHPUpdateEvent = Lplus.Class("EntityHPUpdateEvent")
local def = EntityHPUpdateEvent.define

def.field("number")._EntityId = 0

EntityHPUpdateEvent.Commit()
return EntityHPUpdateEvent