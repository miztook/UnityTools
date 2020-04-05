local PBHelper = require "Network.PBHelper"

local function OnEntityDie(sender, protocol)
	local object = game._CurWorld:FindObject(protocol.EntityId) 
	if object ~= nil then
		object:OnDie(protocol.Killer, protocol.ElementType, protocol.HitType, protocol.IsPlayAnimation)

		local objType = object:GetObjectType()
    	local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
    	if objType == OBJ_TYPE.ELSEPLAYER then
    		object:SendPropChangeEvent("Rescue")
		end
	end
end

PBHelper.AddHandler("S2CEntityDie",OnEntityDie)