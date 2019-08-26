
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelAuction = require'GUI.CPanelAuction'
local CElementData = require"Data.CElementData"
local EItemType = require "PB.Template".Item.EItemType
local CPanelAuctionSell2 = Lplus.Extend(CPanelBase, 'CPanelAuctionSell2')
local def = CPanelAuctionSell2.define
local have_putOn_money = false

def.field("userdata")._ExchangeSell = nil
def.field("userdata")._TreasureSell = nil
def.field("userdata")._InputObj1 = nil           --交易行输入框对应数量、单价 -- 奇珍阁输入框对应起拍价 、一口价
def.field("userdata")._InputObj2 = nil
def.field("userdata")._Btn_Minus = nil
def.field("userdata")._LabItemCount = nil        -- 物品数目
def.field('number')._MaxValue1 = 0               -- 交易行对应最大数量/最大单价 -- 奇珍阁对应起拍价 一口价
def.field('number')._MaxValue2 = 0
def.field('number')._MinValue1 = 0
def.field('number')._MinValue2 = 0
def.field('number')._Value1 = 0                  -- 记录两个默认框的值 -- 交易行总价 = 单价 *数量
def.field('number')._Value2 = 0
def.field('boolean')._IsOnClickZero = true       -- 一口价默认值为0
def.field("userdata")._FreePriceObj = nil        -- 手续费
def.field("userdata")._Frame_Charge = nil        -- 手续费Frame
def.field("number")._FreePriceSpecialId = 240    -- 手续费ID
def.field('number')._TotalPrice = 0
def.field('userdata')._TotalPriceObj = nil
def.field("table")._ItemData = BlankTable
def.field('boolean')._IsExchange = false
def.field("number")._PutawaryTimeIndex = 1       -- 默认物品上架时间6小时
def.field("boolean")._IsCanBuy = false
def.field("boolean")._IsLackFree = false 
def.field('boolean')._IsEnoughCount = false
def.field("number")._PutawayItemCountSpecialId = 234



local instance = nil
def.static('=>', CPanelAuctionSell2).Instance = function ()
	if not instance then
        instance = CPanelAuctionSell2()
        instance._PrefabPath = PATH.Panel_AuctionSell2
        instance._PanelCloseType = EnumDef.PanelCloseType.None

        instance:SetupSortingParam()

        -- instance._DestroyOnHide = true
        -- TO DO
	end
	return instance
end
 

def.override().OnCreate = function(self)
    self._ExchangeSell = self:GetUIObject('Exchange')
    self._TreasureSell = self:GetUIObject('Treasure')
    self._Btn_Minus = self:GetUIObject('Btn_Down20')
end
def.override("dynamic").OnData = function(self, data)
    self._ItemData = data
    self._PutawaryTimeIndex = 1
    self._IsCanBuy = false
    self._IsLackFree = false 
    self._IsEnoughCount = false
    self:SetStartData()
    self:UpdataSellUIShow()
end
def.override('string').OnClick = function(self, id)
    if id == 'Btn_Down1' or id =='Btn_Up1'  then
        self._Value1 = self:PlusOrMinusButton(self._Value1,id,self._InputObj1,self._MaxValue1,self._MinValue1)
    elseif id == 'Btn_Down2' or id =='Btn_Up2' then
        self._Value2 = self:PlusOrMinusButton(self._Value2,id,self._InputObj2,self._MaxValue2,self._MinValue2)
    elseif id == 'Btn_Max1' then
        self._Value1 = self._MaxValue1 
        GUI.SetText(self._InputObj1,GUITools.FormatNumber(self._Value1, false))
    elseif id == 'Btn_Max2' then
        self._Value2 = self._MaxValue2 
        GUI.SetText(self._InputObj2,GUITools.FormatNumber(self._Value2, false))
    elseif id == 'Btn_Zero' then
        self._Value2 = 0
        self._IsOnClickZero = true
        GUI.SetText(self._InputObj2,StringTable.Get(20405))
    elseif id =='Input_Name1' then
        self:OnClickInput1()
    elseif id == "Input_Name2" then
        self:OnClickInput2()
    elseif id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self) 
    elseif id == 'Btn_Sell1' or id == "Btn_Sell2" then  
        self:Buy(id)
    elseif id == "ExItemIcon" or id == "TrItemIcon" then
        local normalPack = game._HostPlayer._Package._NormalPack
        local itemData = normalPack:GetItemBySlot(self._ItemData._Slot)
        local item_temp = CElementData.GetItemTemplate(itemData._Tid)
        if item_temp ~= nil then
            if item_temp.ItemType == EItemType.Equipment then
                CItemTipMan.ShowPackbackEquipTip(itemData, TipsPopFrom.WithoutButton,TipPosition.FIX_POSITION)
            else
                CItemTipMan.ShowItemTips(itemData._Tid, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
            end
        end
        return 
    end
    if self._IsExchange then 
        self._TotalPrice = self._Value1 *self._Value2
        GUI.SetText(self._TotalPriceObj, GUITools.FormatNumber(self._TotalPrice, true))
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if string.find(id, "Rdo_Sell") then
        local index = string.sub(id, -1)
        --0、1、2、3 分别是24、24、12、6小时
        self._PutawaryTimeIndex = tonumber(index)
    end
end

def.method().OnClickInput1 = function(self)
    if CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.EXCHANGE then
        local function callback(count)
            if not self:IsShow() then return end
    		if count == nil or count <= 0 then 
    			self._Value1 = 1 
    		else
    			self._Value1 = count
    		end
            if self._Value1 > self._MaxValue1 then
                self._Value1 = self._MaxValue1
                game._GUIMan:ShowTipText(StringTable.Get(20406), true)
            end
            if self._Value1 < self._MinValue1 then
                self._Value1 = self._MinValue1
                game._GUIMan:ShowTipText(StringTable.Get(20443), true)
            end
    		self:UpdataSellUIShow()
    	end
    	game._GUIMan:OpenNumberKeyboard(self._InputObj1,nil,0,self._MaxValue1,callback, nil)
    elseif CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.TREASURE then
        local function callback(count)
            if not self:IsShow() then return end
    		if count == nil or count <= 0  then 
    			self._Value1 = self._MinValue1
    		else
    			self._Value1 = count
    		end
            if self._Value1 > self._MaxValue1 then
                self._Value1 = self._MaxValue1
                game._GUIMan:ShowTipText(StringTable.Get(20409), true)
            end
            if self._Value1 < self._MinValue1 then
                self._Value1 = self._MinValue1
                game._GUIMan:ShowTipText(StringTable.Get(20412), true)
            end
            self._MinValue2 = math.min( math.ceil(self._Value1 * 1.1), self._MaxValue2)
    		self:UpdataSellUIShow()
    	end
    	game._GUIMan:OpenNumberKeyboard(self._InputObj1,nil,0,self._MaxValue1,callback, nil)
    end
end

def.method().OnClickInput2 = function(self)
    if CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.EXCHANGE then
        local function callback(count)
            if not self:IsShow() then return end
    		if count == nil or count <= 0 then 
    			self._Value2 = self._ItemData.MinPrice
    		else
    			self._Value2 = count
    		end
            if self._Value2 > self._MaxValue2 then
                self._Value2 = self._MaxValue2
                game._GUIMan:ShowTipText(StringTable.Get(20407), true)
            end
            if self._Value2 < self._MinValue2 then
                self._Value2 = self._MinValue2
                game._GUIMan:ShowTipText(StringTable.Get(20411), true)
            end
    		self:UpdataSellUIShow()
    	end
    	game._GUIMan:OpenNumberKeyboard(self._InputObj2,nil,0,self._MaxValue2,callback, nil)
    elseif CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.TREASURE then
        local function callback(count)
            if not self:IsShow() then return end
    		if count == nil or count <= 0 or self._InputObj2:GetComponent(ClassType.Text).text == StringTable.Get(20405) then 
    			self._Value2 = 0
                self._IsOnClickZero = true
                self._MaxValue1 = math.ceil(self._MaxValue2 * 0.9)
    		else
    			self._Value2 = tonumber(self._InputObj2:GetComponent(ClassType.Text).text)
                self._IsOnClickZero = false
    		end
            if self._Value2 > self._MaxValue2 then
                self._Value2 = self._MaxValue2
                game._GUIMan:ShowTipText(StringTable.Get(20410), true)
            end
            if self._Value2 < self._MinValue2 and self._Value2 ~= 0 then
                self._Value2 = self._MinValue2
                game._GUIMan:ShowTipText(StringTable.Get(20408), true)
            end
            if self._Value2 ~= 0 then
                self._MaxValue1 = math.max(math.ceil(self._Value2 * 0.9), self._MinValue1)
            end
    		self:UpdataSellUIShow()
    	end
    	game._GUIMan:OpenNumberKeyboard(self._InputObj2,nil,0,self._MaxValue2,callback, nil)
    end
end

def.method("=>", "boolean").ItemLockedCheck = function(self)
    if self._ItemData == nil then
        return false
    else
        if self._ItemData._Slot ~= nil then
            local package = game._HostPlayer._Package._NormalPack
            local item = package:GetItemBySlot(self._ItemData._Slot)
            if item == nil then
                return false
            else
                if item:IsEquip() then
                    return (not item._IsLock)
                else
                    return true
                end
            end
        else
            return false
        end
    end
    return false
end

-- 可以根据服务器端的错误码进行判断
def.method("string").Buy = function ( self,id)
    local count = tonumber (CElementData.GetSpecialIdTemplate(self._PutawayItemCountSpecialId).Value)
    if CPanelAuction.Instance()._SellItemCount < count then
        self._IsEnoughCount = true 
    else 
        self._IsEnoughCount = false
    end
    if self._IsEnoughCount and not self._IsLackFree then 
        self._IsCanBuy = true 
    else 
        self._IsCanBuy = false  
    end
    if self._IsCanBuy  then 
        if self:ItemLockedCheck() then
            if id == 'Btn_Sell1' then
                game._CAuctionUtil:SendC2SMarketItemPutaway(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData._Slot,self._Value1,self._Value2,0,0)
            elseif id == "Btn_Sell2" then 
                game._CAuctionUtil:SendC2SMarketItemPutaway(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData._Slot,1,self._Value1,self._Value2,self._PutawaryTimeIndex)
            end
            game._GUIMan:ShowTipText(StringTable.Get(20416), true)
        else
            game._GUIMan:ShowTipText(StringTable.Get(20451), true)
        end
        game._GUIMan:CloseByScript(self) 
    else 
        if self._IsLackFree then 
            local callback = function(val)
                if val then
                    if id == 'Btn_Sell1' then
                        game._CAuctionUtil:SendC2SMarketItemPutaway(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData._Slot,self._Value1,self._Value2,0,0)
                    elseif id == "Btn_Sell2" then 
                        game._CAuctionUtil:SendC2SMarketItemPutaway(CPanelAuction.Instance()._CurrentRightToggle,self._ItemData._Slot,1,self._Value1,self._Value2,self._PutawaryTimeIndex)
                    end
                    game._GUIMan:CloseByScript(self) 
                    game._GUIMan:ShowTipText(StringTable.Get(20416), true)
                end
            end
            local EResourceType = require "PB.data".EResourceType
            local freePrice = tonumber(CElementData.GetSpecialIdTemplate(self._FreePriceSpecialId).Value)
            MsgBox.ShowQuickBuyBox(EResourceType.ResourceTypeGold, freePrice, callback)
        elseif not self._IsEnoughCount then
            game._GUIMan:ShowTipText(StringTable.Get(20437), true)
        end
    end
    -- body
end

def.method().SetStartData = function(self)
    local currentRightType = CPanelAuction.Instance()._CurrentRightToggle
    if currentRightType == CPanelAuction.Instance()._RightToggleType.EXCHANGE then
        self._IsOnClickZero = false
        self._TotalPriceObj = self:GetUIObject("Lab_TotalPrice")
        self._FreePriceObj = self:GetUIObject("Lab_PriceNumber2")
        self._Frame_Charge = self:GetUIObject("Frame_Charge2")

        self._IsExchange = true
        self._InputObj1 = self:GetUIObject("Label2")
        self._InputObj2 = self:GetUIObject("Label3")
        --最小售出数量 最大售出数量，售卖的最高价与最低价
        self._Value1 ,self._MinValue1 = math.min(99, self._ItemData._NormalCount),1 -- 默认数量
        self._MaxValue1 = math.min(99, self._ItemData._NormalCount)
        self._MinValue2 = self._ItemData.MinPrice -- 默认单价
        self._Value2 = math.ceil((self._ItemData.MinPrice + self._ItemData.MaxPrice)/2)
        self._MaxValue2 = self._ItemData.MaxPrice
    else
        self._IsOnClickZero = true
        self._FreePriceObj = self:GetUIObject("Lab_PriceNumber1")
        self._Frame_Charge = self:GetUIObject("Frame_Charge1")
        self._IsExchange = false
        self._InputObj1 = self:GetUIObject("Label0")
        self._InputObj2 = self:GetUIObject("Label1")
        self._LabItemCount = self:GetUIObject("Lab_Num")
        self._MaxValue2 = self._ItemData.MaxPrice
        self._MaxValue1 = math.min(99, math.floor(self._ItemData.MaxPrice/1.1))--math.ceil(self._ItemData.MaxPrice /1.1) 
        self._MinValue1 = self._ItemData.MinPrice 
        self._Value1 = self._ItemData.MinPrice --+ (self._ItemData.MaxPrice - self._ItemData.MinPrice) % 2
        self._MinValue2 = math.min( math.ceil(1.1 * self._Value1), self._MaxValue2)
        self._Value2 = 0
        GUI.SetText(self._InputObj2,StringTable.Get(20405))
        GameUtil.SetButtonInteractable(self._Btn_Minus, false)
    end
end
def.method().UpdataSellUIShow = function (self)
--卖界面更新
    local itemData = CElementData.GetItemTemplate(self._ItemData._Tid)
    local freePrice = CElementData.GetSpecialIdTemplate(self._FreePriceSpecialId).Value
    if CPanelAuction.Instance()._CurrentRightToggle == CPanelAuction.Instance()._RightToggleType.EXCHANGE then       
        self._ExchangeSell:SetActive(true)
        self._TreasureSell:SetActive(false)
        local count = 0
        if itemData ~= nil then
            count = game._CCountGroupMan:OnCurUseCount(itemData.ItemUseCountGroupId)
        end
        local setting = {
            [EItemIconTag.Activated] = count > 0,
            [EItemIconTag.Grade] = self._ItemData._Star,
        }
        IconTools.InitItemIconNew(self:GetUIObject("ExItemIcon"), self._ItemData._Tid, setting, EItemLimitCheck.AllCheck)
        local labItemCount = self:GetUIObject("Lab_Number1")
        GUI.SetText(labItemCount, GUITools.FormatNumber(self._ItemData._NormalCount, false))
        local colorname = RichTextTools.GetItemNameRichText(self._ItemData._Tid, 1, false)
        local itemNameObj1 = self:GetUIObject("Lab_ItemName1"):GetComponent(ClassType.Text)
        local lab_level = self:GetUIObject("Lab_Level1")
        local item_temp = CElementData.GetItemTemplate(self._ItemData._Tid)
        itemNameObj1.text = colorname
        GUI.SetText(self._TotalPriceObj,GUITools.FormatMoney(self._Value2 * self._Value1))
        GUI.SetText(lab_level, string.format(StringTable.Get(10657), item_temp.InitLevel))
        lab_level:SetActive(item_temp.InitLevel > 0)
        -- 显示输入框的默认值
        GUI.SetText(self._InputObj1, GUITools.FormatNumber(self._Value1, false))
        GUI.SetText(self._InputObj2, GUITools.FormatNumber(self._Value2, false))
        local templateData = CElementData.GetMarketTemplate(CPanelAuction.Instance()._CurrentRightToggle)
        GUITools.SetTokenMoneyIcon(self:GetUIObject("Img_SellGold1"), templateData.MoneyType)
    else 
        self._ExchangeSell:SetActive(false)
        self._TreasureSell:SetActive(true)
        local count = 0
        if itemData ~= nil then
            count = game._CCountGroupMan:OnCurUseCount(itemData.ItemUseCountGroupId)
        end
        local setting = {
            [EItemIconTag.Activated] = count > 0,
            [EItemIconTag.Grade] = self._ItemData._Star,
        }
        IconTools.InitItemIconNew(self:GetUIObject("TrItemIcon"), self._ItemData._Tid, setting, EItemLimitCheck.AllCheck)
        local colorname = RichTextTools.GetItemNameRichText(self._ItemData._Tid, 1, false)
        local itemNameObj0 = self:GetUIObject("Lab_ItemName0"):GetComponent(ClassType.Text)
        local lab_level = self:GetUIObject("Lab_Level")
        local item_temp = CElementData.GetItemTemplate(self._ItemData._Tid)
        GUI.SetText(lab_level, string.format(StringTable.Get(10657), item_temp.InitLevel))
        lab_level:SetActive(item_temp.InitLevel > 0)
        itemNameObj0.text = colorname
        -- 显示起拍价,一口价的默认值
        GUI.SetText(self._InputObj2, self._Value2 ~= 0 and GUITools.FormatNumber(self._Value2, false) or StringTable.Get(20405))
        GUI.SetText(self._InputObj1,GUITools.FormatNumber(self._Value1, false))
        GUI.SetText(self._LabItemCount, GUITools.FormatNumber(self._ItemData._NormalCount, false))
        local templateData = CElementData.GetMarketTemplate(CPanelAuction.Instance()._CurrentRightToggle)
        GUITools.SetTokenMoneyIcon(self:GetUIObject("Img_Money1"), templateData.MoneyType)
        if self._IsOnClickZero then
            GameUtil.SetButtonInteractable(self._Btn_Minus, false)
        else
            GameUtil.SetButtonInteractable(self._Btn_Minus, true)
        end
    end       
    if have_putOn_money then
        local count = game._HostPlayer:GetMoneyCountByType(1)
        if count < tonumber(freePrice) then
            self._IsLackFree = true
            GUI.SetText(self._FreePriceObj, string.format(StringTable.Get(20414),tonumber(freePrice)))
        else 
            self._IsLackFree = false
            GUI.SetText(self._FreePriceObj, freePrice)
        end  
        self._Frame_Charge:SetActive(true)
    else
        self._IsLackFree = false
        self._Frame_Charge:SetActive(false)
    end
end
def.method("number","string",'userdata',"number","number","=>","number").PlusOrMinusButton = function (self,value1,buttonName,labObj,maxValue,minValue)
    local value = 0
    local id = string.sub(buttonName,5,-2)
    local index = string.sub(buttonName,-1) + 0
    --交易行加减按钮每次加1或是减一
    if self._IsExchange then
        if id == "Down" then
            if index == 1 then
                value = value1 - 1
                if value < 1 then 
                    value = 1
                end
            elseif index == 2 then
                value = math.ceil(value1 - minValue*0.1)
                if value <= minValue then
                    value = minValue
                    game._GUIMan:ShowTipText(StringTable.Get(20411), true)
                end
            end
        elseif id == "Up" then
            if index == 1 then
                value = value1 + 1
                if value > maxValue then
                    value = maxValue
                    game._GUIMan:ShowTipText(StringTable.Get(20418), true)
                end
            elseif index == 2 then
                value = math.floor(value1 + minValue*0.1)
                if value >= maxValue then 
                    value = maxValue
                    game._GUIMan:ShowTipText(StringTable.Get(20407), true)
                end
            end
        end    
    --奇珍阁是按钮加减原价的10%
    else 
        if self._IsOnClickZero and index == 2 then
            value  = math.min( math.ceil(1.1 * self._Value1), self._ItemData.MaxPrice)
            if value > maxValue then
                value = maxValue
            end
            self._IsOnClickZero = false  
            GameUtil.SetButtonInteractable(self._Btn_Minus, true)
        else    
            if id == "Down" then
                if index == 1 then
                    value = math.ceil(value1 - minValue*0.1)
                    if value <= minValue then
                        value = math.ceil(value1 - minValue*0.1)
                        if value < minValue then
                            value = minValue 
                            game._GUIMan:ShowTipText(StringTable.Get(20412), true)
                        end
                        self._MinValue2 = math.max( math.min(math.ceil(value * 1.1), self._MaxValue2), self._ItemData.MinPrice)
                    end
                else
                    value = math.ceil(self._Value2 * 0.9)
                    if value <= minValue then
                        GUI.SetText(labObj,StringTable.Get(20405))
                        self._IsOnClickZero = true
                        self._Value2 = 0
                        GameUtil.SetButtonInteractable(self._Btn_Minus, false)
                        self._MaxValue1 =  math.max( math.max( math.ceil(value * 0.9), self._MinValue1), self._ItemData.MinPrice)
                        return 0
                    end
                end
            elseif id == "Up" then
                if index == 1 then 
                    value = math.ceil(value1 + minValue*0.1)
                    if value >= math.floor(self._Value2/1.1) and self._Value2 ~= 0 then
                        value = math.floor(self._Value2/1.1)
                        game._GUIMan:ShowTipText(StringTable.Get(20408), true)
                    else
                        if value > math.floor(self._ItemData.MaxPrice/1.1) then
                            value = math.floor(self._ItemData.MaxPrice/1.1)
                            game._GUIMan:ShowTipText(StringTable.Get(20409), true)
                        end
                    end
                    self._MinValue2 = math.min( math.ceil(value * 1.1), self._MaxValue2)
                else 
                    value = math.min( math.ceil(self._Value2 * 1.1), self._MaxValue2)
                    if value >= self._ItemData.MaxPrice then
                        value = self._ItemData.MaxPrice
                        game._GUIMan:ShowTipText(StringTable.Get(20413), true)
                    end
                    self._MaxValue1 = value
                end
            end
        end      
    end
    GUI.SetText(labObj,GUITools.FormatNumber(value, false))
    return value
end

CPanelAuctionSell2.Commit()
return CPanelAuctionSell2