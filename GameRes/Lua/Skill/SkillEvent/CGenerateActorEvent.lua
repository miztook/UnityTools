local Lplus = require "Lplus"
local Template = require "PB.Template"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CFxObject = require "Fx.CFxObject"

local CGenerateActorEvent = Lplus.Extend(CSkillEventBase, "CGenerateActorEvent")
local def = CGenerateActorEvent.define

def.static("table", "table", "=>", CGenerateActorEvent).new = function(event, params)
	local obj = CGenerateActorEvent()
	obj._Event = event.GenerateActor
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	if self._Params == nil then 
		warn("event param is nil") 
		return 
	end
	local actor_id = self._Event.ActorId
	local CElementSkill = require "Data.CElementSkill"
	local actor_template = CElementSkill.GetActor(actor_id)
	if actor_template == nil then return end

	-- 非客户端特效Actor走子物体逻辑
	if actor_template.Type ~= Template.Actor.ActorType.Gfx then
		return 
	end

	local param = {}
	param.BelongedSubobject = nil
	param.BelongedCreature = self._Params.BelongedCreature
	param.SkillId = self._Params.SkillId
	param.TargetId = self._Params.TargetId
	param.BirthPlace = self._Event.BirthPlace
	param.BirthPlaceParam = self._Event.BirthPlaceParam
	param.GenerateCount = self._Event.GenerateCount
	param.GenerateAngle = self._Event.GenerateAngle
	
	local CSkillActorMan = require "Skill.CSkillActorMan"
	CSkillActorMan.Instance():GenerateClientActor(actor_template, param)
end

def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CGenerateActorEvent.Commit()
return CGenerateActorEvent