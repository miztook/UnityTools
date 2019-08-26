local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CPopSkillTipsEvent = Lplus.Extend(CSkillEventBase, "CPopSkillTipsEvent")
local def = CPopSkillTipsEvent.define
local CElementData = require "Data.CElementData"

def.static("table", "table", "=>", CPopSkillTipsEvent).new = function(event, params)
	local obj = CPopSkillTipsEvent()
	obj._Event = event.PopSkillTips
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	local s_id=tonumber(self._Event.Content)
	if s_id ~= nil then 
		local strDescrip = CElementData.GetTextTemplate(s_id)
		if strDescrip ~= nil and strDescrip.TextContent ~= nil then
			game._GUIMan:PopSkillTip(self._Event.TipsType, strDescrip.TextContent, self._Event.Duration/1000)
		end
	end
end

CPopSkillTipsEvent.Commit()
return CPopSkillTipsEvent