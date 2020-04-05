local PBHelper = require "Network.PBHelper"

local function OnS2CMarketCellList(sender,msg)
	game._CAuctionUtil:LoadMarketCellListData(msg.MarketType,msg.CellItems,msg.RefTime)
end
PBHelper.AddHandler("S2CMarketCellList", OnS2CMarketCellList)

local function OnS2CMarketItemList(sender,msg)
	game._CAuctionUtil:LoadMarketItemListData(msg.MarketType,msg.ItemList)
end
PBHelper.AddHandler("S2CMarketItemList", OnS2CMarketItemList)

local function OnS2CMarketPutawayInfo(sender,msg)
	game._CAuctionUtil:LoadMarketPutawayInfo(msg.ItemList)
end
PBHelper.AddHandler("S2CMarketPutawayInfo", OnS2CMarketPutawayInfo)

local function OnS2CMarketItemPutaway(send ,msg)
	game._CAuctionUtil:LoadMarketItemPutaway(msg.Item)
end
PBHelper.AddHandler("S2CMarketItemPutaway", OnS2CMarketItemPutaway)

local function OnS2CMarketRefItemList(sender,msg)
	game._CAuctionUtil:LoadMarketRefItemList(msg.ItemList)
end
PBHelper.AddHandler("S2CMarketRefItemList", OnS2CMarketRefItemList)

local function OnS2CMarketTakeOut(send,msg)
	if msg.ItemPos ~= nil then
		game._CAuctionUtil:LoadMarketTakeOut(msg.ItemPos)
	end
end
PBHelper.AddHandler("S2CMarketTakeOut", OnS2CMarketTakeOut)

local function OnS2CMarketItemBuy(sender,msg)
	game._CAuctionUtil:LoadMarketItemBuy(msg.ResCode,msg.ItemList)
end
PBHelper.AddHandler("S2CMarketItemBuy", OnS2CMarketItemBuy)

local function OnS2CMarketBidding(sender,msg)
	game._CAuctionUtil:LoadS2CMarketBidding(msg.ResCode,msg.Item)
end
PBHelper.AddHandler("S2CMarketBidding", OnS2CMarketBidding)



