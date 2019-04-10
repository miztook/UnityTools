local Lplus = require "Lplus"

local UISettingConfig = Lplus.Class("UISettingConfig")
local def = UISettingConfig.define

local uiSettingCfg = nil
def.static().CheckSetting = function()
    if uiSettingCfg == nil then
		local ret, msg, result = pcall(dofile, "Configs/UISettingCfg.lua")
		if ret then
			uiSettingCfg = result
		else
			warn(msg)
		end
	end
end

def.static("string", "=>", "table").GetUISetting = function(resPath)
    --warn("GetUISetting "..resPath)
    UISettingConfig.CheckSetting()

    if uiSettingCfg == nil then return nil end

    local uiTable = uiSettingCfg.UI_Table
    if uiTable ~= nil and uiTable[resPath] ~= nil then
        return uiTable[resPath]
    end

    return nil
end

def.static("=>", "table").GetTable = function()
    -- warn("GetTable called ", debug.traceback())
    UISettingConfig.CheckSetting()

    return uiSettingCfg
end

UISettingConfig.Commit()
return UISettingConfig