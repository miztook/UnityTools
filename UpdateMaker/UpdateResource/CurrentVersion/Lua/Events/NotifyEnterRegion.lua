local Lplus = require "Lplus"

local NotifyEnterRegion = Lplus.Class("NotifyEnterRegion")
local def = NotifyEnterRegion.define

--RegionID:进入的区域ID 
def.field("number").RegionID = 0
def.field("boolean").IsEnter = true

NotifyEnterRegion.Commit()
return NotifyEnterRegion
