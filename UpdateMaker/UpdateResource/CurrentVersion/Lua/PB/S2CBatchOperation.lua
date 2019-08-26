local PBHelper = require "Network.PBHelper"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local net = require "PB.net"
local RewardType = require"PB.data".RewardType

local function OnS2CItemMachiningBatch(sender, msg)
	
	CPanelRoleInfo.Instance():S2CDecItem(msg.ErrorCode)
	-- warn("lidaming ------------S2CItemMachining-------------->>> ", #msg.Items, #msg.Moneys)
	local RewardParams = {}
	for i,v in ipairs(msg.Items) do
		RewardParams[#RewardParams + 1] = 
		{
			Type = RewardType.Item,
			Items = v,
		}
	end

	for i,v in ipairs(msg.Moneys) do
		RewardParams[#RewardParams + 1] = 
		{
			Type = RewardType.Resource,
			Id = v.MoneyId,
			Num = v.Count,
		}
	end

	local ChatManager = require "Chat.ChatManager"
	ChatManager.Instance():ChatSendRewardInfos(RewardParams)
end

PBHelper.AddHandler("S2CItemMachiningBatch", OnS2CItemMachiningBatch)

local function OnS2CItemSell(sender, msg)
 --    local CPanelBatchOperation = require"GUI.CPanelBatchOperation"
	-- if CPanelBatchOperation.Instance():IsShow() then 
	-- 	CPanelBatchOperation.Instance():S2CSell(msg.result)
	-- end
end
PBHelper.AddHandler("S2CItemSell", OnS2CItemSell)
