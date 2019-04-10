local PBHelper = require "Network.PBHelper"
local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR
local DistanceH = Vector3.DistanceH_XZ

local function SetPos(entity, pos)
	if entity then
        local posX, posY, posZ = entity:GetPosXYZ()       
		local distance = DistanceH(posX, posZ, pos.x, pos.z)
		if distance > 0.5 then
			entity:SetPos(pos)
		end
	end
end


local function OnSkillAdsorb(sender, msg)
	local world = game._CurWorld
	local entity = world:FindObject(msg.EntityId)
	if entity == nil then return end
	local target = entity:GetGameObject()
	if target == nil then return end

	local start_adsorb = msg.Is2Start
	local origin = msg.OrignId
	if start_adsorb then
		local speed = msg.Speed
		local position = msg.Position
		SetPos(entity, msg.CurPosition)
		GameUtil.AddAdsorbBehavior(target, origin, speed, position) 
	else
		GameUtil.RemoveBehavior(target, BEHAVIOR.ADSORB)
		SetPos(entity, msg.CurPosition)
	end
end

PBHelper.AddHandler("S2CSkillAdsorb", OnSkillAdsorb)