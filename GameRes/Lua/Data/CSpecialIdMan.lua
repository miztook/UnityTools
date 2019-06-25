local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local CSpecialIdMan = Lplus.Class("CSpecialIdMan")
local def = CSpecialIdMan.define

local SpecialIdKey =
{
	FightScoreFactorMaxHp = 24,
	FightScoreFactorBattleHpRecovery = 25,
	HpHitRecovery = 27,
	FightScoreFactorAttack = 28,
	FightScoreFactorDefense = 29,
    FightScoreFactorFireAttack = 30,	
	FightScoreFactorLightningAttack = 31, 
	FightScoreFactorIceAttack = 32,	 
	FightScoreFactorWindAttack = 33,	  
	FightScoreFactorLightAttack = 34,
	FightScoreFactorDarkAttack = 35,
	FightScoreFactorFireDefense = 36,
	FightScoreFactorLightningDefense = 37,
	FightScoreFactorIceDefense = 38,
	FightScoreFactorWindDefense = 39,	
	FightScoreFactorLightDefense = 40,
	FightScoreFactorDarkDefense = 41,
	FightScoreFactorCriticalLevel = 42,
	FightScoreFactorImmunLevel = 43,
	FightScoreFactorCriticalDamageLevel = 44,

	ResurrentCharge = 56,
	ResurrentSkillId = 57,
	LootPickupRadius = 61,
	GatherSkillId    = 62,
	GuildCreateDiamondCost = 67,
	GuildRenameDiamondCost = 71,
	GuildMaxDonateNum = 73,
	GuildMapID = 74,--公会地图ID
	GuildApplyFortressItem = 75,
	GuildPrayMaxHelp = 400,
	GuildConvoyReward = 436,
	ImmunePhysicalControlState = 92,
	FlawState = 93,
	NpcQuickServiceDis = 81,
	MineQuickGatherDis = 82,
	WorldMapTranform = 103,				--世界地图传送技能
	DungeonFightScoreCompareRange = 122,		-- 副本战力对比区间

	PetExpMedicine = 367,				--宠物经验药
	PetExpMedicineUseInterval = 366,	--宠物经验药，长按间隔时间
	PetAdvanceCoefficient = 359,		--宠物进阶系数
	PetMaxStage = 352,					--宠物最大品阶数
	PetRecastNeedInfo = 351,			--重铸材料信息， 1. id 2. count
	PetAdvanceLvLimitInfo = 398,		--宠物进阶等级限制
	PetUnlockHelpCellInfo = 357,		--宠物助战栏开启规则
	PetUnlockCellPrice = 365,			--宠物背包格子开启价格 1. id 2. count

	SkillLevelUpFontFrontColor = 131,
	SkillLevelUpFontBackColor = 132,
	RuneConfigTwoUnlimitLevel = 133,
	RuneConfigThreeUnlimitLevel = 134,

	MaxClosely = 151,
	MaxFriend = 152,
	MaxEnemies = 153,
	MaxBlackList = 154,
	MaxApplyList = 155,
	MaxServerMsg = 156,
	MaxClientMsg = 157,
	MaxChars = 161,
	ApplyInterval = 162,
	MaxGroupNum = 165,
	FriendDefaultGroupId = 163,
	MaxEvilValue = 171,

	WingLevelUpItem = 191,
	WingLevelUpAssit = 192,
	-- WingGradeUpItem = 193,
	WingClearProf = 194,

	ArenaSceneOne = 202,
	ArenaScene3V3 = 227,
	Arena3V3ConfigTime = 209,
	Arena3V3MateTime = 229,

	InteractiveCDTime = 292,		--玩家交互公共CD
	TowerDungeonID = 293,			--爬塔试炼副本ID	
	MaxTowerDungeonFloor = 294,		--爬塔试炼层数
	SystemFunctionBtnIndex = 308, 	--主界面 左侧弹出按钮
	ActivityEntrance1 = 309,		--主界面 右侧弹出按钮 第1行
	ActivityEntrance2 = 310,		--主界面 右侧弹出按钮 第2行
	ActivityEntrance3 = 311,		--主界面 右侧弹出按钮 第3行
	DurgItemId = 314,				--主界面 右侧弹出按钮 第3行
	DeleteRoleImmediatelyLevelLimit = 322,		-- 立刻删除角色等级限制
	StorageMoneyType = 325,          -- 仓库解锁消耗资源类型
	BountyTax = 327,				--赏金税点
	MutipleProgressCountRule = 348,	--Boss血条 条目规则
	PetHelpAddPropertyRatio = 354,	--宠物助战 增加 战斗百分比
	PetFightAddPropertyRatio = 355, --宠物出战 增加 战斗百分比

	PetPackageMaxSize = 363,		--宠物背包最大个数
	PetUnlockInfo = 365,			--宠物背包开启条件  1.消耗类型 2.消耗数量
	PetSkillTakeOffCostInfo = 372,	--宠物技能书拆除 1.消耗类型，后面的是每级的消耗数量
	EliminateScene = 586,
	EliminateMateTime = 588,
	EliminateMatchingTime = 587,

	EngravingGrindStoneTid = 413,	--刻印重置砂轮

	PlayerSrongScoreC = 426, --我要变强评分C
	PlayerSrongScoreB = 427, --我要变强评分B
	PlayerSrongScoreA = 428, --我要变强评分A
	PlayerSrongScoreS = 429, --我要变强评分S

	IDLE_STATE_TIME = 469,   --休闲状态进入时间
	IDLE_ANIMATION_TIME = 470,--休闲时间间隔

	BlurSpeed = 488,

	GuildBattleRedTower = 496,			-- 公会战场红色防御塔
	GuildBattleBlueTower = 497,			-- 公会战场蓝色防御塔
	GuildBattleRedBase = 498,			-- 公会战场红色基地
	GuildBattleBlueBase = 499,			-- 公会战场蓝色基地
	GuildBattleBlueAltar = 500,			-- 公会战场蓝色普通祭坛
	GuildBattleRedAltar = 502,			-- 公会战场红色普通祭坛
	GuildBattleBlueHighAltar = 503,		-- 公会战场蓝色超级祭坛
	GuildBattleRedHighAltar = 504,		-- 公会战场红色超级祭坛
	GuildBattleOblation = 505,			-- 公会战场普通祭品
	GuildBattleHighOblation = 506,		-- 公会战场高级祭品
	PetFuseAptitudeAddRatio = 627,		-- 宠物资质 融合加成百分比
    GuildBattleNeedScore = 631,         -- 公会战场需要的活跃度

	PetResetRecastCountItem = 527,		-- 宠物重置道具
	PetAptitudeIncFixCoefficient = 542,	-- 宠物资质加成系数

	DailyLuckRefreshUpperLimit = 544,	-- 每日运势刷新次数上限
	DailyLuckRefreshCost = 545,			-- 每日运势刷新消耗
	DailyQuestRefreshCost = 546,		-- 每日任务刷新消耗

	GuideAssistDungeonId = 568, 		-- 新手引导助战副本ID
	GuideAssistQuestId = 569, 			-- 新手引导助战任务ID

	ActivityQuestCountGroupId = 435, 	-- 公会任务次数组ID
	RewardQuestCountGroupId = 543,		-- 赏金任务次数组ID
	RewardQuestNPCId = 577,				-- 赏金任务NPC ID 地图用
	ActivityQuestNPCId = 578,			-- 公会任务NPC ID 地图用

	HorseStandToIdleLoopInterval = 579, -- 坐骑从站立到休闲的循环次数区间
	BeginnerDungeonId = 612, 			-- 新手副本ID
	MaxInforceLevelInfo = 618,			-- 装备强化最高等级（由品质确定）
	ServerQueueSecondsPerPerson = 621,	-- 服务器排队单人的预计时间（秒）
	PetSkillUnlockInfo = 624,			-- 宠物解锁配置
	MaxPetTalentLevel = 625,			-- 宠物天赋技能最大等级
	EyeRegionSingle  = 657,             -- 神之世界单人玩法说明
	EyeRegionMultiPlayer = 658,         -- 神之世界多人玩法说明
	EyeRegionSingleFuncId = 659,        -- 神之世界单人玩法活动id
	EyeRegionMultiPlayerFuncId = 660,   -- 神之世界多人玩法活动id
	BackpackCouponId = 661,				-- 背包扩展券id
	ConsumableTypesId = 666 ,           -- 消耗物品包含的类型
	InforceStoreFromInfo = 668,			-- 强化石来源表
	PetFromInfo	= 669,					-- 宠物蛋来源表
	PetExpRecycleRatio = 677,			-- 宠物经验药返还比例
	PetSkillBookFromInfo = 678,			-- 宠物技能书来源表
}

-- 均是整数
def.static("dynamic", "=>", "dynamic").Get = function(key)
	local specialId = 0
	if type(key) == 'number' then
		specialId = key
	else
		specialId = SpecialIdKey[key]
	end
	local template = CElementData.GetSpecialIdTemplate( specialId )
	if template == nil then
		warn("can not find SpecialId Data Template id = " .. specialId)
		return 0
	end
	local v = template.Value
	if tonumber(v) ~= nil then
		v = tonumber(v)
	end
	return v
end

-- 获取默认值
def.static("dynamic", "=>", "dynamic").GetDefault = function(key)
	local specialId = 0
	if type(key) == 'number' then
		specialId = key
	else
		specialId = SpecialIdKey[key]
	end
	local template = CElementData.GetSpecialIdTemplate( specialId )
	if template == nil then
		warn("can not find SpecialId Data Template id = " .. specialId)
		return 0
	end

	local v = template.Value
	return v
end

CSpecialIdMan.Commit()

return CSpecialIdMan