local Lplus = require "Lplus"

local CRegionLimit = Lplus.Class("CRegionLimit")
local def = CRegionLimit.define

def.field("boolean")._LimitReviveInPlace = false	-- 是否禁止原地复活
def.field("boolean")._LimitRescue = false			-- 是否禁止救援复活
def.field("boolean")._LimitReviveSafe = false		-- 是否禁止安全复活
def.field("boolean")._LimitDodge = false			-- 是否禁止使用闪避
def.field("boolean")._LimitUseBlood = false			-- 是否禁止使用药瓶
def.field("boolean")._LimitRide = false				-- 是否禁止骑乘
def.field("boolean")._LimitLeave = false			-- 是否禁止离开

def.static("=>", CRegionLimit).new = function ()
	local obj = CRegionLimit()
	return obj
end

def.method("table").Set = function (self, limits)
	if limits == nil then return end
	-- print("ForbidReviveInPlace:", limits.ForbidReviveInPlace == true)
	-- print("ForbidRescue:", limits.ForbidRescue == true)
	-- print("ForbidSafeRevive:", limits.ForbidSafeRevive == true)
	-- print("ForbidDodge:", limits.ForbidDodge == true)
	-- print("ForbidUseBlood:", limits.ForbidUseBlood == true)
	-- print("ForbidRide:", limits.ForbidRide == true)
	-- print("ForbidLeave:", limits.ForbidLeave == true)

	self._LimitReviveInPlace = limits.ForbidReviveInPlace == true
	self._LimitRescue = limits.ForbidRescue == true
	self._LimitReviveSafe = limits.ForbidSafeRevive == true
	self._LimitDodge = limits.ForbidDodge == true
	self._LimitUseBlood = limits.ForbidUseBlood == true
	self._LimitRide = limits.ForbidRide == true
	self._LimitLeave = limits.ForbidLeave == true

end

def.method().Reset = function (self)
	self._LimitReviveInPlace = false
	self._LimitRescue = false
	self._LimitReviveSafe = false
	self._LimitDodge = false
	self._LimitUseBlood = false
	self._LimitRide = false
	self._LimitLeave = false
end

CRegionLimit.Commit()
return CRegionLimit