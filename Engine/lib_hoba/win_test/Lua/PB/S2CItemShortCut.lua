--
-- S2CItemShortCut  物品快捷使用
--

local PBHelper = require "Network.PBHelper"

local function OnS2CItemShortCut(sender, msg)
    -- warn("msg.ItemId == ", msg.ItemId, "msg.Src == ", msg.Src)
    local CPanelMainTips = require "GUI.CPanelMainTips"
    local param = 
    {
        ItemId = msg.ItemId,
        Index = msg.Index,
        Count = msg.Count,
        ItemSrc = msg.Src,
        IsQuestItem = false
    }
    CPanelMainTips.Instance():QuickUseTipAddNewItem(param)
end
PBHelper.AddHandler("S2CItemShortCut", OnS2CItemShortCut)