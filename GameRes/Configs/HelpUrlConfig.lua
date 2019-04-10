local HelpUrlConfig = {}

HelpUrlConfig.HelpPageUrlType = 
{
	NONE 						= 0,
	Property                    = 1,
	CalendarMan_Relic_Nor       = 2,
	CalendarMan_Relic_Hard      = 3,
	CalendarMan_Dragon          = 4,
	CalendarMan_Windstorm       = 5,
	CalendarMan_Tyburn          = 6,
	WorldBoss            		= 7,
	Guild_Main					= 8,
	Guild_Shop 					= 10,
	Guild_Skill					= 11,
	Guild_Dungeon				= 12,
	Guild_Smithy				= 13,
	Auction						= 14,
	Achievement					= 16,
	Bag 						= 17,
	Pet  						= 19,
	Charm						= 20,
	Fortify						= 22,
	Guild_Convoy 				= 26,
	Guild_Defend 				= 27,
	Guild_Battle 				= 28,
	Open3V3						= 29,
	Open1V1 					= 30,
	OpenBattle 					= 31,
	Activity					= 32,
	Storage						= 34,
	Team		 				= 35,
	Strong 						= 36,
	Pray 						= 37,
	QuestList 					= 38,
	Expedition					= 39,
}
local HelpPageUrlType = HelpUrlConfig.HelpPageUrlType
HelpUrlConfig.HelpPageUrl =
{
	[HelpPageUrlType.NONE] 							= "",

	[HelpPageUrlType.CalendarMan_Relic_Nor]       	= "https://www.baidu.com",                	-- 遗迹普通
	[HelpPageUrlType.CalendarMan_Relic_Hard]      	= "https://www.baidu.com",               	-- 遗迹噩梦 
	[HelpPageUrlType.CalendarMan_Dragon]          	= "https://www.baidu.com",                  -- 巨龙巢穴
	[HelpPageUrlType.CalendarMan_Windstorm]       	= "https://www.baidu.com",                	-- 风暴试炼
	[HelpPageUrlType.CalendarMan_Tyburn]          	= "https://www.baidu.com",                  -- 奇利恩刑场
	[HelpPageUrlType.WorldBoss]						= "https://www.baidu.com",					-- 狩猎
	[HelpPageUrlType.Guild_Main]					= "https://www.baidu.com",					-- 工会
	[HelpPageUrlType.Guild_Shop]					= "https://www.baidu.com",					-- 温德商会
	[HelpPageUrlType.Guild_Skill]					= "https://www.baidu.com",					-- 魔法核心
	[HelpPageUrlType.Guild_Dungeon]					= "https://www.baidu.com",					-- 异界之门
	[HelpPageUrlType.Guild_Smithy]					= "https://www.baidu.com",					-- 锻造工坊
	[HelpPageUrlType.Guild_Convoy]					= "https://www.baidu.com",					-- 军资押送	
	[HelpPageUrlType.Guild_Defend]					= "https://www.baidu.com", 					-- 次元魔潮
	[HelpPageUrlType.Guild_Battle]					= "https://www.baidu.com",					-- 奇德天空竞技场
	[HelpPageUrlType.Auction]						= "https://www.baidu.com",					-- 拍卖行
	[HelpPageUrlType.Achievement]					= "https://www.baidu.com",					-- 成就
	[HelpPageUrlType.Bag]							= "https://www.baidu.com",					-- 背包
	[HelpPageUrlType.Property]                  	= "https://www.baidu.com",                  -- 信息
	[HelpPageUrlType.Storage]						= "https://www.baidu.com",					-- 仓库
	[HelpPageUrlType.Pet]							= "https://www.baidu.com",					-- 宠物技能
	[HelpPageUrlType.Charm]							= "https://www.baidu.com",					-- 神符
	[HelpPageUrlType.Fortify] 						= "https://www.baidu.com",  				-- 装备
	[HelpPageUrlType.Open3V3]						= "https://www.baidu.com",					-- 荣耀竞技场
	[HelpPageUrlType.Open1V1]						= "https://www.baidu.com", 					-- 冠军竞技场
	[HelpPageUrlType.OpenBattle]					= "https://www.baidu.com", 					-- 无畏竞技场
	[HelpPageUrlType.Activity]						= "https://www.baidu.com",					-- 冒险日历
	[HelpPageUrlType.Team]							= "https://www.baidu.com",					-- 组队
	[HelpPageUrlType.Strong]						= "https://www.baidu.com",					-- 养成
	[HelpPageUrlType.Pray] 							= "https://www.baidu.com",					-- 月光庭院
	[HelpPageUrlType.QuestList]						= "https://www.baidu.com",					-- 任务列表
	[HelpPageUrlType.Expedition]					= "https://www.baidu.com",					-- 远征
}



return HelpUrlConfig