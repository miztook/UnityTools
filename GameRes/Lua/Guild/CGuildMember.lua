local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local GuildMemberType = require "PB.data".GuildMemberType
local bit = require "bit"

local CGuildMember = Lplus.Class("CGuildMember")
local def = CGuildMember.define

-- 成员ID
def.field("number")._RoleID = 0
-- 成员名字
def.field("string")._RoleName = ""
-- 成员职位
def.field("string")._PositionName = ""
-- 成员类型
def.field("number")._RoleType = 0
-- 成员等级
def.field("number")._RoleLevel = 0
-- 离线时间
def.field("number")._LogoutTime = 0
-- 战力
def.field("number")._BattlePower = 0
-- 职业
def.field("number")._ProfessionID = 0
-- 活跃度
def.field("number")._Liveness = 0
-- 活跃度更改时间
def.field("number")._LivenessTime = 0
-- 头像数据
def.field("number")._CustomImgSet = 0
-- 二进制权限管理
def.field("number")._Permission = 0

-- 根据GuildPermission模板与RoleType综合判断当前所有权限
_G.PermissionMask =
{
	Dismiss = bit.lshift(1,0),
	Appoint = bit.lshift(1,1),
	KickMember = bit.lshift(1,2),
	AcceptApply = bit.lshift(1,3),
	AllocResource = bit.lshift(1,4),
	SetAnnounce = bit.lshift(1,5),
	LevelUp = bit.lshift(1,6),
	BuildingInfo = bit.lshift(1,7),
	UpgradeBuild = bit.lshift(1,8),
	BagInfo = bit.lshift(1,9),
	SetDisplayInfo = bit.lshift(1,10),
	FortressApply = bit.lshift(1,11),
	BuyAdminShopItem = bit.lshift(1,12),
}

-- 构造函数 通过获取的参数修改属性
def.static("table", "=>", CGuildMember).new = function(data)
	local obj = CGuildMember()
	obj._RoleID = data.roleID
	obj._RoleName = data.roleName
	obj._RoleLevel = data.roleLevel
	obj._LogoutTime = data.logoutTime
	obj._BattlePower = data.fightScore
	obj._ProfessionID = data.professionID
	obj._Liveness = data.liveness
	obj._LivenessTime = data.livenessTime
	obj._CustomImgSet = data.CustomImgSet

	local roleType = data.roleType
	obj._RoleType = roleType
	
	local name = nil
	if roleType == GuildMemberType.GuildLeader then
		name = "<color=#8F35BF>" .. StringTable.Get(824) .. "</color>"
	elseif roleType == GuildMemberType.GuildViceLeader then
		name = "<color=#A436D7>" .. StringTable.Get(825) .. "</color>"
	elseif roleType == GuildMemberType.GuildElite then
		name = "<color=#3990DA>" .. StringTable.Get(826) .. "</color>"
	elseif roleType == GuildMemberType.GuildNormalMember then
		name = "<color=#5CBE37>" .. StringTable.Get(827) .. "</color>"
	elseif roleType == GuildMemberType.GuildApplyMember then
		name = "<color=#909AA8>" .. StringTable.Get(828) .. "</color>"
	end

	obj._PositionName = name
	return obj
end

--公会权限--1:解散;2:任命;3:踢成员;4:接受申请;5:分配资源;6:设置公告;7:公会升级;8:查看建筑信息;9:建筑升级;
--10:查看背包信息;11:设置显示信息;12:要塞报名;13:购买管理员商店物品;
def.method().SetPermission = function(self) 						
	self._Permission = 0
	local roleType = self._RoleType 
	local allGuildPermission = CElementData.GetAllGuildPermission() 				-- 返回所有权限类型		
	for i, v in ipairs(allGuildPermission) do
		local permission = CElementData.GetTemplate("GuildPermission", v)  			-- 返回的是一个玩家tamplate模板
		if v == 1 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.Dismiss)
			end
		elseif v == 2 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.Appoint)
			end
		elseif v == 3 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.KickMember)
			end
		elseif v == 4 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
                self._Permission = bit.bor(self._Permission, PermissionMask.AcceptApply)
			end
		elseif v == 5 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.AllocResource)
			end
		elseif v == 6 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.SetAnnounce)
			end
		elseif v == 7 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.LevelUp)
			end
		elseif v == 8 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.BuildingInfo)
			end
		elseif v == 9 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.UpgradeBuild)
			end
		elseif v == 10 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.BagInfo)
			end
		elseif v == 11 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.SetDisplayInfo)
			end
		elseif v == 12 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.FortressApply)
			end
		elseif v == 13 then
			if (permission.Leader and roleType == GuildMemberType.GuildLeader) or (permission.ViceLeader and roleType == GuildMemberType.GuildViceLeader) or
				(permission.Elite and roleType == GuildMemberType.GuildElite) or  (permission.NormalMember and roleType == GuildMemberType.GuildNormalMember) then
				self._Permission = bit.bor(self._Permission, PermissionMask.BuyAdminShopItem)
			end
		end
	end
end

-- 根据成员类型获取文字描述
def.method("=>", "string").GetMemberTypeName = function(self)
	return self._PositionName
end

-- 重置公会成员信息
def.method().Clear = function(self)
	self._RoleID = 0
	self._RoleName = nil
	self._PositionName = nil
	self._RoleType = 0
	self._RoleLevel = 0
	self._LogoutTime = 0
	self._BattlePower = 0
	self._ProfessionID = 0
	self._Liveness = 0
	self._LivenessTime = 0
	self._CustomImgSet = 0
	self._Permission = 0
end

-- 根据权限获取右键点击菜单
def.static("table", "number", "number", "=>", "table").GetMenuList = function(member, myTeamId, targetTeamId)
	--local menuList = { "添加好友", "邀请组队", "查看信息", "发送私聊" }
    local MenuComponents = require "GUI.MenuComponents"
    local menuList = 
    {
    	--根据不同逻辑insert到这个table里
        MenuComponents.SeePlayerInfoComponent.new(member._RoleID),
        MenuComponents.ChatComponent.new(member._RoleID),
        MenuComponents.AddFriendComponent.new(member._RoleID),
        MenuComponents.InviteMemberComponent.new(member._RoleID, myTeamId, targetTeamId),
    }
    local hostMember = game._GuildMan:GetHostGuildMemberInfo()

	--公会权限--1:解散;2:任命;3:踢成员;4:接受申请;5:分配资源;6:设置公告;7:公会升级;8:查看建筑信息;9:建筑升级;
	--10:查看背包信息;11:设置显示信息;12:要塞报名;13:购买管理员商店物品;
	if 0 ~= bit.band(hostMember._Permission, PermissionMask.Appoint) then 													
		table.insert(menuList, MenuComponents.MemberManageComponent.new(member))
	end
	if 0 ~= bit.band(hostMember._Permission, PermissionMask.KickMember) then
		table.insert(menuList, MenuComponents.KickMemberComponent.new(member))
	end
	return menuList
end

CGuildMember.Commit()
return CGuildMember