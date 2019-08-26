local Lplus = require "Lplus"
local EntityEvilNumChangeEvent = Lplus.Class("EntityEvilNumChangeEvent")
local def = EntityEvilNumChangeEvent.define

def.field("number")._EntityId = 0

EntityEvilNumChangeEvent.Commit()
return EntityEvilNumChangeEvent