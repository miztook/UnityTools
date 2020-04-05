--
-- S2CEntityNotifyFury
--

local PBHelper = require "Network.PBHelper"

local function OnEntityNotifyAIState( sender,msg )
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object ~= nil then
		object:OnAIStateChange(msg.AIState , msg.CanBeSelect, msg.CanBeAttack )
	end
end

PBHelper.AddHandler("S2CEntityNotifyAIState",OnEntityNotifyAIState)