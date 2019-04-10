local Lplus = require "Lplus"

local EquipChangeCompleteEvent = Lplus.Class("EquipChangeCompleteEvent")
local def = EquipChangeCompleteEvent.define

def.field("number")._PlayerId = 0

EquipChangeCompleteEvent.Commit()
return EquipChangeCompleteEvent