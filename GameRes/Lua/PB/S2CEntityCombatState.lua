--
-- S2CEntityCombatState
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local function OnEntityCombatState(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity == nil then return end
	local function cb ()
		entity:UpdateCombatState(protocol.CombatState, false, protocol.OriginId, protocol.EnterType == 0, false)
	end
	entity:AddLoadedCallback(cb)	
	--entity:SetCurrentTargetId(protocol.CurrentTargetId)
end

PBHelper.AddHandler("S2CEntityCombatState", OnEntityCombatState)

local function OnEntityFightState(sender, protocol)
	local tmpEntity = game._CurWorld:FindObject(protocol.EntityId)
	if tmpEntity == nil then return end
	local function cb (entity)
		if entity:IsMonster() then
			entity:UpdateFightState(protocol.FightState)
			--print(entity._InfoData._Name,protocol.FightState)
			
		 	local EntityCombatStateEvent = require "Events.EntityCombatStateEvent"
		 	local event = EntityCombatStateEvent()
			event._CombatState = protocol.FightState
			event._EntityId = protocol.EntityId
			CGame.EventManager:raiseEvent(nil, event)
		end
	end
	tmpEntity:AddLoadedCallback(cb)
end

PBHelper.AddHandler("S2CEntityFightState", OnEntityFightState)

local function OnEntityUpdateTargetID(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity == nil then return end
	
	entity:SetCurrentTargetId(protocol.TargetId)	
end

PBHelper.AddHandler("S2CEntityUpdateTargetID", OnEntityUpdateTargetID)