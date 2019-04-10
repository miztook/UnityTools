local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CAudioEvent = Lplus.Extend(CSkillEventBase, "CAudioEvent")
local def = CAudioEvent.define

def.field("string")._AsName = ""

def.static("table", "table", "=>", CAudioEvent).new = function(event, params)
	local obj = CAudioEvent()
	obj._Event = event.Audio
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	local host = self._Params.BelongedCreature
	if host ~= nil then 
		self._AsName = CSoundMan.Instance():Play3DAudio(self._Event.AssetPath, host:GetPos(), 0)
	end
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return 20  -- 暂定20s
end

-- 声音效果效果
def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	local entity = self._Params.BelongedCreature
	if entity == nil or entity:IsReleased() then
		CSoundMan.Instance():Stop3DAudio(self._Event.AssetPath, self._AsName )
		CSkillEventBase.OnRelease(self, ctype)
		return true
	end

	local stopNow = (ctype == EnumDef.EntitySkillStopType.PerformEnd and self._Event.FinishConditionPerformEnd)
				or (ctype == EnumDef.EntitySkillStopType.SkillEnd and self._Event.FinishConditionSkillEnd)
				or (ctype == EnumDef.EntitySkillStopType.LifeEnd)
	if stopNow then
		CSoundMan.Instance():Stop3DAudio(self._Event.AssetPath, self._AsName )
		CSkillEventBase.OnRelease(self, ctype)
		return true
	else
		return false
	end
end


CAudioEvent.Commit()
return CAudioEvent
