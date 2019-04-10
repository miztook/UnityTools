--
-- S2CItemShortCut  物品快捷使用
--

local PBHelper = require "Network.PBHelper"

local function OnS2CItemShortCut(sender, msg)
    -- warn("S2CItemShortCut msg.ItemId == ", msg.ItemId, "msg.Src == ", msg.Src)
    local CPanelUIQuickUse = require "GUI.CPanelUIQuickUse"
    local param = 
    {
        ItemId = msg.ItemId,
        Index = msg.Index,
        Count = msg.Count,
        ItemSrc = msg.Src,
        IsQuestItem = false,
        BagType = msg.BagType,
    }
    CPanelUIQuickUse.Instance():QuickUseTipAddNewItem(param)
end
PBHelper.AddHandler("S2CItemShortCut", OnS2CItemShortCut)