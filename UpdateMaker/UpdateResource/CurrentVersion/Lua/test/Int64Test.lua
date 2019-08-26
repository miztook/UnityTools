local PBHelper = require "Network.PBHelper"
local net = require "PB.net"

print("Load Int64Test.lua")

_G.SendPickupMsg = function ()
	local C2SPickUpLoot = require "PB.net".C2SPickUpLoot
	local protocol = C2SPickUpLoot()
	table.insert(protocol.lootEntityIds, LuaUInt64.FromDouble(123456))
	table.insert(protocol.lootEntityIds, LuaUInt64.FromDouble(654321))

	SendProtocol(protocol)
end

_G.SendRoleSelectMsg = function ()
	local id = 123456789000
	local C2SRoleSelect = require "PB.net".C2SRoleSelect
	local msg = C2SRoleSelect()
	msg.RoleId = LuaUInt64.FromDouble(id)
	SendProtocol(msg)
end
