local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CMallUtility = require "Mall.CMallUtility"
local CCommonBtn = require "GUI.CCommonBtn"
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
def.field(CCommonBtn)._Btn_OKWithGold = nil

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
    self._PanelObject._Btn_OKWithGold = self:GetUIObject("Btn_OkWithGold")
    self._PanelObject._Img_CostMoney = self:GetUIObject("Img_SellGold")
    self._PanelObject._Lab_CostNumber = self:GetUIObject("Lab_CostNumber")
    self._PanelObject._Sld_ItemCount = self:GetUIObject("Sld_Count")
    self._PanelObject._ItemCost_Get = self:GetUIObject("ItemCost_Get")
    self._PanelObject._ItemIcon_Get = self:GetUIObject("ItemIcon_Get")
    self._PanelObject._Frame_Items = self:GetUIObject("Frame_Items")
    self._PanelObject._Frame_CountOperate = self:GetUIObject("Frame_CountOperate")
    self._PanelObject._Frame_CountOperate:SetActive(true)
    self._PanelObject._Btn_OKWithGold:SetActive(false)
    self._PanelObject._Frame_Items:SetActive(false)

    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(11106),
    }
    self._Btn_OKWithGold = CCommonBtn.new(self._PanelObject._Btn_OKWithGold ,setting)
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
        GUITools.SetBtnGray(self._PanelObject._Btn_Plus, true, true)
        GUITools.SetBtnGray(self._PanelObject._Btn_Max, true, true)
        GUITools.SetGroupImg(self._PanelObject._Btn_Max:FindChild("Img_BG"), 1)
        GUITools.SetGroupImg(self._PanelObject._Btn_Plus:FindChild("Img_BG"), 1)
    else
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Plus, true)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Max, true)
        GUITools.SetBtnGray(self._PanelObject._Btn_Plus, false, true)
        GUITools.SetBtnGray(self._PanelObject._Btn_Max, false, true)
        GUITools.SetGroupImg(self._PanelObject._Btn_Max:FindChild("Img_BG"), 0)
        GUITools.SetGroupImg(self._PanelObject._Btn_Plus:FindChild("Img_BG"), 0)
    end
    if self._ItemCount <= self._CommonBuyInfo._MinValue then
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Minus, false)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Min, false)
        GUITools.SetBtnGray(self._PanelObject._Btn_Minus, true, true)
        GUITools.SetBtnGray(self._PanelObject._Btn_Min, true, true)
        GUITools.SetGroupImg(self._PanelObject._Btn_Min:FindChild("Img_BG"), 1)
        GUITools.SetGroupImg(self._PanelObject._Btn_Minus:FindChild("Img_BG"), 1)
    else
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Minus, true)
        GameUtil.SetButtonInteractable(self._PanelObject._Btn_Min, true)
        GUITools.SetBtnGray(self._PanelObject._Btn_Minus, false, true)
        GUITools.SetBtnGray(self._PanelObject._Btn_Min, false, true)
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
    GUI.SetText(self._PanelObject._Lab_CostNumber, GUITools.FormatNumber(self._CostCount, false))

    if self._IsCost then
        local moneyHave = game._HostPlayer:GetMoneyCountByType(self._CommonBuyInfo._CostMoneyID)
        GUI.SetText(self._PanelObject._Lab_CostNumber, RichTextTools.GetNeedColorText(GUITools.FormatNumber(self._CostCount, false), moneyHave >= self._CostCount))
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
        if self._CommonBuyInfo._ClickCallBack ~= nil then
            self._CommonBuyInfo._ClickCallBack(false)
        end
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Ok" or id == "Btn_OkWithGold" then
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
    elseif id == "ItemIcon_Cost" then
        if self._CommonBuyInfo._PurposeType == TradingType.COMPOSE then
            CItemTipMan.ShowItemTips(self._CommonBuyInfo._CustomData._Tid, TipsPopFrom.OTHER_PANEL)
        end
    elseif id == "ItemIcon_Get" then
        if self._CommonBuyInfo._PurposeType == TradingType.COMPOSE then
            local template_processItem = CElementData.GetTemplate("ItemMachining", self._CommonBuyInfo._CustomData._Template.ComposeId)
            if template_processItem ~= nil then
                local ComposeTid = template_processItem.DestItemData.DestItems[1].ItemId
                CItemTipMan.ShowItemTips(ComposeTid, TipsPopFrom.OTHER_PANEL)
            end
        elseif self._CommonBuyInfo._PurposeType == TradingType.DECOMPOSE or self._CommonBuyInfo._PurposeType == TradingType.USE then
            CItemTipMan.ShowItemTips(self._CommonBuyInfo._CustomData, TipsPopFrom.OTHER_PANEL)
        end
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
    self._PanelObject._Frame_Items:SetActive(true)
    local uiTemplate = self._PanelObject._Frame_Items:GetComponent(ClassType.UITemplate)
    local item_cost = uiTemplate:GetControl(0)
    local img_arr = uiTemplate:GetControl(1)
    local item_get = uiTemplate:GetControl(2)
    local money_get = uiTemplate:GetControl(3)
    item_cost:SetActive(true)
    img_arr:SetActive(true)
    item_get:SetActive(false)
    money_get:SetActive(true)

    local lab_itemname_cost = item_cost:FindChild("Lab_ItemName")
    local srcItemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData._Tid, 1, false)
    IconTools.InitItemIconNew(item_cost, self._CommonBuyInfo._CustomData._Tid, nil, EItemLimitCheck.AllCheck)
    GUI.SetText(lab_itemname_cost, srcItemName) 

    local lab_count_cost = item_cost:FindChild("Frame_ItemIcon/Lab_Number")
    local item_have_count = game._HostPlayer._Package._NormalPack:GetItemCount(self._CommonBuyInfo._CustomData._Tid)
    GUI.SetText(lab_count_cost, string.format(StringTable.Get(20061), self._ItemCount, item_have_count))
end

local Item_Count_Change_Compose = function(self, itemCount)
    self._IsCost = true
    if self._CommonBuyInfo._CustomData:CanCompose() then
        self._PanelObject._Frame_Items:SetActive(true)
        self._PanelObject._Btn_OK:SetActive(false)
        self._PanelObject._Lab_Des:SetActive(false)
        self._PanelObject._Btn_OKWithGold:SetActive(true)
        local uiTemplate = self._PanelObject._Frame_Items:GetComponent(ClassType.UITemplate)
        local item_cost = uiTemplate:GetControl(0)
        local img_arr = uiTemplate:GetControl(1)
        local item_get = uiTemplate:GetControl(2)
        local money_get = uiTemplate:GetControl(3)
        item_get:SetActive(true)
        img_arr:SetActive(true)
        money_get:SetActive(false)
        
        local template_processItem = CElementData.GetTemplate("ItemMachining", self._CommonBuyInfo._CustomData._Template.ComposeId)
        local ComposeNum = template_processItem.DestCount
        local ComposeTid = template_processItem.DestItemData.DestItems[1].ItemId
        local CostOneNeedNum = template_processItem.SrcItemData.SrcItems[1].ItemCount   --合成一个需要消耗的物品数量
        local CostOneNeedMoney = template_processItem.MoneyNum    --合成一个需要消耗的钱数   
        local BagItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(self._CommonBuyInfo._CustomData._Tid)
        local ComposeName = RichTextTools.GetItemNameRichText(ComposeTid, 1, false)
        local srcItemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData._Tid, 1, false)
        local CostItemNum = 0
        local CostAllMoney = 0
        local lab_itemname_cost = item_cost:FindChild("Lab_ItemName")
        local lab_itemname_get = item_get:FindChild("Lab_ItemName")
        local lab_count_cost = item_cost:FindChild("Frame_ItemIcon/Lab_Number")
        GUI.SetText(lab_itemname_cost, srcItemName)
        GUI.SetText(lab_itemname_get, ComposeName)
        
        local setting = {
            [EItemIconTag.Number] = self._ItemCount,
        }
        IconTools.InitItemIconNew(item_get, ComposeTid, setting, EItemLimitCheck.AllCheck)
        IconTools.InitItemIconNew(item_cost, self._CommonBuyInfo._CustomData._Tid, nil, EItemLimitCheck.AllCheck)
        if self._ItemCount == 0 then
            CostItemNum = CostOneNeedNum
            ComposeNum = 1
            CostAllMoney = CostOneNeedMoney
        else
            CostItemNum = CostOneNeedNum * self._ItemCount     --一共需要消耗的物品数量
            ComposeNum = template_processItem.DestCount * self._ItemCount
            CostAllMoney = CostOneNeedMoney * self._ItemCount
        end
        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = template_processItem.MoneyId,
            [EnumDef.CommonBtnParam.MoneyCost] = CostAllMoney,
        }
        self._Btn_OKWithGold:ResetSetting(setting)
        local CostItemNumStr = tostring(CostItemNum)
        if CostItemNum <= BagItemCount then      --一共消耗的物品数量大于玩家背包中的物品数量显示红色,并且置灰确定按钮，否则显示白色
            CostItemNumStr = "<color=#FFFFFF>"..CostItemNumStr.."</color>"
            self._Btn_OKWithGold:MakeGray(false)
            self._Btn_OKWithGold:SetInteractable(true)
        else
            CostItemNumStr = "<color=#FF0000>"..CostItemNumStr.."</color>"
            self._Btn_OKWithGold:MakeGray(true)
            self._Btn_OKWithGold:SetInteractable(false)
        end
        local count_str = ""
        if BagItemCount >= CostItemNum then
            count_str = string.format(StringTable.Get(20082), BagItemCount, CostItemNum)
        else
            count_str = string.format(StringTable.Get(20081), BagItemCount, CostItemNum)
        end
        GUI.SetText(lab_count_cost, count_str)
        local itemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData._Tid, 1, false)
        self._CommonBuyInfo._Des = string.format(StringTable.Get(19500),CostItemNumStr,itemName,ComposeNum,ComposeName)
    end
end

local Item_Count_Change_Decompose = function(self, itemCount)
    self._IsCost = false
    self._PanelObject._ItemCost_Get:SetActive(true)
    self._PanelObject._Frame_Items:SetActive(true)
    local uiTemplate = self._PanelObject._Frame_Items:GetComponent(ClassType.UITemplate)
    local item_cost = uiTemplate:GetControl(0)
    local img_arr = uiTemplate:GetControl(1)
    local item_get = uiTemplate:GetControl(2)
    local money_get = uiTemplate:GetControl(3)
    item_get:SetActive(false)
    money_get:SetActive(false)

    item_cost:SetActive(false)
    img_arr:SetActive(false)
    item_get:SetActive(true)
    local lab_item_name = item_get:FindChild("Lab_ItemName")
    local itemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData, 1, false)
    GUI.SetText(lab_item_name, itemName)
    local setting = {
        [EItemIconTag.Number] = self._ItemCount,
    }
    IconTools.InitItemIconNew(item_get, self._CommonBuyInfo._CustomData, setting, EItemLimitCheck.AllCheck)
end

local Item_Count_Change_Use = function(self, itemCount)
    self._IsCost = false
    self._PanelObject._ItemCost_Get:SetActive(false)
    self._PanelObject._Frame_Items:SetActive(true)
    local uiTemplate = self._PanelObject._Frame_Items:GetComponent(ClassType.UITemplate)
    local item_cost = uiTemplate:GetControl(0)
    local img_arr = uiTemplate:GetControl(1)
    local item_get = uiTemplate:GetControl(2)
    item_cost:SetActive(false)
    img_arr:SetActive(true)
    item_get:SetActive(true)
    local lab_item_name = item_get:FindChild("Lab_ItemName")
    local itemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData, 1, false)
    GUI.SetText(lab_item_name, itemName)
    local setting = {
        [EItemIconTag.Number] = self._ItemCount,
    }
    IconTools.InitItemIconNew(item_get, self._CommonBuyInfo._CustomData, setting, EItemLimitCheck.AllCheck)
end

local Item_Count_Change_BagBuyCell = function(self, itemCount)
    self._IsCost = true
    self._CostCount = CMallUtility.GetBagBuyCellTotalPrice(itemCount)
end

local Item_Count_Change_PetBagBuyCell = function(self, itemCount)
    self._IsCost = true
    self._PanelObject._ItemCost_Get:SetActive(true)
    self._PanelObject._Frame_Items:SetActive(true)
    local uiTemplate = self._PanelObject._Frame_Items:GetComponent(ClassType.UITemplate)
    local item_cost = uiTemplate:GetControl(0)
    local img_arr = uiTemplate:GetControl(1)
    local item_get = uiTemplate:GetControl(2)
    local money_get = uiTemplate:GetControl(3)
    item_get:SetActive(false)
    money_get:SetActive(true)

    item_cost:SetActive(false)
    img_arr:SetActive(false)
    item_get:SetActive(false)
    --[[local lab_item_name = item_get:FindChild("Lab_ItemName")
    local itemName = RichTextTools.GetItemNameRichText(self._CommonBuyInfo._CustomData, 1, false)
    GUI.SetText(lab_item_name, itemName)
    local setting = {
        [EItemIconTag.Number] = self._ItemCount,
    }
    IconTools.InitItemIconNew(item_get, self._CommonBuyInfo._CustomData, setting, EItemLimitCheck.AllCheck)]]
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
    elseif self._CommonBuyInfo._PurposeType == TradingType.PetBagBuyCell then
        self._ItemCountChangeFunc = Item_Count_Change_PetBagBuyCell
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
    if self._Btn_OKWithGold ~= nil then
        self._Btn_OKWithGold:Destroy()
        self._Btn_OKWithGold = nil
    end
    self._CommonBuyInfo = nil
    self._PanelObject = nil
end

CPanelCommonOperate.Commit()
return CPanelCommonOperate

