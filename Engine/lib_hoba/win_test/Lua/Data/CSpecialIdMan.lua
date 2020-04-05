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
	ImmunePhysicalControlState = 92,
	FlawState = 93,
	NpcQuickServiceDis = 81,
	MineQuickGatherDis = 82,
	WorldMapTranform = 103,				--世界地图传送技能

	GuildApplyFortressItemId = 75,
	PetExpMedicine = 145,				--宠物经验药
	PetExpMedicineUseInterval = 146,	--宠物经验药，长按间隔时间

	MaxClosely = 151,
	MaxFriend = 152,
	MaxEnemies = 153,
	MaxBlackList = 154,
	MaxApplyList = 155,
	MaxServerMsg = 156,
	MaxClientMsg = 157,
	MaxChars = 161,
	ApplyInterval = 162,

	WingLevelUpItem = 191,
	WingLevelUpAssit = 192,
	WingGradeUpItem = 193,
	WingClearProf = 194,

	ArenaSceneOne = 202,
	ArenaScene3V3 = 227,
	Arena3V3ConfigTime = 209,
	Arena3V3MateTime = 229,

	InteractiveCDTime = 292,	--玩家交互公共CD
	TowerDungeonID = 293,		--爬塔试炼副本ID	
	MaxTowerDungeonFloor = 294,	--爬塔试炼层数
}

local SpecialIdValue = {}

def.static("string", "=>", "dynamic").Get = function(key)
	if SpecialIdValue[key] ~= nil then
		return SpecialIdValue[key]
	end

	if SpecialIdKey[key] == nil then
		warn("can not find " .. key .. " in SpecialId Data")
		return 0
	end

	local template = CElementData.GetSpecialIdTemplate(SpecialIdKey[key])
	if template == nil then
		warn("can not find SpecialId Data Template id = " .. SpecialIdKey[key])
		return 0
	end

	local v = template.Value
	if tonumber(v) ~= nil then
		v = tonumber(v)
	end
	SpecialIdValue[key] = v
	return v
end

CSpecialIdMan.Commit()

return CSpecialIdMan