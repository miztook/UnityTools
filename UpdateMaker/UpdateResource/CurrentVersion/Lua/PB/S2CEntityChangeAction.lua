local PBHelper = require "Network.PBHelper"
local EntityType = require"PB.data".EntityType

local function OnS2CEntityChangeAction(sender,msg )
	if msg.EntityType == EntityType.Npc then 
		game._CurWorld._NPCMan:ControlNpcPlayAnimation(msg.EntityTID,msg.StandAction,msg.MoveAction)
	end
end

PBHelper.AddHandler("S2CEntityChangeAction",OnS2CEntityChangeAction)