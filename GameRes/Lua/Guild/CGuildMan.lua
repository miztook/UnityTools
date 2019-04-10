local Lplus = require "Lplus"
local CGuildMan = Lplus.Class("CGuildMan")
local def = CGuildMan.define

local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CGuildMember = require "Guild.CGuildMember"
local CGuildFortress = require "Guild.CGuildFortress"
local CGuildSmithyMan = require "Guild.CGuildSmithyMan"
local PBHelper = require "Network.PBHelper"
local CPanelUIGuild = require "GUI.CPanelUIGuild"
local CPanelUIGuildPray = require "GUI.CPanelUIGuildPray"
local CPanelUIGuildBattleMiniMap = require "GUI.CPanelUIGuildBattleMiniMap"
local GuildMemberType = require "PB.data".GuildMemberType
local GuildState = require "PB.data".GuildState
local GuildBuildingType = require "PB.data".GuildBuildingType
local EConvoyUpdateType = require "PB.net".EConvoyUpdateType
local EGuildNotifyType = require "PB.net".EGuildNotifyType
local EPkMode = require "PB.data".EPkMode
local ChatManager = require "Chat.ChatManager"
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local EGuildRedPointType = require "PB.net".EGuildRedPointType

def.field("table")._ConvoyEntity = nil
-- 用于小地图信息更新
def.field("table")._GuildBattleEntity = nil
-- 个人击杀信息缓存.用于断线重连
def.field("number")._KillNum = 0
def.field("number")._DeathNum = 0
def.field("number")._RedRank = 0
def.field("number")._BlueRank = 0
def.field("number")._RedDotUpdateTimerId = 0
def.field("boolean")._IsInitMoney = true

def.static("=>", CGuildMan).new = function()
	local obj = CGuildMan()
	return obj
end

def.method().Init = function(self)
	self:AddGuildRedTimer()
    self._IsInitMoney = true
end

-- 打开公会请求
def.method().RequestAllGuildInfo = function(self)
	if self:IsHostInGuild() then	
		self:SendC2SGuildBaseInfo(self:GetHostPlayerGuildID(), "")
		self:SendC2SGuildMembersInfo(self:GetHostPlayerGuildID())
		self:SendC2SGuildBuildingInfo()
		self:SendC2SGuildSkillInfo()
	else
		self:SendC2SGuildList()
	end
end

-- 处理红点数据
def.method("table").UpdateGuildRedPoint = function(self, data)
	game._HostPlayer._Guild._RedPoint = data.RedPoint.GuildRedPoints

    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, false)
	local hasRed = false
	local member = self:GetHostGuildMemberInfo()
	if member == nil then return end
	local points = data.RedPoint.GuildRedPoints
	for i, v in ipairs(points) do
		if v == EGuildRedPointType.EGuildRedPointType_PointsReward then
			hasRed = true
		elseif v == EGuildRedPointType.EGuildRedPointType_Pray then
			hasRed = true
		elseif v == EGuildRedPointType.EGuildRedPointType_HasApply then
			if member._RoleType == 1 then
				hasRed = true
			end
		elseif v == EGuildRedPointType.EGuildRedPointType_Salary then
			hasRed = true
		else
			warn("SetGuildRedPoint new type")
		end
	end
	if hasRed then
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, true)
	else
		if 0 ~= bit.band(member._Permission, PermissionMask.UpgradeBuild) then
			if game._HostPlayer._Guild._LevelUp then
				hasRed = true
			else
				local buildingList = game._HostPlayer._Guild._BuildingList
				for i, v in ipairs(buildingList) do
					if v._LevelUp and v._Unlock then
						hasRed = true
					end
				end
			end
		end
		if hasRed then
			CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, true)
		else
			if self:IsSmithyHasRedPoint() then
				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, true)
            else
                CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.GuildList, false)
			end
		end
	end
    if CPanelUIGuild.Instance():IsShow() then
        CPanelUIGuild.Instance():UpdateRedPoint()
    end
end

-- 退出公会请求
def.method().QuitGuild = function(self)
	local member = self:GetHostGuildMemberInfo()
	if member == nil then return end
	if member._RoleType == GuildMemberType.GuildLeader then
		if table.nums(game._HostPlayer._Guild._MemberList) > 1 then	
			game._GUIMan:ShowTipText(StringTable.Get(871), true)
		elseif game._HostPlayer._Guild._GuildState == GuildState.GuildStateCreated then
			self:SendC2SGuildDismiss()
		end
	else
		self:SendS2CGuildExit()
	end
end

-- 公会通知监听(本地发给自己)
def.method("boolean").ShowNotifySelf = function(self, join)
	local msg = nil
	if join then
		msg = string.format(StringTable.Get(8088), RichTextTools.GetGuildNameRichText(game._HostPlayer._Guild._GuildName, false))
	else
		msg = string.format(StringTable.Get(8089), RichTextTools.GetGuildNameRichText(game._HostPlayer._Guild._GuildName, false))	
	end
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelGuild, msg, false, 0, nil,nil)
end

-- 公会通知监听
def.method("table").ShowNotifyGuild = function(self, data)
	if data.GuildID ~= self:GetHostPlayerGuildID() then
		return
	end
	local msg = ""
	local operatorName = data.OperatorName
	if operatorName == nil then
		operatorName = ""
	elseif operatorName ~= "" then
		if operatorName == game._HostPlayer._InfoData._Name then
			operatorName = RichTextTools.GetHostPlayerNameRichText(false)
		else
			operatorName = RichTextTools.GetElsePlayerNameRichText(operatorName, false)
		end
	end
	local targetName = data.TargetName
	if targetName == nil then
		targetName = ""
	elseif targetName ~= "" then
		if targetName == game._HostPlayer._InfoData._Name then
			targetName = RichTextTools.GetHostPlayerNameRichText(false)
		else
			targetName = RichTextTools.GetElsePlayerNameRichText(targetName, false)		
		end
	end
	if data.NotifyType == EGuildNotifyType.EGuildNotifyType_MemberAdd then
		local name = targetName
		if name == nil or name == "" then
			name = operatorName
		end
		msg = string.format(StringTable.Get(880), name, RichTextTools.GetGuildNameRichText(game._HostPlayer._Guild._GuildName, false))
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_MemberExit then
		msg = string.format(StringTable.Get(881), operatorName)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_MemberKick then
		msg = string.format(StringTable.Get(882), targetName)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_ReName then
		msg = string.format(StringTable.Get(8025), RichTextTools.GetGuildNameRichText(data.GuildName, false))
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_SetIcon then
		msg = string.format(StringTable.Get(8024), operatorName)	
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_Create then
		msg = string.format(StringTable.Get(8022), operatorName)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_Dismiss then
		msg = string.format(StringTable.Get(8023), operatorName)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_Announce then
		msg = string.format(StringTable.Get(8026), operatorName, data.Announce)
		game._HostPlayer._Guild._Announce = data.Announce
		if not IsNil(CPanelUIGuild.Instance()._Panel) then
			CPanelUIGuild.Instance()._PageGuildInfo:OnInit()
		end
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_BuildLevelUp then
		msg = string.format(StringTable.Get(8031), self:GetBuildingNameByType(data.BuildType), data.BuildLevel)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_BuffOpen then
		local guildBuff = CElementData.GetTemplate("Talent", data.BuffId)
		msg = string.format(StringTable.Get(8032), guildBuff.Name)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_BuffLevelUp then
		local guildBuff = CElementData.GetTemplate("Talent", data.BuffId)
		msg = string.format(StringTable.Get(8090), guildBuff.Name, data.BuffLevel)
	elseif data.NotifyType == EGuildNotifyType.EGuildNotifyType_Appoint then
		local appoint = ""
		if data.MemberType == GuildMemberType.GuildLeader then
			appoint = StringTable.Get(824)
		elseif data.MemberType == GuildMemberType.GuildViceLeader then
			appoint = StringTable.Get(825)				
		elseif data.MemberType == GuildMemberType.GuildElite then
			appoint = StringTable.Get(826)				
		elseif data.MemberType == GuildMemberType.GuildNormalMember then
			appoint = StringTable.Get(827)		
		elseif data.MemberType == GuildMemberType.GuildApplyMember then
			appoint = StringTable.Get(828)
		end
		msg = string.format(StringTable.Get(879), targetName, appoint)
	end
	ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelGuild, msg, false, 0, nil,nil)
end

-- 公会设置显示信息表现
def.method().UpdatePageGuildSet = function(self)
	local guildPanel = CPanelUIGuild.Instance()
	if guildPanel:IsShow() then
		guildPanel:UpdatePageGuildSet()  
	end
	game._GUIMan:ShowTipText(StringTable.Get(864), true)
end

def.method("table").UpdateHpGuildMoney = function(self, data)
    local EResourceType = require "PB.data".EResourceType
    local role_resources = game._HostPlayer._InfoData._RoleResources
    local needSendEvent = false
    if data.GuildHonour ~= nil then
        if data.GuildHonour ~= role_resources[EResourceType.ResourceTypeGuildHonour] then
            local offset = data.GuildHonour - role_resources[EResourceType.ResourceTypeGuildHonour]
            if offset > 0 and not self._IsInitMoney then
                game._GUIMan:ShowMoveItemTextTips(EResourceType.ResourceTypeGuildHonour,true,offset, false)
            end
            needSendEvent = true
            role_resources[EResourceType.ResourceTypeGuildHonour] = data.GuildHonour
        end
    end
    
    if data.Contribute ~= nil then
        if data.Contribute ~= role_resources[EResourceType.ResourceTypeGuildContribute] then
            local offset = data.Contribute - role_resources[EResourceType.ResourceTypeGuildContribute]
            if offset > 0 and not self._IsInitMoney then
                game._GUIMan:ShowMoveItemTextTips(EResourceType.ResourceTypeGuildContribute,true,offset, false)
            end
            needSendEvent = true
            role_resources[EResourceType.ResourceTypeGuildContribute] = data.Contribute
        end
    end

    if data.fund ~= nil then
        if data.fund ~= role_resources[EResourceType.ResourceTypeGuildFund] then
            local offset = data.fund - role_resources[EResourceType.ResourceTypeGuildFund]
            if offset > 0 and not self._IsInitMoney then
                game._GUIMan:ShowMoveItemTextTips(EResourceType.ResourceTypeGuildFund,true,offset, false)
            end
            needSendEvent = true
            role_resources[EResourceType.ResourceTypeGuildFund] = data.fund
        end
    end

    if data.energy ~= nil then
        if data.energy ~= role_resources[EResourceType.ResourceTypeGuildEnergy] then
            local offset = data.energy - role_resources[EResourceType.ResourceTypeGuildEnergy]
            if offset > 0 and not self._IsInitMoney then
                game._GUIMan:ShowMoveItemTextTips(EResourceType.ResourceTypeGuildEnergy,true,offset, false)
            end
            needSendEvent = true
            role_resources[EResourceType.ResourceTypeGuildEnergy] = data.energy
        end
    end
    if needSendEvent then
        local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
        local event = NotifyMoneyChangeEvent()
        event.ObjID = game._HostPlayer._ID
        event.Type = "All"
        CGame.EventManager:raiseEvent(nil, event)
    end
    self._IsInitMoney = false
end

-- 初始化或刷新公会基础信息
def.method("table").UpdateGuildBaseInfo = function(self, data)
	local _Guild = game._HostPlayer._Guild
	if data.guildID ~= _Guild._GuildID then return end

	_Guild._GuildID = data.guildID
	_Guild._GuildName = data.guildName
	_Guild._GuildState = data.guildState
	_Guild._LeaderName = data.leaderName
	_Guild._LeaderLevel = data.leaderLevel
	_Guild._LeaderID = data.leaderID
	_Guild._MemberNum = data.MemberNum
	_Guild._GuildIconInfo._BaseColorID = data.guildIcon.BaseColorID
	_Guild._GuildIconInfo._FrameID = data.guildIcon.FrameID
	_Guild._GuildIconInfo._ImageID = data.guildIcon.ImageID
	if _Guild._GuildLevel ~= data.guildLevel then
		_Guild._IsMaxLevel = true
		for i,v in ipairs(CElementData.GetAllGuildLevel()) do
			local guild = CElementData.GetTemplate("GuildLevel", v)
			if guild.Level == data.guildLevel then
				_Guild._GuildModuleID = v
				_Guild._MaxMemberNum = guild.MemberNumber
			end
			--假设当前等级+1依旧会有小于等于，则不是最大等级
			if data.guildLevel + 1 <= guild.Level  then
				_Guild._IsMaxLevel = false
			end
		end
	end
	_Guild._GuildLevel = data.guildLevel
    if _Guild._GuildLevel == 0 then
        error("error !!! 公会等级服务器发送过来的数据为 0 ", debug.traceback())
    end
	local roleLevel = data.addLimit.roleLevel
	if roleLevel == 0 then
		roleLevel = GlobalDefinition.MinRoleLevel
	end
	_Guild._AddLimit._RoleLevel = roleLevel
	local battlePower = data.addLimit.battlePower
	_Guild._AddLimit._BattlePower = battlePower
	_Guild._CreateTime = data.createTime
	_Guild._Announce = data.announce
	_Guild._Fund = data.fund
	_Guild._Energy = data.energy
	_Guild._Exp = data.exp
    _Guild._DayFund = data.DayFund
    _Guild._DayEnergy = data.DayEnergy
    _Guild._DayExp = data.DayExp or 0
	_Guild._RewardPoints = data.rewardpoints
	_Guild._GuildLiveness = data.guildliveness
	_Guild._LivenessRank = data.livenessRank
	_Guild._NeedAgree = data.needAgree
	_Guild._IconList = {}
	for i = 1, #data.IconList do
		_Guild._IconList[#_Guild._IconList + 1] = data.IconList[i]
	end
	if data.guildName ~= nil and string.len(data.guildName) > 0 then
		game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)
	end
	_Guild._LevelUp = false
	if _Guild._IsMaxLevel then
		_Guild._LevelUp = false
	else
		local curGuildLevel = CElementData.GetTemplate("GuildLevel", _Guild._GuildModuleID)
		if _Guild._Exp >= curGuildLevel.NextExperience and _Guild._Fund >= curGuildLevel.Fund then
			_Guild._LevelUp = true
		end
	end
    self:UpdateHpGuildMoney(data)

	--self:SendC2SGuildSkillInfo()
end

-- 刷新公会全部基础UI信息
def.method().UpdatePageGuildInfo = function(self)
	local panel = CPanelUIGuild.Instance()
	if panel:IsShow() then
		panel:UpdatePageGuildInfo()
	end
end

-- 刷新公会基础资源UI信息
def.method().UpdatePageGuildBonus = function(self)
	local panel = CPanelUIGuild.Instance()
	if panel:IsShow() then
		panel:UpdatePageGuildBonus()
	end
end

-- 根据在线、职位、活跃度、战力、等级排序
local function MemberSort(a, b)
	if (a.logoutTime == 0 and b.logoutTime == 0) or
		(a.logoutTime > 0 and b.logoutTime > 0) then
		if a.roleType == b.roleType then
			if a.liveness == b.liveness then
				if a.fightScore == b.fightScore then
					return a.roleLevel > b.roleLevel
				end
				return a.fightScore > b.fightScore
			end
			return a.liveness > b.liveness 
		end
		return a.roleType < b.roleType
	end
	return a.logoutTime == 0
end

-- 初始化或刷新公会成员信息
def.method("table").UpdateGuildMembers = function(self, data)
	local hp = game._HostPlayer
	local guild = hp._Guild
    local mem_count = 0
	guild._MemberList = {}
	guild._MemberID = {}
	guild._OnlineMemberID = {}
	guild._ViceNum = 0
	guild._EliteNum = 0

	table.sort(data, MemberSort)

	for i,v in ipairs(data) do
		local member = CGuildMember.new(v)
		guild._MemberList[v.roleID] = member
		guild._MemberID[#guild._MemberID + 1] = v.roleID
		if v.logoutTime == 0 then
			guild._OnlineMemberID[#guild._OnlineMemberID + 1] = v.roleID
		end
		--假设是玩家自己,更新权限信息
		if v.roleID == hp._ID then
			member:SetPermission()
		end
		if v.roleType == GuildMemberType.GuildViceLeader then
			guild._ViceNum = guild._ViceNum + 1
		end
		if v.roleType == GuildMemberType.GuildElite then
			guild._EliteNum = guild._EliteNum + 1
		end
        mem_count = mem_count + 1
	end
    if #guild._MemberID > 1 then
        local sort_func = function(item1, item2)
            local mem1 = guild._MemberList[item1]
            local mem2 = guild._MemberList[item2]
            if mem1._LogoutTime ~= mem2._LogoutTime then
                return mem1._LogoutTime == 0
            else
                if mem1._RoleType ~= mem2._RoleType then
                    return mem1._RoleType < mem2._RoleType
                else
                    if mem1._RoleLevel ~= mem2._RoleLevel then
                        return mem1._RoleLevel > mem2._RoleLevel
                    else
                        return mem1._BattlePower > mem2._BattlePower
                    end
                end
            end
        end
        table.sort(guild._MemberID, sort_func)
        if #guild._OnlineMemberID > 1 then
            table.sort(guild._OnlineMemberID, sort_func)
        end
    end
    guild._MemberNum = mem_count
end

-- 初始化或刷新公会成员UI信息
def.method().UpdateGuildMembersUI = function(self)
	if CPanelUIGuild.Instance():IsShow() then
		CPanelUIGuild.Instance():UpdateGuildMembersInfo()
	end
end

-- 某种建筑是否解锁
def.method("number", "=>", "boolean").IsBuildingUnlock = function(self, buildType)
    local buildings = game._HostPlayer._Guild._BuildingList
    if buildings ~= nil and buildings[buildType] ~= nil then
        if buildings[buildType]._Unlock then
            return true
        else
            return false
        end
    end
    return false
end

-- 刷新公会建筑信息
def.method("table").UpdateGuildBuildings = function(self, data)
	local buildings = game._HostPlayer._Guild._BuildingList
	for i, v in ipairs(data) do
		buildings[v.buildingType] = self:UpdateGuildBuildingStruct(buildings[v.buildingType], v, self:GetBuildingNameByType(v.buildingType))
	end
end

-- 更新某一建筑升级后的信息
def.method("table").UpdateGuildBuilding = function(self, data)
	local buildings = game._HostPlayer._Guild._BuildingList
	local buildingName = self:GetBuildingNameByType(data.buildingType)
	buildings[data.buildingType] = self:UpdateGuildBuildingStruct(buildings[data.buildingType], data, buildingName)
	game._GUIMan:ShowTipText(string.format(StringTable.Get(8033), buildingName), true)

	if data.buildingType == GuildBuildingType.Smithy then
		-- 铁匠铺升级，重新初始化数据
		CGuildSmithyMan.Instance():InitMachiningTidMap()
	end
end

-- 初始化或刷新公会建筑UI信息
def.method().UpdatePageGuildBuilding = function(self)
	if CPanelUIGuild.Instance():IsShow() then
		CPanelUIGuild.Instance():UpdatePageGuildBuilding()
	end
end

-- 设置单个公会建筑信息
def.method("table", "table", "string", "=>", "table").UpdateGuildBuildingStruct = function(self, building, data, name)
	building._Lock = false
	building._BuildingLevel = data.level
	building._IsMaxLevel = true
	building._LevelUp = false
	building._PlayerLevel = self:GetGuildBuildingUnlockLevel(building._BuildingType)
	building._Unlock = game._HostPlayer._InfoData._Level >= building._PlayerLevel
	for i, v in ipairs(CElementData.GetAllGuildBuildLevel()) do
		local guildBuild = CElementData.GetTemplate("GuildBuildLevel", v)
		if guildBuild.BuildType == building._BuildingType then
			if building._BuildingLevel + 1 <= guildBuild.BuildLevel then
				building._IsMaxLevel = false
			end
			if guildBuild.BuildLevel == building._BuildingLevel then
				building._BuildingModuleID = v
			end
			if building._BuildingLevel + 1 == guildBuild.BuildLevel then
				if game._HostPlayer._Guild._GuildLevel >= guildBuild.GuildLevel then
					building._LevelUp = true
				end
			end
		end
	end
	if building._IsMaxLevel then
		building._LevelUp = false
	else
		local curGuildBuilding = CElementData.GetTemplate("GuildBuildLevel", building._BuildingModuleID)
		local guild = game._HostPlayer._Guild
		if guild._Fund < curGuildBuilding.CostFund then
			building._LevelUp = false
		end
	end

	return building
end

-- 根据建筑类型获取建筑描述
def.method("number", "=>", "string").GetBuildingNameByType = function(self, buildingType)
	local name = ""
	if buildingType == 0 then
		name = StringTable.Get(838)
	elseif buildingType == GuildBuildingType.Smithy then
		name = StringTable.Get(839)
	elseif buildingType == GuildBuildingType.PrayPool then
		name = StringTable.Get(840)
	elseif buildingType == GuildBuildingType.GuildDungeon then
		name = StringTable.Get(841)
	elseif buildingType == GuildBuildingType.GuildShop then
		name = StringTable.Get(842)
	elseif buildingType == GuildBuildingType.Laboratory then
		name = StringTable.Get(843)
	else
		warn("new buildingType----", buildingType)
	end
	return name
end

-- 设置公会旗帜
-- 底图，边框，图案
def.method("table", "table").SetGuildIcon = function(self, id, image)
	for i = 1, #id do
		local guildIcon = CElementData.GetTemplate("GuildIcon", id[i])
		if guildIcon == nil then
			warn("error GuildIcon tid:", id[i])
		else
			GUITools.SetGuildIcon(image[i], guildIcon.IconPath)
		end
	end
end

-- 设置玩家头顶公会旗帜
def.method("table", "table").SetPlayerGuildIcon = function(self, guildIcon, guildImage)
	local id = {}
	id[1] = guildIcon._BaseColorID
	id[2] = guildIcon._FrameID
	id[3] = guildIcon._ImageID
	for i = 1, #id do
		if id[i] ~= 0 then
			GUITools.SetGuildIcon(guildImage[i], CElementData.GetTemplate("GuildIcon", id[i]).IconPath)
		end
	end
end

-- 设置公会当前使用旗帜
def.method("table").SetGuildUseIcon = function(self, image)
	local iconId = {}
	local iconInfo = game._HostPlayer._Guild._GuildIconInfo
	iconId[1] = iconInfo._BaseColorID
	iconId[2] = iconInfo._FrameID
	iconId[3] = iconInfo._ImageID
	self:SetGuildIcon(iconId, image)
end

-- 获取主角的公会ID
def.method("=>", "number").GetHostPlayerGuildID = function(self)
	local guildID = 0
	local hp = game._HostPlayer
	if hp ~= nil then
		guildID = hp._Guild._GuildID
	end
	return guildID
end

-- 获取主角的公会角色信息
def.method("=>", "table").GetHostGuildMemberInfo = function(self)
	local hp = game._HostPlayer
	if hp == nil or hp._Guild == nil or not self:IsHostInGuild() then
		return nil
	end

	local info = hp._Guild._MemberList[hp._ID]
--	if info ==  nil then
--		warn("can not get host guild info", debug.traceback())
--	end
	return info
end

-- 获取公会成员信息
def.method("number", "=>", "table").GetGuildMemberInfo = function(self, roleID)
	return game._HostPlayer._Guild._MemberList[roleID]
end

-- 获取主角活跃度排名
def.method("=>", "number").GetHostPlayerLivenessRank = function(self)
	local memberList = game._HostPlayer._Guild._MemberList
	local host = memberList[game._HostPlayer._ID]
	local livenessRank = 1
	for i, v in pairs(memberList) do		
		if host._Liveness < v._Liveness then
			livenessRank = livenessRank + 1
		elseif host._Liveness == v._Liveness then
			if host._LivenessTime > v._LivenessTime then
				livenessRank = livenessRank + 1
			end
		end
	end
	return livenessRank
end

-- 主角是否是在公会中
def.method("=>", "boolean").IsHostInGuild = function(self)
	return self:GetHostPlayerGuildID() ~= 0
end

-- 是否是本公会成员
def.method("number", "=>", "boolean").IsGuildMember = function(self, guildID)
	if guildID == 0 or game._HostPlayer._Guild._GuildID == 0 then
		return false
	end
	if game._HostPlayer._Guild._GuildID == guildID then
		return true
	else
		return false
	end
end

-- 公会资金是否达到上限
def.method("=>", "boolean").IsFundMax = function(self)
	local guildLevel = CElementData.GetTemplate("GuildLevel", game._HostPlayer._Guild._GuildLevel)
	if game._HostPlayer._Guild._Fund >= guildLevel.MaxGuildFund then
		return true
	else
		return false
	end
end

-- 公会能源是否达到上限
def.method("=>", "boolean").IsEnergyMax = function(self)
	local guildLevel = CElementData.GetTemplate("GuildLevel", game._HostPlayer._Guild._GuildLevel)
	if game._HostPlayer._Guild._Energy >= guildLevel.MaxGuildEnergy then
		return true
	else
		return false
	end
end

-- 公会超链接点击
def.method("number").OnClickGuildLink = function(self, guildID)
	if not self:IsHostInGuild() then
		
	else
		game._GUIMan:ShowTipText(StringTable.Get(893), true)
	end
end

def.method("=>", "number").GetGuildSceneTid = function(self)
	return CSpecialIdMan.Get("GuildMapID")
end

-- 是否在公会基地
def.method("=>", "boolean").IsInGuildScene = function(self)
	if game._CurWorld._WorldInfo.SceneTid == self:GetGuildSceneTid() then
		return true
	else
		return false
	end
end

-- 公会建筑是否解锁
def.method("number", "=>", "boolean").IsGuildBuildingUnlock = function(self, buildingType)
	local building = { 114, 112, 92, 113, 111 }
	return game._CFunctionMan:IsUnlockByFunTid(building[buildingType])
end

-- 公会建筑解锁等级
def.method("number", "=>", "number").GetGuildBuildingUnlockLevel = function(self, buildingType)
	local building = { 114, 112, 92, 113, 111 }
	local fun = CElementData.GetTemplate("Fun", building[buildingType])
	for i, v in ipairs(fun.ConditionData.FunUnlockConditions) do
		if v.ConditionLevelUp._is_present_in_parent then
			return v.ConditionLevelUp.LevelUp
		end
	end
	return 0
end

----------------------------------------------------------------------
------------------------公会基地的常用操作----------------------------
----------------------------------------------------------------------

-- 进入公会基地
def.method().EnterGuildMap = function(self)
	if self:IsHostInGuild() then
		self:SendC2SGuildEnterMap()
		game._GUIMan:CloseSubPanelLayer()
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)		
	end
end

-- 离开公会基地
def.method().LeaveGuildMap = function(self)
	self:SendC2SGuildLeaveMap()
end

-- 公会捐献
def.method().OpenGuildDonate = function(self)
	if self:IsHostInGuild() then
		if game._HostPlayer._Guild:GetDonateNum() == 0 then
			game._GUIMan:ShowTipText(StringTable.Get(855), true)
		else
			game._GUIMan:Open("CPanelUIGuildDonate", nil)
		end
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)
	end
end

-- 锻造工坊
def.method().OpenGuildSmithy = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(114) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 114)
        return
    end
	if self:IsHostInGuild() then
		game._GUIMan:Open("CPanelUIGuildSmithy", nil)
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)
	end
end

-- 许愿池
def.method().OpenGuildPray = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(112) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 112)
        return
    end
	if self:IsHostInGuild() then
		self:SendC2SGuildPrayViewPool(game._HostPlayer._ID)
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)
	end
end

-- 获取贡品名称颜色
-- tid:许愿池道具Id
def.method("string", "number", "=>", "string").GetPrayItemColor = function(self, str, tid)
	local color = 
	{
	    [1] = EnumDef.Quality2ColorHexStr[2], --稀有蓝097EE9
	    [2] = EnumDef.Quality2ColorHexStr[3], --史诗紫7E33EF
	    [3] = EnumDef.Quality2ColorHexStr[5], --传说橙E6870C
	}
    return "<color=#" .. color[tid] .. ">" .. str .. "</color>"
end

-- 异界之门
def.method().OpenGuildDungeon = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(92) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 92)
        return
    end
	if self:IsHostInGuild() then
		if self:IsGuildBuildingUnlock(4) then
			self:SendC2SGuildExpeditionInfo()
		else
			game._GUIMan:ShowTipText(StringTable.Get(19470), true)
		end
	else
		game._GUIMan:ShowTipText(StringTable.Get(19471), true)
	end
end

-- 温德商会
def.method().OpenGuildShop = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(113) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 113)
        return
    end
	if self:IsHostInGuild() then
		-- 默认荣誉商店是不需要请求服务器数据的
		-- 默认资金商店ID:2
		self:SendC2SGuildShopViewItemList(2)
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)	
	end
end

-- 魔法核心
def.method().OpenGuildLaboratory = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(111) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 111)
        return
    end
	if self:IsHostInGuild() then
		game._GUIMan:Open("CPanelUIGuildSkill", nil)
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)
	end
end

-- 了解道具
def.method().OpenGuildKnowItem = function(self)
	local CPanelNpcService = require "GUI.CPanelNpcService"
	local dialogue = "当你看到这句话的时候，请告诉我Text.data的Tid"
	if not IsNil(CPanelNpcService.Instance()._Panel) then
		CPanelNpcService.Instance():SetNpcDialogue(dialogue)
	end
end

-- 要塞是否已报名
def.method("number", "=>", "boolean").IsGuildApplyFortress = function(self, tid)
	return game._HostPlayer._Guild._FortressApply[tid]._IsApply
end

-- 报名要塞
def.method("table").OpenGuildApplyFortress = function(self, data)
	local member = self:GetHostGuildMemberInfo()
	if member == nil then return end
	if member._FortressApply then
		if game._HostPlayer._Guild._FortressList[data.Id] == nil then
			game._HostPlayer._Guild._FortressList[data.Id] = CGuildFortress.new()
		end
		self:SendC2SGuildFortressApply(data.Id)
	else
		game._GUIMan:ShowTipText(StringTable.Get(897), true)
	end
end

-- 提交道具
def.method("number").OpenGuildSubmitItem = function(self, data)
	game._GUIMan:Open("CPanelGuildBuy", data)	
end

-- 参与要塞攻占
def.method("number", "=>", "boolean").OpenGuildFortressAttack = function(self, tid)
	local allTid = GameUtil.GetAllTid("Fortress")
	for i, v in ipairs(allTid) do
		local fortress = CElementData.GetTemplate("Fortress", v)
		if fortress.AttackActivityID == tid then
			self:SendC2SGuildFortressAttack(v)
			return true
		end
	end
	return false
end

-- 公会防守
def.method().OpenGuildDefend = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(93) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 93)
        return
    end
	if self:IsHostInGuild() then
		self:SendC2SGuildDefendInfo()
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)
	end
end

-- 公会铁匠铺是否有红点
def.method("=>", "boolean").IsSmithyHasRedPoint = function(self)
	local hp = game._HostPlayer
	local normalPack = hp._Package._NormalPack
	local costPercent = CGuildSmithyMan.Instance():GetCostPercent()
	local machiningTidMap = CGuildSmithyMan.Instance():GetMachiningTidMap()
	for _, machiningTid in pairs(machiningTidMap) do
		local machiningTemplate = CElementData.GetItemMachiningTemplate(machiningTid)
		if machiningTemplate ~= nil then
			-- 先检查货币
			local moneyNeed = machiningTemplate.MoneyNum * costPercent
			local moneyHave = hp:GetMoneyCountByType(machiningTemplate.MoneyId)
			if moneyNeed <= moneyHave then
				-- 再检查材料
				local isMaterialEnough = true
				for _, v in ipairs(machiningTemplate.SrcItemData.SrcItems) do
					local materialInPackage = normalPack:GetItemCount(v.ItemId)
					local materialNeed = v.ItemCount
					if materialNeed > materialInPackage then
						isMaterialEnough = false
						break
					end
				end
				if isMaterialEnough then
					return true
				end
			end
		end
	end
	return false
end

-- 获取货币数目
-- 10 26 魔数，差评 ！！！   added by lijian
def.method("number", "=>", "number").GetMoneyValueByTid = function(self, tid)
	local moneyValue = 0
	if tid == 10 then
		moneyValue = game._HostPlayer._Guild._Fund
	elseif tid == 26 then
		moneyValue = game._HostPlayer._Guild._Energy
	else
		moneyValue = game._HostPlayer._InfoData._RoleResources[tid]
		if moneyValue == nil then
			moneyValue = 0
		end
	end

	return moneyValue
end

-- 获取已经过去时间描述
def.method("number", "=>", "string").GetServerTimeDes = function(self, time)
	local clientTime = GameUtil.GetServerTime() / 1000
    local timeDes = clientTime - time
    if timeDes == clientTime then
    	timeDes = StringTable.Get(1004)
    elseif timeDes > 86400 then
    	timeDes = math.round(timeDes / 86400) .. StringTable.Get(1003) .. StringTable.Get(1006)
    elseif timeDes > 3600 then
    	timeDes = math.round(timeDes / 3600) .. StringTable.Get(1002) .. StringTable.Get(1006)
    elseif timeDes > 60 then
    	timeDes = math.round(timeDes / 60) .. StringTable.Get(1001) .. StringTable.Get(1006)
    else
    	timeDes = "1" .. StringTable.Get(1001) .. StringTable.Get(1006)
    end
	return timeDes
end

-- 获取秒小时分天
def.method("number", "=>", "string").GetTimeDes = function(self, time)
	local timeDes = ""
	local time_1 = math.floor(time / 3600)
	time = time - time_1 * 3600
	local time_2 = math.floor(time / 60)
	time = time - time_2 * 60
	if time_1 > 0 then
		timeDes = time_1 .. StringTable.Get(1002)
	end
	if time_2 > 0 then
		timeDes = timeDes .. time_2 .. StringTable.Get(1001)
	end
	if time > 0 then
		timeDes = timeDes .. time .. StringTable.Get(1000)
	end

	return timeDes
end

-- 获取纯数字描述
def.method("number", "=>", "string").GetTimeNum = function(self, time)
	local timeDes = ""
	local time_1 = math.floor(time / 3600)
	time = time - time_1 * 3600
	local time_2 = math.floor(time / 60)
	time = time - time_2 * 60
	if time_1 > 0 then
		if time_1 >= 10 then
			timeDes = time_1 .. ":"
		else
			timeDes = "0" .. time_1 .. ":"
		end
	else
		timeDes = "00:"
	end
	if time_2 > 0 then
		if time_2 >= 10 then
			timeDes = timeDes .. time_2 .. ":"
		else
			timeDes = timeDes .. "0" .. time_2 .. ":"
		end
	else
		timeDes = timeDes .. "00:"
	end
	if time >= 10 then
		timeDes = timeDes .. time
	else
		timeDes = timeDes .. "0" .. time
	end

	return timeDes
end

----------------------------------------------------------------------
------------------------公会基地的常用操作-----------------------------
----------------------------------------------------------------------

----------------------------------------------------------------------
------------------------公会常用的C2S消息-----------------------------
----------------------------------------------------------------------

-- 请求公会基础信息
-- 初次登陆会提前请求一次主角的公会基础信息
-- S2CBriefUserInfo会在选择角色时接收
def.method("number", "string").SendC2SGuildBaseInfo = function(self, guildID, guildName)
	local protocol = (require "PB.net".C2SGuildBaseInfo)()
	protocol.guildID = guildID
	protocol.guildName = guildName
	PBHelper.Send(protocol)
end

-- 请求全部公会基础信息(公会列表)
def.method().SendC2SGuildList = function(self)
	local protocol = (require "PB.net".C2SGuildList)()
	PBHelper.Send(protocol)
end

-- 请求退出公会(一般非会长)
def.method().SendS2CGuildExit = function(self)
    if game._HostPlayer:GetPkMode() == EPkMode.EPkMode_Guild then
    	game._GUIMan:ShowTipText(StringTable.Get(8015), true)
    	return
    end
	local callback = function(value)
		if value then
			local protocol = (require "PB.net".C2SGuildExit)()
			PBHelper.Send(protocol)
		end
	end
	local time = tonumber(CElementData.GetTemplate("SpecialId", 69).Value) * 24
	local title, msg, closeType = StringTable.GetMsg(46)
	local message = string.format(msg, time)
    MsgBox.ShowMsgBox(message, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
end

-- 踢出公会
def.method("table").SendC2SGuildKickMember = function(self, member)
	local callback = function(value)
		if value then
			local protocol = (require "PB.net".C2SGuildKickMember)()
			protocol.roleID = member._RoleID
			PBHelper.Send(protocol)
		end
	end
	local title, msg, closeType = StringTable.GetMsg(47)
	MsgBox.ShowMsgBox(string.format(msg, member._RoleName), title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

-- 请求加入公会
def.method("number").SendC2SGuildApplyAdd = function(self, guildID)
	local protocol = (require "PB.net".C2SGuildApplyAdd)()
	protocol.guildID = guildID
	PBHelper.Send(protocol)
end

-- 请求解散公会
def.method().SendC2SGuildDismiss = function(self)
    if game._HostPlayer:GetPkMode() == EPkMode.EPkMode_Guild then
    	game._GUIMan:ShowTipText(StringTable.Get(8016), true)
    	return
    end
	local callback = function(value)
		if value then
			local protocol = (require "PB.net".C2SGuildDismiss)()
			PBHelper.Send(protocol)
		end
	end
	local title, msg, closeType = StringTable.GetMsg(48)
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
end

-- 请求公会全部成员信息
def.method("number").SendC2SGuildMembersInfo = function(self, guildID)
	local protocol = (require "PB.net".C2SGuildMembersInfo)()
	protocol.guildID = guildID
	PBHelper.Send(protocol)
end

-- 请求公会建筑基础信息
def.method().SendC2SGuildBuildingInfo = function(self)
	local protocol = (require "PB.net".C2SGuildBuildingInfo)()
	PBHelper.Send(protocol)
end

-- 请求进入公会基地
def.method().SendC2SGuildEnterMap = function(self)
	local protocol = (require "PB.net".C2SGuildEnterMap)()
	PBHelper.Send(protocol)
end

-- 请求离开公会基地
def.method().SendC2SGuildLeaveMap = function(self)
	local protocol = (require "PB.net".C2SGuildLeaveMap)()
	PBHelper.Send(protocol)
end

-- 公会要塞报名
def.method("number").SendC2SGuildFortressApply = function(self, tid)
	local protocol = (require "PB.net".C2SGuildFortressApply)()
	protocol.FortressTID = tid
	PBHelper.Send(protocol)
end

-- 提交要塞报名道具
def.method("number", "number", "number").SendC2SGuildFortressItem = function(self, tid, itemTid, itemNum)
	local protocol = (require "PB.net".C2SGuildFortressItem)()
	protocol.FortressTID = tid
	protocol.ItemTID = itemTid
	protocol.ItemNum = itemNum
	PBHelper.Send(protocol)
end

-- 参与要塞攻打
def.method("number").SendC2SGuildFortressAttack = function(self, tid)
	local protocol = (require "PB.net".C2SGuildFortressAttack)()
	protocol.FortressTID = tid
	PBHelper.Send(protocol)
end

-- 查看操作记录
def.method("number").SendC2SGuildRecord = function(self, type)
	local protocol = (require "PB.net".C2SGuildRecord)()
	local RecordReqType = require "PB.net".RecordReqType
	if type == 0 then
		protocol.ReqType = RecordReqType.RecordReqType_Base
	else
		protocol.ReqType = RecordReqType.RecordReqType_Item
	end
	PBHelper.Send(protocol)
end

-- 查看公会技能信息
def.method().SendC2SGuildSkillInfo = function(self)
	local protocol = (require "PB.net".C2SGuildSkillInfo)()
	PBHelper.Send(protocol)
end

-- 请求打开温德商会
def.method("number").SendC2SGuildShopViewItemList = function(self, shopID)
	local protocol = (require "PB.net".C2SGuildShopViewItemList)()
	protocol.ShopID = shopID
	PBHelper.Send(protocol)
end

-- 查看许愿池
def.method("number").SendC2SGuildPrayViewPool = function(self, roleID)
	local protocol = (require "PB.net".C2SGuildPrayViewPool)()
	protocol.RoleId = roleID
	PBHelper.Send(protocol)
end

-- 查看异界之门
def.method().SendC2SGuildExpeditionInfo = function(self)	
	local protocol = (require "PB.net".C2SGuildExpeditionInfo)()
	PBHelper.Send(protocol)
end

-- 查看公会护送信息
def.method().SendC2SGuildConvoyInfo = function(self)
	local protocol = (require "PB.net".C2SGuildConvoyInfo)()
	PBHelper.Send(protocol) 
end

-- 请求公会红点信息
def.method().SendC2SGuildRedPoint = function(self)
	local protocol = (require "PB.net".C2SGuildRedPoint)()
	PBHelper.Send(protocol)
end

-- 请求公会防守信息
def.method().SendC2SGuildDefendInfo = function(self)
	local protocol = (require "PB.net".C2SGuildDefendInfo)()
	PBHelper.Send(protocol)
end

-- 请求公会战场积分数据
def.method().SendC2SGuildBattleWinCount = function(self)
    local protocol = (require "PB.net".C2SRankGetExtraData)()
    protocol.OptType = 0
    PBHelper.Send(protocol)
end

----------------------------------------------------------------------
------------------------公会常用的C2S消息-----------------------------
----------------------------------------------------------------------

----------------------------------------------------------------------
------------------------公会护送存储消息------------------------------
----------------------------------------------------------------------

-- 公会护送
def.method().OpenGuildConvoy = function(self)
    if not game._CFunctionMan:IsUnlockByFunTid(96) then
        game._CGuideMan:OnShowTipByFunUnlockConditions(0, 96)
        return
    end
	if self:IsHostInGuild() then
		self:SendC2SGuildConvoyInfo()
	else
		game._GUIMan:ShowTipText(StringTable.Get(19471), true)
	end
end

-- 公会护送结束
def.method("table").OnGuildConvoyComplete = function(self, data)
	game._GUIMan:Open("CPanelUIGuildConvoyEnd", data)
	-- 护送信息清空
	self:SetConvoyEntity(nil)
end

-- 设置护送单位信息
def.method("table").SetConvoyEntity = function(self, data)
	if data then
		if data.UpdateType == EConvoyUpdateType.EConvoyUpdateType_EntityInfo then
			self._ConvoyEntity = data.ConvoyEntity
		elseif data.UpdateType == EConvoyUpdateType.EConvoyUpdateType_ConvoyFlag then
			if data.EntityId == game._HostPlayer._ID then
				game._HostPlayer._InfoData._GuildConvoyFlag = data.GuildConvoyFlag
				game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildConvoy)
			else
				local player = game._CurWorld._PlayerMan._ObjMap[data.EntityId]
				if player ~= nil then
					player._InfoData._GuildConvoyFlag = data.GuildConvoyFlag
					player:UpdateTopPate(EnumDef.PateChangeType.GuildConvoy)
				end
			end
		end
	end
end

-- 获取护送单位信息
def.method("=>", "table").GetConvoyEntityPos = function(self)
	local position = nil
	if self._ConvoyEntity then
		local pos = self._ConvoyEntity.Position
		position = Vector3.New(pos.x, pos.y, pos.z)
	end

	return position
end

----------------------------------------------------------------------
------------------------公会护送存储消息------------------------------
----------------------------------------------------------------------

----------------------------------------------------------------------
------------------------公会战场存储消息------------------------------
----------------------------------------------------------------------


-- 打开公会战场(奇德天空竞技场)
def.method().OpenGuildBattle = function(self)
	if self:IsHostInGuild() then
		local protocol = (require "PB.net".C2SGuildBattleFieldOperate)()
		protocol.OpType = 0
		protocol.Position = 0		
		PBHelper.Send(protocol)
	else
		game._GUIMan:ShowTipText(StringTable.Get(8091), true)
	end
end

-- 获取公会战场场景Tid
def.method("=>", "number").GetGuildBattleSceneTid = function(self)
	local guildBattle = CElementData.GetTemplate("GuildBattle", 1)
	if guildBattle == nil then
		return 0
	end
	return guildBattle.MapId
end

-- 是否在公会战场场景内
def.method("=>", "boolean").IsGuildBattleScene = function(self)
	local guildBattle = CElementData.GetTemplate("GuildBattle", 1)
	if guildBattle == nil then
		return false
	end
	return guildBattle.MapId == game._CurWorld._WorldInfo.SceneTid
end

def.method("=>", "table").GetBattleEntityInfo = function(self)
	local entityInfos = self._GuildBattleEntity
	self._GuildBattleEntity = nil -- 数据被取了一遍之后清空
	return entityInfos
end

-- 更新公会战场所有玩家的信息（位置、变身），当前是每秒一次
def.method("table").UpdateBattleEntityInfo = function(self, data)
	local entityInfos = self._GuildBattleEntity
	if entityInfos == nil then
		entityInfos = {}
	end
	for _, info in ipairs(data) do
		entityInfos[info.EntityId] = info -- 数据被取之前做数据更新
	end
	self._GuildBattleEntity = entityInfos
end

-- （公会战场）更新左侧击杀与死亡数据
def.method("table").UpdateBattleDungeon = function(self, data)
	self._KillNum = data.KillNUM
	self._DeathNum = data.DeathNum
	local CPanelTracker = require "GUI.CPanelTracker"
	if not IsNil(CPanelTracker.Instance()._Panel) then
		CPanelTracker.Instance()._DungeonGoalPage:UpdateGuildBattle()
	end
end

-- 公会战场积分数据有变动
def.method("table").UpdateBattleRankInfo = function(self, data)
    self._RedRank = data.RedScore
    self._BlueRank = data.BlueScore
    if CPanelUIGuildBattleMiniMap.Instance():IsShow() then
        CPanelUIGuildBattleMiniMap.Instance():UpdateRankInfo()
    end
end

-- 公会战场祭品状态更新
def.method("table").UpdateBattleMineStatus = function(self, data)
    if CPanelUIGuildBattleMiniMap.Instance():IsShow() then
        CPanelUIGuildBattleMiniMap.Instance():UpdateMineStatus(data.Tid, data.Status, data.EndTime)
    end
end

def.method().ShowKillInfoUI = function(self)
    table.remove()
end

----------------------------------------------------------------------
------------------------公会战场存储消息------------------------------
----------------------------------------------------------------------

----------------------------------------------------------------------
-------------------------公会主界面红点-------------------------------
----------------------------------------------------------------------

def.method().AddGuildRedTimer = function(self)
	if self._RedDotUpdateTimerId == 0 then
		local callback = function()
			if self:GetHostGuildMemberInfo() == nil then
				return
			end
			self:SendC2SGuildRedPoint()
		end
		self._RedDotUpdateTimerId = _G.AddGlobalTimer(30, false, callback)
	end
end

def.method().RemoveGuildRedTimer = function(self)
	if self._RedDotUpdateTimerId ~= 0 then
		_G.RemoveGlobalTimer(self._RedDotUpdateTimerId)
		self._RedDotUpdateTimerId = 0
	end
end

----------------------------------------------------------------------
-------------------------公会主界面红点-------------------------------
----------------------------------------------------------------------

def.method().Release = function(self)
	self:RemoveGuildRedTimer()
    self._IsInitMoney = true
end

CGuildMan.Commit()
return CGuildMan