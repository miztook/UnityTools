--
-- S2CInventoryInfo
--

local PBHelper = require "Network.PBHelper"

local function OnPing(sender, protocol)	
	local timestamp1 = protocol.TimeList[1].Timestamp
	local gap = GameUtil.GetMilliTime() - timestamp1
	game:UpdatePing(gap)
end

PBHelper.AddHandler("S2CPing", OnPing)