--
-- S2CEntityMove
--

local PBHelper = require "Network.PBHelper"

local function OnS2CEntityServiceChange( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil then
		entity._ServiceOpenFlag = msg.ServiceOpenFlag			
	else
		--warn("S2CEntityServiceChange can not find entity with id " .. msg.EntityId)
	end
end

PBHelper.AddHandler("S2CEntityServiceChange",OnS2CEntityServiceChange)