local Lplus = require "Lplus"
local ShowMainUIEvent = Lplus.Class("ShowMainUIEvent")
local def = ShowMainUIEvent.define

def.field("boolean")._IsShow = false

ShowMainUIEvent.Commit()
return ShowMainUIEvent