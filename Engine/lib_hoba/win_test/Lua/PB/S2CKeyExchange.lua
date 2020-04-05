--
-- S2CKeyExchange
-- 
local PBHelper = require "Network.PBHelper"

local function OnKeyExchange(sender,msg)
	if game._IsOfflineGame then
		local C2SKeyExchange = require "PB.net".C2SKeyExchange
		local msg = C2SKeyExchange()
		msg.Nonce = game._KeyNonce
	    PBHelper.Send(msg)
	else
		--warn("-----OnKeyExchange-----")
		local nonce = msg.Nonce
		game._KeyNonce = nonce
		game._NetMan:OnS2CKeyExchange(nonce)
	end
end

PBHelper.AddHandler("S2CKeyExchange",OnKeyExchange)

