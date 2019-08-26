--
-- S2CPickUpLoot
--

local PBHelper = require "Network.PBHelper"

local function OnS2CPickUpLoot(sender, protocol)
	if protocol.lootEntityIds ~= nil and #protocol.lootEntityIds > 0 then
		
		for i,v in ipairs(protocol.lootEntityIds) do
			local man = game._CurWorld:DispatchManager(v)
			if man ~= nil and v ~= nil then
				man:OnLootPickUp(v)
			end
		end
	end
end

PBHelper.AddHandler("S2CPickUpLoot", OnS2CPickUpLoot)