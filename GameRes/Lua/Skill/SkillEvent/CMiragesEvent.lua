local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CMiragesEvent = Lplus.Extend(CSkillEventBase, "CMiragesEvent")
local def = CMiragesEvent.define

def.field("userdata")._GhostModel = nil
def.field("number")._TimerId = 0

def.static("table", "table", "=>", CMiragesEvent).new = function(event, params)
	local obj = CMiragesEvent()
	obj._Event = event.Mirages
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	local entity =  self._Params.BelongedCreature
	if entity then		
		local model = entity:GetCurModel()._GameObject
		local r = self._Event.RimColorR / 255
		local g = self._Event.RimColorG / 255
		local b = self._Event.RimColorB / 255
		local power = self._Event.RimPower 
		local duration = self._Event.Duration/1000
		self._GhostModel = CGhostEffectMan.CreateGhostModel(self._Params.SkillId, model, r, g, b, power)
		
		local function Release( )
			if not IsNil(self._GhostModel) then
				CGhostEffectMan.ReleaseGhostModel(self._Params.SkillId, self._GhostModel)
				self._GhostModel = nil
			end
			self._TimerId = 0
		end

		-- 启用全局的timer , 之后幻影实例入池
		self._TimerId = _G.AddGlobalTimer(duration, true, Release)
	end
end

-- 
def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if self._TimerId > 0 then
		if not IsNil(self._GhostModel) then
			CGhostEffectMan.ReleaseGhostModel(self._Params.SkillId, self._GhostModel)
			self._GhostModel = nil
		end
		_G.RemoveGlobalTimer(self._TimerId)
		self._TimerId = 0
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CMiragesEvent.Commit()
return CMiragesEvent
