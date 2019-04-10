

local Lplus = require "Lplus"

local GameLogicBreakEvent = Lplus.Class("GameLogicBreakEvent")
local def = GameLogicBreakEvent.define

def.field("boolean").IsRoleChanged = false

GameLogicBreakEvent.Commit()
return GameLogicBreakEvent