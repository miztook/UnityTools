local Lplus = require "Lplus"
local UserData = require "Data.UserData".Instance()
local CTeamMember = require "Team.CTeamMember"
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local CPlayer = require "Object.CPlayer"
local CTeam = require "Team.CTeam"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local EWorldType = require "PB.Template".Map.EWorldType
local TeamMode = require "PB.data".TeamMode
local bit = require "bit"

local CTeamMan = Lplus.Class("CTeamMan")
local def = CTeamMan.define

local smallTeamMaxMemCount = 5
local bigTeamMaxMemCount = 10
local MaxFollowCooldownTime = 10

def.field('boolean')._IsInited = true
def.field(CTeam)._Team = nil
def.field("table")._InvitedCache = nil
def.field("boolean")._IsInviting = false			-- 邀请过的列表
def.field("number")._InvitingCount = 0				-- 邀请中的人数

def.field("number")._FollowCooldownTimerId = 0
def.field("number")._FollowCooldownTime = 0

local instance = nil
def.static("=>", CTeamMan).Instance = function()
	if not instance then
		instance = CTeamMan()
		instance._Team = CTeam.new()
	end
	return instance
end

def.method().Init = function(self)
	self._IsInited = true
	self._InvitedCache = {}
	self._IsInviting = false
	self._InvitingCount = 0
end

--是否在队伍中
def.method("=>", "boolean").InTeam = function(self)
	return self._Team._ID > 0
end

--是否在同一队伍
def.method("number", "=>", "boolean").InSameTeam = function(self, teamId)
	return self:InTeam() and self._Team._ID == teamId
end

def.method("number", "=>", "table").GetMember = function(self, memberId)
	local memberList = self._Team._MemberList
	for i = 1, #memberList do
		if memberList[i]._ID == memberId then
			return memberList[i]
		end
	end

	return nil
end

def.method("=>", "string").GetTeamName = function(self)
    return self._Team._TeamName
end

--获取队员名称
def.method("number", "=>", "string").GetTeamMemberName = function(self, memberId)
	local member = self:GetMember(memberId)
	if member ~= nil then
		return member._Name
	end
	return ""
end

def.method("=>", "boolean").HaveTeamMemberInSameMap = function(self)
	if not self:InTeam() then return false end

	local hpId = game._HostPlayer._ID
	local hostTeamInfo = self:GetMember(hpId)
	local hostMapTag = hostTeamInfo._MapTag
	local memberList = self._Team._MemberList

	for i=1, #memberList do
		local member = memberList[i]
		if member._ID ~= hpId and member._IsOnLine and hostMapTag == member._MapTag then
			return true
		end
	end

	return false
end

def.method("=>", "boolean").IsSameMapWithLeader = function(self)
	local hostInfo = self:GetMember(game._HostPlayer._ID)
	local leaderInfo = self:GetMember(self._Team._TeamLeaderId)
	if leaderInfo == nil then return false end
	
	return leaderInfo._IsOnLine and hostInfo._MapTag == leaderInfo._MapTag
end

-- 获取 队员最大上限
def.method("=>", "number").GetMemberMax = function(self)
	return self._Team:GetMemberMax() or 0
end

-- 设置自己的队伍的模式（普通队伍还是团队）
def.method("number").SetSelfTeamMode = function(self, mode)
    self._Team._TeamMode = mode
    self._Team._MemberMax = mode == TeamMode.Corps and bigTeamMaxMemCount or smallTeamMaxMemCount

    TeraFuncs.SendFlashMsg(StringTable.Get(mode == TeamMode.Corps and 20094 or 20095), false)
end

-- 当前队伍mode， 对应data.TeamMode
def.method("=>", "number").GetTeamMode = function(self)
    return self:InTeam() and self._Team._TeamMode or 0
end

def.method("=>", "number").GetTeamId = function(self)
    return self:InTeam() and self._Team._ID or 0
end

-- 当前队伍是否是团
def.method("=>", "boolean").IsBigTeam = function(self)
    if not self:InTeam() then 
        return false
    end
    return self._Team._TeamMode == TeamMode.Corps
end

-- 设置正在邀请的成员个数
def.method("number").SetInvitingCount = function(self, count)
	self._InvitingCount = count
end

def.method("=>", "number").GetInvitingCount = function(self)
	return self._InvitingCount
end

-- 设置是否正在邀请队员
def.method("boolean").SetInvitingState = function(self, bIsInviting)
	self._IsInviting = bIsInviting
end

def.method("=>", "boolean").IsInviting = function(self)
	return self._InvitingCount > 0
end

-- 添加本地邀请过的列表
def.method("number").AddInvitedCache = function(self, roleId)
	if not self:HasInvited(roleId) then
		self._InvitedCache[#self._InvitedCache+1] = roleId
	end
end

-- 查询是否邀请过该成员
def.method("number", "=>", "boolean").HasInvited = function(self, roleId)
	for i,v in ipairs(self._InvitedCache) do
		if v == roleId then
			return true
		end
	end

	return false
end

-- 同步邀请过人员列表
def.method("table").SyncInviteCache = function(self, invitedList)
	self._InvitedCache = {}
	for i,v in ipairs(invitedList) do
		self._InvitedCache[i] = v
	end
end

def.method("number", "table").SendLinkMsg = function(self, channelType, param)
	local ChatLinkType = require "PB.data".ChatLinkType
	local ChatChannel = require "PB.data".ChatChannel

	local linkInfo = {}
	local chatLink = {}
    chatLink.LinkType = ChatLinkType.ChatLinkType_Team
    chatLink.ContentID = self._Team._ID
    linkInfo.ChatLink = chatLink

    local lv = self._Team._Setting.Level
    local combatPower = self._Team._Setting.CombatPower
    local targetId = self._Team._Setting.TargetId

	linkInfo.chatChannel = channelType
	linkInfo.TargetId = param == nil and targetId or param.TargetId
	linkInfo.Level = param == nil and lv or param.Level
	linkInfo.CombatPower = param == nil and combatPower or param.CombatPower
	linkInfo.TeamName = CTeamMan.Instance():GetTeamName()

	local ChatManager = require "Chat.ChatManager"
    ChatManager.Instance():ChatOtherSend(linkInfo)

    if channelType == ChatChannel.ChatChannelWorld then
    	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
		if CPanelUITeamMember.Instance():IsShow() then
    		CPanelUITeamMember.Instance():MarkCanSendWorldChatTime()
    	end
    end
end

local function PaddingRoomLevel(name, lv)
	local result = lv > 0 and string.format(StringTable.Get(20092), name, lv) or name
    return result
end

--获取link信息拼接的字符串
def.method("number", "number", "number", "string","=>", "string").GetLinkStr = function(self, targetId, lv, combatPower, teamName)
    local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", targetId)
	if teamRoomConfig == nil then
		if teamName == "" then
    	    return string.format(StringTable.Get(22407), lv, GUITools.FormatNumber(combatPower))
        else
            return string.format(StringTable.Get(22413), teamName, lv, GUITools.FormatNumber(combatPower))
        end
	else
		local str = PaddingRoomLevel(teamRoomConfig.DisplayName, teamRoomConfig.DisplayLevel)
		local lineStr = "[l]"..StringTable.Get(22019).."[-]"
		if teamName == "" then
    	    return string.format(StringTable.Get(22406), str, lineStr, lv, GUITools.FormatNumber(combatPower))
        else
            return string.format(StringTable.Get(22413), teamName, str, lineStr, lv, GUITools.FormatNumber(combatPower))
        end
	end
end

--刷新UE 红点
def.method("boolean").RefreshTeamApplyRedDotState = function(self, show)
	CRedDotMan.SaveModuleDataToUserData("TeamApply", show)

	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():UpdateTeamRedDotState()
	end

	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
	if CPanelUITeamMember.Instance():IsShow() then
		CPanelUITeamMember.Instance():UpdateTeamRedDotState()
	end
end

def.method().UpdateAllMemberPateNameInSight = function(self)
	local teamMemberList = self._Team._MemberList
	local hp = game._HostPlayer
	local world = game._CurWorld

	for i,v in ipairs(teamMemberList) do
		if v._ID ~= hp._ID then
			local findMember = world:FindObject(v._ID)
			if findMember then
				findMember:UpdateTopPateName(true)
				findMember:UpdatePetName()
				findMember:UpdateTopPate(EnumDef.PateChangeType.HPLine)
				findMember:UpdateTopPate(EnumDef.PateChangeType.Rescue)
				hp:UpdateTargetSelected(v._ID)
			end
		end
	end
end

--获取当前 队伍中 跟随的队员总数
def.method("=>", "number").GetTeamMemberFollowingCount = function(self)
	local count = 0
	local hpId = game._HostPlayer._ID

	local teamMemberList = self._Team._MemberList
	for i=1, #teamMemberList do
		local memberInfo = teamMemberList[i]
		if memberInfo._ID ~= hpId and memberInfo._IsFollow then
			count = count + 1
		end
	end

	return count
end

--是否跟随状态 一般用于队员，队长默认不是跟随状态
def.method("=>", "boolean").IsFollowing = function(self)
	if not self:IsTeamLeader() then
		local curFollowState = self._Team._FollowState
		local EMember_Followed = EnumDef.FollowState.Member_Followed

		return (self._Team._FollowState == EMember_Followed)
	end
	return false
end

do -- 设置队伍属性
	def.method("table").ChangeMemberPosition = function(self, data)
		local member = self:GetMember(data.roleId)
		if member ~= nil then
			member._MapTid = data.mapTId
			member._Position = {x = data.x, z = data.z }
		end
	end

	--队员线路及地图ID
	def.method("table").ChangeMemberMapInfo = function(self, data)
		local member = self:GetMember(data.roleId)
		if member ~= nil then
			member._MapTid = data.worldId
			member._LineId = data.lineId
			member._MapTag = data.mapTag
			member._GameServerId = data.gameServerId
		end
	end

	--队员血量
	def.method("table").ChangeMemberHp = function (self, data)
		local member = self:GetMember(data.roleId)
		if member ~= nil then
			if member._Hp > 0 and data.HP <= 0 then
				--死了
				TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.DeadState, {roleId = data.roleId, DeadState = true})
				if data.roleId ~= game._HostPlayer._ID  then
					local hostInfo = self:GetMember(game._HostPlayer._ID)
					local roleInfo = self:GetMember(data.roleId)
					if hostInfo._MapTid == roleInfo._MapTid and hostInfo._LineId == roleInfo._LineId then
						TeraFuncs.SendFlashMsg(string.format(StringTable.Get(22044), member._Name), false)
					end
				end
			elseif member._Hp <= 0 and data.HP > 0 then
				--活了
				TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.DeadState, {roleId = data.roleId, DeadState = false})
			end
			member._Hp = data.HP
			member._HpMax = data.MaxHp
		end
	end

	--队员等级
	def.method("table").ChangeMemberLevel = function (self, data)
		local member = self:GetMember(data.roleId)
		if member ~= nil then
			member._Lv = data.level
		end
	end

	--上下线
	def.method("table").ChangeMemberOnline = function(self, data)
		local hp = game._HostPlayer
		if hp == nil or data.roleID == hp._ID then
			return
		end

		local member = self:GetMember(data.roleId)
		if member ~= nil then
			member._IsOnLine = data.isOnline
			if not data.isOnline then
				TeraFuncs.SendFlashMsg(string.format(StringTable.Get(22043), member._Name), false)
			end
		end
	end

	--战斗力同步
	def.method("table").ChangeFightScore = function(self, data)
		local member = self:GetMember(data.roleId)
		if member ~= nil then
			member._Fight = data.fightScore
		end
	end

	--队伍目标同步
	def.method("table").ChangeTeamTarget = function(self, data)
		self._Team._TargetId = data.targetId
	end

	--组队跟随标志
	def.method("table").ChangeMemberFollow = function(self, data)
		local member = self:GetMember(data.roleId)
		if member == nil then return end

		local bShowNotify = member._IsFollow ~= data.isFollow
		member._IsFollow = data.isFollow	

		local itIsMe = data.roleId == game._HostPlayer._ID
		-- 如果是主角，提醒，并停止自动战斗
		if itIsMe and bShowNotify then
			local str = data.isFollow and StringTable.Get(237) or StringTable.Get(238)
			TeraFuncs.SendFlashMsg(str ,false)
		end

		if self:IsTeamLeader() then
			-- warn("队长设置状态")
			self:SetLeaderFollowState()
		else
			--自己跟随状态开启
			if itIsMe then
				-- warn("队员设置状态", data.isFollow)
				self:SetHostFollowState( data.isFollow )

				if data.isFollow then
					-- 关闭自动寻路
					game._HostPlayer:StopAutoTrans()
					-- 关闭副本自动战斗
					local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
					CDungeonAutoMan.Instance():Stop()
					-- 关闭自动任务
					local CQuestAutoMan = require"Quest.CQuestAutoMan"
					CQuestAutoMan.Instance():Stop()
					-- 关闭自动战斗
					local CAutoFightMan = require "AutoFight.CAutoFightMan"
					CAutoFightMan.Instance():Stop() 
				end
			end
		end

		self:RefreshPanel()
	end

	def.method("number", "string").ChangeMemberName = function(self, roleId, name)
		local member = self:GetMember(roleId)
		if member ~= nil then member._Name = name end
	end
end

def.method().StopFollow = function(self)
	if self:IsFollowing() then
		self:FollowLeader(false)
	end
end

--队员时，只关心自己的状态
def.method("boolean").SetHostFollowState = function(self, bFollowed)
	local hp = game._HostPlayer

	if hp:In3V3Fight() then
		self:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		return
	end

	local state = EnumDef.FollowState.Member_None
	if bFollowed then state = EnumDef.FollowState.Member_Followed end	
	self:ChangeFollowState(state)

	hp:CancelSyncPosWhenMove( self:IsFollowing() )
end

--队长时，所有队员跟随状态检查，有一个跟随，即变成可以取消跟随
def.method().SetLeaderFollowState = function(self)
	local hp = game._HostPlayer

	if hp:In3V3Fight() then
		self:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		return
	end

	if self:HaveTeamMember() then
		self:ChangeFollowState(EnumDef.FollowState.Leader_Followed)
	else
		self:ChangeFollowState(EnumDef.FollowState.Leader_NoMember)
	end
end

def.method("=>", "boolean").IsAutoApprove = function(self)
	return self._Team._Setting.AutoApproval
end

--刷新组队Buttons状态
local function RefreshFollowButtons(self)
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker and CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():UpdateFollowButton()
	end
end

local function InActiveFollowButton( self )
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker and CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():DisableFollowButton()
	end
end

--刷新组队Buttons状态
local function RefreshFollowCount()
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():UpdateFollowCount()
	end
end
local function RefreshCoolingdownTime()
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():UpdateFollowCoolingdownTime()
	end
end


local function DisableFollowButtonState(self, bDisable)
	local CPanelTracker = require "GUI.CPanelTracker"
	if CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():DisableFollowButtonState( bDisable )
	end

	if not bDisable then
		RefreshFollowCount()
	end
end

local function CancelFollowCooldownTimer(self)
	_G.RemoveGlobalTimer(self._FollowCooldownTimerId)
    self._FollowCooldownTimerId = 0
    DisableFollowButtonState(self, false)
    RefreshFollowButtons()
end

local function FollowCooldownTick(self)
	self._FollowCooldownTime = self._FollowCooldownTime - 1
	RefreshCoolingdownTime()
	if self._FollowCooldownTime <= 0 then
		CancelFollowCooldownTimer(self)
	end
end

local function StartFollowCooldownTimer(self)
	self._FollowCooldownTime = MaxFollowCooldownTime
	self._FollowCooldownTimerId = _G.AddGlobalTimer(1, false ,function()
		FollowCooldownTick(self)
	end)
	DisableFollowButtonState(self, true)
end

--主界面召唤按钮 冷却
def.method().OnClickFollowCoolingdown = function(self)
	if not self:IsFollowClickCoolingdown() then
		StartFollowCooldownTimer(self)
	end
end

def.method("=>", "number").GetFollowCoolingdownTime = function(self)
	return self._FollowCooldownTime
end

def.method("=>", "boolean").IsFollowClickCoolingdown = function(self)
	return self._FollowCooldownTimerId > 0
end

--切换跟随状态
def.method("number").ChangeFollowState = function(self, nowFollowState)
	local curFollowState = self._Team._FollowState

	if nowFollowState == EnumDef.FollowState.Leader_None or nowFollowState == EnumDef.FollowState.Leader_Followed then
		RefreshFollowCount()
	end

	if curFollowState == nowFollowState then return end

	self._Team._FollowState = nowFollowState
	RefreshFollowButtons(self)

	local hp = game._HostPlayer
	hp:CancelSyncPosWhenMove(self:IsFollowing())
end

--刷新UI数据
def.method().RefreshPanel = function(self)
	local CPanelTracker = require "GUI.CPanelTracker"
	CPanelTracker.Instance():UpdateTeamMemberCount()
end

--判断是否为队长
def.method("=>", "boolean").IsTeamLeader = function(self)
	if not self._Team then
		return false
	end
	
	local hp = game._HostPlayer
	return hp._ID == self._Team._TeamLeaderId
end

--通过ID判断是否为队长  前提需要确认该玩家在队伍中
def.method('number', '=>', 'boolean').IsTeamLeaderById = function(self, memberId)
	if not self._Team then
		return false
	end

	return self._Team._TeamLeaderId == memberId
end

--判断是否有队友
def.method("=>", "boolean").HaveTeamMember = function(self)
	return #self._Team._MemberList >= 2
end

def.method("number" ,"=>", "boolean").IsTeamMember = function(self, entityId)
	if self:InTeam() then
		local list = self._Team._MemberList
		for i,member in ipairs( list ) do
			if member._ID == entityId then
				return true
			end
		end
	end

	return false
end

--获取队员数据列表
def.method("=>", "table").GetMemberList = function (self)
	return self._Team._MemberList
end

--获取队员个数
def.method("=>", "number").GetMemberCount = function (self)
	return #self._Team._MemberList
end

--重置队员数据
def.method().ResetMemberList = function (self)
	local hp = game._HostPlayer
	if hp == nil then return end

	hp._TeamId = 0
	self._Team:Reset()
	-- self:UpdateAllMemberPateNameInSight()

	self._IsInited = true

	local TeamJoinOrQuitEvent = require "Events.TeamJoinOrQuitEvent"
	local event = TeamJoinOrQuitEvent()
	event._InTeam = false
	CGame.EventManager:raiseEvent(nil, event)

	-- 重置红点状态
	self:RefreshTeamApplyRedDotState(false)
end

--[[
_G.UpdateReason =
{
	TeamCreate = 0,
	TeamApply = 1, 
	ApplyAckAccept = 2,
	InvitateAckAccept = 3,
	OtherMemberKickOff = 4,
	ExchangeCapation = 5,
	GetTeamInfo = 6,
	OtherMemeberQuit = 7,
}
]]

--添加组员
local function AddMember(self, member, teamId)
	-- 重复添加检查
	local curMemberList = self._Team._MemberList
	for i,v in ipairs(curMemberList) do
		if v._ID == member.roleID then
			return
		end
	end

	local pMember = CTeamMember.new()
	pMember._ID = member.roleID
	if member.isAssist and tonumber(member.name) ~= nil then
		local npcName = CElementData.GetTextTemplate(tonumber(member.name))
		if npcName ~= nil then
			pMember._Name = npcName.TextContent
		else
			warn("Can not find NPC TID------AI Name = ", member.name)
			pMember._Name = member.name
		end
	else
		pMember._Name = member.name
	end
	pMember._IsOnLine = member.isOnline
	pMember._MapTid = member.worldId
	pMember._LineId = member.lineId
	pMember._MapTag = member.mapTag
	pMember._Profession = member.profession
	pMember._Gender = Profession2Gender[member.profession]
	pMember._Lv = member.level
	pMember._Hp = member.Hp
	pMember._HpMax = member.MaxHp
	pMember._Fight = math.ceil(member.Competitiveness)
	pMember._Position = { x = member.x, z = member.z}
	pMember._IsFollow = member.isFollow
	pMember._IsAssist = member.isAssist

	local ModelParams = require "Object.ModelParams"
	local param = ModelParams.new()
	param:MakeParam(member.exterior, member.profession)
	pMember._Param = param

	table.insert(curMemberList, pMember)

	local hp = game._HostPlayer
	--刷新队员Top血条
	if pMember._ID ~= hp._ID then
		local memberObj = game._CurWorld:FindObject(pMember._ID)
		if memberObj ~= nil then
			memberObj:SetTeamId(teamId)
			memberObj:UpdateTopPateName(true)
			memberObj:UpdatePetName()
			memberObj:UpdateTopPate(EnumDef.PateChangeType.HPLine)
			memberObj:UpdateTopPate(EnumDef.PateChangeType.Rescue)
		end
	end

	hp:UpdateTargetSelected(pMember._ID)
end

--剔除组员
local function RemoveMember(self, id)
	local teamMemberList = self._Team._MemberList
	if id > 0 then
		local index = 0
		for i=1, #teamMemberList do
			if id == teamMemberList[i]._ID then
				index = i
				break
			end
		end

		if index > 0 then
			table.remove(teamMemberList, index)
		end
	end

	--刷新队员Top血条
	if id ~= game._HostPlayer._ID then
		local member = game._CurWorld:FindObject( id )
		if member then
			member:SetTeamId(0)
			member:UpdateTopPateName(true)
			member:UpdatePetName()
			member:UpdateTopPate(EnumDef.PateChangeType.HPLine)
			member:UpdateTopPate(EnumDef.PateChangeType.Rescue)
		end
	end

	game._HostPlayer:UpdateTargetSelected(id)
end

--设置队员数据
def.method("table").UpdateMemberList = function(self, data)
	local bNotify = not self:InTeam()

	local hp = game._HostPlayer
	hp._TeamId = data.info.teamID
	
	self._Team._ID = data.info.teamID
	self._Team._TargetId = data.info.targetId
	self._Team._TeamLeaderId = data.info.captainID
	self._Team._IsBountyMode = data.info.isBountyMode
    self._Team._TeamName = data.info.teamName
    self._Team._TeamMode = data.info.mode

    self._Team._MemberMax = (data.info.mode == TeamMode.Corps) and bigTeamMaxMemCount or smallTeamMaxMemCount

	local list = self._Team._MemberList

	if #data.memberList ~= #list then
		local teamListInfo = data.memberList
		if #teamListInfo > #list then
			for i,v in ipairs(teamListInfo) do  -- 这里是刷新 还是全部重新添加？？
				AddMember(self, v, data.info.teamID)
			end
		else
			RemoveMember(self, data.info.modifyRoleID)
		end
	end

	if self:IsTeamLeader() then
		self:SetLeaderFollowState()
	else
		local member = self:GetMember(hp._ID)
		self:SetHostFollowState(member._IsFollow)
	end

	if #data.memberList > 1 then
		local leaderIdx = 0
		for i,v in ipairs(list) do
			if v._ID == self._Team._TeamLeaderId then
				leaderIdx = i
			end
		end
		if leaderIdx ~= 0 and leaderIdx ~= 1 then
			local leader = list[leaderIdx]
			local firstMember = list[1]
			list[1] = leader
			list[leaderIdx] = firstMember
		end
	end

	if bNotify then
		local TeamJoinOrQuitEvent = require "Events.TeamJoinOrQuitEvent"
		local event = TeamJoinOrQuitEvent()
		event._InTeam = true
		CGame.EventManager:raiseEvent(nil, event)
	end
end

----------------------------------------------------------------------
--							C2S::S2CTeam Funcs
----------------------------------------------------------------------
--T人 ok
def.method("number").KickMember = function(self, memberId)
	local title, msg, closeType = StringTable.GetMsg(69)
	local str = string.format(msg, self:GetTeamMemberName(memberId))
	MsgBox.ShowMsgBox(str, title, closeType,  MsgBoxType.MBBT_OKCANCEL,function(val)
        if val then
            local C2STeamT = require "PB.net".C2STeamT
			local protocol = C2STeamT()

			protocol.tData.teamID = self._Team._ID
			protocol.tData.roleID = memberId

			SendProtocol(protocol)
        end
    end)
end

--交换队长 ok
def.method("number").ExchangeLeader = function (self, memberId)
	local title, msg, closeType = StringTable.GetMsg(70)
	local str = string.format(msg, self:GetTeamMemberName(memberId))
	MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_OKCANCEL,function(val)
        if val then
            local C2STeamExchangeCapation = require "PB.net".C2STeamExchangeCapation
			local protocol = C2STeamExchangeCapation()

			protocol.exchangeCaptionData.teamID = self._Team._ID
			protocol.exchangeCaptionData.newCaptionRoldId = memberId

			SendProtocol(protocol)
        end
    end)
end

def.method("number", "number").StartTeamPrepare = function(self, deadLine, dungeonTid)
    local callback = function(val)
        if val then
            if dungeonTid > 0 then
                local reward_count = game._DungeonMan:GetRemainderCount(dungeonTid)
                if reward_count <= 0 then
                    local callback = function(val)
                        TeamUtil.ConfirmParepare(val)
                    end
                    local dungeon_temp = CElementData.GetTemplate("Instance", dungeonTid)
                    if dungeon_temp == nil then
                        TeamUtil.ConfirmParepare(false)
                    end
                    local title, msg, closeType = StringTable.GetMsg(88)
                    local message = string.format(msg, dungeon_temp.TextDisplayName)
			        MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.ImportantTip)
                else
    		        TeamUtil.ConfirmParepare(true)
                end
            else
                TeamUtil.ConfirmParepare(true)
            end
        else
            TeamUtil.ConfirmParepare(false)
        end
    end
    local timeNow = GameUtil.GetServerTime() / 1000
    local duration = math.ceil(deadLine - timeNow)
    -- warn("deadLine = ", deadLine, timeNow, duration)
	local param = {Duration = duration, DungeonId = dungeonTid, CallBack = callback}
	game._GUIMan:Open("CPanelUITeamConfirm", param)

	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	CQuestAutoMan.Instance():Stop()

	local CAutoFightMan = require "AutoFight.CAutoFightMan"
	CAutoFightMan.Instance():Stop()
end

def.method("boolean").UpdateTeamPrepareResult = function(self, ready)
	if ready then
		game._GUIMan:Close("CPanelUITeamMember")
	end
	game._GUIMan:Close("CPanelUITeamConfirm")
end


--返回当前设置信息
def.method("table").UpdateTeamMatchSetting  = function(self, protocol)
	do
		local ETeamMatchSettingType = require "PB.net".S2CTeamMatchSetting.Type
		local curType = protocol.OptType
		--1.请求 0.设置
		if curType == ETeamMatchSettingType.TYPE_Req then
			game._GUIMan:Open("CPanelUITeamSetting", protocol.Setting)
		elseif curType == ETeamMatchSettingType.TYPE_Set then
			game._GUIMan:Close("CPanelUITeamSetting")
			TeraFuncs.SendFlashMsg(StringTable.Get(22013), false)
		end
	end
	
	if self._Team._Setting == nil or self._Team._Setting.TargetId ~= protocol.Setting.TargetId then
		--副本目标
		
        if self._Team._Setting ~= nil then
	        local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", protocol.Setting.TargetId)
        	local str = teamRoomConfig ~= nil and teamRoomConfig.DisplayName or StringTable.Get(22011)
			--弹出更改信息提示
			str = string.format(StringTable.Get(22402), str)
			TeraFuncs.SendFlashMsg(str, false)
			local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
			local ChatManager = require "Chat.ChatManager"
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelTeam, str, false, 0, nil,nil)
		end
		--缓存设置信息
		self._Team._TargetId = protocol.Setting.TargetId
		self._Team._Setting = protocol.Setting
	else
		self._Team._Setting = protocol.Setting
	end
    TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.TeamSetting)
end

def.method("=>", "string").GetCurTargetString = function(self)
    local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", self._Team._TargetId)
	local str = teamRoomConfig == nil and StringTable.Get(22011) or PaddingRoomLevel(teamRoomConfig.DisplayName, teamRoomConfig.DisplayLevel)
	return str
end

def.method("=>", "boolean").IsBountyMode = function(self)
	return self._Team._IsBountyMode
end

local function DoFollow(bFollow)
	local hp = game._HostPlayer
	if hp == nil then return end
    local pos = hp:GetPos()
	local C2STeamFollow = require "PB.net".C2STeamFollow
	local protocol = C2STeamFollow()
    protocol.isFollow = bFollow
    protocol.Position.x = pos.x
    protocol.Position.y = pos.y
    protocol.Position.z = pos.z

    SendProtocol(protocol)
end

--组队跟随
def.method("boolean").FollowLeader = function(self, bFollow)
	if not bFollow then
		DoFollow(bFollow)
	else
		local hostMapTid = game._CurWorld._WorldInfo.MapTid
		local leader = self:GetMember(self._Team._TeamLeaderId)
		local leaderMapTid = leader ~= nil and leader._MapTid or 0
		if leaderMapTid == hostMapTid then
			DoFollow(bFollow)
		else
			local function callback(ret)
				if ret then
					DoFollow(bFollow)
				end
			end
			local title, msg, closeType = StringTable.GetMsg(74)
			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback) 			
		end
	end
end

--队长召唤跟随确认
def.method().ShowTeamFollowConfirm = function(self)
	local callback = function(val)
		if val then
            local callback1 = function(isOK)
                if isOK then
			        TeamUtil.ConfirmFollowState(val)
                end
            end

            if not self:IsSameMapWithLeader() then
	            if game._CurMapType == EWorldType.Pharse then
	                local title, msg, closeType = StringTable.GetMsg(82)
	                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback1)
	            elseif game._CurMapType == EWorldType.Immediate then
	                local title, msg, closeType = StringTable.GetMsg(97)
	                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback1)
	            else
	                callback1(true)
	            end
	        else
	        	callback1(true)
	        end
		end
	end
	local title, msg, closeType = StringTable.GetMsg(71)
	MsgBox.ShowMsgBox(msg, title, closeType, bit.bor(MsgBoxType.MBBT_YESNO, MsgBoxType.MBT_TIMEYES), callback, 10, nil, MsgBoxPriority.ImportantTip) 
end

-- 修改队伍名称
def.method("string").UpdateTeamName = function(self, newTeamName)
    self._Team._TeamName = newTeamName
end

def.method("table").UpdateTeamEquipInfo = function(self, equipInfoList)
	local hp = game._HostPlayer
	-- 如果是第一次初始化 并且 （不在新手本 或 副本中）方可显示
	if self._Team._IsFirstInit and (hp:InDungeon() or game:IsInBeginnerDungeon()) then
		self._Team._IsFirstInit = false
		return
	end

	local ModelParams = require "Object.ModelParams"
	for i,equipInfo in ipairs(equipInfoList) do
		local member = self:GetMember(equipInfo.Id)
		if member ~= nil then 
			local param = ModelParams.new()
			param:MakeParam(equipInfo.Exterior, member._Profession)
			member._Param = param
		end
	end

	game._GUIMan:Open("CPanelUITeamMember", nil)
end

local function ClosePanels()
	local panel_list = 
	{
		"CPanelUITeamMember",
		"CPanelUITeamConfirm",
		"CPanelUITeamCreate",
		"CPanelUITeamInvite",
		"CPanelUITeamSetting",
	}
	for i,v in ipairs(panel_list) do
		game._GUIMan:Close( v )
	end
end

def.method().Reset = function(self)
	CancelFollowCooldownTimer(self)
	self:ResetMemberList()
	ClosePanels()

	InActiveFollowButton(self)
	TeamUtil.SendInfoChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end

def.method().Cleanup = function(self)
	ClosePanels()
	self._InvitedCache = nil
	self._IsInviting = false
	self._InvitingCount = 0
	self._Team:Reset()
end

CTeamMan.Commit()
return CTeamMan