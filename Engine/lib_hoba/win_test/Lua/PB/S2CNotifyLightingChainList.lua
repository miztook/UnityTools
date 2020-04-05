
local PBHelper = require "Network.PBHelper"


local function get_link_trans(entity)
	if entity ~= nil then
		return entity:GetHangPoint("HangPoint_Hurt")
	else
		return nil
	end
end

local function OnNotifyLightingChainList(sender, msg)
	local world = game._CurWorld
	local caster = world:FindObject(msg.EntityId)

	if caster ~= nil then
		local arc = nil
		if caster._SkillHdl ~= nil then
			arc = caster._SkillHdl._CurArcFxPath
		end

		if arc == nil or arc == "" then
			warn("entity", msg.EntityId, "has no arc resource")
			return
		end

		local chainListCount = #msg.ChainList
		if chainListCount <= 1 then return end
		for i = 1, chainListCount - 1 do
			local beginId = msg.ChainList[i]
			local endId = msg.ChainList[i+1]
			caster:AddTimer(i*0.4, true, function()
					local startTarget = world:FindObject(beginId)
					local endTarget = world:FindObject(endId)
					local startTrans = get_link_trans(startTarget)
					local endTrans = get_link_trans(endTarget)
					CFxMan.Instance():PlayArcFx(arc, startTrans, endTrans, 1, 1)
				end)
		end
	end
end

PBHelper.AddHandler("S2CNotifyLightingChainList", OnNotifyLightingChainList)