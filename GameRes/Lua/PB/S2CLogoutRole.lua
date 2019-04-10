--
-- S2CLogoutRole
-- 
local PBHelper = require "Network.PBHelper"

local function OnLogoutRole(sender, msg)

	--warn("OnLogoutRole!!!!")

	--改变流程，在S2CBriefUserInfo中处理
	--清理资源后在返回选角色界面
	--game:ReturnSelectRole()

end

PBHelper.AddHandler("S2CLogoutRole", OnLogoutRole)