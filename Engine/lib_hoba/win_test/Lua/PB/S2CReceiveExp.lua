local PBHelper = require "Network.PBHelper"

local function OnReceiveExp(sender, protocol)
	--warn("S2CReceiveExp", protocol.Offset, protocol.CurrentExp)
	game._HostPlayer:OnReceiveExp(protocol.Offset, protocol.CurrentExp, protocol.CurrentParagonExp)
end

PBHelper.AddHandler("S2CReceiveExp", OnReceiveExp)
