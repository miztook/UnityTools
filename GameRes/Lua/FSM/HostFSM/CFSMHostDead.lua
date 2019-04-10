local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CHostPlayer = Lplus.ForwardDeclare("CHostPlayer")
local CSharpEnum = require "Main.CSharpEnum"
local CModel = require "Object.CModel"

local CFSMHostDead = Lplus.Extend(CFSMStateBase, "CFSMHostDead")
local def = CFSMHostDead.define



def.final(CHostPlayer, "=>", CFSMHostDead).new = function (ecobj)
	local obj = CFSMHostDead()
	obj._Host = ecobj
	obj._Type = FSM_STATE_TYPE.DEAD

	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return not self._Host:IsDead()
end

def.override("number").EnterState = function(self, oldstate)
	CFSMStateBase.EnterState(self, oldstate)
	self._Host:PlayDieAnimation(false)
	self._Host:StopMovementLogic()
	self._Host:SetAutoPathFlag(false)
end

def.override().LeaveState = function(self)
	self._IsValid = false
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	warn("Cann't Dead Twice")
end

CFSMHostDead.Commit()
return CFSMHostDead