local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CLoginMan = require "Main.CLoginMan"
--local GlobalDefinition = require "PB.data".GlobalDefinition()
local UserData = require "Data.UserData".Instance()
local CPanelLogin = Lplus.Extend(CPanelBase, "CPanelLogin")
local def = CPanelLogin.define

def.field("userdata")._Btn_TouchScreen = nil
def.field("userdata")._Lab_TouchScreen = nil
def.field("userdata")._Frame_Input = nil
def.field("userdata")._Frame_Btn = nil
def.field("userdata")._Frame_Server1 = nil
def.field("userdata")._Lab_ServerInfo = nil
def.field("userdata")._Img_Sign1 = nil
def.field("userdata")._InputFieldAccount = nil
def.field("userdata")._InputFieldPassword = nil
def.field("userdata")._Lab_Version = nil

def.field("userdata")._Frame_KakaoLogin = nil
def.field("userdata")._Frame_LongtuLogin = nil
def.field("userdata")._Btn_OnlyServerSelect = nil
def.field("userdata")._Frame_Server2 = nil
def.field("userdata")._Lab_OnlyServerSelect = nil
def.field("userdata")._Img_Sign2 = nil

def.field("number")._OpenType = 0
def.field("number")._SelectZoneId = 0
def.field("table")._ServerList = BlankTable
def.field("number")._StartTimerId = 0
def.field("string")._DebugAccount = ""

local instance = nil
def.static("=>", CPanelLogin).Instance = function ()
	if not instance then 
		instance = CPanelLogin()
		instance._PrefabPath = PATH.Panel_Login
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ClickInterval = 2
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then
		return
	end
	self._Btn_TouchScreen = self:GetUIObject("Btn_TouchScreen")
	self._Lab_TouchScreen = self:GetUIObject("Lab_TouchScreen")
	self._Frame_Input = self:GetUIObject("Frame_Input")
	self._Frame_Btn = self:GetUIObject("Frame_Btn")
	self._Frame_Server1 = self:GetUIObject("Frame_Server1")
	self._Lab_ServerInfo = self:GetUIObject("Lab_ServerInfo")
	self._Img_Sign1 = self:GetUIObject("Img_Sign1")
	self._Lab_Version = self:GetUIObject("Lab_CurrentVersion")
	local InputFieldType = ClassType.InputField
	self._InputFieldAccount = self:GetUIObject("InputField_Account"):GetComponent(InputFieldType)
	self._InputFieldPassword = self:GetUIObject("InputField_Password"):GetComponent(InputFieldType)

	self._Btn_TouchScreen:SetActive(false)
	GUITools.SetUIActive(self._Frame_Btn, false)

	-- Kakao
	self._Frame_KakaoLogin = self:GetUIObject("Frame_KakaoLogin")
	self._Frame_LongtuLogin = self:GetUIObject("Frame_LongtuLogin")
	self._Btn_OnlyServerSelect = self:GetUIObject("Btn_OnlyServerSelect")
	self._Frame_Server2 = self:GetUIObject("Frame_Server2")
	self._Lab_OnlyServerSelect = self:GetUIObject("Lab_OnlyServerSelect")
	self._Img_Sign2 = self:GetUIObject("Img_Sign2")

	local locale = ""
	if GameUtil.GetConfigLocale ~= nil then
		locale = GameUtil.GetConfigLocale()
	end
	if false then
		local comp0 = self._Panel:FindChild("Img_Tips/Lab_ComInfo")
		if comp0 then comp0:SetActive(false) end
		local comp1 = self._Panel:FindChild("Img_Tips/Img_KakaoLogo")
		if comp1 then comp1:SetActive(false) end
		local comp2 = self._Panel:FindChild("Img_Tips/Img_LantuLogo")
		if comp2 then comp2:SetActive(false) end
		local comp3 = self._Panel:FindChild("Img_Tips/Img_bg")
		if comp3 then comp3:SetActive(false) end
	end
end

local function RemoveStartTimer(self)
	if self._StartTimerId ~= 0 then
		_G.RemoveGlobalTimer(self._StartTimerId)
		self._StartTimerId = 0
	end
end

-- 根据类型返回账号密码
local function GetAccountAndPassword(self)
	if self._OpenType == EnumDef.PanelLoginOpenType.DebugLogin then
		local account = self._DebugAccount
		local password = self._InputFieldPassword.text
		return account, password
	else
		local account = CPlatformSDKMan.Instance():GetUserID()
		local password = "111"
		return account, password
	end
end

-- 根据服务器ID获取服务器信息
local function GetServerInfoByZoneId(self, zoneId)
	for _, info in ipairs(self._ServerList) do
		if info.zoneId == zoneId then
			return info
		end
	end
	return nil
end

-- @param data
--        IsOnGameStart:是否属于登录流程 	默认false
--        OpenType:打开类型 				默认DebugLogin
def.override("dynamic").OnData = function(self, data)
	local isFirstOpen = false
	if data ~= nil and data.IsOnGameStart then
		isFirstOpen = true
	end
	self:SetCommon(isFirstOpen)

	self._SelectZoneId = 0
	self._ServerList = {}
	self._Frame_Server1:SetActive(false)
	self._Frame_Server2:SetActive(false)

	self._OpenType = CPlatformSDKMan.Instance():GetPanelLoginOpenType()
	self:CheckOpenType(self._OpenType)
end

def.method().RequestData = function (self)
	self:RequestDataInternal(nil)
end

def.method("function").RequestDataInternal = function (self, callback)
	game._GUIMan:ShowCircle(StringTable.Get(32), true)

	local serverReady, accountReady = false, false
	local function ShowList()
		if serverReady and accountReady then
			game._GUIMan:CloseCircle()
			if self:IsShow() then
				local server_list = CLoginMan.GetServerList()
				self:RefreshServerList(server_list)

				if callback ~= nil then
					-- 属于点击了之后的重新请求
					if next(server_list) == nil then
						-- 点击了之后的重新请求服务器列表再次失败，弹窗提示
						local title = StringTable.Get(8)
						local msg = StringTable.Get(14009)
						MsgBox.ShowMsgBox(msg, title, 0, MsgBoxType.MBBT_OKCANCEL, function(ret)
							-- 弹退出游戏弹窗
							if ret then
								GameUtil.QuitGame()
							end
						end)
					else
						callback()
					end
				end
			end
		end
	end
	-- 请求服务器列表
	CLoginMan.RequestServerList(function ()
		serverReady = true
		ShowList()
	end)
	-- 请求账号信息
	local account, _ = GetAccountAndPassword(self)
	if not IsNilOrEmptyString(account) then
		CLoginMan.RequestAccountRoleList(account, function ()
			accountReady = true

			-- 刷新GM界面
			local DebugTools = require "Main.DebugTools"
			DebugTools.ResetDebugToolState()

			ShowList()
		end)
	else
		accountReady = true
		ShowList()
	end
end

def.method("table").RefreshServerList = function (self, serverlist)
	if serverlist == nil then
		error("RefreshServerList failed, serverlist got nil", debug.traceback())
		return
	end

	--warn("RefreshServerList!! count:", #serverlist)
	self._ServerList = serverlist

	-- if self._SelectZoneId == 0 then
	-- 	local account, password = GetAccountAndPassword(self)
	-- 	if not IsNilOrEmptyString(account) and not IsNilOrEmptyString(password) then
	-- 		local roleList = CLoginMan.GetAccountRoleList(account)
	-- 		for _, info in ipairs(roleList) do
	-- 			if GetServerInfoByZoneId(self, info.zoneId) then
	-- 				--  找到一个在服务器列表里的
	-- 				self._SelectZoneId = info.zoneId
	-- 				break
	-- 			end
	-- 		end
	-- 	end
	-- end
	if self._SelectZoneId == 0 then
		-- 没有获取到中心服已有角色信息，读取本地数据
		local last_login_server_name = UserData:GetCfg(EnumDef.LocalFields.LastLonginServer, "ServerName")
		if not IsNilOrEmptyString(last_login_server_name) then
			for _, info in ipairs(serverlist) do
				if info.name == last_login_server_name then
					self._SelectZoneId = info.zoneId
					break
				end
			end
		end
	end

	local serverInfo = GetServerInfoByZoneId(self, self._SelectZoneId)
	self._Frame_Server1:SetActive(serverInfo ~= nil)
	self._Frame_Server2:SetActive(serverInfo ~= nil)
	if serverInfo ~= nil then
		self:SetServerShow(serverInfo.name, serverInfo.state)
	end

	if next(self._ServerList) == nil then
		warn("RefreshServerList serverlist got empty.")
	end
end

-- 进行通用的设置
def.method("boolean").SetCommon = function (self, isFirstOpen)
	-- 背景音乐
	CSoundMan.Instance():PlayBackgroundMusic(PATH.BGM_Login, 0)
	-- 版本号
	local version = GameUtil.GetCurrentVersion()
	GUI.SetText(self._Lab_Version, version)
	-- 右上角按钮动效
	GUITools.DoScale(self._Frame_Btn, Vector3.one, 0.5, nil)

	if isFirstOpen then
		-- 第一次打开登录界面
		-- GameUtil.ContinueLogoMaskFade()
	else
		StartScreenFade(1, 0, 1, nil)
		GameUtil.OpenOrCloseLoginLogo(true) -- 登录界面的Logo是单独的
	end
	-- 背景视频
	self:PlayVideoBG()
end

-- 设置服务器显示信息
def.method("string", "number").SetServerShow = function (self, server_name, server_state)
	-- 服务器名称
	GUI.SetText(self._Lab_ServerInfo, server_name)
	GUI.SetText(self._Lab_OnlyServerSelect, server_name)
	-- 服务器状态
	local img_index = 3 -- 不可用
	if server_state == EnumDef.ServerState.Good then
		img_index = 0
	elseif server_state == EnumDef.ServerState.Normal then
		img_index = 1
	elseif server_state == EnumDef.ServerState.Busy then
		img_index = 2
	end
	GUITools.SetGroupImg(self._Img_Sign1, img_index)
	GUITools.SetGroupImg(self._Img_Sign2, img_index)
end

def.method("number").CheckOpenType = function (self, openType)
	if openType == EnumDef.PanelLoginOpenType.DebugLogin then
		self._Frame_Input:SetActive(true)
		self._Frame_KakaoLogin:SetActive(false)
		self._Frame_LongtuLogin:SetActive(false)
		self._Btn_OnlyServerSelect:SetActive(false)
		self:StartDebugLogin()
	else
		self._Frame_Input:SetActive(false)
		if openType == EnumDef.PanelLoginOpenType.KakaoLogin then
			self._Frame_KakaoLogin:SetActive(true)
			self._Frame_LongtuLogin:SetActive(false)
			self._Btn_OnlyServerSelect:SetActive(false)
			self:StartKakaoLogin()
		elseif openType == EnumDef.PanelLoginOpenType.LongtuLogin then
			self._Frame_KakaoLogin:SetActive(false)
			self._Frame_LongtuLogin:SetActive(true)
			self._Btn_OnlyServerSelect:SetActive(false)
			self:StartLongtuLogin()
		elseif openType == EnumDef.PanelLoginOpenType.OnlyServer then
			self._Frame_KakaoLogin:SetActive(false)
			self._Frame_LongtuLogin:SetActive(false)
			self._Btn_OnlyServerSelect:SetActive(true)
			self:OpenServerInfo()
		end
	end
end

def.method().StartDebugLogin = function (self)
	GUITools.SetUIActive(self._Frame_Input, false)
	GUITools.DoScale(self._Frame_Input, Vector3.one, 0.5, function ()
		self._Btn_TouchScreen:SetActive(true)
	end)

	local last_use_account_account = UserData:GetCfg(EnumDef.LocalFields.LastUseAccount, "Account")
	if last_use_account_account == nil then
		self._DebugAccount = ""
		self._InputFieldAccount.text = ""
	else
		self._DebugAccount = last_use_account_account
		self._InputFieldAccount.text = last_use_account_account
	end
	local last_use_account_password = UserData:GetCfg(EnumDef.LocalFields.LastUseAccount, "Password")
	if last_use_account_password == nil then
		self._InputFieldPassword.text = ""
	else
		self._InputFieldPassword.text = last_use_account_password
	end

	self._OpenType = EnumDef.PanelLoginOpenType.DebugLogin
	self:RequestDataInternal(nil)
end

-------------------------------SDK Login Start---------------------------------
def.method().StartKakaoLogin = function (self)
	GUITools.SetUIActive(self._Frame_KakaoLogin, false)
	GUITools.DoScale(self._Frame_KakaoLogin, Vector3.one, 0.5, nil)

	self._OpenType = EnumDef.PanelLoginOpenType.KakaoLogin
end

def.method().StartLongtuLogin = function (self)
	GUITools.SetUIActive(self._Frame_LongtuLogin, false)
	GUITools.DoScale(self._Frame_LongtuLogin, Vector3.one, 0.5, nil)

	self._OpenType = EnumDef.PanelLoginOpenType.KakaoLogin
end

def.method().OpenServerInfo = function (self)
	GUITools.SetUIActive(self._Btn_OnlyServerSelect, false)
	GUITools.DoScale(self._Btn_OnlyServerSelect, Vector3.one, 0.5, function ()
		self._Btn_TouchScreen:SetActive(true)
	end)

	self._OpenType = EnumDef.PanelLoginOpenType.OnlyServer
	self:RequestDataInternal(nil)
end
--------------------------------SDK Login End----------------------------------

def.method("number").UpdateServerInfo = function(self, zoneId)
	if next(self._ServerList) == nil then return end
	-- 平台SDK打点
	local PlatformSDKDef = require "PlatformSDK.PlatformSDKDef"
	CPlatformSDKMan.Instance():SetBreakPoint(PlatformSDKDef.PointState.Game_Select_Server)

	local serverInfo = GetServerInfoByZoneId(self, zoneId)
	self._Frame_Server1:SetActive(serverInfo ~= nil)
	self._Frame_Server2:SetActive(serverInfo ~= nil)
	if serverInfo ~= nil then
		self._SelectZoneId = zoneId
		self:SetServerShow(serverInfo.name, serverInfo.state)
	end
end

def.override("string").OnClick = function(self, id)
	if _G.ForbidTimerId ~= 0 then				--不允许输入
		return
	end

	if id == "Btn_ServerSelect" or id == "Btn_OnlyServerSelect" then
		if game:GetNetworkStatus() == EnumDef.NetworkStatus.NotReachable then
			-- 没有网络
			local title = StringTable.Get(8)
			local msg = StringTable.Get(14007)
			MsgBox.ShowMsgBox(msg, title, 0, MsgBoxType.MBBT_OK)
			return
		end
		
		-- game:AddForbidTimer(self._ClickInterval)
		self:RequestDataInternal(function()
			local accountStr, passwordStr = GetAccountAndPassword(self)
			game._GUIMan:Open("CPanelServerSelect", { account = accountStr, password = passwordStr })
		end)
	elseif id == "Btn_TouchScreen" then
		game:AddForbidTimer(self._ClickInterval)
		
		if game._GUIMan:IsCircleShow() then return end
		
		game._GUIMan:CloseCircle()
		game:CloseConnection()
		self:OnBtnStartGame()
	elseif id == "Btn_Stadio" then
		game._GUIMan:Open("CPanelProducers", nil)
	elseif id == "Btn_Setting" then
		TODO()
	elseif id == "Btn_PlayVideo" then
		self:PlayOpenVideo()
	elseif id == "Btn_KakaoLogin" then
		CPlatformSDKMan.Instance():LoginAsKakao()
	elseif id == "Btn_GuestLogin" then
		-- 游客登录需要弹确认弹窗
		local title, msg, closeType = StringTable.GetMsg(133)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, function(ret)
			if ret then
				CPlatformSDKMan.Instance():LoginAsGuest()
			end
		end)
	elseif id == "Btn_LongtuLogin" then
		CPlatformSDKMan.Instance():LoginAsLongtu()
	end
end

def.override("string", "string").OnEndEdit = function(self, id, str)
	if string.find(id, "InputField_Account") then
		if str ~= self._DebugAccount then
			-- 更改了账号
			self._DebugAccount = str
			self:RequestDataInternal(nil)
		end
	end
end

-- 点击进入游戏
def.method().OnBtnStartGame = function(self)
	GameUtil.PlayUISfx(PATH.UIFX_ENTERGAME, self._Lab_TouchScreen, self._Lab_TouchScreen, -1)

	RemoveStartTimer(self)
	-- 等待特效播放
	self._StartTimerId = _G.AddGlobalTimer(self._ClickInterval / 2, true, function()
		if game:GetNetworkStatus() == EnumDef.NetworkStatus.NotReachable then
			-- 没有网络
			local title = StringTable.Get(8)
			local msg = StringTable.Get(14007)
			MsgBox.ShowMsgBox(msg, title, 0, MsgBoxType.MBBT_OK)
			return
		end
		local function TryConnectPhase1()
			local account, password = GetAccountAndPassword(self)
			if not CLoginMan.CheckAccountValid(account, password) then
				return
			end
			if self._SelectZoneId == 0 then
				-- 没有默认服务器，打开服务器选择界面
				local accountStr, passwordStr = GetAccountAndPassword(self)
				game._GUIMan:Open("CPanelServerSelect", { account = accountStr, password = passwordStr })
				return
			end

			local server_info = GetServerInfoByZoneId(self, self._SelectZoneId)
			if server_info == nil then return end

			local ip = server_info.ip
			local port = server_info.port
			local name = server_info.name
			local function TryConnectPhase2()
				local function TryConnectPhase3()
					CLoginMan.Instance():SetQuickEnterRoleId(0)
					CLoginMan.Instance():ConnectToServer(ip, port, name, account, password)
				end
				if server_info.roleCreateDisable then
					-- 服务器禁止创建角色
					local title, msg, closeType = StringTable.GetMsg(132)
					MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, function(ret)
						if ret then
							TryConnectPhase3()
						end
					end)
				else
					TryConnectPhase3()
				end
			end
			if not CLoginMan.CanServerUse(ip, port) then
				-- 服务器维护中
				self:RequestDataInternal(function ()
					if not CLoginMan.CanServerUse(ip, port) then
						-- 再次请求之后还是维护中，弹窗提示
						local title = StringTable.Get(8)
						local msg = StringTable.Get(14008)
						MsgBox.ShowMsgBox(msg, title, 0, MsgBoxType.MBBT_OK)
						return
					end
					TryConnectPhase2()
				end)
			else
				TryConnectPhase2()
			end
		end
		if next(self._ServerList) == nil then
			self:RequestDataInternal(TryConnectPhase1)
		else
			TryConnectPhase1()
		end
	end)
end

def.method().PlayVideoBG = function (self)
	if not GameUtil.IsPlayingVideo() then
		GameUtil.PlayVideo("TERA_BackgroundStory.mp4", true)
	end
end

def.method().PlayOpenVideo = function (self)
	game._GUIMan:Close("CPanelLogin")			--关闭Login
	CSoundMan.Instance():StopBackgroundMusic()
	GameUtil.PlayVideo("TERA_Open.mp4", false, true, function()
			game._GUIMan:Open("CPanelLogin", nil)		--播放完毕, 开启Login
		end);
end

def.override().OnDestroy = function(self)
	GameUtil.StopVideo()
	GameUtil.OpenOrCloseLoginLogo(false)
	RemoveStartTimer(self)

    self._Btn_TouchScreen = nil
    self._Lab_TouchScreen = nil
	self._Frame_Input = nil
	self._Frame_Btn = nil
	self._Frame_Server1 = nil
	self._Lab_ServerInfo = nil
	self._Img_Sign1 = nil
	self._InputFieldAccount = nil
	self._InputFieldPassword = nil
	self._Lab_Version = nil

	self._Frame_KakaoLogin = nil
	self._Frame_LongtuLogin = nil
	self._Btn_OnlyServerSelect = nil
	self._Frame_Server2 = nil
	self._Lab_OnlyServerSelect = nil
	self._Img_Sign2 = nil
end

CPanelLogin.Commit()
return CPanelLogin