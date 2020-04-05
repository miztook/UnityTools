--
-- S2CBackpackEquipInfo
--

local PBHelper = require "Network.PBHelper"

local function OnBackpackEquipInfo(sender, protocol)
	--warn("S2CBackpackEquipInfo Location=", protocol.Location)
	game._HostPlayer._Package._EquipPack._ItemSet = protocol.BagData.Items-- index itemDB
	local items = game._HostPlayer._Package._EquipPack._ItemSet
	--print(#items)
end

PBHelper.AddHandler("S2CBackpackEquipInfo", OnBackpackEquipInfo)