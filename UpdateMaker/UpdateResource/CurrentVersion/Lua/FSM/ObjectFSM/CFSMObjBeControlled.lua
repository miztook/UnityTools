local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CPlayer = Lplus.ForwardDeclare("CPlayer")
local JudgementHitType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitType

local CFSMObjBeControlled = Lplus.Extend(CFSMStateBase, "CFSMObjBeControlled")
local def = CFSMObjBeControlled.define

def.field("table")._Params = nil
def.field("table")._MoveDir = nil
def.field("table")._MoveDest = nil
def.field("table")._AnimationTimers = nil
def.field("number")._StartTime = 0 --当前控制状态开始时间
def.field("number")._ControlType = 0   -- 1 硬直 2 - 击退 3 - 击倒 4 - 击飞 5 - 眩晕 6 - 冰冻

def.final(CEntity, "number", "table", "table", "=>", CFSMObjBeControlled).new = function (ecobj, ctype, params, dest)
	local obj = CFSMObjBeControlled()
	obj._Host = ecobj
	obj._Type = FSM_STATE_TYPE.BE_CONTROLLED
	obj._ControlType = ctype
	obj._Params = params
	obj._MoveDest = dest

	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return not self._Host:IsDead()
end

local function Update(self)
	local host = self._Host
    self._StartTime = Time.time
	self._AnimationTimers = {}
	local hit_params = self._Params
	if self._ControlType == JudgementHitType.Stiffness then
		if not host:IsPlayingAnimation(EnumDef.CLIP.NORMAL_HURT) then
			host:GetCurModel():PlayHurtAnimation(false, host:GetHurtAnimation())
		end
		if host:IsPlayingAnimation(EnumDef.CLIP.COMMON_RUN) or host:IsPlayingAnimation(EnumDef.CLIP.BATTLE_RUN) then
			if host:IsInCombatState() then
				host:PlayAnimation(EnumDef.CLIP.BATTLE_STAND, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
			else
				host:PlayAnimation(EnumDef.CLIP.COMMON_STAND, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
			end
		end
	elseif self._ControlType == JudgementHitType.Knockback then
		if not host:IsPlayingAnimation(EnumDef.CLIP.NORMAL_HURT) then
			host:GetCurModel():PlayHurtAnimation(false, host:GetHurtAnimation())
		end
		if host:IsPlayingAnimation(EnumDef.CLIP.COMMON_RUN) or host:IsPlayingAnimation(EnumDef.CLIP.BATTLE_RUN) then
			if host:IsInCombatState() then
				host:PlayAnimation(EnumDef.CLIP.BATTLE_STAND, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
			else
				host:PlayAnimation(EnumDef.CLIP.COMMON_STAND, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
			end
		end

		if host:IsHostPlayer() then
			GameUtil.SetGameCamCtrlParams(true, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)
		end
		
		local dis = hit_params[1]
		local time = hit_params[2]/1000
		if time ~= 0 then
			local root = host:GetGameObject()
			GameUtil.AddMoveBehavior(root, self._MoveDest, dis/time, function(ret) 		
					if host:IsHostPlayer() then					
						GameUtil.SetGameCamCtrlParams(false, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)
					end
				end, false)
		else
			host:SetPos(self._MoveDest)
		end
	elseif self._ControlType == JudgementHitType.Knockdown then
		local time = hit_params[1]/1000
		local ani = {"hurt_fell_c", "standup_c"} 
		-- 落地过程-保持在最后一帧
		host:StopHurAnimation()
		host:PlayClampForeverAnimation(ani[1], 0, false, 0)
		-- 起身阶段
		local standup_start_time = time - host:GetAnimationLength(ani[2]) -- 持续倒地时间
		self._AnimationTimers[1] = host:AddTimer(standup_start_time, true, function()
				if not host:IsDead() then
					host:PlayAnimation(ani[2], EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
				end
			end)
	elseif self._ControlType == JudgementHitType.KnockIntoTheAir then
		local dis = hit_params[1]
		local fly_time = hit_params[2]/1000
		local fallen_time = hit_params[3]/1000
		local ani = {"hurt_fly_c", "hurt_fallen_c", "standup_c"}
		-- 击飞过程-先播击飞动作，动作时间可缩放
		host:StopHurAnimation()
		host:PlayAnimation(ani[1], EnumDef.SkillFadeTime.MonsterOther, false, fly_time, 1)
		-- 落地过程-保持在最后一帧
		self._AnimationTimers[1] = host:AddTimer(fly_time, true, function()
				if not host:IsDead() then
					host:PlayClampForeverAnimation(ani[2], 0, false, 0)
				end
			end)
		-- 起身阶段
		local standup_start_time = fly_time + fallen_time - host:GetAnimationLength(ani[3]) -- 持续倒地时间

		self._AnimationTimers[2] = host:AddTimer(standup_start_time, true, function()
				if not host:IsDead() then
					host:PlayAnimation(ani[3], EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)			
				end
			end)
		if host:IsHostPlayer() then
			GameUtil.SetGameCamCtrlParams(true, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)
		end
		if fly_time ~= 0 then
			local root = host:GetGameObject()
			GameUtil.AddMoveBehavior(root, self._MoveDest, dis/fly_time, function(ret)
				if host:IsHostPlayer() then 
					GameUtil.SetGameCamCtrlParams(false, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)
				end
			end, false)
		else
			host:SetPos(self._MoveDest)
		end
	end
end

local function ClearTimers(self)
	local timer_ids = self._AnimationTimers
	if timer_ids ~= nil then
		for _,v in ipairs(timer_ids) do
			self._Host:RemoveTimer(v)
		end
	end
	self._AnimationTimers = nil
end

def.override("number").EnterState = function(self, oldstate)
	--warn("CFSMObjBeControlled EnterState", Time.time, debug.traceback())
	CFSMStateBase.EnterState(self, oldstate)
	Update(self)
end

def.override().LeaveState = function(self)
	--warn("CFSMObjBeControlled EnterState", Time.time, debug.traceback())
	self._IsValid = false
	ClearTimers(self)
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	if self._ControlType == JudgementHitType.Knockback then 
		-- 击倒、击飞有效，进入新状态
		if newstate._ControlType == JudgementHitType.Knockback 
			or newstate._ControlType == JudgementHitType.Knockdown
			or newstate._ControlType == JudgementHitType.KnockIntoTheAir then
			self._ControlType = newstate._ControlType
			self._Params = newstate._Params
			self._MoveDest = newstate._MoveDest
			Update(self)
		end
	elseif self._ControlType == JudgementHitType.Stiffness then 
		-- 受到硬直，重新播放挨打动画，硬直时间取较长的硬直时间
		if newstate._ControlType == JudgementHitType.Stiffness then
			self._ControlType = newstate._ControlType
			self._Params = newstate._Params
			self._MoveDest = newstate._MoveDest
			Update(self)
		-- 击退、击倒、击飞都有效，进入新状态
		elseif newstate._ControlType == JudgementHitType.Knockback 
			or newstate._ControlType == JudgementHitType.Knockdown 
			or newstate._ControlType == JudgementHitType.KnockIntoTheAir then
			ClearTimers(self)
			self._ControlType = newstate._ControlType
			self._Params = newstate._Params
			self._MoveDest = newstate._MoveDest
			Update(self)
		end
	end
end

def.override().UpdateWhenBecomeVisible = function(self)
	-- 简化处理
	self._Host:PlayAnimation(EnumDef.CLIP.BATTLE_STAND, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
end

CFSMObjBeControlled.Commit()
return CFSMObjBeControlled