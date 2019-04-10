local Lplus = require "Lplus"
local ElsePlayerLevelChangeEvent = Lplus.Class("ElsePlayerLevelChangeEvent")
local def = ElsePlayerLevelChangeEvent.define

def.field("number")._EntityId = 0

ElsePlayerLevelChangeEvent.Commit()
return ElsePlayerLevelChangeEvent