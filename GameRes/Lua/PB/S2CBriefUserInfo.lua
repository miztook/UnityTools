--
-- S2CBriefUserInfo
-- 
local PBHelper = require "Network.PBHelper"

local function OnBriefUserInfo(sender, msg)
	game._AnotherDeviceLogined = false

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
	
	warn("OnBriefUserInfo Role count:", #list)
	
	game._AccountInfo._RoleList = list
	game._AccountInfo._OrderRoleName = msg.OrderedRole.RoleName

	--收到服务器登录消息之后再打开Loading界面
	-- game._GUIMan:Open("CPanelLoading", nil)
	
	_G.canSendPing = true
	_G.canAutoReconnect = true

	local CLoginMan = require "Main.CLoginMan"
	if CLoginMan.Instance():GetQuickEnterRoleId() <= 0 and msg.SelectRoleId == 0 then	--登录上次角色
		game:ReturnSelectRole()
	else
		CLoginMan.Instance():OnAccountInfoSet(msg.SelectRoleId)
	end



end

PBHelper.AddHandler("S2CBriefUserInfo", OnBriefUserInfo)
