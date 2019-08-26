
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local ItemLockEvent = require "Events.ItemLockEvent"
local EItemType = require "PB.Template".Item.EItemType
local EResourceType = require "PB.data".EResourceType
local ServerMessageBase = require "PB.data".ServerMessageBase
local Gender = require "PB.data".Gender
local CPanelAuction = Lplus.Extend(CPanelBase, 'CPanelAuction')
local CFrameCurrency = require "GUI.CFrameCurrency"
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local CCommonBtn = require "GUI.CCommonBtn"
local CCommonNumInput = require "GUI.CCommonNumInput"
local bit = require "bit"
local def = CPanelAuction.define

local isHideTreasure = true
local instance = nil
def.field("table")._PanelObject = BlankTable
def.field('boolean')._IsShowCanUse = true --默认情况下只显示适合自己的
def.field("table")._RightToggleType = BlankTable
def.field("table")._UpToggleType = BlankTable
def.field("table")._BagType = BlankTable
def.field("string")._SortDropDownText = ""
def.field("table")._TemplateData = BlankTable
def.field("number")._OpenIndex = -1
def.field("table")._ClientData = BlankTable
def.field('table')._FromServerData = BlankTable
def.field("table")._FrameRightItemsEnum = BlankTable
def.field("table")._SellBagItem = BlankTable
def.field("table")._AllBagItems = BlankTable
def.field('number')._PutawayItemCountSpecialId = 234
def.field('number')._RushNeedMoneySpecialId = 235
def.field('table')._PutawayItemInfoData = BlankTable
def.field('table')._ItemDurationSpecialId = BlankTable
def.field('table')._AllItemInfo = BlankTable
def.field('number')._SellItemCount = 0
def.field("number")._CurrentSelectBigTabId = 0
def.field("number")._CurrentSelectSmallTabId = 0
def.field("number")._CurrentSelectSmallIndex = 1
def.field('number')._CurrentRightToggle = 1
def.field("number")._CurrentUpToggle = 1
def.field("number")._CurrentBagType = 1
def.field("number")._CurrentSortType = 1        --当前给宝物库物品排序的方式
def.field("boolean")._IsOnClickSortButton = false
def.field("boolean")._IsSuccessBuy = false
def.field("userdata")._ButtonLabObj = nil
def.field("boolean")._IsWithFixedPriceBuy = false      --  是否用一口价进行购买
def.field("boolean")._IsTabOpen = false
def.field("boolean")._JustOpenTab = false
def.field("boolean")._JustOpenDropdown = false
def.field("userdata")._LastSelectTabItem = nil
def.field("number")._CurrentSelectItemIndex = 0
def.field("userdata")._CurrentSelectItem = nil
def.field(CFrameCurrency)._Frame_Money = nil
def.field(CCommonBtn)._Btn_Buy = nil
def.field(CCommonBtn)._Btn_Refresh = nil
def.field(CCommonNumInput)._Num_Input = nil
-------------------------------------------------     购买相关
def.field("table")._BuyItemData = BlankTable
def.field("number")._BuyItemNumber = 1 --默认购买一个
def.field("number")._TotalPrice = 0
-------------------------------------------------     刷新相关（竞拍实时更新）
def.field("number")._NowFirstItemID = -1             --第一层item的ID
def.field("number")._UpdatePriceTimeID = -1          --刷新的Timer id
-------------------------------------------------
def.field("table")._TimerID = BlankTable            -- 售卖和公会拍卖商使用的timer
def.field("table")._ItemShowTimerID = BlankTable    -- 交易所售卖中的物品时间显示的timer
def.static('=>', CPanelAuction).Instance = function ()
	if not instance then
        instance = CPanelAuction()
        instance._PrefabPath = PATH.UI_Auction
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()

        -- TO DO
	end
	return instance
end

local OnItemLockEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdataSellBagItemShow()
    end
end
 
def.override().OnCreate = function(self)
    self._PanelObject = {}
    self._PanelObject._FrameTreasureSell = self:GetUIObject("Frame_TreasureSell")
    self._PanelObject._FrameExchangeSell = self:GetUIObject("Frame_ExchangeSell")
    self._PanelObject._Rdo_TagGroup = self:GetUIObject("Rdo_TagGroup")
    self._PanelObject._NodeMenu = self:GetUIObject("Frame_MenuBG"):GetComponentInChildren(ClassType.GNewTabList)
    self._PanelObject._ViewItem0 = self:GetUIObject("View_Item0")
    self._PanelObject._ViewItem = self:GetUIObject("ViewItem")
    self._PanelObject._ViewItem1 = self:GetUIObject("View_Item1")
    self._PanelObject._StartTimeObj = self:GetUIObject("Lab_TimeValues")
    self._PanelObject._FrameSell = self:GetUIObject("Frame_Sell")
    self._PanelObject._Lab_Name_1 = self:GetUIObject("Lab_Name_1")
    self._PanelObject._Lab_Name_2 = self:GetUIObject("Lab_Name_2")
    self._PanelObject._Lab_Name_3 = self:GetUIObject("Lab_Name_3")
    self._PanelObject._Frame_Buttom = self:GetUIObject("Frame_Buttom")
    self._PanelObject._Frame_Right = self:GetUIObject("Frame_Right")
    self._PanelObject._Frame_Menu = self:GetUIObject("Frame_MenuBG")
    self._PanelObject._Img_SpendIcon = self:GetUIObject("Img_SpendIcon")
    self._PanelObject._Frame_DropDown = self:GetUIObject("Frame_DropDown")
    self._PanelObject._Lab_Title = self:GetUIObject("Lab_Title")
    self._PanelObject._FrameSideTabs = self:GetUIObject("Frame_SideTabs")
    self._PanelObject._Rdo_ShowCanUse = self:GetUIObject("Rdo_ShowCanUse")
    self._PanelObject._Img_ExchangeNoItems = self:GetUIObject("Img_ExchangeNoItems")
    self._PanelObject._ARdo_3 = self._PanelObject._Rdo_TagGroup:FindChild("ARdo_3")
    self._PanelObject._Btn_GoToFirst = self:GetUIObject("Btn_GoToFirst")
    self._Btn_Buy = CCommonBtn.new(self:GetUIObject("Btn_Buy"), nil)
    self._Btn_Refresh = CCommonBtn.new(self:GetUIObject("Btn_Rush"), nil)
    local countChangeCb = function(count)
        self._BuyItemNumber = count
        self:UpdateBuyPanel()
    end
    self._Num_Input = CCommonNumInput.new(self:GetUIObject("Frame_NumInput"), countChangeCb, 1, 1)
    CGame.EventManager:addHandler(ItemLockEvent, OnItemLockEvent)
end

def.override("dynamic").OnData = function(self, data)
    self._HelpUrlType = HelpPageUrlType.Auction
    if game._CFunctionMan:IsForbidFun(45) then
        MsgBox.ShowSystemMsgBox(ServerMessageBase.TradeDisenable, MsgBoxType.MBBT_OK)
        game._GUIMan:CloseByScript(self)
        return
    end
    if game._HostPlayer:IsInGlobalZone() then
        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
        game._GUIMan:CloseByScript(self)
        return
    end
    self:InitEnumValues()
    self._JustOpenTab = true
    self._CurrentUpToggle = self._UpToggleType.BUY                                  
    self:SetCurrentPageIndex(data)
    self._CurrentBagType = self._BagType.Weapon
    GUI.SetGroupToggleOn(self._PanelObject._FrameSideTabs,self._CurrentBagType + 1)
    self._TemplateData = CElementData.GetMarketTemplate(self._CurrentRightToggle)
    self._PanelObject._NodeMenu:SetItemCount(#self._TemplateData.UIBigTypes)
    self._PanelObject._NodeMenu:OpenTab(#self._TemplateData.UIBigTypes[1].UISmallTypes)
    self._PanelObject._NodeMenu:SelectItem(0,0)
    self._CurrentSelectBigTabId = self._TemplateData.UIBigTypes[1].Id 
    self._CurrentSelectSmallTabId = self._TemplateData.UIBigTypes[1].UISmallTypes[1].Id
    game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
    self._IsOnClickSortButton = false
    self._IsSuccessBuy = false
    self._IsWithFixedPriceBuy = false
    self._CurrentSortType = 4
    self._AllItemInfo = game._CAuctionUtil._TemplateData
    self:GetAllBagItems()
    GUI.SetText(self._PanelObject._Lab_Name_1,self._TemplateData.Name)
    GUI.SetText(self._PanelObject._Lab_Name_2,CElementData.GetMarketTemplate(2).Name)
    GUI.SetText(self._PanelObject._Lab_Name_3,CElementData.GetMarketTemplate(3).Name)
    -- 设置下拉菜单层级
    local dropDown = self._PanelObject._Frame_DropDown:FindChild("Drop_Group_Ride")
    self._JustOpenDropdown = true
    self._PanelObject._Rdo_ShowCanUse:GetComponent(ClassType.Toggle).isOn = self._IsShowCanUse
    --GameUtil.AdjustDropdownRect(dropDown, 6)
    local dropTemplate = dropDown:FindChild("Drop_Template")
    GUITools.SetupDropdownTemplate(self, dropTemplate)
    GUI.SetDropDownOption(dropDown, self._SortDropDownText)
    GameUtil.SetDropdownValue(dropDown, 3)

    --更新货币
    if self._Frame_Money == nil then
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end
    self:UpdatePanel()
    --更新下方刷新信息  -- 暂时屏蔽
--    GUITools.SetTokenMoneyIcon(self._PanelObject._Img_SpendIcon, self._TemplateData.MoneyType)
--    local count = CElementData.GetSpecialIdTemplate(self._RushNeedMoneySpecialId).Value
--    GUI.SetText(self._PanelObject._Img_SpendIcon:FindChild("Lab_SpendCount"), tostring(count))
end

def.method().InitEnumValues = function(self)
    self._RightToggleType =
    {
        EXCHANGE = 1,--交易所
        TREASURE = 2,--奇珍阁
        GUILDAUCTION = 3, --工会拍卖行 
        WORLDAUCTION = 4, -- 世界拍卖行       
    }
    self._UpToggleType = 
    {
        --NONE = 0,
        BUY = 1,
        SELL = 2,
    }
    self._ItemDurationSpecialId = 
    {
        238,--24h
        237,--12h
        236,--拍卖行道具上架持续时间 6h
    }
    self._BagType =
    {
        Weapon = 1,
        Armor = 2,
        Accessory = 3,
        Charm = 4,
        Rune = 5,
        Else = 6,
    }
    self._FrameRightItemsEnum = {
        FRAME_ITEM = 0,       --物品名称Text
        LAB_ITEMCOUNT = 1,      --物品数量
        LAB_ITEMDES = 2,        --物品的描述
        LAB_CURRENTCOUNT = 3,   --当前购买的物品数量
        LAB_ITEMNAME = 4,       --物品名字
        LAB_CURRTOTALMONEY = 5, --当前总钱数
        IMG_HAVENMONEY = 6,     --钱图标
        LAB_HAVENMONEY = 7,     --背包中的钱数
        LAB_LEVEL = 8,          --等级
    }
    self._SortDropDownText =
        StringTable.Get(10007)..","..    --品质
        StringTable.Get(884)..","..      --等级
        StringTable.Get(20435)..","..    --剩余时间
        StringTable.Get(20432)..","..    --竞拍价
        StringTable.Get(20433)..","..    --一口价
        StringTable.Get(20442)          --上架时间
end

def.method().GetAllBagItems = function(self)
    local tempitemSets = game._HostPlayer._Package._NormalPack._ItemSet
    local items = self._AllItemInfo[self._CurrentRightToggle]

    self._AllBagItems = {}
    for itemId,itemInfo in pairs(items) do 
        for _,item2 in pairs(tempitemSets) do
            if  itemId == item2._Tid and GameUtil.GetServerTime()/1000 - item2._SellCoolDownExpired > 0 and not item2._IsBind then
                if item2:IsEquip() then
                    if not item2._IsLock then
                        self._AllBagItems[#self._AllBagItems+1] = item2    
                    end
                else
                    self._AllBagItems[#self._AllBagItems+1] = item2
                end
            end
        end
    end 
end

def.method("dynamic").SetCurrentPageIndex = function(self, data)
    if data == nil then
        self._CurrentRightToggle = self._RightToggleType.EXCHANGE
    else
        if type(data) == "number" then
            if data == self._RightToggleType.TREASURE then
                local glory_temp = CElementData.GetTemplate("GloryLevel", game._HostPlayer._InfoData._GloryLevel)
                local need_temp = game._CWelfareMan:GetGloryUnlockData(EnumDef.GloryUnlockType.WorldAuctionUnlock)
                if need_temp == nil then
                    self._CurrentRightToggle = self._RightToggleType.EXCHANGE
                    game._GUIMan:ShowTipText(StringTable.Get(20445), false)
                else
                    if game._HostPlayer._InfoData._GloryLevel < need_temp.Level then
                        self._CurrentRightToggle = self._RightToggleType.EXCHANGE
                        game._GUIMan:ShowTipText(string.format(StringTable.Get(20444), need_temp.Name), false)
                    else
                        local param = tonumber(data)
                        self._CurrentRightToggle = (param > self._RightToggleType.GUILDAUCTION or param < self._RightToggleType.EXCHANGE) 
                                                        and self._RightToggleType.EXCHANGE or param
                    end
                end
            else
                local param = tonumber(data)
                self._CurrentRightToggle = (param > self._RightToggleType.GUILDAUCTION or param < self._RightToggleType.EXCHANGE) 
                                                and self._RightToggleType.EXCHANGE or param
            end
        else
            self._CurrentRightToggle = self._RightToggleType.EXCHANGE
        end
    end
    GUI.SetGroupToggleOn(self._PanelObject._Rdo_TagGroup, self._CurrentRightToggle + 1)
end

def.method("number", "number", "=>", "boolean").BuyGoodCount = function(self,itemTid, count)
    local itemData = CElementData.GetItemTemplate(itemTid)
    return count <= itemData.PileLimit
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
		return
    elseif self._Num_Input ~= nil and self._Num_Input:OnClick(id) then
        return
    elseif self._Btn_Buy ~= nil and self._Btn_Buy:OnClick(id) then
        local callback = function(val)
            if val then
                if self:BuyGoodCount(self._BuyItemData.ItemID, self._BuyItemNumber) then
                    if game._HostPlayer:HasEnoughSpace(self._BuyItemData.ItemID,self._BuyItemData.Item.IsBind, self._BuyItemNumber) then
                        game._CAuctionUtil:SendC2SMarketItemBuy(self._CurrentRightToggle,self._BuyItemData.ItemPos,self._BuyItemNumber)
                    else
                        game._GUIMan:ShowTipText(StringTable.Get(22308), true)
                    end
                else
                    game._GUIMan:ShowTipText(StringTable.Get(20438), true)
                end
            end
        end
        MsgBox.ShowQuickBuyBox(self._TemplateData.MoneyType, self._BuyItemData.Price * self._BuyItemNumber, callback)
    elseif self._Btn_Refresh ~= nil and self._Btn_Refresh:OnClick(id) then
        self:RushItemList()
    elseif id == 'Btn_Sell' then
        self:BToggleChange(self._UpToggleType.SELL)
    elseif id == "Btn_GoToFirst" then
        self:UpdataBuyListItemDataFirst(self._FromServerData,-1)
        game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
    elseif id == 'Btn_Back' then
        if self._CurrentUpToggle == self._UpToggleType.BUY then
            game._GUIMan:CloseByScript(self)
        else
            if self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION then
                game._GUIMan:CloseByScript(self)
            else
                self:BToggleChange(self._UpToggleType.BUY)
            end
        end
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == 'Btn_WroldOrGuildAuction' then
        if self._CurrentRightToggle == self._RightToggleType.WORLDAUCTION then
            self._CurrentRightToggle = self._RightToggleType.GUILDAUCTION
        elseif self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION then
            self._CurrentRightToggle = self._RightToggleType.WORLDAUCTION
        end
        game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,0)
    elseif id == 'Btn_BasePrice4' or id == 'Btn_HighestPrice5' or id == 'Btn_Quality1' or id == 'Btn_Level2' or id == 'Btn_Time3' then 
        if self._CurrentRightToggle == self._RightToggleType.TREASURE then
            local key = string.sub(id,-1) + 0
            self._ClientData = self:SortAscending(self._ClientData ,key)
            local itemGuidObj = self:GetUIObject("List_Item_Guid3"):GetComponent(ClassType.GNewList)
            itemGuidObj:SetItemCount(#self._ClientData)
        end
    elseif id == "Btn_Close" then
        game._GUIMan:CloseSubPanelLayer()
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if string.find(id, "ARdo") then  --交易类型
        local index = string.sub(id,-1) + 0
        self:AToggleChange(index)
    elseif id == "Rdo_ShowCanUse" then
        self._IsShowCanUse = checked
        self:UpdataBuyListItemDataFirst(self._FromServerData,-1)
    elseif id == "Rdo_SideTab1" then
        self._CurrentBagType = self._BagType.Weapon
        self:UpdataSellBagItemShow()
    elseif id == "Rdo_SideTab2" then
        self._CurrentBagType = self._BagType.Armor
        self:UpdataSellBagItemShow()
    elseif id == "Rdo_SideTab3" then
        self._CurrentBagType = self._BagType.Accessory
        self:UpdataSellBagItemShow()
    elseif id == "Rdo_SideTab4" then
        self._CurrentBagType = self._BagType.Charm
        self:UpdataSellBagItemShow()
    elseif id == "Rdo_SideTab5" then
        self._CurrentBagType = self._BagType.Rune
        self:UpdataSellBagItemShow()
    elseif id == "Rdo_SideTab6" then
        self._CurrentBagType = self._BagType.Else
        self:UpdataSellBagItemShow()
    end
end
--右侧Toggle事件
def.method("number").AToggleChange = function(self,toggleIndex)
    if self._CurrentRightToggle == toggleIndex then return end
    if toggleIndex == self._RightToggleType.TREASURE then
        local glory_temp = CElementData.GetTemplate("GloryLevel", game._HostPlayer._InfoData._GloryLevel)
        local need_temp = game._CWelfareMan:GetGloryUnlockData(EnumDef.GloryUnlockType.WorldAuctionUnlock)
        if need_temp == nil then
            GUI.SetGroupToggleOn(self._PanelObject._Rdo_TagGroup, self._CurrentRightToggle + 1)
            game._GUIMan:ShowTipText(StringTable.Get(20445), false)
            return
        else
            if game._HostPlayer._InfoData._GloryLevel < need_temp.Level then
                GUI.SetGroupToggleOn(self._PanelObject._Rdo_TagGroup, self._CurrentRightToggle + 1)
                game._GUIMan:ShowTipText(string.format(StringTable.Get(20444), need_temp.Name), false)
                return
            end
        end
    end

    self._CurrentRightToggle = toggleIndex
    self:GetAllBagItems()
    self:RemoveTickUpdateTimer()
    self:UpdatePanel()
    if self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION then
        self._IsOnClickSortButton = false
        self:AddTickUpdateTimer()
    end
end

def.method().UpdatePanel = function(self)
    self._PanelObject._ViewItem0:SetActive(false)
    self._PanelObject._ViewItem1:SetActive(false)
    self._PanelObject._ViewItem:SetActive(false)
    self._PanelObject._Frame_Right:SetActive(false)
    if self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION then 
        self:GetUIObject("Frame_Buy"):SetActive(true)
        self:GetUIObject("Frame_Sell"):SetActive(false)
        self:GetUIObject("Btn_Sell"):SetActive(false)
        self._PanelObject._FrameExchangeSell:SetActive(false)
        self._PanelObject._FrameTreasureSell:SetActive(true)
        self._TemplateData = CElementData.GetMarketTemplate(self._CurrentRightToggle)
        if #self._TemplateData.UIBigTypes > 0 then
            self._CurrentSelectBigTabId = self._TemplateData.UIBigTypes[1].Id 
        end
        if #self._TemplateData.UIBigTypes[1].UISmallTypes > 0 then
            self._CurrentSelectSmallTabId = self._TemplateData.UIBigTypes[1].UISmallTypes[1].Id
        end
        self._PanelObject._NodeMenu:SetItemCount(#self._TemplateData.UIBigTypes)
        self._IsTabOpen = false
        self._JustOpenTab = true
        self._PanelObject._NodeMenu:SelectItem(0,0)
        game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,0)
        return
    end
    if self._CurrentUpToggle == self._UpToggleType.BUY then
        self:GetUIObject("Frame_Buy"):SetActive(true)
        self:GetUIObject("Frame_Sell"):SetActive(false)
        self:GetUIObject("Btn_Sell"):SetActive(true)
        self._PanelObject._ARdo_3:SetActive(true)
        GUI.SetText(self._PanelObject._Lab_Title, StringTable.Get(20447))
        self._TemplateData = CElementData.GetMarketTemplate(self._CurrentRightToggle)
        if #self._TemplateData.UIBigTypes > 0 then
            self._CurrentSelectBigTabId = self._TemplateData.UIBigTypes[1].Id 
        end
        if #self._TemplateData.UIBigTypes[1].UISmallTypes > 0 then
            self._CurrentSelectSmallTabId = self._TemplateData.UIBigTypes[1].UISmallTypes[1].Id
        end
        self._PanelObject._NodeMenu:SetItemCount(#self._TemplateData.UIBigTypes)
        self._IsTabOpen = false
        self._JustOpenTab = true
        self._PanelObject._NodeMenu:SelectItem(0,0)
        if self._CurrentRightToggle == self._RightToggleType.EXCHANGE or self._CurrentRightToggle == self._RightToggleType.TREASURE then
            self._TemplateData = CElementData.GetMarketTemplate(self._CurrentRightToggle)
        end
        game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
    else
        self:GetUIObject("Frame_Buy"):SetActive(false)
        self:GetUIObject("Frame_Sell"):SetActive(true)
        self:GetUIObject("Btn_Sell"):SetActive(false)
        self._PanelObject._ARdo_3:SetActive(false)
        GUI.SetText(self._PanelObject._Lab_Title, StringTable.Get(21303))
        if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
            self._PanelObject._FrameExchangeSell:SetActive(true)
            self._PanelObject._FrameTreasureSell:SetActive(false)
        elseif self._CurrentRightToggle == self._RightToggleType.TREASURE then
            self._PanelObject._FrameExchangeSell:SetActive(false)
            self._PanelObject._FrameTreasureSell:SetActive(true)
        end
        game._CAuctionUtil:SendC2SMarketPutawayInfo(self._CurrentRightToggle)
        self:UpdataSellBagItemShow()
    end
    self:RemoveGlobalTimer()
    self:RemoveTickUpdateTimer()
end
-- 上面Toggle 处理买卖UI
def.method("number").BToggleChange = function(self,toggleIndex)
    if self._CurrentUpToggle == toggleIndex then return end
    self._CurrentUpToggle = toggleIndex
    self:UpdatePanel()
end
def.method().RushItemList = function (self)
    if game._CAuctionUtil:GetAuctionRefCount() == 0 then
        game._CAuctionUtil:SendC2SMarketRefItemList(self._CurrentRightToggle,self._CurrentSelectBigTabId,true)
        return
    end
    local refCount = game._CAuctionUtil:GetAuctionRefCount()
    local data = self:GetMoneyCountByRefCount(refCount)
    local moneyTemp = CElementData.GetMoneyTemplate(self._TemplateData.MoneyType)

    local title, msg, closeType = StringTable.GetMsg(9)
    local text = string.format(msg,data, moneyTemp.TextDisplayName) 
    local callback = function (value)
        if value then
            local callback1 = function(val1)
                if val1 then
                    game._CAuctionUtil:SendC2SMarketRefItemList(self._CurrentRightToggle,self._CurrentSelectBigTabId,true)
                end
            end
            MsgBox.ShowQuickBuyBox(self._TemplateData.MoneyType, data, callback1)
        end
    end
    MsgBox.ShowMsgBox(text, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
end

def.method('=>','table').OnlyShowCanUseItem = function (self)
    local itemList = {}
    for i,item in pairs(self._FromServerData) do 
        if self:CanUse(item.ItemID) then
            table.insert(itemList,item)
        end
    end
    return itemList
end
def.method("number","=>","boolean").CanUse = function (self,itemId)
    local itemData = CElementData.GetItemTemplate(itemId)
    local prof = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
    if itemData.MinLevelLimit > game._HostPlayer._InfoData._Level or itemData.MaxLevelLimit < game._HostPlayer._InfoData._Level then 
        return false
    else 
        if itemData.ItemType == EItemType.Equipment or itemData.ItemType == EItemType.Rune or itemData.ItemType == EItemType.Charm then 
            if prof == bit.band(itemData.ProfessionLimitMask, prof) then 
                return true
            else 
                return false
            end
        elseif itemData.ItemType == EItemType.Dress then 
            if itemData.GenderLimitMask == game._HostPlayer._InfoData._Gender or itemData.GenderLimitMask == Gender.BOTH  then 
                return true 
            else
                return false
            end 
        else 
            return true 
        end
    end
end

def.method("table").UpdataSellListItemData = function (self,data)
    self._ClientData = data
    self._SellItemCount = #self._ClientData
    local itemGuidObj = nil
    local labNothingSell = self:GetUIObject("LabNothingSellItems")
    if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
        itemGuidObj = self:GetUIObject("ExchangeSell_List_TeamList"):GetComponent(ClassType.GNewListLoop) 
    elseif self._CurrentRightToggle == self._RightToggleType.TREASURE then
        itemGuidObj = self:GetUIObject ("TreasureSell_List_TeamList"):GetComponent(ClassType.GNewListLoop)
    end
    if self._SellItemCount == 0 then
        labNothingSell:SetActive(true)
    else 
        labNothingSell:SetActive(false)
    end 
    self:RemoveGlobalTimer()
    self:RemoveAllItemShowTimer()
    if self._SellItemCount == 0 then
        itemGuidObj:SetItemCount(0)
    else
        itemGuidObj:SetItemCount(self._SellItemCount)           
    end
end


--根据模板数据 从背包中删选能够售卖的Item
def.method().UpdataSellBagItemShow = function(self)
    self._SellBagItem = {}
    self._PutawayItemInfoData = {}
    self:GetAllBagItems()
    self._SellBagItem = self:GetCurrentTypeItems(self._CurrentBagType)
    local items = self._AllItemInfo[self._CurrentRightToggle]
    
    for i,v in pairs (items) do
        for _,item2 in pairs(self._SellBagItem) do
            if i == item2._Tid then  
                self._PutawayItemInfoData[#self._PutawayItemInfoData+1] = {}
                self._PutawayItemInfoData[#self._PutawayItemInfoData].MaxPrice = v.MaxPrice
                self._PutawayItemInfoData[#self._PutawayItemInfoData].MinPrice = v.MinPrice
                self._PutawayItemInfoData[#self._PutawayItemInfoData]._Tid = item2._Tid
                self._PutawayItemInfoData[#self._PutawayItemInfoData]._Slot = item2._Slot
                self._PutawayItemInfoData[#self._PutawayItemInfoData]._NormalCount = item2._NormalCount
                if item2:IsEquip() then
                    self._PutawayItemInfoData[#self._PutawayItemInfoData]._Star = item2._BaseAttrs.Star
                end
            end
        end
    end
    local frame_NO = self:GetUIObject("Frame_NO")
    local frame_HAVE = self:GetUIObject("Frame_HAVE")
    if #self._SellBagItem == 0  then    
        frame_NO:SetActive(true)        
        frame_HAVE:SetActive(false)
    else   
        local function SortFucn(e1, e2)
            return e1._Tid < e2._Tid           
        end    
        frame_NO:SetActive(false)
        frame_HAVE:SetActive(true)
        table.sort(self._SellBagItem,SortFucn)
        table.sort(self._PutawayItemInfoData,SortFucn)                
        --背包中的Item按照ItemID从大到小显示             
    end  
    local itemGuidObj1 = self:GetUIObject("Sell_List_Item"):GetComponent(ClassType.GNewListLoop) 
    itemGuidObj1:SetItemCount(#self._SellBagItem)         

    for i = 1,6 do
        local items = self:GetCurrentTypeItems(i)
		GUI.SetText(self._PanelObject._FrameSideTabs:FindChild("Rdo_SideTab"..i.."/Label"),string.format(StringTable.Get(21516),#items))
	end
end

--过滤物品类型
def.method("number", "=>", "table").GetCurrentTypeItems = function(self, bagType)
    local items = {}
    for i,v in ipairs(self._AllBagItems) do
        if bagType == self._BagType.Weapon then 
			if v:IsEquip() and v:GetCategory() == EnumDef.ItemCategory.Weapon  then 
				table.insert(items,v)
			end
		elseif bagType == self._BagType.Armor then 
			if v:IsEquip() and v:GetCategory() == EnumDef.ItemCategory.Armor then 
				table.insert(items,v)
			end
		elseif bagType == self._BagType.Accessory then 
			if v:IsEquip() and v:GetCategory() == EnumDef.ItemCategory.Jewelry then 
				table.insert(items,v)
			end
		elseif bagType == self._BagType.Charm then 
			if v:IsCharm() then 
				table.insert(items,v)
			end
		elseif bagType == self._BagType.Else then 
			if not v:IsEquip() and not v:IsCharm() then 
				table.insert(items,v)
			end
		end
    end
    return items
end

def.method("number", "=>", "number").GetMoneyCountByRefCount = function(self, count)
    local data =  tonumber (CElementData.GetSpecialIdTemplate(self._RushNeedMoneySpecialId).Value)
    local moneyCount = count * data
    if moneyCount > 50 then
        moneyCount = 50
    end
    return moneyCount
end

--第一次得到购买界面的Item列表数据
def.method("table","number").UpdataBuyListItemDataFirst = function (self,data,refTime)
    self._FromServerData = data
    if self._IsShowCanUse and self._CurrentRightToggle == self._RightToggleType.EXCHANGE then 
        self._ClientData = self:OnlyShowCanUseItem()
    else
        self._ClientData = data
    end
    self._PanelObject._Frame_DropDown:SetActive(false)
    self._PanelObject._Btn_GoToFirst:SetActive(false)
    local itemGuidObj = nil
    if self._CurrentRightToggle == self._RightToggleType.EXCHANGE or self._CurrentRightToggle == self._RightToggleType.TREASURE then      
        self._PanelObject._Frame_Right:SetActive(true)
        self._PanelObject._Frame_Right:FindChild("Frame_NotEmpty"):SetActive(false)
        self._PanelObject._Frame_Right:FindChild("Frame_Empty"):SetActive(true)
        self._PanelObject._Frame_Menu:SetActive(true)
        self._PanelObject._ViewItem0:SetActive(true)
        self._PanelObject._ViewItem1:SetActive(false)
        self._PanelObject._ViewItem:SetActive(false)
        itemGuidObj = self:GetUIObject("List_Item_Guid1")
        local lab_Info = self._PanelObject._Frame_Right:FindChild("Frame_Empty/Lab_ItemName")
        if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
            self._PanelObject._Frame_Buttom:SetActive(true)
            GUI.SetText(lab_Info, StringTable.Get(20430))
--            if refTime > 0 then  -- 去掉计时
--                self:ShowTime(refTime,self._PanelObject._StartTimeObj,0,true)
--            end
            --更新下方信息
            local refCount = game._CAuctionUtil:GetAuctionRefCount()
            local moneyCount = self:GetMoneyCountByRefCount(refCount)
            local lab_first_free = self:GetUIObject("Lab_FirstFree")
            local btn_rush = self:GetUIObject("Btn_Rush")
            local node_content = btn_rush:FindChild("Img_Bg/Node_Content")
            if moneyCount == 0 then
                lab_first_free:SetActive(true)
                node_content:SetActive(false)
            else
                lab_first_free:SetActive(false)
                node_content:SetActive(true)
            end
            local setting = {
                [EnumDef.CommonBtnParam.MoneyID] = self._TemplateData.MoneyType,
                [EnumDef.CommonBtnParam.MoneyCost] = moneyCount   
            }
            self._Btn_Refresh:ResetSetting(setting)
        else
            self._PanelObject._Frame_Buttom:SetActive(false)
            GUI.SetText(lab_Info, StringTable.Get(20431))
        end
        itemGuidObj:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._ClientData)
    elseif self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION or self._CurrentRightToggle == self._RightToggleType.WORLDAUCTION then
        self._PanelObject._ViewItem0:SetActive(false)
        self._PanelObject._ViewItem1:SetActive(false)
        self._PanelObject._ViewItem:SetActive(true)
        self._PanelObject._Frame_Buttom:SetActive(false)
        itemGuidObj = self:GetUIObject("List_Item_Guid3")
        self._ClientData = self:SortAscending(self._ClientData,4)
        itemGuidObj:GetComponent(ClassType.GNewList):SetItemCount(#self._ClientData)
        --self:AddTickUpdateTimer()
    end
    self:RemoveAllItemShowTimer()
    if #self._ClientData <=0 then
        itemGuidObj:SetActive(false)
        self._PanelObject._Img_ExchangeNoItems:SetActive(true)
    else
        itemGuidObj:SetActive(true)
        self._PanelObject._Img_ExchangeNoItems:SetActive(false)
    end
end
--点击界面中的item，第二次更新UI中Item数据
def.method("table").UpdataBuyListItemDataSecond = function(self,data)
    self._ClientData = data
    local itemListGuid = nil
    if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
        self._PanelObject._ViewItem0:SetActive(false)
        self._PanelObject._ViewItem:SetActive(false)
        self._PanelObject._ViewItem1:SetActive(true)
        self._PanelObject._Btn_GoToFirst:SetActive(true)
        itemListGuid = self:GetUIObject("List_Item_Guid2"):GetComponent(ClassType.GNewListLoop)
        self:ResetBuyDataAndPanel()
        self:RemoveAllItemShowTimer()
        self._ClientData = self:SortForExchange(data)
        itemListGuid :SetItemCount(#self._ClientData)
        if #self._ClientData > 0 then
            local item = itemListGuid:GetItem(0)
            itemListGuid:SetSelection(0)
            self:OnSelectItem(item, "List_Item_Guid2", 0)
        end
    elseif self._CurrentRightToggle == self._RightToggleType.TREASURE then 
        self._PanelObject._ViewItem0:SetActive(false)
        self._PanelObject._ViewItem:SetActive(true)
        self._PanelObject._ViewItem1:SetActive(false)
        self._PanelObject._Frame_DropDown:SetActive(true)
        self._ClientData = self:SortAscending(self._ClientData ,self._CurrentSortType)
        itemListGuid = self:GetUIObject("List_Item_Guid3"):GetComponent(ClassType.GNewList)
        itemListGuid :SetItemCount(#self._ClientData)
    end  
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)   
    if id == 'List_Item_Guid1'then
        self:OnInitExchangeOrTreasureItemFirst(item,index) 
        self:ResetBuyDataAndPanel()     --初始化item的时候需要把购买初始化
    elseif id == 'List_Item_Guid2'then
        self:OnInitExchangeItemSecond(item,index)

    elseif id == 'List_Item_Guid3' then
       self:OnInitTreasureSecondOrAuctionFirst(item,index)

    elseif id == 'ExchangeSell_List_TeamList' then
        self:OnInitSellExchangeItem(item,index)

    elseif id == 'TreasureSell_List_TeamList' then
        self:OnInitSellTreasureItem(item,index)
        
    elseif id == 'Sell_List_Item' then
        self:OnInitSellBag(item,index)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)   
    if id == 'List_Item_Guid1' then  
        if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
            self._PanelObject._Frame_Right:SetActive(true)
        else
            self._PanelObject._Frame_Right:SetActive(false)
        end
        self._NowFirstItemID = self._ClientData[index + 1].ItemID
        self:AddTickUpdateTimer()
        game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,self._ClientData[index + 1].ItemID )
    elseif id == 'List_Item_Guid2' then
    --物品购买界面
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        uiTemplate:GetControl(3):SetActive(true)
        if self._CurrentSelectItemIndex == index + 1 then return end
        if self._CurrentSelectItem ~= nil then
            self._CurrentSelectItem:FindChild("Img_SelectBG"):SetActive(false)
        end
        self._BuyItemNumber = 1
        self._CurrentSelectItem = item
        self._CurrentSelectItem:FindChild("Img_SelectBG"):SetActive(true)
        self._CurrentSelectItemIndex = index + 1
        self._PanelObject._Frame_Right:FindChild("Frame_NotEmpty"):SetActive(true)
        self._PanelObject._Frame_Right:FindChild("Frame_Empty"):SetActive(false)
        self._BuyItemData = self._ClientData[index + 1]
        self._Num_Input:ResetMinAndMaxCount(1, self._BuyItemData.ItemNum)
        self._Num_Input:SetCountWithOutCb(self._BuyItemNumber)
        self:UpdateBuyPanel()
   elseif id == 'Sell_List_Item' then
    --物品上架界面
        game._GUIMan:Open("CPanelAuctionSell2",self._PutawayItemInfoData[index+1])
    end
end
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if id_btn == "Frame_Item" then
        local alinObj = nil
        local item_data = self._ClientData[index + 1]
        if (self._CurrentRightToggle == self._RightToggleType.EXCHANGE and self._CurrentUpToggle == self._UpToggleType.BUY) or 
            (self._CurrentRightToggle == self._RightToggleType.TREASURE and id == "List_Item_Guid1") then
            alinObj = button_obj.parent
        else
            alinObj = button_obj:FindChild("Img_ItemIcon")
        end
        local item_temp = CElementData.GetItemTemplate(item_data.ItemID)
        if self._ClientData[index + 1].Item ~= nil and item_temp.ItemType == EItemType.Equipment then
            local itemData = CIvtrItem.CreateVirtualItem(item_data.Item)
            if itemData:IsEquip() then 
				itemData:ShowTipWithFuncBtns(TipsPopFrom.OTHER_PALYER,TipPosition.DEFAULT_POSITION,button_obj,button_obj)
			else
				itemData:ShowTipWithFuncBtns(TipsPopFrom.OTHER_PALYER,TipPosition.DEFAULT_POSITION,button_obj,button_obj)
			end
        else
            CItemTipMan.ShowItemTips(item_data.ItemID, TipsPopFrom.OTHER_PANEL, alinObj, TipPosition.FIX_POSITION)
        end
    --物品下架
    elseif id_btn == "Btn_Down" then
        local callback = function (value)
            if value then
                local itemDate = self._ClientData[index + 1]
                if itemDate ~= nil and game._HostPlayer:HasEnoughSpace(itemDate.ItemID, itemDate.Item.IsBind, 1) then
                    game._CAuctionUtil:SendC2SMarketItemTakeOut(self._CurrentRightToggle,self._ClientData[index + 1].ItemPos)
                else
                    game._GUIMan:ShowTipText(StringTable.Get(20436), true)
				end
            end
        end
        local title, msg, closeType = StringTable.GetMsg(10)
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)  
    --竞价
    elseif id_btn == "Btn_Buy1" then
        self._BuyItemData = self._ClientData[index + 1]
        self._ButtonLabObj = button_obj : FindChild("Lab_Buy1")  
        if self._BuyItemData.FixedPrice ~= 0 and self._BuyItemData.StartPrice*1.1 >= self._BuyItemData.FixedPrice then
            game._GUIMan:Open("CPanelAuctionSell1", { data = self._ClientData[index + 1], buyType = 3})     --buyType = 3是即将竞拍的加个大于一口价
        else
            game._GUIMan:Open("CPanelAuctionSell1", { data = self._ClientData[index + 1], buyType = 1})     --buyType = 0是一口价，1是竞拍价
        end
    elseif id_btn == "Btn_Buy2" then 
        self._BuyItemData = self._ClientData[index + 1]
        self._IsWithFixedPriceBuy = true
        game._GUIMan:Open("CPanelAuctionSell1", { data = self._ClientData[index + 1], buyType = 0})
    end
end

def.method('userdata','number').OnInitExchangeOrTreasureItemFirst = function (self,item,index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local number = uiTemplate:GetControl(0)
    local lab_Level = uiTemplate:GetControl(1)
    local lab_Name = uiTemplate:GetControl(2)
    local item_icon = uiTemplate:GetControl(3)
    local item_temp = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
    local count = 0
    if item_temp ~= nil then
        count = game._CCountGroupMan:OnCurUseCount(item_temp.ItemUseCountGroupId)
    end
    local setting = {
        [EItemIconTag.Activated] = count > 0,
    }
    IconTools.InitItemIconNew(item_icon, self._ClientData[index + 1].ItemID, setting, EItemLimitCheck.AllCheck)
    local itemTemp = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
--    local market_item_temp = CElementData.GetTemplate("MarketItem", self._ClientData[index + 1].ProductId)
--    if market_item_temp ~= nil and market_item_temp.MaxCellNum > 0 then
--        if market_item_temp.MaxCellNum < self._ClientData[index + 1].ItemNum then
--            GUI.SetText(number,GUITools.FormatNumber(market_item_temp.MaxCellNum, false))
--        else
--            GUI.SetText(number,tostring(self._ClientData[index + 1].ItemNum))
--        end
--    else
--        GUI.SetText(number,tostring(self._ClientData[index + 1].ItemNum))
--    end
    GUI.SetText(number,tostring(self._ClientData[index + 1].ItemNum))
    if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
        GUI.SetText(lab_Name, RichTextTools.GetItemNameRichText(self._ClientData[index + 1].ItemID, 1, false))
        if itemTemp.InitLevel > 0 or game._IsOpenDebugMode == true then
            lab_Level:SetActive(true)
            GUI.SetText(lab_Level, string.format(StringTable.Get(10657),itemTemp.InitLevel))
        else
            lab_Level:SetActive(false)
        end
    else
        lab_Level:SetActive(false)
    end
end

def.method('userdata','number').OnInitExchangeItemSecond = function (self,item,index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local lab_time = uiTemplate:GetControl(0)
    local labPriceNumber = uiTemplate:GetControl(1)
    local item_icon = uiTemplate:GetControl(4)
    local lab_item_name = uiTemplate:GetControl(5)
    local lab_level = uiTemplate:GetControl(6)
    local lab_number = uiTemplate:GetControl(7)
    local item_temp = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
    local count = 0
    local setting = {}
    if item_temp == nil then
        warn("error !! 没有找到物品，ID： ", self._ClientData[index + 1].ItemID)
        return
    end
    count = game._CCountGroupMan:OnCurUseCount(item_temp.ItemUseCountGroupId)
    if item_temp.ItemType == EItemType.Equipment then
        setting = {
            [EItemIconTag.Activated] = count > 0,
            [EItemIconTag.Grade] = self._ClientData[index + 1].Item.FightProperty.star
        }
    else
        setting = {
            [EItemIconTag.Activated] = count > 0,
        }
    end
    IconTools.InitItemIconNew(item_icon, self._ClientData[index + 1].ItemID, setting, EItemLimitCheck.AllCheck)
    GUI.SetText(labPriceNumber, GUITools.FormatMoney(self._ClientData[index + 1].Price))
    GUI.SetText(lab_level, string.format(StringTable.Get(10657), item_temp.InitLevel))
    GUI.SetText(lab_number, tostring(self._ClientData[index + 1].ItemNum))
    lab_level:SetActive(item_temp.InitLevel > 0)
--    local number = uiTemplate:GetControl(0)
    GUITools.SetTokenMoneyIcon(uiTemplate:GetControl(2), self._TemplateData.MoneyType)
--    GUI.SetText(number,tostring(self._ClientData[index + 1].ItemNum))
    --local itemTemp = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
    if lab_item_name ~= nil then
        GUI.SetText(lab_item_name, RichTextTools.GetItemNameRichText(self._ClientData[index + 1].ItemID, 1, false))
    end
    local start_time = self._ClientData[index + 1].PutawayTime
    local specialId = self._ItemDurationSpecialId[self._ClientData[index + 1].Duration] 
    local duration = tonumber(CElementData.GetSpecialIdTemplate(specialId).Value) *3600
    local callback = function()
        local time = duration - (GameUtil.GetServerTime() / 1000  - start_time)
        GUI.SetText(lab_time, GUITools.FormatTimeFromSecondsToZero(true, time))
    end
    self._ItemShowTimerID[index] = _G.AddGlobalTimer(1, false, callback)
end

def.method('userdata','number').OnInitTreasureSecondOrAuctionFirst = function (self,item,index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate) 
    local lab_item_name = uiTemplate:GetControl(0)
    local imgMoney1 = uiTemplate:GetControl(2)
    local button_obj1 = uiTemplate:GetControl(1)
    local button_obj2 = uiTemplate:GetControl(9)
    local imgMoney2 = uiTemplate:GetControl(5)
    local labTime = uiTemplate:GetControl(8)
    local basePrice = uiTemplate:GetControl(3)
    local item_icon = uiTemplate:GetControl(4)
    local highestPrice = uiTemplate:GetControl(6)
    local lab_Lv = uiTemplate:GetControl(7)
    local lab_Count = uiTemplate:GetControl(10)
    local lab_level = uiTemplate:GetControl(11)
    local lab_btn_tip = uiTemplate:GetControl(12)
    local itemData = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
    local count = 0
    if itemData ~= nil then
        count = game._CCountGroupMan:OnCurUseCount(itemData.ItemUseCountGroupId)
    end
    local setting = {
        [EItemIconTag.Activated] = count > 0,
        [EItemIconTag.Grade] = itemData ~= nil and itemData.ItemType == EItemType.Equipment 
            and self._ClientData[index + 1].Item ~= nil and self._ClientData[index + 1].Item.FightProperty.star or nil
    }
    IconTools.InitItemIconNew(item_icon, self._ClientData[index + 1].ItemID, setting, EItemLimitCheck.AllCheck)
    GUI.SetText(lab_item_name, RichTextTools.GetItemNameRichText(self._ClientData[index + 1].ItemID, 1, false))
    GUI.SetText(lab_level, string.format(StringTable.Get(10657), itemData.InitLevel))
    lab_level:SetActive(itemData.InitLevel > 0)
    --设置物品等级
    if itemData.MinLevelLimit == 0 then
        GUI.SetText(lab_Lv,StringTable.Get(132))
    else 
        GUI.SetText(lab_Lv,tostring(itemData.MinLevelLimit))
    end
    --设置数量
    if self._ClientData[index + 1].Item ~= nil and self._ClientData[index + 1].Item.Count > 0 then
        lab_Count:SetActive(true)
        GUI.SetText(lab_Count,tostring(self._ClientData[index + 1].Item.Count))
    else
        lab_Count:SetActive(false)
    end
    --设置一口价
    if self._ClientData[index + 1].FixedPrice == 0 or self._ClientData[index + 1].FixedPrice == nil then
        button_obj2:SetActive(false)
    else 
        button_obj2 :SetActive(true)
        GUI.SetText(highestPrice,GUITools.FormatMoney(self._ClientData[index + 1].FixedPrice))
    end 
    -- 处理按钮失效
    GUITools.SetGroupImg(button_obj2:FindChild("Image"), 0)
    if self._ClientData[index+1].OwnerId == game._HostPlayer._ID then
        GameUtil.SetButtonInteractable(button_obj1, false)
        GUITools.SetBtnGray(button_obj1, true)
        GUI.SetText(basePrice,GUITools.FormatMoney(self._ClientData[index + 1].StartPrice or self._ClientData[index + 1].Price))
        GUITools.SetGroupImg(button_obj1:FindChild("Image"), 1)
    else
        if self._ClientData[index + 1].Bidder == game._HostPlayer._ID then 
            GameUtil.SetButtonInteractable(button_obj1, false)
            GUITools.SetBtnGray(button_obj1, true)
            GUITools.SetGroupImg(button_obj1:FindChild("Image"), 1)
            GUI.SetText(basePrice,GUITools.FormatMoney(self._ClientData[index + 1].StartPrice))
            GUI.SetText(lab_btn_tip, StringTable.Get(20425))
        else 
            GUI.SetText(basePrice,GUITools.FormatMoney(self._ClientData[index + 1].StartPrice or self._ClientData[index + 1].Price))
            GameUtil.SetButtonInteractable(button_obj1, true)
            GUITools.SetBtnGray(button_obj1, false)
            GUITools.SetGroupImg(button_obj1:FindChild("Image"), 0)
            GUI.SetText(lab_btn_tip, StringTable.Get(20432))
        end
    end

    if self._ClientData[index + 1].Duration ~= nil and self._ClientData[index + 1].Duration > 0 then
        local time = 0
        if not self._IsOnClickSortButton  then
            if self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION then
                local specialId = 242
                local duration = tonumber(CElementData.GetSpecialIdTemplate(specialId).Value)
                if duration then
                    time = duration - (GameUtil.GetServerTime() / 1000  - self._ClientData[index + 1].PutawayTime)
                else
                    time = 0
                end
            else
                local specialId = self._ItemDurationSpecialId[self._ClientData[index + 1].Duration] 
                local duration = tonumber(CElementData.GetSpecialIdTemplate(specialId).Value) *3600
                time = duration - (GameUtil.GetServerTime() / 1000  - self._ClientData[index + 1].PutawayTime)
            end
        else
            time = self._ClientData[index + 1].RemainTime
        end

        self:ShowTime(time,labTime,self._ClientData[index + 1].ItemPos,false)
    end
    GUITools.SetTokenMoneyIcon(imgMoney1, self._TemplateData.MoneyType)
    GUITools.SetTokenMoneyIcon(imgMoney2, self._TemplateData.MoneyType)
end

-- 售卖界面ItemList初始化
def.method('userdata','number').OnInitSellExchangeItem = function (self,item,index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local frame_Have = uiTemplate:GetControl(11)
    local item_icon = uiTemplate:GetControl(2)
    local item_temp = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
    local count = 0
    if item_temp ~= nil then
        count = game._CCountGroupMan:OnCurUseCount(item_temp.ItemUseCountGroupId)
    end
    local setting = {
        [EItemIconTag.Activated] = count > 0,
        [EItemIconTag.Grade] = item_temp ~= nil and item_temp.ItemType == EItemType.Equipment 
            and self._ClientData[index + 1].Item ~= nil and self._ClientData[index + 1].Item.FightProperty.star or nil
    }
    IconTools.InitItemIconNew(item_icon, self._ClientData[index + 1].ItemID, setting, EItemLimitCheck.AllCheck)
    local lab_Price = uiTemplate:GetControl(1)
    GUI.SetText(lab_Price, GUITools.FormatMoney(self._ClientData[index + 1].Price))    
    local duration = 24 *3600
    local time = duration - (GameUtil.GetServerTime() / 1000  - self._ClientData[index + 1].PutawayTime)
    local labTime = uiTemplate:GetControl(8)
    local labTimeTips = uiTemplate:GetControl(9)
    local labItemCount = uiTemplate:GetControl(7)
    local img_Money = uiTemplate:GetControl(0)
    GUI.SetText(labTimeTips,  StringTable.Get(20429) )
    self:ShowTime(time,labTime,self._ClientData[index + 1].ItemPos,false)
    GUI.SetText(labItemCount, tostring(self._ClientData[index + 1].ItemNum))
    GUITools.SetTokenMoneyIcon(img_Money, self._TemplateData.MoneyType)
end
def.method('userdata','number').OnInitSellTreasureItem = function (self,item,index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local frame_Have = uiTemplate:GetControl(11)
    local lab_Tips = uiTemplate:GetControl(10)
    local item_icon = uiTemplate:GetControl(0)
    local item_temp = CElementData.GetItemTemplate(self._ClientData[index + 1].ItemID)
    local count = 0
    if item_temp ~= nil then
        count = game._CCountGroupMan:OnCurUseCount(item_temp.ItemUseCountGroupId)
    end
    local setting = {
        [EItemIconTag.Number] = self._ClientData[index + 1].ItemNum,
        [EItemIconTag.Activated] = count > 0,
    }
    IconTools.InitItemIconNew(item_icon, self._ClientData[index + 1].ItemID, setting, EItemLimitCheck.AllCheck)

    local labTime = uiTemplate:GetControl(4)
    local basePrice = uiTemplate:GetControl(8)
    local highestPrice = uiTemplate:GetControl(6)
    GUI.SetText(basePrice,GUITools.FormatMoney(self._ClientData[index + 1].StartPrice))
    GUI.SetText(highestPrice, GUITools.FormatMoney(self._ClientData[index + 1].FixedPrice))
    --显示上架剩余时间 = 道具持续时间-（当前时间-上架时间）
    local specialId = self._ItemDurationSpecialId[self._ClientData[index + 1].Duration] 
    local duration = tonumber(CElementData.GetSpecialIdTemplate(specialId).Value) *3600
    local time = duration - (GameUtil.GetServerTime() / 1000  - self._ClientData[index + 1].PutawayTime)
    self:ShowTime(time,labTime,self._ClientData[index + 1].ItemPos,false)
    local img_Money1 = uiTemplate:GetControl(7)
    local img_Money2 = uiTemplate:GetControl(9)
    GUITools.SetTokenMoneyIcon(img_Money1, self._TemplateData.MoneyType)
    GUITools.SetTokenMoneyIcon(img_Money2, self._TemplateData.MoneyType)
end

def.method().UpdateBuyPanel = function(self)
    local uiTemplate = self._PanelObject._Frame_Right:FindChild("Frame_NotEmpty"):GetComponent(ClassType.UITemplate)
    local frame_Item = uiTemplate:GetControl(self._FrameRightItemsEnum.FRAME_ITEM)              --物品名称Text
    local lab_ItemCount = uiTemplate:GetControl(self._FrameRightItemsEnum.LAB_ITEMCOUNT)            --物品数量
    local lab_ItemDes = uiTemplate:GetControl(self._FrameRightItemsEnum.LAB_ITEMDES)                --物品的描述
    local lab_CurrentCount = uiTemplate:GetControl(self._FrameRightItemsEnum.LAB_CURRENTCOUNT)      --当前购买的物品数量
    local lab_item_name = uiTemplate:GetControl(self._FrameRightItemsEnum.LAB_ITEMNAME)             --物品名称
    local Img_HavenMoney = uiTemplate:GetControl(self._FrameRightItemsEnum.IMG_HAVENMONEY)          --钱图标
    local lab_Haven = uiTemplate:GetControl(self._FrameRightItemsEnum.LAB_HAVENMONEY)               --背包中的钱数
    local lab_level = uiTemplate:GetControl(self._FrameRightItemsEnum.LAB_LEVEL)                    --物品等级

    local itemTemp = CElementData.GetItemTemplate(self._BuyItemData.ItemID)
    local count = 0
    if itemTemp ~= nil then
        count = game._CCountGroupMan:OnCurUseCount(itemTemp.ItemUseCountGroupId)
    end
    local setting = {
        [EItemIconTag.Activated] = count > 0,
    }

    if itemTemp ~= nil and itemTemp.ItemType == EItemType.Equipment and self._BuyItemData.Item ~= nil then
        setting = {
            [EItemIconTag.Activated] = count > 0,
            [EItemIconTag.Grade] = self._BuyItemData.Item.FightProperty.star
        }
    end
    IconTools.InitItemIconNew(frame_Item, self._BuyItemData.ItemID, setting, EItemLimitCheck.AllCheck)

    GUI.SetText(lab_ItemCount, tostring(self._BuyItemData.ItemNum))
    GUI.SetText(lab_ItemDes, itemTemp.TextDescription)
    GUI.SetText(lab_CurrentCount, tostring(self._BuyItemNumber))

    GUI.SetText(lab_item_name, RichTextTools.GetItemNameRichText(self._BuyItemData.ItemID, 1, false))
    GUI.SetText(lab_level, string.format(StringTable.Get(10657), itemTemp.InitLevel))
    lab_level:SetActive(itemTemp.InitLevel > 0)
    local setting = {
        [EnumDef.CommonBtnParam.MoneyID] = self._TemplateData.MoneyType,
        [EnumDef.CommonBtnParam.MoneyCost] = self._BuyItemNumber * self._BuyItemData.Price  
    }
    self._Btn_Buy:ResetSetting(setting)
    GUI.SetText(lab_Haven, tostring(game._HostPlayer:GetMoneyCountByType(self._TemplateData.MoneyType)))
    GUITools.SetTokenMoneyIcon(Img_HavenMoney, self._TemplateData.MoneyType)
end

def.method().ResetBuyDataAndPanel = function(self)
    self._BuyItemData = nil
    self._CurrentSelectItemIndex = 0
    self._BuyItemNumber = 1
    if self._CurrentSelectItem ~= nil then
        self._CurrentSelectItem:GetComponent(ClassType.UITemplate):GetControl(3):SetActive(false)
    end
    self._PanelObject._Frame_Right:FindChild("Frame_NotEmpty"):SetActive(false)
    self._PanelObject._Frame_Right:FindChild("Frame_Empty"):SetActive(true)
end

--购买成功
def.method().SuccessBuy = function (self)
    if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
        game._GUIMan:ShowTipText(StringTable.Get(20421), true)
    else
        if self._IsWithFixedPriceBuy then 
            game._GUIMan:ShowTipText(StringTable.Get(20421), true)
            self._IsWithFixedPriceBuy = false
        else
            game._GUIMan:ShowTipText(StringTable.Get(20424), true)
        end
    end
    self._IsSuccessBuy = true
    game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,self._BuyItemData.ItemID)
end
--购买失败
def.method("number").FailBuy = function (self,resCode)  
    if resCode == 526 then
        game._GUIMan:ShowTipText(StringTable.Get(20420), true)
    elseif resCode == 752 then
        game._GUIMan:ShowTipText(StringTable.Get(20422), true)
    elseif resCode == 750 then
        game._GUIMan:ShowTipText(StringTable.Get(20423), true)
    else
        game._GUIMan:ShowTipText(StringTable.Get(9), true)
    end  
    game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,self._BuyItemData.ItemID) 
end

def.method('userdata','number').OnInitSellBag = function (self,item,index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local itemData = self._SellBagItem[index + 1]
    local count = game._CCountGroupMan:OnCurUseCount(itemData._Template.ItemUseCountGroupId)
    local setting = {
        [EItemIconTag.Number] = itemData._NormalCount,
        [EItemIconTag.New] = false,
        [EItemIconTag.Bind] = itemData:IsBind(),
        [EItemIconTag.Activated] = count > 0,
        [EItemIconTag.Grade] = itemData:IsEquip() and itemData._BaseAttrs.Star or nil
    }
    IconTools.InitItemIconNew(item, itemData._Tid, setting, EItemLimitCheck.AllCheck)
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if self._JustOpenDropdown then
        self._JustOpenDropdown = false
        return
    end
    self._CurrentSortType = index + 1
    self._ClientData = self:SortAscending(self._ClientData ,self._CurrentSortType)
    self:RemoveAllItemShowTimer()
    local itemGuidObj = self:GetUIObject("List_Item_Guid3"):GetComponent(ClassType.GNewList)
    itemGuidObj:SetItemCount(#self._ClientData)
end

def.method("userdata", "number").UpdateTabItemArrow = function(self, item, index)
    local img_arrow = item:FindChild("Img_Arrow")
    if img_arrow then
        GUITools.SetGroupImg(img_arrow, index)
        GUITools.SetNativeSize(img_arrow)
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickTabListDeep1(list,item,bigTypeIndex)
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            self:OnClickTabListDeep2(list,bigTypeIndex,smallTypeIndex)
        end
        if self._CurrentRightToggle ~= self._RightToggleType.EXCHANGE then
            self:RemoveGlobalTimer()
        end
    end
end

def.method('userdata','userdata','number').OnClickTabListDeep1 = function(self,list,item,bigTypeIndex)
    local bigTab = self._TemplateData.UIBigTypes[bigTypeIndex]
    local function OpenTab()
            --如果有小类型 打开小类型
        local current_type_count = #bigTab.UISmallTypes
        self._CurrentSelectBigTabId = bigTab.Id
        self._PanelObject._NodeMenu:OpenTab(current_type_count)
        self:UpdateTabItemArrow(item, 2)
        if current_type_count > 0 then
            local bigTypeID = bigTab.Id
            if self._CurrentSelectSmallIndex > current_type_count then 
                self._CurrentSelectSmallIndex = 1
            end
            local smallTypeID = bigTab.UISmallTypes[self._CurrentSelectSmallIndex].Id
            self._CurrentSelectSmallTabId = smallTypeID
            if not self._JustOpenTab then
                if self._CurrentRightToggle ~= self._RightToggleType.GUILDAUCTION then
                    game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
                else
                    game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,0)
                end
            end
        end 
        self._IsTabOpen = true
    end
    local function CloseTab()
        self._PanelObject._NodeMenu:OpenTab(0)
        self:UpdateTabItemArrow(item, 1)
        self._IsTabOpen = false
    end

    --如果当前是奇珍阁，需要移除刷新计时
    if self._CurrentRightToggle == self._RightToggleType.TREASURE then
        self:RemoveTickUpdateTimer()
    end
    
    if self._CurrentSelectBigTabId == bigTab.Id then
        if self._IsTabOpen then
            CloseTab()
        else
            OpenTab()
        end
    else
        self._CurrentSelectSmallIndex = 1
        if self._LastSelectTabItem ~= nil then
            self:UpdateTabItemArrow(self._LastSelectTabItem, 0)
        end
        self._LastSelectTabItem = item
        OpenTab()
    end
end

def.method('userdata','number','number').OnClickTabListDeep2 = function(self,list,bigTypeIndex,smallTypeIndex)
    local main_type = bigTypeIndex
    local sub_index = smallTypeIndex    
    local bigTypeID = self._TemplateData.UIBigTypes[main_type].Id
    local smallTypeID = self._TemplateData.UIBigTypes[main_type].UISmallTypes[sub_index].Id
    if bigTypeID == self._CurrentSelectBigTabId and smallTypeID ~= self._CurrentSelectSmallTabId then
        self._CurrentSelectSmallTabId = smallTypeID
        if self._IsSuccessBuy then 
            game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
            self._IsSuccessBuy = false
        elseif not self._JustOpenTab then
            if self._CurrentRightToggle ~= self._RightToggleType.GUILDAUCTION then
                --game._CAuctionUtil:GetSmallTabListData(self._CurrentRightToggle,self._CurrentSelectSmallTabId,-1)
                game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
            else
                game._CAuctionUtil:GetGuildSmallTabListData(self._CurrentRightToggle,self._CurrentSelectSmallTabId,-1)
            end
        end
    elseif bigTypeID == self._CurrentSelectBigTabId and smallTypeID == self._CurrentSelectSmallTabId then
        --self._PanelObject._ViewItem0:SetActive(true)
        --self._CheckView:SetActive(true)
        if self._IsSuccessBuy then 
            game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
            self._IsSuccessBuy = false
        elseif not self._JustOpenTab then
            if self._CurrentRightToggle ~= self._RightToggleType.GUILDAUCTION then
                game._CAuctionUtil:GetSmallTabListData(self._CurrentRightToggle,self._CurrentSelectSmallTabId,-1)
            else
                game._CAuctionUtil:GetGuildSmallTabListData(self._CurrentRightToggle,self._CurrentSelectSmallTabId,-1)
            end
        end
    elseif bigTypeID ~= self._CurrentSelectBigTabId then 
        self._CurrentSelectSmallTabId = smallTypeID
        self._CurrentSelectBigTabId = bigTypeID
        if self._CurrentRightToggle ~= self._RightToggleType.GUILDAUCTION then
            game._CAuctionUtil:SendC2SMarketCellList(self._CurrentRightToggle,self._CurrentSelectBigTabId)
        else
            game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,0)
        end
    end 
    --如果当前点击的是奇珍阁，需要移除刷新计时
    if self._CurrentRightToggle == self._RightToggleType.TREASURE--[[ or self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION ]]then
        self:RemoveTickUpdateTimer()
    end
    self._CurrentSelectSmallIndex = sub_index
    self._JustOpenTab = false
end


--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local main_type = main_index + 1
            local bigTabName =  self._TemplateData.UIBigTypes[main_type].DisplayName
            if self._CurrentSelectBigTabId == self._TemplateData.UIBigTypes[main_type].Id then
                self._LastSelectTabItem = item
            end
            self:UpdateTabItemArrow(item, 0)
            GUI.SetText(item:FindChild("Lab_Text"),bigTabName)      
        elseif sub_index ~= -1 then
            local bigTypeIndex = main_index + 1
            local smallTypeIndex = sub_index + 1
            local bigTab = self._TemplateData.UIBigTypes[bigTypeIndex]
            local smallTabName = bigTab.UISmallTypes[smallTypeIndex].DisplayName
            GUI.SetText(item:FindChild("Lab_Text"),smallTabName)      
        end
    end
end

-- 针对交易所页签的商品特殊排序规则加的函数
def.method("table", "=>", "table").SortForExchange = function(self, items)
    local sort_func = function(item1, item2)
        if item1.StartPrice ~= item2.StartPrice then
            return item1.StartPrice < item2.StartPrice
        else
            if item1.RemainTime ~= item2.RemainTime then
                return item1.RemainTime < item2.RemainTime
            else
                return false
            end
        end
        return false
    end
    local itemDatas = {}
    for i,v in ipairs(items) do
        local itemData = CElementData.GetItemTemplate(v.ItemID)
        itemDatas[i] = {}
        itemDatas[i].InitQuality = itemData.InitQuality
        itemDatas[i].InitLevel = itemData.InitLevel
        itemDatas[i].Price = v.Price
        itemDatas[i].StartPrice = v.StartPrice
        itemDatas[i].FixedPrice = v.FixedPrice
        itemDatas[i].PutawayTime = v.PutawayTime
        itemDatas[i].ItemID = v.ItemID
        itemDatas[i].ItemPos = v.ItemPos
        itemDatas[i].Bidder = v.Bidder
        itemDatas[i].OwnerId = v.OwnerId
        itemDatas[i].Item = v.Item
        itemDatas[i].ShareHolder = v.ShareHolder
        itemDatas[i].ItemNum = v.ItemNum
        --拍卖行的持续时间有待改善
        if v.Duration and v.Duration > 0 then
            local specialId = self._ItemDurationSpecialId[v.Duration] 
            local duration = tonumber(CElementData.GetSpecialIdTemplate(specialId).Value) *3600
            local remainTime = duration - (GameUtil.GetServerTime() / 1000  - v.PutawayTime)
            itemDatas[i].RemainTime = remainTime
            itemDatas[i].Duration = v.Duration
        else
            itemDatas[i].RemainTime = 0
            itemDatas[i].Duration = 0
        end
    end
    table.sort(itemDatas,sort_func)
    return itemDatas
end

def.method("table","number","=>","table").SortAscending = function (self,items,key)
    if self._CurrentRightToggle == self._RightToggleType.TREASURE then
        self._IsOnClickSortButton = true 
    end
    local ps = {"InitQuality","InitLevel","RemainTime","StartPrice","FixedPrice","PutawayTime"}
    local propertyName = ps[1]
    local function sort_func(itm1,itm2)
        if itm1.ItemPos ~= itm2.ItemPos then
            return itm1.ItemPos > itm2.ItemPos
        else
            if itm1[propertyName] == nil or itm2[propertyName] == nil then return false end
            if key == 6 or key <=2 then
                return itm1[propertyName] > itm2[propertyName]
            elseif key <= 4 then        --如果拍卖价相同，按照上架时间排序
                if itm1[propertyName] < itm2[propertyName] then
                    return true
                elseif itm1[propertyName] == itm2[propertyName] and itm1.PutawayTime and itm1.PutawayTime > itm2.PutawayTime then
                    return true
                else
                    return false
                end
            else
                if itm1[propertyName] == 0 and itm2[propertyName] == 0 then
                    return false
                elseif itm1[propertyName] == 0 and itm2[propertyName] ~= 0 then
                    return false
                elseif itm2[propertyName] == 0 and itm1[propertyName] ~= 0 then
                    return true
                else
                    return itm1[propertyName] < itm2[propertyName]
                end
            end
        end
    end
    local itemDatas = {}
    for i,v in ipairs(items) do
        local itemData = CElementData.GetItemTemplate(v.ItemID)
        itemDatas[i] = {}
        itemDatas[i].InitQuality = itemData.InitQuality
        itemDatas[i].InitLevel = itemData.InitLevel
        itemDatas[i].StartPrice = v.StartPrice
        itemDatas[i].FixedPrice = v.FixedPrice
        itemDatas[i].PutawayTime = v.PutawayTime
        itemDatas[i].ItemID = v.ItemID
        itemDatas[i].ItemPos = v.ItemPos
        itemDatas[i].Bidder = v.Bidder
        itemDatas[i].OwnerId = v.OwnerId
        itemDatas[i].Item = v.Item
        --拍卖行的持续时间有待改善
        if v.Duration and v.Duration > 0 then
            local specialId = self._ItemDurationSpecialId[v.Duration] 
            local duration = tonumber(CElementData.GetSpecialIdTemplate(specialId).Value) *3600
            local remainTime = duration - (GameUtil.GetServerTime() / 1000  - v.PutawayTime)
            itemDatas[i].RemainTime = remainTime
            itemDatas[i].Duration = v.Duration
        else
            itemDatas[i].RemainTime = 0
            itemDatas[i].Duration = 0
        end
    end
    items = itemDatas
    propertyName = ps[key]
    local sort_pos = function(item1, item2)
        if item1.ItemPos ~= item2.ItemPos then
            return item1.ItemPos > item2.ItemPos
        else
            return false
        end
        return false
    end
    if #items > 1 then
        table.sort(items, sort_func)
    end
    return items
end

def.method( "number","userdata","number","boolean").ShowTime = function (self, startTime,textObj,itemPos,isRushTime)
    local index = itemPos + 1
    if  self._TimerID[index] ~= nil then
        if self._TimerID[index] ~= 0 then
            _G.RemoveGlobalTimer(self._TimerID[index])
            self._TimerID[index] = 0
        end
    else 
        self._TimerID[index] = 0
    end
    if self._TimerID[index] == 0 then

        local callback = function()
            local hour = math.floor(startTime / 3600)
            if hour < 10 then
                hour = "0" .. hour
            end
            local minute = math.floor((startTime % 3600) / 60)
            if minute < 10 then
                minute = "0" .. minute
            end
            local second =  math.floor(startTime % 60)
            if second < 10 then
                second = "0" .. second
            end
            if not IsNil(textObj) then
                if isRushTime then
                    GUI.SetText(textObj,minute ..StringTable.Get(20427)..second..StringTable.Get(20428))
                else
                    GUI.SetText(textObj,hour..":"..minute..":"..second)
                end     
            end
            startTime = startTime - 1

            if startTime <= 0 then 
                -- 消除计时器
                _G.RemoveGlobalTimer(self._TimerID[index])
                self._TimerID[index] = 0
                if self._CurrentRightToggle == self._RightToggleType.EXCHANGE then
                    game._CAuctionUtil:SendC2SMarketRefItemList(self._CurrentRightToggle,self._CurrentSelectBigTabId,false)
                end
            end            
        end
        self._TimerID[index] = _G.AddGlobalTimer(1, false, callback)  
    end
end

def.method().RemoveGlobalTimer = function(self)
    for i,v in pairs(self._TimerID) do
        _G.RemoveGlobalTimer(v)
        v = 0
    end
    self._TimerID = {}
end

def.method().RemoveAllItemShowTimer = function(self)
    for i,v in pairs(self._ItemShowTimerID) do
        _G.RemoveGlobalTimer(v)
        v = 0
    end
    self._ItemShowTimerID = {}
end

--添加可竞拍界面的竞拍价实时刷新的Timer
def.method().AddTickUpdateTimer = function(self)
    if self._UpdatePriceTimeID ~= -1 then
        _G.RemoveGlobalTimer(self._UpdatePriceTimeID)
    end
    local callback = function()
        if self._CurrentRightToggle == self._RightToggleType.GUILDAUCTION then
            game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,0)
        elseif self._CurrentRightToggle == self._RightToggleType.TREASURE then
            game._CAuctionUtil:SendC2SMarketItemList(self._CurrentRightToggle,self._NowFirstItemID)
        end
    end
    self._UpdatePriceTimeID = _G.AddGlobalTimer(1, false, callback)
end
--删除可竞拍界面的竞拍价实时刷新的Timer
def.method().RemoveTickUpdateTimer = function(self)
    if self._UpdatePriceTimeID ~= -1 then
        _G.RemoveGlobalTimer(self._UpdatePriceTimeID)
        self._UpdatePriceTimeID = -1
        self._NowFirstItemID = -1
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:RemoveGlobalTimer()
    self:RemoveAllItemShowTimer()
    self:RemoveTickUpdateTimer()
    self._CurrentSelectItemIndex = 0
    self._SellItemCount = 0
    self._CurrentSelectBigTabId = 0
    self._CurrentSelectSmallTabId = 0
    self._CurrentSelectSmallIndex = 1
    self._CurrentRightToggle = 1
    self._CurrentUpToggle = 1
    self._CurrentBagType = 1
    self._CurrentSortType = 1
    self._IsOnClickSortButton = false
    self._IsSuccessBuy = false
    self._ButtonLabObj = nil
    self._IsWithFixedPriceBuy = false      --  是否用一口价进行购买
    self._IsTabOpen = false
    self._JustOpenTab = true
    self._IsShowCanUse = true
    self._SortDropDownText = ""
    CGame.EventManager:removeHandler(ItemLockEvent, OnItemLockEvent)
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
    if self._Btn_Refresh ~= nil then
        self._Btn_Refresh:Destroy()
        self._Btn_Refresh = nil
    end
    if self._Num_Input ~= nil then
        self._Num_Input:Destroy()
        self._Num_Input = nil
    end
    self._PanelObject = nil
    self._CurrentSelectItem = nil
    self._PutawayItemInfoData = nil
    self._ItemDurationSpecialId = nil
    self._AllItemInfo = nil
    self._SellBagItem = nil
    self._RightToggleType = nil
    self._UpToggleType = nil
    self._BagType = nil
    self._AllBagItems = nil
    self._FrameRightItemsEnum = nil
    self._LastSelectTabItem = nil
end
CPanelAuction.Commit()
return CPanelAuction