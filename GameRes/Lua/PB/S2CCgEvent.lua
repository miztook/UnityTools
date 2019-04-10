--
-- S2CCgEvent
--
local PBHelper = require "Network.PBHelper"

local function OnCgEvent( sender,msg )
	if msg.Flag == 0 then
		CGMan.PlayById(msg.CgAssetId, nil, 1)
	else
		CGMan.StopCG()
	end
end

PBHelper.AddHandler("S2CCgEvent", OnCgEvent)