--
-- S2CLogoutAccount
-- 
local PBHelper = require "Network.PBHelper"

local function OnLogoutAccount(sender, msg)
	game:ReturnLoginStage()
end

PBHelper.AddHandler("S2CLogoutAccount", OnLogoutAccount)