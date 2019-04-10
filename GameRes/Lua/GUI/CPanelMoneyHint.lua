
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelMoneyHint = Lplus.Extend(CPanelBase, 'CPanelMoneyHint')
local def = CPanelMoneyHint.define
 
def.field('userdata')._Lab_EquipTips = nil
def.field('userdata')._Lab_EquipName = nil
def.field('userdata')._Lab_ShowType = nil
def.field('number')._TipPosition = 0
def.field("userdata")._Frame_All = nil 

local instance = nil
def.static('=>', CPanelMoneyHint).Instance = function ()
	if not instance then
        instance = CPanelMoneyHint()
        instance._PrefabPath = PATH.UI_MoneyHint
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        -- instance._DestroyOnHide = true
        instance:SetupSortingParam()
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
--     _MoneyID , -- 货币id
--     _TipPos,   -- tips的位置（默认位置和随着Item适配）
--     _TargetObj, -- 目标物体（根据位置不同设定）
--}
def.override("dynamic").OnData = function(self, data) 
    CPanelBase.OnData(self,data)
    self._TipPosition = data._TipPos
    local MoneyItem = CElementData.GetMoneyTemplate(data._MoneyID)
    if MoneyItem == nil then return warn("MoneyItem is nil ")end 
    local name = ""   
    if game._IsOpenDebugMode == true then
        name = "(".. data._MoneyID ..")" .. MoneyItem.TextDisplayName
    else
        name = MoneyItem.TextDisplayName
    end
    GUI.SetText(self._Lab_EquipName,name)
    GUI.SetText(self._Lab_ShowType,MoneyItem.TextDisplayType)
    GUI.SetText(self._Lab_EquipTips,MoneyItem.Description)
    GUITools.SetGroupImg(self:GetUIObject("Img_Quality"), MoneyItem.Quality)
    GUITools.SetItemIcon(self:GetUIObject("Img_ItemIcon"),MoneyItem.IconPath) 
    local labQuality = self:GetUIObject("Lab_QualityText")
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + MoneyItem.Quality), MoneyItem.Quality)
    GUI.SetText(labQuality,color)
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
CPanelMoneyHint.Commit()
return CPanelMoneyHint