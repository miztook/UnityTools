--No use
--[[
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local ItemQuality= require"PB.Template".Item.ItemQuality
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"


local CPanelBatchOperation = Lplus.Extend(CPanelBase, 'CPanelBatchOperation')
local def = CPanelBatchOperation.define
 
def.field("table")._OperationType = BlankTable
def.field("number")._CurOperationType = 0
def.field("table")._ConfirmItemListData = BlankTable
def.field("table")._AllItemData = BlankTable
def.field("table")._RdoType = BlankTable
def.field("number")._CurRdoType = 0
def.field("boolean")._IsAllSelect = false
def.field("number")._ProfMask = 0
def.field("boolean")._IsSelectQuality = false
def.field("number")._TotalPrice = 0
-- def.field("table")._CurAllChooseItemObj = nil

def.field("userdata")._RdoSell = nil
def.field("userdata")._RdoDecompose = nil 
def.field("userdata")._LabTitle = nil 
def.field("userdata")._BtnDecompose = nil 
def.field("userdata")._BtnSell = nil 
def.field("userdata")._ImgSellIcon = nil 
def.field("userdata")._ImgDecomposeIcon = nil 
def.field("userdata")._FrameMoney = nil 
def.field("userdata")._RdoAll = nil 
def.field("userdata")._RdoEquip = nil 
def.field("userdata")._RdoCharm = nil 
def.field("userdata")._RdoElse = nil 
def.field("userdata")._ChooseList = nil 
def.field("userdata")._ConfirmList = nil
def.field("userdata")._ImgAllSelect = nil 
def.field("userdata")._ImgNotAllSelect = nil 
def.field("userdata")._ImgSelectQuality = nil 
def.field("userdata")._ImgNotSelectQuality = nil 
def.field("userdata")._LabMoney = nil 
def.field("userdata")._TipPosition = nil 

--Sell or Decompose effect, time and a screen mask, but can still close
def.field("number")._M_TimerId = 0
def.field("userdata")._EffectMask = nil

--DotweenPlayer group: 1 选中效果 

local instance = nil
def.static('=>', CPanelBatchOperation).Instance = function ()
	if not instance then
        instance = CPanelBatchOperation()
        instance._PrefabPath = PATH.UI_BatchOperation
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        instance._OperationType = 
            {
                DECOMPOSE = 1,
                SELL = 2,
            }
	end
	return instance
end
 
def.override().OnCreate = function(self)
   
    self._RdoType = 
    {
        ALL = 1,
        EQUIPMENT = 2,
        CHARM = 3,
        ELSE = 4,
    }
    self._RdoSell = self:GetUIObject("Rdo_Sell")
    self._RdoDecompose = self:GetUIObject("Rdo_Decompose")
    self._LabTitle = self:GetUIObject("Lab_Title")
    self._BtnDecompose = self:GetUIObject("Btn_Decompose")
    self._BtnSell = self:GetUIObject("Btn_Sell")
    self._FrameMoney = self:GetUIObject("Frame_Money")
    self._ChooseList = self:GetUIObject("ChooseList_Item"):GetComponent(ClassType.GNewListLoop)
    self._ConfirmList = self:GetUIObject("ConfirmList_Item"):GetComponent(ClassType.GNewListLoop)
    self._ImgAllSelect = self:GetUIObject("Img_AllSelected")
    self._ImgNotAllSelect = self:GetUIObject("Img_NotAllSelected")
    self._ImgSelectQuality = self:GetUIObject("Img_SelectedQuality")
    self._ImgNotSelectQuality = self:GetUIObject("Img_NotSelectedQuality")
    self._LabMoney = self:GetUIObject("Lab_Money")
    self._ImgSellIcon = self:GetUIObject("Img_Sell")
    self._ImgDecomposeIcon = self:GetUIObject("Img_Decompose")
    self._TipPosition = self:GetUIObject("TipPosition")
    self._EffectMask = self:GetUIObject("Img_EffectMask")
end

-- panelData 背包物品批量操作类型（）

def.override("dynamic").OnData = function (self,data)
    
    self._CurRdoType = self._RdoType.ALL
    self._CurOperationType = data
    self._IsAllSelect = false
    self._IsSelectQuality = false
    self._RdoAll = self:GetUIObject("Rdo_All"..self._CurOperationType)
    self._RdoEquip = self:GetUIObject("Rdo_Equipment"..self._CurOperationType)
    self._RdoElse = self:GetUIObject("Rdo_Else"..self._CurOperationType)
    self._AllItemData = {}
    self._ConfirmItemListData = {}
    if self._CurOperationType == self._OperationType.SELL then
        self:InitSellPanel()
    elseif self._CurOperationType == self._OperationType.DECOMPOSE then 
        self:InitDecomposePanel()
        self._RdoCharm = self:GetUIObject("Rdo_Charm"..self._CurOperationType)
    end
    self:UpdatePanel()

    self:LockUI(false)

end

local function DelayedRefreshEffect(self)
    --warn("DelayedRefreshEffect "..tostring(self._M_TimerId))

    local cf_cnt = #self._ConfirmItemListData
    for i= 1, cf_cnt, 1 do
        local g_item = self._ConfirmList:GetItem(i - 1)

        if g_item ~= nil then
            g_item = g_item:FindChild("FxCenter")
            if g_item ~=nil then
                GameUtil.PlayUISfxClipped(PATH.UI_xiaosan, g_item, self._Panel, self._ConfirmList.gameObject.parent)
            end
        end
    end

    --self:UpdatePanel()

	-- Add Timer
	if self._M_TimerId == 0 then
        self:LockUI(true)
        self._M_TimerId = _G.AddGlobalTimer(0.5, true, function()
            self:LockUI(false)
            self:UpdatePanel()
            _G.RemoveGlobalTimer(self._M_TimerId)
            self._M_TimerId = 0
		end)
	end
end

local function KillDelayRefreshEffects(self)
    if self._M_TimerId ~= 0 then
        self:LockUI(false)
        _G.RemoveGlobalTimer(self._M_TimerId)
        self._M_TimerId = 0
	end
end

def.override().OnDestroy = function (self)
    KillDelayRefreshEffects(self)

    self._RdoSell = nil
    self._RdoDecompose = nil
    self._LabTitle = nil
    self._BtnDecompose = nil
    self._BtnSell = nil
    self._ImgSellIcon = nil
    self._ImgDecomposeIcon = nil
    self._FrameMoney = nil
    self._RdoAll = nil
    self._RdoEquip = nil
    self._RdoCharm = nil
    self._RdoElse = nil
    self._ChooseList = nil
    self._ConfirmList = nil
    self._ImgAllSelect = nil
    self._ImgNotAllSelect = nil
    self._ImgSelectQuality = nil
    self._ImgNotSelectQuality = nil
    self._LabMoney = nil
    self._TipPosition = nil
    self._EffectMask = nil
end

def.method("boolean").LockUI = function(self, b_lock)
    self._EffectMask:SetActive(b_lock)
end

def.method().InitSellPanel = function (self)
    GUI.SetText(self._LabTitle,StringTable.Get(24001))
    self._FrameMoney:SetActive(true)
    self._ImgSellIcon:SetActive(true)
    self._ImgDecomposeIcon:SetActive(false)
    self._BtnSell:SetActive(true)
    self._BtnDecompose:SetActive(false)
    self._RdoDecompose:SetActive(false)
    self._RdoSell:SetActive(true)
    self:UpdateTotalMoney()
end

def.method().InitDecomposePanel = function (self)
    GUI.SetText(self._LabTitle,StringTable.Get(24000))
    self._FrameMoney:SetActive(false)
    self._ImgSellIcon:SetActive(false)
    self._ImgDecomposeIcon:SetActive(true)
    self._BtnSell:SetActive(false)
    self._BtnDecompose:SetActive(true)
    self._RdoDecompose:SetActive(true)
    self._RdoSell:SetActive(false)
end


def.method().UpdatePanel = function(self)

    if self._Panel == nil then return end
    local Img_OnCheck = "Img_D"

    if self._CurRdoType == self._RdoType.ALL then
        self._RdoAll:FindChild(Img_OnCheck):SetActive(true)
        self._RdoEquip:FindChild(Img_OnCheck):SetActive(false)
        self._RdoElse:FindChild(Img_OnCheck):SetActive(false)
        if not IsNil(self._RdoCharm) then 
            self._RdoCharm:FindChild(Img_OnCheck):SetActive(false)
        end
    elseif self._CurRdoType == self._RdoType.EQUIPMENT  then
        self._RdoAll:FindChild(Img_OnCheck):SetActive(false)
        self._RdoEquip:FindChild(Img_OnCheck):SetActive(true)
        self._RdoElse:FindChild(Img_OnCheck):SetActive(false)
        if not IsNil(self._RdoCharm) then 
            self._RdoCharm:FindChild(Img_OnCheck):SetActive(false)
        end
    elseif self._CurRdoType == self._RdoType.CHARM  then 
        self._RdoAll:FindChild(Img_OnCheck):SetActive(false)
        self._RdoEquip:FindChild(Img_OnCheck):SetActive(false)
        self._RdoElse:FindChild(Img_OnCheck):SetActive(false)
        if not IsNil(self._RdoCharm) then 
            self._RdoCharm:FindChild(Img_OnCheck):SetActive(true)
        end
    elseif self._CurRdoType == self._RdoType.ELSE  then 
        self._RdoAll:FindChild(Img_OnCheck):SetActive(false)
        self._RdoEquip:FindChild(Img_OnCheck):SetActive(false)
        self._RdoElse:FindChild(Img_OnCheck):SetActive(true)
        if not IsNil(self._RdoCharm) then 
            self._RdoCharm:FindChild(Img_OnCheck):SetActive(false)
        end
    end 

    self._AllItemData = self:GetItemSets(game._HostPlayer._Package._NormalPack._ItemSet)

    self:UpdateItem()
    self:UpdateTotalMoney()
end

-- 刷新两侧Item
def.method().UpdateItem = function (self)
    if self._IsAllSelect then 
        self._ConfirmItemListData = self._AllItemData
    elseif self._IsSelectQuality then 
        self:FiltrateBelowBlueQualityItem()
    end
    -- self._CurAllChooseItemObj = {}
    self._ConfirmList:SetItemCount(#self._ConfirmItemListData)
    self._ChooseList:SetItemCount(#self._AllItemData)
end 

def.method().UpdateTotalMoney = function (self)
    self._TotalPrice = 0
    if self._CurOperationType == self._OperationType.SELL then 
        if #self._ConfirmItemListData > 0 then 
            for i ,itemData in ipairs(self._ConfirmItemListData) do
                local price = itemData._Template.RecyclePriceInGold * itemData._NormalCount
                self._TotalPrice = price + self._TotalPrice
            end
        end
    end
    GUI.SetText(self._LabMoney,tostring(self._TotalPrice))
end


local function sortfunction(item1, item2)
    if item1._Tid == 0 then
        return false
    end
    if item2._Tid == 0 then
        return true
    end

    local profMask = instance._ProfMask

    if item1._ProfessionMask == profMask and item2._ProfessionMask == profMask then
        if item1._SortId == item2._SortId then
            return item1._Slot < item2._Slot
        else
            return item1._SortId > item2._SortId
        end
    elseif item1._ProfessionMask == profMask then
        return true
    elseif item2._ProfessionMask == profMask then
            return false
    else
        if item1._SortId == item2._SortId then
            return item1._Slot < item2._Slot
        else
            return item1._SortId > item2._SortId
        end
    end
end

-----------------------------------------获取左侧能够出售或是分解Item数据---------------------------
def.method("table",'=>',"table").GetItemSets = function(self,tempitemSets)
    if self._CurOperationType == self._OperationType.SELL then 
        return self:GetSellItemSets(tempitemSets)
    elseif self._CurOperationType == self._OperationType.DECOMPOSE then
        return self:GetDecomposeItemSets(tempitemSets)
    end
end

--获取售卖物品集合
def.method("table",'=>',"table").GetSellItemSets = function(self,tempitemSets)
    -- local itemSets = self._ItemSet
    local itemSets = {}
    -- local tempitemSets = game._HostPlayer._Package._NormalPack._ItemSet
    if self._CurRdoType == self._RdoType.ALL then --所有物品
        for i,item in ipairs(tempitemSets) do
            if item:CanSell() then
                table.insert(itemSets, item)
            end
        end
    elseif self._CurRdoType == self._RdoType.EQUIPMENT then--装备
        for i,item in ipairs(tempitemSets) do
            if item._Tid ~= 0 then
                if item:IsEquip() and item:CanSell() then
                    table.insert(itemSets, item)
                end 
            end
        end
    elseif self._CurRdoType == self._RdoType.ELSE then
        for i,item in ipairs(tempitemSets) do
            if not item:IsEquip() and not item:IsCharm() and item:CanSell() then
                table.insert(itemSets, item)
            end
        end
    end

    --当a应该排在b前面时, 返回true, 反之返回false: sortid  从大到小排序
    table.sort(itemSets , sortfunction)
    -- self._ItemSet = itemSets
    return itemSets
end

--获取分解物品集合
def.method("table",'=>',"table").GetDecomposeItemSets = function(self,tempitemSets)
    -- local itemSets = self._ItemSet
    local itemSets = {}
    -- local tempitemSets = game._HostPlayer._Package._NormalPack._ItemSet
    if self._CurRdoType == self._RdoType.ALL then --所有物品
        for i,item in ipairs(tempitemSets) do
            if item:CanDecompose() then
                table.insert(itemSets, item)
            end
        end
    elseif self._CurRdoType == self._RdoType.EQUIPMENT then--装备
        for i,item in ipairs(tempitemSets) do
            if item._Tid ~= 0 then
                if item:IsEquip() and item:CanDecompose() then
                    table.insert(itemSets, item)
                end 
            end
        end
    elseif self._CurRdoType == self._RdoType.CHARM then
        for i,item in ipairs(tempitemSets) do
            if item._Tid ~= 0 then
                if item:IsCharm() and item:CanDecompose() then
                    table.insert(itemSets, item)
                end 
            end
        end
    elseif self._CurRdoType == self._RdoType.ELSE then
        for i,item in ipairs(tempitemSets) do
            if not item:IsEquip() and not item:IsCharm() and item:CanDecompose() then
                table.insert(itemSets, item)
            end
        end
    end

    --当a应该排在b前面时, 返回true, 反之返回false: sortid  从大到小排序
    table.sort(itemSets , sortfunction)
    -- self._ItemSet = itemSets
    return itemSets
end

--------------------------------------------设置右侧选中Item数据 ------------------------------------
def.method("boolean","number","number").SetConfirmItemSets = function (self,isChoose,slot,index)
    if not isChoose then 
        if #self._ConfirmItemListData > 0 then 
            local itemListData = {}
            for i,itemData in ipairs(self._ConfirmItemListData) do
                if itemData._Slot ~= slot then 
                    table.insert(itemListData,itemData)
                end
            end
            self._ConfirmItemListData = itemListData
        end
    else
        table.insert(self._ConfirmItemListData,self._AllItemData[index + 1])
    end
    self._ConfirmList:SetItemCount(#self._ConfirmItemListData)
end
-- 筛选蓝色品质以下的Item
def.method().FiltrateBelowBlueQualityItem = function (self)
    local itemDatas = {}
    for i,itemData in ipairs(self._AllItemData) do
        if itemData._Quality <= ItemQuality.Rare then 
            table.insert(itemDatas,itemData)
        end
    end
    self._ConfirmItemListData = itemDatas
    
end

-----------------------------------------出售或是分解操作 ---------------------------
-- 出售物品
local function SellItemsOperation (value)
    if value then 
        local SellItems = {}
        local C2SItemSell = require "PB.net".C2SItemSell
        local protocol = C2SItemSell()  
        local ItemSellStruct = require"PB.net".ItemSellStruct
        if #instance._ConfirmItemListData > 0 then 
            for i,item in ipairs(instance._ConfirmItemListData) do
                local SellItem = ItemSellStruct()
                SellItem.Index = item._Slot
                SellItem.Count = item._NormalCount
                table.insert(protocol.Items,SellItem)
            end    
            PBHelper.Send(protocol)
            -- 刷新界面

            --instance:UpdatePanel()  

            instance:LockUI(true)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_Sell_Item, 0)
        end
    end  
end

-- 分解物品
local function DecomposeItemsOperation (value)
    if value then 
        if #instance._ConfirmItemListData > 0 then
            local C2SItemMachiningBatch = require "PB.net".C2SItemMachiningBatch
            local protocol = C2SItemMachiningBatch()
            local C2SItemStruct = require"PB.net".ItemMachiningBatchStruct
            for i,item in ipairs(instance._ConfirmItemListData) do
                local DecomposeItem = C2SItemStruct()
                DecomposeItem.Slot = item._Slot
                DecomposeItem.Count = item._NormalCount
                table.insert(protocol.Machings,DecomposeItem)
            end
            PBHelper.Send(protocol)

            instance:LockUI(true)
        end
    end
end

-- 检测出售或是分解的物品中是否有紫色级以上品质的道具
def.method("=>","boolean").CheckAbovePurpleQualityItem = function (self)
    for i,item in ipairs(self._ConfirmItemListData ) do
        if item._Quality >= ItemQuality.Epic then 
            return true
        end
    end
    return false
end

-- S2C分解协议返回操作
def.method('number').S2CDecompose = function (self, ErrorCode)
    --warn("S2CDecompose" .. tostring(ErrorCode))
    if ErrorCode == 0 then 
        self._IsSelectQuality = false
        self._IsAllSelect = false
        self._ImgAllSelect:SetActive(false)
        self._ImgSelectQuality:SetActive(false)
        self._ImgNotAllSelect:SetActive(true)
        self._ImgNotSelectQuality:SetActive(true)

        DelayedRefreshEffect(self)
        self._ConfirmItemListData = {}

        --self:UpdatePanel()
    else
        game._GUIMan:ShowErrorTipText(ErrorCode)
        self:LockUI(false)
    end
end

-- S2C售卖协议返回操作
def.method("number").S2CSell = function (self,result)
    --warn("S2CSell" .. tostring(result))
    if result == 0 then 
        self._IsSelectQuality = false
        self._IsAllSelect = false
        self._ImgAllSelect:SetActive(false)
        self._ImgSelectQuality:SetActive(false)
        self._ImgNotAllSelect:SetActive(true)
        self._ImgNotSelectQuality:SetActive(true)

        DelayedRefreshEffect(self)
        self._ConfirmItemListData = {}

        --self:UpdatePanel()
    else
        self:LockUI(false)
    end
end
----------------------------------Item显示设置 --------------------------------------

-- -- 显示选中框
-- def.method("userdata").ShowBorder = function(self, item)
--     if item ~= nil then
--         local obj = GUITools.GetChild(item, 5)
--         if not IsNil(obj) then
--             obj:SetActive(true)
--         else
--             warn("Can not get child at ", item.name)
--         end
--     end
-- end

-- --清除格子选中框
-- def.method().CleanBorder = function(self)
--     if not IsNil(self._CurrentSelectedItem) then
--         self._CurLongPressItem:FindChild('Img_Select'):SetActive(false)
--     end
-- end

------------------------------------触发事件 -----------------------------
def.override("string", "boolean").OnToggle = function(self, id, checked)
    if string.find(id, "Rdo_All") and checked then
        self._RdoAll:FindChild("Img_U"):SetActive(false)
        self._CurRdoType = self._RdoType.ALL
        self:UpdatePanel()
    elseif string.find(id, "Rdo_Equipment") and checked then
        self._RdoEquip:FindChild("Img_U"):SetActive(false)
        self._CurRdoType = self._RdoType.EQUIPMENT
        self:UpdatePanel()
    elseif string.find(id, "Rdo_Else") and checked then
        self._RdoElse:FindChild("Img_U"):SetActive(false)
        self._CurRdoType = self._RdoType.ELSE
        self:UpdatePanel()
    elseif string.find(id,"Rdo_Charm") and checked then
        self._RdoCharm:FindChild("Img_U"):SetActive(false)
        self._CurRdoType = self._RdoType.CHARM
        self:UpdatePanel()
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, btn_obj, id, id_btn, index)
    if id == "ChooseList_Item" then 

        self._IsSelectQuality = false
        self._IsAllSelect = false
        self._ImgAllSelect:SetActive(false)
        self._ImgSelectQuality:SetActive(false)
        self._ImgNotAllSelect:SetActive(true)
        self._ImgNotSelectQuality:SetActive(true)

        local item = self._ChooseList:GetItem(index)
        if item == nil then return end
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local Btn_Selected = uiTemplate:GetControl(12)
        local Btn_NotSelected = uiTemplate:GetControl(11)

        local itemData = self._AllItemData[index + 1]
        
        if id_btn == "Btn_Selected" then 
            --删除
            Btn_Selected:SetActive(false)
            Btn_NotSelected:SetActive(true)
            self:SetConfirmItemSets(false,itemData._Slot,index)
        elseif id_btn == "Btn_NotSelected" then 
            -- 选中
            Btn_Selected:SetActive(true)
            Btn_NotSelected:SetActive(false)
            self:SetConfirmItemSets(true,itemData._Slot,index)
            if itemData:IsEquip() then 
                CItemTipMan.ShowPackbackEquipTip(itemData, TipsPopFrom.OTHER_PANEL,TipPosition.DEFAULT_POSITION,self._TipPosition)
            else
                CItemTipMan.ShowPackbackItemTip(itemData, TipsPopFrom.OTHER_PANEL,TipPosition.DEFAULT_POSITION,self._TipPosition)
            end

            --选中效果 dotween group 1
            local dt_selected = uiTemplate:GetControl(13)
            if not IsNil(dt_selected) then
                dt_selected = dt_selected:GetComponent(ClassType.DOTweenPlayer)
                if not IsNil(dt_selected) then
                    dt_selected:Restart("1")
                end
            end

        end
        self:UpdateTotalMoney()
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "ConfirmList_Item" then 
        local itemData = self._ConfirmItemListData[index + 1]
        self:SetConfirmItemSets(false,itemData._Slot,index)
        self:UpdateItem() 
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local itemData = {}
    if id == "ChooseList_Item" then 
        itemData = self._AllItemData[index + 1]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local Btn_Selected = uiTemplate:GetControl(12)
        local Btn_NotSelected = uiTemplate:GetControl(11)
        Btn_Selected:SetActive(false)
        Btn_NotSelected:SetActive(true) 
        if self._IsAllSelect then 
            Btn_Selected:SetActive(true)
            Btn_NotSelected:SetActive(false)
        elseif self._IsSelectQuality then 
            if self._AllItemData[index + 1]._Quality <= ItemQuality.Rare then 
                Btn_Selected:SetActive(true)
                Btn_NotSelected:SetActive(false) 
            else
                Btn_Selected:SetActive(false)
                Btn_NotSelected:SetActive(true) 
            end  
        else
            if #self._ConfirmItemListData > 0 then 
                for i,confirmItem in ipairs(self._ConfirmItemListData) do
                    if itemData._Slot == confirmItem._Slot then 
                        Btn_Selected:SetActive(true)
                        Btn_NotSelected:SetActive(false) 
                    end
                end
            else
                Btn_Selected:SetActive(false)
                Btn_NotSelected:SetActive(true) 
            end  
        end
        -- table.insert(self._CurAllChooseItemObj,item)
    elseif id == "ConfirmList_Item" then 
        itemData = self._ConfirmItemListData[index + 1]
    end
    GUITools.SetItem(item, itemData._Template, itemData._NormalCount, 0, itemData:IsBind(), itemData._IsNewGot, itemData:CanUse())
    if itemData:IsEquip() then 
        GUITools.SetEquipItemFightArrow(itemData,item)
    end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_AllSelected" then 
        if not self._IsAllSelect then 
            self._ImgAllSelect:SetActive(true)
            self._ImgNotAllSelect:SetActive(false)
            self._ImgSelectQuality:SetActive(false)
            self._ImgNotSelectQuality:SetActive(true)

            self._IsSelectQuality = false
            self._IsAllSelect = true
        else
            self._ImgAllSelect:SetActive(false)
            self._ImgNotAllSelect:SetActive(true)

            self._IsAllSelect = false
            self._ConfirmItemListData = {} 
        end

        self:UpdateItem()
        self:UpdateTotalMoney()
    elseif id == "Btn_SelectedQuality" then 
        if not self._IsSelectQuality then 
            self._IsAllSelect = false
            self._IsSelectQuality = true

            self._ImgAllSelect:SetActive(false)
            self._ImgNotAllSelect:SetActive(true)
            self._ImgSelectQuality:SetActive(true)
            self._ImgNotSelectQuality:SetActive(false)

        else
            self._IsSelectQuality = false
            self._ImgSelectQuality:SetActive(false)
            self._ImgNotSelectQuality:SetActive(true)

            self._ConfirmItemListData = {}
        end

        self:UpdateItem()
        self:UpdateTotalMoney()
    elseif id == "Btn_Sell" then 
        local result = self:CheckAbovePurpleQualityItem()
        if not result then 
            SellItemsOperation(true)
        else
            local title, str, closeType = StringTable.GetMsg(11)
            MsgBox.ShowMsgBox(str,title,closeType,MsgBoxType.MBBT_OKCANCEL,SellItemsOperation) 
        end
    elseif id == "Btn_Decompose" then 
        local result = self:CheckAbovePurpleQualityItem()
        if not result then 
            DecomposeItemsOperation(true)
        else
            local title, str,closeType = StringTable.GetMsg(12)
            MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,DecomposeItemsOperation)     
        end
    end
end


CPanelBatchOperation.Commit()
return CPanelBatchOperation
]]