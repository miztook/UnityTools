local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CSanctionMessage(sender,protocol)
warn("=============OnS2CSanctionMessage=============")
	local data = 
	{
		SanctionTime = protocol.SanctionTime,
	}
	game._GUIMan:CloseCircle()
	game._GUIMan:Open("CPanelUISanctionPrompt", data)
end
PBHelper.AddHandler("S2CSanctionMessage", OnS2CSanctionMessage)