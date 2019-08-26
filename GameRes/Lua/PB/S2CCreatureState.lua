local PBHelper = require "Network.PBHelper"


local function ProcessOneProtocol(msg)
	local object = game._CurWorld:FindObject(msg.EntityId) 
	if object == nil then return end

	if not object:IsCullingVisible() then
		object:UpdateState_Simple()
	else
		object:AddLoadedCallback(function()
			local info = {}
			local buffDetail = msg.BuffDetail

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

			info.Attr = buffDetail.Attrs or {}
			object:UpdateState(msg.Add, buffDetail.Id, buffDetail.Duration, buffDetail.OriginId, info)
		end)
	end		
end

local function OnS2CCreatureState(sender, protocol)
	if game._CurGameStage ~= _G.GameStage.InGameStage then return end

	ProcessOneProtocol(protocol)

	if protocol.ProtoList ~= nil then
		for i,v in ipairs(protocol.ProtoList) do
			ProcessOneProtocol(v)
		end
	end
end

PBHelper.AddHandler("S2CCreatureState",OnS2CCreatureState)
