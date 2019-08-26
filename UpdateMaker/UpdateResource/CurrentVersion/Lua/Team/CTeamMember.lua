local Lplus = require "Lplus"
local ModelParams = require "Object.ModelParams"

local CTeamMember = Lplus.Class("CTeamMember")
local def = CTeamMember.define

def.field("number")._ID = 0
def.field("string")._Name = ""
def.field("boolean")._IsOnLine = true
def.field("boolean")._IsFollow = false
def.field("number")._MapTid = 0
def.field("number")._LineId = 0
def.field("string")._MapTag = ""
def.field("number")._GameServerId = 0

def.field("number")._Profession = 0
def.field("number")._Gender = 0
def.field("table")._Position = nil

def.field("number")._Lv = 0
def.field("number")._Hp = 0
def.field("number")._HpMax = 0
def.field("number")._Fight = 0
def.field("boolean")._IsAssist = false

def.field(ModelParams)._Param = nil


def.static("=>", CTeamMember).new = function ()
	local obj = CTeamMember()
	return obj
end

def.method().Reset = function (self)
	self._ID = 0
	self._Name = ""
	self._IsOnLine = false
	self._IsFollow = false
	self._MapTid = 0
	self._LineId = 0
	self._Profession = 0
	self._Gender = 0
	self._Position = nil

	self._Lv = 0
	self._Hp = 0
	self._HpMax = 0
	self._Fight = 0
	self._Param = nil
end

CTeamMember.Commit()
return CTeamMember