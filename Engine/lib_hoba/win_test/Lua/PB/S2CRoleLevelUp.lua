--
-- S2CRoleLevelUp
--

local PBHelper = require "Network.PBHelper"

local function OnRoleLevelUp(sender, msg)
	local entity = game._CurWorld:FindObject(msg.EntityId)
	if entity == nil then 
		--warn("can not find entity with id " .. msg.EntityId .. " when S2CRoleLevelUp")
		return 
	end
	entity:OnLevelUp(msg.CurrentLevel, msg.CurrentExp, msg.CurrentParagonLevel, msg.CurrentParagonExp)
end

PBHelper.AddHandler("S2CRoleLevelUp", OnRoleLevelUp)