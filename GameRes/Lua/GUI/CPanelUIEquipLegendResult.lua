local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelUIEquipLegendResult = Lplus.Extend(CPanelBase, 'CPanelUIEquipLegendResult')
local def = CPanelUIEquipLegendResult.define

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
        Btn_OK = self:GetUIObject('Btn_OK'),
    }

    do
        local LegendOld = self._PanelObject.LegendOld
        LegendOld.Root = self:GetUIObject('Group_LegendOld')
        LegendOld.Name = LegendOld.Root:FindChild("Lab_Legend")
        LegendOld.Desc = LegendOld.Root:FindChild("Lab_LegendDesc")
    end

    do
        local LegendNew = self._PanelObject.LegendNew
        LegendNew.Root = self:GetUIObject('Group_LegendNew')
        LegendNew.Name = LegendNew.Root:FindChild("Lab_Legend")
        LegendNew.Desc = LegendNew.Root:FindChild("Lab_LegendDesc")
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
    IconTools.InitItemIconNew(root.SelectItem, self._ItemDataOld._Tid, setting)

    do
        local LegendOld = self._PanelObject.LegendOld
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(self._ItemDataOld._TalentId, self._ItemDataOld._TalentLevel, true)
        GUI.SetText(LegendOld.Name, talentInfo.Name)
        GUI.SetText(LegendOld.Desc, talentInfo.Desc)
    end

    do
        local LegendNew = self._PanelObject.LegendNew
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(self._ItemDataNew.TalentId, self._ItemDataNew.TalentLevel, true)
        GUI.SetText(LegendNew.Name, talentInfo.Name)
        GUI.SetText(LegendNew.Desc, talentInfo.Desc)
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

CPanelUIEquipLegendResult.Commit()
return CPanelUIEquipLegendResult