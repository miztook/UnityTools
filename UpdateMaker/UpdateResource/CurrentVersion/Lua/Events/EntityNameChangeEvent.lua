local Lplus = require "Lplus"
local EntityNameChangeEvent = Lplus.Class("EntityNameChangeEvent")
local def = EntityNameChangeEvent.define

def.field("number")._EntityId = 0

EntityNameChangeEvent.Commit()
return EntityNameChangeEvent