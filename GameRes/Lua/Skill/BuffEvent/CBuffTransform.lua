local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"
local ChangeShapeEvent = require "Events.ChangeShapeEvent"
local CGame = Lplus.ForwardDeclare("CGame")

local CBuffTransform = Lplus.Extend(CBuffEventBase, "CBuffTransform")
local def = CBuffTransform.define

def.static("table", "table", "=>", CBuffTransform).new = function(host, event)
	local obj = CBuffTransform()
	obj._Event = event
	obj._Host = host
	return obj
end

def.override().OnEvent = function(self)
	local entity = self._Host
	if entity ~= nil and not entity:IsReleased() then
		local event = self._Event	
		if event.Transform.TransformType == 0 then
			entity:ChangeShape(event.Transform.MonsterId)		
		else
			local model = 
				{
					BodyAssetPath = event.Transform.BodyAssetPath,
					HeadAssetPath = event.Transform.HeadAssetPath,
					HairAssetPath = event.Transform.HairAssetPath,
					WeaponTid = event.Transform.WeaponItemTid  --(注意！！！！是模板Id)
				}
			entity:ChangeAllPartShape(model, nil)
		end

		if entity:IsHostPlayer() then
			if not event.Transform.KeepSkill then
				local skills = {}
				for i = 1, 6 do
					local id = event.Transform["Skill" .. i]
					skills[#skills + 1] = id
				end
				entity:UpdateTransformSkills(skills)
			end

			entity:SetForbidDrugState(event.Transform.ForbidUseBlood)

			local event = ChangeShapeEvent()
			CGame.EventManager:raiseEvent(nil, event)
		end
	end
end

def.override().OnBuffEnd = function(self)	
	local entity = self._Host
	if entity ~= nil and not entity:IsReleased() then
		local event = self._Event	

		if event.Transform.TransformType == 0 then
			entity:ResetModelShape()
		else  -- 身体部分切换
			entity:ResetPartShape(nil)
		end

		if entity:IsHostPlayer() then
			if not event.Transform.KeepSkill then				
				entity:UpdateTransformSkills(nil)
			end

			entity:SetForbidDrugState(false)

			local event = ChangeShapeEvent()
			CGame.EventManager:raiseEvent(nil, event)
		end
	end

	CBuffEventBase.OnBuffEnd(self)
end

CBuffTransform.Commit()
return CBuffTransform