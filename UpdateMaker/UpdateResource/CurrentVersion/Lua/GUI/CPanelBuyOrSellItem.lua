--No use
--[[
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require'Data.CElementData'
local EResourceType = require "PB.data".EResourceType
local CPanelBuyOrSellItem = Lplus.Extend(CPanelBase, "CPanelBuyOrSellItem")
local def = CPanelBuyOrSellItem.define

def.field('userdata')._Lab_ShowType = nil
def.field("userdata")._Lab_ItemDescribe = nil
def.field('table')._ItemData = nil 
def.field('number')._UnitPrice = 0
def.field('userdata')._Lab_TotalPrice = nil 
def.field('userdata')._Lab_Number = nil 
def.field('userdata')._Lab_NumberTips = nil
def.field('userdata')._Lab_TotalPriceTips = nil 
def.field('userdata')._Lab_SellOrBuy = nil 
def.field('number')._MaxNumber = 0 
def.field("userdata")._UIItem = nil 
def.field("number")._CurNumber = 1
def.field("userdata")._InputNumber = nil 
def.field("number")._TradingType = 0
def.field("userdata")._Lab_ButtonName = nil 
def.field("function")._CallBack = nil
def.field("number")._TotalPrice = 0
def.field("boolean")._IsUseKeyboard = false
def.field("userdata")._Img_Money = nil
def.field("number")._MoneyType = 0

def.field("userdata")._Btn_Down = nil 
def.field("userdata")._Btn_Up = nil

local instance = nil 
def.static('=>', CPanelBuyOrSellItem).Instance = function ()
	if not instance then
        instance = CPanelBuyOrSellItem()
        instance._PrefabPath = PATH.UI_SellOrBuyItem
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        --instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end
def.override().OnCreate = function(self)
	self._Lab_ShowType = self:GetUIObject("Lab_ItemType")
	self._Lab_ItemDescribe = self:GetUIObject("Lab_ItemDescribe")
	self._Lab_TotalPriceTips = self:GetUIObject("Lab_TotalPrice")
	self._Lab_NumberTips = self:GetUIObject("Lab_NumberTips")
	self._Lab_Number = self:GetUIObject("Lab_InputNumber")
	self._Lab_TotalPrice = self:GetUIObject("Lab_TotalPrice")
	self._UIItem = self:GetUIObject("Item")
	self._Img_Money = self:GetUIObject("Img_Money")
	self._Lab_ButtonName = self:GetUIObject("Lab_SellOrBuy")
	self._Btn_Up = self:GetUIObject("Btn_Up")
	self._Btn_Down = self:GetUIObject("Btn_Down")
end
def.override("dynamic").OnData = function (self,data)
	self._ItemData = CElementData.GetItemTemplate(data._ID)
	self._MaxNumber = data._MaxNumber
	self._UnitPrice = data._UnitPrice
	self._CallBack = data._CallBack
	self._CurNumber = 1
	self._TradingType = data._TradingType
	GUI.SetText(self._Lab_NumberTips,StringTable.Get(21300))
	GUI.SetText(self._Lab_TotalPriceTips,StringTable.Get(21301))
	self._TradingType = data._TradingType
	self._MoneyType = data._MoneyType
	self._IsUseKeyboard = false
	
	self:InitPanel()
	-- body
end
def.method().InitPanel = function (self)
	if self._MaxNumber == 0 then 
		self._MaxNumber = 999
		self._UIItem:FindChild("Lab_Number"):SetActive(false)
		GUITools.SetItem(self._UIItem,self._ItemData,nil)
	else
		self._UIItem:FindChild("Lab_Number"):SetActive(true)
		GUITools.SetItem(self._UIItem,self._ItemData,self._MaxNumber)
	end
	GUI.SetText(self._Lab_ShowType,self._ItemData.DescriptionType)
	GUI.SetText(self._Lab_ItemDescribe,self._ItemData.TextDescription)
	GUI.SetText(self._Lab_Number,tostring(self._CurNumber))
	if self._UnitPrice == 0 then 
		self._UnitPrice = self._ItemData.RecyclePriceInGold 
	end

	GUITools.SetTokenMoneyIcon(self._Img_Money, self._MoneyType)
	self._TotalPrice = self._UnitPrice * self._CurNumber
	GUI.SetText(self._Lab_TotalPrice,tostring(self._TotalPrice))
	GameUtil.SetButtonInteractable(self._Btn_Up,true) 
	GUITools.SetGroupImg(self._Btn_Up,0)
	GameUtil.SetButtonInteractable(self._Btn_Down, false)
	GUITools.SetGroupImg(self._Btn_Down,1)
	if self._TradingType == TradingType.BUY then 
		GUI.SetText(self._Lab_ButtonName,StringTable.Get(21302))
	elseif self._TradingType == TradingType.SELL then 
		GUI.SetText(self._Lab_ButtonName,StringTable.Get(21303))
	end 
	
	
	-- body
end
def.override('string').OnClick = function (self,id)
	 if id == "Btn_Up" then  
        if self._CurNumber < self._MaxNumber then
            self._CurNumber = self._CurNumber + 1
            self:UpdataTotalPriceAndNumber()   
        else
        	if self._TradingType == TradingType.SELL then 
        		game._GUIMan:ShowTipText(StringTable.Get(21306), true)
        	else
            	game._GUIMan:ShowTipText(StringTable.Get(20426), true)
            end
        end
    elseif id == "Btn_Down"then         
        if self._CurNumber > 1 then
            self._CurNumber = self._CurNumber -1 
            self:UpdataTotalPriceAndNumber()     
        end 
    elseif id == "Input_Number" then 
    	local function callback()
    		self._CurNumber = tonumber(self._Lab_Number:GetComponent(ClassType.Text).text)
    		self:UpdataTotalPriceAndNumber()
    	end
    	game._GUIMan:OpenNumberKeyboard(self._Lab_Number,nil,1,self._MaxNumber,callback, nil)
    elseif id == "Btn_Ok" then  
    	local func_result = self._CallBack
	    if func_result ~= nil then
            func_result(self._CurNumber)
	    end
	    game._GUIMan:CloseByScript(self)
    end      
end
def.method().UpdataTotalPriceAndNumber = function (self)
	if self._CurNumber == self._MaxNumber then 
		GameUtil.SetButtonInteractable(self._Btn_Up, false)
		GUITools.SetGroupImg(self._Btn_Up,1)
		GameUtil.SetButtonInteractable(self._Btn_Down,true)
		GUITools.SetGroupImg(self._Btn_Down,0)
	elseif self._CurNumber == 1 then
		GameUtil.SetButtonInteractable(self._Btn_Up,true) 
		GUITools.SetGroupImg(self._Btn_Up,0)
		GameUtil.SetButtonInteractable(self._Btn_Down, false)
		GUITools.SetGroupImg(self._Btn_Down,1)
	else
		GameUtil.SetButtonInteractable(self._Btn_Up,true)
		GameUtil.SetButtonInteractable(self._Btn_Down,true)
		GUITools.SetGroupImg(self._Btn_Down,0)
		GUITools.SetGroupImg(self._Btn_Up,0)
	end

    self._TotalPrice = self._UnitPrice * self._CurNumber
    GUI.SetText(self._Lab_TotalPrice,tostring(self._TotalPrice))
    GUI.SetText(self._Lab_Number,tostring(self._CurNumber))
end

CPanelBuyOrSellItem.Commit()
return CPanelBuyOrSellItem
]]
