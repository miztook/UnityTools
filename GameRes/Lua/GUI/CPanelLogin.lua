local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
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

local instance = nil
def.static("=>", CPanelLogin).Instance = function ()
	if not instance then 
		instance = CPanelLogin()
		instance._PrefabPath = PATH.Panel_Login
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ClickInterval = 1
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
		local account = self._InputFieldAccount.text
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

	self._OpenType = CPlatformSDKMan.Instance():GetPanelLoginOpenType()
	self:CheckOpenType(self._OpenType)

	self._SelectZoneId = 0
	local server_list = GameUtil.GetServerList(true)
	self:RefreshServerList(server_list)
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
	-- 		local CLoginMan = require "Main.CLoginMan"
	-- 		local roleList = CLoginMan.GetAccountRoleList(account, true)
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
		game._GUIMan:ShowTipText(StringTable.Get(14005), false)
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
		GameUtil.ContinueLogoMaskFade()
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
		self._InputFieldAccount.text = ""
	else
		self._InputFieldAccount.text = last_use_account_account
	end
	local last_use_account_password = UserData:GetCfg(EnumDef.LocalFields.LastUseAccount, "Password")
	if last_use_account_password == nil then
		self._InputFieldPassword.text = ""
	else
		self._InputFieldPassword.text = last_use_account_password
	end

	self._OpenType = EnumDef.PanelLoginOpenType.DebugLogin
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
		game:AddForbidTimer(self._ClickInterval)
		
		local accountStr, passwordStr = GetAccountAndPassword(self)
		game._GUIMan:Open("CPanelServerSelect", { account = accountStr, password = passwordStr })
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
		CPlatformSDKMan.Instance():LoginAsGuest()
	elseif id == "Btn_LongtuLogin" then
		CPlatformSDKMan.Instance():LoginAsLongtu()
	end
end

-- 点击进入游戏
def.method().OnBtnStartGame = function(self)
	GameUtil.PlayUISfx(PATH.UIFX_ENTERGAME, self._Lab_TouchScreen, self._Lab_TouchScreen, -1)

	RemoveStartTimer(self)
	self._StartTimerId = _G.AddGlobalTimer(self._ClickInterval / 2, true, function()
		-- 等待特效播放
		if next(self._ServerList) == nil then 
			local server_list = GameUtil.GetServerList(true)
			self:RefreshServerList(server_list)
			return
		end
		local CLoginMan = require "Main.CLoginMan"
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
		local ip, port, name = "", 0, ""
		if server_info ~= nil then
			ip = server_info.ip
		 	port = server_info.port
		 	name = server_info.name
		end
		CLoginMan.Instance():SetQuickEnterRoleId(0)
		CLoginMan.Instance():ConnectToServer(ip, port, name, account, password)
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