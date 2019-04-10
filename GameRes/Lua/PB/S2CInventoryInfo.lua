--
-- S2CInventoryInfo
--

local PBHelper = require "Network.PBHelper"

local function OnInventoryInfo(sender, protocol)
	--warn("S2CInventoryInfo Location=", protocol.Location)
end

PBHelper.AddHandler("S2CInventoryInfo", OnInventoryInfo)