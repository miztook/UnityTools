local Lplus = require "Lplus"

local EntityDisappearEvent = Lplus.Class("EntityDisappearEvent")
local def = EntityDisappearEvent.define

def.field("number")._ObjectID = 0

EntityDisappearEvent.Commit()
return EntityDisappearEvent