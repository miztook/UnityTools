-- PlatformSDKDef
-- 平台SDK枚举，与C#一致

-- 渠道平台类型
local PLATFORM_TYPE =
{
	Any = 0,					-- debug

	KakaoIOS = 1,				-- kakao, ios
	KakaoAndroid = 2,			-- kakao, android

	-- TencentIOS = 11,			-- 腾讯, ios
	-- TencentAndroid = 12,		-- 腾讯, android

	LongtuIOS = 21,				-- 龙图, ios
	LongtuAndroid = 22,			-- 龙图, android
}

-- 初始化状态
local INIT_STATE =
{
	Succeed = 0,
	Failed = 1,
}

-- 登录状态
local LOGIN_STATE =
{
	Succeed = 0,
	UserCancel = 1,
	AppKeyInvalid = 2,
	AppIdInvalid = 3,
	HasAssociate = 4,
	TimeOut = 5,
	UnknownError = 99,
}

-- 登出状态
local LOGOUT_STATE =
{
	Succeed = 0,
	Failed = 1,
}

-- 支付状态
local BUY_STATE =
{
	Succeed = 0,
	UserCancel = 1,
	NetworkFailed = 2,
	PayFailed = 3,
	UnknownError = 99,
}

-- 打点节点
local POINT_STATE =
{
	Game_Start = 0,						-- 启动游戏
	Game_Check_Update = 1,				-- 检查更新
	Game_Check_Update_Fail = 2,			-- 检查更新失败
	Game_Start_Update = 3,				-- 开始更新
	Game_End_Update = 4,				-- 结束更新
	Game_Get_Announcement = 5,			-- 获取公告
	Game_Get_Server_List = 6,			-- 获取服务器列表
	Game_Select_Server = 7,				-- 选择服务器
	Game_User_Login = 8,				-- 账号登录
	Game_User_Login_Fail = 9,			-- 账号登录失败
	Game_Create_Role = 10,				-- 角色创建
	Game_Create_Role_Fail = 11,			-- 角色创建失败
	Game_Role_Login = 12,				-- 角色登录
	Game_Role_Login_Fail = 13, 			-- 角色登录失败
}

-- Kakao登录渠道
local KAKAO_IDP =
{
	Guest = 0,
	Kakao = 1,
	-- Facebook = 2,
	-- Google = 3,
	-- AppleGameCenter = 4,
}

-- Kakao推送选项
local KAKAO_PUSH_OPTION =
{
	Player = 0,
	Night = 1
}

return
{
	PlatformType = PLATFORM_TYPE,
	InitState = INIT_STATE,
	LoginState = LOGIN_STATE,
	LogoutState = LOGOUT_STATE,
	BuyState = BUY_STATE,
	PointState = POINT_STATE,
	KakaoIDP = KAKAO_IDP,
	KakaoPushOption = KAKAO_PUSH_OPTION,
}