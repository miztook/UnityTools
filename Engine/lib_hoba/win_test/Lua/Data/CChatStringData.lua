local Lplus = require "Lplus"

local CChatStringData = Lplus.Class("CChatStringData")
local def = CChatStringData.define

local ChatStringList = nil
local ChatEmotionList = nil

def.static("number", "=>", "string").GetChat = function(id)
	if ChatStringList == nil then
		local ret, msg, result = pcall(dofile, _G.ConfigsDir.."chatcfg.lua")
		if ret then
			ChatStringList = result
		else
			warn(msg)
		end
	end
	if ChatStringList == nil then return "nil string" end

	return ChatStringList[id]
end

def.static("number", "=>", "string").GetChatEmotion = function(id)
	if ChatEmotionList == nil then
		local ret, msg, result = pcall(dofile, _G.ConfigsDir.."emotions.lua")
		if ret then
			ChatEmotionList = result
		else
			warn(msg)
		end
	end
	if ChatEmotionList == nil then return "nil string" end

	return ChatEmotionList[id]
end


CChatStringData.Commit()
return CChatStringData