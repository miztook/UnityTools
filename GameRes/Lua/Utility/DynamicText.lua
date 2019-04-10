--[[
	动态文本
	在文本中嵌入特定的字符串，根据运行时游戏环境实际情况进行字符串替换，实现内容动态变化的文本
	不同的模块规则不同：

	=============================================
	对话中关于玩家的可变字符配置方法：
	配置方法 {关键字}
	关键字如下：
	Name	玩家名	
	Class	职业名 重剑士，剑斗士，祭司，弓箭手
	Race	种族 人类，卡斯塔尼克，艾琳，精灵
	HeShe	性别 他，她
	例如：
	{Name}，你好！ 
	--> 包子大人，你好 （“包子大人”为当前主角名字）
	
	=============================================
	技能描述：
	配置方式 <levelup5>
	关键字 
	levelup
	例如：
	4段攻击，对身前敌人共造成<color=#5aa2ffff><levelup5>+<levelup6>%</color>攻击力的伤害。
	--> 4段攻击，对身前敌人共造成500+10%攻击力的伤害。 (500、10为技能升级表中配置的数据)

	=============================================
	TODO: 增加其他规则描述
]]


KEYWORDS_LEVELUP={
	'levelup',
	'talentlevelup',
	'runelevelup',
}


local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CElementSkill = require "Data.CElementSkill"

local DynamicText = Lplus.Class("DynamicText")
do
	local def = DynamicText.define
	
	local function ReplaceSpecialWord(str)
		local resultStr = str
		if string.find(str, "%%") then
			resultStr = string.gsub(str, "%%", "%%%%")
		end

		return resultStr
	end

	local function Match(str, key, repl)
		key = ReplaceSpecialWord(key)
		repl = ReplaceSpecialWord(repl)

		local keyword = "<"..key..">"
		
		return string.gsub(str, keyword, repl)
	end

	--[[对话相关动态字符串解析]]
	def.static("string", "=>", "string").ParseDialogueText = function (srcText)
		local parsedText = ""

		if srcText and srcText ~= "" then
			parsedText = srcText
			local function replace(match)
		        local info = game._HostPlayer._InfoData
		        if match == EnumDef.SpecialWordsOfDialogue.Name then
		            return "<color=#92EF50FF>"..info._Name.."</color>"
		        elseif match == EnumDef.SpecialWordsOfDialogue.Class then
		            return StringTable.Get(528 + info._Prof)
		        elseif match == EnumDef.SpecialWordsOfDialogue.Race then
		            return StringTable.Get(524 + info._Prof)
		        elseif match == EnumDef.SpecialWordsOfDialogue.HeShe then
		            if info._Gender == EnumDef.Gender.Male then
		                return StringTable.Get(523)
		            else
		                return StringTable.Get(524)
		            end
		        end
			end

			parsedText = string.gsub(parsedText, "{(%w+)}", replace)
		end

		return parsedText
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
		local SkillLevelupTemplateKey = "SkillLevelUp"
		local TalentLevelupTemplateKey = "TalentLevelUp"

		local result = 0
		local allSkillLevelUp = nil

		if bIsTalent then
			allSkillLevelUp =  GameUtil.GetAllTid( TalentLevelupTemplateKey )
		else
			allSkillLevelUp = GameUtil.GetAllTid( SkillLevelupTemplateKey )
		end

		local levelUpTemplate = nil
		for i, tid in ipairs( allSkillLevelUp ) do
			if bIsTalent then
				local talentLevelUpTemplate = CElementData.GetTemplate(TalentLevelupTemplateKey, tid)
				if talentLevelUpTemplate.SkillId == skillId and talentLevelUpTemplate.LevelUpId == levelupId then
					levelUpTemplate = talentLevelUpTemplate
					break
				end
			else
				local skillLevelUpTemplate = CElementData.GetTemplate(SkillLevelupTemplateKey, tid)
				if skillLevelUpTemplate.SkillId == skillId and skillLevelUpTemplate.LevelUpId == levelupId then
					levelUpTemplate = skillLevelUpTemplate
					break
				end
			end
		end

		if levelUpTemplate ~= nil then
			if levelUpTemplate.LevelDatas[skillLevel] ~= nil then
				result = levelUpTemplate.LevelDatas[skillLevel].Value
			end
		end

		if result == 0 then
			-- warn("-----缺少正确的技能升级数据以支撑UI显示")
		end

		return result
	end

	--[[技能描述动态字符串解析]]
	def.static("number", "number", "boolean", "=>", "string").ParseSkillDescText = function (skillId, skillLevel, bIsTalent)
		local SkillLevelupKey = "levelup"
		local TalentLevelupKey = "talentlevelup"
		local SkillLevelupTemplateKey = "SkillLevelUp"
		local TalentLevelupTemplateKey = "TalentLevelUp"

		local parsedText = DynamicText.GetSkillDesc(skillId, bIsTalent)

		if parsedText ~= "" then
			local curSkillKeyword = ""
			local curSkillTemplateKey = ""
			if bIsTalent then
				curSkillKeyword = TalentLevelupKey
				curSkillTemplateKey = TalentLevelupTemplateKey
			else
				curSkillKeyword = SkillLevelupKey
				curSkillTemplateKey = SkillLevelupTemplateKey
			end

			--整数处理
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
					if string.find(k, curSkillKeyword) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = DynamicText.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent)
					val = math.abs(val)
					local replStr = fmtVal2Str( val )
					parsedText = Match(parsedText, v, replStr)
				end
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
					if string.find(k, curSkillKeyword) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = DynamicText.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent) * 100
					val = math.abs(val)
					local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
					replStr = string.format("%s%%", replStr)
					parsedText = Match(parsedText, v, replStr)
				end
			end
		end

		return parsedText
	end

	--[[技能描述动态字符串解析 -- 返回 数据类型-索引数据]]
	def.static("number", "number", "boolean", "=>", "table").GetParseSkillDescTextKeyValue = function (skillId, skillLevel, bIsTalent)
		local reslutTable = { Integer={}, Percentage={}}

		local SkillLevelupKey = "levelup"
		local TalentLevelupKey = "talentlevelup"
		local SkillLevelupTemplateKey = "SkillLevelUp"
		local TalentLevelupTemplateKey = "TalentLevelUp"

		local parsedText = DynamicText.GetSkillDesc(skillId, bIsTalent)

		if parsedText ~= "" then
			local curSkillKeyword = ""
			local curSkillTemplateKey = ""
			if bIsTalent then
				curSkillKeyword = TalentLevelupKey
				curSkillTemplateKey = TalentLevelupTemplateKey
			else
				curSkillKeyword = SkillLevelupKey
				curSkillTemplateKey = SkillLevelupTemplateKey
			end

			--整数处理
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
					if string.find(k, curSkillKeyword) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = DynamicText.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent)
					val = math.abs(val)
					local replStr = fmtVal2Str( val )
					parsedText = Match(parsedText, v, replStr)

					local info = {}
					info.Key = v
					info.Value = val
					table.insert(reslutTable.Integer, info)
				end
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
					if string.find(k, curSkillKeyword) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = DynamicText.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent) * 100
					val = math.abs(val)
					local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
					replStr = string.format("%s%%", replStr)
					parsedText = Match(parsedText, v, replStr)

					local info = {}
					info.Key = v
					info.Value = val
					table.insert(reslutTable.Percentage, info)
				end
			end
		end

		return reslutTable
	end

	--[[技能描述动态字符串解析 -- 返回 数据类型-索引数据]]
	def.static("number", "number", "boolean", "table", "=>", "string").ExchangeParseSkillDescText = function (skillId, skillLevel, bIsTalent, info)
		-- warn("ExchangeParseSkillDescText = ", skillId, skillLevel, bIsTalent, table.nums(info))
		local SkillLevelupKey = "levelup"
		local TalentLevelupKey = "talentlevelup"
		local SkillLevelupTemplateKey = "SkillLevelUp"
		local TalentLevelupTemplateKey = "TalentLevelUp"

		local parsedText = DynamicText.GetSkillDesc(skillId, bIsTalent)

		if parsedText ~= "" then
			local curSkillKeyword = ""
			local curSkillTemplateKey = ""
			if bIsTalent then
				curSkillKeyword = TalentLevelupKey
				curSkillTemplateKey = TalentLevelupTemplateKey
			else
				curSkillKeyword = SkillLevelupKey
				curSkillTemplateKey = SkillLevelupTemplateKey
			end

			--整数处理
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
					if string.find(k, curSkillKeyword) then
						table.insert(keys, k)
					end
				end
				local index = 1
				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local replStr = info.Integer[index].Value
					-- warn("replStrAAAAAAAAAAAA = ", replStr)
					index = index + 1
					parsedText = Match(parsedText, v, replStr)
					-- warn("parsedText = ", parsedText)
				end
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
					if string.find(k, curSkillKeyword) then
						table.insert(keys, k)
					end
				end

				local index = 1
				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local replStr = info.Percentage[index].Value
					-- warn("replStrBBBBBBBBBBBB = ", replStr)
					index = index + 1
					parsedText = Match(parsedText, v, replStr)
				end
			end
		end

		return parsedText
	end

	--[[纹章描述动态字符串解析]]
	def.static("number", "number", "=>", "string").ParseRuneDescText = function (runeId, runeLevel)
		local runeTemplate = CElementData.GetTemplate("Rune", runeId)
		if runeTemplate == nil then return "" end

		local RuneLevelupKey = "runelevelup"
		local parsedText = runeTemplate.RuneDescription
		if parsedText ~= "" then
			--整数处理
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
					if string.find(k, RuneLevelupKey) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel)
					val = math.abs(val)
					local replStr = fmtVal2Str( val )
					parsedText = Match(parsedText, v, replStr)
				end
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
					if string.find(k, RuneLevelupKey) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel) * 100
					val = math.abs(val)
					local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
					replStr = string.format("%s%%", replStr)
					parsedText = Match(parsedText, v, replStr)
				end
			end
		end

		return parsedText
	end

	--[[纹章描述动态字符串解析]]
	def.static("number", "number", "string", "=>", "string").ParseRuneDescSpecial = function (runeId, runeLevel, parsedText)
		local runeTemplate = CElementData.GetTemplate("Rune", runeId)
		if runeTemplate == nil then return "" end

		local RuneLevelupKey = "runelevelup"
		-- local parsedText = runeTemplate.RuneDescription
		if parsedText ~= "" then
			--整数处理
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
					if string.find(k, RuneLevelupKey) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel)
					val = math.abs(val)
					local replStr = fmtVal2Str( val )
					parsedText = Match(parsedText, v, replStr)
				end
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
					if string.find(k, RuneLevelupKey) then
						table.insert(keys, k)
					end
				end

				for k,v in pairs(keys) do
					local levelupId = tonumber( string.match(v, "[0-9]+") )
					local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel) * 100
					val = math.abs(val)
					local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
					replStr = string.format("%s%%", replStr)
					parsedText = Match(parsedText, v, replStr)
				end
			end
		end

		return parsedText
	end

	--[[状态描述动态字符串解析]]
	def.static("string", "table", "=>", "string").ParseBuffStateDescText = function (parsedText, buffInfo)
		if buffInfo.Skill then
			parsedText = DynamicText.ParseSkill(parsedText, buffInfo.Skill.ID, buffInfo.Skill.Level, false)
		end
		if buffInfo.Talent then
			parsedText = DynamicText.ParseSkill(parsedText, buffInfo.Talent.ID, buffInfo.Talent.Level, true)
		end
		if buffInfo.Rune then
			parsedText = DynamicText.ParseRune(parsedText, buffInfo.Rune.ID, buffInfo.Rune.Level)
		end
		parsedText = DynamicText.ParseAttr(parsedText, buffInfo.Attr)

		return parsedText
	end
	
	--[[技能描述动态字符串解析 str -> str]]  
	def.static("string", "number", "number", "boolean", "=>", "string").ParseSkill = function (parsedText, skillId, skillLevel, bIsTalent)
		local SkillLevelupKey = "levelup"
		local TalentLevelupKey = "talentlevelup"
		local SkillLevelupTemplateKey = "SkillLevelUp"
		local TalentLevelupTemplateKey = "TalentLevelUp"

		local curSkillKeyword = ""
		local curSkillTemplateKey = ""
		if bIsTalent then
			curSkillKeyword = TalentLevelupKey
			curSkillTemplateKey = TalentLevelupTemplateKey
		else
			curSkillKeyword = SkillLevelupKey
			curSkillTemplateKey = SkillLevelupTemplateKey
		end

		--整数处理
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
				if string.find(k, curSkillKeyword) and string.sub(k,1,string.len(curSkillKeyword)) == curSkillKeyword then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local levelupId = tonumber( string.match(v, "[0-9]+") )
				local val = DynamicText.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent)
				val = math.abs(val)
				local replStr = fmtVal2Str( val )
				parsedText = Match(parsedText, v, replStr)
			end
		end
		--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
				if string.find(k, curSkillKeyword) and string.sub(k,1,string.len(curSkillKeyword)) == curSkillKeyword then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local levelupId = tonumber( string.match(v, "[0-9]+") )
				local val = DynamicText.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent) * 100
				val = math.abs(val)
				local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
				replStr = string.format("%s%%", replStr)
				parsedText = Match(parsedText, v, replStr)
			end
		end

		return parsedText
	end
	--[[纹章描述动态字符串解析 str -> str]]  
	def.static("string", "number", "number", "=>", "string").ParseRune = function (parsedText, runeId, runeLevel)
		local RuneLevelupKey = "runelevelup"

		--整数处理
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
				if string.find(k, RuneLevelupKey) and string.sub(k,1,string.len(RuneLevelupKey)) == RuneLevelupKey then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local levelupId = tonumber( string.match(v, "[0-9]+") )
				local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel)
				val = math.abs(val)
				local replStr = fmtVal2Str( val )
				parsedText = Match(parsedText, v, replStr)
			end
		end
		--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
				if string.find(k, RuneLevelupKey) and string.sub(k,1,string.len(RuneLevelupKey)) == RuneLevelupKey then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local levelupId = tonumber( string.match(v, "[0-9]+") )
				local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel) * 100
				val = math.abs(val)
				local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
				replStr = string.format("%s%%", replStr)
				parsedText = Match(parsedText, v, replStr)
			end
		end

		return parsedText
	end
	--[[属性描述动态字符串解析 str -> str]]  
	def.static("string", "table", "=>", "string").ParseAttr = function (parsedText, attrInfo)
		local AttrKey = "attr"

		local function GetAttrValueById( attrId )
			local nRet = 0
			for i,v in ipairs( attrInfo ) do
				if v.Key == attrId then
					nRet = v.Value
					break
				end
			end

			return nRet
		end

		--整数处理
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+)") do
				if string.find(k, AttrKey) and string.sub(k,1,string.len(AttrKey)) == AttrKey then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local attrId = tonumber( string.match(v, "[0-9]+") )
				local val = GetAttrValueById(attrId)
				val = math.abs(val)
				local replStr = fmtVal2Str( val )
				parsedText = Match(parsedText, v, replStr)
			end
		end
		--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, "([a-zA-Z]+[0-9]+\%%)") do
				if string.find(k, AttrKey) and string.sub(k,1,string.len(AttrKey)) == AttrKey then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local attrId = tonumber( string.match(v, "[0-9]+") )
				local val = GetAttrValueById(attrId) * 100
				val = math.abs(val)
				local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
				replStr = string.format("%s%%", replStr)
				parsedText = Match(parsedText, v, replStr)
			end
		end

		return parsedText
	end
end

return DynamicText.Commit()