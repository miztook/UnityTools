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

def.field("boolean")._StateOnRide = false
def.field("boolean")._StateHasWing = false
def.field("boolean")._StateInCombat = false

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

local function callbackMove(ret, self)
	if ret == 1 then
		if self._OnMoveEndSuccess ~= nil then
			self._OnMoveEndSuccess()
		elseif self._Host then
			self._Host:Stand()
		end
	else
		if self._OnMoveEndFail ~= nil then
			self._OnMoveEndFail()
		elseif self._Host then
			self._Host:Stand()
		end
	end		
end

def.override("number", "=>").EnterState = function(self, oldstate)
    --warn("CFSMObjMove EnterState", debug.traceback())
	CFSMStateBase.EnterState(self, oldstate)
	
	 -- 翅膀动作要比人物动作先更新，因为人物动作的更新会导致翅膀动作改变
	if self._Mountable then			
		self._Host:UpdateWingAnimation()
		self:PlayMountStateAnimation(oldstate)

		self._StateHasWing = self._Host._WingModel ~= nil
		self._StateOnRide = self._Host:IsClientMounting()
		self._StateInCombat = self._Host:IsInCombatState()
	else
		self:PlayStateAnimation(oldstate)	

		self._StateHasWing = false
		self._StateOnRide = self._Host:IsClientMounting()	
		self._StateInCombat = self._Host:IsInCombatState()
	end
	
	local root = self._Host:GetGameObject()
	local speed = self._Speed

	local function cb(ret)
		callbackMove(ret, self)
	end
	if self._TargetPos ~= nil then
		GameUtil.AddMoveBehavior(root, self._TargetPos, speed, cb, true)
	elseif self._TargetId ~= 0 then
		local target = game._CurWorld:FindObject(self._TargetId)
		if target ~= nil and target:GetGameObject() ~= nil then
			GameUtil.AddFollowBehavior(root, target:GetGameObject(), self._Speed, self._FollowParams.MaxDis, self._FollowParams.MinDis, true, cb)
		else
			warn("AddFollowBehavior param is nil")
		end
	end
end

def.override("number").PlayStateAnimation = function(self, oldstate)	
	local animation, wingAnimation, ratePlay = self._Host:GetEntityFsmAnimation(FSM_STATE_TYPE.MOVE)
	self._Host:PlayAnimation(animation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay)
	self._Host:PlayWingAnimation(wingAnimation, EnumDef.SkillFadeTime.MonsterOther, false, 0, ratePlay, false)
end

def.override("number").PlayMountStateAnimation = function(self,oldstate)
	if self._Host:IsClientMounting() then
		local baseSpeed,fightSpeed = self._Host:GetBaseSpeedAndFightSpeed()
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

def.method().Update = function ( self )
	local go = self._Host:GetGameObject()

	--状态变化后才更新动画
	if self._Mountable then		
		local curStateWing = self._Host._WingModel ~= nil
		local curStateRide = self._Host:IsClientMounting()
		local curStateInCombat = self._Host:IsInCombatState()

		if curStateWing ~= self._StateHasWing or curStateRide ~= self._StateOnRide or curStateInCombat ~= self._StateInCombat then
			self._Host:UpdateWingAnimation()
			self:PlayMountStateAnimation(self._Type)
		end

		self._StateHasWing = curStateWing
		self._StateOnRide = curStateRide
		self._StateInCombat = curStateInCombat
	else
		local curStateWing = false
		local curStateRide = self._Host:IsClientMounting()
		local curStateInCombat = self._Host:IsInCombatState()

		if curStateWing ~= self._StateHasWing or curStateRide ~= self._StateOnRide or curStateInCombat ~= self._StateInCombat then
			self:PlayStateAnimation(self._Type)	
		end

		self._StateHasWing = curStateWing
		self._StateOnRide = curStateRide
		self._StateInCombat = curStateInCombat
	end

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
			warn("AddFollowBehavior param is nil")
		end
	end
end

def.override().UpdateWhenBecomeVisible = function(self)
	local go = self._Host:GetGameObject()

	--状态变化后才更新动画
	if self._Mountable then		
		self._Host:UpdateWingAnimation()
		self:PlayMountStateAnimation(self._Type)

		self._StateHasWing = self._Host._WingModel ~= nil
		self._StateOnRide = self._Host:IsClientMounting()
		self._StateInCombat = self._Host:IsInCombatState()
	else
		self:PlayStateAnimation(self._Type)

		self._StateHasWing = false
		self._StateOnRide = self._Host:IsClientMounting()
		self._StateInCombat = self._Host:IsInCombatState()
	end

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
			warn("AddFollowBehavior param is nil")
		end
	end
end

CFSMObjMove.Commit()
return CFSMObjMove