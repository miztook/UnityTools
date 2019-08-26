local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelLog = Lplus.Extend(CPanelBase, "CPanelLog")
local def = CPanelLog.define

def.field("userdata")._PanelLog = nil
def.field("userdata")._TextLog = nil
def.field("userdata")._ScrollViewContent = nil

local instance = nil

def.static("=>", CPanelLog).Instance = function()
	if instance == nil then
		instance = CPanelLog()
		instance._PrefabPath = PATH.UI_Log
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then return end

	self._PanelLog = self._Panel:FindChild("Frame_LOG")
	self._TextLog = self._Panel:FindChild("Frame_LOG/Img_BG2/Scroll_View/Viewport/Content/Lab_logprint")
	self._TextLog:GetComponent(ClassType.Text).text = ""
	self._ScrollViewContent = self._PanelLog:FindChild("Img_BG2/Scroll_View/Viewport/Content")

	self._PanelLog:SetActive(false)
end

def.method().TogglePanelLog = function(self)
	local is_shown = self._PanelLog.activeSelf
	self._PanelLog:SetActive(not is_shown)
end

def.override("string").OnClick = function(self, id)
	if id == "Btn_Log" then
		self:TogglePanelLog()
		self:ShowLogs(1)
	elseif id == "Btn_Back" then
		self:TogglePanelLog()
	end
end

def.method("number").ShowLogs = function(self, logType)
	if not self:IsShow() then return end
	GameUtil.ShowGameLogs(logType, self._TextLog, self._ScrollViewContent)
end

def.override('string', 'boolean').OnToggle = function(self, id, checked)
	if not checked then return end
	if id == "Rdo_LogTab1" then
		self:ShowLogs(1)
	elseif id == "Rdo_LogTab2" then
		self:ShowLogs(2)
	elseif id == "Rdo_LogTab3" then
		self:ShowLogs(3)
	elseif id == "Rdo_LogTab4" then
		self:ShowLogs(4)
	end
end

CPanelLog.Commit()
return CPanelLog
