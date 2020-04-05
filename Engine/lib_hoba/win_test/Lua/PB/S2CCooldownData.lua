--
-- S2CCooldownData
--

local PBHelper = require "Network.PBHelper"

local function OnCooldownData( sender,msg )
	local host = game._HostPlayer
	if host ~= nil then
		host:StartCooldown(msg.CooldownId, msg.AccumulateCount, msg.CurTime, msg.MaxTime)
	end
end

PBHelper.AddHandler("S2CCooldownData",OnCooldownData)