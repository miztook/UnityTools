--
-- S2CEntityStopMove
--

local PBHelper = require "Network.PBHelper"
local function OnEntityStopMove( sender,msg )
	if game._CurWorld == nil then return end
	
	local entity = game._CurWorld:FindObject(msg.EntityId) 

	if entity ~= nil then
		local cur_pos = Vector3.New(msg.CurrentPosition.x, msg.CurrentPosition.y, msg.CurrentPosition.z)
		local cur_ori = Vector3.New(msg.CurrentOrientation.x, msg.CurrentOrientation.y, msg.CurrentOrientation.z)
		entity:OnStopMove(cur_pos, cur_ori, msg.MoveType)
	else
		--warn("S2CEntityStopMove can not find entity with id " .. msg.EntityId)
	end
end

PBHelper.AddHandler("S2CEntityStopMove",OnEntityStopMove)

local function OnS2CRoleTrans(sender,msg )
	if msg.DelayTime > 0 then 
		StartScreenFade(0, 1, 1, nil)
	end
end

PBHelper.AddHandler("S2CRoleTrans",OnS2CRoleTrans)
