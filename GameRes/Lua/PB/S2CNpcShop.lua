local PBHelper = require "Network.PBHelper"
local CPanelNpcShop = require"GUI.CPanelNpcShop"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local ENpcSaleType = require"PB.data".ENpcSaleType
local CQuest = require "Quest.CQuest"
local ServerMessageBase = require "PB.data".ServerMessageBase
local CElementData = require "Data.CElementData"

local function OnS2CNpcSaleSyncRes(sender,msg)
	if CPanelNpcShop.Instance():IsShow() then 
		CPanelNpcShop.Instance():UpdateSubShopBuyInfoData(msg.Info)
	end
end
PBHelper.AddHandler("S2CNpcSaleSyncRes", OnS2CNpcSaleSyncRes)

local function OnS2CNpcSaleBuyRes(sender,msg)
	if CPanelNpcShop.Instance():IsShow() then 
		CPanelNpcShop.Instance():LoadReFreshItems(msg)
	end

    local item_id = 0
    local allIDs = GameUtil.GetAllTid("NpcSale")
	for i,v in pairs(allIDs) do
		repeat
			local shopItem = CElementData.GetTemplate("NpcSale", v) 
            if shopItem.IsNotShow then break end
            if shopItem.Id ~= msg.NpcSaleTid then break end
            if shopItem.NpcSaleSubs then
                for i1,v1 in ipairs(shopItem.NpcSaleSubs) do
                    repeat
                        if v1.Id ~= msg.SubId then break end
                        if v1.IsNotShow then break end
                        if v1.NpcSaleType == ENpcSaleType.Level then 
				            if game._HostPlayer._InfoData._Level < v1.NpcSaleParam then break end
			            end
			            if v1.NpcSaleType == ENpcSaleType.Guild then 
				            if not game._GuildMan:IsHostInGuild() then break end 
			            end
                        if v1.NpcSaleItems then
                            for i2,v2 in ipairs(v1.NpcSaleItems) do
                                repeat
                                    if v2.Id ~= msg.DetailId then break end
                                    local itemTemp = CElementData.GetItemTemplate(v2.ItemId)
                                    local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
                                    if profMask ~= bit.band(itemTemp.ProfessionLimitMask, profMask) then 
						                break
					                end
                                    item_id = v2.ItemId
                                until true;
                            end
                        end
                    until true;
                end
            end
		until true
	end

    if item_id > 0 then
	    if msg.ErrorCode == ServerMessageBase.BagFull then
		    if CQuestAutoMan.Instance():IsOn() then
                local curQuestId = CQuestAutoMan.Instance():GetCurQuestId()
			    local is_buy, quest_item_id = CQuest.Instance():IsQuest2BuyItem(curQuestId) 
			    if is_buy and quest_item_id == item_id then
				    CQuestAutoMan.Instance():Stop()
                    CAutoFightMan.Instance():Stop()
			    end
		    end
	    end
    else
        warn("没有找到购买物品的模板数据")
    end
end
PBHelper.AddHandler("S2CNpcSaleBuyRes", OnS2CNpcSaleBuyRes)

-- 错误码
local function ErrorTip(ErrorCode)
    game._GUIMan:ShowErrorTipText(ErrorCode)
end

local function OnS2CNpcSaleRandomRefresh(sender,msg)
    if msg.ErrorCode == 0 then
--        CPanelNpcShop.Instance():UpdateSubShopBuyInfoData(msg.Info)
    else
        ErrorTip(msg.ErrorCode)
    end
end
PBHelper.AddHandler("S2CNpcSaleRandomRefreshRes", OnS2CNpcSaleRandomRefresh)
