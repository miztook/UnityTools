local Lplus = require "Lplus"
local CGuildFortress = Lplus.Class("CGuildFortress")
local def = CGuildFortress.define

def.field("number")._FortressTid = 0
def.field("number")._ApplyScore = 0
def.field("boolean")._IsApply = false

def.static("=>", CGuildFortress).new = function()
	local obj = CGuildFortress()
	return obj
end

--重置公会建筑信息
def.method().ResetGuildFortress = function(self)
	self._FortressTid = 0
	self._ApplyScore = 0
	self._IsApply = false
end

CGuildFortress.Commit()
return CGuildFortress