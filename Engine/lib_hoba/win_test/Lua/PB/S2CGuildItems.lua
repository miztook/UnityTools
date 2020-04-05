--
-- S2CGuildItems
--

local PBHelper = require "Network.PBHelper"
local Data = require "PB.data"
local CElementData = require "Data.CElementData"

local function OnS2CGuildItems(sender, msg)
    local itemTable = nil
    local package = game._HostPlayer._Package
	local normalPack = package._NormalPack

    for i = 1, #msg.Items do 
        if msg.ItemSrc == Data.ENUM_ITEM_SRC.OPEN_BOX then
            local tid = msg.Items[i].ItemId
            local itemTemp = CElementData.GetTemplate("Item", tid)
            if itemTemp == nil then return end
            local iconPath = _G.CommonAtlasDir.."Icon/" .. itemTemp.IconAtlasPath .. ".png"
            local Iteminfo = itemTemp.TextDisplayName .. "x" ..	msg.Items[i].Count			
            game._GUIMan:ShowIconAndTextTip(iconPath, StringTable.Get(7),GUITools.GetQualityText(Iteminfo, itemTemp.InitQuality))
            local CIItem = normalPack:GetItem(tid)  -- 根据一个物品的Tid（讲道理应该是根据一个物品的slot）获取到对应物品的所有属性。
            if itemTable == nil then itemTable = {} end
            itemTable[#itemTable + 1] = CIItem
        elseif msg.ItemSrc == Data.ENUM_ITEM_SRC.MACHINING then
            local tid = msg.Items[i].ItemId
            local itemTemp = CElementData.GetTemplate("Item", tid)
            if itemTemp == nil then return end
            local iconPath = _G.CommonAtlasDir.."Icon/" .. itemTemp.IconAtlasPath .. ".png"
            local Iteminfo = itemTemp.TextDisplayName .. "x" ..	msg.Items[i].Count
            game._GUIMan:ShowIconAndTextTip(iconPath, StringTable.Get(7),GUITools.GetQualityText(Iteminfo, itemTemp.InitQuality))
        end
    end

    if itemTable ~= nil and #itemTable > 0 then
        game._GUIMan:Open("CPanelGiftHint",itemTable)
    end
end
PBHelper.AddHandler("S2CGuildItems", OnS2CGuildItems)