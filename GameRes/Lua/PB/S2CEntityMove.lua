--
-- S2CEntityMove
--

local PBHelper = require "Network.PBHelper"

local function OnEntityMove( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 

	if entity ~= nil then
		local curStepDestPos = Vector3.New(msg.CurrentPosition.x, msg.CurrentPosition.y, msg.CurrentPosition.z)
		local curOri = Vector3.New(msg.CurrentOrientation.x, msg.CurrentOrientation.y, msg.CurrentOrientation.z)
		local moveDir = Vector3.New(msg.MoveDirection.x, msg.MoveDirection.y, msg.MoveDirection.z)
		local finalDstPos = Vector3.New(msg.DstPosition.x, msg.DstPosition.y, msg.DstPosition.z)
		entity:OnMove(curStepDestPos, curOri, msg.MoveType, moveDir, msg.MoveSpeed, msg.IsDestPosition, finalDstPos)
	else
		--warn("S2CEntityMove can not find entity with id " .. msg.EntityId)
	end

	--warn(Time.frameCount, msg.EntityId, msg.MoveType)
end

PBHelper.AddHandler("S2CEntityMove",OnEntityMove)