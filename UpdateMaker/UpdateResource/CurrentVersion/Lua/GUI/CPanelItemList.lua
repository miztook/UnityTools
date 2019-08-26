
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CUIItemList = Lplus.Extend(CPanelBase, 'CUIItemList')
local def = CUIItemList.define

def.field("userdata")._ItemListObj = nil 
def.field("userdata")._DropConditionObj = nil 
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

-- 材料类型, 用于设置无材料时获取途径
def.field("number")._ApproachMaterialType = 0
def.field("userdata")._Tab_NoneMaterial = nil
def.field("userdata")._List_NoneMaterial = nil
def.field("userdata")._Lab_NoneMaterial = nil
def.field("userdata")._Lab_Nothing = nil
def.field("table")._MaterialFromInfo = BlankTable   -- 材料来源信息表
def.field("userdata")._Frame_Item = nil
def.field("userdata")._Drop_Condition = nil

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
    self._BtnOK = self:GetUIObject("Btn_Ok")
    self._TipPos = self:GetUIObject("TipPosition")
    self._Tab_NoneMaterial = self:GetUIObject('Tab_NoneMaterial')
    self._Lab_Nothing = self:GetUIObject('Lab_Nothing')
    self._Lab_NoneMaterial = self:GetUIObject('Lab_NoneMaterial')
    self._List_NoneMaterial = self:GetUIObject('List_NoneMaterial'):GetComponent(ClassType.GNewList)
    self._Frame_Item = self:GetUIObject('Frame_Item')
    self._Drop_Condition = self:GetUIObject('Drop_Condition')

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
    self._ApproachMaterialType = data.ApproachMaterialType or 0
    self._NewListComponent.SingleSelect = self._ApproachMaterialType ~= EnumDef.ApproachMaterialType.PetFuse

    self:SetDropGroup()
    self:UpdateListShow()
end

def.method("boolean").UpdateNoneMaterialUI = function(self, bNoneMaterial)
    local bActive = bNoneMaterial and self._ApproachMaterialType ~= EnumDef.ApproachMaterialType.None
    self._Tab_NoneMaterial:SetActive( bActive )
    self._Lab_Nothing:SetActive( bNoneMaterial and not bActive)
    self._Frame_Item:SetActive( not bNoneMaterial )

    if bActive then
        if self._ApproachMaterialType == EnumDef.ApproachMaterialType.PetAdvance then
            local CPetUtility = require "Pet.CPetUtility"
            self._MaterialFromInfo = CPetUtility.GetPetFromInfo()
            GUI.SetText(self._Lab_NoneMaterial, StringTable.Get(10988))
        elseif self._ApproachMaterialType == EnumDef.ApproachMaterialType.PetFuse then
            local CPetUtility = require "Pet.CPetUtility"
            self._MaterialFromInfo = CPetUtility.GetPetFromInfo()
            GUI.SetText(self._Lab_NoneMaterial, StringTable.Get(10988))
        elseif self._ApproachMaterialType == EnumDef.ApproachMaterialType.PetSkillBook then
            local CPetUtility = require "Pet.CPetUtility"
            self._MaterialFromInfo = CPetUtility.GetPetSkillBookFromInfo()
            GUI.SetText(self._Lab_NoneMaterial, StringTable.Get(10989))
        end

        local count = #self._MaterialFromInfo
        self._List_NoneMaterial:SetItemCount( count )
    end
end

def.method().UpdateListShow = function (self)
    local bNoneMaterial = self._CurItemData == nil or #self._CurItemData == 0
    self:UpdateNoneMaterialUI( bNoneMaterial )

    if bNoneMaterial then 
        self._ItemListObj:SetActive(false)
        GUITools.SetBtnGray(self._BtnOK, true)
    else 
        self._ItemListObj:SetActive(true)
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
    local idx = index+1

    if id == "List_Item" then 
        -- 初始化Item列表
        self._InitItemFunc(self._Sender, item, self._CurItemData[idx])
    elseif id == "List_NoneMaterial" then
        local info = self._MaterialFromInfo[idx]
        GUI.SetText(item:FindChild("Img_Bg/Lab_Name"), info.Name)
        GUITools.SetIcon(item:FindChild("Img_Bg/Img_Icon"), info.IconPath)
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local idx = index+1
    if id == "List_Item" then
        local itemData = self._CurItemData[idx]
        local bCanBeSelect = self._SelectItemCall(self._Sender, item, itemData, false)

        if self._ApproachMaterialType ~= EnumDef.ApproachMaterialType.PetFuse then
            -- 选中操作
            if self._CurSelectItemIndex == idx or not bCanBeSelect then return end
            self._NewListComponent:SetSelection(index)
            self._CurSelectItemIndex = idx
        end
    elseif id == "List_NoneMaterial" then
        local info = self._MaterialFromInfo[idx]
        game._AcheivementMan:DrumpToRightPanel(info.ID,0)
        game._GUIMan:CloseByScript(self)
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
            if self._ApproachMaterialType == EnumDef.ApproachMaterialType.PetFuse then
                if self._SelectItemCall(self._Sender, self._CurSelectItem, itemData, true) then
                    game._GUIMan:CloseByScript(self)
                    return
                end
            else
                if itemData ~= nil then 
                    if self._SelectItemCall(self._Sender, self._CurSelectItem, itemData, true) then
                        game._GUIMan:CloseByScript(self)
                        return
                    end
                end
            end
        end
        local strMsg = ""
        if self._ApproachMaterialType == EnumDef.ApproachMaterialType.PetFuse or
           self._ApproachMaterialType == EnumDef.ApproachMaterialType.PetAdvance then
            strMsg = StringTable.Get(28004)
        else
            strMsg = StringTable.Get(28002)
        end

        game._GUIMan:ShowTipText(strMsg,false)
    end
end

-- 设置上拉菜单
def.method().SetDropGroup = function(self)
    local bActive = self._ApproachMaterialType ~= EnumDef.ApproachMaterialType.PetAdvance
    self._Drop_Condition:SetActive(bActive)
    if not bActive then return end

    self._BeforeCondition = 0 
    local groupStr = self._AllConditionList[1]
    if #self._AllConditionList >= 2 then 
        for i = 2, #self._AllConditionList do
            groupStr = groupStr .. "," .. self._AllConditionList[i]
        end
    end

    GUI.SetDropDownOption(self._DropConditionObj, groupStr)
end

def.override().OnDestroy = function(self)
    instance = nil 
end
 
CUIItemList.Commit()
return CUIItemList