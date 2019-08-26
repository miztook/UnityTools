local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local GainNewItemEvent = require "Events.GainNewItemEvent"
local NotifyFunctionEvent = require "Events.NotifyFunctionEvent"
local CMallUtility = require "Mall.CMallUtility"
local CQuest = require "Quest.CQuest"
local CPageBag = require "GUI.CPageBag"
local CGame = Lplus.ForwardDeclare("CGame")
local EPlatformType = require "PB.data".EPlatformType
local EFormatType = require "PB.Template".Store.EFormatType
local EGoodsType = require "PB.Template".Goods.EGoodsType
local EActivityStoreType = require "PB.Template".ActivityStore.EActivityStoreType

local CMallMan = Lplus.Class("CMallMan")
local def = CMallMan.define
local instance = nil

def.static("=>", CMallMan).Instance = function()
	if instance == nil then
		instance = CMallMan()
	end
	return instance
end

local RefundTipSpecialID = 686

def.field("table")._MallRoleInfo = nil                  -- 角色商城数据(对应net.proto的RoleStoreDB里面的StoreDatas)
def.field("table")._TabDatasFromServer = BlankTable     -- 从server请求的页签数据(或者是CMallMan里面的缓存数据)
def.field("table")._BannerDatas = BlankTable            -- 从server请求的banner数据
def.field("boolean")._IsMallRoleInfoInited = false      -- 商城角色数据是否已经初始化了
def.field("number")._TotalUnlockTid = 80                -- 召唤解锁id
def.field("number")._ElfUnlockTid = 10                  -- 精灵献礼解锁ID
def.field("number")._PetExtractUnlockTid = 75           -- 宠物解锁ID
def.field("table")._ActivityDataTimers = BlankTable     -- 活动商品是否时间到的timers
def.field("boolean")._IsSingle = true                   -- 是否是单抽（用于再来一次）
def.field("boolean")._IsFirstLoad = true                -- 是否是第一次加载抽奖结果界面。
def.field("boolean")._IsExtracting = false              -- 是否正在抽取
def.field("userdata")._MallLotteryCache = nil           -- 抽取翻牌界面的缓存（为了不让lua清掉）

------------------------------------------活动商城Start------------------------------------------------
def.field("table")._ActivityPagesData = BlankTable
------------------------------------------活动商城 End ------------------------------------------------

-- 获得召唤的页签商城数据（net.proto里面StoreFound结构的table）
def.method("=>", "table").GetSummonTagsDataFromServer = function(self)
    local store_funds = {}
    for i,v in ipairs(self._TabDatasFromServer.StoreTagFounds) do
        for j,w in ipairs(v.Stores) do
            if w.FormatType == EFormatType.SprintGiftTemp or w.FormatType == EFormatType.PetDropRuleTemp then
                w.BigTagID = v.TagId
                store_funds[#store_funds + 1] = w
            end
        end
    end
    return store_funds
end

def.method("=>", "table").GetTagsDataFromServer = function(self)
    local data = {}
    data.StoreTagFounds = {}
    if self._TabDatasFromServer == nil or self._TabDatasFromServer.StoreTagFounds == nil then
        data.RefundStatementURL = ""
        warn("error !!! : CMallMan.GetTagsDataFromServer() -- self._TabDatasFromServer.StoreTagFounds为空！！！", debug.traceback())
        return data 
    end
    for _,v in ipairs(self._TabDatasFromServer.StoreTagFounds) do
        if v.Stores ~= nil and (#v.Stores > 0) then
            data.StoreTagFounds[#data.StoreTagFounds + 1] = {}
            local store_fund = data.StoreTagFounds[#data.StoreTagFounds]
            store_fund.TagId = v.TagId
            store_fund.TagName = v.TagName
            store_fund.TagSort = v.TagSort
            store_fund.LabelType = v.LabelType
            store_fund.Stores = {}
            for _1,v1 in ipairs(v.Stores) do
                if v1.FormatType ~= EFormatType.SprintGiftTemp and v1.FormatType ~= EFormatType.PetDropRuleTemp then
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
    data.RefundStatementURL = self._TabDatasFromServer.RefundStatementURL
    return data
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
        CMallMan.Instance():SaveSummonRedPointState(EnumDef.MallStoreType.ElfExtract, can_extract)
        local CPanelSummon = require "GUI.CPanelSummon"
        if CPanelSummon.Instance():IsShow() then
            for _,v in ipairs(instance._TabDatasFromServer.StoreTagFounds) do
                for _1,v1 in ipairs(v.Stores) do
                    if v1.FormatType == EFormatType.SprintGiftTemp then
                        CPanelSummon.Instance():ShowRedPoint(v1.StoreId, can_extract)
                    end
                end
            end
            CPanelSummon.Instance():OnGainNewItem(sender, event)
        end
    end
end

local OnSystemUnlockEvent = function(sender, event)
    if instance ~= nil then
        local id = event.FunID
        if id == instance._ElfUnlockTid and game._CFunctionMan:IsUnlockByFunTid(instance._TotalUnlockTid) then
            instance:SaveSummonRedPointState(EnumDef.MallStoreType.ElfExtract, CMallUtility.CanExtractElf())
        end
    end
end

local function OnHostPlayerLevelChangeEvent(sender, event)
    if instance ~= nil then
        instance:OnActivityMallHandleLevelUp()
    end
end

def.method().Init = function(self)
    self._IsFirstLoad = true
    CGame.EventManager:addHandler(GainNewItemEvent, OnGainNewItemEvent)
    CGame.EventManager:addHandler(NotifyFunctionEvent, OnSystemUnlockEvent)
    CGame.EventManager:addHandler('HostPlayerLevelChangeEvent', OnHostPlayerLevelChangeEvent)
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
    for k,v in pairs(redPointMap) do
        if v == true and k ~= EnumDef.MallStoreType.ElfExtract and k ~= EnumDef.MallStoreType.PetExtract then
            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mall,true)
            return
        end
    end
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Mall,false)
end

-- 获得召唤的红点状态
def.method("number", "=>", "boolean").GetSummonRedPointState = function(self, keyID)
    local redPointMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Summon)
    if redPointMap ~= nil and redPointMap[keyID] ~= nil then
        return redPointMap[keyID]
    end
    return false
end

-- 保存召唤的红点状态
def.method("number", "boolean").SaveSummonRedPointState = function(self, keyID, value)
    local red_map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Summon)
    if red_map == nil then
        red_map = {}
    end
    red_map[keyID] = value
    CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Summon, red_map)
    local finded = false
    for _,v in pairs(red_map) do
        if v == true then
            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Summon,true)
            finded = true
        end
    end
    if not finded then
        CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Summon,false)
    end
    local CPanelSummon = require "GUI.CPanelSummon"
    if CPanelSummon.Instance():IsShow() then
        CPanelSummon.Instance():UpdatePanelRedPoint()
    end
end

-- 根据角色数据设置红点信息
def.method().SetFundOrMonthlyCardRedPointStateByPlayerBuyInfo = function(self)
    if self._MallRoleInfo == nil then return end

    for _,v in ipairs(self._MallRoleInfo.RoleStoreData.StoreDatas) do
        local store_temp = CElementData.GetTemplate("Store", v.StoreId)
        if store_temp == nil then print("CMallMan.SetRedPointStateByPlayerBuyInfo   找不到对应的商店模板", v.StoreId) return end
        if store_temp.FormatType == EFormatType.FundTemp then
            local goods_id = tonumber(store_temp.GoodIds) or 0
            local good_temp = CElementData.GetTemplate("Goods", goods_id)
            if good_temp == nil then return end
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
            local goods_id = tonumber(store_temp.GoodIds) or 0
            local good_temp = CElementData.GetTemplate("Goods", goods_id)
            if good_temp == nil then return end
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

local goods_sort_func = function(item1, item2)
    if item1.IsRemainCount ~= item2.IsRemainCount then
        return item1.IsRemainCount
    else
        return item1.Id < item2.Id
    end
    return false
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
        if self:CheckGoodsAllRight(v.Id) and self:CheckGoodsLifeTime(v.ShowEndTime) then
            pageData.Goods[#pageData.Goods + 1] = {}
            local idx = #pageData.Goods
            pageData.Goods[idx].Id = v.Id
            pageData.Goods[idx].Name = v.Name
            pageData.Goods[idx].GoodsType = v.GoodsType
            pageData.Goods[idx].CostType = v.CostType
            pageData.Goods[idx].Stock = v.Stock
            pageData.Goods[idx].DiscountType = v.DiscountType
            pageData.Goods[idx].ItemId = v.ItemId
            pageData.Goods[idx].ItemCount = v.ItemCount
            pageData.Goods[idx].GainMoneyId = v.GainMoneyId
            pageData.Goods[idx].GainMoneyCount = v.GainMoneyCount
            pageData.Goods[idx].GiftItemId = v.GiftItemId
            pageData.Goods[idx].GiftItemCount = v.GiftItemCount
            pageData.Goods[idx].GiftMoneyId = v.GiftMoneyId
            pageData.Goods[idx].GiftMoneyCount = v.GiftMoneyCount
            pageData.Goods[idx].CostMoneyId = v.CostMoneyId
            pageData.Goods[idx].CostMoneyCount = v.CostMoneyCount
            pageData.Goods[idx].IOS_ProductId = v.IOS_ProductId
            pageData.Goods[idx].AND_ProductId = v.AND_ProductId
            pageData.Goods[idx].CashCount_IOS = v.CashCount_IOS
            pageData.Goods[idx].CashCount_AOS = v.CashCount_AOS
            pageData.Goods[idx].IconPath = v.IconPath
            pageData.Goods[idx].LimitType = v.LimitType
            pageData.Goods[idx].LabelType = v.LabelType
            pageData.Goods[idx].NextRefreshTime = v.NextRefreshTime
            pageData.Goods[idx].ShowEndTime = v.ShowEndTime
            local buy_count = self:GetItemHasBuyCountByID(pageData.StoreId, v.Id)
            pageData.Goods[idx].IsRemainCount = v.Stock > 0 and v.Stock > buy_count or v.Stock <= 0
        end
    end

    table.sort(pageData.Goods, goods_sort_func)
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
        if self:CheckGoodsAllRight(v.Id) and self:CheckGoodsLifeTime(v.ShowEndTime) then
            local item = {}
            item.Id = v.Id
            item.Name = v.Name
            item.GoodsType = v.GoodsType
            item.CostType = v.CostType
            item.Stock = v.Stock
            item.DiscountType = v.DiscountType
            item.ItemId = v.ItemId
            item.ItemCount = v.ItemCount
            item.GainMoneyId = v.GainMoneyId
            item.GainMoneyCount = v.GainMoneyCount
            item.GiftItemId = v.GiftItemId
            item.GiftItemCount = v.GiftItemCount
            item.GiftMoneyId = v.GiftMoneyId
            item.GiftMoneyCount = v.GiftMoneyCount
            item.CostMoneyId = v.CostMoneyId
            item.CostMoneyCount = v.CostMoneyCount
            item.IOS_ProductId = v.IOS_ProductId
            item.AND_ProductId = v.AND_ProductId
            item.CashCount_IOS = v.CashCount_IOS
            item.CashCount_AOS = v.CashCount_AOS
            item.IconPath = v.IconPath
            item.LimitType = v.LimitType
            item.LabelType = v.LabelType
            item.NextRefreshTime = v.NextRefreshTime
            item.ShowEndTime = v.ShowEndTime
            local buy_count = self:GetItemHasBuyCountByID(pageData.StoreId, v.Id)
            item.IsRemainCount = v.Stock > buy_count
            table.insert(pageData.Goods, item)
        end
    end
    table.sort(pageData.Goods, goods_sort_func)
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
        if self:BigTagLockCheck(v.TagId) and self:SpecialHideTagCheck(v.TagId) and v.Stores ~= nil and (#v.Stores > 0) then
            data.StoreTagFounds[#data.StoreTagFounds + 1] = {}
            local store_fund = data.StoreTagFounds[#data.StoreTagFounds]
            store_fund.TagId = v.TagId
            store_fund.TagName = v.TagName
            store_fund.TagSort = v.TagSort
            store_fund.LabelType = v.LabelType
            store_fund.Stores = {}
            for _1,v1 in ipairs(v.Stores) do
                if self:ModuleLockCheck(v1.FormatType) and self:SpecialHideStoreCheck(v1.StoreId) and self:ShowEndTimeCheck(v1.ShowEndTime) then
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

def.method("number", "number", "=>", "boolean").BannerTimeIsOK = function(self, startTime, endTime)
    local now_time = GameUtil.GetServerTime()/1000
    if now_time > startTime and now_time < endTime then
        return true
    end
    return false
end

-- 加载所有bannner数据
def.method().LoadBannerTempData = function(self)
    self._BannerDatas = {}
    local all_banners = CElementData.GetAllTid("Banner")
    if all_banners == nil then return end

    for i,v in ipairs(all_banners) do
        local banner_temp = CElementData.GetTemplate("Banner", v)
        if banner_temp then
            local item = {}
            item.BannerTid = v
            item.OpenFlag = banner_temp.IsOpen and self:BannerTimeIsOK(GUITools.FormatTimeFromGmtToSeconds(banner_temp.StartTime) or 0, GUITools.FormatTimeFromGmtToSeconds(banner_temp.EndTime) or 0)
            item.SortId = banner_temp.SortId or 0
            self._BannerDatas[#self._BannerDatas + 1] = item
        end
    end
end

local IsTimeOK = function(startTime, endTime)
    if startTime == nil or endTime == nil then
        return true
    end
    local now_time = GameUtil.GetServerTime()/1000
    if startTime > 0 and endTime > 0 then
        return now_time > startTime and now_time < endTime
    end
    return true
end

def.method("=>", "table").GetAllOpenedBanner = function(self)
    local opened_table = {}
    for i,v in ipairs(self._BannerDatas) do
        if v.OpenFlag and IsTimeOK(v.StartTime, v.EndTime) then
            opened_table[#opened_table + 1] = v
        end
    end
    return opened_table
end

def.method("table").ParseBannerInfoData = function(self, msg)
    if msg.BannerDatas == nil then return end
    for k,w in ipairs(self._BannerDatas) do
        for i,v in ipairs(msg.BannerDatas) do
            if v.BannerTid == w.BannerTid then
                w.SortId = v.SortWeight
                w.StartTime = v.StartTime
                w.EndTime = v.EndTime
                if v.OpenFlag ~= nil then
                    w.OpenFlag = v.OpenFlag and self:BannerTimeIsOK(v.StartTime, v.EndTime)
                else
                    w.OpenFlag = false
                end
            end
        end
    end

    local sort_func = function(item1, item2)
        if item1.SortId == item2.SortId then
            return false
        else
            return item1.SortId > item2.SortId
        end
    end
    table.sort(self._BannerDatas, sort_func)
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

-- 大页签是否韩服隐藏（1.9.0）
def.method("number", "=>", "boolean").SpecialHideTagCheck = function(self, tagID)
    local options = GameConfig.Get("FuncOpenOption")
    if options.HideMall and (tagID == 2 or tagID == 7) then
        return false
    end
    return true
end

-- 小页签是否韩服隐藏（1.9.0）
def.method("number", "=>", "boolean").SpecialHideStoreCheck = function(self, storeID)
    local options = GameConfig.Get("FuncOpenOption")
    if options.HideMall and storeID == 14 then
        return false
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

def.method("number", "=>", "boolean").CheckGoodsAllRight = function(self, goodsID)
    local goods_temp = CElementData.GetTemplate("Goods", goodsID)
    if goods_temp == nil then
        warn("error !!! 商品模板数据为空 ，ID： ", goodsID)
        return false
    end
    if goods_temp.GoodsType == EGoodsType.Item then
        local item_temp = CElementData.GetItemTemplate(goods_temp.ItemId)
        if item_temp == nil then
            warn("error !!! 商品的物品TID错误， 商品ID：", goodsID)
            return false
        end
        local host_level = game._HostPlayer._InfoData._Level
        if host_level < goods_temp.ShowLimitLevelMin then
            return false
        end
        if item_temp.QuestId ~= nil and item_temp.QuestId > 0 then
            if not CQuest.Instance():IsQuestCompleted(item_temp.QuestId) then
                return false
            end
        end
    end
    return true
end

def.method("number", "=>", "boolean").CheckGoodsLifeTime = function(self, deadTime)
    if deadTime <= 0 then
        return true
    end
    local now_time = GameUtil.GetServerTime()
    return now_time < deadTime
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

-- 获得是单抽还是十连抽
def.method("=>","boolean").GetIsSingle = function(self)
    return self._IsSingle
end

-- 获得不同平台下的模板商品的现金消耗
def.method("number", "=>", "number").GetGoodsTempCashCost = function(self, goodsTid)
    local goods_temp = CElementData.GetTemplate("Goods", goodsTid)
    if goods_temp == nil then
        warn("error !!! 商品数据错误，没有此ID的商品  ID：", goodsTid)
        return 0
    end
    if IsAndroid() or IsWin() then
        return goods_temp.AOS_CashCount
    elseif IsIOS() then
        return goods_temp.IOS_CashCount
    end
end

-- 获得不同平台下的服务器数据的现金消耗
def.method("table", "=>", "number").GetGoodsDataCashCost = function(self, goods_item)
    if IsAndroid() or IsWin() then
        return (goods_item.CashCount_AOS or 0)
    elseif IsIOS() then
        return (goods_item.CashCount_IOS or 0)
    end
    return 0
end

-- 点击了退款声明Label
def.method().HandleClickBuyTips = function(self)
    local bKakaoPlatform = CPlatformSDKMan.Instance():IsInKakao()
    if bKakaoPlatform then
        local key = CElementData.GetSpecialIdTemplate(RefundTipSpecialID).Value
        local url = CPlatformSDKMan.Instance():GetCustomData(key)
        CPlatformSDKMan.Instance():ShowInAppWeb(url)
    else
        if self._TabDatasFromServer == nil or self._TabDatasFromServer.RefundStatementURL == nil or self._TabDatasFromServer.RefundStatementURL == "" then
            warn("退款声明URL 为空！！！ ")
            return
        end
        print("弹了退款申明的URL ", self._TabDatasFromServer.RefundStatementURL)
        game._GUIMan:OpenUrl(self._TabDatasFromServer.RefundStatementURL)
        --CPlatformSDKMan.Instance():ShowInAppWeb(self._TabDatasFromServer.RefundStatementURL)
    end
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

-- 精灵献礼抽取协议
def.method("number").ElfExtract = function(self, count)
    if CPageBag.Instance():IsBagFull() then
        game._GUIMan:ShowTipText(StringTable.Get(256), false)
        return
    end
    if self._IsExtracting then
        print("正在抽奖中")
        return
    end
    self._IsSingle = (count == 1)
    self._IsExtracting = true
    local C2SSprintGiftReq = require "PB.net".C2SSprintGiftReq
    local protocol = C2SSprintGiftReq()
    protocol.Count = count
    local PBHelper = require "Network.PBHelper"
    PBHelper.Send(protocol)

    GameUtil.PreLoadUIFX(PATH.UIFX_MallLottery_Get)
    if self._IsFirstLoad then
        local cb = function(asset)
            self._IsFirstLoad = false
            self._MallLotteryCache = asset
        end
        GameUtil.AsyncLoadPanel(PATH.UI_MallLottery, cb, false)
    end
end

-- 宠物抽奖
def.method("number").PetExtract = function(self, count)
    if CPageBag.Instance():IsBagFull() then
        game._GUIMan:ShowTipText(StringTable.Get(256), false)
        return
    end
    if self._IsExtracting then
        print("正在抽奖中")
        return
    end
    self._IsSingle = (count == 1)
    self._IsExtracting = true
    local C2SPetDropRuleReq = require "PB.net".C2SPetDropRuleReq
    local protocol = C2SPetDropRuleReq()
    protocol.Count = count
    local PBHelper = require "Network.PBHelper"
    PBHelper.Send(protocol)
    GameUtil.PreLoadUIFX(PATH.UIFX_MallLottery_Get)
    if self._IsFirstLoad then
        local cb = function(asset)
            self._IsFirstLoad = false
            self._MallLotteryCache = asset
        end
        GameUtil.AsyncLoadPanel(PATH.UI_MallLottery, cb, false)
    end
end

def.method("number", "number").BuyActivityGoods = function(self, pageID, goodsID)
    local goods_temp = CElementData.GetTemplate("Goods", goodsID)
    if goods_temp ~= nil then
        local C2SAtStoreBuyReq = require "PB.net".C2SAtStoreBuyReq
        local ECostType = require "PB.Template".Goods.ECostType
        local protocol = C2SAtStoreBuyReq()
        protocol.AtStoreTid = pageID
        protocol.GoodsId = goodsID
        protocol.Count = 1
        print("发送购买消息 ", pageID, goodsID)
        if goods_temp.CostType == ECostType.Cash then
            -- send receipt cache
            CPlatformSDKMan.Instance():ProcessPurchaseCache()

            protocol.Platform = _G.IsIOS() and EPlatformType.EPlatformType_AppStore or
                        (_G.IsAndroid() and EPlatformType.EPlatformType_GooglePlay or EPlatformType.EPlatformType_default)
            protocol.DeviceId = GameUtil.GetOpenUDID()
            --TODO("FIXME::支付 需要平台传入! Google | Apple | T-Store")
        end
        SendProtocol(protocol)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Buy_Item, 0)
    else
        warn("error !!! 购买活动商品错误,没有这个商品的模板数据，goodsID为： ", goodsID, debug.traceback())
    end
end

-- 请求banner的更新
def.method().RequestBannerInfo = function(self)
    local C2SBannerInfo = require "PB.net".C2SBannerInfo
    local protocol = C2SBannerInfo()
    SendProtocol(protocol)
end

--======================S2C======================

--处理页签数据
def.method("table").HandleTabsData = function(self, datas)
    local CPanelMall = require "GUI.CPanelMall"
    local CPanelSummon = require "GUI.CPanelSummon"
    self._TabDatasFromServer = self:ParseTagsData(datas)
    if CPanelMall.Instance():IsShow() then
        CPanelMall.Instance():Init(self._TabDatasFromServer)
    end
    if CPanelSummon.Instance():IsShow() then
        CPanelSummon.Instance():Init()
    end
end

--处理小页签数据
def.method("table").HandleSmallTypeData = function(self, datas)

    local CPanelMall = require "GUI.CPanelMall"
    local CPanelSummon = require "GUI.CPanelSummon"
    if CPanelMall.Instance():IsShow() then
        CPanelMall.Instance():HandleSmallTabData(datas)
    end
    if CPanelSummon.Instance():IsShow() then
        CPanelSummon.Instance():HandleSmallTabData(datas)
    end
end

--处理商城的角色操作数据
def.method("table").HandleMallRoleInfo = function(self, datas)
    self._MallRoleInfo = self:ParseRoleData(datas)
    self:SetFundOrMonthlyCardRedPointStateByPlayerBuyInfo()
    local bState = CMallUtility.CanExtractElf() and game._CFunctionMan:IsUnlockByFunTid(self._ElfUnlockTid) and game._CFunctionMan:IsUnlockByFunTid(self._TotalUnlockTid)
    self:SaveSummonRedPointState(EnumDef.MallStoreType.ElfExtract, bState)
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
            for i,v in ipairs(datas.Goods) do
                self:SetItemHasBuyCountByID(datas.StoreId, v.Id, 0)
            end
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
            CPanelMall.Instance():HandleReceiveRewardSuccess(msg.StoreTid)
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

-- banner上线的时候同步过来的消息
def.method("table").HandleBannerInfoData = function(self, msg)
    self:LoadBannerTempData()
    self:ParseBannerInfoData(msg)

    local BannerInfoUpdate = require "Events.BannerInfoUpdate"
    local event = BannerInfoUpdate()
    CGame.EventManager:raiseEvent(nil, event)
end

-- banner更新消息
def.method("table").HandleBannerUpdate = function(self, msg)
    if self._BannerDatas ~= nil then
        for i,v in ipairs(self._BannerDatas) do
            if v.BannerTid == msg.PbBannerData.BannerTid then
                v.OpenFlag = msg.PbBannerData.OpenFlag
            end
        end
    end
    local BannerInfoUpdate = require "Events.BannerInfoUpdate"
    local event = BannerInfoUpdate()
    event._BannerID = msg.PbBannerData.BannerTid
    event._IsOpen = msg.PbBannerData.OpenFlag
    CGame.EventManager:raiseEvent(nil, event)
end


------------------------------------------活动商城Start------------------------------------------------
local GetBuyCount = function(self, pageId, goodId)
    local goods_data = self._ActivityPagesData.ActivityGoodsDatas
    for i,v in ipairs(goods_data) do
        if v.AtStoreTid == pageId and v.GoodsId == goodId then
            return v.BuyCount
        end
    end
    return 0
end

local GetCurActivityGoodsID = function(self, pageId, goodIds)
    for i,v in ipairs(goodIds) do
        local good_temp = CElementData.GetTemplate("Goods", v)
        if good_temp ~= nil then
            if good_temp.Stock > 0 then
                if good_temp.Stock > GetBuyCount(self, pageId, v) then
                    return i,v
                end
            else
                return i,v
            end
        end
    end
    return #goodIds, goodIds[#goodIds]
end

-- 上线之后得到服务器发送过来的数据就把活动商城的红点更新出来
local UpdateSynDataRedPoint = function(self)
    local active_datas = self:GetOpenActivityData()
    local new_red_state = {}
    for i,v in ipairs(active_datas) do
        new_red_state[v.Id] = true
    end
    self:UpdateActivityMallPageRedPointStates(new_red_state)
end

local SendActivityMallDataChangeEvent = function(self)
    local ActivityMallDataChangeEvent = require "Events.ActivityMallDataChangeEvent"
    local event = ActivityMallDataChangeEvent()
    CGame.EventManager:raiseEvent(nil, event)
end


local RemoveTimeRightCheckTimer = function(self)
    if self._ActivityDataTimers ~= nil then
        for i,v in pairs(self._ActivityDataTimers) do
            _G.RemoveGlobalTimer(v)
        end
    end
    self._ActivityDataTimers = nil
end

local AddTimeRightCheckTimer = function(self)
    if self._ActivityPagesData == nil or self._ActivityPagesData.AccountTemplateRecords == nil then return end
    RemoveTimeRightCheckTimer(self)
    self._ActivityDataTimers = {}
    local start_time = GameUtil.GetServerTime()

    for i,v in ipairs(self._ActivityPagesData.AccountTemplateRecords) do
        if start_time < v.StartTime then
            local callback = function()
                v.IsOpen = true
                SendActivityMallDataChangeEvent(self)
                self:UpdateActivityMallPageRedPointState(v.Id, true)
            end
            self._ActivityDataTimers[v.Id] = _G.AddGlobalTimer((v.StartTime - start_time)/1000, true, callback)
        elseif start_time < v.EndTime then
            local callback = function()
                v.IsOpen = false
                SendActivityMallDataChangeEvent(self)
                self:UpdateActivityMallPageRedPointState(v.Id, false)
            end
            self._ActivityDataTimers[v.Id] = _G.AddGlobalTimer((v.EndTime - start_time)/1000, true, callback)
        end
    end
end


-- 解析活动商城角色数据和模板数据
local ParseActivityMallDatas = function(msg)
    local new_msg = {}
    new_msg.ActivityGoodsDatas = {}
    new_msg.AccountTemplateRecords = {}
    if msg.ActivityGoodsDatas then
        for i,v in ipairs(msg.ActivityGoodsDatas) do
            local item = {}
            item.AtStoreTid = v.AtStoreTid
            item.GoodsId = v.GoodsId
            item.BuyCount = v.BuyCount ~= nil and v.BuyCount or 0
            new_msg.ActivityGoodsDatas[#new_msg.ActivityGoodsDatas + 1] = item
        end
    end
    
    if msg.AccountTemplateRecords then
        for i,v in ipairs(msg.AccountTemplateRecords) do
            local item = {}
            item.Id = v.Id
            item.ActivityStoreType = v.ActivityStoreType ~= nil and v.ActivityStoreType or 0
            item.Switch = v.Switch ~= nil and v.Switch or false
            item.MinLevel = v.MinLevel ~= nil and v.MinLevel or 0
            item.MaxLevel = v.MaxLevel ~= nil and v.MaxLevel or 0
            item.StartTime = v.StartTime ~= nil and v.StartTime or 0
            item.EndTime = v.EndTime ~= nil and v.EndTime or 0
            item.GoodsList = {}

            if v.GoodsList then
                for k,w in ipairs(v.GoodsList) do
                    item.GoodsList[#item.GoodsList + 1] = w
                end
            end
            new_msg.AccountTemplateRecords[#new_msg.AccountTemplateRecords + 1] = item
        end
    end
    return new_msg
end

local TimeIsOk = function(startTime, endTime)
    local now_time = GameUtil.GetServerTime()
    if now_time > startTime and now_time < endTime then
        return true
    end
    return false
end

local LevelCheck = function(minLevel, maxLevel)
    local hp = game._HostPlayer
    local now_level = hp._InfoData._Level
    if now_level >= minLevel and now_level <= maxLevel then
        return true
    end
    return false
end

local CheckIsOpen = function(v)
    if v.Switch and TimeIsOk(v.StartTime, v.EndTime) and LevelCheck(v.MinLevel, v.MaxLevel) and v.HasBuyOver == false then
        return true
    end
    return false
end

local UpdateAdditionValues = function(self)
    for i,item in ipairs(self._ActivityPagesData.AccountTemplateRecords) do
        repeat
            local page_temp = CElementData.GetTemplate("ActivityStore", item.Id)
            if page_temp == nil then
                warn("error !! ActivityStore 模板数据为空 ！！！ " , item.Id)
                item.IsMultGoods = false
                break
            end
            item.IsMultGoods = page_temp.ActivityStoreType == EActivityStoreType.StageStore
            if item.IsMultGoods then
                item.CurGoodsIndex, item.CurGoodsId = GetCurActivityGoodsID(self, item.Id, item.GoodsList)
            else
                item.CurGoodsIndex = 1
                item.CurGoodsId = item.GoodsList[1]
            end
            local good_temp = CElementData.GetTemplate("Goods", item.CurGoodsId)
            if good_temp then
                if good_temp.Stock > 0 then
                    item.HasBuyOver = (item.CurGoodsIndex >= #item.GoodsList and GetBuyCount(self, item.Id, item.CurGoodsId) >= good_temp.Stock)
                else
                    item.HasBuyOver = false
                end
            else
                item.HasBuyOver = false
            end
            if CheckIsOpen(item) then
                item.IsOpen = true
            else
                item.IsOpen = false
            end
        until true;
    end
end


-- 得到开启的活动数据
def.method("=>", "table").GetOpenActivityData = function(self)
    local opened_data = {}
    if self._ActivityPagesData == nil or self._ActivityPagesData.AccountTemplateRecords == nil then
        warn("error !!! 服务器并没有把推荐商品信息发送过来")
        return opened_data
    end
    for i,v in ipairs(self._ActivityPagesData.AccountTemplateRecords) do
        if v.IsOpen then
            opened_data[#opened_data + 1] = v
        end
    end
    return opened_data
end

-- 得到活动商品的购买数量
def.method("number", "number", "=>", "number").GetActivityMallGoodsBuyCount = function(self, activityID, goodsID)
    if self._ActivityPagesData == nil or self._ActivityPagesData.ActivityGoodsDatas == nil then
        warn("error !!! 服务器并没有把推荐商品信息发送过来")
        return 0
    end
    for i,v in ipairs(self._ActivityPagesData.ActivityGoodsDatas) do
        if v.AtStoreTid == activityID and v.GoodsId == goodsID then
            return v.BuyCount
        end
    end
    return 0
end

def.method("number", "=>", "table").GetActivityGoodsTempData = function(self, pageID)
    for i,v in ipairs(self._ActivityPagesData.AccountTemplateRecords) do
        if v.Id == pageID then
            return v
        end
    end
    return nil
end

-- 更新活动商品的购买数量
def.method("number", "number", "number").UpdateActivityMallGoodsBuyCount = function(self, activityID, goodsID, count)
    if self._ActivityPagesData == nil or self._ActivityPagesData.ActivityGoodsDatas == nil then
        warn("error !!! 服务器并没有把推荐商品信息发送过来")
        return
    end
    local is_finded = false
    for i,v in ipairs(self._ActivityPagesData.ActivityGoodsDatas) do
        if v.AtStoreTid == activityID and v.GoodsId == goodsID then
            is_finded = true
            v.BuyCount = count
        end
    end
    if not is_finded then
        local item = {}
        item.AtStoreTid = activityID
        item.GoodsId = goodsID
        item.BuyCount = count
        self._ActivityPagesData.ActivityGoodsDatas[#self._ActivityPagesData.ActivityGoodsDatas + 1] = item
    end
    UpdateAdditionValues(self)
end

-- 主角升级的回调函数
def.method().OnActivityMallHandleLevelUp = function(self)
    if self._ActivityPagesData == nil or self._ActivityPagesData.AccountTemplateRecords == nil then
        warn("error !!! 服务器并没有把推荐商品信息发送过来")
        return
    end
    local host_level = game._HostPlayer._InfoData._Level
    local change_table = {}
    for i,v in ipairs(self._ActivityPagesData.AccountTemplateRecords) do
        if not v.IsOpen and CheckIsOpen(v) then
            v.IsOpen = true
            local item = {}
            item.Id = v.Id
            item.State = true
            change_table[#change_table + 1] = item
        elseif v.IsOpen and (not CheckIsOpen(v)) then
            v.IsOpen = false
            local item = {}
            item.Id = v.Id
            item.State = false
            change_table[#change_table + 1] = item
        end
    end
    if #change_table > 0 then
        SendActivityMallDataChangeEvent(self)
        for i,v in ipairs(change_table) do
            self:UpdateActivityMallPageRedPointState(v.Id, v.State)
        end
    end
end


-- 更新活动商店的红点状态们。
def.method("table").UpdateActivityMallPageRedPointStates = function(self, states)
    local redPointMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.ActivityMall)
    if states == nil then
        redPointMap = {}
    else
        redPointMap = states
    end
    CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.ActivityMall, redPointMap)
    for _,v in pairs(redPointMap) do
        if v == true then
            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.ActivityMall,true)
            return
        end
    end
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.ActivityMall,false)
end

-- 更新活动商店的红点状态。
def.method("number", "boolean").UpdateActivityMallPageRedPointState = function(self, pageID, state)
    local redPointMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.ActivityMall)
    if redPointMap == nil then 
        redPointMap = {}
    end
    redPointMap[pageID] = state
    CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.ActivityMall, redPointMap)
    for _,v in pairs(redPointMap) do
        if v == true then
            CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.ActivityMall,true)
            return
        end
    end
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.ActivityMall,false)
end

-- 获得活动商店page的红点状态
def.method("number", "=>", "boolean").GetActivityMallPageRedPointState = function(self, pageID)
    local redPointMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.ActivityMall)
    if redPointMap == nil or redPointMap[pageID] == nil then
        return false
    end
    return redPointMap[pageID]
end

-- 请求活动商城数据
def.method().RequestActivitySynData = function(self)
    local C2SAtStoreSyncReq = require "PB.net".C2SAtStoreSyncReq
    local protocol = C2SAtStoreSyncReq()
    SendProtocol(protocol)
end


-- 收到上线的时候活动商城的数据
def.method("table").HandleActivitySynData = function(self, msg)
    self._ActivityPagesData = ParseActivityMallDatas(msg)
    UpdateAdditionValues(self)
    UpdateSynDataRedPoint(self)
    AddTimeRightCheckTimer(self)
    SendActivityMallDataChangeEvent(self)
end

-- 购买活动商品的返回消息
def.method("table").HandleBuyActivityGoods = function(self, msg)
    local pre_count = self:GetActivityMallGoodsBuyCount(msg.AtStoreTid, msg.GoodsId)
    local now_count = pre_count + msg.Count
    self:UpdateActivityMallGoodsBuyCount(msg.AtStoreTid, msg.GoodsId, now_count)
    SendActivityMallDataChangeEvent(self)
end

------------------------------------------活动商城 End ------------------------------------------------

def.method().Cleanup = function(self)
    RemoveTimeRightCheckTimer(self)
    self._IsMallRoleInfoInited = false
    self._MallRoleInfo = nil
    self._TabDatasFromServer = nil
    self._BannerDatas = nil
    self._IsFirstLoad = true
    self._MallLotteryCache = nil
    CGame.EventManager:removeHandler(GainNewItemEvent, OnGainNewItemEvent)
    CGame.EventManager:removeHandler(NotifyFunctionEvent, OnSystemUnlockEvent)
    CGame.EventManager:removeHandler('HostPlayerLevelChangeEvent', OnHostPlayerLevelChangeEvent)
    instance = nil
end

CMallMan.Commit()
return CMallMan