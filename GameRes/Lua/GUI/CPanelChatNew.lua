local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local ChatManager = Lplus.ForwardDeclare("ChatManager")
local ChatContentBuild = require "Chat.ChatContentBuild"
local CElementData = require "Data.CElementData"
local ChatChannel = require "PB.data".ChatChannel
local Chattype = require "PB.data".ChatType
local CTeamMan = require "Team.CTeamMan"
local CPageFriendChat = require "GUI.CPageFriendChat"
local TeamJoinOrQuitEvent = require "Events.TeamJoinOrQuitEvent"
local MenuComponents = require "GUI.MenuComponents"
local CPanelEmotions = require "GUI.CPanelEmotions"

local CPanelChatNew = Lplus.Extend(CPanelBase, 'CPanelChatNew')
local def = CPanelChatNew.define

def.field('userdata')._Frame_PlayerChat = nil
def.field('userdata')._Input_Chat = nil
def.field('userdata')._Frame_Me = nil
def.field('userdata')._Frame_Chat = nil
def.field("userdata")._Frame_FriendChat = nil 
def.field('userdata')._Btn_Send = nil
def.field('userdata')._Frame_SystemChat = nil
def.field("userdata")._Frame_RecentList = nil 
def.field("userdata")._Frame_FriendScroll = nil 
def.field("userdata")._Frame_FriendTitle = nil
def.field("userdata")._Img_ChatBg = nil 
def.field('userdata')._Btn_Face = nil
def.field('userdata')._Frame_ChatInput = nil
def.field('userdata')._Chatobj = nil
def.field('userdata')._Lab_Prop = nil
def.field('userdata')._Btn_NewMsg = nil
def.field('userdata')._Rdo_TagGroup = nil
def.field("userdata")._Lab_Title = nil 
def.field("userdata")._EmotionPosition = nil 
def.field("userdata")._Frame_QuickMsg = nil 
-- def.field("userdata")._List_QuickMsg = nil
def.field('table')._ChatObject = BlankTable
def.field('number')._Channel = -1
def.field('number')._ChatType = Chattype.ChatTypeNormal  -- 默认文本聊天
def.field('number')._ItemIndex = 0  --背包中对应服务器的index
def.field('number')._ItemType = 0   --背包的类型
def.field('string')._ItemName = ""  --物品名称
def.field('number')._M_timerId = 0
def.field('boolean')._IsPointerOver = true
def.field('boolean')._IsRecording = true  -- 是否正在录音
def.field('boolean')._FirstLockChat = false -- 标记是否第一次进入分页
def.field('number')._ScrollRect_timer = 0
def.field('number')._AnchorPositionY = 0
def.field('number')._AnchoredPositionHeight = 0
def.field('number')._Drag_timerId = 0
def.field('boolean')._IsShowQuickMsg = false -- 是否显示快捷消息
def.field('table')._QuickMsgList = BlankTable
def.field('table')._QuickMsgObjList = BlankTable
def.field("number")._MaxQuickMsgNum = 10                 -- 最大快捷消息数量

local instance = nil
def.static('=>', CPanelChatNew).Instance = function ()
	if not instance then
        instance = CPanelChatNew()
        instance._PrefabPath = PATH.UI_ChatNew
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance._ClickInterval = 1
        instance:SetupSortingParam()
	end
	return instance
end

local function OnEntityClick(sender, event)
    if event._Param ~= nil and instance:IsShow() and event._Param ~= instance._Panel.name then
        if event._Param == "Panel_Main_MiniMap(Clone)" 
        or event._Param == "UI_ActivityEntrance(Clone)" then
            if instance:IsShow() then
                game._GUIMan:Close("CPanelChatNew")
            end
        end
    end
end

local function OnTeamJoinOrQuitEvent(sender, event)
    if instance._Channel == ChatChannel.ChatChannelTeam then
        if event._InTeam == true then
            instance._Frame_ChatInput:SetActive(true)
            instance:GetUIObject('Input_Chat'):SetActive(true)
            instance._Lab_Prop:SetActive(false)
            -- 暂时是进入队伍后关闭界面  lzl。
            if instance:IsShow() then
                game._GUIMan:Close("CPanelChatNew")
            end
        else
            instance._Frame_ChatInput:SetActive(false)
            instance:GetUIObject('Input_Chat'):SetActive(false)
            instance._Lab_Prop:SetActive(true)
            instance._Lab_Prop:GetComponent(ClassType.Text).text = string.format(StringTable.Get(13014), StringTable.Get(13016))
        end
    end
end

-- 第一次打开直接打开私聊
def.override().OnCreate = function(self)
    GameUtil.EnableReversedRaycast(self._Panel)     --开启反面检测
    self._Frame_PlayerChat = self:GetUIObject('Frame_PlayerChat')
    self._Frame_SystemChat = self:GetUIObject('Frame_SystemChat')
    self._Frame_Me = self:GetUIObject('Frame_Me')
    self._Frame_Chat = self:GetUIObject('Frame_Chat')
    self._Frame_FriendChat = self:GetUIObject("Frame_FriendChat")
    self._Input_Chat = self:GetUIObject('Input_Chat'):GetComponent(ClassType.InputField)
    self._Btn_Send = self:GetUIObject('Btn_Send')
    self._Lab_Title = self:GetUIObject("Lab_Title")
    self._Btn_Face = self:GetUIObject('Btn_Face')
    self._Lab_Prop = self:GetUIObject("Lab_Prop")
    self._Frame_ChatInput = self:GetUIObject('Frame_ChatInput')
    self._Btn_NewMsg = self:GetUIObject('Btn_NewMsg')
    self._Rdo_TagGroup = self:GetUIObject('Rdo_TagGroup')
    self._EmotionPosition = self:GetUIObject("EmotionPanelPosition")
    self._Frame_RecentList = self:GetUIObject("Frame_RecentList")
    self._Frame_FriendScroll = self:GetUIObject("Frame_FriendScroll")
    self._Frame_FriendTitle = self:GetUIObject("Frame_FriendTitle")
    self._Img_ChatBg = self:GetUIObject("Img_ChatBG")
    self._Frame_QuickMsg = self:GetUIObject("Frame_QuickMsg")
    self._Frame_FriendTitle:SetActive(false)
    self._Img_ChatBg:SetActive(true)
    self._Frame_FriendScroll:SetActive(false)
    self._Frame_RecentList:SetActive(false)
    self._Channel = ChatChannel.ChatChannelWorld   -- 默认频道为世界频道
    GUI.SetGroupToggleOn(self._Rdo_TagGroup, self._Channel + 1)
    GUI.SetText(self._Lab_Title,StringTable.Get(13051))
    self:GetChannelToToggle(self._Channel)
    -- self._List_QuickMsg = self:GetUIObject('List_QuickMsg'):GetComponent(ClassType.GNewList)
    self._FirstLockChat = false
    self._QuickMsgList = _G.QuickMsgTable
    CGame.EventManager:addHandler('NotifyClick', OnEntityClick)
    CGame.EventManager:addHandler('TeamJoinOrQuitEvent', OnTeamJoinOrQuitEvent)
	-- CGame.EventManager:addHandler(NotifyGuildEvent, OnNotifyGuildEvent)
    self._IsShowQuickMsg = false

    for i = 1, self._MaxQuickMsgNum do
        table.insert(self._QuickMsgObjList, self:GetUIObject("List_QuickMsg"):FindChild("QuickMsg".. i))
    end
end

def.override("dynamic").OnData = function(self,data)
    self:ShowChatObjData()
    self:ShowChatMsg()
    if data == 1 then
        game._GUIMan:CloseByScript(self)
        return
    elseif data ~= nil and data.DataName ~= nil and data.DataName == "ItemLinkInfo" then
        self._Channel = ChatChannel. ChatChannelWorld
        GUI.SetGroupToggleOn(self._Rdo_TagGroup, self._Channel + 1)
        self:GetChannelToToggle(self._Channel)
        self:ItemLinkInfo(data.item_data._Slot, data.bag_type, data.item_data:GetNameText())
    elseif data ~= nil and data.IsOpenFriendChat ~= nil and data.IsOpenFriendChat then 
        for i = 1 ,7 do
            local Rdo_Tag = self:GetUIObject("Rdo_Tag"..i)
            local isOpen = (i == 7)
            Rdo_Tag:GetComponent(ClassType.Toggle).isOn = isOpen
        end
        self:OpenFriendChat(data.RoleData)
    end
    local Obj = self:GetUIObject("Rdo_Tag7"):FindChild("Img_RedPoint")
    CPageFriendChat.Instance():ShowRedPoint(Obj)
    if CPageFriendChat.Instance()._IsInDelete then 
        CPageFriendChat.Instance()._IsInDelete = false
        self:OpenRecentList()
    end
end

def.override('string').OnClick = function(self, id)
    if _G.ForbidTimerId ~= 0 then               --不允许输入
        return
    end
    if id == 'Btn_Send' then
        if self._Channel == ChatChannel.ChatChannelSocial then 
            CPageFriendChat.Instance():SendMsg()
        return end
        self:OnSend()
    elseif id == 'Btn_Face' then
        local param = {
                    InputChat = self._Input_Chat,
                    PositionObj = self._EmotionPosition,
                }
        game._GUIMan:Open("CPanelEmotions",param)
    elseif id == 'Btn_Close' then
        game._GUIMan:Close("CPanelChatNew")
    elseif string.find(id, "Btn_SendQuickMsg") then
        local index = tonumber(string.sub(id, string.len("Btn_SendQuickMsg")+1,-1))
        local item = self._QuickMsgObjList[index]
        local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
        self._IsShowQuickMsg = not self._IsShowQuickMsg
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg)
        self._Input_Chat.text = QuickMsg_Input.text
        self:OnSend()
        self:SaveQuickMsgToData()
    elseif id == 'Btn_QuickMsg' then
        self._IsShowQuickMsg = not self._IsShowQuickMsg
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg)
        if self._QuickMsgList == nil then return end
        self:SaveQuickMsgToData()
        local account = game._NetMan._UserName
		local UserData = require "Data.UserData"
		local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.QuickMsg, account)
		if accountInfo ~= nil then
			local serverInfo = accountInfo[game._NetMan._ServerName]
			if serverInfo ~= nil then
				local roleInfo = serverInfo[game._HostPlayer._ID]
				if roleInfo ~= nil then
					local listFx = roleInfo["QuickMsg"]
					if listFx ~= nil then
						if self._QuickMsgList == nil then
							self._QuickMsgList = {}
						end
                        for i,v in ipairs(listFx) do
							self._QuickMsgList[i] = v
						end
						UserData.Instance():SetCfg(EnumDef.LocalFields.QuickMsg, account, accountInfo)
					end
				end
			end
		end
        -- init快捷消息
        self:InitQuickMsgItem()
        
    elseif id == 'Btn_ChatSet' then
        -- 聊天设置
        game._GUIMan:Open("CPanelUIChatSet", nil)
    -- 有新消息提示
    elseif id == 'Btn_NewMsg' then
        local chatObj = nil
        if self._Channel == ChatChannel.ChatChannelSocial then 
            chatObj = self._Frame_FriendChat
        else
            chatObj = self._Frame_Chat
        end
        local height = GameUtil.GetPreferredHeight(chatObj:GetComponent(ClassType.RectTransform))  --.rect.height
        local screenRect = GameUtil.GetRootCanvasPosAndSize(self._Panel) --这个screenRect 里面有x y z w  ，  z是屏幕宽度，w是屏幕高度
        local ChatBGHeight = screenRect.w - 140
        local y = (height - ChatBGHeight)
        -- warn("lidaming y = ", y)
        chatObj:GetComponent(ClassType.RectTransform).anchoredPosition = Vector2.New(0, y)
        self._Btn_NewMsg:SetActive(false)
        self._FirstLockChat = false

    elseif string.find(id,"Btn_Board") and self._Channel ~= ChatChannel.ChatChannelSocial then
        -- warn("board btn id == ", id , (string.len("Btn_Board") - string.len(id)))      
        local msgId = string.sub(id, string.len("Btn_Board") - string.len(id)) 
        local pos = ChatManager.Instance():FindMessage(tonumber(msgId))
		-- warn("msgId == ", msgId, pos)
    	if pos > 0 then
            local msg = ChatManager.Instance()._MsgList[pos]
			if msg ~= nil then
                if msg.RoleId == game._HostPlayer._ID then return end
                local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
                game:CheckOtherPlayerInfo(msg.RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.Chat)

            end
        end
    end
    if self._Channel == ChatChannel.ChatChannelSocial then 
        CPageFriendChat.Instance():Click(id)
    end
end

def.override('string', 'number').OnScroll = function(self, id, value)
    if id == 'Img_ChatBG' then
        -- local screenRect = GameUtil.GetRootCanvasPosAndSize(self._Panel) --这个screenRect 里面有x y z w  ，  z是屏幕宽度，w是屏幕高度
        -- local ChatBGHeight = screenRect.w - 140 -- Top和Bottom固定值是140
        -- local BeforeHeight = self._Frame_Chat:GetComponent(ClassType.RectTransform).rect.height
        -- local BeforePositionHeight = BeforeHeight - ChatBGHeight
        -- local anchoredPosHeight = self._Frame_Chat:GetComponent(ClassType.RectTransform).anchoredPosition.y
        -- 可视范围的大小。
        -- warn("=============================>>", value)
        if value > -5 then
            self._Btn_NewMsg:SetActive(false)
        end
    end
    -- TO DO	
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_Emoji' then
        local imgEmoji = GUITools.GetChild(item , 0)
        GameUtil.SetEmojiSprite(imgEmoji, index)
    end
    CPageFriendChat.Instance():InitItem(item, id, index)
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)    
    if id == 'List_Emoji' then
        if self._Input_Chat == nil then
            -- warn("self._Input_Chat == nil")
            return
        end
        GameUtil.InputEmoji(self._Input_Chat, index)
    end
    CPageFriendChat.Instance():SelectItem(item, id, index)
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    CPageFriendChat.Instance():SelectItemButton(button_obj, id, id_btn, index)
end

def.method().InitQuickMsgItem = function(self)
    for i = 1, self._MaxQuickMsgNum do
        local QuickMsgItem = self._QuickMsgObjList[i]
        if not IsNil(QuickMsgItem) then
            local QuickMsg_Input = GUITools.GetChild(QuickMsgItem , 1)
            QuickMsg_Input.name = "Input_QuickMsg" .. i
            QuickMsg_Input:GetComponent(ClassType.InputField).text = self._QuickMsgList[i]
        end
    end
end


--关闭Frame_QuickMsg的时候，缓存一次快捷消息
def.method().SaveQuickMsgToData = function (self)
    local account = game._NetMan._UserName
    local UserData = require "Data.UserData"
    local accountInfo = UserData.Instance():GetCfg(EnumDef.LocalFields.QuickMsg, account)
    if accountInfo == nil then
        accountInfo = {}
    end
    local serverName = game._NetMan._ServerName
    if accountInfo[serverName] == nil then
        accountInfo[serverName] = {}
    end
            
    local roleIndex = game._HostPlayer._ID  
    if accountInfo[serverName][roleIndex] == nil then
        accountInfo[serverName][roleIndex] = {}
    end

    local QuickMsglist = accountInfo[serverName][roleIndex]["QuickMsg"]
    QuickMsglist = {}  --不管有没有新数据，全都重新存一遍	

    if self._QuickMsgList ~= nil and #self._QuickMsgList > 0 then		
        for i,v in ipairs(self._QuickMsgList) do
            local item = self._QuickMsgObjList[i]
            if item == nil then return end
            local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
            local FilterMgr = require "Utility.BadWordsFilter".Filter
			local StrMsg = FilterMgr.FilterChat(QuickMsg_Input.text)
            QuickMsglist[#QuickMsglist + 1] = StrMsg			
        end
    else
        accountInfo[serverName][roleIndex]["QuickMsg"] = nil
    end
    accountInfo[serverName][roleIndex]["QuickMsg"] = QuickMsglist    
    UserData.Instance():SetCfg(EnumDef.LocalFields.QuickMsg, account, accountInfo)
end

def.method('number', 'number').OnGTextClick = function(self, msgId, linkId)    
    -- warn("lidaming --------------> linkId ==", linkId)
    if linkId ~= 0 then
        -- warn("lidaming -----> OnGTextClick msgId == ", msgId)
        if self._Channel == ChatChannel.ChatChannelSocial then 
            CPageFriendChat.Instance():LinkClick(msgId)
        else
            ChatManager.Instance():OnLinkClick(msgId, linkId)
        end
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)    
    self._FirstLockChat = false
    local index = tonumber(string.sub(id,-1))
    GUI.SetText(self._Lab_Title,StringTable.Get(13049 + index))
	if id == "Rdo_Tag1" and checked then
        self._Channel = ChatChannel.ChatChannelSystem
	elseif id == "Rdo_Tag2" and checked then
        self._Channel = ChatChannel.ChatChannelWorld  
    elseif id == "Rdo_Tag3" and checked then
        self._Channel = ChatChannel.ChatChannelCurrent
    elseif id == "Rdo_Tag4" and checked then
        self._Channel = ChatChannel.ChatChannelTeam
    elseif id == "Rdo_Tag5" and checked then
        self._Channel = ChatChannel.ChatChannelGuild
    elseif id == "Rdo_Tag6" and checked then
        self._Channel = ChatChannel.ChatChannelCombat
    elseif id == "Rdo_Tag7" and checked then
        self._Channel = ChatChannel.ChatChannelSocial
        self:OpenRecentList()
        return
    end
    CPageFriendChat.Instance():Hide()
    self:GetChannelToToggle(self._Channel)
end

def.method().OnSend = function(self)
    if self._Input_Chat == nil then return end
    local strText = self._Input_Chat.text
    -- if not self:CheckValid() then
    --     return
    -- else
    if string.len(strText) <= 0 then
        -- FlashTip("Please Input Text!", "tip", 2)
        game._GUIMan: ShowTipText(StringTable.Get(13019),true)
        -- warn("Please Input Text!")
        return
    end
    local BAGTYPE = require "PB.net".BAGTYPE
    if self:HideDebugLogFPS(strText) == false then return end

    local msg = ChatManager.Instance():NewMsgEx()
    msg.RoleId = game._HostPlayer._ID
    msg.PlayerName = game._HostPlayer._InfoData._Name
    msg.Channel = self._Channel
    local itemInfo = CPanelEmotions.Instance():IsSendItemLink()
    if itemInfo ~= nil then 
        self._ChatType = Chattype.ChatTypeItemInfo
        self._ItemIndex = itemInfo._Slot
        if itemInfo._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then 
            self._ItemType = BAGTYPE.ROLE_EQUIP
        elseif itemInfo._PackageType == IVTRTYPE_ENUM.IVTRTYPE_PACK then
            self._ItemType = BAGTYPE.BACKPACK
        else
            self._ItemType = BAGTYPE.BACKPACK
        end
    end
    local IsSendPositionLink = CPanelEmotions.Instance():IsSendPositionLink()
    if IsSendPositionLink then        
        self._ChatType = Chattype.ChatTypeLink
        msg.LinkType = require "PB.data".ChatLinkType.ChatLinkType_Path
        msg.LinkParam1 = game._CurWorld._WorldInfo.SceneTid
        msg.Link_MapId = game._CurWorld._WorldInfo.SceneTid
        msg.Link_PathPos = game._HostPlayer:GetPosXYZ()      
    end
    msg.MsgType = self._ChatType  
    msg.Prof = game._HostPlayer._InfoData._Prof
    msg.Level = game._HostPlayer._InfoData._Level
    msg.StrMsg = strText
    msg.Voice = ""  -- 录音的string
    msg.ItemBgIndex = self._ItemIndex
    msg.ItemBgType = self._ItemType
    msg.Status = ReadStatus.Read
    msg.Result = SendStatus.Sending --正在发送
    --发送
    ChatManager.Instance():SendMsg(msg)    
end

-- Debug(c 0/1), Log(l 0/1), FPS(f 0/1) --->  1 开启, 0 关闭
def.method("string", "=>" ,"boolean").HideDebugLogFPS = function(self, strText)
    if string.find(strText,"c") ~= nil then
        local hidedebug = nil
        if strText == "c 1" then
            hidedebug = true
        elseif strText == "c 0" then
            hidedebug = false
        end

        if hidedebug ~= nil then
            game:HideDebug(hidedebug)
        else
            return true
        end
        
        return false
    elseif string.find(strText,"l") ~= nil then    
        local hidelog = nil 
        if strText == "l 1" then
            hidelog = true
        elseif strText == "l 0" then
            hidelog = false
        end
        if hidelog ~= nil then
            game:HideLog(hidelog)
        else
            return true
        end        
        return false
    elseif string.find(strText,"f") ~= nil then 
        local hideFPS = nil
        if strText == "f 1" then
            hideFPS = true
        elseif strText == "f 0" then
            hideFPS = false
        end
        if hideFPS ~= nil then
            game:HideFPSPing(hideFPS)
        else
            return true
        end
        return false
    else
        return true
    end
end

-- 物品链接信息
def.method("number","number","string").ItemLinkInfo = function(self,ItemBgIndex,ItemBgType,ItemName)
    if self._Input_Chat == nil then
        return
    end
    self._ItemIndex = ItemBgIndex
    self._ItemType = ItemBgType    
    self._ItemName = ItemName
    local strText = self._Input_Chat.text
    if string.find(strText,"<") == nil then
        strText = strText.."<"..self._ItemName..">"
    else        
        strText = string.gsub(strText, "%b<>", "<"..self._ItemName..">" )
    end
    self._ChatType = Chattype.ChatTypeItemInfo
    self._Input_Chat.text = strText
end

-- 切换频道（如果是系统频道，隐藏输入框）
def.method("number").GetChannelToToggle = function(self, toggleChannel)
    local is_channel_system = true
    if toggleChannel == ChatChannel.ChatChannelGuild then
        if not game._GuildMan:IsHostInGuild() then
            self._Frame_ChatInput:SetActive(false)
            self:GetUIObject('Input_Chat'):SetActive(false)
            self._Lab_Prop:SetActive(true)
            self._Lab_Prop:GetComponent(ClassType.Text).text =  string.format(StringTable.Get(13014), StringTable.Get(13015))
        else
            self._Frame_ChatInput:SetActive(true)
            self:GetUIObject('Input_Chat'):SetActive(true)
            self._Lab_Prop:SetActive(false)
        end
    elseif toggleChannel == ChatChannel.ChatChannelTeam then
        if not CTeamMan.Instance():InTeam() then
            self._Frame_ChatInput:SetActive(false)
            self:GetUIObject('Input_Chat'):SetActive(false)
            self._Lab_Prop:SetActive(true)
            self._Lab_Prop:GetComponent(ClassType.Text).text =  string.format(StringTable.Get(13014), StringTable.Get(13016))
        else
            self._Frame_ChatInput:SetActive(true)
            self:GetUIObject('Input_Chat'):SetActive(true)
            self._Lab_Prop:SetActive(false)
        end
    elseif toggleChannel == ChatChannel.ChatChannelSystem then
        self._Frame_ChatInput:SetActive(false)
        self:GetUIObject('Input_Chat'):SetActive(false)
        self._Lab_Prop:SetActive(true)
        self._Lab_Prop:GetComponent(ClassType.Text).text =  StringTable.Get(13017)
    elseif toggleChannel == ChatChannel.ChatChannelCombat then
        self._Frame_ChatInput:SetActive(false)
        self:GetUIObject('Input_Chat'):SetActive(false)
        self._Lab_Prop:SetActive(true)
        self._Lab_Prop:GetComponent(ClassType.Text).text =  StringTable.Get(13037)
    else
        self._Frame_ChatInput:SetActive(true)
        self:GetUIObject('Input_Chat'):SetActive(true)
        self._Lab_Prop:SetActive(false)
    end    
    self:ShowChatObjData()    
    self:ShowChatMsg()
end

def.method().ShowChatObjData = function(self)
    local count = #self._ChatObject
    for i = 1, count do
       Object.DestroyImmediate(self._ChatObject[i])
    end
    self._ChatObject = {}
end

--显示一条聊天信息
def.method("table").ShowOneChatMsgEx = function(self,msg)
    if self._Frame_Chat == nil then return end
    
	if self._Channel == msg.Channel then   --一条消息的频道是否等于当前频道
		local strnew = ChatContentBuild.BuildOneMsg(msg)
		if msg.Status == ReadStatus.NotRead then
			msg.Status = ReadStatus.Read
		end
    else
        return  --不是当前频道就直接return
	end   

    local index = msg.UniqueMsgID
    -- warn("lidaming ShowOneChatMsgEx msg.UniqueMsgID == ", index)
    if index > 0 then            
        if (msg.Channel == ChatChannel.ChatChannelCurrent or
                msg.Channel == ChatChannel.ChatChannelWorld or
                msg.Channel == ChatChannel.ChatChannelTeam or
                msg.Channel == ChatChannel.ChatChannelGuild) then
            if msg.Prof == 0 or msg.Level == 0 then
                self:InstSystemChat()        
                local gtextComp = GUITools.GetChild(self._Chatobj , 4)
                GUI.SetText(gtextComp, tostring(msg.StrMsg))
                gtextComp:GetComponent(ClassType.GText).TextID = msg.UniqueMsgID
                -- GUITools.SetGroupImg(GUITools.GetChild(self._Chatobj , 0),msg.Channel)
                local lab_channel = GUITools.GetChild(self._Chatobj , 0)
                local chatcfg = _G.ChatCfgTable.Channel[msg.Channel]
                GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
                GUI.SetTextAndChangeLayout(gtextComp, tostring(msg.StrMsg), 320) 
            else
                local headIconPath = nil
                -- warn("msg.gender == ", msg.gender)
                if msg.Gender == EnumDef.Gender.Female then
                    headIconPath = CElementData.GetProfessionTemplate(msg.Prof).FemaleIconAtlasPath
                else
                    headIconPath = CElementData.GetProfessionTemplate(msg.Prof).MaleIconAtlasPath
                end
                if msg.RoleId == game._HostPlayer._ID then --是玩家自己发的
                    -- 玩家自己发送成功,清空发送
                    self._Input_Chat.text = ""
                    self:InstMeChat()
                    GUITools.SetHeadIcon(GUITools.GetChild(self._Chatobj , 1),headIconPath)
                    local leveltext = GUITools.GetChild(self._Chatobj , 2)
                    GUI.SetText(leveltext, tostring(msg.Level))
                    local chatText = GUITools.GetChild(self._Chatobj , 8)
                    local MeNameText = GUITools.GetChild(self._Chatobj , 4)
                    local chatTextBg = GUITools.GetChild(self._Chatobj , 7)
                    GUI.SetText(MeNameText, "")   --StringTable.Get(13036)
                    -- GUITools.SetGroupImg(GUITools.GetChild(self._Chatobj , 5),msg.Channel )
                    local lab_channel = GUITools.GetChild(self._Chatobj , 5)
                    local chatcfg = _G.ChatCfgTable.Channel[msg.Channel]
                    GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
                    chatText:GetComponent(ClassType.GText).TextID = msg.UniqueMsgID 
                    local Lab_VoiceTime = GUITools.GetChild(self._Chatobj , 12)                    
                    local btn_playVoice = GUITools.GetChild(self._Chatobj , 13) 
                    local img_playVoice = GUITools.GetChild(self._Chatobj , 10) 
                    btn_playVoice.name = "Btn_MeVoice" .. msg.UniqueMsgID     

                    local btn_board = GUITools.GetChild(self._Chatobj , 0)
                    btn_board.name = "Btn_Board" .. msg.UniqueMsgID

                    -- warn("Lab_VoiceTime.name == ", Lab_VoiceTime.name)                          
                    if msg.MsgType ~= Chattype.ChatTypeVoice then
                        btn_playVoice:SetActive(false)
                        img_playVoice:SetActive(false)
                        chatText:SetActive(true)
                        GUI.SetText(chatText, tostring(msg.StrMsg))  
                        GUI.SetTextAndChangeLayout(chatText, tostring(msg.StrMsg), 270)                                         
                    end
                else
                    self:InstPlayerChat()        
                    local playerNametext = GUITools.GetChild(self._Chatobj , 5)
                    GUI.SetText(playerNametext, tostring(msg.PlayerName))
                    GUITools.SetHeadIcon(GUITools.GetChild(self._Chatobj , 1),headIconPath)                    
                    local leveltext = GUITools.GetChild(self._Chatobj , 2)
                    GUI.SetText(leveltext, tostring(msg.Level))
                    -- GUITools.SetGroupImg(GUITools.GetChild(self._Chatobj , 4),msg.Channel )
                    local lab_channel = GUITools.GetChild(self._Chatobj , 4)
                    local chatcfg = _G.ChatCfgTable.Channel[msg.Channel]
                    GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
                    local gtextCompBg = GUITools.GetChild(self._Chatobj , 10)
                    local gtextComp = GUITools.GetChild(self._Chatobj , 11)
                    gtextComp:GetComponent(ClassType.GText).TextID = msg.UniqueMsgID
                    local Lab_VoiceTime = GUITools.GetChild(self._Chatobj , 9)
                    local img_playVoice = GUITools.GetChild(self._Chatobj , 7)
                    local btn_playVoice = GUITools.GetChild(self._Chatobj , 13)
                    btn_playVoice.name = "Btn_PlayerVoice" .. msg.UniqueMsgID

                    local btn_board = GUITools.GetChild(self._Chatobj , 0)
                    btn_board.name = "Btn_Board" .. msg.UniqueMsgID
                    
                    -- warn("Lab_VoiceTime.name == ", Lab_VoiceTime.name)   
                    if msg.MsgType ~= Chattype.ChatTypeVoice then
                        btn_playVoice:SetActive(false)
                        img_playVoice:SetActive(false)
                        gtextComp:SetActive(true)
                        GUI.SetText(gtextComp, tostring(msg.StrMsg))  
                        GUI.SetTextAndChangeLayout(gtextComp, tostring(msg.StrMsg), 270)                                                  
                    end
                end 
            end
        elseif msg.Channel == ChatChannel.ChatChannelSystem
            or msg.Channel == ChatChannel.ChatChannelCombat then
            self:InstSystemChat()        
            local gtextComp = GUITools.GetChild(self._Chatobj , 4)
            GUI.SetText(gtextComp, tostring(msg.StrMsg))
            GUI.SetTextAndChangeLayout(gtextComp, tostring(msg.StrMsg), 320) 
            gtextComp:GetComponent(ClassType.GText).TextID = msg.UniqueMsgID
            -- GUITools.SetGroupImg(GUITools.GetChild(self._Chatobj , 0),msg.Channel )
            local lab_channel = GUITools.GetChild(self._Chatobj , 0)
            local chatcfg = _G.ChatCfgTable.Channel[msg.Channel]
            GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
        end
        self:ChatContentHeight() 
    end
end

--显示聊天窗口的所有聊天记录
def.method().ShowChatMsg = function(self)
    local msg = ChatManager.Instance():GetMsgByChannel(self._Channel)
    if msg == nil then return end  
    for i =1, #msg do 
        local strnew = ChatContentBuild.BuildOneMsg(msg[i])        
        if (self._Channel == ChatChannel.ChatChannelCurrent or
			self._Channel == ChatChannel.ChatChannelWorld or
			self._Channel == ChatChannel.ChatChannelTeam or
			self._Channel == ChatChannel.ChatChannelGuild) then
            if msg[i].Prof == 0 or msg[i].Level == 0 then
                self:InstSystemChat()        
                local gtextComp = GUITools.GetChild(self._Chatobj , 4)
                GUI.SetText(gtextComp, tostring(msg[i].StrMsg))
                gtextComp:GetComponent(ClassType.GText).TextID = msg[i].UniqueMsgID
                local lab_channel = GUITools.GetChild(self._Chatobj , 0)
                local chatcfg = _G.ChatCfgTable.Channel[self._Channel]
                GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
                GUI.SetTextAndChangeLayout(gtextComp, tostring(msg[i].StrMsg), 320) 
            else
                local headIconPath = nil
                if msg[i].Gender == EnumDef.Gender.Female then
                    headIconPath = CElementData.GetProfessionTemplate(msg[i].Prof).FemaleIconAtlasPath
                else
                    headIconPath = CElementData.GetProfessionTemplate(msg[i].Prof).MaleIconAtlasPath
                end
                if msg[i].RoleId == game._HostPlayer._ID then --是玩家自己发的                
                    self:InstMeChat()                
                    local chatText = GUITools.GetChild(self._Chatobj , 8)
                    
                    chatText:GetComponent(ClassType.GText).TextID = msg[i].UniqueMsgID

                    GUITools.SetHeadIcon(GUITools.GetChild(self._Chatobj , 1), headIconPath)
                    local levelText = GUITools.GetChild(self._Chatobj , 2)
                    local MeNameText = GUITools.GetChild(self._Chatobj , 4)
                    GUI.SetText(MeNameText, "")  -- StringTable.Get(13036)
                    local lab_channel = GUITools.GetChild(self._Chatobj , 5)
                    local chatcfg = _G.ChatCfgTable.Channel[msg[i].Channel]
                    GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
                    GUI.SetText(levelText, tostring(msg[i].Level))
                    local Lab_VoiceTime = GUITools.GetChild(self._Chatobj , 12)
                    
                    local btn_playVoice = GUITools.GetChild(self._Chatobj , 13) 
                    local img_playVoice = GUITools.GetChild(self._Chatobj , 10) 
                     
                    local chatTextBg = GUITools.GetChild(self._Chatobj , 7)
                    btn_playVoice.name = "Btn_MeVoice" .. msg[i].UniqueMsgID  
                    
                    local btn_board = GUITools.GetChild(self._Chatobj , 0)
                    btn_board.name = "Btn_Board" .. msg[i].UniqueMsgID  

                    -- warn("Lab_VoiceTime == ", Lab_VoiceTime.name)          
                    if msg[i].MsgType ~= Chattype.ChatTypeVoice then                  
                        btn_playVoice:SetActive(false)
                        img_playVoice:SetActive(false)
                        chatText:SetActive(true)
                        GUI.SetText(chatText, tostring(msg[i].StrMsg))  
                        GUI.SetTextAndChangeLayout(chatText, tostring(msg[i].StrMsg), 270)                                           
                    end
                else
                    self:InstPlayerChat()
                    local playerNameText = GUITools.GetChild(self._Chatobj , 5)
                    GUI.SetText(playerNameText, tostring(msg[i].PlayerName))
                    GUITools.SetHeadIcon(GUITools.GetChild(self._Chatobj , 1), headIconPath)
                    local chatText = GUITools.GetChild(self._Chatobj , 11)
                    local chatTextBg = GUITools.GetChild(self._Chatobj , 10)
                    local levelText = GUITools.GetChild(self._Chatobj , 2)
                    GUI.SetText(levelText, tostring(msg[i].Level))
                    -- GUITools.SetGroupImg(GUITools.GetChild(self._Chatobj , 4),self._Channel)
                    local lab_channel = GUITools.GetChild(self._Chatobj , 4)
                    local chatcfg = _G.ChatCfgTable.Channel[self._Channel]
                    GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
                    local Lab_VoiceTime = GUITools.GetChild(self._Chatobj , 9)
                    chatText:GetComponent(ClassType.GText).TextID = msg[i].UniqueMsgID
                    local btn_playVoice = GUITools.GetChild(self._Chatobj , 13)
                    local img_playVoice = GUITools.GetChild(self._Chatobj , 7) 
                    btn_playVoice.name = "Btn_PlayerVoice" .. msg[i].UniqueMsgID  

                    local btn_board = GUITools.GetChild(self._Chatobj , 0)
                    btn_board.name = "Btn_Board" .. msg[i].UniqueMsgID  

                    -- warn("Lab_VoiceTime.name == ", Lab_VoiceTime.name)                  
                    if msg[i].MsgType ~= Chattype.ChatTypeVoice then
                        btn_playVoice:SetActive(false)
                        img_playVoice:SetActive(false)
                        chatText:SetActive(true)
                        GUI.SetText(chatText, tostring(msg[i].StrMsg))  
                        GUI.SetTextAndChangeLayout(chatText, tostring(msg[i].StrMsg), 270)                                         
                    end
                end  
            end
        elseif self._Channel == ChatChannel.ChatChannelSystem 
            or self._Channel == ChatChannel.ChatChannelCombat then
            self:InstSystemChat()        
            local gtextComp = GUITools.GetChild(self._Chatobj , 4)
            GUI.SetText(gtextComp, tostring(msg[i].StrMsg))
            GUI.SetTextAndChangeLayout(gtextComp, tostring(msg[i].StrMsg), 320)  
            gtextComp:GetComponent(ClassType.GText).TextID = msg[i].UniqueMsgID

            -- GUITools.SetGroupImg(GUITools.GetChild(self._Chatobj , 0),self._Channel )
            local lab_channel = GUITools.GetChild(self._Chatobj , 0)
            local chatcfg = _G.ChatCfgTable.Channel[self._Channel]
            GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")
        end        
    end
    self:ChatContentHeight()
end

def.method().ChatContentHeight = function(self)
    if self._Frame_Chat == nil or self._Frame_FriendChat == nil then return end
    local chatObj = nil 
    if self._Channel == ChatChannel.ChatChannelSocial then
        chatObj = self._Frame_FriendChat 
    else
        chatObj = self._Frame_Chat
    end
    local BeforeHeight = chatObj:GetComponent(ClassType.RectTransform).rect.height
    local height = GameUtil.GetPreferredHeight(chatObj:GetComponent(ClassType.RectTransform))  --.rect.height    
    local screenRect = GameUtil.GetRootCanvasPosAndSize(self._Panel) --这个screenRect 里面有x y z w  ，  z是屏幕宽度，w是屏幕高度
    local ChatBGHeight = screenRect.w - 140 -- Top和Bottom固定值是140    --GameUtil.GetPreferredHeight(self._Panel:FindChild('Img_BG/Img_ChatBG'):GetComponent(ClassType.RectTransform))
    local BeforePositionHeight = BeforeHeight - ChatBGHeight
    self._AnchoredPositionHeight = chatObj:GetComponent(ClassType.RectTransform).anchoredPosition.y
    -- warn("lidaming anchored ==" .. self._AnchoredPositionHeight , BeforePositionHeight, height) -- string.format("%d", self._AnchoredPositionHeight)
    
    -- 当前可视范围 > Mask
    if height > ChatBGHeight then
        local y = (height - ChatBGHeight) 
        

        if (BeforePositionHeight - self._AnchoredPositionHeight ) < 20 then
            self._FirstLockChat = false
        else
            self._FirstLockChat = true
        end
        -- warn("lidaming y ==" , (BeforePositionHeight - self._AnchoredPositionHeight ), self._FirstLockChat) 
        if self._FirstLockChat == true then
            self._Btn_NewMsg:SetActive(true)
        elseif self._FirstLockChat == false then
            chatObj:GetComponent(ClassType.RectTransform).anchoredPosition = Vector2.New(0, y)
            self._Btn_NewMsg:SetActive(false)  
            return
        end         
        
    elseif height <= ChatBGHeight then 
        self._Btn_NewMsg:SetActive(false) 
    end    
end

def.method().InstMeChat = function(self)
    self._Chatobj = GameObject.Instantiate(self._Frame_Me)
    table.insert(self._ChatObject,self._Chatobj)
    self._Chatobj:SetParent(self._Frame_Chat)
    self._Chatobj.localPosition = Vector3.zero   
    self._Chatobj.localScale = Vector3.one
    self._Chatobj.localRotation = Vector3.zero
    self._Chatobj:SetActive(true) 
    GUITools.RegisterGTextEventHandler(self._Panel, self._Chatobj) 
    GUITools.RegisterButtonEventHandler(self._Panel, GUITools.GetChild(self._Chatobj , 0)) 
    GUITools.RegisterButtonEventHandler(self._Panel, GUITools.GetChild(self._Chatobj , 13)) 
end

def.method().InstPlayerChat = function(self)
    self._Chatobj = GameObject.Instantiate(self._Frame_PlayerChat)
    table.insert(self._ChatObject,self._Chatobj)
    self._Chatobj:SetParent(self._Frame_Chat)
    self._Chatobj.localPosition = Vector3.zero
    self._Chatobj.localScale = Vector3.one
    self._Chatobj.localRotation = Vector3.zero
    self._Chatobj:SetActive(true)
    GUITools.RegisterGTextEventHandler(self._Panel, self._Chatobj)   
    GUITools.RegisterButtonEventHandler(self._Panel, GUITools.GetChild(self._Chatobj , 0)) 
    GUITools.RegisterButtonEventHandler(self._Panel, GUITools.GetChild(self._Chatobj , 13)) 
end

def.method().InstSystemChat = function(self)
    self._Chatobj = GameObject.Instantiate(self._Frame_SystemChat)
    table.insert(self._ChatObject,self._Chatobj)
    self._Chatobj:SetParent(self._Frame_Chat)
    self._Chatobj.localPosition = Vector3.zero
    self._Chatobj.localScale = Vector3.one
    self._Chatobj.localRotation = Vector3.zero
    self._Chatobj:SetActive(true)
    GUITools.RegisterGTextEventHandler(self._Panel, self._Chatobj)  
end

--[[]]
def.override("string", "string").OnEndEdit = function(self, id, str)
    if string.find(id, "Input_QuickMsg") then    -- if id == 'Input_Chat' then
        local index = tonumber(string.sub(id, string.len("Input_QuickMsg")+1,-1))
        local item = self._QuickMsgObjList[index]
        local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
        local FilterMgr = require "Utility.BadWordsFilter".Filter
        local StrMsg = FilterMgr.FilterChat(str)
        QuickMsg_Input.text = StrMsg
    end
end

------------------------------私聊-------------------------------
-- 直接打开私聊 开始聊天
def.method("table").OpenFriendChat = function(self,RoleData) 
    self._Channel = ChatChannel.ChatChannelSocial
    CPageFriendChat.Instance():Show(self,CPageFriendChat.OpenType.CHAT,RoleData) 
end

def.method().OpenRecentList = function(self)
    self._Channel = ChatChannel.ChatChannelSocial
    CPageFriendChat.Instance():Show(self,CPageFriendChat.OpenType.RECENTLIST,nil) 
end

def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler('NotifyClick', OnEntityClick)
    CGame.EventManager:removeHandler('TeamJoinOrQuitEvent', OnTeamJoinOrQuitEvent)
    -- CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
    self._FirstLockChat = false
    self._Channel = -1
    self._Frame_QuickMsg = nil 
    -- self._List_QuickMsg = nil
    self._QuickMsgList = {}
    CPageFriendChat.Instance():Destroy()
end

CPanelChatNew.Commit()
return CPanelChatNew 