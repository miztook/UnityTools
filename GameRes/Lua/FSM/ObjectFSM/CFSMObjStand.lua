local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CPlayer = Lplus.ForwardDeclare("CPlayer")
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE

local CFSMObjStand = Lplus.Extend(CFSMStateBase, "CFSMObjStand")
local def = CFSMObjStand.define

def.field("boolean")._IsAniQueued = false

def.final(CEntity, "=>", CFSMObjStand).new = function (ecobj)
	local obj = CFSMObjStand()
	obj._Host = ecobj
	obj._Type = FSM_STATE_TYPE.IDLE

	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return not self._Host:IsDead()
end

def.override("number").EnterState = function(self, oldstate)
	--warn("CFSMHostStand EnterState", self._Host._ID, debug.traceback())
	CFSMStateBase.EnterState(self, oldstate)
	self._Host:StopMovementLogic()
	
	if self._Mountable then			--动画
		self:PlayMountStateAnimation(oldstate)
	else
		self:PlayStateAnimation(oldstate)		
	end

	self._Host:UpdateWingAnimation()
end

local function StarStandBehaviourComp(self)
	local comp = self._Host:RequireStandBehaviourComp()
	if comp ~= nil then
		comp:StartIdle()
	end
end

local function StopStandBehaviourComp(self)
	local comp = self._Host:GetStandBehaviourComp()
	if comp ~= nil then 
		comp:StopIdle() 
	end
end

local function StarHorseStandBehaviourComp(self)
	local comp = self._Host:RequireHorseStandBehaviourComp()
	if comp ~= nil then
		comp:StartIdle()
	end
end

local function StopHorseStandBehaviourComp(self)
	local comp = self._Host:GetHorseStandBehaviourComp()
	if comp ~= nil then 
		comp:StopIdle() 
	end
end

-- 非玩家才调用此接口
def.override("number").PlayStateAnimation = function(self, oldstate)
	-- 若为NPC，在普通站立时需要表现休闲动作
	if self._Host:GetObjectType() == OBJ_TYPE.NPC then
		if self._Host:IsInCombatState() then
			StopStandBehaviourComp(self)
			local ani = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)
			self._Host:PlayAnimation(ani, EnumDef.SkillFadeTime.MonsterOther, self._IsAniQueued, 0, 1)
		else
			StarStandBehaviourComp(self)
		end
	else
		-- 如果战斗状态下没有BATTLE_STAND，则换播COMMON_STAND
		local ani = EnumDef.CLIP.COMMON_STAND	
		if self._Host:IsInCombatState() and self._Host:HasAnimation(EnumDef.CLIP.BATTLE_STAND) then
			ani = EnumDef.CLIP.BATTLE_STAND
		end

		local animation = ani
		if self._Host:IsPlayerType() and self._Host:GetChangePoseState() then			
			animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)	
		end	
		self._Host:PlayAnimation(ani, EnumDef.SkillFadeTime.MonsterOther, self._IsAniQueued, 0, 1)
	end
end

def.override("number").PlayMountStateAnimation = function(self, oldstate)
	local bRide = self._Mountable and self._Host:IsOnRide()
	if self._Host:IsInCombatState() and not self._Host:IsOnRide()then
		if self._Host:HasAnimation(EnumDef.CLIP.BATTLE_STAND) then
			local animation = EnumDef.CLIP.BATTLE_STAND
			if self._Host:IsPlayerType() and self._Host:GetChangePoseState() then
				animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)	
			end		
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, self._IsAniQueued, 0, 1)
		else
			if bRide then
				local fade_time = EnumDef.SkillFadeTime.MonsterOther
				local animation = self._Host:GetRideStandAnimationName()
				if self._Host:IsPlayingAnimation(animation) then
					-- 在坐骑上相同动作时不做融合，直接从头播放
					fade_time = 0
				end
				self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_STAND, fade_time, self._IsAniQueued, 0,1)
				self._Host:PlayAnimation(animation, fade_time, self._IsAniQueued, 0, 1)
				StarHorseStandBehaviourComp(self)
			else
				local animation = EnumDef.CLIP.COMMON_STAND
				if self._Host:IsPlayerType() and self._Host:GetChangePoseState() then
					animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)	
				end
				self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, self._IsAniQueued, 0, 1)
				StopHorseStandBehaviourComp(self)
			end
		end
	else
		if bRide then
			local fade_time = EnumDef.SkillFadeTime.MonsterOther
			local animation = self._Host:GetRideStandAnimationName()
			if self._Host:IsPlayingAnimation(animation) then
				-- 在坐骑上相同动作时不做融合，直接从头播放
				fade_time = 0
			end
			self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_STAND, fade_time, self._IsAniQueued, 0,1)
			self._Host:PlayAnimation(animation, fade_time, self._IsAniQueued, 0, 1)
			StarHorseStandBehaviourComp(self)
		else
			local animation = EnumDef.CLIP.COMMON_STAND
			if self._Host:IsPlayerType() and self._Host:GetChangePoseState() then
				animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)	
			end	
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, self._IsAniQueued, 0, 1)
			StopHorseStandBehaviourComp(self)
		end
	end
end

def.override().LeaveState = function(self)
	StopStandBehaviourComp(self)
	StopHorseStandBehaviourComp(self)
	self._IsValid = false
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	if self._Mountable then
		self:PlayMountStateAnimation(self._Type)
	else
		self:PlayStateAnimation(self._Type)		
	end	
end

CFSMObjStand.Commit()
return CFSMObjStand