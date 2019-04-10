local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"

local CPanelUIEquipInheritResult = Lplus.Extend(CPanelBase, 'CPanelUIEquipInheritResult')
local def = CPanelUIEquipInheritResult.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._ItemDataOld = nil
def.field("table")._ItemDataNew = nil
def.field("number")._CounterTimer = 0 
def.field("number")._CounterNum = 0
def.field("number")._CounterMax = 5
def.field("boolean")._ShowGfx = true

----------------------------------------------------------------------------------
--                                特效处理 Begin
----------------------------------------------------------------------------------
def.field("table")._GfxObjectGroup = BlankTable
local gfxGroupName = "InheritResult"

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = "2"
    root.DoTweenTimeDelay = 1.8
    root.TweenObjectHook = self:GetUIObject("SelectItem")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.TweenTimerId = 0

    root.GfxHook = self._Panel
    root.GfxTimeDelay = 0
    root.Gfx = PATH.ETC_Legend_juqi
    root.GfxTimerId = 0

    root.GfxBgHook1 = self:GetUIObject("SelectItem")
    root.GfxBgHook2 = self._Panel

    -- root.GfxBg1 = PATH.ETC_Legend_Result_BG1
    -- root.GfxBg2 = PATH.ETC_Legend_Result_BG2
    root.GfxBg1 = PATH.ETC_Fortify_Success_BG1
    root.GfxBg2 = PATH.ETC_Fortify_Success_BG2
end

-- 播放背景特效
def.method().PlayGfxBg = function(self)
    local root = self._GfxObjectGroup
    self:AddEvt_PlayFx(gfxGroupName, 1.8, root.GfxBg1, root.GfxBgHook1, root.GfxBgHook1, -1, 1)
    self:AddEvt_PlayFx(gfxGroupName, 1.8, root.GfxBg2, root.GfxBgHook2, root.GfxBgHook2, -1, 1)
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

    self:AddEvt_SetActive(gfxGroupName, self._ShowGfx and 1.8 or 0, self._Panel:FindChild("Img_PanelBG"), true)
    self:AddEvt_PlayDotween(gfxGroupName, self._ShowGfx and 1.8 or 0, root.DoTweenPlayer, root.TweenGroupId)
    self:AddEvt_Shake(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 0.5, 15, 0.05)
end
-- 关闭特效
def.method().StopGfx = function(self)
    local root = self._GfxObjectGroup
    GameUtil.StopUISfx(root.Gfx, root.GfxHook)
end
-- 重置 组件和位置信息
def.method().ResetGfxGroup = function(self)
    local root = self._GfxObjectGroup
    root.GfxHook.localPosition = root.OrignPosition
end

def.method().GfxLogic = function(self)
    local root = self._GfxObjectGroup
    self._Panel:FindChild("Img_PanelBG"):SetActive( false )
    self:PlayGfx()
end

----------------------------------------------------------------------------------
--                                特效处理 End
----------------------------------------------------------------------------------


local instance = nil
def.static('=>', CPanelUIEquipInheritResult).Instance = function ()
    if not instance then
        instance = CPanelUIEquipInheritResult()
        instance._PrefabPath = PATH.UI_EquipInheritResult
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)
    self._PanelObject = 
    {
        SelectItem = self:GetUIObject('SelectItem'),
        Reinforce = {},
        Property = {},
        Lab_Next = self:GetUIObject("Lab_Next"),
        Btn_OK = self:GetUIObject('Btn_OK'),
    }

    do
        local Reinforce = self._PanelObject.Reinforce
        Reinforce.Root = self:GetUIObject('Img_Inherit_Reinforce')
        Reinforce.Name = self:GetUIObject('Lab_InheritedReinforceName')
        Reinforce.Old = self:GetUIObject('Lab_InheritedReinforceOldValue')
        Reinforce.New = self:GetUIObject('Lab_InheritedReinforceNewValue')
        Reinforce.Img_UpOrDown = self:GetUIObject('Img_Reinforce_UpOrDown')
    end

    do
        local Property = self._PanelObject.Property
        Property.Root = self:GetUIObject('Img_Inherit_Property')
        Property.Name = self:GetUIObject("Lab_InheritedPropertyName")
        Property.Old = self:GetUIObject("Lab_InheritedPropertyOldValue")
        Property.New = self:GetUIObject("Lab_InheritedPropertyNewValue")
        Property.Img_UpOrDown = self:GetUIObject('Img_Property_UpOrDown')
    end
end

local function SetClickType()
    instance._PanelCloseType = EnumDef.PanelCloseType.ClickAnyWhere
end
local function PlayAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Succees, 0)
end
local function BtnActice()
    instance._PanelObject.Btn_OK:SetActive(true)
end
def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._ItemDataNew = data.New
            self._ItemDataOld = data.Old
            self._ShowGfx = data.ShowGfx
        end

        CPanelBase.OnData(self,data)
    end

    -- 初始化特效所需组件信息
    self:InitGfxGroup()
    -- 更新UI组件
    self:UpdateUI()
    -- 特效逻辑
    self:GfxLogic()
    -- 播放背景特效
    self:PlayGfxBg()

    self:AddEvt_LuaCB(gfxGroupName, self._CounterMax, SetClickType)
    self:AddEvt_LuaCB(gfxGroupName, self._ShowGfx and 1.8 or 0, PlayAudio)
    -- self:StartCounter()
    self._PanelObject.Btn_OK:SetActive(false)
    self:AddEvt_LuaCB(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 0.65, BtnActice)
end
local function CounterTick(self)
    if instance:IsShow() then
        instance._CounterNum = instance._CounterNum - 1

        if instance._CounterNum <= 0 then
            local str = StringTable.Get(31607)
            GUI.SetText(instance._PanelObject.Lab_Next, str)
            instance:StopCounter()
        else
            local str = string.format(StringTable.Get(31606), instance._CounterNum)
            GUI.SetText(instance._PanelObject.Lab_Next, str)
        end
    end
end
def.method().StartCounter = function(self)
    self:StopCounter()
    self._CounterNum = self._CounterMax + 1
    self._CounterTimer = _G.AddGlobalTimer(1, false, CounterTick)
end
def.method().StopCounter = function(self)
    if self._CounterTimer > 0 then
        _G.RemoveGlobalTimer(self._CounterTimer)
    end    
end
def.method().UpdateUI = function(self)
    local root = self._PanelObject

    local setting =
    {
        [EItemIconTag.StrengthLv] = self._ItemDataNew.InforceLevel,
        [EItemIconTag.Bind] = self._ItemDataNew.IsBind,
    }
    IconTools.InitItemIconNew(root.SelectItem, self._ItemDataNew.Tid, setting)

    do
        local Reinforce = self._PanelObject.Reinforce
        GUI.SetText(Reinforce.Name, StringTable.Get(152))
        local oldLv = self._ItemDataOld.InforceLevel
        local newLv = self._ItemDataNew.InforceLevel

        GUI.SetText(Reinforce.Old, tostring(oldLv))
        GUI.SetText(Reinforce.New, tostring(newLv))

        local bShow = newLv ~= oldLv
        Reinforce.Img_UpOrDown:SetActive( bShow )
        if bShow then
            GUITools.SetGroupImg(Reinforce.Img_UpOrDown, newLv > oldLv and 1 or 0)
        end
    end

    do
        local Property = self._PanelObject.Property
        local propertyGeneratorElement = CElementData.GetAttachedPropertyGeneratorTemplate( self._ItemDataOld.FightProperty.index )
        local fightElement = CElementData.GetAttachedPropertyTemplate( propertyGeneratorElement.FightPropertyId )

        GUI.SetText(Property.Name, fightElement.TextDisplayName)

        local oldVal = 0
        local newVal = 0
        do
        -- 旧属性
            local itemData = self._ItemDataOld
            local template = CElementData.GetTemplate("Item", itemData.Tid)
            local baseVal = itemData.FightProperty.value
            local curVal = baseVal
            local lv = itemData.InforceLevel
            if lv > 0 then
                local InforceInfo = CEquipUtility.GetInforceInfoByLevel(template.ReinforceConfigId, lv)
                local fixedIncVal = math.ceil(baseVal * InforceInfo.InforeValue / 100)
                curVal = baseVal + math.max(fixedIncVal, lv)
            end
            GUI.SetText(Property.Old, GUITools.FormatNumber(curVal))
            oldVal = curVal
        end
        do
        -- 新属性
            local itemData = self._ItemDataNew
            local template = CElementData.GetTemplate("Item", itemData.Tid)
            local baseVal = itemData.FightProperty.value
            local curVal = baseVal
            local lv = itemData.InforceLevel
            if lv > 0 then
                local InforceInfo = CEquipUtility.GetInforceInfoByLevel(template.ReinforceConfigId, lv)
                local fixedIncVal = math.ceil(baseVal * InforceInfo.InforeValue / 100)
                curVal = baseVal + math.max(fixedIncVal, lv)
            end
            GUI.SetText(Property.New, GUITools.FormatNumber(curVal))
            newVal = curVal
        end

        local bShow = newVal ~= oldVal
        Property.Img_UpOrDown:SetActive( bShow )
        if bShow then
            GUITools.SetGroupImg(Property.Img_UpOrDown, newVal > oldVal and 1 or 0)
        end
    end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_OK" then
        game._GUIMan:CloseByScript(self)
    end
    CPanelBase.OnClick(self, id)
end

def.override().OnHide = function(self)
    self:StopCounter()
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    self:StopGfx()
    self:StopGfxBg()
    instance = nil
end

CPanelUIEquipInheritResult.Commit()
return CPanelUIEquipInheritResult