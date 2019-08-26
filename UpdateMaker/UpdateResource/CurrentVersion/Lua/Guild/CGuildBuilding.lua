local Lplus = require "Lplus"
local CGuildBuilding = Lplus.Class("CGuildBuilding")
local def = CGuildBuilding.define

def.field("number")._BuildingType = 0
def.field("number")._BuildingLevel = 0
def.field("string")._BuildingName = ""
def.field("number")._BuildingModuleID = 0
def.field("boolean")._IsMaxLevel = true
-- 解锁单独添加
def.field("boolean")._Lock = true
def.field("number")._GuildLevel = 0
-- 新版根据玩家等级解锁
def.field("number")._PlayerLevel = 0
def.field("boolean")._Unlock = false
-- 是否可升级(shit red point)
def.field("boolean")._LevelUp = false

def.static("=>", CGuildBuilding).new = function()
	local obj = CGuildBuilding()
	return obj
end

--重置公会建筑信息
def.method().ResetGuildBuilding = function(self)
	self._BuildingType = 0
	self._BuildingLevel = 0
	self._BuildingName = ""
	self._BuildingModuleID = 0
	self._IsMaxLevel = true
	self._Lock = true
	self._GuildLevel = 0
	self._PlayerLevel = 0
	self._LevelUp = false
end

CGuildBuilding.Commit()
return CGuildBuilding