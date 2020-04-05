--
-- S2CSelfDefiniteInfo
-- 
local PBHelper = require "Network.PBHelper"

local function OnSelfDefiniteInfo(sender, msg)

	local info = msg.DetailRoleInfo
	if game._HostPlayer == nil then			
		game:PrepareForGameStart()
		game:CreateHostPlayer(info)
	end

	game._HostPlayer:ResetServerState(info)		--断线重连后同步服务器的状态
end

PBHelper.AddHandler("S2CSelfDefiniteInfo", OnSelfDefiniteInfo)
