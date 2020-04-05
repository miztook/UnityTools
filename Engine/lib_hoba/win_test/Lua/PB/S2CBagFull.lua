-- 背包满了之后弹出提示字

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local function OnS2CBagFull(sender, msg)
    local template = CElementData.GetItemTemplate(msg.ItemTid)
    game._GUIMan:ShowTipText(string.format(StringTable.Get(10712), template.Name), true)
end
PBHelper.AddHandler("S2CBagFull", OnS2CBagFull)