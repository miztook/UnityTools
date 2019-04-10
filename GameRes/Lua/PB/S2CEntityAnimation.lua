local PBHelper = require "Network.PBHelper"

local function OnEntityAnimation( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId)
	if entity == nil then return end
	entity:AddLoadedCallback(function(e)
				if entity:IsReleased() then return end
				entity:SaveReplaceAnimationsAndPlay(msg.AnimationInfos)
			end)
end

PBHelper.AddHandler("S2CEntityAnimation", OnEntityAnimation)