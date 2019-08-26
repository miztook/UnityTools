local PBHelper = require "Network.PBHelper"

local function OnS2CRedirectGate(sender, msg)
	warn("OnS2CRedirectGate", msg.addr)
    game._NetMan:RedirectGate(msg.addr)
end
PBHelper.AddHandler("S2CRedirectGate", OnS2CRedirectGate)