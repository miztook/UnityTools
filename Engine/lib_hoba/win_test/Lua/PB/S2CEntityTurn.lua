--
-- S2CEntityTurn
--

local PBHelper = require "Network.PBHelper"

local _turnDir = Vector3.zero
local function OnEntityTurn( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil then
		local orient = msg.TurnToOrientation
		_turnDir.x = orient.x
		_turnDir.y = orient.y
		_turnDir.z = orient.z
		--warn("OnEntityTurn", entity:GetGameObject().name, "dir =", dir)
		if msg.Speed ~= nil and msg.Speed > 0 then
			entity:TurnToDir(_turnDir, msg.Speed)
		else
			entity:SetDir(_turnDir)
		end
	end
end

PBHelper.AddHandler("S2CEntityTurn",OnEntityTurn)