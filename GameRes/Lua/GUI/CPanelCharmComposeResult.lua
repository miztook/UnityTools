local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CCharmMan = require "Charm.CCharmMan"

local CPanelCharmComposeResult = Lplus.Extend(CPanelBase, "CPanelCharmComposeResult")
local def = CPanelCharmComposeResult.define
local instance = nil

def.field("table")._PanelObject = nil
def.field("boolean")._IsSuccess = true
def.field("boolean")._ShowGfx = false
def.field("number")._NewCharmID = 0
def.field("number")._OldCharmID = 0
def.field("number")._Mat1 = 0
def.field("number")._Mat2 = 0

def.static('=>', CPanelCharmComposeResult).Instance = function ()
	if not instance then
        instance = CPanelCharmComposeResult()
        instance._PrefabPath = PATH.UI_CharmComposeResult
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	self._PanelObject = {}
    self._PanelObject._Lab_SuccessTip = self:GetUIObject("Lab_SuccessTip")
    self._PanelObject._Lab_FaildTip = self:GetUIObject("Lab_FailedTip")
    self._PanelObject._Img_ItemIcon = self:GetUIObject("Img_Item")
    self._PanelObject._Lab_ItemName = self:GetUIObject("Lab_ItemName")
    self._PanelObject._Tab_SuccessAttr = self:GetUIObject("Tab_SuccessAttr")
    self._PanelObject._Tab_FaildTip = self:GetUIObject("Tab_FailedTip")
    self._PanelObject._Lab_LevelInfo = self:GetUIObject("Lab_LevelInfo")
    self._PanelObject._Lab_LevelBase = self:GetUIObject("Lab_LevelBase")
    self._PanelObject._Lab_LevelUp = self:GetUIObject("Lab_LevelUp")
    self._PanelObject._Lab_AttrName1 = self:GetUIObject("Lab_AttrName1")
    self._PanelObject._Lab_AttrName2 = self:GetUIObject("Lab_AttrName2")
    self._PanelObject._Lab_AttrValue1 = self:GetUIObject("Lab_AttrValue1")
    self._PanelObject._Lab_AttrValue2 = self:GetUIObject("Lab_AttrValue2")
    self._PanelObject._Lab_AttrValue3 = self:GetUIObject("Lab_AttrValue3")
    self._PanelObject._Lab_AttrValue4 = self:GetUIObject("Lab_AttrValue4")
    self._PanelObject._Lab_FailedTip1 = self:GetUIObject("Lab_FailedTip1")
    self._PanelObject._Lab_FailedTip2 = self:GetUIObject("Lab_FailedTip2")
    self:InitGfxGroup()
end

def.override("dynamic").OnData = function (self,data)
    if data == nil then return end
    self._IsSuccess = data.IsSuccess
    self._NewCharmID = data.NewCharmTid
    self._OldCharmID = data.OldCharmTid
    self._Mat1 = data.Mat1 or 0
    self._Mat2 = data.Mat2 or 0
    self._ShowGfx = not CCharmMan.Instance():GetCharmComposeSkipGfx()
    self:GfxLogic()
	self:UpdatePanel()
end

----------------------------------------------------------------------------------
--                                特效处理 Begin
----------------------------------------------------------------------------------
def.field("table")._GfxObjectGroup = BlankTable
local gfxGroupName = "CharmComposeResult"

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = "2"
    root.DoTweenTimeDelay = self._ShowGfx and 1.8 or 0
    root.TweenObjectHook = self:GetUIObject("Img_Item")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.TweenTimerId = 0

    root.GfxHook = self._Panel
    root.GfxTimeDelay = 0
    root.Gfx = PATH.ETC_Legend_juqi
    root.GfxTimerId = 0

    root.GfxBgHook1 = self:GetUIObject("Img_Item")
    root.GfxBgHook2 = self._Panel

    root.GfxBg1 = PATH.ETC_Fortify_Success_BG1
    root.GfxBg2 = PATH.ETC_Fortify_Success_BG2
end

-- 播放背景特效
def.method().PlayGfxBg = function(self)
    local root = self._GfxObjectGroup
    self:AddEvt_PlayFx(gfxGroupName, self._ShowGfx and 1.8 or 0, root.GfxBg1, root.GfxBgHook1, root.GfxBgHook1, -1, 1)
    self:AddEvt_PlayFx(gfxGroupName, self._ShowGfx and 1.8 or 0, root.GfxBg2, root.GfxBgHook2, root.GfxBgHook2, -1, 1)
end
-- 关闭背景特效
def.method().StopGfxBg = function(self)
    local root = self._GfxObjectGroup
    self:KillEvts(gfxGroupName)
end
-- 播放特效
def.method().PlayGfx = function(self)
    local root = self._GfxObjectGroup
    if self._ShowGfx then
        GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1, 20 , 3)
    end
    self:AddEvt_SetActive(gfxGroupName, self._ShowGfx and 1.8 or 0, self._Panel:FindChild("Frame_Center"), true)
    self:AddEvt_SetActive(gfxGroupName, self._ShowGfx and 1.8 or 0, self._Panel:FindChild("Img_BG"), true)
    self:AddEvt_PlayDotween(gfxGroupName, self._ShowGfx and 1.8 or 0, root.DoTweenPlayer, root.TweenGroupId)
    self:AddEvt_Shake(gfxGroupName, self._ShowGfx and 2.3 or 0.5, 15, 0.05)
end
-- 关闭特效
def.method().StopGfx = function(self)
    local root = self._GfxObjectGroup
    GameUtil.StopUISfx(root.Gfx, root.GfxHook)
end
-- 重置 组件和位置信息
def.method().ResetGfxGroup = function(self)
    local root = self._GfxObjectGroup
--    root.GfxHook.localPosition = root.OrignPosition
end

def.method().GfxLogic = function(self)
    local root = self._GfxObjectGroup
    self._Panel:FindChild("Img_BG"):SetActive( false )
    self._Panel:FindChild("Frame_Center"):SetActive( false )
    self:PlayGfx()
    self:PlayGfxBg()
end

----------------------------------------------------------------------------------
--                                特效处理 End
----------------------------------------------------------------------------------

-- 根据属性的加成类型和值返回字符串（+ 799 / + 6%）
def.method("dynamic", "dynamic", "=>", "string").GetPropStringByPropTypeAndValue = function(self, propType, propValue)
    if propType == nil or propValue == nil then return "+0" end
    if propType == 1 or propType == 2 then
        if propType == 1 then
            return "+"..propValue
        elseif propType == 2 then
            local value = propValue/100
            local value_str = string.format("+%0.1f%%", value)
            return value_str
        end
    else
        warn("CCharmPageInlay:GetPropStringByPropTypeAndValue() 属性类型错误", propType)
        return "+0"
    end
end

-- 刷新界面
def.method().UpdatePanel = function(self)
    local new_item_temp = CElementData.GetItemTemplate(self._NewCharmID)
    local new_charm_temp = CElementData.GetTemplate("CharmItem", self._NewCharmID)
    local old_charm_temp = CElementData.GetTemplate("CharmItem", self._OldCharmID)
    if new_item_temp == nil or new_charm_temp == nil then return end
    IconTools.InitItemIconNew(self._PanelObject._Img_ItemIcon, self._NewCharmID, nil)
    GUI.SetText(self._PanelObject._Lab_ItemName, new_item_temp.TextDisplayName)
    self._PanelObject._Lab_LevelInfo:SetActive(true)
    GUI.SetText(self._PanelObject._Lab_LevelInfo, StringTable.Get(19363))
    GUI.SetText(self._PanelObject._Lab_LevelBase, old_charm_temp.Level.."")
    GUI.SetText(self._PanelObject._Lab_LevelUp, new_charm_temp.Level.."")
    if self._IsSuccess then
        self._PanelObject._Tab_SuccessAttr:SetActive(true)
        self._PanelObject._Tab_FaildTip:SetActive(false)
        if new_charm_temp.PropID1 > 0 then
            local prop_temp1 = CElementData.GetAttachedPropertyTemplate(new_charm_temp.PropID1)
            GUI.SetText(self._PanelObject._Lab_AttrName1, prop_temp1.TextDisplayName)
            GUI.SetText(self._PanelObject._Lab_AttrValue1, self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType1, new_charm_temp.PropValue1))
            self._PanelObject._Lab_AttrName1:SetActive(true)
        else
            self._PanelObject._Lab_AttrName1:SetActive(false)
        end
        if new_charm_temp.PropID2 > 0 then
            local prop_temp2 = CElementData.GetAttachedPropertyTemplate(new_charm_temp.PropID2)
            GUI.SetText(self._PanelObject._Lab_AttrName2, prop_temp2.TextDisplayName)
            GUI.SetText(self._PanelObject._Lab_AttrValue2, self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType2, new_charm_temp.PropValue2))
            self._PanelObject._Lab_AttrName2:SetActive(true)
        else
            self._PanelObject._Lab_AttrName2:SetActive(false)
        end
        if old_charm_temp.PropID1 > 0 then
            GUI.SetText(self._PanelObject._Lab_AttrValue3, self:GetPropStringByPropTypeAndValue(old_charm_temp.PropType1, old_charm_temp.PropValue1))
            self._PanelObject._Lab_AttrValue3:SetActive(true)
        else
            self._PanelObject._Lab_AttrValue3:SetActive(false)
        end
        if old_charm_temp.PropID2 > 0 then
            GUI.SetText(self._PanelObject._Lab_AttrValue4, self:GetPropStringByPropTypeAndValue(old_charm_temp.PropType2, old_charm_temp.PropValue2))
            self._PanelObject._Lab_AttrValue4:SetActive(true)
        else
            self._PanelObject._Lab_AttrValue4:SetActive(false)
        end
    else
--        self._PanelObject._Lab_SuccessTip:SetActive(false)
--        self._PanelObject._Lab_FaildTip:SetActive(true)
        self._PanelObject._Tab_SuccessAttr:SetActive(false)
        self._PanelObject._Tab_FaildTip:SetActive(true)
        local mat_charm_temp1 = CElementData.GetTemplate("CharmItem", self._Mat1)
        local mat_charm_temp2 = CElementData.GetTemplate("CharmItem", self._Mat2)
        if mat_charm_temp1 == nil or mat_charm_temp2 == nil then
            warn("CPanelCahrmComposeResult  UpdatePanel, 两个材料神符为空 ")
            return
        end
        GUI.SetText(self._PanelObject._Lab_FailedTip1, string.format(StringTable.Get(19353), mat_charm_temp1.Name))
        GUI.SetText(self._PanelObject._Lab_FailedTip2, string.format(StringTable.Get(19353), mat_charm_temp2.Name))
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Img_Item" then
        if self._NewCharmID > 0 then
            local item_temp = CElementData.GetItemTemplate(self._NewCharmID)
            if item_temp ~= nil then
                CItemTipMan.ShowItemTips(self._NewCharmID, TipsPopFrom.OTHER_PANEL, self._PanelObject._Img_ItemIcon, TipPosition.FIX_POSITION)
            end
        end
    elseif id == "Btn_OK" then
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:StopGfxBg()
    self:StopGfx()
    self._NewCharmID = 0
    self._Mat1 = 0
    self._Mat2 = 0
end

def.override().OnDestroy = function(self)
    self._PanelObject = nil
end

CPanelCharmComposeResult.Commit()
return CPanelCharmComposeResult

