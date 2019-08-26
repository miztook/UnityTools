local Lplus = require "Lplus"

local SendUseItemEvent = Lplus.Class("SendUseItemEvent")
local def = SendUseItemEvent.define

def.field("number")._Tid = 0
def.field("number")._Slot = 0

SendUseItemEvent.Commit()
return SendUseItemEvent