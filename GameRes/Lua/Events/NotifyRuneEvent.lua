local Lplus = require "Lplus"

local NotifyRuneEvent = Lplus.Class("NotifyRuneEvent")
local def = NotifyRuneEvent.define

-- Level:纹章升级
-- Config:纹章配置更改
def.field("string").Type = ""

NotifyRuneEvent.Commit()
return NotifyRuneEvent
