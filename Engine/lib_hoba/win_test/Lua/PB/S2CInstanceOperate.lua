--
--副本相关的通信
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

local CPanelInstanceEnter = require "GUI.CPanelInstanceEnter"
local CPanelTracker = require "GUI.CPanelTracker"
local CPanelInstanceEnd = require "GUI.CPanelInstanceEnd"
local CAutoFight = require "ObjHdl.CAutoFight"

--副本结算面板延迟弹出时间
local instanceEndDelayId = 85

--房间匹配
local function OnS2CInstanceRoomInit(sender, msg)
	CPanelInstanceEnter.Instance():OnMatchTeam()			
end
PBHelper.AddHandler("S2CInstanceRoomInit", OnS2CInstanceRoomInit)

--房间信息
local function OnS2CInstanceRoomInfo(sender, msg)
	CPanelInstanceEnter.Instance():OnMultiConfirm(msg.resRoomInfo.InstanceId)
end
PBHelper.AddHandler("S2CInstanceRoomInfo", OnS2CInstanceRoomInfo)

--准备
local function OnS2CInstanceEnterPrepare(sender, msg)
	local instance = CElementData.GetTemplate("Instance", msg.resEnterPrepare.InstanceTId)
	if instance.InstanceType == 0 then
		CPanelTracker.Instance():AddInstanceTimer(msg.resEnterPrepare.DurationSeconds)
	else
		game._GUIMan:Open("CPanelTime", nil)
	end
end
PBHelper.AddHandler("S2CInstanceEnterPrepare", OnS2CInstanceEnterPrepare)

--开始
local function OnS2CInstanceEnterStart(sender, msg)
	local instance = CElementData.GetTemplate("Instance", msg.resEnterStart.InstanceTId)
	if instance.InstanceType == 0 then
		CPanelTracker.Instance():AddInstanceTimer(msg.resEnterStart.DurationSeconds)
	else
		CPanelTracker.Instance():AddInstanceTimer(msg.resEnterStart.DurationSeconds)
	end
end
PBHelper.AddHandler("S2CInstanceEnterStart", OnS2CInstanceEnterStart)

--进入副本
local function OnS2CInstanceEnterDungeon(sender,msg)
	game._DungeonMan:SetDungeonID(msg.dungeonTId)
end
PBHelper.AddHandler("S2CInstanceEnter", OnS2CInstanceEnterDungeon)

--离开副本
local function OnS2CExitDungeon(sender,msg)
	game._DungeonMan:ClearDungeonShow()
end
PBHelper.AddHandler("S2CInstanceLeave", OnS2CExitDungeon)

--结算
local function OnS2CInstanceEnterReward(sender, msg)
	local instanceEndDelayTime = tonumber(CElementData.GetTemplate("SpecialId", instanceEndDelayId).Value)
	local callback = function()
		--假设依旧在副本中
		if game._HostPlayer:InDungeon() then
			msg.resEnterReward.DurationSeconds = msg.resEnterReward.DurationSeconds - instanceEndDelayTime
			--game._GUIMan:Open("CPanelInstanceEnd", msg.resEnterReward)
			local data = {}
			data._Type = 0
			data._InfoData = msg.resEnterReward
			game._GUIMan:SetNormalUIMoveToHide(true, 0, "CPanelDungeonEnd", data)
		end
	end
	TimerUtil.AddGlobalTimer(instanceEndDelayTime, true, callback)
	game._GUIMan:ShowSuccessTimeTips(instanceEndDelayTime)
	CPanelTracker.Instance():RemoveInstanceTimer()
 	CAutoFight.Instance():Stop()
end
PBHelper.AddHandler("S2CInstanceEnterReward", OnS2CInstanceEnterReward)

--副本预警
local function OnS2CInstanceWarning(sender, msg)
	game._GUIMan:Open("CPanelInstanceAlarm",1.5)			
end
PBHelper.AddHandler("S2CInstanceWarning", OnS2CInstanceWarning)

--副本NPC对话
local function OnNpcConvertion(sender, msg)
	local talkData = {}
	talkData.NpcTId = msg.NpcTId
	talkData.DialogTId = msg.DialogueTId
	game._GUIMan:Open("CPanelDungeonNpcTalk",talkData)
	
	--if game._DungeonMan: InDungeon() then
	CPanelTracker.Instance():SetPanelMaxOrMin(false)
	--end
end
PBHelper.AddHandler("S2CNpcConvertion", OnNpcConvertion)

--[[
		副本数据同步
		INIT = 0;			// 初始化下发
		UPDATE_DATA  = 2;   // 数据更新]]
local function OnDungeonData(sender, msg)
	local resData = msg.resInstanceData
    if(resData.OptCode == 0) then    	
		for _,v in ipairs(resData.InstanceDataList) do
			game._DungeonMan: AddDungeonData(v)
			--warn("副本开启："..tostring(v.IsOpen).."特效开启"..tostring(v.IsPlayEffects))
		end
		
	elseif(msg.resInstanceData.OptCode == 2)then
		for _,v in ipairs(msg.resInstanceData.InstanceDataList) do
			game._DungeonMan: ChangeDungeonData(v)
		end
	end	

	--warn("CNorCount:"..resData.NormalEnterCount.."//".."ChardCount:"..resData.NightMareEnterCount.."//".."ChellCount:"..resData.HellEnterCount)
	game._DungeonMan: SetDungeonCount(resData.NormalEnterCount,resData.NightMareEnterCount,resData.HellEnterCount,resData.TowerTier)

end
PBHelper.AddHandler("S2CInstanceData", OnDungeonData)

--副本目标
local function OnAddDungeonGoals(sender, msg)
	game._DungeonMan: ClearDungeonGoal()
	for _,v in ipairs(msg.Goals.Goals) do
		game._DungeonMan: AddDungeonGoal(v)
	end

	--warn("S2CDungeonGoals")
end
PBHelper.AddHandler("S2CDungeonGoals",OnAddDungeonGoals)

--副本计数
local function OnDungeonGoalNotify(sender, msg)
	game._DungeonMan:ChangeDungeonGoal(msg.Id,msg.MaxCount,msg.CurCount)
end
PBHelper.AddHandler("S2CDungeonGoalsNotify",OnDungeonGoalNotify)

--副本伤害信息
local function OnS2CDungeonDamageStatistics(sender, msg)
	local data = {}
	data._Data = msg.DamageStatisticsDatas
	local mapTid = game._CurWorld._WorldInfo.MapTid
	data._Type = 0
	if mapTid == game._ArenaSceneOneId then
		data._Type = 2
	end
	game._GUIMan:Open("CPanelDungeonPlayer", data)
end
PBHelper.AddHandler("S2CDungeonDamageStatistics", OnS2CDungeonDamageStatistics)