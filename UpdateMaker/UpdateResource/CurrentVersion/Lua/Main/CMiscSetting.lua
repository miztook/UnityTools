local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local UserData = require "Data.UserData".Instance()
local CPateBase = require "GUI.CPate".CPateBase
local PBHelper = require "Network.PBHelper"

local CMiscSetting = Lplus.Class("CMiscSetting")
local def = CMiscSetting.define

def.field("boolean")._IsShowHeadInfo = true
def.field("boolean")._IsShowLanguageChange = false

def.static("=>", CMiscSetting).new = function()
	local obj = CMiscSetting()
	obj:SaveToUserData()
	return obj
end

def.method().LoadUserData = function(self)
	local players_in_screen = UserData:GetField(EnumDef.LocalFields.ManPlayersInScreen)
    if players_in_screen == nil or type(players_in_screen) ~= "number" then
        _G.MAX_VISIBLE_PLAYER = 25
    else
        _G.MAX_VISIBLE_PLAYER = players_in_screen
    end
	local ev = UserData:GetField(EnumDef.LocalFields.ShowHeadInfo)
	if ev == nil or type(ev) ~= "boolean" then
		self._IsShowHeadInfo = true
	else
		self._IsShowHeadInfo = ev
	end
end

def.method("=>","boolean").IsShowHeadInfo = function(self)
	return self._IsShowHeadInfo
end

def.method("boolean").SetShowHeadInfo = function(self, is_show)
	self._IsShowHeadInfo = is_show
	self:UpdateHeadInfo()
end

def.method("=>", "boolean").IsShowLanguageChange = function(self)
    return self._IsShowLanguageChange
end

def.method("boolean").SetShowLanguageChange = function(self, isShow)
    self._IsShowLanguageChange = isShow
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

def.method("number", "boolean").SyncToServerCareNumAndShowTopPate = function(self, num, isShow)
    local C2SSetCareNum = require "PB.net".C2SSetCareNum
    local protocol = C2SSetCareNum()
    protocol.CareNum = num
    protocol.IsShowHeadWord = isShow
    PBHelper.Send(protocol)
end

CMiscSetting.Commit()
return CMiscSetting
