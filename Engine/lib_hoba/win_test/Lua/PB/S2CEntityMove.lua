--
-- S2CEntityMove
--

local PBHelper = require "Network.PBHelper"
local CGame = require "Main.CGame"

local function OnEntityMove( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil then
		local cur_pos = Vector3.New(msg.CurrentPosition.x, msg.CurrentPosition.y, msg.CurrentPosition.z)
		local cur_ori = Vector3.New(msg.CurrentOrientation.x, msg.CurrentOrientation.y, msg.CurrentOrientation.z)
		local movedir = Vector3.New(msg.MoveDirection.x, msg.MoveDirection.y, msg.MoveDirection.z)
		local dstPos = Vector3.New(msg.DstPosition.x, msg.DstPosition.y, msg.DstPosition.z)
		entity:OnMove(cur_pos, cur_ori, msg.MoveType, movedir, msg.MoveSpeed, msg.IsDestPosition, dstPos)			
	else
		--warn("S2CEntityMove can not find entity with id " .. msg.EntityId)
	end
end

PBHelper.AddHandler("S2CEntityMove",OnEntityMove)