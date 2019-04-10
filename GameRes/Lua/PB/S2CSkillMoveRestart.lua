local PBHelper = require "Network.PBHelper"
local DistanceH = Vector3.DistanceH_XZ
-- DestPosition, Speed, EntityId
local function OnS2CSkillMoveRestart(sender, msg)
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity then
		local go = entity:GetGameObject()
        local posX, posY, posZ = entity:GetPosXYZ()       
		local destpos = Vector3.New(msg.DestPosition.x, msg.DestPosition.y, msg.DestPosition.z)
		local move_lenth = DistanceH(posX, posZ, destpos.x, destpos.z)
		local duration = move_lenth /  msg.Speed
		GameUtil.AddDashBehavior(go, destpos, duration, true, false)
	end
end
PBHelper.AddHandler("S2CSkillMoveRestart", OnS2CSkillMoveRestart)