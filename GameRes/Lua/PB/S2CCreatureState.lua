local PBHelper = require "Network.PBHelper"

local function OnS2CCreatureState(sender, protocol)
	local object = game._CurWorld:FindObject(protocol.EntityId) 
	if object == nil then return end

	object:AddLoadedCallback(function()
		local info = {}
		local buffDetail = protocol.BuffDetail

		if buffDetail.SkillId and buffDetail.SkillLevel then
			info.Skill = 
			{ 
				ID = buffDetail.SkillId,
				Level = buffDetail.SkillLevel,
			}
		end
		if buffDetail.TalentId and buffDetail.TalentLevel then
			info.Talent = 
			{
				ID = buffDetail.TalentId,
				Level = buffDetail.TalentLevel,
			}
		end
		if buffDetail.RuneId and buffDetail.RuneLevel then
			info.Rune = 
			{
				ID = buffDetail.RuneId,
				Level = buffDetail.RuneLevel,
			}
		end

		info.Attr = buffDetail.Attrs
		object:UpdateState(protocol.Add, buffDetail.Id, buffDetail.Duration, buffDetail.OriginId, info)
	end)	
end

PBHelper.AddHandler("S2CCreatureState",OnS2CCreatureState)
