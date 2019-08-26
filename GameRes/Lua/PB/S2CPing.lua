--
-- S2CInventoryInfo
--

local PBHelper = require "Network.PBHelper"

_G.BigPingTime = 0

local function OnPing(sender, protocol)	
	local gap = GameUtil.GetClientTime() - protocol.TimeList[1].Timestamp
	game._Ping = gap
	GameUtil.UpdatePingDisplay(gap)

	--[[
	if not game:IsInGame() or game._CurMapId == 0 then
		_G.BigPingTime = 0
		return 
	end

	if gap > 1000 then
		local now = os.time()
		if _G.BigPingTime > 0 and now - _G.BigPingTime > 5 then
			if game._NetMan._GameSession:IsConnected() or game._NetMan._GameSession:IsConnecting() then	
				warn("ping > 1000 last 5 seconds! close!")
				game._NetMan:Close()
				_G.OnConnectionEvent(EVENT.DISCONNECTED)
			end
			_G.BigPingTime = 0
		elseif _G.BigPingTime == 0 then
			_G.BigPingTime = now
		end
	else
		_G.BigPingTime = os.time()
	end
	]]
end

PBHelper.AddHandler("S2CPing", OnPing)