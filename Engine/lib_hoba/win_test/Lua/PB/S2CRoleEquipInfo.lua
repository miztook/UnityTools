--
-- S2CBackpackEquipInfo
--

local PBHelper = require "Network.PBHelper"
--local template = require "PB.Template"
local net = require "PB.net"
local CInventory = require "Package.CInventory"

local function OnRoleEquipInfo(sender, protocol)
	local equipPack = game._HostPlayer._Package._EquipPack
	local items = protocol.RoleEquipData.Items
	local packageType = IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK
	for i,v in ipairs(items) do
		local item = CInventory.CreateItem(v)
		item._PackageType = packageType
		equipPack:UpdateItem(item)
	end

	do
		local Lplus = require "Lplus"
		local CGame = Lplus.ForwardDeclare("CGame")
		local PackageChangeEvent = require "Events.PackageChangeEvent"
	    local event = PackageChangeEvent()
	    event.PackageType = net.BAGTYPE.ROLE_EQUIP
	    CGame.EventManager:raiseEvent(nil, event)
	end
end

PBHelper.AddHandler("S2CRoleEquipInfo", OnRoleEquipInfo)