local PBHelper = require "Network.PBHelper"
local CElementData = require"Data.CElementData"

-- 错误码
local function ErrorTip(ErrorCode)
    game._GUIMan:ShowErrorTipText(ErrorCode)
end

--进游戏获取模拟5职业数据用于好友助战
local function OnS2CSocialInfoMirrorFriend(sender, protocol)
    game._CFriendMan:OnS2CSocialInfoMirrorFriend(protocol)
end
PBHelper.AddHandler("S2CSocialInfoMirrorFriend", OnS2CSocialInfoMirrorFriend)

--进游戏获取好友列表
local function OnS2CSocialInfo(sender, protocol)
    -- warn("OnS2CSocialInfo call.")
    game._CFriendMan:OnSocialInfo(protocol)
end
PBHelper.AddHandler("S2CSocialInfo", OnS2CSocialInfo)

--申请,批准，删除
local function OnS2CSocialOperation(sender, protocol)
    if protocol.ErrorCode == 0 then 
        game._CFriendMan:OnS2CSocialOperation(protocol)
    else
        ErrorTip(protocol.ErrorCode)
    end
end
PBHelper.AddHandler("S2CSocialOperation", OnS2CSocialOperation)

--被申请,批准，删除
local function OnS2CSocialSyncData(sender, protocol)
    -- warn("OnS2CSocialSyncData call.".."OptType="..protocol.OptType)
    game._CFriendMan:OnS2CSocialSyncData(protocol)
end
PBHelper.AddHandler("S2CSocialSyncData", OnS2CSocialSyncData)

--一键清除
local function OnS2CSocialClearApplyList(sender, protocol)
    -- warn("OnS2CSocialClearApplyList call.")
    if protocol.ErrorCode ~= 0 then
        ErrorTip(protocol.ErrorCode)
        return
    end
    game._CFriendMan:OnS2CSocialClearApplyList()
end
PBHelper.AddHandler("S2CSocialClearApplyList", OnS2CSocialClearApplyList)

--搜索玩家
local function OnS2CSocialSearch(sender, protocol)
    game._CFriendMan:OnS2CSocialSearch(protocol)
end
PBHelper.AddHandler("S2CSocialSearch", OnS2CSocialSearch)

-- 推荐玩家
local function OnS2CSocialRecommend(sender, protocol)
    -- warn("OnS2CSocialSearch call.")
    game._CFriendMan:OnS2CSocialRecommend(protocol)
end
PBHelper.AddHandler("S2CSocialRecommend", OnS2CSocialRecommend)

-- -- 针对组
-- local function OnS2CSocialGroupOpt(sender, protocol)

--     if protocol.ErrorCode ~= 0 then
--         ErrorTip(protocol.ErrorCode)
--         return
--     end
--     game._CFriendMan:OnS2CSocialGroupOpt(protocol)

-- end
-- PBHelper.AddHandler("S2CSocialGroupOpt", OnS2CSocialGroupOpt)

-- --好友分组(组员)
-- local function OnS2CSocialEditGroup(sender, protocol)
--     if protocol.ErrorCode == 0 then
--         game._CFriendMan:OnS2CSocialEditGroup(protocol)
--         return
--     end
--     ErrorTip(protocol.ErrorCode)
-- end
-- PBHelper.AddHandler("S2CSocialEditGroup", OnS2CSocialEditGroup)

--上下线提示
local function OnS2CSocialOOLine(sender, protocol)
    game._CFriendMan:OnSocialOOLine(protocol)
end
PBHelper.AddHandler("S2CSocialOOLine", OnS2CSocialOOLine)

--私聊
local function OnS2CSocialChat(sender, protocol)
    -- warn("OnS2CSocialChat call.")
    game._CFriendMan:OnS2CSocialChat(protocol)
end

PBHelper.AddHandler("S2CSocialChat", OnS2CSocialChat)

--更新好友助战使用次数
local function OnS2CSocialUpdateInfo(sender,protocol)
-- warn("----------------OnS2CSocialUpdateInfo -------")
    game._CFriendMan:OnS2CSocialUpdateInfo(protocol)
end
PBHelper.AddHandler("S2CSocialUpdateInfo", OnS2CSocialUpdateInfo)

local function OnS2CSocialBroadCastChange(sender,protocol)
-- warn("----------------OnS2CSocialUpdateInfo -------")
    game._CFriendMan:OnS2CSocialBroadCastChange(protocol)
end
PBHelper.AddHandler("S2CSocialBroadCastChange", OnS2CSocialBroadCastChange)
