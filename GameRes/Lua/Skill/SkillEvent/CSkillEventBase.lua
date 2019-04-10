local Lplus = require "Lplus"

local CSkillEventBase = Lplus.Class("CSkillEventBase")
local def = CSkillEventBase.define

def.field("table")._Event = nil
def.field("table")._Params = nil
def.field("boolean")._IsToBlockPerformSequence = false 
def.field("boolean")._IsReleased = false 

def.virtual().OnEvent = function(self)
end

def.virtual("=>", "number").GetLifeTime = function(self)
	return 0
end

def.method("=>", "boolean").IsReleased = function(self)
	return self._IsReleased
end

def.virtual("number", "=>", "boolean").OnRelease = function(self, ctype)
	if self._IsReleased then return false end

	self._Event = nil
	self._Params = nil
	self._IsReleased = true
	return true
end


CSkillEventBase.Commit()
return CSkillEventBase
