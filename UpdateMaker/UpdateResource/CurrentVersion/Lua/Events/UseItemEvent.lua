local Lplus = require "Lplus"

local UseItemEvent = Lplus.Class("UseItemEvent")
local def = UseItemEvent.define

def.field("number")._ID = 0
def.field("number")._ItemType = 0

UseItemEvent.Commit()
return UseItemEvent