local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local NotifyArenaEvent = require "Events.NotifyArenaEvent"
local CPanelMateOn = require "GUI.CPanelMateOn"
local C3V3Panel = require "GUI.CPanel3v3"
local CPanelMate = require "GUI.CPanelMate"
local C3V3LoadingPanel = require "GUI.CPanel3v3Loading"
local ServerMessageId = require "PB.data".ServerMessageId
local CPanelTracker = require "GUI.CPanelTracker"

--发送竞技场事件
local function SendArenaEvent(data, eventType)
	local event = NotifyArenaEvent()
	event.Type = eventType
	CGame.EventManager:raiseEvent(data, event)
end

--------------------1v1--------------------

local function OnS2CJJC1x1State(sender, msg)
	SendArenaEvent(msg, "One")
end
PBHelper.AddHandler("S2CJJC1x1State", OnS2CJJC1x1State)

local function OnS2CJJC1x1Reward(sender, msg)
	local data = {}
	data._Type = 2
	data._InfoData = msg
	game._GUIMan:SetNormalUIMoveToHide(true, 0, "CPanelDungeonEnd", data)
end
PBHelper.AddHandler("S2CJJC1x1Reward", OnS2CJJC1x1Reward)

local function OnS2CJJC1x1Info(sender, msg)
	game._GUIMan:Open("CPanelMirrorArena", msg)
end
PBHelper.AddHandler("S2CJJC1x1Info", OnS2CJJC1x1Info)

--------------------1v1--------------------

--------------------3v3--------------------

--3V3请求匹配成功
local function OnS2CArenaMatching(sender, msg)
	game._GUIMan:Close("CPanel3v3")
	game._GUIMan:Open("CPanelMateOn", msg.RoleId)	
end
PBHelper.AddHandler("S2CArenaMatching", OnS2CArenaMatching)

--竞技场匹配结果
local function OnS2CArenaMatchResult(sender, msg)	
	game._GUIMan:Close("CPanelMateOn")
	game._GUIMan:Open("CPanelMate", msg.Info)
 	game._HostPlayer: Set3v3RoomID(msg.Info.RoomId)    
end
PBHelper.AddHandler("S2CArenaMatchResult", OnS2CArenaMatchResult)

--确定进入3V3
local function OnConfigEnter3V3(sender, msg)
	if CPanelMate.Instance():IsShow() then
	 	CPanelMate.Instance():OnS2CConfigReady(msg.RoleId,true)	
	end
end
PBHelper.AddHandler("S2CArenaEnterConfirm",OnConfigEnter3V3)

--开始载入
local function OnS2CArenaStartLoading(sender, msg)
	game._GUIMan:Open("CPanel3v3Loading", msg)
	--warn("S2CArenaStartLoading!!!!!!!!!!!!!!!!!!!")
end
PBHelper.AddHandler("S2CArenaStartLoading", OnS2CArenaStartLoading)

--地图加载进度
local function OnS2CArenaMapLoadProgress(sender, msg)
	if C3V3LoadingPanel.Instance():IsShow() then
	 	C3V3LoadingPanel.Instance():ChangeLoadRatio(msg.RoleId,msg.Progress)
	 	--warn("S2CArenaMapLoadProgress",msg.RoleId,msg.Progress)
	end
end 
PBHelper.AddHandler("S2CArenaMapLoadProgress",OnS2CArenaMapLoadProgress)


--取消匹配
local function OnCancelMatch(sender, msg)
	if msg == nil or msg.RoleId == nil then return end
	if CPanelMate.Instance():IsShow() then
	 	CPanelMate.Instance():OnS2CConfigReady(msg.RoleId,false)	 	
	end	

	if C3V3LoadingPanel.Instance():IsShow() then
		game._GUIMan:Close("CPanel3v3Loading")	
	end

	--确认进入时间超时
	if msg.Reason == ServerMessageId.PVP_EnterConfirmTimeOver then 
		if CPanelMate.Instance():IsShow() then
			game._GUIMan:Close("CPanelMate")
		end

		local template = CElementData.GetSystemNotifyTemplate(ServerMessageId.PVP_EnterConfirmTimeOver)
		local message = ""
		if template ~= nil then
			message = template.TextContent
		end

		game._GUIMan:ShowTipText(message, false)
	end

	--匹配超时
	if msg.Reason == ServerMessageId.PVP_TimeOver then
		local template = CElementData.GetSystemNotifyTemplate(ServerMessageId.PVP_TimeOver)
		local message = ""
		if template ~= nil then
			message = template.TextContent
		end

		game._GUIMan:ShowTipText(message, false)
	end

	if CPanelMateOn.Instance():IsShow() then
		game._GUIMan:Close("CPanelMateOn")
	end

	--取消的时候，判断一下是不是自我行为，清空roomID
	if msg.RoleId == game._HostPlayer._ID then
		game._HostPlayer: Set3v3RoomID(0) 
	end
end
PBHelper.AddHandler("S2CArenaCancelRes",OnCancelMatch)


--3V3正式开始
local function Start3V3Arena(sender, msg)
	game._GUIMan:Close("CPanel3v3Loading")	

	--添加倒计时（临时）
	local timer_id = 0
	local time = 0
	local callback = function()
		time = time + 1
		if time == 4 then
			local CPanelTracker = require "GUI.CPanelTracker"
			CPanelTracker.Instance():OpenDungeonUI(true)
			TimerUtil.RemoveGlobalTimer(timer_id)
		end
	end
	timer_id = TimerUtil.AddGlobalTimer(1, false, callback)
	CPanelTracker.Instance():SetToggleInteratable("Tog_Team",false)
end
PBHelper.AddHandler("S2CArenaStart",Start3V3Arena)

--3V3结束
local function End3V3Arena(sender, msg)
	game._HostPlayer: Set3v3RoomID(0) 
	CPanelTracker.Instance():SetToggleInteratable("Tog_Team",true)
end
PBHelper.AddHandler("S2CArenaEnd",End3V3Arena)

--3V3 玩家信息
local function RevArenaData(sender, msg)
	if C3V3Panel.Instance():IsShow() then
		C3V3Panel.Instance():InitPlayerData(msg)
	end
end
PBHelper.AddHandler("S2CArenaData",RevArenaData)

--匹配未成功，返回到等待匹配状态
local function BackToMatching(sender, msg)
	game._HostPlayer: Set3v3RoomID(0) 
	game._GUIMan:Close("CPanelMate")
	game._GUIMan:Close("CPanel3v3Loading")	
	game._GUIMan:Open("CPanelMateOn", msg.RoleId)
end
PBHelper.AddHandler("S2CArenaBackToMatching",BackToMatching)


--3V3结算
local function On3V3ArenaReward(sender, msg)
	local data = {}
	data._Type = 3
	--删掉一些无用的数据，重新构建一组UI需要的数据
	local rewardData = 
	{
		RewardState = msg.RewardState,
		PassTime = msg.PassTime,
		Star = msg.Star,
		WinStreak = msg.WinStreak,
		Rewards = msg.Rewards,
		LeftTime = msg.LeftTime,
		Stage = msg.Stage,
		RedList = msg.RedList,
		BlackList = msg.BlackList
	}

	--[[
	for i,v in ipairs(msg.BlackList) do
    	warn("Reward Black",v.RoleId)
    end

     for i,v in ipairs( msg.RedList) do
    	warn("Reward Red",v.RoleId)
    end
	]]

	data._InfoData = rewardData
	game._GUIMan:SetNormalUIMoveToHide(true, 0, "CPanelDungeonEnd", data)
end
PBHelper.AddHandler("S2CArenaReward",On3V3ArenaReward)

--------------------3v3--------------------