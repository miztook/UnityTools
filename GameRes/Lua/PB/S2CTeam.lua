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
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel

local function SendMsgToChatChannel(channel, msg)
	local ChatManager = require "Chat.ChatManager"
	ChatManager.Instance():ClientSendMsg(channel, msg, false, 0, nil, nil)
	TeraFuncs.SendFlashMsg(msg)
end

local function TurnPanelTeamMember()
	if not CTeamMan.Instance():IsTeamLeader() then
		game._GUIMan:Close("CPanelUITeamCreate")
		game._GUIMan:Open("CPanelUITeamMember", nil)
	end 
end

--创建队伍
local function OnS2CTeamCreate(sender, msg)	
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	CTeamMan.Instance():RefreshPanel()
	if msg.teamInfo.info.capture ~= nil then
		local defaultTeamName = string.format(StringTable.Get(22037), msg.teamInfo.info.capture)
	    TeamUtil.ChangeTeamName(defaultTeamName)
	end

	local hp = game._HostPlayer
	game._GUIMan:Close("CPanelUITeamCreate")
	
	if hp:InDungeon() or game:IsInBeginnerDungeon() then
		return
	end

	-- 打开组队页面显示
	game._GUIMan:Open("CPanelUITeamMember",nil)
end
PBHelper.AddHandler("S2CTeamCreate", OnS2CTeamCreate)

--申请组队
local function OnS2CTeamApply(sender, msg)
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	CTeamMan.Instance():RefreshPanel()
	TurnPanelTeamMember()
end
PBHelper.AddHandler("S2CTeamApply", OnS2CTeamApply)

--队长接受申请
local function OnS2CTeamApplyAckAccept(sender, msg)
	local hpId = game._HostPlayer._ID
	for i,v in ipairs(msg.teamInfo.memberList) do
		if v.roleID == msg.teamInfo.info.modifyRoleID then
			if v.roleID == hpId then
				TurnPanelTeamMember()
				SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelTeam, StringTable.Get(229) )
			else
				SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelTeam, v.name..StringTable.Get(229) )
			end
		end
	end

	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	CTeamMan.Instance():RefreshPanel()
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
    TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.NewRoleComeIn)
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
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	CTeamMan.Instance():RefreshPanel()
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
    --TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.NewRoleComeIn)
end
PBHelper.AddHandler("S2CTeamInvitateAckAccept", OnS2CTeamInvitateAckAccept)

local function OnS2CTeamInviteCache(sender,protocol)
	CTeamMan.Instance():SyncInviteCache(protocol.roleIds)
end
PBHelper.AddHandler("S2CTeamInviteCache", OnS2CTeamInviteCache)

--拒绝邀请组队
local function OnS2CTeamInvitateAckRefuse(sender, msg)	
	--TODO
end
PBHelper.AddHandler("S2CTeamInvitateAckRefuse", OnS2CTeamInvitateAckRefuse)

--离开队伍
local function OnS2CTeamLeave(sender, msg)
	--主动离开
	local data = msg.teamInfo
	local id = msg.teamLeaveInfo.leaveRoleID
	local hp = game._HostPlayer
	local teamMan = CTeamMan.Instance()

	if id == hp._ID then
		-- teamMan:UpdateAllMemberPateNameInSight()

		if not game:IsInBeginnerDungeon() then
			TeraFuncs.SendFlashMsg( StringTable.Get(208) )
		end

		if hp:In3V3Fight() then
			teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		else
			teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
		end
		teamMan:ResetMemberList()
	else
		local strMemberName = teamMan:GetTeamMemberName(id)
		if not game:IsInBeginnerDungeon() then
			SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelTeam, strMemberName..StringTable.Get(224) )
		end
		teamMan:UpdateMemberList(data)
	end

	CTeamMan.Instance():RefreshPanel()
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamLeave", OnS2CTeamLeave)

--队长T人
local function OnS2CTeamT(sender, msg)
	local hp = game._HostPlayer
	local teamMan = CTeamMan.Instance()
	--被T了
	if msg.teamTDataInfo.TroleID == hp._ID then
		-- teamMan:UpdateAllMemberPateNameInSight()

		if hp:In3V3Fight() then
			teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		else
			teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
		end
		
		teamMan:ResetMemberList()
		TeraFuncs.SendFlashMsg( StringTable.Get(239) )

		local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
		if CPanelUITeamMember and CPanelUITeamMember.Instance():IsShow() then
			game._GUIMan:CloseByScript(CPanelUITeamMember.Instance())
		end
	else
		local str = string.format(StringTable.Get(240), msg.teamTDataInfo.TName)
		-- TeraFuncs.SendFlashMsg( str )
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelTeam,str)
		CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	end
	CTeamMan.Instance():RefreshPanel()
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamT", OnS2CTeamT)

--队长变换
local function OnS2CTeamExchangeCapation(sender, msg)
	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	local captureName = msg.teamInfo.info.capture

	local str = nil
	if game._HostPlayer._ID == msg.teamInfo.info.captainID then
		str = StringTable.Get(248)
	else
		local teamMan = CTeamMan.Instance()
		teamMan:RefreshTeamApplyRedDotState(false)
		str = string.format(StringTable.Get(247), captureName)
	end
	SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelTeam, str)
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamExchangeCapation", OnS2CTeamExchangeCapation)

--获得地图组队列表
local function OnS2CTeamList(sender, msg)
	local CPanelUITeamCreate = require "GUI.CPanelUITeamCreate"
	CPanelUITeamCreate.Instance():SetTeamList(msg.teamListInMap.teamInfoList)
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
	   	CTeamMan.Instance():RefreshPanel()
		return
	end

	CTeamMan.Instance():UpdateMemberList(msg.teamInfo)
	CTeamMan.Instance():RefreshPanel()
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamGetTeamInfo", OnS2CTeamGetTeamInfo)

--队长获得队伍申请数据
local function OnS2CTeamGetApplyInfo(sender, msg)
	local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
	CPanelUITeamInvite.Instance():UpdateApplyList(msg.applicationInfo.applicationInfoList)
end
PBHelper.AddHandler("S2CTeamGetApplyInfo", OnS2CTeamGetApplyInfo)


--实时更新队伍申请数据
local function OnS2CTeamApplyCount(sender, msg)	
	-- warn("实时更新队伍申请数据 Count = ", msg.teamApplicationCount.num)
	if msg.teamApplicationCount.num > 0 then
		TeraFuncs.SendFlashMsg(StringTable.Get(20093))
	else
		-- --清空申请列表
		-- local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
		-- if CPanelUITeamInvite.Instance() then
		-- 	CPanelUITeamInvite.Instance():UpdateApplyList({})
		-- end
		
		--清空通知列表
        MsgNotify.Remove(EnumDef.NotificationType.TeamApplication)
        CTeamMan.Instance():RefreshTeamApplyRedDotState(false)
	end
end
PBHelper.AddHandler("S2CTeamApplyCount", OnS2CTeamApplyCount)

--队伍相关属性变化同步
local function OnS2CTeamChange(sender, msg)	
	local data = msg.teamInfoChangeData
	local ETeamInfo = require "PB.net".TeamInfoChange_s2cd
	local TeamInfoChangeType = EnumDef.TeamInfoChangeType

	if data.type == ETeamInfo.TYPE.TYPE_HP then
		CTeamMan.Instance():ChangeMemberHp(data.hpInfo)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.Hp, data.hpInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_LEVEL then
		CTeamMan.Instance():ChangeMemberLevel(data.levelInfo)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.Level, data.levelInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_MAP_INFO then
		CTeamMan.Instance():ChangeMemberMapInfo(data.mapInfo)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.MapInfo, data.mapInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_ONOFFLINE then
		CTeamMan.Instance():ChangeMemberOnline(data.onOffLine)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.OnLineState, data.onOffLine)
	elseif data.type == ETeamInfo.TYPE.TYPE_FOLLOW then
		CTeamMan.Instance():ChangeMemberFollow(data.followInfo)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.FollowState, data.followInfo)
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
		CTeamMan.Instance():ChangeFightScore(data.fightScoreInfo)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.FightScore, data.fightScoreInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_BOUNTY then

	elseif data.type == ETeamInfo.TYPE.TYPE_TARGETCHANGE then
		CTeamMan.Instance():ChangeTeamTarget(data.targetChange)
        TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.TARGETCHANGE, data.matchState)
	elseif data.type == ETeamInfo.TYPE.TYPE_MATCHSTATECHANGE then

	elseif data.type == ETeamInfo.TYPE.TYPE_POSITION then
		CTeamMan.Instance():ChangeMemberPosition(data.positionInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_AutoApproval then
		
	elseif data.type == ETeamInfo.TYPE.TYPE_InvitateStatus then
		CTeamMan.Instance():SetInvitingCount(data.invitateStatus.status)
		TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.InvitateStatus, data.invitateStatus)
    elseif data.type == ETeamInfo.TYPE.TYPE_MODE then
        local TeamMode = require "PB.data".TeamMode
        if CTeamMan.Instance():InSameTeam(data.changeMode.teamId) then
            CTeamMan.Instance():SetSelfTeamMode(data.changeMode.mode)
        end
        TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.TeamMode, data.changeMode)
    elseif data.type == ETeamInfo.TYPE.TYPE_NAME then
    	CTeamMan.Instance():ChangeMemberName(data.memberName.roleId, data.memberName.newName)
    	TeamUtil.SendInfoChangeEvent(TeamInfoChangeType.TeamMemberName, data.memberName)
	end
end
PBHelper.AddHandler("S2CTeamChange", OnS2CTeamChange)

--队伍解散
local function OnS2CTeamDisband(sender, msg)
	local hp = game._HostPlayer
	local teamMan = CTeamMan.Instance()
	-- teamMan:UpdateAllMemberPateNameInSight()

	SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(222))

	teamMan:ResetMemberList()
	local hp = game._HostPlayer
	if hp:In3V3Fight() then
		teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
	else
		teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
	end
	
	game._GUIMan:Close("CPanelUITeamMember")

	CTeamMan.Instance():RefreshPanel()
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end
PBHelper.AddHandler("S2CTeamDisband", OnS2CTeamDisband)

--队伍Id同步
local function OnS2CPlayerTeamChange(sender, msg)
	local entity = game._CurWorld:FindObject(msg.PlayerId) 
	if entity == nil then return end

	entity._TeamId = msg.TeamId
end
PBHelper.AddHandler("S2CPlayerTeamChange", OnS2CPlayerTeamChange)

--组队确认
local function OnS2CTeamFollowConfirm(sender,protocol)
	CTeamMan.Instance():ShowTeamFollowConfirm()
end
PBHelper.AddHandler("S2CTeamFollowConfirm", OnS2CTeamFollowConfirm)

--队友已准备
local function OnS2CTeamMemberConfirmed(sender,protocol)
	local CPanelUITeamConfirm = require "GUI.CPanelUITeamConfirm"
	if CPanelUITeamConfirm.Instance():IsShow() then
		CPanelUITeamConfirm.Instance():UpdateTeamMemberConfirmed(protocol.roleId)
	end
end
PBHelper.AddHandler("S2CTeamMemberConfirmed", OnS2CTeamMemberConfirmed)

--进入确认界面弹出成功
local function OnS2CTeamStartPrepare(sender,protocol)
	CTeamMan.Instance():StartTeamPrepare(protocol.DeadLine, protocol.DungeonTid)
end
PBHelper.AddHandler("S2CTeamStartPrepare", OnS2CTeamStartPrepare)

--确认界面结果
local function OnS2CTeamPrepareResult(sender,protocol) 
	local CPanelDungeonEnd = require"GUI.CPanelDungeonEnd"
	CTeamMan.Instance():UpdateTeamPrepareResult(protocol.success)
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
	CTeamMan.Instance():UpdateTeamMatchSetting(protocol)
end
PBHelper.AddHandler("S2CTeamMatchSetting", OnS2CTeamMatchSetting)

--协议名称
local function OnS2CTeamCanInviteRoleList(sender,protocol)
	local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
	CPanelUITeamInvite.Instance():UpdateInviteList(protocol.roleList)
end
PBHelper.AddHandler("S2CTeamCanInviteRoleList", OnS2CTeamCanInviteRoleList)

-- 可邀请的各个页签的数量信息
local function OnS2CTeamCanApplyCount(sender, protocol)
    local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
    if CPanelUITeamInvite.Instance():IsShow() then
   		CPanelUITeamInvite.Instance():UpdateCount(protocol.GuidCount, protocol.FirendCount, protocol.ApplyCount)
   	end
end
PBHelper.AddHandler("S2CTeamCount", OnS2CTeamCanApplyCount)

local function OnS2CTeamNameChange(sender, protocol)
    CTeamMan.Instance():UpdateTeamName(protocol.teamName)
end
PBHelper.AddHandler("S2CTeamNameChange", OnS2CTeamNameChange)

--队员装备信息
local function OnS2CTeamEquipInfo(sender,protocol)
	local teamMan = CTeamMan.Instance()
	teamMan:UpdateTeamEquipInfo(protocol.Info)
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
        local notify = NotifyComponents.TeamInviteNotify.new(protocol.Name, protocol.teamId, protocol.roleId, TeamUtil.ExchangeToDungeonId(protocol.targetId), nil)
        MsgNotify.Add(notify)

        local NotifyPowerSavingEvent = require "Events.NotifyPowerSavingEvent"
        local event = NotifyPowerSavingEvent()
        event.Type = "TeamInv"
		event.Param1 = notify._InviterName

		local roomId = TeamUtil.ExchangeToRoomId(notify._DungeonID)
        local roomTemplate = CElementData.GetTemplate("TeamRoomConfig", roomId)
        local str = ""
        if roomTemplate == nil then
            str = TeamUtil.GetTeamRoomNameByDungeonId(notify._DungeonID)
        else
            str = RichTextTools.GetElsePlayerNameRichText(roomTemplate.DisplayName, false)
        end

		event.Param2 = str
        CGame.EventManager:raiseEvent(nil, event)

	elseif curType == EOpt.Opt_Apply then
        -- 申请红点信息设置
        if CRedDotMan.GetModuleDataToUserData("TeamApply") == true then return end
        teamMan:RefreshTeamApplyRedDotState(true)
	end
end
PBHelper.AddHandler("S2CTeamTips", OnS2CTeamTips)

-- 组队匹配 匹配玩家不合格类型
local function OnS2CTeamMemberCheckRes(sender,protocol)
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
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(201) )
	elseif ETEAM_ERROR_CODE.MUST_BE_CAPTAIN == ret then
		--warn("队伍已经解散")	
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(202) )
	elseif ETEAM_ERROR_CODE.IS_IN_OTHER_TEAM == ret then
		--warn("玩家已经在其他队伍了")	
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(209) )
	elseif ETEAM_ERROR_CODE.TEAM_NOT_FIND == ret then
		--warn("必须是队长")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(213) )
	elseif ETEAM_ERROR_CODE.TEAM_IS_FULL == ret then
		--warn("队伍已经满了")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(203) )
	elseif ETEAM_ERROR_CODE.TEAM_IS_FULL == ret then
		--warn("玩家不在线")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(207) )
	elseif ETEAM_ERROR_CODE.TIME_OUT == ret then
		--warn("操作超时")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(206) )
	elseif ETEAM_ERROR_CODE.NOT_ON_LINE == ret then
		--warn("不在线")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(226) )
	elseif ETEAM_ERROR_CODE.APPLY_OK == ret then
		--warn("申请成功")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(227) )
	elseif ETEAM_ERROR_CODE.INVITATE_OK == ret then
		--warn("邀请成功")
		SendMsgToChatChannel(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(228) )
	end
end
PBHelper.AddHandler("S2CTeamErrorCode", OnS2CTeamErrorCode)
