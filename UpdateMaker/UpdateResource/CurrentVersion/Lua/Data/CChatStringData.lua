local Lplus = require "Lplus"

local CChatStringData = Lplus.Class("CChatStringData")
local def = CChatStringData.define

def.static("number", "=>", "string").GetChat = function(id)
	local ChatStringList = _G.ChatCfgTable
	if ChatStringList == nil then return "nil string" end

	return ChatStringList[id]
end

CChatStringData.Commit()
return CChatStringData