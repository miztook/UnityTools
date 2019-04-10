local Lplus = require "Lplus"
local CombatStateChangeEvent = Lplus.Class("CombatStateChangeEvent")
local def = CombatStateChangeEvent.define

def.field("boolean")._IsInCombatState = false
def.field("number")._CombatType = 0 -- 0 client 1 server

CombatStateChangeEvent.Commit()
return CombatStateChangeEvent