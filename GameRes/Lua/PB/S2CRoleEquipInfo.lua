--
-- S2CBackpackEquipInfo
--

local PBHelper = require "Network.PBHelper"
--local template = require "PB.Template"
local net = require "PB.net"
local CInventory = require "Package.CInventory"

local function OnRoleEquipInfo(sender, protocol)
	local hp = game._HostPlayer
	local equipPack = hp._Package._EquipPack
	local items = protocol.RoleEquipData.Items
	local packageType = IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK
	for i,v in ipairs(items) do
		local item = CInventory.CreateItem(v)
		item._PackageType = packageType
		equipPack:UpdateItem(item)
		local inforceLv = (item._Tid > 0 and item._InforceLevel > 0) and item._InforceLevel or 0
		hp:UpdateEquipments(item._Slot, item._Tid, inforceLv)
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