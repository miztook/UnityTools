local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local UserData = require "Data.UserData".Instance()
local CMiscSetting = Lplus.Class("CMiscSetting")
local CPateBase = require "GUI.CPate".CPateBase
local def = CMiscSetting.define

def.static("=>", CMiscSetting).new = function()
	local obj = CMiscSetting()
	obj:LoadUserData()
	return obj
end

def.field("boolean")._IsShowHeadInfo = true

def.method("=>","boolean").IsShowHeadInfo = function(self)
	return self._IsShowHeadInfo
end

def.method("boolean").SetShowHeadInfo = function(self, is_show)
	self._IsShowHeadInfo = is_show
	self:UpdateHeadInfo()
end

def.method().UpdateHeadInfo = function(self)

--warn("****************UpdateHeadInfo "..tostring(self._IsShowHeadInfo))

	GameUtil.SetShowHeadInfo(self._IsShowHeadInfo)
	--CPateBase.UpdateAllVisibility()

end

def.method().SaveToUserData = function(self)

--	-- warn("SaveToUserData: ", debug.traceback())
--	UserData:SetField(EnumDef.LocalFields.PowerSaving, self._IsEnabled)
--	UserData:SetField(EnumDef.LocalFields.PowerSavingTime, self._TimeCD)
	UserData:SetField(EnumDef.LocalFields.ShowHeadInfo, self._IsShowHeadInfo)
	--warn("****************SaveToUserData "..tostring(self._IsShowHeadInfo))
end

def.method().LoadUserData = function(self)


--	local ev = UserData:GetField(EnumDef.LocalFields.PowerSaving)
--	if ev == nil or type(ev) ~= "boolean" then
--		self._IsEnabled = true
--	else
--		self._IsEnabled = ev
--	end

--	ev = UserData:GetField(EnumDef.LocalFields.PowerSavingTime)
--	if ev == nil or type(ev) ~= "number" then
--		self._IsEnabled = false
--	else
--		self:SetSleepingTime(ev)
--	end

--	-- warn("***LoadUserData: "..tostring(ev == nil or type(isClickGroundMove) ~= "boolean"))
    local players_in_screen = UserData:GetField(EnumDef.LocalFields.ManPlayersInScreen)
    if players_in_screen == nil or type(players_in_screen) ~= "number" then
        _G.MAX_VISIBLE_PLAYER = 20
    else
        _G.MAX_VISIBLE_PLAYER = players_in_screen
    end
	local ev = UserData:GetField(EnumDef.LocalFields.ShowHeadInfo)
	if ev == nil or type(ev) ~= "boolean" then
		self._IsShowHeadInfo = true
	else
		self._IsShowHeadInfo = ev
	end

	--warn("****************LoadUserData "..tostring(self._IsShowHeadInfo))
end

CMiscSetting.Commit()
return CMiscSetting
