--
-- S2CEntityShout
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local ChatManager = Lplus.ForwardDeclare("ChatManager")
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local ESyncChannel = require "PB.Template".SystemNotify.ESyncChannel

local function OnEntityShout( sender,msg )
	local entity = game._CurWorld:FindObject(msg.EntityId) 
	if entity ~= nil and entity._IsReady then
		function cb()
			local CElementData = require "Data.CElementData"
			local textTemplate = CElementData.GetTextTemplate(msg.TextId)
			if textTemplate == nil then return end
			local text = textTemplate.TextContent
			entity:OnTalkPopTopChange(true, text, tonumber(textTemplate.Duration/1000))

			local str = entity._InfoData._Name .. ":" .. text
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelCurrent, str, false)

			local syncChannel = textTemplate.SyncChannel
			if syncChannel ~= nil and syncChannel ~= ESyncChannel.DontSync then
				-- 同步，暂时不显示当前频道
				if syncChannel == ESyncChannel.Scroll then
					-- 走马灯
					game._GUIMan:OpenSpecialTopTips(str)
				elseif syncChannel ~= ESyncChannel.ChatChannelCurrent then
					-- 系统频道，世界频道，队伍频道，公会频道
					local enumTable =
					{
						[ESyncChannel.ChatChannelSystem] = ECHAT_CHANNEL_ENUM.ChatChannelSystem,
						[ESyncChannel.ChatChannelWorld] = ECHAT_CHANNEL_ENUM.ChatChannelWorld,
						[ESyncChannel.ChatChannelTeam] = ECHAT_CHANNEL_ENUM.ChatChannelTeam,
						[ESyncChannel.ChatChannelGuild] = ECHAT_CHANNEL_ENUM.ChatChannelGuild,
					}
					ChatManager.Instance():ClientSendMsg(enumTable[syncChannel], str, false)
				end
			end
		end

		if msg.DelayTime ~= nil and msg.DelayTime ~= 0 then
			entity:AddTimer(msg.DelayTime, true, function()
				if cb ~= nil then cb() end
				end)
		else
			cb()
		end

		--TODO()
	end
end

PBHelper.AddHandler("S2CEntityShout",OnEntityShout)