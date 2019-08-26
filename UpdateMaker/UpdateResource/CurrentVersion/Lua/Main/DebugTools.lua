local Lplus = require "Lplus"

local DebugTools = Lplus.Class("DebugTools")
local def = DebugTools.define

local function hideCmdPanel(enable)
    local panel = require "GUI.CPanelDebug".Instance()
    if panel:IsShow() == not enable then return end

    if enable then
    	game._GUIMan:Close("CPanelDebug")
    else
    	game._GUIMan:Open("CPanelDebug", nil)	
    end
end

local function hideLogPanel(enable)
    local panel = require "GUI.CPanelLog".Instance()
    if panel:IsShow() == not enable then return end

    if enable then
    	game._GUIMan:Close("CPanelLog")
    else
    	game._GUIMan:Open("CPanelLog", nil)	
    end
end

local function hideFpsPingPanel(enable)
    GameUtil.EnableFpsPingDisplay(not enable)
end

local function resetDebugToolState()
    local isHideDebug = false
    local deployType = GameUtil.GetConfigDeployType()
    if deployType == "real" then 
        -- Real版本
        isHideDebug = GameUtil.GetSpecialLevel() ~= EnumDef.AccountSpecialLevel.Level1
    end
    local options = GameConfig.Get("DebugOption")
    hideCmdPanel(isHideDebug or options.HideCmd)
    hideLogPanel(isHideDebug or options.HideLog)
    hideFpsPingPanel(isHideDebug or options.HideFpsPing)
end

def.const("function").HideCmdPanel = hideCmdPanel
def.const("function").HideLogPanel = hideLogPanel
def.const("function").HideFpsPingPanel = hideFpsPingPanel
def.const("function").ResetDebugToolState = resetDebugToolState

def.const("boolean").EnableEntityInfoDebug = false

DebugTools.Commit()
return DebugTools