local Lplus = require "Lplus"
local CGuildLimit = Lplus.Class("CGuildLimit")
local def = CGuildLimit.define

--角色等级
def.field("number")._RoleLevel = 0
--角色战力
def.field("number")._BattlePower = 0

def.static("=>", CGuildLimit).new = function()
	local obj = CGuildLimit()
	return obj
end

--重置公会条件
def.method().ResetGuildLimit = function(self)
	self._RoleLevel = 0
	self._BattlePower = 0
end

CGuildLimit.Commit()
return CGuildLimit