local PBHelper = require "Network.PBHelper"

local function OnReceiveExp(sender, protocol)
	game._HostPlayer:OnReceiveExp(protocol.Offset, protocol.CurrentExp, protocol.CurrentParagonExp)

    --[[   取消获得经验提示
    local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
	local ChatManager = require "Chat.ChatManager"
    local msg = string.format(StringTable.Get(13032), StringTable.Get(410), GUITools.FormatMoney(protocol.Offset))
    if msg ~= nil then
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
    end
    ]]
end

PBHelper.AddHandler("S2CReceiveExp", OnReceiveExp)
