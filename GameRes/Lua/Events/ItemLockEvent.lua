local Lplus = require "Lplus"

local ItemLockEvent = Lplus.Class("ItemLockEvent")
local def = ItemLockEvent.define

def.field("boolean")._IsLock = false    -- 是否是锁定
def.field("number")._BagType = 0        -- 背包类型
def.field("number")._Slot = 0           -- slot

ItemLockEvent.Commit()
return ItemLockEvent