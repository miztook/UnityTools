--
-- S2CLogoutAccount
-- 
local PBHelper = require "Network.PBHelper"

local function OnLogoutAccount(sender, msg)
	-- warn("OnLogoutAccount ", game._AnotherDeviceLogined, game:IsRoleSceneAutoReturnLogin())
	if game._AnotherDeviceLogined then
		-- 顶号重新登录
		local callback = function()
			game:ReturnToLoginStage()
		end
		local title, msg, closeType = StringTable.GetMsg(79)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, callback, nil, nil, MsgBoxPriority.Disconnect)
		
		ClearScreenFade()
	elseif game:IsRoleSceneAutoReturnLogin() then
		-- 选择角色闲置超时自动返回登录
		local callback = function()
			game:ReturnToLoginStage()
		end
		local title, msg, closeType = StringTable.GetMsg(134)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, callback, nil, nil, MsgBoxPriority.Disconnect)
	else
		game:ReturnToLoginStage()
	end
end

PBHelper.AddHandler("S2CLogoutAccount", OnLogoutAccount)