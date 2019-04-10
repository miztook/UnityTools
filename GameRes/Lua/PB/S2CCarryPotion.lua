local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
-- 装备药品
local function OnS2CCarryPotion(sender, msg)
	if not game then
		return
	end

	if msg.result == 0 then
		-- msg.itemTid
		game._HostPlayer:SetEquipedPotion(msg.Tid)
		
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
	    local net = require "PB.net"
	    event.PackageType = net.BAGTYPE.BACKPACK
	    CGame.EventManager:raiseEvent(nil, event)
	else
		game._GUIMan:ShowErrorCodeMsg(msg.result, nil)
	end
end
PBHelper.AddHandler("S2CCarryPotion", OnS2CCarryPotion)