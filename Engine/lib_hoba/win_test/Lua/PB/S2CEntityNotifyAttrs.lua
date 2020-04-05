--
-- S2CEntityNotifyAttrs
--

local PBHelper = require "Network.PBHelper"

local function OnEntityNotifyAttrs( sender,msg )
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object ~= nil then
		object:UpdateFightProperty(msg.CreatureAttrs)

		-- fire property change event
		object:SendPropChangeEvent("All")
	end
end

PBHelper.AddHandler("S2CEntityNotifyAttrs",OnEntityNotifyAttrs)