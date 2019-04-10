local Lplus = require "Lplus"

local CChatStringData = Lplus.Class("CChatStringData")
local def = CChatStringData.define

def.static("number", "=>", "string").GetChat = function(id)
	local ChatStringList = _G.ChatCfgTable
	if ChatStringList == nil then return "nil string" end

	return ChatStringList[id]
end

def.static("number", "=>", "string").GetChatEmotion = function(id)
	local ChatEmotionList = _G.EmotionsTable
	if ChatEmotionList == nil then return "nil string" end

	return ChatEmotionList[id]
end


CChatStringData.Commit()
return CChatStringData