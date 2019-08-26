local Lplus = require "Lplus"
local MainPanelRedPointStateChangeEvent = Lplus.Class("MainPanelRedPointStateChangeEvent")
local def = MainPanelRedPointStateChangeEvent.define

def.field("number")._RedDotType = 0
def.field("boolean")._State = false

MainPanelRedPointStateChangeEvent.Commit()
return MainPanelRedPointStateChangeEvent