local PBHelper = require "Network.PBHelper"

local function OnEntityHeadInstruction( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId)
	if entity == nil then return end
	entity:SaveEntityHeadInstructionData(msg)
end

PBHelper.AddHandler("S2CEntityHeadInstruction", OnEntityHeadInstruction)