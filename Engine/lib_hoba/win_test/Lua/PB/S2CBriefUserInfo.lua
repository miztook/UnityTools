--
-- S2CBriefUserInfo
-- 
local PBHelper = require "Network.PBHelper"

local function OnBriefUserInfo(sender, msg)
	if game._AccountInfo == nil then
		local CAccountInfo = require "Main.CAccountInfo"
		game._AccountInfo = CAccountInfo.new()
	end

	local briefAccountInfo = msg.BriefAccountInfo

	game._AccountInfo._Diamond = briefAccountInfo.Diamond
	game._AccountInfo._VipLevel = briefAccountInfo.VipLevel
	game._AccountInfo._VipExp = briefAccountInfo.VipExp
	game._AccountInfo._ParagonLevel = briefAccountInfo.ParagonLevel
	game._AccountInfo._ParagonExp =  briefAccountInfo.ParagonExp
	game._AccountInfo._RoleList = {}
	local list = {}
	for i = 1, #msg.BriefRoleInfoList do
		list[#list+1] =  msg.BriefRoleInfoList[i]
	end
	--warn("Role count:", #list, #msg.BriefRoleInfoList)
	game._AccountInfo._RoleList = list
	--收到服务器登录消息之后再打开Loading界面
	game._GUIMan:Open("CPanelLoading", nil)
	game:EnterRoleSelectStage(1)
end

PBHelper.AddHandler("S2CBriefUserInfo", OnBriefUserInfo)
