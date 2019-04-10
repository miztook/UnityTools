local PBHelper = require "Network.PBHelper"

local function OnS2CShieldValueChange(sender,protocol)
-- warn("=============OnS2CShieldValueChange=============")
	local entity = game._CurWorld:FindObject(protocol.EntityId)
	if entity ~= nil then
		entity:UpdateShield(protocol.ShieldValue)
	end
end
PBHelper.AddHandler("S2CShieldValueChange", OnS2CShieldValueChange)