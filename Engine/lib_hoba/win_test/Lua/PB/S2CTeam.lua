--
-- S2CTeam
--

local PBHelper = require "Network.PBHelper"


local function SendFlashMsg(msg)
	game._GUIMan:ShowTipText(msg, false)
end
local function SendMsgToSysteamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false)
end
local function SendMsgToTeamChannel(msg)
	local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"

	SendFlashMsg(msg)
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelTeam, msg, false)
end

local function Refresh()
	game._HostPlayer._TeamMan:RefreshPanel()
end

local function ChangeTeamInfo(data)
	local ETeamInfo = require "PB.net".TeamInfoChange_s2cd

	if data.type == ETeamInfo.TYPE.TYPE_HP then
		--print("血量同步")
		game._HostPlayer._TeamMan:ChangeMemberHp(data.hpInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_LEVEL then
		--print("等级同步")
		game._HostPlayer._TeamMan:ChangeMemberLevel(data.levelInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_MAP_INFO then
		--print("线路同步")
		game._HostPlayer._TeamMan:ChangeMemberMapInfo(data.mapInfo)
	elseif data.type == ETeamInfo.TYPE.TYPE_ONOFFLINE then
		--print("在线状态同步")
		game._HostPlayer._TeamMan:ChangeMemberOnline(data.onOffLine)
	elseif data.type == ETeamInfo.TYPE.TYPE_FOLLOW then
		--print("跟随状态同步")
		game._HostPlayer._TeamMan:ChangeMemberFollow(data.followInfo)
	end
end

local function TurnPanelTeamMember()
	--warn("=========TurnPanelTeamMember==========")
	if not game._HostPlayer._TeamMan:IsTeamLeader() then
		game._GUIMan:Close("CPanelJoinTeam")
		game._GUIMan:Open("CPanelTeamMember",nil)
	end 
end

--[[
local function SetApplyListCount(count)
	local CPanelTeamMember = require "GUI.CPanelTeamMember"

	if CPanelTeamMember.Instance():IsShow() then
		CPanelTeamMember.Instance():UpdateApplicationListCount(count)
	end
end
]]

local function SetMemberList(data)
	game._HostPlayer._TeamMan:SetMemberList(data)
end

local function SetApplicationList(data)
	local CPanelTeamMember = require "GUI.CPanelTeamMember"
	if CPanelTeamMember and CPanelTeamMember.Instance():IsShow() then
		local CPanelApplicationList = require "GUI.CPanelApplicationList"
		if CPanelApplicationList and CPanelApplicationList.Instance() then
			CPanelApplicationList.Instance():SetData(data)
		end
	end
end

local function SetTeamList(data)
	--warn("======OnS2CTeam::获取队伍列表=======")
	local CPanelJoinTeam = require "GUI.CPanelJoinTeam"
	if CPanelJoinTeam then
		CPanelJoinTeam.Instance():SetTeamList(data)
	end
end

local function CreateTeam() 
	--warn("======OnS2CTeam::创建队伍=======")
	--创建队伍
	game._GUIMan:Open("CPanelTeamMember",nil)
end

local function QuitTeam(data, id)
	--warn("======OnS2CTeam::离开队伍=======")
	--warn("leaveid == ", id)
	--离开队伍

	local hp = game._HostPlayer
	local teamMan = hp._TeamMan

	if id == hp._ID then
		teamMan:UpdateAllMemberPateNameInSight()

		SendFlashMsg( StringTable.Get(208) )
		teamMan:ResetMemberList()
		if hp:In3V3Fight() then
			teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		else
			teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
		end
	else
		local strMemberName = teamMan:GetTeamMemberName(id)
		SendMsgToTeamChannel( strMemberName..StringTable.Get(224) )
		SetMemberList(data)
	end

	Refresh()
end

local function DisbandTeam()
	local teamMan = game._HostPlayer._TeamMan
	teamMan:UpdateAllMemberPateNameInSight()

	SendMsgToSysteamChannel( StringTable.Get(222) )

	teamMan:ResetMemberList()
	if hp:In3V3Fight() then
		teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
	else
		teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
	end
	
	local CPanelTeamMember = require "GUI.CPanelTeamMember"
	if CPanelTeamMember and CPanelTeamMember.Instance():IsShow() then
		game._GUIMan:CloseByScript(CPanelTeamMember.Instance())
	end

	Refresh()
end

--创建队伍
local function OnS2CTeamCreate(sender, msg)	
	SetMemberList(msg.teamInfo)
	Refresh()
	CreateTeam()
end
PBHelper.AddHandler("S2CTeamCreate", OnS2CTeamCreate)

--申请组队
local function OnS2CTeamApply(sender, msg)
	SetMemberList(msg.teamInfo)
	TurnPanelTeamMember()
	Refresh()
end
PBHelper.AddHandler("S2CTeamApply", OnS2CTeamApply)

--队长接受申请
local function OnS2CTeamApplyAckAccept(sender, msg)

	for i,v in ipairs(msg.teamInfo.memberList) do
		if v.roleID == msg.teamInfo.info.modifyRoleID then
			if v.roleID == game._HostPlayer._ID then
				SendMsgToTeamChannel( StringTable.Get(229) )
			else
				SendMsgToTeamChannel( v.name..StringTable.Get(229) )
			end
		end
	end
	
	TurnPanelTeamMember()

	SetMemberList(msg.teamInfo)
	Refresh()
end
PBHelper.AddHandler("S2CTeamApplyAckAccept", OnS2CTeamApplyAckAccept)

--队长拒绝申请
local function OnS2CTeamApplyAckRefuse(sender, msg)	
	--TODO
end
PBHelper.AddHandler("S2CTeamApplyAckRefuse", OnS2CTeamApplyAckRefuse)

--邀请组队
local function OnS2CTeamInvitate(sender, msg)	
	local teamLeaderName = msg.teamInvitate.name
	local teamId = msg.teamInvitate.teamId

	local param = 
	{
		TeamLeaderName = teamLeaderName,
		TeamId = teamId
	}

	CNotificationMan.Instance():Push(EnumDef.NotificationType.TeamInvite, param)
end
PBHelper.AddHandler("S2CTeamInvitate", OnS2CTeamInvitate)

--接受邀请组队
local function OnS2CTeamInvitateAckAccept(sender, msg)	
	SetMemberList(msg.teamInfo)
	Refresh()
end
PBHelper.AddHandler("S2CTeamInvitateAckAccept", OnS2CTeamInvitateAckAccept)

--拒绝邀请组队
local function OnS2CTeamInvitateAckRefuse(sender, msg)	
	--TODO
end
PBHelper.AddHandler("S2CTeamInvitateAckRefuse", OnS2CTeamInvitateAckRefuse)

--离开队伍
local function OnS2CTeamLeave(sender, msg)
	--主动离开
	QuitTeam(msg.teamInfo, msg.teamLeaveInfo.leaveRoleID)
	Refresh()
end
PBHelper.AddHandler("S2CTeamLeave", OnS2CTeamLeave)

--队长T人
local function OnS2CTeamT(sender, msg)
	local teamMan = game._HostPlayer._TeamMan	
	--被T了
	if msg.teamTDataInfo.TroleID == game._HostPlayer._ID then
		teamMan:UpdateAllMemberPateNameInSight()

		teamMan:ResetMemberList()
		SendFlashMsg( StringTable.Get(239) )
		if hp:In3V3Fight() then
			teamMan:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		else
			teamMan:ChangeFollowState(EnumDef.FollowState.No_Team)
		end
		
		local CPanelTeamMember = require "GUI.CPanelTeamMember"
		if CPanelTeamMember and CPanelTeamMember.Instance():IsShow() then
			game._GUIMan:CloseByScript(CPanelTeamMember.Instance())
		end

		local CMenuList = require "GUI.CMenuList"
		if CMenuList and CMenuList.Instance():IsShow() then
			game._GUIMan:CloseByScript(CMenuList.Instance())
		end
		
	else
		local str = string.format(StringTable.Get(240), msg.teamTDataInfo.TName)
		--warn("T = ", str)
		SendFlashMsg( str )
		SetMemberList(msg.teamInfo)
	end
	Refresh()
end
PBHelper.AddHandler("S2CTeamT", OnS2CTeamT)

--队长变换
local function OnS2CTeamExchangeCapation(sender, msg)	
	SetMemberList(msg.teamInfo)
	Refresh()
end
PBHelper.AddHandler("S2CTeamExchangeCapation", OnS2CTeamExchangeCapation)

--自动加入设置
local function OnS2CTeamAutoJoin(sender, msg)	
	--SetAutoJoinInfo(msg.teamInfo.info)
end
PBHelper.AddHandler("S2CTeamAutoJoin", OnS2CTeamAutoJoin)

--获得地图组队列表
local function OnS2CTeamList(sender, msg)
	SetTeamList(msg.teamListInMap.teamInfoList)
end
PBHelper.AddHandler("S2CTeamList", OnS2CTeamList)

--获得本队数据
local function OnS2CTeamGetTeamInfo(sender, msg)
	--warn("OnS2CTeamGetTeamInfo")
	SetMemberList(msg.teamInfo)
	Refresh()
end
PBHelper.AddHandler("S2CTeamGetTeamInfo", OnS2CTeamGetTeamInfo)

--队长获得队伍申请数据
local function OnS2CTeamGetApplyInfo(sender, msg)
	SetApplicationList(msg.applicationInfo.applicationInfoList)
end
PBHelper.AddHandler("S2CTeamGetApplyInfo", OnS2CTeamGetApplyInfo)

--[[
--实时更新队伍申请数据
local function OnS2CTeamApplyCount(sender, msg)	
	SetApplyListCount(msg.teamApplicationCount.num)
end
PBHelper.AddHandler("S2CTeamApplyCount", OnS2CTeamApplyCount)
]]

--队伍相关属性变化同步
local function OnS2CTeamChange(sender, msg)	
	ChangeTeamInfo(msg.teamInfoChangeData)
end
PBHelper.AddHandler("S2CTeamChange", OnS2CTeamChange)

--队伍解散
local function OnS2CTeamDisband(sender, msg)
	DisbandTeam()
end
PBHelper.AddHandler("S2CTeamDisband", OnS2CTeamDisband)

--队伍Id同步
local function OnS2CPlayerTeamChange(sender, msg)
	local entity = game._CurWorld:FindObject(msg.PlayerId) 
	if entity == nil then return end

	entity._Team._ID = msg.TeamId
end
PBHelper.AddHandler("S2CPlayerTeamChange", OnS2CPlayerTeamChange)

--队长的位置信息
local function OnS2CTeamLeaderPositon(sender,protocol)
--warn("=============OnS2CTeamLeaderPositon=============")
	local pos = protocol.position
	--warn("pos.x = ", pos.x, "pos.y = ", pos.y, "pos.z = ", pos.z)
	--game._HostPlayer._TeamMan:SetLeaderPosition( pos, protocol.IsMapEndPos)
	game._HostPlayer._TeamMan:SetLeaderPosition( pos )
end
PBHelper.AddHandler("S2CTeamLeaderPositon", OnS2CTeamLeaderPositon)

--组队确认
local function OnS2CTeamFollowConfirm(sender,protocol)
--warn("=============OnS2CTeamFollowConfirm=============")
	game._HostPlayer._TeamMan:ShowTeamFollowConfirm()
end
PBHelper.AddHandler("S2CTeamFollowConfirm", OnS2CTeamFollowConfirm)


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