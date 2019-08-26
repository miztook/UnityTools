local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CElementSkill = require "Data.CElementSkill"
local CPopSkillNameEvent = Lplus.Extend(CSkillEventBase, "CPopSkillNameEvent")
local def = CPopSkillNameEvent.define

def.static("table", "table", "=>", CPopSkillNameEvent).new = function(event, params)
	local obj = CPopSkillNameEvent()
	obj._Event = event.PopSkillName
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)	
	local skill_id = self._Params.SkillId
	local skill = CElementSkill.Get(skill_id) 	
	if skill then
		game._GUIMan:ShowAttentionTips(skill.Name, EnumDef.AttentionTipeType._Boss, self._Event.Duration/1000)	
	end	
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return self._Event.Duration/1000
end

CPopSkillNameEvent.Commit()
return CPopSkillNameEvent