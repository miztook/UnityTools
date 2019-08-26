local Lplus = require "Lplus"
local ShowDressEvent = Lplus.Class("ShowDressEvent")
local def = ShowDressEvent.define

def.field("boolean")._DressShowEnable = false
def.field("number")._DressSlot = 0

ShowDressEvent.Commit()
return ShowDressEvent