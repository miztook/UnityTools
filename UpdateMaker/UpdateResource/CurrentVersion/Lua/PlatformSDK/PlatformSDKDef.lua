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

-- 打点节点（与C#对应）
local POINT_STATE =
{
	Game_Start = 0,						-- 启动游戏
	Game_Check_Update = 1,				-- 检查更新
	Game_Check_Update_Fail = 2,			-- 检查更新失败
	Game_Popup_Download_CDN = 3,		-- 弹出下载更新弹窗
	Game_Start_Download_CDN = 4,		-- 开始下载更新
	Game_End_Download_CDN = 5,			-- 结束下载更新
	Game_Start_Update = 6,				-- 开始更新
	Game_End_Update = 7,				-- 结束更新
	Game_Account_Login = 8,				-- 平台账号登录
	Game_Account_Login_Succeed = 9,		-- 平台账号登录成功
	Game_Get_Announcement = 10,			-- 获取公告
	Game_Get_Server_List = 11,			-- 获取服务器列表
	Game_Select_Server = 12,			-- 选择服务器
	Game_User_Login = 13,				-- 服务器登录
	Game_User_Login_Succeed = 14,		-- 服务器登录成功
	Game_User_Login_Fail = 15,			-- 服务器登录失败
	Game_Start_Create_Role = 16,		-- 进入角色创建
	Game_Create_Role = 17,				-- 角色创建
	Game_Create_Role_Fail = 18,			-- 角色创建失败
	Game_Role_Login = 19,				-- 角色登录
	Game_Role_Login_Fail = 20, 			-- 角色登录失败
}

-- 游戏流程的打点类型
local PIPELINE_POINT_TYPE =
{
	QuestEnter = 1,
	QuestEnd = 2,
	PlayCG = 3,
	BossEnter = 4,
	DungeonGoal = 5,
	DungeonEnter = 6,
	DungeonEnd = 7,
	GuideEnter = 8,
	GuideEnd = 9,
	GuideTriggerEnter = 10,
	GuideTriggerEnd = 11,
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
	PipelinePointType = PIPELINE_POINT_TYPE,
	KakaoIDP = KAKAO_IDP,
	KakaoPushOption = KAKAO_PUSH_OPTION,
}