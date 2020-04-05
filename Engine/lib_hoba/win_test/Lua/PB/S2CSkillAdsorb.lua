
local PBHelper = require "Network.PBHelper"

local function OnSkillAdsorb(sender, msg)
	local world = game._CurWorld
	local entity = world:FindObject(msg.EntityId)
	if entity == nil then return end
	local target = entity:GetGameObject()
	if target == nil then return end

	local start_adsorb = msg.Is2Start
	local origin = msg.OrignId
	if start_adsorb then
		local speed = msg.Speed
		local position = msg.Position
		--entity._ServerPos = position--实际上，服务器有可能没有移动到这个位置，是否通过普通移动实现吸附移动
		GameUtil.AddAdsorbBehavior(target, origin, speed, position)
		--warn("AddAdsorbBehavior", origin)
	else
		GameUtil.RemoveAdsorbBehavior(target, origin)
		--warn("RemoveAdsorbBehavior", origin)
	end
end

PBHelper.AddHandler("S2CSkillAdsorb", OnSkillAdsorb)