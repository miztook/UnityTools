--
-- S2CUpdateToken
-- 
local PBHelper = require "Network.PBHelper"

local function OnTokenUpdated(sender,msg)
	local token = msg.AccountToken
	local UserData = require "Data.UserData".Instance()
	UserData:SetCfg(EnumDef.LocalFields.LastUseAccount, "AccountToken", token)
	UserData:SaveDataToFile()
end

PBHelper.AddHandler("S2CUpdateToken",OnTokenUpdated)

