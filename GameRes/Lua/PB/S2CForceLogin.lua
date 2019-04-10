--
-- S2CForceLogin
--

local PBHelper = require "Network.PBHelper"

--协议名称
local function OnS2CForceLogin(sender,protocol)
	--warn("=============OnS2CForceLogin=============")
	local title, msg, closeType = StringTable.GetMsg(75)
	
	if not game._IsReconnecting then
		game._GUIMan:CloseCircle()
	end

	MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,function(val)
        local C2SForceLogin = require "PB.net".C2SForceLogin
		local protocol = C2SForceLogin()
		protocol.Force = val

		SendProtocol(protocol)

		if val == false then
			game:CloseConnection()
		end
    end, nil, nil, MsgBoxPriority.Disconnect)
end
PBHelper.AddHandler("S2CForceLogin", OnS2CForceLogin)