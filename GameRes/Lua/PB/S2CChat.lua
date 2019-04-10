--
-- S2CChat
--

local PBHelper = require "Network.PBHelper"
local ChatManager = require "Chat.ChatManager"
local CHAT_RETURN_CODE = require "PB.net".CHAT_RETURN_CODE
local ChatLinkType = require "PB.data".ChatLinkType

--根据返回的code进行不同的提示
local function OnChatReturnCode(code)
	local ErrorStr = ""
	if code == CHAT_RETURN_CODE.MONEY_NOT_ENOUGH then
		ErrorStr = StringTable.Get(13004)
	elseif code == CHAT_RETURN_CODE.OPT_FAST then
		ErrorStr = StringTable.Get(13003)
	elseif code == CHAT_RETURN_CODE.FORBID_TALK then
		ErrorStr = StringTable.Get(13005)
	elseif code == CHAT_RETURN_CODE.DATA_ERR then
		ErrorStr = StringTable.Get(13007)
	elseif code == CHAT_RETURN_CODE.LEVEL_NOT_ENOUGH then
		ErrorStr = StringTable.Get(13006)
	elseif code == CHAT_RETURN_CODE.NOT_HAVE_GUILD then
		ErrorStr = StringTable.Get(13000)
	elseif code == CHAT_RETURN_CODE.NOT_HAVE_TEAM then
		ErrorStr = StringTable.Get(13001)
	elseif code == CHAT_RETURN_CODE.CONTENT_TOO_LONG then
		ErrorStr = StringTable.Get(13008)
	elseif code == CHAT_RETURN_CODE.SENSITIVE_WORD then
		ErrorStr = StringTable.Get(13002)
	else
		warn("msg.returnCode == " ..code)
	end
	game._GUIMan:ShowTipText(ErrorStr, false)
end


local function OnChat(sender, msg)
	if msg.returnCode == CHAT_RETURN_CODE.OK_CHAT_RETURN_CODE then
		if game._HostPlayer == nil then return end
		-- warn("msg.chatContent.chatLink.LinkType == ", msg.chatContent.chatLink.LinkType, msg.chatContent.senderInfo.Id, game._HostPlayer._ID)
		if msg.chatContent.senderInfo.Id == game._HostPlayer._ID and msg.chatContent.chatLink.LinkType == ChatLinkType.ChatLinkType_Team then
			game._GUIMan:ShowTipText(StringTable.Get(13020), false)
		end
		ChatManager.Instance():OnPrtc_ChatPublic(msg.chatContent)
	else
		OnChatReturnCode(msg.returnCode)
		return
	end
end
PBHelper.AddHandler("S2CChat", OnChat)

 