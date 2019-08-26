--
-- S2CEntityCombatState
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local function OnEntityCombatState(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity == nil or not entity:IsCullingVisible() then return end
	local function cb ()
		entity:UpdateCombatState(protocol.CombatState, false, protocol.OriginId, protocol.EnterType == 0, false)
	end
	entity:AddLoadedCallback(cb)	
end

PBHelper.AddHandler("S2CEntityCombatState", OnEntityCombatState)

local function OnEntityFightState(sender, protocol)
	local tmpEntity = game._CurWorld:FindObject(protocol.EntityId)
	if tmpEntity == nil or not tmpEntity:IsCullingVisible() then return end

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

local function ProcessOneProtocol(protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity == nil or not entity:IsCullingVisible() then return end
	
	entity:SetCurrentTargetId(protocol.TargetId)
end

local function OnEntityUpdateTargetID(sender, protocol)
	ProcessOneProtocol(protocol)

	if protocol.ProtoList ~= nil then
		for i,v in ipairs(protocol.ProtoList) do
			ProcessOneProtocol(v)
		end
	end	
end

PBHelper.AddHandler("S2CEntityUpdateTargetID", OnEntityUpdateTargetID)