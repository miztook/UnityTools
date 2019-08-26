local PBHelper = require "Network.PBHelper"

local function ProcessOneProtocol(protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity ~= nil then
		if entity:IsCullingVisible() then
			entity:UpdateShield(protocol.ShieldValue)
		else
			entity:UpdateShield_Simple(protocol.ShieldValue)
		end
	end
end

local function OnS2CShieldValueChange(sender,protocol)
	ProcessOneProtocol(protocol)
	
	if protocol.ProtoList ~= nil then
		for i,v in ipairs(protocol.ProtoList) do
			ProcessOneProtocol(v)
		end
	end	
end
PBHelper.AddHandler("S2CShieldValueChange", OnS2CShieldValueChange)