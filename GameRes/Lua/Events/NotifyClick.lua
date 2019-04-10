local Lplus = require "Lplus"

local NotifyClick = Lplus.Class("NotifyClick")
local def = NotifyClick.define

def.field("dynamic")._Param = nil

NotifyClick.Commit()
return NotifyClick