local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"

local CPanelUIPetFightingProperty = Lplus.Extend(CPanelBase, "CPanelUIPetFightingProperty")
local def = CPanelUIPetFightingProperty.define

def.field("userdata")._List_Prop = nil          -- 属性List GO
def.field("table")._PetsPropInfo = BlankTable   -- 存储宠物属性信息的集合
def.field("userdata")._Lab_FightScore = nil     -- 战斗力

local instance = nil
def.static("=>",CPanelUIPetFightingProperty).Instance = function()
    if instance == nil then
        instance = CPanelUIPetFightingProperty()
        instance._PrefabPath = PATH.UI_PetFightingProperty
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._List_Prop = self:GetUIObject("List_Property"):GetComponent(ClassType.GNewList)
    self._Lab_FightScore = self:GetUIObject("Lab_FightScore")
end

def.override("dynamic").OnData = function(self,data)
    self._PetsPropInfo = CPetUtility.CalcPropertyInfo()
    self._List_Prop:SetItemCount(#self._PetsPropInfo)

    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local score = petPackage:GetTotalFightScore()
    GUI.SetText(self._Lab_FightScore, GUITools.FormatNumber(score))
    
    CPanelBase.OnData(self,data)
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_Property" then
        local propertyInfo = self._PetsPropInfo[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local lab_prop_name = uiTemplate:GetControl(0)
        local lab_value = uiTemplate:GetControl(1)
        GUI.SetText(lab_prop_name, propertyInfo.Name)
        local val = GUITools.FormatNumber(propertyInfo.Value)
	    GUI.SetText(lab_value, tostring(val))
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelUIPetFightingProperty.Commit()
return CPanelUIPetFightingProperty