--
-- S2CGuide
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"

--服务器行为树通知教学
local function OnS2CTeachingStart(sender, msg)
	print("OnS2CTeachingStart")

	game._CGuideMan:OnServer(msg.TeachingId)
end
PBHelper.AddHandler("S2CTeachingStart", OnS2CTeachingStart)