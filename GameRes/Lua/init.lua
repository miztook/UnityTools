
--[[--

初始化，载入预定义的常量、模块。

### 常量

在初始化框架之前，可以定义以下常量：

-   DEBUG: 设置框架的调试输出级别

    ```lua
    DEBUG = 0           -- 不输出任何调试信息（默认值）
    DEBUG = 1           -- 输出基本的调试信息
    DEBUG = 2           -- 输出详细的调试信息
    ```

-   DEBUG_FPS: 设置是否在画面中显示渲染帧率等信息

    ```lua
    DEBUG_FPS = false   -- 不显示（默认值）
    DEBUG_FPS = true    -- 显示
    ```

-   DEBUG_MEM: 设置是否输出内存占用信息

    ```lua
    DEBUG_MEM = false   -- 不输出（默认值）
    DEBUG_MEM = true    -- 每 10 秒输出一次
    ```
    
<br />


### 自动载入的模块

框架初始化时，会自动载入以下基本模块：

-   debug: 调试接口
-   functions: 提供一组常用的函数，以及对 Lua 标准库的扩展
-   device: 针对设备接口的扩展
-   crypto: 加密相关的接口
-   luaj: 提供从 Lua 调用 Java 方法的接口（仅限 Android 平台）
-   luaoc: 提供从 Lua 调用 Objective-C 方法的接口（仅限 iOS 平台）
]]

-- 初始化参数定义
local DEBUG = 2
local DEBUG_MEM = false


if type(DEBUG) ~= "number" then DEBUG = 0 end
if type(DEBUG_MEM) ~= "boolean" then DEBUG_MEM = false end

----

-- disable stdout buffer
io.stdout:setvbuf("no")

require "Utility.Debug"
require "Utility.Functions"
require "Utility.ShortCodes"

printInfo("# DEBUG = "..DEBUG)

if DEBUG_MEM then
    local function ShowMemoryUsage()
        printInfo(string.format("LUA VM MEMORY USED: %0.2f KB", collectgarbage("count")))
        --printInfo("---------------------------------------------------")
    end
    _G.AddGlobalTimer(30, false, ShowMemoryUsage)
end

-- LPlus config
local LuaCheckLevelEnum =
{
    None = 0,
    Limited = 1,
    Strict = 2,
}

local LuaCheckingLevel = LuaCheckLevelEnum.Strict

package.loaded.Lplus_config =
{
    reflection = false,
    declare_checking = LuaCheckingLevel >= 1,
    accessing_checking = LuaCheckingLevel >= 2,
    calling_checking = LuaCheckingLevel >= 2,
    reload = false,
}

_G.ReadConfigTable = function (path)
    local ret, msg, result = pcall(dofile, path)
    if ret then
        return result
    else
        warn("ReadConfigTable Failed!!!!!!!!! ", path, msg)
        return nil
    end
end

--释放已经加载的lua模块
_G.Unrequire = function(m)
    package.loaded[m] = nil
    _G[m] = nil
end

_G.UserLanguageCode = nil
_G.ConfigsDir = nil
_G.CommonAtlasDir = "Assets/Outputs/CommonAtlas/"

require "Data.ResPath"


_G.ResetLanguage = function()
    _G.UserLanguageCode = GameUtil.GetUserLanguageCode()
    print("_G.UserLanguageCode =", _G.UserLanguageCode)
    --if true then 
    if _G.UserLanguageCode == "CN" then
        _G.ConfigsDir = "Configs/"
        GameUtil.UnloadBundle("interfaces_kr")
        GameUtil.UnloadBundle("interfaces_tw")
    else
        _G.ConfigsDir = "Configs/KR/"
        GameUtil.UnloadBundle("interfaces")
        GameUtil.UnloadBundle("interfaces_tw")
    end

    --受 _G.ConfigsDir影响
    _G.Unrequire("Data.ConfigsData")
    require "Data.ConfigsData"

    GameUtil.SetSoundLanguage("Korean")  --使用GameRes\Audio\GeneratedSoundBanks\Windows下的localize语音

    GameUtil.ClearHUDTextFontCache()

    --清除data数据，重新设置data路径
    local CElementData = require "Data.CElementData"
    CElementData.ClearAll()
    GameUtil.GC(false)
    local MapBasicConfig = require "Data.MapBasicConfig" 
    MapBasicConfig.Reset()

    GameUtil.DetermineTemplatePath()
    GameUtil.PreloadGameData()
end

_G.IsLanguageChanged = function ()
    return _G.UserLanguageCode ~= GameUtil.GetUserLanguageCode()
end

_G.DevelopmentBuild = GameUtil.GetDevelopMode()
_G.ResponseDevice = GameUtil.GetResponseDeviceString()
_G.ResponseOSVersion = GameUtil.GetResponseOSVersionString()
_G.ResponseMACString = GameUtil.GetResponseMACString()

--warn("MemoryLimit:", GameUtil.GetLargeMemoryLimit(), GameUtil.GetMemoryLimit())
--warn("response Device-OSVersion-MAC:", _G.ResponseDevice, _G.ResponseOSVersion, _G.ResponseMACString)

_G.PreprocessTemplateDatas = function ()
    local specialDataPaths =
    {
        Actor = {"Actor0.data", "Actor1.data" },
        Quest = {"Quest0.data", "Quest1.data", "Quest2.data", "Quest3.data", "Quest4.data", "Quest5.data", "Quest6.data", "Quest7.data", "Quest8.data"},
        Skill = {"Skill0.data", "Skill1.data"},
    }
    for name, path in pairs(specialDataPaths) do
        GameUtil.AddSpecialTemplateDataPath(name, path)
    end 

    local preloadedTemplates = 
    {
        "Actor", "SensitiveWord", "Fun", "Asset", "Cooldown", "Faction", "Quest", "Item", "Instance",
        "Skill", "SkillLearnCondition", "SkillLevelUpCondition", "SkillLevelUp", "SpecialId", "Monster",
    }

    for i,v in ipairs(preloadedTemplates) do
        GameUtil.AddPreloadTemplateData(v)
    end
end

--GameUtil.SetEncryptKey("ooxxooxx")
_G.PreprocessTemplateDatas()
_G.ResetLanguage()