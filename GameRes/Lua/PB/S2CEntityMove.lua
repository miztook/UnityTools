--
-- S2CEntityMove
--

local PBHelper = require "Network.PBHelper"

local function OnEntityMove( sender,msg )
	--[[
	_G.NumEntityMove = _G.NumEntityMove + 1
	local last = os.clock()
	]]
	local entity = game._CurWorld:FindObject(msg.EntityId) 

	if entity ~= nil then
		local msgCurPos = msg.CurrentPosition
		local msgCurOri = msg.CurrentOrientation
		local msgDir = msg.MoveDirection
		local msgDstPos = msg.DstPosition

		local curStepDestPos = Vector3.New(msgCurPos.x, msgCurPos.y, msgCurPos.z)
		local curOri = Vector3.New(msgCurOri.x, msgCurOri.y, msgCurOri.z)
		local moveDir = Vector3.New(msgDir.x, msgDir.y, msgDir.z)
		local finalDstPos = Vector3.New(msgDstPos.x, msgDstPos.y, msgDstPos.z)
		entity:OnMove(curStepDestPos, curOri, msg.MoveType, moveDir, msg.MoveSpeed, msg.IsDestPosition, finalDstPos)
	else
		--warn("S2CEntityMove can not find entity with id " .. msg.EntityId)
	end

	--[[
	do 
		local now = os.clock()
		_G.TimeHandleEntityMove1 = _G.TimeHandleEntityMove1 + (now - last) * 1000
		last = now
	end
	]]
end

PBHelper.AddHandler("S2CEntityMove",OnEntityMove)