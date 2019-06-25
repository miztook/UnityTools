local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CHostPlayer = Lplus.ForwardDeclare("CHostPlayer")

local CFSMHostSkill = Lplus.Extend(CFSMStateBase, "CFSMHostSkill")
local def = CFSMHostSkill.define

def.field("string")._Animation = ""
def.field("boolean")._IsHalfBody = false

def.final(CHostPlayer, "string", "dynamic", "=>", CFSMHostSkill).new = function (hostplayer, ani, half)
	local obj = CFSMHostSkill()
	obj._Host = hostplayer
	obj._Type = FSM_STATE_TYPE.SKILL
	obj._Animation = ani
	obj._IsHalfBody = half or false
	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return not self._Host:IsDead()
end

def.override("number").EnterState = function(self, oldstate)
	CFSMStateBase.EnterState(self, oldstate)
	self._Host:StopHurAnimation()
	self._Host:UpdateWingAnimation()

	if not self._IsHalfBody then
		self._Host:PlayAnimation(self._Animation, EnumDef.SkillFadeTime.HostSkill, false, 0, 1)
	else
		self._Host:PlayPartialAnimation(self._Animation)
	end
end

def.override().LeaveState = function(self)
	self._IsValid = false
	self._IsHalfBody = false
	self._Host = nil
end

def.override(CFSMStateBase).UpdateState = function(self, newstate)
	self._Animation = newstate._Animation
	self._IsHalfBody = newstate._IsHalfBody
	if not self._IsHalfBody then
		self._Host:PlayAnimation(self._Animation, EnumDef.SkillFadeTime.HostSkill, false, 0, 1)
	else
		self._Host:PlayPartialAnimation(self._Animation)
	end
end


CFSMHostSkill.Commit()
return CFSMHostSkill