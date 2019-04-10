local Lplus = require "Lplus"

local NotifyCGEvent = Lplus.Class("NotifyCGEvent")
local def = NotifyCGEvent.define

-- start:开始CG
-- end:结束CG
def.field("string").Type = ""
-- 当前播放CG的AssetId
def.field("number").Id = 0

NotifyCGEvent.Commit()
return NotifyCGEvent
