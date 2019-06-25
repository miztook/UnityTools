
local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"

local bit = require "bit"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require("Data.CElementData")
local ENpcSaleType = require"PB.data".ENpcSaleType
local ENpcSaleLimitType = require"PB.data".ENpcSaleLimitType
local EResourceType = require "PB.data".EResourceType
local EItemEventType = require "PB.data".EItemEventType
local EItemType = require "PB.Template".Item.EItemType
local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
local ESaleType = require "PB.data".ESaleType
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPanelNpcShop = Lplus.Extend(CPanelBase, "CPanelNpcShop")
local DynamicText = require "Utility.DynamicText"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CCommonBtn = require "GUI.CCommonBtn"
local CCommonNumInput = require "GUI.CCommonNumInput"
local CMallUtility = require "Mall.CMallUtility"

local def = CPanelNpcShop.define
local EShopType = require "PB.data".EShopType
--local GlobalDefinition = require "PB.data".GlobalDefinition()

local OpenShopType = {
    FROMUI = 1,
  	FROMNPC = 2,
}

def.field("table")._ShopData = nil
def.field("table")._ShowShop = nil 
def.field("table")._CurrentShopAllItems = nil
def.field("table")._CurrentItemsData = BlankTable
def.field("table")._CurrentSubShopBuyInfo = nil
def.field("number")._CurNumber = 1
def.field("number")._UnitPrice = 0
def.field("number")._HavenMoney = 0
def.field('number')._MaxNumber = 0
def.field("number") ._TotalPrice = 0
def.field("number")._BuyId = 0
def.field("number")._CostMoneyID = 0        -- 当前购买需要花费的MoneyID
def.field("number")._CurrentBigShopID = -1  -- 记录当前打开的父商店ID
def.field("number")._CurrentSubShopID = -1  -- 记录当前打开的子商店ID
def.field("number")._CurItemIndex = 0       -- 记录前一个选中的Item index
def.field("number")._CurSubShopIndex = 1    -- 记录当前选中的子商店index
def.field("number")._CurBigShopIndex = 1    -- 记录当前选中的父商店index
def.field("userdata")._BeforeItem = nil     -- 上次高亮的物品item
def.field("userdata")._BeforeMenuItem = nil -- 上次高亮的menuItem
def.field("number")._OpenTargetId = 0       -- 任务开启目标ID
def.field("number")._OpenTargetCount = 1    -- 任务开启目标需求数量
def.field("boolean")._IsQuestAutoBuy = false   -- 是不是任务自动化发起的
def.field("boolean")._NeedScrollDrump = false  -- 是否需要直接选中Item
def.field("number")._QuestAutoBuyItemId = 0 -- 自动任务购买道具Id
def.field("number")._OpenType = 1           -- 打开界面的由来（npc还是UI）
def.field("number")._AutoRefreshTimer = 0   -- 商店自动刷新timer
def.field(CFrameCurrency)._Frame_Money = nil
def.field(CCommonBtn)._Btn_Buy = nil
def.field(CCommonNumInput)._Num_Input = nil
def.field("boolean")._IsSatisfyCondition = false
def.field("boolean")._IsTabOpen = true
def.field("table")._HostPlayerReputations = nil 

def.field("table")._PanelObject = nil

local instance = nil
def.static("=>", CPanelNpcShop).Instance = function()
	if not instance then
		instance = CPanelNpcShop()
		instance._PrefabPath = PATH.UI_NPCShop
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._PanelObject = {}
	self._PanelObject._MenuTabList = self:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)
	self._PanelObject._List_Item = self:GetUIObject("List_Item")
	self._PanelObject._LeftTipPosition = self:GetUIObject("LeftTipPosition")
	self._PanelObject._RightTipPosition = self:GetUIObject("RightTipPosition")
	self._PanelObject._LabRefreshTimeTips = self:GetUIObject("Lab_RefreshTimeTips")
	self._PanelObject._LabItemName = self:GetUIObject("Lab_ItemName1")
	self._PanelObject._LabItemDescription = self:GetUIObject("Lab_ItemDescription")
	self._PanelObject._Lab_ItemNumber = self:GetUIObject("Lab_ItemNumber")
    self._PanelObject._LabTotal = self:GetUIObject("Lab_Total")
	self._PanelObject._ImgMoney1 = self:GetUIObject("Img_TotalMoney")
    self._PanelObject._BtnRefresh = self:GetUIObject("Btn_Refresh")
    self._PanelObject._LabRefreshCost = self:GetUIObject("Lab_RefreshCost")
    self._PanelObject._Img_CostMoney = self:GetUIObject("Img_CostMoney")
    self._PanelObject._Btn_Buy = self:GetUIObject("Btn_Buy")
    self._PanelObject._Item_Icon = self:GetUIObject("ItemIconNew")
    self._PanelObject._LabLevel = self:GetUIObject("Lab_Level")
    self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    local setting = {
       [EnumDef.CommonBtnParam.MoneyID] = 1,
       [EnumDef.CommonBtnParam.MoneyCost] = 0   
    }
    self._Btn_Buy = CCommonBtn.new(self._PanelObject._Btn_Buy, setting)
    local onCountChange = function(count)
        self._CurNumber = count
        self:UpdateBuyInfoPanel()
    end
    self._Num_Input = CCommonNumInput.new(self:GetUIObject("Frame_NumInput"), onCountChange, 1, 99)
end

--接收数据 
--panelData = 
-- {
-- 	--OpenType = (OpenShopType.FROMUI / OpenShopType.FROMNPC)   --打开方式
-- 	--ShopId ,      --父商店ID
    --SubShopId     --子商店ID
    --ItemId,       --物品ID  
    --RepID,        --声望ID
    --Count,        --所需数量（仅针对道具有效）
    --IsAuto        --自动购买（自动任务触发）
-- }
def.override("dynamic").OnData = function(self, data)
	self._HelpUrlType = HelpPageUrlType.NPCShop
    self._CurItemIndex = 0
    self._CurNumber = 1
    if data.OpenType then
        self._OpenType = data.OpenType
    else
        self._OpenType = OpenShopType.FROMUI
    end
	self:GetDataFromTemplate()
    self:FilterAndChoseShopByData(data)
	self._OpenTargetId = data.ItemId or 0
	self._OpenTargetCount = data.Count or 1	
    self._IsQuestAutoBuy = data.IsAuto or false
    if self._IsQuestAutoBuy then
        self._QuestAutoBuyItemId = data.ItemId
    else
        self._QuestAutoBuyItemId = 0
    end
    self._CurrentBigShopID = self._CurrentBigShopID < 0 and self._ShowShop[self._CurBigShopIndex].ShopId or self._CurrentBigShopID
    self._CurrentSubShopID = self._CurrentSubShopID < 0 and self._ShowShop[self._CurBigShopIndex].NpcSaleSubs[self._CurSubShopIndex].SubShopId or self._CurrentSubShopID
	self._HostPlayerReputations = game._CReputationMan:GetAllReputation()
	self._PanelObject._MenuTabList:SetItemCount(#self._ShowShop)
    self:GetCurrentShopAllItems()
    self:SendC2SNpcSaleSyncReq()
    self:UpdateMoneyFrame()
    self._IsTabOpen = false
    self._PanelObject._MenuTabList:OpenTab(#self._ShowShop[self._CurBigShopIndex].NpcSaleSubs)
    self._PanelObject._MenuTabList:SelectItem(self._CurBigShopIndex - 1, self._CurSubShopIndex - 1)

    if self._IsQuestAutoBuy then
        CQuestAutoMan.Instance():Pause(_G.PauseMask.UIShown)
    end
end

--更新货币栏
def.method().UpdateMoneyFrame = function(self)
    if self._CurrentBigShopID == 4 then
        self._Frame_Money:Init(EnumDef.MoneyStyleType.BucketShop)
    elseif self._CurrentBigShopID == 16 then
        self._Frame_Money:Init(EnumDef.MoneyStyleType.GloryShop)
    elseif self._CurrentBigShopID == 17 then
        self._Frame_Money:Init(EnumDef.MoneyStyleType.FearlessShop)
    elseif self._CurrentBigShopID == 9 then
        self._Frame_Money:Init(EnumDef.MoneyStyleType.ReputationShop)
    elseif self._CurrentBigShopID == 23 then
        if self._CurrentSubShopID == 1 then
            self._Frame_Money:Init(EnumDef.MoneyStyleType.SmallCharmShop)
        elseif self._CurrentSubShopID == 2 then
            self._Frame_Money:Init(EnumDef.MoneyStyleType.BigCharmShop)
        else
            self._Frame_Money:Init(EnumDef.MoneyStyleType.None)
        end
    else
        self._Frame_Money:Init(EnumDef.MoneyStyleType.None)
    end
    self._Frame_Money:Update()
end

----------------------------------------------------------------------
--针对大商店或者小商店排序
----------------------------------------------------------------------
def.method("table").SortShops = function(self, shops)
    local func = function(it1, it2)
        return it1.Sort < it2.Sort
    end
    table.sort(shops, func)
end


----------------------------------------------------------------------
--针对商店配置的显示与否和开启条件进行第一次过滤，存入self._ShopData中
----------------------------------------------------------------------
def.method().GetDataFromTemplate = function (self)
	self._ShopData = {}
	local allIDs = GameUtil.GetAllTid("NpcSale")
    local hp_level = game._HostPlayer._InfoData._Level
	for i,v in pairs(allIDs) do
		repeat
			local shopItem = CElementData.GetTemplate("NpcSale", v)
            if shopItem == nil then
                warn("error !!!! 商店ID不存在 ID: ",v)
                break
            end
            if shopItem.IsNotShow and self._OpenType == OpenShopType.FROMUI then break end
			self._ShopData[#self._ShopData + 1] = {}
			self._ShopData[#self._ShopData].ShopId = shopItem.Id
            self._ShopData[#self._ShopData].Name = shopItem.Name
            self._ShopData[#self._ShopData].Sort = shopItem.Sort
            self._ShopData[#self._ShopData].NpcSaleSubs = {}
            if shopItem.NpcSaleSubs then
                if #shopItem.NpcSaleSubs == 1 then 
                    self._ShopData[#self._ShopData].IsHideSubMenu = true 
                else
                    self._ShopData[#self._ShopData].IsHideSubMenu = false
                end 
                for i1,v1 in ipairs(shopItem.NpcSaleSubs) do
                    repeat
                        if v1.IsNotShow and self._OpenType == OpenShopType.FROMUI then break end
                        if v1.NpcSaleType == ENpcSaleType.Level then 
				            if game._HostPlayer._InfoData._Level < v1.NpcSaleParam then break end
			            end
			            if v1.NpcSaleType == ENpcSaleType.Guild then 
				            if not game._GuildMan:IsHostInGuild() then break end 
			            end

                        local npc_sale_subs = self._ShopData[#self._ShopData].NpcSaleSubs
                        npc_sale_subs[#npc_sale_subs + 1] = {}
                        npc_sale_subs[#npc_sale_subs].SubShopId = v1.Id
                        npc_sale_subs[#npc_sale_subs].Name = v1.Name
                        npc_sale_subs[#npc_sale_subs].RefreshTime = v1.RefreshTime
                        npc_sale_subs[#npc_sale_subs].NpcSaleType = v1.NpcSaleType
                        npc_sale_subs[#npc_sale_subs].NpcSaleParam = v1.NpcSaleParam
                        npc_sale_subs[#npc_sale_subs].Sort = v1.Sort
                        npc_sale_subs[#npc_sale_subs].SaleType = v1.SaleType
                        npc_sale_subs[#npc_sale_subs].SaleCount = v1.SaleCount
                        npc_sale_subs[#npc_sale_subs].ResetTime = v1.ResetTime
                        npc_sale_subs[#npc_sale_subs].ResetCostMoneyIds = v1.ResetCostMoneyIds
                        npc_sale_subs[#npc_sale_subs].ResetCostMoneyCounts = v1.ResetCostMoneyCounts
                        npc_sale_subs[#npc_sale_subs].NpcSaleItems = {}
                        if v1.NpcSaleItems then
                            for i2,v2 in ipairs(v1.NpcSaleItems) do
                                repeat
                                    local itemTemp = CElementData.GetItemTemplate(v2.ItemId)
                                    if itemTemp == nil then warn("error 物品不存在，id是", v2.ItemId) break end
                                    local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
                                    if profMask ~= bit.band(itemTemp.ProfessionLimitMask, profMask) then 
						                break
					                end
                                    if itemTemp.MaxLevelLimit < hp_level then break end
                                    npc_sale_subs[#npc_sale_subs].NpcSaleItems[#npc_sale_subs[#npc_sale_subs].NpcSaleItems + 1] = v2
                                until true;
                            end
                        end
                    until true;
                end
            end
            self:SortShops(self._ShopData[#self._ShopData].NpcSaleSubs)
            if #self._ShopData[#self._ShopData].NpcSaleSubs == 0 then
                self._ShopData[#self._ShopData] = nil
            end
		until true
	end
    self:SortShops(self._ShopData)
    
end

def.method("number", "number", "=>", "table").GetSubShopInfoByTidAndSubId = function(self, tid, subID)
    for _,v in ipairs(self._ShopData) do
        if tid == v.ShopId then
            for _1,v1 in ipairs(v.NpcSaleSubs) do
                if subID == v1.SubShopId then
                    return v1
                end
            end
        end
    end
    return nil
end

-----------------------------------------------------------------------
-- 第二次过滤商店数据，根据传过来的参数，决定跳转到哪个shop
-----------------------------------------------------------------------
def.method("table").FilterAndChoseShopByData = function(self, data)
    self._ShowShop = {}
    if data.OpenType  == OpenShopType.FROMUI then
    	self._ShowShop = self._ShopData 
        local find = false
        for i,v in ipairs(self._ShowShop) do
            if data.ShopId ~= nil and v.ShopId == data.ShopId and data.ShopId ~= 9 then
                self._CurBigShopIndex = i
                self._CurrentBigShopID = data.ShopId
                for i1, v1 in ipairs(v.NpcSaleSubs) do
                    if v1.SubShopId == data.SubShopId then
                        self._CurSubShopIndex = i1
                        self._CurrentSubShopID = data.SubShopId
                    end
                end
                find = true
            end
            if data.ShopId ~= nil and data.ShopId == 9--[[ENpcSaleServiceType.NpcSale_Repatation]] then
                for i1, v1 in ipairs(v.NpcSaleSubs) do
                    if find then break end
                    for i2, v2 in ipairs(v1.NpcSaleItems) do
                        if find then break end
                        if v2.ReputationType == data.RepID then
                            self._CurBigShopIndex = i
                            self._CurrentBigShopID = v.ShopId
                            self._CurSubShopIndex = i1
                            self._CurrentSubShopID = v1.SubShopId
                            self._CurItemIndex = i2 - 1
                            find = true
                        end
                    end
                end
            end
            if find then break end
        end
	elseif data.OpenType == OpenShopType.FROMNPC then
		for i,v in pairs(self._ShopData) do
			if data.ShopId == v.ShopId then 
				self._CurBigShopIndex = 1
				self._ShowShop[#self._ShowShop + 1] = v
			end
		end
	end
end

----------------------------------------------------------------------
--根据当前选中的商店提取出可以购买的物品
----------------------------------------------------------------------
def.method().GetCurrentShopAllItems = function (self)
	self._CurrentShopAllItems = {}
	local items = nil
	for i,v in ipairs(self._ShowShop) do 
		if self._CurrentBigShopID == v.ShopId then 
            for i1,v1 in ipairs(v.NpcSaleSubs) do
                if self._CurrentSubShopID == v1.SubShopId then
        			items = v1
                end
            end
		end
	end
    if items ~= nil then
        for i,v in ipairs(items.NpcSaleItems) do
            self._CurrentShopAllItems[#self._CurrentShopAllItems + 1] = v
        end
    else
        warn("Error -- CPanelNpcShop.GetCurrentShopAllItems -- Can not find shop data: shopId "..self._CurrentBigShopID.." subShopId "..self._CurrentSubShopID)
    end
end

----------------------------------------------------------------------
--当前能否时候这个物品<itemId>物品ID</itemId>
----------------------------------------------------------------------
def.method("number","=>","boolean").CanUse = function (self,itemId)
	local itemTemplate = CElementData.GetItemTemplate(itemId)
	local infoData = game._HostPlayer._InfoData
	--职业限制
	local profMask = EnumDef.Profession2Mask[infoData._Prof]
	if profMask ~= bit.band(itemTemplate.ProfessionLimitMask, profMask) then return false end
	-- 性别限制
	local gender =  Profession2Gender[infoData._Prof]
	if itemTemplate.GenderLimitMask ~= 2 and itemTemplate.GenderLimitMask ~= gender then return false end
	-- 等级限制
	if infoData._Level < itemTemplate.MinLevelLimit or infoData._Level > itemTemplate.MaxLevelLimit then return false end
	return true	
end

----------------------------------------------------------------------
--更新购买物品的item的显示<index>物品Index</index>
----------------------------------------------------------------------
def.method().UpdateBuyInfoPanel = function (self)
    local index = self._CurItemIndex
    self._Btn_Buy:SetInteractable(true)
    self._Btn_Buy:MakeGray(false)
    self._Num_Input:SetInteractable(true)
    local interactable = true
    local no_limit = false
    local cost_money_id = self._CurrentItemsData[index + 1].CostMoneyId
    local uni_price = self._CurrentItemsData[index + 1].CostMoneyNum
    local have_count = game._HostPlayer:GetMoneyCountByType(cost_money_id)
    local can_pay_count = math.floor(have_count/uni_price)
    if index < 0 then
        interactable = false
    end
    -- 判断条件是否满足
    if self._CurrentItemsData[index + 1].IsLevel then 
   		if game._HostPlayer._InfoData._Level < self._CurrentItemsData[index + 1].Level then
   			self._CurNumber = 1
            self._MaxNumber = 1
            interactable = false
		end	
    end
    if self._CurrentItemsData[index + 1].IsStage then
   		if game._HostPlayer._InfoData._Arena3V3Stage < self._CurrentItemsData[index + 1].StageLevel then 
	    	self._CurNumber = 1
            self._MaxNumber = 1
            interactable = false
   		end 	
    end
    if self._CurrentItemsData[index + 1].IsReputation then
    	local is_locked = true
    	for i,v in pairs(self._HostPlayerReputations) do 
   			if i == self._CurrentItemsData[index + 1].ReputationType then
   				if v.Level >= self._CurrentItemsData[index + 1] .ReputationLevel then 
   					is_locked = false
   				end
   			end
   		end
   		if is_locked then 
	   		self._CurNumber = 1
            self._MaxNumber = 1
            interactable = false
		end
    end
    -- 判断剩余数量 0置灰无效按钮
    if self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.DayRefresh or self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.Forever then
	    if self._CurrentItemsData[index + 1].LimitCount > 0 then
            local buy_count = self:GetBuyCountByDetialID(self._CurrentItemsData[index + 1].Id)
	    	self._BuyId = self._CurrentItemsData[index + 1].Id
            if CMallUtility.GetQuickBuyTid(cost_money_id, true) > 0 then
                self._MaxNumber = math.max(self._CurrentItemsData[index + 1].LimitCount - buy_count, 0)
            else
                self._MaxNumber = math.min(can_pay_count, math.max(self._CurrentItemsData[index + 1].LimitCount - buy_count, 0))
            end
	    else
	    	self._CurNumber = 1
            self._MaxNumber = 1
            interactable = false
	    end
	elseif self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.NoLimit then 
        local buy_count = self:GetBuyCountByDetialID(self._CurrentItemsData[index + 1].Id)
        local can_buy_count = 0
        if CMallUtility.GetQuickBuyTid(cost_money_id, true) > 0 then
        	self._MaxNumber = 99
        else
            self._MaxNumber = can_pay_count
        end
		self._BuyId = self._CurrentItemsData[index + 1].Id
        no_limit = true
	end
    self._MaxNumber = math.max(self._MaxNumber, 1)
    self._CurNumber = math.min(self._CurNumber, self._MaxNumber)
    self._CurNumber = math.max(self._CurNumber, 1)
	local itemId = self._CurrentItemsData[index + 1].ItemId			
	local item = CElementData.GetItemTemplate(itemId)
    local buy_count = self:GetBuyCountByDetialID(self._CurrentItemsData[index + 1].Id)
	GUI.SetText(self._PanelObject._LabItemName, self:GetItemNameRichText(itemId))
    GUI.SetText(self._PanelObject._Lab_ItemNumber, no_limit and StringTable.Get(8086) or tostring(self._MaxNumber))
    GUI.SetText(self._PanelObject._LabLevel, string.format(StringTable.Get(10657), item.InitLevel))
	IconTools.InitItemIconNew(self._PanelObject._Item_Icon, itemId, nil, EItemLimitCheck.AllCheck)

	--GameUtil.SetOutlineColor(EnumDef.Quality2ColorHexStr[item.InitQuality],self._PanelObject._LabItemName)
	if item.ItemType == EItemType.Rune then 
		if item.EventType1 == EItemEventType.ItemEvent_Rune then 
	        local runeTemplate = CElementData.GetRuneTemplate(tonumber(item.Type1Param1))
	        if runeTemplate ~= nil then
	            local str = DynamicText.ParseRuneDescText(tonumber(item.Type1Param1),tonumber(item.Type1Param2)) 
	            GUI.SetText(self._PanelObject._LabItemDescription, str)
		    else 
		        warn("RuneTemplate is nil :" .. item.Type1Param1)
		    end
		end
	else
		GUI.SetText(self._PanelObject._LabItemDescription,item.TextDescription)
	end

	local moneyItem = CElementData.GetMoneyTemplate(self._CurrentItemsData[index + 1].CostMoneyId)
	if moneyItem ==  nil then 
		warn("MoneyItemId is ",self._CurrentItemsData[index + 1].CostMoneyId,"  nil")
	else
    	-- todo(GetMoneyCountByType,方法需要添加其他货币数量)
        self._CostMoneyID = self._CurrentItemsData[index + 1].CostMoneyId
        self._UnitPrice = self._CurrentItemsData[index + 1].CostMoneyNum
        self._TotalPrice = self._UnitPrice *self._CurNumber
        local have_count = game._HostPlayer:GetMoneyCountByType(self._CostMoneyID)
	    GUI.SetText(self._PanelObject._LabTotal,tostring(have_count))
        GUITools.SetTokenMoneyIcon(self._PanelObject._ImgMoney1, self._CostMoneyID)
        local setting = {
                [EnumDef.CommonBtnParam.MoneyID] = self._CostMoneyID,
                [EnumDef.CommonBtnParam.MoneyCost] = self._TotalPrice,
            }
        self._Btn_Buy:ResetSetting(setting)
        self._Num_Input:ResetMinAndMaxCount(1, self._MaxNumber)
        if not interactable then
--            self._Btn_Buy:SetInteractable(false)
            self._Btn_Buy:MakeGray(true)
            self._Num_Input:SetCountWithOutCb(self._CurNumber)
--            self._Num_Input:SetInteractable(false)
        end
    end    
end

def.method().OnClickBtnBuy = function(self)
    local index = self._CurItemIndex
    if index < 0 then
        return
    end
    -- 判断条件是否满足
    if self._CurrentItemsData[index + 1].IsLevel then 
   		if game._HostPlayer._InfoData._Level < self._CurrentItemsData[index + 1].Level then
            game._GUIMan:ShowTipText(StringTable.Get(22314), true)
            return
		end	
    end
    if self._CurrentItemsData[index + 1].IsStage then
   		if game._HostPlayer._InfoData._Arena3V3Stage < self._CurrentItemsData[index + 1].StageLevel then 
            game._GUIMan:ShowTipText(StringTable.Get(22315), true)
            return
   		end 	
    end
    if self._CurrentItemsData[index + 1].IsReputation then
    	local is_locked = true
    	for i,v in pairs(self._HostPlayerReputations) do 
   			if i == self._CurrentItemsData[index + 1].ReputationType then
   				if v.Level >= self._CurrentItemsData[index + 1] .ReputationLevel then 
   					is_locked = false
   				end
   			end
   		end
   		if is_locked then 
            game._GUIMan:ShowTipText(StringTable.Get(22316), true)
            return
		end
    end
    -- 判断剩余数量 0置灰无效按钮
    if self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.DayRefresh or self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.Forever then
	    if self._CurrentItemsData[index + 1].LimitCount <= 0 then
            game._GUIMan:ShowTipText(StringTable.Get(22317), true)
            return
	    end
	end
    local callback = function(val)
        if val then
            self:SendC2SNpcSaleBuyReq()
        end
    end
    MsgBox.ShowQuickBuyBox(self._CostMoneyID, self._TotalPrice, callback)
end

def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
    if self._Btn_Buy:OnClick(id) then
        self:OnClickBtnBuy()
    elseif self._Num_Input:OnClick(id) then
        return
	elseif self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
		return
    elseif id == "Btn_Question" then
        TODO(StringTable.Get(19))
	elseif id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
		game._GUIMan:Close("CPanelNumberKeyboard")
	elseif id == 'Btn_Exit' then
		game._GUIMan:Close("CPanelNumberKeyboard")
    	game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Refresh" then
        local cur_sub_shop = self:GetSubShopInfoByTidAndSubId(self._CurrentBigShopID, self._CurrentSubShopID)
        if cur_sub_shop ~= nil then
            if cur_sub_shop.SaleType == ESaleType.ESaleType_Normal then
                return
            elseif cur_sub_shop.SaleType == ESaleType.ESaleType_Random then
                local cost_types = string.split(cur_sub_shop.ResetCostMoneyIds, "*")
                local cost_counts = string.split(cur_sub_shop.ResetCostMoneyCounts, "*")
                local buy_count = self._CurrentSubShopBuyInfo.ResetCount
                if #cost_counts ~= #cost_types then warn("随机商店刷新时间配置错误") return end
                if buy_count >= #cost_types then
                    game._GUIMan:ShowTipText(StringTable.Get(31803),false)
                else
                    self:SendC2SSubShopRefresh()
                end
            end
        end
	end 

end

def.method("number", "=>", "boolean").IsItemLockByIndex = function(self, index)
    local lock = false
    if self._CurrentItemsData[index].IsLevel then 
       	if game._HostPlayer._InfoData._Level < self._CurrentItemsData[index].Level then
            lock = true
       	end
    end
    if self._CurrentItemsData[index].IsStage then
       	local stageItem = CElementData.GetPVP3v3Template(self._CurrentItemsData[index].StageLevel)
       	if game._HostPlayer._InfoData._Arena3V3Stage < self._CurrentItemsData[index].StageLevel then 
            lock = true
       	end
    end
    if self._CurrentItemsData[index].IsReputation then
        local is_rep_locked = true 
       	for i,v in pairs(self._HostPlayerReputations) do 
       		if i == self._CurrentItemsData[index].ReputationType then
       			if v.Level >= self._CurrentItemsData[index] .ReputationLevel then 
       				is_rep_locked = false
       			end
       		end
       	end
        if is_rep_locked then
            lock = true
        end
    end
    return lock
end

def.method("number", "=>", "string").GetItemNameRichText = function(self, tid)
    local itemTemplate = CElementData.GetItemTemplate(tid)
    if itemTemplate == nil then warn("获取物品名称错误，没有该物品", tid) return "" end
    local richText = "<color=#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality]..">"..itemTemplate.TextDisplayName.."</color>"
    return richText
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if id == "List_Item" then
        local uiItem = uiTemplate:GetControl(1)
        local imgHighLight = uiTemplate:GetControl(0)
        local labLimitCandition = uiTemplate:GetControl(3)
        local labItemName = uiTemplate:GetControl(2)
        local labPrice = uiTemplate:GetControl(4)
        local imgMoney = uiTemplate:GetControl(5)
        local labMaxNumber = uiTemplate:GetControl(6)
        local imgSellOut = uiTemplate:GetControl(7)
        local imgSellOutBG = uiTemplate:GetControl(9)
        local imgDisCount = uiTemplate:GetControl(8)
        local labRepuLess = uiTemplate:GetControl(10)
        local labDiscount = uiTemplate:GetControl(11)
        local item_1 = uiTemplate:GetControl(12)
        local item_2 = uiTemplate:GetControl(13)
        local img_high_bg = uiTemplate:GetControl(14)
        local lab_level = uiTemplate:GetControl(15)
        local itemId = self._CurrentItemsData[index + 1].ItemId
        local canUse = self:CanUse(itemId)
        local lock = false
        local is_selected = false
        labLimitCandition:SetActive(false)
        labMaxNumber:SetActive(false)
        IconTools.InitItemIconNew(uiItem, itemId, nil, EItemLimitCheck.AllCheck)
        -- 商店的Item名字为白色
        local itemTemplate = CElementData.GetItemTemplate(itemId)
        GUI.SetText(labItemName,self:GetItemNameRichText(itemId))
        GUI.SetText(lab_level, string.format(StringTable.Get(10657), itemTemplate.InitLevel))
        lab_level:SetActive(itemTemplate.InitLevel > 0)
        --购买信息默认显示第一个item
        if self._OpenTargetId ~= 0 and itemId == self._OpenTargetId then
            is_selected = true
            self._BeforeItem = item
            imgHighLight:SetActive(true)
            img_high_bg:SetActive(true)
            self._CurItemIndex = index
            self._NeedScrollDrump = true
            local hasNum = game._HostPlayer._Package._NormalPack:GetItemCount(self._OpenTargetId)
			if hasNum < self._OpenTargetCount then
				self._CurNumber = self._OpenTargetCount - hasNum
			end
            self:UpdateBuyInfoPanel()
        elseif self._OpenTargetId == 0 and self._CurItemIndex == index then
            is_selected = true
            self._BeforeItem = item
            imgHighLight:SetActive(true)
            img_high_bg:SetActive(true)
            self._CurItemIndex = index
    	    self:UpdateBuyInfoPanel()
        else
            is_selected = false
            imgHighLight:SetActive(false)
            img_high_bg:SetActive(false)
        end
        -- 折扣信息
        if self._CurrentItemsData[index + 1].DiscountType > 0 then
            imgDisCount:SetActive(true)
            local discount_str = tostring(self._CurrentItemsData[index + 1].DiscountType * 10)
            GUI.SetText(labDiscount, discount_str)        
        else
            imgDisCount:SetActive(false)
        end
        --显示数量
        local remain_count = math.max(self._CurrentItemsData[index + 1].LimitCount - self:GetBuyCountByDetialID(self._CurrentItemsData[index + 1].Id) ,0)
        if self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.NoLimit then 
            imgSellOut:SetActive(false)
        elseif self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.Forever then
            imgSellOut:SetActive(false)
            labMaxNumber:SetActive(true)
            GUI.SetText(labMaxNumber,string.format(StringTable.Get(22300),remain_count))
        elseif self._CurrentItemsData[index + 1].LimitType == ENpcSaleLimitType.DayRefresh then
            labMaxNumber:SetActive(true)
       	    if remain_count == 0 then
                imgSellOut:SetActive(true)
       		    GUI.SetText(labMaxNumber,StringTable.Get(22302))
       	    else
       		    imgSellOut:SetActive(false)
                imgSellOutBG:SetActive(false)
       		    GUI.SetText(labMaxNumber,string.format(StringTable.Get(22301), remain_count))
       	    end
        end
        GUI.SetText(labPrice, GUITools.FormatNumber(self._CurrentItemsData[index + 1].CostMoneyNum, false))
        --显示限制条件
        if self._CurrentItemsData[index + 1].IsLevel then 
       		if game._HostPlayer._InfoData._Level < self._CurrentItemsData[index + 1].Level then
       			local str = string.format(StringTable.Get(273),self._CurrentItemsData[index + 1].Level)
           		labLimitCandition:SetActive(true)
                GUI.SetText(labLimitCandition,str)
                lock = true
       		end
        end
        if self._CurrentItemsData[index + 1].IsStage then
       		local stageItem = CElementData.GetPVP3v3Template(self._CurrentItemsData[index + 1].StageLevel)
       		if game._HostPlayer._InfoData._Arena3V3Stage < self._CurrentItemsData[index + 1].StageLevel then 
       			local str = string.format(StringTable.Get(275),stageItem.Name)
                GUI.SetText(labLimitCandition,str)
           		labLimitCandition:SetActive(true)
                lock = true
       		end
        end
    
        if self._CurrentItemsData[index + 1].IsReputation then
       		local ReputationTemplate = CElementData.GetReputationTemplate (self._CurrentItemsData[index + 1].ReputationType)
       		local is_rep_locked = true 
       		for i,v in pairs(self._HostPlayerReputations) do 
       			if i == self._CurrentItemsData[index + 1].ReputationType then
       				if v.Level >= self._CurrentItemsData[index + 1] .ReputationLevel then 
       					is_rep_locked = false
       				end
       			end
       		end

       		if is_rep_locked then 
                lock = true
                labRepuLess:SetActive(true)
                local str = string.format(StringTable.Get(274), StringTable.Get(25000 + self._CurrentItemsData[index + 1].ReputationLevel))
           		GUI.SetText(labRepuLess,str)
       		else
                labRepuLess:SetActive(false)
       		end
        else
            labRepuLess:SetActive(false)
        end	
        if lock then
       		imgSellOutBG:SetActive(true)
            imgMoney:SetActive(false)
            --GUITools.SetBtnExpressGray(item_1, true)
            GUITools.SetBtnExpressGray(item_2, true)
            if is_selected then
                img_high_bg:SetActive(false)
            end
        else
            imgSellOutBG:SetActive(false)
            imgMoney:SetActive(true)
            --GUITools.SetBtnExpressGray(item_1, false)
            GUITools.SetBtnExpressGray(item_2, false)
        end
        -- 显示消耗的货币
        local moneyItem = CElementData.GetMoneyTemplate(self._CurrentItemsData[index + 1].CostMoneyId)
        if moneyItem == nil then return end
        GUITools.SetItemIcon(imgMoney,moneyItem.IconPath)
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	if id == "List_Item" then 
		-- 右侧物品购买显示
		if self._CurItemIndex ~= index then 
            if self._BeforeItem ~= nil and not IsNil(self._BeforeItem) then
			    local uiTemplate = self._BeforeItem:GetComponent(ClassType.UITemplate)
			    uiTemplate:GetControl(0):SetActive(false)
                uiTemplate:GetControl(14):SetActive(false)
            end
			local uiTemplate1 = item:GetComponent(ClassType.UITemplate)
            local is_lock = self:IsItemLockByIndex(index + 1)
			uiTemplate1:GetControl(0):SetActive(true)
            uiTemplate1:GetControl(14):SetActive(not is_lock)
			self._BeforeItem = item
			self._CurItemIndex = index
            self._CurNumber = 1
            self._Num_Input:SetCountWithOutCb(1)
			self:UpdateBuyInfoPanel()
		end
	end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
	if id_btn == "Tab_Item" then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
		if index % 2 == 0 then
			CItemTipMan.ShowItemTips(self._CurrentItemsData[index + 1].ItemId,TipsPopFrom.OTHER_PANEL,uiTemplate:GetControl(1),TipPosition.FIX_POSITION)
		else
			CItemTipMan.ShowItemTips(self._CurrentItemsData[index + 1].ItemId,TipsPopFrom.OTHER_PANEL,uiTemplate:GetControl(1),TipPosition.FIX_POSITION)
		end
	end
end

def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then     --一级页签
            local bigTypeIndex = main_index + 1
            if self._ShowShop[bigTypeIndex].IsHideSubMenu then
                item:FindChild("Img_Arrow"):SetActive(false)
            else
                local img_arrow = item:FindChild("Img_Arrow")
                img_arrow:SetActive(true)
                GUITools.SetGroupImg(img_arrow, 0)
                GUITools.SetNativeSize(img_arrow)
            end
            if bigTypeIndex == self._CurBigShopIndex then
                self._BeforeMenuItem = item
            end
            GUI.SetText(item:FindChild("Lab_Text"),self._ShowShop[bigTypeIndex].Name)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            GUI.SetText(item:FindChild("Lab_Text"),self._ShowShop[bigTypeIndex].NpcSaleSubs[smallTypeIndex].Name)
        end
    end
end

def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then     -- 一级页签
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list,item,bigTypeIndex)
        elseif sub_index ~= -1 then -- 二级页签
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
    end
end

----------------------------------------------------------------------
--点击MenuList的一级页签处理函数<index>一级页签的index</index>
----------------------------------------------------------------------
def.method('userdata','userdata','number').OnClickTabListDeep1 = function(self,list,item,index)
    local shopData = self._ShowShop[index]
    if self._CurBigShopIndex == index then 
        local function OpenTab()
            local current_type_count = #shopData.NpcSaleSubs
            self._PanelObject._MenuTabList:OpenTab(current_type_count)
            GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 2)
            GUITools.SetNativeSize(item:FindChild("Img_Arrow"))
            self._IsTabOpen = true
        end

        local function CloseTab()
            self._PanelObject._MenuTabList:OpenTab(0)
            GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 1)
            GUITools.SetNativeSize(item:FindChild("Img_Arrow"))
            self._IsTabOpen = false
        end

        if shopData.IsHideSubMenu then
            self._IsTabOpen = false
        else
            if self._IsTabOpen then
                CloseTab()
            else
                OpenTab()
            end
        end
    else
        self._CurBigShopIndex = index
		self._CurrentBigShopID = self._ShowShop[self._CurBigShopIndex].ShopId
        self._CurSubShopIndex = -1
        self:OnClickTabListDeep2(list, index, 1)
		GUI.SetText(self._PanelObject._LabRefreshTimeTips,string.format(StringTable.Get(22310), string.sub(shopData.NpcSaleSubs[self._CurSubShopIndex].RefreshTime,1, -4)))
        if shopData.IsHideSubMenu then
            self._PanelObject._MenuTabList:OpenTab(0)
        else
            self._PanelObject._MenuTabList:OpenTab(#self._ShowShop[self._CurBigShopIndex].NpcSaleSubs)
        end
        if self._BeforeMenuItem then
            GUITools.SetGroupImg(self._BeforeMenuItem:FindChild("Img_Arrow"), 0)
            GUITools.SetNativeSize(self._BeforeMenuItem:FindChild("Img_Arrow"))
        end
        GUITools.SetGroupImg(item:FindChild("Img_Arrow"), 2)
        GUITools.SetNativeSize(item:FindChild("Img_Arrow"))
        self._BeforeMenuItem = item
        self._IsTabOpen = true
    end
end

----------------------------------------------------------------------
--点击MenuList的二级页签处理函数<bigTypeIndex>一级页签的index</bigTypeIndex>
--        <smallTypeIndex>二级页签的index</smallTypeIndex>
----------------------------------------------------------------------
def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    if self._CurBigShopIndex == bigTypeIndex and self._CurSubShopIndex == smallTypeIndex then return end
    self._CurrentSubShopID = self._ShowShop[bigTypeIndex].NpcSaleSubs[smallTypeIndex].SubShopId
	self._CurItemIndex = 0
    self._CurSubShopIndex = smallTypeIndex
    self._CurNumber = 1
    self._Num_Input:SetCountWithOutCb(1)
    self:SendC2SNpcSaleSyncReq()
    self:UpdateMoneyFrame()
end

def.method("table").UpdateRefreshTimeInfo = function(self, subShop)
    if subShop == nil then return end
    if subShop.SaleType == ESaleType.ESaleType_Normal then
        GUI.SetText(self._PanelObject._LabRefreshTimeTips,string.format(StringTable.Get(22310),string.sub(subShop.RefreshTime, 1, -4)))
        self._PanelObject._BtnRefresh:SetActive(false)
    elseif subShop.SaleType == ESaleType.ESaleType_Random then
        local cost_types = string.split(subShop.ResetCostMoneyIds, "*")
        local cost_counts = string.split(subShop.ResetCostMoneyCounts, "*")
        local buy_count = self._CurrentSubShopBuyInfo.ResetCount
        if #cost_counts ~= #cost_types then warn("随机商店刷新时间配置错误") return end

        if buy_count >= #cost_types then
            self._PanelObject._BtnRefresh:SetActive(false)
            self._PanelObject._LabRefreshTimeTips:SetActive(false)
        else
            self._PanelObject._BtnRefresh:SetActive(true)
            self._PanelObject._LabRefreshTimeTips:SetActive(true)
            local need_count = tonumber(cost_counts[buy_count + 1])
            local need_money_id = tonumber(cost_types[buy_count + 1])
            GUI.SetText(self._PanelObject._LabRefreshCost, cost_counts[buy_count + 1])
            GUITools.SetTokenMoneyIcon(self._PanelObject._Img_CostMoney, need_money_id)
        end
        local callback = function()
            local remain_time = (self._CurrentSubShopBuyInfo.ResetTime - GameUtil.GetServerTime())/1000
            remain_time = math.max(0, remain_time)
            local time_str = GUITools.FormatTimeFromSecondsToZero(false, remain_time)
            GUI.SetText(self._PanelObject._LabRefreshTimeTips, string.format(StringTable.Get(19477), string.sub(time_str, 1, -4)))
            if remain_time <= 0 then
                _G.RemoveGlobalTimer(self._AutoRefreshTimer)
                self._AutoRefreshTimer = 0
                self._PanelObject._BtnRefresh:SetActive(false)
                self._PanelObject._LabRefreshTimeTips:SetActive(false)
            end
        end
        if self._AutoRefreshTimer ~= 0 then
            _G.RemoveGlobalTimer(self._AutoRefreshTimer)
            self._AutoRefreshTimer = 0
        end
        self._AutoRefreshTimer = _G.AddGlobalTimer(1, false, callback)
    end
end

----------------------------------------------------------------------
-- 请求购买信息的回调函数，先更新本地购买信息，再更新界面
--    <saleSubs>服务器发送过来的子商店购买信息</saleSubs>
----------------------------------------------------------------------
def.method("table").UpdateSubShopBuyInfoData = function(self, saleSub)
    self._CurrentSubShopBuyInfo = {}
    self._CurrentSubShopBuyInfo.Tid = saleSub.Tid
    self._CurrentSubShopBuyInfo.SubId = saleSub.SubId
    self._CurrentSubShopBuyInfo.NextRefreshTime = saleSub.NextRefreshTime
    self._CurrentSubShopBuyInfo.ResetCount = saleSub.ResetCount
    self._CurrentSubShopBuyInfo.ResetTime = saleSub.ResetTime
    self._CurrentSubShopBuyInfo.NpcSaleInfos = {}
    for _,v in ipairs(saleSub.NpcSaleInfos) do
        self._CurrentSubShopBuyInfo.NpcSaleInfos[#self._CurrentSubShopBuyInfo.NpcSaleInfos + 1] = {}
        self._CurrentSubShopBuyInfo.NpcSaleInfos[#self._CurrentSubShopBuyInfo.NpcSaleInfos].DetailId = v.DetailId
        self._CurrentSubShopBuyInfo.NpcSaleInfos[#self._CurrentSubShopBuyInfo.NpcSaleInfos].Count = v.Count
    end
    local cur_sub_shop = self:GetSubShopInfoByTidAndSubId(self._CurrentBigShopID, self._CurrentSubShopID)
    if cur_sub_shop ~= nil then
        if cur_sub_shop.SaleType == ESaleType.ESaleType_Normal then
            self:LoadShopItemsInfo()
        elseif cur_sub_shop.SaleType == ESaleType.ESaleType_Random then
            self:LoadMysticalItemsInfo()
        end
        self:UpdateRefreshTimeInfo(cur_sub_shop)
    end
end

def.method("number", "number", "number", "number").UpdateBuyCount = function(self, tid, subId, detailId, count)
    if self._CurrentSubShopBuyInfo == nil then return end
    if self._CurrentSubShopBuyInfo.Tid ~= tid or self._CurrentSubShopBuyInfo.SubId ~= subId then return end
    for _,v in ipairs(self._CurrentSubShopBuyInfo.NpcSaleInfos) do
        if v.DetailId == detailId then
            v.Count = v.Count + count
        end
    end
end

----------------------------------------------------------------------
--通过DetailsID 获得已经购买该物品的数量
----------------------------------------------------------------------
def.method("number", "=>", "number").GetBuyCountByDetialID = function(self, detialId)
    if self._CurrentSubShopBuyInfo == nil then return 0 end
    for _,v in ipairs(self._CurrentSubShopBuyInfo.NpcSaleInfos) do
        if v.DetailId == detialId then
            return v.Count
        end
    end
    return 0
end

----------------------------------------------------------------------
--通过DetailsID 设置已经购买该物品的数量
----------------------------------------------------------------------
def.method("number", "number").SetBuyCountByDetialID = function(self, detialId, count)
    if self._CurrentSubShopBuyInfo == nil then return end
    for _,v in ipairs(self._CurrentSubShopBuyInfo.NpcSaleInfos) do
        if v.DetailId == detialId then
            v.Count = v.Count + count
            return
        end
    end
    self._CurrentSubShopBuyInfo.NpcSaleInfos[#self._CurrentSubShopBuyInfo.NpcSaleInfos + 1] = {}
    self._CurrentSubShopBuyInfo.NpcSaleInfos[#self._CurrentSubShopBuyInfo.NpcSaleInfos].DetailId = detialId
    self._CurrentSubShopBuyInfo.NpcSaleInfos[#self._CurrentSubShopBuyInfo.NpcSaleInfos].Count = count
end

----------------------------------------------------------------------
--从当前SubShop里面的物品里面挑出来可以购买的物品
----------------------------------------------------------------------
def.method().SelectCanBuyItemsFromShopAllItems = function(self)
    self._CurrentItemsData = {}
    for i,v in ipairs(self._CurrentShopAllItems) do
        if v.LimitType == ENpcSaleLimitType.Forever or v.LimitType == ENpcSaleLimitType.DayRefresh then
            local has_buy_count = self:GetBuyCountByDetialID(v.Id)
            if  v.LimitCount > has_buy_count then
                self._CurrentItemsData[#self._CurrentItemsData + 1] = v
            end
        else
            self._CurrentItemsData[#self._CurrentItemsData + 1] = v
        end
    end
end

def.method().ResetTargetItemIdFromCanBuyItems = function(self)
    if self._OpenTargetId ~= 0 then
        local finded = false
        for i,v in ipairs(self._CurrentItemsData) do
            if v.ItemId == self._OpenTargetId then
                finded = true
            end
        end
        if not finded then
            self._OpenTargetId = 0
        end
    end
end

local IsMystcialOnSell = function(self, detailID)
    for _,v in ipairs(self._CurrentSubShopBuyInfo.NpcSaleInfos) do
        if v.DetailId == detailID then
            return true
        end
    end
    return false
end

----------------------------------------------------------------------
-- 从服务器发送过来的神秘商店中挑选出来能显示的
----------------------------------------------------------------------
def.method().SelectCanBuyItemsFromMysticalShopAllItems = function(self)
    self._CurrentItemsData = {}
    if self._CurrentSubShopBuyInfo.Tid ~= self._CurrentBigShopID or self._CurrentSubShopID ~= self._CurrentSubShopBuyInfo.SubId then
        warn("error !! 购买数据商店页签和当前选择的页签不一样")
        return
    end
    for i,v in ipairs(self._CurrentShopAllItems) do
        if v.LimitType == ENpcSaleLimitType.Forever or v.LimitType == ENpcSaleLimitType.DayRefresh then
            if  v.LimitCount > 0 and IsMystcialOnSell(self, v.Id) then
                self._CurrentItemsData[#self._CurrentItemsData + 1] = v
            end
        else
            if IsMystcialOnSell(self, v.Id) then
                self._CurrentItemsData[#self._CurrentItemsData + 1] = v
            end
        end
    end
end

----------------------------------------------------------------------
--点击2级页签之后更新要显示的物品信息列表并显示出来(非神秘商店)
----------------------------------------------------------------------
def.method().LoadShopItemsInfo = function (self)
    if self._CurrentSubShopBuyInfo ~= nil then
        --更新当前所有商店的物品信息
        if self._CurrentBigShopID ~= self._CurrentSubShopBuyInfo.Tid or self._CurrentSubShopID ~= self._CurrentSubShopBuyInfo.SubId then
            warn("error !! 购买数据商店页签和当前选择的页签不一样")
            return
        end
    end
    self:GetCurrentShopAllItems()
    self:SelectCanBuyItemsFromShopAllItems()
    self:ResetTargetItemIdFromCanBuyItems()
    self._PanelObject._List_Item:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._CurrentItemsData)
    if self._NeedScrollDrump then
        self._PanelObject._List_Item:GetComponent(ClassType.GNewListLoop):ScrollToStep(self._CurItemIndex)
        self._NeedScrollDrump = false
    end
    self._OpenTargetId = 0
end

def.method().LoadMysticalItemsInfo = function(self)
    if self._CurrentSubShopBuyInfo ~= nil then
        --更新当前所有商店的物品信息
        if self._CurrentBigShopID ~= self._CurrentSubShopBuyInfo.Tid or self._CurrentSubShopID ~= self._CurrentSubShopBuyInfo.SubId then
            warn("error !! 购买数据商店页签和当前选择的页签不一样")
            return
        end
    end
    self:GetCurrentShopAllItems()
    self:SelectCanBuyItemsFromMysticalShopAllItems()
    self:ResetTargetItemIdFromCanBuyItems()
    self._PanelObject._List_Item:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._CurrentItemsData)
    if self._NeedScrollDrump then
        self._PanelObject._List_Item:GetComponent(ClassType.GNewListLoop):ScrollToStep(self._CurItemIndex)
        self._NeedScrollDrump = false
    end
    self._OpenTargetId = 0
end

----------------------------------------------------------------------
--购买之后更新购买信息，刷新界面
----------------------------------------------------------------------
def.method("table").LoadReFreshItems = function (self,data)
	if data.ErrorCode == 0 then 
		game._GUIMan: ShowTipText(StringTable.Get(22311),false)
        if self._CurrentBigShopID == data.NpcSaleTid and self._CurrentSubShopID == data.SubId then
            --self:UpdateBuyCount(data.NpcSaleTid, data.SubId, data.DetailId, data.Count)
            self:SetBuyCountByDetialID(data.DetailId, data.Count)
            local cur_sub_shop = self:GetSubShopInfoByTidAndSubId(self._CurrentBigShopID, self._CurrentSubShopID)
            if cur_sub_shop ~= nil then
                if cur_sub_shop.SaleType == ESaleType.ESaleType_Normal then
                    self:LoadShopItemsInfo()
                elseif cur_sub_shop.SaleType == ESaleType.ESaleType_Random then
                    self:LoadMysticalItemsInfo()
                end
                self:UpdateRefreshTimeInfo(cur_sub_shop)
            end
        end
    else
        game._GUIMan:ShowErrorTipText(data.ErrorCode)
	end
end

----------------------- 协议 -----------------------
def.method().SendC2SNpcSaleSyncReq = function(self)
	local C2SNpcSaleSyncReq = require "PB.net".C2SNpcSaleSyncReq
	local protocol = C2SNpcSaleSyncReq()
	protocol.Tid = self._CurrentBigShopID
    protocol.SubId = self._CurrentSubShopID
	PBHelper.Send(protocol)
end

def.method().SendC2SNpcSaleBuyReq = function (self)
	local C2SNpcSaleBuyReq = require "PB.net".C2SNpcSaleBuyReq
	local protocol = C2SNpcSaleBuyReq()
	protocol.NpcSaleTid = self._CurrentBigShopID
    protocol.SubId = self._CurrentSubShopID
	protocol.DetailId = self._BuyId
	protocol.Count = self._CurNumber
	PBHelper.Send(protocol)
end

def.method().SendC2SSubShopRefresh = function(self)
    local C2SNpcSaleRandomRefreshReq = require "PB.net".C2SNpcSaleRandomRefreshReq
    local protocol = C2SNpcSaleRandomRefreshReq()
    protocol.NpcSaleTid = self._CurrentBigShopID
    protocol.SubId = self._CurrentSubShopID
    PBHelper.Send(protocol)
end

def.override().OnHide = function(self)
    local restartQuestAuto = false
    if self._IsQuestAutoBuy and self._QuestAutoBuyItemId > 0 and self._OpenTargetCount > 0 then
        local haveCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._QuestAutoBuyItemId)
        restartQuestAuto = (haveCount >= self._OpenTargetCount)
    end
    if restartQuestAuto then
        CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)
    else
        CQuestAutoMan.Instance():Stop()
        CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
    end

    self._IsQuestAutoBuy = false
    self._QuestAutoBuyItemId = 0
    self._OpenTargetCount = 0
    self._OpenTargetId = 0
    self._NeedScrollDrump = false
    self._CurBigShopIndex = 1
    self._CurSubShopIndex = 1
    self._CurrentBigShopID = -1
    self._CurrentSubShopID = -1

    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
    if self._Btn_Buy ~= nil then
        self._Btn_Buy:Destroy()
        self._Btn_Buy = nil
    end
    if self._Num_Input ~= nil then
        self._Num_Input:Destroy()
        self._Num_Input = nil
    end
    if self._AutoRefreshTimer ~= 0 then
        _G.RemoveGlobalTimer(self._AutoRefreshTimer)
        self._AutoRefreshTimer = 0
    end
    self._CurrentShopAllItems = nil
    self._CurrentItemsData = nil
    self._PanelObject = nil
	self._CurrentSubShopBuyInfo = nil
    self._ShopData = nil
    self._ShowShop = nil 
    self._HostPlayerReputations = nil 
    self._BeforeItem = nil
end

CPanelNpcShop.Commit()
return CPanelNpcShop