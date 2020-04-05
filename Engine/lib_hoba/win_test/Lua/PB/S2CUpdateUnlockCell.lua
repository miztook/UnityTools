--
-- S2CInventoryInfo
--
local PBHelper = require "Network.PBHelper"

local function OnUpdateUnlockCell(sender, protocol)
--warn("S2CUpdateUnlockCell Location=", protocol.Location)
	-- local net = require "PB.net"
	-- if protocol.BagType == net.BAGTYPE.BACKPACK then
	warn("22222222222222")
	game._HostPlayer._Package._NormalPack._EffectSize = protocol.Count
	warn("protocol.Count___"..protocol.Count)
	-- else
	-- end
	do
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
	    -- event.PackageType = protocol.BagType
	    CGame.EventManager:raiseEvent(nil, event)
	end

end

PBHelper.AddHandler("S2CUpdateUnlockCell", OnUpdateUnlockCell)