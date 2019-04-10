--
-- OnS2CSyncServerStartTime
--

local PBHelper = require "Network.PBHelper"

local function OnS2CSyncServerStartTime(sender, protocol)


   	--warn("protocol.ServerUtcTotalMilliseconds",protocol.ServerUtcTotalMilliseconds)
   	--local x = 
	GameUtil.SetServerOpenTime(protocol.ServerStartTime ,protocol.ServerUtcTotalMilliseconds )

end

PBHelper.AddHandler("S2CSyncServerStartTime", OnS2CSyncServerStartTime)