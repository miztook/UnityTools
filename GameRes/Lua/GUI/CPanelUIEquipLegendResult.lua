local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"

local CPanelUIEquipLegendResult = Lplus.Extend(CPanelBase, 'CPanelUIEquipLegendResult')
local def = CPanelUIEquipLegendResult.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._ItemData = nil
def.field("number")._PackageType = 0
def.field("number")._CounterTimer = 0 
def.field("number")._CounterNum = 0
def.field("number")._CounterMax = 5
def.field("boolean")._ShowGfx = true

----------------------------------------------------------------------------------
--                                特效处理 Begin
----------------------------------------------------------------------------------
def.field("table")._GfxObjectGroup = BlankTable
local gfxGroupName = "LegendResult"

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
    root.GfxLegendNewHook = self:GetUIObject("Group_LegendNew")

    root.GfxLegendNew = PATH.UI_Legend_New
    root.GfxBg1 = PATH.ETC_Fortify_Success_BG1
    root.GfxBg2 = PATH.ETC_Fortify_Success_BG2
    -- root.GfxBg1 = PATH.ETC_Legend_Result_BG1
    -- root.GfxBg2 = PATH.ETC_Legend_Result_BG2
end

-- 播放背景特效
def.method().PlayGfxBg = function(self)
    local root = self._GfxObjectGroup
    GameUtil.PlayUISfx(root.GfxBg1, root.GfxBgHook1, root.GfxBgHook1, -1)
    GameUtil.PlayUISfx(root.GfxBg2, root.GfxBgHook2, root.GfxBgHook2, -1, 20, 1)
end
-- 关闭背景特效
def.method().StopGfxBg = function(self)
    local root = self._GfxObjectGroup
    GameUtil.StopUISfx(root.GfxBg1, root.GfxBgHook1)
    GameUtil.StopUISfx(root.GfxBg2, root.GfxBgHook2)
end
-- 播放特效
def.method().PlayGfx = function(self)
    local root = self._GfxObjectGroup
    if self._ShowGfx then
        GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1, 20 , 3)
    end

    self:AddEvt_PlayFx(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 1, root.GfxLegendNew, root.GfxLegendNewHook, root.GfxLegendNewHook, -1, 1)
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
def.static('=>', CPanelUIEquipLegendResult).Instance = function ()
    if not instance then
        instance = CPanelUIEquipLegendResult()
        instance._PrefabPath = PATH.UI_EquipLegendResult
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
        LegendOld = {},
        LegendNew = {},
        Lab_Next = self:GetUIObject("Lab_Next"),
        Btn_ChangeAgain = self:GetUIObject("Btn_ChangeAgain"),
        Btn_Save = self:GetUIObject('Btn_Save'),
        Btn_Cancel = self:GetUIObject('Btn_Cancel'),
    }

    do
        local LegendOld = self._PanelObject.LegendOld
        LegendOld.Root = self:GetUIObject('Group_LegendOld')
        LegendOld.Name = LegendOld.Root:FindChild("Group_Skill/Group/Lab_Legend")
        LegendOld.Level = LegendOld.Root:FindChild("Group_Skill/Group/Lab_LegendLv")
        LegendOld.Desc = LegendOld.Root:FindChild("Group_Skill/Lab_LegendDesc")
    end

    do
        local LegendNew = self._PanelObject.LegendNew
        LegendNew.Root = self:GetUIObject('Group_LegendNew')
        LegendNew.Level = LegendNew.Root:FindChild("Group_Skill/Group/Lab_LegendLv")
        LegendNew.Name = LegendNew.Root:FindChild("Group_Skill/Group/Lab_Legend")
        LegendNew.Desc = LegendNew.Root:FindChild("Group_Skill/Lab_LegendDesc")
    end
end

local function SetClickType()
    instance._PanelCloseType = EnumDef.PanelCloseType.ClickAnyWhere
end
local function PlayAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Succees, 0)
end
local function BtnActive()
    instance._PanelObject.Btn_Save:SetActive(true)
    instance._PanelObject.Btn_Cancel:SetActive(true)
    instance._PanelObject.Btn_ChangeAgain:SetActive(true)
    instance:UpdateBtnChangeState()
end
def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._PackageType = data.PackageType
            self._ItemData = data.ItemData
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
    self:AddEvt_LuaCB(gfxGroupName, self._ShowGfx and 1.8 or 0, PlayAudio)
    -- self:StartCounter()
    local root = self._PanelObject
    root.Btn_Save:SetActive(false)
    root.Btn_Cancel:SetActive(false)
    root.Btn_ChangeAgain:SetActive(false)
    self:AddEvt_LuaCB(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 0.65, BtnActive)
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
        [EItemIconTag.StrengthLv] = self._ItemData._InforceLevel,
        [EItemIconTag.Bind] = true,
    }
    IconTools.InitItemIconNew(root.SelectItem, self._ItemData._Tid, setting)

    do
        local LegendOld = self._PanelObject.LegendOld
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(self._ItemData._TalentId, self._ItemData._TalentLevel, true)

        local strLv = string.format(StringTable.Get(10641), talentInfo.Level)
        GUI.SetText(LegendOld.Level, strLv)
        GUI.SetText(LegendOld.Name, talentInfo.Name)
        GUI.SetText(LegendOld.Desc, talentInfo.Desc)
    end

    do
        local LegendNew = self._PanelObject.LegendNew
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(self._ItemData._TalentIdCache, self._ItemData._TalentLevelCache, true)
        
        local strLv = string.format(StringTable.Get(10641), talentInfo.Level)
        GUI.SetText(LegendNew.Level, strLv)
        GUI.SetText(LegendNew.Name, talentInfo.Name)
        GUI.SetText(LegendNew.Desc, talentInfo.Desc)
    end

    self:UpdateBtnChangeState()
end

def.method().UpdateBtnChangeState = function(self)
    local bCanChange = self:CheckCanChange()
    GUITools.SetBtnGray(self._PanelObject.Btn_ChangeAgain, not bCanChange)
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == 'Btn_Save' then
        CEquipUtility.SendC2SItemTalentChangeConfirm(self._PackageType, self._ItemData._Slot, true)
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Cancel' then
        CEquipUtility.SendC2SItemTalentChangeConfirm(self._PackageType, self._ItemData._Slot, false)
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_ChangeAgain' then
        self:OnClickChangeAgain()
    end
    CPanelBase.OnClick(self, id)
end

def.method().OnClickChangeAgain = function(self)
    local function Do( ret )
        if ret then
            CEquipUtility.SendC2SItemTalentChange(self._PackageType, self._ItemData._Slot)
        end
    end

    local MoneyNeedInfo = CEquipUtility.GetEquipChangeMoneyNeedInfo(self._ItemData)
    MsgBox.ShowQuickBuyBox(MoneyNeedInfo[1], MoneyNeedInfo[2], Do)
end

def.method("=>","boolean").CheckCanChange = function(self)
    local bRet = false
    local ChangeNeedInfo = CEquipUtility.GetEquipChangeNeedInfo(self._ItemData)
    bRet = ChangeNeedInfo.MaterialHave >= ChangeNeedInfo.MaterialNeed

    if bRet then
        local hp = game._HostPlayer
        local MoneyNeedInfo = CEquipUtility.GetEquipRecastMoneyNeedInfo(self._ItemData)
        local moneyHave = hp:GetMoneyCountByType(MoneyNeedInfo[1])
        local moneyNeed = MoneyNeedInfo[2]
        bRet = bRet and (moneyHave >= moneyNeed)
    end

    return bRet
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

CPanelUIEquipLegendResult.Commit()
return CPanelUIEquipLegendResult