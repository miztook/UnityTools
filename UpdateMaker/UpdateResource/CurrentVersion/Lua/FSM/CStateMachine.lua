local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"

local CStateMachine = Lplus.Class("CStateMachine")
local def = CStateMachine.define

def.field(CFSMStateBase)._CurState = nil

def.final("=>", CStateMachine).new = function ()
	local obj = CStateMachine()
	return obj
end

def.method(CFSMStateBase, "=>", "boolean").ChangeState = function(self, state)
	if state == nil then
		if self._CurState then
			self._CurState:LeaveState()
			self._CurState = nil
		end
		return true
	end

	if self._CurState == nil then
		self._CurState = state
		state:EnterState(0)
		self._CurState = state
		return true
	end

	if self._CurState._IsValid then
		if not state:TryEnterState(self._CurState._Type) then
			return false
		end
	end
	if state._Type == self._CurState._Type then
		self:UpdateStateParam(state)
		self._CurState:UpdateState(state)
	else
		if self._CurState._IsValid then
			self._CurState:LeaveState()
		end
		local oldstate = self._CurState
		self._CurState = state
		self._CurState:EnterState(oldstate._Type)
	end
	return true
end

def.method("=>", CFSMStateBase).GetCurrentState = function (self)
	return self._CurState
end

def.method(CFSMStateBase).UpdateStateParam = function (self, state)
	if state._Type == FSM_STATE_TYPE.IDLE then
		self._CurState._IsAniQueued = state._IsAniQueued
	end
end

def.method("=>", "boolean").UpdateCurStateWhenBecomeVisible = function (self)
	if self._CurState ~= nil then
		self._CurState:UpdateWhenBecomeVisible()
		return true
	end

	return false
end

def.method().UpdateMoveStateAnimation = function (self)
	self._CurState:PlayMountStateAnimation(0)
end

def.method().Release = function(self)
	if self._CurState ~= nil then
		self._CurState:LeaveState()
		self._CurState = nil
	end
end

CStateMachine.Commit()
return CStateMachine