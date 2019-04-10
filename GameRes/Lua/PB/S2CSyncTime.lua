--
-- S2CSyncTime
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local function OnSyncTime(sender, protocol)
	--warn("OnSyncTime Location=", protocol.Location)
	game:UpdateServerTime(protocol.ServerUtcTotalMilliseconds)
end

PBHelper.AddHandler("S2CSyncTime", OnSyncTime)