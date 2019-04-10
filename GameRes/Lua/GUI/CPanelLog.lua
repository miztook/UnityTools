local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelLog = Lplus.Extend(CPanelBase, "CPanelLog")
local def = CPanelLog.define

def.field("userdata")._PanelLog = nil
def.field("userdata")._TextLog = nil

local instance = nil
local logType = 1

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
	
	self._PanelLog:SetActive(false)
end

def.override().OnDestroy = function(self)
    --instance = nil --destroy
end

def.method().TogglePanelLog = function(self)
	local is_shown = self._PanelLog.activeSelf
	self._PanelLog:SetActive(not is_shown)
end

def.override("string").OnClick = function(self, id)
	--warn("huangxin", id)
	if id == "Btn_Log" then
		self:TogglePanelLog()
		self:OnSyncLog("")
	elseif id == "Btn_Back" then
		self:TogglePanelLog()
	end

end

local function IsCriticalLog (log)
	local s, e = string.find(log, "[Error]")
	return (s ~= nil and e ~= nil)
end

def.override('string', 'boolean').OnToggle = function(self, id, checked)
	if id == "Rdo_LogTab1" and checked then
		logType=1
		self:OnSyncLog("1")
	elseif id == "Rdo_LogTab2" and checked then
		logType=2
		self:OnSyncLog("2")
	elseif id == "Rdo_LogTab3" and checked then
		logType=3
		self:OnSyncLog("3")
	elseif id == "Rdo_LogTab4" and checked then
		logType=4
		self:OnSyncLog("4")
	end
end

def.method("string").OnSyncLog = function(self, log)
	--if IsCriticalLog(log) and not self._PanelLog.activeSelf then
	--	self:TogglePanelLog()
	--end

	if not IsNil(self._PanelLog) and self._PanelLog.activeSelf then
		if IsNil(self._TextLog) then return end

		local logs = game:GetLogs()
		local logstr = ""
		for i = #logs, 1, -1 do

			local start1,logIndex=string.find(logs[i],"Log")
			local start2,woringIndex=string.find(logs[i],"Warning")
			local start3,errorIndex=string.find(logs[i],"Error")			
			
			if  logType==1  then
				logstr =logstr ..logs[i] .. "\n"
			elseif logType==2 and logIndex ~=nil   then
				logstr =logstr ..logs[i] .. "\n"
			elseif logType==3 and woringIndex ~= nil  then
				logstr =logstr ..logs[i] .. "\n"
			elseif logType==4 and errorIndex ~= nil  then
				logstr =logstr ..logs[i] .. "\n"
			end					
		end				

		self._TextLog:GetComponent(ClassType.Text).text = logstr
		local height = self._TextLog:GetComponent(ClassType.Text).preferredHeight
		local content = self._PanelLog:FindChild("Img_BG2/Scroll_View/Viewport/Content")

		local panelRectTransform = content:GetComponent(ClassType.RectTransform)
		local sizeDelta = panelRectTransform.sizeDelta
		sizeDelta.y = height
		panelRectTransform.sizeDelta = sizeDelta
	end
end

CPanelLog.Commit()
return CPanelLog
