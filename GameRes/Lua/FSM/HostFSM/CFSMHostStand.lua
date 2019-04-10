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
	local bRide = self._Host:IsOnRide()
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
		if self._Host:IsInCombatState() and not self._Host:IsOnRide() then
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
				if self._Host:GetMountTid() == 23 or self._Host:GetMountTid() == 24 then    -- 摩托和炮车的TID。。需要配成特殊ID					
					CSoundMan.Instance():Stop3DAudio("motorcycle_run_land","")
					CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land","")
					CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land_stop","")
					CSoundMan.Instance():Play3DAudio("motorcycle_idle", game._HostPlayer:GetPos(), fade_time)	
				
				elseif self._Host:GetMountTid() == 3 then    -- 飞毯的TID。。需要配成特殊ID					
					CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land","")
					CSoundMan.Instance():Stop3DAudio("motorcycle_idle","")
					CSoundMan.Instance():Stop3DAudio("motorcycle_run_land","")	
					CSoundMan.Instance():Play3DAudio("flying_carpet_run_land_stop", game._HostPlayer:GetPos(), 0)					
				else
					CSoundMan.Instance():Stop3DAudio("motorcycle_idle","")
					CSoundMan.Instance():Stop3DAudio("motorcycle_run_land","")	
					CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land","")
					CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land_stop","")
				end
				self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_STAND, fade_time, self._IsAniQueued, 0,1)
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