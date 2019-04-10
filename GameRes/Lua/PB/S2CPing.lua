--
-- S2CInventoryInfo
--

local PBHelper = require "Network.PBHelper"

local function OnPing(sender, protocol)	
	local timestamp1 = protocol.TimeList[1].Timestamp
	game:UpdatePing(timestamp1)
end

PBHelper.AddHandler("S2CPing", OnPing)