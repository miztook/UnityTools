local Lplus = require "Lplus"

local CAccountInfo = Lplus.Class("CAccountInfo")
local def = CAccountInfo.define

def.field("number")._Diamond = 0
def.field("number")._VipLevel = 0
def.field("number")._VipExp = 0
def.field("number")._ParagonLevel = 0    -- 巅峰等级
def.field("number")._ParagonExp = 0      -- 巅峰经验
def.field("table")._RoleList = BlankTable
def.field("string")._OrderRoleName = "" 	-- 预约的角色名字

def.field("number")._CurrentSelectRoleIndex = 0

--[[
_RoleList 表格式：
	[index] = {
					Id	= 1,
					Name = "Hello",
					ProfessionId = 3,
					Gender = 0/1, 
					Level = 5,
					WeaponAssetId = 6,
					ModelAssetId = 7
			  }
]]

def.method().Clear = function (self)
	self._Diamond = 0
	self._VipLevel = 0
	self._VipExp = 0
	self._ParagonLevel = 0    -- 巅峰等级
	self._ParagonExp = 0      -- 巅峰经验
	self._RoleList = {}

	self._CurrentSelectRoleIndex = 0
end

def.static("=>", CAccountInfo).new = function ()
	local obj = CAccountInfo()	
	return obj
end

CAccountInfo.Commit()
return CAccountInfo