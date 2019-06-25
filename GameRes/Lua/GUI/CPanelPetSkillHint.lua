
local Lplus = require 'Lplus'
local CPanelHintBase = require 'GUI.CPanelHintBase'
local CElementData = require "Data.CElementData"

local CUIPetSkillHint = Lplus.Extend(CPanelHintBase, 'CUIPetSkillHint')
local def = CUIPetSkillHint.define
 
def.field('userdata')._Lab_EquipTips = nil
def.field('userdata')._Lab_EquipName = nil
def.field('userdata')._Lab_ShowType = nil
def.field('number')._TipPosition = 0
def.field("userdata")._Frame_All = nil 

local instance = nil
def.static('=>', CUIPetSkillHint).Instance = function ()
	if not instance then
        instance = CUIPetSkillHint()
        instance._PrefabPath = PATH.UI_PetSkillHint
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance:SetupSortingParam()
        -- instance._DestroyOnHide = true
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._Lab_EquipTips = self:GetUIObject("Lab_EquipTips")
    self._Lab_EquipName = self:GetUIObject("Lab_EquipName")
    self._Lab_ShowType = self:GetUIObject("Lab_ShowType")
    self._Frame_All = self:GetUIObject("Frame_All")
end

--panelData= 
--{
--     _TalentID , -- 被动技能id
--     _TalentLevel, --技能等级
--     _TipPos,   -- tips的位置（默认位置和随着Item适配）
--     _TargetObj, -- 目标物体（根据位置不同设定）
--}

def.override("dynamic").OnData = function(self, data) 
    self._TipPosition = data._TipPos
    local TalentItem = CElementData.GetTalentTemplate(data._TalentID)
    if TalentItem == nil then warn("TalentItem is nil", data._TalentID) end 
    local name = ""   
    if game._IsOpenDebugMode == true then
        name = "(".. data._TalentID  ..")" .. TalentItem.Name
    else
        name = TalentItem.Name
    end
    GUITools.SetGroupImg(self:GetUIObject("Img_Quality"), TalentItem.InitQuality)
    local labQuality = self:GetUIObject("Lab_QualityText")
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + TalentItem.InitQuality), TalentItem.InitQuality)
    GUI.SetText(labQuality,color)
    GUI.SetText(self._Lab_EquipName,name)
    self._Lab_ShowType:SetActive(false)
    local DynamicText = require"Utility.DynamicText"
    GUI.SetText(self._Lab_EquipTips,DynamicText.ParseSkillDescText(data._TalentID, data._TalentLevel, true))
    GUITools.SetItemIcon(self:GetUIObject("Img_ItemIcon"),TalentItem.Icon) 
    -- self:InitTipPosition(data._TargetObj)
end

def.method("userdata").InitTipPosition = function (self,target)
    if self._TipPosition == 0 or target == nil then return end
    if self._TipPosition == TipPosition.FIX_POSITION then 
        GameUtil.SetTipsPosition(target,self._Frame_All)
    elseif self._TipPosition == TipPosition.DEFAULT_POSITION then 
        self._Frame_All.localPosition = target.localPosition
    end
end

def.method().Hide = function(self)
    game._GUIMan:CloseByScript(self)
    -- MsgBox.CloseAll()
end

CUIPetSkillHint.Commit()
return CUIPetSkillHint