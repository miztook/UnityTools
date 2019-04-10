local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CMallUtility = require "Mall.CMallUtility"
local CPanelCommonOperate = Lplus.Extend(CPanelBase, "CPanelCommonOperate")
local def = CPanelCommonOperate.define
local instance = nil

def.field("number")._ItemCount = 0                  -- 当前输入的数量
def.field("number")._CostCount = 0                  -- 当前花费或者获得的数量
def.field("boolean")._IsSliderChage = false         -- 点击Slider让Slider数值变化（防止多次设置slider）
def.field("boolean")._SliderChangeByScript = false  -- 引起slider变化的是否是代码
def.field("boolean")._IsCost = false                -- 是花钱还是赚钱
def.field("table")._CommonBuyInfo = BlankTable      -- 传入的参数
def.field("table")._PanelObject = nil
def.field("function")._ItemCountChangeFunc = nil    -- 数量变化的回调函数

def.static('=>', CPanelCommonOperate).Instance = function ()
	if not instance then
        instance = CPanelCommonOperate()
        instance._PrefabPath = PATH.UI_CommonOperate
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._PanelObject = {}
    self._PanelObject._Lab_Title = self:GetUIObject("Lab_Title")
    self._PanelObject._Lab_Des = self:GetUIObject("Lab_Des")
    self._PanelObject._Lab_ItemCount = self:GetUIObject("Lab_Count")
    self._PanelObject._Btn_Plus = self:GetUIObject("Btn_Plus")
    self._PanelObject._Btn_Minus = self:GetUIObject("Btn_Minus")
    self._PanelObject._Btn_Max = self:GetUIObject("Btn_Max")
    self._PanelObject._Btn_Min = self:GetUIObject("Btn_Min")
    self._PanelObject._Btn_OK = self:GetUIObject("Btn_Ok")
    self._PanelObject._Img_CostMoney = self:GetUIObject("Img_SellGold")
    self._PanelObject._Lab_CostNumber = self:GetUIObject("Lab_CostNumber")
    self._PanelObject._Lab_CostOrGetTip = self:GetUIObject("Lab_CostOrGetTip")
    self._PanelObject._Sld_ItemCount = self:GetUIObject("Sld_Count")
    self._PanelObject._FrameCost = self:GetUIObject("Frame_Cost")

    GUITools.RegisterSliderEventHandler(self._Panel, self._PanelObject._Sld_ItemCount)
end

def.override("dynamic").OnData = function (self,data)
	self._CommonBuyInfo = data
    self._ItemCount = self._CommonBuyInfo._MinValue
    self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
    if self._CommonBuyInfo._MaxValue == -1 then
        self._CommonBuyInfo._MaxValue = 99
    end
    self:AssignItemCountChangeFunc()
    if self._ItemCountChangeFunc ~= nil then
        self._ItemCountChangeFunc(self, self._ItemCount) 
    end
	self:UpdatePanel()
end

def.method().UpdatePanel = function (self)
    if self._CommonBuyInfo == nil then return end
    GUI.SetText(self._PanelObject._Lab_Title, self._CommonBuyInfo._Title)
    GUI.SetText(self._PanelObject._Lab_Des, self._CommonBuyInfo._Des)
    GUI.SetText(self._PanelObject._Lab_ItemCount, self._ItemCount.."")

    if self._ItemCount >= self._CommonBuyInfo._MaxValue then
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Plus, false)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Max, false)
        GUITools.SetGroupImg(self._PanelObject._Btn_Max:FindChild("Img_BG"), 1)
        GUITools.SetGroupImg(self._PanelObject._Btn_Plus:FindChild("Img_BG"), 1)
    else
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Plus, true)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Max, true)
        GUITools.SetGroupImg(self._PanelObject._Btn_Max:FindChild("Img_BG"), 0)
        GUITools.SetGroupImg(self._PanelObject._Btn_Plus:FindChild("Img_BG"), 0)
    end
    if self._ItemCount <= self._CommonBuyInfo._MinValue then
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Minus, false)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Min, false)
        GUITools.SetGroupImg(self._PanelObject._Btn_Min:FindChild("Img_BG"), 1)
        GUITools.SetGroupImg(self._PanelObject._Btn_Minus:FindChild("Img_BG"), 1)
    else
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Minus, true)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Min, true)
        GUITools.SetGroupImg(self._PanelObject._Btn_Min:FindChild("Img_BG"), 0)
        GUITools.SetGroupImg(self._PanelObject._Btn_Minus:FindChild("Img_BG"), 0)
    end
    if not self._IsSliderChage then
        self._SliderChangeByScript = true
        self._PanelObject._Sld_ItemCount:GetComponent(ClassType.Slider).value = (self._ItemCount-self._CommonBuyInfo._MinValue)/(self._CommonBuyInfo._MaxValue-self._CommonBuyInfo._MinValue)
    end

    if self._CommonBuyInfo._CostMoneyID ~= -1 then
        GUITools.SetTokenMoneyIcon(self._PanelObject._Img_CostMoney, self._CommonBuyInfo._CostMoneyID)
    end
    GUI.SetText(self._PanelObject._Lab_CostNumber, tostring(self._CostCount))

    if self._IsCost then
        GUI.SetText(self._PanelObject._Lab_CostOrGetTip, StringTable.Get(24005))
        local moneyHave = game._HostPlayer:GetMoneyCountByType(self._CommonBuyInfo._CostMoneyID)
        GUI.SetText(self._PanelObject._Lab_CostNumber, RichTextTools.GetNeedColorText(tostring(self._CostCount), moneyHave >= self._CostCount))
    else
        GUI.SetText(self._PanelObject._Lab_CostOrGetTip, StringTable.Get(24006))
    end
    self._IsSliderChage = false
    self._SliderChangeByScript = false
end

def.override('string').OnClick = function (self,id)
	if id == "Btn_Plus" then
        self._ItemCount = math.min(self._ItemCount + 1, self._CommonBuyInfo._MaxValue)
        self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
        if self._ItemCountChangeFunc ~= nil then
           self._ItemCountChangeFunc(self, self._ItemCount) 
        end
        self:UpdatePanel()
    elseif id == "Btn_Minus"then         
        self._ItemCount = math.max(self._ItemCount - 1, 0)
        self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
        if self._ItemCountChangeFunc ~= nil then
           self._ItemCountChangeFunc(self, self._ItemCount) 
        end
        self:UpdatePanel()
    elseif id == "Btn_Cancel" or id == "Btn_Close" then 
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Ok" then
        if self._IsCost then
            local moneyHave = game._HostPlayer:GetMoneyCountByType(self._CommonBuyInfo._CostMoneyID)
            if self._CostCount > moneyHave then
                local money = CElementData.GetTemplate("Money", self._CommonBuyInfo._CostMoneyID)
			    game._GUIMan:ShowTipText(string.format(StringTable.Get(893), money.TextDisplayName), true)
                if self._CommonBuyInfo._FailCallBack ~= nil then
                    self._CommonBuyInfo._FailCallBack(self._ItemCount)
                    game._GUIMan:CloseByScript(self)
                end
            else
    	        if self._CommonBuyInfo._OkCallBack ~= nil then
                    self._CommonBuyInfo._OkCallBack(self._ItemCount)
                end
                game._GUIMan:CloseByScript(self)
            end
        else
            if self._CommonBuyInfo._OkCallBack ~= nil then
                self._CommonBuyInfo._OkCallBack(self._ItemCount)
            end
            game._GUIMan:CloseByScript(self)
        end
    elseif id == "Btn_Max" then
        self._ItemCount = self._CommonBuyInfo._MaxValue
        self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
        if self._ItemCountChangeFunc ~= nil then
           self._ItemCountChangeFunc(self, self._ItemCount) 
        end
        self:UpdatePanel()
    elseif id == "Btn_Min" then
        self._ItemCount = self._CommonBuyInfo._MinValue
        self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
        if self._ItemCountChangeFunc ~= nil then
           self._ItemCountChangeFunc(self, self._ItemCount) 
        end
        self:UpdatePanel()
    elseif id == "Btn_Input" then
        local function callback(count)
    		self._ItemCount = count
            self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
            if self._ItemCount > self._CommonBuyInfo._MaxValue then self._ItemCount = self._CommonBuyInfo._MaxValue end
            if self._ItemCount < self._CommonBuyInfo._MinValue then self._ItemCount = self._CommonBuyInfo._MinValue end
            GUI.SetText(self._PanelObject._Lab_ItemCount, self._ItemCount.."")
            if self._ItemCountChangeFunc ~= nil then
               self._ItemCountChangeFunc(self, self._ItemCount) 
            end
    		self:UpdatePanel()
    	end
    	game._GUIMan:OpenNumberKeyboard(self._PanelObject._Lab_ItemCount,nil,self._CommonBuyInfo._MinValue,self._CommonBuyInfo._MaxValue,callback, callback)
    end
end

def.method("string", "number").OnSliderChanged = function(self, id, value)
    if self._SliderChangeByScript then return end
    if id == "Sld_Count" then
        self._ItemCount = math.max(math.floor((self._CommonBuyInfo._MaxValue - self._CommonBuyInfo._MinValue) * value + self._CommonBuyInfo._MinValue + 0.5), self._CommonBuyInfo._MinValue)
        self._CostCount = self._ItemCount * self._CommonBuyInfo._Price
        self._IsSliderChage = true
        if self._ItemCountChangeFunc ~= nil then
            self._ItemCountChangeFunc(self, self._ItemCount) 
        end
        self._IsSliderChage = false
        self:UpdatePanel()
    end
end

local Item_Count_Change_Buy = function(self, itemCount)
    self._IsCost = true
end

local Item_Count_Change_Sell = function(self, itemCount)
    self._IsCost = false
end

local Item_Count_Change_Compose = function(self, itemCount)
    self._IsCost = true
    if self._CommonBuyInfo._CustomData:CanCompose() then
        local template_processItem = CElementData.GetTemplate("ItemMachining", self._CommonBuyInfo._CustomData._Template.ComposeId)
        local ComposeNum = template_processItem.DestCount
        local ComposeTid = template_processItem.DestItemData.DestItems[1].ItemId
        local CostOneNeedNum = template_processItem.SrcItemData.SrcItems[1].ItemCount   --合成一个需要消耗的物品数量
        local CostOneNeedMoney = template_processItem.MoneyNum    --合成一个需要消耗的钱数   
        local BagItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._CommonBuyInfo._CustomData._Tid)
        local ComposeName = RichTextTools.GetItemNameRichText(ComposeTid, 1, false)
        local CostItemNum = 0
        if self._ItemCount == 0 then
            CostItemNum = CostOneNeedNum
            ComposeNum = 1
        else
            CostItemNum = CostOneNeedNum * self._ItemCount     --一共需要消耗的物品数量
            ComposeNum = template_processItem.DestCount * self._ItemCount
        end  
        local CostItemNumStr = tostring(CostItemNum)
        if CostItemNum > BagItemCount then      --一共消耗的物品数量大于玩家背包中的物品数量显示红色,并且置灰确定按钮，否则显示白色
            CostItemNumStr = "<color=#FF0000>"..CostItemNumStr.."</color>"
            GameUtil.SetButtonInteractable(self._PanelObject._Btn_OK, false)
            GameUtil.MakeImageGray(self._PanelObject._Btn_OK:FindChild("Img_BG"), true)
        else
            CostItemNumStr = "<color=#FFFFFF>"..CostItemNumStr.."</color>"
            GameUtil.SetButtonInteractable(self._PanelObject._Btn_OK, true)
            GameUtil.MakeImageGray(self._PanelObject._Btn_OK:FindChild("Img_BG"), false)
        end
        local itemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData._Tid, 1, false)
        self._CommonBuyInfo._Des = string.format(StringTable.Get(19500),CostItemNumStr,itemName,ComposeNum,ComposeName)
    end
end

local Item_Count_Change_Decompose = function(self, itemCount)
    self._IsCost = false
end

local Item_Count_Change_Use = function(self, itemCount)
    self._IsCost = false
    self._PanelObject._FrameCost:SetActive(false)
end

local Item_Count_Change_BagBuyCell = function(self, itemCount)
    self._IsCost = true
    self._CostCount = CMallUtility.GetBagBuyCellTotalPrice(itemCount)
end

def.method().AssignItemCountChangeFunc = function(self)
    if self._CommonBuyInfo._PurposeType == TradingType.BUY then
        self._ItemCountChangeFunc = Item_Count_Change_Buy
    elseif self._CommonBuyInfo._PurposeType == TradingType.SELL then
        self._ItemCountChangeFunc = Item_Count_Change_Sell
    elseif self._CommonBuyInfo._PurposeType == TradingType.COMPOSE then
        self._ItemCountChangeFunc = Item_Count_Change_Compose
    elseif self._CommonBuyInfo._PurposeType == TradingType.DECOMPOSE then
        self._ItemCountChangeFunc = Item_Count_Change_Decompose
    elseif self._CommonBuyInfo._PurposeType == TradingType.USE then
        self._ItemCount = self._CommonBuyInfo._MaxValue
        self._ItemCountChangeFunc = Item_Count_Change_Use
    elseif self._CommonBuyInfo._PurposeType == TradingType.BagBuyCell then
        self._ItemCountChangeFunc = Item_Count_Change_BagBuyCell
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._IsSliderChage = false
    self._SliderChangeByScript = false
    self._ItemCount = 0
    self._CostCount = 0
    self._ItemCountChangeFunc = nil
end

def.override().OnDestroy = function(self)
    self._CommonBuyInfo = nil
    self._PanelObject = nil
end

CPanelCommonOperate.Commit()
return CPanelCommonOperate

