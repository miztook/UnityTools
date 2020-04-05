--
--公会相关的网络通信
--
--【孟令康】
--
--2016年8月31日
--

local PBHelper = require "Network.PBHelper"

--公会界面
local CPanelGuild = require "GUI.CPanelGuild"
--公会列表
local CPanelGuildList = require "GUI.CPanelGuildList"
--公会申请列表
local CPanelGuildApplyList = require "GUI.CPanelGuildApplyList"

local GUILD_OPERATE_RETURN_CODE = require "PB.net".GUILD_OPERATE_RETURN_CODE

--根据返回的code进行不同的提示
local function OnGuildOperateReturnCode(code)
	if code == GUILD_OPERATE_RETURN_CODE.OK then
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
	elseif code == GUILD_OPERATE_RETURN_CODE.FORMAL_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(812), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.DIAMOND_NOT_ENOUGH then
		game._GUIMan:ShowTipText(StringTable.Get(813), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NOT_IN_GUILD then
		game._GUIMan:ShowTipText(StringTable.Get(814), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.NOT_HAVE_PERMISSION then
		game._GUIMan:ShowTipText(StringTable.Get(815), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.TARGET_OFFLINE then
		game._GUIMan:ShowTipText(StringTable.Get(816), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.STATE_AIDING then
		game._GUIMan:ShowTipText(StringTable.Get(817), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.ROLE_APPLY_FULL then
		game._GUIMan:ShowTipText(StringTable.Get(8008), true)
	elseif code == GUILD_OPERATE_RETURN_CODE.RESOURCE_LIMIT then
		game._GUIMan:ShowTipText(StringTable.Get(844), true)
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
	else
		warn("-----Unkown GUILD_OPERATE_RETURN_CODE-----")
	end
end

----------------------------------------------------------------------
--------------------游戏登录初始接收的公会消息------------------------
----------------------------------------------------------------------

local function OnS2CRoleGuildInfo(sender, msg)
	local _Guild = game._HostPlayer._Guild
	_Guild._GuildID = msg.GuildID
	_Guild._ApplyList = msg.ApplyList
	_Guild._DonateNum = msg.DonateNum
	if msg.LeaveTime ~= nil then
		_Guild._LeaveTime = msg.LeaveTime
	end
	if msg.Contribute ~= nil then
		_Guild._Contribute = msg.Contribute
	end
	if msg.GuildHonour ~= nil then
		_Guild._GuildHonour = msg.GuildHonour
	end

	--初始请求公会基础信息以及公会成员信息
	local guildMan = game._HostPlayer._GuildMan
	guildMan:OnC2SGuildBaseInfo(guildMan:GetHostPlayerGuildID(), "")
	guildMan:OnC2SGuildMembersInfo(guildMan:GetHostPlayerGuildID())
	guildMan:OnC2SGuildBuildingInfo()
end
PBHelper.AddHandler("S2CRoleGuildInfo", OnS2CRoleGuildInfo)

----------------------------------------------------------------------
--------------------游戏登录初始接收的公会消息------------------------
----------------------------------------------------------------------

--创建公会
local function OnS2CGuildCreate(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo } , "Create")
	end
end
PBHelper.AddHandler("S2CGuildCreate", OnS2CGuildCreate)

--援建公会
local function OnS2CGuildAid(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo } , "Aid")		
	end
end
PBHelper.AddHandler("S2CGuildAid", OnS2CGuildAid)

--加入公会
local function OnS2CGuildApplyAdd(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent( { guildID = msg.guildID }, "ApplyAddSuccess")
	end
end
PBHelper.AddHandler("S2CGuildApplyAdd", OnS2CGuildApplyAdd)

--退出公会
local function OnS2CGuildExit(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(nil , "Quit")
	end
end
PBHelper.AddHandler("S2CGuildExit", OnS2CGuildExit)

--接受加入申请(发给自己)
local function OnS2CGuildAcceptApplySelf(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		CPanelGuildApplyList.Instance():OnRefreshData(msg.applyList.applyMember)
		game._HostPlayer._GuildMan:SendGuildEvent({ memberInfo = msg.members.allMember} , "AcceptApply")
	end
end
PBHelper.AddHandler("S2CGuildAcceptApplySelf", OnS2CGuildAcceptApplySelf)

--接收加入申请(发给被操作者)
local function OnS2CGuildAcceptApplyOther(sender, msg)
	game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo } , "ApplyAdd")
end
PBHelper.AddHandler("S2CGuildAcceptApplyOther", OnS2CGuildAcceptApplyOther)

--拒绝申请(发给自己)
local function OnS2CGuildRefuseApplySelf(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		CPanelGuildApplyList.Instance():OnRefreshData(msg.applyList.applyMember)
	end
end
PBHelper.AddHandler("S2CGuildRefuseApplySelf", OnS2CGuildRefuseApplySelf)

--拒绝申请(发给被操作者)
local function OnS2CGuildRefuseApplyOther(sender, msg)
	--UI表现待定
	game._GUIMan:ShowTipText("恭喜公会申请被拒绝", true)
end
PBHelper.AddHandler("S2CGuildRefuseApplyOther", OnS2CGuildRefuseApplyOther)

--设置公会职位
local function OnS2CGuildAppoint(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent( { memberInfo = msg.members.allMember }, "Appoint")
	end
end
PBHelper.AddHandler("S2CGuildAppoint", OnS2CGuildAppoint)

--踢出公会成员(发给自己)
local function OnS2CGuildKickMemberSelf(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent( { memberInfo = msg.members.allMember }, "KickMember")
	end
end
PBHelper.AddHandler("S2CGuildKickMemberSelf", OnS2CGuildKickMemberSelf)

--踢出公会成员(发给被操作者)
local function OnS2CGuildKickMemberOther(sender, msg)
	game._HostPlayer._GuildMan:SendGuildEvent(nil , "Quit")
end
PBHelper.AddHandler("S2CGuildKickMemberOther", OnS2CGuildKickMemberOther)

--查看公会列表
local function OnS2CGuildList(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.guildList.guildList, "GuildList")		
	end
end
PBHelper.AddHandler("S2CGuildList", OnS2CGuildList)

--查看公会基础信息
local function OnS2CGuildBaseInfo(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	--在打开公会，搜索公会均会通过这条消息返回
	--暂且如此处理，未找到好的处理方式
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		if game._HostPlayer._GuildMan:HostPlayerInGuild() then
			if IsNil(CPanelGuildList.Instance()._Panel) then
				game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo }, "BaseInfo")
			end
		end
		if not IsNil(CPanelGuildList.Instance()._Panel) then
			CPanelGuildList.Instance():OnSearchGuild(msg.baseInfo)
		end
	else
		if not IsNil(CPanelGuildList.Instance()._Panel) then
			CPanelGuildList.Instance():OnSearchGuild(nil)
		end
	end
end
PBHelper.AddHandler("S2CGuildBaseInfo", OnS2CGuildBaseInfo)

--查看公会所有成员信息
local function OnS2CGuildMembersInfo(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent( { memberInfo = msg.members.allMember }, "MemberInfo")
	end
end
PBHelper.AddHandler("S2CGuildMembersInfo", OnS2CGuildMembersInfo)

--查看公会申请列表
local function OnS2CGuildApplyList(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._GUIMan:Open("CPanelGuildApplyList", msg.applyList.applyMember)
	end
end
PBHelper.AddHandler("S2CGuildApplyList", OnS2CGuildApplyList)

--查看公会操作记录
local function OnS2CGuildRecord(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		local RecordReqType = require "PB.net".RecordReqType
		if msg.recordReqType == RecordReqType.RecordReqType_Base then
			game._GUIMan:Open("CPanelGuildEvent", msg.record.Record)
		elseif msg.recordReqType == RecordReqType.RecordReqType_Item then
			game._HostPlayer._GuildMan:SendGuildEvent(msg.record.Record, "RecordItem")
		end
	end
end
PBHelper.AddHandler("S2CGuildRecord", OnS2CGuildRecord)

--设置加入公会条件
local function OnS2CGuildSetAddLimit(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.addLimit, "AddLimit")
	end
end
PBHelper.AddHandler("S2CGuildSetAddLimit", OnS2CGuildSetAddLimit)

--设置转正条件
local function OnS2CGuildSetFormalLimit(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.formalLimit, "FormalLimit")
	end
end
PBHelper.AddHandler("S2CGuildSetFormalLimit", OnS2CGuildSetFormalLimit)

--设置公会标语
local function OnS2CGuildSetTitle(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.title, "GuildTitle")
	end
end
PBHelper.AddHandler("S2CGuildSetTitle", OnS2CGuildSetTitle)

--设置公会公告
local function OnS2CGuildSetAnnounce(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.announce, "Announce")
	end
end
PBHelper.AddHandler("S2CGuildSetAnnounce", OnS2CGuildSetAnnounce)

--设置公会名字
local function OnS2CGuildSetName(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.name, "Rename")
	end
end
PBHelper.AddHandler("S2CGuildSetName", OnS2CGuildSetName)

--解散公会
local function OnS2CGuildDismiss(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(nil , "Quit")
	end
end
PBHelper.AddHandler("S2CGuildDismiss", OnS2CGuildDismiss)

--公会预解散
local function OnS2CGuildPreDismiss(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		--warn("OnGuildDismiss")
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo}, "BaseInfo")
		CPanelGuild.Instance():OnGuildDismiss()
	end
end
PBHelper.AddHandler("S2CGuildPreDismiss", OnS2CGuildPreDismiss)

--公会取消解散
local function OnS2CGuildCancelDismiss(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		--warn("OnGuildCancelDismiss")
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo}, "BaseInfo")		
		CPanelGuild.Instance():OnGuildCancelDismiss()
	end
end
PBHelper.AddHandler("S2CGuildCancelDismiss", OnS2CGuildCancelDismiss)

--公会捐献
local function OnS2CGuildDonate(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo, donateNum = msg.donateNum }, "Donate")
	end
end
PBHelper.AddHandler("S2CGuildDonate", OnS2CGuildDonate)

--公会升级
local function OnS2CGuildLevelUp(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo }, "GuildLevelUp")		
	end
end
PBHelper.AddHandler("S2CGuildLevelUp", OnS2CGuildLevelUp)

--公会建筑升级
local function OnS2CGuildBuildingLevelUp(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ baseInfo = msg.baseInfo, buildingInfo = msg.buildingInfo }, "GuildBuildingLevelUp")		
	end
end
PBHelper.AddHandler("S2CGuildBuildingLevelUp", OnS2CGuildBuildingLevelUp)

--查看公会建筑基础信息
local function OnS2CGuildBuildingInfo(sender, msg)
	--OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ buildingInfo = msg.buildings.buildings }, "BuildingInfo")
	end
end
PBHelper.AddHandler("S2CGuildBuildingInfo", OnS2CGuildBuildingInfo)

--分配道具
local function OnS2CGuildAssignItem(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(msg.itemIndex, "AssignItem")	
	end
end
PBHelper.AddHandler("S2CGuildAssignItem", OnS2CGuildAssignItem)

--公会背包信息
local function OnS2CGuildBagInfo(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ bagInfo = msg.bagInfo }, "WareHouse")
	end
end
PBHelper.AddHandler("S2CGuildBagInfo", OnS2CGuildBagInfo)

--公会通知
local function OnS2CGuildNotify(sender, msg)
	game._HostPlayer._GuildMan:SendGuildEvent({ notifyInfo = msg.GuildNotify }, "Notify")
end
PBHelper.AddHandler("S2CGuildNotify", OnS2CGuildNotify)

--公会取消援建
local function OnS2CGuildCancelAid(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent(nil , "Quit")
	end
end
PBHelper.AddHandler("S2CGuildCancelAid", OnS2CGuildCancelAid)

--要塞攻占报名
local function OnS2CGuildFortressApply(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ fortressInfo = msg.FortressInfo }, "FortressApply")
	end
end
PBHelper.AddHandler("S2CGuildFortressApply", OnS2CGuildFortressApply)

--提交要塞报名道具
local function OnS2CGuildFortressItem(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
		game._HostPlayer._GuildMan:SendGuildEvent({ fortressInfo = msg.FortressInfo }, "FortressItem")		
	end
end
PBHelper.AddHandler("S2CGuildFortressItem", OnS2CGuildFortressItem)

--参与要塞攻占
local function OnS2CGuildFortressAttack(sender, msg)
	OnGuildOperateReturnCode(msg.resCode)
	if msg.resCode == GUILD_OPERATE_RETURN_CODE.OK then
	end
end
PBHelper.AddHandler("S2CGuildFortressAttack", OnS2CGuildFortressAttack)

--公会信息同步
local function OnS2CGuildAoiGuildInfo(sender, msg)
	if msg.EntityID == game._HostPlayer._ID then
		game._HostPlayer._Guild._GuildID = msg.GuildID
		game._HostPlayer._Guild._GuildName = msg.GuildName
		game._HostPlayer:SendPropChangeEvent("GuildName")
		return
	end
	local player = game._CurWorld._PlayerMan._ObjMap[msg.EntityID]
	if player ~= nil then
		player._Guild._GuildID = msg.GuildID
		if msg.GuildName ~= nil then
			player._Guild._GuildName = msg.GuildName
		end
		player:SendPropChangeEvent("GuildName")
	end
end
PBHelper.AddHandler("S2CGuildAoiGuildInfo", OnS2CGuildAoiGuildInfo)