local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local CPanelMinimap = Lplus.ForwardDeclare("CPanelMinimap")
local CPanelMate = require "GUI.CPanelMate"
local CPanelArenaLoading = require "GUI.CPanelArenaLoading"
local CSpecialIdMan = require  "Data.CSpecialIdMan"
local CPanelTracker = require "GUI.CPanelTracker"
local CPanelBattleMiddle = require "GUI.CPanelBattleMiddle"
local CPanelPVPHead = require"GUI.CPanelPVPHead"
local EDungeonType = require "PB.data".EDungeonType
local CPanelMinimap = require"GUI.CPanelMinimap"
local ServerMessageEliminate = require "PB.data".ServerMessageEliminate
local ServerMessageArena3V3 = require "PB.data".ServerMessageArena3V3
local EMatchState = require"PB.data".EMatchState
local CPanelArenaOneMatching = require "GUI.CPanelArenaOneMatching"
local CElementData = require "Data.CElementData"
local CPanelMirrorArena = require "GUI.CPanelMirrorArena"
local CPanelDungeonEnd = require "GUI.CPanelDungeonEnd"
local CQuestAutoMan = require "Quest.CQuestAutoMan"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local EJJC1x1State = require "PB.net".S2CJJC1x1State.EJJC1x1State
local CCalendarMan = require "Main.CCalendarMan"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local CPanelCalendar = require "GUI.CPanelCalendar"
local ETableStateType = require 'PB.net'.TableState.eTableStateType
local EMatchType = require "PB.net".EMatchType

local CArenaMan = Lplus.Class("CArenaMan")
local def = CArenaMan.define

def.field("number")._CurOpenArenaType = 0
def.field("table")._1V1HostData = nil
def.field("table")._3V3HostData = nil
def.field("table")._BattleHostData = nil 
def.field("boolean")._IsBattleFinalGame = false
def.field("boolean")._IsMatching3V3 = false
def.field("boolean")._IsMatchingBattle = false
def.field("boolean")._IsBanMatching3V3 = false
def.field("boolean")._IsBanMatchingBattle = false
def.field("boolean")._IsAgainStart3V3 = false
def.field("boolean")._IsAgainStart1V1 = false
def.field("boolean")._IsAgainStartBattle = false
def.field("table")._FriendInfoData = BlankTable
def.field("boolean")._IsReconnectionOut = false           -- 无畏战场重连后是否被淘汰

def.final("=>", CArenaMan).new = function ()
	local obj = CArenaMan()
	return obj
end

--更新竞技场数据
local function UpdateData(self,data)
	local hp = game._HostPlayer
	local infoData = {}
	infoData.Name = hp._InfoData._Name
	infoData.Level = hp._InfoData._Level
	infoData.Prof = hp._InfoData._Prof
	infoData.CustomImgSet = hp._InfoData._CustomImgSet
	infoData.ID = hp._ID
	infoData.Gender = hp._InfoData._Gender
	infoData.FightScore = hp:GetHostFightScore()
	if self._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then 
		infoData.Stage  = data.Stage 
		infoData.TotalTimes  = data.TotalTimes 
		infoData.WinTimes  = data.WinTimes 
		infoData.Star = data.Star	
		infoData.SeasonLeftTime = data.SeasonLeftTime
		infoData.ObtainedHonor = data.ObtainedHonor
		infoData.MaxHonor = data.MaxHonor
		self._3V3HostData = infoData
	elseif self._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then
		infoData.Rank = data.Rank
		infoData.Score = data.Score
		infoData.WinCount = data.WinCount
		infoData.TotalCount = data.TotalCount
		infoData.EnterNum = data.EnterNum
		self._1V1HostData = infoData
	elseif self._CurOpenArenaType == EnumDef.OpenArenaType.OpenBattle then 
		local dungeonTid = CSpecialIdMan.Get("EliminateScene")
		-- 副本奖励次数
		infoData.RemainderTime =  game._DungeonMan:GetDungeonData(dungeonTid).RemainderTime
		infoData.EliminateScore = data.EliminateScore
		infoData.Rank = data.Rank 
		infoData.SeasonLeftTime = data.SeasonLeftTime
		self._BattleHostData = infoData
	end
end

-- 恢复匹配
local function RestoreStateMatching(self,data)
	
	if data.DungeonType == EDungeonType.Type_Arena then 
		self._IsMatching3V3 = true
		local time = nil

		if data.LeftTime == 0 then 
			game._DungeonMan:MatchingTime3V3Man(0)
			time = data.StartTime
		else
			game._HostPlayer: Set3v3RoomID(0) 
			game._GUIMan:Close("CPanelMate")
			self._IsMatching3V3 = true
			local max =  CSpecialIdMan.Get("Arena3V3MateTime")
			game._DungeonMan:MatchingTime3V3Man(max - data.LeftTime)
			time = GameUtil.GetServerTime()/1000 - (max - data.LeftTime)
		end
		CPanelMirrorArena.Instance():BackToMatching3V3(time)
	elseif data.DungeonType == EDungeonType.Type_Eliminate then
		self._IsMatchingBattle = true
		local time = nil
		if data.LeftTime == 0 then 
			game._DungeonMan:MatchingTimeBattleMan(0)
			time = data.StartTime
			
		else
			game._HostPlayer:SetEliminateRoomID(0)  
			game._GUIMan:Close("CPanelMate")
			local max =  CSpecialIdMan.Get("EliminateMateTime")
			game._DungeonMan:MatchingTime3V3Man(max - data.LeftTime)
			time = GameUtil.GetServerTime()/1000 - (max - data.LeftTime)
		end
		CPanelMirrorArena.Instance():BackToMatchingBattle(time)
	end
end

-- 恢复 已经进入匹配确认界面
local function RestoreStateMatched(self,data)
	local panelData = nil 

	local isConfirmed = false
	if data.MatchState == EMatchState.EMatchState_Confirm then 
		isConfirmed = true
	end

	if data.DungeonType == EDungeonType.Type_Arena then 
		local info = 
		{
			RedList = data.RedList,
			BlackList = data.BlackList,
			DeadLine = data.DeadLine,
			RoomId = data.RoomId,
			IsConfirmed = isConfirmed,
		}
		panelData = 
		{
			CurArenaType = EnumDef.OpenArenaType.Open3V3,
			Info = info,
		}
		game._HostPlayer:Set3v3RoomID(data.RoomId)
	elseif data.DungeonType == EDungeonType.Type_Eliminate then
		game._DungeonMan:MatchingTimeBattleMan(0)
		self._IsMatchingBattle = true
		local info = 
		{
			ConfirmCount = data.ConfirmCount,
			RoleCount = data.RoleCount,
			RoomId = data.RoomId,
			IsConfirmed = isConfirmed,
		}
		panelData = 
		{
			CurArenaType = EnumDef.OpenArenaType.OpenBattle,
			Info = info,
		}
		game._HostPlayer: SetEliminateRoomID(data.RoomId)
	end

	game._GUIMan:Open("CPanelMate",panelData)			
end

-- 恢复 惩罚
local function RestoreStatePunish(self,data)
	if data.DungeonType == EDungeonType.Type_Arena then
		game._DungeonMan:BanMatchingTime3V3Man(data.BanMatchTime)
		game._DungeonMan:BanMatchingTime3V3Man(data.punishTime)
		self._IsBanMatching3V3 = true
	end 
end

-- 直接打开竞技场
def.method("number").OpenArena = function(self,dungeonTid)
	local isOpen = game._CCalendarMan:IsCalendarOpenByPlayID(dungeonTid)
	if not isOpen then 
		game._GUIMan:ShowTipText(StringTable.Get(30109), false)
	return end
	if dungeonTid == game._DungeonMan:Get1v1WorldTID() then 
		self:SendC2SOpenOne()
	elseif dungeonTid == game._DungeonMan:Get3V3WorldTID() then 
		self:SendC2SOpenThree()
	elseif dungeonTid == game._DungeonMan:GetEliminateWorldTID() then 
		self:OnOpenBattle()
	end
end

--发送打开1v1消息
def.method().SendC2SOpenOne = function(self)
	local protocol = require "PB.net".C2SJJC1x1Info
	PBHelper.Send(protocol())
end

--发送打开3v3消息
def.method().SendC2SOpenThree = function(self)
	local protocol = (require "PB.net".C2SMatchDataReq)()
	protocol.MatchType = EMatchType.EMatchType_Arena
	PBHelper.Send(protocol)
end

--打开无畏战场
def.method().OnOpenBattle = function (self)
	local protocol = (require "PB.net".C2SMatchDataReq)()
	protocol.MatchType = EMatchType.EMatchType_Eliminate
	PBHelper.Send(protocol)
end

--打开竞技场界面
def.method("table").OpenPanel = function (self,data)
	self._CurOpenArenaType = data.Type
	UpdateData(self,data.Data)
	if self._CurOpenArenaType == EnumDef.OpenArenaType.OpenBattle then 
		game._GUIMan:Open("CPanelMirrorArena",self._BattleHostData)
	elseif self._CurOpenArenaType == EnumDef.OpenArenaType.Open3V3 then 
		game._GUIMan:Open("CPanelMirrorArena",self._3V3HostData)
	elseif self._CurOpenArenaType == EnumDef.OpenArenaType.Open1V1 then 
		if CPanelMirrorArena.Instance():IsShow() then 
			CPanelMirrorArena.Instance():Update1V1RoleInfo()
			return
		end
		game._GUIMan:Open("CPanelMirrorArena",self._1V1HostData)
	end
end

---------------------------S2C-------------------------------
--1v1Info
def.method("table").OnS2C1V1Info = function(self,msg)
	local panelData = 
	{
		Data = msg,
		Type = EnumDef.OpenArenaType.Open1V1
	}

	if self._IsAgainStart1V1 then 
		self._1V1HostData = nil 
		self._CurOpenArenaType = EnumDef.OpenArenaType.Open1V1
		self._IsAgainStart1V1 = false
		UpdateData(self,msg)
		local C2SReStartInstance = require "PB.net".C2SReStartInstance
        local protocol = C2SReStartInstance()
        PBHelper.Send(protocol)
		return 
	end
	self:OpenPanel(panelData)
end

--1v1匹配状态
def.method("table").OnS2C1V1State = function(self,msg)
	if not CPanelArenaOneMatching.Instance():IsShow() then 	
		game._GUIMan:Open("CPanelArenaOneMatching",nil)
	end
	if CPanelDungeonEnd.Instance():IsShow() then 
		game._GUIMan:Close("CPanelDungeonEnd")
	end
	if msg.State == EJJC1x1State.Success then 
		if CPanelCalendar.Instance():IsShow() then
			game._GUIMan:Close("CPanelCalendar")
		end
	end
	CPanelArenaOneMatching.Instance():UpdateState(msg)
end

-- 1v1 结算
def.method("table").OnS2C1V1Reward = function(self,msg)
	game._GUIMan:Close("CPanelPVPHead")
	--假设依旧在副本中
	if game._HostPlayer:InDungeon() then
		local function callback() 
			msg.DurationSeconds = msg.DurationSeconds
			local data = {}
			data._Type = 2
			data._InfoData = msg
			game._GUIMan:Open("CPanelDungeonEnd", data)
		end
		game._GUIMan:SetMainUIMoveToHide(true,callback)
	end
	CAutoFightMan.Instance():Stop()
end

-- 3V3 开启状态
def.method("boolean").OnS2C3V3ActivityState = function(self,isOpen)
	local panelData = 
	{
		IsOpen = isOpen,
		Type = EnumDef.OpenArenaType.Open3V3
	}
	CPanelMirrorArena.Instance():ChangeButtonState(panelData)
end

-- 3v3玩家信息  
def.method("table").OnS2C3V3PlayerInfo = function(self,msg)
	local panelData = 
	{
		Data = msg,
		Type = EnumDef.OpenArenaType.Open3V3
	}
	self:OpenPanel(panelData)

	if msg.PunishLeftTime > 0 then 
		game._DungeonMan:BanMatchingTime3V3Man(msg.PunishLeftTime)
		self._IsBanMatching3V3 = true
	end
	-- 再次挑战发送匹配消息-
	if self._IsAgainStart3V3 then
		self._3V3HostData = nil 
		self._IsAgainStart3V3 = false
		local protocol = (require "PB.net".C2SMatching)()
		protocol.MatchType = EMatchType.EMatchType_Arena
		PBHelper.Send(protocol)
	end
end

-- 请求匹配成功显示匹配倒计时
def.method().OnS2C3V3Matcihing = function(self)
	self._IsMatching3V3 = true
	game._DungeonMan:MatchingTime3V3Man(0)
	CPanelMirrorArena.Instance():Start3V3Matcing()
	CQuestAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
end

-- 匹配未成功(回到匹配界面接着匹配)
def.method("table").OnS2C3V3BackToMatching = function(self,msg)
	game._HostPlayer: Set3v3RoomID(0) 
	game._GUIMan:Close("CPanelMate")
	self._IsMatching3V3 = true
	local max = CSpecialIdMan.Get("Arena3V3MateTime")
	game._DungeonMan:MatchingTime3V3Man(max - msg.LeftTime )
	local time = GameUtil.GetServerTime()/1000 - (max - msg.LeftTime )
	CPanelMirrorArena.Instance():BackToMatching3V3(time)
	CQuestAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
end

-- 打开确认界面 删除所有匹配时间计时器
def.method("table").OnS2C3V3MatchResult = function(self,msg)
	self._IsMatching3V3 = false
	CPanelMirrorArena.Instance():Cancel3V3Timers()

	local data = 
		{
			CurArenaType = EnumDef.OpenArenaType.Open3V3,
			Info = msg.ArenaInfo,
		}
		warn("msg.ArenaInfo.RoomId  ",msg.ArenaInfo.RoomId)
	game._GUIMan:Open("CPanelMate", data)
 	game._HostPlayer:Set3v3RoomID(msg.ArenaInfo.RoomId) 
 	CQuestAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()   
end

-- 确定进入3V3 加载确认界面的相关信息
def.method("table").OnS2CConfigEnter3V3 = function(self,msg)
	if CPanelMate.Instance():IsShow() then
	 	CPanelMate.Instance():OnS2CConfigReady(msg.RoleId,true)	
	end
end

--开始载入loading界面
def.method("table").OnS2C3V3StartLoading = function(self,msg)
	game._GUIMan:Close("CPanelMate")
	game._GUIMan:Close("CPanelMirrorArena")
	game._GUIMan:CloseSubPanelLayer()
    game._GUIMan._UIManCore:SetAsyncLoadOpenCicle(false)

	local data = 
	{
		CurArenaType = EnumDef.OpenArenaType.Open3V3,
		Info = msg.ArenaInfo
	}
	if CPanelCalendar.Instance():IsShow() then
		game._GUIMan:Close("CPanelCalendar")
	end
	local CPanelUIActivity = require "GUI.CPanelUIActivity"
	if CPanelUIActivity.Instance():IsShow() then
		game._GUIMan:Close("CPanelUIActivity")
	end
	game._GUIMan:Open("CPanelArenaLoading", data)
end

-- 地图加载进度
def.method("table").OnS2C3V3MapProgress = function(self,msg)
	if CPanelArenaLoading.Instance():IsShow() then 
		CPanelArenaLoading.Instance():ChangeLoadRatio(msg.RoleId,msg.Progress)
	end
end

--3v3取消匹配(被动和主动)
def.method("table").OnS2C3V3CancelMatch = function(self,msg)
	self._IsMatching3V3 = false
	CPanelMirrorArena.Instance():Cancel3V3Timers()
	if CPanelMate.Instance():IsShow()  then
	 	game._GUIMan:Close("CPanelMate")
	 	self:SendC2SOpenThree()	
	end	

	if CPanelArenaLoading.Instance():IsShow() then
		game._GUIMan:Close("CPanelArenaLoading")	
	end
	self._FriendInfoData = nil 
	CPanelMirrorArena.Instance():Clear3V3FriendModel()
	
	-- 关闭小地图旁边快捷匹配
	CPVPAutoMatch.Instance():Stop()

	--确认进入时间超时
	if msg.Reason == ServerMessageArena3V3.PVP_EnterConfirmTimeOver then 
		game._GUIMan:ShowErrorTipText(ServerMessageArena3V3.PVP_EnterConfirmTimeOver)
	end

	--匹配超时
	if msg.Reason == ServerMessageArena3V3.PVP_TimeOver then
		game._GUIMan:ShowErrorTipText(ServerMessageArena3V3.PVP_TimeOver)
	end

	--取消的时候，判断一下是不是自我行为，清空roomID
	if msg.RoleId == game._HostPlayer._ID then
		game._HostPlayer: Set3v3RoomID(0) 
	end
    game._GUIMan._UIManCore:SetAsyncLoadOpenCicle(true)
end

--3V3 开始
def.method().OnS2CStart3V3 = function(self)
    --添加倒计时（临时）
	game._GUIMan:Close("CPanelArenaLoading")
    game._GUIMan._UIManCore:SetAsyncLoadOpenCicle(true)
	local CPanelTracker = require "GUI.CPanelTracker"
	CPanelTracker.Instance():ResetDungeonShow()
	local timer_id = 0
	local time = 0
	local callback = function()
		time = time + 1
		if time == 4 then
			game._DungeonMan:SetDungeonID(game._DungeonMan:Get3V3WorldTID())
			CPanelTracker.Instance():SwitchPage(1) -- 默认切换到组队界面
			CPanelTracker.Instance():OpenDungeonUI(true)--重置副本显示状态
			_G.RemoveGlobalTimer(timer_id)
		end
	end
	timer_id = _G.AddGlobalTimer(1, false, callback)
end

-- 3v3结算
def.method("table").OnS2C3V3Reward = function(self,msg)
	game._GUIMan:Close("CPanelPVPHead")
	self._FriendInfoData = nil 
	CPanelMirrorArena.Instance():Clear3V3FriendModel()

	CAutoFightMan.Instance():Stop()

	if game._HostPlayer:InDungeon() then
		local function callback()
			local data = {}
			data._Type = EnumDef.DungeonEndType.ArenaThreeType
			local duration = msg.PassTime
			--删掉一些无用的数据，重新构建一组UI需要的数据
			local rewardData = 
			{
				RewardState = msg.RewardState,
				PassTime = duration ,
				Star = msg.Star,
				WinStreak = msg.WinStreak,
				Rewards = msg.Rewards,
				LeftTime = msg.LeftTime,
				Stage = msg.Stage,
				RedList = msg.RedList,
				BlackList = msg.BlackList,
				OldStage = msg.OldStage,
				OldStar = msg.OldStar,
			}
			data._InfoData = rewardData
			game._GUIMan:Open("CPanelDungeonEnd", data)
		end
		game._GUIMan:SetMainUIMoveToHide(true,callback)
	end
end

def.method("table").OnS2C3V3FriendInfo = function(self,data)
	self._FriendInfoData = {}
	self._FriendInfoData = data
	CPanelMirrorArena.Instance():Update3V3FriendModel()
end

-- 无为战场Info
def.method("table").OnS2CEliminateDataRes = function (self,msg)
	local panelData = 
	{
		Data = msg,
		Type = EnumDef.OpenArenaType.OpenBattle
	}
	if self._IsAgainStartBattle then 
		self._BattleHostData = nil 
		self._CurOpenArenaType = EnumDef.OpenArenaType.OpenBattle
		self._IsAgainStartBattle = false
		UpdateData(self,msg)
		local C2SReStartInstance = require "PB.net".C2SReStartInstance
        local protocol = C2SReStartInstance()
        PBHelper.Send(protocol)
		return 
	end
	if msg.PunishLeftTime > 0 then 
		game._DungeonMan:BanMatchingTimeBattleMan(msg.PunishLeftTime)
		self._IsBanMatchingBattle = true
	end
	self:OpenPanel(panelData)
end

--无畏战场活动状态
def.method("boolean").OnS2CEliminateActivityState = function(self,isOpen)
	local panelData = 
	{
		IsOpen = isOpen,
		Type = EnumDef.OpenArenaType.OpenBattle
	}
	CPanelMirrorArena.Instance():ChangeButtonState(panelData)
end

def.method().OnS2CEliminateMatching = function(self)
	if self._IsAgainStartBattle then 
		self._IsAgainStartBattle = false
		self:OnOpenBattle()
	end
	self._IsMatchingBattle = true
	game._DungeonMan:MatchingTimeBattleMan(0)
	CPanelMirrorArena.Instance():StartBattleMatching()

	CQuestAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
end

--匹配成功返回匹配结果
def.method("table").OnS2CEliminateMatchResult = function(self,msg)
	self._IsMatchingBattle = false

	CPanelMirrorArena.Instance():CancelBattleTimers()
	
	local data = 
	{
		CurArenaType = EnumDef.OpenArenaType.OpenBattle,
		Info = msg.EliminateInfo
	}
	game._GUIMan:Open("CPanelMate", data)

	game._HostPlayer:SetEliminateRoomID(msg.EliminateInfo.RoomId)  

	CQuestAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
end

-- 取消匹配结果(被动取消和主动取消)
def.method("table").OnS2CEliminateCancelRes = function(self,msg)
	self._IsMatchingBattle = false
	CPanelMirrorArena.Instance():CancelBattleTimers()
	if CPanelMate.Instance():IsShow() then
	 	game._GUIMan:Close("CPanelMate")
	 	self:OnOpenBattle()	
	end	

	if CPanelArenaLoading.Instance():IsShow() then
		game._GUIMan:Close("CPanelArenaLoading")	
	end

	if CPanelMirrorArena.Instance():IsShow() then 
		self:OnOpenBattle()
	end
	
	CPVPAutoMatch.Instance():Stop()
	--确认进入时间超时
	if msg.Reason == ServerMessageArena3V3.PVP_EnterConfirmTimeOver then 
		game._GUIMan:ShowErrorTipText(ServerMessageEliminate.PVP_EnterConfirmTimeOver)
	end
	--匹配超时
	if msg.Reason == ServerMessageEliminate.Eliminate_TimeOver then
		game._GUIMan:ShowErrorTipText(ServerMessageEliminate.Eliminate_TimeOver)
	end
	if msg.RoleId == game._HostPlayer._ID then
		game._HostPlayer: SetEliminateRoomID(0) 
	end
end

--玩家确认进入
def.method("number").OnS2CEliminateEnterConfirm = function(self,roleId)
	if CPanelMate.Instance():IsShow() then
	 	CPanelMate.Instance():OnS2CConfigReady(roleId,true)	
	end
end

--正式开始无为战场
def.method().OnS2CEliminateStart = function(self)

	game._GUIMan:Close("CPanelArenaLoading")
	local timer_id = 0
	local time = 0
	local callback = function()
		time = time + 1
		if time == 4 then
			game._DungeonMan:SetDungeonID(game._DungeonMan:GetEliminateWorldTID())
			_G.RemoveGlobalTimer(timer_id)
		end
	end
	timer_id = _G.AddGlobalTimer(1, false, callback)
end

-- 匹配未成功返回主界面
def.method("table").OnS2CEliminateBackToMatching = function(self,msg)
	game._HostPlayer: SetEliminateRoomID(0) 
	game._GUIMan:Close("CPanelMate")
	self._IsMatchingBattle = true
	local max =  CSpecialIdMan.Get("EliminateMatchingTime")
	game._DungeonMan:MatchingTimeBattleMan(max - msg.LeftTime)
	local time = GameUtil.GetServerTime()/1000 - (max - msg.LeftTime)
    CPanelMirrorArena.Instance():BackToMatchingBattle(time)
	
	CQuestAutoMan.Instance():Stop()
	CAutoFightMan.Instance():Stop()
end

def.method("table").OnS2CEliminateInfo = function(self,msg)
	if msg.TableInfo.State == ETableStateType.Normal then 
		self._IsBattleFinalGame = false
	elseif msg.TableInfo.State == ETableStateType.Finals then 
		self._IsBattleFinalGame = true
	end
	if CPanelPVPHead.Instance():IsShow() then 
		CPanelBattleMiddle.Instance():UpdateRankShow(msg.TableInfo)
	else
		local panelData = 
						{
							DungeonType = EDungeonType.Type_Eliminate,
							TableInfo = msg.TableInfo,
						}
		game._GUIMan:Open("CPanelPVPHead", panelData)
	end
	if not CPanelBattleMiddle.Instance():IsShow() then 
		game._GUIMan:Open("CPanelBattleMiddle",msg.TableInfo)
	end
end

--开始载入
def.method().OnS2CEliminateStartLoading = function(self)
	game._GUIMan:Close("CPanelMate")
	game._GUIMan:Close("CPanelMirrorArena")
	if CPanelCalendar.Instance():IsShow() then
		game._GUIMan:Close("CPanelCalendar")
	end
	local data = 
	{
		CurArenaType = EnumDef.OpenArenaType.OpenBattle,
	}
	game._GUIMan:Open("CPanelArenaLoading", data)

	-- CPanelBattleMiddle.Instance():InitRankData(msg.RoleList)
end

--同步角色信息
def.method("table").OnS2CEliminateRoleInfos = function(self,msg)
	CPanelBattleMiddle.Instance():InitRankData(msg.RoleList)
end

-- 积分更新击杀数
def.method("table").OnS2CEliminateScoreUpdate = function(self,msg)
	CPanelBattleMiddle.Instance():UpdateRoleData(msg.RoleId,msg.Score,msg.KillNum,msg.TableId)
end

-- 通知谁持有中心物件
def.method("table").OnS2CEliminateCenterItemUpdate = function(self,msg)
	CPanelBattleMiddle.Instance():UpdateCenterItemIcon(msg.TableId,msg.RoleId)
end

-- 结算
def.method("table").OnS2CEliminateReward = function(self,msg)
	game._GUIMan:Close("CPanelPVPHead")
	game._GUIMan:Close("CPanelBattleMiddle")
	CAutoFightMan.Instance():Stop()
	if not msg.IsMid then 
		if game._HostPlayer:InDungeon() then
			local function callback()
				local data = {}
				data._IsOut = msg.IsOut
				data._Type = EnumDef.DungeonEndType.EliminateType
				data._RewardTid = msg.RewardTid
				data._LeftTime = msg.LeftTime
				data._AllRoleDataList = msg.RankRoles
				data._AddScore = msg.AddScore
				data._Rank = msg.Rank
				game._GUIMan:Open("CPanelDungeonEnd", data)
			end
			game._GUIMan:SetMainUIMoveToHide(true,callback)
		end
	else 
		local data = nil 
		if msg.IsOut then 
			data = {}
			data._IsOut = msg.IsOut
			data._Type = EnumDef.DungeonEndType.EliminateType
			data._RewardTid = msg.RewardTid
			data._LeftTime = msg.LeftTime
			data._AllRoleDataList =  msg.RankRoles
			data._AddScore = msg.AddScore
			data._Rank = msg.Rank
		end
		if self._IsReconnectionOut then
			CPanelBattleMiddle.Instance():ReconnectionInitData(msg.RankRoles,self._IsReconnectionOut)
		end
		local ListA,ListB = CPanelBattleMiddle.Instance():GetMidRankData()

		local panelData =
						{
							ListA = ListA,
							ListB = ListB,
							LeftTime = msg.LeftTime,
							IsOut = msg.IsOut,
							EndData = data,
							RoleList =msg.RankRoles, 
						} 
		game._GUIMan:Open("CPanelBattleResult",panelData)
	end
end

-- 击杀
def.method("table").OnS2CEliminateKillInfo = function(self,msg)
	CPanelBattleMiddle.Instance():ShowKillTip(msg)
end

-- 断线(其他玩家断线 玩家收到的信息 ) 初始进入竞技场时的也会传来
def.method("table").OnS2CDungeonAdditionInfo = function(self,msg)
	if msg.DungeonType == EDungeonType.Type_JJC or msg.DungeonType == EDungeonType.Type_Arena then 
		if CPanelPVPHead.Instance():IsShow() then 
			CPanelPVPHead.Instance():UpdatePlayerData(msg.Infos)
		else
			game._GUIMan:Open("CPanelPVPHead", msg)
		end
	elseif msg.DungeonType == EDungeonType.Type_Eliminate then
		CPanelTracker.Instance():ShowSelfPanel(false)
		self._IsReconnectionOut = msg.IsOut 
		if self._IsReconnectionOut then return end
		CPanelBattleMiddle.Instance():ReconnectionInitData(msg,msg.IsOut)
	end
end

--自己断线重连 回到匹配界面
def.method("table").OnS2CMatchRestoreData = function(self,msg)
	local  data = nil
	for _,v in pairs( msg.MutilMatchRestore) do 
		if v.DungeonType == EDungeonType.Type_Arena then 
			data = v
		elseif v.DungeonType == EDungeonType.Type_Eliminate then 
			data = v
		end
	end
	if data == nil then return end 
	if data.MatchState == EMatchState.EMatchState_Matching then 
		RestoreStateMatching(self,data)
	elseif data.MatchState == EMatchState.EMatchState_Matched or data.MatchState == EMatchState.EMatchState_Confirm then 
		RestoreStateMatched(self,data)
	elseif data.MatchState == EMatchState.EMatchState_Punish then 
		RestoreStatePunish(self,data)
	end   
end

-- 切换账号 或是 切换角色 关闭默认之前角色匹配相关数据
def.method().Cleanup = function (self)
	self._CurOpenArenaType = 0
	self._1V1HostData = nil
	self._3V3HostData = nil
	self._BattleHostData = nil 
	self._IsMatching3V3 = false
	self._IsMatchingBattle = false
	self._IsBanMatching3V3 = false
	self._IsAgainStart3V3 = false
	self._IsAgainStart1V1 = false
	self._IsAgainStartBattle = false
	self._FriendInfoData = nil 
	self._IsReconnectionOut = false
end

CArenaMan.Commit()
return CArenaMan