local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CUIModel = require "GUI.CUIModel"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPage3V3 = require"GUI.CPage3V3"
local CPageBattle = require"GUI.CPageBattle"
local CPage1V1 = require"GUI.CPage1V1"
local CPanelMinimap = require"GUI.CPanelMinimap"
local CPVPAutoMatch = require"ObjHdl.CPVPAutoMatch"

local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelMirrorArena = Lplus.Extend(CPanelBase, "CPanelMirrorArena")
local def = CPanelMirrorArena.define

def.field(CUIModel)._Model4ImgRender_0 = nil
def.field(CFrameCurrency)._Frame_Money = nil
def.field("userdata")._ButtonRule = nil 
def.field("userdata")._Frame_Right = nil 
def.field("userdata")._Lab_Title = nil 
def.field("userdata")._Frame_1V1 = nil 
def.field("userdata")._Frame_3V3 = nil 
def.field("userdata")._Frame_Battle = nil
def.field("userdata")._Frame_Model3V3 = nil 
 
def.field("table")._BattleHostData = nil 
def.field("number")._Matching_TimerID = 0 --匹配计时器
def.field("number")._BattleWaitingTimeSpecialId = 376
def.field("table")._PanelObject = nil


def.field("number")._3v3LimitLevelSpicalId = 227

local instance = nil
def.static("=>", CPanelMirrorArena).Instance = function()
	if not instance then
		instance = CPanelMirrorArena()
		instance._PrefabPath = PATH.UI_MirrorArena
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	
	self._PanelObject =  
    {
        Frame_1V1 = {},            
        Frame_3V3 = {},                
        Frame_Battle = {},          
    }
 	self._Frame_Right = self:GetUIObject("Frame_Right")
 
    self._ButtonRule = self:GetUIObject("Btn_BattleRule")
    self._Model4ImgRender_0 = GUITools.CreateHostUIModel(self:GetUIObject("Img_Role0"), EnumDef.RenderLayer.UI,nil,EnumDef.UIModelShowType.NoWing)

    self._Model4ImgRender_0:AddLoadedCallback(function() 
        self._Model4ImgRender_0:SetModelParam(self._PrefabPath, game._HostPlayer._InfoData._Prof)
    end)

    self._Frame_Battle = self:GetUIObject("Frame_BattleField")
    self._Frame_1V1 = self:GetUIObject("Frame_1V1")
    self._Frame_3V3 = self:GetUIObject("Frame_3V3")
    self._Lab_Title = self:GetUIObject("Lab_Title1")
    self._Frame_Model3V3 = self:GetUIObject("Frame_Model3V3")

    do 
    	local info = self._PanelObject.Frame_1V1
		info.root = self._Frame_1V1
	 	info._FrameRole = self:GetUIObject("Frame_Role")
	 	info._PrefabPath = self._PrefabPath
	    info._FrameRoleInfo1V1 = self:GetUIObject("Img_RoleInfo1V1")
	    info._ItemIcon1 = self:GetUIObject("ItemIcon1")
	    info._ItemIcon2 = self:GetUIObject("ItemIcon2")
	    info._FrameMatchTime = self:GetUIObject("Frame_MatchBan")
	    info._LabWin = self:GetUIObject("Lab_Win")
	    info._LabWinPoint = self:GetUIObject("Lab_WinPoint")
	    info._LabChance = self:GetUIObject("Lab_Chance")
	end

	do 
		local info = self._PanelObject.Frame_3V3
		info.root = self._Frame_3V3
		info._PrefabPath = self._PrefabPath
	    info._FrameRoleInfo3V3 = self:GetUIObject("Img_RoleInfo3V3")
	    info._ItemIcon3 = self:GetUIObject("ItemIcon3")
	    info._ItemIcon4 = self:GetUIObject("ItemIcon4")
	    info._FrameBadge = self:GetUIObject("Frame_Badge")
	   	info._ImgSan = self:GetUIObject("Img_San")
	   	info._ImgLevel = self:GetUIObject("Img_Level")
	    info._LabLevel = self:GetUIObject("Lab_San")
	    info._LabSanLevel  = self:GetUIObject("Lab_SanLevel")
	    -- info._ImgRoleInfo2 = self:GetUIObject("Img_RoleInfo2")
	    info._LabBlood = self:GetUIObject("Lab_Honor")
	    info._HonorIndicator = self:GetUIObject("Bld_Honor"):GetComponent(ClassType.Slider) 
	    info._BtnCancelCharge = self:GetUIObject("Btn_CancelCharge")   
	    info._LabTime = self:GetUIObject("Lab_Me")
	    info._Lab_Btn_Charge3V3 = self:GetUIObject("Lab_Charge2")
	    info._BtnCharge3V3 = self:GetUIObject("Btn_Charge2")
	    info._LabWin = self:GetUIObject("Lab_Win1")
	    info._LabWinPoint = self:GetUIObject("Lab_WinPoint1")
	    info._LabChance = self:GetUIObject("Lab_ChanceTips2")
	    info._LabSeasonTime = self:GetUIObject("Lab_TimeTip2")
	    info._LabAwardStage2 = self:GetUIObject("Lab_AwardStage2")
	    info._FriendInfoModel = self._Frame_Model3V3
	    info._FrameMatchTime = self:GetUIObject("Frame_MatchBan")
	    info._LabChanceAndBanTime = self:GetUIObject("Lab_MatchBanTime")
	    info._FrameSeasonTime = self:GetUIObject("Frame_SeasonTime")
	    info._LabMatchBanTip = self:GetUIObject("Lab_MatchBanTip")
        info._ImgPanelBG = self:GetUIObject("Img_PanelBG")
	end
	do 
		local info = self._PanelObject.Frame_Battle
		info.root = self._Frame_Battle
		info._RoleInfoBattle = self:GetUIObject("Img_RoleInfoBattle")
		
		-- info._LabJoinLevel = self:GetUIObject("Lab_JoinLevel")
		-- info._LabJoinNumber = self:GetUIObject("Lab_JoinNumber")
		info._LabRank = self:GetUIObject("Lab_BattleRank")
		info._LabScore = self:GetUIObject("Lab_BattleScore")
		info._LabRewardTimes = self:GetUIObject("Lab_BattleRewardTimes")
		info._LabRemainTime = self:GetUIObject("Lab_RemainTime")
		info._ItemIcon5 = self:GetUIObject("ItemIcon5")
		info._ItemIcon6 = self:GetUIObject("ItemIcon6")
		info._ItemIcon7 = self:GetUIObject("ItemIcon7")
		info._BtnCancelCharge = self:GetUIObject("Btn_CancelChargeBattle")
		info._BtnChargeBattle = self:GetUIObject("Btn_ChargeBattle")
		info._LabMatchingTime = self:GetUIObject("Lab_BattleMatchingTime")
		info._BtnLabCharge = self:GetUIObject("Lab_Charge")
	    info._FrameMatchTime = self:GetUIObject("Frame_MatchBan")
	    info._LabMatchBanTip = self:GetUIObject("Lab_MatchBanTip")
		info._BtnChargeBg = info._BtnChargeBattle:FindChild("Img_Bg")
		info._LabTime = self:GetUIObject("Lab_MatchBanTime")
        info._ImgPanelBG = self:GetUIObject("Img_PanelBG")
	end
end

def.override("dynamic").OnData = function(self, data)	
	CPanelBase.OnData(self,data)
	if self._Frame_Money == nil then
        self:GetUIObject("Frame_Money"):SetActive(true)
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end
	self:InitPanel(data)
    do  --显示UI特效
        local img_BG = self:GetUIObject("Img_PanelBG")
        GameUtil.PlayUISfx(PATH.UIFX_JJC_Ready_BGLight, img_BG, img_BG, -1)
    end 
end

--Button点击
def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	elseif self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
        return
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
	elseif id == "Btn_Question" then 
		TODO()
	elseif id == "Btn_Shop"  then 
		local ShopId = 0
		-- 荣耀商店
		if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 or game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then
			ShopId = 16
		else
			ShopId = 17
		end
		local panelData = 
		{
			OpenType = 1,
			ShopId  = ShopId,
		}
		game._GUIMan:Open("CPanelNpcShop",panelData)
	end
	if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then 
		CPage3V3.Instance():Click(id)
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then 
		CPage1V1.Instance():Click(id)
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.OpenBattle then 
		CPageBattle.Instance():Click(id)
	end
end

def.method("table").InitPanel = function (self,data)
	print(game._CArenaMan._CurOpenArenaType)
	if game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then
		self._Frame_3V3:SetActive(true)
		self._Frame_1V1:SetActive(false)
		self._Frame_Battle:SetActive(false)
		self._Frame_Model3V3:SetActive(true)
		GUI.SetText(self._Lab_Title,StringTable.Get(20067))
		GUITools.SetUIActive( self._ButtonRule ,false)
		CPage3V3.Instance():Show(self._PanelObject.Frame_3V3,self._PanelObject.Frame_3V3.root)
		self._HelpUrlType = HelpPageUrlType.Open3V3
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then 
		self._Frame_3V3:SetActive(false)
		self._Frame_1V1:SetActive(true)
		self._Frame_Battle:SetActive(false)
		self._Frame_Model3V3:SetActive(false)
		GUI.SetText(self._Lab_Title,StringTable.Get(20066))
		GUITools.SetUIActive( self._ButtonRule ,false)
		CPage1V1.Instance():Show(self._PanelObject.Frame_1V1,self._PanelObject.Frame_1V1.root)
		self._HelpUrlType = HelpPageUrlType.Open1V1
	elseif game._CArenaMan._CurOpenArenaType == EnumDef.OpenArenaType.OpenBattle then 
		self._Frame_3V3:SetActive(false)
		self._Frame_1V1:SetActive(false)
		self._Frame_Battle:SetActive(true)
		self._Frame_Model3V3:SetActive(false)
		GUI.SetText(self._Lab_Title,StringTable.Get(20068))	
		GUITools.SetUIActive( self._ButtonRule ,true)
		CPageBattle.Instance():Show(self._PanelObject.Frame_Battle,self._PanelObject.Frame_Battle.root)
		self._HelpUrlType = HelpPageUrlType.OpenBattle
	end
end

def.method("dynamic").OpenAutoMatch = function(self,time)
	if game._CArenaMan._IsMatching3V3 then
		local waitingTime = CSpecialIdMan.Get("Arena3V3MateTime")
		local startTime = time or game._DungeonMan._3V3MatchingStartTime
		local endTime = startTime + waitingTime 
		local dungeonTemplate = CElementData.GetInstanceTemplate(game._DungeonMan:Get3V3WorldTID())

		if dungeonTemplate then
			CPVPAutoMatch.Instance():InitMatchFunctionText(dungeonTemplate.TextDisplayName)
		 	CPVPAutoMatch.Instance():Start(EnumDef.AutoMatchType.In3V3Fight,startTime,endTime)
		 end		
	elseif game._CArenaMan._IsMatchingBattle then 
		local waitingTime = tostring(CElementData.GetSpecialIdTemplate(self._BattleWaitingTimeSpecialId).Value)
		local startTime = time or game._DungeonMan._BattleMatchingStartTime
		local endTime = startTime + waitingTime 	
		local dungeonTemplate = CElementData.GetInstanceTemplate(game._DungeonMan:GetEliminateWorldTID())
		if dungeonTemplate then	
			CPVPAutoMatch.Instance():InitMatchFunctionText(dungeonTemplate.TextDisplayName)
			CPVPAutoMatch.Instance():Start(EnumDef.AutoMatchType.InBattleFight,startTime,endTime)
		end
	end
end

def.method().Start3V3Matcing = function(self)
	if self:IsShow() then 

		CPage3V3.Instance():ShowMatchingTime3V3(GameUtil.GetServerTime()/1000)
	else
		-- 组队 其他队员在没有进入匹配主界面时 在小地图旁边进行匹配显示
		self:OpenAutoMatch(GameUtil.GetServerTime()/1000)
		-- CPanelMinimap.Instance():ShowMatchingTimeArena(GameUtil.GetServerTime()/1000)
	end
end

def.method().StartBattleMatching = function(self)
	if self:IsShow() then 		
		CPageBattle.Instance():ShowMatchingTimeBattle(GameUtil.GetServerTime()/1000)
	else
		self:OpenAutoMatch(GameUtil.GetServerTime()/1000)
	end
end

--删除3v3匹配计时器(界面和小地图)
def.method().Cancel3V3Timers = function(self)
	if self:IsShow() then
		CPage3V3.Instance():Cancel3V3Timer()
	end
	CPVPAutoMatch.Instance():Stop()
end

--删除无为战场匹配计时器
def.method().CancelBattleTimers = function(self)
	if self:IsShow() then
		CPageBattle.Instance():CancelBattleTimer()
	end
	CPVPAutoMatch.Instance():Stop()
end

-- 清除3v3队友模型或数据(重新刷新界面数据显示)
def.method().Clear3V3FriendModel = function(self)
	if self:IsShow() then 
		game._CArenaMan:SendC2SOpenThree()
		CPage3V3.Instance():HideFriendModel()
	end
end

-- 匹配未成功(回到匹配界面接着匹配)
def.method("number").BackToMatching3V3 = function(self,time)
	if self:IsShow() then
		CPage3V3.Instance():ShowMatchingTime3V3(time)
	else
		self:OpenAutoMatch(time)
	end
end

def.method("number").BackToMatchingBattle = function(self,time)
	if self:IsShow() then
		CPageBattle.Instance():ShowMatchingTimeBattle(time)
	else
		self:OpenAutoMatch(time)
	end
end

-- 活动状态改变3v3和无畏战场按钮显示
def.method("table").ChangeButtonState = function(self,data)
	if not self:IsShow() then return end
	if data.Type == EnumDef.OpenArenaType.Open3V3 then 
		CPage3V3.Instance():Change3V3BtnChargeState(data.IsOpen)
	elseif data.Type == EnumDef.OpenArenaType.OpenBattle then 
		CPageBattle.Instance():ChangeBattleBtnChargeState(data.IsOpen)
	end
end

def.method().Update3V3FriendModel = function(self)
	CPage3V3.Instance():UpdateFriendModel()
end

def.method().Update1V1RoleInfo = function(self)
	local obj = self:GetUIObject("Img_RoleInfo1V1")
	if obj == nil then return end
	CPage1V1.Instance():UpdateRoleInfo(obj)
end

def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
	self:OpenAutoMatch(nil)
	if self._Model4ImgRender_0 then
		self._Model4ImgRender_0:Destroy()
		self._Model4ImgRender_0 = nil
	end
	CPage3V3.Instance():Destroy()
	CPage1V1.Instance():Destroy()
	CPageBattle.Instance():Destroy()
	self._PanelObject = nil 
	instance = nil 
end


CPanelMirrorArena.Commit()
return CPanelMirrorArena