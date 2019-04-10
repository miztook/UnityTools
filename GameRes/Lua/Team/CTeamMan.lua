local Lplus = require "Lplus"
local UserData = require "Data.UserData".Instance()
local CTeamMember = require "Team.CTeamMember"
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local CTeamMan = Lplus.Class("CTeamMan")
local CPlayer = require "Object.CPlayer"
local CTeam = require "Team.CTeam"
local CPVPAutoMatch = require "ObjHdl.CPVPAutoMatch"
local ERule = require "PB.Template".TeamRoomConfig.Rule
local EWorldType = require "PB.Template".Map.EWorldType
local TeamMode = require "PB.data".TeamMode
local bit = require "bit"

local def = CTeamMan.define
local instance = nil
local smallTeamMaxMemCount = 5
local bigTeamMaxMemCount = 10

def.field('boolean')._IsInited = true
def.field(CTeam)._Team = nil
--def.field("number")._TargetMatchId = 0
def.field("table")._TeamRoomDataTable = BlankTable
def.field("table")._InvitedCache = BlankTable
def.field("boolean")._IsInviting = false			-- 邀请过的列表

local function SendFlashMsg(msg, bUp)
	game._GUIMan:ShowTipText(msg, bUp)
end

def.static("=>", CTeamMan).Instance = function()
	if not instance then
		instance = CTeamMan()
		instance._Team = CTeam.new()
	end
	return instance
end

----------------------------------------------------------------------
--							Client::Team Funcs
----------------------------------------------------------------------

def.method("number").SendLinkMsg = function(self, channelType)
	if self._Team._Setting.TargetId > 1 then
		local ChatLinkType = require "PB.data".ChatLinkType
		local ChatChannel = require "PB.data".ChatChannel
		local ERule = require "PB.Template".TeamRoomConfig.Rule

		local linkInfo = {}
		local chatLink = {}
	    chatLink.LinkType = ChatLinkType.ChatLinkType_Team
	    chatLink.ContentID = self._Team._ID
	    linkInfo.ChatLink = chatLink

	    local lv = self._Team._Setting.Level
	    local combatPower = self._Team._Setting.CombatPower
	    local targetId = self._Team._Setting.TargetId

		linkInfo.chatChannel = channelType
		linkInfo.TargetId = targetId
		linkInfo.Level = lv
		linkInfo.CombatPower = combatPower
	    require "Chat.ChatManager".Instance():ChatOtherSend(linkInfo)

	    if channelType == ChatChannel.ChatChannelWorld then
	    	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
			if CPanelUITeamMember.Instance():IsShow() then
	    		CPanelUITeamMember.Instance():MarkCanSendWorldChatTime()
	    	end
	    end
	end
end


def.method("=>", "boolean").HaveTeamMemberInSameMap = function(self)
	if not self:InTeam() then return false end
	local bRet = false

	local hostTeamInfo = self:GetTeamMember(game._HostPlayer._ID)
	local hostMapTag = hostTeamInfo._MapTag
	local memberList = self:GetMemberList()

	for i=1, #memberList do
		local member = memberList[i]
		if member._ID ~= game._HostPlayer._ID and
		   member._IsOnLine == true and
		   hostMapTag == member._MapTag then
		   
			bRet = true
			break
		end
	end

	return bRet
end

---- 设置 队员最大上限
--def.method("number").SetMemberMax = function(self, count)
--	if self._Team ~= nil then
--		self._Team:SetMemberMax(count)
--	end
--end

-- 获取 队员最大上限
def.method("=>", "number").GetMemberMax = function(self)
	return self._Team ~= nil and self._Team:GetMemberMax() or 0
end

-- 设置自己的队伍的模式（普通队伍还是团队）
def.method("number").SetSelfTeamMode = function(self, mode)
    if self._Team ~= nil then
        self._Team._TeamMode = mode
        if mode == TeamMode.Corps then
            self._Team._MemberMax = bigTeamMaxMemCount
        else
            self._Team._MemberMax = smallTeamMaxMemCount
        end
        if self._Team._TargetId > 0 then
            local dungeon_id = self:ExchangeToDungeonId(self._Team._TargetId)
            local dungeon_temp = CElementData.GetTemplate("Instance", dungeon_id)
            if dungeon_temp ~= nil then
                if self._Team._MemberMax ~= dungeon_temp.MaxRoleNum then
                    self._Team._TargetId = 0
                end
            end
        end
    end
end

-- 当前队伍mode， 对应data.TeamMode
def.method("=>", "number").GetTeamMode = function(self)
    if self._Team == nil then
        return 0
    else
        if self:InTeam() then
            return self._Team._TeamMode
        else
            return 0
        end
    end
end

-- 当前队伍是否是团
def.method("=>", "boolean").IsBigTeam = function(self)
    if not self:InTeam() then
        return false
    end
    return self._Team._TeamMode == TeamMode.Corps
end


-- 设置是否正在邀请队员
def.method("boolean").SetInvitingState = function(self, bIsInviting)
	self._IsInviting = bIsInviting
end
def.method("=>", "boolean").IsInviting = function(self)
	return self._IsInviting
end
-- 添加本地邀请过的列表
def.method("number").AddInvitedCache = function(self, roleId)
	-- 1. 添加
	self._InvitedCache[#self._InvitedCache+1] = roleId
	-- 2. 去重
	removeRepeated(self._InvitedCache)
end
-- 查询是否邀请过该成员
def.method("number", "=>", "boolean").HasInvited = function(self, roleId)
	local bRet = false
	if next(self._InvitedCache) ~= nil then
		for i=1,#self._InvitedCache do
			if roleId == self._InvitedCache[i] then
				bRet = true
				break
			end
		end
	end

	return bRet
end
-- 同步邀请过人员列表
def.method("table").SyncInviteCache = function(self, invitedList)
	self:ResetInvitedCache()
	for i,v in ipairs(invitedList) do
		self._InvitedCache[i] = v
	end
end
-- 重置邀请过人员列表
def.method().ResetInvitedCache = function(self)
	self._InvitedCache = {}
end

--获取link信息拼接的字符串
def.method("number", "number", "number", "=>", "string").GetLinkStr = function(self, targetId, lv, combatPower)
    local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", targetId)
	local str = ""
	local lineStr = "[l]"..StringTable.Get(22019).."[-]"
    if teamRoomConfig ~= nil then
        str = teamRoomConfig.DisplayName
    end
    local team_name = self._Team._TeamName
    
    if str == "" then
        if team_name == "" then
    	    str = string.format(StringTable.Get(22407), lv, combatPower)
        else
            str = string.format(StringTable.Get(22413), self._Team._TeamName, lv, combatPower)
        end
    else
        if team_name == "" then
    	    str = string.format(StringTable.Get(22406), str, lineStr, lv, combatPower)
        else
            str = string.format(StringTable.Get(22413), self._Team._TeamName, str, lineStr, lv, combatPower)
        end
    end
    
    return str
end

--上线时 设置当前队伍申请红点状态
def.method().InitTeamApplyRedDotState = function(self)
	self:SetTeamApplyRedDotState(false)
end
--刷新UE 红点
def.method().RefreshTeamApplyRedDotState = function(self)
	local CPanelTracker = require "GUI.CPanelTracker"

	if CPanelTracker.Instance():IsShow() then
		CPanelTracker.Instance():UpdateTeamRedDotState()
	end

	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
	if CPanelUITeamMember.Instance():IsShow() then
		CPanelUITeamMember.Instance():UpdateTeamRedDotState()
	end
end
--获取队伍申请 红点信息
def.method("=>", "boolean").GetTeamApplyRedDotState = function(self)
	return CRedDotMan.GetModuleDataToUserData("TeamApply") or false
end
--设置队伍申请 红点信息
def.method("boolean").SetTeamApplyRedDotState = function(self, bShow)
	CRedDotMan.SaveModuleDataToUserData("TeamApply", bShow)
end

def.method("number", "=>", "table").GetMemberPositionInfo = function(self, memberId)
	local memberInfo = self:GetMemberInfoById(memberId)
	if memberInfo == nil or memberInfo._Position == nil then return nil end

	local ret = { Position = memberInfo._Position, MapId = memberInfo._MapTid}
	return ret
end

--def.method("=>", "number").GetTargetMatchId = function(self)
--	return self._TargetMatchId
--end

def.method("number", "=>", "boolean").IsOnline = function(self, id)
	local member = self:GetMemberInfoById(id)
	return (member ~= nil and member._IsOnLine)
end

def.method("=>", "boolean").HaveOnlineMember = function(self)
	local bRet = false
	local memberList = self:GetMemberList()

	for i=1, #memberList do
		local member = memberList[i]
		if member._IsOnLine == true and member._ID ~= game._HostPlayer._ID then
			bRet = true
			break
		end
	end
	return bRet
end

--def.method("boolean").SetAutoMatching = function(self, bAuto)
----	if CPVPAutoMatch.Instance():CanMatch() and bAuto then
----		if self:InTeam() then
----			CPVPAutoMatch.Instance():Start(EnumDef.AutoMatchType.InTeam, nil, nil)
----		else
----			CPVPAutoMatch.Instance():Start(EnumDef.AutoMatchType.SearchTeam, nil, nil)
----		end
----	else
----		CPVPAutoMatch.Instance():Stop()
----	end

--	self._Team._IsAutoMatch = bAuto
--    local CPanelTracker = require "GUI.CPanelTracker"
--    CPanelTracker.Instance():UpdateTeamMemberCount()
--    CPanelTracker.Instance():UpdateMatchingText()
--end

--def.method("=>", "boolean").IsAutoMatching = function(self)
--	return self._Team._IsAutoMatch
--end

def.method("number", "=>", "table").GetMemberInfoById = function(self, memberId)
	local memberList = self:GetMemberList()
	local info = nil

	for i=1, #memberList do
		if memberList[i]._ID == memberId then
			info = memberList[i]
			break
		end
	end

	return info
end

def.method("=>","boolean").IsSameMapIdOfLeader = function(self)
	return game._CurWorld._WorldInfo.MapTid == self:GetLeaderMapId()
end

def.method("=>", "number").GetLeaderMapId = function(self)
	local info = self:GetLeaderInfo()
	local ret = 0

	if info ~= nil then
		ret = info._MapTid
	end

	return ret
end

def.method("=>", "table").GetLeaderInfo = function(self)
	local memberList = self:GetMemberList()
	local info = nil

	for i=1, #memberList do
		if memberList[i]._ID == self._Team._TeamLeaderId then
			info = memberList[i]
			break
		end
	end

	return info
end

def.method("dynamic", "=>", "boolean").CanJoinTeamInSight = function(self, entity)
	if entity == nil then return false end
	if entity:IsHostile() then return false end

	return true
end

--获取当前视野范围内存在的队员个数
def.method("=>", "number").GetTeamMemberCountInSight = function(self)
	local count = 1

	local teamMemberList = self:GetMemberList()
	for i=1, #teamMemberList do
		local memberInfo = teamMemberList[i]
		if memberInfo._ID ~= game._HostPlayer._ID then
			local findMember = game._CurWorld:FindObject( memberInfo._ID )
			if findMember then
				count = count + 1
			end
		end
	end

	return count
end

def.method("=>", "string").GetTeamName = function(self)
    return self._Team._TeamName
end

def.method().UpdateAllMemberPateNameInSight = function(self)
	local teamMemberList = self:GetMemberList()
	for i=1, #teamMemberList do
		local memberInfo = teamMemberList[i]

		if memberInfo._ID ~= game._HostPlayer._ID then
			local findMember = game._CurWorld:FindObject( memberInfo._ID )
			if findMember then

				if findMember._TopPate then
					findMember._TopPate:UpdateName(true)
					findMember:UpdatePetName()
				end
				findMember:UpdateTopPate(EnumDef.PateChangeType.HPLine)
				findMember:UpdateTopPate(EnumDef.PateChangeType.Rescue)
			end
		end
	end
	game._HostPlayer:UpdateTargetSelected()
end

--有队员离开时，需要刷新Toppate的信息
def.method("number").UpdateMemberPateNameInSight = function(self, memberId)
	local findMember = self:GetTeamMemberInSight( memberId )
	if findMember then
		findMember._TopPate:UpdateName(true)
		findMember:UpdatePetName()
	end
end

--获取当前视野范围内存在的队员
def.method("number", "=>", CPlayer).GetTeamMemberInSight = function(self, memberId)
	local findMember = game._CurWorld:FindObject( memberId )
	if findMember then
		return findMember
	end

	return nil
end

--获取当前 队伍中 跟随的队员总数
def.method("=>", "number").GetTeamMemberFollowingCount = function(self)
	local count = 0

	local teamMemberList = self:GetMemberList()
	for i=1, #teamMemberList do
		local memberInfo = teamMemberList[i]
		if memberInfo._ID ~= game._HostPlayer._ID and memberInfo._IsFollow then
			count = count + 1
		end
	end

	return count
end

--获取当前组队跟随 排序位置
def.method("=>", "number").CalcFollowIndex = function(self)
	local hp = game._HostPlayer

	--当前视野范围内成员个数
	local curCount = self:GetTeamMemberFollowingCount()
	local followIndex = curCount + 1 --从1开始，为了table取值方便

	if followIndex < self._Team._FollowIndex or self._Team._FollowIndex == 0 then
		self:SetFollowIndex( followIndex )
	end

	return followIndex
end

--设置当前组队跟随 排序位置
def.method("number").SetFollowIndex = function(self, followIndex)
	self._Team._FollowIndex = followIndex
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

--是否在队伍中
def.method("=>", "boolean").InTeam = function(self)
	return self._Team._ID > 0
end

--是否在同一队伍
def.method("number", "=>", "boolean").InSameTeam = function(self, teamId)
	return self:InTeam() and self._Team._ID == teamId
end

--获取队员名称
def.method("number", "=>", "string").GetTeamMemberName = function(self, memberId)
	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		if v._ID == memberId then
			return v._Name
		end
	end
	return ""
end

def.method("table").ChangeMemberPosition = function(self, data)
	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		----warn("v._ID = ",v._ID,"data.roleID = ",data.roleId)
		if v._ID == data.roleId then
			v._MapTid = data.mapTId
			v._Position = {x = data.x, z = data.z }
			break
		end
	end
end

--队员线路及地图ID
def.method("table").ChangeMemberMapInfo = function(self, data)
	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		----warn("v._ID = ",v._ID,"data.roleID = ",data.roleId)
		if v._ID == data.roleId then
			v._MapTid = data.worldId
			v._LineId = data.lineId
			v._MapTag = data.mapTag
			v._GameServerId = data.gameServerId
			break
		end
	end
end

local function SendChangeEvent(type, data)
	local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"
	local event = TeamInfoChangeEvent()
	event._Type = type

	if data then
		event._ChangeInfo = data
	end

	CGame.EventManager:raiseEvent(nil, event)
end
--队员血量
def.method("table").ChangeMemberHp = function (self, data)
	local teamMemberList = self:GetMemberList()

	for k,v in pairs(teamMemberList) do
		----warn("v._ID = ",v._ID,"data.roleID = ",data.roleId)
		if v._ID == data.roleId then
			if v._Hp > 0 and data.HP <= 0 then
				--死了
				SendChangeEvent(EnumDef.TeamInfoChangeType.DeadState, {roleId = data.roleId, DeadState = true})
				if data.roleId ~= game._HostPlayer._ID  then
					local hostInfo = self:GetMemberInfoById(game._HostPlayer._ID)
					local roleInfo = self:GetMemberInfoById(data.roleId)
					
					if hostInfo._MapTid == roleInfo._MapTid and hostInfo._LineId == roleInfo._LineId then
						SendFlashMsg(string.format(StringTable.Get(22044), v._Name), false)
					end
				end
			elseif v._Hp <= 0 and data.HP > 0 then
				--活了
				SendChangeEvent(EnumDef.TeamInfoChangeType.DeadState, {roleId = data.roleId, DeadState = false})
			end
			v._Hp = data.HP
			v._HpMax = data.MaxHp
			break
		end
	end
end

--队员等级
def.method("table").ChangeMemberLevel = function (self, data)
	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		if v._ID == data.roleId then
			v._Lv = data.level
			break
		end
	end
end

--上下线
def.method("table").ChangeMemberOnline = function(self, data)
	if game._HostPlayer == nil or data.roleID == game._HostPlayer._ID then
		return
	end

	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		if v._ID == data.roleId then
			v._IsOnLine = data.isOnline
			if data.isOnline == false and data.roleId ~= game._HostPlayer._ID then
				SendFlashMsg(string.format(StringTable.Get(22043), v._Name), false)
			end
			break
		end
	end
end

--战斗力同步
def.method("table").ChangeFightScore = function(self, data)
	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		if v._ID == data.roleId then
			v._Fight = data.fightScore
			break
		end
	end
end

--队伍目标同步
def.method("table").ChangeTeamTarget = function(self, data)
	self._Team._TargetId = data.targetId
end

def.method("number", "=>", "boolean").MemberIsSelf = function(self, memberId)
	return memberId == game._HostPlayer._ID
end

def.method().StopFollow = function(self)
	if self:IsFollowing() then
		self:FollowLeader(false)
	end
end

--组队跟随标志
def.method("table").ChangeMemberFollow = function(self, data)
	local teamMemberList = self:GetMemberList()
	for k,v in pairs(teamMemberList) do
		if v._ID == data.roleId then
			v._IsFollow = data.isFollow
			break
		end
	end

	-- 如果是主角，提醒，并停止自动战斗
	if self:MemberIsSelf(data.roleId) then
		local str = nil
		if data.isFollow then
			str = StringTable.Get(237)
		else
			str = StringTable.Get(238)
		end
		SendFlashMsg(str ,false)
	end

	if self:IsTeamLeader() then
		-- warn("队长设置状态")
		self:SetLeaderFollowState()
	else
		--自己跟随状态开启
		if self:MemberIsSelf( data.roleId ) then
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
				local CAutoFightMan = require "ObjHdl.CAutoFightMan"
				CAutoFightMan.Instance():Stop() 
			else
				--local CAutoFightMan = require "ObjHdl.CAutoFightMan"
				--CAutoFightMan.Instance():Stop()
			end
		end
	end

	self:RefreshPanel()
end

--获取成员信息，teammember
def.method("number", "=>", "table").GetTeamMember = function(self, id)
	local teamMemberList = self:GetMemberList()
	for i=1, #teamMemberList do
		if teamMemberList[i]._ID == id then
			return teamMemberList[i]
		end
	end
	return nil	
end

--队员时，只关心自己的状态
def.method("boolean").SetHostFollowState = function(self, bFollowed)
	local hp = game._HostPlayer

	if hp:In3V3Fight() then
		self:ChangeFollowState(EnumDef.FollowState.In3V3Fight)
		return
	end

	if bFollowed then		
		self:ChangeFollowState( EnumDef.FollowState.Member_Followed )
	else
		
		self:ChangeFollowState( EnumDef.FollowState.Member_None )
	end

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
		local teamMemberList = self:GetMemberList()
		local bFollowing = false
		self:ChangeFollowState(EnumDef.FollowState.Leader_Followed)
	--[[
		for i=1, #teamMemberList do
			local member = teamMemberList[i]
			if member._ID ~= hp._ID and member._IsFollow then
				bFollowing = true

				break
			end
		end
		
		if bFollowing then
			self:ChangeFollowState(EnumDef.FollowState.Leader_Followed)
		else
			self:ChangeFollowState(EnumDef.FollowState.Leader_None)
		end
	]]
	else
		self:ChangeFollowState(EnumDef.FollowState.Leader_NoMember)
	end
end

def.method("=>", "boolean").IsAutoApprove = function(self)
	return self._Team._Setting.AutoApproval
end

def.method("boolean").ChangeAutoApprove = function(self, bAuto)
	self._Team._AutoApprove = bAuto
	local CPanelUITeamSetting = require "GUI.CPanelUITeamSetting"
	CPanelUITeamSetting.Instance():UpdateAutoApprove()
end

----更改赏金模式
--def.method("table").ChangeBounty = function(self, data)
--	self._Team._IsBountyMode = data.isBounty

--	local CPanelUITeamSetting = require "GUI.CPanelUITeamSetting"
--	CPanelUITeamSetting.Instance():UpdateBountyMode()

--	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
--	CPanelUITeamMember.Instance():UpdateBountyBtn()
--end

----更改匹配状态
--def.method("table").ChangeTeamMatchState = function(self, data)
--	self:SetAutoMatching(data.isMatching)

--	local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
--	if CPanelUITeamMember and CPanelUITeamMember.Instance():IsShow() then
--		CPanelUITeamMember.Instance():SetAutoMatchText()
--	end
--end

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
def.field("number")._FollowCooldownTimerId = 0
def.field("number")._FollowCooldownTime = 0
local MaxFollowCooldownTime = 3

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
	-- local CPanelUITeamMember = require "GUI.CPanelUITeamMember"
	-- if CPanelUITeamMember and CPanelUITeamMember.Instance():IsShow() then
	-- 	CPanelUITeamMember.Instance():UpdateTeamInfo()
	-- end
    --血条界面不再提供队长标志了
	--[[local CPanelUIHead = require "GUI.CPanelUIHead"
	CPanelUIHead.Instance():UpdateLeaderMark()]]

	local CPanelTracker = require "GUI.CPanelTracker"
	CPanelTracker.Instance():UpdateTeamMemberCount()
end

def.method("dynamic").SetDefaultTeamName = function(self, leaderName)
    if leaderName == nil then return end
    local new_name = string.format(StringTable.Get(22037), leaderName)
    self._Team._TeamName = new_name
    self:SendC2SChangeTeamName(new_name)
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
	return #self:GetMemberList() >= 2
end

def.method("number" ,"=>", "boolean").IsTeamMember = function(self, entityId)
	if self:InTeam() then
		local list = self:GetMemberList()
		if #list > 0 then
			for i,member in ipairs( list ) do
				if member._ID == entityId then
					return true
				end
			end
		end
	end

	return false
end

--获取队员数据列表
def.method("=>", "table").GetMemberList = function (self)
	return self._Team._MemberList
end

--获取除队长以外的队伍数据
def.method("=>", "table").GetMemberListExceptHost = function(self)
	local list = {}
	for i,v in ipairs( self:GetMemberList() ) do
		if v._ID ~= game._HostPlayer._ID then
			table.insert(list, v)
		end
	end
	return list
end

--获取队员个数
def.method("=>", "number").GetMemberCount = function (self)
	return #self._Team._MemberList
end

--重置队员数据
def.method().ResetMemberList = function (self)
	local hp = game._HostPlayer
	if hp == nil then return end

	local world = game._CurWorld
	for k,v in pairs( self:GetMemberList() ) do
		local id = v._ID
		v:ResetMember()

		local findMember = world:FindObject( id )
		if findMember then
			if findMember._TopPate then
				findMember._TopPate:UpdateName(true)
				findMember:UpdatePetName()
			end
			findMember:UpdateTopPate(EnumDef.PateChangeType.HPLine)
			findMember:UpdateTopPate(EnumDef.PateChangeType.Rescue)
		end

		self._Team._MemberList[k] = nil
	end
	
	self._Team:Reset()
	self._IsInited = true
	hp._TeamId = 0
	
	local TeamJoinOrQuitEvent = require "Events.TeamJoinOrQuitEvent"
	local event = TeamJoinOrQuitEvent()
	event._InTeam = false
	CGame.EventManager:raiseEvent(nil, event)

	-- 重置红点状态
	self:SetTeamApplyRedDotState(false)
	self:RefreshTeamApplyRedDotState()
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
--设置队员数据
def.method("table").UpdateMemberList = function(self, data)
	local bNotify = false
	if not self:InTeam() then
		bNotify = true
	end

	local hp = game._HostPlayer
	self._Team._ID = data.info.teamID
	self._Team._TargetId = data.info.targetId
	hp._TeamId = data.info.teamID
	self._Team._TeamLeaderId = data.info.captainID
	self._Team._IsBountyMode = data.info.isBountyMode
--	self._Team._IsAutoMatch = data.info.isMatching
    self._Team._TeamName = data.info.teamName
    self._Team._TeamMode = data.info.mode
    if data.info.mode == TeamMode.Corps then
        self._Team._MemberMax = bigTeamMaxMemCount
    else
        self._Team._MemberMax = smallTeamMaxMemCount
    end

	local list = self:GetMemberList()
	local modifyRoleID = data.info.modifyRoleID

	if #data.memberList ~= #list then
		local teamListInfo = data.memberList
		if #data.memberList > #list then
			--AddMember
			if self._IsInited then
				for i,v in ipairs(teamListInfo) do
					self:AddMember(v, data.info.teamID)
				end
				self._IsInited = false
			else
				local newMemberList = {}
				for i,v in ipairs(teamListInfo) do
					if not self:IsTeamMember( v.roleID ) then
						self:AddMember(v, data.info.teamID)
					end
				end
			end
		else
			--PopMember
			self:PopMember( modifyRoleID )
		end
	end

	if self:IsTeamLeader() then
		self:SetLeaderFollowState()
	else
		local teamMemberList = self:GetMemberList()

		for i=1, #teamMemberList do
			local member = teamMemberList[i]
			if member._ID == hp._ID then
				self:SetHostFollowState(member._IsFollow)
				break
			end
		end
	end

	if #data.memberList > 1 then
		self:SortMemberByLeader(self._Team._TeamLeaderId)
	end

	if bNotify then
		local TeamJoinOrQuitEvent = require "Events.TeamJoinOrQuitEvent"
		local event = TeamJoinOrQuitEvent()
		event._InTeam = true
		CGame.EventManager:raiseEvent(nil, event)
	end

	--if reason ==  _G.UpdateReason. then
	--end
end

--添加组员
def.method("number").SortMemberByLeader = function (self,LeaderID)
	local resultList = {}
	for i,v in ipairs(self:GetMemberList()) do
		if v._ID == LeaderID then
			table.insert(resultList, v)
			break
		end
	end
	for i,v in ipairs(self:GetMemberList()) do
		if v._ID ~= LeaderID then
			table.insert(resultList, v)
		end
	end
	self._Team._MemberList = resultList
end

--添加组员
def.method("table", "number").AddMember = function (self, member, teamId)
	--warn("AddMember---------------",teamId , member.roleID)
	local pMember = CTeamMember.new()
	pMember._ID = member.roleID
	
	if member.isAssist and tonumber(member.name) ~= nil then
		local npcName = CElementData.GetTextTemplate(tonumber(member.name))
		pMember._Name = npcName.TextContent
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
	table.insert(self:GetMemberList() , pMember)

	--刷新队员Top血条
	if pMember._ID ~= game._HostPlayer._ID then
		local memberObj = game._CurWorld:FindObject( pMember._ID )
		if memberObj ~= nil then
			memberObj:SetTeamId(teamId)
			if not IsNil(memberObj._TopPate) then 
				memberObj._TopPate:UpdateName(true)
				memberObj:UpdatePetName()
			end
			memberObj:UpdateTopPate(EnumDef.PateChangeType.HPLine)
			memberObj:UpdateTopPate(EnumDef.PateChangeType.Rescue)
		end
	end

	game._HostPlayer:UpdateTargetSelected()
end

--剔除组员
def.method("number").PopMember = function (self, id)
	----warn("========PopMember=======[id = "..id.."]")
	local teamMemberList = self:GetMemberList()
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
			if member._TopPate then
				member._TopPate:UpdateName(true)
				member:UpdatePetName()
				member:UpdateTopPate(EnumDef.PateChangeType.HPLine)
				member:UpdateTopPate(EnumDef.PateChangeType.Rescue)
			end
		end
	end

	game._HostPlayer:UpdateTargetSelected()
end

def.method().ModifyMemeber = function(self)
	-- body
end
----------------------------------------------------------------------
--							C2S::S2CTeam Funcs
----------------------------------------------------------------------

--创建队伍 OK
def.method("number", "number", "string","number","boolean", "number").CreateTeam = function (self, iLevel, iCompetitive, strNotice, targetId, bBountyMode, teamMode)
	local C2STeamCreate = require "PB.net".C2STeamCreate
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
def.method("number").ApplyTeam = function (self, teamId)

	local C2STeamApply = require "PB.net".C2STeamApply
	local protocol = C2STeamApply()
	protocol.applyData.teamID = teamId

	SendProtocol(protocol)
end

--队长接受申请
def.method("number").ApproveJoinTeam = function (self, memberId)

	local C2STeamApplyAckAccept = require "PB.net".C2STeamApplyAckAccept
	local protocol = C2STeamApplyAckAccept()

	protocol.applyAckData.teamID = self._Team._ID
	protocol.applyAckData.roleID = memberId
	protocol.applyAckData.account = ""

	SendProtocol(protocol)
end

--队长拒绝申请
def.method("number").RefuseJoinTeam = function (self, memberId)

	local C2STeamApplyAckRefuse = require "PB.net".C2STeamApplyAckRefuse
	local protocol = C2STeamApplyAckRefuse()
	
	protocol.applyAckData.teamID = self._Team._ID
	protocol.applyAckData.roleID = memberId
	protocol.applyAckData.account = ""

	SendProtocol(protocol)
end

--邀请组队 C2STeamInvitate
def.method("number").InvitateMember = function(self, memberId)
----warn("InvitateMember : ", memberId)

	local C2STeamInvitate = require "PB.net".C2STeamInvitate
    local protocol = C2STeamInvitate()

    protocol.invitateData.invitateRoleID = memberId
    protocol.invitateData.teamID = self._Team._ID
    protocol.invitateData.invitateAccount = ""
    SendProtocol(protocol)
end

--接受邀请 C2STeamInvitateAckAccept
def.method("number").InvitateAccept = function(self, teamId)
	local C2STeamInvitateAckAccept = require "PB.net".C2STeamInvitateAckAccept
    local protocol = C2STeamInvitateAckAccept()

    protocol.invitateAckData.teamID = teamId
    protocol.invitateAckData.invitateRoleID = game._HostPlayer._ID
    SendProtocol(protocol)
end

--拒绝邀请 C2STeamInvitateAckRefuse
def.method("number").InvitateRefuse = function(self, teamId)
	local C2STeamInvitateAckRefuse = require "PB.net".C2STeamInvitateAckRefuse
    local protocol = C2STeamInvitateAckRefuse()

    protocol.invitateAckData.teamID = teamId
    protocol.invitateAckData.invitateRoleID = game._HostPlayer._ID
    SendProtocol(protocol)
end

--离开队伍 ok
def.method().QuitTeam = function(self)
	----warn("C2S::退出队伍")
	local C2STeamLeave = require "PB.net".C2STeamLeave

	local protocol = C2STeamLeave()
	protocol.leaveData.teamID = self._Team._ID

	SendProtocol(protocol)
end

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

def.method("number").KickMemberDirectly = function(self, memberId)
    local C2STeamT = require "PB.net".C2STeamT
	local protocol = C2STeamT()

	protocol.tData.teamID = self._Team._ID
	protocol.tData.roleID = memberId

	SendProtocol(protocol)
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

--自动入队标志  废弃
def.method("boolean", "number", "number", "string").SetJoinTeamInfo = function (self, bAutoApprove, iLevel, iCompetitive, strNotice)
	local C2STeamAutoJoin = require "PB.net".C2STeamAutoJoin
	local protocol = C2STeamAutoJoin()
	
	protocol.autoJoinTeam.teamID = self._Team._ID
	protocol.autoJoinTeam.bAuto = bAutoApprove
	protocol.autoJoinTeam.level = iLevel
	protocol.autoJoinTeam.Competitive = iCompetitive
	protocol.autoJoinTeam.tips = strNotice

	SendProtocol(protocol)
end

-- 切换队伍模式，切换为团队或者普通队伍
def.method("number").ChangeTeamMode = function(self, mode)
    local C2STeamChangeMode = require "PB.net".C2STeamChangeMode
    local protocol = C2STeamChangeMode()
    protocol.mode = mode
    SendProtocol(protocol)
end

--房间相关---------------------------------------------------------
--获取地图上的队伍列表
def.method("number").C2SGetTeamListInRoom = function(self,roomID)
    print("C2SGetTeamListInRoom ", roomID)
	local C2STeamGetTeamList = require "PB.net".C2STeamGetTeamList
	local protocol = C2STeamGetTeamList()
	protocol.teamlistData.mapID = game._CurWorld._WorldInfo.MapTid
	protocol.targetId = roomID
	protocol.from = 1
	protocol.count = 99

	SendProtocol(protocol)
end

--自动寻找队伍
def.method("number").C2STeamAutoMatchReq = function(self,TargetId)
	local C2STeamAutoMatchReq = require "PB.net".C2STeamAutoMatchReq
	local protocol = C2STeamAutoMatchReq()
	protocol.TargetId = TargetId

	SendProtocol(protocol)
end

--取消自动寻找队伍
def.method().C2STeamCancelMatchReq = function(self)
	local C2STeamCancelMatchReq = require "PB.net".C2STeamCancelMatchReq
	local protocol = C2STeamCancelMatchReq()

	SendProtocol(protocol)
end

----寻找队伍中
--def.method("number").OnS2CTeamAutoMatchTarget = function(self, targetId)
--	local CPanelUITeamCreate = require "GUI.CPanelUITeamCreate"

--	local function BeginSearch()
--		self:SetAutoMatching(true)
--	end
--	local function EndSearch()
--		self:SetAutoMatching(false)
--	end

--	if targetId == 0 then
--		EndSearch()
--	elseif targetId ~= self._TargetMatchId then
--		EndSearch()
--		BeginSearch()

--		local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", targetId)
--		local str = ""
--        if teamRoomConfig == nil then
--            str = StringTable.Get(22011)
--        else
--            str = teamRoomConfig.DisplayName
--        end

--		SendFlashMsg(string.format(StringTable.Get(22405), str), false)
--	end

--	self._TargetMatchId = targetId
--    local TeamInfoChangeType = EnumDef.TeamInfoChangeType
--    local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"
--    local event = TeamInfoChangeEvent()
--	event._Type = TeamInfoChangeType.TARGETCHANGE
--	CGame.EventManager:raiseEvent(nil, event)
--end

--开始确认
def.method("number").C2SStartParepare = function(self, targetID)
	local C2SStartParepare = require "PB.net".C2SStartParepare
	local protocol = C2SStartParepare()
    protocol.targetId = targetID
	SendProtocol(protocol)
end

def.method("number", "number").OnS2CTeamStartPrepare = function(self, duration, dungeonTid)
    local callback = function(val)
        if val then
            if dungeonTid > 0 then
                local reward_count = game._DungeonMan:GetRemainderCount(dungeonTid)
                if reward_count <= 0 then
                    local callback = function(val)
                        if val then
                            self:C2SConfirmParepare(true)
                        else
                            self:C2SConfirmParepare(false)
                        end
                    end
                    local dungeon_temp = CElementData.GetTemplate("Instance", dungeonTid)
                    if dungeon_temp == nil then
                        self:C2SConfirmParepare(false)
                    end
                    local title, msg, closeType = StringTable.GetMsg(88)
                    local message = string.format(msg, dungeon_temp.TextDisplayName)
			        MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Disconnect)
                else
    		        self:C2SConfirmParepare(true)
                end
            else
                self:C2SConfirmParepare(true)
            end
        else
            self:C2SConfirmParepare(false)
        end
    end
	local param = {Duration = duration, DungeonId = dungeonTid, CallBack = callback}
	game._GUIMan:Open("CPanelUITeamConfirm", param)

	local CQuestAutoMan = require "Quest.CQuestAutoMan"
	CQuestAutoMan.Instance():Stop()

	local CAutoFightMan = require "ObjHdl.CAutoFightMan"
	CAutoFightMan.Instance():Stop()
end

-- --拒绝进入反馈
def.method("table").OnS2CTeamPrepareFail = function(self,info)
	--print("拒绝进入反馈OnS2CTeamPrepareFail")
end

--选择是否进入
def.method("boolean").C2SConfirmParepare = function(self,boolean)
	warn("C2SConfirmParepare...........", boolean)

	local C2SConfirmParepare = require "PB.net".C2SConfirmParepare
	local protocol = C2SConfirmParepare()
	protocol.comfirm = boolean

	SendProtocol(protocol)
end

--确认进入反馈
def.method("number").OnS2CTeamMemberConfirmed = function(self,roleId)
	local CPanelUITeamConfirm = require "GUI.CPanelUITeamConfirm"
	if CPanelUITeamConfirm and CPanelUITeamConfirm.Instance():IsShow() then
		CPanelUITeamConfirm.Instance():UpdateTeamMemberConfirmed(roleId)
	end
end

def.method("boolean").OnS2CTeamPrepareResult = function(self,boolean)
	if boolean then
		game._GUIMan:Close("CPanelUITeamMember")
		game._GUIMan:Close("CPanelUITeamConfirm")
	else
		game._GUIMan:Close("CPanelUITeamConfirm")
	end
end

--请求设置
def.method().C2SMatchSettingReq = function(self)
	local C2SMatchSettingReq = require "PB.net".C2SMatchSettingReq
	local protocol = C2SMatchSettingReq()

	SendProtocol(protocol)
end
--修改设置
def.method("number", "number", "number", "boolean", "boolean", "boolean").C2SModifyMatchSetting = function(self,TargetId,Level,CombatPower,bAutoApprove,bGuildOnly,bFriendOnly)

	local C2SModifyMatchSetting = require "PB.net".C2SModifyMatchSetting
	local protocol = C2SModifyMatchSetting()
	protocol.Setting.TargetId = TargetId
	protocol.Setting.Level = Level
	protocol.Setting.CombatPower = CombatPower
	protocol.Setting.AutoApproval = bAutoApprove
	protocol.Setting.GuildOnly = bGuildOnly
	protocol.Setting.FriendOnly = bFriendOnly

	SendProtocol(protocol)
--[[
	--warn("================== C2SModifyMatchSetting =======================")
	--warn("TargetId = ", protocol.Setting.TargetId )
	--warn("Level = ", protocol.Setting.Level )
	--warn("CombatPower = ", protocol.Setting.CombatPower )
	--warn("IsBounty = ", protocol.Setting.IsBounty )
	--warn("AutoApproval = ", protocol.Setting.AutoApproval )
	
	for i,v in ipairs(protocol.Setting.Profession) do
		--warn("C2SModifyMatchSetting Profession = ", v)
	end
]]
end
--返回当前设置信息
def.method("table").OnS2CTeamMatchSetting  = function(self, protocol)
	do
		local ETeamMatchSettingType = require "PB.net".S2CTeamMatchSetting.Type
		local curType = protocol.OptType
		--1.请求 0.设置
		if curType == ETeamMatchSettingType.TYPE_Req then
			game._GUIMan:Open("CPanelUITeamSetting", protocol.Setting)
		elseif curType == ETeamMatchSettingType.TYPE_Set then
			game._GUIMan:Close("CPanelUITeamSetting")
			SendFlashMsg(StringTable.Get(22013), false)
		else
			----warn("更新的最后设置了，无需特殊处理暂时")
		end
	end
	
	if self._Team._Setting == nil or self._Team._Setting.TargetId ~= protocol.Setting.TargetId then
		--副本目标
		local str = ""
        local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", protocol.Setting.TargetId)
        if teamRoomConfig == nil then
            str = StringTable.Get(22011)
        else
            str = teamRoomConfig.DisplayName
        end
        if self._Team._Setting ~= nil then
			--弹出更改信息提示
			str = string.format(StringTable.Get(22402), str)
			SendFlashMsg(str, false)
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
    SendChangeEvent(EnumDef.TeamInfoChangeType.TeamSetting)
--[[
	--warn("================== OnS2CTeamMatchSetting =======================")
	--warn("TargetId = ", protocol.Setting.TargetId )
	--warn("Level = ", protocol.Setting.Level )
	--warn("CombatPower = ", protocol.Setting.CombatPower )
	--warn("IsBounty = ", protocol.Setting.IsBounty )
	--warn("AutoApproval = ", protocol.Setting.AutoApproval )
	
	for i,v in ipairs(protocol.Setting.Profession) do
		--warn("OnS2CTeamMatchSetting Profession = ", v)
	end
]]
end

def.method("=>", "string").GetTargetString = function(self)
	local str = ""
    local teamRoomConfig = CElementData.GetTemplate("TeamRoomConfig", self._Team._TargetId)
    if teamRoomConfig == nil then
        str = StringTable.Get(22011)
    else
        str = teamRoomConfig.DisplayName
    end

	return str
end

def.method("=>", "boolean").IsBountyMode = function(self)
	return self._Team._IsBountyMode
end

def.method("boolean").C2STeamAutoApproval = function(self, bAutoApprove)
	local C2STeamAutoApproval = require "PB.net".C2STeamAutoApproval
	local protocol = C2STeamAutoApproval()

	protocol.open = bAutoApprove
	SendProtocol(protocol)
end

--def.method().C2SChangeBountyMode = function(self)
--	if self:IsBountyMode() then
--		self:C2SCancelBountyMode()
--	else
--		self:C2SSetBountyMode()
--	end
--end

----设置赏金模式
--def.method().C2SSetBountyMode = function(self)
--	local C2SSetBountyMode = require "PB.net".C2SSetBountyMode
--	local protocol = C2SSetBountyMode()

--	SendProtocol(protocol)
--end
--取消赏金模式
--def.method().C2SCancelBountyMode = function(self)
--	local C2SCancelBountyMode = require "PB.net".C2SCancelBountyMode
--	local protocol = C2SCancelBountyMode()

--	SendProtocol(protocol)
--end

--设置自动匹配模式
def.method("number").S2CTeamAutoMatchTarget = function(self,TargetId)
	----warn("S2CTeamAutoMatchTarget=",TargetId)
	local S2CTeamAutoMatchTarget = require "PB.net".S2CTeamAutoMatchTarget
	local protocol = S2CTeamAutoMatchTarget()
	protocol.TargetId = TargetId
	SendProtocol(protocol)
end

-- --加载所有房间数据
-- def.method().LoadTeamRoomData = function(self)
-- 	self._TeamRoomDataTable = {}
-- 	local ERule = require "PB.Template".TeamRoomConfig.Rule

-- 	for k,v in pairs(CElementData.GetAllTeamRoomData()) do
-- 		local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", v)
--         --附近默认开启 & 副本是否开启

--         if (tmpConfig.PlayingLaw == ERule.DUNGEON and game._DungeonMan:DungeonIsOpen(tmpConfig.PlayingLawParam1)) or
--            (tmpConfig.PlayingLaw ~= ERule.DUNGEON and game._CFunctionMan:IsUnlockByFunTid(tmpConfig.FunTid)) then
-- 			--房间类型
-- 			local level1
-- 			for i2,v2 in ipairs(self._TeamRoomDataTable) do
-- 				if tmpConfig.ChannelOneSerial == v2.ChannelOneSerial then
-- 					level1 = v2
-- 					break
-- 				end
-- 			end

-- 			--如果 数组里面没有这个类型
-- 			if level1 == nil then
-- 				--先创建这个类型
-- 				level1 = {}
-- 				level1.ChannelOneSerial = tmpConfig.ChannelOneSerial
-- 				level1.ChannelOneName = tmpConfig.ChannelOneName

-- 				self._TeamRoomDataTable[#self._TeamRoomDataTable+1] = level1
-- 			end
-- 			--如果是1级频道
-- 			if tmpConfig.ChannelTwoName == nil or tmpConfig.ChannelTwoName == "" then
-- 				level1.Data = tmpConfig
-- 			else
-- 				if level1.ListData == nil then
-- 					level1.ListData = {}
-- 				end
-- 				level1.ListData[#level1.ListData+1] = tmpConfig
-- 			end
-- 		end
-- 	end
-- end
--加载所有房间数据
def.method("boolean").LoadTeamRoomData = function(self, bJustDungeOn)
	self._TeamRoomDataTable = {}
	local allTeamRoomData = CElementData.GetAllTeamRoomData()

	for k,v in pairs( allTeamRoomData ) do
		--房间类型
		local level1 = nil
		local tmpConfig = CElementData.GetTemplate("TeamRoomConfig", v)

		-- 设置是否解锁标志位
		local bIsNearBy = v == 1
		local bDungeonIsOpen = tmpConfig.PlayingLaw == ERule.DUNGEON and game._DungeonMan:DungeonIsOpen(tmpConfig.PlayingLawParam1)
		local bFuncIsOpen = tmpConfig.PlayingLaw ~= ERule.DUNGEON and game._CFunctionMan:IsUnlockByFunTid(tmpConfig.FunTid)
		local bIsOpen = bIsNearBy or bDungeonIsOpen or bFuncIsOpen
		bIsOpen = bIsOpen and ((bJustDungeOn and tmpConfig.PlayingLaw == ERule.DUNGEON) or (bJustDungeOn == false))

		if bIsOpen then
			for i2,v2 in ipairs(self._TeamRoomDataTable) do
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

				self._TeamRoomDataTable[#self._TeamRoomDataTable+1] = level1
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

		local function SortFunc(a,b)
			if a.Open == b.Open then
				return a.ChannelOneSerial < b.ChannelOneSerial
			else
				return a.Open
			end
		end
		table.sort(self._TeamRoomDataTable, SortFunc)
	end
end


--获取所有功能数据
def.method("=>","table").GetAllTeamRoomData = function(self)
	self:LoadTeamRoomData(false)
	
	return self._TeamRoomDataTable
end

def.method("=>", "table").GetAllTeamDungeOnRoomData = function(self)
	self:LoadTeamRoomData(true)
	
	return self._TeamRoomDataTable
end

--获取此房间的UI下标位置
def.method("number","=>","number","number").GetRoomIndexByID = function(self,targetId)
    local bindex = -1
    local sindex = -1
    for i,v in ipairs(self._TeamRoomDataTable) do
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
def.method("number","=>","number","number").GetRoomIndexByDungeonID = function(self, dungeonId)
    local bindex = 0
    local sindex = 0
    for i,v in ipairs(self._TeamRoomDataTable) do
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

-- 副本ID 转换到RoomId
def.method("number", "=>", "number").ExchangeToRoomId = function(self, dungeonId)
	local nRet = 0
	local teamData = self:GetAllTeamRoomData()
	local b,s = self:GetRoomIndexByDungeonID(dungeonId)

    if b > 0 then
        if s > 0 then
            nRet = (teamData[b].ListData[s]).Data.Id
        else
            nRet = (teamData[b].Data).Id
        end
	end

	return nRet
end

-- RoomId 转换到 副本ID
def.method("number", "=>", "number").ExchangeToDungeonId = function(self, roomId)
	local nRet = 0
	local template = CElementData.GetTemplate("TeamRoomConfig", roomId)

	if template ~= nil and template.PlayingLaw == ERule.DUNGEON then
		nRet = template.PlayingLawParam1
	end
	return nRet
end

def.method("number", "=>", "string").GetTeamRoomNameByDungeonId = function(self, dungeonId)
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

--获得队伍数据
def.method().GetCurTeamList = function(self)
	local C2STeamGetTeamInfo = require "PB.net".C2STeamGetTeamInfo
	local protocol = C2STeamGetTeamInfo()

	SendProtocol(protocol)
end

--队长获取申请列表 ok
def.method().GetApplicationList = function(self)
	local C2STeamGetApplyInfo = require "PB.net".C2STeamGetApplyInfo
	local protocol = C2STeamGetApplyInfo()
	protocol.applyData.teamID = self._Team._ID

	SendProtocol(protocol)

	self:SetTeamApplyRedDotState(false)
	self:RefreshTeamApplyRedDotState()
end

--解散队伍
def.method().DisbandTeam = function(self)
	local C2STeamDisband = require "PB.net".C2STeamDisband
	local protocol = C2STeamDisband()

	SendProtocol(protocol)
end

--队长一键拒绝
def.method().RefuseAllApplications = function(self)
	----warn("队长一键拒绝")
	local C2STeamOneKeyApplyAckRefuse = require "PB.net".C2STeamOneKeyApplyAckRefuse
	local protocol = C2STeamOneKeyApplyAckRefuse()

	SendProtocol(protocol)
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
		--hp:CancelSyncPosWhenMove(false)
	else
		if self:IsSameMapIdOfLeader() then
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
			        local C2STeamFollowConfirm = require "PB.net".C2STeamFollowConfirm
			        local protocol = C2STeamFollowConfirm()
			        protocol.isFollow = val
			        SendProtocol( protocol )
                end
            end
            if game._CurMapType == EWorldType.Pharse then
                local title, msg, closeType = StringTable.GetMsg(82)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback1)
            elseif game._CurMapType == EWorldType.Immediate then
                local title, msg, closeType = StringTable.GetMsg(97)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback1)
            else
                callback1(true)
            end
		end
	end
	local title, msg, closeType = StringTable.GetMsg(71)
	MsgBox.ShowMsgBox(msg, title, closeType, bit.bor(MsgBoxType.MBBT_YESNO, MsgBoxType.MBT_TIMEYES), callback, 10) 
end

--获取可以邀请的人员数据
def.method("number").SendGetInviteList = function(self, inviteType)
-- warn("SendGetInviteList....获取可以邀请的人员数据 : ", inviteType)
	local C2STeamGetCanInviteRoleList = require "PB.net".C2STeamGetCanInviteRoleList
	local protocol = C2STeamGetCanInviteRoleList()

	protocol.inviteType = inviteType
	SendProtocol(protocol)
end
--接收可以邀请的人员数据，刷新UI列表
def.method("table").OnS2CTeamCanInviteRoleList = function(self, list)
	local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
	CPanelUITeamInvite.Instance():UpdateInviteList(list)
end

def.method().SendC2SGetTeamEquipInfo = function(self)
	local C2SGetTeamEquipInfo = require "PB.net".C2SGetTeamEquipInfo
	local protocol = C2SGetTeamEquipInfo()
	SendProtocol(protocol)
end

-- 更新界面各个页签可邀请的数量
def.method("number", "number", "number").OnS2CTeamCount  = function(self, guildCount, friendCount, applyCount)
    local CPanelUITeamInvite = require "GUI.CPanelUITeamInvite"
    CPanelUITeamInvite.Instance():UpdateCount(guildCount, friendCount, applyCount)
end

-- 发送队伍邀请界面各个页签的数量显示请求
def.method().SendC2SGetCount = function(self)
    local C2STeamCount  = require "PB.net".C2STeamCount
    local protocol = C2STeamCount()
    SendProtocol(protocol)
end

-- 修改队伍名称
def.method("string").OnS2CTeamNameChange = function(self, newTeamName)
    self._Team._TeamName = newTeamName
end

-- 发送修改队伍名的协议
def.method("string").SendC2SChangeTeamName = function(self, teamName)
    local C2STeamChangeTeamName = require "PB.net".C2STeamChangeTeamName
    local protocol = C2STeamChangeTeamName()
    protocol.teamName = teamName
    SendProtocol(protocol)
end

def.method("table").SetExteriorParam = function(self, equipInfo)
	local memberInfo = self:GetMemberInfoById(equipInfo.Id)
	if memberInfo == nil then return end

	local ModelParams = require "Object.ModelParams"
	local param = ModelParams.new()
	param:MakeParam(equipInfo.Exterior, memberInfo._Profession)

	memberInfo._Param = param
end

def.method("table").OnS2CTeamEquipInfo = function(self, equipInfoList)
	for i,equipInfo in ipairs(equipInfoList) do
		self:SetExteriorParam(equipInfo)
	end

	game._GUIMan:Open("CPanelUITeamMember", nil)
end

def.method().ClosePanels = function(self)
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
--	self._TargetMatchId = 0
	self:ResetMemberList()
	self:ClosePanels()

	InActiveFollowButton(self)

	local function SendChangeEvent(type, data)
		local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"
		local event = TeamInfoChangeEvent()
		event._Type = type

		if data then
			event._ChangeInfo = data
		end

		CGame.EventManager:raiseEvent(nil, event)
	end
	SendChangeEvent(EnumDef.TeamInfoChangeType.ResetAllMember)
end

def.method().Release = function(self)
--	self._TargetMatchId = 0
	self:ResetInvitedCache()
	self:ResetMemberList()
end

CTeamMan.Commit()
return CTeamMan