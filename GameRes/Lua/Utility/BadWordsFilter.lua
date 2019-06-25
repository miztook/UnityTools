
--local ret, msg, result = pcall(dofile, "Configs/badwords.lua")
--屏蔽字库
--local tabooWords = result

local CElementData = require "Data.CElementData"
local IDRange = require "PB.Template".SensitiveWord.IDRange
local tabooWords_Name = {}
local tabooWords_Chat = {}

local function charsize(ch)
	if not ch then
		return 0
	elseif ch >240 then
		return 4
	elseif ch >225 then
		return 3
	elseif ch >192 then
		return 2
	else
		return 1
	end
end

local function strlen(str)
	local len = 0
	local aNum = 0 --字母个数
	local hNum = 0 --汉字个数
	local currentIndex = 1
	while currentIndex <= #str do
		local char = string.byte(str,currentIndex)
		local cs = charsize(char)
		currentIndex = currentIndex  + cs
		len = len + 1
		if cs == 1 then
			aNum = aNum + 1
		elseif cs >= 2 then
			hNum = hNum + 1
		end
	end
	return len, aNum, hNum
end

local function makepos(len,from,to)
	if not from and not to then
		return 1,len
	elseif not to then
		if from >0 then
			if from > len then
				return len,len+1
			else
				return from,len
			end
		elseif from <0 then
			if from+len >= 0 and from+len <len then
				return from+len+1,len
			elseif from+len <0 then
				return 1,len
			end
		else
			return 1,len
		end
	elseif not from then
		if to >0 then
			if to <=len then
				return 1,to
			elseif to > len then
				return 1,len
			end
		elseif to <0 then
			if to+len >= 0 and to+len <len then
				return 1,len+to+1
			elseif to + len <0 then
				return 1,len
			end
		else
			error(("bad argument #d to 'from' (number expected,got nil)"))
		end
	else
		if from >0 and to >0 then
			if from <=len and to <= len and from <= to then
				return from,to
			elseif from <= len and to > len then
				return from,len
			else
				error(("invalid pos for list range(expected range(%d-%d),but got (%d-%d)) "):format(1,len,from,to))
			end
		elseif from <0 and to <0 then
			if from+len >= 0 and from+len <len and to+len >= 0 and to+len <len then
				if from <= to then
					return from+len+1,to+len+1
				end
			end
			error(("invalid pos for list range(expected range(%d-%d),but got (%d-%d)) "):format(-len,-1,from,to))
		elseif from >0 and to <0 then
			return from,to+len+1
		elseif from <0 and to >0 then
			if to <= len then
				return from+len+1,to
			else
				return from+len+1,len
			end
			error(("invalid pos for list range got (%d-%d) "):format(from,to))
		else
			error(("invalid pos for list range got (%d-%d) "):format(from,to))
		end
	end
end

local function strsub(str,...)
	local len = strlen(str)
	local from,to = makepos(len,...)
	if from >len or to < from then 
		return "" 
	end
	local frombyte = 1
	local index = 1
	while true do
		if index >= from then
			break
		end
		local char = string.byte(str,frombyte)
		frombyte = frombyte + charsize(char)
		index = index + 1
	end

	index = from
	local byteIndex = frombyte
	while true do
		if index > to then
			break
		end
		local char = string.byte(str,byteIndex)
		byteIndex = byteIndex + charsize(char)
		index = index + 1
	end
	local tobyte = byteIndex
	return string.sub(str,frombyte,tobyte-1)
end

local function tochar(str,pos)
	return strsub(str,pos,pos)
end

local special_characters_list = {"^","$","(",")","%",".","[","]","*","+","-","?"}
local function checkspecialcharacters(str)
	local str_ret = ""
	for i=1,strlen(str) do
		local char = tochar(str,i)
		local need_escape = false
		for _, v in ipairs(special_characters_list) do
			if v == char then
				need_escape = true
				break
			end
		end
		if need_escape then
			str_ret = str_ret .. "\\" .. char
		else
			str_ret = str_ret .. char
		end
	end
	return str_ret
end

local data_id_list = CElementData.GetAllSensitiveWord()

--韩文版名字和聊天屏蔽词分开
if _G.UserLanguageCode == "KR" then
	for i = 1, #data_id_list do
		if data_id_list[i] > IDRange.ChatStart then
			local data = CElementData.GetSensitiveWordTemplate(data_id_list[i])	

			if string.find(data.TextWord, "%%") == nil then
				tabooWords_Chat[#tabooWords_Chat+1] = checkspecialcharacters(data.TextWord)
			end
		else
			local data = CElementData.GetSensitiveWordTemplate(data_id_list[i])	

			if string.find(data.TextWord, "%%") == nil then
				tabooWords_Name[#tabooWords_Name+1] = checkspecialcharacters(data.TextWord)
			end
			
		end
	end
else   --名字和聊天屏蔽词相同
	for i = 1, #data_id_list do
		local data = CElementData.GetSensitiveWordTemplate(data_id_list[i])	

		if string.find(data.TextWord, "%%") == nil then
			tabooWords_Name[#tabooWords_Name+1] = checkspecialcharacters(data.TextWord)
		end
	end
	tabooWords_Chat = tabooWords_Name
end
data_id_list = nil

local function filter(str, caseSensitive, tabooWords)
	local str_ret = ""

	if not caseSensitive then
		local str_old = str
		local str_new = string.gsub(str,"%a",function(letter)
			return string.lower(letter)
		end)
		for _,v in ipairs(tabooWords) do
			local key = string.lower(v)
			str_new = string.gsub(str_new,key,function(s)
				return string.rep("*",strlen(s))
			end)
		end
		for i=1,strlen(str_old) do
			local old_char = tochar(str_old,i)
			local new_char = tochar(str_new,i)
			if new_char ~= "*" then
				str_ret = str_ret .. old_char
			else
				str_ret = str_ret .. "*"
			end
		end
	else
		local str_new = str
		for _,v in ipairs(tabooWords) do
			local key = v
			str_new = string.gsub(str_new,key,function(s)
				return string.rep("*",strlen(s))
			end)
		end
		str_ret = str_new
	end
	return str_ret
end

local debug_4_test = false
-- 测试屏蔽字
if debug_4_test then
	local str_test = "WWW煞笔啊abcCBA傻逼啊sb啊"
	print(strlen("WWW煞笔啊abcCBA傻逼啊sb啊"))
	print("\n测试代码请在上面写")
end


local Lplus = require "Lplus"

local LuaString = Lplus.Class("LuaString")
do
	local def = LuaString.define

	def.static("string","varlist","=>","string").SubStr = function(str,...)
		return strsub(str,...)
	end

	def.static("string","number","=>","string").CharAt = function(str,pos)
		return tochar(str,pos)
	end

	def.static("string","=>","number").Len = function(str)
		return strlen(str)
	end
end
LuaString.Commit()


local Filter = Lplus.Class("Filter")
do
	local def = Filter.define

	def.const("function").FilterName = function(str)
		return filter(str, false, tabooWords_Name)
	end

	def.const("function").FilterChat = function(str)
		return filter(str, false, tabooWords_Chat)
	end

end
Filter.Commit()


return 
{
	LuaString = LuaString,
	Filter = Filter,
}