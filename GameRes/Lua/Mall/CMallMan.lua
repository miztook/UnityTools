local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local GainNewItemEvent = require "Events.GainNewItemEvent"
local NotifyFunctionEvent = require "Events.NotifyFunctionEvent"
local ApplicationQuitEvent = require "Events.ApplicationQuitEvent"
local CMallUtility = require "Mall.CMallUtility"
local CGame = Lplus.ForwardDeclare("CGame")
local EPlatformType = require "PB.data".EPlatformType
local EFormatType = require "PB.Template".Store.EFormatType
local EGoodsType = require "PB.Template".Goods.EGoodsType
local CMallMan = Lplus.Class("CMallMan")
local def = CMallMan.define
local instance = nil

def.static("=>", CMallMan).Instance = function()
	if instance == nil then
		instance = CMallMan()
	end
	return instance
end

def.field("number")._RefreshTime = 0                    -- 定义页签刷新的时间戳
def.field("table")._MallRoleInfo = nil                  -- 角色商城数据(对应net.proto的RoleStoreDB里面的StoreDatas)
def.field("table")._TabDatasFromServer = BlankTable     -- 从server请求的页签数据(或者是CMallMan里面的缓存数据)
def.field("boolean")._IsMallRoleInfoInited = false      -- 商城角色数据是否已经初始化了
def.field("number")._TotalUnlockTid = 80                -- 召唤解锁id
def.field("number")._ElfUnlockTid = 10                  -- 精灵献礼解锁ID
def.field("number")._PetExtractUnlockTid = 75           -- 宠物解锁ID

def.method("=>", "table").GetTagsDataFromServer = function(self)
    return self._TabDatasFromServer
end

def.method("number").RemoveTagsDataFromServer = function(self, StoreId)
    for i,v in ipairs(self._TabDatasFromServer.StoreTagFounds) do
        for j,w in ipairs(v.Stores) do
            if w.StoreId == StoreId then
                local remove_tag = false
                if #v.Stores <= 1 then
                    remove_tag = true
                end
                table.remove(v.Stores, j)
                if remove_tag then
                    table.remove(self._TabDatasFromServer.StoreTagFounds, i)
                end
                return
            end
        end
    end
end

local OnGainNewItemEvent = function(sender, event)
    if instance ~= nil then
        local can_extract = (CMallUtility.CanExtractElf() and game._CFunctionMan:IsUnlockByFunTid(instance._ElfUnlockTid) and game._CFunctionMan:IsUnlockByFunTid(instance._TotalUnlockTid))
        CMallMan.Instance():SaveRedPointState(EnumDef.MallStoreType.ElfExtract, can_extract)
        local CPanelMall = require "GUI.CPanelMall"
        if CPanelMall.Instance():IsShow() then
            for _,v in ipairs(instance._TabDatasFromServer.StoreTagFounds) do
                for _1,v1 in ipairs(v.Stores) do
                    if v1.StoreId == EnumDef.MallStoreType.ElfExtract then
                        CPanelMall.Instance():ShowRedPoint(v.TagId, v1.StoreId, can_extract)
                    end
                end
            end
            CPanelMall.Instance():OnGainNewItem(sender, event)
        end
    end
end

local OnSystemUnlockEvent = function(sender, event)
    if instance ~= nil then
        local id = event.FunID
        if id == instance._ElfUnlockTid and game._CFunctionMan:IsUnlockByFunTid(instance._TotalUnlockTid) then
            instance:SaveRedPointState(EnumDef.MallStoreType.ElfExtract, CMallUtility.CanExtractElf())
        end
    end
end

local OnApplicationQuit = function(sender, event)
    instance:Release()
end

def.method().Init = function(self)
    CGame.EventManager:addHandler(GainNewItemEvent, OnGainNewItemEvent)
    CGame.EventManager:addHandler(NotifyFunctionEvent, OnSystemUnlockEvent)
    CGame.EventManager:addHandler(ApplicationQuitEvent, OnApplicationQuit)
end

def.method("number", "number", "=>", "table").GetTagDataByTagIDAndStoreID = function(self, tagID, storeID)
    if self._TabDatasFromServer == BlankTable then
        warn("商城页签数据为空")
        return nil 
    end
    for _,v in ipairs(self._TabDatasFromServer.StoreTagFounds) do
        for _1,v1 in ipairs(v.Stores) do
            if v.TagId == tagID and v1.StoreId == storeID then
                return v1
            end
        end
    end
    return nil
end

--通过StoreID和itemID获得物品的购买次数
def.method("number", "number", "=>", "number").GetItemHasBuyCountByID = function(self, storeID, itemID)
    if self._MallRoleInfo == nil then return 0 end
    for _,v in ipairs(self._MallRoleInfo.RoleStoreData.StoreDatas) do
        if v.StoreId == storeID then
            for i1,v1 in ipairs(v.GoodsDatas) do
                if v1.GoodsId == itemID then
                    return v1.BuyCount
                end
            end
        end
    end
    return 0
end

--通过StoreID和itemID设置物品的购买次数
def.method("number", "number", "number", "=>", "boolean").SetItemHasBuyCountByID = function(self, storeID, itemID, count)
    if self._MallRoleInfo == nil or self._MallRoleInfo.RoleStoreData == nil then return false end
    for _,v in ipairs(self._MallRoleInfo.RoleStoreData.StoreDatas) do
        if v.StoreId == storeID then
            for i1,v1 in ipairs(v.GoodsDatas) do
                if v1.GoodsId == itemID then
                    v1.BuyCount = count
                    return true
                end
            end
        end
    end
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas + 1] = {}
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas].StoreId = storeID
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas].RefreshCount = 0
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas].GoodsDatas = {}
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas].GoodsDatas[1] = {}
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas].GoodsDatas[1].GoodsId = itemID
    self._MallRoleInfo.RoleStoreData.StoreDatas[#self._MallRoleInfo.RoleStoreData.StoreDatas].GoodsDatas[1].BuyCount = count
    return true
end

--获得商店的刷新次数
def.method("number", "=>", "number").GetStoreRefreshCountByID = function(self, storeID)
    if self._MallRoleInfo == nil then return 0 end
    for _,v in ipairs(self._MallRoleInfo.RoleStoreData.StoreDatas) do
        if v.StoreId == storeID then
            return v.RefreshCount
        end
    end
    return 0
end

--设置商店的刷新次数
def.method("number", "number").SetStoreRefreshCountByID = function(self, storeID, count)
    if self._MallRoleInfo == nil then return end
    for _,v in ipairs(self._MallRoleInfo.RoleStoreData.StoreDatas) do
        if v.StoreId == storeID then
            v.RefreshCount = count
        end
    end
end

-- 获得月卡今天能否领取
def.method("number", "=>", "boolean").CanGetMonthlyCardReward = function(self, tid)
    if self._MallRoleInfo == nil or (not self._IsMallRoleInfoInited) or self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid] == nil then 
        return false
    end
    return self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid].IsCanReward
end

-- 设置月卡今天能否领取
def.method("number", "boolean").SetGetMonthlyCardReward = function(self, tid, canReward)
    if self._MallRoleInfo == nil or (not self._IsMallRoleInfoInited) or self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid] == nil then
        return
    end
    self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid].IsCanReward = canReward
end

--红点状态信息
def.method("number", "=>", "boolean").GetRedPointState = function(self, keyID)
    local redPointMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Mall)
    if redPointMap ~= nil and redPointMap[keyID] ~= nil then
        return redPointMap[keyID]
    end
    return false
end

--存储红点状态信息
def.method("number", "boolean").SaveRedPointState = function(self, keyID, value)
    local redPointMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Mall)
    if redPointMap == nil then 
        redPointMap = {}
    end
    redPointMap[keyID] = value
    CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Mall, redPointMap)
    for _,v in pairs(redPointMap) do
        if v == true then
            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mall,true)
            return
        end
    end
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mall,false)
end

-- 根据角色数据设置红点信息
def.method().SetFundOrMonthlyCardRedPointStateByPlayerBuyInfo = function(self)
    if self._MallRoleInfo == nil then return end

    for _,v in ipairs(self._MallRoleInfo.RoleStoreData.StoreDatas) do
        local store_temp = CElementData.GetTemplate("Store", v.StoreId)
        if store_temp == nil then print("CMallMan.SetRedPointStateByPlayerBuyInfo   找不到对应的商店模板", v.StoreId) return end
        if store_temp.FormatType == EFormatType.FundTemp then
            local good_temp = CElementData.GetTemplate("Goods", tonumber(store_temp.GoodIds))
            local find_it = false
            for i,v1 in pairs(self._MallRoleInfo.RoleStoreData.FundDatas) do
                if i == good_temp.FundId then
                    self:SaveRedPointState(v.StoreId, #v1.CanRewardIds > 0)
                    find_it = true
                end
            end
            if not find_it then
                self:SaveRedPointState(v.StoreId, false)
            end
        elseif store_temp.FormatType == EFormatType.MonthlyCardTemp then
            local good_temp = CElementData.GetTemplate("Goods", tonumber(store_temp.GoodIds))
            local find_it = false
            for i,v1 in pairs(self._MallRoleInfo.RoleStoreData.MonthlyCardDatas) do
                if i == good_temp.MonthlyCardId then
                    self:SaveRedPointState(v.StoreId, v1.IsCanReward)
                    find_it = true
                end
            end
            if not find_it then
                self:SaveRedPointState(v.StoreId, false)
            end
        end
    end
    
end

--解析商城数据
def.method("table", "=>", "table").ParseMsg = function(self, data)
    local pageData = {}
    pageData.StoreTagId = data.StoreTagId
    pageData.StoreId = data.StoreId
    pageData.FormatType = data.FormatType
    pageData.RefreshCount = data.RefreshCount
    pageData.NextRefreshTime = data.NextRefreshTime
    pageData.RateQueryURL = data.RateQueryURL
    pageData.Goods = {}
    for i,v in ipairs(data.Goods) do
        pageData.Goods[i] = {}
        pageData.Goods[i].Id = v.Id
        pageData.Goods[i].Name = v.Name
        pageData.Goods[i].GoodsType = v.GoodsType
        pageData.Goods[i].CostType = v.CostType
        pageData.Goods[i].Stock = v.Stock
        pageData.Goods[i].DiscountType = v.DiscountType
        pageData.Goods[i].ItemId = v.ItemId
        pageData.Goods[i].ItemCount = v.ItemCount
        pageData.Goods[i].GainMoneyId = v.GainMoneyId
        pageData.Goods[i].GainMoneyCount = v.GainMoneyCount
        pageData.Goods[i].GiftItemId = v.GiftItemId
        pageData.Goods[i].GiftItemCount = v.GiftItemCount
        pageData.Goods[i].GiftMoneyId = v.GiftMoneyId
        pageData.Goods[i].GiftMoneyCount = v.GiftMoneyCount
        pageData.Goods[i].CostMoneyId = v.CostMoneyId
        pageData.Goods[i].CostMoneyCount = v.CostMoneyCount
        pageData.Goods[i].IOS_ProductId = v.IOS_ProductId
        pageData.Goods[i].CashCount = v.CashCount
        pageData.Goods[i].IconPath = v.IconPath
        pageData.Goods[i].LimitType = v.LimitType
        pageData.Goods[i].LabelType = v.LabelType
        pageData.Goods[i].NextRefreshTime = v.NextRefreshTime
    end
    pageData.RecommendInfo1 = {}
    pageData.RecommendInfo1.Infos = {}
    if data.RecommendInfo1 ~= nil then
        for i,v in ipairs(data.RecommendInfo1.Infos) do
            pageData.RecommendInfo1.Infos[i].TagId = v.TagId
            pageData.RecommendInfo1.Infos[i].StoreId = v.StoreId
            pageData.RecommendInfo1.Infos[i].GoodsId = v.GoodsId
            pageData.RecommendInfo1.Infos[i].IconPath = v.IconPath
        end
    end
    pageData.RecommendInfo2 = {}
    pageData.RecommendInfo2.Infos = {}
    if data.RecommendInfo2 ~= nil then
        for i,v in ipairs(data.RecommendInfo2.Infos) do
            pageData.RecommendInfo2.Infos[i].TagId = v.TagId
            pageData.RecommendInfo2.Infos[i].StoreId = v.StoreId
            pageData.RecommendInfo2.Infos[i].GoodsId = v.GoodsId
            pageData.RecommendInfo2.Infos[i].IconPath = v.IconPath
        end
    end
    pageData.RecommendInfo3 = {}
    pageData.RecommendInfo3.Infos = {}
    if data.RecommendInfo3 ~= nil then
        for i,v in ipairs(data.RecommendInfo3.Infos) do
            pageData.RecommendInfo3.Infos[i].TagId = v.TagId
            pageData.RecommendInfo3.Infos[i].StoreId = v.StoreId
            pageData.RecommendInfo3.Infos[i].GoodsId = v.GoodsId
            pageData.RecommendInfo3.Infos[i].IconPath = v.IconPath
        end
    end
    pageData.WebViewUrl = data.WebViewUrl
    return pageData
end

--更新商城数据中的物品
def.method("table", "table").UpdateGoods = function(self, pageData, data)
    pageData.Goods = {}
    for i,v in ipairs(data.Goods) do
        pageData.Goods[i] = {}
        pageData.Goods[i].Id = v.Id
        pageData.Goods[i].Name = v.Name
        pageData.Goods[i].GoodsType = v.GoodsType
        pageData.Goods[i].CostType = v.CostType
        pageData.Goods[i].Stock = v.Stock
        pageData.Goods[i].DiscountType = v.DiscountType
        pageData.Goods[i].ItemId = v.ItemId
        pageData.Goods[i].ItemCount = v.ItemCount
        pageData.Goods[i].GainMoneyId = v.GainMoneyId
        pageData.Goods[i].GainMoneyCount = v.GainMoneyCount
        pageData.Goods[i].GiftItemId = v.GiftItemId
        pageData.Goods[i].GiftItemCount = v.GiftItemCount
        pageData.Goods[i].GiftMoneyId = v.GiftMoneyId
        pageData.Goods[i].GiftMoneyCount = v.GiftMoneyCount
        pageData.Goods[i].CostMoneyId = v.CostMoneyId
        pageData.Goods[i].CostMoneyCount = v.CostMoneyCount
        pageData.Goods[i].IOS_ProductId = v.IOS_ProductId
        pageData.Goods[i].CashCount = v.CashCount
        pageData.Goods[i].IconPath = v.IconPath
        pageData.Goods[i].LimitType = v.LimitType
        pageData.Goods[i].LabelType = v.LabelType
        pageData.Goods[i].NextRefreshTime = v.NextRefreshTime
    end
end

--解析角色数据
def.method("table", "=>", "table").ParseRoleData = function(self, roleData)
    local mallInfo = {}
    mallInfo.RoleStoreData = {}
    mallInfo.RoleStoreData.StoreDatas = {}
    if roleData.RoleStoreData.StoreDatas then
        for i,v in ipairs(roleData.RoleStoreData.StoreDatas) do
            mallInfo.RoleStoreData.StoreDatas[i] = {}
            mallInfo.RoleStoreData.StoreDatas[i].StoreId = v.StoreId
            mallInfo.RoleStoreData.StoreDatas[i].NextRefreshTime = v.NextRefreshTime
            mallInfo.RoleStoreData.StoreDatas[i].RefreshCount = v.RefreshCount
            if v.GoodsDatas then
                mallInfo.RoleStoreData.StoreDatas[i].GoodsDatas = {}
                for i1,v1 in ipairs(v.GoodsDatas) do
                    mallInfo.RoleStoreData.StoreDatas[i].GoodsDatas[i1] = {}
                    local good_data = mallInfo.RoleStoreData.StoreDatas[i].GoodsDatas[i1]
                    good_data.GoodsId = v1.GoodsId
                    good_data.BuyCount = v1.BuyCount
                    good_data.DiscountType = v1.DiscountType
                    good_data.MoneyCount = v1.MoneyCount
                    good_data.NextRefreshTime = v1.NextRefreshTime
                end
            end
        end
    end
    mallInfo.RoleStoreData.FundDatas = {}
    if roleData.RoleStoreData.FundDatas then
        for i,v in ipairs(roleData.RoleStoreData.FundDatas) do
            local fund_tid = roleData.RoleStoreData.FundDatas[i].Tid
            --print("fund_tid ", fund_tid)
            mallInfo.RoleStoreData.FundDatas[fund_tid] = {}
            local fund_item = mallInfo.RoleStoreData.FundDatas[fund_tid]
            fund_item.IsBuy = true
            fund_item.CanRewardIds = {}
            if roleData.RoleStoreData.FundDatas[i].CanRewardIds then
                for j,w in ipairs(roleData.RoleStoreData.FundDatas[i].CanRewardIds) do
                    fund_item.CanRewardIds[j] = w
                end
                if #fund_item.CanRewardIds > 0 then
                    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mall,true)
                end
            end
            if roleData.RoleStoreData.FundDatas[i].FinishIds then
                fund_item.FinishIds = {}
                if roleData.RoleStoreData.FundDatas[i].FinishIds then
                    for j,w in ipairs(roleData.RoleStoreData.FundDatas[i].FinishIds) do
                        fund_item.FinishIds[j] = w
                    end
                end
            end
        end
    end
    mallInfo.RoleStoreData.MonthlyCardDatas = {}
    if roleData.RoleStoreData.MonthlyCardDatas then
        for i,v in ipairs(roleData.RoleStoreData.MonthlyCardDatas) do
            local tid = roleData.RoleStoreData.MonthlyCardDatas[i].Tid
            mallInfo.RoleStoreData.MonthlyCardDatas[tid] = {}
            mallInfo.RoleStoreData.MonthlyCardDatas[tid].Tid = roleData.RoleStoreData.MonthlyCardDatas[i].Tid
            mallInfo.RoleStoreData.MonthlyCardDatas[tid].ExpiredTime = roleData.RoleStoreData.MonthlyCardDatas[i].ExpiredTime
            mallInfo.RoleStoreData.MonthlyCardDatas[tid].LastRewardTime = roleData.RoleStoreData.MonthlyCardDatas[i].LastRewardTime
            mallInfo.RoleStoreData.MonthlyCardDatas[tid].IsCanReward = roleData.RoleStoreData.MonthlyCardDatas[i].IsCanReward
        end
    end
    return mallInfo
end

-- 解析页签数据，缓存起来
def.method("table", "=>", "table").ParseTagsData = function(self, msg)
    local data = {}
    data.StoreTagFounds = {}
    for _,v in ipairs(msg.StoreTagFounds) do
        if self:BigTagLockCheck(v.TagId) then
            data.StoreTagFounds[#data.StoreTagFounds + 1] = {}
            local store_fund = data.StoreTagFounds[#data.StoreTagFounds]
            store_fund.TagId = v.TagId
            store_fund.TagName = v.TagName
            store_fund.TagSort = v.TagSort
            store_fund.LabelType = v.LabelType
            store_fund.Stores = {}
            for _1,v1 in ipairs(v.Stores) do
                if self:ModuleLockCheck(v1.FormatType) and self:ShowEndTimeCheck(v1.ShowEndTime) then
                    store_fund.Stores[#store_fund.Stores + 1] = {}
                    local small_fund = store_fund.Stores[#store_fund.Stores]
                    small_fund.StoreId = v1.StoreId
                    small_fund.StoreName = v1.StoreName
                    small_fund.FormatType = v1.FormatType
                    small_fund.ShowEndTime = v1.ShowEndTime
                    small_fund.LabelType = v1.LabelType
                end
            end
            if #store_fund.Stores == 0 then
                table.remove(data.StoreTagFounds, #data.StoreTagFounds)
            end
        end
    end
    local sort_func = function(item1, item2)
        if item1 == nil or item2 == nil then return false end
        return item1.TagSort > item2.TagSort
    end
    table.sort(data.StoreTagFounds, sort_func)
    data.RefundStatementURL = msg.RefundStatementURL
    return data
end

-- 购买了新的基金
def.method("number").BuyNewFund = function(self, fundTid)
    if self._MallRoleInfo == nil then return end

    local fund_datas = self._MallRoleInfo.RoleStoreData.FundDatas
    if fund_datas[fundTid] == nil then
        fund_datas[fundTid] = {}
        fund_datas[fundTid].IsBuy = true
        fund_datas[fundTid].CanRewardIds = {}
        fund_datas[fundTid].FinishIds = {}
    else
        fund_datas[fundTid].IsBuy = true
    end
end

-- 通过月卡TID获得月卡数据，为空说明没有购买
def.method("number", "=>", "table").GetMonthCardRoleData = function(self, tid)
    if self._MallRoleInfo == nil then return nil end

    if self._IsMallRoleInfoInited and self._MallRoleInfo.RoleStoreData.MonthlyCardDatas ~= nil then
        return self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid]
    end
    return nil
end

-- 通过基金TID获得基金数据，为空说明没有购买
def.method("number", "=>", "table").GetFundRoleData = function(self, tid)
    if self._MallRoleInfo == nil then return nil end

    if self._IsMallRoleInfoInited and self._MallRoleInfo.RoleStoreData.FundDatas ~= nil then
        return self._MallRoleInfo.RoleStoreData.FundDatas[tid]
    end
    return nil
end

-- 大页签是否解锁
def.method("number", "=>", "boolean").BigTagLockCheck = function(self, tagID)
    if tagID == 4 then
        return game._CFunctionMan:IsUnlockByFunTid(self._TotalUnlockTid)
    end
    return true
end

-- 小页签是否解锁
def.method("number", "=>", "boolean").ModuleLockCheck = function(self, formatType)
    if formatType == EFormatType.NewPlayerBagTemp then
        
    elseif formatType == EFormatType.MysticalStoreTemp then
        local glory_temp = CElementData.GetTemplate("GloryLevel", game._HostPlayer._InfoData._GloryLevel)
        if glory_temp == nil then
            return false
        else
            return glory_temp.BlackMarketUnlcok
        end
    elseif formatType == EFormatType.SprintGiftTemp then
        return game._CFunctionMan:IsUnlockByFunTid(self._ElfUnlockTid)
    elseif formatType == EFormatType.PetDropRuleTemp then
        return game._CFunctionMan:IsUnlockByFunTid(self._PetExtractUnlockTid)
    end
    return true
end

-- 商品页签是否已经过时
def.method("number", "=>", "boolean").ShowEndTimeCheck = function(self, endTime)
    local now_time = GameUtil.GetServerTime()
    return endTime > 0 and endTime > now_time or true
end

-- 根据商店ID判断该商店是否解锁
def.method("number", "=>", "boolean").IsStoreUnlock = function(self, storeID)
    if storeID == nil or storeID <= 0 then return false end
    if self._TabDatasFromServer == nil then return false end
    for _,v in ipairs(self._TabDatasFromServer.StoreTagFounds) do
        if v ~= nil and v.Stores ~= nil then
            for _1,w in ipairs(v.Stores) do
                if w.StoreId == storeID then
                    return self:ModuleLockCheck(w.FormatType)
                end
            end
        end
    end
    return false
end

-- 点击了退款声明Label
def.method().HandleClickBuyTips = function(self)
    if self._TabDatasFromServer == nil or self._TabDatasFromServer.RefundStatementURL == nil or self._TabDatasFromServer.RefundStatementURL == "" then
        warn("退款声明URL 为空！！！ ")
        return
    end
    print("弹了退款申明的URL ", self._TabDatasFromServer.RefundStatementURL)
    --game._GUIMan:OpenUrl(self._TabDatasFromServer.RefundStatementURL)
    CPlatformSDKMan.Instance():ShowInAppWeb(self._TabDatasFromServer.RefundStatementURL)
end

--======================C2S======================

--请求页签信息
def.method().RequestTabs = function(self)
    local C2SStoreSetUpReq = require "PB.net".C2SStoreSetUpReq
	local protocol = C2SStoreSetUpReq()
    --protocol.RefreshTime = self._RefreshTime
	SendProtocol(protocol)
end

--请求小页签具体的内容数据
def.method("number", "number").RequestSmallTypeData = function(self, bigTabID, smallTabID)
    local C2SStoreDataReq = require "PB.net".C2SStoreDataReq
	local protocol = C2SStoreDataReq()
    protocol.StoreTagId = bigTabID
    protocol.StoreId = smallTabID
    --protocol.RefreshTime = 0
	SendProtocol(protocol)
end

--请求角色商城数据
def.method().RequestMallRoleInfo = function(self)
    local C2SStoreSyncInfo = require "PB.net".C2SStoreSyncInfo
    local protocol = C2SStoreSyncInfo()
    SendProtocol(protocol)
end

--购买物品（代币）
def.method("number", "number", "number").BuyGoodsItem = function(self, storeID, goodsID, count)
    local C2SStoreBuyReq = require "PB.net".C2SStoreBuyReq
    local protocol = C2SStoreBuyReq()
    protocol.StoreId = storeID
    protocol.GoodsId = goodsID
    protocol.Count = count or 1
    --平台 测试 直接先传入苹果
    protocol.Platform = EPlatformType.EPlatformType_default
    protocol.DeviceId = GameUtil.GetOpenUDID()
    --TODO("FIXME::支付 需要平台传入! Google | Apple | T-Store")
    SendProtocol(protocol)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Buy_Item, 0)
end

--购买物品（人民币）
def.method("number", "number","dynamic", "dynamic").BuyItemByRMB = function(self,storeID, goodsID, androidItemID, iosItemID)
    local C2SStoreBuyReq = require "PB.net".C2SStoreBuyReq
    local protocol = C2SStoreBuyReq()
    protocol.StoreId = storeID
    protocol.GoodsId = goodsID
    protocol.Count = 1
    --平台 测试 直接先传入苹果
    protocol.Platform = _G.IsIOS() and EPlatformType.EPlatformType_AppStore or
                        (_G.IsAndroid() and EPlatformType.EPlatformType_GooglePlay or EPlatformType.EPlatformType_default)
    protocol.DeviceId = GameUtil.GetOpenUDID()
    --TODO("FIXME::支付 需要平台传入! Google | Apple | T-Store")
    SendProtocol(protocol)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Buy_Item, 0)
end

--神秘商店刷新
def.method("number", "number").RefreshMystoryShop = function(self, bigTagID, smallTagID)
    local C2SStoreMysticalRefreshReq = require "PB.net".C2SStoreMysticalRefreshReq
    local protocol = C2SStoreMysticalRefreshReq()
    protocol.StoreTagId = bigTagID
    protocol.StoreId = smallTagID
    SendProtocol(protocol)
end

--基金奖励领取请求
def.method("number", "number", "number").FundGetReward = function(self, tid, detailID, storeID)
    local C2SFundGetReward = require "PB.net".C2SFundGetReward
    local protocol = C2SFundGetReward()
    protocol.Tid = tid
    protocol.DetailId = detailID
    protocol.StoreTid = storeID
    SendProtocol(protocol)
end

-- 月卡今天的奖励领取
def.method("number", "number").MonthlyCardGetReward = function(self, tid, storeID)
    local C2SMonthlyGetReward = require "PB.net".C2SMonthlyGetReward
    local protocol = C2SMonthlyGetReward()
    protocol.Tid = tid
    protocol.StoreTid = storeID
    SendProtocol(protocol)
end

--======================S2C======================

--处理页签数据
def.method("table").HandleTabsData = function(self, datas)
    local CPanelMall = require "GUI.CPanelMall"
    if not CPanelMall.Instance():IsShow() then return end
    self._TabDatasFromServer = self:ParseTagsData(datas)
    CPanelMall.Instance():Init(self._TabDatasFromServer)
end

--处理小页签数据
def.method("table").HandleSmallTypeData = function(self, datas)
    local CPanelMall = require "GUI.CPanelMall"
    if not CPanelMall.Instance():IsShow() then return end
    CPanelMall.Instance():HandleSmallTabData(datas)
end

--处理商城的角色操作数据
def.method("table").HandleMallRoleInfo = function(self, datas)
    self._MallRoleInfo = self:ParseRoleData(datas)
    self:SetFundOrMonthlyCardRedPointStateByPlayerBuyInfo()
    local bState = CMallUtility.CanExtractElf() and game._CFunctionMan:IsUnlockByFunTid(self._ElfUnlockTid) and game._CFunctionMan:IsUnlockByFunTid(self._TotalUnlockTid)
    self:SaveRedPointState(EnumDef.MallStoreType.ElfExtract, bState)
    self._IsMallRoleInfoInited = true
end

--处理购买物品
def.method("table").HandleBuyItemReply = function(self, datas)
    if datas.ResCode == 0 then
        local nowCount = self:GetItemHasBuyCountByID(datas.StoreId, datas.GoodsId)
        self:SetItemHasBuyCountByID(datas.StoreId, datas.GoodsId, nowCount+datas.Count)
        if datas.Monthly ~= nil then
            if self._MallRoleInfo == nil then
                warn("MallRoleInfo is nil !!!!!!!!")
            else
                local tid = datas.Monthly.Tid
                self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid] = {}
                self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid].Tid = datas.Monthly.Tid
                self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid].ExpiredTime = datas.Monthly.ExpiredTime
                self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid].LastRewardTime = datas.Monthly.LastRewardTime
                self._MallRoleInfo.RoleStoreData.MonthlyCardDatas[tid].IsCanReward = datas.Monthly.IsCanReward
                self:SaveRedPointState(datas.StoreId, datas.Monthly.IsCanReward)
            end
        end

        local good_temp = CElementData.GetTemplate("Goods", datas.GoodsId)
        if good_temp ~= nil then
            if good_temp.GoodsType == EGoodsType.Fund then
                self:BuyNewFund(good_temp.FundId)
            end
        end

        local CPanelMall = require "GUI.CPanelMall"
        if not CPanelMall.Instance():IsShow() then return end
        CPanelMall.Instance():HandleBuyItemSuccess(datas)
        CPanelMall.Instance():RefreshPanel(nil)
    else
        game._GUIMan:ShowErrorTipText(datas.ResCode)
    end
end

--处理刷新
def.method("table").HandleRefreshReply = function(self, datas)
    if datas.ResCode == 0 then
        if datas.RefreshCount ~= nil then
            self:SetStoreRefreshCountByID(datas.StoreId, datas.RefreshCount)
            local CPanelMall = require "GUI.CPanelMall"
            if not CPanelMall.Instance():IsShow() then return end
            CPanelMall.Instance():RefreshPanel(datas)
        end
    else
        game._GUIMan:ShowErrorTipText(datas.ResCode)
    end
end

-- 处理单个商品的刷新
def.method("table").HandleGoodsRefreshReply = function(self, datas)
    self:SetItemHasBuyCountByID(datas.StoreId, datas.GoodsId, 0)
    local CPanelMall = require "GUI.CPanelMall"
    if not CPanelMall.Instance():IsShow() then return end
    CPanelMall.Instance():SetGoodsRefreshTime(datas.StoreTagId, datas.StoreId, datas.GoodsId, datas.NextRefreshTime)
    CPanelMall.Instance():RefreshPanel(nil)
end

--基金可领取数据更新
def.method("table").HandleFundCanRewardInc = function(self, datas)
    local tid = datas.Tid
    if self._MallRoleInfo ~= nil and self._IsMallRoleInfoInited then
        for i,v in ipairs(datas.DetailIds) do
            local haveValue = -1
            for _i,_v in ipairs(self._MallRoleInfo.RoleStoreData.FundDatas[tid].CanRewardIds) do
                if v == _v then
                    haveValue = _i
                end
            end
            if haveValue == -1 then
                self._MallRoleInfo.RoleStoreData.FundDatas[tid].CanRewardIds[#self._MallRoleInfo.RoleStoreData.FundDatas[tid].CanRewardIds+1] = v
            end
        end
    end
    self:SetFundOrMonthlyCardRedPointStateByPlayerBuyInfo()
    local CPanelMall = require "GUI.CPanelMall"
    if CPanelMall.Instance():IsShow() then
        CPanelMall.Instance():RefreshPanel(nil)
    end
end

--基金领取消息回复处理
def.method("table").HandleFundGetRewardReply = function (self, datas)
    local tid = datas.Tid
    if datas.ResCode == 0 then
        if self._MallRoleInfo ~= nil and self._IsMallRoleInfoInited then
            table.removebyvalue(self._MallRoleInfo.RoleStoreData.FundDatas[tid].CanRewardIds, datas.DetailId, true)
            local haveValue = -1
            for i,v in ipairs(self._MallRoleInfo.RoleStoreData.FundDatas[tid].FinishIds) do
                if v == datas.DetailId then
                    haveValue = i
                end
            end
            if haveValue == -1 then
                self._MallRoleInfo.RoleStoreData.FundDatas[tid].FinishIds[#self._MallRoleInfo.RoleStoreData.FundDatas[tid].FinishIds+1] = datas.DetailId;
            end
            self:SetFundOrMonthlyCardRedPointStateByPlayerBuyInfo()
        end
    else
        game._GUIMan:ShowErrorTipText(datas.ResCode)
        return
    end
    local CPanelMall = require "GUI.CPanelMall"
    if CPanelMall.Instance():IsShow() then
        CPanelMall.Instance():RefreshPanel(nil)
    end
end

-- 月卡当天奖励领取消息回复
def.method("table").HandleMonthlyCardGetRewardReply = function(self, msg)
    if msg.ResCode == 0 then
        self:SetGetMonthlyCardReward(msg.Tid, false)
        self:SaveRedPointState(msg.StoreTid, false)
        local CPanelMall = require "GUI.CPanelMall"
        if CPanelMall.Instance():IsShow() then
            CPanelMall.Instance():RefreshPanel(nil)
        end
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
    end
end

def.method("table").HandleQuickStoreBuyReq = function(self, msg)
    local CPanelQuickBuy = require "GUI.CPanelQuickBuy"
    if msg.ResCode == 0 then
        if CPanelQuickBuy.Instance():IsShow() then
            CPanelQuickBuy.Instance():HandleQuickStoreSuccess(msg.Param, true)
        end
    else
        game._GUIMan:ShowErrorTipText(msg.ResCode)
        if CPanelQuickBuy.Instance():IsShow() then
            CPanelQuickBuy.Instance():HandleQuickStoreSuccess(msg.Param, false)
        end
    end
end

def.method().Clear = function(self)
    self._RefreshTime = 0
    self._IsMallRoleInfoInited = false
    self._MallRoleInfo = nil
	self._TabDatasFromServer = nil
end

def.method().Release = function(self)
    self._RefreshTime = 0
    self._IsMallRoleInfoInited = false
    self._MallRoleInfo = nil
    self._TabDatasFromServer = nil
    CGame.EventManager:removeHandler(GainNewItemEvent, OnGainNewItemEvent)
    CGame.EventManager:removeHandler(NotifyFunctionEvent, OnSystemUnlockEvent)
    CGame.EventManager:removeHandler(ApplicationQuitEvent, OnApplicationQuit)
    instance = nil
end

CMallMan.Commit()
return CMallMan