local PBHelper = require "Network.PBHelper"

local function OnS2CCreatureState(sender, protocol)
	local object = game._CurWorld:FindObject(protocol.EntityId) 
	if object == nil then return end
	object:UpdateState(protocol.Add, protocol.StateId, protocol.Duration, protocol.OriginId)
	object._SkillHdl:ApplyBuffPerform(protocol.EntityId, protocol.StateId, protocol.Add)
end

PBHelper.AddHandler("S2CCreatureState",OnS2CCreatureState)
