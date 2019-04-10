local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local net = require "PB.net"
local function OnS2CItemMachiningBatch(sender, msg)
	
	CPanelRoleInfo.Instance():S2CDecItem(msg.ErrorCode)
	-- warn("lidaming ------------S2CItemMachining-------------->>> ", #msg.RewardInfos)
	local ChatManager = require "Chat.ChatManager"
	ChatManager.Instance():ChatSendRewardInfos(msg.RewardInfos)
end

PBHelper.AddHandler("S2CItemMachiningBatch", OnS2CItemMachiningBatch)

local function OnS2CItemSell(sender, msg)
 --    local CPanelBatchOperation = require"GUI.CPanelBatchOperation"
	-- if CPanelBatchOperation.Instance():IsShow() then 
	-- 	CPanelBatchOperation.Instance():S2CSell(msg.result)
	-- end
end
PBHelper.AddHandler("S2CItemSell", OnS2CItemSell)
