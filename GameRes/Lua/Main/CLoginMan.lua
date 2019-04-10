-- 登录管理

local Lplus = require "Lplus"
local CLoginMan = Lplus.Class("CLoginMan")
local def = CLoginMan.define

local PBHelper = require "Network.PBHelper"
local UserData = require "Data.UserData".Instance()
local ROLE_VAILD = require "PB.data".ERoleVaild
local CElementData = require "Data.CElementData"
local CPanelLoginIns = require "GUI.CPanelLogin".Instance()

def.field("number")._QuickEnterRoleId = 0 -- 快速进入的角色Id
def.field("string")._OrderRoleName = "" -- 预约的角色名字

local instance = nil
def.static("=>", CLoginMan).Instance = function ()
	if instance == nil then
		instance = CLoginMan()
	end
	return instance
end

-- 获取账号信息列表
def.static("string", "boolean", "=>", "table").GetAccountRoleList = function (account, isRefresh)
	--[[
	roleList =
	{
		[1] =
		{
			roleId,
			level,
			name,
			profession,
			customSet,
			zoneId,
		},
		...
	}
	--]]
	local roleList = GameUtil.GetAccountRoleList(account, isRefresh) -- 先从中心服获取
	local localRoleList = UserData:GetCfg(EnumDef.LocalFields.RecentLoginRoleInfo, account)
	if localRoleList ~= nil then
		-- 加入本地服务器的本地角色数据
		local isFront = true
		local insertIndex = 1
		for _, info in ipairs(localRoleList) do
			if info.zoneId < 0 then
				-- 属于本地服务器
				if roleList == nil then
					roleList = {}
				end
				table.insert(roleList, insertIndex, info)
				insertIndex = insertIndex + 1
			else
				if roleList ~= nil then
					for i=insertIndex, #roleList do
						local roleInfo = roleList[i]
						if roleInfo.roleId == info.roleId then
							insertIndex = i+1
							break
						end
					end
				end
			end
		end
	end
	return roleList
end

-- 检查账号名的合法性
def.static("string", "string", "=>", "boolean").CheckAccountValid = function (account, password)
	if account == nil or password == nil then
		warn("CheckAccountValid failed, account or password got nil", debug.traceback())
		return false
	end
	local len = GameUtil.GetStringLength(account)
	local min = GlobalDefinition.MinAccountLength
	local max = GlobalDefinition.MaxAccountLength
	if(len < min or len > max) then
		local ServerMessageBase = require "PB.data".ServerMessageBase
		local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.AccountLengthInvalid)
		local message = ""
		if template == nil then
			message = StringTable.Get(9)
		else
			message = template.TextContent
		end
		game._GUIMan:CloseCircle()
		MsgBox.CloseAll()
		MsgBox.ShowSystemMsgBox(ServerMessageBase.AccountLengthInvalid, message, StringTable.Get(8), MsgBoxType.MBBT_OK)
		return false
	end

	if password == "" then
		game._GUIMan:CloseCircle()
		MsgBox.CloseAll()
		local title, msg, closeType = StringTable.GetMsg(52)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
		return false
	end
	return true
end

-- 服务器是否维护中
def.static("string", "number", "=>", "boolean").CanServerUse = function (ip, port)
	local serverList = GameUtil.GetServerList(false)
	if serverList ~= nil then
		for _, info in ipairs(serverList) do
			if ip == info.ip and port == info.port then
				return info.state ~= EnumDef.ServerState.Unuse
			end
		end
	end
	return false
end

-- 设置快速进入角色Id
def.method("number").SetQuickEnterRoleId = function (self, roleId)
	self._QuickEnterRoleId = roleId
end

def.method("=>", "string").GetOrderRoleName = function (self)
	return self._OrderRoleName
end

def.method("string").SetOrderRoleName = function (self, roleName)
	self._OrderRoleName = roleName
end

-- 连接服务器
def.method("string", "number", "string", "string", "string").ConnectToServer = function(self, ip, port, server_name, account, password)
	if not CLoginMan.CheckAccountValid(account, password) then return end

	if not CLoginMan.CanServerUse(ip, port) then
		-- 服务器维护中，刷新服务器列表
		game._GUIMan:ShowTipText(StringTable.Get(32), false)
		if CPanelLoginIns:IsShow() then
			local server_list = GameUtil.GetServerList(true)
			CPanelLoginIns:RefreshServerList(server_list)
		end
		return
	end

	if game._NetMan:IsValidIpAddress(ip) then
		-- 平台SDK打点
		local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
		CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_User_Login)

		game._NetMan:Connect(ip, port, server_name, account, password)
		game._GUIMan:ShowCircle(StringTable.Get(14002), true)

		UserData:SetCfg(EnumDef.LocalFields.LastLonginServer, "Ip", ip)
		UserData:SetCfg(EnumDef.LocalFields.LastLonginServer, "Port", port)
		UserData:SetCfg(EnumDef.LocalFields.LastLonginServer, "ServerName", server_name)
		UserData:SetCfg(EnumDef.LocalFields.LastUseAccount, "Account", account)
		UserData:SetCfg(EnumDef.LocalFields.LastUseAccount, "Password", password)
	    UserData:SaveDataToFile()
	else
		local callback = function()	
			game._GUIMan:CloseCircle()
			MsgBox.CloseAll()

			--如果连接失败，刷新服务器列表
			if CPanelLoginIns:IsShow() then
				local server_list = GameUtil.GetServerList(true)
				CPanelLoginIns:RefreshServerList(server_list)
			end
		end
		do
			local message = ""
			local ServerMessageBase = require "PB.data".ServerMessageBase
			local CElementData = require "Data.CElementData"
			local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.ConnectedFailed)
			if template == nil then
				message = "连接失败"
			else
				message = template.TextContent
			end
			game._GUIMan:ShowCircle(message, false)
		end
		_G.AddGlobalTimer(1.5, true, callback)
	end
end

-- 快速进入角色选择界面
def.method().QuickStartGame = function(self)
	local last_use_account_account = UserData:GetCfg(EnumDef.LocalFields.LastUseAccount, "Account")
	if last_use_account_account == nil then
		last_use_account_account = ""
	end
	local last_use_account_password = UserData:GetCfg(EnumDef.LocalFields.LastUseAccount, "Password")
	if last_use_account_password == nil then
		last_use_account_password = ""
	end
	if not CLoginMan.CheckAccountValid(last_use_account_account, last_use_account_password) then
	   return
	end

	local last_login_server_ip = UserData:GetCfg(EnumDef.LocalFields.LastLonginServer, "Ip")
	if last_login_server_ip == nil then
		last_login_server_ip = "127.0.0.1"
	end

	local last_login_server_port = UserData:GetCfg(EnumDef.LocalFields.LastLonginServer, "Port")
	if last_login_server_port == nil then
		last_login_server_port = 8001
	end

	local last_login_server_name = UserData:GetCfg(EnumDef.LocalFields.LastLonginServer, "ServerName")
	if last_login_server_name == nil then
		last_login_server_name = "本机测试服"
	end

	if last_use_account_account == "" or last_use_account_password == "" then
		game._GUIMan:CloseCircle()
		MsgBox.CloseAll()
		local title, msg, closeType = StringTable.GetMsg(52)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
	else
		self._QuickEnterRoleId = 0

		if game._NetMan:IsValidIpAddress(last_login_server_ip) then
			game._NetMan:Connect(last_login_server_ip, last_login_server_port, last_login_server_name, last_use_account_account, last_use_account_password)
			game._GUIMan:ShowCircle(StringTable.Get(14002), true)
		else		
			local callback = function()	
				game._GUIMan:CloseCircle()
				MsgBox.CloseAll()

				--如果连接失败，刷新服务器列表
				if CPanelLoginIns:IsShow() then
					local server_list = GameUtil.GetServerList(true)
					CPanelLoginIns:RefreshServerList(server_list)
				end
			end
			do
				local message = ""
				local ServerMessageBase = require "PB.data".ServerMessageBase
				local CElementData = require "Data.CElementData"
				local template = CElementData.GetSystemNotifyTemplate(ServerMessageBase.ConnectedFailed)
				if template == nil then
					message = "连接失败"
				else
					message = template.TextContent
				end
				game._GUIMan:ShowCircle(message, false)
			end
			_G.AddGlobalTimer(1.5, true, callback)
		end
	end
end

def.method("number").OnAccountInfoSet = function (self, selectedRoleId)
	GameUtil.ReportUserId(game._NetMan._UserName)

	if self._QuickEnterRoleId > 0 then
		-- 玩家自己选择快速进入
		self:DoEnterWorld(self._QuickEnterRoleId, false)
		self._QuickEnterRoleId = 0
	elseif selectedRoleId > 0 then
		-- 服务器推送进入
		self:DoEnterWorld(selectedRoleId, true)
	else
		-- 进入选择角色场景
		-- 默认选择上次登录的角色，没有则选择第一个
		local roleIndex = 1
		do
			local curZoneId = game._NetMan:GetCurZoneId()
			if curZoneId > 0 then
				local curRoleId = 0
				local roleList = CLoginMan.GetAccountRoleList(game._NetMan._UserName, true)
				if roleList ~= nil then
					for _, info in ipairs(roleList) do
						if info.zoneId == curZoneId then
							curRoleId = info.roleId
							break
						end
					end
				end
				if curRoleId > 0 then
					for index, info in ipairs(game._AccountInfo._RoleList) do
						if info.Id == curRoleId then
							roleIndex = index
							break
						end
					end
				end
			end
		end
		-- 进入账号角色相关界面
		game:EnterRoleSelectStage(roleIndex)
	end
end

-- 快速进入游戏世界（不需要进入角色选择界面）
def.method("number").QuickEnterWorld = function (self, index)
	local roleInfoList = UserData:GetCfg(EnumDef.LocalFields.QuickEnterGameRoleInfo, game._NetMan._UserName)
	if type(roleInfoList) == "table" and #roleInfoList > 0 then
		-- 找到对应角色信息
		local selectedRoleInfo = roleInfoList[index]
		if selectedRoleInfo == nil then return end

		local selectedRoleId = 0
		if selectedRoleInfo.HeadIcon ~= nil and type(selectedRoleInfo.HeadIcon.RoleID) == "number" then
			selectedRoleId = selectedRoleInfo.HeadIcon.RoleID
		end

		self:DoEnterWorld(selectedRoleId, false)
	end
end

def.method("number", "boolean").DoEnterWorld = function (self, selectedRoleId, bServerQuickEnter)
	if selectedRoleId <= 0 then return end

	for i, role in ipairs(game._AccountInfo._RoleList) do
		if role.Id == selectedRoleId then
			if role.RoleVaild == ROLE_VAILD.HangUp then
				-- 正在删除中
				game._GUIMan:ShowTipText(StringTable.Get(18), false)
				game._GUIMan:CloseCircle()	
			else 
				game._AccountInfo._CurrentSelectRoleIndex = i
				if not bServerQuickEnter then				--客户端发C2SRoleSelect才会收到S2CSelfDefiniteInfo
					local function callback()
						game._GUIMan:Close("CPanelServerSelect")
						game._GUIMan:Close("CPanelLogin")
						game._GUIMan:Close("CPanelUIServerQueue")
						game._GUIMan:CloseCircle()

						game:SendSelectRole(role.Id)
					end
					StartScreenFade(0, 1, 0.5, callback)
				else                             --接下来会收到S2CSelfDefiniteInfo
					game._AccountInfo._CurrentSelectRoleIndex = i

					game._GUIMan:Close("CPanelServerSelect")
					game._GUIMan:Close("CPanelLogin")
					game._GUIMan:Close("CPanelUIServerQueue")

					if not game._IsReconnecting then
						game._GUIMan:CloseCircle()
					end
				end
			end
			break
		end
	end
end

CLoginMan.Commit()
return CLoginMan