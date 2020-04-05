local PBHelper = require "Network.PBHelper"

local function OnGainReward(sender, protocol)
	local printfunc = function()
		print('reward end')
	end
	game._GUIMan:ShowRewardTip(protocol.RewardId)
end

PBHelper.AddHandler("S2CGainReward", OnGainReward)