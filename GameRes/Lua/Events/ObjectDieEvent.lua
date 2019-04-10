local Lplus = require "Lplus"

local ObjectDieEvent = Lplus.Class("ObjectDieEvent")
local def = ObjectDieEvent.define

def.field("number")._ObjectID = 0

ObjectDieEvent.Commit()
return ObjectDieEvent