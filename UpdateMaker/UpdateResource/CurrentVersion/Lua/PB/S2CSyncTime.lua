--
-- S2CSyncTime
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnSyncTime(sender, protocol)
	-- 移动中带有时间戳，服务器会校对时间戳，如果异常，强制同步时间
	local gap = GameUtil.GetClientTime() - protocol.ServerUtcTotalMilliseconds
	GameUtil.SetServerTimeGap(gap)
end

PBHelper.AddHandler("S2CSyncTime", OnSyncTime)