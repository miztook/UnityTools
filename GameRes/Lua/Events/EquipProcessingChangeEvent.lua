local Lplus = require "Lplus"
local EquipProcessingChangeEvent = Lplus.Class("EquipProcessingChangeEvent")
local def = EquipProcessingChangeEvent.define


def.field("table")._Msg = BlankTable
def.field("number")._Type = 0

EquipProcessingChangeEvent.Commit()
return EquipProcessingChangeEvent