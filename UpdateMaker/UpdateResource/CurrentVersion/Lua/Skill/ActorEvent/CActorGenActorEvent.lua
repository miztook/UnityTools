local Lplus = require "Lplus"
local Template = require "PB.Template"
local CActorEventBase = require "Skill.ActorEvent.CActorEventBase"
local CFxObject = require "Fx.CFxObject"

local CActorGenActorEvent = Lplus.Extend(CActorEventBase, "CActorGenActorEvent")
local def = CActorGenActorEvent.define

def.field("boolean")._DisappearWhenParentEntityRelease = false

def.static("table", "table", "=>", CActorGenActorEvent).new = function (event, params)
	local obj = CActorGenActorEvent()
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
	if actor_id == 0 then return end  -- 0 为占位符

	local CElementSkill = require "Data.CElementSkill"
	local actor_template = CElementSkill.GetActor(actor_id)
	if actor_template == nil then return end

	-- 非客户端特效Actor走子物体逻辑
	if actor_template.Type ~= Template.Actor.ActorType.Gfx then
		return 
	end

	local param = {} 
	param.BelongedSubobject = self._Params.BelongedSubobject
	param.BelongedCreature = self._Params.BelongedCreature
	param.TargetId = self._Params.TargetId
	param.BirthPlace = self._Event.BirthPlace
	param.BirthPlaceParam = self._Event.BirthPlaceParam
	param.GenerateCount = self._Event.GenerateCount
	param.GenerateAngle = self._Event.GenerateAngle

	local CSkillActorMan = require "Skill.CSkillActorMan"
	CSkillActorMan.Instance():GenerateClientActor(actor_template, param)
	self._DisappearWhenParentEntityRelease = actor_template.DisappearConditionOriginEntityDead
end

CActorGenActorEvent.Commit()
return CActorGenActorEvent