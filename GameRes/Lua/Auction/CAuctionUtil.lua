local Lplus = require "Lplus"
local CElementSkill = require "Data.CElementSkill"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelAuction = require"GUI.CPanelAuction"
local CPanelAuctionSell1 = require "GUI.CPanelAuctionSell1"
local CAuctionUtil = Lplus.Class("CAuctionUtil")
local def = CAuctionUtil.define

def.field("table")._AllItemID = nil
def.field('table')._TemplateData = nil
def.field("table")._SellItems = nil

def.field("number")._BuyItemID = 0
def.field("number")._BuyItemPos = 0
def.field("number")._RefCount = 0
def.field("number")._AuctionRefCount = 0    --拍卖行的刷新次数
def.field("table")._BuyItemList = BlankTable
def.field("table")._CurrentBigTypeData= BlankTable
def.field("table")._PutawaryItemsData = BlankTable

def.static("=>", CAuctionUtil).new = function ()
    local obj = CAuctionUtil()
    return obj
end

local ParseMarketItems = function(items, productId)
    local new_table = {}
    local selected_table = {}
    for i,v in ipairs(items) do
        local item = {}
        item.ItemID = v.ItemID
        item.ItemNum = v.ItemNum
        item.Price = v.Price
        item.StartPrice = v.StartPrice
        item.FixedPrice = v.FixedPrice
        item.PutawayTime = v.PutawayTime
        item.ItemPos = v.ItemPos
        item.Duration = v.Duration
        item.Bidder = v.Bidder
        item.OwnerId = v.OwnerId
        item.ShareHolder = v.ShareHolder
        item.Item = v.Item
        item.Added = false
        new_table[#new_table + 1] = item
    end
    local market_temp = CElementData.GetTemplate("MarketItem", productId)
    local limitCount = market_temp == nil and 0 or market_temp.MaxCellNum
    if limitCount > 0 and #new_table > limitCount then
        for i = 1,limitCount do
            local default = 2^53
            local index = -1
            for i1,v in ipairs(new_table) do
                if v.Added == false and v.Price < default then
                    default = v.Price
                    index = i1
                end
            end
            if index > 0 then
                selected_table[#selected_table + 1] = new_table[index]
                new_table[index].Added = true
            end
        end
    else
        selected_table = new_table
    end
    return selected_table
end

local ParseCellItems = function(items)
    local new_items = {}
    for i,v in ipairs(items) do
        local item = {}
        item.ItemID = v.ItemID
        item.ItemNum = v.ItemNum
        item.ProductId = v.ProductId
        new_items[#new_items + 1] = item
    end
    return new_items
end

--检索当前大标签下的所有ItemID 得到小标签下的Item
def.method("number","number","number").GetSmallTabListData = function (self,marketType,smallTypeID,refTime) 
    local tm = {}
    local itemIDs = self._TemplateData[marketType]  
    for _,v1 in ipairs(self._CurrentBigTypeData) do 
        if itemIDs[v1.ItemID].SmallTypeID == smallTypeID and v1.ItemNum > 0 then
            table.insert(tm,v1)
        end
    end
    local items = self:SortAscending(tm, 1) 
    CPanelAuction.Instance():UpdataBuyListItemDataFirst(items,refTime)
end
--检索当前大标签下的所有ItemID 得到小标签下的Item
def.method("number","number","number").GetGuildSmallTabListData = function (self,marketType,smallTypeID,refTime) 
    local tm = {} 
    local itemIDs = self._TemplateData[marketType]  
    local bigType = CPanelAuction.Instance()._CurrentSelectBigTabId
    for _,v1 in ipairs(self._CurrentBigTypeData) do 
        if itemIDs[v1.ItemID] and itemIDs[v1.ItemID].SmallTypeID == smallTypeID and itemIDs[v1.ItemID].BigTypeID == bigType and v1.ItemNum > 0 then
            table.insert(tm,v1)
        end
    end
    local items = self:SortAscending(tm,1) 
    CPanelAuction.Instance():UpdataBuyListItemDataFirst(items,refTime)
end

--默认控制item按Id 价格，竞价升序排序
def.method("table","number","=>","table").SortAscending = function (self,items,key)
    local ps = {"ItemID","Price","StartPrice","PutawayTime", "ItemPos"}
    local propertyName = ps[key] -- 默认为ItemID排序
    local function sort_func(itm1,itm2)
       if itm1[propertyName] < itm2[propertyName] then
           return true
       else
            if itm1[propertyName] == itm2[propertyName] then
                if itm1["PutawayTime"] == nil or itm2["PutawayTime"] == nil then
                    return false
                else
                    return itm1["PutawayTime"] < itm2["PutawayTime"]
                end
            else
                return false
            end
       end
    end
    table.sort(items,sort_func)
    return items
    -- body
end
--处理模板数据
def.method().LoadAllMarketItemData = function (self)
    if self._AllItemID ~= nil then return end

    self._AllItemID = {}
    self._TemplateData = {}
    self._SellItems = {}

    local allIds = CElementData.GetAllTid("MarketItem")
    for _,v in pairs(allIds) do
        local marketItem = CElementData.GetTemplate("MarketItem", v) 
        self._AllItemID[marketItem.Id] = {}
        self._AllItemID[marketItem.Id].MinPrice = marketItem.MinPrice
        self._AllItemID[marketItem.Id].MaxPrice = marketItem.MaxPrice 
        self._AllItemID[marketItem.Id].ItemID = marketItem.ItemId
    end 

    for i = 1 ,3 do 
        local temp1 = {}
        local temp2 = {}
        local templateData = CElementData.GetMarketTemplate(i)
        for _,v1 in ipairs(templateData.UIBigTypes) do
            local bigTypeID = v1.Id
            for _,v2 in ipairs(v1.UISmallTypes) do
                local smallTypeID = v2.Id
                if not IsNilOrEmptyString(v2.SellItems) then
                    local sellItemIDs = string.split(v2.SellItems,'*')
                    for _,v3 in ipairs(sellItemIDs) do
                        local j = tonumber(v3)
                        table.insert(temp2,j)
                        temp1[self._AllItemID[j].ItemID] = {}
                        temp1[self._AllItemID[j].ItemID].MarketItemID = j
                        temp1[self._AllItemID[j].ItemID].BigTypeID = bigTypeID
                        temp1[self._AllItemID[j].ItemID].SmallTypeID = smallTypeID
                        temp1[self._AllItemID[j].ItemID].MinPrice = self._AllItemID[j].MinPrice
                        temp1[self._AllItemID[j].ItemID].MaxPrice = self._AllItemID[j].MaxPrice
                    end
                end
            end
        end
        self._TemplateData[i] = temp1
        self._SellItems[i] = temp2
    end
end

def.method().ClearAllMarketItemData = function (self)
    self._AllItemID = nil
    self._TemplateData = nil
    self._SellItems = nil
end

def.method("number").SetRefCount = function(self, count)
    self._RefCount = count
end

-- 通过ItemID找到交易所的商品ID
def.method("number", "=>", "number").GetMarketItemIDByItemID = function(self, itemID)
    for k,v in pairs(self._AllItemID) do 
        if v.ItemID == itemID then
            return k
        end
    end
    return -1
end

--获取拍卖行刷新次数
def.method("=>", "number").GetAuctionRefCount = function(self)
    return self._AuctionRefCount
end

--设置拍卖行刷新次数
def.method("number").SetAuctionRefCount = function(self, refCount)
    self._AuctionRefCount = refCount
end



def.method("table","table","=>","table").UpdataPutawaryOrBuyItemList = function (self,items,item)
    if items == nil then 
        table.insert(items,item)
    else
        local isInsert = true
        for i,v1 in ipairs(items) do 
            if v1.ItemPos == item.ItemPos then
                items[i] = item 
                isInsert = false
            end
        end 
        if isInsert then 
            table.insert(items,item)
        end
    end
    return items
end
def.method("number","=>","table").TakeOutItem = function (self,itemPos)
    local temp = {}
    for _,v in ipairs(self._PutawaryItemsData) do 
        if v.ItemPos ~= itemPos then
            table.insert(temp,v)
        end
    end
    return temp
end
def.method("number","table").UpdataMarketBuyItemList = function(self,marketType,itemList)  
    if marketType == CPanelAuction.Instance()._RightToggleType.EXCHANGE then 
        local items = self:SortAscending(itemList,2)
        CPanelAuction.Instance():UpdataBuyListItemDataSecond(items)   
    elseif marketType == CPanelAuction.Instance()._RightToggleType.TREASURE then 
        local items = self:SortAscending(itemList,1)
        if #items > 30 then
            for i = 31 ,#items,1 do 
                items[i] = nil
            end
        end
        CPanelAuction.Instance():UpdataBuyListItemDataSecond(items) 
    elseif marketType == CPanelAuction.Instance()._RightToggleType.GUILDAUCTION or marketType == CPanelAuction.Instance()._RightToggleType.WORLDAUCTION then 
        self._CurrentBigTypeData = itemList
        self:GetGuildSmallTabListData(marketType,CPanelAuction.Instance()._CurrentSelectSmallTabId,0)
    end                  
end

def.method().Cleanup = function(self)
    self._BuyItemList = {}
    self._CurrentBigTypeData = {}
    self._PutawaryItemsData = {}
end
-- 根据当前UI界面所处CellList还是ItemList像服务器发送数据
-- def.method("number").C2SByItemUIType = function(self,itemUIType)
--     if itemUIType == CPanelAuction.Instance()._ItemUIType.CELLLIST then 
--         SendC2SMarketCellList()
--     else
--         SendC2SMarketItemList()
--     end
-- end
--------------------------------C2S-------------------------------------------------
def.method("number","number").SendC2SMarketCellList = function (self,marketType,bigTabID)
    local C2SMarketCellList = require "PB.net".C2SMarketCellList
    local protocol = C2SMarketCellList()
    protocol.MarketType = marketType
    protocol.ItemBigType = bigTabID
    PBHelper.Send(protocol)
end

def.method("number","number").SendC2SMarketItemList = function (self,marketType,itemID)
	local C2SMarketItemList = require "PB.net".C2SMarketItemList
    local protocol = C2SMarketItemList()
    protocol.MarketType = marketType
    protocol.ItemID= itemID
    PBHelper.Send(protocol)
end
-- 上架物品
def.method("number","number","number",'number','number','number').SendC2SMarketItemPutaway = function (self,marketType,itemPos,bigTabID,basePrice,maxPrice,durationTime )
    local C2SMarketItemPutaway = require "PB.net".C2SMarketItemPutaway
    local protocol = C2SMarketItemPutaway()
    protocol.MarketType = marketType
    protocol.ItemPos= itemPos
    protocol.ItemNum = bigTabID
    if basePrice > 0  then
        protocol.BasePrice = basePrice
    end
    if maxPrice > 0 then 
        protocol.MaxPrice = maxPrice
    end
    if durationTime >0 then 
        protocol.DurationTime = durationTime
    end
    PBHelper.Send(protocol)
end
-- 上架物品信息
def.method("number").SendC2SMarketPutawayInfo = function (self,marketType) 
	local C2SMarketPutawayInfo = require"PB.net".C2SMarketPutawayInfo
	local protocol = C2SMarketPutawayInfo()
	protocol.MarketType = marketType
    PBHelper.Send(protocol)
end
--刷新
def.method('number','number','boolean').SendC2SMarketRefItemList = function (self,marketType,bigTypeID,isDiamondRef)
    local C2SMarketRefItemList = require"PB.net".C2SMarketRefItemList
    local protocol = C2SMarketRefItemList()
    protocol.MarketType = marketType
    protocol.BigType = bigTypeID
    protocol.IsDiamondRef = isDiamondRef
    PBHelper.Send(protocol)
end
--下架物品
def.method("number","number").SendC2SMarketItemTakeOut = function (self,marketType,itemPos)
    local C2SMarketItemTakeOut = require"PB.net".C2SMarketItemTakeOut
    local protocol = C2SMarketItemTakeOut()
    protocol.MarketType = marketType
    protocol.ItemPos = itemPos
    PBHelper.Send(protocol)
    -- body
end
--购买
def.method("number","number","number").SendC2SMarketItemBuy = function (self,marketType,itemPos,buyNum)
    local C2SMarketItemBuy = require"PB.net".C2SMarketItemBuy
    local protocol = C2SMarketItemBuy()
    protocol.MarketType = marketType
    protocol.ItemPos = itemPos
    protocol.BuyNum = buyNum
    PBHelper.Send(protocol)
    -- body
end
--竞价
def.method("number","number","number").SendC2SMarketBidding = function (self,marketType,itemPos,price)
    local C2SMarketBidding = require"PB.net".C2SMarketBidding
    local protocol = C2SMarketBidding()
    protocol.MarketType = marketType
    protocol.ItemPos = itemPos
    protocol.Price = price 
    PBHelper.Send(protocol)
    -- body
end

----------------------------------------------S2C-------------------------
def.method("number","table","number").LoadMarketCellListData = function (self,marketType,cellItems,refTime)
    if CPanelAuction.Instance():IsShow() and CPanelAuction.Instance()._CurrentRightToggle == marketType  then
        self._CurrentBigTypeData = ParseCellItems(cellItems)
        self:GetSmallTabListData(marketType,CPanelAuction.Instance()._CurrentSelectSmallTabId,refTime) 
    end
end
 
def.method("table").LoadMarketItemListData = function (self,msg)
    local marketType = msg.MarketType
    local productId = msg.ProductId
    if CPanelAuction.Instance():IsShow() and CPanelAuction.Instance()._CurrentRightToggle == marketType then  
        self._BuyItemList = ParseMarketItems(msg.ItemList, productId)
        self: UpdataMarketBuyItemList(marketType,self._BuyItemList)
    end
end
--加载从服务器端传来的单个Item上架信息数据
def.method("table").LoadMarketItemPutaway = function(self,item)
    if item == nil or not CPanelAuction.Instance():IsShow() then return end
    self._PutawaryItemsData = self:UpdataPutawaryOrBuyItemList(self._PutawaryItemsData,item)
    CPanelAuction.Instance():UpdataSellBagItemShow()
    CPanelAuction.Instance():UpdataSellListItemData(self._PutawaryItemsData)
end
def.method("table").LoadMarketPutawayInfo = function (self,itemList)
    self._PutawaryItemsData = itemList
    if CPanelAuction.Instance():IsShow() then
        CPanelAuction.Instance():UpdataSellListItemData(self._PutawaryItemsData)
    end
end
-- 刷新交易所
def.method("table").LoadMarketRefItemList = function (self,itemList)
    if CPanelAuction.Instance():IsShow() then
        self._CurrentBigTypeData = itemList
        --self:GetSmallTabListData(marketType,CPanelAuction.Instance()._CurrentSelectSmallTabId,refTime) 
        self:SendC2SMarketCellList(CPanelAuction.Instance()._CurrentRightToggle,CPanelAuction.Instance()._CurrentSelectBigTabId)
    end
end
def.method("number").LoadMarketTakeOut = function(self,itemPos)
    if CPanelAuction.Instance():IsShow() then
        CPanelAuction.Instance():UpdataSellBagItemShow()
        self._PutawaryItemsData = self:TakeOutItem(itemPos)
        CPanelAuction.Instance():UpdataSellListItemData(self._PutawaryItemsData)
    end
end
def.method("number","table").LoadMarketItemBuy = function(self,resCode,itemList)
    if CPanelAuction.Instance():IsShow() then
        if resCode == 0 then 
            CPanelAuction.Instance():SuccessBuy()
        elseif resCode == 526 then
            CPanelAuction.Instance():FailBuy(resCode)
        end
    end
end
def.method("number","table").LoadS2CMarketBidding = function (self,resCode,item)
    CPanelAuction.Instance()._IsOnClickSortButton = false
    if CPanelAuction.Instance():IsShow() then
        if resCode == 0 then 
            CPanelAuction.Instance():SuccessBuy()
        else
            CPanelAuction.Instance():FailBuy(resCode)
        end
    end
end
CAuctionUtil.Commit()
return CAuctionUtil