local Lplus = require "Lplus"
local CActiveSkillInfo = Lplus.Class("CActiveSkillInfo")

local def = CActiveSkillInfo.define

def.field("boolean")._IsGoingOn = false
def.field("number")._SkillID = 0
def.field("number")._StartTime = 0
def.field("table")._Skill = nil
def.field("number")._SkillTimerID = 0
def.field("number")._PerformIdx = 0
def.field("number")._PerformTimerID = 0
def.field("number")._Param = 0


def.static("=>", CActiveSkillInfo).new = function ()
	local obj = CActiveSkillInfo()
	return obj
end

def.method().Reset = function(self)
	self._IsGoingOn = false
	self._SkillID = 0
	self._StartTime = 0
	self._Skill = nil
	self._PerformIdx = 0
end

CActiveSkillInfo.Commit()
return CActiveSkillInfo