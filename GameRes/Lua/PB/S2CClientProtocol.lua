--
-- S2CClientProtocol
--
local PBHelper = require "Network.PBHelper"

local function OnS2CClientProtocol( sender,msg )
	warn("S2CClientProtocol", msg.IsSend)
	local canSend = msg.IsSend
	if not canSend then
		-- 发送应答协议
		local C2SClientProtocolAck = require "PB.net".C2SClientProtocolAck
		local protocol = C2SClientProtocolAck()
        PBHelper.Send(protocol)
	end
	CGameSession.Instance().IsSendingPaused = (not canSend)
end

PBHelper.AddHandler("S2CClientProtocol", OnS2CClientProtocol)