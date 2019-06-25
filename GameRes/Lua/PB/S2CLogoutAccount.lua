--
-- S2CLogoutAccount
-- 
local PBHelper = require "Network.PBHelper"

local function OnLogoutAccount(sender, msg)
	if game._AnotherDeviceLogined then
		-- 顶号重新登录
		warn("===========OnLogoutAccount AnotherDeviceLogined=========")
		local callback = function()
			game:ReturnLoginStage()
			_G.MsgBoxDisconnectShow = false
		end
		_G.MsgBoxDisconnectShow = true
		local title, msg, closeType = StringTable.GetMsg(79)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, callback, nil, nil, MsgBoxPriority.Disconnect)
		
		-- game:RaiseDisconnectEvent()
		ClearScreenFade()
	else
		game:ReturnLoginStage()
	end
end

PBHelper.AddHandler("S2CLogoutAccount", OnLogoutAccount)