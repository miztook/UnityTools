
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CUIItemList = Lplus.Extend(CPanelBase, 'CUIItemList')
local def = CUIItemList.define

def.field("userdata")._ItemListObj = nil 
def.field("userdata")._DropConditionObj = nil 
def.field("userdata")._LabNothingObj = nil 
def.field("userdata")._BtnOK = nil
def.field("userdata")._NewListComponent = nil 
def.field("userdata")._CurSelectItem = nil 

def.field("number")._CurSelectItemIndex = 0 
def.field("number")._BeforeCondition = 0 
def.field("boolean")._IsNothing = false


-- 传进来的数据
def.field("dynamic")._Sender = nil
def.field("table")._CurItemData = nil 
def.field("table")._AllConditionList = nil 
def.field("string")._NothingText  = ''
def.field("function")._InitItemFunc = nil 
def.field("function")._SelectItemCall = nil 
def.field("function")._ConditionFunc = nil  
def.field("number")._ShowTipType = 0
def.field("userdata")._TipPos = nil 

local instance = nil
def.static('=>', CUIItemList).Instance = function ()
    if not instance then
        instance = CUIItemList()
        instance._PrefabPath = PATH.UI_ItemList
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end
 
def.override().OnCreate = function(self)
    self._ItemListObj = self:GetUIObject('List_Item')
    self._NewListComponent = self ._ItemListObj:GetComponent(ClassType.GNewList)
    self._DropConditionObj = self:GetUIObject("Drop_Condition")
    self._LabNothingObj = self:GetUIObject("Lab_Nothing")
    self._BtnOK = self:GetUIObject("Btn_Ok")
    self._TipPos = self:GetUIObject("TipPosition")
    local dropTemplate = self:GetUIObject("Drop_Template")
    GUITools.SetupDropdownTemplate(self, dropTemplate)
    self._NothingText = StringTable.Get(28001)
end


def.override("dynamic").OnData = function (self,data)
    self._Sender = data.Sender
    self._CurItemData = data.CurItemList
    self._InitItemFunc = data.InitItemFunc 
    self._SelectItemCall = data.SelectItemCall
    self._ShowTipType = data.ShowTipType
    self._ConditionFunc = data.ConditionFunc
    self._AllConditionList = data.AllConditionList
    if self._CurItemData == nil or #self._CurItemData == 0 then 
        self._LabNothingObj:SetActive(true)
        GUI.SetText(self._LabNothingObj,self._NothingText)
    else
        self._LabNothingObj:SetActive(false)
    end
    self:SetDropGroup()
    self:UpdateListShow()
end

def.method().UpdateListShow = function (self)
    if self._CurItemData == nil or #self._CurItemData == 0 then 
        self._ItemListObj:SetActive(false)
        self._LabNothingObj:SetActive(true)
        GUI.SetText(self._LabNothingObj,self._NothingText)
        GUITools.SetBtnGray(self._BtnOK, true)
        return
    else 
        self._ItemListObj:SetActive(true)
        self._LabNothingObj:SetActive(false)
        GUITools.SetBtnGray(self._BtnOK, false)
        self._CurSelectItemIndex = 0
        self._CurSelectItem = nil 
        self._NewListComponent:SetItemCount(#self._CurItemData)
    end
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if string.find(id, "Drop_Condition") then
        if self._BeforeCondition == index + 1 then return end
        -- 做筛选
        self._BeforeCondition = index + 1
        local value = self._ConditionFunc(self._Sender, index + 1)
        if type(value) == "string" then
            self._IsNothing = true
            self._NothingText = value
            self._CurItemData = nil 
        elseif type(value) == "table" then
            self._CurItemData = value 
            self._IsNothing = false
        end
        self:UpdateListShow()
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)   
    if id == "List_Item" then 
        -- 初始化Item列表
        self._InitItemFunc(self._Sender, item, self._CurItemData[index + 1])
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Item" then

        local itemData = self._CurItemData[index+1]
        local bCanBeSelect = self._SelectItemCall(self._Sender, item, itemData, false)

        -- 选中操作
        if self._CurSelectItemIndex == index + 1 or not bCanBeSelect then return end

        self._NewListComponent:SetSelection(index)
        self._CurSelectItemIndex = index + 1
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id_btn == "Btn_Icon" then
        -- 显示tips
        local itemData = self._CurItemData[index + 1]
        if self._ShowTipType == ShowTipType.ShowPackbackTip then
            if itemData:IsEquip() then 
                CItemTipMan.ShowPackbackEquipTip(itemData, TipsPopFrom.OTHER_PANEL,TipPosition.FIX_POSITION,item)
            else
                CItemTipMan.ShowPackbackItemTip(itemData, TipsPopFrom.OTHER_PANEL,TipPosition.FIX_POSITION,item)
            end
        elseif self._ShowTipType == ShowTipType.ShowItemTip then
            CItemTipMan.ShowItemTips(itemData._Tid, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
        elseif self._ShowTipType == ShowTipType.ShowPetTip then 
            local panelData = 
            {
                _PetData = self._CurItemData[index + 1],
                _TipPos = TipPosition.FIX_POSITION,
                _TargetObj = item, 
            }
            
            CItemTipMan.ShowPetTips(panelData)
        end
    end
end

def.override("string").OnClick = function(self,id)
    if id == "Btn_Sort" then 
        if self._IsNothing then return end
        local itemList = {}
        for i = 0, #self._CurItemData - 1 do
            table.insert(itemList,self._CurItemData[#self._CurItemData - i])
        end
        self._CurItemData = itemList
        self._NewListComponent:SetItemCount(#self._CurItemData)
    elseif id == "Btn_Ok" then 
        if not self._IsNothing then 
            local itemData = self._CurItemData[self._CurSelectItemIndex]
            if itemData ~= nil then 
                self._SelectItemCall(self._Sender, self._CurSelectItem, itemData, true)
                game._GUIMan:CloseByScript(self)
                return
            end
        end
        game._GUIMan:ShowTipText(StringTable.Get(28002),false)
    end
end

-- 设置上拉菜单
def.method().SetDropGroup = function(self)
    self._BeforeCondition = 0 
    local groupStr = self._AllConditionList[1]
    if #self._AllConditionList >= 2 then 
        for i = 2, #self._AllConditionList do
            groupStr = groupStr .. "," .. self._AllConditionList[i]
        end
    end

    -- GameUtil.AdjustDropdownRect(self._DropConditionObj, #self._AllConditionList)
    GUI.SetDropDownOption(self._DropConditionObj, groupStr)
end

def.override().OnDestroy = function(self)
    instance = nil 
end
 
CUIItemList.Commit()
return CUIItemList