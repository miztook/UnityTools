local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"
local CPanelSkillSlot = require "GUI.CPanelSkillSlot"

local CBuffChangeSkillIcon = Lplus.Extend(CBuffEventBase, "CBuffChangeSkillIcon")
local def = CBuffChangeSkillIcon.define

def.static("table", "table", "=>", CBuffChangeSkillIcon).new = function(host, event)
	if host == nil or host._ID ~= game._HostPlayer._ID then return nil end

	local obj = CBuffChangeSkillIcon()
	obj._Event  = event
	return obj
end

def.override().OnEvent = function(self)
	local skillId = self._Event.ChangeSkillIcon.SKillId
	local cconPath = self._Event.ChangeSkillIcon.IconPath
	CPanelSkillSlot.Instance():ChangeSkillIconByBuffEvent(skillId, cconPath)
end

def.override().OnBuffEnd = function(self)	
	local skillId = self._Event.ChangeSkillIcon.SKillId
	CPanelSkillSlot.Instance():ChangeSkillIconByBuffEvent(skillId, "")

	CBuffEventBase.OnBuffEnd(self)
end

CBuffChangeSkillIcon.Commit()
return CBuffChangeSkillIcon