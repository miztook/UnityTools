local Lplus = require "Lplus"

local NotifyShopEvent = Lplus.Class("NotifyShopEvent")
local def = NotifyShopEvent.define

--All:全部UI刷新
--View:打开出售列表
--Buy:购买相应物品
def.field("string").Type = ""

NotifyShopEvent.Commit()
return NotifyShopEvent
