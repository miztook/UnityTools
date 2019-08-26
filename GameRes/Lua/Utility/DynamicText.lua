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

	local function WholeWordMatch(words, key)
		return (string.find(words, key) and string.sub(words,1,string.len(key)) == key)
	end

	def.static("string", "string", "=>", "table").ParseDescKeys = function (parsedText, keyword)
		local keysMap = {}
		
		if parsedText ~= "" then
			--整数处理
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, _G.Regexp4Int) do
					local isFloat = string.find(parsedText, k .. "%%")
					if (not isFloat) and WholeWordMatch(k, keyword) then
						table.insert(keys, k)
					end
				end
				keysMap.IntegerKeys = keys
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			do
				local keys = {}
				for k,v in string.gmatch(parsedText, _G.Regexp4Percent) do
					if WholeWordMatch(k, keyword) then
						table.insert(keys, k)
					end
				end
				keysMap.PercentageKeys = keys
			end
		else
			keysMap.IntegerKeys = {}
			keysMap.PercentageKeys = {}
		end

		return keysMap
	end

	--[[技能描述动态字符串解析]]
	def.static("number", "number", "boolean", "=>", "string").ParseSkillDescText = function (skillId, skillLevel, bIsTalent)
		local parsedText = CElementSkill.GetSkillDesc(skillId, bIsTalent)
		return DynamicText.ParseSkillSpecial(parsedText, skillId, skillLevel, bIsTalent)
	end

	--[[纹章描述动态字符串解析]]
	def.static("number", "number", "=>", "string").ParseRuneDescText = function (runeId, runeLevel)
		local runeTemplate = CElementData.GetTemplate("Rune", runeId)
		if runeTemplate == nil then return "" end
		return DynamicText.ParseRuneDescSpecial(runeTemplate.RuneDescription, runeId, runeLevel)
	end

	--[[技能描述动态字符串解析 str -> str]]  
	def.static("string", "number", "number", "boolean", "=>", "string").ParseSkillSpecial = function (parsedText, skillId, skillLevel, bIsTalent)
		local curSkillKeyword = bIsTalent and "talentlevelup" or "levelup"
		local keys = DynamicText.ParseDescKeys(parsedText, curSkillKeyword)

		--整数处理
		do
			for k,v in pairs(keys.IntegerKeys) do
				local levelupId = tonumber( string.match(v, _G.Regexp4Num) )
				local val = CElementSkill.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent)
				val = math.abs(val)
				local replStr = fixFloatStr(val, 2)
				parsedText = Match(parsedText, v, replStr)
			end
		end
		--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
		do
			for k,v in pairs(keys.PercentageKeys) do
				local levelupId = tonumber( string.match(v, _G.Regexp4Num) )
				local val = CElementSkill.GetSkillLevelUpValue(skillId, levelupId, skillLevel, bIsTalent) * 100
				val = math.abs(val)
				local replStr = fixFloatStr(val, 2, true)
				replStr = string.format("%s%%", replStr)
				parsedText = Match(parsedText, v, replStr)
			end
		end

		return parsedText
	end

	--[[纹章描述动态字符串解析]]
	def.static("string", "number", "number", "=>", "string").ParseRuneDescSpecial = function (parsedText, runeId, runeLevel)
		local runeTemplate = CElementData.GetTemplate("Rune", runeId)
		if runeTemplate == nil then return parsedText end

		if parsedText ~= "" then
			local RuneLevelupKey = "runelevelup"
			local keys = DynamicText.ParseDescKeys(parsedText, RuneLevelupKey)
			--整数处理
			for k,v in pairs(keys.IntegerKeys) do
				local levelupId = tonumber( string.match(v, _G.Regexp4Num) )
				local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel)
				val = math.abs(val)

				local replStr = fixFloatStr(val, 2)
				parsedText = Match(parsedText, v, replStr)
			end
			--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
			for k,v in pairs(keys.PercentageKeys) do
				local levelupId = tonumber( string.match(v, _G.Regexp4Num) )
				local val = CElementSkill.GetRuneLevelUpValue(runeId, levelupId, runeLevel) * 100
				val = math.abs(val)
				local replStr = fixFloatStr(val, 2, true)
				replStr = string.format("%s%%", replStr)
				parsedText = Match(parsedText, v, replStr)
			end
		end

		return parsedText
	end

	--[[状态描述动态字符串解析]]
	def.static("string", "table", "=>", "string").ParseBuffStateDescText = function (parsedText, buffInfo)
		if buffInfo.Skill then
			parsedText = DynamicText.ParseSkillSpecial(parsedText, buffInfo.Skill.ID, buffInfo.Skill.Level, false)
		end
		if buffInfo.Talent then
			parsedText = DynamicText.ParseSkillSpecial(parsedText, buffInfo.Talent.ID, buffInfo.Talent.Level, true)
		end
		if buffInfo.Rune then
			parsedText = DynamicText.ParseRuneDescSpecial(parsedText, buffInfo.Rune.ID, buffInfo.Rune.Level)
		end
		parsedText = DynamicText.ParseAttr(parsedText, buffInfo.Attr)

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
			for k,v in string.gmatch(parsedText, _G.Regexp4Int) do
				if string.find(k, AttrKey) and string.sub(k,1,string.len(AttrKey)) == AttrKey then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local attrId = tonumber( string.match(v, _G.Regexp4Num) )
				local val = GetAttrValueById(attrId)
				val = math.abs(val)
				local replStr = fixFloatStr(val, 2)
				parsedText = Match(parsedText, v, replStr)
			end
		end
		--浮点数 至多保留两位 显示：【乘以100，并且加上% 字符】
		do
			local keys = {}
			for k,v in string.gmatch(parsedText, _G.Regexp4Percent) do
				if string.find(k, AttrKey) and string.sub(k,1,string.len(AttrKey)) == AttrKey then
					table.insert(keys, k)
				end
			end

			for k,v in pairs(keys) do
				local attrId = tonumber( string.match(v, _G.Regexp4Num) )
				local val = GetAttrValueById(attrId) * 100
				val = math.abs(val)
				local replStr = fixFloatStr(val, 2, true)
				replStr = string.format("%s%%", replStr)
				parsedText = Match(parsedText, v, replStr)
			end
		end

		return parsedText
	end
end

return DynamicText.Commit()