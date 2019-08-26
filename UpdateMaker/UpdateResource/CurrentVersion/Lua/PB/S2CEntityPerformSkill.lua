--
-- S2CEntityPerformSkill
--
local PBHelper = require "Network.PBHelper"


local function ProcessOneEntityPerformSkillMsg(msg, simple)
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object == nil or object._SkillHdl == nil then return end

	local moveInfo = msg.MoveInfo
	if object:IsCullingVisible() then
		local destPosition = Vector3.New(msg.DestPosition.x, msg.DestPosition.y, msg.DestPosition.z)
		local direction = Vector3.New(msg.Direction.x, msg.Direction.y, msg.Direction.z)
		object._SkillHdl:OnEntityPerformSkill(msg.SkillId, msg.PerformId, msg.IsDeadskill, msg.TargetId, destPosition, direction, moveInfo)
	else
		object._SkillHdl:OnEntityPerformSkill_Simple(moveInfo)
	end
end

local function OnEntityPerformSkill(sender,msg)
	ProcessOneEntityPerformSkillMsg(msg, false)
	if msg.ProtoList ~= nil then
		for i,v in ipairs(msg.ProtoList) do
			ProcessOneEntityPerformSkillMsg(v, false)
		end
	end
end

PBHelper.AddHandler("S2CEntityPerformSkill", OnEntityPerformSkill)

local function ProcessOneEntityStopSkillMsg(msg)
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object == nil or object._SkillHdl == nil or object:IsHostPlayer() then return end

	if object:IsCullingVisible() then
		object._SkillHdl:OnEntityStopSkill(msg.SkillId, true)
	else
		object._SkillHdl:OnEntityStopSkill_Simple(msg.SkillId, true)	
	end
end

local function OnEntityStopSkill(sender,msg)
	ProcessOneEntityStopSkillMsg(msg)
	if msg.ProtoList ~= nil then
		for i,v in ipairs(msg.ProtoList) do
			ProcessOneEntityStopSkillMsg(v)
		end
	end
end

PBHelper.AddHandler("S2CEntityStopSkill",OnEntityStopSkill)


