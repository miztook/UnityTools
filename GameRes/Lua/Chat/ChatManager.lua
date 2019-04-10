local Lplus = require "Lplus"
local CHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local ChatLinkType = require "PB.data".ChatLinkType
local ChatType = require "PB.data".ChatType
local CGame = Lplus.ForwardDeclare("CGame")
local CMsg = require "Chat.CMsg"
local PBHelper = require "Network.PBHelper"
local ChatManager = Lplus.Class("ChatManager")
local CElementData = require "Data.CElementData"
local UserData = require "Data.UserData".Instance()
local CTeamMan = require "Team.CTeamMan"
local CPanelChatNew = require "GUI.CPanelChatNew"

local CurrentChatLevel = nil  --当前可以说话的等级
local CurrentChatLevelId = 95
local WorldChatLevel = nil  --世界可以说话的等级
local WorldChatLevelId = 97
-- local CurrentChatCDTime = nil	   --当前说话CD时间(秒)
-- local CurrentChatCDTimeId = 94	--当前说话CD时间Id
-- local WorldChatCDTime = nil	   --世界说话CD时间(秒)
-- local WorldChatCDTimeId = 96	--世界说话CD时间Id
local CurrentPlayVoiceID = nil	--当前播放的语音ID

do
	local def = ChatManager.define
	def.field("table")._MsgList = BlankTable
    def.field("table")._SendMsgList = BlankTable
	def.field("table")._NotReadCounter = BlankTable
    def.field("number")._CurrentLastMsgId = 0
	def.field("number")._WorldLastMsgId = 0

	def.field("boolean")._Channel_World = true
	def.field("boolean")._Channel_Guild = true
	def.field("boolean")._Channel_System = true
	def.field("boolean")._Channel_Team = true
	def.field("boolean")._Channel_Current = true
	def.field("boolean")._Channel_Combat= false
	def.field("boolean")._Channel_Social= true

	local Instance = nil
	def.static("=>",ChatManager).Instance = function()
		if Instance == nil then
		    Instance = ChatManager()
		end
		return Instance
	end
    --创建一个Msg对象
	def.method("=>",CMsg).NewMsg = function(self)
		return CMsg.NewRecvMsg()
	end
	--创建一个Msg对象
	def.method("=>",CMsg).NewMsgEx = function(self)
		return CMsg.NewSendMsg()
	end

	--聊天面板最大显示的消息条数
	def.method("=>","number").GetMsgListMaxCount = function(self)
        return 20
	end

	--获取存在本地的聊天消息
	def.method().GetMsg = function(self)

	end
	
	--链接点击处理
	def.method("number","number").OnLinkClick = function(self, msgId, linkId)
		local pos = self:FindMessage(msgId)
		-- warn("lidaming ------------> pos == ", pos )
    	if pos > 0 then
			local msg = self._MsgList[pos]
			--LinkType = msg.LinkType        ContentID = msg.LinkParam1
			if msg ~= nil then
				-- warn("------------------------->>> msg.TYPE == ", msg.MsgType)
				if msg.MsgType == ChatType.ChatTypeItemInfo then
					if msg.ItemInfo ~= nil then  								--物品链接
						--  warn("lidaming msg.ItemInfo.Tid = ", #msg.ItemInfo, linkId)
						if #msg.ItemInfo > 0 then
							-- warn("msg.ItemInfo[linkId].Id ==", msg.ItemInfo[linkId].Id)
							if msg.ItemInfo[linkId] == nil then return end  
							local itemTemplate = CElementData.GetItemTemplate(msg.ItemInfo[linkId].Tid)
							local itemName = " <"..itemTemplate.TextDisplayName..">"
							if string.find(msg.StrMsg, itemName) then
								CItemTipMan.ShowChatItemTips(msg.ItemInfo[linkId], TipsPopFrom.CHAT_PANEL)
							end
						else
							-- warn("msg.ItemInfo.Tid ==", msg.ItemInfo.Tid)
							if msg.ItemInfo == nil then return end  
							local itemTemplate = CElementData.GetItemTemplate(msg.ItemInfo.Tid)
							local itemName = "["..itemTemplate.TextDisplayName.."]"
							if string.find(msg.StrMsg, itemName) then
								CItemTipMan.ShowChatItemTips(msg.ItemInfo, TipsPopFrom.CHAT_PANEL)
							end
						end
					end
				elseif msg.MsgType == ChatType.ChatTypeLink then
					if msg.LinkType == ChatLinkType.ChatLinkType_Dungeon then 		--副本链接
						warn("lidaming ChatLinkType_Dungeon!!!")
					elseif msg.LinkType == ChatLinkType.ChatLinkType_Guild then   	--公会链接						
						if msg.RoleId ~= game._HostPlayer._ID then
							game._GuildMan:OnClickGuildLink(msg.LinkParam1)
						else
							game._GUIMan: ShowTipText(string.format(StringTable.Get(13018), StringTable.Get(13015)),true)
						end
					elseif msg.LinkType == ChatLinkType.ChatLinkType_Team then   	--队伍邀请链接						
						if CTeamMan.Instance():InTeam() then
							game._GUIMan: ShowTipText(string.format(StringTable.Get(13018), StringTable.Get(13016)),true)							
						else
							CTeamMan.Instance():ApplyTeam(msg.LinkParam1)
						end
					elseif msg.LinkType == ChatLinkType.ChatLinkType_Path then
						-- 寻路到对应的地图和位置
						local HostPlayerPosX, HostPlayerPosZ = game._HostPlayer:GetPosXZ() -- 无内存分配的getPosition
        				if math.ceil(HostPlayerPosX) == math.ceil(msg.Link_PathPos.x) and math.ceil(HostPlayerPosZ) == math.ceil(msg.Link_PathPos.z) then return end
						local CTransManage = require "Main.CTransManage"
						local targetPos = Vector3.New(msg.Link_PathPos.x, msg.Link_PathPos.y, msg.Link_PathPos.z)
						CTransManage.Instance():StartMoveByMapIDAndPos(msg.Link_MapId, targetPos, nil, false, false)
					end
				else
					warn("lidaming msg.MsgType = ", msg.MsgType)
				end
				
			end
    	end
	end

	def.method("number").OnVoiceClick = function(self, msgId)
		local pos = self:FindMessage(msgId)
    	if pos > 0 then
			local msg = self._MsgList[pos]
			--LinkType = msg.LinkType        ContentID = msg.LinkParam1
			if msg ~= nil and msg.Voice ~= nil then
				local VoiceExist = VoiceUtil.OffLine_IsVoiceFileExist(msg.Voice)
				-- local VoiceExist = true
				-- warn(" VoiceExist == false", VoiceExist)
				local resPath = msg.Voice
				if VoiceExist == false then  		--判断本地是否已经存在。
					local ret = VoiceUtil.OffLine_DownloadFile(msg.Voice , resPath)
				elseif VoiceExist == true then
					self:OnPlayVoice(msg.Voice)
				end
			end
    	end
	end

	def.method("string").OnPlayVoice = function(self , fileId)
		-- 先判断当前是否在播放语音，如果在播放就停止，播放当前点击的语音。
		warn("OnPlayVoice CurrentPlayVoiceID == ", CurrentPlayVoiceID)
		if CurrentPlayVoiceID ~= nil then
			self:OnStopVoice(CurrentPlayVoiceID)
			-- if CurrentPlayVoiceID == fileId then
			-- 	CurrentPlayVoiceID = nil
			-- 	CSoundMan.Instance():SetSoundBGMVolume(1, true)
			-- 	return
			-- end
		end
		--CSoundMan.Instance():EnableBackgroundMusic(false)	-- 音量调小的值。暂时写死。
		CSoundMan.Instance():SetSoundBGMVolume(0, true)
		local ret = VoiceUtil.OffLine_PlayRecordedFile(fileId)
		-- ret = VoiceUtil.Translation_SpeechToText(fileId)
		-- warn("ret == ", ret , "fileId == ", fileId)		
		CurrentPlayVoiceID = fileId
	end

	def.method("string").OnStopVoice = function(self , fileId)
		-- warn("OnStopVoice CurrentPlayVoiceID == ", CurrentPlayVoiceID)
		
		--CSoundMan.Instance():EnableBackgroundMusic(true)
		CSoundMan.Instance():SetSoundBGMVolume(1, true)
		local ret = VoiceUtil.OffLine_StopPlayFile(fileId)
		-- warn("OnStopVoice ret == ", ret)
	end

	-- 自动播放语音
	def.method("table").OnAutoPlayVoice = function(self, msg)		
		local CPanelUIChatSet = require "GUI.CPanelUIChatSet".Instance()
		if (msg.chatChannel == CHAT_CHANNEL_ENUM.ChatChannelWorld and CPanelUIChatSet._Channel_WorldVoice == false)            
        or (msg.chatChannel == CHAT_CHANNEL_ENUM.ChatChannelGuild and CPanelUIChatSet._Channel_GuildVoice == false)
        or (msg.chatChannel == CHAT_CHANNEL_ENUM.ChatChannelTeam and CPanelUIChatSet._Channel_TeamVoice == false)
        or (msg.chatChannel == CHAT_CHANNEL_ENUM.ChatChannelCurrent and CPanelUIChatSet._Channel_CurrentVoice == false) then
			return
        end
		if msg.senderInfo.Id == game._HostPlayer._ID then return end
		if msg ~= nil and msg.voice ~= nil then
			local VoiceExist = VoiceUtil.OffLine_IsVoiceFileExist(msg.voice)
			-- local VoiceExist = true
			-- warn(" VoiceExist ==>>>", VoiceExist, msg.voice)
			local resPath = msg.voice
			if VoiceExist == false then  		--判断本地是否已经存在。
				local ret = VoiceUtil.OffLine_DownloadFile(msg.voice , resPath)					
			end
			-- 先判断当前是否在播放语音，如果在播放就停止，播放当前点击的语音。
			if CurrentPlayVoiceID ~= nil and CurrentPlayVoiceID ~= msg.voice then
				self:OnStopVoice(CurrentPlayVoiceID)
			end
			CSoundMan.Instance():SetSoundBGMVolume(0, true)
			local ret = VoiceUtil.OffLine_PlayRecordedFile(msg.voice)
			-- ret = VoiceUtil.Translation_SpeechToText(msg.voice)
			CurrentPlayVoiceID = msg.voice
		end
		-- warn("lidaming OnAutoPlayVoice msg.voiceID == ", msg.voice)		
	end

------------------------------------------------
	def.method("table").AddSimpleMessage = function(self, finalContent)
		local msg = self:NewMsg()

		local FilterMgr = require "Utility.BadWordsFilter".Filter
		local chatstr = FilterMgr.FilterChat(finalContent.text)
		msg.RoleId = finalContent.senderInfo.Id
		msg.msgplayer = finalContent.senderInfo.Name
        msg.Level = finalContent.senderInfo.Level
		msg.Channel = finalContent.chatChannel
		msg.MsgType = 0
		msg.Prof = finalContent.senderInfo.HeadIcon
		msg.Gender = finalContent.senderInfo.Gender
		msg.StrMsg = chatstr
		msg.Voice = finalContent.Voice
		msg.VoiceLength = math.ceil(finalContent.voiceLength)
		msg.StrRecvMsg = chatstr
		msg.result = SendStatus.Success
		msg.Status = ReadStatus.Read
		if finalContent.ItemInfo ~= nil then
			msg.ItemInfo = finalContent.itemInfo
		elseif finalContent.chatLink ~= nil then
			msg.LinkType = finalContent.chatLink.LinkType
			if msg.LinkType == ChatLinkType.ChatLinkType_Dungeon then
				msg.LinkParam1 = finalContent.chatLink.ContentID
			elseif msg.LinkType == ChatLinkType.ChatLinkType_Guild then
				msg.LinkParam1 = finalContent.chatLink.ContentID
			elseif msg.LinkType == ChatLinkType.ChatLinkType_Team then
				msg.LinkParam1 = finalContent.chatLink.ContentID
			elseif msg.LinkType == ChatLinkType.ChatLinkType_Path then
				msg.LinkParam1 = finalContent.chatLink.ContentID
				msg.Link_MapId = finalContent.chatLink.MapTid
				msg.Link_PathPos = finalContent.chatLink.PathPos
			elseif msg.LinkType ~= 0 then
				warn("未处理的聊天链接类型")
			end
		end
		self:AddToMsgChain(msg)
	end

	def.method(CMsg).AddToMsgChain = function(self,msg)
        local CPanelMainChat = require "GUI.CPanelMainChat"
        local channel = msg.Channel
        --该频道现有消息数量
        local count = self:GetChannelTotalCount(channel)
		--warn("AddToMsgChain count == ", count)
        if count >= self:GetMsgListMaxCount() then
            local pos = self:GetFirstChannelMsg(channel)
            if pos > 0 then
                self:RemoveAt(pos) --移除该频道的第一条消息 
				-- CPanelMainChat.Instance():RemoveAtFirst()               
            end
        end		

		
		if CPanelChatNew.Instance():IsShow() then
			if count >= self:GetMsgListMaxCount() then
				local pos = self:GetFirstChannelMsg(channel)
				if pos > 0 then
					self:RemoveAt(pos) --移除该频道的第一条消息             
				end
			end		
		end
		-- self._MsgList[#self._MsgList + 1] = msg
		-- table.insert(self._MsgList,msg)
		self:UpdateMsgInChain(msg)		
	end 

	def.method("number").RemoveAt = function(self,pos)
        table.remove(self._MsgList,pos) --移除该频道的一条消息
    end

    def.method(CMsg).AddSendMsgToChain = function(self,msg)
        table.insert(self._MsgList,msg)
		-- self._MsgList[#self._MsgList + 1] = msg
    end

	-- def.method("number","number").LastSendMsgTime = function(self,channel,sendTime)
	-- 	if channel == CHAT_CHANNEL_ENUM.ChatChannelCurrent then
	-- 		self._CurrentLastMsgId = sendTime
	-- 	elseif channel == CHAT_CHANNEL_ENUM.ChatChannelWorld then
	-- 		self._WorldLastMsgId = sendTime
	-- 	end
	-- end

    -- def.method("number",CMsg).UpdateSendMsg = function(self,pos,msg)
    --     self._MsgList[pos] = msg
    -- end


	-- 添加一条消息到列表
	def.method(CMsg).UpdateMsgInChain = function(self,msg)
		-- self:UpdateMsg(pos,msg)
		local CPanelMainChat = require "GUI.CPanelMainChat"
		CPanelMainChat.Instance():UpdateMsgInShow(msg)  

		if CPanelChatNew.Instance():IsShow() then
			CPanelChatNew.Instance():ShowOneChatMsgEx(msg)
		end
	end

    -- def.method("number",CMsg).UpdateMsg = function(self,pos,msg)
    --     self._MsgList[pos] = msg
    -- end

    -- def.method(CMsg).UpdateMsgEx = function(self,msg)
    -- 	local pos = self:FindMessage(msg.UniqueMsgID)
    -- 	if pos >0 then
    -- 		self._MsgList[pos] = msg
    -- 	end
    -- end

	def.method("number").RemoveMsg = function(self,uniqueId)
        local k = self:FindMessage(uniqueId)
        if k >0 then
            self:RemoveAt(k)
        end
        --TODO:UpdateUI
    end

	-- 清空聊天消息
	def.method().ClearnMsg = function(self)
		self._MsgList = {}
		self._SendMsgList = {}
    end


	def.method().SaveMsg = function(self)
    --     local msgList = self._SendMsgList 
    --     for i=1, #msgList do
    --         local msg = self._SendMsgList[i]--self._MsgList[i]
    --         if msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelWorld or
	-- 		   msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelGuild or
	-- 		   msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelSystem then
	-- 		    warn("SaveDataToFile!!!"..msg.Channel)
	-- 			UserData:SetCfg("ChatMsgList", "RoleId", msg.RoleId)
	-- 			UserData:SetCfg("ChatMsgList", "msgplayer", msg.msgplayer)
	-- 		    UserData:SetCfg("ChatMsgList", "channel", msg.Channel)
	-- 			UserData:SetCfg("ChatMsgList", "level", msg.Level)
	-- 			UserData:SetCfg("ChatMsgList", "MsgType", msg.MsgType)
	-- 			UserData:SetCfg("ChatMsgList", "StrMsg", msg.StrMsg)
	-- 			UserData:SetCfg("ChatMsgList", "ItemInfo", msg.ItemInfo)

	-- 			UserData:SaveDataToFile()
    --         end
    --     end
    end

--------查找消息---------
	def.method("number","=>","number").FindMessage = function(self,uniqudId)
		--for k,v in pairs(self._MsgList) do
		for i = #self._MsgList , 1 ,-1 do
			if self._MsgList[i].UniqueMsgID == uniqudId then
				return i
			end
		end
		return 0
	end

    def.method("number","=>",CMsg,"number").FindHpMessage = function(self,uniqudId)
		for k,v in pairs(self._MsgList) do
			if v.UniqueHpMsgID == uniqudId and v.RoleId == game._HostPlayer._ID then
				return v,k
			end
		end
		return nil,0
	end

    def.method("number","string","=>",CMsg,"number").FindSimpleMessage = function(self,channel,StrMsg)
		for k,v in pairs(self._MsgList) do
			if v.text == StrMsg and v.chatChannel == channel then
                return v,k
            end
		end
		return nil,0
	end

	def.method("=>","table").GetMsgList = function(self)
		return self._MsgList
	end

	-- 根据index获取到对应的消息
	def.method("number", "=>","table").GetMsgByuniqueMsgID = function(self ,index)
		local retlist = {}
		for i = 1 , #self._MsgList do
			if self._MsgList[i].UniqueMsgID == index then
				table.insert(retlist,self._MsgList[i])
			end
		end
		return retlist
	end

--[[ 好友聊天
    def.method("string","=>","table").GetChatWithList = function(self,RoleId)
        local retlist = {}
        local msgList = self:GetMsgByChannel(10)
        for _,v in pairs(msgList) do
            table.insert(retlist,v)
        end
        return retlist
    end
]]
	--根据频道获取聊天消息
	def.method("number","=>","table").GetMsgByChannel = function(self,channel)
		local retlist = {}
		for i = 1 , #self._MsgList do
			if self._MsgList[i].Channel == channel then
				table.insert(retlist,self._MsgList[i])
			end
		end
		return retlist
	end

    def.method("number","=>","number").GetChannelTotalCount = function(self,channel)
        local count = 0
		if self._MsgList == nil then return end
        for _,v in pairs(self._MsgList) do
			if v.Channel == channel then
				count = count + 1
			end
		end
        return count
    end

    def.method("number","=>","number").GetChannelNotReadCount = function(self,channel)
    	return self._NotReadCounter[channel] or 0
    end

    def.method("number").IncNotReadForChannel = function(self,channel)
		local oldNum = self._NotReadCounter[channel] or 0 
    	self._NotReadCounter[channel] = oldNum + 1
    end

    def.method("number").DecNotReadForChannel = function(self,channel)
    	local oldNum = self._NotReadCounter[channel] or 0
		if oldNum <= 0 then return end 
    	self._NotReadCounter[channel] = oldNum - 1
    end

    def.method("number","=>","number").GetFirstChannelMsg = function(self,channel)
        for i = 1 , #self._MsgList do
			if self._MsgList[i].Channel == channel then
				return i
			end
		end
        return 0
    end

    def.method("number","=>","number").GetLastChannelMsg = function(self,channel)
        local ret = 0
        for k,v in pairs(self._MsgList) do
			if v.chatChannel == channel then
                ret = k
            end
        end
        return ret
    end

    def.method("number","number","=>",CMsg).FindPrevChannelMsg = function(self,uniqueId,channel)
        local pos = self:FindMessage(uniqueId)
        if pos == 0 then
            return nil
        end
        for i=pos-1,1,-1 do
            local v = self._MsgList[i]
            if v.chatChannel == channel then
                return v
            end
        end
        return nil
    end

    def.method("number","number","=>",CMsg).FindNextChannelMsg = function(self,uniqueId,channel)
        local pos = self:FindMessage(uniqueId)
        if pos == 0 then
            return nil
        end
        for i=pos+1,#self._MsgList do
            local v = self._MsgList[i]
            if v.chatChannel == channel then
                return v
            end
        end
        return nil
    end
    --获取频道上一次发送的消息
    def.method("number","=>",CMsg).GetLastSendMsgByChannel = function(self,channel)
        local count = #self._SendMsgList --#self._MsgList
        for i=count,1,-1 do
            local msg = self._SendMsgList[i]--self._MsgList[i]
            if msg.Channel == channel and msg.RoleId == game._HostPlayer._ID then
                return msg
            end
        end
        return nil
    end

	----------------------------------------------------------------
	def.method().Toggle = function(self)
		CPanelChatNew.Instance():Toggle()
	end

	def.method("function").OpenChatPanel = function(self,callback)
		CPanelChatNew.Instance():OpenPanel(callback)
	end

	def.method().SimpleOpenChatPanel = function(self)
		self:OpenChatPanel(nil)
	end

    def.method("string","=>","string").MakeJoinTeam = function(self,str)
        return str
    end

    def.method("string","=>","string").MakeJoinFaction = function(self,str)
        return str
    end

	--[[
		Client Input 使用
	]]
	def.method("number","=>","string").FormatParamPlaceHolder = function(self,index)
		return index
	end

	def.method("number","number","=>","string").MakeIvtrItemClient = function(self,pack,slot)
		return pack,slot
	end

	------------------------------------------------------------------
	--[[
		C2S
	]]

	def.method().ReSend = function(self)
		for k,msg in pairs(self._SendMsgList) do
			if msg.RoleId == game._HostPlayer._ID and msg.result == SendStatus.Failure then				
                self:SendMsg(msg)
                self:UpdateMsgInChain(msg)
			end
		end
	end

	--客户端推送一条消息（频道，说的内容，是否发送协议，聊天类型，类型相关内容 ）
	def.method("number","string","boolean","number", "table","table").ClientSendMsg = function(self, Channel, Content, IsServer, SendChatType, LinkInfo,RoleInfo)
		if IsServer == true then
			--warn("Client TO Server!!!")
			local msg = self:NewMsgEx()
			msg.StrMsg = Content
			msg.Channel = Channel
			msg.MsgType = SendChatType
			self:SendMsg(msg)
		elseif IsServer == false then
			--warn("Client TO Client!!!")			
			local msg = self:NewMsg()
			msg.Channel = Channel
			if msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelGuild then --帮派    
				-- warn(debug.traceback())  
				if game._GuildMan:IsHostInGuild() == false then
					-- warn("NO GUILD !!!")
					return
				end
			elseif msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelTeam then --队伍
				if not CTeamMan.Instance():InTeam() then
					-- warn("NO TEAM!!!")
					return
				end				
			elseif msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelSocial then -- 好友 
				msg.RoleId = RoleInfo.RoleId
				msg.PlayerName = RoleInfo.PlayerName 
			end	
			msg.MsgType = SendChatType
			if SendChatType == ChatType.ChatTypeItemInfo and LinkInfo ~= nil then
				msg.ItemInfo = LinkInfo
			end
			msg.StrMsg = Content
			self._MsgList[#self._MsgList + 1] = msg
			self:AddToMsgChain(msg)
		end
	end

	--发送公会援助和加入队伍邀请
	def.method("table").ChatOtherSend = function (self,linkInfo)
		local msg = self:NewMsgEx()
		msg.ChatLink = linkInfo.ChatLink	--协议结构
		msg.Channel = linkInfo.chatChannel
		msg.MsgType = ChatType.ChatTypeLink  --固定聊天类型为：ChatTypeLink 链接
		msg.LinkType = linkInfo.ChatLink.LinkType
		msg.LinkParam1 = linkInfo.ChatLink.ContentID
		msg.Link_TargetId = linkInfo.TargetId		
		msg.Link_Level = linkInfo.Level
		msg.Link_FighatScore = linkInfo.CombatPower
		self:SendMsg(msg)
	end

	--发送分解物品 获得奖励提示。PS：可能是多个
	def.method("table").ChatSendRewardInfos = function (self,RewardInfos)
		-- 分解物品 获得奖励 发送系统消息提示
		local RewardType = require"PB.data".RewardType
		if RewardInfos ~= nil and #RewardInfos > 0 then
			local RewardMsg = nil
			local ItemData = {}
			for i,v in ipairs(RewardInfos) do
				if v ~= nil then
					if v.Type == RewardType.Item then 
						if RewardMsg == nil then
							RewardMsg = string.format(StringTable.Get(13045), RichTextTools.GetItemNameRichText(v.Id, 1,true), v.Num)						
						else
							RewardMsg = RewardMsg .. string.format(StringTable.Get(13045), RichTextTools.GetItemNameRichText(v.Id, 1,true), v.Num)
						end
						ItemData[#ItemData + 1] = CElementData.GetItemTemplate(v.Id)
					elseif v.Type == RewardType.Resource then 
						local CTokenMoneyMan = require "Data.CTokenMoneyMan"
						if RewardMsg == nil then
							RewardMsg = string.format(StringTable.Get(13045), CTokenMoneyMan.Instance():GetName(v.Id), v.Num)
						else
							RewardMsg = RewardMsg .. string.format(StringTable.Get(13045), CTokenMoneyMan.Instance():GetName(v.Id), v.Num)
						end			
					end
				end
			end

			local msg = string.format(StringTable.Get(13031), RewardMsg)
			if msg ~= nil then
				self:ClientSendMsg(CHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 2, ItemData,nil)
			end
		end
	end


    def.method(CMsg).SendMsg = function(self,msg)
		if msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelWorld and game._HostPlayer._InfoData._WorldChatCount == 0 then
			game._GUIMan:ShowTipText(StringTable.Get(13023), false)
			return
		end
        local C2SChat = require "PB.net".C2SChat
		
		local protocol = C2SChat()
		local StrMsg = ""
        --Modify
		local chatType = msg.MsgType
		if chatType ~= ChatType.ChatTypeVoice then  --语音聊天
			local FilterMgr = require "Utility.BadWordsFilter".Filter
			StrMsg = FilterMgr.FilterChat(msg.StrMsg)
		end
		
        local channel = msg.Channel		
        protocol.chatType = chatType
        protocol.chatChannel = channel
        protocol.text = StrMsg
		protocol.voice = msg.Voice
		protocol.voiceLength = msg.VoiceLength
		protocol.Index = msg.ItemBgIndex
		protocol.bgType = msg.ItemBgType

		if chatType == ChatType.ChatTypeLink then			
			if channel == CHAT_CHANNEL_ENUM.ChatChannelGuild then --帮派        
				if not game._GuildMan:IsHostInGuild() then
					game._GUIMan:ShowTipText(StringTable.Get(13000), false)
					-- warn("NO GUILD !!!")
					return
				end
			elseif channel == CHAT_CHANNEL_ENUM.ChatChannelTeam then --队伍
				if not CTeamMan.Instance():InTeam() then
					game._GUIMan:ShowTipText(StringTable.Get(13001), false)
					-- FlashTip(StringTable.Get(13001), "tip", 2)
					-- warn("NO TEAM!!!")
					return
				end
			end
			protocol.chatLink.LinkType = msg.LinkType
			protocol.chatLink.ContentID = msg.LinkParam1 or 0
			protocol.chatLink.TargetId = msg.Link_TargetId
			protocol.chatLink.FightScore = msg.Link_FighatScore
			protocol.chatLink.Level = msg.Link_Level
			protocol.chatLink.MapTid = msg.Link_MapId
			local vPosX, vPosY, vPosZ = game._HostPlayer:GetPosXYZ()
			protocol.chatLink.PathPos.x = vPosX
			protocol.chatLink.PathPos.y = vPosY
			protocol.chatLink.PathPos.z = vPosZ
			PBHelper.Send(protocol)
		else			
			if channel == CHAT_CHANNEL_ENUM.ChatChannelGuild then --帮派        
				if game._GuildMan:IsHostInGuild() then
					PBHelper.Send(protocol)
				else
					game._GUIMan:ShowTipText(StringTable.Get(13000), false)
					-- warn("NO GUILD !!!")
					return
				end
			elseif channel == CHAT_CHANNEL_ENUM.ChatChannelTeam then --队伍
				if not CTeamMan.Instance():InTeam() then
					game._GUIMan:ShowTipText(StringTable.Get(13001), false)
					-- FlashTip(StringTable.Get(13001), "tip", 2)
					-- warn("NO TEAM!!!")
					return
				else             
					PBHelper.Send(protocol)
				end 
			elseif channel == CHAT_CHANNEL_ENUM.ChatChannelCurrent then --当前
				if CurrentChatLevel == nil then
					CurrentChatLevel = tonumber(CElementData.GetSpecialIdTemplate(CurrentChatLevelId).Value)
				end
				if game._HostPlayer._InfoData._Level >= CurrentChatLevel then     
					PBHelper.Send(protocol)
				else
					local TipStr = CurrentChatLevel..StringTable.Get(13010)
					-- FlashTip(TipStr , "tip", 2)
					game._GUIMan:ShowTipText(TipStr, false)
				end
			elseif channel == CHAT_CHANNEL_ENUM.ChatChannelWorld then --世界
				if WorldChatLevel == nil then
					WorldChatLevel = tonumber(CElementData.GetSpecialIdTemplate(WorldChatLevelId).Value)
				end
				if game._HostPlayer._InfoData._Level >= WorldChatLevel then                            
					PBHelper.Send(protocol)
				else
					local TipStr = WorldChatLevel..StringTable.Get(13009)
					-- FlashTip(TipStr , "tip", 2)
					game._GUIMan:ShowTipText(TipStr, false)
				end
			end
		end
    end
--[[
     On S2CChat
]]
	def.method("table").OnPrtc_ChatPublic = function(self,prtc)
		local FilterMgr = require "Utility.BadWordsFilter".Filter
		local StrMsg = FilterMgr.FilterChat(prtc.text)
		--CreateMsg
		local pos,msg_send,pos_send = 0,nil,0
		local msg = self:NewMsg()
		
		--Set ChatType
		local currentType = prtc.chatType
		
		if currentType == ChatType.ChatTypeNormal then  --普通聊天
			
		elseif currentType == ChatType.ChatTypeVoice then  --语音聊天		
			-- 如果聊天界面没有打开，就自动播放语音。
			if not CPanelChatNew.Instance():IsShow() then
				self:OnAutoPlayVoice(prtc)
			end
		elseif currentType == ChatType.ChatTypeItemInfo then  --物品链接
			if prtc.itemInfo ~= nil then  								
				msg.ItemInfo = prtc.itemInfo
				-- warn("prtc.itemInfo == ", prtc.itemInfo.Tid)
				if prtc.itemInfo.Tid == 0 then 
					game._GUIMan:ShowTipText(StringTable.Get(13025), false)
					return
				end
				local itemTemplate = CElementData.GetItemTemplate(prtc.itemInfo.Tid)
				if string.find(StrMsg, itemTemplate.TextDisplayName) then
					local LinkBefore = "[l]#"..EnumDef.Quality2ColorHexStr[itemTemplate.InitQuality].." <"
					local LinkAfter = ">[-]"
					StrMsg = string.gsub(StrMsg, "<", LinkBefore)
					StrMsg = string.gsub(StrMsg, ">", LinkAfter)
				end
			end
		elseif currentType == ChatType.ChatTypeRoleInfo then  --人物链接

		elseif currentType == ChatType.ChatTypeLink then  --链接类型
			msg.LinkType = prtc.chatLink.LinkType
			msg.LinkParam1 = prtc.chatLink.ContentID
			if msg.LinkType == ChatLinkType.ChatLinkType_Team then   	--队伍邀请链接						
				StrMsg = CTeamMan.Instance():GetLinkStr(prtc.chatLink.TargetId, prtc.chatLink.Level, prtc.chatLink.FightScore)	
			elseif msg.LinkType == ChatLinkType.ChatLinkType_Path then	
        		if string.find(StrMsg, math.ceil(prtc.chatLink.PathPos.x)) and string.find(StrMsg, math.ceil(prtc.chatLink.PathPos.z)) then
					local LinkBefore = "[l]<"
					local LinkAfter = ">[-]"
					StrMsg = string.gsub(StrMsg, "<", LinkBefore)
					StrMsg = string.gsub(StrMsg, ">", LinkAfter)
				end
				-- math.ceil(HostPlayerPosX).. "," .. math.ceil(HostPlayerPosZ)
				msg.Link_MapId = prtc.chatLink.MapTid
				msg.Link_PathPos = prtc.chatLink.PathPos
			end
		else
			warn("UnKnown Chat Type , Please check!")
			return
		end

		--Same Block
		do
			msg.RoleId = prtc.senderInfo.Id
			msg.PlayerName = prtc.senderInfo.Name
			msg.Channel = prtc.chatChannel
			msg.MsgType = currentType
			msg.StrMsg = StrMsg
			msg.Voice = prtc.voice
			msg.VoiceLength = math.ceil(prtc.voiceLength)
			msg.Level = prtc.senderInfo.Level
			msg.Prof = prtc.senderInfo.HeadIcon
			msg.Gender = prtc.senderInfo.Gender
			msg.StrRecvMsg = StrMsg

			msg.Result = SendStatus.Success
		end
		-- 添加到消息列表
		self._MsgList[#self._MsgList + 1] = msg
		self:AddToMsgChain(msg)	
		-- 世界频道聊天剩余免费次数
		if msg.RoleId == game._HostPlayer._ID then
			if msg.Channel == CHAT_CHANNEL_ENUM.ChatChannelWorld and game._HostPlayer._InfoData._WorldChatCount > 0 then
				-- 如果当前类型为超链接，则不扣世界频道聊天次数。
				if currentType == ChatType.ChatTypeLink then return end
				local SurplusCount = game._HostPlayer._InfoData._WorldChatCount - 1
				if SurplusCount == 0 then
					game._GUIMan:ShowTipText(StringTable.Get(13023), false)
				else
					game._GUIMan:ShowTipText(string.format(StringTable.Get(13024), SurplusCount), false)
				end
				game._HostPlayer._InfoData._WorldChatCount = SurplusCount
			end
		end
	end

	def.method().UpdateChatSetStates = function (self)
		--更新聊天选中状态
		local Channel_World = UserData:GetField("Channel_World")
		if Channel_World ~= nil then
			self._Channel_World = Channel_World
		end
		local Channel_Guild = UserData:GetField("Channel_Guild")
		if Channel_Guild ~= nil then
			self._Channel_Guild = Channel_Guild
		end
		local Channel_System = UserData:GetField("Channel_System")
		if Channel_System ~= nil then
			self._Channel_System = Channel_System
		end
		local Channel_Team = UserData:GetField("Channel_Team")
		if Channel_Team ~= nil then
			self._Channel_Team = Channel_Team
		end
		local Channel_Current = UserData:GetField("Channel_Current")
		if Channel_Current ~= nil then
			self._Channel_Current = Channel_Current
		end
	
		local Channel_Combat = UserData:GetField("Channel_Combat")
		if Channel_Combat ~= nil then
			self._Channel_Combat = Channel_Combat
		end
	
		local Channel_Social = UserData:GetField("Channel_Social")
		if Channel_Social ~= nil then
			self._Channel_Social = Channel_Social
		end	
	end
end

ChatManager.Commit()
return ChatManager
