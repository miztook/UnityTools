--
--副本相关的通信
--
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

local CPanelTracker = require "GUI.CPanelTracker"
local CPanelMinimap = require "GUI.CPanelMinimap"
local CPanelDungeonEnd = require"GUI.CPanelDungeonEnd"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require"Dungeon.CDungeonAutoMan"
local CPath = require"Path.CPath"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
--副本结算面板延迟弹出时间
local instanceEndDelayId = 85

--房间匹配
local function OnS2CInstanceRoomInit(sender, msg)
	local callback = function()
        local protocol = (require "PB.net".C2SConfirmCancel)()
        protocol.reqConfirmCancel.InstanceId = game._DungeonMan: GetMatchID()
        PBHelper.Send(protocol)
    end
    --提示匹配 
    local title, msg, closeType = StringTable.GetMsg(66)
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)	
    game._DungeonMan: SetMatchID(0)	
end
PBHelper.AddHandler("S2CInstanceRoomInit", OnS2CInstanceRoomInit)

--房间信息
local function OnS2CInstanceRoomInfo(sender, msg)
	MsgBox.CloseAll()
	local nInstanceID = msg.resRoomInfo.InstanceId
    --信息回调
    local callback = function(value)
        if value then
            local protocol = (require "PB.net".C2SConfirmOk)()
            protocol.reqConfirmOk.InstanceId = nInstanceID
            PBHelper.Send(protocol)
        else
            local protocol = (require "PB.net".C2SConfirmCancel)()
            protocol.reqConfirmCancel.InstanceId = nInstanceID
            PBHelper.Send(protocol)
        end
    end
    local title, msg, closeType = StringTable.GetMsg(67)
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
    game._DungeonMan: SetMatchID(0)	
end
PBHelper.AddHandler("S2CInstanceRoomInfo", OnS2CInstanceRoomInfo)

--准备
local function OnS2CInstanceEnterPrepare(sender, msg)
	local instance = CElementData.GetTemplate("Instance", msg.resEnterPrepare.InstanceTId)
	local EInstanceType = require "PB.Template".Instance.EInstanceType

	if instance.InstanceType == EInstanceType.INSTANCE_NORMAL or instance.InstanceType == EInstanceType.INSTANCE_GUILD_BATTLEFIELD then
		CPanelTracker.Instance():AddDungeonTime(msg.resEnterPrepare.EndTime, 0)
		--重置副本显示状态
		CPanelTracker.Instance():ResetDungeonShow()
	elseif instance.InstanceType == EInstanceType.INSTANCE_JJC1X1 or  instance.InstanceType == EInstanceType.INSTANCE_PVP3X3 or instance.InstanceType == EInstanceType.INSTANCE_ELIMINATE then
		game._GUIMan:Close("CPanelMirrorArena")
		game._GUIMan:Open("CPanelTime", nil)
		local time,timer_id = 0,0
		local callback = function()
			time = time + 1
			CSoundMan.Instance():Play2DAudio(PATH.GUISound_Window_Count, 0)
			if time == 3 then
				_G.RemoveGlobalTimer(timer_id)
			end
		end
		timer_id = _G.AddGlobalTimer(1, false, callback)
	elseif instance.InstanceType == EInstanceType.INSTANCE_EXPEDITION then
		game._GUIMan:Close("CPanelUIExpeditionList")
		game._GUIMan:Close("CPanelUIExpedition")
		--重置副本显示状态
		CPanelTracker.Instance():ResetDungeonShow()
	end
end
PBHelper.AddHandler("S2CInstanceEnterPrepare", OnS2CInstanceEnterPrepare)

--开始
local function OnS2CInstanceEnterStart(sender, msg)
	game._DungeonMan:OnDungeonStart(msg)
	--warn("S2CInstanceEnterStart")
end
PBHelper.AddHandler("S2CInstanceEnterStart", OnS2CInstanceEnterStart)

--进入副本
local function OnS2CInstanceEnterDungeon(sender,msg)
	CAutoFightMan.Instance():Stop()
	game._GUIMan:Close("CPanelUIDungeon")
	local CPanelCalendar = require "GUI.CPanelCalendar"
	if CPanelCalendar.Instance():IsShow() then
		game._GUIMan:Close("CPanelCalendar")
	end
	local CPanelUIActivity = require "GUI.CPanelUIActivity"
	if CPanelUIActivity.Instance():IsShow() then
		game._GUIMan:Close("CPanelUIActivity")
	end
    local CPanelUITeamMatchingBoard = require "GUI.CPanelUITeamMatchingBoard"
    if CPanelUITeamMatchingBoard.Instance():IsShow() then
        game._GUIMan:Close("CPanelUITeamMatchingBoard")
    end
    local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
    if CPanelUITeamMember.Instance():IsShow() then
        game._GUIMan:Close("CPanelUITeamMember")
    end

    local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"
    local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
    CPVEAutoMatch.Instance():StopAll()
    if game._CArenaMan._IsMatching3V3 then 
    	CPVPAutoMatch.Instance():Stop()
    	game._CArenaMan._IsMatching3V3 = false
    end
    if game._CArenaMan._IsMatchingBattle then 
    	CPVPAutoMatch.Instance():Stop()
    	game._CArenaMan._IsMatchingBattle = false
    end
	game._DungeonMan:OnEnterDungeon(msg)
end
PBHelper.AddHandler("S2CInstanceEnter", OnS2CInstanceEnterDungeon)

--离开副本
local function OnS2CExitDungeon(sender,msg)
	game._DungeonMan:OnLeaveDungeon()	
end
PBHelper.AddHandler("S2CInstanceLeave", OnS2CExitDungeon)

--结算
local function OnS2CInstanceEnterReward(sender, msg)
	-- 停止组队跟随
	--game._HostPlayer:StopAutoFollow()
	-- 结算隐藏路径及目标
	local CPath = require "Path.CPath"
	CPath.Instance():Hide()
	local GuildId = CSpecialIdMan.Get("GuildMapID")
	local instanceEndDelayTime = tonumber(CElementData.GetTemplate("SpecialId", instanceEndDelayId).Value)
	local callback = function()
		--假设依旧在副本中
		if game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate() or msg.resEnterReward.InstanceTId == GuildId then
			game:QuitNearCam()
			msg.resEnterReward.DurationSeconds = msg.resEnterReward.DurationSeconds - instanceEndDelayTime
			--game._GUIMan:Open("CPanelInstanceEnd", msg.resEnterReward)
			local data = {}
			local ins = msg.resEnterReward.InstanceTId
			if msg.resEnterReward.InstanceTId == CSpecialIdMan.Get("TowerDungeonID") then 
				data._Type = EnumDef.DungeonEndType.TrialType
			elseif msg.resEnterReward.InstanceTId == GuildId then 
				data._Type = EnumDef.DungeonEndType.GuildDefend
			else
				data._Type = EnumDef.DungeonEndType.InstanceType
			end
			data._InfoData = msg.resEnterReward
			game._GUIMan:SetNormalUIMoveToHide(true, 0, "CPanelDungeonEnd", data)
		end
	end
	_G.AddGlobalTimer(instanceEndDelayTime, true, callback)
	--CPanelMinimap.Instance():RemoveInstanceTimer()
 	if msg.resEnterReward.IsWin then
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Finish_Success, 0)
 	else
		CSoundMan.Instance():Play2DAudio(PATH.GUISound_Finish_Fail, 0)
 	end

	CAutoFightMan.Instance():Stop()
	
 	game._PlayerStrongMan:SetNeedPlayerStrong(not msg.resEnterReward.IsWin)

	local event = require("Events.DungeonResultEvent")()
	CGame.EventManager:raiseEvent(nil, event)
end
PBHelper.AddHandler("S2CInstanceEnterReward", OnS2CInstanceEnterReward)

-- 副本评级奖励 
local function OnS2CInstanceScore(sender,msg)
	CPanelDungeonEnd.Instance():SaveInstanceScore(msg.ResourceType,msg.Ratio,msg.ConversionNum)
end
PBHelper.AddHandler("S2CInstanceScore", OnS2CInstanceScore)


--副本预警
local function OnS2CInstanceWarning(sender, msg)
	game._GUIMan:Open("CPanelInstanceAlarm",1.5)			
end
PBHelper.AddHandler("S2CInstanceWarning", OnS2CInstanceWarning)

--副本NPC对话
local function OnNpcConvertion(sender, msg)
	if game._HostPlayer:IsDead() then return end --人物死亡。不显示NPC对话了

	--local talkData = {}
	--talkData.NpcTId = msg.NpcTId
	--talkData.NpcTId = 223
	--talkData.DialogTId = msg.DialogueTId
	--talkData.DialogTId = 241
	--print_r(talkData)
	game._GUIMan:Open("CPanelDungeonNpcTalk",msg.DialogueTId)
	
	--if game._DungeonMan: InDungeon() then
	CPanelTracker.Instance():ShowSelfPanel(false)
	--end
end
PBHelper.AddHandler("S2CNpcConvertion", OnNpcConvertion)

--[[
		副本数据同步
		INIT = 0;			// 初始化下发
		UPDATE_DATA  = 2;   // 数据更新]]
local function OnDungeonData(sender, msg)
	local InstanceDataUpdate = require "PB.net".ResInstanceData.InstanceDataUpdate
	local resData = msg.resInstanceData
    if(resData.OptCode == InstanceDataUpdate.INIT) then    	
		for _,v in ipairs(resData.InstanceDataList) do
			game._DungeonMan:AddDungeonData(v)
			--warn("副本开启："..tostring(v.IsOpen).."特效开启"..tostring(v.IsPlayEffects))
		end
		
	elseif(msg.resInstanceData.OptCode == InstanceDataUpdate.UPDATE_DATA)then
		for _,v in ipairs(msg.resInstanceData.InstanceDataList) do
			game._DungeonMan:ChangeDungeonData(v)
		end
	elseif(msg.resInstanceData.OptCode == InstanceDataUpdate.DUNGEON_TIMER)then
		local CPanelMinimap = require "GUI.CPanelMinimap"
		CPanelMinimap.Instance():HideDungeonShow()
		--warn("InstanceDataUpdate.DUNGEON_TIMER")
	end	

	-- warn("S2CInstanceData TowerTier:", msg.resInstanceData.TowerTier, " TowerBestPassTime:", msg.resInstanceData.TowerBestPassTime)
	game._DungeonMan:SetTowerFloorAndTime(msg.resInstanceData.TowerTier, msg.resInstanceData.TowerBestPassTime)
	game._DungeonMan:SetExpeditionAffixs(msg.resInstanceData.affixs)
end
PBHelper.AddHandler("S2CInstanceData", OnDungeonData)

--副本目标
local function OnAddDungeonGoals(sender, msg)	
	game._DungeonMan:AddDungeonGoal(msg.Goals)
	CDungeonAutoMan.Instance():ChangeGoal()

	--warn("S2CDungeonGoals")
end
PBHelper.AddHandler("S2CDungeonGoals",OnAddDungeonGoals)

--副本计数
local function OnDungeonGoalNotify(sender, msg)
	game._DungeonMan:ChangeDungeonGoal(msg.Id,msg.CurCount)
	CDungeonAutoMan.Instance():ChangeGoal()
end
PBHelper.AddHandler("S2CDungeonGoalsNotify",OnDungeonGoalNotify)

--副本完成
local function OnS2CInstanceReachAllObj(sender, msg)
	game._DungeonMan:ClearDungeonGoal()
	game._DungeonMan:ReachAll()
end
PBHelper.AddHandler("S2CInstanceReachAllObj",OnS2CInstanceReachAllObj)



--副本BOSS技能预警提示
local function OnS2CBossUseSkillNotify(sender,msg)
	local skillID = msg.skillId
	local skilldata = CElementData.GetSkillTemplate(skillID)
	local monsterID = msg.param
	local monsterdata = CElementData.GetMonsterTemplate(monsterID)
	if skilldata ~= nil and monsterdata ~= nil then
		local tips = string.format(StringTable.Get(535),monsterdata.TextDisplayName,skilldata.Name)
		game._GUIMan:ShowAttentionTips(tips, EnumDef.AttentionTipeType._Boss, 1.5)
	end
end
PBHelper.AddHandler("S2CBossUseSkillNotify", OnS2CBossUseSkillNotify)


--BOSS镜头动画
local function OnS2CBossCameraAnimation(sender,msg)  
    game._DungeonMan:BOSSEnterAnimation(msg.EntityId,msg.AnimationName,msg.Param)
end
PBHelper.AddHandler("S2CCameraEvent", OnS2CBossCameraAnimation)


--Pass镜头动画
local function OnS2CClickFlag(sender,msg)  
	-- warn("OnS2CClickFlag", msg.flag)
	local EType = require "PB.data".EClickFlag 
	if msg.flag == EType.EClickFlag_endCameraAnimation then
		game._DungeonMan:FinishBOSSEnterAnimation()
	end
end
PBHelper.AddHandler("S2CClickFlag", OnS2CClickFlag)

--远征副本信息
local function OnS2CRevExpeditionData(sender,msg)
	game._DungeonMan:SetExpetionData(msg)

	local CPanelUIExpeditionList = require"GUI.CPanelUIExpeditionList"
	if CPanelUIExpeditionList.Instance():IsShow() then
		CPanelUIExpeditionList.Instance():InitPanelShow()
	end
	local CPanelUIExpedition = require "GUI.CPanelUIExpedition"
	if CPanelUIExpedition.Instance():IsShow() then
		CPanelUIExpedition.Instance():InitPanelShow()
	end
end
PBHelper.AddHandler("S2CExpedition", OnS2CRevExpeditionData)

-- 副本通用介绍弹窗
local function OnS2CDungeonEnterInterface(sender,msg)
	game._DungeonMan:SetCurIntroductionPopupTID(msg.tempId)

	game._GUIMan:Open("CPanelUIDungeonIntroduction", msg.tempId)
	local CPanelMinimap = require "GUI.CPanelMinimap"
	CPanelMinimap.Instance():EnableDungeonIntroductionBtn(true)
end
PBHelper.AddHandler("S2CDungeonEnterInterface", OnS2CDungeonEnterInterface)

-- 副本通用进度条
local function OnS2CDungeonProgress(sender,msg)
	local CPanelMainChat = require "GUI.CPanelMainChat"
	if CPanelMainChat and CPanelMainChat.Instance():IsShow() then
		CPanelMainChat.Instance():OnDungeonProgress(msg)
	end
end
PBHelper.AddHandler("S2CDungeonProgress", OnS2CDungeonProgress)

-- 副本事件倒计时
local function OnS2CDungeonCountDown(sender,msg)
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker and CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():AddDungeonCountdown(msg.EndTime, msg.name)
	end
end
PBHelper.AddHandler("S2CDungeonCountDown", OnS2CDungeonCountDown)

-- 强锁或解锁单位
local function OnS2CChangeLockTarget(sender,msg)
	warn("OnS2CChangeLockTarget entityId:", msg.entityId, "isLock:", msg.isLock)
	if msg.isLock then
		local entity = game._CurWorld:FindObject(msg.entityId)
		if entity ~= nil then
			game._HostPlayer:UpdateTargetInfo(entity, true)
		end
	else
		game._HostPlayer:UpdateTargetInfo(nil, false)
	end
end
PBHelper.AddHandler("S2CChangeLockTarget", OnS2CChangeLockTarget)

-- 修改单位碰撞体半径
local function OnS2CChangeEntityCollisionRadius(sender,msg)
	-- warn("OnS2CChangeEntityCollisionRadius entityId:", msg.entityId, "CollisionRadius:", msg.CollisionRadius)
	local entity = game._CurWorld:FindObject(msg.entityId)
	if entity ~= nil then
		entity:SetRadius(msg.CollisionRadius)
	end
end
PBHelper.AddHandler("S2CChangeEntityCollisionRadius", OnS2CChangeEntityCollisionRadius)