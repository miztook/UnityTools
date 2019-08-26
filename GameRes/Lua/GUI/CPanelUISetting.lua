-- 系统设置
-- 时间：2017/10/10

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local bit = require "bit"
local UserData = require "Data.UserData".Instance()
local CGame = Lplus.ForwardDeclare("CGame")
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local QualitySettingMan = require "Main.QualitySettingMan"
local CElementData = require "Data.CElementData"
local EParmType = require "PB.Template".ItemApproach.EParmType


local CPanelUISetting = Lplus.Extend(CPanelBase, "CPanelUISetting")
local def = CPanelUISetting.define

def.field("table")._PanelObjects = BlankTable
def.field("table")._LanguageList = BlankTable
def.field("table")._LanguageTextList = BlankTable
def.field("string")._OriginLanguageCode = ""
def.field("boolean")._IsShowLanguage = false
def.field("boolean")._IgnoreClick = false
def.field("boolean")._IsScriptToggle = false
def.field("boolean")._IsScriptSlider = false
--基础设置
def.field("number")._FrameRate = 30                 -- 帧率
def.field("boolean")._IsOpenPlayerPush = false      -- 是否接收推送
def.field("boolean")._IsOpenNightPush = false       -- 是否接收夜间推送
def.field("number")._MaxPlayersInScreen = _G.MAX_VISIBLE_PLAYER
def.field("number")._BGMVolume = 0                  -- 背景音乐
def.field("number")._SoundVolume = 0                -- 音效
def.field("number")._OrigBGMVolume = 0              -- 背景音乐
def.field("number")._OrigSoundVolume = 0            -- 音效
def.field("number")._DataPage = -1                  -- 外部传到界面的data
def.field("boolean")._IsEnablePowerSaving = false   -- 是否开启省电模式
def.field("number")._PowerSavingIndex = 1           -- 省点模式Index
def.field("boolean")._IsClickGroundMove = true      -- 是否开启点地面移动
def.field("boolean")._IsShowHeadInfo = true         -- 是否显示头顶信息
def.field("boolean")._IsBossLensLock = false        -- 是否开启Boss镜头锁定
def.field("boolean")._IsPvpLensLock = false         -- 是否开启PVP镜头锁定

--渲染设置
def.field("number")._WholeQualityLevel = 0          -- 总体质量等级
def.field("number")._ShadowLevel = 0                -- 阴影效果等级
def.field("number")._PostProcessLevel = 0           -- 后处理效果等级
def.field("number")._SceneDetialLevel = 0           -- 场景细节等级
def.field("number")._FXLevel = 0                    -- 特效品质
def.field("number")._RoleModelLevel = 0             -- 角色效果等级
--def.field("boolean")._IsHighEffectOn = true         -- 高级特效效果开启？
def.field("boolean")._IsFogOn = true                -- 雾效果开启？
--def.field("boolean")._IsSnowRainOn = true           -- 全局天气特效开启？
--def.field("boolean")._IsFootEffectOn = true         -- 角色脚部特效开启？
--def.field("boolean")._IsDetailSoundOn = true        -- 细节音效开启？
def.field("boolean")._IsDepthOfFocus = true         -- 景深效果开启？
def.field("boolean")._IsWaterReflect = true         -- 水面反射效果开启？
--def.field("boolean")._IsHighFrame = true            -- 开启高帧率？
--战斗设置
def.field("boolean")._IsMedicalAutoUse = true       -- 药水自动使用开启？
def.field("boolean")._IsDrugSortBuyHigh = true       -- 药水自动使用低等级还是高等级
def.field("number")._HPMinNumber = 0                -- 最低使用药水的HP百分比（0-100）
def.field("table")._UserSkillMap = nil              -- 目前学习的技能（用于自动化战斗时是否释放）
def.field("boolean")._IsAnyChange = false           -- 任何一个设置变化了，就需要saveFile

local instance = nil
def.static("=>", CPanelUISetting).Instance = function()
    if not instance then
        instance = CPanelUISetting()
        instance._DestroyOnHide = true
        instance._ClickInterval = 0.2
        instance._PrefabPath = PATH.UI_Setting
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects._RdoGroup_Menu = self:GetUIObject("Rdo_MenuGroup")
    local bgmSld = self:GetUIObject("Sld_BGM")
    local effectSoundSld = self:GetUIObject("Sld_EffectSound")
    local hpMinSld = self:GetUIObject("Sld_HPMinValue")
    self._PanelObjects._Rdo_RenderSetting = self:GetUIObject("Rdo_RenderSetting"):GetComponent(ClassType.Toggle)
    self._PanelObjects._Rdo_Setting = self:GetUIObject("Rdo_Setting"):GetComponent(ClassType.Toggle)
    self._PanelObjects._Rdo_BattleSetting = self:GetUIObject("Rdo_BattleSetting"):GetComponent(ClassType.Toggle)
    self._PanelObjects._Rdo_AccountSetting = self:GetUIObject("Rdo_AccountSetting"):GetComponent(ClassType.Toggle)
    self._PanelObjects._Frame_RenderSetting = self:GetUIObject("Frame_RenderSetting")
    self._PanelObjects._Frame_Setting = self:GetUIObject("Frame_Setting")
    self._PanelObjects._Frame_BattleSetting = self:GetUIObject("Frame_BattleSetting")
    self._PanelObjects._Frame_AccountSetting = self:GetUIObject("Frame_AccountSetting")
    -- 基础设置
    self._PanelObjects._RdoGroup_PersonNum = self:GetUIObject("Group_PersonNum")
    self._PanelObjects._Sld_BGM = bgmSld:GetComponent(ClassType.Slider)
    self._PanelObjects._Sld_EffectSound = effectSoundSld:GetComponent(ClassType.Slider)
    self._PanelObjects._Lab_BGMVal = self:GetUIObject("Lab_BGMVal")
    self._PanelObjects._Lab_EffectSoundVal = self:GetUIObject("Lab_EffectSoundVal")
    self._PanelObjects._RdoGroup_PlayerPush = self:GetUIObject("Group_PlayerPush")
    self._PanelObjects._RdoGroup_NightPush = self:GetUIObject("Group_NightPush")
    self._PanelObjects._RdoGroup_ClickGroundMove = self:GetUIObject("Group_ClickGroud")
    self._PanelObjects._RdoGroup_PowerSaving = self:GetUIObject("Group_Power")
    self._PanelObjects._RdoGroup_HeadInfo = self:GetUIObject("Group_HeadInfo")
    self._PanelObjects._RdoGroup_SkillRecover = self:GetUIObject("Group_Camera_SkillRecover")
    self._PanelObjects._Drop_Language = self:GetUIObject("Drop_Language")
    self._PanelObjects._Img_BGM = self:GetUIObject("Img_BGM")
    self._PanelObjects._Img_EffectSound = self:GetUIObject("Img_EffectSound")
    self._PanelObjects._Drop_Language:SetActive(game._MiscSetting:IsShowLanguageChange())

    --渲染设置
    self._PanelObjects._RdoGroup_MainControl = self:GetUIObject("Rdo_MainControlGroup")
    self._PanelObjects._RdoGroup_PostProcess = self:GetUIObject("Rdo_PostProcessGroup")
    self._PanelObjects._RdoGroup_ShadowLevel = self:GetUIObject("Rdo_ShadowLevelGroup")
    self._PanelObjects._RdoGroup_SceneDetail = self:GetUIObject("Rdo_BGGroup")
    self._PanelObjects._RdoGroup_FXLevel = self:GetUIObject("Rdo_FXLevelGroup")
    self._PanelObjects._RdoGroup_Shader_Level = self:GetUIObject("Rdo_ShaderLodLevel")
    self._PanelObjects._RdoGroup_RoleModel = self:GetUIObject("Rdo_RoleModelGroup")
    self._PanelObjects._RdoGroup_MipMap = self:GetUIObject("Rdo_MipMapGroup")
    --self._PanelObjects._Rdo_HighFX = self:GetUIObject("Rdo_HighFX"):GetComponent(ClassType.Toggle)
    --self._PanelObjects._Rdo_Weather = self:GetUIObject("Rdo_Weather")
    self._PanelObjects._RdoGroup_Fog = self:GetUIObject("Group_Fog")
    --self._PanelObjects._Rdo_FootFX = self:GetUIObject("Rdo_FootFX"):GetComponent(ClassType.Toggle)
    --self._PanelObjects._Rdo_DetailSound = self:GetUIObject("Rdo_DetailSound")
    self._PanelObjects._RdoGroup_FrameRate = self:GetUIObject("Rdo_FrameRateGroup")
    self._PanelObjects._RdoGroup_DepthOfFocus = self:GetUIObject("Group_DepthOfFocus")
    self._PanelObjects._RdoGroup_WaterReflect = self:GetUIObject("Group_WaterReflect")
    self._PanelObjects._Rdo_Frame_Rate3 = self:GetUIObject("Rdo_FrameRate_3")
    --self._PanelObjects._Rdo_HighFrame = self:GetUIObject("Rdo_HighFrame"):GetComponent(ClassType.Toggle)

    -- 战斗设置
    self._PanelObjects._Group_FightLock_PVE = self:GetUIObject("Group_FightLock_PVE")
    self._PanelObjects._Group_FightLock_PVP = self:GetUIObject("Group_FightLock_PVP")
    self._PanelObjects._Group_AutoUse = self:GetUIObject("Group_AutoUse")
    self._PanelObjects._Group_UseSort = self:GetUIObject("Group_UseSort")
    self._PanelObjects._Lab_HPMinVal = self:GetUIObject("Lab_HPMinVal")
    self._PanelObjects._Sld_HpMinVal = hpMinSld:GetComponent(ClassType.Slider)
    self._PanelObjects._Frame_Skill = self:GetUIObject("Frame_Skill")

    --账号设置
    self._PanelObjects._Input_UserID = self:GetUIObject("Input_UserID"):GetComponent(ClassType.InputField)
    self._PanelObjects._Btn_KakaoLogout = self:GetUIObject("Btn_Logout_Kakao")
    self._PanelObjects._Btn_GuestLogout = self:GetUIObject("Btn_Logout_Guest")
    self._PanelObjects._Btn_Account_Conversion = self:GetUIObject("Btn_Account_Conversion")
    self._PanelObjects._Btn_GoogleService = self:GetUIObject("Btn_GoogleService")
    self._PanelObjects._Lab_GoogleService = self:GetUIObject("Lab_GoogleService")
    self._PanelObjects._Btn_Account_Delete = self:GetUIObject("Btn_Account_Delete")
    self._PanelObjects._Btn_LongtuLogout = self:GetUIObject("Btn_Logout_Longtu")
    self._PanelObjects._Btn_3 = self:GetUIObject("Btn_3")
    self._PanelObjects._Btn_4 = self:GetUIObject("Btn_4")
    self._PanelObjects._Btn_5 = self:GetUIObject("Btn_5")
    self._PanelObjects._Btn_6 = self:GetUIObject("Btn_6")

    GUITools.RegisterSliderEventHandler(self._Panel, bgmSld)
    GUITools.RegisterSliderEventHandler(self._Panel, effectSoundSld)
    GUITools.RegisterSliderEventHandler(self._Panel, hpMinSld)
    --GameUtil.RegisterUIEventHandler(self._Panel, self._PanelObjects._Rdo_Weather, ClassType.GNewIOSToggle)
    --GameUtil.RegisterUIEventHandler(self._Panel, self._PanelObjects._Rdo_DetailSound, ClassType.GNewIOSToggle)
    -- 多语言
    self._LanguageList =
    {
        "CN",-- 简中
--      "TW",-- 繁中
--      "EN",-- 英语
        "KR",-- 韩语
    }
    self._LanguageTextList = 
    {
        19708,
--        19709,
--        19710,
        19711,
    }
    self._OriginLanguageCode = GameUtil.GetUserLanguageCode()
    self:SetDorpdownGroup()
end

local OnElseClick = function(sender, event)
    if instance._IgnoreClick then instance._IgnoreClick = false; return end
    if event._Param ~= nil and instance:IsShow() and event._Param == instance._Panel.name then
        --点击别的地方取消显示语言
        if instance._IsShowLanguage then
            instance._IsShowLanguage = not instance._IsShowLanguage
        end
    end
end

local OnPlatformSDKEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateKakaoAccountBtn()
    end
end

local HandleIOSToggleShow = function(iosToggleGO, isOn)
    local lab_on = iosToggleGO:FindChild("Lab_RdoOn")
    if lab_on ~= nil then
        lab_on:SetActive(isOn)
    end
    iosToggleGO:GetComponent(ClassType.GNewIOSToggle).Value = isOn
end

local PersonNumCfg = {6, 10, 15, 25}

local GetGroupIndexByPersonNum = function(personNum)
    for i,v in ipairs(PersonNumCfg) do
        if personNum == v then
            return i
        end
    end

    return 4
end

local GetNewPersonNumberByIndex = function(index)
    if index >= 1 and index <= 4 then
        return PersonNumCfg[index]
    end
    
    return _G.MAX_VISIBLE_PLAYER
end

local GetPowerSaveIndex = function(seconds)
    if seconds == 0 then
        return 1
    elseif seconds == 180 then
        return 2
    elseif seconds == 300 then
        return 3
    elseif seconds == 600 then
        return 4
    end
    return 1
end

local GetPowerSaveSeconds = function(index)
    if index == 1 then
        return 300
    elseif index == 2 then
        return 180
    elseif index == 3 then
        return 300
    elseif index == 4 then
        return 600
    end
    return 0
end


local InitSkillMap = function(self)
    self._UserSkillMap = {}
    local userSkillMap = game._HostPlayer._MainSkillIDList
    local userSkillState = game._HostPlayer._MainSkillLearnState
    for k, v in ipairs(userSkillMap) do
        if k ~= 1 and userSkillState[v] then
            local skill_is_forbid = UserData:GetField("UserSkillAuto"..v)
            local item = {}
            item._SkillID = v
            if skill_is_forbid ~= nil then
                item._IsOn = not skill_is_forbid
            else
                item._IsOn = true
            end
            self._UserSkillMap[#self._UserSkillMap + 1] = item
        end
    end
end


local SaveSkillMap = function(self)
    for i,v in ipairs(self._UserSkillMap) do
        if v ~= nil and v._IsOn ~= nil then
            UserData:SetField("UserSkillAuto"..v._SkillID, not v._IsOn)
        end
    end
end

local SelectForbidAutoSkill = function(self)
    local new_table = {}
    for i,v in ipairs(self._UserSkillMap) do
        if v ~= nil and not v._IsOn then
            new_table[#new_table + 1] = v._SkillID
        end
    end
    return new_table
end

local UpdateSkillUI = function(self)
    local uiTemplate = self._PanelObjects._Frame_Skill:GetComponent(ClassType.UITemplate)
    for i=1,7 do
        local rdo_skill = uiTemplate:GetControl(i-1)
        local skill_data = self._UserSkillMap[i]
        if skill_data then
            rdo_skill:SetActive(true)
            rdo_skill:GetComponent(ClassType.Toggle).isOn = self._UserSkillMap[i]._IsOn
            local skill_temp = CElementData.GetSkillTemplate(skill_data._SkillID)
            if skill_temp ~= nil then
                GUITools.SetSkillIcon(rdo_skill:FindChild("Img_BG"), skill_temp.IconName)
                GUITools.SetSkillIcon(rdo_skill:FindChild("Img_Open"), skill_temp.IconName)
            end
        else
            rdo_skill:SetActive(false)
        end
        GameUtil.MakeImageGray(rdo_skill:FindChild("Img_BG"), true)
    end
end

def.override("dynamic").OnData = function(self, data)
    self._HelpUrlType = HelpPageUrlType.Setting
    self._IsAnyChange = false
    self._IsScriptSlider = true
    if data ~= nil and type(data) == "number" then
        self._DataPage = data
    else
        self._DataPage = EnumDef.SettingPageType.BaseSetting
    end
    --技能信息数据初始化
    InitSkillMap(self)
    self:UpdateValues()
    self:UpdatePage()
    self:UpdateControlStates()
    self._IsScriptSlider = false
    CGame.EventManager:addHandler('NotifyClick', OnElseClick)
    CGame.EventManager:addHandler('PlatformSDKEvent', OnPlatformSDKEvent)
end

def.method().UpdatePage = function(self)
    if self._DataPage ~= -1 then
        if self._DataPage == EnumDef.SettingPageType.RenderSetting then
            self._PanelObjects._Rdo_RenderSetting.isOn = true
            self._PanelObjects._Rdo_Setting.isOn = false
            self._PanelObjects._Rdo_BattleSetting.isOn = false
            self._PanelObjects._Rdo_AccountSetting.isOn = false
            self._PanelObjects._Frame_RenderSetting:SetActive(true)
            self._PanelObjects._Frame_Setting:SetActive(false)
            self._PanelObjects._Frame_BattleSetting:SetActive(false)
            self._PanelObjects._Frame_AccountSetting:SetActive(false)
        elseif self._DataPage == EnumDef.SettingPageType.BaseSetting then
            self._PanelObjects._Rdo_RenderSetting.isOn = false
            self._PanelObjects._Rdo_Setting.isOn = true
            self._PanelObjects._Rdo_BattleSetting.isOn = false
            self._PanelObjects._Rdo_AccountSetting.isOn = false
            self._PanelObjects._Frame_RenderSetting:SetActive(false)
            self._PanelObjects._Frame_Setting:SetActive(true)
            self._PanelObjects._Frame_BattleSetting:SetActive(false)
            self._PanelObjects._Frame_AccountSetting:SetActive(false)
        elseif self._DataPage == EnumDef.SettingPageType.BattleSetting then
            self._PanelObjects._Rdo_RenderSetting.isOn = false
            self._PanelObjects._Rdo_Setting.isOn = false
            self._PanelObjects._Rdo_BattleSetting.isOn = true
            self._PanelObjects._Rdo_AccountSetting.isOn = false
            self._PanelObjects._Frame_RenderSetting:SetActive(false)
            self._PanelObjects._Frame_Setting:SetActive(false)
            self._PanelObjects._Frame_BattleSetting:SetActive(true)
            self._PanelObjects._Frame_AccountSetting:SetActive(false)
        elseif self._DataPage == EnumDef.SettingPageType.AccountSetting then
            self._PanelObjects._Rdo_RenderSetting.isOn = false
            self._PanelObjects._Rdo_Setting.isOn = false
            self._PanelObjects._Rdo_BattleSetting.isOn = false
            self._PanelObjects._Rdo_AccountSetting.isOn = true
            self._PanelObjects._Frame_RenderSetting:SetActive(false)
            self._PanelObjects._Frame_Setting:SetActive(false)
            self._PanelObjects._Frame_BattleSetting:SetActive(false)
            self._PanelObjects._Frame_AccountSetting:SetActive(true)
        else
            warn("(CPanelUISetting) -- PageType is error")
        end
    end
end

def.method().UpdateValues = function(self)
    local game = game
    self._WholeQualityLevel = QualitySettingMan.Instance():GetWholeQualityLevel()
    self._PostProcessLevel = QualitySettingMan.Instance():GetPostProcessLevel()                     
    self._ShadowLevel = QualitySettingMan.Instance():GetShadowLevel()
    self._RoleModelLevel = QualitySettingMan.Instance():GetCharacterLevel()
    self._SceneDetialLevel = QualitySettingMan.Instance():GetSceneDetailLevel()
    self._FXLevel = QualitySettingMan.Instance():GetFxLevel()
    self._IsDepthOfFocus = QualitySettingMan.Instance():IsUseDOF()
    self._IsFogOn = QualitySettingMan.Instance():IsUsePostProcessFog()
    self._IsWaterReflect = QualitySettingMan.Instance():IsUseWaterReflection()
    --self._IsSnowRainOn = QualitySettingMan.Instance():IsUseWeatherEffect()
    --self._IsDetailSoundOn = QualitySettingMan.Instance():IsUseDetailFootStepSound()
--    self._IsHighFrame = QualitySettingMan.Instance():GetFPSLimit() == 60 or QualitySettingMan.Instance():GetFPSLimit() == 200
    self._FrameRate = QualitySettingMan.Instance():GetFPSLimit()

    self._IsShowHeadInfo = game._MiscSetting:IsShowHeadInfo()

    -- TODO 景深、水面反射、开启高帧率
    self._MaxPlayersInScreen = game._MaxPlayersInScreen
    self._BGMVolume = CSoundMan.Instance():GetBGMSysVolume()
    self._OrigBGMVolume = self._BGMVolume
    self._SoundVolume = CSoundMan.Instance():GetEffectSysVolume()
    self._OrigSoundVolume = self._SoundVolume
    self._IsBossLensLock = game._IsOpenPVECamLock
    self._IsPvpLensLock = game._IsOpenPVPCamLock
    
    -- 药品相关
    self._IsMedicalAutoUse, self._IsDrugSortBuyHigh, self._HPMinNumber, self._IsClickGroundMove = game._HostPlayer:GetHostPlayerConfig()
	self._IsEnablePowerSaving = game._CPowerSavingMan:IsEnabled()
    self._PowerSavingIndex = GetPowerSaveIndex(self._IsEnablePowerSaving and game._EnterPowerSaveSeconds or 0)
    --SDK相关
    self._IsOpenPlayerPush = CPlatformSDKMan.Instance():GetPlayerPushStatus()
    self._IsOpenNightPush = CPlatformSDKMan.Instance():GetNightPushStatus()
end

-- 更新控件状态
def.method().UpdateControlStates = function(self)
    -- 画质
    if self._WholeQualityLevel > 0 then
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
    else
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
    end
    -- 后处理
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PostProcess, self._PostProcessLevel + 1)
    -- 阴影
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_ShadowLevel, self._ShadowLevel + 1)
    -- 角色效果
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_RoleModel, self._RoleModelLevel + 1)
    -- 场景细节
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_SceneDetail, self._SceneDetialLevel + 1)
    -- 特效级别
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_FXLevel, self._FXLevel + 1)
    --高级特效效果
    --self._PanelObjects._Rdo_HighFX.isOn = self._IsHighEffectOn
    --后处理雾
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_Fog, self._IsFogOn and 2 or 1)
    --天气效果(暂时屏蔽)
    --HandleIOSToggleShow(self._PanelObjects._Rdo_Weather, self._IsSnowRainOn)
    --脚步效果
    --self._PanelObjects._Rdo_FootFX.isOn = self._IsFootEffectOn
    --细节脚步声（暂时屏蔽）
    --HandleIOSToggleShow(self._PanelObjects._Rdo_DetailSound, self._IsDetailSoundOn)
    --景深效果
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_DepthOfFocus, self._IsDepthOfFocus and 2 or 1)
    --水面反射
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_WaterReflect, self._IsWaterReflect and 2 or 1)
--    --开启高帧率
--    self._PanelObjects._Rdo_HighFrame.isOn = self._IsHighFrame
    if QualitySettingMan.Instance():CanSetHighFrameRate() then
        self._PanelObjects._Rdo_Frame_Rate3:SetActive(true)
    else
        self._PanelObjects._Rdo_Frame_Rate3:SetActive(false)
    end
    if self._FrameRate == 25 or self._FrameRate == 0 then
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_FrameRate, 1)
    elseif self._FrameRate == 30 then
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_FrameRate, 2)
    else
        if QualitySettingMan.Instance():CanSetHighFrameRate() then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_FrameRate, 3)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_FrameRate, 2)
        end
    end
    -- 同屏人数
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PersonNum, GetGroupIndexByPersonNum(self._MaxPlayersInScreen))
    -- 背景音乐
    self._PanelObjects._Sld_BGM.value = self._BGMVolume
    self:SetValueLab(self._PanelObjects._Lab_BGMVal, self._BGMVolume, 100, true)
    GUITools.SetGroupImg(self._PanelObjects._Img_BGM,self._BGMVolume <= 0 and 1 or 0)
    -- 特效音乐
    self._PanelObjects._Sld_EffectSound.value = self._SoundVolume
    self:SetValueLab(self._PanelObjects._Lab_EffectSoundVal, self._SoundVolume, 100, true)
    GUITools.SetGroupImg(self._PanelObjects._Img_EffectSound,self._SoundVolume <= 0 and 1 or 0)

    -- 镜头
    GUI.SetGroupToggleOn(self._PanelObjects._Group_FightLock_PVE, game._IsOpenPVECamLock and 2 or 1)
    GUI.SetGroupToggleOn(self._PanelObjects._Group_FightLock_PVP, game._IsOpenPVPCamLock and 2 or 1)
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_SkillRecover, game._IsOpenCamSkillRecover and 2 or 1)
    --血量限制
    self._PanelObjects._Sld_HpMinVal.value = self._HPMinNumber
    self:SetValueLab(self._PanelObjects._Lab_HPMinVal, self._HPMinNumber, 100, true)
    -- 药水自动使用
    GUI.SetGroupToggleOn(self._PanelObjects._Group_AutoUse, self._IsMedicalAutoUse and 2 or 1)
    --print("self._IsDrugSortBuyHigh ", self._IsDrugSortBuyHigh, self._IsDrugSortBuyHigh and 2 or 1)
    GUI.SetGroupToggleOn(self._PanelObjects._Group_UseSort, self._IsDrugSortBuyHigh and 2 or 1)
    -- 消息推送
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PlayerPush, self._IsOpenPlayerPush and 2 or 1)
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_NightPush, self._IsOpenNightPush and 2 or 1)
    -- 点地移动
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_ClickGroundMove, self._IsClickGroundMove and 2 or 1)
	--省电
	GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PowerSaving, self._PowerSavingIndex)
	--GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PowerSaving, self._IsEnablePowerSaving and 2 or 1)
	--头顶
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_HeadInfo, game._MiscSetting:IsShowHeadInfo() and 2 or 1)

    --玩家ID
    self._PanelObjects._Input_UserID.text = CPlatformSDKMan.Instance():GetUserID()
    self:SetAccountBtn()
    --技能信息界面更新
    UpdateSkillUI(self)
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if string.find(id, "Rdo_") == nil then          --限制点击频率
        if _G.ForbidTimerId ~= 0 then               --不允许输入
            return
        end
    end

    local save_value = false
    if id == "Btn_Back" or id == "Btn_Exit" then
        --如果未保存，恢复语音设置
        CSoundMan.Instance():SetBGMSysVolume(self._OrigBGMVolume)
        CSoundMan.Instance():SetEffectSysVolume(self._OrigSoundVolume)
        CSoundMan.Instance():SetCutSceneSysVolume(self._OrigSoundVolume)
        CSoundMan.Instance():SetUISysVolume(self._OrigSoundVolume)

        game._GUIMan:CloseByScript(self)
    -- 天气特效暂时屏蔽
--    elseif id == "Rdo_Weather" then
--        save_value = true
--        self._IsSnowRainOn = not self._IsSnowRainOn
--        HandleIOSToggleShow(self._PanelObjects._Rdo_Weather, self._IsSnowRainOn)
    -- 细节音效暂时屏蔽
--    elseif id == "Rdo_DetailSound" then
--        save_value = true
--        self._IsDetailSoundOn = not self._IsDetailSoundOn
--        HandleIOSToggleShow(self._PanelObjects._Rdo_DetailSound, self._IsDetailSoundOn)
    elseif id == "Btn_1" then
        -- 卡死脱离
        if game._HostPlayer:IsInServerCombatState() then
            game._GUIMan:ShowTipText(StringTable.Get(19704), false)
        else
            game:AddForbidTimer(self._ClickInterval)

            local C2SReturnToBorn = require "PB.net".C2SReturnToBorn
            local protocol = C2SReturnToBorn()
            SendProtocol(protocol)
            game:StopAllAutoSystems()
            game._GUIMan:CloseByScript(self)
        end
    elseif id == "Btn_2" then
        -- 切换角色
        if game._HostPlayer:IsInServerCombatState() then
            game._GUIMan:ShowTipText(StringTable.Get(19706), false)
        else
            game:AddForbidTimer(self._ClickInterval)
            do
                local C2SLogoutRole = require "PB.net".C2SLogoutRole
                local protocol = C2SLogoutRole()
                SendProtocol(protocol)
            end
        end
    elseif id == "Btn_3" then
        -- 实名认证
        TODO()
    elseif id == "Btn_4" then
        game:AddForbidTimer(self._ClickInterval)

        -- 客服中心
        CPlatformSDKMan.Instance():ShowCustomerCenter(function(deepLinkUrl)
            -- TODO:处理DeepLink
            warn("ShowCustomerCenter callback deepLinkUrl:", deepLinkUrl)
        end)
    elseif id == "Btn_5" then
        game:AddForbidTimer(self._ClickInterval)

        -- 游戏公告
        CPlatformSDKMan.Instance():ShowAnnouncement(function(deepLinkUrl)
            -- TODO:处理DeepLink
            warn("ShowAnnouncement callback deepLinkUrl:", deepLinkUrl)
        end)
    elseif id == "Btn_6" then
        game:AddForbidTimer(self._ClickInterval)

        -- 优惠券
        CPlatformSDKMan.Instance():ShowCoupon()
    elseif id == "Btn_7" then
        -- 跳转至官咖
        local approachItem = CElementData.GetItemApproach(1000)
        if approachItem == nil then
            warn("error !!! banner 填的物品跳转路径ID错误，Banner ID: ", 1000)
            return
        end
        if approachItem.ClickType == EParmType.KakaoKey then
            local bKakaoPlatform = CPlatformSDKMan.Instance():IsInKakao()
            if bKakaoPlatform then
                if approachItem.ClickValue1 and approachItem.ClickValue1 ~= "" then
                    local url = CPlatformSDKMan.Instance():GetCustomData(approachItem.ClickValue1)
                    CPlatformSDKMan.Instance():ShowDaumCafeWithUrl(url)
                else
                    warn("error !!! 物品获取途径模板数据错误，填写的kakao key不对，ID： ", 1000)
                end
            else
                warn("error !!! 不是kakao平台，跳转官咖失败")
            end
        end
    elseif string.find(id, "Btn_Logout") then
        game:AddForbidTimer(self._ClickInterval)

        if CPlatformSDKMan.Instance():IsInDebug() then
            -- if game._HostPlayer:IsInServerCombatState() then
            --     game._GUIMan:ShowTipText(StringTable.Get(19705), false)
            -- else
                game:LogoutAccount()
            -- end
        else
            CPlatformSDKMan.Instance():Logout()
        end
    elseif string.find(id, "Btn_GoogleService") then
        game:AddForbidTimer(self._ClickInterval)

        if CPlatformSDKMan.Instance():IsGoogleGameLogined() then
            -- 登出
            CPlatformSDKMan.Instance():GoogleGameLogout()
        else
            -- 登录
            CPlatformSDKMan.Instance():GoogleGameLogin()
        end
    elseif string.find(id, "Btn_Account_Delete") then
        game:AddForbidTimer(self._ClickInterval)

        -- 账号注销
        CPlatformSDKMan.Instance():Unregister()
    elseif string.find(id, "Btn_Account_Conversion") then
        game:AddForbidTimer(self._ClickInterval)

        -- 账号转变
        CPlatformSDKMan.Instance():AccountConversion()
    elseif string.find(id, "Btn_Copy") then
        GameUtil.CopyTextToClipboard(self._PanelObjects._Input_UserID.text)
    elseif id == "Btn_HpMin" then
        GUITools.ShowCommonTip(StringTable.Get(29003), StringTable.Get(29004), self:GetUIObject("Btn_HpMin"))
    elseif id == "Btn_SkillInfo" then
        local prof = game._HostPlayer._InfoData._Prof
        local str = StringTable.Get(29006)
        if prof == EnumDef.Profession.Aileen then
            str = StringTable.Get(29007)
        elseif prof == EnumDef.Profession.Archer then
            str = StringTable.Get(29008)
        end
        GUITools.ShowCommonTip(StringTable.Get(29005), str, self:GetUIObject("Btn_SkillInfo"))
    elseif id == "Btn_CameraInfo" then
        GUITools.ShowCommonTip(StringTable.Get(29009), StringTable.Get(29010), self:GetUIObject("Btn_CameraInfo"))
    elseif id == "Btn_ReBackBattleValues" then
        self:ReBackBattleValues()
        self:SaveValues()
        self:UpdateControlStates()
    end
    if save_value then
        self:SaveValues()
        self._IsAnyChange = true
    end
end

def.method("=>", "string").GetDropGroupStr = function(self)
    local groupStr = ""
    for i, v in ipairs(self._LanguageTextList) do
        local str = StringTable.Get(v)
        if i ~= #self._LanguageTextList then
            groupStr = groupStr .. str ..","
        else
            groupStr = groupStr .. str
        end
    end
    return groupStr
end

-- 设置下拉菜单
def.method().SetDorpdownGroup = function(self)
    local dropTemplate = self._PanelObjects._Drop_Language:FindChild("Drop_Template")
    GUITools.SetupDropdownTemplate(self, dropTemplate)
    
    local groupStr = self:GetDropGroupStr()
    GUI.SetDropDownOption(self._PanelObjects._Drop_Language, groupStr)

   -- GameUtil.AdjustDropdownRect(self._PanelObjects._Drop_Language, #self._LanguageList)
    self:ResetDropGroup()
end

-- 恢复原来的选项
def.method().ResetDropGroup = function(self)
    local resetIndex = 1
    local j = 1
    for i, v in ipairs(self._LanguageList) do
        if v == self._OriginLanguageCode then
            resetIndex = i
        end
    end

    GameUtil.SetDropdownValue(self._PanelObjects._Drop_Language, resetIndex - 1)
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if string.find(id, "Drop_Language") then
        local languageCode = self._LanguageList[index + 1]
        if self._OriginLanguageCode == languageCode then return end
        if game._HostPlayer:IsInServerCombatState() then
            -- 战斗中
            game._GUIMan:ShowTipText(StringTable.Get(19707), false)
            self:ResetDropGroup()
            return
        end

        game._GUIMan:CloseCircle()
        MsgBox.ClearAllBoxes()
        local title, msg, closeType = StringTable.GetMsg(36)
        local message = string.format(msg, languageCode)
        local specTip = StringTable.Get(19700)
        local callback = function(ret)
            if ret then
                if languageCode ~= "" then
                    GameUtil.WriteUserLanguageCode(languageCode)
                end

                game:LogoutAccount()
            else
                -- 恢复原来设置
                self:ResetDropGroup()
            end
        end
        local setting = {
            [MsgBoxAddParam.SpecialStr] = specTip,
        }
        MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, nil, setting)
    end
end

def.method("string", "=>", "boolean").IsYes = function(self, id)
    local char = string.sub(id, -1)
    if char == "Y" then
        return true
    elseif char == "N" then
        return false
    end
    return false
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if self._IsScriptToggle then
        self._IsScriptToggle = false
        return
    end
    local shouldSave = true
    if string.find(id, "Rdo_MainControl_") and checked then
        local FPSAdapter = require "System.FPSAdapter"
        FPSAdapter.Revert()
        
        -- 渲染设置
        -- 从左到右依次是 极速->低->中->高->最高->自定义，预设最后一个数组分别是 1，2，3，4，5，6
        self._WholeQualityLevel = tonumber(string.sub(id, -1))

        if self._WholeQualityLevel > 5 then self._WholeQualityLevel = 0 end
        QualitySettingMan.Instance():SetWholeQualityLevel(self._WholeQualityLevel)

        --总体效果设置要更新其他设置
        -- 后处理
        self._PostProcessLevel = QualitySettingMan.Instance():GetPostProcessLevel()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PostProcess, self._PostProcessLevel + 1)

        -- 阴影
        self._ShadowLevel = QualitySettingMan.Instance():GetShadowLevel()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_ShadowLevel, self._ShadowLevel + 1)

        -- 角色效果
        self._RoleModelLevel = QualitySettingMan.Instance():GetCharacterLevel()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_RoleModel, self._RoleModelLevel + 1)

        -- 场景细节
        self._SceneDetialLevel = QualitySettingMan.Instance():GetSceneDetailLevel()      
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_SceneDetail, self._SceneDetialLevel + 1)

        -- 特效级别
        self._FXLevel = QualitySettingMan.Instance():GetFxLevel()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_FXLevel, self._FXLevel + 1)

         --后处理雾
        self._IsFogOn = QualitySettingMan.Instance():IsUsePostProcessFog()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_Fog, self._IsFogOn and 2 or 1)
        
        --景深效果
        self._IsDepthOfFocus = QualitySettingMan.Instance():IsUseDOF()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_DepthOfFocus, self._IsDepthOfFocus and 2 or 1)
        
        --水面反射
        self._IsWaterReflect = QualitySettingMan.Instance():IsUseWaterReflection()
        GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_WaterReflect, self._IsWaterReflect and 2 or 1)

    elseif string.find(id, "Rdo_ShadowLevel_") and checked then
        -- 关闭阴影
        self._ShadowLevel = tonumber(string.sub(id, -1)) - 1

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_PostProcess_") and checked then
        -- 后处理设置
        self._PostProcessLevel = tonumber(string.sub(id, -1)) - 1

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_BG_") and checked then
        -- 场景细节
        self._SceneDetialLevel = tonumber(string.sub(id, -1)) - 1

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_FXLevel_") and checked then
        -- 特效级别
        self._FXLevel = tonumber(string.sub(id, -1)) - 1

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_RoleModel_") and checked then
        -- 角色效果
        self._RoleModelLevel = tonumber(string.sub(id, -1)) - 1

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end
    --[[
    elseif string.find(id, "Rdo_HighFX") then
        self._IsHighEffectOn = checked

    elseif string.find(id, "Rdo_FootFX") then
        self._IsFootEffectOn = checked
    ]]
    elseif string.find(id, "Rdo_DepthOfFocus") then
        local is_yes = self:IsYes(id)
        self._IsDepthOfFocus = is_yes

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_Fog") then
        local is_yes = self:IsYes(id)
        self._IsFogOn = is_yes

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_WaterReflect") then
        local is_yes = self:IsYes(id)
        self._IsWaterReflect = is_yes

        --重新计算总体效果
        self._WholeQualityLevel = QualitySettingMan.Instance():CalcWholeQualityLevel(self._PostProcessLevel, self._ShadowLevel, self._RoleModelLevel, self._SceneDetialLevel, self._FXLevel, self._IsDepthOfFocus, self._IsFogOn, self._IsWaterReflect)
        if self._WholeQualityLevel > 0 then
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, self._WholeQualityLevel)
        else
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_MainControl, 6)
        end

    elseif string.find(id, "Rdo_FrameRate_") and checked then
        local idx = tonumber(string.sub(id, -1))
        if idx == 1 then
            self._FrameRate = 25
        elseif idx == 2 then
            self._FrameRate = 30
        else
            self._FrameRate = 60
        end
    elseif string.find(id, "Rdo_PersonNum") then
        local idx = tonumber(string.sub(id, -1))
        local new_num = GetNewPersonNumberByIndex(idx)
        self._MaxPlayersInScreen = new_num
        game._MiscSetting:SyncToServerCareNumAndShowTopPate(self._MaxPlayersInScreen, self._IsShowHeadInfo)
    elseif string.find(id, "Group_FightLock_PVE") then
        -- Boss镜头锁定
        local is_yes = self:IsYes(id)
        self._IsBossLensLock = is_yes
    elseif string.find(id, "Group_FightLock_PVP") then
        -- PVP镜头锁定
        local is_yes = self:IsYes(id)
        self._IsPvpLensLock = is_yes
    elseif string.find(id, "Rdo_Camera_SkillRecover") then
        -- 相机的技能回正
        local is_yes = self:IsYes(id)
        game._IsOpenCamSkillRecover = is_yes
--    elseif string.find(id, "Rdo_PowerSaving") then
--        local is_yes = self:IsYes(id)
--        self._IsEnablePowerSaving = is_yes
    elseif string.find(id, "Rdo_PowerSaving") then
        local idx = tonumber(string.sub(id, -1))
        self._PowerSavingIndex = idx
        if idx <= 1 then
            self._IsEnablePowerSaving = false
        else
            self._IsEnablePowerSaving = true
        end
    elseif string.find(id, "Rdo_ClickGroud") then
        local is_yes = self:IsYes(id)
        self._IsClickGroundMove = is_yes
    elseif string.find(id, "Rdo_HeadInfo") then
        local is_yes = self:IsYes(id)
        self._IsShowHeadInfo = is_yes
        game._MiscSetting:SyncToServerCareNumAndShowTopPate(self._MaxPlayersInScreen, self._IsShowHeadInfo)
    elseif string.find(id, "Rdo_AutoUse") then
        local is_yes = self:IsYes(id)
        self._IsMedicalAutoUse = is_yes
    elseif string.find(id, "Rdo_UseSort") then
        local is_high = self:IsYes(id)
        self._IsDrugSortBuyHigh = is_high
    elseif string.find(id, "Rdo_Skill") then
        local idx = tonumber(string.sub(id, -1))
        if idx then
            local skill_info = self._UserSkillMap[idx]
            if skill_info then
                skill_info._IsOn = checked
            else
                warn("error !!! 技能index对不上")
            end
        end
    elseif string.find(id, "Rdo_PlayerPush") then
        -- 接收推送
        local checked = self:IsYes(id)
        if self._IsOpenPlayerPush == checked then return end
        
        self._IsOpenPlayerPush = checked
        if not checked and self._IsOpenNightPush then
            -- 关闭接收推送时，夜间推送也需要关闭
            self._IsOpenNightPush = false
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_NightPush, self._IsOpenNightPush and 2 or 1)
            CPlatformSDKMan.Instance():EnableNightPush(false, nil)
        end
        CPlatformSDKMan.Instance():EnablePlayerPush(checked, nil)
    elseif string.find(id, "Rdo_NightPush") then
        -- 接收夜间推送
        local checked = self:IsYes(id)
        if self._IsOpenNightPush == checked then return end
        if not self._IsOpenPlayerPush and checked then
            -- 接收推送关闭时，无法打开夜间推送
            self._IsScriptToggle = true
            GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_NightPush, 1)
            game._GUIMan:ShowTipText(StringTable.Get(19720), false)
            return
        end

        self._IsOpenNightPush = checked
        CPlatformSDKMan.Instance():EnableNightPush(checked, nil)
    else
        shouldSave = false
    end
    if shouldSave then
        self:SaveValues()
        self._IsAnyChange = true
    end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    
end

def.method("string", "=>", "number").GetLanIndex = function(self, lan)
    for i = 1, #self._LanguageList do
        if lan == self._LanguageList[i] then
            return i
        end
    end
    return 1
end

-- 更新Push状态
def.method().UpdatePushStatus = function(self)
    self._IsOpenPlayerPush = CPlatformSDKMan.Instance():GetPlayerPushStatus()
    self._IsOpenNightPush = CPlatformSDKMan.Instance():GetNightPushStatus()
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_PlayerPush, self._IsOpenPlayerPush and 2 or 1)
    GUI.SetGroupToggleOn(self._PanelObjects._RdoGroup_NightPush, self._IsOpenNightPush and 2 or 1)
end

-- 滑动条值改变的回调
def.method("string", "number").OnSliderChanged = function(self, id, value)
    if self._IsScriptSlider then return end
    if string.find(id, "Sld_BGM") then
        -- 背景音乐
        self._BGMVolume = value
        CSoundMan.Instance():SetBGMSysVolume(value)
        self:SetValueLab(self._PanelObjects._Lab_BGMVal, value, 100, true)
        GUITools.SetGroupImg(self._PanelObjects._Img_BGM,self._BGMVolume <= 0 and 1 or 0)
    elseif string.find(id, "Sld_EffectSound") then
        -- 效果音乐
        self._SoundVolume = value
        CSoundMan.Instance():SetEffectSysVolume(value)
        CSoundMan.Instance():SetCutSceneSysVolume(value)
        CSoundMan.Instance():SetUISysVolume(value)
        self:SetValueLab(self._PanelObjects._Lab_EffectSoundVal, value, 100, true)
        GUITools.SetGroupImg(self._PanelObjects._Img_EffectSound,self._SoundVolume <= 0 and 1 or 0)
    elseif string.find(id, "Sld_HPMinValue") then
        -- 吃药最低血量限制
        self._HPMinNumber = value
        self:SetValueLab(self._PanelObjects._Lab_HPMinVal, self._HPMinNumber, 100, true)
    end
    self:SaveValues()
    self._IsAnyChange = true
end

def.override("string").OnPointerDown = function(self, id)
end

def.override("string").OnPointerUp = function(self,id)

end

def.method("userdata", "number", "number", "boolean").SetValueLab = function(self, labObj, value, maxVal, isProc)
    if IsNil(labObj) then return end
    local showVal = value * maxVal
    local str = ""
    if showVal < maxVal / 2 then
        str = str..tostring(math.ceil(showVal))
    else
        str = str..tostring(math.floor(showVal))
    end
    if isProc then str = str.."%" end
    GUI.SetText(labObj, str)
end

def.method().SetAccountBtn = function(self)
    if CPlatformSDKMan.Instance():IsInDebug() then return end
    -- Longtu
    local bLongtuPlatform = CPlatformSDKMan.Instance():IsInLongtu()
    self._PanelObjects._Btn_LongtuLogout:SetActive(bLongtuPlatform)
    -- Kakao
    local bKakaoPlatform = CPlatformSDKMan.Instance():IsInKakao()
    self._PanelObjects._Btn_GuestLogout:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_KakaoLogout:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_Account_Conversion:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_GoogleService:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_Account_Delete:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_3:SetActive(false)
    self._PanelObjects._Btn_4:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_5:SetActive(bKakaoPlatform)
    self._PanelObjects._Btn_6:SetActive(bKakaoPlatform and _G.IsAndroid()) -- 优惠券按钮只在安卓显示
    if bKakaoPlatform then
        self:UpdateKakaoAccountBtn()
    end
end

def.method().UpdateKakaoAccountBtn = function(self)
    local isGuest = CPlatformSDKMan.Instance():IsGuest()
    self._PanelObjects._Btn_GuestLogout:SetActive(isGuest)
    self._PanelObjects._Btn_KakaoLogout:SetActive(not isGuest)
    self._PanelObjects._Btn_Account_Conversion:SetActive(isGuest)
    self._PanelObjects._Btn_GoogleService:SetActive(not isGuest and _G.IsAndroid())
    if not isGuest then
        local googleStr = CPlatformSDKMan.Instance():IsGoogleGameLogined() and StringTable.Get(19722) or StringTable.Get(19721)
        GUI.SetText(self._PanelObjects._Lab_GoogleService, googleStr)
    end
end

-- 回复默认设置（战斗设置）
def.method().ReBackBattleValues = function(self)
    for i,v in ipairs(self._UserSkillMap) do
        v._IsOn = true
    end
end

-- 让玩家设置的内容生效。
def.method().SaveValues = function(self)
    --warn("Save Values", debug.traceback())

    QualitySettingMan.Instance():SetPostProcessLevel(self._PostProcessLevel)
    QualitySettingMan.Instance():SetShadowLevel(self._ShadowLevel)
    QualitySettingMan.Instance():SetCharacterLevel(self._RoleModelLevel)
    QualitySettingMan.Instance():SetSceneDetailLevel(self._SceneDetialLevel)
    QualitySettingMan.Instance():SetFxLevel(self._FXLevel)

    QualitySettingMan.Instance():ApplyChanges()

    QualitySettingMan.Instance():EnableDOF(self._IsDepthOfFocus)
    QualitySettingMan.Instance():EnablePostProcessFog(self._IsFogOn)
    QualitySettingMan.Instance():EnableWaterReflection(self._IsWaterReflect)
    --QualitySettingMan.Instance():EnableWeatherEffect(self._IsSnowRainOn)
    --QualitySettingMan.Instance():EnableDetailFootStepSound(self._IsDetailSoundOn)

    QualitySettingMan.Instance():SetFPSLimit(self._FrameRate)
    -- TODO 景深、水面反射、开启高帧率

    local FPSAdapter = require "System.FPSAdapter"
    FPSAdapter.SyncSettings()

    --设置Pve摄像机跟随
    game._IsOpenPVECamLock = self._IsBossLensLock
    if not self._IsBossLensLock then
        game:UpdateCameraLockState(0, false)
    end
    --设置Pvp摄像机跟随
    game._IsOpenPVPCamLock = self._IsPvpLensLock
    if not self._IsPvpLensLock then
        game:UpdateCameraLockState(0, false)
    end

    if self._MaxPlayersInScreen == 0 then self._MaxPlayersInScreen = _G.MAX_VISIBLE_PLAYER end
    game._MaxPlayersInScreen = self._MaxPlayersInScreen
    UserData:SetField(EnumDef.LocalFields.ManPlayersInScreen, self._MaxPlayersInScreen)
    --game._HostPlayer._IsClickGroundMove = self._IsClickGroundMove
    --设置主角的Userdata
    game._HostPlayer:UpdateHostPlayerConfig(self._IsMedicalAutoUse, self._IsDrugSortBuyHigh, self._HPMinNumber, self._IsClickGroundMove)
	--省电
--	game._CPowerSavingMan:Enable(self._IsEnablePowerSaving)
    if self._PowerSavingIndex > 1 then
        game._EnterPowerSaveSeconds = GetPowerSaveSeconds(self._PowerSavingIndex)
        game._CPowerSavingMan:SetSleepingTime(GetPowerSaveSeconds(self._PowerSavingIndex))
    end
    game._CPowerSavingMan:Enable(self._IsEnablePowerSaving)
    game._MiscSetting:SetShowHeadInfo(self._IsShowHeadInfo)
    --DOTO设置是否显示头顶信息（上面这行只是保存了配置，并没有生效）

    CSoundMan.Instance():SetBGMSysVolume(self._BGMVolume)
    CSoundMan.Instance():SetEffectSysVolume(self._SoundVolume)
    CSoundMan.Instance():SetCutSceneSysVolume(self._SoundVolume)
    CSoundMan.Instance():SetUISysVolume(self._SoundVolume)

    self._OrigBGMVolume = self._BGMVolume
    self._OrigSoundVolume = self._SoundVolume
    -- 保存技能自动化战斗时的信息到userdata
    SaveSkillMap(self)
    CAutoFightMan.Instance():SetCantRecastSkillTable(SelectForbidAutoSkill(self))
    -- 设置界面保存数据的时候就直接写入到文件，防止修改设置之后直接杀进程保存不上的问题。
    
end

def.override().OnHide = function(self)
    self._IsScriptToggle = false
    if self._IsAnyChange then
        QualitySettingMan.Instance():SaveQualityConfigToUserData()
        game:SaveCamParamsToUserData()
        game:SaveGameConfigToUserData()
	    game:SaveLoginRoleConfigToUserData()	 -- 保存角色信息
        UserData:SaveDataToFile()
    end
    CPanelBase.OnHide(self)
    CGame.EventManager:removeHandler('NotifyClick', OnElseClick)
    CGame.EventManager:removeHandler('PlatformSDKEvent', OnPlatformSDKEvent)
end

def.override().OnDestroy = function(self)
    self._UserSkillMap = nil
    self._PanelObjects = nil
    self._LanguageList = nil
    self._LanguageTextList = nil
    self._OriginLanguageCode = ""
end

CPanelUISetting.Commit()
return CPanelUISetting