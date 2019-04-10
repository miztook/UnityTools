--
-- 平台SDK
--

local Lplus = require "Lplus"
local CPlatformSDKMan = Lplus.Class("CPlatformSDKMan")
local def = CPlatformSDKMan.define

local CGame = Lplus.ForwardDeclare("CGame")
local EPurchaseType = require "PB.data".EPurchaseType
local SDKDef = require "PlatformSDK.PlatformSDKDef"
local PlatformSDKEvent = require "Events.PlatformSDKEvent"

def.field("number")._PlatformType = -1
def.field("string")._UserID = ""
def.field("string")._AccessToken = ""
def.field("boolean")._IsGuest = true
def.field("boolean")._Is2ShowGoogleAchievement = false
def.field("table")._GoogleAchievementList = BlankTable

local DEFAULT_UPLOAD_GUILD_NAME = "-" -- 默认上传的工会名

local instance = nil
def.static("=>",CPlatformSDKMan).Instance = function()
	if not instance then
		instance = CPlatformSDKMan()
	end
	return instance
end

--[[
##################### Callback Function #####################
]]
local function fnInitCallback(bSuccess)
	if instance ~= nil then
		instance:InitCallback(bSuccess)
	end
end
local function fnLoginCallback(eLoginState,strUserName,strAccessToken,strUserID,bGuest)
	if instance ~= nil then
		instance:LoginCallback(eLoginState,strUserName,strAccessToken,strUserID,bGuest)
	end
end
local function fnLogoutCallback(bSuccess)
	if instance ~= nil then
		instance:LogoutCallback(bSuccess)
	end
end
local function fnBuyCallback(bSuccess,iBillingType,strOrderId,strTransactionId,strReceipt)
	if instance ~= nil then
		instance:BuyCallback(bSuccess,iBillingType,strOrderId,strTransactionId,strReceipt)
	end
end

-- 初始化回调
def.method("boolean").InitCallback = function(self,bSuccess)
	warn("初始化回调 Lua::InitCallback...", bSuccess)

	game._GUIMan:CloseCircle()
	if bSuccess then
		local pType = self:GetPlatformType()
		if pType == SDKDef.PlatformType.Any then
			-- Debug Type
			game._GUIMan:Open("CPanelLogin", { IsOnGameStart = true })
		else
			-- 检查自动登录
			-- 如果已自动登录，会调 LoginCallback
			PlatformSDK.CheckAutoLogin()
			local hasLogined = self:IsLogined()
			warn("Platform AutoLogin...", hasLogined)
			if not hasLogined then
				if self:IsInLongtu() then
					-- 龙图平台直接调用登录，走渠道登录进程
					self:LoginAsLongtu()
				else
					-- 还没有登录，需要弹SDK登录界面
					game._GUIMan:Open("CPanelLogin", { IsOnGameStart = true })
				end
			end
		end
	end
end

-- 登录回调
-- @param bSuccess:是否成功
-- @param strUserName:用户名称
-- @param strAccessToken:访问令牌
-- @param strUserID:用户ID
-- @param bGuest:是否游客登录
def.method("number","string","string","string","boolean").LoginCallback = function(self,eLoginState,strUserName,strAccessToken,strUserID,bGuest)
	warn("登录回调 Lua::LoginCallback... ", eLoginState, " ID:", strUserID, " IsGuest:", bGuest, " PushState Player:", self:GetPlayerPushStatus(), "Night:", self:GetNightPushStatus())

	game._GUIMan:CloseCircle()
	if eLoginState == SDKDef.LoginState.Succeed then
		self._UserID = strUserID
		self._AccessToken = strAccessToken
		self._IsGuest = bGuest

		-- Show Lontu Notice
		if self:IsInLongtu() then
			self:SetBreakPoint(SDKDef.PointState.Game_Get_Announcement)
			self:ShowAnnouncement(nil)
		end

		-- 更新界面
		local CPanelLogin = require "GUI.CPanelLogin"
		if CPanelLogin.Instance():IsShow() then
			CPanelLogin.Instance():CheckOpenType(self:GetPanelLoginOpenType())
		else
			game._GUIMan:Open("CPanelLogin", { IsOnGameStart = true })
		end
	elseif eLoginState == SDKDef.LoginState.HasAssociate then
		TODO("在其他地方登录")
	elseif eLoginState == SDKDef.LoginState.TimeOut then
		TODO("登录超时")
	end
end

-- 登出回调
def.method("boolean").LogoutCallback = function(self,bSuccess)
	warn("登出回调 Lua::LogoutCallback...", bSuccess)

	game._GUIMan:CloseCircle()
	if bSuccess then
		self:Clear()
		game:LogoutAccount()
	end
end

-- 支付回调
def.method("boolean","number","string","string","string").BuyCallback = function(self,bSuccess,iBillingType,strOrderId,strTransactionId,strReceipt)
	warn("支付回调 Lua::BuyCallback...", bSuccess)

	if bSuccess then

	else

	end

	-- 验单
	--self:SendC2SPurchaseInfo(bSuccess, strOrderId, strTransactionId, strReceipt)
end

--[[
##################### Client Function #####################
]]

-- 开始SDK登录流程
def.method().StartLoginFlow = function(self)
	game._GUIMan:ShowCircle(StringTable.Get(30), true)

	-- 先注册回调事件
	PlatformSDK.RegisterCallback(fnLoginCallback, fnLogoutCallback, fnBuyCallback)
	PlatformSDK.Initialize(fnInitCallback)
end

-- 重新开始登录流程
def.method().RestartLoginFlow = function(self)
	game._GUIMan:Open("CPanelLogin", { IsOnGameStart = false })
end

def.method().Clear = function(self)
	self._UserID = ""
	self._AccessToken = ""
	self._IsGuest = true
	self._Is2ShowGoogleAchievement = false
	self._GoogleAchievementList = {}
end

def.method("=>", "boolean").IsLogined = function(self)
	return PlatformSDK.GetLoginStatus()
end

def.method("=>", "string").GetUserID = function(self)
	return self._UserID
end

def.method("=>", "boolean").IsGuest = function(self)
	return self._IsGuest
end

def.method("=>", "number").GetPlatformType = function(self)
	if self._PlatformType == -1 then
		self._PlatformType = PlatformSDK.GetPlatformType()
	end
	return self._PlatformType
end

def.method("=>", "boolean").IsInDebug = function(self)
	local pType = self:GetPlatformType()
	return pType == SDKDef.PlatformType.Any
end

def.method("=>", "boolean").IsInKakao = function(self)
	local pType = self:GetPlatformType()
	return pType == SDKDef.PlatformType.KakaoIOS or pType == SDKDef.PlatformType.KakaoAndroid
end

def.method("=>", "boolean").IsInLongtu = function(self)
	local pType = self:GetPlatformType()
	return pType == SDKDef.PlatformType.LongtuIOS or pType == SDKDef.PlatformType.LongtuAndroid
end

def.method("=>", "string").GetAccessToken = function(self)
	return self._AccessToken
end

def.method().LoginAsKakao = function(self)
	if self:IsInDebug() then return end
	-- if self:IsLogined() then
	-- 	warn("LoginAsKakao failed, platform has already logined")
	-- 	return
	-- end
	warn("Start LoginAsKakao...")
	game._GUIMan:ShowCircle(StringTable.Get(14002), true)
	PlatformSDK.Login(SDKDef.KakaoIDP.Kakao)
end

def.method().LoginAsGuest = function(self)
	if self:IsInDebug() then return end
	-- if self:IsLogined() then
	-- 	warn("LoginAsGuest failed, platform has already logined")
	-- 	return
	-- end
	warn("Start LoginAsGuest...")
	game._GUIMan:ShowCircle(StringTable.Get(14002), true)
	PlatformSDK.Login(SDKDef.KakaoIDP.Guest)
end

def.method().LoginAsLongtu = function(self)
	if self:IsInDebug() then return end
	-- game._GUIMan:ShowCircle(StringTable.Get(14002), true)
	warn("Start LoginAsLongtu...")
	PlatformSDK.Login()
end

-- 正常登出
def.method().Logout = function(self)
	if self:IsInDebug() then return end
	game._GUIMan:ShowCircle(StringTable.Get(31), true)
	PlatformSDK.Logout()
end

-- 直接登出
def.method().LogoutDirectly = function(self)
	if self:IsInDebug() then return end
	game._GUIMan:ShowCircle(StringTable.Get(31), true)
	PlatformSDK.LogoutDirectly()
end

-- 账号转变
def.method().AccountConversion = function(self)
	if self:IsInDebug() then return end
	-- if not self:IsLogined() then return end
	game._GUIMan:ShowCircle("", true)
	local function callback(isSuccessful)
		game._GUIMan:CloseCircle()
		if isSuccessful then
			self._IsGuest = false

			local event = PlatformSDKEvent()
			event._Type = EnumDef.PlatformSDKEventType.AccountConversion
			CGame.EventManager:raiseEvent(nil, event)
		end
	end
	PlatformSDK.AccountConversion(callback)
end

-- 账号注销
def.method().Unregister = function(self)
	if self:IsInDebug() then return end
	-- if not self:IsLogined() then return end
	game._GUIMan:ShowCircle("", true)
	local function callback(isSuccessful)
		game._GUIMan:CloseCircle()
		if isSuccessful then
			-- 返回登录界面
			self:Clear()
			game:LogoutAccount()
		end
	end
	PlatformSDK.Unregister(callback)
end

def.method("=>", "number").GetPanelLoginOpenType = function(self)
	local openType = EnumDef.PanelLoginOpenType.DebugLogin
	local pType = self:GetPlatformType()
	if pType == SDKDef.PlatformType.KakaoIOS or pType == SDKDef.PlatformType.KakaoAndroid then
		-- Kakao
		local hasLogined = self:IsLogined()
		openType = hasLogined and EnumDef.PanelLoginOpenType.OnlyServer or EnumDef.PanelLoginOpenType.KakaoLogin
	elseif pType == SDKDef.PlatformType.LongtuIOS or pType == SDKDef.PlatformType.LongtuAndroid then
		-- Longtu
		local hasLogined = self:IsLogined()
		openType = hasLogined and EnumDef.PanelLoginOpenType.OnlyServer or EnumDef.PanelLoginOpenType.LongtuLogin
	end
	return openType
end

def.method("=>", "number").GetChannelType = function(self)
	local EChannelType = require "PB.data".EChannelType
	local cType = EChannelType.EChannelType_default -- 占位，非法
	local pType = self:GetPlatformType()
	if pType == SDKDef.PlatformType.Any then
		-- Debug
		cType = EChannelType.EChannelType_Any
	elseif pType == SDKDef.PlatformType.KakaoIOS or pType == SDKDef.PlatformType.KakaoAndroid then
		-- Kakao
		cType = EChannelType.EChannelType_Kakao
	elseif pType == SDKDef.PlatformType.LongtuIOS or pType == SDKDef.PlatformType.LongtuAndroid then
		-- Longtu
		cType = EChannelType.EChannelType_Longtu
	end
	return cType
end

-- 获取服务器所需参数，每种平台可以自定义
def.method("=>", "string").GetC2SResponseParam1= function(self)
	local param = ""
	if self:IsInLongtu() then
		param = PlatformSDK.GetLoginJson()
	end
	return param
end

def.method("number").UploadRoleInfo = function(self, uploadType)
	local hp = game._HostPlayer
	if hp == nil then return end

	local sendType = 0
	if self:IsInLongtu() then
		 -- 对于龙图平台 sendType 0:角色信息变更 1:登陆 2:创角
		if uploadType == EnumDef.UploadRoleInfoType.RoleInfoChange then
			sendType = 0
		elseif uploadType == EnumDef.UploadRoleInfoType.Login then
			sendType = 1
		end
	end
	-- warn("UploadRoleInfo uploadType:", uploadType, "sendType:", sendType, debug.traceback())
	local hp_info = hp._InfoData
	local guild_name = IsNilOrEmptyString(hp._Guild._GuildName) and DEFAULT_UPLOAD_GUILD_NAME or hp._Guild._GuildName
	PlatformSDK.UploadRoleInfo(sendType,
							   hp._ID,
							   hp_info._Name,
							   hp_info._Level,
							   hp_info._GloryLevel,
							   hp._ServerZoneId,
							   game._NetMan._ServerName,
							   guild_name,
							   hp._RoleCreateTime,
							   hp._RoleLevelMTime)
end

def.method("number", "string", "number", "number", "string", "number").UploadRoleInfoWhenCreate = function(self, roleId, roleName, roleLevel, zoneId, guildName, createTime)
	local sendType = 0
	if self:IsInLongtu() then
		sendType = 2 -- 对于龙图平台 sendType 0:角色信息变更 1:登陆 2:创角
	end
	-- warn("UploadRoleInfoWhenCreate sendType:", sendType, debug.traceback())
	if IsNilOrEmptyString(guildName) then
		guildName = DEFAULT_UPLOAD_GUILD_NAME
	end
	PlatformSDK.UploadRoleInfo(sendType,
							   roleId,
							   roleName,
							   roleLevel,
							   0, 		-- vip等级默认填0
							   zoneId,
							   game._NetMan._ServerName,
							   guildName,
							   createTime,
							   createTime)
end

-- 设置玩家全天推送状态
-- @param callback:回调，带参数 isSuccessful
def.method("boolean", "function").EnablePlayerPush = function(self, enable, callback)
	PlatformSDK.EnablePush(enable, SDKDef.KakaoPushOption.Player, callback)
end

-- 设置玩家夜间推送状态
-- @param callback:回调，带参数 isSuccessful
def.method("boolean", "function").EnableNightPush = function(self, enable, callback)
	PlatformSDK.EnablePush(enable, SDKDef.KakaoPushOption.Night, callback)
end

-- 获取玩家全天推送状态
def.method("=>", "boolean").GetPlayerPushStatus = function(self)
	return PlatformSDK.GetPushStatus(SDKDef.KakaoPushOption.Player)
end

-- 获取玩家夜间推送状态
def.method("=>", "boolean").GetNightPushStatus = function(self)
	return PlatformSDK.GetPushStatus(SDKDef.KakaoPushOption.Night)
end

-- 推广
-- @param callback:回调，带参数 DeepLinkURL
def.method("function").ShowPromotion = function(self, callback)
	if not self:IsLogined() then return end -- 没有登录不允许调
	PlatformSDK.ShowPromotion(callback)
end

-- 公告
-- @param callback:回调，带参数 DeepLinkURL
def.method("dynamic").ShowAnnouncement = function(self, callback)
	PlatformSDK.ShowAnnouncement(callback)
end

-- 客服中心
-- @param callback:回调，带参数 DeepLinkURL
def.method("function").ShowCustomerCenter = function(self, callback)
	PlatformSDK.ShowCustomerCenter(callback)
end

-- 平台SDK WebView
-- @param url:打开的Web链接
-- @param callback:回调，带参数 DeepLinkURL
-- def.method("string", "function").ShowInAppWeb = function(self, url, callback)
-- 	PlatformSDK.ShowInAppWeb(url, callback)
-- end
def.method("string").ShowInAppWeb = function(self, url)
	PlatformSDK.ShowInAppWeb(url)
end

-- 优惠券
def.method().ShowCoupon = function(self)
	PlatformSDK.ShowCoupon(function(isSuccessful)
		if isSuccessful then
			-- 使用优惠券成功后通知服务器
			local C2SItemCouponReq = require "PB.net".C2SItemCouponReq
			local protocol = C2SItemCouponReq()
			SendProtocol(protocol)
		end
	end)
end

def.method("string", "number", "boolean").UpdateGoogleAchieveData = function(self, id, curValue, isFinish)
	if IsNilOrEmptyString(id) then return end

	self._GoogleAchievementList[id] = 
	{
		IsFinish = isFinish,
		CurValue = curValue
	}
end

-- 是否已登录 Google Game
def.method("=>", "boolean").IsGoogleGameLogined = function(self)
	return PlatformSDK.IsGoogleGameLogined()
end

-- 登录 Google Game
def.method().GoogleGameLogin = function(self)
	PlatformSDK.GoogleGameLogin(function(isSuccessful)
		if isSuccessful then
			self:CheckGoogleAchievementState()

			local event = PlatformSDKEvent()
			event._Type = EnumDef.PlatformSDKEventType.GoogleGame
			CGame.EventManager:raiseEvent(nil, event)
		end
	end)
end

-- 登出 Google Game
def.method().GoogleGameLogout = function(self)
	PlatformSDK.GoogleGameLogout(function(isSuccessful)
		if isSuccessful then
			local event = PlatformSDKEvent()
			event._Type = EnumDef.PlatformSDKEventType.GoogleGame
			CGame.EventManager:raiseEvent(nil, event)
		end
	end)
end

-- 更新谷歌成就状态
def.method().CheckGoogleAchievementState = function(self)
	if not self:IsGoogleGameLogined() then return end

	for id, data in pairs(self._GoogleAchievementList) do
		self:SetGoogleAchievementCompletionLevel(id, data.CurValue)
		if data.IsFinish then
			self:CompleteGoogleAchievement(id)
		end
	end
	if self._Is2ShowGoogleAchievement then
		PlatformSDK.ShowGoogleAchievementView()
		self._Is2ShowGoogleAchievement = false
	end
end

-- 尝试显示Google成就面板
def.method().TryShowGoogleAchievementView = function(self)
	if not self:IsGoogleGameLogined() then return end
	
	if not game._AcheivementMan._HasGotAchieveDatas then
		-- 先请求数据
		game._AcheivementMan:SendC2SAchieveSync()
		self._Is2ShowGoogleAchievement = true
	else
		PlatformSDK.ShowGoogleAchievementView()
	end
end

-- 完成一个Google成就
def.method("string").CompleteGoogleAchievement = function(self, id)
	if IsNilOrEmptyString(id) then return end
	PlatformSDK.CompleteGoogleAchievement(id)
end

-- 设置Google成就完成进度
def.method("string", "number").SetGoogleAchievementCompletionLevel = function(self, id, level)
	if IsNilOrEmptyString(id) or level <= 0 then return end
	PlatformSDK.SetGoogleAchievementCompletionLevel(id, level)
end

-- 设置打点
def.method("dynamic").SetBreakPoint = function(self, pointType)
	PlatformSDK.SetBreakPoint(pointType)
end

-- 平台是否有退出游戏（弹窗）
def.method("=>", "boolean").IsPlatformExitGame = function(self)
	return PlatformSDK.IsPlatformExitGame()
end

-- 平台退出游戏（弹窗）
def.method().ExitGame = function(self)
	PlatformSDK.ExitGame()
end

---------------------------- 支付相关 start -------------------------
def.method("number").InitIap = function(self, roldId)
	warn("Lua::InitIap")
	PlatformSDK.InitializeIAP(roldId)
end

-- 开启支付
def.method("number", "string", "string").DoPurchase = function(self, purchaseType, orderId, productId)
	warn("Lua::DoPurchase : ", purchaseType, orderId, productId)
	PlatformSDK.DoPurchase(purchaseType, orderId, productId)
end

-- 缓存中Receipt 再验证
def.method().ProcessPurchaseCache = function(self)
	PlatformSDK.ProcessPurchaseCache()
end

def.method("number").GetOrderInfoByType = function (self, purchaseType)
	warn("GetOrderInfoByType...")
	if purchaseType == EPurchaseType.EPlatformType_AppStore then
		warn("Apple Store Info")
	elseif purchaseType == EPurchaseType.EPlatformType_GooglePlay then
		warn("Google Play Info")
	elseif purchaseType == EPurchaseType.EPlatformType_TStore then
		warn("T-Store Info")
	else
		warn("Not supported purchaseType Platform = ", purchaseType)
	end
end

-- 发送验单协议
def.method("boolean", "string", "string", "string").SendC2SPurchaseInfo = function(self, bSuccess, orderId, transactionId, receipt)
	local OrderId = orderId
	local TransactionId = transactionId  
	local IsPaySuccess = bSuccess
	local Receipt= receipt

	local C2SPurchaseVerifyReq = require "PB.net".C2SPurchaseVerifyReq
	local protocol = C2SPurchaseVerifyReq()

	protocol.OrderId = OrderId
	protocol.TransactionId = TransactionId
	protocol.IsPaySuccess = IsPaySuccess
	protocol.Receipt= Receipt

	SendProtocol(protocol)
end
---------------------------- 支付相关 end -------------------------


def.method("string").DoFillBilling = function(self, str)
	PlatformSDK.DoFillBillTest(str)
end
def.method().GetFillBilling = function(self)
	PlatformSDK.DoFillBillTest()
end

CPlatformSDKMan.Commit()
return CPlatformSDKMan