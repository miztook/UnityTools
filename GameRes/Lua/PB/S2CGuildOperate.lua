--
--公会相关的网络通信
--
--【孟令康】
--
--2016年8月31日
--

local PBHelper = require "Network.PBHelper"
local CPanelUIGuild = require "GUI.CPanelUIGuild"
local CPanelUIGuildList = require "GUI.CPanelUIGuildList"
local CPanelUIGuildApply = require "GUI.CPanelUIGuildApply"
local CGuildMsgParser = require "Guild.CGuildMsgParser"
local GUILD_OPERATE_RETURN_CODE = require "PB.net".GUILD_OPERATE_RETURN_CODE
local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local ChatManager = require "Chat.ChatManager"
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local CElementData = require "Data.CElementData"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

--根据返回的code进行不同的提示
local function OnGuildOperateReturnCode(code)
	if code == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		--warn(StringTable.Get(800))
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_MEMBER_FULL then
		game._GUIMan:ShowTipText(StringTable.Get(801), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NOT_FIND_GUILD then
		--warn(StringTable.Get(802))
	elseif code == GUILD_OPERATE_RETURN_CODE.ERR_PRAM then
		--warn(StringTable.Get(803))
	elseif code == GUILD_OPERATE_RETURN_CODE.ROLE_LEVEL_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(804), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_SAME_NAME then
		game._GUIMan:ShowTipText(StringTable.Get(805), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ROLE_HAD_GUILD then
		game._GUIMan:ShowTipText(StringTable.Get(806), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_EXP_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(807), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ROLE_OFF_LINE then
		game._GUIMan:ShowTipText(StringTable.Get(808), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ROLE_HAD_APPLY then
		game._GUIMan:ShowTipText(StringTable.Get(809), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NOT_FIND_ROLE then
		game._GUIMan:ShowTipText(StringTable.Get(810), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ADD_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(811), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.DIAMOND_NOT_ENOUGH_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:ShowTipText(StringTable.Get(813), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NOT_IN_GUILD then
		game._GUIMan:ShowTipText(StringTable.Get(814), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NOT_HAVE_PERMISSION then
		game._GUIMan:ShowTipText(StringTable.Get(815), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.TARGET_OFFLINE then
		game._GUIMan:ShowTipText(StringTable.Get(816), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ROLE_APPLY_FULL then
		game._GUIMan:ShowTipText(StringTable.Get(8008), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.RESOURCE_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(813), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.DONATE_NUM_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(855), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_LEVEL_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(854), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_LEAVE_CD then
		game._GUIMan:ShowTipText(StringTable.Get(8001), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NAME_TOO_LONG then
		--game._GUIMan:ShowTipText(StringTable.Get(817), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ANNOUNCE_TOO_LONG then
		--game._GUIMan:ShowTipText(StringTable.Get(817), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.TITLE_TOO_LONG then
		--game._GUIMan:ShowTipText(StringTable.Get(817), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.QUEST_NOT_FINISH then
		game._GUIMan:ShowTipText(StringTable.Get(8009), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.HAS_APPLIED_FORTRESS then
		game._GUIMan:ShowTipText(StringTable.Get(8007), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ACTIVITY_NOT_OPEN then
		game._GUIMan:ShowTipText(StringTable.Get(8010), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.FORTRESS_NOT_APPLY then
		game._GUIMan:ShowTipText(StringTable.Get(8014), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_POST_FULL then
		game._GUIMan:ShowTipText(StringTable.Get(8019), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_IN_EIXTLIST then
		game._GUIMan:ShowTipText(StringTable.Get(8020), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILD_IN_APPLYLIST then
		game._GUIMan:ShowTipText(StringTable.Get(867), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.TEMP_DATA_ERROR then
		game._GUIMan:ShowTipText(StringTable.Get(868), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.BUILD_LEVEL_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(892), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDSHOP_BAGLIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(256), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDSHOP_BUYTIMES then
		game._GUIMan:ShowTipText(StringTable.Get(264), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDSHOP_NOITEM then
		game._GUIMan:ShowTipText(StringTable.Get(257), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDSHOP_ITEMLOCK then
		game._GUIMan:ShowTipText(StringTable.Get(261), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDSHOP_ITEMNUM then
		game._GUIMan:ShowTipText(StringTable.Get(266), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDPRAY_NOTCOMPLETE then
		game._GUIMan:ShowTipText(StringTable.Get(8050), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDPRAY_NOPRAYITEM then
		game._GUIMan:ShowTipText(StringTable.Get(8051), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDPRAY_HASITEM then
		game._GUIMan:ShowTipText(StringTable.Get(8041), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDPRAY_DATACHANGE then

	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDSHOP_HELPTIMES then
		game._GUIMan:ShowTipText(StringTable.Get(8043), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDMAP_INFIGHT then
		game._GUIMan:ShowTipText(StringTable.Get(8045), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDPOINTS_QUALIFICATION then
		game._GUIMan:ShowTipText(StringTable.Get(8058), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDEXPEDITION_HASOPEN then
		game._GUIMan:ShowTipText(StringTable.Get(8070), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.GUILDEXPEDITION_ACTIVITYLIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(8071), true)
	else
		warn("-----Unkown GUILD_OPERATE_RETURN_CODE-----")
	end
end

-- 更新平台角色信息
local function UpdateRoleInfoToPlatform()
	CPlatformSDKMan.Instance():UploadRoleInfo(EnumDef.UploadRoleInfoType.RoleInfoChange)
end

----------------------------------------------------------------------
--------------------游戏登录初始接收的公会消息------------------------
----------------------------------------------------------------------

local function OnS2CRoleGuildInfo(sender, msg)
	local _Guild = game._HostPlayer._Guild
	_Guild._GuildID = msg.GuildID
	_Guild._ApplyList = msg.ApplyList
	_Guild._DonateNum = msg.DonateNum
	_Guild._HelpNum = msg.HelpTimes
	if msg.LeaveTime ~= nil then
		_Guild._LeaveTime = msg.LeaveTime
	end
	if msg.Contribute ~= nil then
		_Guild._Contribute = msg.Contribute
	end
	if msg.GuildHonour ~= nil then
		_Guild._GuildHonour = msg.GuildHonour
	end
	for i = 1, #msg.PointsList do
		_Guild._PointsList[#_Guild._PointsList + 1] = msg.PointsList[i]
	end
	for i = 1, #msg.ExpeditionRewardList do
		_Guild._ExpeditionRewardList[#_Guild._ExpeditionRewardList + 1] = msg.ExpeditionRewardList[i]
	end
	if msg.guildIcon ~= nil then
		_Guild._GuildIconInfo._BaseColorID = msg.guildIcon.BaseColorID
		_Guild._GuildIconInfo._FrameID = msg.guildIcon.FrameID
		_Guild._GuildIconInfo._ImageID = msg.guildIcon.ImageID
	end
	--初始请求公会基础信息以及公会成员信息
	local guildMan = game._GuildMan
	if msg.GuildID ~= 0 then
        guildMan:RequestAllGuildInfo()
        game._GuildMan:SendC2SGuildBattleWinCount()
        game._GuildMan:SendC2SGuildRedPoint()
	end
end
PBHelper.AddHandler("S2CRoleGuildInfo", OnS2CRoleGuildInfo)

----------------------------------------------------------------------
--------------------游戏登录初始接收的公会消息------------------------
----------------------------------------------------------------------

-- 创建公会
local function OnS2CGuildCreate(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildBaseInfo(msg.baseInfo)
		
		game._GUIMan:Close("CPanelUIGuildList")
		game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)
		guildMan:ShowNotifySelf(true)
        -- 刚创建的公会啥也没有呢，需要请求一下各种数据，不然在不打开公会界面条件下任何用到公会数据的界面都会报错（为空）
        guildMan:SendC2SGuildMembersInfo(guildMan:GetHostPlayerGuildID())
        guildMan:SendC2SGuildBuildingInfo()
		guildMan:SendC2SGuildSkillInfo()
        --打开公会界面
        game._GUIMan:Open("CPanelUIGuild", _G.GuildPage.Building)

        UpdateRoleInfoToPlatform()
	end
end
PBHelper.AddHandler("S2CGuildCreate", OnS2CGuildCreate)

-- 加入公会
local function OnS2CGuildApplyAdd(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		if msg.baseInfo.needAgree then
			game._GUIMan:ShowTipText(StringTable.Get(888), true)
			table.insert(game._HostPlayer._Guild._ApplyList, msg.baseInfo.guildID)
			local CPanelUIGuildList = require "GUI.CPanelUIGuildList"
			if CPanelUIGuildList.Instance():IsShow() then
				CPanelUIGuildList.Instance():OnGuildApplyAddSuccess()
			end
		else
			guildMan:UpdateGuildBaseInfo(msg.baseInfo)
			guildMan:RequestAllGuildInfo()
			guildMan:ShowNotifySelf(true)	
			game._GUIMan:Close("CPanelUIGuildList")
            --打开公会界面
            game._GUIMan:Open("CPanelUIGuild", _G.GuildPage.Building)

            UpdateRoleInfoToPlatform()
		end
	end
end
PBHelper.AddHandler("S2CGuildApplyAdd", OnS2CGuildApplyAdd)

-- 退出公会
local function OnS2CGuildExit(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:ShowNotifySelf(false)
		game._HostPlayer._Guild:ResetGuild()
		game._GUIMan:ShowTipText(StringTable.Get(830), true)
		game._GUIMan:Close("CPanelUIGuild")
		game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)

		UpdateRoleInfoToPlatform()
	end
end
PBHelper.AddHandler("S2CGuildExit", OnS2CGuildExit)

-- 接受加入申请(发给自己)
local function OnS2CGuildAcceptApplySelf(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if not IsNil(CPanelUIGuildApply.Instance()._Panel) then
		CPanelUIGuildApply.Instance():OnRefreshList(msg.applyList.applyMember)
	end
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildMembers(msg.members.allMember)
		guildMan:UpdateGuildMembersUI()
	end
end
PBHelper.AddHandler("S2CGuildAcceptApplySelf", OnS2CGuildAcceptApplySelf)

-- 接受加入申请(发给被操作者)
local function OnS2CGuildAcceptApplyOther(sender, msg)
	local guildMan = game._GuildMan
	guildMan:UpdateGuildBaseInfo(msg.baseInfo)
	guildMan:ShowNotifySelf(true)

	-- 加入公会批准表现(包括但不限于玩家自己的申请被接受)
	game._GUIMan:ShowTipText(string.format(StringTable.Get(876), RichTextTools.GetGuildNameRichText(game._HostPlayer._Guild._GuildName, false)), true)
	game._GUIMan:Close("CPanelUIGuildList")	
	game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)

	UpdateRoleInfoToPlatform()
end
PBHelper.AddHandler("S2CGuildAcceptApplyOther", OnS2CGuildAcceptApplyOther)

-- 拒绝申请(发给自己)
local function OnS2CGuildRefuseApplySelf(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if not IsNil(CPanelUIGuildApply.Instance()._Panel) then
		CPanelUIGuildApply.Instance():OnRefreshList(msg.applyList.applyMember)
	end
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		
	end
end
PBHelper.AddHandler("S2CGuildRefuseApplySelf", OnS2CGuildRefuseApplySelf)

-- 拒绝申请(发给被操作者)
local function OnS2CGuildRefuseApplyOther(sender, msg)
end
PBHelper.AddHandler("S2CGuildRefuseApplyOther", OnS2CGuildRefuseApplyOther)

--设置公会职位
local function OnS2CGuildAppoint(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildMembers(msg.members.allMember)
		guildMan:UpdateGuildMembersUI()
	end
end
PBHelper.AddHandler("S2CGuildAppoint", OnS2CGuildAppoint)

--踢出公会成员(发给自己)
local function OnS2CGuildKickMemberSelf(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildMembers(msg.members.allMember)
		guildMan:UpdateGuildMembersUI()
	end
end
PBHelper.AddHandler("S2CGuildKickMemberSelf", OnS2CGuildKickMemberSelf)

--踢出公会成员(发给被操作者)
local function OnS2CGuildKickMemberOther(sender, msg)
	local guildMan = game._GuildMan
	guildMan:ShowNotifySelf(false)
	game._HostPlayer._Guild:ResetGuild()
	game._GUIMan:ShowTipText(StringTable.Get(830), true)
	game._GUIMan:Close("CPanelUIGuild")
	game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)

	UpdateRoleInfoToPlatform()
end
PBHelper.AddHandler("S2CGuildKickMemberOther", OnS2CGuildKickMemberOther)

--查看公会列表
local function OnS2CGuildList(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local data = {}
		data._Index = 0
		data._Data = msg.guildList.guildList
        local CPanelUIGuildList = require "GUI.CPanelUIGuildList"
        if CPanelUIGuildList.Instance():IsShow() then
            CPanelUIGuildList.Instance():OnData(data)
        else
            game._GUIMan:Open("CPanelUIGuildList", data)
        end
	end
end
PBHelper.AddHandler("S2CGuildList", OnS2CGuildList)

--查看公会基础信息
local function OnS2CGuildBaseInfo(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	--在打开公会，搜索公会均会通过这条消息返回
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		if game._GuildMan:IsHostInGuild() then
			game._GuildMan:UpdateGuildBaseInfo(msg.baseInfo)
			game._GuildMan:UpdatePageGuildInfo()
		end
		if CPanelUIGuildList.Instance():IsShow() then
			CPanelUIGuildList.Instance():ShowSearchGuild(msg.baseInfo)
		end
	else
		if CPanelUIGuildList.Instance():IsShow() then
			CPanelUIGuildList.Instance():ShowSearchGuild(nil)
		end
	end
end
PBHelper.AddHandler("S2CGuildBaseInfo", OnS2CGuildBaseInfo)

--查看公会所有成员信息
local function OnS2CGuildMembersInfo(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildMembers(msg.members.allMember)
		guildMan:UpdateGuildMembersUI()
	end
end
PBHelper.AddHandler("S2CGuildMembersInfo", OnS2CGuildMembersInfo)

--查看公会申请列表
local function OnS2CGuildApplyList(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildApply", msg.applyList.applyMember)
	end
end
PBHelper.AddHandler("S2CGuildApplyList", OnS2CGuildApplyList)

--查看公会操作记录
local function OnS2CGuildRecord(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local RecordReqType = require "PB.net".RecordReqType
		if msg.recordReqType == RecordReqType.RecordReqType_Base then
			if CPanelUIGuild.Instance():IsShow() then
				CPanelUIGuild.Instance():UpdateGuildEvent(msg.record.Record)
			end
		elseif msg.recordReqType == RecordReqType.RecordReqType_Item then
			-- do nothing
		end
	end
end
PBHelper.AddHandler("S2CGuildRecord", OnS2CGuildRecord)

-- 设置公会公告
local function OnS2CGuildSetAnnounce(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._HostPlayer._Guild._Announce = msg.announce
		game._GUIMan:ShowTipText(StringTable.Get(831), true)
	end
end
PBHelper.AddHandler("S2CGuildSetAnnounce", OnS2CGuildSetAnnounce)

-- 解散公会
local function OnS2CGuildDismiss(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		
		guildMan:ShowNotifySelf(false)
		game._HostPlayer._Guild:ResetGuild()
		
		game._GUIMan:ShowTipText(StringTable.Get(833), true)
		game._GUIMan:Close("CPanelUIGuild")
		game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)

		UpdateRoleInfoToPlatform()
	end
end
PBHelper.AddHandler("S2CGuildDismiss", OnS2CGuildDismiss)

-- 公会捐献
local function OnS2CGuildDonate(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildBaseInfo(msg.baseInfo)
		guildMan:UpdateGuildMembers(msg.memberInfo.allMember)
		game._HostPlayer._Guild._DonateNum = msg.donateNum
		game._HostPlayer._Guild._Contribute = msg.contribute

		guildMan:UpdatePageGuildBonus()
		guildMan:UpdateGuildMembersUI()
		guildMan:UpdatePageGuildBuilding()
		game._GUIMan:ShowTipText(StringTable.Get(821), true)
		local CPanelUIGuildDonate = require "GUI.CPanelUIGuildDonate"
		if CPanelUIGuildDonate.Instance():IsShow() then
			CPanelUIGuildDonate.Instance():OnShowBtnDonate()
			CPanelUIGuildDonate.Instance():OnSuccessPlayUIEffect()
			
		end
	end
end
PBHelper.AddHandler("S2CGuildDonate", OnS2CGuildDonate)

--公会升级
local function OnS2CGuildLevelUp(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildBaseInfo(msg.baseInfo)
		guildMan:UpdateGuildBuildings(msg.buildings.buildings)
		guildMan:UpdatePageGuildInfo()
		guildMan:UpdatePageGuildBuilding()
        local GuildEvent = require "Events.GuildEvent"
        local event = GuildEvent()
        event._Type = "GuildLevelUp"
        CGame.EventManager:raiseEvent(nil, event)
		game._GUIMan:Close("CPanelUIGuildLvUp")
		game._GUIMan:ShowTipText(string.format(StringTable.Get(8033), StringTable.Get(838)), true)
	end
end
PBHelper.AddHandler("S2CGuildLevelUp", OnS2CGuildLevelUp)

--公会建筑升级
local function OnS2CGuildBuildingLevelUp(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildBaseInfo(msg.baseInfo)
		guildMan:UpdateGuildBuilding(msg.buildingInfo)
		guildMan:UpdatePageGuildBonus()
		guildMan:UpdatePageGuildBuilding()
		game._GUIMan:Close("CPanelUIGuildLvUp")		

        local GuildEvent = require "Events.GuildEvent"
        local event = GuildEvent()
        event._Type = "GuildBuildingLevelUp"
        event._Param = msg.buildingInfo.buildingType
        CGame.EventManager:raiseEvent(nil, event)
	end
end
PBHelper.AddHandler("S2CGuildBuildingLevelUp", OnS2CGuildBuildingLevelUp)

--查看公会建筑基础信息
local function OnS2CGuildBuildingInfo(sender, msg)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildBuildings(msg.buildings.buildings)
		guildMan:UpdatePageGuildBuilding()
	end
end
PBHelper.AddHandler("S2CGuildBuildingInfo", OnS2CGuildBuildingInfo)

--公会通知
local function OnS2CGuildNotify(sender, msg)
	game._GuildMan:ShowNotifyGuild(msg.GuildNotify)
end
PBHelper.AddHandler("S2CGuildNotify", OnS2CGuildNotify)

--要塞攻占报名
local function OnS2CGuildFortressApply(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:ShowTipText(StringTable.Get(898), true)
	end
end
PBHelper.AddHandler("S2CGuildFortressApply", OnS2CGuildFortressApply)

--提交要塞报名道具
local function OnS2CGuildFortressItem(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:ShowTipText(StringTable.Get(8006), true)		
	end
end
PBHelper.AddHandler("S2CGuildFortressItem", OnS2CGuildFortressItem)

--参与要塞攻占
local function OnS2CGuildFortressAttack(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
	end
end
PBHelper.AddHandler("S2CGuildFortressAttack", OnS2CGuildFortressAttack)

-- 公会信息同步
local function OnS2CGuildAoiGuildInfo(sender, msg)
	if msg.EntityID == game._HostPlayer._ID then
		local _Guild = game._HostPlayer._Guild
		_Guild._GuildID = msg.GuildID
		_Guild._GuildName = msg.GuildName
		if msg.Icon ~= nil then
			_Guild._GuildIconInfo._BaseColorID = msg.Icon.BaseColorID
			_Guild._GuildIconInfo._FrameID = msg.Icon.FrameID
			_Guild._GuildIconInfo._ImageID = msg.Icon.ImageID
		end
		game._HostPlayer:UpdateTopPate(EnumDef.PateChangeType.GuildName)
		return
	end
	local player = game._CurWorld._PlayerMan._ObjMap[msg.EntityID]
	if player ~= nil then
		local _Guild = player._Guild
		_Guild._GuildID = msg.GuildID
		if msg.GuildName ~= nil then
			_Guild._GuildName = msg.GuildName
		end
		if msg.Icon ~= nil then
			_Guild._GuildIconInfo._BaseColorID = msg.Icon.BaseColorID
			_Guild._GuildIconInfo._FrameID = msg.Icon.FrameID
			_Guild._GuildIconInfo._ImageID = msg.Icon.ImageID
		end
		player:UpdateTopPate(EnumDef.PateChangeType.GuildName)
	end
end
PBHelper.AddHandler("S2CGuildAoiGuildInfo", OnS2CGuildAoiGuildInfo)

-- 设置公会显示信息
local function OnS2CGuildSetDisplayInfo(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local guildMan = game._GuildMan
		guildMan:UpdateGuildBaseInfo(msg.baseInfo)
		guildMan:UpdatePageGuildInfo()
		guildMan:UpdatePageGuildBonus()
		guildMan:UpdatePageGuildSet()

		UpdateRoleInfoToPlatform()
	end
end
PBHelper.AddHandler("S2CGuildSetDisplayInfo", OnS2CGuildSetDisplayInfo)

-- 公会领取每日积分奖励
local function OnS2CGuildPointsReward(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
--		local data = { _PointsTID = msg.PointsTID }
		table.insert(game._HostPlayer._Guild._PointsList, msg.PointsTID)
		game._GuildMan:UpdatePageGuildBonus()
	end
end
PBHelper.AddHandler("S2CGuildPointsReward", OnS2CGuildPointsReward)

-- 公会领取每周工资
local function OnS2CGuildDrawSalary(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local panel = require "GUI.CPanelUIGuildSalary".Instance()
		if panel:IsShow() then
			local data = {}
			data._Rank = msg.Rank
			data._RewardId = msg.RewardId
			panel:ShowBtnDraw(data)					
		end
	end
end
PBHelper.AddHandler("S2CGuildDrawSalary", OnS2CGuildDrawSalary)

-- 查看公会技能信息
local function OnS2CGuildSkillInfo(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local data = CGuildMsgParser.ParseGuildSkillInfo(msg)
		game._HostPlayer._Guild._GuildSkill = data
	end
end
PBHelper.AddHandler("S2CGuildSkillInfo", OnS2CGuildSkillInfo)

-- 公会技能升级（个人）
local function OnS2CGuildSkillLevelUp(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
        local data = {}
        data.SkillId = msg.Skill.SkillId
        data.SkillLevel = msg.Skill.SkillLevel

        local isNewSkil = true
        local guildSkillData = game._HostPlayer._Guild._GuildSkill._SkillData
        for i, v in ipairs(guildSkillData) do
			if v.SkillId == data.SkillId then
				guildSkillData[i] = data
				isNewSkil = false
				break
			end
		end
		if isNewSkil then
		    guildSkillData[#guildSkillData + 1] = data
		end

		local event = NotifyGuildEvent()
		event.Type = "SkillLevelUp"
        event.Param = msg.Skill.SkillId
		CGame.EventManager:raiseEvent(data, event)
	end
end
PBHelper.AddHandler("S2CGuildSkillLevelUp", OnS2CGuildSkillLevelUp)

-- 公会BUFF开启
local function OnS2CGuildBuffOpen(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local buffData = game._HostPlayer._Guild._GuildSkill._BuffData
		for i, v in ipairs(buffData) do
			if v.BuffId == msg.BuffData.BuffId then
				buffData[i] = msg.BuffData
				break
			end
		end

		game._HostPlayer._Guild._Fund = msg.Fund

		if CPanelUIGuild.Instance():IsShow() then
			CPanelUIGuild.Instance():UpdatePageGuildBonus()
		end
        game._GuildMan:SendC2SGuildBaseInfo(game._GuildMan:GetHostPlayerGuildID(), "")
		local event = NotifyGuildEvent()
		event.Type = "BuffOpen"
		CGame.EventManager:raiseEvent(msg.BuffData, event)
	end
end
PBHelper.AddHandler("S2CGuildBuffOpen", OnS2CGuildBuffOpen)

-- 公会BUFF设置
local function OnS2CGuildBuffSet(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local buffData = game._HostPlayer._Guild._GuildSkill._BuffData
		for i, v in ipairs(buffData) do
			if v.BuffId == msg.SkillID then
				buffData[i].AutoFlag = msg.AutoFlag
				break
			end
		end
		local event = NotifyGuildEvent()
		event.Type = "BuffSet"
		CGame.EventManager:raiseEvent(msg, event)
	end
end
PBHelper.AddHandler("S2CGuildBuffSet", OnS2CGuildBuffSet)

-- 商店道具列表
local function OnS2CGuildShopViewItemList(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local data = {}
		data._Tid = msg.ShopId
		data._Items = msg.Items
		game._GUIMan:Open("CPanelUIGuildShop", data)
	end
end
PBHelper.AddHandler("S2CGuildShopViewItemList", OnS2CGuildShopViewItemList)

-- 商店购买道具
local function OnS2CGuildShopBuyItem(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._HostPlayer._Guild._Fund = msg.Fund
		
		local data = {}
		data._Tid = msg.ShopId
		data._ItemTid = msg.ItemID
		data._ItemNum = msg.ItemNum
		data._Fund = msg.Fund

		local event = NotifyGuildEvent()
		event.Type = "GuildShopBuy"
		CGame.EventManager:raiseEvent(data, event)
	end
end
PBHelper.AddHandler("S2CGuildShopBuyItem", OnS2CGuildShopBuyItem)

-- 查看许愿池
local function OnS2CGuildPrayViewPool(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local data = {}
		data._MemberInfo = msg.MemberInfo
		data._PrayItems = msg.PrayItems

		if msg.MemberInfo.roleID == game._HostPlayer._ID then
			game._GUIMan:Open("CPanelUIGuildPray", data)
		else
			local CPanelUIGuildPray = require "GUI.CPanelUIGuildPray"
			CPanelUIGuildPray.Instance():InitPrayDataOther(data)
		end

		game._GUIMan:Close("CPanelUIGuildPrayHelp")
	end
end
PBHelper.AddHandler("S2CGuildPrayViewPool", OnS2CGuildPrayViewPool)

-- 领取祈祷奖励
local function OnS2CGuildPrayDrawReward(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then

		local panel = require "GUI.CPanelUIGuildPray".Instance()
		if panel:IsShow() then
			panel:ShowBtnReward(msg.PoolIndex)					
			panel:UpdatePrayData(msg.PoolIndex)
		end
        game._GuildMan:SendC2SGuildRedPoint()
	end
end
PBHelper.AddHandler("S2CGuildPrayDrawReward", OnS2CGuildPrayDrawReward)

-- 查看祈祷记录
local function OnS2CGuildPrayViewRecord(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildPrayEvent", msg.Records)
	end
end
PBHelper.AddHandler("S2CGuildPrayViewRecord", OnS2CGuildPrayViewRecord)

-- 祈祷加速
local function OnS2CGuildPrayReduceTime(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local panel = require "GUI.CPanelUIGuildPray".Instance()
		panel:OnS2CGuildPrayReduceTime(msg.PrayItem)

        if msg.PrayItem ~= nil then
            if msg.PrayItem.CompleteTime <= GameUtil.GetServerTime()/1000 then
                game._GuildMan:SendC2SGuildRedPoint()
            end
        end
	end
end
PBHelper.AddHandler("S2CGuildPrayReduceTime", OnS2CGuildPrayReduceTime)

-- 帮助祈祷
local function OnS2CGuildPrayHelpPray(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
        local guild = game._HostPlayer._Guild
		guild._HelpNum = guild._HelpNum + 1
        local left_help_count = guild._MaxHelpNum - guild._HelpNum
		game._GUIMan:ShowTipText(string.format(StringTable.Get(8052), left_help_count), true)
    elseif msg.ResCode == GUILD_OPERATE_RETURN_CODE.GUILDPRAY_DATACHANGE then
    	game._GUIMan:ShowTipText(StringTable.Get(8053), true)
	end

	local panel = require "GUI.CPanelUIGuildPray".Instance()
	panel:OnS2CGuildPrayHelpPray(msg.PrayItem)

end
PBHelper.AddHandler("S2CGuildPrayHelpPray", OnS2CGuildPrayHelpPray)

-- 查看帮助列表
local function OnS2CGuildPrayHelperList(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildPrayHelp", msg.Helpers)
	end
end
PBHelper.AddHandler("S2CGuildPrayHelperList", OnS2CGuildPrayHelperList)

-- 放置祈祷道具
local function OnS2CGuildPrayPutOnItem(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local panel = require "GUI.CPanelUIGuildPray".Instance()
		panel:OnS2CGuildPrayPutOnItem(msg.PrayItem)

        game._GUIMan:ShowTipText(StringTable.Get(8107), true)
        local ChatManager = require "Chat.ChatManager"
        local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
		ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, StringTable.Get(8107), false, 0, nil,nil)
	end
end
PBHelper.AddHandler("S2CGuildPrayPutOnItem", OnS2CGuildPrayPutOnItem)

-- 远征开启
local function OnS2CGuildExpeditionOpen(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildDungeon", msg.ExpeditionInfo)
	end
end
PBHelper.AddHandler("S2CGuildExpeditionOpen", OnS2CGuildExpeditionOpen)

-- 远征进入
local function OnS2CGuildExpeditionEnter(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:CloseSubPanelLayer()
	end
end
PBHelper.AddHandler("S2CGuildExpeditionEnter", OnS2CGuildExpeditionEnter)

-- 远征查看
local function OnS2CGuildExpeditionInfo(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildDungeon", msg.ExpeditionInfo)
	end
end
PBHelper.AddHandler("S2CGuildExpeditionInfo", OnS2CGuildExpeditionInfo)

-- 远征伤害信息
local function OnS2CGuildExpeditionDamageInfo(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then		
		local CPanelUIGuildDungeon = require "GUI.CPanelUIGuildDungeon"
		CPanelUIGuildDungeon.Instance():ShowDamageDatas(msg.DamageInfo.DamageDatas)	
	end
end
PBHelper.AddHandler("S2CGuildExpeditionDamageInfo", OnS2CGuildExpeditionDamageInfo)

-- 领取远征奖励
local function OnS2CGuildExpeditionDungeonReward(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		table.insert(game._HostPlayer._Guild._ExpeditionRewardList, msg.DungeonTId)
		local panel = require "GUI.CPanelUIGuildDungeon".Instance()
		if panel:IsShow() then
			panel:OnShowBtnReward(msg.DungeonTId)
		end
	end
end
PBHelper.AddHandler("S2CGuildExpeditionDungeonReward", OnS2CGuildExpeditionDungeonReward)

-- 公会护送信息
local function OnS2CGuildConvoyInfo(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildConvoy", msg)
	end
end
PBHelper.AddHandler("S2CGuildConvoyInfo", OnS2CGuildConvoyInfo)

-- 公会护送报名
local function OnS2CGuildConvoyApply(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local panel = require "GUI.CPanelUIGuildConvoy".Instance()
		if panel:IsShow() then
			panel:ShowBtnSign()
		end
	end
end
PBHelper.AddHandler("S2CGuildConvoyApply", OnS2CGuildConvoyApply)

-- 公会护送参与
local function OnS2CGuildConvoyJoin(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:CloseSubPanelLayer()
	end
end
PBHelper.AddHandler("S2CGuildConvoyJoin", OnS2CGuildConvoyJoin)

-- 公会护送匹配结果
local function OnS2CGuildConvoyMatchRes(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildConvoyVs", msg)
	end
end
PBHelper.AddHandler("S2CGuildConvoyMatchRes", OnS2CGuildConvoyMatchRes)

-- 公会护送更新
local function OnS2CGuildConvoyUpdate(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GuildMan:SetConvoyEntity(msg)

		local event = NotifyGuildEvent()
		event.Type = "GuildConvoyUpdate"
		CGame.EventManager:raiseEvent(msg, event)
	end
end
PBHelper.AddHandler("S2CGuildConvoyUpdate", OnS2CGuildConvoyUpdate)

-- 公会护送完成
local function OnS2CGuildConvoyComplete(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GuildMan:OnGuildConvoyComplete(msg)

		local event = NotifyGuildEvent()
		event.Type = "GuildConvoyComplete"
		CGame.EventManager:raiseEvent(msg, event)
	end
end
PBHelper.AddHandler("S2CGuildConvoyComplete", OnS2CGuildConvoyComplete)

-- 公会护送伤害排名
local function OnS2CGuildConvoyRankInfo(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		local panel = require "GUI.CPanelUIGuildConvoyResult".Instance()
		if panel:IsShow() then
			panel:ShowDamage(msg.DamageInfo.DamageDatas)
		end	
	end
end
PBHelper.AddHandler("S2CGuildConvoyRankInfo", OnS2CGuildConvoyRankInfo)

-- 公会红点
local function OnS2CGuildRedPoint(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GuildMan:UpdateGuildRedPoint(msg)		
	end
end
PBHelper.AddHandler("S2CGuildRedPoint", OnS2CGuildRedPoint)

-- 公会防守信息
local function OnS2CGuildDefendInfo(sender, msg)
	OnGuildOperateReturnCode(msg.ResCode)
	if msg.ResCode == GUILD_OPERATE_RETURN_CODE.OK_GUILD_OPERATE_RETURN_CODE then
		game._GUIMan:Open("CPanelUIGuildDefend", msg)		
	end
end
PBHelper.AddHandler("S2CGuildDefendInfo", OnS2CGuildDefendInfo)

-- 公会防守更新
local function OnS2CGuildDefendUpdate(sender, msg)
	local event = NotifyGuildEvent()
	event.Type = "GuildDefendUpdate"
	CGame.EventManager:raiseEvent(msg, event)
end
PBHelper.AddHandler("S2CGuildDefendUpdate", OnS2CGuildDefendUpdate)

-- 公会防守开始一波
local function OnS2CGuildDefendRoundStart(sender, msg)
	local guildDefend = CElementData.GetTemplate("GuildDefend", msg.Round)
	local guildDes = string.format(StringTable.Get(8085), msg.Round) .. "  " .. guildDefend.DescText
	game._GUIMan:ShowAttentionTips(guildDes, 1, 3)	
end
PBHelper.AddHandler("S2CGuildDefendRoundStart", OnS2CGuildDefendRoundStart)

-- 公会防守完成一波
local function OnS2CGuildDefendFinishRound(sender, msg)
	-- do nothing		
end
PBHelper.AddHandler("S2CGuildDefendFinishRound", OnS2CGuildDefendFinishRound)

-- 公会防守完成
local function OnS2CGuildDefendComplete(sender, msg)
	local event = NotifyGuildEvent()
	event.Type = "GuildDefendComplete"
	CGame.EventManager:raiseEvent(msg, event)
end
PBHelper.AddHandler("S2CGuildDefendComplete", OnS2CGuildDefendComplete)

-- 公会战场报名
local function OnS2CGuildBattleFieldOperate(sender, msg)
	if msg.OpType == 0 then
		if game._GuildMan:IsHostInGuild() then
			game._GUIMan:Open("CPanelUIGuildBattle", msg)
		end
--		game._GUIMan:Open("CPanelUIGuildBattle", msg)
	elseif msg.OpType == 1 then
		local panel = require "GUI.CPanelUIGuildBattle".Instance()
		if panel:IsShow() then
			panel:ShowBtnSign(msg)
		end	
	elseif msg.OpType == 2 then
		game._GUIMan:CloseSubPanelLayer()
    elseif msg.OpType == 3 then
        local panel = require "GUI.CPanelUIGuildBattle".Instance()
		if panel:IsShow() then
			panel:ShowBtnSign(msg)
		end	
	end
end
PBHelper.AddHandler("S2CGuildBattleFieldOperate", OnS2CGuildBattleFieldOperate)

-- 公会战场小地图刷新
local function OnS2CGuildBattleFieldUpdate(sender, msg)
    if game._GuildMan:IsGuildBattleScene() then
	    game._GuildMan:UpdateBattleEntityInfo(msg.EntityInfo)		
    end
end
PBHelper.AddHandler("S2CGuildBattleFieldUpdate", OnS2CGuildBattleFieldUpdate)

-- 公会战场结算
local function OnS2CGuildBattleFieldReward(sender, msg)
	game._GUIMan:SetNormalUIMoveToHide(true, 0, "CPanelUIGuildBattleEnd", msg)
	--game._GUIMan:Open("CPanelUIGuildBattleEnd", msg)
	local CAutoFightMan = require "ObjHdl.CAutoFightMan"
	CAutoFightMan.Instance():Stop()
end
PBHelper.AddHandler("S2CGuildBattleFieldReward", OnS2CGuildBattleFieldReward)

-- 公会战场左侧面板刷新
local function OnS2CGuildBattleFieldDungeon(sender, msg)
    if game._GuildMan:IsGuildBattleScene() then
	    game._GuildMan:UpdateBattleDungeon(msg)		
    end
end
PBHelper.AddHandler("S2CGuildBattleFieldDungeon", OnS2CGuildBattleFieldDungeon)

-- 公会战场祭品倒计时显示
local function OnS2CMineRefreshNotify(sender, msg)
    if game._GuildMan:IsGuildBattleScene() then
	    local CPanelTracker = require "GUI.CPanelTracker"
	    if CPanelTracker then
		    CPanelTracker.Instance():UpdateGuildBattleRefreshTime(msg.EndTime, msg.RefreshType)
	    end
    end
end
PBHelper.AddHandler("S2CMineRefreshNotify", OnS2CMineRefreshNotify)

-- 公会战场谁击杀了谁
local function OnS2CGuildBFKillPlayerNotify(sender, msg)
    local CPanelMainTips = require "GUI.CPanelMainTips"
    local KillData = {
        RoleId = msg.Killer.RoleId,
        CustomImgSet = msg.Killer.CustomImgSet,
        Gender = msg.Killer.Gender,
        Profession = msg.Killer.Profession,
        Name = msg.Killer.Name
    }
    local DeathData = {
        RoleId = msg.Dead.RoleId,
        CustomImgSet = msg.Dead.CustomImgSet,
        Gender = msg.Dead.Gender,
        Profession = msg.Dead.Profession,
        Name = msg.Dead.Name
    }
    local PanelData = 
	{
		KillData = KillData,
		DeathData = DeathData,
		HitNum = msg.KillNums,
	}
	CPanelMainTips.Instance():ShowKillTips(PanelData)
end
PBHelper.AddHandler("S2CGuildBFKillPlayerNotify", OnS2CGuildBFKillPlayerNotify)

-- 公会战场积分刷新
local function OnS2CGuildBFScoreChange(sender, msg)
    if game._GuildMan:IsGuildBattleScene() then
        game._GuildMan:UpdateBattleRankInfo(msg)
    end
end
PBHelper.AddHandler("S2CGuildBFScoreChange", OnS2CGuildBFScoreChange)

-- 公会战场祭坛更新
local function OnS2CGuildBFMineStatus(sender, msg)
    if game._GuildMan:IsGuildBattleScene() then
        game._GuildMan:UpdateBattleMineStatus(msg)
    end
end
PBHelper.AddHandler("S2CGuildBFMineStatus", OnS2CGuildBFMineStatus)

-- 公会战场胜场和积分信息
local function OnS2CGuildBFExtraData(sender, msg)
    if game._HostPlayer ~= nil and game._HostPlayer._Guild ~= nil then
        game._HostPlayer._Guild._GuildBFWinCount = msg.GuildBFWinCount
        game._HostPlayer._Guild._GuildBFRank = msg.GuildBFScore
        local event = NotifyGuildEvent()
		event.Type = "GuildBFInfo"
		CGame.EventManager:raiseEvent(msg, event)
    end
end
PBHelper.AddHandler("S2CRankGetExtraData", OnS2CGuildBFExtraData)
