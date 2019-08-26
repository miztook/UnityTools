-- 
-- 服务器排队
--

local PBHelper = require "Network.PBHelper"

local function OnS2CUpdateQueueNumber(sender, msg)
	-- warn("OnS2CUpdateQueueNumber number:", msg.number, " total:", msg.total)
	_G.Do_SendProtocol_Ping(GameUtil.GetPingTimeStamp())

	game._GUIMan:CloseCircle()
	local data =
	{
		Type = 1,
		CurNum = msg.number,
		TotalNum = msg.total
	}
	game._GUIMan:Open("CPanelUIServerQueue", data)
end
PBHelper.AddHandler("S2CUpdateQueueNumber", OnS2CUpdateQueueNumber)

local function OnS2CZoneOverload(sender, msg)
	-- warn("OnS2CZoneOverload")
	game._GUIMan:CloseCircle()
	local data =
	{
		Type = 2,
		Account = game._NetMan._UserName,
		Password = game._NetMan._Password
	}
	game._GUIMan:Open("CPanelUIServerQueue", data)
	game:ResetConnection()
end
PBHelper.AddHandler("S2CZoneOverload", OnS2CZoneOverload)