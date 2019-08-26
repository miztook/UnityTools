local Lplus = require "Lplus"

local PackageChangeEvent = Lplus.Class("PackageChangeEvent")
local def = PackageChangeEvent.define

def.field("number").PackageType = -1
def.field("table").ItemTids = nil
def.field("table").DecomposedSlots = nil     --分解消耗的物品对应格子

PackageChangeEvent.Commit()
return PackageChangeEvent