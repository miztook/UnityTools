--
-- S2CSyncTime
--

local PBHelper = require "Network.PBHelper"
local CGame = require "Main.CGame"

local function OnSyncTime(sender, protocol)
	--warn("OnSyncTime Location=", protocol.Location)
	CGame.Instance():UpdateServerTime(protocol.ServerUtcTotalMilliseconds)
end

PBHelper.AddHandler("S2CSyncTime", OnSyncTime)