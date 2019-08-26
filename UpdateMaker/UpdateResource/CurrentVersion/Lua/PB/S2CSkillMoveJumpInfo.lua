--
-- S2CSkillMoveJumpInfo
--

local PBHelper = require "Network.PBHelper"

local function OnSkillMoveJumpInfo( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil then
		local speed = msg.Speed
		local dest_pos = Vector3.New(msg.DestPosition.x, msg.DestPosition.y, msg.DestPosition.z)
		entity:OnSkillMoveJump(dest_pos, speed)

		local src_pos = Vector3.New(msg.SrcPosition.x, msg.SrcPosition.y, msg.SrcPosition.z)
		local dir = (dest_pos - src_pos):Normalize()
		--warn("OnSkillMoveJumpInfo", src_pos, dest_pos, "dir =", dir)
	else
		--warn("S2CSkillMoveJumpInfo can not find entity with id " .. msg.EntityId)
	end
end

PBHelper.AddHandler("S2CSkillMoveJumpInfo",OnSkillMoveJumpInfo)