--
-- S2CEntityPerformSkill
--
local PBHelper = require "Network.PBHelper"
local function OnEntityPerformSkill( sender,msg )
	--[[
		message S2CEntityPerformSkill
		{
			optional S2C_PROTOC_TYPE type	= 1	[ default = S2C_PROTOC_TYPE.SPT_ENTITY_PERFORM_SKILL ];
			required int32 EntityId			= 2;
			required int32 SkillId			= 3;
			required int32 PerformId		= 4;
			optional int32 TargetId 		= 5;
			optional vector3 DestPosition	= 6;
			optional vector3 Direction		= 7;
			optional SkillMoveInfo MoveInfo = 8;
		}
	]]
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object ~= nil and object._SkillHdl ~= nil then
		local destPosition = Vector3.New(msg.DestPosition.x, msg.DestPosition.y, msg.DestPosition.z)
		local direction = Vector3.New(msg.Direction.x, msg.Direction.y, msg.Direction.z)
		local moveInfo = msg.MoveInfo
		object._SkillHdl:OnEntityPerformSkill(msg.SkillId, msg.PerformId, msg.IsDeadskill, msg.TargetId, destPosition, direction, moveInfo)
	end
end

PBHelper.AddHandler("S2CEntityPerformSkill",OnEntityPerformSkill)

local function OnEntityStopSkill(sender,msg)
	local object = game._CurWorld:FindObject(msg.EntityId) 
	
	if object ~= nil and not object:IsHostPlayer() then
		object._SkillHdl:OnEntityStopSkill(msg.SkillId, true)	
	end
end

PBHelper.AddHandler("S2CEntityStopSkill",OnEntityStopSkill)


