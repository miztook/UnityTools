local Lplus = require "Lplus"
local CUIMan = Lplus.ForwardDeclare("CUIMan")
local template = require "PB.Template"
local CElementData = require "Data.CElementData"
local bit = require "bit"

local RichTextTools = Lplus.Class("RichTextTools")
local def = RichTextTools.define

--材料够不够的颜色显示
def.static("string","boolean","=>", "string").GetNeedColorText = function(str, bEnough)
	local index = 0
	if bEnough then
		index = 1
	end
	local color_code = EnumDef.NeedColorHexStr[index]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

--<color=#FF0000>文字内容</color> Quality2ColorHexStr
def.static("string","number","=>", "string").GetQualityText = function(str,quality)
	local color_code = EnumDef.Quality2ColorHexStr[quality]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

def.static("string","number","=>", "string").GetAttrColorText = function(str,star)
    local Star2ColorHexStr = 
    {
        [0] = EnumDef.Quality2ColorHexStr[0],--ffffff
        [1] = EnumDef.Quality2ColorHexStr[0],--ffffff
        [2] = EnumDef.Quality2ColorHexStr[5],--"E6870C", --橙E6870C
    }
	local color_code = Star2ColorHexStr[star]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

def.static('string', 'boolean', '=>', "string").GetOnlineColorHexText = function(str, bOnline)
	local index = 0
	if bOnline then
		index = 1
	end
	local color_code = EnumDef.OnlineColorHexStr[index]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

def.static("number","=>","string").GetRuneColorText = function(star)
    local Star2ColorHexStr = 
    {
        [1] = EnumDef.Quality2ColorHexStr[2], --蓝097EE9
        [2] = EnumDef.Quality2ColorHexStr[3], --紫7E33EF
        [3] = EnumDef.Quality2ColorHexStr[5], --橙E6870C
    }
    star = math.modf( (star - 1) / 3 )
	local color_code = Star2ColorHexStr[star + 1]
    local level = ""
	if star == 0 then
		level =  StringTable.Get(155)
	elseif star == 1 then
		level = StringTable.Get(156)
	elseif star == 2 then
		level =StringTable.Get(157)
	else
		level = StringTable.Get(155)		
	end
	return "<color=#" .. color_code ..">" ..level .."</color>"
end

def.static("string","number","=>", "string").GetTopPateColorText = function(str,index)
	local color_code = EnumDef.TopPateColorHexStr[index]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

def.static("string","number","=>", "string").GetQuestTypeColorText = function(str,index)
	local color_code = EnumDef.QuestColorHexStr[index]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

def.static("string","=>", "string").GetUnavailableColorText = function(str)
	return "<color=#FF0000>" ..str .."</color>"
end

def.static("string", "=>", "string").GetAvailableColorText = function(str)
	return "<color=#5CBE37>" ..str .."</color>"
end

def.static("string","number","=>", "string").GetDailyQuestLuckColorText = function(str,index)
	local color_code = EnumDef.DailyQuestLuckColor[index]
	return "<color=#" .. color_code ..">" ..str .."</color>"
end

--公会名字富文本(待定)
def.static("string", "boolean", "=>", "string").GetGuildNameRichText = function (guildName, isGText)
    local richText = ""
    if isGText then 
        richText = "[l]#41C721 "..guildName.."[-]"
    else
        richText = "<color=#41C721>"..guildName.."</color>"
    end
    return richText
end

--HostPlayer名字富文本
def.static("boolean", "=>", "string").GetHostPlayerNameRichText = function (isGText)
    local richText = game._HostPlayer._InfoData._Name
    if isGText then 
        richText = "[l]#41C721 "..richText.."[-]"
    else
        richText = "<color=#41C721>"..richText.."</color>"
    end
    return richText
end

--ElsePlayer名字富文本
def.static("string", "boolean", "=>", "string").GetElsePlayerNameRichText = function (elsePlayerName, isGText)
    local richText = ""
    if isGText then 
        richText = "[l]#72B4FF "..elsePlayerName.."[-]"
    else
        richText = "<color=#72B4FF>"..elsePlayerName.."</color>"
    end
    return richText
end

--物品名字富文本
def.static("number", "number", "boolean", "=>", "string").GetItemNameRichText = function(tid, count, isGText)
    local itemTemplate = CElementData.GetItemTemplate(tid)
    if itemTemplate == nil then warn("获取物品名称错误，没有该物品", tid) return "" end
    local richText = ""
    if isGText then
        if count > 1 then
            if itemTemplate.InitLevel > 0 then
                richText = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." ["..itemTemplate.TextDisplayName..string.format(StringTable.Get(10714), itemTemplate.InitLevel).."][-]".." x "..count
            else
                richText = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." ["..itemTemplate.TextDisplayName.."][-]".." x "..count
            end
        else
            if itemTemplate.InitLevel > 0 then
                richText = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." ["..itemTemplate.TextDisplayName..string.format(StringTable.Get(10714), itemTemplate.InitLevel).."][-]"
            else
                richText = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." ["..itemTemplate.TextDisplayName.."][-]"
            end
        end
    else
        if count > 1 then
            if itemTemplate.InitLevel > 0 then
                richText = "<color=#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality]..">"..itemTemplate.TextDisplayName..string.format(StringTable.Get(10714), itemTemplate.InitLevel).."</color>".." x "..count
            else
                richText = "<color=#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality]..">"..itemTemplate.TextDisplayName.."</color>".." x "..count
            end
        else
            if itemTemplate.InitLevel > 0 then
                richText = "<color=#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality]..">"..itemTemplate.TextDisplayName..string.format(StringTable.Get(10714), itemTemplate.InitLevel).."</color>"
            else
                richText = "<color=#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality]..">"..itemTemplate.TextDisplayName.."</color>"
            end
        end
    end
    return richText
end

--宠物小名富文本
def.static("number", "string", "boolean", "=>", "string").GetPetNickNameRichText = function(petTid, nickName, isGText)
    local pet_temp = CElementData.GetPetTemplate(petTid)
    if pet_temp == nil then warn("获取宠物信息错误， 没有该宠物，ID： ", petTid) return "" end
    local richText = ""
    if nickName == "" then
        if isGText then
            richText = "[l]#"..EnumDef.Quality2ColorHexStr[pet_temp.Quality]..pet_temp.TextDisplayName.."[-]"
        else
            richText = "<color=#"..EnumDef.Quality2ColorHexStr[pet_temp.Quality]..">"..pet_temp.TextDisplayName.."</color>"
        end
    else
        if isGText then
            richText = "[l]#"..EnumDef.Quality2ColorHexStr[pet_temp.Quality]..nickName.."[-]"
        else
            richText = "<color=#"..EnumDef.Quality2ColorHexStr[pet_temp.Quality]..">"..nickName.."</color>"
        end
    end
    return richText
end

--时间事件富文本
def.static("string", "boolean", "=>", "string").GetEventTimeRichText = function (eventTimeText, isGText)
    local richText = ""
    if isGText then
        richText = "[l]#7F98BE "..eventTimeText.."[-]"
    else
        richText = "<color=#7F98BE>"..eventTimeText.."</color>"
    end
    return richText
end

RichTextTools.Commit()
return RichTextTools