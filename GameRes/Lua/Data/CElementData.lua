local Lplus = require "Lplus"
local pb_template = require "PB.Template"
require "Tools.EfficiencyAnalyze"
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

	--[[ =============================================
	=====           模板详细                     =====
	=================================================]]

	local function GetTemplateInternal(tid, name, map)
		if tid <= 0 then return nil end

		if map ~= nil and map[tid] ~= nil then
			return map[tid]
		else
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
			return template
		end
	end

	-- 需要缓存的模板
	-- 一次性的不需要缓存，根据统计数据进行增加
	local templateData = {}
	local dataCachedItems = {"Profession", "Actor", "State", "Monster", "Npc", "Mine", "Money", "Item",
							 "Service", "Map", "Reputation", "Trans", "CountGroup", "TeamRoomConfig"}

	def.static("string", "number", "=>", "table").GetTemplate = function(name, id)
		EfficiencyTemplateDataRegist(name, id)
		local map = nil
		if isCachedAll and templateData[name] == nil then 
			templateData[name] = {} 
		else
			map = templateData[name]
			if map == nil then
				for i,v in ipairs(dataCachedItems) do
					if name == v then
						templateData[name] = {} 
						map = templateData[name]
						break
					end
				end
			end
		end

		return GetTemplateInternal(id, name, map)
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

	
	do -- 特定模板获取接口封装
		def.static("number", "=>", "table").GetSkillTemplate = function(tid)
			return CElementData.GetTemplate("Skill", tid)
		end

		def.static("number", "=>", "table").GetSkillTemplateClone = function(tid)
			local data = GameUtil.GetTemplateData("Skill", tid)
			local template_class = pb_template["Skill"]
			local template = template_class()
			if data ~= nil and string.len(data) > 0 then
				template:ParseFromString(data) 
			end

			return template
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
			return CElementData.GetTemplate("SpecialId", tid)
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

		def.static("number", "=>", "table").GetManualTotalRewardTemplate = function(tid)
			return CElementData.GetTemplate("ManualTotalReward", tid)
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

		def.static("number", "=>", "table").GetExecutionUnitTemplate = function(tid)
			return CElementData.GetTemplate("ExecutionUnit", tid)
		end

		def.static("number", "=>", "table").GetFunTemplate = function(tid)
			return CElementData.GetTemplate("Fun", tid)
		end

		def.static("number", "=>", "table").GetSensitiveWordTemplate = function(tid)
			return CElementData.GetTemplate("SensitiveWord", tid)
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
	end


	--[[ =============================================
	=====           模板Tids                     =====
	=================================================]]
	local allTidsData = {}
	local tidCachedItems = {"GuildLevel", "GuildBuildLevel", "GuildPermission", "QuestChapter", "Banner", "Trans", "Instance", "Pet", "AttachedProperty", "Map",
					"TeamRoomConfig"}

	local function GetAllTidInternal(name)
		local map = allTidsData[name]
		if map ~= nil then
			return map
		else
			for i,v in ipairs(tidCachedItems) do
				if name == v then
					allTidsData[name] = {} 
					map = allTidsData[name]
					break
				end
			end

			local tids = GameUtil.GetAllTid(name)
			if map ~= nil then allTidsData[name] = tids end
			return tids
		end
	end

	def.static("string", "=>", "table").GetAllTid = function(name)
		EfficiencyAllTidRegist(name)
		return GetAllTidInternal(name)
	end

	do -- 特定模板获取接口封装
		def.static("=>", "table").GetAllGuildLevel = function()
			return GetAllTidInternal("GuildLevel")
		end

		def.static("=>", "table").GetAllGuildBuildLevel = function()
			return GetAllTidInternal("GuildBuildLevel")
		end

		def.static("=>", "table").GetAllGuildPermission = function()
			return GetAllTidInternal("GuildPermission")
		end

		def.static("=>", "table").GetAllFun = function()
			return GetAllTidInternal("Fun")
		end

		def.static("=>", "table").GetAllWingLevelUp = function()
			return GetAllTidInternal("WingLevelUp")
		end

		def.static("=>", "table").GetAllTeamRoomData = function()
			return GetAllTidInternal("TeamRoomConfig")
		end

		def.static("=>", "table").GetAllQuestChapter = function()
			return GetAllTidInternal("QuestChapter")
		end
		
		def.static("=>", "table").GetAllQuestGroup = function()
			return GetAllTidInternal("QuestGroup")
		end

		def.static("=>", "table").GetAllReputation = function()
			return GetAllTidInternal("Reputation")
		end

		def.static("=>", "table").GetAllHangQuest = function()
			return GetAllTidInternal("HangQuest")
		end

		def.static("=>", "table").GetAllGoods = function()
			return GetAllTidInternal("Goods")
		end

		def.static("=>", "table").GetAllPet = function()
			return GetAllTidInternal("Pet")
		end

		def.static("=>", "table").GetAllAttachedProperty = function()
			return GetAllTidInternal("AttachedProperty")
		end
	end

	--[[ =============================================
	=====           其他数据处理                 =====
	=================================================]]

	-- 不要放在这里，放进对应模块  -- added by Jerry

	--获取属性信息
	def.static("number", "=>", "table").GetPropertyInfoById = function(id)
		local data = {}
		--属性组ID
		local property = CElementData.GetTemplate("AttachedPropertyGenerator", id)
		
		--属性ID
		local fightElement = CElementData.GetAttachedPropertyTemplate(property.FightPropertyId)
		data.Name = fightElement.TextDisplayName
		data.ID = property.Id
		data.FightPropertyId = property.FightPropertyId
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
			data.MinValue = min--property.StarSettings[1].MinValue
			data.MaxValue = max--property.StarSettings[propertyCnt].MaxValue
			data.MaxStar = propertyCnt
		end

		return data
	end

	--获取装备属性信息表 ID为附加属性组生成器ID (AttachedPropertyGroupGeneratorId)
	local EquipAttrInfoMap = {}
	def.static("number", "=>" , "table").GetEquipAttrInfoById = function(id)
		if EquipAttrInfoMap == nil then EquipAttrInfoMap = {} end

		if EquipAttrInfoMap[id] == nil then
			local info = {}
			--附加属性组
			local groupTemplate = CElementData.GetTemplate("AttachedPropertyGroupGenerator", id)
			--附加属性
			for _,v in ipairs(groupTemplate.ConfigData.AttachedPropertyGeneratorConfigs) do
				if v ~= nil then
					local map = CElementData.GetPropertyInfoById(v.Id)
					info[map.ID] = map
				end
       		end	
       		EquipAttrInfoMap[id] = info		 
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
		if PetAllLevelInfo == nil then PetAllLevelInfo = {} end

		if table.nums(PetAllLevelInfo) == 0 then
			local infoTids = CElementData.GetAllTid("PetLevel")
			for i, tid in ipairs(infoTids) do
				local data = CElementData.GetTemplate("PetLevel", tid)
				if data ~= nil then
					if PetAllLevelInfo[data.PetQuality] == nil then
						PetAllLevelInfo[data.PetQuality] = {}
					end
					PetAllLevelInfo[data.PetQuality][data.Level] = data.Experience
				end
			end
		end

		return PetAllLevelInfo[quality][level] or 0
	end

	--[[获取技能&被动技能的描述]]
	def.static("number", "boolean", "=>", "string").GetSkillDesc = function(skillId, bIsTalent)
		local desc = ""

		if bIsTalent then
			local TalentTemplate = CElementData.GetTemplate("Talent", skillId)
			if TalentTemplate then
				desc = TalentTemplate.TalentDescribtion
			end
		else
			local SkillTemplate = CElementData.GetTemplate("Skill", skillId)
			if SkillTemplate then
				desc = SkillTemplate.SkillDescription
			end
		end

		return desc
	end

	--[[获取技能ID 升级等级的数值， 需要遍历]]
	def.static("number", "number", "number", "boolean", "=>", "number").GetSkillLevelUpValue = function(skillId, levelupId, skillLevel, bIsTalent)
		--warn("GetSkillLevelUpValue = ", skillId, levelupId, skillLevel, bIsTalent)
		local result = 0
		local allSkillLevelUp =  CElementData.GetAllTalentOrSkillLevelUpTemplateSimple(bIsTalent)
		local Tid = 0
		for tid, temp in ipairs( allSkillLevelUp ) do
			if temp.SkillId == skillId and temp.LevelUpId == levelupId then
				Tid = tid
				break
			end
		end
		if Tid > 0 then 
			local templateName = bIsTalent and "TalentLevelUp" or "SkillLevelUp"
			local temp = CElementData.GetTemplate( templateName,Tid)
			if temp ~= nil and temp.LevelDatas[skillLevel] ~= nil  then 
				result = temp.LevelDatas[skillLevel].Value
			end
		end

		return result
	end

	local function ReplaceKeywords(str, key, repl)
		if string.find(key, "%%") then
			key = string.gsub(key, "%%", "%%%%")
		end

		if string.find(repl, "%%") then
			repl = string.gsub(repl, "%%", "%%%%")
		end

		local keyword = "<"..key..">"
		return string.gsub(str, keyword, repl)
	end

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
					if LegendaryGroupInfoMap[id][v.TalentID] == nil then
						map.MinLv = map.Level
						map.MaxLv = map.Level
						LegendaryGroupInfoMap[id][v.TalentID] = map
					else
						local old = LegendaryGroupInfoMap[id][v.TalentID]
						old.MinLv = math.min(old.MinLv ,map.Level)
						old.MaxLv = math.max(old.MaxLv ,map.Level)
					end
				end
			end

			local keyword = "talentlevelup"
			for k, skillInfo in pairs(LegendaryGroupInfoMap[id]) do
				if skillInfo.MinLv ~= skillInfo.MaxLv then
					skillInfo.LvDesc = string.format(StringTable.Get(31339), skillInfo.MinLv, skillInfo.MaxLv)
					
					local parsedText = CElementData.GetSkillDesc(skillInfo.ID, true)
					local keysMap = DynamicText.ParseDescKeys(parsedText, keyword)
					-- 多重替换
					-- Integer fixed replace
					for i, v in ipairs(keysMap.IntegerKeys) do
						local replaceStr = ""
						local levelupId = tonumber( string.match(v, _G.Regexp4Num) )
						for lv = skillInfo.MinLv, skillInfo.MaxLv do
							local val = CElementData.GetSkillLevelUpValue(skillInfo.ID, levelupId, lv, true)
							val = math.abs(val)
							if replaceStr ~= "" then replaceStr = replaceStr .. "/" end
							replaceStr = replaceStr .. fixFloatStr(val, 2)  
						end
						parsedText = ReplaceKeywords(parsedText, v, replaceStr)
					end

					-- Percentage fixed replace
					for i, v in ipairs(keysMap.PercentageKeys) do
						local replaceStr = ""
						local levelupId = tonumber( string.match(v, _G.Regexp4Num) )
						for lv = skillInfo.MinLv, skillInfo.MaxLv do
							local val = CElementData.GetSkillLevelUpValue(skillInfo.ID, levelupId, lv, true) * 100
							val = math.abs(val)
							local strValue = string.format("%s%%", fixFloatStr(val, 2, true))
							if replaceStr ~= "" then replaceStr = replaceStr .. "/" end
							replaceStr = replaceStr .. strValue
						end
						parsedText = ReplaceKeywords(parsedText, v, replaceStr)
					end
					skillInfo.SkillDesc = parsedText
				else
					skillInfo.LvDesc = string.format(StringTable.Get(31338), skillInfo.Level)
					skillInfo.SkillDesc = skillInfo.Desc
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

		if table.nums(InheritGroupInfoMap) == 0 then
			local infoTids = CElementData.GetAllTid("EquipInherit")
			for i, tid in ipairs(infoTids) do
				local template = CElementData.GetTemplate('EquipInherit', tid)
				if template ~= nil then
					if InheritGroupInfoMap[template.ItemLevel] == nil then InheritGroupInfoMap[template.ItemLevel] = {} end
					local infoMap = InheritGroupInfoMap[template.ItemLevel]
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

						infoMap[inheritData.InforceLevel] = data
					end
				end
			end
		end

		return (InheritGroupInfoMap[itemLevel] ~= nil and InheritGroupInfoMap[itemLevel][inforceLv]) and
		        InheritGroupInfoMap[itemLevel][inforceLv] or nil
	end


	--附魔信息表
	local EquipEnchantInfoMap = {}
	def.static("number", "=>", "table").GetEquipEquipEnchantInfoMapByItemID = function(id)
		local itemTemplate = CElementData.GetTemplate("Item", id)
		if itemTemplate == nil then return nil end
		local EItemEventType = require "PB.data".EItemEventType	--物品使用 类型
		if EItemEventType.ItemEvent_EquipEnchant ~= itemTemplate.EventType1 then return nil end

		if EquipEnchantInfoMap == nil then EquipEnchantInfoMap = {} end

		local EnchantId = tonumber(itemTemplate.Type1Param1)
		local AttachedPropertyGroupGeneratorId = tonumber(itemTemplate.Type1Param2)

		if table.nums(EquipEnchantInfoMap) == 0 then
			local allIds = CElementData.GetAllTid("Enchant")
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
		local valDesc = nil
		if propertyInfo.MinValue == propertyInfo.MaxValue then
			valDesc = string.format(StringTable.Get(31340), propertyInfo.MinValue)
		else
			valDesc = string.format(StringTable.Get(31337), propertyInfo.MinValue, propertyInfo.MaxValue)
		end
		propertyInfo.ValueDesc = valDesc

		local result = {}
		result.Enchant = EquipEnchantInfoMap[EnchantId] or nil
		result.Property = propertyInfo

		return result
	end

	--强化石信息表
	local EquipInforceInfoMap = {}
	def.static("number", "=>", "table").GetEquipInforceInfoMap = function(equipInforceId)
		if EquipInforceInfoMap == nil then EquipInforceInfoMap = {} end

		if table.nums(EquipInforceInfoMap) == 0 then
			local allIds = CElementData.GetAllTid("EquipInforce")
			for i, tid in ipairs(allIds) do
				local template = CElementData.GetTemplate("EquipInforce", tid)
				if template ~= nil then
					local data = {}
					data.ID = equipInforceId
					data.Name = template.Name
					data.InforceDatas = {}
					data.SafeLevel = 0
					for _, inforceData in ipairs(template.InforceDatas) do
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

	--获取技能，被动技能的一个结构
	def.static('number', 'number', 'boolean', '=>', 'table').GetSkillInfoByIdAndLevel = function(id, level, bIsTalent)
		local template = CElementData.GetTemplate("Talent", id)
		if template == nil then return nil end
		
		local info = {}
		info.ID = id
		info.Name = template.Name
		info.Level = level
		local DynamicText = require "Utility.DynamicText"
		info.Desc = DynamicText.ParseSkillDescText(id, level, bIsTalent)
		
		local propertyId = template.ExecutionUnits[1].Event.AddAttachedProperty.Id
		local fightElement = CElementData.GetAttachedPropertyTemplate(propertyId)
		info.PropertyName = fightElement ~= nil and fightElement.TextDisplayName or ""

		return info
	end

	-- 预处理数据时使用，不会因为该数据设置了缓存选项 而在预处理阶段就将所有数据缓存下来   -- added by Jerry
	local function GetTemplateWithoutCache(name, id)
		return GetTemplateInternal(id, name, nil)
	end

	--任务信息缓存，只保留有用信息
	local AllQuest = nil
	def.static("number", "=>", "table").GetQuestTemplateSimple = function (tid)
		if AllQuest == nil then
			AllQuest = {}
		 	local ids = CElementData.GetAllTid("Quest")
			for _,v in pairs(ids) do
				if v then
					local tmp = GetTemplateWithoutCache("Quest", v)
					AllQuest[v] = { Id = tmp.Id, IsSubQuest = tmp.IsSubQuest, IsRepeated = tmp.IsRepeated, Type = tmp.Type, CountGroupTid = tmp.CountGroupTid }
				end
			end
		end
		return AllQuest[tid]
	end

	def.static("=>", "table").GetAllQuestTemplateSimple = function ()
		if AllQuest == nil then
			AllQuest = {}
		 	local ids = CElementData.GetAllTid("Quest")
			for _,v in pairs(ids) do
				if v then
					local tmp = GetTemplateWithoutCache("Quest", v)
					AllQuest[v] = { Id = tmp.Id, IsSubQuest = tmp.IsSubQuest, IsRepeated = tmp.IsRepeated, Type = tmp.Type, CountGroupTid = tmp.CountGroupTid }
				end
			end
		end
		return AllQuest
	end

	--TalentLevelUp缓存，只保留有用信息
	local AllTalentLevelUp = {}
	local AllSkillLevelUp = {} 
	def.static("boolean","=>", "table").GetAllTalentOrSkillLevelUpTemplateSimple = function (isTalent)
		local data = isTalent and AllTalentLevelUp or AllSkillLevelUp
		if table.nums(data) == 0 then
			local templateName = isTalent and "TalentLevelUp" or "SkillLevelUp"
		 	local ids = CElementData.GetAllTid(templateName)
			for _,v in pairs(ids) do
				if v then
					local tmp = GetTemplateWithoutCache(templateName, v)
					data[v] = { SkillId = tmp.SkillId, LevelUpId = tmp.LevelUpId }
				end
			end
		end

		return data
	end

	--[[ =============================================
	=====              数据清理                  =====
	=================================================]]	

	def.static().ClearAll = function()
		templateData = {}
		allTidsData = {}

		AllQuest = nil
		AllTalentLevelUp = {} 
		AllSkillLevelUp = {} 
		EquipAttrInfoMap = nil
		PetAllGuideInfo = nil
		LegendaryGroupInfoMap = nil
		PetAllLevelInfo = nil
		InheritGroupInfoMap = nil
		EquipEnchantInfoMap = nil
		EquipInforceInfoMap = nil
	end
end

CElementData.Commit()
return CElementData