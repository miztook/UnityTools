
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require"Data.CElementData"
local CPanelAuction = require'GUI.CPanelAuction'
local EResourceType = require "PB.data".EResourceType
local CPanelAuctionSell1 = Lplus.Extend(CPanelBase, 'CPanelAuctionSell1')
local def = CPanelAuctionSell1.define

def.field("userdata")._LabCost = nil
def.field("number")._BuyItemNumber = 1 --默认购买一个
def.field("number")._ItemMaxNumber = 10
def.field("number")._UnitPrice = 0
def.field("table")._ItemData = BlankTable
def.field("userdata")._BuyAuctionOrTreasureUI = nil
def.field("userdata")._Frame_FixedTip = nil
def.field("userdata")._Frame_StartTip = nil
def.field("number")._TotalPrice = 0
def.field("userdata")._Img_SellGold2 = nil 
def.field("userdata")._Lab_Title = nil
def.field("number")._BuyType = -1   --0是一口价，1是竞拍价,3是竞拍价超过一口价

local instance = nil
def.static('=>', CPanelAuctionSell1).Instance = function ()
	if not instance then
        instance = CPanelAuctionSell1()
        instance._PrefabPath = PATH.Panel_AuctionSell1
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
        instance._DestroyOnHide = true
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._BuyAuctionOrTreasureUI = self:GetUIObject("BuyTreasureOrAuction")
    self._Img_SellGold2 = self:GetUIObject("Img_SellGold2")
    self._Frame_FixedTip = self:GetUIObject("Frame_FixedTip")
    self._Frame_StartTip = self:GetUIObject("Frame_StartTip")
    self._Lab_Title = self:GetUIObject("Lab_Title")
end

def.override('dynamic').OnData = function(self, data)
    self._ItemData = data.data
    self._BuyType = data.buyType
    self:UpdataBuyUIShow()
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Buy' or id == "Btn_Ok" then
        local money_id = CPanelAuction.Instance()._TemplateData.MoneyType
        local moneyCount = game._HostPlayer:GetMoneyCountByType(money_id)
        if id == "Btn_Buy" then
            local callback = function(val)
                if val then
                    game._CAuctionUtil:SendC2SMarketItemBuy(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData.ItemID,self._UnitPrice,self._BuyItemNumber)
                end
            end
            MsgBox.ShowQuickBuyBox(money_id, self._TotalPrice, callback)
        --竞价
        elseif id == "Btn_Ok" then
            local callback = function(val)
                if val then
                    game._CAuctionUtil:SendC2SMarketBidding(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData.ItemPos,self._UnitPrice)
                    game._GUIMan:CloseByScript(self)
                end
            end
            MsgBox.ShowQuickBuyBox(money_id, self._TotalPrice, callback)
        end
    elseif id == "Btn_Up" then        
        if self._BuyItemNumber < self._ItemMaxNumber then
            self._BuyItemNumber = self._BuyItemNumber + 1
            self:UpdataTotalPriceAndNumber()   
        else
            game._GUIMan:ShowTipText(StringTable.Get(20426), true)
        end
    elseif id == "Btn_Down"then         
        if self._BuyItemNumber > 1 then
            self._BuyItemNumber = self._BuyItemNumber -1 
            self:UpdataTotalPriceAndNumber()     
        end        
    elseif id == "Btn_Max" then
        self._BuyItemNumber = self._ItemMaxNumber
        self:UpdataTotalPriceAndNumber()
    elseif id == 'Btn_Back' or id == 'Btn_Cancel' then
        game._GUIMan:CloseByScript(self) 
    elseif id == "Img_ItemIcon1" or id == "ItemIconNew" then
        CItemTipMan.ShowItemTips(self._ItemData.ItemID, TipsPopFrom.OTHER_PANEL)
    end
end
def.method("number").FailBuy = function (self,resCode)  
    game._GUIMan:CloseByScript(self) 
    if resCode == 526 then
        game._GUIMan:ShowTipText(StringTable.Get(20420), true)
    elseif resCode == 562 then
        game._GUIMan:ShowTipText(StringTable.Get(20422), true)
    elseif resCode == 525 then
        game._GUIMan:ShowTipText(StringTable.Get(20423), true)
    end  
    game._CAuctionUtil:SendC2SMarketItemList(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData.ItemID) 
    
    -- body
end
def.method().SuccessBuy = function (self)
    game._GUIMan:CloseByScript(self) 
    if CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.EXCHANGE then
        game._GUIMan:ShowTipText(StringTable.Get(20421), true)
    else
        if CPanelAuction.Instance()._IsWithFixedPriceBuy then 
            game._GUIMan:ShowTipText(StringTable.Get(20421), true)
            CPanelAuction.Instance()._IsWithFixedPriceBuy = false
        else
            game._GUIMan:ShowTipText(StringTable.Get(20424), true)
        end
    end
    CPanelAuction.Instance()._IsSuccessBuy = true
    game._CAuctionUtil:SendC2SMarketItemList(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData.ItemID)
   
end
def.method().UpdataBuyUIShow = function (self)
--卖界面更新
    local itemData = CElementData.GetItemTemplate(self._ItemData.ItemID)
    if CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.EXCHANGE then

    else
        if itemData == nil then warn("error !!! 物品不存在！ ID: ", self._ItemData.ItemID) return end
        self._BuyAuctionOrTreasureUI:SetActive(true)
        self._BuyItemNumber = 1
        local setting = {
            [EItemIconTag.Number] = self._ItemData.Item.Count,
        }
        IconTools.InitItemIconNew(self:GetUIObject("ItemIconNew"), self._ItemData.ItemID, setting, EItemLimitCheck.AllCheck)
        local colorname = ""
        local size = GUITools.GetTextSize(self:GetUIObject("Lab_ItemName2"))
        if size == nil or itemData.InitLevel <= 0 then
            colorname = RichTextTools.GetItemNameRichText(self._ItemData.ItemID, 1, false)
        else
            local strLv = string.format(StringTable.Get(19073), itemData.InitLevel)
            strLv = GUITools.FormatRichTextSize(size-2, strLv)
            colorname = RichTextTools.GetItemNameRichText(self._ItemData.ItemID, 1, false)..strLv
        end
        local itemNameObj2 = self:GetUIObject("Lab_ItemName2"):GetComponent(ClassType.Text)
        itemNameObj2.text = colorname
        self._LabCost = self:GetUIObject("Lab_CostNumber21")

        local lab_Tip = nil
        local tex_Tip = ""
        local tex_title = ""
        if self._BuyType == 0 then      --如果是一口价
            self._UnitPrice = self._ItemData.FixedPrice
            self._TotalPrice = self._UnitPrice 
            self._Frame_FixedTip:SetActive(true)
            self._Frame_StartTip:SetActive(false)
            lab_Tip = self._Frame_FixedTip:FindChild("Lab_StockNumber1")
            tex_Tip = string.format(StringTable.Get(20439),self._TotalPrice,
                 "<color=#" .. EnumDef.Quality2ColorHexStr[itemData.InitQuality] ..">" .. itemData.TextDisplayName .."</color>")
            tex_title = StringTable.Get(31008)
        elseif self._BuyType == 1 then      --如果是竞拍价
            self._UnitPrice = math.ceil(self._ItemData.StartPrice * 1.1) 
            self._TotalPrice = self._UnitPrice 
            self._Frame_FixedTip:SetActive(false)
            self._Frame_StartTip:SetActive(true)
            lab_Tip = self._Frame_StartTip:FindChild("Lab_StockNumber2")
            tex_Tip = string.format(StringTable.Get(20440),self._TotalPrice)
            tex_title = StringTable.Get(20448)
        elseif self._BuyType == 3 then      --如果是竞拍价，但是竞拍的价格大于一口价
            self._UnitPrice = self._ItemData.FixedPrice
            self._TotalPrice = self._UnitPrice
            self._Frame_FixedTip:SetActive(true)
            self._Frame_StartTip:SetActive(false)
            lab_Tip = self._Frame_FixedTip:FindChild("Lab_StockNumber1")
            tex_Tip = string.format(StringTable.Get(20441),self._TotalPrice,
                 "<color=#" .. EnumDef.Quality2ColorHexStr[itemData.InitQuality] ..">" .. itemData.TextDisplayName .."</color>")
            tex_title = StringTable.Get(31008)
        else
            warn("Unknown BuyType!!!!")
            self._UnitPrice = 0
        end
        GUI.SetText(lab_Tip, tex_Tip)

        local templateData = CElementData.GetMarketTemplate(CPanelAuction.Instance()._CurrentRightToggle)
        GUITools.SetTokenMoneyIcon(self._Img_SellGold2, templateData.MoneyType)
        GUI.SetText(self._Lab_Title, tex_title)
        GUI.SetText(self._LabCost, GUITools.FormatMoney(self._TotalPrice))
    end
end
def.method().UpdataTotalPriceAndNumber = function (self)
    self._TotalPrice = self._UnitPrice * self._BuyItemNumber
    GUI.SetText(self._LabCost, GUITools.FormatMoney(self._TotalPrice))
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._BuyAuctionOrTreasureUI = nil
    self._Img_SellGold2 = nil
    self._Frame_FixedTip = nil
    self._Frame_StartTip = nil
    self._ItemData = nil
    self._LabCost = nil
    self._Lab_Title = nil
    self._BuyItemNumber = 1
    self._ItemMaxNumber = 10
    self._UnitPrice = 0
    self._TotalPrice = 0
end

CPanelAuctionSell1.Commit()
return CPanelAuctionSell1

