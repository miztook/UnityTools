local data = {}
data.Channel = {}
data.Cfg = {}

data.Cfg = 
{
    SmallPanelStayTime = 15, --缩略面板消息停留时间
    MaxMsgListCount = 100, --聊天界面最大显示的消息条数
    MaxRecentMsgNum = 5, --找回发言最大存储的消息数
    MsgSendCoolTime = 1, --不重复发言的限制时间
    SameMsgSendCoolTime = 10,--重复发言（内容完全相同）的限制时间  10s
}

data.Channel[0] = 
{
	channel = 0,    --当前频道
	channelname = "[현재]",
	mainbtnname = "현재",
	channelcolor = "FFFFFF",
	rolenamecolor = "00FF00", 	-- 角色名称颜色：暂时没用，用的prefab上默认颜色。
	textcolor = "FFFFFF",		-- 文本颜色：暂时没用，用的prefab上默认颜色。
    cooltime = 0,
}

data.Channel[1] = 
{
	channel = 1,    --世界频道
	channelname = "[월드]",
	mainbtnname = "월드",
	channelcolor = "14C8C2",
	rolenamecolor = "FFD700", 
	textcolor = "14C8C2",
    cooltime = 10,
}

data.Channel[2] = 
{
	channel = 2,    --队伍频道
	channelname = "[파티]",
	mainbtnname = "파티",
	channelcolor = "41C721",
	rolenamecolor = "66CDAA", 
	textcolor = "41C721",
    cooltime = 10,
}

data.Channel[3] = 
{
	channel = 3,    --公会频道
	channelname = "[길드]",
	mainbtnname = "길드",
	channelcolor = "98C2EC",
	rolenamecolor = "7EC0EE", 
	textcolor = "98C2EC",
    cooltime = 10,
}

data.Channel[4] = 
{
	channel = 4,     --系统频道
	channelname = "[시스템]",
	mainbtnname = "시스템",
	channelcolor = "FFCD00",
	rolenamecolor = "EEB422", 
	textcolor = "FFCD00",
    cooltime = 0,
}

data.Channel[5] = 
{
	channel = 5,     --战斗频道
	channelname = "[전투]",
	mainbtnname = "전투",
	channelcolor = "F64F9E",
	rolenamecolor = "66CDAA", 
	textcolor = "F64F9E",
    cooltime = 0,
}

data.Channel[6] = 
{
	channel = 6,     --私聊频道
	channelname = "[귓속말]",
	mainbtnname = "귓속말",
	channelcolor = "A876F0",
	rolenamecolor = "66CDAA", 
	textcolor = "A876F0",
    cooltime = 0,
}

return data
