local Lplus = require "Lplus"

local PetUpdateEvent = Lplus.Class("PetUpdateEvent")
local def = PetUpdateEvent.define

def.field("number")._ID = 0
def.field("number")._Type = 0

PetUpdateEvent.Commit()
return PetUpdateEvent