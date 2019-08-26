local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local net = require "PB.net"
local CElementData = require "Data.CElementData"
local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"
local ERule = require "PB.Template".TeamRoomConfig.Rule

--创建队伍 OK
local function createTeam(iLevel, iCompetitive, strNotice, targetId, bBountyMode, teamMode)
	local C2STeamCreate = net.C2STeamCreate
	local protocol = C2STeamCreate()
	
	protocol.createData.teamID = 0

	--以下可以不要
	protocol.createData.bAuto = false
	protocol.createData.level = iLevel
	protocol.createData.Competitive = iCompetitive
	protocol.createData.tips = "strNotice"
	protocol.createData.targetId = targetId
	protocol.createData.bBountyMode = bBountyMode
    protocol.createData.mode = teamMode
	SendProtocol(protocol)
end

--组队申请
local function applyTeam(teamId)
	local C2STeamApply = net.C2STeamApply
	local protocol = C2STeamApply()
	protocol.applyData.teamID = teamId

	SendProtocol(protocol)
end

--队长接受申请
local function approveJoinTeam(teamId, memberId)
	local C2STeamApplyAckAccept = net.C2STeamApplyAckAccept
	local protocol = C2STeamApplyAckAccept()
	protocol.applyAckData.teamID = teamId 
	protocol.applyAckData.roleID = memberId
	protocol.applyAckData.account = ""

	SendProtocol(protocol)
end

--队长拒绝申请
local function refuseJoinTeam(teamId, memberId)
	local C2STeamApplyAckRefuse = net.C2STeamApplyAckRefuse
	local protocol = C2STeamApplyAckRefuse()
	protocol.applyAckData.teamID = teamId 
	protocol.applyAckData.roleID = memberId
	protocol.applyAckData.account = ""

	SendProtocol(protocol)
end

--邀请组队 C2STeamInvitate
local function inviteMember(teamId, memberId)
	local C2STeamInvitate = net.C2STeamInvitate
    local protocol = C2STeamInvitate()
    protocol.invitateData.invitateRoleID = memberId
    protocol.invitateData.teamID = teamId 
    protocol.invitateData.invitateAccount = ""
    SendProtocol(protocol)
end

--接受邀请 C2STeamInvitateAckAccept
local function inviteAccept(teamId)
	local C2STeamInvitateAckAccept = net.C2STeamInvitateAckAccept
    local protocol = C2STeamInvitateAckAccept()
    protocol.invitateAckData.teamID = teamId
    protocol.invitateAckData.invitateRoleID = game._HostPlayer._ID
    SendProtocol(protocol)
end

--拒绝邀请 C2STeamInvitateAckRefuse
local function inviteRefuse(teamId)
	local C2STeamInvitateAckRefuse = net.C2STeamInvitateAckRefuse
    local protocol = C2STeamInvitateAckRefuse()
    protocol.invitateAckData.teamID = teamId
    protocol.invitateAckData.invitateRoleID = game._HostPlayer._ID
    SendProtocol(protocol)
end

--离开队伍 ok
local function quitTeam(teamId)
	local C2STeamLeave = net.C2STeamLeave
	local protocol = C2STeamLeave()
	protocol.leaveData.teamID = teamId --self._Team._ID
	SendProtocol(protocol)
end

local function kickMemberDirectly(teamId, memberId)
    local C2STeamT = require "PB.net".C2STeamT
	local protocol = C2STeamT()
	protocol.tData.teamID = teamId
	protocol.tData.roleID = memberId
	SendProtocol(protocol)
end

-- 切换队伍模式，切换为团队或者普通队伍
local function changeTeamMode(mode)
    local C2STeamChangeMode = net.C2STeamChangeMode
    local protocol = C2STeamChangeMode()
    protocol.mode = mode
    SendProtocol(protocol)
end

--获取地图上的队伍列表
local function requestTeamListInRoom(roomID)
	if roomID == nil then return end
	
	local C2STeamGetTeamList = net.C2STeamGetTeamList
	local protocol = C2STeamGetTeamList()
	protocol.teamlistData.mapID = game._CurWorld._WorldInfo.MapTid
	protocol.targetId = roomID
	protocol.from = 1
	protocol.count = 99
	SendProtocol(protocol)
end

--自动寻找队伍
local function requestTeamAutoMatch(targetId)
	local C2STeamAutoMatchReq = net.C2STeamAutoMatchReq
	local protocol = C2STeamAutoMatchReq()
	protocol.TargetId = targetId
	SendProtocol(protocol)
end

--开始确认
local function startParepare(targetID)
	local C2SStartParepare = net.C2SStartParepare
	local protocol = C2SStartParepare()
    protocol.targetId = targetID
	SendProtocol(protocol)
end

--选择是否进入
local function confirmParepare(ready)
	local C2SConfirmParepare = net.C2SConfirmParepare
	local protocol = C2SConfirmParepare()
	protocol.comfirm = ready
	SendProtocol(protocol)
end

--请求设置
local function requestMatchSetting()
	local C2SMatchSettingReq = net.C2SMatchSettingReq
	local protocol = C2SMatchSettingReq()
	SendProtocol(protocol)
end

--修改设置
local function modifyMatchSetting(targetId,level,combatPower,bAutoApprove,bGuildOnly,bFriendOnly)
	local C2SModifyMatchSetting = net.C2SModifyMatchSetting
	local protocol = C2SModifyMatchSetting()
	protocol.Setting.TargetId = targetId
	protocol.Setting.Level = level
	protocol.Setting.CombatPower = combatPower
	protocol.Setting.AutoApproval = bAutoApprove
	protocol.Setting.GuildOnly = bGuildOnly
	protocol.Setting.FriendOnly = bFriendOnly
	SendProtocol(protocol)
end

local function changeTeamAutoApproval(bAutoApprove)
	local C2STeamAutoApproval = net.C2STeamAutoApproval
	local protocol = C2STeamAutoApproval()
	protocol.open = bAutoApprove
	SendProtocol(protocol)
end

--解散队伍
local function disbandTeam()
	local C2STeamDisband = net.C2STeamDisband
	local protocol = C2STeamDisband()
	SendProtocol(protocol)
end

--获取可以邀请的人员数据
local function requestInviteList(inviteType)
	local C2STeamGetCanInviteRoleList = net.C2STeamGetCanInviteRoleList
	local protocol = C2STeamGetCanInviteRoleList()
	protocol.inviteType = inviteType
	SendProtocol(protocol)
end

local function requestApplyInfo(teamId)
    local C2STeamGetApplyInfo = net.C2STeamGetApplyInfo
	local protocol = C2STeamGetApplyInfo()
	protocol.applyData.teamID = teamId 
	SendProtocol(protocol)
end

-- 发送队伍邀请界面各个页签的数量显示请求
local function requestTeamDisplayCount()
    local C2STeamCount  = net.C2STeamCount
    local protocol = C2STeamCount()
    SendProtocol(protocol)
end

local function confirmFollowState(follow)
    local C2STeamFollowConfirm = net.C2STeamFollowConfirm
    local protocol = C2STeamFollowConfirm()
    protocol.isFollow = follow
    SendProtocol( protocol )
end

local function requestTeamEquipInfo()
	local C2SGetTeamEquipInfo = net.C2SGetTeamEquipInfo
	local protocol = C2SGetTeamEquipInfo()
	SendProtocol(protocol)
end

-- 发送修改队伍名的协议
local function changeTeamName(teamName)
    local C2STeamChangeTeamName = net.C2STeamChangeTeamName
    local protocol = C2STeamChangeTeamName()
    protocol.teamName = teamName
    SendProtocol(protocol)
end

local function sendInfoChangeEvent(type, data)
	local event = TeamInfoChangeEvent()
	event._Type = type
	if data ~= nil then event._ChangeInfo = data end

	CGame.EventManager:raiseEvent(nil, event)
end

--获取此房间的UI下标位置
local function getRoomIndexByID(roomDataTable, targetId)
    if roomDataTable == nil then return -1, -1 end
    
    local bindex = -1
    local sindex = -1
    for i,v in ipairs(roomDataTable) do
        --如果是1级界面
        if v.ListData == nil or #v.ListData == 0 then
            --如果是这个目标房间
            if targetId == v.Data.Id then
                bindex = i
                break
            end
        else
        --如果是2级界面
            for i2,v2 in ipairs(v.ListData) do
                --如果是这个目标房间
                if targetId == v2.Data.Id then
                    bindex = i
                    sindex = i2
                    break
                end
            end    
        end
    end
    return bindex,sindex
end

--获取此房间的UI下标位置
local function getRoomIndexByDungeonID(roomDataTable, dungeonId)
    if roomDataTable == nil then return 0, 0 end
    local bindex = 0
    local sindex = 0
    for i,v in ipairs(roomDataTable) do
        --如果是1级界面
        if v.ListData == nil or #v.ListData == 0 then
            --如果是这个目标房间
            if dungeonId == v.Data.PlayingLawParam1 then
                bindex = i
                break
            end
        else
        --如果是2级界面
            for i2,v2 in ipairs(v.ListData) do
                --如果是这个目标房间
                if dungeonId == v2.Data.PlayingLawParam1 then
                    bindex = i
                    sindex = i2
                    break
                end
            end    
        end
    end
    return bindex,sindex
end

local function SortFunc(a,b)
	if a.Open == b.Open then
		return a.ChannelOneSerial < b.ChannelOneSerial
	else
		return a.Open
	end
end

--加载所有房间数据
local function loadValidTeamRoomData(bJustDungeOn)
	local result = {}

	local allTeamRoomData = CElementData.GetAllTeamRoomData()
	local dungeonMan = game._DungeonMan
	local functionMan = game._CFunctionMan

	for i,v in ipairs(allTeamRoomData) do
		--房间类型
		local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", v)

		-- 设置是否解锁标志位
		local bIsNearBy = v == 1
		local bDungeonIsOpen = tmpConfig.PlayingLaw == ERule.DUNGEON and dungeonMan:DungeonIsOpen(tmpConfig.PlayingLawParam1)
		local bFuncIsOpen = tmpConfig.PlayingLaw ~= ERule.DUNGEON and functionMan:IsUnlockByFunTid(tmpConfig.FunTid)
		local bIsOpen = bIsNearBy or bDungeonIsOpen or bFuncIsOpen
		bIsOpen = bIsOpen and ((bJustDungeOn and tmpConfig.PlayingLaw == ERule.DUNGEON) or (bJustDungeOn == false))

		local level1 = nil
		if bIsOpen then
			for i2,v2 in ipairs(result) do
				if tmpConfig.ChannelOneSerial == v2.ChannelOneSerial then
					level1 = v2
					break
				end
			end

			--如果 数组里面没有这个类型
			if level1 == nil then
				--先创建这个类型
				level1 = {}
				level1.ChannelOneSerial = tmpConfig.ChannelOneSerial
				level1.ChannelOneName = tmpConfig.ChannelOneName

				result[#result+1] = level1
			end

			--如果是1级频道
			if tmpConfig.ChannelTwoName == nil or tmpConfig.ChannelTwoName == "" then
				level1.Open = bIsOpen
				level1.Data = tmpConfig
			else
				if level1.ListData == nil then
					level1.ListData = {}
				end
				local data = {}
				data.Open = bIsOpen
				data.Data = tmpConfig
				if bIsOpen then
					level1.Open = bIsOpen
				end
				level1.ListData[#level1.ListData+1] = data
			end
		end
	end

	table.sort(result, SortFunc)

	return result
end

-- 副本ID 转换到RoomId
local function exchangeToRoomId(dungeonId)
	local teamData = loadValidTeamRoomData(false)
	local b,s = getRoomIndexByDungeonID(teamData, dungeonId)

    if b > 0 then
        if s > 0 then
            return (teamData[b].ListData[s]).Data.Id
        else
            return (teamData[b].Data).Id
        end
	end

	return 0
end

-- RoomId 转换到 副本ID
local function exchangeToDungeonId(roomId)
	local template = CElementData.GetTemplate("TeamRoomConfig", roomId)
	if template ~= nil and template.PlayingLaw == ERule.DUNGEON then
		return template.PlayingLawParam1
	end

	return 0
end

local function getTeamRoomNameByDungeonId(dungeonId)
	local dungeon = CElementData.GetTemplate("Instance", dungeonId)
	if dungeon == nil then return "" end

	local name = ""
	local EInstanceType = require "PB.Template".Instance.EInstanceType
	if dungeon.InstanceType == EInstanceType.INSTANCE_NORMAL or
	   dungeon.InstanceType == EInstanceType.INSTANCE_JJC1X1 or
	   dungeon.InstanceType == EInstanceType.INSTANCE_PVPelseif or
	   dungeon.InstanceType == EInstanceType.INSTANCE_TOWER or
	   dungeon.InstanceType == EInstanceType.INSTANCE_ELIMINATE or
	   dungeon.InstanceType == EInstanceType.INSTANCE_NORMAL_MAP or
	   dungeon.InstanceType == EInstanceType.INSTANCE_GUILDBASE or
	   dungeon.InstanceType == EInstanceType.INSTANCE_GUILD_BATTLEFIELD then
	   	name = dungeon.TextDisplayName
	elseif dungeon.InstanceType == EInstanceType.INSTANCE_GILLIAM or
		   dungeon.InstanceType == EInstanceType.INSTANCE_DRAGON then
		name = string.format(StringTable.Get(939), dungeon.TextDisplayName, StringTable.Get(960+dungeon.InstanceDifficultyMode))
	else
		name = string.format(StringTable.Get(939), dungeon.TextDisplayName, StringTable.Get(940+dungeon.InstanceType))
	end

	return RichTextTools.GetElsePlayerNameRichText(name, false)
end

return 
{
	CreateTeam = createTeam,
	ApplyTeam = applyTeam,
	ApproveJoinTeam = approveJoinTeam,
	RefuseJoinTeam = refuseJoinTeam,
	InviteMember = inviteMember,
	InviteAccept = inviteAccept,
	InviteRefuse = inviteRefuse,
	QuitTeam = quitTeam,
	KickMemberDirectly = kickMemberDirectly,
	ChangeTeamMode = changeTeamMode,
	RequestTeamListInRoom = requestTeamListInRoom,
	RequestTeamAutoMatch = requestTeamAutoMatch,
	StartParepare = startParepare,
	ConfirmParepare = confirmParepare,
	RequestMatchSetting = requestMatchSetting,
	ModifyMatchSetting = modifyMatchSetting,
	ChangeTeamAutoApproval = changeTeamAutoApproval,
	DisbandTeam = disbandTeam,
	RequestInviteList = requestInviteList,
	RequestApplyInfo = requestApplyInfo,
	RequestTeamDisplayCount = requestTeamDisplayCount,
	ConfirmFollowState = confirmFollowState,
	RequestTeamEquipInfo = requestTeamEquipInfo,
	ChangeTeamName = changeTeamName,

	SendInfoChangeEvent = sendInfoChangeEvent,  

	GetRoomIndexByID = getRoomIndexByID,
	GetRoomIndexByDungeonID = getRoomIndexByDungeonID,

	LoadValidTeamRoomData = loadValidTeamRoomData,
	ExchangeToRoomId = exchangeToRoomId,
	ExchangeToDungeonId = exchangeToDungeonId,
	GetTeamRoomNameByDungeonId = getTeamRoomNameByDungeonId,
}