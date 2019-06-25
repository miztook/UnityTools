--
-- S2CTeam
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CTeamMan = require "Team.CTeamMan"
local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"
local NotifyComponents = require "GUI.NotifyComponents"
local CElementData = require "Data.CElementData"

local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end

local function SendChangeEvent(type, data)
	local event = TeamInfoChangeEvent()
	event._Type = type

	if data then
		event._ChangeInfo = data
	end

	CGame.EventManager:raiseEvent(nil, event)
end

local function SendMsgToSysteamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
end
local function SendMsgToTeamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelTeam, msg, false, 0, nil,nil)
end

local function Refresh()
	CTeamMan.Instance():RefreshPanel()
end

local function SetDefaultTeamName(leaderID)
    CTeamMan.Instance():SetDefaultTeamName(leaderID)
end

local function ChangeTeamInfo(data)
	local ETeamInfo = require "PB.net".TeamInfoChange_s2cd
	local TeamInfoChangeType = EnumDef.TeamInfoChangeType

	if data.type == ETeamInfo.TYPE.TYPE_HP then
		--print("血量同步")
		CTeamMan.Instance():ChangeMemberHp(data.hpInfo)
		SendChangeEvent(TeamInfoChangeType.Hp, data.hpInfo)

	elseif data.type == ETeamInfo.TYPE.TYPE_LEVEL then
		--print("等级同步")
		CTeamMan.Instance():ChangeMemberLevel(data.levelInfo)
		SendChangeEvent(TeamInfoChangeType.Level, data.levelInfo)

	elseif data.type == ETeamInfo.TYPE.TYPE_MAP_INFO then
		--print("线路同步")
		CTeamMan.Instance():ChangeMemberMapInfo(data.mapInfo)
		SendChangeEvent(TeamInfoChangeType.MapInfo, data.mapInfo)

	elseif data.type == ETeamInfo.TYPE.TYPE_ONOFFLINE then
		--print("在线状态同步")
		CTeamMan.Instance():ChangeMemberOnline(data.onOffLine)
		SendChangeEvent(TeamInfoChangeType.OnLineState, data.onOffLine)

	elseif data.type == ETeamInfo.TYPE.TYPE_FOLLOW then
		--print("跟随状态同步")
		CTeamMan.Instance():ChangeMemberFollow(data.followInfo)
		SendChangeEvent(TeamInfoChangeType.FollowState, data.followInfo)

		local entity = game._CurWorld:FindObject(data.followInfo.roleId)
		if entity ~= nil and entity:IsHostPlayer() then
			if data.followInfo.isFollow then
				-- 开始跟随，退出外观和近景
				local CExteriorMan = require "Main.CExteriorMan"
				CExteriorMan.Instance():Quit()
				game:QuitNearCam()
			end
		end
	elseif data.type == ETeamInfo.TYPE.TYPE_FIGHTSCORE then
		--print("战斗力同步")
		CTeamMan.Instance():ChangeFightScore(data.fightScoreInfo)
		SendChangeEvent(TeamInfoChangeType.FightScore, data.fightScoreInfo)

	elseif data.type == ETeamInfo.TYPE.TYPE_BOUNTY then
		--print("赏金模式同步")
		--CTeamMan.Instance():ChangeBounty(data.bountyInfo)

	elseif data.type == ETeamInfo.TYPE.TYPE_TARGETCHANGE then
		--print("队伍目标同步")
		CTeamMan.Instance():ChangeTeamTarget(data.targetChange)
        SendChangeEvent(TeamInfoChangeType.TARGETCHANGE, data.matchState)
	elseif data.type == ETeamInfo.TYPE.TYPE_MATCHSTATECHANGE then
		--print("匹配状态同步")
--		CTeamMan.Instance():ChangeTeamMatchState(data.matchState)
--        SendChangeEvent(TeamInfoChangeType.MATCHSTATECHANGE, data.matchState)
	elseif data.type == ETeamInfo.TYPE.TYPE_POSITION then
		--print("队员位置信息改变")
		CTeamMan.Instance():ChangeMemberPosition(data.positionInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_AutoApproval then
		--print("自动批准 ", data.autoApproval.autoApproval)
		CTeamMan.Instance():ChangeAutoApprove(data.autoApproval.autoApproval)
	elseif data.type == ETeamInfo.TYPE.TYPE_InvitateStatus then
		-- warn("data.invitateStatus.status = ", data.invitateStatus.status)
		CTeamMan.Instance():SetInvitingState(data.invitateStatus.status > 0)
		SendChangeEvent(TeamInfoChangeType.InvitateStatus, data.invitateStatus)
    elseif data.type == ETeamInfo.TYPE.TYPE_MODE then
        -- warn("转化为团队 ", data.changeMode.teamId,data.changeMode.mode)
        local TeamMode = require "PB.data".TeamMode
        if CTeamMan.Instance():InSameTeam(data.changeMode.teamId) then
            CTeamMan.Instance():SetSelfTeamMode(data.changeMode.mode)
        end
        SendChangeEvent(TeamInfoChangeType.TeamMode, data.changeMode)
    elseif data.type == ETeamInfo.TYPE.TYPE_NAME then
    	warn("队员名称改变 ", data.memberName.roleId, data.memberName.newName)
    	CTeamMan.Instance():ChangeMemberName(data.memberName.roleId, data.memberName.newName)
    	SendChangeEvent(TeamInfoChangeType.TeamMemberName, data.memberName)
	end
end

local function TurnPanelTeamMember()
	-- warn("=========TurnPanelTeamMember==========", debug.traceback())
	if not CTeamMan.Instance():IsTeamLeader() then
		game._GUIMan:Close("CPanelUITeamCreate")
		game._GUIMan:Open("CPanelUITeamMember", nil)
	end 
end

local function SetApplicationList(data)
	local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
	if CPanelUITeamInvite and CPanelUITeamInvite.Instance() then
		CPanelUITeamInvite.Instance():UpdateApplyList(data)
	end
end

local function SetTeamList(data)
	--warn("======OnS2CTeam::获取队伍列表=======")
	local CPanelUITeamCreate = require "GUI.CPanelUITeamCreate"
	if CPanelUITeamCreate then
		CPanelUITeamCreate.Instance():SetTeamList(data)
	end
end

local function QuitTeam(data, id)
	--warn("======OnS2CTeam::离开队伍=======")
	--warn("leaveid == ", id)
	local hp = game._HostPlayer
	local teamMan = CTeamMan.Instance()

	if id == hp._ID then
		teamMan:UpdateAllMemberPateNameInSight()

		SendFlashMsg( StringTable.Get(208) )
		if hp:In3V3Fight() then
			teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		else
			teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
		end
		teamMan:ResetMemberList()
	else
		local strMemberName = teamMan:GetTeamMemberName(id)
		SendMsgToTeamChannel( strMemberName..StringTable.Get(224) )
		teamMan:UpdateMemberList(data)
	end
end

local function DisbandTeam()
	local hp = game._HostPlayer
	local teamMan = CTeamMan.Instance()
	teamMan:UpdateAllMemberPateNameInSight()

	SendMsgToSysteamChannel( StringTable.Get(222) )

	teamMan:ResetMemberList()
	local hp = game._HostPlayer
	if hp:In3V3Fight() then
		teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
	else
		teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
	end
	
	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
	if CPanelUITeamMember and CPanelUITeamMember.Instance():IsShow() then
		game._GUIMan:CloseByScript(CPanelUITeamMember.Instance())
	end

	Refresh()
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end

--创建队伍
local function OnS2CTeamCreate(sender, msg)	
-- warn("OnS2CTeamCreate=============")
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
    SetDefaultTeamName(msg.teamInfo.info.capture)
	Refresh()

	local hp = game._HostPlayer
	game._GUIMan:Close("CPanelUITeamCreate")
	
	if hp:InDungeon() or game:IsInBeginnerDungeon() then
		return
	end

	-- warn("打开组队页面显示", hp:InDungeon(), game:IsInBeginnerDungeon())
	-- 打开组队页面显示
	game._GUIMan:Open("CPanelUITeamMember",nil)
end
PBHelper.AddHandler("S2CTeamCreate", OnS2CTeamCreate)

--申请组队
local function OnS2CTeamApply(sender, msg)
--warn("OnS2CTeamApply===============")
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	TurnPanelTeamMember()
	Refresh()
end
PBHelper.AddHandler("S2CTeamApply", OnS2CTeamApply)

--队长接受申请
local function OnS2CTeamApplyAckAccept(sender, msg)
	-- warn("OnS2CTeamApplyAckAccept...............")
	for i,v in ipairs(msg.teamInfo.memberList) do
		if v.roleID == msg.teamInfo.info.modifyRoleID then
			if v.roleID == game._HostPlayer._ID then
				TurnPanelTeamMember()
				SendMsgToTeamChannel( StringTable.Get(229) )
			else
				SendMsgToTeamChannel( v.name..StringTable.Get(229) )
			end
		end
	end

	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	Refresh()
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
    SendChangeEvent(EnumDef.TeamInfoChangeType.NewRoleComeIn)
end
PBHelper.AddHandler("S2CTeamApplyAckAccept", OnS2CTeamApplyAckAccept)

--队长拒绝申请
local function OnS2CTeamApplyAckRefuse(sender, msg)	
	--TODO
end
PBHelper.AddHandler("S2CTeamApplyAckRefuse", OnS2CTeamApplyAckRefuse)

--邀请组队
local function OnS2CTeamInvitate(sender, msg)
    
end
PBHelper.AddHandler("S2CTeamInvitate", OnS2CTeamInvitate)

--接受邀请组队
local function OnS2CTeamInvitateAckAccept(sender, msg)
--warn("OnS2CTeamInvitateAckAccept==============")
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	Refresh()
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
    --SendChangeEvent(EnumDef.TeamInfoChangeType.NewRoleComeIn)
end
PBHelper.AddHandler("S2CTeamInvitateAckAccept", OnS2CTeamInvitateAckAccept)

--拒绝邀请组队
local function OnS2CTeamInvitateAckRefuse(sender, msg)	
	--TODO
end
PBHelper.AddHandler("S2CTeamInvitateAckRefuse", OnS2CTeamInvitateAckRefuse)

--离开队伍
local function OnS2CTeamLeave(sender, msg)
-- warn("OnS2CTeamLeave===============", msg.teamLeaveInfo.leaveRoleID)
	--主动离开
	QuitTeam(msg.teamInfo, msg.teamLeaveInfo.leaveRoleID)
	Refresh()
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamLeave", OnS2CTeamLeave)

--队长T人
local function OnS2CTeamT(sender, msg)
--warn("OnS2CTeamT===============")

	local hp = game._HostPlayer
	local teamMan = CTeamMan.Instance()
	--被T了
	if msg.teamTDataInfo.TroleID == hp._ID then
		teamMan:UpdateAllMemberPateNameInSight()

		if hp:In3V3Fight() then
			teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		else
			teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
		end
		
		teamMan:ResetMemberList()
		SendFlashMsg( StringTable.Get(239) )

		local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
		if CPanelUITeamMember and CPanelUITeamMember.Instance():IsShow() then
			game._GUIMan:CloseByScript(CPanelUITeamMember.Instance())
		end
	else
		local str = string.format(StringTable.Get(240), msg.teamTDataInfo.TName)
		-- SendFlashMsg( str )
		SendMsgToTeamChannel(str)
		CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	end
	Refresh()
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamT", OnS2CTeamT)

--队长变换
local function OnS2CTeamExchangeCapation(sender, msg)
--warn("S2CTeamExchangeCapation==============")
	--队长变化，临时将客户端状态先行停止。服务器后端因传到world会滞后消息，跟随重构后挪到服务器即没有问题。
	--local followLocalData = { roleId = game._HostPlayer._ID,isFollow = false }
	--CTeamMan.Instance():ChangeMemberFollow(followLocalData)
	--SendChangeEvent(EnumDef.TeamInfoChangeType.FollowState, followLocalData)

	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	local captureName = msg.teamInfo.info.capture

	if game._HostPlayer._ID == msg.teamInfo.info.captainID then
		captureName = StringTable.Get(248)
	else
		local teamMan = CTeamMan.Instance()
		teamMan:SetTeamApplyRedDotState(false)
		teamMan:RefreshTeamApplyRedDotState()
	end
	-- SendFlashMsg(string.format(StringTable.Get(247), captureName))
	SendMsgToTeamChannel(string.format(StringTable.Get(247), captureName))
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamExchangeCapation", OnS2CTeamExchangeCapation)

----自动加入设置
--local function OnS2CTeamAutoJoin(sender, msg)	
--	--SetAutoJoinInfo(msg.teamAutoJoinCondition)
--end
--PBHelper.AddHandler("S2CTeamAutoJoin", OnS2CTeamAutoJoin)

--获得地图组队列表
local function OnS2CTeamList(sender, msg)
--warn("OnS2CTeamList==============", msg)
	SetTeamList(msg.teamListInMap.teamInfoList)
end
PBHelper.AddHandler("S2CTeamList", OnS2CTeamList)

--获得本队数据
local function OnS2CTeamGetTeamInfo(sender, msg)
	--warn("OnS2CTeamGetTeamInfo::获得本队数据")
	-- 完全同步客户端队伍数据，因数据跨game 有几率发送不成功
	CTeamMan.Instance():ResetMemberList()

	if msg.teamInfo == nil or
	   msg.teamInfo.info == nil or
	   msg.teamInfo.info.teamID == nil or
	   msg.teamInfo.info.teamID <= 0 then
	   	Refresh()
		return
	end

	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	Refresh()
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamGetTeamInfo", OnS2CTeamGetTeamInfo)

--队长获得队伍申请数据
local function OnS2CTeamGetApplyInfo(sender, msg)
--warn("OnS2CTeamGetApplyInfo=============")
	SetApplicationList(msg.applicationInfo.applicationInfoList)
end
PBHelper.AddHandler("S2CTeamGetApplyInfo", OnS2CTeamGetApplyInfo)


--实时更新队伍申请数据
local function OnS2CTeamApplyCount(sender, msg)	
	--warn("实时更新队伍申请数据 Count = ", msg.teamApplicationCount.num)
	if msg.teamApplicationCount.num > 0 then
		
	else
		-- --清空申请列表
		-- local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
		-- if CPanelUITeamInvite.Instance() then
		-- 	CPanelUITeamInvite.Instance():UpdateApplyList({})
		-- end
		
		--清空通知列表
        MsgNotify.Remove(EnumDef.NotificationType.TeamApplication)

        CTeamMan.Instance():SetTeamApplyRedDotState(false)
        CTeamMan.Instance():RefreshTeamApplyRedDotState()
	end
end
PBHelper.AddHandler("S2CTeamApplyCount", OnS2CTeamApplyCount)


--队伍相关属性变化同步
local function OnS2CTeamChange(sender, msg)	
	ChangeTeamInfo(msg.teamInfoChangeData)
end
PBHelper.AddHandler("S2CTeamChange", OnS2CTeamChange)

--队伍解散
local function OnS2CTeamDisband(sender, msg)
--warn("OnS2CTeamDisband==============")
	DisbandTeam()
end
PBHelper.AddHandler("S2CTeamDisband", OnS2CTeamDisband)

--队伍Id同步
local function OnS2CPlayerTeamChange(sender, msg)
--warn("OnS2CPlayerTeamChange============")
	local entity = game._CurWorld:FindObject(msg.PlayerId) 
	if entity == nil then return end

	entity._TeamId = msg.TeamId
end
PBHelper.AddHandler("S2CPlayerTeamChange", OnS2CPlayerTeamChange)

--组队确认
local function OnS2CTeamFollowConfirm(sender,protocol)
--warn("=============OnS2CTeamFollowConfirm=============")
	CTeamMan.Instance():ShowTeamFollowConfirm()
end
PBHelper.AddHandler("S2CTeamFollowConfirm", OnS2CTeamFollowConfirm)

----自动匹配操作反馈
--local function OnS2CTeamAutoMatchTarget(sender,protocol)
----warn("=============OnS2CTeamAutoMatchTarget=============")
--	CTeamMan.Instance():OnS2CTeamAutoMatchTarget(protocol.TargetId)
--end
--PBHelper.AddHandler("S2CTeamAutoMatchTarget", OnS2CTeamAutoMatchTarget)

--队友已准备
local function OnS2CTeamMemberConfirmed(sender,protocol)
--warn("=============OnS2CTeamMemberConfirmed=============")
	CTeamMan.Instance():OnS2CTeamMemberConfirmed(protocol.roleId)
end
PBHelper.AddHandler("S2CTeamMemberConfirmed", OnS2CTeamMemberConfirmed)

--进入确认界面弹出成功
local function OnS2CTeamStartPrepare(sender,protocol)
    --warn("=============OnS2CTeamStartPrepare=============")
	CTeamMan.Instance():OnS2CTeamStartPrepare(protocol.DeadLine, protocol.DungeonTid)
end
PBHelper.AddHandler("S2CTeamStartPrepare", OnS2CTeamStartPrepare)

--[[
--进入确认界面弹出失败。  【【现在改成服务器直接发送系统消息提示了】】
local function OnS2CTeamPrepareFail(sender,protocol)
	local FailReason = require "PB.net".TeamRoomPrepareFailInfo.FailReason
	local ret = protocol.info.failReason

	if FailReason.NOT_IN_AOI == ret then
		--warn("不在队长视野内")
		SendMsgToSysteamChannel( string.format( StringTable.Get(22001),protocol.info.failRoleName ) )
	elseif FailReason.NOT_FOLLOW == ret then
		--warn("没有跟随队长 ")	
		SendMsgToSysteamChannel( string.format( StringTable.Get(22002),protocol.info.failRoleName ) )
	elseif FailReason.ENTER_TIMES_NOT_ENOUGH == ret then
		--warn("进入次数不足")	
		SendMsgToSysteamChannel( string.format( StringTable.Get(22003),protocol.info.failRoleName ) )
	elseif FailReason.NOT_COMFIRM == ret then
		--warn("未确认")	
		SendMsgToSysteamChannel( string.format( StringTable.Get(22004),protocol.info.failRoleName ) )
	elseif FailReason.REFRUSE == ret then
		--warn("拒绝")	
		SendMsgToSysteamChannel( string.format( StringTable.Get(22005),protocol.info.failRoleName ) )
	elseif FailReason.TEAM_MEMBER_IN_DUNGEON == ret then
		SendMsgToSysteamChannel( string.format( StringTable.Get(22016),protocol.info.failRoleName ) )
	elseif FailReason.LEVEL_NOT_ENOUGH == ret then
		SendMsgToSysteamChannel( string.format( StringTable.Get(22017),protocol.info.failRoleName ) )
	end

	CTeamMan.Instance():OnS2CTeamPrepareFail(protocol.info)
end
PBHelper.AddHandler("S2CTeamPrepareFail", OnS2CTeamPrepareFail)
]]

--确认界面结果
local function OnS2CTeamPrepareResult(sender,protocol) 
--warn("=============OnS2CTeamPrepareResult=============")
	local CPanelDungeonEnd = require"GUI.CPanelDungeonEnd"
	CTeamMan.Instance():OnS2CTeamPrepareResult(protocol.success)
	if CPanelDungeonEnd.Instance():IsShow() and protocol.success then
		game._GUIMan:Close("CPanelDungeonEnd")
		game._GUIMan:Open("CPanelLoading" ,{BGResPathId = game._CurWorld._WorldInfo.SceneTid})
        --game._NetMan:SetProtocolPaused(true)
		CPanelDungeonEnd.Instance():CloseLoadingPanel()
		GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
		GameUtil.SetCamToDefault(true, true, false, true)
	end

	if protocol.success then
		-- 确认成功，退出外观
		local CExteriorMan = require "Main.CExteriorMan"
		CExteriorMan.Instance():Quit()
		game:QuitNearCam()
	end
end
PBHelper.AddHandler("S2CTeamPrepareResult", OnS2CTeamPrepareResult)

--返回当前设置信息
local function OnS2CTeamMatchSetting(sender,protocol)
--warn("OnS2CTeamMatchSetting================")
	CTeamMan.Instance():OnS2CTeamMatchSetting(protocol)
end
PBHelper.AddHandler("S2CTeamMatchSetting", OnS2CTeamMatchSetting)

--协议名称
local function OnS2CTeamCanInviteRoleList(sender,protocol)
--warn("=============OnS2CTeamCanInviteRoleList=============")
	CTeamMan.Instance():OnS2CTeamCanInviteRoleList(protocol.roleList)
end
PBHelper.AddHandler("S2CTeamCanInviteRoleList", OnS2CTeamCanInviteRoleList)

-- 可邀请的各个页签的数量信息
local function OnS2CTeamCanApplyCount(sender, protocol)
    CTeamMan.Instance():OnS2CTeamCount(protocol.GuidCount, protocol.FirendCount, protocol.ApplyCount)
end
PBHelper.AddHandler("S2CTeamCount", OnS2CTeamCanApplyCount)

local function OnS2CTeamNameChange(sender, protocol)
    CTeamMan.Instance():OnS2CTeamNameChange(protocol.teamName)
end
PBHelper.AddHandler("S2CTeamNameChange", OnS2CTeamNameChange)

--队员装备信息
local function OnS2CTeamEquipInfo(sender,protocol)
-- warn("=============OnS2CTeamEquipInfo=============")
	local teamMan = CTeamMan.Instance()
	local hp = game._HostPlayer

	-- 如果是第一次初始化 并且 （不在新手本 或 副本中）方可显示
	if teamMan:IsFirtstInit() and (hp:InDungeon() or game:IsInBeginnerDungeon()) then
		teamMan:SetIsFirtstInit(false)
		return
	end

	CTeamMan.Instance():OnS2CTeamEquipInfo(protocol.Info)
end
PBHelper.AddHandler("S2CTeamEquipInfo", OnS2CTeamEquipInfo)

--组队跟随自动战斗逻辑开关
local function OnS2CTeamAutoFight(sender,protocol)
	local bAutoFight = protocol.autoFight

	local hp = game._HostPlayer
	hp:CancelSyncPosWhenMove(not bAutoFight)

	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	if bAutoFight then
		CAutoFightMan.Instance():Start()
        CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, false)
	else
		CAutoFightMan.Instance():Stop()
	end
end
PBHelper.AddHandler("S2CTeamAutoFight", OnS2CTeamAutoFight)

--组队跟随尝试上马
local function OnS2CTeamFollowTryRideHorse(sender,protocol)
--warn("=============OnS2CTeamFollowTryRideHorse=============")
	local hp = game._HostPlayer
	local bIsOn = (not hp:IsServerMounting()) and hp:CanRide()
	if bIsOn then
		SendHorseSetProtocol(-1, true)
	end
end
PBHelper.AddHandler("S2CTeamFollowTryRideHorse", OnS2CTeamFollowTryRideHorse)

--申请，邀请弹出提示
local function OnS2CTeamTips(sender,protocol)
	local EOpt = require "PB.net".S2CTeamTips.Opt

	local teamMan = CTeamMan.Instance()
	local curType = protocol.opt
	if curType == EOpt.Opt_Invite then
        local notify = NotifyComponents.TeamInviteNotify.new(protocol.Name, protocol.teamId, protocol.roleId, teamMan:ExchangeToDungeonId(protocol.targetId), nil)
        MsgNotify.Add(notify)

        local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
        local event = NotifyPowerSavingEvent()
        event.Type = "TeamInv"
		event.Param1 = notify._InviterName

		local roomId = teamMan:ExchangeToRoomId(notify._DungeonID)
        local roomTemplate = CElementData.GetTemplate("TeamRoomConfig", roomId)
        local str = ""
        if roomTemplate == nil then
            str = teamMan:GetTeamRoomNameByDungeonId(notify._DungeonID)
        else
            str = RichTextTools.GetElsePlayerNameRichText(roomTemplate.DisplayName, false)
        end

		event.Param2 = str
        CGame.EventManager:raiseEvent(nil, event)

	elseif curType == EOpt.Opt_Apply then
		local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
        local ChatManager = require "Chat.ChatManager"
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(22078), false, 0, nil,nil)

        -- 申请红点信息设置
        if teamMan:GetTeamApplyRedDotState() == true then return end
        teamMan:SetTeamApplyRedDotState(true)
        teamMan:RefreshTeamApplyRedDotState()
	end
end
PBHelper.AddHandler("S2CTeamTips", OnS2CTeamTips)

-- 组队匹配 匹配玩家不合格类型
local function OnS2CTeamMemberCheckRes(sender,protocol)
-- warn("=============OnS2CTeamMemberCheckRes=============")
	game._GUIMan:Open("CPanelTeamIneligible", protocol.checkRes)
end
PBHelper.AddHandler("S2CTeamMemberCheckRes", OnS2CTeamMemberCheckRes)

--返回状态码
local function OnS2CTeamErrorCode(sender, msg)
--warn("OnS2CTeamErrorCode")
--[[
enum TEAM_ERROR_CODE
{
	OK 					= 0;
	// OTHER Error Code
	PARAMS_NULL 			= 1;		// 对应参数不正确

									IS_IN_TEAM  			= 2;		// 已经在队伍中
									TEAM_NOT_FIND  			= 3;		// 队伍已经解散
	CONDITION_NOT_MEET  	= 4; 		// 不满足条件
	NOT_IN_TEAM  			= 5;		// 没在队伍中
									MUST_BE_CAPTAIN  		= 6;		// 必须是队长
									TEAM_IS_FULL  			= 7;		// 队伍已经满了
									IS_IN_OTHER_TEAM  		= 8;   		// 玩家已经在其他队伍了
	NOT_IN_SAME_TEAM  		= 9;  		// 提升队长的时候
	PARAMS_ERROR  			= 10;		// 参数错啦
	APPLY_LIST_IS_FULL  	= 11;		// 申请人数太多啦。
	NOT_ON_LINE 		    = 12;		// 不在线
	HAD_IN_APPLY 			= 13; 		// 已经存在Apply中
									TIME_OUT 				= 14;       // 操作超时
}
]]	
	local ETEAM_ERROR_CODE = require "PB.net".TEAM_ERROR_CODE
	local ret = msg.returnCode

	if ETEAM_ERROR_CODE.IS_IN_TEAM == ret then
		--warn("已经在队伍中")
		SendMsgToSysteamChannel( StringTable.Get(201) )
	elseif ETEAM_ERROR_CODE.MUST_BE_CAPTAIN == ret then
		--warn("队伍已经解散")	
		SendMsgToSysteamChannel( StringTable.Get(202) )

	elseif ETEAM_ERROR_CODE.IS_IN_OTHER_TEAM == ret then
		--warn("玩家已经在其他队伍了")	
		SendMsgToSysteamChannel( StringTable.Get(209) )

	elseif ETEAM_ERROR_CODE.TEAM_NOT_FIND == ret then
		--warn("必须是队长")
		SendMsgToSysteamChannel( StringTable.Get(213) )

	elseif ETEAM_ERROR_CODE.TEAM_IS_FULL == ret then
		--warn("队伍已经满了")
		SendMsgToSysteamChannel( StringTable.Get(203) )

	elseif ETEAM_ERROR_CODE.TEAM_IS_FULL == ret then
		--warn("玩家不在线")
		SendMsgToSysteamChannel( StringTable.Get(207) )

	elseif ETEAM_ERROR_CODE.TIME_OUT == ret then
		--warn("操作超时")
		SendMsgToSysteamChannel( StringTable.Get(206) )

	elseif ETEAM_ERROR_CODE.NOT_ON_LINE == ret then
		--warn("不在线")
		SendMsgToSysteamChannel( StringTable.Get(226) )
		
	elseif ETEAM_ERROR_CODE.APPLY_OK == ret then
		--warn("申请成功")
		SendMsgToSysteamChannel( StringTable.Get(227) )

	elseif ETEAM_ERROR_CODE.INVITATE_OK == ret then
		--warn("邀请成功")
		SendMsgToSysteamChannel( StringTable.Get(228) )
	end
end
PBHelper.AddHandler("S2CTeamErrorCode", OnS2CTeamErrorCode)
