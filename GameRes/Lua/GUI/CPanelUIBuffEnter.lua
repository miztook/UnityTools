
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelUIBuffEnter = Lplus.Extend(CPanelBase, 'CPanelUIBuffEnter')
local def = CPanelUIBuffEnter.define

local CGame = Lplus.ForwardDeclare("CGame")
local CPlatformSDKMan = require "PlatformSDK.CPlatformSDKMan"
local CBtnAutoKill = require "GUI.CBtnAutoKill"

def.field("userdata")._Btn_Open = nil
def.field("userdata")._Frame_ToolBar = nil
def.field("userdata")._Btn_GoogleAchievement = nil
def.field("userdata")._Btn_OpenHotTime = nil
def.field("userdata")._Btn_Survey = nil
def.field(CBtnAutoKill)._CBtnAutoKill = nil

local instance = nil
def.static('=>', CPanelUIBuffEnter).Instance = function ()
	if not instance then
        instance = CPanelUIBuffEnter()
        instance._PrefabPath = PATH.UI_BuffEnter
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Btn_Open = self:GetUIObject("Btn_Open")
    self._Frame_ToolBar = self:GetUIObject("Frame_ToolBar")
    self._Btn_GoogleAchievement = self:GetUIObject("Btn_GoogleAchievement")
    self._Btn_OpenHotTime = self:GetUIObject("Btn_OpenHotTime")    
    self._Btn_Survey = self:GetUIObject("Btn_Survey") 
    if self._Btn_OpenHotTime ~= nil then
        self._Btn_OpenHotTime:SetActive(not game._IsHideHottime)
    end

    if self._Btn_Survey ~= nil then
        self._Btn_Survey:SetActive(not game._IsHideAppMsgBox)
    end
    self._CBtnAutoKill = CBtnAutoKill.Instance( self:GetUIObject('Btn_Autokill'), nil )

    do
		-- 判断功能是否解锁  150 成长引导Tid
		local unlock = game._CFunctionMan:IsUnlockByFunTid(150)
		if self:GetUIObject('Btn_GrowthGuide') ~= nil then
			self:GetUIObject('Btn_GrowthGuide'):SetActive(unlock)
		end
	end
end

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

local function OnPlatformSDKEvent(sender, event)
    if instance ~= nil and instance:IsShow() then
        if event._Type == EnumDef.PlatformSDKEventType.GoogleGame then
            instance:UpdateBtnGoogleAchievement()
        end
    end
end

def.override("dynamic").OnData = function(self,data)
    if game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:Get3V3WorldTID() or game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:Get1v1WorldTID() or
       game._CurWorld._WorldInfo.SceneTid == game._DungeonMan:GetEliminateWorldTID() then
       game._GUIMan:CloseByScript(self)
    end

    self:GetUIObject("Btn_Community"):SetActive(false)
    self:UpdateBtnGoogleAchievement()
    CGame.EventManager:addHandler("PlatformSDKEvent", OnPlatformSDKEvent)

    game._CWorldBossMan:UpdateBossRedPoint()
end

def.override('string').OnClick = function(self, id)    
    if id == "Btn_Open" then
        self:EnableToolBar(true)
    elseif id == 'Btn_OpenHotTime' then
        game._GUIMan:Open("CPanelUIHotTime",nil)
    elseif id == "Btn_Close" then
        self:EnableToolBar(false)
    elseif id == "Btn_Survey" then
        self:GoogleSurveyLogic()
    elseif id == "Btn_Community" then
        self:SDKCommunityLogic()
    elseif id == "Btn_GoogleAchievement" then
        CPlatformSDKMan.Instance():TryShowGoogleAchievementView()
    elseif id == "Btn_WorldBoss" then
        game._CWorldBossMan:SendC2SEliteBossMapStateInfo(true, game._CurWorld._WorldInfo.SceneTid)
        game._GUIMan:Open("CPanelWorldBoss", nil)
    elseif id == "Btn_Autokill" then 
    	if self._CBtnAutoKill ~= nil then
    		self._CBtnAutoKill:OnClick()
        end
    elseif id == "Btn_GrowthGuide" then 
    	game._GUIMan:Open("CPanelStrong",nil)
    	return
    end
end

def.method("boolean").EnableToolBar = function(self, enable)
    GUITools.SetUIActive(self._Btn_Open, not enable)
    GUITools.SetUIActive(self._Frame_ToolBar, enable)
end

def.method().GoogleSurveyLogic = function(self)
    -- Google 调查问卷功能 （CBT临时需求）
    -- 此处需要策划进行配置限制条件， 因为是临时需求， 考虑是否写死
    local limitMinLevel = 25
    if game._HostPlayer:GetLevel() < limitMinLevel then
        local str = string.format(StringTable.Get(31900), limitMinLevel)
        SendFlashMsg(str, false)
    else
        game._GUIMan:OpenUrl("https://www.wjx.cn/jq/24980549.aspx")
    end
end

def.method().SDKCommunityLogic = function(self)
    -- SDK 提供的活动界面入口，社区
    game._GUIMan:OpenUrl("https://qa-cus-zinny3.game.kakao.com/notice/detail/988?gameId=182242")
end

def.method().UpdateBtnGoogleAchievement = function(self)
    local bShowGoogle = CPlatformSDKMan.Instance():IsGoogleGameLogined()
    self._Btn_GoogleAchievement:SetActive(bShowGoogle)
end

def.method("boolean").IsShowHottimeBuffEnterSfx = function(self, isShow)
    if self._Btn_OpenHotTime == nil then return end
    local Img_Item = self._Btn_OpenHotTime:FindChild("Img_Bg")
    if isShow then
        GameUtil.PlayUISfx(PATH.UIFX_HOTTIME_BuffEnter, Img_Item, Img_Item, -1)
    else
        GameUtil.StopUISfx(PATH.UIFX_HOTTIME_BuffEnter, Img_Item)
    end
end

def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler("PlatformSDKEvent", OnPlatformSDKEvent)

    self._Btn_Open = nil
    self._Frame_ToolBar = nil
    self._Btn_GoogleAchievement = nil
    self._Btn_OpenHotTime = nil
    self._Btn_Survey = nil
    if self._CBtnAutoKill ~= nil then
        self._CBtnAutoKill:Destory()
        self._CBtnAutoKill = nil
    end  
end

CPanelUIBuffEnter.Commit()
return CPanelUIBuffEnter