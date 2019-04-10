local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CEntity = require "Object.CEntity"
local CHostPlayer = Lplus.ForwardDeclare("CHostPlayer")
local CTransManage = require "Main.CTransManage"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local CTargetDetector = require "ObjHdl.CTargetDetector"

local CFSMHostMove = Lplus.Extend(CFSMStateBase, "CFSMHostMove")
local def = CFSMHostMove.define

def.field("number")._TargetId = 0
def.field("function")._OnMoveEndSuccess = nil
def.field("function")._OnMoveEndFail = nil
def.field("number")._MaxDis = 0
def.field("number")._MinDis = 0
def.field("number")._Speed = 0
def.field("number")._Offset = 0
def.field("boolean")._IgnorePosChange = false
def.field("table")._TargetPos = nil
def.field("number")._DetectTimerID = 0

def.final(CHostPlayer, "dynamic", "number", "number", "boolean", "function", "function", "=>", CFSMHostMove).new = function (hostplayer, target, speed, offset, ignoreposchange, successcb, failcb)
	local obj = CFSMHostMove()
	obj._Host = hostplayer
	obj._Type = FSM_STATE_TYPE.MOVE

	if Lplus.is(target, CEntity) then
		obj._TargetId = target._ID
		obj._TargetPos = nil
	else
		obj._TargetId = 0
		obj._TargetPos = target
	end

	obj._OnMoveEndSuccess = successcb
	obj._OnMoveEndFail = failcb
	obj._Speed = speed
	obj._Offset = offset
	obj._IgnorePosChange = ignoreposchange

	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)	
	local world = game._CurWorld
	if not world or not world._IsReady then
		return false
	end	
	return not self._Host:IsDead()
end

def.override("number", "=>").EnterState = function(self, oldstate)
	CFSMStateBase.EnterState(self, oldstate)
	self._Host:UpdateWingAnimation() -- 翅膀动作要比人物动作先更新，因为人物动作的更新会导致翅膀动作改变
	self:PlayMountStateAnimation(oldstate)
	
	local root = self._Host:GetGameObject()

	local cb = function(ret)
		if ret == 1 then
			if self._OnMoveEndSuccess ~= nil then
				self._OnMoveEndSuccess()
			else
				self._Host:Stand()
			end
		else
			if self._OnMoveEndFail ~= nil then
				self._OnMoveEndFail()
			else
				self._Host:Stand()
			end
		end		
	end
	if game._IsUsingJoyStick then		
		GameUtil.AddJoyStickMoveBehavior(root, self._Speed, true)
	elseif self._TargetPos ~= nil then
		GameUtil.AddMoveBehavior(root, self._TargetPos, self._Speed, self._Offset, cb, true, self._Host._IsAutoPathing, self._IgnorePosChange)
	elseif self._TargetId ~= 0 then
		local target = game._CurWorld:FindObject(self._TargetId)
		if target ~= nil and target:GetGameObject() ~= nil then
			GameUtil.AddFollowBehavior(root, target:GetGameObject(), self._Speed, self._MaxDis, self._MinDis, true, cb)
		else
			warn("AddFollowBehavior param is nil", debug.traceback())
		end
	end
	--self._Host:ShowMoveBlurEffect()
	local bRide = self._Host:IsOnRide()
	GameUtil.EnableGroundNormal(self._Host:GetGameObject(), bRide)			--运用地面法向

	--非自动战斗下，移动中索敌
	
	if self._DetectTimerID ~= 0 then
		self._Host:RemoveTimer(self._DetectTimerID)
		self._DetectTimerID = 0
	end

	self._DetectTimerID = self._Host:AddTimer(auto_detector_time, false, function()
					if not CAutoFightMan.Instance():IsOn() then
  						CTargetDetector.Instance():DetectOnce()
  					end
				end)
end

def.override("number").PlayMountStateAnimation = function(self,oldstate)
	local bRide = self._Host:IsOnRide()
	local baseSpeed, fightSpeed = self._Host:GetBaseSpeedAndFightSpeed()
	if self._Host:IsInCombatState() and not self._Host:IsOnRide() then
		local animation, wingAnimation, ratePlay = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.MOVE)
		self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, false, 0, ratePlay)
		self._Host:PlayWingAnimation(wingAnimation, EnumDef.SkillFadeTime.HostOther, false, 0, ratePlay, false)
	else
		if bRide then
			if self._Host:GetMountTid() == 23 or self._Host:GetMountTid() == 24 then    -- 摩托和炮车的TID。。需要配成特殊ID					
				CSoundMan.Instance():Stop3DAudio("motorcycle_idle","")
				CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land","")
				CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land_stop","")
				CSoundMan.Instance():Play3DAudio("motorcycle_run_land", game._HostPlayer:GetPos(), 0)
			elseif self._Host:GetMountTid() == 3 then    -- 飞毯的TID。。需要配成特殊ID					
				CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land_stop","")
				CSoundMan.Instance():Stop3DAudio("motorcycle_idle","")
				CSoundMan.Instance():Stop3DAudio("motorcycle_run_land","")	
				CSoundMan.Instance():Play3DAudio("flying_carpet_run_land", game._HostPlayer:GetPos(), 0)
			else
				CSoundMan.Instance():Stop3DAudio("motorcycle_idle","")
				CSoundMan.Instance():Stop3DAudio("motorcycle_run_land","")	
				CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land","")
				CSoundMan.Instance():Stop3DAudio("flying_carpet_run_land_stop","")	
            end
			local horseBaseSpeed = self._Host:GetHorseBaseSpeed(baseSpeed)
			local _, houseRate = self._Host:GetRunAnimationNameAndRate(horseBaseSpeed,horseBaseSpeed)
			self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_RUN, EnumDef.SkillFadeTime.HostOther, false,0, houseRate)
			local animation = self._Host:GetRideRunAnimationName()
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, false, 0, houseRate)
			
		else
			local animation, wingAnimation, ratePlay = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.MOVE)
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, false, 0, ratePlay)
			self._Host:PlayWingAnimation(wingAnimation, EnumDef.SkillFadeTime.HostOther, false, 0, ratePlay, false)
		end
	end
end

def.override().LeaveState = function(self)
	if self._Host ~= nil and self._DetectTimerID ~= 0 then
		self._Host:RemoveTimer(self._DetectTimerID)
		self._DetectTimerID = 0
	end

	self._IsValid = false
	--self._Host:CloseMoveBlurEffect()
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	self._TargetId = newstate._TargetId
	self._TargetPos = newstate._TargetPos
	self._MaxDis = newstate._MaxDis
	self._MinDis = newstate._MinDis
	self._OnMoveEndSuccess = newstate._OnMoveEndSuccess
	self._OnMoveEndFail = newstate._OnMoveEndFail
	self._Speed = newstate._Speed
	self._Offset = newstate._Offset
	self:Update()
end

def.method().Update = function ( self )
	local host = self._Host	
	local go = host:GetGameObject()
	local bRide = self._Host:IsOnRide()
	local cb = function(ret)
		if ret == 1 then
			if self._OnMoveEndSuccess ~= nil then
				self._OnMoveEndSuccess()
			else
				self._Host:Stand()
			end
		else
			if self._OnMoveEndFail ~= nil then
				self._OnMoveEndFail()
			else
				self._Host:Stand()
			end
		end

		self._Offset = 0
	end

	if game._IsUsingJoyStick then
		GameUtil.AddJoyStickMoveBehavior(go, self._Speed, true)
		GameUtil.EnableGroundNormal(go, bRide)			--运用地面法向
	elseif self._TargetPos ~= nil then
		GameUtil.AddMoveBehavior(go, self._TargetPos, self._Speed, self._Offset, cb, true, self._Host._IsAutoPathing, self._IgnorePosChange)
		GameUtil.EnableGroundNormal(go, bRide)			--运用地面法向
	elseif self._TargetId ~= 0 then
		local target = game._CurWorld:FindObject(self._TargetId)
		if target ~= nil and target:GetGameObject() ~= nil then
			GameUtil.AddFollowBehavior(go, target:GetGameObject(), self._Speed, self._MaxDis, self._MinDis, true, cb)
			GameUtil.EnableGroundNormal(go, bRide)			--运用地面法向
		else
			warn("AddFollowBehavior param is nil", debug.traceback())
		end
	end

	--self._Host:ShowMoveBlurEffect()
end

CFSMHostMove.Commit()
return CFSMHostMove