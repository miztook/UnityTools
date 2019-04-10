local Lplus = require "Lplus"

local EntityCombatStateEvent = Lplus.Class("EntityCombatStateEvent")
local def = EntityCombatStateEvent.define

def.field("number")._EntityId = 0
def.field("number")._CombatState = 0

EntityCombatStateEvent.Commit()
return EntityCombatStateEvent