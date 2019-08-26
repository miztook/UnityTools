-- 分帧加载
local step = 0

function _G.preload()
	step = step + 1
	if step == 1 then
		require "protobuf.protobuf"
		require "UnityClass.WrapClassID"
	elseif step == 2 then
		require "PB.pb_preload"
	elseif step == 2 then
		require "Data.ClientDef"
	elseif step == 3 then
		require "Main.CGame"
	elseif step == 4 then
		require "Main.EntryPoint"
	elseif step == 5 then
		require "GUI.BuyOrSellItemMan"
		require "GUI.ItemListMan"
		require "Main.CGMan"
		require "GUI.CItemTipMan"
		require "GUI.MsgBox"
		require "GUI.OperationTip"
		require "GUI.MenuList"
		require "GUI.MsgNotify"
		require "GUI.CRedDotMan"
	elseif step == 6 then
		if _G.DevelopmentBuild then
			require "HotFix"
		end
		require "System.AppMsgBoxMan"
		require "System.TeraFuncs"
		require "System.EventUntil"
		game:Init()
	elseif step == 7 then
		return true
	end

	return false
end