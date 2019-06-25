
--
-- 加载设置
--


require "UnityClass.WrapClassID"

--

--
-- 网络协议定义及处理
--
require "PB.pb_preload"

--
-- 主逻辑预加载
--
require "Data.ClientDef"
require "Main.CGame"

--
-- 入口点
--

require "Main.EntryPoint"
require "GUI.BuyOrSellItemMan"
require "GUI.ItemListMan"

require "Main.CGMan"
require "GUI.CItemTipMan"
require "GUI.MsgBox"
require "GUI.OperationTip"
require "GUI.MenuList"
require "GUI.MsgNotify"
require "GUI.CRedDotMan"
require "HotFix"

print("load prelaod.lua")

-- TODO: 优化 逐块加载
--[[
local step = 0
local function preload()
	step = step + 1
	if step == 1 then
		-- TODO: 阶段1
	elseif step == 2 then
		-- TODO: 阶段2
	end
end

return prelaod

]]
