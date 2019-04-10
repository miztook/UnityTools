local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CSkipEvent = Lplus.Extend(CSkillEventBase, "CSkipEvent")
local def = CSkipEvent.define

def.static("table", "table", "=>", CSkipEvent).new = function(event, params)
	local obj = CSkipEvent()
	obj._Event = event.Skip
	obj._Params = params
	obj._IsToBlockPerformSequence = false
	return obj
end

def.override().OnEvent = function(self)
	local hp = game._HostPlayer
	if self._Params.BelongedCreature == nil or self._Params.BelongedCreature._ID ~= hp._ID then return end

	local CJumpPrecondition = require "Skill.CJumpPrecondition"
	local precondition_id = self._Event.Condition
	local precondition_param = self._Event.ConditionParam1
	if CJumpPrecondition.Check(precondition_id, precondition_param) then
		local hdl = hp._SkillHdl
		local index = hdl:GetPerformIdxById(self._Params.SkillId, self._Event.DestPerformId)

		-- 由于OnPerformJump 可能会注册新的 正常停止事件, 这里清一下
		hdl:ClearSpecialTriggerTypeEvents(TriggerType.All)

		hdl:OnPerformJump(self._Params.SkillId, index, true)
		hdl:ClearComboInfos()
		self._IsToBlockPerformSequence = true
	else
		self._IsToBlockPerformSequence = false
	end
end

CSkipEvent.Commit()
return CSkipEvent
