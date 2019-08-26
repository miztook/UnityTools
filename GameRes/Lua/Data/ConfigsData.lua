--所有受Configs本地化影响到数据模块，在语言改变后需要重新加载，并且相关使用的地方不能有缓存
collectgarbage("collect")

_G.ChatCfgTable = ReadConfigTable(_G.ConfigsDir.."chatcfg.lua")

--local preCount = collectgarbage("count")
_G.GameTextTable = ReadConfigTable(_G.ConfigsDir.."game_text.lua")
--local lateCount = collectgarbage("count")
--printInfo(string.format("GameTextTable Memery Used: %0.2f KB", (lateCount - preCount)))

_G.ModuleProfDiffCfgTable = ReadConfigTable(_G.ConfigsDir.."ModuleProfDiffCfg.lua")

--preCount = collectgarbage("count")
_G.CommandListTable = ReadConfigTable(_G.ConfigsDir.."CommandList.lua").GetAllCommandList()
--lateCount = collectgarbage("count")
--printInfo(string.format("CommandList Memery Used: %0.2f KB", (lateCount - preCount)))

-- 用完即丢，无需全局缓存
--_G.SystemEntranceCfgTable = ReadConfigTable(_G.ConfigsDir.."SystemEntranceCfg.lua")

_G.DebugTextTable = ReadConfigTable(_G.ConfigsDir.."debug_text.lua")

-- ActivityTypeCfg 零引用
--_G.ActivityTypeCfgTable = ReadConfigTable(_G.ConfigsDir.."ActivityTypeCfg.lua")

-- RandomName 用完即丢，不用保留
-- _G.RandomNameCfgTable = ReadConfigTable(_G.ConfigsDir.."RandomName.lua")

-- 此数据制作临时变量使用，用完即丢，不要_G
--_G.AdventureGuideBasicInfoTable = ReadConfigTable(_G.ConfigsDir.."AdventureGuideBasicInfo.lua")

_G.AppMsgBoxTable = ReadConfigTable(_G.ConfigsDir.."AppMsgBoxCfg.lua")

_G.QuickMsgTable = ReadConfigTable(_G.ConfigsDir.."QuickMsgCfg.lua")