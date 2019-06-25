local Lplus = require "Lplus"

_G.GlobalDefinition = {}

	GlobalDefinition.Version = "0.9.22"
	GlobalDefinition.MinAccountLength			= 4
	GlobalDefinition.MaxAccountLength			= 20
	
	GlobalDefinition.HmacMd5Length			= 16 
	GlobalDefinition.MaxDeviceUniqueIdLength	= 16 
	GlobalDefinition.ChallengeNonceSize		= 16 
	GlobalDefinition.KeyExchangeNonceSize		= 16 
	
	GlobalDefinition.MinRoleNameLength		= 2
	GlobalDefinition.MaxRoleNameLength		= 7
	GlobalDefinition.MaxRoleCount				= 4

	GlobalDefinition.ProfessionCount			= 5
	GlobalDefinition.FactionCount				= 7

	GlobalDefinition.MinRoleLevel				= 1
	GlobalDefinition.MaxRoleLevel				= 60
	GlobalDefinition.InitRoleLevel			= 1
	GlobalDefinition.MinRoleParagonLevelLevel	= 1
	GlobalDefinition.MaxRoleParagonLevelLevel	= 999
	
	GlobalDefinition.MinQuestNameLength		= 1
	GlobalDefinition.MaxQuestNameLength		= 18
	GlobalDefinition.MinQuestObjNameLength	= 1
	GlobalDefinition.MaxQuestObjNameLength	= 22
	GlobalDefinition.MinRoleTitleLength		= 1 
	GlobalDefinition.MaxRoleTitleLength		= 16 
	GlobalDefinition.MinItemNameLength		= 1 
	GlobalDefinition.MaxItemNameLength		= 14 
	
	GlobalDefinition.MinGuildNameLength		= 1
	GlobalDefinition.MaxGuildNameLength		= 6
	GlobalDefinition.MinGuildTitleLength		= 0 
	GlobalDefinition.MaxGuildTitleLength		= 16 
	GlobalDefinition.MinGuildAnnounceLength	= 0 
	GlobalDefinition.MaxGuildAnnounceLength	= 100 
	GlobalDefinition.MinGuildHonourNum		= 1 
	GlobalDefinition.MaxGuildHonourNum		= 999999
	GlobalDefinition.MinFightScoreNum			= 1
	GlobalDefinition.MaxFightScoreNum			= 999999
	GlobalDefinition.MinTeamNameLength 		= 1
	GlobalDefinition.MaxTeamNameLength 		= 12
	GlobalDefinition.MinPetNameLength 		= 1
	GlobalDefinition.MaxPetNameLength 		= 4
	

	GlobalDefinition.MaxMonsterLevel			= 60
	GlobalDefinition.MaxItemLevel				= 60
	GlobalDefinition.ElementCount				= 4
	GlobalDefinition.MaxPileLimit				= 999
	GlobalDefinition.MaxPackbackItemNum		= 100 --背包中物品的最大数
	GlobalDefinition.MaxRoleEquipNum      	= 8 	--角色身上最大的装备数量
	GlobalDefinition.MaxEquipAttrsNum         = 10
	GlobalDefinition.DefaultPackbackNum       = 40 --背包中默认开启的格子数量

	GlobalDefinition.MaxQuestLimit			= 20

	GlobalDefinition.TeamMaxMember			= 5

	GlobalDefinition.ServiceSellItemInfinitItemShowNum = 999 -- 无限库存时客户端显示的数量，服务器设置的数量


	--参与怪物相关模板唯一Id运算
	GlobalDefinition.MonsterLevelPropertyIdStep   = 10000
	
	
	--初始任务ID
	GlobalDefinition.DefaultQuestID				= 2
	
	--最大聊天字数
	GlobalDefinition.MaxChatContentLen			= 100

	--随机权重总值
	GlobalDefinition.DefaultTotleWeight			= 10000

	--int类型无效值
	GlobalDefinition.DefaultIntInvalid			= -1
	
	--商店
	GlobalDefinition.MaxShopBuyNum				= 99
		
	GlobalDefinition.AuthSalt				= "MeteoriteStudio"