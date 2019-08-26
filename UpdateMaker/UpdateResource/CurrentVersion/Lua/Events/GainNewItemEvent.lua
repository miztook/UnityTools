local Lplus = require "Lplus"

local GainNewItemEvent = Lplus.Class("GainNewItemEvent")
local def = GainNewItemEvent.define

def.field("table").ItemUpdateInfo = nil
def.field("number").BagType = -1

GainNewItemEvent.Commit()
return GainNewItemEvent