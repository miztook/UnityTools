local Lplus = require "Lplus"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CEntity = Lplus.ForwardDeclare("CEntity")

local CFSMObjSkill = Lplus.Extend(CFSMStateBase, "CFSMObjSkill")
local def = CFSMObjSkill.define

def.field("string")._Animation = ""
def.field("boolean")._IsHalfBody = false


def.final(CEntity, "string", "dynamic", "=>", CFSMObjSkill).new = function (o, ani, half)
	local obj = CFSMObjSkill()
	obj._Host = o
	obj._Type = FSM_STATE_TYPE.SKILL
	obj._Animation = ani
	obj._IsHalfBody = half or false
	obj:CheckMountable()
	return obj
end

def.override("number", "=>", "boolean").TryEnterState = function(self, oldstate)
	return not self._Host:IsDead() or self._Host._SkillHdl:IsCastingDeathSkill()
end

def.override("number").EnterState = function(self, oldstate)
	CFSMStateBase.EnterState(self, oldstate)
	self._Host:StopHurAnimation()

	if self._Mountable then			
		self._Host:UpdateWingAnimation()
	end

	if not self._IsHalfBody then
		self._Host:PlayAnimation(self._Animation, EnumDef.SkillFadeTime.MonsterSkill, false, 0, 1)
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
	-- 技能动作按照技能配置执行，存在不同相连段播放同一个动作的情况  -- added by lijian
	--if self._Animation ~= newstate._Animation or self._IsHalfBody ~= newstate._IsHalfBody then
		self._Animation = newstate._Animation
		self._IsHalfBody = newstate._IsHalfBody

		if not self._IsHalfBody then
			self._Host:PlayAnimation(self._Animation, EnumDef.SkillFadeTime.MonsterSkill, false, 0, 1)
		else
			self._Host:PlayPartialAnimation(self._Animation)
		end
	--end
end

-- 隐身期间，所有技能表现均已经忽略，只要回到最终状态就OK
def.override().UpdateWhenBecomeVisible = function(self)
	local ani = self._Host:IsInServerCombatState() and EnumDef.CLIP.BATTLE_STAND or EnumDef.CLIP.COMMON_STAND
	self._Host:PlayAnimation(ani, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
end

CFSMObjSkill.Commit()
return CFSMObjSkill