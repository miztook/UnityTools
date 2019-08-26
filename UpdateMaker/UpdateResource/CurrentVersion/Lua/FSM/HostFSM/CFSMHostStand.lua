local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CHostPlayer = Lplus.ForwardDeclare("CHostPlayer")

local CFSMHostStand = Lplus.Extend(CFSMStateBase, "CFSMHostStand")
local def = CFSMHostStand.define

def.field("boolean")._IsAniQueued = false

def.final(CHostPlayer, "=>", CFSMHostStand).new = function (hostplayer)
	local obj = CFSMHostStand()
	obj._Host = hostplayer
	obj._Type = FSM_STATE_TYPE.IDLE

	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return not self._Host:IsDead()
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


def.override("number").EnterState = function(self, oldstate)
	--print("CFSMHostStand EnterState", debug.traceback())
	CFSMStateBase.EnterState(self, oldstate)
	self._Host:StopMovementLogic()
	self:PlayMountStateAnimation(oldstate)
	self._Host:UpdateWingAnimation()
end

def.override("number").PlayMountStateAnimation = function(self, oldstate)
	local bRide = self._Host:IsClientMounting()
	if oldstate == FSM_STATE_TYPE.NONE then
		if bRide then
			local fade_time = EnumDef.SkillFadeTime.HostOther
			local animation = self._Host:GetRideStandAnimationName()
			if self._Host:IsPlayingAnimation(animation) then
				-- 在坐骑上相同动作时不做融合，直接从头播放
				fade_time = 0
			end
			self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_STAND, fade_time, self._IsAniQueued, 0,1)
			self._Host:PlayAnimation(animation, fade_time, self._IsAniQueued, 0, 1)
			StarHorseStandBehaviourComp(self)
		else
			local animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, self._IsAniQueued, 0, 1)
			StopHorseStandBehaviourComp(self)
		end
	else
		if self._Host:IsInCombatState() and not bRide then
			local animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, self._IsAniQueued, 0, 1)
		else
			if bRide then
				local fade_time = EnumDef.SkillFadeTime.HostOther
				local animation = self._Host:GetRideStandAnimationName()
				if self._Host:IsPlayingAnimation(animation) then
					-- 在坐骑上相同动作时不做融合，直接从头播放
					fade_time = 0
				end
				self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_STAND, fade_time, self._IsAniQueued, 0,1)
				self._Host:PlaySpecialMountStandSound(fade_time)
				self._Host:PlayAnimation(animation, fade_time, self._IsAniQueued, 0, 1)
				StarHorseStandBehaviourComp(self)				
			else
				local animation = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.IDLE)
				self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, self._IsAniQueued, 0, 1)
				StopHorseStandBehaviourComp(self)
				CSoundMan.Instance():Stop3DAudio("motorcycle_idle","")
				CSoundMan.Instance():Stop3DAudio("motorcycle_run_land","")	
			end
		end	
	end		
end

def.override().LeaveState = function(self)
	StopHorseStandBehaviourComp(self)
	self._IsValid = false
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	self:PlayMountStateAnimation(self._Type)
end

CFSMHostStand.Commit()
return CFSMHostStand