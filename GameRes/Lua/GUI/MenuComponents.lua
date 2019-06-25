local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local net = require "PB.net"
local PBHelper = require "Network.PBHelper"
local CTeamMan = require "Team.CTeamMan"
local GuildMemberType = require "PB.data".GuildMemberType

----------------------------------------
--基类
----------------------------------------
local MenuComponent = Lplus.Class("MenuComponent")
do
	local def = MenuComponent.define
    def.field("function")._CallBack = nil
    --按钮的名字
	def.virtual("=>","string").GetBtnName = function (self)
        return ""
	end
    --处理点击事件
	def.virtual().HandleClick = function (self)
        if self._CallBack ~= nil then
            self._CallBack()
        end
	end
    --是否满足条件
    def.virtual("=>", "boolean").IsMeetCondition = function(self)
    end
    --设置额外的点击回调
    def.method("function").SetCallBack = function (self, callBack)
        self._CallBack = callBack
    end
	MenuComponent.Commit()
end

----------------------------------------
--私聊
----------------------------------------
local ChatComponent = Lplus.Extend(MenuComponent,"ChatComponent")
do
	local def = ChatComponent.define
    def.field("number")._TargetEntiyID = 0
	def.static("number","=>",ChatComponent).new = function (targetID)
		local obj = ChatComponent()
        obj._TargetEntiyID = targetID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(29001)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        return true
    end
	def.override().HandleClick = function (self)
		--TODO  新版的聊天接口现在还没有给出。
        if not game._CFriendMan:IsInBlackList(self._TargetEntiyID) then 
            game._CFriendMan:AddChat(self._TargetEntiyID)
        else
            game._GUIMan:ShowTipText(StringTable.Get(30325),false)
        end    
        MenuComponent.HandleClick(self)
	end

	ChatComponent.Commit()
end

----------------------------------------
--移出最近联系人
----------------------------------------
local RemoveRecentChatComponent = Lplus.Extend(MenuComponent,"RemoveRecentChatComponent")
do
	local def = RemoveRecentChatComponent.define
    def.field("number")._TargetEntiyID = 0
	def.static("number","=>",RemoveRecentChatComponent).new = function (targetEntityID)
		local obj = RemoveRecentChatComponent()
        obj._TargetEntiyID = targetEntityID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21419)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        --TODO
        if game._CFriendMan: IsHaveRemoveRecentButton(self._TargetEntiyID) then 
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        game._CFriendMan:RemoveRecentContact(self._TargetEntiyID)
        MenuComponent.HandleClick(self)
	end

	RemoveRecentChatComponent.Commit()
end

----------------------------------------
--添加好友
----------------------------------------
local AddFriendComponent = Lplus.Extend(MenuComponent,"AddFriendComponent")
do
	local def = AddFriendComponent.define
    def.field("number")._RoleID = 0
	def.static("number","=>",AddFriendComponent).new = function (roleID)
		local obj = AddFriendComponent()
        obj._RoleID = roleID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21402)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if not game._CFriendMan:IsFriend(self._RoleID) then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._RoleID ~= 0 then
            game._CFriendMan:DoApply(self._RoleID)
            MenuComponent.HandleClick(self)
        end
	end
	AddFriendComponent.Commit()
end

----------------------------------------
--删除好友
----------------------------------------
local DeleteFriendComponent = Lplus.Extend(MenuComponent,"DeleteFriendComponent")
do
	local def = DeleteFriendComponent.define
    def.field("number")._RoleID = 0
	def.static("number","=>",DeleteFriendComponent).new = function (roleID)
		local obj = DeleteFriendComponent()
        obj._RoleID = roleID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21411)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if game._CFriendMan:IsFriend(self._RoleID) and not game._CFriendMan:IsInBlackList(self._RoleID) then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._RoleID ~= 0 then
            game._CFriendMan:DoDeleteFriend(self._RoleID)
            MenuComponent.HandleClick(self)
        end
	end
	DeleteFriendComponent.Commit()
end

----------------------------------------
--加入黑名单
----------------------------------------
local AddBlackListComponent = Lplus.Extend(MenuComponent,"AddBlackListComponent")
do
	local def = AddBlackListComponent.define
    def.field("number")._RoleID = 0
	def.static("number","=>",AddBlackListComponent).new = function (roleID)
		local obj = AddBlackListComponent()
        obj._RoleID = roleID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21412)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if not game._CFriendMan:IsInBlackList(self._RoleID) then
            if game._HostPlayer:IsInGlobalZone() then
                return false
            else
                return true
            end
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._RoleID ~= 0 then
            game._CFriendMan:DoAddBlackList(self._RoleID)
            MenuComponent.HandleClick(self)
        end
	end
	AddBlackListComponent.Commit()
end

----------------------------------------
--移除黑名单
----------------------------------------
local RemoveBlackListComponent = Lplus.Extend(MenuComponent,"RemoveBlackListComponent")
do
	local def = RemoveBlackListComponent.define
    def.field("number")._RoleID = 0
	def.static("number","=>",RemoveBlackListComponent).new = function (roleID)
		local obj = RemoveBlackListComponent()
        obj._RoleID = roleID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21415)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if game._CFriendMan:IsInBlackList(self._RoleID) then 
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._RoleID ~= 0 then
            --CFriendMan.Instance():AddBlackList(self._RoleID)
            game._CFriendMan:DoOutBlackList(self._RoleID)
            MenuComponent.HandleClick(self)
        end
	end
	RemoveBlackListComponent.Commit()
end

----------------------------------------
--成员管理
----------------------------------------
local MemberManageComponent = Lplus.Extend(MenuComponent,"MemberManageComponent")
do
	local def = MemberManageComponent.define
    def.field("table")._Member = BlankTable
    --#1.调用的panel #2.成员对象
	def.static("table","=>",MemberManageComponent).new = function (member)
		local obj = MemberManageComponent()
        obj._Member = member
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21407)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if game._GuildMan:IsHostInGuild() and game._GuildMan:GetHostGuildMemberInfo()._RoleType == GuildMemberType.GuildLeader then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if game._HostPlayer:IsInGlobalZone() then
            game._GUIMan:ShowTipText(StringTable.Get(15556), false)
            return
        end
        if self._Member ~= nil then
            game._GUIMan:Open("CPanelUIGuildSet", self._Member)
            MenuComponent.HandleClick(self)
        end
	end
	MemberManageComponent.Commit()
end

----------------------------------------
--踢出公会
----------------------------------------
local KickMemberComponent = Lplus.Extend(MenuComponent,"KickMemberComponent")
do
	local def = KickMemberComponent.define
    def.field("table")._Member = nil
	def.static("table","=>",KickMemberComponent).new = function (member)
		local obj = KickMemberComponent()
        obj._Member = member
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21408)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        return true
    end
	def.override().HandleClick = function (self)
        if self._Member ~= nil then
            game._GuildMan:SendC2SGuildKickMember(self._Member)
            MenuComponent.HandleClick(self)
        end
	end
	KickMemberComponent.Commit()
end

----------------------------------------
--任命成员
----------------------------------------
local AppointMemberComponent = Lplus.Extend(MenuComponent,"AppointMemberComponent")
do
	local def = AppointMemberComponent.define
    def.field("table")._Member = nil
	def.static("table","=>",AppointMemberComponent).new = function (member)
		local obj = AppointMemberComponent()
        obj._Member = member
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21416)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if game._GuildMan:IsHostInGuild() and game._GuildMan:GetHostGuildMemberInfo()._RoleType == GuildMemberType.GuildLeader 
            and game._GuildMan:IsGuildMember(self._Member._RoleID) then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._Member ~= nil then
            game._GUIMan:Open("CPanelUIGuildSet", self._Member)
            MenuComponent.HandleClick(self)
        end
	end
	AppointMemberComponent.Commit()
end

----------------------------------------
--转让会长(仅会长显示)
----------------------------------------
local AssigGuildLeaderComponent = Lplus.Extend(MenuComponent,"AssigGuildLeaderComponent")
do
	local def = AssigGuildLeaderComponent.define
    def.field("number")._MemberID = 0
	def.static("number","=>",AssigGuildLeaderComponent).new = function (memberID)
		local obj = AssigGuildLeaderComponent()
        obj._MemberID = memberID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21416)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if game._GuildMan:IsHostInGuild() and game._GuildMan:GetHostGuildMemberInfo()._RoleType == GuildMemberType.GuildLeader 
            and game._GuildMan:IsGuildMember(self._MemberID) then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._MemberID ~= 0 then
            --game._GuildMan:SendC2SGuildKickMember(self._MemberID)
            game._GUIMan:ShowTipText("转让会长的功能还没有",true)
            MenuComponent.HandleClick(self)
        end
	end
	AssigGuildLeaderComponent.Commit()
end

----------------------------------------
--查看信息
----------------------------------------
local SeePlayerInfoComponent = Lplus.Extend(MenuComponent,"SeePlayerInfoComponent")
do
	local def = SeePlayerInfoComponent.define
    def.field("number")._RoleID = 0
	def.static("number","=>",SeePlayerInfoComponent).new = function (roleID)
		local obj = SeePlayerInfoComponent()
        obj._RoleID = roleID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21404)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        if game._HostPlayer:IsInGlobalZone() then
            return false
        end
        return true
    end
	def.override().HandleClick = function (self)
        if self._RoleID ~= 0 then
            --game._GUIMan:ShowTipText("查看信息的功能暂时未开通",true)
            local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
            game:CheckOtherPlayerInfo(self._RoleID, EOtherRoleInfoType.RoleInfo_Detail, nil)
            MenuComponent.HandleClick(self)
        end
	end
	SeePlayerInfoComponent.Commit()
end

----------------------------------------
-- 战斗力对比
----------------------------------------
local CombatCompareComponent = Lplus.Extend(MenuComponent,"CombatCompareComponent")
do
	local def = CombatCompareComponent.define
    def.field("number")._RoleID = 0
	def.static("number","=>",CombatCompareComponent).new = function (roleID)
		local obj = CombatCompareComponent()
        obj._RoleID = roleID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21418)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        return true
    end
	def.override().HandleClick = function (self)
        if self._RoleID ~= 0 then
            -- TODO 打开一个界面            
            -- game._GUIMan:ShowTipText(tostring(self._RoleID), false)
            -- game._GUIMan:Open("CPanelUIPlayerStrongCompare", nil)
            local C2SCompareOtherInfo = require "PB.net".C2SCompareOtherInfo
            local protocol = C2SCompareOtherInfo()
            protocol.OtherRoleId = self._RoleID
            PBHelper.Send(protocol)
            MenuComponent.HandleClick(self)
        end
	end
	CombatCompareComponent.Commit()
end

----------------------------------------
--组队邀请
----------------------------------------
local InviteMemberComponent = Lplus.Extend(MenuComponent,"InviteMemberComponent")
do
	local def = InviteMemberComponent.define
    def.field("number")._TargetID = 0
    def.field("number")._MyTeamID = 0
    def.field("number")._TargetTeamId = 0

	def.static("number","number","number","=>",InviteMemberComponent).new = function (targetID, myTeamId, targetTeamId)
		local obj = InviteMemberComponent()
        obj._TargetID = targetID
        obj._MyTeamID = myTeamId
        obj._TargetTeamId = targetTeamId

		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21401)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        local TeamMan = CTeamMan.Instance()
        -- 如果双方都没队伍 or 我是队长，他没队伍
        if (self._MyTeamID <= 0 and self._TargetTeamId <= 0 and not game._CFriendMan:IsInBlackList(self._TargetID)) or (TeamMan:IsTeamLeader() and self._TargetTeamId <= 0 and not game._CFriendMan:IsInBlackList(self._TargetID)) then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        CTeamMan.Instance():InvitateMember(self._TargetID)
        MenuComponent.HandleClick(self)
	end
	InviteMemberComponent.Commit()
end

----------------------------------------
--申请入队
----------------------------------------
local ApplyInTeamComponent = Lplus.Extend(MenuComponent,"ApplyInTeamComponent")
do
	local def = ApplyInTeamComponent.define
    def.field("number")._TargetID = 0
    def.field("number")._MyTeamID = 0
    def.field("number")._TargetTeamId = 0

	def.static("number","number","number","=>",ApplyInTeamComponent).new = function (targetID, myTeamId, targetTeamId)
		local obj = ApplyInTeamComponent()
        obj._TargetID = targetID
        obj._MyTeamID = myTeamId
        obj._TargetTeamId = targetTeamId

		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21413)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        local TeamMan = CTeamMan.Instance()
        -- 如果我没队伍，他有队伍
        if self._MyTeamID <= 0 and self._TargetTeamId > 0 and not game._CFriendMan:IsInBlackList(self._TargetID) then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        if self._TargetID ~= 0 then
            CTeamMan.Instance():ApplyTeam(self._TargetTeamId)
            MenuComponent.HandleClick(self)
        end
	end
	ApplyInTeamComponent.Commit()
end

----------------------------------------
--离开队伍
----------------------------------------
local QuitTeamComponent = Lplus.Extend(MenuComponent,"QuitTeamComponent")
do
	local def = QuitTeamComponent.define
	def.static("=>",QuitTeamComponent).new = function ()
		local obj = QuitTeamComponent()
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21409)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        local TeamMan = CTeamMan.Instance()
        if TeamMan:InTeam() then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        CTeamMan.Instance():QuitTeam()
        MenuComponent.HandleClick(self)
	end
	QuitTeamComponent.Commit()
end

----------------------------------------
--请离队伍（仅队长显示）
----------------------------------------
local KickTeamComponent = Lplus.Extend(MenuComponent,"KickTeamComponent")
do
	local def = KickTeamComponent.define
    def.field("number")._MemberID = 0
	def.static("number","=>",KickTeamComponent).new = function (memberID)
		local obj = KickTeamComponent()
        obj._MemberID = memberID
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21405)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        local TeamMan = CTeamMan.Instance()
        if TeamMan:InTeam() and TeamMan:IsTeamMember(self._MemberID) and TeamMan:IsTeamLeader() then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        CTeamMan.Instance():KickMember(self._MemberID)
        MenuComponent.HandleClick(self)
	end
	KickTeamComponent.Commit()
end

----------------------------------------
--转让队长（仅队长显示）
----------------------------------------
local ExchangeTeamLeaderComponent = Lplus.Extend(MenuComponent,"ExchangeTeamLeaderComponent")
do
	local def = ExchangeTeamLeaderComponent.define
    def.field("number")._MemberID = 0
	def.static("number","=>",ExchangeTeamLeaderComponent).new = function (memberId)
		local obj = ExchangeTeamLeaderComponent()
        obj._MemberID = memberId
		return obj
	end
    def.override("=>", "string").GetBtnName = function (self)
        return StringTable.Get(21410)
    end
    def.override("=>", "boolean").IsMeetCondition = function(self)
        local TeamMan = CTeamMan.Instance()
        if TeamMan:InTeam() and TeamMan:IsTeamMember(self._MemberID) and TeamMan:IsTeamLeader() then
            return true
        else
            return false
        end
    end
	def.override().HandleClick = function (self)
        CTeamMan.Instance():ExchangeLeader(self._MemberID)
        MenuComponent.HandleClick(self)
	end
	ExchangeTeamLeaderComponent.Commit()
end

return {
    --MenuComponent = MenuComponent,                              --基类
    ChatComponent = ChatComponent,                              --私聊
    AddFriendComponent = AddFriendComponent,                    --添加好友
    DeleteFriendComponent = DeleteFriendComponent,              --删除好友
    SeePlayerInfoComponent = SeePlayerInfoComponent,            --查看信息
    CombatCompareComponent = CombatCompareComponent,
    MemberManageComponent = MemberManageComponent,              --成员管理（公会）
    KickMemberComponent = KickMemberComponent,                  --踢出公会（公会）
    AppointMemberComponent = AppointMemberComponent,            --任命成员（公会）
    AssigGuildLeaderComponent = AssigGuildLeaderComponent,      --转让会长（公会）
    InviteMemberComponent = InviteMemberComponent,              --组队邀请
    ApplyInTeamComponent = ApplyInTeamComponent,                --申请入队
    QuitTeamComponent = QuitTeamComponent,                      --离开队伍
    ExchangeTeamLeaderComponent = ExchangeTeamLeaderComponent,  --转让队长
    KickTeamComponent = KickTeamComponent,						--踢出队伍
    AddBlackListComponent = AddBlackListComponent,              --加入黑名单
    RemoveBlackListComponent = RemoveBlackListComponent,        --移除黑名单
    RemoveRecentChatComponent = RemoveRecentChatComponent,      --移出列表（最近联系人）
}