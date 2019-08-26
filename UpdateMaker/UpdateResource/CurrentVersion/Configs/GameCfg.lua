local config = 
{
	ViewAngle = 30,

	DebugOption = 
		{ 
			HideCmd = false, 
			HideLog = false, 
			HideFpsPing = false, 
		},

	FuncOpenOption = 
		{
			HideMall = false,       -- 是否隐藏商城的Page（礼包商城，成长福利，蓝钻兑换）
			HideGuildBattle = false,     -- 是否隐藏公会战场这个功能。
			HideUrlHelp 	= false,     -- 是否隐藏UI帮助提示功能。
			HideHottime 	= false,     -- 是否隐藏Hottime功能。
			HideAppMsgBox 	= false,     -- 是否隐藏问卷弹窗功能。
			HideLancer = false,          -- 是否隐藏枪骑士职业创建。
		},
}

return config