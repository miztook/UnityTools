local PBHelper = require "Network.PBHelper"
local CFriendMan = require "Main.CFriendMan"

--进游戏获取好友列表
local function OnS2CSocialInfo(sender, protocol)
    -- warn("OnS2CSocialInfo call.")
    CFriendMan.Instance():Init()
    CFriendMan.Instance():OnSocialInfo(protocol)
end
PBHelper.AddHandler("S2CSocialInfo", OnS2CSocialInfo)

--申请,批准，删除
local function OnS2CSocialOperation(sender, protocol)
    -- warn("OnS2CSocialOperation call.")
    if protocol.ErrorCode ~= 0 then
        game._GUIMan:ShowTipText(StringTable.Get(protocol.OptType + 19126),false)
        return
    end
    CFriendMan.Instance():OnS2CSocialOperation(protocol)
end
PBHelper.AddHandler("S2CSocialOperation", OnS2CSocialOperation)

--被申请,批准，删除
local function OnS2CSocialSyncData(sender, protocol)
    -- warn("OnS2CSocialSyncData call.".."OptType="..protocol.OptType)
    CFriendMan.Instance():OnS2CSocialSyncData(protocol)
end
PBHelper.AddHandler("S2CSocialSyncData", OnS2CSocialSyncData)

--一键清除
local function OnS2CSocialClearApplyList(sender, protocol)
    -- warn("OnS2CSocialClearApplyList call.")
    if protocol.ErrorCode ~= 0 then
        game._GUIMan:ShowTipText(StringTable.Get(19114),false)
        return
    end
    CFriendMan.Instance():OnS2CSocialClearApplyList()
end
PBHelper.AddHandler("S2CSocialClearApplyList", OnS2CSocialClearApplyList)

--搜索玩家
local function OnS2CSocialSearch(sender, protocol)
    -- warn("OnS2CSocialSearch call.")
    CFriendMan.Instance():OnS2CSocialSearch(protocol)
end
PBHelper.AddHandler("S2CSocialSearch", OnS2CSocialSearch)

--编辑分组
local function OnS2CSocialGroupName(sender, protocol)
    -- warn("OnS2CSocialGroupName call.")
    if protocol.ErrorCode ~= 0 then
        game._GUIMan:ShowTipText(StringTable.Get(19124),false)
        return
    end
    CFriendMan.Instance():OnS2CSocialGroupName(protocol)
end
PBHelper.AddHandler("S2CSocialGroupName", OnS2CSocialGroupName)

--好友分组
local function OnS2CSocialEditGroup(sender, protocol)
    -- warn("OnS2CSocialEditGroup call.")
    if protocol.ErrorCode ~= 0 then
        game._GUIMan:ShowTipText(StringTable.Get(19125),false)
        return
    end
    CFriendMan.Instance():OnS2CSocialEditGroup(protocol)
end
PBHelper.AddHandler("S2CSocialEditGroup", OnS2CSocialEditGroup)

--上下线提示
local function OnS2CSocialOOLine(sender, protocol)
    CFriendMan.Instance():OnSocialOOLine(protocol)
end
PBHelper.AddHandler("S2CSocialOOLine", OnS2CSocialOOLine)

--私聊
local function OnS2CSocialChat(sender, protocol)
    -- warn("OnS2CSocialChat call.")
    CFriendMan.Instance():OnS2CSocialChat(protocol)
end
PBHelper.AddHandler("S2CSocialChat", OnS2CSocialChat)
--读消息
local function OnS2CSocialGetChats(sender, protocol)
    -- warn("OnS2CSocialGetChats call.")
    CFriendMan.Instance():OnS2CSocialGetChats(protocol.Contents)
end
PBHelper.AddHandler("S2CSocialGetChats", OnS2CSocialGetChats)

--未读消息推送
local function OnS2CSocialChatNotify(sender, protocol)
    -- warn("OnS2CSocialChatNotify call.")
    CFriendMan.Instance():OnS2CSocialChatNotify(protocol)
end
PBHelper.AddHandler("S2CSocialChatNotify", OnS2CSocialChatNotify)