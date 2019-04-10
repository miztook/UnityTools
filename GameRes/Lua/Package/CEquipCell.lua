local Lplus = require "Lplus"

local CEquipCell = Lplus.Class("CEquipCell")
local def = CEquipCell.define

def.field("number")._InforceLevel = 0
def.field("number")._SurmountLevel = 0

def.static("=>", CEquipCell).new = function ()
	local obj = CEquipCell()
	return obj
end

CEquipCell.Commit()
return CEquipCell