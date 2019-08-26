local Lplus = require "Lplus"

local NotifyPowerSavingEvent = Lplus.Class("NotifyPowerSavingEvent")
local def = NotifyPowerSavingEvent.define

--Dead, BagFull, LevelUp, TeamInv, Activity,Dungeon
def.field("string").Type = ""
def.field("dynamic").Param1 = nil
def.field("dynamic").Param2 = nil

NotifyPowerSavingEvent.Commit()
return NotifyPowerSavingEvent