local Lplus = require "Lplus"
local CSkillEventBase = Lplus.ForwardDeclare("CSkillEventBase")
local EVENT_TYPE = require "Skill.SkillDef".EVENT_TYPE

local CSkillEventFactory = Lplus.Class("CSkillEventFactory")
local def = CSkillEventFactory.define

local CreatFunctions =
	{
		[EVENT_TYPE.AfterImage] = require "Skill.SkillEvent.CAfterImageEvent".new,
		[EVENT_TYPE.Animation] = require "Skill.SkillEvent.CAnimationEvent".new,
		[EVENT_TYPE.Audio] = require "Skill.SkillEvent.CAudioEvent".new,
		[EVENT_TYPE.BulletTime] = require "Skill.SkillEvent.CBulletTimeEvent".new,
		[EVENT_TYPE.GenerateActor] = require "Skill.SkillEvent.CGenerateActorEvent".new,
		[EVENT_TYPE.Judgement] = require "Skill.SkillEvent.CJudgementEvent".new,
		[EVENT_TYPE.Skip] = require "Skill.SkillEvent.CSkipEvent".new,
		[EVENT_TYPE.StopSkill] = require "Skill.SkillEvent.CStopSkillEvent".new,
		[EVENT_TYPE.SkillMove] = require "Skill.SkillEvent.CSkillMoveEvent".new, 
		[EVENT_TYPE.StopMove] = require "Skill.SkillEvent.CStopMoveEvent".new, 		
		[EVENT_TYPE.CameraShake] = require "Skill.SkillEvent.CCameraShakeEvent".new,
		[EVENT_TYPE.BlurEffect] = require "Skill.SkillEvent.CBlurEffectEvent".new,
		[EVENT_TYPE.CameraTransform] = require "Skill.SkillEvent.CCameraTransformEvent".new,
		[EVENT_TYPE.Mirages] = require "Skill.SkillEvent.CMiragesEvent".new,
		[EVENT_TYPE.ScreenEffect] = require "Skill.SkillEvent.CScreenEffectEvent".new,
		[EVENT_TYPE.Cloak] = require "Skill.SkillEvent.CCloakEvent".new,
		[EVENT_TYPE.SkillIndicator] = require "Skill.SkillEvent.CSkillIndicatorEvent".new,		
		[EVENT_TYPE.GenerateKnifeLight] = require "Skill.SkillEvent.CGenerateKnifeLightEvent".new,
		[EVENT_TYPE.ResetTargetPos] = require "Skill.SkillEvent.CResetTargetPosEvent".new,
		[EVENT_TYPE.PopSkillName] = require "Skill.SkillEvent.CPopSkillNameEvent".new,
		[EVENT_TYPE.PopSkillTips] = require "Skill.SkillEvent.CPopSkillTipsEvent".new,
		[EVENT_TYPE.ContinuedTurn] = require "Skill.SkillEvent.CContinuedTurnEvent".new,
		[EVENT_TYPE.CameraEffect] = require "Skill.SkillEvent.CCameraEffectEvent".new,
	}

-- 非瞬时事件列表
-- 此列表中的事件在中断（包含异常和正常）时需要进行效果清理
--[[
local NonInstantMap = 
	{
		[EVENT_TYPE.CameraShake] = 1,
		[EVENT_TYPE.CameraTransform] = 1,
		[EVENT_TYPE.GenerateKnifeLight] = 1,
		[EVENT_TYPE.Audio] = 1,
		[EVENT_TYPE.Judgement] = 1,
		[EVENT_TYPE.PopSkillName]  = 1,
		[EVENT_TYPE.ContinuedTurn]  = 1,
		[EVENT_TYPE.CameraEffect]  = 1,
		[EVENT_TYPE.BlurEffect]  = 1,
		[EVENT_TYPE.ScreenEffect]  = 1,		
		[EVENT_TYPE.BulletTime]  = 1,		
		[EVENT_TYPE.PopSkillTips]  = 1,
	}
]]
local Property2TypeMap =
	{
		{"GenerateActor", EVENT_TYPE.GenerateActor},
		{"Animation", EVENT_TYPE.Animation},
		{"Audio", EVENT_TYPE.Audio},
		{"Judgement", EVENT_TYPE.Judgement},
		{"Skip", EVENT_TYPE.Skip},
		{"StopSkill", EVENT_TYPE.StopSkill},
		{"SkillMove", EVENT_TYPE.SkillMove},
		{"StopMove", EVENT_TYPE.StopMove},
		{"CameraShake", EVENT_TYPE.CameraShake},
		{"MotionBlur", EVENT_TYPE.BlurEffect},
		{"CameraTransform", EVENT_TYPE.CameraTransform},
		{"AfterImage", EVENT_TYPE.AfterImage},
		{"ScreenEffect", EVENT_TYPE.ScreenEffect},
		{"Cloak", EVENT_TYPE.Cloak},
		{"SkillIndicator", EVENT_TYPE.SkillIndicator},
		{"Mirages", EVENT_TYPE.Mirages},
		{"GenerateKnifeLight", EVENT_TYPE.GenerateKnifeLight},
		{"ResetTargetPosition", EVENT_TYPE.ResetTargetPos},
		{"PopSkillName", EVENT_TYPE.PopSkillName},
		{"ContinuedTurn", EVENT_TYPE.ContinuedTurn},
		{"CameraEffect", EVENT_TYPE.CameraEffect},
		{"BulletTime", EVENT_TYPE.BulletTime},
		{"PopSkillTips", EVENT_TYPE.PopSkillTips},
	}

local special_ids = 
	{ 
		EVENT_TYPE.SkillMove, 
		EVENT_TYPE.StopMove, 
		EVENT_TYPE.GenerateActor, 
		EVENT_TYPE.Cloak,
	}

local CheckSpecial = function(type_id)
	for _,v in ipairs(special_ids) do
		if type_id == v then
			return true
		end
	end
	return false
end

local GetEventType = function(event)
	for i,v in ipairs(Property2TypeMap) do
		if event[v[1]]._is_present_in_parent then
			return v[2]
		end
	end
	
	return 0
end

local MakeParams = function(host, skill_id, target_id)
	local is_special = true
	local params = {}
	if is_special then
		params.BelongedCreature = host
		params.SkillId = skill_id
		params.TargetId = target_id
	end
	return params
end

local function createEvent(host, event, skill_id, target_id)
	local e = nil
	local event_type = GetEventType(event)
	local create_func = CreatFunctions[event_type]
	if create_func ~= nil then
		local params = MakeParams(host, skill_id, target_id)
		e = create_func(event, params)
	elseif event_type ~= 0 then
		warn("undefined skill event type ", event_type)
	end
	return e --, (NonInstantMap[event_type] == nil)
end

def.const("function").CreateEvent = createEvent

CSkillEventFactory.Commit()
return CSkillEventFactory
