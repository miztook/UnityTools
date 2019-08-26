local PBHelper = require "Network.PBHelper"

local function OnS2CMarketCellList(sender,msg)
    if msg.ResCode == 0 then
        game._CAuctionUtil:LoadMarketCellListData(msg.MarketType,msg.CellItems,msg.RefTime)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketCellList", OnS2CMarketCellList)

local function OnS2CMarketItemList(sender,msg)
    if msg.ResCode == 0 then
        game._CAuctionUtil:LoadMarketItemListData(msg)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketItemList", OnS2CMarketItemList)

local function OnS2CMarketPutawayInfo(sender,msg)
    if msg.ResCode == 0 then
        game._CAuctionUtil:LoadMarketPutawayInfo(msg.ItemList)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketPutawayInfo", OnS2CMarketPutawayInfo)

local function OnS2CMarketItemPutaway(send ,msg)
    if msg.ResCode == 0 then
    	game._CAuctionUtil:LoadMarketItemPutaway(msg.Item)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketItemPutaway", OnS2CMarketItemPutaway)

local function OnS2CMarketRefItemList(sender,msg)
    if msg.ResCode == 0 then
        game._CAuctionUtil:SetAuctionRefCount(msg.RefCount)
	    game._CAuctionUtil:LoadMarketRefItemList(msg.ItemList)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketRefItemList", OnS2CMarketRefItemList)

local function OnS2CMarketTakeOut(send,msg)
    if msg.ResCode == 0 then
	    if msg.ItemPos ~= nil then
		    game._CAuctionUtil:LoadMarketTakeOut(msg.ItemPos)
	    end
        game._GUIMan:ShowTipText(StringTable.Get(20404), true)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
        local CPanelAuction = require "GUI.CPanelAuction"
        if CPanelAuction.Instance():IsShow() then
            CPanelAuction.Instance():UpdatePanel()
        end
    end
end
PBHelper.AddHandler("S2CMarketTakeOut", OnS2CMarketTakeOut)

local function OnS2CMarketItemBuy(sender,msg)
    if msg.ResCode == 0 then
    	game._CAuctionUtil:LoadMarketItemBuy(msg.ResCode,msg.ItemList)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketItemBuy", OnS2CMarketItemBuy)

local function OnS2CMarketBidding(sender,msg)
    if msg.ResCode == 0 then
    	game._CAuctionUtil:LoadS2CMarketBidding(msg.ResCode,msg.Item)
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end
PBHelper.AddHandler("S2CMarketBidding", OnS2CMarketBidding)



