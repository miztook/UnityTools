--
-- S2CGuildItems
--

local PBHelper = require "Network.PBHelper"
local Data = require "PB.data"
local CPanelUIWelfare = require"GUI.CPanelUIWelfare"
local CPanelMall = require "GUI.CPanelMall"
local CElementData = require "Data.CElementData"
local CMallUtility = require "Mall.CMallUtility"
local EFormatType = require "PB.Template".Store.EFormatType


local function OnS2CGuildItems(sender, msg)
    local itemTable = nil
    local package = game._HostPlayer._Package
	local normalPack = package._NormalPack
    if msg.ItemSrc == Data.ENUM_ITEM_SRC.OPEN_BOX then
        if msg.Items ~= nil then 
            local panelData = {}
            panelData = 
            {
                IsFromRewardTemplate = false,
                ListItem = msg.Items,
                MoneyList = msg.Moneys,
            }
            game._GUIMan:Open("CPanelLottery",panelData) 
        end
    -- elseif msg.ItemSrc == Data.ENUM_ITEM_SRC.MACHINING then
    --     if msg.Items ~= nil then 
    --         for i = 1, #msg.Items do 
    --             local tid = msg.Items[i].ItemId
    --             local itemTemp = CElementData.GetTemplate("Item", tid)
    --             if itemTemp == nil then return end
    --             local iconPath = _G.CommonAtlasDir.."Icon/" .. itemTemp.IconAtlasPath .. ".png"
    --             local Iteminfo = itemTemp.TextDisplayName .. "x" .. msg.Items[i].Count
    --             game._GUIMan:ShowIconAndTextTip(iconPath, StringTable.Get(7),RichTextTools.GetQualityText(Iteminfo, itemTemp.InitQuality))
    --         end
    --     end
    elseif msg.ItemSrc == Data.ENUM_ITEM_SRC.SPRINTGIFT or msg.ItemSrc == Data.ENUM_ITEM_SRC.PETDROP then
        if msg.Items ~= nil then
            local panelData = {}
            panelData = 
            {
                IsFromRewardTemplate = false,
                ItemSrc = msg.ItemSrc,
                ListItem = msg.Items,
                MoneyList = msg.Moneys,
            }
            local net_cb_id = 0
            local is_disconnect = false
            local cg_complete = function()
                if is_disconnect then
                    is_disconnect = false
                    return
                end
                game._GUIMan:Open("CPanelMallLottery",panelData)
                if net_cb_id > 0 then
                    game._CNetAutomicMan:UnRegistAutomicHandle(net_cb_id)
                    net_cb_id = 0
                end
            end
            local is_show_fx = true
            if msg.ItemSrc == Data.ENUM_ITEM_SRC.SPRINTGIFT then
                is_show_fx = CMallUtility.IsShowGfx(EnumDef.LocalFields.MallSkipGfx_Springift)
            else
                is_show_fx = CMallUtility.IsShowGfx(EnumDef.LocalFields.PetEggSkipGfx_PetEgg)
            end
            if is_show_fx then
                local cg_id = (msg.ItemSrc == Data.ENUM_ITEM_SRC.SPRINTGIFT and 26 or 27)
                local disconnect_cb = function()
                    is_disconnect = true
                    CGMan.StopCG()
                end

                local reconnect_cb = function()
                    --_G.OnCGFinish(false)
                    cg_complete()
                end
                if msg.ItemSrc == Data.ENUM_ITEM_SRC.SPRINTGIFT then
                    net_cb_id = game._CNetAutomicMan:RegistAutomicHandle(disconnect_cb, reconnect_cb)
                    CGMan.PlayCG(cg_id, cg_complete, 1, false)
                else
                    net_cb_id = game._CNetAutomicMan:RegistAutomicHandle(disconnect_cb, reconnect_cb)
                    CGMan.PlayCG(cg_id, cg_complete, 1, false)
                end
            else
                cg_complete()
            end
        end
    end
   

            -- local tid = msg.Items[i].ItemId
            -- local itemTemp = CElementData.GetTemplate("Item", tid)
            -- if itemTemp == nil then return end
            -- local iconPath = _G.CommonAtlasDir.."Icon/" .. itemTemp.IconAtlasPath .. ".png"
            -- local Iteminfo = itemTemp.TextDisplayName .. "x" ..	msg.Items[i].Count			
            -- game._GUIMan:ShowIconAndTextTip(iconPath, StringTable.Get(7),RichTextTools.GetQualityText(Iteminfo, itemTemp.InitQuality))
            -- local CIItem = normalPack:GetItem(tid)  -- 根据一个物品的Tid（讲道理应该是根据一个物品的slot）获取到对应物品的所有属性。
            -- if itemTable == nil then itemTable = {} end
            -- itemTable[#itemTable + 1] = CIItem



    -- if itemTable ~= nil and #itemTable > 0 then
    --     game._GUIMan:Open("CPanelGiftHint",itemTable)
    -- end
end
PBHelper.AddHandler("S2CGuildItems", OnS2CGuildItems)

local function OnS2CSprintGiftRes(sender, msg )
    if CPanelMall.Instance():IsShow() and CPanelMall.Instance()._CurrentPage._PageType == EFormatType.SprintGiftTemp then
        if msg.result == 0 then 
            CPanelMall.Instance()._CurrentPage:UpdateMaterialNum()
        else
            game._GUIMan:ShowErrorTipText(msg.result)
        end
    end
end
PBHelper.AddHandler("S2CSprintGiftRes", OnS2CSprintGiftRes)

-- 扭蛋开启界面回消息
local function OnS2CPetDropRuleSync(sender, msg )
    if CPanelMall.Instance():IsShow() and CPanelMall.Instance()._CurrentPage._PageType == EFormatType.PetDropRuleTemp then
       CPanelMall.Instance()._CurrentPage:OnS2CPetInitDataAndPanel(msg)
    end
end
PBHelper.AddHandler("S2CPetDropRuleSync", OnS2CPetDropRuleSync)

-- 扭蛋开启界面回消息
local function OnS2CPetDropRuleRes(sender, msg )
    if CPanelMall.Instance():IsShow() and CPanelMall.Instance()._CurrentPage._PageType == EFormatType.PetDropRuleTemp then
        if msg.result == 0 then 
           CPanelMall.Instance()._CurrentPage:AddNextFreeTime(msg.NextFreeTime)
        else
            game._GUIMan:ShowErrorTipText(msg.result)
        end
    end
end
PBHelper.AddHandler("S2CPetDropRuleRes", OnS2CPetDropRuleRes)

-- 碎片兑换

local function OnS2CPetSaleBuyRes(sender, msg )
    if CPanelMall.Instance():IsShow() and CPanelMall.Instance()._CurrentPage._PageType == EFormatType.PetDropRuleTemp then
        
        if msg.result == 0 then 
            CPanelMall.Instance()._CurrentPage:UpdateMoney()
        else
            game._GUIMan:ShowErrorTipText(msg.result)
        end
    end
end
PBHelper.AddHandler("S2CPetSaleBuyRes", OnS2CPetSaleBuyRes)