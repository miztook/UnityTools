local PBHelper = require "Network.PBHelper"
local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR
local DistanceH = Vector3.DistanceH_XZ

--[[
	由于多个吸附叠加运算容易导致不同步现象，所以简化为同时可以存在多个吸附操作，但是只有一个生效。 
	服务器选择速度快距离最近的的吸附通知客户端，吸附结束或者有新的吸附时进行再次选择并通知客户端，直达所有的吸
	附操作执行完毕通知客户端结束
--]]
local function OnSkillAdsorb(sender, msg)
	local world = game._CurWorld
	local entity = world:FindObject(msg.EntityId)
	if entity == nil then return end
	local target = entity:GetGameObject()
	if target == nil then return end

	--当前规则：新吸附中断旧吸附
	--entity:SetPos(msg.CurPosition)
	local is2Add = msg.Is2Start
	local origin = msg.OrignId
	--warn("S2CSkillAdsorb", is2Add, Time.time)
	if is2Add then
		local speed = msg.Speed
		local position = msg.Position
		GameUtil.AddAdsorbEffect(target, origin, speed, position) 
	else
		GameUtil.RemoveAdsorbEffect(target, origin)
	end
end

PBHelper.AddHandler("S2CSkillAdsorb", OnSkillAdsorb)