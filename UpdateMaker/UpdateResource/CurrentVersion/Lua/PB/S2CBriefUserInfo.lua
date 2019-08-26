--
-- S2CBriefUserInfo
-- 
local PBHelper = require "Network.PBHelper"

local function OnBriefUserInfo(sender, msg)
	-- 平台SDK打点
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_User_Login_Succeed)

	local game = game
	game._AnotherDeviceLogined = false

	if game._AccountInfo == nil then
		local CAccountInfo = require "Main.CAccountInfo"
		game._AccountInfo = CAccountInfo.new()
	end

	local briefAccountInfo = msg.BriefAccountInfo
	local accountInfo = game._AccountInfo
	accountInfo._Diamond = briefAccountInfo.Diamond
	accountInfo._VipLevel = briefAccountInfo.VipLevel
	accountInfo._VipExp = briefAccountInfo.VipExp
	accountInfo._ParagonLevel = briefAccountInfo.ParagonLevel
	accountInfo._ParagonExp =  briefAccountInfo.ParagonExp

	local list = {}
	for i = 1, #msg.BriefRoleInfoList do
		list[#list+1] =  msg.BriefRoleInfoList[i]
	end
	
	accountInfo._RoleList = list
	accountInfo._OrderRoleName = msg.OrderedRole.RoleName

	_G.CanSendPing = true
	_G.CanAutoReconnect = true

	if game._CurGameStage == _G.GameStage.LoginStage then 
		-- msg.SelectRoleId == 0 : 正常登陆
		-- msg.SelectRoleId > 0 : 快速登陆
		game:EnterSelectRoleStage(msg.SelectRoleId)
	elseif game._CurGameStage == _G.GameStage.InGameStage then
		-- 重连
		if msg.SelectRoleId > 0 then  -- 服务器角色尚未下线，避免Loading
			local loginMan = require "Main.CLoginMan".Instance()
			loginMan:OnAccountInfoSet(msg.SelectRoleId) 
		else -- 服务器角色已经下线

			--[[
			local title, msg, closeType = StringTable.GetMsg(51)

			MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK, 
			function(value) 
				game:ReturnToLoginStage() 
			end, nil, nil, MsgBoxPriority.Disconnect) 
			]]
			
			game:ReturnToLoginStage() 
			game._GUIMan:ShowTipText(StringTable.Get(14003), false)
		end 
	elseif game._CurGameStage == _G.GameStage.SelectRoleStage then
		-- 重新选择角色
		--game:ReturnToSelectRoleStage(msg.SelectRoleId)
	end
end

PBHelper.AddHandler("S2CBriefUserInfo", OnBriefUserInfo)
