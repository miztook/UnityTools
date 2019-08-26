local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"

local CPanelUIEquipFortityResult = Lplus.Extend(CPanelBase, 'CPanelUIEquipFortityResult')
local def = CPanelUIEquipFortityResult.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._ItemDataOld = nil
def.field("table")._ItemDataNew = nil
def.field("boolean")._Succees = false
def.field("boolean")._Restitution = false
def.field("number")._CounterTimer = 0 
def.field("number")._CounterNum = 0
def.field("number")._CounterMax = 5
def.field("boolean")._ShowGfx = true

----------------------------------------------------------------------------------
--                                特效处理 Begin
----------------------------------------------------------------------------------
def.field("table")._GfxObjectGroup = BlankTable
local gfxGroupName = "FortityResult"

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup
    root.DoTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = "2"
    root.TweenObjectHook = self:GetUIObject("SelectItem")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.OrignRotation = root.TweenObjectHook.localRotation
    root.GfxHook = self._Panel
    root.Gfx = PATH.ETC_Fortify_juqi
    root.GfxBgHook1 = self:GetUIObject("SelectItem")
    root.GfxBgHook2 = self._Panel
    if self._Succees then
        root.GfxBg1 = PATH.ETC_Fortify_Success_BG1
        root.GfxBg2 = PATH.ETC_Fortify_Success_BG2
    else
        root.GfxBg1 = PATH.ETC_Fortify_Failed_BG1
        root.GfxBg2 = PATH.ETC_Fortify_Failed_BG2
    end
end

-- 播放背景特效
def.method().PlayGfxBg = function(self)
    local root = self._GfxObjectGroup
    self:AddEvt_PlayFx(gfxGroupName, self._ShowGfx and 1.8 or 0, root.GfxBg1, root.GfxBgHook1, root.GfxBgHook1, -1, self._Succees and 2 or -1)
    self:AddEvt_PlayFx(gfxGroupName, self._ShowGfx and 1.8 or 0, root.GfxBg2, root.GfxBgHook2, root.GfxBgHook2, -1, self._Succees and 2 or -1)
end
-- 关闭背景特效
def.method().StopGfxBg = function(self)
    self:KillEvts(gfxGroupName)
end

-- 播放特效
def.method().PlayGfx = function(self)
    local root = self._GfxObjectGroup
    if self._ShowGfx then
        self:AddEvt_PlayFx(gfxGroupName, 0, root.Gfx, root.GfxHook, root.GfxHook, -1, 3)
    end
    self:AddEvt_SetActive(gfxGroupName, self._ShowGfx and 1.8 or 0, self._Panel:FindChild("Img_BG"), true)
    self:AddEvt_SetActive(gfxGroupName, self._ShowGfx and 1.8 or 0, self:GetUIObject("Img_ShowGroup"), true)
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
    root.GfxHook.localPosition.localRotation = root.OrignRotation
end

def.method().GfxLogic = function(self)
    local root = self._GfxObjectGroup

    self._Panel:FindChild("Img_BG"):SetActive( false )
    self:GetUIObject("Img_ShowGroup"):SetActive( false )
    self:PlayGfx()
end

----------------------------------------------------------------------------------
--                                特效处理 End
----------------------------------------------------------------------------------


local instance = nil
def.static('=>', CPanelUIEquipFortityResult).Instance = function ()
    if not instance then
        instance = CPanelUIEquipFortityResult()
        instance._PrefabPath = PATH.UI_EquipFortityResult
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
        Lab_Success = self:GetUIObject('Lab_Success'),
        Lab_Failed = self:GetUIObject('Lab_Failed'),
        Lab_EquipName = self:GetUIObject('Lab_EquipName'),
        Frame_EquipIcon = self:GetUIObject('Frame_EquipIcon'),
        Img_ResultTitle = self:GetUIObject('Img_ResultTitle'),
        Lab_Restitution = self:GetUIObject('Lab_Restitution'),
        AttributeInfo = {},
        PVPAttributeInfo = {},
        AttrChangeInfo = {},
        Lab_Next = self:GetUIObject("Lab_Next"),
        Btn_OK = self:GetUIObject('Btn_OK'),
    }

    do
        local AttributeInfo = self._PanelObject.AttributeInfo
        AttributeInfo.Name = self:GetUIObject('Lab_AttributeName')
        AttributeInfo.New = self:GetUIObject('Lab_PropertyNew')
        AttributeInfo.Old = self:GetUIObject('Lab_PropertyOld')
    end

    do
        local PVPAttributeInfo = self._PanelObject.PVPAttributeInfo
        PVPAttributeInfo.Root = self:GetUIObject("PVP_Property")
        PVPAttributeInfo.Name = self:GetUIObject('Lab_PVPAttributeName')
        PVPAttributeInfo.New = self:GetUIObject('Lab_PVPPropertyNew')
        PVPAttributeInfo.Old = self:GetUIObject('Lab_PVPPropertyOld')
    end

    do
        local AttrChangeInfo = self._PanelObject.AttrChangeInfo
        AttrChangeInfo.Root = self:GetUIObject('AttrChange_Group')
        AttrChangeInfo.New = self:GetUIObject('Lab_AttrNew')
        AttrChangeInfo.Old = self:GetUIObject('Lab_AttrOld')
    end
end

local function SetClickType()
    instance._PanelCloseType = EnumDef.PanelCloseType.ClickAnyWhere
end
local function PlaySuccessAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Succees, 0)
end
local function PlayFailedAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Failed, 0)
end
local function BtnActice()
    instance._PanelObject.Btn_OK:SetActive(true)
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._ItemDataNew = data.New
            self._ItemDataOld = data.Old
            self._Succees = data.Success
            self._Restitution = data.Restitution
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

    -- self:AddEvt_LuaCB(gfxGroupName, self._CounterMax, SetClickType)
    if instance._Succees then
        self:AddEvt_LuaCB(gfxGroupName, self._ShowGfx and 1.8 or 0, PlaySuccessAudio)
    else
        self:AddEvt_LuaCB(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 0.5, PlayFailedAudio)
    end

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
    local bHasPVP = self._ItemDataNew.PVPFightProperty.index > 0

    local setting =
    {
        [EItemIconTag.StrengthLv] = self._ItemDataNew.InforceLevel,
        [EItemIconTag.Bind] = true,
        [EItemIconTag.Grade] = self._ItemDataNew.FightProperty.star or -1,
    }
    IconTools.InitItemIconNew(root.SelectItem, self._ItemDataOld._Tid, setting)

    root.PVPAttributeInfo.Root:SetActive( bHasPVP )
    root.Lab_Success:SetActive(self._Succees)
    root.Lab_Failed:SetActive(not self._Succees)
    GUITools.SetGroupImg(root.Img_ResultTitle, self._Succees and 0 or 1)

    GUI.SetText(root.Lab_EquipName, self._ItemDataOld:GetNameText())

    local AttributeInfo = root.AttributeInfo
    local PVPAttributeInfo = root.PVPAttributeInfo
    local fightElement = CElementData.GetAttachedPropertyTemplate(self._ItemDataOld._BaseAttrs.ID)
    GUI.SetText(AttributeInfo.Name, fightElement.TextDisplayName)
    if bHasPVP then
        local pvpData = CElementData.GetAttachedPropertyTemplate(self._ItemDataOld._PVPFightProperty.ID)
        GUI.SetText(PVPAttributeInfo.Name, pvpData.TextDisplayName)
    end


    local curLv = self._ItemDataOld._InforceLevel
    local newLv = self._ItemDataNew.InforceLevel
    local baseVal = self._ItemDataOld._BaseAttrs.Value
    local basvPVPVal = bHasPVP and self._ItemDataOld._PVPFightProperty.Value or 0

    local nextVal = baseVal
    local nextPVPVal = basvPVPVal
    local InforceInfoNew = CEquipUtility.GetInforceInfoByLevel(self._ItemDataOld._ReinforceConfigId, newLv)
    if InforceInfoNew ~= nil then
        local fixedIncVal = math.ceil(baseVal * InforceInfoNew.InforeValue / 100)
        local fixedPVPIncVal = bHasPVP and math.ceil(baseVal * InforceInfoNew.InforeValue / 100) or 0
        nextVal = baseVal + math.max(fixedIncVal, newLv)
        nextPVPVal = bHasPVP and basvPVPVal +  math.max(fixedPVPIncVal, newLv) or 0
    end

    local curVal = baseVal
    local curPVPVal = basvPVPVal
    local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(self._ItemDataOld._ReinforceConfigId, curLv)
    if InforceInfoOld ~= nil then
        local fixedIncVal = math.ceil(baseVal * InforceInfoOld.InforeValue / 100)
        local fixedPVPIncVal = math.ceil(baseVal * InforceInfoOld.InforeValue / 100)

        curVal = baseVal + math.max(fixedIncVal, curLv)
        curPVPVal = bHasPVP and basvPVPVal + math.max(fixedPVPIncVal, curLv)
    end

    local processStatus = curLv == newLv and EnumDef.EquipProcessStatus.None or
                          ((curLv < newLv) and EnumDef.EquipProcessStatus.Success or EnumDef.EquipProcessStatus.Failed)

    GUI.SetText(AttributeInfo.New, RichTextTools.GetEquipProcessColorText(GUITools.FormatNumber(nextVal), processStatus))
    GUI.SetText(AttributeInfo.Old, GUITools.FormatNumber(curVal))
    if bHasPVP then
        GUI.SetText(PVPAttributeInfo.New, RichTextTools.GetEquipProcessColorText(GUITools.FormatNumber(nextPVPVal), processStatus))
        GUI.SetText(PVPAttributeInfo.Old, GUITools.FormatNumber(curPVPVal))
    end

    local AttrChangeInfo = self._PanelObject.AttrChangeInfo
    GUI.SetText(AttrChangeInfo.New, RichTextTools.GetEquipProcessColorText(string.format(StringTable.Get(10973), newLv), processStatus))
    GUI.SetText(AttrChangeInfo.Old, string.format(StringTable.Get(10973), curLv))

    local bActive = self._Restitution~=nil and curLv > newLv
    -- 返还逻辑
    root.Lab_Restitution:SetActive( bActive )
    if bActive then
        local restitutionId = InforceInfoOld.RefundItemId
        local restitutionCount = InforceInfoOld.RefundItemCount
        local bShow = restitutionId > 0 and restitutionCount > 0
        root.Lab_Restitution:SetActive( bShow )
        if bShow then
            local restitutionTemplate = CElementData.GetTemplate("Item", restitutionId)
            local restitutionName = RichTextTools.GetQualityText(restitutionTemplate.TextDisplayName, restitutionTemplate.InitQuality)
            GUI.SetText(root.Lab_Restitution, string.format(StringTable.Get(10972), restitutionName, restitutionCount))
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
    self:KillEvts(gfxGroupName)
end

def.override().OnDestroy = function(self)
    --self:StopDotween()
    self:StopGfx()
    self:StopGfxBg()
    instance = nil
end

CPanelUIEquipFortityResult.Commit()
return CPanelUIEquipFortityResult