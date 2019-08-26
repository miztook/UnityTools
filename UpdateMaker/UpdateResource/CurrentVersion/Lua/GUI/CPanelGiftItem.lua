
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelGiftItem = Lplus.Extend(CPanelBase, 'CPanelGiftItem')
local EItemType = require "PB.Template".Item.EItemType
local def = CPanelGiftItem.define

def.field("userdata")._FrameGetPer = nil 
def.field("table")._TipPanel = nil 
def.field("userdata")._FrameAll = nil 

local instance = nil
def.static('=>', CPanelGiftItem).Instance = function ()
	if not instance then
        instance = CPanelGiftItem()
        instance._PrefabPath = PATH.UI_GiftItem
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
   self._FrameGetPer = self:GetUIObject("Frame_GetPer")
   self._FrameAll = self:GetUIObject("Frame_All")
end

def.override("dynamic").OnData = function(self,data)
    local itemTemp = CElementData.GetItemTemplate(data.ItemId)
    local item = self:GetUIObject("Item")
    local img_item_icon = item:FindChild("Img_ItemIcon")
    GUITools.SetItemIcon(img_item_icon, itemTemp.IconAtlasPath)
    local img_quality = item:FindChild("Img_Quality")
    GUITools.SetGroupImg(img_quality, itemTemp.InitQuality)
    local lab_item_name = item:FindChild("Lab_ItemName")
    GUI.SetText(lab_item_name, RichTextTools.GetQualityText(itemTemp.TextDisplayName, itemTemp.InitQuality))
    -- GUITools.SetItem(item,data.ItemId)  
    local Lab_ShowType = self:GetUIObject("Lab_ShowType")
    GUI.SetText(Lab_ShowType,itemTemp.DescriptionType)
    local labDescribe = self:GetUIObject("Lab_EquipTips")
    GUI.SetText(labDescribe,itemTemp.TextDescription)

    self._FrameGetPer:SetActive(true)
    -- self._TipPanel = data.TipPanel
    -- self._TipPanel._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
    GameUtil.SetGiftItemPosition(data.TargetObj, self._FrameAll) 
    if data.Percent == 0 then
        self._FrameGetPer:SetActive(false)
    return end
    local labQuality = self:GetUIObject("Lab_QualityText")
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + itemTemp.InitQuality), itemTemp.InitQuality)
    GUI.SetText(labQuality,color)
    local labQualityTip = self:GetUIObject("Lab_Tip1")
    local labLvTip = self:GetUIObject("Lab_Tip2")
    if itemTemp.ItemType == EItemType.Equipment then 
        GUI.SetText(labQualityTip,StringTable.Get(10686))
        GUI.SetText(labLvTip,StringTable.Get(10688))
    else
        GUI.SetText(labQualityTip,StringTable.Get(10687))
        GUI.SetText(labLvTip,StringTable.Get(10689))
    end

    local lab_Level = self:GetUIObject("Lab_Lv") 
    if itemTemp.MinLevelLimit > 0 then 
        lab_Level :SetActive(true)
        GUI.SetText(lab_Level,tostring(itemTemp.MinLevelLimit))
    else
        lab_Level:SetActive(false)
    end
    local labPer = self:GetUIObject("Lab_AttriValues")
    GUI.SetText(labPer,string.format(StringTable.Get(10685),data.Percent / 100))
end

def.override().OnDestroy = function(self)
    -- if self._TipPanel ~= nil then 
    --     self._TipPanel._PanelCloseType = EnumDef.PanelCloseType.Tip
    -- end
    instance = nil
end

CPanelGiftItem.Commit()
return CPanelGiftItem