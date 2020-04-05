--
-- S2CChat
--

local PBHelper = require "Network.PBHelper"
local ChatManager = require "Chat.ChatManager"
local CHAT_RETURN_CODE = require "PB.net".CHAT_RETURN_CODE


--根据返回的code进行不同的提示
local function OnChatReturnCode(code)
	if code == CHAT_RETURN_CODE.MONEY_NOT_ENOUGH then
		FlashTip(StringTable.Get(13004) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.OPT_FAST then
		FlashTip(StringTable.Get(13003) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.FORBID_TALK then
		FlashTip(StringTable.Get(13005) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.DATA_ERR then
		FlashTip(StringTable.Get(13007) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.LEVEL_NOT_ENOUGH then
		FlashTip(StringTable.Get(13006) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.NOT_HAVE_GUILD then
		FlashTip(StringTable.Get(13000) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.NOT_HAVE_TEAM then
		FlashTip(StringTable.Get(13001) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.CONTENT_TOO_LONG then
		FlashTip(StringTable.Get(13008) , "tip", 2)
	elseif code == CHAT_RETURN_CODE.SENSITIVE_WORD then
		FlashTip(StringTable.Get(13002) , "tip", 2)
	else
		warn("msg.returnCode == " ..code)
	end
end


local function OnChat(sender, msg)
	if msg.returnCode == CHAT_RETURN_CODE.OK then
		ChatManager.Instance():OnPrtc_ChatPublic(msg.chatContent)
	else
		OnChatReturnCode(msg.returnCode)
		return
	end
end
PBHelper.AddHandler("S2CChat", OnChat)

 