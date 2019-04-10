local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

-- 测试lua内存消耗
local LuaMemory = Lplus.Class("LuaMemory")
do

	local Template = 
	{
		"Achievement",
		"ActivityContent",
		"ActivityContentPage",
		"Actor",
		"Asset",
		"AttachedProperty",
		"AttachedPropertyGenerator",
		"AttachedPropertyGroupGenerator",
		"CharmField",
		"CharmItem",
		"ColorConfig",
		"Cooldown",
		"CyclicQuest",
		"CyclicQuestReward",
		"Designation",
		"Dialogue",
		"Dress",
		"DressScore",
		"DropLibrary",
		"DropLimit",
		"DropRule",
		"DungeonGroupConfig",
		"DyeAndEmbroidery",
		"Email",
		"EquipConsumeConfig",
		"EquipInforce",
		"EquipSuit",
		"ExecutionUnit",
		"Faction",
		"FactionRelationship",
		"FightProperty",
		"FightPropertyConfig",
		"Fortress",
		"Fun",
		"Guide",
		"GuildBuildLevel",
		"GuildDonate",
		"GuildLevel",
		"GuildPermission",
		"GuildShop",
		"GuildSmithy",
		"GuildWareHouseLevel",
		"Hearsay",
		"Horse",
		"Instance",
		"Item",
		"ItemMachining",
		"LegendaryGroup",
		"LegendaryPropertyUpgrade",
		"Letter",
		"LevelUpExp",
		"Liveness",
		"ManualAnecdote",
		"ManualEntrie",
		"Map",
		"Market",
		"MarketItem",
		"MetaFightPropertyConfig",
		"Mine",
		"Money",
		"Monster",
		"MonsterAffix",
		"MonsterPosition",
		"MonsterProperty",
		"NavigationData",
		"Npc",
		"NpcShop",
		"Obstacle",
		"Pet",
		"PetLevel",
		"Profession",
		"PublicDrop",
		"PVP3v3",
		"Quest",
		"Rank",
		"Reputation",
		"Reward",
		"Rune",
		"RuneLevelUp",
		"Scene",
		"ScriptCalendar",
		"ScriptConfig",
		"SensitiveWord",
		"Service",
		"Sign",
		"Skill",
		"SkillLearnCondition",
		"SkillLevelUp",
		"SkillLevelUpCondition",
		"SpecialId",
		"State",
		"Suit",
		"SystemNotify",
		"Talent",
		"TalentGroup",
		"TalentLevelUp",
		"Text",
		"TowerDungeon",
		"Trans",
		"User",
		"Wing",
		"WingGradeUp",
		"WingLevelUp",
		"WingLevelWeight",
		"WingTalent",
		"WingTalentLevel",
		"WingTalentPage",
		"WorldBossConfig",
		"GloryLevel",
		"SpecialSign",
	}

	local def = LuaMemory.define	
	def.static("=>", LuaMemory).new = function()
		local obj = LuaMemory()
		return obj
	end

	def.method("string").GetMemoryByName = function(self, name)

	end

	def.static().AllMemory = function()
		local memoryInfo = ""
		local oldTotal = collectgarbage("count")
		for i, v in ipairs(Template) do
			local oldMemory = collectgarbage("count")
			local allTid = GameUtil.GetAllTid(v)
			local allTemplate = {}
			for j, w in ipairs(allTid) do
				allTemplate[#allTemplate + 1] = CElementData.GetTemplate(v, w)
			end
			local newMemory = collectgarbage("count")
			memoryInfo = memoryInfo .. (newMemory - oldMemory) .. "\n"
		end
		local newTotal = collectgarbage("count")
		memoryInfo = memoryInfo .. (newTotal - oldTotal)

		GameUtil.LuaMemory(memoryInfo)
	end

end
LuaMemory.Commit()
return LuaMemory