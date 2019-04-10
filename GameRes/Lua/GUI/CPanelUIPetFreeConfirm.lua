local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"

local CPanelUIPetFreeConfirm = Lplus.Extend(CPanelBase, 'CPanelUIPetFreeConfirm')
local def = CPanelUIPetFreeConfirm.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._PetData = nil
def.field("number")._PetMatItemID = 1026        -- 宠物碎片ID

local instance = nil
def.static('=>', CPanelUIPetFreeConfirm).Instance = function ()
    if not instance then
        instance = CPanelUIPetFreeConfirm()
        instance._PrefabPath = PATH.UI_PetFreeConfirm
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._PetData = data
        end

        CPanelBase.OnData(self,data)
    end
    local mat_temp = CElementData.GetItemTemplate(self._PetMatItemID)
    local title, msg, closeType = StringTable.GetMsg(34)
    local item = self:GetUIObject('Item')
    local Img_Quality = item:FindChild("Img_Quality")
    local img_quality1 = item:FindChild("Img_Quality1")
    local Img_ItemIcon = item:FindChild("Img_ItemIcon")
    local Lab_Lv = self:GetUIObject("Lab_Level")
    local lab_mat_count = self:GetUIObject("Lab_MatCount")
    local img_mat_icon = lab_mat_count:FindChild("Img_Get")
    local lab_msg = self:GetUIObject('Lab_Message')
    local lab_title = self:GetUIObject('Lab_MsgTitle')
    local strLv = string.format(StringTable.Get(19073), self._PetData._Level)
    local size = GUITools.GetTextSize(lab_msg)
    strLv = GUITools.FormatRichTextSize(size-2, strLv)
    msg = string.format(msg, self._PetData:GetRecyclingPetDebris(), RichTextTools.GetItemNameRichText(self._PetMatItemID, 1, false), 
        RichTextTools.GetPetNickNameRichText(self._PetData._Tid, self._PetData._NickName, false)..strLv)

    GUI.SetText(lab_title, title)
    GUI.SetText(lab_msg, msg)
    if mat_temp ~= nil then
        GUITools.SetIcon(img_mat_icon, mat_temp.IconAtlasPath)
    end
    GUITools.SetIcon(Img_ItemIcon, self._PetData._IconPath)
    GUITools.SetGroupImg(Img_Quality, self._PetData._Quality)
    GUITools.SetGroupImg(img_quality1, self._PetData._Quality)
    GUI.SetText(Lab_Lv, tostring(self._PetData._Level))
    GUI.SetText(lab_mat_count, tostring(self._PetData:GetRecyclingPetDebris()))
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Yes' then
        CPetUtility.SendC2SPetSetFree(self._PetData._ID)
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
        game._GUIMan:CloseByScript(self)
    elseif id == "Item" then
        local panelData = 
        {
            _PetData = self._PetData,
            _TipPos = TipPosition.FIX_POSITION,
            _TargetObj = self:GetUIObject('Item'), 
        }
            
        CItemTipMan.ShowPetTips(panelData)
    end
    CPanelBase.OnClick(self, id)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelUIPetFreeConfirm.Commit()
return CPanelUIPetFreeConfirm