local Lplus = require "Lplus"
local pb_template = require "PB.Template"
local elementdatautility = require "Data.CElementDataUtility"

local error = error
--local tostring = tostring

--[[example
	local itemElement = CElementData.GetTemplate("Item", id)
]]


local CElementData = Lplus.Class("CElementData")
do
	local def = CElementData.define

	local function GetTemplateInternal(tid, name, map)
		if tid == 0 then return nil end
		
		if _G.pb_csharp_template_table[name] ~= nil then
			return _G.GetTemplateInternalCSharp(tid, name, map)
		end

		if map ~= nil and map[tid] ~= nil then
			return map[tid]
		else
			local data = GameUtil.GetTemplateData(name, tid)
			local template_class = pb_template[name]
			local template = template_class()
			if data ~= nil and string.len(data) > 0 then
				template:ParseFromString(data)
				if map ~= nil then
					map[tid] = template
				end
			else
				warn(name .. " template data has error, tid = " .. tid)
				return nil
			end

			return template
		end
	end

	local templateData = {}
	def.static("string", "number", "=>", "table").GetTemplate = function(name, id)
		if templateData[name] == nil then
			templateData[name] = {}
		end
		--warn(debug.traceback())
		return GetTemplateInternal(id, name, templateData[name])
	end

	def.static("string", "=>", "number").GetTemplateHeaderVersion = function(name)
		return GameUtil.GetTemplateDataHeaderVersion(name)
	end

	--全部公会升级模板ID缓存
	--降低C#与Lua之间的数据交互
	local AllGuildLevel = nil
	def.static("=>", "table").GetAllGuildLevel = function()
		if AllGuildLevel == nil then
			AllGuildLevel = GameUtil.GetAllTid("GuildLevel")
		end
		return AllGuildLevel
	end

	local AllGuildBuildLevel = nil
	def.static("=>", "table").GetAllGuildBuildLevel = function()
		if AllGuildBuildLevel == nil then
			AllGuildBuildLevel = GameUtil.GetAllTid("GuildBuildLevel")
		end
		return AllGuildBuildLevel
	end

	local AllGuildPermission = nil
	def.static("=>", "table").GetAllGuildPermission = function()
		if AllGuildPermission == nil then
			AllGuildPermission = GameUtil.GetAllTid("GuildPermission")
		end
		return AllGuildPermission
	end

	local AllGuide = nil
	def.static("=>", "table").GetAllGuide = function()
		if AllGuide == nil then
			AllGuide = GameUtil.GetAllTid("Guide")
		end
		return AllGuide
	end

	local AllFun = nil
	def.static("=>", "table").GetAllFun = function()
		if AllFun == nil then
			AllFun = GameUtil.GetAllTid("Fun")
		end
		return AllFun
	end

	local WingLevelUpData = nil
	def.static("=>", "table").GetAllWingLevelUp = function()
		if WingLevelUpData == nil then
			WingLevelUpData = GameUtil.GetAllTid("WingLevelUp")
		end
		return WingLevelUpData
	end

	local SkillTemplateMap = {}
	def.static("number", "=>", "table").GetSkillTemplate = function(tid)
		return GetTemplateInternal(tid, "Skill", SkillTemplateMap)
	end
	local MarketTemplateMap = {}
	def.static("number", "=>", "table").GetMarketTemplate = function(tid)
		return GetTemplateInternal(tid, "Market", MarketTemplateMap)
	end
	local SkillLevelUpTemplateMap = {}
	def.static("number", "=>", "table").GetSkillLevelUpTemplate = function(tid)
		return GetTemplateInternal(tid, "SkillLevelUp", SkillLevelUpTemplateMap)
	end

	local SkillLearnConditionTemplateMap = {}
	def.static("number", "=>", "table").GetSkillLearnConditionTemplate = function(tid)
		return GetTemplateInternal(tid, "SkillLearnCondition", SkillLearnConditionTemplateMap)
	end

	local SkillLevelUpConditionTemplateMap = {}
	def.static("number", "=>", "table").GetSkillLevelUpConditionTemplate = function(tid)
		return GetTemplateInternal(tid, "SkillLevelUpCondition", SkillLevelUpConditionTemplateMap)
	end

	local RuneTemplateMap = {}
	def.static("number", "=>", "table").GetRuneTemplate = function(tid)
		return GetTemplateInternal(tid, "Rune", RuneTemplateMap)
	end

	local RuneLevelUpTemplateMap = {}
	def.static("number", "=>", "table").GetRuneLevelUpTemplate = function(tid)
		return GetTemplateInternal(tid, "RuneLevelUp", RuneLevelUpTemplateMap)
	end

	local TalentTemplateMap = {}
	def.static("number", "=>", "table").GetTalentTemplate = function(tid)
		return GetTemplateInternal(tid, "Talent", TalentTemplateMap)
	end

	local ActorTemplateMap = {}
	def.static("number", "=>", "table").GetActorTemplate = function(tid)
		return GetTemplateInternal(tid, "Actor", ActorTemplateMap)
	end

	local StateTemplateMap = {}
	def.static("number", "=>", "table").GetStateTemplate = function(tid)
		return GetTemplateInternal(tid, "State", StateTemplateMap)
	end

	local ProfessionTemplateMap = {}
	def.static("number", "=>", "table").GetProfessionTemplate = function (tid)
		return GetTemplateInternal(tid, "Profession", ProfessionTemplateMap)
	end

	local MonsterTemplateMap = {}
	def.static("number", "=>", "table").GetMonsterTemplate = function (tid)
		return GetTemplateInternal(tid, "Monster", MonsterTemplateMap)
	end

	local NpcTemplateMap = {}
	def.static("number", "=>", "table").GetNpcTemplate = function (tid)
		return GetTemplateInternal(tid, "Npc", NpcTemplateMap)
	end

	local MineTemplateMap = {}
	def.static("number", "=>", "table").GetMineTemplate = function(tid)
		return GetTemplateInternal(tid, "Mine", MineTemplateMap)
	end

	local ServiceTemplateMap = {}
	def.static("number", "=>", "table").GetServiceTemplate = function (tid)
		return GetTemplateInternal(tid, "Service", ServiceTemplateMap)
	end

	local ObstacleTemplateMap = {}
	def.static("number", "=>", "table").GetObstacleTemplate = function (tid)
		return GetTemplateInternal(tid, "Obstacle", ObstacleTemplateMap)
	end

	local SceneTemplateMap = {}
	def.static("number", "=>", "table").GetSceneTemplate = function(tid)
		return GetTemplateInternal(tid, "Scene", SceneTemplateMap)
	end

	local MapTemplateMap = {}
	def.static("number", "=>", "table").GetMapTemplate = function(tid)
		return GetTemplateInternal(tid, "Map", MapTemplateMap)
	end

	local InstanceTemplateMap = {}
	def.static("number", "=>", "table").GetInstanceTemplate = function(tid)
		return GetTemplateInternal(tid, "Instance", InstanceTemplateMap)
	end

	def.static("number", "=>", "table").GetSpecialIdTemplate = function(tid)
		return GetTemplateInternal(tid, "SpecialId", nil)
	end

	def.static("number", "=>", "table").GetHearsayTemplate = function(tid)
		return GetTemplateInternal(tid, "Hearsay", nil)
	end

	local TextTemplateMap = {}
	def.static("number", "=>", "table").GetTextTemplate = function(tid)
		return GetTemplateInternal(tid, "Text", TextTemplateMap)
	end

	local DialogueTemplateMap = {}
	def.static("number", "=>", "table").GetDialogueTemplate = function(tid)
		return GetTemplateInternal(tid, "Dialogue", DialogueTemplateMap)
	end

	local SystemNotifyTemplateMap = {}
	def.static("number", "=>", "table").GetSystemNotifyTemplate = function(tid)
		return GetTemplateInternal(tid, "SystemNotify", SystemNotifyTemplateMap)
	end

	local QuestTemplateMap = {}
	def.static("number", "=>", "table").GetQuestTemplate = function(tid)
		return GetTemplateInternal(tid, "Quest", QuestTemplateMap)
	end

	local ManualEntrieTemplateMap = {}
	def.static("number", "=>", "table").GetManualEntrieTemplate = function(tid)
		return GetTemplateInternal(tid, "ManualEntrie", ManualEntrieTemplateMap)
	end

	local ManualTemplateMap = {}
	def.static("number", "=>", "table").GetManualTemplate = function(tid)
		return GetTemplateInternal(tid, "ManualAnecdote", ManualTemplateMap)
	end

	local GuildSmithyTemplateMap = {}
	def.static("number", "=>", "table").GetGuildSmithyTemplate = function(smithyId)
		return GetTemplateInternal(smithyId, "GuildSmithy", GuildSmithyTemplateMap)
	end

	local ItemTemplateMap = {}
	def.static("number", "=>", "table").GetItemTemplate = function(tid)
		return GetTemplateInternal(tid, "Item", ItemTemplateMap)
	end

	local CharmItemTemplateMap = {}
	def.static("number", "=>", "table").GetCharmItemTemplate = function(tid)
		return GetTemplateInternal(tid, "CharmItem", CharmItemTemplateMap)
	end

	local RewardTemplateMap = {}
	def.static("number", "=>", "table").GetRewardTemplate = function(tid)
		return GetTemplateInternal(tid, "Reward", RewardTemplateMap)
	end

	local CyclicQuestRewardMap = {}
	def.static("number", "=>", "table").GetCyclicQuestRewardMap = function(tid)
		return GetTemplateInternal(tid, "CyclicQuestReward", CyclicQuestRewardMap)
	end

	local MetaFightPropertyConfigTemplateMap = {}
	def.static("number", "=>", "table").GetMetaFightPropertyConfigTemplate = function(tid)
		return GetTemplateInternal(tid, "MetaFightPropertyConfig", MetaFightPropertyConfigTemplateMap)
	end

	local AttachedPropertyTemplateMap = {}
	def.static("number", "=>", "table").GetAttachedPropertyTemplate = function(tid)
		--print(debug.traceback())
		return GetTemplateInternal(tid, "AttachedProperty", AttachedPropertyTemplateMap)
	end

	local AttachedPropertyGeneratorTemplateMap = {}
	def.static("number", "=>", "table").GetAttachedPropertyGeneratorTemplate = function(tid)
		return GetTemplateInternal(tid, "AttachedPropertyGenerator", AttachedPropertyGeneratorTemplateMap)
	end	

	local AttachedPropertyGroupGeneratorTemplateMap = {}
	def.static("number", "=>", "table").GetAttachedPropertyGroupGeneratorTemplateMap = function(tid)
		return GetTemplateInternal(tid, "AttachedPropertyGroupGenerator", AttachedPropertyGroupGeneratorTemplateMap)
	end

	local NavigationDataTemplateMap = {}
	def.static("number", "=>", "table").GetNavigationDataTemplate = function(tid)
		return GetTemplateInternal(tid, "NavigationData", NavigationDataTemplateMap)
	end

	local AssetTemplateMap = {}
	def.static("number", "=>", "table").GetAssetTemplate = function(tid)
		return GetTemplateInternal(tid, "Asset", AssetTemplateMap)
	end

	local EquipInforceTemplateMap = {}
	def.static("number", "=>", "table").GetEquipInforceTemplate = function(tid)
		return GetTemplateInternal(tid, "EquipInforce", EquipInforceTemplateMap)
	end

	local EquipSuitTemplateMap = {}
	def.static("number", "=>", "table").GetEquipSuitTemplate = function(tid)
		return GetTemplateInternal(tid, "EquipSuit", EquipSuitTemplateMap)
	end

	local SuitTemplateMap = {}
	def.static("number", "=>", "table").GetSuitTemplate = function(tid)
		return GetTemplateInternal(tid, "Suit", SuitTemplateMap)
	end

	local LegendaryPropertyUpgradeTemplateMap = {}
	def.static("number", "=>", "table").GetLegendaryUpgradeTemplate = function(tid)
		return GetTemplateInternal(tid, "LegendaryPropertyUpgrade", LegendaryPropertyUpgradeTemplateMap)
	end
	


	local LevelUpExpTemplateMap = {} --
	def.static("number", "=>", "table").GetLevelUpExpTemplate = function(tid)
		return GetTemplateInternal(tid, "LevelUpExp", LevelUpExpTemplateMap)
	end

	local TransTemplateMap = {}
	def.static("number", "=>", "table").GetTransTemplate = function(tid)
		return GetTemplateInternal(tid, "Trans", TransTemplateMap)
	end

	local DungeonGroupConfigTemplateMap = {}
	def.static("number", "=>", "table").GetDungeonGroupConfigTemplate = function(tid)
		return GetTemplateInternal(tid, "DungeonGroupConfig", DungeonGroupConfigTemplateMap)
	end

	local ExecutionUnitTemplateMap = {}
	def.static("number", "=>", "table").GetExecutionUnitTemplate = function(tid)
		return GetTemplateInternal(tid, "ExecutionUnit", ExecutionUnitTemplateMap)
	end

	local GuideTemplateMap = {}
	def.static("number", "=>", "table").GetGuideTemplate = function(tid)
		return GetTemplateInternal(tid, "Guide", GuideTemplateMap)
	end

	local FunTemplateMap = {}
	def.static("number", "=>", "table").GetFunTemplate = function(tid)
		return GetTemplateInternal(tid, "Fun", FunTemplateMap)
	end

	local PVP33TemplateMap = {}
	def.static("number", "=>", "table").Get3V3Template = function(tid)
		return GetTemplateInternal(tid, "PVP3v3", PVP33TemplateMap)
	end

	--克隆数据(这里不可缓存数据)
	local function GetTemplateCloneInternal(tid, key)
		local data = GameUtil.GetTemplateData(key, tid)
		local template_class = pb_template[key]
		local template = template_class()
		if data ~= nil and string.len(data) > 0 then
			template:ParseFromString(data)
		else
			--warn(key .. " template data has error")
		end

		return template
	end

	def.static("number", "=>", "table").GetSkillTemplateClone = function(tid)
		return GetTemplateCloneInternal(tid, "Skill")
	end

	--local EquipResMap = {}
	def.static("number", "=>" , "table").GetEquipResMapTemp = function(id)--资源ID

	    local index_data_path = "Configs/equip_res_map.lua"
		local ret, msg, result = pcall(dofile, index_data_path)
		if ret then
			local data_path = result[id] -- 获取换装资源的文件路径 如 "Configs/humwarrior_m_lv01_nor_body.lua"
			if data_path == nil then 
				return nil
			else
				local ret1, msg1, result1 = pcall(dofile, data_path) 
				if ret1 then
					return result1
				else
					warn("failed to pcall " .. data_path .. " - " .. msg1)
				end
			end
		else
			warn("failed to pcall " .. index_data_path .. " - " .. msg)
		end

		return nil
	end

	def.static("number", "=>" , "table").GetEquipResMap = function(id)
		--if EquipResMap[id] ~= nil then return EquipResMap[i] end

		local assetTemplate = CElementData.GetAssetTemplate(id)
		if assetTemplate == nil then
			return nil
		end
		local assetPath = assetTemplate.Path--资源路径/assets/outputs/....

	    local index_data_path = "Configs/equip_res_map.lua"
		local ret, msg, result = pcall(dofile, index_data_path)
		if ret then
			for k,v in pairs(result) do
				local data_path = v -- 获取换装资源的文件路径 如 "Configs/humwarrior_m_lv01_nor_body.lua"
				if data_path == nil then 
					return nil
				else
					local ret, msg, configResult = pcall(dofile, data_path) 
					if ret then
						if configResult.AssetPath == assetPath then
							--EquipResMap[id] = configResult
							--print(data_path)
							return configResult
						end
					else
						warn("failed to pcall " .. data_path .. " - " .. msg)
					end
				end
			end

		else
			warn("failed to pcall " .. index_data_path .. " - " .. msg)
		end

		return nil
	end

	def.static("string", "=>" , "table").GetEquipResMapByName = function(root_name)
	    local index_data_path = "Configs/equip_res_map.lua"
		local ret, msg, result = pcall(dofile, index_data_path)
		if ret then
			for k,v in pairs(result) do
				local data_path = v -- 获取换装资源的文件路径 如 "Configs/humwarrior_m_lv01_nor_body.lua"
				if data_path == nil then 
					return nil
				else
					local ret, msg, configResult = pcall(dofile, data_path) 
					if ret then
						if configResult.Name ~= nil and configResult.Name == root_name then
							return configResult
						end
					else
						warn("failed to pcall " .. data_path .. " - " .. msg)
					end
				end
			end

		else
			warn("failed to pcall " .. index_data_path .. " - " .. msg)
		end

		return nil
	end



	--获取装备属性信息表 ID为附加属性组生成器ID (AttachedPropertyGroupGeneratorId)
	local EquipAttrInfoMap = {}
	def.static("number", "=>" , "table").GetEquipAttrInfoById = function(id)
		if EquipAttrInfoMap[id] == nil then
			EquipAttrInfoMap[id] = {}
			--附加属性组
			local groupTemplate = CElementData.GetTemplate("AttachedPropertyGroupGenerator", id)
			
			--附加属性
			for _,v in ipairs(groupTemplate.AttachedPropertyGeneratorConfigs) do
				if v ~= nil then

					local map = {}
					--属性组ID
					local property = CElementData.GetTemplate("AttachedPropertyGenerator", v.Id)
					
					--属性ID
					local fightElement = CElementData.GetAttachedPropertyTemplate(property.FightPropertyId)
					map.Name = fightElement.TextDisplayName
					map.ID = property.Id

					local propertyCnt = #property.StarSettings
					if propertyCnt > 0 then
						map.MinValue = property.StarSettings[1].MinValue
						map.MaxValue = property.StarSettings[propertyCnt].MaxValue
					end

					EquipAttrInfoMap[id][map.ID] = map
				end
       		end			 
		end

		return EquipAttrInfoMap[id]
	end
end

CElementData.Commit()
return CElementData
