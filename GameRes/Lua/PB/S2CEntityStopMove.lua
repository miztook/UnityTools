--
-- S2CEntityStopMove
--

local PBHelper = require "Network.PBHelper"
local function OnEntityStopMove( sender,msg )
	if game._CurWorld == nil then return end
	
	local entity = game._CurWorld:FindObject(msg.EntityId) 

	if entity ~= nil then
		local msgCurPos = msg.CurrentPosition
		local msgCurOri = msg.CurrentOrientation
		
		local cur_pos = Vector3.New(msgCurPos.x, msgCurPos.y, msgCurPos.z)
		local cur_ori = Vector3.New(msgCurOri.x, msgCurOri.y, msgCurOri.z)
		if entity:IsCullingVisible() then
			entity:OnStopMove(cur_pos, cur_ori, msg.MoveType)
		else
			entity:OnStopMove_Simple(cur_pos, cur_ori, msg.MoveType)
		end
	else
		--warn("S2CEntityStopMove can not find entity with id " .. msg.EntityId)
	end
end

PBHelper.AddHandler("S2CEntityStopMove",OnEntityStopMove)

local function OnS2CRoleTrans(sender,msg )
	if msg.DelayTime > 0 then 

		CSoundMan.Instance():Play3DAudio(PATH.GUISound_Event_map_portal, game._HostPlayer:GetPos(),0)
		
		StartScreenFade(0, 1, 1, nil)
	end
end

PBHelper.AddHandler("S2CRoleTrans",OnS2CRoleTrans)
