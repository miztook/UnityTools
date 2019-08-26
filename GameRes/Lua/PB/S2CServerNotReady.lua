--
-- 无法进入游戏服
--

local PBHelper = require "Network.PBHelper"

local function OnS2CServerNotReady(sender, protocol)
	--warn("OnS2CServerNotReady NotReadyType:" .. protocol.NotReadyType)
	game:CloseConnection() -- 断开连接防止继续发送协议

	local title = StringTable.Get(8)
	local msg = "ServerNotReady"
	local ENotReady = require "PB.net".S2CServerNotReady.NotReady
	if protocol.NotReadyType == ENotReady.CannotGetGameSession then
		msg = StringTable.Get(14006)
	end
	MsgBox.ShowMsgBox(msg, title, 0, MsgBoxType.MBBT_OK, function()
		-- 返回登录界面即可
		game:ReturnToLoginStage()
	end)
end
PBHelper.AddHandler("S2CServerNotReady", OnS2CServerNotReady)