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
	-- 成长引导
	StrongGuide					= 40,
	-- 生涯
	Manual 						= 42, -- 万物志
	-- 宠物
	PetInfo 					= 43, -- 信息
	PetCultivate 				= 44, -- 培养
	PetFuse 					= 45, -- 融合
	PetAdvance 					= 46, -- 升星
	PetSkill 					= 47, -- 技能
	-- 指南
	Liveness 					= 48, -- 活跃度
	AdvancedGuide 				= 49, -- 业绩指引
	DailyTask 					= 50, -- 每日任务
	-- 技能
	SkillInfo 					= 51, -- 技能
	Rune 						= 52, -- 纹章
	Soul 						= 53, -- 专精
	Mastery 					= 54, -- 天赋
	-- 商店
	NPCShop 					= 55, -- 商店
	-- 商城
	MallRecommond				= 56, -- 推荐
	MallBagShop					= 57, -- 礼包商店
	MallMoneyExchange			= 58, -- 货币兑换
	MallExtract					= 59, -- 召唤
	MallAssetShop				= 60, -- 资源商店
	MallOutLookShop 			= 61, -- 外观商店
	MallFundAndMonth 			= 62, -- 成长福利
	MallPointsShop				= 63, -- 积分商店
	-- 飞翼
	Wing 						= 64,
	-- 设置
	Setting 					= 65,
	Ranking                     = 66, -- 排行榜
	-- 福利
	Welfare 					= 67,
	-- 外观
	Exterior 					= 68,
	-- 自动匹配
	TeamMatchingBoard 			= 69,
	-- 扫荡
	AutoKillMonster 			= 70,
}
local HelpPageUrlType = HelpUrlConfig.HelpPageUrlType
HelpUrlConfig.HelpPageUrl =
{
	[HelpPageUrlType.NONE] 							= "",

	[HelpPageUrlType.CalendarMan_Relic_Nor]       	= "RelicNormal",                -- 遗迹普通
	[HelpPageUrlType.CalendarMan_Relic_Hard]      	= "RelicHard",               	-- 遗迹噩梦 
	[HelpPageUrlType.CalendarMan_Dragon]          	= "RelicDragon",                -- 巨龙巢穴
	[HelpPageUrlType.CalendarMan_Windstorm]       	= "TowerChanllenge",            -- 风暴试炼
	[HelpPageUrlType.CalendarMan_Tyburn]          	= "RelicQilien",                -- 奇利恩刑场
	[HelpPageUrlType.WorldBoss]						= "HuntingBoss",				-- 狩猎
	[HelpPageUrlType.Guild_Main]					= "Guild",						-- 工会
	[HelpPageUrlType.Guild_Shop]					= "GuildShop",					-- 温德商会
	[HelpPageUrlType.Guild_Skill]					= "GuildSkill",					-- 魔法核心
	[HelpPageUrlType.Guild_Dungeon]					= "GuildDungeon",				-- 异界之门
	[HelpPageUrlType.Guild_Smithy]					= "GuildSmithy",				-- 锻造工坊 
	[HelpPageUrlType.Guild_Defend]					= "GuildDefense", 				-- 次元魔潮
	[HelpPageUrlType.Guild_Battle]					= "SkyArena",					-- 奇德天空竞技场
	[HelpPageUrlType.Auction]						= "Auction",					-- 拍卖行
	[HelpPageUrlType.Achievement]					= "Career",						-- 成就
	[HelpPageUrlType.Bag]							= "Information",				-- 背包
	[HelpPageUrlType.Property]                  	= "Information",                -- 信息
	[HelpPageUrlType.Storage]						= "Information",				-- 仓库
	[HelpPageUrlType.Pet]							= "Pet",						-- 宠物
	[HelpPageUrlType.Charm]							= "Charm",						-- 神符
	[HelpPageUrlType.Fortify] 						= "EquipProcess",  				-- 加工
	[HelpPageUrlType.Open3V3]						= "PVP3v3",						-- 荣耀竞技场
	[HelpPageUrlType.Open1V1]						= "PVP1v1", 					-- 冠军竞技场
	[HelpPageUrlType.OpenBattle]					= "FearlessBattle", 			-- 无畏竞技场
	[HelpPageUrlType.Activity]						= "Adventure",					-- 冒险日历
	[HelpPageUrlType.Team]							= "Team",						-- 组队
	--[HelpPageUrlType.Strong]						= "https://www.baidu.com",		-- 养成  --需要删除
	[HelpPageUrlType.Pray] 							= "MoonGarden",					-- 月光庭院
	[HelpPageUrlType.QuestList]						= "Quest",						-- 任务列表    --已删
	[HelpPageUrlType.Expedition]					= "Expedition",					-- 远征
	-- 指南
	[HelpPageUrlType.Liveness] 						= "Handbook",					-- 活跃度
	[HelpPageUrlType.AdvancedGuide]					= "Handbook",					-- 业绩指引
	[HelpPageUrlType.DailyTask]						= "Handbook",					-- 每日任务
	-- 技能
	[HelpPageUrlType.SkillInfo]						= "Skill",						-- 技能
	[HelpPageUrlType.Rune]							= "Skill",						-- 纹章
	[HelpPageUrlType.Soul]							= "Skill",						-- 专精
	[HelpPageUrlType.Mastery]						= "Skill",						-- 天赋
	[HelpPageUrlType.StrongGuide]					= "GrowthGuide",				-- 成长引导
	[HelpPageUrlType.Manual]						= "Career",						-- 万物志
	[HelpPageUrlType.NPCShop]						= "Shop",						-- 商店
	[HelpPageUrlType.Wing]							= "Wing",						-- 飞翼
	-- 宠物
	[HelpPageUrlType.PetInfo]						= "Pet",						-- 信息
	[HelpPageUrlType.PetCultivate]					= "Pet",						-- 培养
	[HelpPageUrlType.PetFuse]						= "Pet",						-- 融合
	[HelpPageUrlType.PetAdvance]					= "Pet",						-- 升星
	[HelpPageUrlType.PetSkill]						= "Pet",						-- 技能
	-- 商城
	[HelpPageUrlType.MallRecommond]					= "Mall",						-- 推荐
	[HelpPageUrlType.MallBagShop]					= "Mall",						-- 礼包商店
	[HelpPageUrlType.MallMoneyExchange]				= "Mall",						-- 货币兑换
	[HelpPageUrlType.MallExtract]					= "Mall",						-- 召唤
	[HelpPageUrlType.MallAssetShop]					= "Mall",						-- 资源商店
	[HelpPageUrlType.MallOutLookShop]				= "Mall",						-- 外观商店
	[HelpPageUrlType.MallFundAndMonth]				= "Mall",						-- 成长福利
	[HelpPageUrlType.MallPointsShop]				= "Mall",						-- 积分商店
	
	[HelpPageUrlType.Setting]						= "Setting",					-- 设置
	[HelpPageUrlType.Ranking]						= "Ranking",					-- 排行
	[HelpPageUrlType.Welfare]						= "Welfare",					-- 福利
	[HelpPageUrlType.Exterior]						= "Appearance",					-- 外观
	[HelpPageUrlType.TeamMatchingBoard]				= "AutoMatching",				-- 自动匹配
	[HelpPageUrlType.AutoKillMonster]				= "HangQuest",					-- 扫荡
	
	-- [HelpPageUrlType.Guild_Convoy]					= "https://www.baidu.com",					-- 军资押送	
}



return HelpUrlConfig