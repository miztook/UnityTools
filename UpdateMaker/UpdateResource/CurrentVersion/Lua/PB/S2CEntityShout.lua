--
-- S2CEntityShout
--

local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local ChatManager = Lplus.ForwardDeclare("ChatManager")
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local ESyncChannel = require "PB.Template".SystemNotify.ESyncChannel

local function OnEntityShout( sender,msg )
	local tmpEntity = game._CurWorld:FindObject(msg.EntityId) 
	if tmpEntity ~= nil and tmpEntity._IsReady then
		local function cb(entity,textID)
			if IsNil(entity) then
				return
			end
			local CElementData = require "Data.CElementData"
			local DynamicText = require "Utility.DynamicText"

			local textTemplate = CElementData.GetTextTemplate(textID)
			if textTemplate == nil then return end

			if not IsNilOrEmptyString(textTemplate.AudioAssetPath) then
				CSoundMan.Instance():Play3DShout(textTemplate.AudioAssetPath, tmpEntity:GetPos(),0)
				--CSoundMan.Instance():Play2DVoice(textTemplate.AudioAssetPath, 0)
			end

			local text = DynamicText.ParseDialogueText(textTemplate.TextContent)
			entity:ShowPopText(true, text, tonumber(textTemplate.Duration/1000))
			--print("text=",text,textID)
			local syncChannel = textTemplate.SyncChannel
			if syncChannel ~= nil and syncChannel ~= ESyncChannel.DontSync then
				-- 同步到指定频道
				local strName = RichTextTools.GetElsePlayerNameRichText(entity._InfoData._Name,false).. ":" .. text
				if syncChannel == ESyncChannel.Scroll then
					-- 走马灯		
					game._GUIMan:OpenSpecialTopTips(strName)
				else
					-- 系统频道，当前频道，世界频道，队伍频道，公会频道
					local enumTable =
					{
						[ESyncChannel.ChatChannelSystem] = ECHAT_CHANNEL_ENUM.ChatChannelSystem,
						[ESyncChannel.ChatChannelCurrent] = ECHAT_CHANNEL_ENUM.ChatChannelCurrent,
						[ESyncChannel.ChatChannelWorld] = ECHAT_CHANNEL_ENUM.ChatChannelWorld,
						[ESyncChannel.ChatChannelTeam] = ECHAT_CHANNEL_ENUM.ChatChannelTeam,
						[ESyncChannel.ChatChannelGuild] = ECHAT_CHANNEL_ENUM.ChatChannelGuild,
					}
					ChatManager.Instance():ClientSendMsg(enumTable[syncChannel], strName, false, 0, nil,nil)
				end
			end
		end

		if msg.DelayTime ~= nil and msg.DelayTime ~= 0 then
			tmpEntity:AddTimer(msg.DelayTime, true, function()
				if cb ~= nil then cb(tmpEntity,msg.TextId) end
				end)
		else
			cb(tmpEntity,msg.TextId)
		end

		--TODO()
	end
end

PBHelper.AddHandler("S2CEntityShout",OnEntityShout)