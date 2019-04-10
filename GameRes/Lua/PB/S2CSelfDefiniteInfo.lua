--
-- S2CSelfDefiniteInfo
-- 
local PBHelper = require "Network.PBHelper"

local function OnSelfDefiniteInfo(sender, msg)

	local info = msg.DetailRoleInfo
	if game._HostPlayer == nil then			
		game:PrepareForGameStart()
		game:CreateHostPlayer(info)

		-- 平台上传角色信息
		CPlatformSDKMan.Instance():UploadRoleInfo(EnumDef.UploadRoleInfoType.Login)
	else
		game._HostPlayer:ResetServerState(info)		--断线重连后同步服务器的状态	
	end
	-- 弹出app弹窗
	game:OnAppMsgBoxStatic(EnumDef.TriggerTag.ReachGloryLevel, info.GloryLevel)
end

PBHelper.AddHandler("S2CSelfDefiniteInfo", OnSelfDefiniteInfo)
