--
-- S2CForceLogin
--

local PBHelper = require "Network.PBHelper"

--连接服务器时检测到账号已登录
local function OnS2CForceLogin(sender,protocol)
	--warn("=============OnS2CForceLogin=============")
	if game._AccountInfo == nil then
		-- 还没连接游戏服（正常登录的顶号流程）
		if not game._IsReconnecting then
			game._GUIMan:CloseCircle()
		end
		local title, msg, closeType = StringTable.GetMsg(75)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,function(val)
			local C2SForceLogin = require "PB.net".C2SForceLogin
			local protocol = C2SForceLogin()
			protocol.Force = val

			SendProtocol(protocol)

			if val == false then
				game:CloseConnection()
			end
	    end, nil, nil, MsgBoxPriority.Disconnect)
	else
		-- 已连接游戏服（例如断线重连后收到账号已登录）
		game._AnotherDeviceLogined = true
		game._GUIMan:CloseCircle()
		game:CloseConnection() -- 主动断连，否则下面的弹窗会被服务器的自动断连关闭

		local callback = function()
			game:ReturnToLoginStage()
		end
		local title, msg, closeType = StringTable.GetMsg(79)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, callback, nil, nil, MsgBoxPriority.Disconnect)
	end
end
PBHelper.AddHandler("S2CForceLogin", OnS2CForceLogin)