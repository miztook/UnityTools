--
-- S2CKeyExchange
-- 
local PBHelper = require "Network.PBHelper"

local function OnKeyExchange(sender,msg)
	local token = msg.AccountToken
	local UserData = require "Data.UserData".Instance()
	UserData:SetCfg(EnumDef.LocalFields.LastUseAccount, "AccountToken", token)
	UserData:SaveDataToFile()

	local C2SKeyExchange = require "PB.net".C2SKeyExchange
	local msg = C2SKeyExchange()
    PBHelper.Send(msg)
end

PBHelper.AddHandler("S2CKeyExchange",OnKeyExchange)

