local Lplus = require "Lplus"
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"

--[[
local NotifyIconPath = {
    None = "",
    TeamInvite = "",
    TeamApplication = "",
    GuildInvite = "",
    Mail = "",
    Conversation = "",
    SystemNotify = ""
}
]]
----------------------------------------
--基类
----------------------------------------
local NotifyBase = Lplus.Class("NotifyBase")
do
	local def = NotifyBase.define
    def.field("number")._NotifyType = -1                        -- 通知类型（EnumDef.NotificationType）
    def.field("boolean")._IsOkRemoveSameType = false            -- 点击确定的时候是否移除队列里面同类型的
    def.field("boolean")._IsCancleRemoveSameType = false        -- 点击取消的时候是否移除队列里面同类型的
    def.field("boolean")._IsClickCancle = true                  -- 是否是点击的取消（用来记录用户点击的取消还是确定）
    def.field("number")._BornTime = 0                           -- 该通知创建时间
    def.field("function")._CallBack = nil                       -- 点击时的回调
    -- 执行通知
    def.virtual("boolean").DONotify = function(self, isOK)
        if self._CallBack ~= nil then
            self._CallBack(isOK)
        end
    end
    -- 图标路径
    def.virtual("=>", "string").GetIconPath = function (self)
        return ""
    end
    -- Title
	def.virtual("=>","string").GetTitle = function (self)
        return ""
	end
    -- 描述
    def.virtual("=>","string").GetDes = function (self)
        return ""
	end
    -- 拿一个notify和自己比较
    def.virtual("table", "=>", "boolean").Compare = function(self, other)
        return false
    end
    -- 重新设置出生时间
    def.virtual("number").ResetBornTime = function(self, time)
        self._BornTime = time
    end

    def.method("function").SetCallBack = function (self, callBack)
        self._CallBack = callBack
    end
	NotifyBase.Commit()
end

----------------------------------------
--组队邀请
----------------------------------------
local TeamInviteNotify = Lplus.Extend(NotifyBase,"TeamInviteNotify")
do
	local def = TeamInviteNotify.define
    def.field("string")._TargetName = ""
    def.field("number")._TeamID = 0
    def.field("number")._TargetID = 0
    def.field("number")._DungeonID = 0
    def.field("string")._InviterName = ""

    def.static("string","number","number", "number", "function","=>",TeamInviteNotify).new = function (targetName, teamID, targetID, dungeonID, callBack)
		local obj = TeamInviteNotify()
        obj._NotifyType = EnumDef.NotificationType.TeamInvite
        obj._TargetName = CTeamMan.Instance():GetTeamRoomNameByDungeonId(dungeonID)
        obj._InviterName = targetName
        obj._TeamID = teamID
        obj._TargetID = targetID
        obj._DungeonID = dungeonID
        obj._IsOkRemoveSameType = false
        obj._IsCancleRemoveSameType = false
        obj._CallBack = callBack
		return obj
	end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        if isOK then
            CTeamMan.Instance():InvitateAccept(self._TeamID)
        else
            CTeamMan.Instance():InvitateRefuse(self._TeamID)
        end
        NotifyBase.DONotify(self, isOK)
    end
    --图标路径
    --def.override("=>", "string").GetIconPath = function (self)
    --    return NotifyIconPath.TeamInvite
    --end
    --Title
	def.override("=>","string").GetTitle = function (self)
        local tip = string.format(StringTable.Get(22047), self._InviterName)
        return tip
	end
    --描述
    def.override("=>","string").GetDes = function (self)
        local dungeon_temp = CElementData.GetTemplate("Instance", self._DungeonID)
        if dungeon_temp == nil then 
            return StringTable.Get(22039)
        else
            local teamMan = CTeamMan.Instance()
            local roomId = teamMan:ExchangeToRoomId(self._DungeonID)
            local roomTemplate = CElementData.GetTemplate("TeamRoomConfig", roomId)
            local str = ""
            if roomTemplate == nil then
                str = teamMan:GetTeamRoomNameByDungeonId(self._DungeonID)
            else
                str = RichTextTools.GetElsePlayerNameRichText(roomTemplate.DisplayName, false)
            end

            return string.format(StringTable.Get(22038), str)
        end
	end
    --拿一个notify和自己比较
    def.override("table", "=>", "boolean").Compare = function(self, other)
        return other._NotifyType == self._NotifyType and
               other._TeamID == self._TeamID and
               other._TargetID == self._TargetID and
               other._DungeonID == self._DungeonID
    end
	TeamInviteNotify.Commit()
end

----------------------------------------
-- 限时活动开启提示
----------------------------------------
local TimeLimitActivityNotify = Lplus.Extend(NotifyBase, "TimeLimitActivityNotify")
do
    local def = TimeLimitActivityNotify.define
    def.field("string")._ActivityName = ""

    def.static("string", "function","=>",TimeLimitActivityNotify).new = function (activityName, callBack)
		local obj = TimeLimitActivityNotify()
        obj._NotifyType = EnumDef.NotificationType.TimeLimitActivity
        obj._ActivityName = activityName
        obj._IsOkRemoveSameType = false
        obj._IsCancleRemoveSameType = false
        obj._CallBack = callBack
		return obj
	end
--    --执行通知
--    def.override("boolean").DONotify = function(self, isOK)
--        NotifyBase.DONotify(self, isOK)
--    end

	def.override("=>","string").GetTitle = function (self)
--        local tip = StringTable.Get(22035)
--        return tip
        return ""
	end
    --描述
    def.override("=>","string").GetDes = function (self)
        return string.format(StringTable.Get(19493), self._ActivityName)
	end
    --拿一个notify和自己比较
    def.override("table", "=>", "boolean").Compare = function(self, other)
        return self._NotifyType == other._NotifyType and
               string.find(self._ActivityName,other._ActivityName) ~= nil
    end
	TimeLimitActivityNotify.Commit()
end

----------------------------------------
-- 普通提示
----------------------------------------
local NormalNotify = Lplus.Extend(NotifyBase, "NormalNotify")
do
    local def = NormalNotify.define
    def.field("string")._Title = ""
    def.field("string")._Des = ""

    def.static("string", "string", "function", "=>",NormalNotify).new = function (title, des, callback)
		local obj = NormalNotify()
        obj._NotifyType = EnumDef.NotificationType.Normal
        obj._Title = title
        obj._Des = des
        obj._IsOkRemoveSameType = false
        obj._IsCancleRemoveSameType = false
        obj._CallBack = callback
		return obj
	end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        NotifyBase.DONotify(self, isOK)
    end

	def.override("=>","string").GetTitle = function (self)
        return self._Title
	end
    --描述
    def.override("=>","string").GetDes = function (self)
        return self._Des
	end
    --拿一个notify和自己比较
    def.override("table", "=>", "boolean").Compare = function(self, other)
        return self._NotifyType == other._NotifyType and
               string.find(self._Title, other._Title) ~= nil and
               string.find(self._Des, other._Des) ~= nil
    end
	NormalNotify.Commit()
end

return {
    TeamInviteNotify = TeamInviteNotify,                  --队邀请通知
    TimeLimitActivityNotify = TimeLimitActivityNotify,    --限时活动到点通知
    NormalNotify = NormalNotify,
    --TeamApplicationNotify = TeamApplicationNotify,      --组队申请通知
    --GuildInviteNotify = GuildInviteNotify,              --公会邀请通知
    --MailNotify = MailNotify,                            --邮件通知
    --ConversationNotify = ConversationNotify,            --聊天通知
    --SystemNotify = SystemNotify,                        --系统提示
    --NormalNotify = NormalNotify,                        --简单通用通知    
}



--[[
----------------------------------------
--组队同意
----------------------------------------
local TeamApplicationNotify = Lplus.Extend(NotifyBase,"TeamApplicationNotify")
do
    local def = TeamApplicationNotify.define
    def.field("string")._TargetName = ""
    def.field("number")._TeamID = 0
    def.field("number")._TargetID = 0
    def.static("string","number","number","function","=>",TeamApplicationNotify).new = function (targetName, teamID, targetID, callBack)
        local obj = TeamApplicationNotify()
        obj._NotifyType = EnumDef.NotificationType.TeamApplication
        obj._RemovePrevious = false
        obj._TargetName = targetName
        obj._TeamID = teamID
        obj._TargetID = targetID
        obj._CallBack = callBack
        return obj
    end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        if isOK then
        end
    end
    --图标路径
    def.override("=>", "string").GetIconPath = function (self)
        return NotifyIconPath.TeamApplication
    end
    --Title
    def.override("=>","string").GetTitle = function (self)
        return self._TargetName
    end
    --描述
    def.override("=>","string").GetDes = function (self)
        return StringTable.Get(22026)
    end
    TeamApplicationNotify.Commit()
end

----------------------------------------
--公会邀请
----------------------------------------
local GuildInviteNotify = Lplus.Extend(NotifyBase,"GuildInviteNotify")
do
    local def = GuildInviteNotify.define
    def.field("string")._TargetName = ""

    def.static("string","function","=>",GuildInviteNotify).new = function (targetName, callBack)
        local obj = GuildInviteNotify()
        obj._NotifyType = EnumDef.NotificationType.GuildInvite
        obj._TargetName = targetName
        obj._CallBack = callBack
        return obj
    end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        --TODO

        NotifyBase.DONotify(self, isOK)
    end
    --图标路径
    def.override("=>", "string").GetIconPath = function (self)
        return NotifyIconPath.GuildInvite
    end
    --Title
    def.override("=>","string").GetTitle = function (self)
        return self._TargetName
    end
    --描述
    def.override("=>","string").GetDes = function (self)
        return StringTable.Get(875)
    end
    GuildInviteNotify.Commit()
end

----------------------------------------
--邮件通知
----------------------------------------
local MailNotify = Lplus.Extend(NotifyBase,"MailNotify")
do
    local def = MailNotify.define

    def.static("function","=>",MailNotify).new = function (callBack)
        local obj = MailNotify()
        obj._NotifyType = EnumDef.NotificationType.Mail
        obj._CallBack = callBack
        return obj
    end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        --TODO

        NotifyBase.DONotify(self, isOK)
    end
    --图标路径
    def.override("=>", "string").GetIconPath = function (self)
        return NotifyIconPath.Mail
    end
    --Title
    def.override("=>","string").GetTitle = function (self)
        return StringTable.Get(15002)
    end
    --描述
    def.override("=>","string").GetDes = function (self)
        return StringTable.Get(15005)
    end
    MailNotify.Commit()
end

----------------------------------------
--聊天（Conversation）
----------------------------------------
local ConversationNotify = Lplus.Extend(NotifyBase,"ConversationNotify")
do
    local def = ConversationNotify.define
    def.field("string")._TargetName = ""
    def.static("string","function","=>",ConversationNotify).new = function (targetName,callBack)
        local obj = ConversationNotify()
        obj._NotifyType = EnumDef.NotificationType.Conversation
        obj._TargetName = targetName
        obj._CallBack = callBack
        return obj
    end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        --TODO

        NotifyBase.DONotify(self, isOK)
    end
    --图标路径
    def.override("=>", "string").GetIconPath = function (self)
        return NotifyIconPath.Conversation
    end
    --Title
    def.override("=>","string").GetTitle = function (self)
        return self._TargetName
    end
    --描述
    def.override("=>","string").GetDes = function (self)
        return StringTable.Get(29001)
    end
    ConversationNotify.Commit()
end

----------------------------------------
--简单通用的
----------------------------------------
local NormalNotify = Lplus.Extend(NotifyBase,"NormalNotify")
do
    local def = NormalNotify.define
    def.field("string")._Title = ""
    def.field("string")._Des = ""
    def.field("string")._IconPath = ""
    --标题、描述、消息显示类型的图标、回调
    def.static("string","string","string", "function","=>",NormalNotify).new = function (title, des, iconPath,callBack)
        local obj = NormalNotify()
        obj._NotifyType = EnumDef.NotificationType.Normal
        obj._Title = title
        obj._Des = des
        obj._IconPath = iconPath
        obj._CallBack = callBack
        return obj
    end
    --执行通知
    def.override("boolean").DONotify = function(self, isOK)
        --TODO

        NotifyBase.DONotify(self, isOK)
    end
    --图标路径
    def.override("=>", "string").GetIconPath = function (self)
        return self._IconPath
    end
    --Title
    def.override("=>","string").GetTitle = function (self)
        return self._Title
    end
    --描述
    def.override("=>","string").GetDes = function (self)
        return self._Des
    end
    NormalNotify.Commit()
end

]]