------------------------------
----------S2CItemMachining
---------------------------------

local PBHelper = require "Network.PBHelper"
local data = require "PB.data"
local net = require "PB.net"

local function OnS2CItemMachining(sender, msg)
	if msg.ErrorCode == data.ServerMessageId.Success then
		local EMachingType = net.EMachingType
		if msg.MachingType == EMachingType.EMachingType_Guild then
			local CPanelUIGuildSmithy = require "GUI.CPanelUIGuildSmithy"
			CPanelUIGuildSmithy.Instance():ForgeSuccCallBack()
		end
	else
		error("ItemMaching fail, ItemMachingID : " .. msg.ItemMachiningId .. ", msg.ErrorCode == " .. msg.ErrorCode)
	end
end
PBHelper.AddHandler("S2CItemMachining", OnS2CItemMachining)