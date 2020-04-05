--
-- S2CCgEvent
--
local PBHelper = require "Network.PBHelper"

local function OnCgEvent( sender,msg )
	CGMan.PlayById(msg.CgAssetId, nil, 1)
end

PBHelper.AddHandler("S2CCgEvent", OnCgEvent)