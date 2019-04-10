local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local UserData = require "Data.UserData"
local CPanelFriend = require "GUI.CPanelFriend"
local ChatChannel = require "PB.data".ChatChannel
local SOCIAL_OPT_TYPE = require "PB.net".SOCIAL_OPT_TYPE
local GROUP_EDIT_TYPE = require "PB.net".GROUP_EDIT_TYPE
local SOCIAL_OO_TYPE = require "PB.net".SOCIAL_OO_TYPE
local CElementData = require "Data.CElementData"
local SOCIAL_TYPE = require "PB.net".SOCIAL_TYPE
local GROUP_EDIT_TYPE = require "PB.net".GROUP_EDIT_TYPE
local ChatType = require "PB.data".ChatType
local BagType = require "PB.net".BAGTYPE
local CPanelChatNew = require "GUI.CPanelChatNew"
local CPanelCreateChat = require "GUI.CPanelCreateChat"
local CPageFriendChat = require "GUI.CPageFriendChat"
local ChatManager = require "Chat.ChatManager"

local CFriendMan = Lplus.Class("CFriendMan")
local def = CFriendMan.define

-- 特殊id
def.field("number")._MaxFriendClosely = 0                        --最近联系人上限
def.field("number")._MaxFriend = 0                               --好友上限
def.field("number")._MaxBlackListNum = 0                            --黑名单上限
def.field("number")._MaxApplyList = 0                            --申请列表上限
def.field("number")._MaxServerMsg = 0                            --服务器离线消息上限
def.field("number")._MaxClientMsg = 0                            --客户端私聊存储消息上限
def.field("number")._MaxChars = 0                                
def.field("number")._MinApplyInterval = 0                         --最小申请好友的间隔时间
def.field("number")._MaxGroupNum = 0                              --最大分组数量

def.field("boolean")._IsFriendModuleReady = false
def.field("table")._ChatMessageList = BlankTable                         -- 聊天消息数据列表（以发送者id 为key值 存储消息和对话目标角色id）
def.field("table")._UnreadMsgList = BlankTable							 -- 未读消息列表(离线数据 在上线后没读变为未读数据)
def.field("table")._FriendList = BlankTable                              -- 好友列表(包括和黑名单)
def.field("table")._BlackList = BlankTable 							     -- 黑名单
def.field("table")._ApplyList = BlankTable                               -- 别人向我申请列表
def.field("table")._SearchResult = nil                                   -- 搜索结果
def.field("table")._RecommondList = BlankTable 						     -- 推荐列表
def.field("table")._OnLineMsgList = BlankTable                           -- 在线消息
def.field("table")._RecentList = BlankTable							     -- 最近联系人列表
def.field("table")._ApplyListToElse = BlankTable						 -- 玩家向别人申请的列表
 
def.field("table")._CurChatMsgListData = BlankTable                                           -- 当前聊天对话框信息数据列表（发送者id 该id对应_ChatMessageList的列表索引,内容消息） 
def.field("table")._RemoveRecentIdListTime = BlankTable                                       -- 从最近联系人删除的对话需要保存一定时间 
def.field("table")._DesRoleData = nil                                                    -- 主角发送信息的目标角色id

def.field("table")._FightMirrorData = BlankTable                                               -- 好友助战镜像数据

-- local RecordKeys = 
-- {
--     CHAT_MESSAGES = "chat_messages",           --本地数据中存储聊天记录的key
--     UNREAD_MESSAGES = "unread_messages",           -- 本地数据中存储未读数据记录的key
-- }

def.final("=>", CFriendMan).new = function ()
	local obj = CFriendMan()
	return obj
end

local function CompaireByTime(e1, e2)
	if e1.OptTime > e2.OptTime then
    	return true
    else
    	return false
    end
end

local function sortfunction1 (e1,e2)
    if e1.Msg.time ~= e2.Msg.time then 
        return e1.Msg.time < e2.Msg.time
    else
        return false
    end
end

--声音是否合法
local function IsValidVoice(voice)
    if voice == nil then
        game._GUIMan:ShowTipText(StringTable.Get(19136),false)
        return false
    end
    return true
end

local function IsMsgOverMaxChars(self,str)
    if string.utf8len(str) > self._MaxChars then
        game._GUIMan:ShowTipText(StringTable.Get(19142),false)
        return true
    end
    return false
end

local function CompaireByOnlineAndOptTime(e1,e2)
	if e1.IsOnLine and not e2.IsOnLine then 
		return true
    elseif e1.IsOnLine == e2.IsOnLine then
        if e1.OptTime > e2.OptTime then 
            return true
        else
            return false
        end
	else 
		return false
	end
end

local function SetGroupMemberOptTime(self,roleId)
 --消息对话时间
    local sendTime = 0
    local reciveTime = 0
    if self._ChatMessageList[roleId] ~= nil and #self._ChatMessageList[roleId] > 0 then 
        local msgs = self._ChatMessageList[roleId]
        reciveTime = msgs[#msgs].time
    end
    if self._ChatMessageList[game._HostPlayer._ID] ~= nil then 
        for i,v in ipairs(self._ChatMessageList[game._HostPlayer._ID]) do
            if v.DesRoleId == roleId then 
                sendTime = v.time
            end
        end
    end
    if sendTime > reciveTime  then 
        return sendTime
    else
        return reciveTime
    end
end

local function GetFriendByRoleId(self,roleId)
	if #self._FriendList == 0 or roleId <= 0 then return nil end
	for i = 1,#self._FriendList do 
		if self._FriendList[i].RoleId == roleId then 
			return self._FriendList[i]
		end
	end
	return nil
end

--添加未读消息
local function AddUnreadMsg(self,msg)
	local roleId = msg.senderInfo.Id or msg.senderInfo.RoleId
    local msg1 = {DesRoleId = game._HostPlayer._ID,chatType = msg.chatType, text = msg.text ,voiceTxt = msg.voice, time = msg.time, seconds = msg.voiceLength,itemInfo = msg.itemInfo}
        -- 添加到未读消息列表
    if self._UnreadMsgList[roleId] == nil then 
        self._UnreadMsgList[roleId] = {}
        table.insert(self._UnreadMsgList[roleId],msg1)
    else
        table.insert(self._UnreadMsgList[roleId],msg1)
    end	
end

-- 更新(好友,黑名单,最近联系人)在线状态
local function UpdateOnlineState(data,roleId,isOnline,LogoutTime)
    if #data == 0 then return end
	for i,v in ipairs(data) do
		if v.RoleId == roleId then 
			v.IsOnLine = isOnline
            v.LogoutTime = LogoutTime
            break            
		end
	end
end

-- 判断当前聊天对话框条数是否超限根据选中的对话id 并把对话信息添加到表中
local function IsOverClientSaveMsg(self,msg,roleId)
    if self._CurChatMsgListData[roleId] ~= nil and #self._CurChatMsgListData[roleId] >= self._MaxClientMsg then 
        -- 删除 顶端
        local firstMsg = self._CurChatMsgListData[1]
        table.remove(self._ChatMessageList[firstMsg.SenderRoleId],firstMsg.Index)
        table.remove(self._CurChatMsgListData[roleId],1)
        table.insert(self._ChatMessageList[msg.senderInfo.Id],msg)

         -- 当前聊天列表
        local msgItem = {}
        msgItem.SenderRoleId = msg.senderInfo.Id     -- 发送者id
        msgItem.Index = #self._ChatMessageList[msg.senderInfo.Id]
        msgItem.Msg = msg
        table.insert(self._CurChatMsgListData[roleId],msgItem)
        
        return true
    else
        if self._ChatMessageList[msg.senderInfo.Id] == nil then 
            self._ChatMessageList[msg.senderInfo.Id] = {}
        end
        table.insert(self._ChatMessageList[msg.senderInfo.Id],msg)
         -- 当前聊天列表
        local msgItem = {}
        msgItem.SenderRoleId = msg.senderInfo.Id     -- 发送者id
        msgItem.Index = #self._ChatMessageList[msg.senderInfo.Id]             
        msgItem.Msg = msg
        if self._CurChatMsgListData[roleId] == nil then 
            self._CurChatMsgListData[roleId] = {}
        end
        table.insert(self._CurChatMsgListData[roleId],msgItem)
        return false
    end
end

-- 把离线添加到本地消息列表中
local function GetOffLineMsg(self,data)
    if data == nil then return end
    for i,v in ipairs(data) do
        local roleId = v.senderInfo.Id

        local senderInfo = {Id = v.senderInfo.Id,Name = v.senderInfo.Name,Level = v.senderInfo.Level,HeadIcon = v.senderInfo.HeadIcon,Gender = v.senderInfo.Gender,Profession = v.senderInfo.Profession}
        local msg = {DesRoleId = game._HostPlayer._ID ,senderInfo = senderInfo,chatType = v.chatType, text = v.text ,voiceTxt = v.voice, time = v.time, seconds = v.voiceLength }
        local msg1 = {DesRoleId = game._HostPlayer._ID,chatType = v.chatType, text = v.text ,voiceTxt = v.voice, time = v.time, seconds = v.voiceLength}
        -- 添加到未读消息列表
        if self._UnreadMsgList[roleId] == nil then 
            self._UnreadMsgList[roleId] = {}
            table.insert(self._UnreadMsgList[roleId],msg1)
        else
            table.insert(self._UnreadMsgList[roleId],msg1)
        end

        --添加到本地消息列表（别人发给我）

        if self._CurChatMsgListData[roleId] == nil then 
            self._CurChatMsgListData[roleId] = self:GetChatMessagesTable(roleId) 
        end
        IsOverClientSaveMsg(self,msg,roleId)
    end
end

--添加单条消息加到角色聊天记录(目标角色id，角色信息， 信息类型 ，文本内容)
-- 服务器传过来的表要重新构建 不能直接存储lua
local function AddMsg(self,desRid,senderInfo, chatType,txt,t,voice, me, seconds ,isReceive,itemInfo)
    local msg = nil 
    local roleId = 0 
    if not me then
        -- 别人发给我
        if senderInfo.id ~= -1 then
            senderInfo = {Id = senderInfo.Id,Name = senderInfo.Name,Level = senderInfo.Level,HeadIcon = senderInfo.HeadIcon,Gender = senderInfo.Gender,Profession = senderInfo.Profession}
            roleId = senderInfo.Id
            msg = {DesRoleId = game._HostPlayer._ID ,senderInfo = senderInfo,chatType = chatType, text = txt ,voiceTxt = voice, time = t, seconds = seconds,itemInfo = itemInfo}
        else
             -- 系统消息
            senderInfo = {Id = senderInfo.Id,Name = senderInfo.Name}
            roleId = senderInfo.Id
            msg = {DesRoleId = game._HostPlayer._ID ,senderInfo = senderInfo,chatType = chatType, text = txt ,voiceTxt = voice, time = t, seconds = seconds,itemInfo = itemInfo}
        end
    else
        -- 我发给别人 
        senderInfo = {Id = game._HostPlayer._ID,Name = game._HostPlayer._InfoData._Name,Level = game._HostPlayer._InfoData._Level,
                      HeadIcon = game._HostPlayer._InfoData._CustomImgSet,Gender = game._HostPlayer._InfoData._Gender,Profession = game._HostPlayer._InfoData._Prof}
        msg = {DesRoleId = desRid,senderInfo = senderInfo,chatType = chatType, text = txt ,voiceTxt = voice, time = t, seconds = seconds,itemInfo = itemInfo}
        roleId = desRid
    end
    local isOver = IsOverClientSaveMsg(self,msg,roleId)
    if isOver then
        CPageFriendChat.Instance():RemoveAtFirstChatItem()
        CPageFriendChat.Instance():AddChatToLast(msg,isReceive)
    else
        CPageFriendChat.Instance():AddChatToLast(msg,isReceive)
    end
    -- 显示到主界面MainChat
    local RoleInfo = {
                        RoleId = senderInfo.Id,
                        PlayerName = senderInfo.Name ,
                    }
    ChatManager.Instance():ClientSendMsg(ChatChannel.ChatChannelSocial, txt, false,chatType,itemInfo,RoleInfo )               
    -- CPanelMainChat.Instance():UpdateMsgInShow(chatMsg)  
end

local function RemoveRecentContactByRoleId (self,roleId)
    if self._RecentList == nil or #self._RecentList == 0 then return end
    for i,v in ipairs(self._RecentList) do
        if v.RoleId == roleId then 
            table.remove(self._RecentList,i)
            break
        end
    end
end

-- 添加最近联系人(如果已经在最近联系人中需要删掉 重新加到列表中且index为1)
local function InserRecentContactByRoleData(self,roleData,isRefresh)
    RemoveRecentContactByRoleId(self,roleData.RoleId)
    table.insert(self._RecentList, 1, roleData)
    if #self._RecentList > self._MaxFriendClosely then
    	table.remove(self._RecentList,#self._RecentList)
   	end
    -- 在界面中系统消息在最近联系人的列表中第一位
    --主动与人对话时不刷新列表，一旦对方给回给我就需要马上刷新，其他就进入到最近联系人界面的时候刷新
    if not isRefresh then return end
	-- CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.RECENTCONTACTS)
end

local function UpdateMemberAmicability(self,roleData,data)
    if #data == 0 then return data end
    for i,v in ipairs(data) do
        if v.RoleId == roleData.RoleId then 
            v.Amicability = roleData.Amicability
            break
        end
    end
    return data
end

local function GetUserData(self)
    local account = game._NetMan._UserName
    local msgAll = nil
    local accountInfo1 = UserData.Instance():GetCfg(EnumDef.LocalFields.FriendChatMessage, account)  or {} 
    local accountInfo2 = UserData.Instance():GetCfg(EnumDef.LocalFields.FriendChatUnreadMsg, account)  or {} 

    if accountInfo1 ~= nil then
        local serverInfo = accountInfo1[game._NetMan._ServerName]
        if serverInfo ~= nil then
            msgAll = serverInfo[game._HostPlayer._ID]
        end
    end
    self._ChatMessageList = msgAll or {}

    local unread = nil
    if accountInfo2 ~= nil then
        local serverInfo = accountInfo2[game._NetMan._ServerName]
        if serverInfo ~= nil then
            unread = serverInfo[game._HostPlayer._ID]
        end
    end
    -- self._RecentList = native_data[RecordKeys.RECENT_CONTACTS] or {}
    self._UnreadMsgList = unread or {}
    -- warn("私聊记录读取："..tostring(table.nums(self._ChatMessageList))..", 最近联系人读取："..tostring(table.nums(self._UnreadMsgList)))
end

-- 最近联系人（非好友）聊天记录在移出最近联系人列表后，保存一段时间，超过时间后删除。
local function AddIDToRemovedTable(self,id)
    if self:IsFriend(id) then return end

    if self._RemoveRecentIdListTime == nil or table.nums(self._RemoveRecentIdListTime) == 0 then 
        self._RemoveRecentIdListTime = {}
    end
    table.insert(self._RemoveRecentIdListTime , id)
end

local function DeleteIDFromRemovedTable(self,id) 
    if self._RemoveRecentIdListTime == nil or #self._RemoveRecentIdListTime == 0  then  return end
    for i ,ID in ipairs(self._RemoveRecentIdListTime) do 
        if ID == id then 
            table.remove(self._RemoveRecentIdListTime,i)
            return
        end 
    end
end

local function HostPlayerSendMsg(self,content,desRoleId)
    if desRoleId ~= self._DesRoleData.RoleId then return end
    local FilterMgr = require "Utility.BadWordsFilter".Filter
    local StrMsg = FilterMgr.FilterChat(content.text)
    if content.chatType == ChatType.ChatTypeNormal then 
        AddMsg(self, desRoleId, nil, ChatType.ChatTypeNormal, StrMsg, content.time, nil, true, nil, false)
    elseif content.chatType == ChatType.ChatTypeVoice then
        AddMsg(self, desRoleId, nil, ChatType.ChatTypeVoice, "", content.time,content.voice, true,content.voiceLength,false)
    elseif content.chatType == ChatType.ChatTypeItemInfo then 
        if content.itemInfo.Tid == 0 then 
            game._GUIMan:ShowTipText(StringTable.Get(13025), false)
            return
        end

        local itemTemplate = CElementData.GetItemTemplate(content.itemInfo.Tid)
        if string.find(StrMsg, itemTemplate.TextDisplayName) then
            local LinkBefore = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." <"
            local LinkAfter = ">[-]"
            StrMsg = string.gsub(StrMsg, "<", LinkBefore)
            StrMsg = string.gsub(StrMsg, ">", LinkAfter)
        end
        AddMsg(self, desRoleId,nil, ChatType.ChatTypeItemInfo,StrMsg, content.time, "",true, nil,false,content.itemInfo)
    end
    InserRecentContactByRoleData(self,self._DesRoleData,false)
    -- UpdateGroupMemberOptTime(self,self._DesRoleData)
end

local function ReceiveMessage(self,content)
    AddUnreadMsg(self,content)
    local FilterMgr = require "Utility.BadWordsFilter".Filter
    local StrMsg = FilterMgr.FilterChat(content.text)
    local senderInfo = content.senderInfo
    local roleData = GetFriendByRoleId(self,senderInfo.Id)
    if roleData == nil then
        --陌生人
        roleData = {
                            RoleId = senderInfo.Id,
                            Name = senderInfo.Name,
                            Profession = senderInfo.Profession,
                            Gender = senderInfo.Gender,
                            Level = senderInfo.Level,
                            GroupId = -1, 
                            CustomImgSet = senderInfo.HeadIcon,
                            OptTime = content.time,
                            IsOnLine = true,

                        }

    end

    if content.chatType == ChatType.ChatTypeItemInfo then 
        if content.itemInfo.Tid == 0 then 
            game._GUIMan:ShowTipText(StringTable.Get(13025), false)
            return
        end
        local itemTemplate = CElementData.GetItemTemplate(content.itemInfo.Tid)
        if string.find(StrMsg, itemTemplate.TextDisplayName) then
            local LinkBefore = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." <"
            local LinkAfter = ">[-]"
            StrMsg = string.gsub(StrMsg, "<", LinkBefore)
            StrMsg = string.gsub(StrMsg, ">", LinkAfter)
        end
    end

    InserRecentContactByRoleData(self,roleData,false)
    -- UpdateGroupMemberOptTime(self,roleData)
    AddMsg(self,game._HostPlayer._ID,senderInfo,content.chatType,StrMsg, content.time,content.voice,false,content.voiceLength,true,content.itemInfo)
    
    if not CPanelFriend.Instance():IsShow() then 
        CPanelFriend.Instance():ShowChatFriendRed()
    end
end

def.method().Init = function(self)
	
    self._MaxFriendClosely = CSpecialIdMan.Get("MaxClosely")
    self._MaxFriend = CSpecialIdMan.Get("MaxFriend")
    -- max_enemies = CSpecialIdMan.Get("MaxEnemies")
    self._MaxBlackListNum = CSpecialIdMan.Get("MaxBlackList")
    self._MaxApplyList = CSpecialIdMan.Get("MaxApplyList")
    self._MaxServerMsg = CSpecialIdMan.Get("MaxServerMsg")
    self._MaxClientMsg = CSpecialIdMan.Get("MaxClientMsg")
    self._MaxChars = CSpecialIdMan.Get("MaxChars")
    self._MinApplyInterval = CSpecialIdMan.Get("ApplyInterval")  
    self._MaxGroupNum = CSpecialIdMan.Get("MaxGroupNum")
end

def.method().Release = function(self)
    self._ChatMessageList = {}
    self._UnreadMsgList = {}
    self._FriendList = {}
    self._BlackList = {}
    self._ApplyList = {}
    self._SearchResult = nil
    self._RecommondList = {}
    self._OnLineMsgList = {}
    self._RecentList = {}
    self._ApplyListToElse = {}
    self._CurChatMsgListData = {}
    self._RemoveRecentIdListTime = {}
    self._DesRoleData = nil
end


--好友数是否超过上限
def.method("=>","boolean").IsFriendNumberOverMax = function(self)
    if #self._FriendList >= self._MaxFriend then
        game._GUIMan:ShowTipText(StringTable.Get(30304),false)
        return true
    end
    return false
end

-- 判断数据情况
def.method("=>","boolean").IsFriendModuleReady = function(self)
    if not self._IsFriendModuleReady then 
        game._GUIMan:ShowTipText(StringTable.Get(30310),false)
    end
    return self._IsFriendModuleReady
end

--存储好友相关的缓存数据到本地(设备)
def.method().SaveRecord = function(self)
    -- warn("私聊记录写入："..tostring(table.nums(friends_messages))..", 群发记录写入："..tostring(table.nums(groups_messages))..", 最近联系人写入："..tostring(table.nums(recent_contacts)))
    if game._HostPlayer == nil or game._HostPlayer._ID == 0 then return end

    -- 移除最近联系人（非好友）的聊天记录
    if self._RemoveRecentIdListTime ~= nil and #self._RemoveRecentIdListTime > 0 then 
        for i,Id in ipairs(self._RemoveRecentIdListTime) do 
            if self._ChatMessageList[Id] == nil or #self._ChatMessageList[Id] == 0 then break end
            -- 我发给这个人的
            self._ChatMessageList[Id] = nil
            if self._ChatMessageList[game._HostPlayer._ID] == nil or #self._ChatMessageList[game._HostPlayer._ID] == 0 then break end
            
            local data = {}
            for i,v in ipairs(self._ChatMessageList[game._HostPlayer._ID]) do 
                if v.DesRoleId ~= Id then 
                    table.insert(data,v)
                end
            end
            if #data > 0 then 
                self._ChatMessageList[game._HostPlayer._ID] = data
            else
                self._ChatMessageList[game._HostPlayer._ID] = nil 
            end
        end
    end

    local account = game._NetMan._UserName
    if table.nums(self._ChatMessageList) > 0 then

        -- 将语音聊天和物品连接都转换成普通text类型
        for i ,v in pairs(self._ChatMessageList) do 
            if v ~= nil and #v > 0 then
                for j,msg in ipairs(v) do 
                    msg.chatType = ChatType.ChatTypeNormal
                    msg.itemInfo = nil
                end
            end
        end
     
        local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.FriendChatMessage, account)
        if accountInfo == nil then
            accountInfo = {}
        end
        local serverName = game._NetMan._ServerName
        if accountInfo[serverName] == nil then
            accountInfo[serverName] = {}
        end
        local roleId = game._HostPlayer._ID
        if accountInfo[serverName][roleId] == nil then
            accountInfo[serverName][roleId] = {}
        end
        accountInfo[serverName][roleId] = self._ChatMessageList
        -- print_r(self._ChatMessageList)
        UserData.Instance():SetCfg(EnumDef.LocalFields.FriendChatMessage, account, accountInfo)
    end


    if table.nums(self._UnreadMsgList) > 0 then 
        for i ,v in pairs(self._UnreadMsgList) do 
            if v ~= nil and #v > 0 then
                for j,msg in ipairs(v) do 
                    msg.chatType = ChatType.ChatTypeNormal
                    msg.itemInfo = nil
                end
            end
        end
        -- warn("保存  消息" ,table.nums(self._UnreadMsgList))
        local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.FriendChatUnreadMsg, account)
        if accountInfo == nil then
            accountInfo = {}
        end
        local serverName = game._NetMan._ServerName
        if accountInfo[serverName] == nil then
            accountInfo[serverName] = {}
        end
        local roleId = game._HostPlayer._ID
        if accountInfo[serverName][roleId] == nil then
            accountInfo[serverName][roleId] = {}
        end
        accountInfo[serverName][roleId] = self._UnreadMsgList
        -- print_r(self._UnreadMsgList)
        UserData.Instance():SetCfg(EnumDef.LocalFields.FriendChatUnreadMsg, account, accountInfo)
    end
end

-------------------------------------外部调用 --------------------------
-- 获取好友列表(包括黑名单里的好友)
def.method("=>","table").GetFriendList = function(self)
    return self._FriendList
end

--获取助战镜像数据
def.method("=>","table").GetFightMirrorList = function(self)
    return self._FightMirrorData
end

-- 角色id为roleId 是不是好友
def.method("number","=>","boolean").IsFriend = function (self,roleId)
	if #self._FriendList == 0 then return false end
	for i,v in ipairs(self._FriendList) do
		if v.RoleId == roleId then 
			return true
		end
	end
	return false
end

-- 是否在黑名单中
def.method("number","=>","boolean").IsInBlackList = function(self,roleId)
	if #self._BlackList == 0 then return false end 
	for i,v in ipairs(self._BlackList) do
		if v.RoleId == roleId then 
			return true
		end
	end
	return false
end

-- 获取非黑名单里的好友
def.method("=>","table").GetFriendsWithoutBlack = function(self)
    local friends = {}
    if #self._FriendList == 0 then return friends end
    for i,friend in ipairs(self._FriendList) do
        if not self:IsInBlackList(friend.RoleId) then 
            table.insert(friends,friend)
        end
    end
    return friends
end

def.method("number","=>","boolean").IsInRecentContactsList = function(self,roleId)
	if #self._RecentList == 0 then return false end
	for i,v in ipairs(self._RecentList) do
		if v.RoleId == roleId then 
			return true
		end
	end
	return false
end

def.method("number","=>","boolean").IsHaveRemoveRecentButton = function(self,roleId)
    if self:IsInRecentContactsList(roleId) then 
        return true
    end
    return false
end

def.method("=>","boolean").IsHaveUnreadMsg = function(self)
    if table.nums(self._UnreadMsgList) > 0 then 
        return true
    else
        return false
    end
end

-- -- 角色id为roleId 是不是在向别人申请的列表中
-- def.method("number","=>","boolean").IsInApplyList = function(self,roleId)
-- 	if #self._ApplyList <= 0 then return end
-- 	for i,v in ipairs(self._ApplyList) do
-- 		if v.RoleId == roleId then 
-- 			return true
-- 		end
-- 	end
-- 	return false
-- end

--获取申请列表
def.method("=>", "table").GetFriendsApply = function(self)

    if #self._ApplyList <= 1 then return self._ApplyList end
    if self._ApplyList then
        table.sort(self._ApplyList, CompaireByTime)
    end

    if #self._ApplyList > self._MaxApplyList then 
    	for i = self._MaxApplyList +1 ,#self._ApplyList do
    		table.remove(self._ApplyList,i)
    	end
    end

    return self._ApplyList
end

--获取推荐列表
def.method("=>","table").GetRecommondList = function(self)
	return self._RecommondList
end

-- 获取搜索结果
def.method("=>","dynamic").GetSearchReault = function(self) 
    return self._SearchResult
end

-- 获取最近联系人列表
def.method("=>","table").GetRecentList = function (self)
	return self._RecentList
end

--通过id获取未读信息数据
def.method("number","=>","dynamic").GetUnreadMsgByRoleId = function (self,roleId)
	return self._UnreadMsgList[roleId]
end

--读取消息（将消息从未读信息中删除）
def.method("number").ReadMsgChat = function(self, role_id)
    if self._UnreadMsgList[role_id] == nil then return end
    self._UnreadMsgList[role_id] = nil 
end

def.method("number","=>","dynamic").GetChatMessagesTable = function (self,roleId)
    if self._CurChatMsgListData[roleId] ~= nil then return self._CurChatMsgListData[roleId] end
    self._CurChatMsgListData[roleId] = {}
    if self._ChatMessageList[roleId] ~= nil then 
        for i,v in ipairs(self._ChatMessageList[roleId]) do
            local msgItem = {}
            msgItem.SenderRoleId = roleId     -- 发送者id
            msgItem.Index = i
            msgItem.Msg = v
            table.insert(self._CurChatMsgListData[roleId],msgItem)
        end
    end
    -- 我发给这个人的
    if self._ChatMessageList[game._HostPlayer._ID] ~= nil and #self._ChatMessageList[game._HostPlayer._ID] > 0 then 
        for i,v in ipairs(self._ChatMessageList[game._HostPlayer._ID]) do 
            if v.DesRoleId == roleId then 
                local msgItem = {}
                msgItem.SenderRoleId = game._HostPlayer._ID 
                msgItem.Index = i
                msgItem.Msg = v
                table.insert(self._CurChatMsgListData[roleId],msgItem)
            end
        end
    end
    if #self._CurChatMsgListData[roleId] > 0 then 
        table.sort(self._CurChatMsgListData[roleId],sortfunction1)
    end
	return self._CurChatMsgListData[roleId]
end

-- 获取黑名单数据
def.method("=>","table").GetBlackListData = function(self)
    return self._BlackList
end

--把某人移除黑名单
def.method("number").RemoveBlackListByRoleId = function(self,roleId)
    for i,v in ipairs(self._BlackList) do
        if v.RoleId == roleId then
            table.remove(self._BlackList,i)
            break
        end
    end
    CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.BLACKLIST)
end

-- 删除对话消息和联系人
def.method("number","boolean").DeleteMsgsAndRecentByRoleId = function(self,roleId,isUpdate)
    local function callback(value)
        if not value then return end
        if self._ChatMessageList[roleId] ~= nil then 
            self._ChatMessageList[roleId] = nil 
        end

        local results = {}
        if self._ChatMessageList[game._HostPlayer._ID] ~= nil and  #self._ChatMessageList[game._HostPlayer._ID] > 0 then 
            for i,v in ipairs(self._ChatMessageList[game._HostPlayer._ID]) do
                if v.DesRoleId ~= roleId then 
                    table.insert(results,v)
                end
            end
        end
        self._ChatMessageList[game._HostPlayer._ID] = results
        self._CurChatMsgListData[roleId] = nil
       	self._UnreadMsgList[roleId] = nil
       	CPageFriendChat.Instance():ShowRedPoint(nil)
        self:SendProtocol("C2SSocialOperation",{{roleId},SOCIAL_OPT_TYPE.ContactsOut})
        if not isUpdate then return end
        CPageFriendChat.Instance():UpdateDeleteChatItem()
    end 
    local title, str, closeType = StringTable.GetMsg(13)
    MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback) 
end

-- 系统通知消息
def.method("string").AddFriendSystemNotifyMsg = function(self,msgText)
    -- 系统通知角色id 设为-1 
    local sendInfo = 
    {
        Id = -1,
        Name = StringTable.Get(30336)
    }
    local message = 
    {
        chatType = ChatType.ChatTypeNormal,
        senderInfo = sendInfo,
        text = msgText,
        voice = nil,
        time = GameUtil.GetServerTime(),
        voiceLength = 0,
        itemInfo = nil ,
    }
    local roleData = {
                        RoleId = -1,
                        Name = StringTable.Get(30336),
                        OptTime = GameUtil.GetServerTime()
                    }
    InserRecentContactByRoleData(self,roleData,true)
    AddUnreadMsg(self,message)
    AddMsg(self,game._HostPlayer._ID,sendInfo,ChatType.ChatTypeNormal,msgText,GameUtil.GetServerTime(),nil,false,nil,true)
end
---------------------------------------------------------------------------------
--------------------------服务器相关通讯-client to server-------------------------
---------------------------------------------------------------------------------

--一键清除申请列表
def.method().DoClearApplyList = function(self)
    self:SendProtocol("C2SSocialClearApplyList", nil)
end

--同意申请(单独或是一键全部同意)
def.method("table").DoAgreeApply = function(self, data)
	if #data == 1 then 
    	if self:IsFriendNumberOverMax() or self:IsFriend(data[1]) then return end
	end
    self:SendProtocol("C2SSocialOperation", {data, SOCIAL_OPT_TYPE.Agree})
end

--拒绝申请(单独或是一键拒绝)
def.method("table").DoRejectApply = function(self,data)
	if #data == 1 then 
    	if self:IsFriend(data[1]) then return end
    end
    self:SendProtocol("C2SSocialOperation", {data, SOCIAL_OPT_TYPE.Refused})
end

--搜索好友
def.method("string").DoSearch = function(self, text)
    self:SendProtocol("C2SSocialSearch", text)
end

--请求推荐好友
def.method().DoRcommond = function (self)
	self:SendProtocol("C2SSocialRecommend",nil)
end

--申请好友(好友界面)
def.method("dynamic").DoFriendApply = function(self, data)
    if self:IsFriendNumberOverMax() then return end
    if type(data)  == "number" then 
        if self._ApplyListToElse[data] ~= nil then 
            if GameUtil.GetServerTime() - self._ApplyListToElse[data] < self._MinApplyInterval *1000 then 
                self._ApplyListToElse[data] = GameUtil.GetServerTime()
                game._GUIMan:ShowTipText(StringTable.Get(30309),false)
            return end
        end
        self._ApplyListToElse[data] = GameUtil.GetServerTime()
        self:SendProtocol("C2SSocialOperation", {{data}, SOCIAL_OPT_TYPE.Apply})
    elseif type(data)  == "table" then
        local ids = {}
        for i,v in ipairs(data) do
            if self._ApplyListToElse[v.RoleId] ~= nil then 
                if GameUtil.GetServerTime() - self._ApplyListToElse[v.RoleId] >= self._MinApplyInterval *1000 then 
                    table.insert(ids,v.RoleId)
                end
            else
                table.insert(ids,v.RoleId)
            end
        end
        self:SendProtocol("C2SSocialOperation", {ids, SOCIAL_OPT_TYPE.Apply})
    end
end

-- 申请好友(外部)
def.method("number").DoApply = function(self, role_id)
    if self:IsFriendNumberOverMax() then return end
    if self:IsInBlackList(role_id) then 
        local function callback(value)
            if not value then
                return
            else
                self:RemoveBlackListByRoleId(role_id)
                self:DoFriendApply(role_id)  
                return
            end
        end
   
        local title, str, closeType = StringTable.GetMsg(49)
        MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback) 
    else
       self:DoFriendApply(role_id) 
    end
end

--删除好友
def.method("number").DoDeleteFriend = function (self,role_id)
    local function callback( value )
        if not value then return end
        self:SendProtocol("C2SSocialOperation", {{role_id}, SOCIAL_OPT_TYPE.Delete})
        -- body
    end
    local title, str, closeType = StringTable.GetMsg(116)
    MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback) 
end

-- 添加到黑名单
def.method("number").DoAddBlackList = function (self,roleId)
	if #self._BlackList >= self._MaxBlackListNum then 
		game._GUIMan:ShowTipText(StringTable.Get(30323),false)
		return
	end
    local function callback(value)
        if not value then return end
        self:SendProtocol("C2SSocialOperation", {{roleId}, SOCIAL_OPT_TYPE.BlackIn})
    end
    local title, str, closeType = StringTable.GetMsg(100)
    MsgBox.ShowMsgBox(str,title, closeType, MsgBoxType.MBBT_OKCANCEL,callback) 
end

-- 移除黑名单
def.method("dynamic").DoOutBlackList = function (self,roleId)
    if type(roleId) == "number" then 
        self:SendProtocol("C2SSocialOperation", {{roleId}, SOCIAL_OPT_TYPE.BlackOut})
    elseif type(roleId) == "table" then 
        self:SendProtocol("C2SSocialOperation", {roleId, SOCIAL_OPT_TYPE.BlackOut})
    end
end


--修改编辑分组名
def.method("string","number").EditGroupName = function(self,groupName,editGroupId)
    self:SendProtocol("C2SSocialGroupOpt", {GROUP_EDIT_TYPE.GroupName, groupName,editGroupId})
end

-- 增加分组
def.method("string").DoAddGroup = function (self,groupName)
    self:SendProtocol("C2SSocialGroupOpt", {GROUP_EDIT_TYPE.GroupAdd, groupName,0})
end

-- 删除分组
def.method("number").DoDeleteGroup = function (self,groupId)
    self:SendProtocol("C2SSocialGroupOpt", {GROUP_EDIT_TYPE.GroupDelete, "",groupId})
end

-- 编辑分组(GroupId 目标组id)
def.method("number","number","number").DoEditGroup = function (self,roleId,fromGroupId,toGroupId)
    self:SendProtocol("C2SSocialEditGroup", {roleId,fromGroupId,toGroupId})
end

--给角色发送文本消息
def.method("table", "string").DoSendText = function(self, roleData, txt)
    if string.len(txt) <= 0 then
        game._GUIMan: ShowTipText(StringTable.Get(13019),true)
        return
    end
    if IsMsgOverMaxChars(self,txt) then return end
    if self:IsInBlackList(roleData.RoleId) then game._GUIMan:ShowTipText(StringTable.Get(30333),false) return end

    local FilterMgr = require "Utility.BadWordsFilter".Filter
    txt = FilterMgr.FilterChat(txt)
    self._DesRoleData = {}
    self._DesRoleData = {RoleId = roleData.RoleId, Name = roleData.Name, Profession = roleData.Profession,
                        Gender = roleData.Gender, Level = roleData.Level, GroupId = roleData.GroupId,
                        SocialType = roleData.SocialType, Amicability = roleData.Amicability, Fight = roleData.Fight,
                        OptTime = roleData.OptTime, IsOnLine = roleData.IsOnLine,CustomImgSet = roleData.CustomImgSet,
                        LogoutTime = roleData.LogoutTime ,
                    }
    self:SendProtocol("C2SSocialChat", {roleData.RoleId,ChatType.ChatTypeNormal,ChatChannel.ChatChannelSocial, txt})
end

--给角色发送语音消息
def.method("table", "string","number").DoSendVoice = function(self, roleData, voice , seconds)
    
    if not IsValidVoice(voice) then return end
    if self:IsInBlackList(roleData.RoleId) then game._GUIMan:ShowTipText(StringTable.Get(30333),false) return end
    self._DesRoleData = {}
    self._DesRoleData = {RoleId = roleData.RoleId, Name = roleData.Name, Profession = roleData.Profession,
                        Gender = roleData.Gender, Level = roleData.Level, GroupId = roleData.GroupId,
                        SocialType = roleData.SocialType, Amicability = roleData.Amicability, Fight = roleData.Fight,
                        OptTime = roleData.OptTime, IsOnLine = roleData.IsOnLine,CustomImgSet = roleData.CustomImgSet}
    self:SendProtocol("C2SSocialChat", {roleData.RoleId,ChatType.ChatTypeVoice,ChatChannel.ChatChannelSocial,"", voice, 0, 0, nil,seconds})
end

--发送物品连接
def.method("table","string","table").DoSendItemLink = function(self,roleData,strMsg,itemInfo)
    if self:IsInBlackList(roleData.RoleId) then game._GUIMan:ShowTipText(StringTable.Get(30333),false) return end
    self._DesRoleData = {}
    self._DesRoleData = {RoleId = roleData.RoleId, Name = roleData.Name, Profession = roleData.Profession,
                        Gender = roleData.Gender, Level = roleData.Level, GroupId = roleData.GroupId,
                        SocialType = roleData.SocialType, Amicability = roleData.Amicability, Fight = roleData.Fight,
                        OptTime = roleData.OptTime, IsOnLine = roleData.IsOnLine,CustomImgSet = roleData.CustomImgSet}
    local bagType = BagType.BACKPACK
    if itemInfo._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then
        bagType = BagType.ROLE_EQUIP
    end
    self:SendProtocol("C2SSocialChat", {roleData.RoleId,ChatType.ChatTypeItemInfo,ChatChannel.ChatChannelSocial,strMsg, "", itemInfo._Slot, bagType, nil,nil})
end

def.method("string", "dynamic").SendProtocol = function(self, protocol_name, param)
    -- warn(protocol_name.." sended. Params:")
    local prot = GetC2SProtocol(protocol_name)
    if protocol_name == "C2SSocialSearch" then
        prot.IDorName = param
    elseif protocol_name == "C2SSocialClearApplyList" then
        prot.SocialType = SOCIAL_TYPE.Friends
    elseif protocol_name == "C2SSocialOperation" then
       for i,v in ipairs(param[1]) do
           table.insert(prot.RoleIds,v)
       end
        prot.OptType = param[2]
        prot.SocialType = SOCIAL_TYPE.Friends
    elseif protocol_name == "C2SSocialGroupOpt" then
    	prot.GroupEditType = param[1]
        prot.Name = param[2]
        prot.GroupId = param[3]
    elseif protocol_name == "C2SSocialEditGroup" then
        prot.RoleId = param[1]
        prot.FromGroupId = param[2]
        prot.ToGroupId = param[3]
    elseif protocol_name == "C2SSocialRecommend" then
    -- 默认推荐6个
    	prot.count = 6
    elseif protocol_name == "C2SSocialChat" then
        prot.DesRoleId = param[1]
        if param[2] then
            prot.chatType = param[2]
        end
        if param[3] then
            prot.chatChannel = param[3]
        end
        if param[4] then
            prot.text = param[4]
        end
        if param[5] then 
            prot.voice = param[5]
        end
        if param[6] then 
            prot.Index = param[6]
        end
        if param[7] then 
            prot.bgType = param[7]
        end
        if param[8] then 
            prot.chatType = param[8]
        end
        if param[9] then 
            prot.voiceLength = param[9]
        end
    end 
    SendProtocol(prot)
end

-- 私聊按钮接口 (陌生人添加需要发送消息)
def.method("number").AddChat = function (self,roleId)
	local roleData = GetFriendByRoleId(self,roleId)
	if roleData == nil then 
		self:SendProtocol("C2SSocialOperation",{{roleId},SOCIAL_OPT_TYPE.ContactsIn})
	else
 		InserRecentContactByRoleData(self,roleData,false)
        game._GUIMan:Open("CPanelChatNew",{IsOpenFriendChat = true,RoleData = roleData})
	end
    game._GUIMan:Close("CPanelFriend")
end

-- 移除最近联系人 
def.method("number").RemoveRecentContact = function (self,roleId)
    self:DeleteMsgsAndRecentByRoleId(roleId,false)
end

---------------------------------------------------------------------------------
--------------------------服务器相关通讯-server to client-------------------------
---------------------------------------------------------------------------------
--进游戏返回好友列表
def.method("table").OnSocialInfo = function(self, data)
    GetUserData(self)
    self._FriendList = data.Info.Friends or {}
    self._BlackList = data.Info.Blacks or {}
    GetOffLineMsg(self,data.Info.Contents)
    --红点
    self._ApplyList = data.Info.Applys or {}
    if #self._ApplyList > 0 then 
        local data = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Friends)
        if data == nil then
            data = {}
        end
        data.IsShowApplyRed = true
        CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Friends,data)
    end
    CPanelFriend.Instance():ShowChatFriendRed()
    self._RecentList = data.Info.ContactRoles or {}
    self._IsFriendModuleReady = true
end

--玩家主动操作,服务器返回申请（我对他人的申请）、批准(包括批量统一，添加好友 更新好友列表 更新申请列表)、删除(删除好友 更新好友列表 更新通讯录或是最近联系人) 拒绝（刷新申请列表） 好友 信息
--加入黑名单
-- 添加陌生人到最近联系人  移除最近联系人
def.method("table").OnS2CSocialOperation = function(self, data)
    local content = nil
    local role = nil
    if data.OptType == SOCIAL_OPT_TYPE.Apply then 
        game._GUIMan:ShowTipText(StringTable.Get(30338), false)
    elseif data.OptType == SOCIAL_OPT_TYPE.Agree then  
    	if #data.Roles  == 1 then 
    		-- todo 错误码
        	content = StringTable.Get(30302)
		    for i,v in ipairs(self._ApplyList) do
	            if v.RoleId == data.Roles[1].RoleId then
	                table.remove(self._ApplyList, i)
                    v.Amicability = data.Roles[1].Amicability
                	table.insert(self._FriendList, v)
                    DeleteIDFromRemovedTable(self,v.RoleId)
	                break
	            end
	        end
            self._RecentList = UpdateMemberAmicability(self,data.Roles[1],self._RecentList)
        	game._GUIMan:ShowTipText(content, false)
        elseif #data.Roles > 1  then  
        	for j ,w in ipairs(data.Roles) do
	        	for i,v in ipairs(self._ApplyList) do
	        		if w.RoleId == v.RoleId then
		                table.remove(self._ApplyList, i)
                        v.Amicability = data.Roles[1].Amicability
	                	table.insert(self._FriendList, v)
                        DeleteIDFromRemovedTable(self,v.RoleId)
	                	break
		            end
		        end
               self._RecentList = UpdateMemberAmicability(self,w,self._RecentList)
		    end
        end

        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.APPLY)
       	-- 更新通讯录
       	CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.FRIENDLIST)
    elseif data.OptType == SOCIAL_OPT_TYPE.Delete then  
        for i,v in ipairs(self._FriendList) do
            if v.RoleId == data.Roles[1].RoleId then
                table.remove(self._FriendList, i)
                break
            end
        end
      	-- 更新通讯录
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.FRIENDLIST)
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.BLACKLIST)
        -- CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.RECENTCONTACTS)
    elseif data.OptType == SOCIAL_OPT_TYPE.Refused then
    	if #data.Roles  == 1 then 
		    for i,v in ipairs(self._ApplyList) do
	            if v.RoleId == data.Roles[1].RoleId then
	                table.remove(self._ApplyList, i)
	                break
	            end
	        end
        elseif #data.Roles > 1 and data.ErrorCode == 0 then 
        	for j ,w in ipairs(data.Roles) do
	        	for i,v in ipairs(self._ApplyList) do
	        		if w.RoleId == v.RoleId then
		                table.remove(self._ApplyList, i)
		                break
		            end
		        end
		    end
        end
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.APPLY) 
    elseif data.OptType == SOCIAL_OPT_TYPE.BlackIn then 
    	table.insert(self._BlackList,data.Roles[1])
    	RemoveRecentContactByRoleId(self,data.Roles[1].RoleId)
        CPageFriendChat.Instance():UpdateRecentList()
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.BLACKLIST) 
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.FRIENDLIST) 
    elseif data.OptType == SOCIAL_OPT_TYPE.BlackOut then 
        if #data.Roles == 1 then
        	for i,v in ipairs(self._BlackList) do
        		if v.RoleId == data.Roles[1].RoleId then
        			table.remove(self._BlackList,i)
        			break
        		end
        	end
        else 
            -- 一键解除所有屏蔽
            self._BlackList = {}
        end
        game._GUIMan:ShowTipText(StringTable.Get(30353),false)
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.BLACKLIST) 
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.FRIENDLIST) 
	elseif data.OptType == SOCIAL_OPT_TYPE.ContactsIn then 
		if data.ErrorCode == 0 then
			-- 和陌生人私聊开启对话界面
			InserRecentContactByRoleData(self,data.Roles[1],false)
            if not CPanelChatNew.Instance():IsShow() then 
                game._GUIMan:Open("CPanelChatNew",{IsOpenFriendChat = true,RoleData = data.Roles[1]})
            else
                CPanelChatNew.Instance():OpenFriendChat(data.Roles[1])
            end
		end
	elseif data.OptType == SOCIAL_OPT_TYPE.ContactsOut then 
		if data.ErrorCode == 0 then
			RemoveRecentContactByRoleId(self,data.Roles[1].RoleId)
            CPageFriendChat.Instance():UpdateRecentList()
            AddIDToRemovedTable(self,data.Roles[1].RoleId)
		end
    elseif data.OptType == SOCIAL_OPT_TYPE.Amicability then 
        self._RecentList = UpdateMemberAmicability(self,data.Roles[1],self._RecentList)
        self._FriendList = UpdateMemberAmicability(self,data.Roles[1],self._FriendList)
    end
end

--服务器推送 玩家被 申请(别人对我的申请，更新申请列表)、批准(添加好友 更新好友列表，更新通讯录)、删除(删除好友 更新好友列表 最近联系人列表和通讯录)的信息
def.method("table").OnS2CSocialSyncData = function(self, data)
    if data.OptType == SOCIAL_OPT_TYPE.Apply then   
    	if self:IsInBlackList(data.Player.RoleId) then return end

        if #self._ApplyList == 0 then
            table.insert(self._ApplyList,data.Player)
        else
            local count = #self._ApplyList
            for i = 1, count do
                local friend = self._ApplyList[i]
                if friend.RoleId == data.Player.RoleId then
                	self._ApplyList[i].OptTime = data.Player.OptTime
                	return
                end
            end
        	table.insert(self._ApplyList,data.Player)
        end  
        -- 红点
        if CPanelFriend.Instance()._CurTogglePage ~= CPanelFriend.OpenPageType.APPLY then 
            local data = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Friends) or {}
            data.IsShowApplyRed = true
            CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Friends,data)
            if not CPanelFriend.Instance():IsShow() then 
                CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Friends,true)
            else
                CPanelFriend.Instance():ShowRedApply()
            end
        else
           CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.APPLY)
        end
        
    elseif data.OptType == SOCIAL_OPT_TYPE.Agree then 
        if not self:IsFriend(data.Player.RoleId) then
        	table.insert(self._FriendList, data.Player)
            DeleteIDFromRemovedTable(self,data.Player.RoleId)
        end

        if self._ApplyListToElse ~= nil then 
            if self._ApplyListToElse[data.Player.RoleId] ~= nil then 
                self._ApplyListToElse[data.Player.RoleId] = nil  
            end  
        end
       
        self._RecentList = UpdateMemberAmicability(self,data.Player,self._RecentList)
        game._GUIMan:ShowTipText(string.format(StringTable.Get(30331),data.Player.Name),false)
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.FRIENDLIST)
    elseif data.OptType == SOCIAL_OPT_TYPE.Delete then 
    	if #self._FriendList == 0 then return end
    	for i,v in ipairs(self._FriendList) do
    		if v.RoleId == data.Player.RoleId then 
    			table.remove(self._FriendList,i)
    			break
    		end
    	end
        game._GUIMan:ShowTipText(string.format(StringTable.Get(30335),data.Player.Name),false)
    	-- 更新通讯录 判断更新黑名单里的成员关系状态
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.FRIENDLIST)
        CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.BLACKLIST)
    elseif data.OptType == SOCIAL_OPT_TYPE.Refused then
        game._GUIMan:ShowTipText(string.format(StringTable.Get(30332),data.Player.Name),false)
    elseif data.OptType == SOCIAL_OPT_TYPE.Amicability then 
        if data.Roles ~= nil then
            self._RecentList = UpdateMemberAmicability(self,data.Roles[1],self._RecentList)
            self._FriendList = UpdateMemberAmicability(self,data.Roles[1],self._FriendList)
        else
            warn("data.Roles is nil")
        end
    end        
end

--推送好友
def.method("table").OnS2CSocialRecommend = function (self,data)
	self._RecommondList = data.Players
	CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.INQUIRE)
end

--搜索结果
def.method("table").OnS2CSocialSearch = function(self, data)
    if data.ResCode == 0 then 
        self._SearchResult = data.Player
    end
    CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.INQUIRE)
    if CPanelCreateChat.Instance():IsShow() then 
        if data.ResCode == 0 then 
            self:AddChat(data.Player.RoleId)
            game._GUIMan:Close("CPanelCreateChat")
        else
            game._GUIMan:ShowTipText(StringTable.Get(30348),false)
        end
    end
end

--一键申请列表清除
def.method().OnS2CSocialClearApplyList = function(self)
    self._ApplyList = {}
    CPanelFriend.Instance():UpdatePageShow(CPanelFriend.OpenPageType.APPLY)
end

--好友上下线提示
def.method("table").OnSocialOOLine = function(self, data)
	local LineType = data.OOType
    local IsOnLine = false
	if LineType == SOCIAL_OO_TYPE.OnLine then
		IsOnLine = true
	end 
   	UpdateOnlineState(self._RecentList,data.RoleId,IsOnLine,data.LogoutTime)	
   	UpdateOnlineState(self._BlackList,data.RoleId,IsOnLine,data.LogoutTime) 
    UpdateOnlineState(self._FriendList,data.RoleId,IsOnLine,data.LogoutTime)
end

--收取单条消息
def.method("table").OnS2CSocialChat = function (self,data)
    local Content = data.Content 
    local senderId = Content.senderInfo.Id 
    if senderId ~= game._HostPlayer._ID then
        -- warn("------ReceiveMessage------ ",Content.text)
        ReceiveMessage(self,Content)
    else
        HostPlayerSendMsg(self,Content,data.DesRoleId)
    end
end

def.method("table").OnS2CSocialUpdateInfo = function(self,data)
    for _,player in ipairs(data.Players) do 
        for _,friend in ipairs(self._FriendList) do
            if friend.RoleId  == player.RoleId then 
                -- warn("player.UsedAssistCount  ",player.UsedAssistCount)
                    friend.UsedAssistCount = player.UsedAssistCount
                break
            end
        end
    end
    if #self._FightMirrorData == 0 then return end
    for _,player in ipairs(data.Players) do 
        for _,Mirror in ipairs(self._FightMirrorData) do
            if Mirror.RoleId  == player.RoleId then 
                -- warn("player.UsedAssistCount  ",player.UsedAssistCount)
                    Mirror.UsedAssistCount = player.UsedAssistCount
                break
            end
        end
    end
end

def.method("table").OnS2CSocialBroadCastChange = function(self,data)
    if #self._FriendList > 0  then 
        for i,friend in ipairs(self._FriendList) do 
            if friend.RoleId == data.RoleId then 
                friend.MapInfo.mapTemplateId = data.MapInfo.mapTemplateId
                friend.MapInfo.LineId = data.MapInfo.LineId
                friend.Name = data.Name
                friend.Level = data.Level
                friend.CustomImgSet = data.CustomImgSet
                friend.Fight = data.FightScore
            break end
        end
    end
    if #self._RecentList > 0  then 
        for i,recent in ipairs(self._RecentList) do 
            if recent.RoleId == data.RoleId then 
            	if recent.MapInfo ~= nil then 
	                recent.MapInfo.mapTemplateId = data.MapInfo.mapTemplateId
	                recent.MapInfo.LineId = data.MapInfo.LineId
	            end
                recent.Name = data.Name
                recent.Level = data.Level
                recent.CustomImgSet = data.CustomImgSet
                recent.Fight = data.FightScore
            break end
        end
    end
end

def.method("table").OnS2CSocialInfoMirrorFriend = function(self,data)
    self._FightMirrorData = data.MirrorFriends
end

CFriendMan.Commit()
return CFriendMan