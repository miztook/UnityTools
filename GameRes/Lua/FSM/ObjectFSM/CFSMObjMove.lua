local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CPlayer = Lplus.ForwardDeclare("CPlayer")
local CGame = Lplus.ForwardDeclare("CGame")

local CFSMObjMove = Lplus.Extend(CFSMStateBase, "CFSMObjMove")
local def = CFSMObjMove.define

def.field("number")._TargetId = 0
def.field("function")._OnMoveEndSuccess = nil
def.field("function")._OnMoveEndFail = nil
def.field("number")._Speed = 0 
def.field("table")._FollowParams = nil
def.field("table")._TargetPos = nil

def.final(CEntity, "dynamic", "number", "function", "function", "=>", CFSMObjMove).new = function (object, target,speed, successcb, failcb)
	local obj = CFSMObjMove()
	obj._Host = object
	obj._Type = FSM_STATE_TYPE.MOVE
	obj._OnMoveEndSuccess = successcb
	obj._OnMoveEndFail = failcb

	if Lplus.is(target, CEntity) then
		obj._TargetId = target._ID
		obj._TargetPos = nil
	else
		obj._TargetId = 0
		obj._TargetPos = target
	end


	obj._Speed = speed

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
    --warn("CFSMObjMove EnterState", debug.traceback())
	CFSMStateBase.EnterState(self, oldstate)
	
	self._Host:UpdateWingAnimation() -- 翅膀动作要比人物动作先更新，因为人物动作的更新会导致翅膀动作改变
	if self._Mountable then			--动画
		self:PlayMountStateAnimation(oldstate)
	else
		self:PlayStateAnimation(oldstate)		
	end
	
	local root = self._Host:GetGameObject()
	local speed = self._Speed

	local function cb(ret)
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
	if self._TargetPos ~= nil then
		GameUtil.AddMoveBehavior(root, self._TargetPos, speed, cb, true)
	elseif self._TargetId ~= 0 then
		local target = game._CurWorld:FindObject(self._TargetId)
		if target ~= nil and target:GetGameObject() ~= nil then
			GameUtil.AddFollowBehavior(root, target:GetGameObject(), self._Speed, self._FollowParams.MaxDis, self._FollowParams.MinDis, true, cb)
		else
			warn("AddFollowBehavior param is nil", debug.traceback())
		end
	end
end

def.override("number").PlayStateAnimation = function(self, oldstate)	
	local animation, wingAnimation, ratePlay = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.MOVE)
	self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay)
	self._Host:PlayWingAnimation(wingAnimation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay, false)
end

def.override("number").PlayMountStateAnimation = function(self,oldstate)
	local bRide = self._Host:IsOnRide()
	local baseSpeed,fightSpeed = self._Host:GetBaseSpeedAndFightSpeed()
	if self._Host:IsInCombatState() and not self._Host:IsOnRide() then		
		local animation, wingAnimation, ratePlay = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.MOVE)
		self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay)
		self._Host:PlayWingAnimation(wingAnimation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay, false)
	else
		if bRide then
			local horseBaseSpeed = self._Host:GetHorseBaseSpeed(baseSpeed)
			local _, houseRate = self._Host:GetRunAnimationNameAndRate(horseBaseSpeed,horseBaseSpeed)
			self._Host:PlayMountAnimation(EnumDef.CLIP.COMMON_RUN, EnumDef.SkillFadeTime.MonsterOther, false, 0,houseRate)
			local animation = self._Host:GetRideRunAnimationName()
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, false, 0, houseRate)
		else
			local animation, wingAnimation, ratePlay = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.MOVE)
			self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay)
			self._Host:PlayWingAnimation(wingAnimation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay, false)
		end
	end
end

def.override().LeaveState = function(self)
	self._IsValid = false
	self._Host:StopMovementLogic()

	self._OnMoveEndSuccess = nil
	self._OnMoveEndFail = nil
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	self._TargetId = newstate._TargetId
	self._TargetPos = newstate._TargetPos
	self._OnMoveEndSuccess = newstate._OnMoveEndSuccess
	self._OnMoveEndFail = newstate._OnMoveEndFail
	self._Speed = newstate._Speed
	self._FollowParams = newstate._FollowParams
	self:Update()
end

local function callbackMove(ret, self)
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

def.method().Update = function ( self )
	local m = self._Host:GetCurModel()
	local go = self._Host:GetGameObject()

	self:PlayMountStateAnimation(self._Type)
	local cb = function(ret)
		callbackMove(ret, self)
	end

	local speed = self._Speed
	if self._TargetPos ~= nil then
		GameUtil.AddMoveBehavior(go, self._TargetPos, speed, cb, true)
	elseif self._TargetId ~= 0 then
		local target = game._CurWorld:FindObject(self._TargetId)
		if target ~= nil and target:GetGameObject() ~= nil then
			GameUtil.AddFollowBehavior(go, target:GetGameObject(), speed, self._FollowParams.MaxDis, self._FollowParams.MinDis, true, cb)
		else
			warn("AddFollowBehavior param is nil", debug.traceback())
		end
	end
end

CFSMObjMove.Commit()
return CFSMObjMove