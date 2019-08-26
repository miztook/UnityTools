-- 背包满了之后弹出提示字

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local function OnS2CBagFull(sender, msg)
    if msg.ItemTid == 0 then game._GUIMan:ShowTipText(StringTable.Get(20436), true) return end  -- Tid为0，只提示背包已满。
    local template = CElementData.GetItemTemplate(msg.ItemTid)
    if template ~= nil then
        game._GUIMan:ShowTipText(string.format(StringTable.Get(10712), template.Name), true)
    else
        game._GUIMan:ShowTipText(string.format(StringTable.Get(10712), tostring(msg.ItemTid)), true)
    end
    
end
PBHelper.AddHandler("S2CBagFull", OnS2CBagFull)