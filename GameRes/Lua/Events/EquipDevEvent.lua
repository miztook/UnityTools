local Lplus = require "Lplus"
local EquipDevEvent = Lplus.Class("EquipDevEvent")
local def = EquipDevEvent.define

def.field("table")._Msg = nil
def.field("boolean")._IsRebuildSave = false

EquipDevEvent.Commit()
return EquipDevEvent