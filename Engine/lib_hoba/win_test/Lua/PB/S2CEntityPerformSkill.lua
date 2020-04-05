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
	if object ~= nil then
		object:AddLoadedCallback(function(e)
			if e._SkillHdl ~= nil then
				local destPosition = Vector3.New(msg.DestPosition.x, msg.DestPosition.y, msg.DestPosition.z)
				local direction = Vector3.New(msg.Direction.x, msg.Direction.y, msg.Direction.z)
				local moveInfo = msg.MoveInfo
				if not e:IsHostPlayer() then
					e._SkillHdl:StopGfxPlay(EnumDef.EntitySkillStopType.PerformEnd)
					e._SkillHdl:StopActiveEvents(msg.SkillId, EnumDef.ScreenEventTerminal.PerformEnd)
					e:SetDeathSkilling(msg.IsDeadskill)
				end

				e._SkillHdl:OnEntityPerformSkill(msg.SkillId, msg.PerformId, msg.TargetId, destPosition, direction, moveInfo)
			end
		end)
	end
end

PBHelper.AddHandler("S2CEntityPerformSkill",OnEntityPerformSkill)

local function OnEntityStopSkill(sender,msg)
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object ~= nil then
		if object:IsHostPlayer() then
			--warn("TODO: Host OnEntityPerformSkill")
		elseif object._SkillHdl ~= nil then
			object._SkillHdl:OnEntityStopSkill(msg.SkillId)
		end
	end
end

PBHelper.AddHandler("S2CEntityStopSkill",OnEntityStopSkill)


