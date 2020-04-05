--
-- S2CServerMessage
--

local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local ServerMessageId = require "PB.data".ServerMessageId
local ESystemNotifyDisplayType = require "PB.Template".SystemNotify.SystemNotifyDisplayType
local ESyncChannel = require "PB.Template".SystemNotify.ESyncChannel

local function OnServerMessage(sender, protocol)
	local template = CElementData.GetSystemNotifyTemplate(protocol.MessageId)
	local message = ""

	local curType = ESystemNotifyDisplayType.MessageBox
	local syncChannel = ESyncChannel.DontSync

	if template ~= nil then
		curType = template.DisplayType
		syncChannel = template.SyncChannel
		message = template.TextContent

		message = string.format(message, unpack(protocol.Params))
	end

	if message == nil then
		message = "Unkown message {id = " .. tostring(protocol.MessageId) .. "}"
	end

	if curType == ESystemNotifyDisplayType.Scroll then					--走马灯
		game._GUIMan:OpenSpecialTopTips( message )
	elseif curType == ESystemNotifyDisplayType.SystemChatChannel then	--系统聊天频道
		local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
		local ChatManager = require "Chat.ChatManager"
		ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, message, false)
	elseif curType == ESystemNotifyDisplayType.FloatingTipBottom then	--底部飞字
		game._GUIMan:ShowTipText(message, false)
	elseif curType == ESystemNotifyDisplayType.FloatingTipTop then	--顶部飞字
		game._GUIMan:ShowTipText(message, true)
	else 														--默认为 消息框
		local title = StringTable.Get(8)
		message = string.format("%s(%d)", message, protocol.MessageId)
		MsgBox.ShowMsgBox(message, title, MsgBoxType.MBBT_OK)
	end

	if syncChannel ~= nil and syncChannel ~= ESyncChannel.DontSync then
		-- 同步，与显示方式重复则不同步
		local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
		local ChatManInstance = require "Chat.ChatManager".Instance()
		if syncChannel == ESyncChannel.Scroll and curType ~= ESystemNotifyDisplayType.Scroll then
			-- 走马灯
			game._GUIMan:OpenSpecialTopTips(message)
		elseif syncChannel ~= ESyncChannel.ChatChannelSystem or curType ~= ESystemNotifyDisplayType.SystemChatChannel then
			-- 系统频道，当前频道，世界频道，队伍频道，公会频道
			local enumTable =
			{
				[ESyncChannel.ChatChannelSystem] = ECHAT_CHANNEL_ENUM.ChatChannelSystem,
				[ESyncChannel.ChatChannelCurrent] = ECHAT_CHANNEL_ENUM.ChatChannelCurrent,
				[ESyncChannel.ChatChannelWorld] = ECHAT_CHANNEL_ENUM.ChatChannelWorld,
				[ESyncChannel.ChatChannelTeam] = ECHAT_CHANNEL_ENUM.ChatChannelTeam,
				[ESyncChannel.ChatChannelGuild] = ECHAT_CHANNEL_ENUM.ChatChannelGuild,
			}
			ChatManInstance:ClientSendMsg(enumTable[syncChannel], message, false)
		end
	end
	
	--服务器登录异常初始化处理
	--[[
		ServerMessageId.AuthFailed = 11
		ServerMessageId.MultiLogin = 12
		ServerMessageId.ServerOverload = 13
		ServerMessageId.GameServerNotExist = 14
		ServerMessageId.AccountLengthInvalid = 15
        ServerMessageId.RoleNameLengthInvalid = 16
	]]
	if protocol.MessageId >= 11 and protocol.MessageId <= 16 then --重复登录
		--关闭连接
		game._NetMan._GameSession:ResetConnectFlag()
		game._NetMan:Close()
	    game:CancelReconnectTimer()
	end
	--登录困难触发转圈界面关闭
	game._GUIMan:Close("CPanelCircle")
end

PBHelper.AddHandler("S2CServerMessage", OnServerMessage)