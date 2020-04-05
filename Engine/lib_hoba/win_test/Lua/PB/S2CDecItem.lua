--
-- S2CDecItem
--

local PBHelper = require "Network.PBHelper"

local function OnDecreaseItem( sender,msg )

	local pack = game._HostPlayer._Package._NormalIvtrs[msg.Location]
	if pack == nil then
		return
	end

	pack:SetItem(msg.Index, msg.DecCount, 0)

	do
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
		local net = require "PB.net"
	    event.PackageType = net.BAGTYPE.BACKPACK
	    CGame.EventManager:raiseEvent(nil, event)
	end
end

PBHelper.AddHandler("S2CDecItem", OnDecreaseItem)