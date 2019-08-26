------------------------------
----------S2CItemMachining  lidaming
---------------------------------

local PBHelper = require "Network.PBHelper"
local data = require "PB.data"
local net = require "PB.net"
local RewardType = require"PB.data".RewardType

local function OnS2CItemMachining(sender, msg)
	local isSucceed = true
	if msg.ErrorCode ~= data.ServerMessageBase.Success then
		isSucceed = false
		-- warn("lidaming --->>> ItemMachingID : " .. msg.ItemMachiningId .. ", msg.ErrorCode == " .. msg.ErrorCode..",msg.Slot ==".. msg.Slot)
		game._GUIMan:ShowErrorTipText(msg.ErrorCode)
	end

	local EMachingType = net.EMachingType
	if msg.MachingType == EMachingType.EMachingType_Guild then
		local CPanelUIGuildSmithy = require "GUI.CPanelUIGuildSmithy"
		if CPanelUIGuildSmithy and CPanelUIGuildSmithy.Instance():IsShow() then
			CPanelUIGuildSmithy.Instance():ForgeCallBack(msg.GuildMachiningItem, isSucceed)
		end

		if isSucceed then
			local CPanelUIGuild = require "GUI.CPanelUIGuild"
			if CPanelUIGuild and CPanelUIGuild.Instance():IsShow() then
				CPanelUIGuild.Instance():UpdateRedPoint()
			end
		end
	end
	local EMachingOptType = require "PB.net".EMachingOptType
	if msg.MachingOptType == EMachingOptType.EMachingOptType_Decompose then
		-- warn("lidaming ------------S2CItemMachining-------------->>> ", #msg.Items, #msg.Moneys)
		local RewardParams = {}
		for i,v in ipairs(msg.Items) do
			warn("vvvvvvvvvvvvvvvvvv====>>>", v.Tid, v.Count)
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
end
PBHelper.AddHandler("S2CItemMachining", OnS2CItemMachining)