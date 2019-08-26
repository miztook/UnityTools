local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"

local CPanelInstanceAlarm = Lplus.Extend(CPanelBase, "CPanelInstanceAlarm")
local def = CPanelInstanceAlarm.define

local instance = nil
def.static("=>",CPanelInstanceAlarm).Instance = function ()
	if not instance then
        instance = CPanelInstanceAlarm()
        instance._PrefabPath = PATH.Panel_Instance_Alarm
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnDestroy = function(self)
	--instance = nil --destroy
end

def.override("dynamic").OnData = function(self, data)
	if(data == nil) then data = 1 end
	local timerID = -1
	local callback = function()
		_G.RemoveGlobalTimer(timerID)
		game._GUIMan:CloseByScript(self)
	end

	timerID = _G.AddGlobalTimer(data, false, callback)
end

CPanelInstanceAlarm.Commit()
return CPanelInstanceAlarm