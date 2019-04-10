local PBHelper = require "Network.PBHelper"
-- local CPanelArenaEnter = require"GUI.CPanelArenaEnter"
-- local CPanelMirrorArena = require"GUI.CPanelMirrorArena"

local function OnS2CReputationView(sender,msg)
	game._CReputationMan:OnS2CReputationView(msg)
end
PBHelper.AddHandler("S2CReputationView", OnS2CReputationView)

local function OnS2CReputationChange(sender,msg)
	game._CReputationMan:OnS2CReputationChange(msg.ReputationInfo)
	if msg.TotalExp > 0 then
		local CElementData = require "Data.CElementData"
		local reputationTemp = CElementData.GetTemplate("Reputation", msg.ReputationInfo.ReputationID)
		local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
		local ChatManager = require "Chat.ChatManager"
		local msg = string.format(StringTable.Get(13032), string.format(StringTable.Get(31016),reputationTemp.Name), GUITools.FormatMoney(msg.TotalExp))
		if msg ~= nil then
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
		end
	end
end
PBHelper.AddHandler("S2CReputationChange", OnS2CReputationChange)