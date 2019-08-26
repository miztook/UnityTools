--
-- S2CLogoutRole
-- 
local PBHelper = require "Network.PBHelper"

local function OnLogoutRole(sender, msg)

		game._CurGameStage = _G.GameStage.SelectRoleStage

		game:ReturnToSelectRoleStage(0)

	--改变流程，在S2CBriefUserInfo中处理
	--清理资源后在返回选角色界面
end

PBHelper.AddHandler("S2CLogoutRole", OnLogoutRole)