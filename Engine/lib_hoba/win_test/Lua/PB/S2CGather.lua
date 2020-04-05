--
-- S2CGather
--

local PBHelper = require "Network.PBHelper"

--坐骑通知
local function OnS2CGatherSuccess(sender, msg)
	if msg.EntityID == game._HostPlayer._ID then
		game._HostPlayer:AddGatherNum(msg.MineTID,1)
	end
end
PBHelper.AddHandler("S2CGatherSuccess", OnS2CGatherSuccess)