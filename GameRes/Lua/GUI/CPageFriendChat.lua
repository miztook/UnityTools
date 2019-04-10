local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local ChatChannel = require "PB.data".ChatChannel
local CPanelEmotions = require "GUI.CPanelEmotions"
local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
local ChatType = require "PB.data".ChatType
local CElementData = require "Data.CElementData"
local CPageFriendChat = Lplus.Class("CPageFriendChat")
local MenuComponents = require "GUI.MenuComponents"
local def = CPageFriendChat.define

def.field("table")._Parent = nil 
def.field("userdata")._RdoRedPoint = nil 
def.field("userdata")._LabProp = nil 
-- 最近联系人
def.field("userdata")._FrameRecentList = nil 
def.field("userdata")._BtnChatSet = nil 
def.field("userdata")._ListRecent = nil 
def.field("userdata")._BtnCreateChat = nil 
def.field("userdata")._LabDeleteChats = nil 
def.field("userdata")._LabNo = nil 
-- 聊天
def.field("userdata")._FrameFriendTitle = nil 
def.field("userdata")._ElseScroll = nil 
def.field("userdata")._FriendScroll = nil 
def.field("userdata")._FrameChatInput = nil 
def.field("userdata")._LabPlayerName = nil
def.field("userdata")._BtnApply = nil 
def.field("userdata")._ChatPool = nil 
def.field("userdata")._ElsePlayChat = nil 
def.field("userdata")._MeChat = nil 
def.field("userdata")._FrameFriendChat = nil 
def.field("userdata")._InputChat = nil 

def.field("table")._RecentListData = nil 
def.field("number")._CurOpenType = 0
-- def.field("userdata")._CurSelectItem = nil 
def.field("number")._CurSelectIndex = 0 
def.field("boolean")._IsInDelete = false 
def.field("table")._ItemList = nil
-- 聊天数据
def.field("table")._CurChatRoleData = nil 
def.field("table")._ChatGameObjectList = nil 
def.field("table")._ChatObjPoolList = nil 
def.field("table")._PreMsg = nil 
def.field("table")._CurChatMsgListData = BlankTable 
def.field("number")._CurPlayVoiceID = 0

local OpenType = {
					NONE = 0,
					CHAT = 1,
					RECENTLIST = 2,
				}
def.const("table").OpenType = OpenType

--用于系统聊天中的好友私聊
local instance = nil
def.static("=>", CPageFriendChat).Instance = function()
	if instance == nil then
        instance = CPageFriendChat()
	end
	return instance
end

local function formatTime(time)
	local d = math.floor(time / 86400)
	local h = math.floor(time % 86400 / 3600)
	local m = math.ceil(time % 3600 / 60)
	local timeText = ""
	if d > 0 then 
		timeText = string.format(StringTable.Get(601),d)
	elseif d == 0 then 
		if h == 0 then 
			timeText = string.format(StringTable.Get(603),m)
		else 
			timeText = string.format(StringTable.Get(602),h)..string.format(StringTable.Get(603),m)
		end
	end
	return timeText
end

local function formatTime1(time)
	local retime = (GameUtil.GetServerTime() -  time)/1000 
	local d = math.floor( retime / 86400)
	local timeText = ""
	if d > 0 then 
		timeText = os.date("%m.%d",time/1000)
	elseif d == 0 then 
		timeText = os.date("%H:%M",time/1000)
	end
	return timeText
end

----------------------------------------------- 对话 -----------------------------------------
local function GetVoiceUILength(self, VoiceSecond)
    -- 语音条的最小长度和最大长度（暂时写死）
    local Img_VoicelengthMin = 82 
    local Img_VoicelengthMax = 332
    local Img_VoiceWidth = 0
    if VoiceSecond <= 5 then
        Img_VoiceWidth = Img_VoicelengthMin
    elseif VoiceSecond >= 50 then
        Img_VoiceWidth = Img_VoicelengthMax
    else
        if VoiceSecond <= 10 then
            Img_VoiceWidth = (Img_VoicelengthMax * 0.35)
        elseif VoiceSecond <= 20 then
            Img_VoiceWidth = (Img_VoicelengthMax * 0.4)
        elseif VoiceSecond <= 30 then
            Img_VoiceWidth = (Img_VoicelengthMax * 0.5)
        elseif VoiceSecond <= 40 then
            Img_VoiceWidth = (Img_VoicelengthMax * 0.7)
        elseif VoiceSecond <= 50 then
            Img_VoiceWidth = (Img_VoicelengthMax * 0.85)
        end       
    end
    return Img_VoiceWidth
end

-- 停止播放语音
local function OnStopVoice(self , fileId)
	CSoundMan.Instance():SetSoundBGMVolume(1, true)
	local ret = VoiceUtil.OffLine_StopPlayFile(fileId)
end

-- 播放语音聊天
local function OnPlayVoice(self , fileId)
	-- 先判断当前是否在播放语音，如果在播放就停止，播放当前点击的语音。
	if self._CurPlayVoiceID ~= nil then
		OnStopVoice(self,self._CurPlayVoiceID)
	end
	CSoundMan.Instance():SetSoundBGMVolume(0, true)
	local ret = VoiceUtil.OffLine_PlayRecordedFile(fileId)
	self._CurPlayVoiceID = fileId
end

-- 点击语音聊天
local function OnVoiceClick(self, msgId)
	local msg = self._CurChatMsgListData[msgId]
	if msg == nil or msg.voiceTxt ~= nil then return end
	local VoiceExist = VoiceUtil.OffLine_IsVoiceFileExist(msg.voiceTxt)
	-- local VoiceExist = true
	-- warn(" VoiceExist == false", VoiceExist)
	local resPath = msg.voiceTxt
	if VoiceExist == false then  		--判断本地是否已经存在。
		local ret = VoiceUtil.OffLine_DownloadFile(msg.voiceTxt , resPath)
	elseif VoiceExist == true then
		OnPlayVoice(self,msg.voiceTxt)
	end
end

-- 缓存对话Object物体 清除数据列表
local function ClearChatObjDataAndGameObject(self)
	if self._ChatGameObjectList == nil or #self._ChatGameObjectList == 0 then return end
	local count = #self._ChatGameObjectList
    for i = 1, count do
    	self._ChatGameObjectList[i].Obj:SetParent(self._ChatPool)
    	local item = {}
    	item.IsMe = self._ChatGameObjectList[i].IsMe
    	item.Obj = self._ChatGameObjectList[i].Obj
    	self._ChatGameObjectList[i].Obj:SetActive(false)
    	if self._ChatObjPoolList == nil then 
    		self._ChatObjPoolList = {}
    	end
    	table.insert(self._ChatObjPoolList,item)
    end
    self._ChatGameObjectList = {}
end

-- 从池中去Obj
local function GetChatObjFromPool(self,isMe)
	if self._ChatObjPoolList == nil or #self._ChatObjPoolList == 0 then return end

	for i =#self._ChatObjPoolList, 1, -1 do
        local v = self._ChatObjPoolList[i]
		if v.IsMe == isMe then 
			table.remove(self._ChatObjPoolList,i)
			return v.Obj
		end
	end
	return nil
end

local function InstPlayerChat (self)
  	local chatObj = GetChatObjFromPool(self,false)
	if chatObj == nil then 
    	chatObj = GameObject.Instantiate(self._ElsePlayChat)
    end
    local item = {IsMe = false,Obj = chatObj}
    if self._ChatGameObjectList == nil then 
    	self._ChatGameObjectList = {}
    end
    table.insert(self._ChatGameObjectList,item)
    chatObj:SetParent(self._FrameFriendChat)

    chatObj.localPosition = Vector3.zero
    chatObj.localScale = Vector3.one
    chatObj.localRotation = Vector3.zero
    chatObj:SetActive(true)
    GUITools.RegisterGTextEventHandler(self._Parent._Panel, chatObj)   
    GUITools.RegisterButtonEventHandler(self._Parent._Panel, GUITools.GetChild(chatObj , 6)) 
    GUITools.RegisterButtonEventHandler(self._Parent._Panel, GUITools.GetChild(chatObj , 11)) 
    return chatObj
end

local function InstMeChat(self)
	local chatObj = GetChatObjFromPool(self,true)
	if chatObj == nil then 
    	chatObj = GameObject.Instantiate(self._MeChat)
    end
    local item = {IsMe = true,Obj = chatObj}
    if self._ChatGameObjectList == nil then 
    	self._ChatGameObjectList = {}
    end
    table.insert(self._ChatGameObjectList,item)
    chatObj:SetParent(self._FrameFriendChat)
    chatObj.localPosition = Vector3.zero   
    chatObj.localScale = Vector3.one
    chatObj.localRotation = Vector3.zero
    chatObj:SetActive(true) 
    GUITools.RegisterGTextEventHandler(self._Parent._Panel, chatObj) 
    GUITools.RegisterButtonEventHandler(self._Parent._Panel, GUITools.GetChild(chatObj , 0)) 
    GUITools.RegisterButtonEventHandler(self._Parent._Panel, GUITools.GetChild(chatObj , 6)) 
    return chatObj
end

-- 设置单条信息
local function ShowOneChatMsg(self,msg,msgId)
	local chatObj = nil
	if msg.senderInfo.Id ~= game._HostPlayer._ID and msg.senderInfo.Id ~= -1 then 
		chatObj = InstPlayerChat(self)
	elseif msg.senderInfo.Id ~= game._HostPlayer._ID and msg.senderInfo.Id == -1 then 
		chatObj = InstPlayerChat(self)
	elseif msg.senderInfo.Id == game._HostPlayer._ID then 
		chatObj = InstMeChat(self)
	end

	local labName = GUITools.GetChild(chatObj , 0)
    local labLv = GUITools.GetChild(chatObj , 1)
    local imgHead = GUITools.GetChild(chatObj , 2)
    local labTextChat = GUITools.GetChild(chatObj , 3)
    local frameVoice = GUITools.GetChild(chatObj , 4)
    local labVoiceTime = GUITools.GetChild(chatObj , 5)                    
    local btnPlayVoice = GUITools.GetChild(chatObj , 6)
    local labChatTime = GUITools.GetChild(chatObj,7)
    local imgVoiceBg = GUITools.GetChild(chatObj,8)
    local imgSystemHead = GUITools.GetChild(chatObj,9)
	local imgLv = GUITools.GetChild(chatObj,10)
    labTextChat:GetComponent(ClassType.GText).TextID = msgId

	if self._PreMsg ~= nil then
		if (msg.time - self._PreMsg.time)/1000 >= 300 then 
			labTextChat:SetActive(true)
			GUI.SetText(labChatTime,os.date("%m-%d %H:%M", self._PreMsg.time/1000))
		else
			labChatTime:SetActive(false)
		end
	elseif self._PreMsg == nil and msgId == 1 then 
		labTextChat:SetActive(true)
		GUI.SetText(labChatTime,os.date("%m-%d %H:%M", msg.time/1000))
	else
		labChatTime:SetActive(false)
	end
	self._PreMsg = msg

    GUI.SetText(labName, msg.senderInfo.Name)
    -- 非系统消息id
    if msg.senderInfo.Id ~= -1 then
    	imgSystemHead:SetActive(false)
    	imgHead:SetActive(true)
    	if msg.senderInfo.Id ~= game._HostPlayer._ID then 
	    	GUI.SetText(labLv, tostring(self._CurChatRoleData.Level))
	    	game:SetEntityCustomImg(imgHead,msg.senderInfo.Id,self._CurChatRoleData.CustomImgSet,self._CurChatRoleData.Gender,self._CurChatRoleData.Profession)
    	else
		    GUI.SetText(labName, game._HostPlayer._InfoData._Name)
			GUI.SetText(labLv, tostring(game._HostPlayer._InfoData._Level))
	    	game:SetEntityCustomImg(imgHead,msg.senderInfo.Id,game._HostPlayer._InfoData._CustomImgSet,game._HostPlayer._InfoData._Gender,game._HostPlayer._InfoData._Prof)
    	end
    else
    	imgLv:SetActive(false)
    	imgSystemHead:SetActive(true)
    	imgHead:SetActive(false)
    end
    -- warn("msg.chatType == ChatType.ChatTypeNormal",msg.chatType == ChatType.ChatTypeNormal)
    if msg.chatType == ChatType.ChatTypeVoice then 
    	btnPlayVoice:SetActive(true)
    	frameVoice :SetActive(true)
    	labTextChat:SetActive(false)
    	btnPlayVoice.name = "Btn_PlayerVoice"..msgId
    	local voiceStr = msg.voiceLength .. "’"
        GUI.SetText(labVoiceTime, voiceStr)  
        GUI.SetImageAndChangeLayout(imgVoiceBg, GetVoiceUILength(self,msg.seconds), 332)
    elseif msg.chatType == ChatType.ChatTypeNormal or msg.chatType == ChatType.ChatTypeItemInfo  then 
    	frameVoice:SetActive(false)
    	labTextChat:SetActive(true)
	 	btnPlayVoice:SetActive(false)
	 	-- warn("msg.text    ",msg.text)
        GUI.SetText(labTextChat, tostring(msg.text))  
        GUI.SetTextAndChangeLayout(labTextChat, tostring(msg.text), 270) 
        labTextChat.name = "Lab_ChatText"..msgId   
    end
end

-- 更新右侧聊天界面显示 传来与玩家对话id 
local function ShowMsgs(self,roleId)
	-- 聊天
	self._CurChatMsgListData = game._CFriendMan:GetChatMessagesTable(roleId)
	-- warn("#self._CurChatMsgListData   ",#self._CurChatMsgListData)
	-- if #self._CurChatMsgListData == 0 then return end
	ClearChatObjDataAndGameObject(self)

	if #self._CurChatMsgListData > 0 then 
		for i,v in ipairs(self._CurChatMsgListData) do 
			ShowOneChatMsg(self,v.Msg,i)
		end
	end
    local chatObj = self._FrameFriendChat
    local height = GameUtil.GetPreferredHeight(chatObj:GetComponent(ClassType.RectTransform))  --.rect.height
    local screenRect = GameUtil.GetRootCanvasPosAndSize(self._Parent._Panel) --这个screenRect 里面有x y z w  ，  z是屏幕宽度，w是屏幕高度
    local ChatBGHeight = screenRect.w - 140
    local y = (height - ChatBGHeight)
    chatObj:GetComponent(ClassType.RectTransform).anchoredPosition = Vector2.New(0, y)
	-- self._Parent:ChatContentHeight()		
end

local function ReadRoleIdMsgs(self,RoleId)
	if self._CurChatRoleData == nil then return end

	if self._CurChatRoleData.RoleId == RoleId then 
		game._CFriendMan:ReadMsgChat(RoleId)
	end
end

-- 直接打开聊天 or 打开最近联系人列表
def.method("table","number","dynamic").Show = function(self, parent,openType,ChatRoleData)
	if self._Parent == nil then 
		self._Parent = parent
		self._FrameRecentList = self._Parent:GetUIObject("Frame_RecentList")
		self._FrameFriendTitle = self._Parent:GetUIObject("Frame_FriendTitle")
		self._ElseScroll = self._Parent:GetUIObject("Img_ChatBG")
		self._FriendScroll = self._Parent:GetUIObject("Frame_FriendScroll")
		self._FrameChatInput = self._Parent:GetUIObject("Frame_ChatInput")
		self._LabPlayerName = self._Parent:GetUIObject("Lab_ChatName")
		self._ListRecent = self._Parent:GetUIObject("List_Recent")
		self._LabNo = self._Parent:GetUIObject("Lab_NoRecent")
		self._RdoRedPoint = self._Parent:GetUIObject("Rdo_Tag7"):FindChild("Img_RedPoint")
		self._LabDeleteChats = self._Parent:GetUIObject("Lab_DeleteChats")
		self._BtnCreateChat = self._Parent:GetUIObject("Btn_CreateChat")
		self._BtnChatSet = self._Parent:GetUIObject("Btn_ChatSet")
		self._BtnApply = self._Parent:GetUIObject("Btn_AddApply")
		self._ChatPool = self._Parent:GetUIObject("FriendTemplate")
		self._ElsePlayChat = self._Parent:GetUIObject("Frame_FriendPlayerChat")
		self._MeChat = self._Parent:GetUIObject("Frame_FriendMe")
		self._FrameFriendChat = self._Parent:GetUIObject("Frame_FriendChat")
		self._InputChat = self._Parent:GetUIObject("Input_Chat")
		self._LabProp = self._Parent:GetUIObject("Lab_Prop")
	end
	self._LabProp:SetActive(false)
	self._IsInDelete = false
	self._BtnCreateChat:SetActive(true)
	GUI.SetText(self._LabDeleteChats,StringTable.Get(30345))
	if openType == OpenType.CHAT then 
		self:InitChatPanel(ChatRoleData)
	elseif openType == OpenType.RECENTLIST then 
		self._CurOpenType = OpenType.RECENTLIST
		self._FrameRecentList:SetActive(true)
		self._BtnChatSet:SetActive(false)
		self._ElseScroll:SetActive(false)
		self._FriendScroll:SetActive(false)
		self._FrameChatInput:SetActive(false)
		self._FrameFriendTitle:SetActive(false)
		self:UpdateRecentList()
	end
end

def.method("table").InitChatPanel = function(self,RoleData)
	self._CurOpenType = OpenType.CHAT
	self._InputChat:SetActive(true)
	self._ElseScroll:SetActive(false)
	self._FriendScroll:SetActive(true)
	self._FrameFriendChat:SetActive(true)
	self._FrameChatInput:SetActive(true)
	self._FrameFriendTitle:SetActive(true)
	self._FrameRecentList:SetActive(false)
	self._BtnChatSet:SetActive(false)
	GUI.SetText(self._LabPlayerName,RoleData.Name)
	if game._CFriendMan:IsFriend(RoleData.RoleId) then
		self._BtnApply:SetActive(false)
	else
		self._BtnApply:SetActive(true)
	end
	if RoleData.RoleId == -1 then 
		self._FrameChatInput:SetActive(false)
	end
	self._CurChatRoleData = RoleData
	ReadRoleIdMsgs(self,self._CurChatRoleData.RoleId)
	self:ShowRedPoint(self._RdoRedPoint)
	ShowMsgs(self,self._CurChatRoleData.RoleId)
end

def.method("string").Click = function (self,id)
	if id == "Btn_CreateChat" then 
		game._GUIMan:Open("CPanelCreateChat",nil)
	elseif id == "Btn_DeleteChats" then 
		if not self._IsInDelete then 
			if #self._RecentListData == 0 then 
				game._GUIMan:ShowTipText(StringTable.Get(30347),false)
			return end
			self._IsInDelete = true
			self._BtnCreateChat:SetActive(false)
			GUI.SetText(self._LabDeleteChats,StringTable.Get(30344))
			for i ,item in ipairs(self._ItemList) do 
				if item ~= nil then 
					local uiTemplate = item:GetComponent(ClassType.UITemplate)
					local btnDelete = uiTemplate:GetControl(7)
					local notDelete = uiTemplate:GetControl(11)
					btnDelete:SetActive(true)
					notDelete:SetActive(false)
				end
			end
			self:ShowRedPoint(self._RdoRedPoint)
		else
			self._IsInDelete = false
			self._BtnCreateChat:SetActive(true)
			GUI.SetText(self._LabDeleteChats,StringTable.Get(30345))
			self:UpdateRecentList()
		end	
	elseif id == "Btn_AddApply" then 
		game._CFriendMan:DoApply(self._CurChatRoleData.RoleId)
	elseif id == "Btn_FriendBack" then
		self._CurOpenType = OpenType.RECENTLIST
		self._FrameRecentList:SetActive(true)
		self._BtnChatSet:SetActive(false)
		self._ElseScroll:SetActive(false)
		self._FrameChatInput:SetActive(false)
		self._FrameFriendTitle:SetActive(false)
		self._FriendScroll:SetActive(false)
		self:UpdateRecentList()
	elseif id == "Btn_Board" and self._CurOpenType == OpenType.CHAT then 
		if self._CurChatRoleData.RoleId == -1 then 
			local comps = {
				            MenuComponents.RemoveRecentChatComponent.new(self._CurChatRoleData.RoleId),
				           }
			MenuList.Show(comps, nil, nil)
		else
			game:CheckOtherPlayerInfo(self._CurChatRoleData.RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.RecentList)
		end
	elseif string.find(id,"Btn_PlayerVoice")then
	    game:AddForbidTimer(self._Parent._ClickInterval)  
	    local msgId = ""
	    if string.find(id,"Btn_PlayerVoice") then
	        msgId = string.sub(id, string.len("Btn_PlayerVoice") - string.len(id))     
	    end
	    OnVoiceClick(self,tonumber(msgId))
	    game._IsSystemPlayVoice = false
	end
end

def.method('userdata', 'string', 'number').InitItem = function(self, item, id, index)
	if id == "List_Recent" then 
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		local imgHead = uiTemplate:GetControl(0)
		local labName = uiTemplate:GetControl(1)
		local imgProfession = uiTemplate:GetControl(2)
		local lablv = uiTemplate:GetControl(3)
		local labState = uiTemplate:GetControl(4)
		local labContent = uiTemplate:GetControl(5)
		local imgOffLineMsg = uiTemplate:GetControl(6)
		local btnDelete = uiTemplate:GetControl(7)
		local imgSystemHead = uiTemplate:GetControl(8)
		local labMsgNum = uiTemplate:GetControl(9)
		local labChatTime = uiTemplate:GetControl(10)
		local notDelete = uiTemplate:GetControl(11)
		local imgBg =  uiTemplate:GetControl(12)
		local imgChatBg = uiTemplate:GetControl(13)
		local data = self._RecentListData[index + 1]
		item:SetActive(true)
		table.insert(self._ItemList,item)
		notDelete:SetActive(true)
		btnDelete:SetActive(false)
		GUI.SetText(labName,data.Name)
		local msgs = game._CFriendMan:GetChatMessagesTable(data.RoleId)
		if #msgs == 0 then 
			GUI.SetText(labContent ,StringTable.Get(30352))
			imgOffLineMsg:SetActive(false)
			labChatTime:SetActive(false) 
		else
			labChatTime:SetActive(true) 
			GUI.SetText(labChatTime ,formatTime1(data.OptTime))
			if msgs[#msgs].Msg.chatType == ChatType.ChatTypeVoice then 
				GUI.SetText(labContent,StringTable.Get(30349))
		    elseif msgs[#msgs].Msg.chatType == ChatType.ChatTypeNormal or msgs[#msgs].Msg.chatType == ChatType.ChatTypeItemInfo then 
		        GUI.SetText(labContent, tostring(msgs[#msgs].Msg.text))  
		    end
			local UnreadMsgs = game._CFriendMan:GetUnreadMsgByRoleId(data.RoleId)
			if UnreadMsgs == nil then 
				imgOffLineMsg:SetActive(false) 
			else 
				imgOffLineMsg:SetActive(true)
				GUI.SetText(labMsgNum,tostring(#UnreadMsgs))
			end
		end		
		if data.RoleId == -1 then 
			imgSystemHead:SetActive(true)
			imgHead:SetActive(false)
			labState:SetActive(false)
			lablv:SetActive(false)
			imgProfession:SetActive(false)
		return end
		
		imgSystemHead:SetActive(false)
		imgHead:SetActive(true)
        game:SetEntityCustomImg(imgHead,data.RoleId,data.CustomImgSet,data.Gender,data.Profession)
        GUITools.SetGroupImg(imgProfession,data.Profession - 1)
        GUI.SetText(lablv,string.format(StringTable.Get(30327),data.Level))
        GameUtil.MakeImageGray(imgHead, not data.IsOnLine)
        GameUtil.MakeImageGray(imgBg, not data.IsOnLine) 
        GameUtil.MakeImageGray(imgChatBg, not data.IsOnLine)
		if not data.IsOnLine then
			if data.LogoutTime == nil then warn(" RECENTLIST Lack logoutTime ",data.RoleId) end
			GUI.SetText(labState,formatTime((GameUtil.GetServerTime() - data.LogoutTime)/1000) ..StringTable.Get(30343) )
			GUI.SetAlpha(imgHead,128)
			GUI.SetAlpha(imgBg,128)
			GUI.SetAlpha(imgChatBg,128)
			GUI.SetAlpha(lablv,128)
			GUI.SetAlpha(labName,128)
			GUI.SetAlpha(imgProfession,128)
			GUI.SetAlpha(labContent,128)
		else
			labState:SetActive(false)
			GUI.SetAlpha(imgHead,255)
			GUI.SetAlpha(imgBg,255)
			GUI.SetAlpha(imgChatBg,255)
			GUI.SetAlpha(lablv,255)
			GUI.SetAlpha(labName,255)
			GUI.SetAlpha(imgProfession,255)
			GUI.SetAlpha(labContent,255)
		end
	end
end

def.method("userdata", "string", "string", "number").SelectItemButton = function(self, button_obj, id, id_btn, index)
	if id_btn == "Btn_Delete" and id == "List_Recent" then 
		-- self._CurSelectItem = self._ItemList[index + 1]
		self._CurSelectIndex = index
		game._CFriendMan:DeleteMsgsAndRecentByRoleId(self._RecentListData[index + 1].RoleId,true)
	elseif id_btn == "Btn_Border" and id == "List_Recent" then 
		if self._RecentListData[index + 1].RoleId == -1 then 
			local comps = {
				            MenuComponents.RemoveRecentChatComponent.new(self._RecentListData[index + 1].RoleId),
				           }
			MenuList.Show(comps, nil, nil)
		else
			game:CheckOtherPlayerInfo(self._RecentListData[index + 1].RoleId, EOtherRoleInfoType.RoleInfo_Simple, EnumDef.GetTargetInfoOriginType.RecentList)
		end
	end
end

def.method('userdata', 'string', 'number').SelectItem = function(self, item, id, index)
	if id == "List_Recent" then
		if not self._IsInDelete then 
			self:InitChatPanel(self._RecentListData[index + 1])
		end
	end
end

def.method().SendMsg = function(self)
 	local itemInfo = CPanelEmotions.Instance():IsSendItemLink()
	if itemInfo ~= nil then 
        game._CFriendMan:DoSendItemLink(self._CurChatRoleData,self._InputChat:GetComponent(ClassType.InputField).text,itemInfo)
    else
	    game._CFriendMan:DoSendText(self._CurChatRoleData,self._InputChat:GetComponent(ClassType.InputField).text)
    end
    self._InputChat:GetComponent(ClassType.InputField).text = "" 
end

def.method().UpdateRecentList = function(self)
    if self._Parent == nil or not self._Parent:IsShow() or self._Parent._Channel ~= ChatChannel.ChatChannelSocial  then return end
	if self._IsInDelete then return end
	if not self._CurOpenType == OpenType.RECENTLIST then return end
	self._RecentListData = game._CFriendMan:GetRecentList()

	if #self._RecentListData == 0 then 
		self._LabNo:SetActive(true)
		self._ListRecent:SetActive(false)
		self._ItemList = {}
		self._ListRecent:GetComponent(ClassType.GNewList):SetItemCount(#self._RecentListData)
	return end
	self._LabNo:SetActive(false)
	self._ListRecent:SetActive(true)
	self._ItemList = {}
	warn(" #self._RecentListData 最近联系人个数 ",#self._RecentListData)
	self._ListRecent:GetComponent(ClassType.GNewList):SetItemCount(#self._RecentListData)
end

-- 删除对话成功 更新界面
def.method().UpdateDeleteChatItem = function(self)
    if self._Parent == nil or not self._Parent:IsShow() or self._Parent._Channel ~= ChatChannel.ChatChannelSocial then return end
	if not self._CurOpenType == OpenType.RECENTLIST then return end
	-- self._CurSelectItem:SetActive(false)
	self._ListRecent:GetComponent(ClassType.GNewList):RemoveItem(self._CurSelectIndex,1)
	self._CurSelectIndex = 0
	game._GUIMan:ShowTipText(StringTable.Get(30346),false)
end

def.method("table","boolean").AddChatToLast = function (self,msg,isReceive)
	-- 发送
    if self._Parent == nil or not self._Parent:IsShow() or self._Parent._Channel ~= ChatChannel.ChatChannelSocial then return end
	if not isReceive then 
		ShowOneChatMsg(self,msg,#self._CurChatMsgListData)
		self._Parent:ChatContentHeight()
	return end
	if self._CurOpenType == OpenType.RECENTLIST then 
		self:UpdateRecentList()
		self:ShowRedPoint(self._RdoRedPoint)
	elseif self._CurOpenType == OpenType.CHAT then 
		if msg.senderInfo.Id == self._CurChatRoleData.RoleId then 
			ReadRoleIdMsgs(self,msg.senderInfo.Id)
			ShowOneChatMsg(self,msg,#self._CurChatMsgListData)
            self._Parent:ChatContentHeight()
            game._CFriendMan:ReadMsgChat(msg.senderInfo.Id)
        else
        	self:ShowRedPoint(self._RdoRedPoint)
		end
	end
end

-- 删除单条对话(超出策划定义对话条数)
def.method().RemoveAtFirstChatItem = function(self)
	if self._Parent == nil then return end
	-- 删除对顶端对话
	local data = self._ChatGameObjectList[1]
    table.remove(self._ChatGameObjectList,1)
	local chatObj = data.Obj 
	chatObj:SetParent(self._ChatPool)
	if self._ChatObjPoolList == nil then 
		self._ChatObjPoolList = {}
	end
	table.insert(self._ChatObjPoolList,data)
end

def.method("userdata").ShowRedPoint = function(self,obj)
	if obj ~= nil then 
		obj:SetActive(game._CFriendMan:IsHaveUnreadMsg())
		return
	elseif self._Parent:IsShow() and self._RdoRedPoint ~= nil then 
		self._RdoRedPoint:SetActive(game._CFriendMan:IsHaveUnreadMsg())
	end
end

def.method("number").LinkClick = function(self,msgId)
    if msgId <= 0 then return end
    local msg = self._CurChatMsgListData[msgId].Msg
    if msg == nil then return end
    if msg.chatType == ChatType.ChatTypeItemInfo then
        if msg.itemInfo == nil then  return end  
        local itemTemplate = CElementData.GetItemTemplate(msg.itemInfo.Tid)
        local itemName = itemTemplate.TextDisplayName
        if string.find(msg.text, itemName) then
            CItemTipMan.ShowChatItemTips(msg.itemInfo, TipsPopFrom. CHAT_PANEL)
        end
    end
end

-- 发送语音聊天
def.method("string" , "number").SendVoiceMsg = function(self,fid,seconds)
	game._CFriendMan:DoSendVoice(self._CurChatRoleData,fid,seconds)
end

def.method().Hide = function(self)
	if self._Parent ==  nil then return end
	self._IsInDelete = false
	self._FrameChatInput:SetActive(false)
	self._FrameFriendTitle:SetActive(false)
	self._FrameRecentList:SetActive(false)
	self._BtnChatSet:SetActive(true)
	self._ElseScroll:SetActive(true)
	self._FriendScroll:SetActive(false)
	ClearChatObjDataAndGameObject(self)
end

def.method().Destroy = function(self)
	instance = nil 
end

CPageFriendChat.Commit()
return CPageFriendChat
