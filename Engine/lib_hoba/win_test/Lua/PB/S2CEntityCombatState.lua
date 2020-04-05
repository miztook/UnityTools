--
-- S2CEntityCombatState
--

local PBHelper = require "Network.PBHelper"

local function OnEntityCombatState(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity == nil then return end
	local function cb ()
		entity:UpdateCombatState(protocol.CombatState, false, 0, protocol.OriginId, protocol.EnterType == 0)
	end
	entity:AddLoadedCallback(cb)	
end

PBHelper.AddHandler("S2CEntityCombatState", OnEntityCombatState)

local function OnEntityFightState(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity == nil then return end
	local function cb ()
		if entity:IsMonster() then
			entity:UpdateFightState(protocol.FightState)
		end
	end
	entity:AddLoadedCallback(cb)
end

PBHelper.AddHandler("S2CEntityFightState", OnEntityFightState)