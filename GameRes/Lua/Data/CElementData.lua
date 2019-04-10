local Lplus = require "Lplus"
local pb_template = require "PB.Template"
--local lsMan = require "Data.LSMan"

local error = error
--local tostring = tostring

--[[example
	local itemElement = CElementData.GetTemplate("Item", id)
]]

local isCachedAll = true
local logMemoryUsedMsg = false
local beforeLoadCSharp = 0
local beforeLoadLua = 0
local function LogMemoryUsedMsg(onlyCSharp, beforeLoad, name, tid)
	if not logMemoryUsedMsg then return end
	if beforeLoad then
		beforeLoadCSharp = GameUtil.GetCSharpUsedMemoryCount()
		beforeLoadLua = collectgarbage("count") * 1024
	else
		local msg = nil
		if onlyCSharp then
			msg = "==> Load " .. name .. " Template (" .. tid .. ") Use: C# - %d"
		else
			msg = "==> Load " .. name .. " Template (" .. tid .. ") Use: C# - %d Lua - %d"
		end
		local csharpCount = GameUtil.GetCSharpUsedMemoryCount() - beforeLoadCSharp
		local luaCount = collectgarbage("count") * 1024 - beforeLoadLua
		local log = nil
		if onlyCSharp then
			log = string.format(msg, csharpCount)
		else
			log = string.format(msg, csharpCount, luaCount)
		end
		
		do warn(log) end
	end
end

local beginUsageStatistics = false
local templateUsageStatistics = nil

local CElementData = Lplus.Class("CElementData")
do
	local def = CElementData.define

	local function GetTemplateInternal(tid, name, map)
		if tid <= 0 then return nil end

--[[
		if _G.pb_csharp_template_table[name] ~= nil then
			LogMemoryUsedMsg(true, true, name, tid)
			local t = _G.GetTemplateInternalCSharp(tid, name, map)
			--t = _G.LSMan.GetTemplate(name, t)
			LogMemoryUsedMsg(true, false, name, tid)
			return t
		end
]]

		if map ~= nil and map[tid] ~= nil then
			return map[tid]
		else
			LogMemoryUsedMsg(false, true, name, tid)
			local data = GameUtil.GetTemplateData(name, tid)
			local template_class = pb_template[name]
			local template = template_class()
			if data ~= nil and string.len(data) > 0 then
				template:ParseFromString(data)
				--template = _G.LSMan.GetTemplate(name, template)
				if map ~= nil then
					map[tid] = template
				end
			else
				warn("Failed to get " .. name .. " template data (tid = " .. tid .. ")", debug.traceback())
				return nil
			end
			LogMemoryUsedMsg(false, false, name, tid)
			return template
		end
	end

	-- 需要缓存的模板
	-- 一次性的不需要缓存，根据统计数据进行增加
	local templateData = 
	{
		Profession = {},
		Actor = {},
		State = {},
		Monster = {},
		Npc = {},
		Mine = {},
		Money = {},
		Item = {},
		Service = {},
		Map = {},
		Reputation = {},
		Designation = {},
		Trans = {},
		CountGroup = {},
		Quest = {},
	}

	def.static("string", "number", "=>", "table").GetTemplate = function(name, id)
		if beginUsageStatistics then
			if templateUsageStatistics == nil then templateUsageStatistics = {} end
			if templateUsageStatistics[name] == nil then templateUsageStatistics[name] = {} end
			local statis = templateUsageStatistics[name]
			if statis[id] == nil then 
				statis[id] = {1, os.time(), 0}
			else
				statis[id][1] = 1 + statis[id]
				statis[id][3] = os.time()
			end
		end
		if isCachedAll and templateData[name] == nil then templateData[name] = {} end
		return GetTemplateInternal(id, name, templateData[name])
	end

	def.static().DumpStatistics = function()
		if templateUsageStatistics == nil then return end
		local filename = _G.res_base_path .. "/" .. "template_usage.csv"
		local f = io.open(filename,"w")
		local title = "Template,Tid,Count,Time\n"
		f:write(title)
		for k,v in pairs(templateUsageStatistics) do
			for k1,v1 in pairs(v) do
				local s = string.format("%s,%d,%d,%f\n", k, k1, v1[1], v1[3]-v1[2])
				f:write(s)
			end
		end
		f:close()
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

	def.static("=>", "table").GetAllFun = function()
		return GameUtil.GetAllTid("Fun")
	end

	def.static("=>", "table").GetAllWingLevelUp = function()
		return GameUtil.GetAllTid("WingLevelUp")
	end

	def.static("=>", "table").GetAllTeamRoomData = function()
		return GameUtil.GetAllTid("TeamRoomConfig")
	end

	def.static("=>", "table").GetAllQuestChapter = function()
		return GameUtil.GetAllTid("QuestChapter")
	end
	
	def.static("=>", "table").GetAllQuestGroup = function()
		return GameUtil.GetAllTid("QuestGroup")
	end

	def.static("=>", "table").GetAllReputation = function()
		return GameUtil.GetAllTid("Reputation")
	end

	def.static("=>", "table").GetAllHangQuest = function()
		return GameUtil.GetAllTid("HangQuest")
	end

	def.static("=>", "table").GetAllSensitiveWord = function()
		return GameUtil.GetAllTid("SensitiveWord")
	end

	def.static("number", "=>", "table").GetReputationTemplate = function(tid)
		return CElementData.GetTemplate("Reputation", tid)
	end


	def.static("number", "=>", "table").GetSkillTemplate = function(tid)
		return CElementData.GetTemplate("Skill", tid)
	end

	def.static("number", "=>", "table").GetTeamRoomTemplate = function(tid)
		return CElementData.GetTemplate("TeamRoomConfig", tid)
	end


	def.static("number", "=>", "table").GetMarketTemplate = function(tid)
		return CElementData.GetTemplate("Market", tid)
	end

	def.static("number", "=>", "table").GetSkillLevelUpTemplate = function(tid)
		return CElementData.GetTemplate("SkillLevelUp", tid)
	end

	def.static("number", "=>", "table").GetSkillLearnConditionTemplate = function(tid)
		return CElementData.GetTemplate("SkillLearnCondition", tid)
	end

	def.static("number", "=>", "table").GetSkillLevelUpConditionTemplate = function(tid)
		return CElementData.GetTemplate("SkillLevelUpCondition", tid)
	end

	def.static("number", "=>", "table").GetRuneTemplate = function(tid)
		return CElementData.GetTemplate("Rune", tid)
	end

	def.static("number", "=>", "table").GetSkillMasteryTemplate = function(tid)
		return CElementData.GetTemplate("SkillMastery", tid)
	end

	def.static("number", "=>", "table").GetRuneLevelUpTemplate = function(tid)
		return CElementData.GetTemplate("RuneLevelUp", tid)
	end

	def.static("number", "=>", "table").GetTalentTemplate = function(tid)
		return CElementData.GetTemplate("Talent", tid)
	end

	def.static("number", "=>", "table").GetActorTemplate = function(tid)
		return CElementData.GetTemplate("Actor", tid)
	end

	def.static("number", "=>", "table").GetStateTemplate = function(tid)
		return CElementData.GetTemplate("State", tid)
	end

	def.static("number", "=>", "table").GetProfessionTemplate = function (tid)
		return CElementData.GetTemplate("Profession", tid)
	end

	def.static("number", "=>", "table").GetMonsterTemplate = function (tid)
		return CElementData.GetTemplate("Monster", tid)
	end

	def.static("number", "=>", "table").GetNpcTemplate = function (tid)
		return CElementData.GetTemplate("Npc", tid)
	end

	def.static("number", "=>", "table").GetMineTemplate = function(tid)
		return CElementData.GetTemplate("Mine", tid)
	end

	def.static("number", "=>", "table").GetServiceTemplate = function (tid)
		return CElementData.GetTemplate("Service", tid)
	end

	def.static("number", "=>", "table").GetHorseTemplate = function (tid)
		return CElementData.GetTemplate("Horse", tid)
	end

	def.static("number", "=>", "table").GetObstacleTemplate = function (tid)
		return CElementData.GetTemplate("Obstacle", tid)
	end

	def.static("number", "=>", "table").GetMapTemplate = function(tid)
		return CElementData.GetTemplate("Map", tid)
	end

	def.static("number", "=>", "table").GetInstanceTemplate = function(tid)
		return CElementData.GetTemplate("Instance", tid)
	end

	def.static("number", "=>", "table").GetSpecialIdTemplate = function(tid)
		return GetTemplateInternal(tid, "SpecialId", nil)
	end

	def.static("number", "=>", "table").GetHearsayTemplate = function(tid)
		return GetTemplateInternal(tid, "Hearsay", nil)
	end

	def.static("number", "=>", "table").GetTextTemplate = function(tid)
		return CElementData.GetTemplate("Text", tid)
	end

	def.static("number", "=>", "table").GetDialogueTemplate = function(tid)
		return CElementData.GetTemplate("Dialogue", tid)
	end

	def.static("number", "=>", "table").GetSystemNotifyTemplate = function(tid)
		return CElementData.GetTemplate("SystemNotify", tid)
	end

	def.static("number", "=>", "table").GetQuestTemplate = function(tid)
		return CElementData.GetTemplate("Quest", tid)
	end

	def.static("number", "=>", "table").GetManualEntrieTemplate = function(tid)
		return CElementData.GetTemplate("ManualEntrie", tid)
	end

	def.static("number", "=>", "table").GetManualTemplate = function(tid)
		return CElementData.GetTemplate("ManualAnecdote", tid)
	end

	def.static("number", "=>", "table").GetGuildSmithyTemplate = function(tid)
		return CElementData.GetTemplate("GuildSmithy", tid)
	end

	def.static("number", "=>", "table").GetItemTemplate = function(tid)
		return CElementData.GetTemplate("Item", tid)
	end

	def.static("number", "=>", "table").GetCharmItemTemplate = function(tid)
		return CElementData.GetTemplate("CharmItem", tid)
	end

	def.static("number", "=>", "table").GetCharmBlessItemTemplate = function (tid)
		return CElementData.GetTemplate("CharmWishes", tid)
	end

	def.static("number", "=>", "table").GetRewardTemplate = function(tid)
		return CElementData.GetTemplate("Reward", tid)
	end
	def.static("number", "=>", "table").GetMoneyTemplate = function(tid)
		return CElementData.GetTemplate("Money", tid)
	end
	def.static("number", "=>", "table").GetCyclicQuestRewardMap = function(tid)
		return CElementData.GetTemplate("CyclicQuestReward", tid)
	end

	def.static("number", "=>", "table").GetMetaFightPropertyConfigTemplate = function(tid)
		return CElementData.GetTemplate("MetaFightPropertyConfig", tid)
	end

	def.static("number", "=>", "table").GetAttachedPropertyTemplate = function(tid)
		--print(debug.traceback())
		return CElementData.GetTemplate("AttachedProperty", tid)
	end

	def.static("number", "=>", "table").GetAttachedPropertyGeneratorTemplate = function(tid)
		return CElementData.GetTemplate("AttachedPropertyGenerator", tid)
	end	

	def.static("number", "=>", "table").GetAttachedPropertyGroupGeneratorTemplateMap = function(tid)
		return CElementData.GetTemplate("AttachedPropertyGroupGenerator", tid)
	end

	def.static("number", "=>", "table").GetNavigationDataTemplate = function(tid)
		return CElementData.GetTemplate("NavigationData", tid)
	end

	def.static("number", "=>", "table").GetAssetTemplate = function(tid)
		return CElementData.GetTemplate("Asset", tid)
	end

	def.static("number", "=>", "table").GetEquipInforceTemplate = function(tid)
		return CElementData.GetTemplate("EquipInforce", tid)
	end

	def.static("number", "=>", "table").GetEquipSuitTemplate = function(tid)
		return CElementData.GetTemplate("EquipSuit", tid)
	end

	def.static("number", "=>", "table").GetSuitTemplate = function(tid)
		return CElementData.GetTemplate("Suit", tid)
	end

	def.static("number", "=>", "table").GetLegendaryUpgradeTemplate = function(tid)
		return CElementData.GetTemplate("LegendaryPropertyUpgrade", tid)
	end

	def.static("number", "=>", "table").GetLegendaryGroupTemplate = function(tid)
		return CElementData.GetTemplate("LegendaryGroup", tid)
	end

	def.static("number", "=>", "table").GetPVP3v3Template = function(tid)
		return CElementData.GetTemplate("PVP3v3", tid)
	end

	def.static("number", "=>", "table").GetLevelUpExpTemplate = function(tid)
		return CElementData.GetTemplate("LevelUpExp", tid)
	end

	def.static("number", "=>", "table").GetTransTemplate = function(tid)
		return CElementData.GetTemplate("Trans", tid)
	end

	def.static("number", "=>", "table").GetDungeonGroupConfigTemplate = function(tid)
		return CElementData.GetTemplate("DungeonGroupConfig", tid)
	end

	def.static("number", "=>", "table").GetExecutionUnitTemplate = function(tid)
		return CElementData.GetTemplate("ExecutionUnit", tid)
	end

	def.static("number", "=>", "table").GetGuideTemplate = function(tid)
		return CElementData.GetTemplate("Guide", tid)
	end

	def.static("number", "=>", "table").GetFunTemplate = function(tid)
		return CElementData.GetTemplate("Fun", tid)
	end

	def.static("number", "=>", "table").GetSensitiveWordTemplate = function(tid)
		return GetTemplateInternal(tid, "SensitiveWord", nil)
	end

	def.static("number", "=>", "table").GetScriptCalendarTemplate = function(tid)
		return CElementData.GetTemplate("ScriptCalendar", tid)
	end
	def.static("number", "=>", "table").GetRankTemplate = function(tid)
		return CElementData.GetTemplate("Rank", tid)
	end
	def.static("number", "=>", "table").GetRankRewardTemplate = function(tid)
		return CElementData.GetTemplate("RankReward", tid)
	end

	def.static("number", "=>", "table").GetItemMachiningTemplate = function(tid)
		return CElementData.GetTemplate("ItemMachining", tid)
	end
	
	def.static("number", "=>", "table").GetExpeditionTemplate = function(tid)
		return CElementData.GetTemplate("Expedition", tid)
	end
	
	def.static("number", "=>", "table").GetEliminateTemplate = function(tid)
		return CElementData.GetTemplate("Eliminate", tid)
	end

	def.static("number", "=>", "table").GetDressTemplate = function(tid)
		return CElementData.GetTemplate("Dress", tid)
	end

	def.static("number", "=>", "table").GetPetTemplate = function(tid)
		return CElementData.GetTemplate("Pet", tid)
	end

	def.static("number", "=>", "table").GetPlayerStrong = function(tid)
		return CElementData.GetTemplate("PlayerStrong", tid)
	end

	def.static("number", "=>", "table").GetPlayerStrongCell = function(tid)
		return CElementData.GetTemplate("PlayerStrongCell", tid)
	end


	def.static("number", "=>", "table").GetPlayerStrongValue = function(tid)
		return CElementData.GetTemplate("PlayerStrongValue", tid)
	end

	def.static("number", "=>", "table").GetItemApproach = function(tid)
		return CElementData.GetTemplate("ItemApproach", tid)
	end

	def.static("number", "=>", "table").GetInforceDecomposeApproach = function(tid)
		return CElementData.GetTemplate("InforceDecompose", tid)
	end

	def.static("number", "=>", "table").GetExpFind = function(tid)
		return CElementData.GetTemplate("ExpFind", tid)
	end
	--克隆数据(这里不可缓存数据)
	local function GetTemplateCloneInternal(tid, key)
		local data = GameUtil.GetTemplateData(key, tid)
		local template_class = pb_template[key]
		local template = template_class()
		if data ~= nil and string.len(data) > 0 then
			template:ParseFromString(data)
			--template = _G.LSMan.GetTemplate(key, template)
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

	--获取属性信息
	def.static("number", "=>", "table").GetPropertyInfoById = function(id)
		local map = {}
		--属性组ID
		local property = CElementData.GetTemplate("AttachedPropertyGenerator", id)
		
		--属性ID
		local fightElement = CElementData.GetAttachedPropertyTemplate(property.FightPropertyId)
		map.Name = fightElement.TextDisplayName
		map.ID = property.Id
		map.FightPropertyId = property.FightPropertyId
		local propertyCnt = #property.StarSettings
		if propertyCnt > 0 then
			local max = -1
			local min = 99999999999
			for i=1, propertyCnt do
				local propertyData = property.StarSettings[i]
				if propertyData.Weight > 0 then
					min = math.min(min, propertyData.MinValue)
					max = math.max(max, propertyData.MaxValue)
				end
			end
			map.MinValue = min--property.StarSettings[1].MinValue
			map.MaxValue = max--property.StarSettings[propertyCnt].MaxValue
			map.MaxStar = propertyCnt
		end

		return map
	end

	--获取装备属性信息表 ID为附加属性组生成器ID (AttachedPropertyGroupGeneratorId)
	local EquipAttrInfoMap = {}
	def.static("number", "=>" , "table").GetEquipAttrInfoById = function(id)
		if EquipAttrInfoMap == nil then EquipAttrInfoMap = {} end

		if EquipAttrInfoMap[id] == nil then
			EquipAttrInfoMap[id] = {}
			--附加属性组
			local groupTemplate = CElementData.GetTemplate("AttachedPropertyGroupGenerator", id)
			
			--附加属性
			for _,v in ipairs(groupTemplate.ConfigData.AttachedPropertyGeneratorConfigs) do
				if v ~= nil then
					local map = CElementData.GetPropertyInfoById(v.Id)
					EquipAttrInfoMap[id][map.ID] = map
				end
       		end			 
		end

		return EquipAttrInfoMap[id]
	end

	--获取宠物图鉴信息
	local PetAllGuideInfo = {}
	def.static("number", "=>" , "table").GetPetGuideById = function(id)
		if PetAllGuideInfo == nil then PetAllGuideInfo = {} end
		if PetAllGuideInfo[id] == nil then
			local template = CElementData.GetTemplate("Pet", id)
			if template == nil then return nil end

			local map = {}
			map.ID = id
			map.Name = template.Name
			map.Genus = template.Genus
			map.IconPath = template.IconPath
			map.GuideIconPath = template.GuideIconPath
			map.Quality = template.Quality
			map.PetStroy = template.Stroy
			map.ApproachIDs = template.ApproachIDs
			map.ModelAssetPath = nil

			do
			--模型 关联怪物信息
				local monsterData = CElementData.GetTemplate("Monster", template.AssociatedMonsterId)
				if monsterData ~= nil then
					map.ModelAssetPath = monsterData.ModelAssetPath
				end
			end

			do
			-- 属性信息
				map.PropertyList = {}
				-- 数值需求, 前三条潜规则默认写死一个属性组ID, 其余的不读，为服务器随机 
				local strIds = template.AttachedPropertyGroupGeneratorIds
				local generatorIds = string.split(strIds, "*")
				if #generatorIds < 3 then
					warn("宠物：数值配错了,至少得有三条随机：", id)
					return nil
				end
				-- 数值需求, 前三条潜规则默认写死一个属性组ID, 其余的不读，为服务器随机 
				for i=1, 3 do
					local generatorId = tonumber(generatorIds[i])
					local groupTemplate = CElementData.GetTemplate("AttachedPropertyGroupGenerator", generatorId)
					if groupTemplate == nil or #groupTemplate.ConfigData.AttachedPropertyGeneratorConfigs == 0 then
						warn("宠物：数值配错了,属性组没有：", generatorId)
						return nil
					end
					local attachedPropertyGenerator = groupTemplate.ConfigData.AttachedPropertyGeneratorConfigs[1]
					local propertyInfo = CElementData.GetPropertyInfoById(attachedPropertyGenerator.Id)
					table.insert(map.PropertyList, propertyInfo)
				end
			end
			do
			-- 资质信息
				map.AptitudeList = {}
				-- 数值需求, 前三条潜规则默认写死一个属性组ID, 其余的不读，为服务器随机 
				local strIds = template.AttachedPropertyGeneratorIds
				local propertyGeneratorIds = string.split(strIds, "*")
				if #propertyGeneratorIds < 3 then
					warn("宠物：数值配错了,至少得有三条随机：", id)
					return nil
				end
				-- 数值需求, 前三条潜规则默认写死一个属性组ID, 其余的不读，为服务器随机 
				for i=1, 3 do
					local propertyGeneratorId = tonumber(propertyGeneratorIds[i])
					local propertyInfo = CElementData.GetPropertyInfoById(propertyGeneratorId)
					table.insert(map.AptitudeList, propertyInfo)
				end
			end
			do
				-- 天赋技能库
				map.TalentList = {}
				local generatorId = template.TelantSkillGroupId
				local groupTemplate = CElementData.GetTemplate("LegendaryGroup", generatorId)
				if groupTemplate == nil or #groupTemplate.Legendarys.LegendaryPairs == 0 then
					warn("宠物：数值配错了,天赋属性组没有：", id)
					return nil
				end
				for i=1, #groupTemplate.Legendarys.LegendaryPairs do
					local talentId = groupTemplate.Legendarys.LegendaryPairs[i].TalentID
					local talentTemplate = CElementData.GetTemplate('Talent', talentId)
					if talentTemplate == nil then
						warn("宠物：数值配错了,天赋没有：", id)
						return nil
					end
					local DynamicText = require "Utility.DynamicText"
					local talentInfo = {}
					
					talentInfo.ID = talentId
					talentInfo.Name = talentTemplate.Name
					talentInfo.Desc = DynamicText.ParseSkillDescText(talentId, 1, true)
					talentInfo.IconPath = talentTemplate.Icon
					talentInfo.Quality = talentTemplate.InitQuality

					table.insert(map.TalentList, talentInfo)
				end
			end

			PetAllGuideInfo[id] = map
		end

		return PetAllGuideInfo[id]
	end

	--获取宠物图鉴信息
	local PetAllLevelInfo = {}
	def.static("number", "number", "=>" , "number").GetPetExp = function(quality, level)
		if PetAllLevelInfo == nil then 
			PetAllLevelInfo = {}
			local MaxQualityCount = 7
			for i=1, MaxQualityCount do
				PetAllLevelInfo[i-1] = {}
			end
		end
		
		if PetAllLevelInfo[quality][level] == nil then
			local infoTids = GameUtil.GetAllTid("PetLevel")
			for i, tid in ipairs(infoTids) do
				local data = CElementData.GetTemplate("PetLevel", tid)
				if data ~= nil then
					PetAllLevelInfo[data.PetQuality][data.Level] = data.Experience
				end
			end
		end

		return PetAllLevelInfo[quality][level] or 0
	end

	-- --获取装备传奇属性组，可进行转换的库
	-- local LegendaryGroupInfoMap = {}
	-- def.static('number', '=>', 'table').GetLegendaryGroupInfoById = function(id)
	-- 	if LegendaryGroupInfoMap == nil then LegendaryGroupInfoMap = {} end

	-- 	if LegendaryGroupInfoMap[id] == nil then
	-- 		LegendaryGroupInfoMap[id] = {}
	-- 		--传奇属性组
	-- 		local groupTemplate = CElementData.GetTemplate('LegendaryGroup', id)
	-- 		--传奇属性（天赋/被动技能 类似的名字...）
	-- 		local legendarys = groupTemplate.Legendarys.LegendaryPairs
	-- 		for _,v in ipairs(legendarys) do
	-- 			local map = CElementData.GetSkillInfoByIdAndLevel(v.TalentID, v.TalentLevel, true)
	-- 			if map ~= nil then
	-- 				table.insert(LegendaryGroupInfoMap[id], map)
	-- 			end
	-- 		end
	-- 	end

	-- 	return LegendaryGroupInfoMap[id]
	-- end

	--获取装备传奇属性组，可进行转换的库
	local LegendaryGroupInfoMap = {}
	def.static('number', '=>', 'table').GetLegendaryGroupInfoById = function(id)
		if LegendaryGroupInfoMap == nil then LegendaryGroupInfoMap = {} end

		if LegendaryGroupInfoMap[id] == nil then
			LegendaryGroupInfoMap[id] = {}

			local DynamicText = require "Utility.DynamicText"
			--传奇属性组
			local groupTemplate = CElementData.GetTemplate('LegendaryGroup', id)
			--传奇属性（天赋/被动技能 类似的名字...）
			local legendarys = groupTemplate.Legendarys.LegendaryPairs
			for _,v in ipairs(legendarys) do
				local map = CElementData.GetSkillInfoByIdAndLevel(v.TalentID, v.TalentLevel, true)
				if map ~= nil then
					local info = DynamicText.GetParseSkillDescTextKeyValue(v.TalentID, v.TalentLevel, true)
					-- warn("组织    组织v.TalentID = ", v.TalentID)
					if LegendaryGroupInfoMap[id][v.TalentID] == nil then
						map.MinLv = map.Level
						map.MaxLv = map.Level
						map.InfoMin = clone(info)
						map.InfoMax = clone(info)

						LegendaryGroupInfoMap[id][v.TalentID] = map
					else
						local old = LegendaryGroupInfoMap[id][v.TalentID]
						old.MinLv = math.min(old.MinLv ,map.Level)
						old.MaxLv = math.max(old.MaxLv ,map.Level)
						-- calc min integer
						for i, oldInfo in ipairs(old.InfoMin.Integer) do
							oldInfo.Value = math.min(oldInfo.Value, info.Integer[i].Value)
						end
						-- calc max integer
						for i, oldInfo in ipairs(old.InfoMax.Integer) do
							oldInfo.Value = math.max(oldInfo.Value, info.Integer[i].Value)
						end
						-- calc min percentage
						for i, oldInfo in ipairs(old.InfoMin.Percentage) do
							oldInfo.Value = math.min(oldInfo.Value, info.Percentage[i].Value)
						end
						-- calc max percentage
						for i, oldInfo in ipairs(old.InfoMax.Percentage) do
							oldInfo.Value = math.max(oldInfo.Value, info.Percentage[i].Value)
						end
					end
				end
			end

			for k,skillInfo in pairs(LegendaryGroupInfoMap[id]) do
				-- warn("skillInfo.MinLv = ",skillInfo.ID, skillInfo.MinLv, skillInfo.MaxLv)
				if skillInfo.MinLv ~= skillInfo.MaxLv then
					local resultInfo = {Integer={}, Percentage={}}
					-- Integer fixed replace
					for i,v in ipairs(skillInfo.InfoMin.Integer) do
						local data = {}
						local minStr = fmtVal2Str(v.Value)
						local maxStr = fmtVal2Str(skillInfo.InfoMax.Integer[i].Value)
						local replaceStr = string.format(StringTable.Get(31337), minStr, maxStr)
						data.Key = v.Key
						data.Value = replaceStr
						-- warn("replaceStr = ", replaceStr)
						table.insert(resultInfo.Integer, data)
					end
					-- Percentage fixed replace
					for i,v in ipairs(skillInfo.InfoMin.Percentage) do
						local data = {}
						local minStr = string.format("%s%%", fmtVal2Str(tonumber(fmtVal2Str(v.Value))))
						local maxStr = string.format("%s%%", fmtVal2Str(tonumber(fmtVal2Str(skillInfo.InfoMax.Percentage[i].Value))))
						local replaceStr = string.format(StringTable.Get(31337), minStr, maxStr)
						data.Key = v.Key
						data.Value = replaceStr
						-- warn("replaceStr%%%%%%%%%%%%%%%%%%%%%% = ", replaceStr)
						table.insert(resultInfo.Percentage, data)
					end
					skillInfo.LvDesc = string.format(StringTable.Get(31339), skillInfo.MinLv, skillInfo.MaxLv)
					skillInfo.SkillDesc = DynamicText.ExchangeParseSkillDescText(skillInfo.ID, 1, true, resultInfo)
				else
					skillInfo.LvDesc = string.format(StringTable.Get(31338), skillInfo.Level)
					skillInfo.SkillDesc = skillInfo.Desc
					-- warn("等级描述一致： ", skillInfo.LvDesc)
					-- warn("只有一种文字描述 ： ", skillInfo.Desc)
				end
			end
		end

		return LegendaryGroupInfoMap[id]
	end

	--获取装备继承信息，按等级索引
	local InheritGroupInfoMap = {}
	def.static('number', 'number', '=>', 'table').GetInheritInfo = function(itemLevel, inforceLv)
		-- warn("GetInheritInfo = ", itemLevel, inforceLv)
		if InheritGroupInfoMap == nil then InheritGroupInfoMap = {} end

		if InheritGroupInfoMap[itemLevel] == nil then
			local infoTids = GameUtil.GetAllTid("EquipInherit")
			for i, tid in ipairs(infoTids) do
				local template = CElementData.GetTemplate('EquipInherit', tid)
				if template ~= nil then
					if InheritGroupInfoMap[template.ItemLevel] == nil then InheritGroupInfoMap[template.ItemLevel] = {} end

					for i, inheritData in ipairs(template.InheritDatas) do
						local data = {}
						data.Id = inheritData.Id
						data.Name = inheritData.Name
						data.DisplayName = inheritData.DisplayName
						data.InforceLevel = inheritData.InforceLevel
						data.InheritLevel = inheritData.InheritLevel
						data.CostMoneyId = inheritData.CostMoneyId
						data.CostMoneyCount = inheritData.CostMoneyCount
						data.perfectMoneyId = inheritData.perfectMoneyId
						data.perfectMoneyCount = inheritData.perfectMoneyCount
						data.perfectInheritLevel = inheritData.perfectInheritLevel

						InheritGroupInfoMap[template.ItemLevel][inheritData.InforceLevel] = data
					end
				end
			end
		end

		return (InheritGroupInfoMap[itemLevel] ~= nil and InheritGroupInfoMap[itemLevel][inforceLv]) and
		        InheritGroupInfoMap[itemLevel][inforceLv] or nil
	end
--[[
	-- 宠物开锁条件, 因配置再VIP等级内,需要全遍历,所以存个结构
	local PetUnlockInfo = {}
	def.static("=>", "table").GetPetUnlockInfo = function()
		if PetUnlockInfo == nil then PetUnlockInfo = {} end

		if #PetUnlockInfo == 0 then 
			local tmpUnlockHelp1 = {}
			local tmpUnlockHelp2 = {}
			local infoTids = GameUtil.GetAllTid("GloryLevel")
			for i, tid in ipairs(infoTids) do
				--荣耀等级
				local gloryemplate = CElementData.GetTemplate('GloryLevel', tid)
				if gloryemplate.No2PetUnlock then
					table.insert(tmpUnlockHelp1, gloryemplate.Level)
				end
				if gloryemplate.No3PetUnlock then
					table.insert(tmpUnlockHelp2, gloryemplate.Level)
				end
			end
			local function sorcFunction(a,b)
				return a < b
			end
			table.sort(tmpUnlockHelp1, sorcFunction)
			table.sort(tmpUnlockHelp2, sorcFunction)
			table.insert(PetUnlockInfo, tmpUnlockHelp1[1])
			table.insert(PetUnlockInfo, tmpUnlockHelp2[1])
		end

		return PetUnlockInfo
	end
]]
	--获取技能，被动技能的一个结构
	def.static('number', 'number', 'boolean', '=>', 'table').GetSkillInfoByIdAndLevel = function(id, level, bIsTalent)
		local info = {}
		local template = CElementData.GetTemplate("Talent", id)
		if template == nil then return nil end
		
		local DynamicText = require "Utility.DynamicText"
		info.ID = id
		info.Name = template.Name
		info.Level = level
		info.Desc = DynamicText.ParseSkillDescText(id, level, bIsTalent)

		return info
	end

	local PetSkillCellInfoMap = {}
	def.static("number", "=>", "table").GetPetSkillCellInfoByQuality = function(quality)
		if PetSkillCellInfoMap == nil then PetSkillCellInfoMap = {} end

		local key = tostring(quality)
		if PetSkillCellInfoMap[key] == nil then
			local data = {}
			--quality 从0开始，lua索引从1开始，故++操作
			local petQualityInfoData = CElementData.GetTemplate("PetQualityInfo", quality+1)
			local CPetUtility = require "Pet.CPetUtility"
			local MaxSkillCount = CPetUtility.GetMaxSkillCount()
			local MaxPetStage = CPetUtility.GetMaxPetStage()

			local tmpStageInfo = {}
			for i=1, MaxPetStage do
				local keyStage = string.format("Stage%d", i)
				if petQualityInfoData[keyStage] ~= nil then
					local openSkillCount = petQualityInfoData[keyStage]
					table.insert(tmpStageInfo, openSkillCount)
				end
			end

			local tmpSkillCellInfo = {}
			for stageIndex=1, #tmpStageInfo do
				local bCanOpen = false
				for skillIndex=1, MaxSkillCount do
					if tmpStageInfo[stageIndex-1] == nil or tmpStageInfo[stageIndex-1] < skillIndex then
						if skillIndex <= tmpStageInfo[stageIndex] then
							bCanOpen = true
							table.insert(tmpSkillCellInfo, tmpStageInfo[stageIndex])
						end
					end
				end

				--无法开启的情况,第一个无法开启的情况出现,则后面均无法开启
				if bCanOpen == false then
					table.insert(tmpSkillCellInfo, -1)
					break
				end
			end
			
			PetSkillCellInfoMap[key] = tmpSkillCellInfo
		end

		return PetSkillCellInfoMap[key]
	end

	--刻印石信息表
	local EquipEngravingInfoMap = {}
	def.static("number", "number", "=>", "table").GetEquipEngravingInfoMapByLevelAndSlot = function(level, equipSlot)
		--warn('GetEquipEngravingInfoMapByLevelAndSlot', level, equipSlot)
		--刻印装备 20级以下 无法刻印
		if level < 20 then return nil end
		if EquipEngravingInfoMap == nil then EquipEngravingInfoMap = {} end

		local key = tostring(level)
		if EquipEngravingInfoMap[key] == nil then
			local map = {}
			local tidList = {}

			local allIds = GameUtil.GetAllTid("EquipEngraving")
			for i, tid in ipairs(allIds) do
				local data = CElementData.GetTemplate("EquipEngraving", tid)
				local keyLevel = tostring(data.EngravingLevel)
				local keySlot = tostring(data.EngravingSlot)

				if EquipEngravingInfoMap[keyLevel] == nil then EquipEngravingInfoMap[keyLevel] = {} end
				if EquipEngravingInfoMap[keyLevel][keySlot] == nil then EquipEngravingInfoMap[keyLevel][keySlot] = {} end
				EquipEngravingInfoMap[keyLevel][keySlot].MoneyId = data.CostMoneyId
				EquipEngravingInfoMap[keyLevel][keySlot].MoneyNeed = data.CostMoneyCount
				EquipEngravingInfoMap[keyLevel][keySlot].GrindStoneNeed = data.CostGrindStoneCount
				EquipEngravingInfoMap[keyLevel][keySlot].StoneIdList = {}

				--刻印石ID
				local EngravingStoneIds = string.split(data.EngravingStoneIds, "*")
				for i=1, #EngravingStoneIds do
					table.insert(EquipEngravingInfoMap[keyLevel][keySlot].StoneIdList, tonumber(EngravingStoneIds[i]))
				end
			end
		end

		return EquipEngravingInfoMap[key][tostring(equipSlot)] or nil
	end

	--附魔信息表
	local EquipEnchantInfoMap = {}
	def.static("number", "=>", "table").GetEquipEquipEnchantInfoMapByItemID = function(id)
		-- warn('GetEquipEquipEnchantInfoMapByItemID', id)
		local itemTemplate = CElementData.GetTemplate("Item", id)
		if itemTemplate == nil then return nil end
		local EItemEventType = require "PB.data".EItemEventType	--物品使用 类型
		if EItemEventType.ItemEvent_EquipEnchant ~= itemTemplate.EventType1 then return nil end

		if EquipEnchantInfoMap == nil then EquipEnchantInfoMap = {} end

		local EnchantId = tonumber(itemTemplate.Type1Param1)
		local AttachedPropertyGroupGeneratorId = tonumber(itemTemplate.Type1Param2)

		if EquipEnchantInfoMap[EnchantId] == nil then
			local allIds = GameUtil.GetAllTid("Enchant")
			for i, tid in ipairs(allIds) do
				local data = {}
				local template = CElementData.GetTemplate("Enchant", tid)
				data.ID = template.Id
				data.Name = template.Name
				data.Level = template.EnchantLevel
				data.Slot = template.EnchantSlot+1
				data.CostMoneyId = template.CostMoneyId
				data.CostMoneyCount = template.CostMoneyCount
				data.ExpiredTime = template.EnchantExpiredTime

				EquipEnchantInfoMap[tid] = data
			end
		end

		local propertyInfo = CElementData.GetPropertyInfoById(AttachedPropertyGroupGeneratorId)
		local valDesc = ""
		if propertyInfo.MinValue == propertyInfo.MaxValue then
			valDesc = string.format(StringTable.Get(31340), propertyInfo.MinValue)
		else
			valDesc = string.format(StringTable.Get(31337), propertyInfo.MinValue, propertyInfo.MaxValue)
		end
		propertyInfo.ValueDesc = valDesc

		local result = {}
		result.Enchant = EquipEnchantInfoMap[EnchantId] or nil
		result.Property = propertyInfo
		-- warn("result.Enchant Slot = ", result.Enchant.Slot)

		return result
	end

	--强化石信息表
	local EquipInforceInfoMap = {}
	def.static("number", "=>", "table").GetEquipInforceInfoMap = function(equipInforceId)
		-- warn('GetEquipInforceInfoMap', equipInforceId)
		if EquipInforceInfoMap == nil then EquipInforceInfoMap = {} end

		if EquipInforceInfoMap[equipInforceId] == nil then
			local allIds = GameUtil.GetAllTid("EquipInforce")
			for i, tid in ipairs(allIds) do
				local EquipInforceTemplate = CElementData.GetTemplate("EquipInforce", tid)
				if EquipInforceTemplate ~= nil then
					local data = {}
					data.ID = equipInforceId
					data.Name = EquipInforceTemplate.Name
					data.InforceDatas = {}
					data.SafeLevel = 0
					for _, inforceData in ipairs(EquipInforceTemplate.InforceDatas) do
						table.insert(data.InforceDatas, inforceData)
						if inforceData.DownPercent == 0 then
							data.SafeLevel = inforceData.InforceLevel
						end
					end

					EquipInforceInfoMap[tid] = data
				end
			end
		end

		return EquipInforceInfoMap[equipInforceId] or nil
	end

	def.static().ClearAll = function()
		templateData = 
		{
			Profession = {},
			Actor = {},
			State = {},
			Monster = {},
			Npc = {},
			Mine = {},
			Money = {},
			Item = {},
			Service = {},
			Scene = {},
			Reputation = {},
			Designation = {},
			Trans = {},
			CountGroup = {},
			Quest = {},
		}

		AllGuildLevel = nil
		AllGuildBuildLevel = nil
		AllGuildPermission = nil
		AllGuide = nil
		PetSkillCellInfoMap = nil
		EquipAttrInfoMap = nil
		PetAllGuideInfo = nil
		LegendaryGroupInfoMap = nil
		EquipEngravingInfoMap = nil
		PetAllLevelInfo = nil
		InheritGroupInfoMap = nil
		EquipEnchantInfoMap = nil
		EquipInforceInfoMap = nil
	end
end

CElementData.Commit()
return CElementData