local PBHelper = require "Network.PBHelper"

local function OnGainReward(sender, protocol)
	warn("S2CGainReward 尚未处理")
end

PBHelper.AddHandler("S2CGainReward", OnGainReward)