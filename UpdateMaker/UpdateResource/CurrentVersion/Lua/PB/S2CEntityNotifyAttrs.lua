--
-- S2CEntityNotifyAttrs
--

local PBHelper = require "Network.PBHelper"

local function OnEntityNotifyAttrs( sender,msg )
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object ~= nil then
		--warn("S2CEntityNotifyAttrs", msg.EntityId, msg.IsNotifyFightScore)
		object:UpdateFightProperty(msg.CreatureAttrs, msg.IsNotifyFightScore)

		-- fire property change event
		object:SendPropChangeEvent()
	end
end

PBHelper.AddHandler("S2CEntityNotifyAttrs",OnEntityNotifyAttrs)