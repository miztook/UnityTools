local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CEntity = Lplus.ForwardDeclare("CEntity")
local Template = require "PB.Template"
local ClinetData = require "PB.data"
local CFSMObjDead = Lplus.Extend(CFSMStateBase, "CFSMObjDead")
local def = CFSMObjDead.define

def.field("number")._ElementType = 0 
def.field("number")._HitType = 0
def.field("number")._CorpseStayDuration = 0
def.field("boolean")._AlreadyDead = false

def.final(CEntity, "number", "number", "number", "boolean", "=>", CFSMObjDead).new = function (ecobj, element_type, hit_type, corpse_stay_duration, bAlreadyDead)
	local obj = CFSMObjDead()
	obj._Host = ecobj
	obj._Type = FSM_STATE_TYPE.DEAD
	obj._ElementType = element_type
	obj._HitType = hit_type
	obj._CorpseStayDuration = corpse_stay_duration
	obj._AlreadyDead = bAlreadyDead

	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return true
end

def.override("number").EnterState = function(self, oldstate)
	--warn("CFSMObjDead EnterState", self._Host._ID, self._AlreadyDead, debug.traceback())
	CFSMStateBase.EnterState(self, oldstate)
	if self._AlreadyDead then
		self._Host:PlayDieAnimation(true)
		self._Host:StopMovementLogic()
	else
		self._Host:PlayDieAnimation(false)
		self._Host:StopMovementLogic()
	end
end

def.override().LeaveState = function(self)
	self._IsValid = false
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	warn("Cann't Dead Twice")
end

def.override().UpdateWhenBecomeVisible = function(self)
	self._Host:PlayDieAnimation(true)
end

CFSMObjDead.Commit()
return CFSMObjDead