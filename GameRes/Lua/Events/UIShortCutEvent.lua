local Lplus = require "Lplus"

local UIShortCutEvent = Lplus.Class("UIShortCutEvent")
local def = UIShortCutEvent.define

def.field("number")._Type = 0
def.field("dynamic")._Data = nil

UIShortCutEvent.Commit()
return UIShortCutEvent
