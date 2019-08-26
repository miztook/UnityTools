
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local ChatManager = Lplus.ForwardDeclare("ChatManager")
local ChatContentBuild = require "Chat.ChatContentBuild"
local CElementData = require "Data.CElementData"
local CPageInteractive = require "GUI.CPageInteractive"
local CPanelUIChatSet = require "GUI.CPanelUIChatSet".Instance()
local NotifyGuildEvent = require "Events.NotifyGuildEvent"
local EntityEnterEvent = require "Events.EntityEnterEvent"
local EConvoyActState = require "PB.net".EConvoyActState
local EConvoyUpdateType = require "PB.net".EConvoyUpdateType
local EItemType = require "PB.Template".Item.EItemType
local ChatChannel = require "PB.data".ChatChannel
local CTeamMan = require "Team.CTeamMan"
local CPanelChatNew = require "GUI.CPanelChatNew"
local CPanelRoleInfo = require"GUI.CPanelRoleInfo"
local CPanelMainChat = Lplus.Extend(CPanelBase, 'CPanelMainChat')
local UserData = require "Data.UserData".Instance()
local def = CPanelMainChat.define
 
def.field("userdata")._BtnCamera = nil
def.field("userdata")._PanelChat = nil
def.field("userdata")._LabelExp = nil
def.field("userdata")._ScrollExp = nil
def.field("userdata")._ViewChanel = nil
def.field("userdata")._ItemPool = nil
-- def.field("userdata")._BtnCloseImg = nil
def.field("userdata")._Btn_Bag = nil 
def.field("userdata")._PanelTween = nil 
def.field("userdata")._Item_template = nil
def.field("userdata")._ItemContent = nil
def.field("userdata")._Img_Camera = nil
def.field("boolean")._Main_Chat_Switch = true
def.field(CPageInteractive)._PageInteractive = nil --交互面板
def.field("dynamic")._SizeDelta = nil
def.field("table")._UniqueMsg = BlankTable

def.field('table')._EmotionsTable = BlankTable   --聊天表情
def.field('table')._ChatTemplate = BlankTable   --聊天对象
def.field("boolean")._IsShowRelax = false

def.field("number")._BagPercentNum = 0
def.field("userdata")._BagBg = nil
def.field("userdata")._BagCoolDown = nil
def.field("userdata")._BagBg1 = nil
def.field("userdata")._BagCoolDown1 = nil

def.field("number")._TimerId = 0

def.field("userdata")._BagCoolDownNum = nil

-- 公会护送、防守等相关
def.field("userdata")._Frame_HPBar = nil
def.field("userdata")._Bar_HP = nil
def.field("userdata")._Lab_HPPercent = nil
def.field("userdata")._Lab_HPInfo = nil
def.field("boolean")._Should_Set_HPInfo = true
-- 副本辅助显示相关
def.field("userdata")._Frame_ProgressBar = nil
def.field("userdata")._Bar_Progress = nil
def.field("userdata")._Lab_ProgressPercent = nil
def.field("userdata")._Lab_ProgressInfo = nil
def.field("userdata")._Frame_CompetitionBar = nil
def.field("userdata")._Bar_Competition = nil
def.field("userdata")._Lab_CompetitionLeft = nil
def.field("userdata")._Lab_CompetitionRight = nil
def.field("userdata")._Frame_DuelBar = nil
def.field("userdata")._Bar_DuelLeft = nil
def.field("userdata")._Lab_DuelLeft = nil
def.field("userdata")._Bar_DuelRight = nil
def.field("userdata")._Lab_DuelRight = nil
def.field("userdata")._Frame_KillProgress = nil
def.field("userdata")._Bar_KillProgress = nil
def.field("userdata")._Lab_KillProgressPercent = nil
def.field("userdata")._Lab_KillProgressInfo = nil
def.field("userdata")._TweenMan_KillProgressBoss = nil
def.field("userdata")._Img_KillProgressBoss = nil
def.field("userdata")._Frame_KillProgressBossEffect = nil
def.field("boolean")._IsKillProgressBossActivated = false
-- 主界面快捷消息
def.field("userdata")._Frame_QuickMsg = nil
def.field("userdata")._List_QuickMsg = nil
def.field('table')._QuickMsgList = BlankTable
def.field("boolean")._IsShowQuickMsg = false

local instance = nil
def.static('=>', CPanelMainChat).Instance = function ()
	if not instance then
        instance = CPanelMainChat()
        instance._PrefabPath = PATH.UI_Main_Chat
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

local OnExpChangedEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateExpInfo()
    end
end

local OnLevelChangeEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateExpInfo()
    end
end

local function OnEntityClick(sender, event)
    if event._Param ~= nil and instance:IsShow() and event._Param ~= instance._Panel.name then
    	if instance._IsShowRelax then
            instance._PageInteractive:SetVisible(false)
            instance._IsShowRelax = false
        end
    end
end

local OnNotifyGuildEvent = function(sender, event)
    if not IsNil(instance._Panel) then
        if event.Type == "GuildConvoyUpdate" then
            instance:OnUpdateGuildConvoy(sender)
        elseif event.Type == "GuildConvoyComplete" then
            instance:OnHideBarInfo()
        elseif event.Type == "GuildDefendUpdate" then
            instance:OnUpdateGuildDefend(sender)
        elseif event.Type == "GuildDefendComplete" then
            instance:OnHideBarInfo()
        end
    end
end

local OnEntityEnterEvent = function(sender, event)
    if not IsNil(instance._Panel) then
        instance:OnHideBarInfo()
    end
end

local function OnNotifyFunctionEvent(sender, event)
	if instance then
		if event.FunID == EnumDef.EGuideTriggerFunTag.Bag then
			instance._Btn_Bag:SetActive(true)
		end
	end
end

def.override().OnCreate = function(self)
    if IsNil(self._Panel) then return end
    self._PanelChat = self:GetUIObject('Img_Chat'):GetComponent(ClassType.RectTransform)
    self._LabelExp = self:GetUIObject("Lab_EXP"):GetComponent(ClassType.Text)
    self._ScrollExp = self:GetUIObject("Frame_AreaEXP"):GetComponent(ClassType.Scrollbar)
    self._ViewChanel = self:GetUIObject("View_Chanel")     --:GetComponent(ClassType.GNewTable)

    -- self._BtnCloseImg = self:GetUIObject("Img_Close")
    self._Item_template = self:GetUIObject("Item")
    self._ItemPool = self._Panel:AddComponent(ClassType.GameObjectPool)   
    self._ItemPool:Regist(self._Item_template, 5) 
    self._ItemContent = self:GetUIObject('Content')

    self:UpdateExpInfo()
    self._BagBg = self:GetUIObject("Img_BagBg")
    self._BagCoolDown = self:GetUIObject("Bag_CoolDown")
    self._BagBg1 = self:GetUIObject("Img_BagBg1")
    self._BagCoolDown1 = self:GetUIObject("Bag_CoolDown1")
    self._BagCoolDownNum = self:GetUIObject("Bag_Pct")       
    CGame.EventManager:addHandler("ExpUpdateEvent", OnExpChangedEvent)
    CGame.EventManager:addHandler("HostPlayerLevelChangeEvent", OnLevelChangeEvent)
    CGame.EventManager:addHandler('NotifyClick', OnEntityClick)
    CGame.EventManager:addHandler(NotifyGuildEvent, OnNotifyGuildEvent)
    CGame.EventManager:addHandler(EntityEnterEvent, OnEntityEnterEvent)  
    CGame.EventManager:addHandler("NotifyFunctionEvent", OnNotifyFunctionEvent)
    -- self:refreshMsgList(true)
    -- 背景缩半隐藏
    -- self._SizeDelta = self._PanelChat.sizeDelta
    -- self._SizeDelta.y = self._SizeDelta.y / 2
    -- self._PanelChat.sizeDelta = Vector2.New(self._SizeDelta.x, self._SizeDelta.y)
    -- self._BtnCloseImg.localRotation = Vector3.New(0, 0, 0)

    -- self._ViewChanel:SetItemCount(0)
    -- self._ViewChanel:ScrollToStep(0)
    local panelInteractive = self:GetUIObject("panel_Interactive")
    if not IsNil(panelInteractive) then
        panelInteractive: SetActive(false)
    end
    self._PageInteractive = CPageInteractive.new(self, panelInteractive)  
    self._ChatTemplate = {}    
    --没有交互图标，暂时关闭
    -- local interBtn = self._Panel:FindChild("Btn_Interactive")
    -- if not IsNil(interBtn) then
    --     interBtn: SetActive(false)
    -- end

    -- 背包
    self._Btn_Bag = self:GetUIObject("Btn_Bag")
    if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bag) then
        self._Btn_Bag :SetActive(false)
    else
        self._Btn_Bag:SetActive(true)
    end    

    -- 相机模式
    self._Img_Camera = self:GetUIObject("Img_Camera")
    local camera_mode = GameUtil.GetGameCamCtrlMode()
    self:SetLabCameraMode(camera_mode)

    -- 血条
    self._Frame_HPBar = self:GetUIObject("Bar_HP")
    self._Bar_HP = self._Frame_HPBar:GetComponent(ClassType.Scrollbar)
    self._Lab_HPPercent = self:GetUIObject("Lab_HPPercent")
    self._Lab_HPInfo = self:GetUIObject("Lab_HPInfo")
    -- 副本通用活动进度条
    self._Frame_ProgressBar = self:GetUIObject("Bar_Progress")
    self._Bar_Progress = self._Frame_ProgressBar:GetComponent(ClassType.Scrollbar)
    self._Lab_ProgressPercent = self:GetUIObject("Lab_ProgressPercent")
    self._Lab_ProgressInfo = self:GetUIObject("Lab_ProgressInfo")
    -- 副本通用对抗进度条
    self._Frame_CompetitionBar = self:GetUIObject("Bar_Competition")
    self._Bar_Competition = self._Frame_CompetitionBar:GetComponent(ClassType.Scrollbar)
    self._Lab_CompetitionLeft = self:GetUIObject("Lab_CompetitionLeft")
    self._Lab_CompetitionRight = self:GetUIObject("Lab_CompetitionRight")
    -- 副本通用决斗进度条
    self._Frame_DuelBar = self:GetUIObject("Frame_DuelBar")
    self._Bar_DuelLeft = self:GetUIObject("Bar_DuelLeft"):GetComponent(ClassType.Scrollbar)
    self._Lab_DuelLeft = self:GetUIObject("Lab_DuelLeft")
    self._Bar_DuelRight = self:GetUIObject("Bar_DuelRight"):GetComponent(ClassType.Scrollbar)
    self._Lab_DuelRight = self:GetUIObject("Lab_DuelRight")
    -- 副本通用杀怪计数进度条
    self._Frame_KillProgress = self:GetUIObject("Frame_KillProgress")
    self._Bar_KillProgress = self:GetUIObject("Bar_KillProgress"):GetComponent(ClassType.Scrollbar)
    self._Lab_KillProgressPercent = self:GetUIObject("Lab_KillProgressPercent")
    self._Lab_KillProgressInfo = self:GetUIObject("Lab_KillProgressInfo")
    self._TweenMan_KillProgressBoss = self:GetUIObject("Frame_KillProgressBoss"):GetComponent(ClassType.DOTweenPlayer)
    self._Img_KillProgressBoss = self:GetUIObject("Img_KillProgressBoss")
    self._Frame_KillProgressBossEffect = self:GetUIObject("Frame_KillProgressBossEffect")

    -- 主界面快捷消息
    self._Frame_QuickMsg = self:GetUIObject("Frame_QuickMsg")
    self._List_QuickMsg = self:GetUIObject("List_QuickMsg"):GetComponent(ClassType.GNewList)
    self._QuickMsgList = _G.QuickMsgTable

    ChatManager.Instance():UpdateChatSetStates()
    
end

def.override('dynamic').OnData = function(self, data)   
    -- 打开聊天界面就开启离线语音
    local isVoiceEnabled = VoiceUtil.IsVoiceEnabled()
    local voiceMode = VoiceUtil.GetVoiceMode()
    local bSuccess = VoiceUtil.SwitchToVoiceMode(EnumDef.VoiceMode.OffLine);
    voiceMode = VoiceUtil.GetVoiceMode()
    self:ShowBagRed()
    -- 按钮红点
    CRedDotMan.UpdateMainChatRedDotShow(self:GetUIObject("Frame_Social"))
    
    -- 背包百分比
    self:SetBagCapacityLast(self._BagPercentNum)
    -- 显示时间 电量和网络
    self:SetSystemInfo()
    self:ListenToEvent()
end

--显示背包红点
def.method().ShowBagRed = function(self)
       -- 检测背包是否显示红点
    local isShowRed = false
    for i,item in ipairs(game._HostPlayer._Package._NormalPack._ItemSet) do 
        if item._ItemType == EItemType.TreasureBox then 
            isShowRed = true
            break 
        end  
    end
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Bag,isShowRed)  
end

-- 设置背包剩余
def.method("number").SetBagCapacityLast = function(self, pct)
    if self._IsLoading or not self:IsShow()then
        self._BagPercentNum = pct
        return
    end
    if pct >= 1 then 
        self._BagBg:SetActive(false)
        self._BagCoolDown:SetActive(false)
        self._BagBg1:SetActive(true)
        self._BagCoolDown1:SetActive(true)
        GameUtil.PlayUISfx(PATH.UIFx_zhujiemian_beibaoman, self._Btn_Bag, self._Btn_Bag,-1)
        if self._PanelTween ~= nil then 
            self._PanelTween:Restart("5")
        end
    else
        self._BagBg:SetActive(true)
        self._BagCoolDown:SetActive(true)
        self._BagBg1:SetActive(false)
        self._BagCoolDown1:SetActive(false)
        GameUtil.StopUISfx(PATH.UIFx_zhujiemian_beibaoman, self._Btn_Bag)
        if self._PanelTween ~= nil then 
            self._PanelTween:Stop("5")
        end
    end
    GUI.SetText(self._BagCoolDownNum, math.floor(pct*100) .."%")
    local imgAmout = self._BagCoolDown:GetComponent(ClassType.Image)
    if imgAmout then
        imgAmout.fillAmount = (pct*80 + 10)/100
    end
    self._BagPercentNum = pct
end

-- 设置时间 电量和 网络
def.method().SetSystemInfo = function(self)
    local labTime = self:GetUIObject("Lab_NowTime")
    local imgRechange = self:GetUIObject("Img_Recharge")
    local imgBtttery = self:GetUIObject("Img_Bettery")
    local imgData = self:GetUIObject("Img_Data")
    local imgWifi = self:GetUIObject("Img_WIFI")
    local filled = imgBtttery:GetComponent(ClassType.Image)
    local BttteryLv = -1
    local BatStatus = -1
    if self._TimerId ~= 0 then 
       _G.RemoveGlobalTimer(self._TimerId) 
       self._TimerId = 0
    end
    local function callback()
        GUI.SetText(labTime,os.date("%H:%M",GameUtil.GetServerTime()/1000 )) 

        local batteryStatus = game:GetBatteryStatus()
        local batteryLevel = game:GetBatteryLevel()
        local networkStatus = game:GetNetworkStatus()

        if BatStatus ~= batteryStatus then 
            if batteryStatus == EnumDef.BatteryStatus.Charging then 
                imgRechange:SetActive(true)
                GUITools.SetGroupImg(imgBtttery,1)
            else
                imgRechange:SetActive(false)
                GUITools.SetGroupImg(imgBtttery,0)
            end
            BatStatus = batteryStatus
        end
        if BttteryLv ~= batteryLevel then 
            filled.fillAmount = batteryLevel 
            BttteryLv = batteryLevel
        end
        local imgNetwork = nil
        if networkStatus == EnumDef.NetworkStatus.DataNetwork then 
            imgData:SetActive(true)
            imgWifi:SetActive(false)
            imgNetwork = imgData
        elseif networkStatus == EnumDef.NetworkStatus.LocalNetwork then 
            imgData:SetActive(false)
            imgWifi:SetActive(true)
            imgNetwork = imgWifi
        elseif networkStatus == EnumDef.NetworkStatus.NotReachable then
            return
        end
        local ping = game:GetPing() 
        if imgNetwork == nil then return end
        if ping <= 100 then 
            local color = Color.New(92/255, 190/255, 55/255, 1)
            GUITools.SetGroupImg(imgNetwork,3)
            GameUtil.SetImageColor(imgNetwork,color)
           
        elseif ping > 100 and ping <= 200 then 
            local color = Color.New(211/255, 144/255, 84/255, 1)
            GUITools.SetGroupImg(imgNetwork,2)
            GameUtil.SetImageColor(imgNetwork,color)
        else
            local color = Color.New(274/255, 0/255, 0/255, 0)
            GUITools.SetGroupImg(imgNetwork,1)
            GameUtil.SetImageColor(imgNetwork,color)
        end
    end
    self._TimerId = _G.AddGlobalTimer(1,false,callback)
end

-- 更新显示聊天消息
def.method("table").UpdateMsgInShow = function(self, msg)
    if self._Panel ~= nil then
         
        -- warn("lidaming main chat #self._UniqueMsg  == ", #self._UniqueMsg , msg.StrMsg)
        if IsNilOrEmptyString(msg.StrMsg) then return end
        
        local hp = game._HostPlayer
        if msg.Channel ~= ChatChannel.ChatChannelSocial then        -- 私聊不显示头顶气泡
            if msg.RoleId ~= nil and msg.RoleId == hp._ID then
                hp:ShowPopText(true, msg.StrMsg, 10)
            else
                local entity = game._CurWorld:FindObject(msg.RoleId)
                if entity then
                    entity:ShowPopText(true, msg.StrMsg, 10)	    
                end
            end
        end
        if (msg.Channel == ChatChannel.ChatChannelWorld and ChatManager.Instance()._Channel_World == false)            
        or (msg.Channel == ChatChannel.ChatChannelGuild and ChatManager.Instance()._Channel_Guild == false)
        or (msg.Channel == ChatChannel.ChatChannelTeam and ChatManager.Instance()._Channel_Team == false)
        or (msg.Channel == ChatChannel.ChatChannelCurrent and ChatManager.Instance()._Channel_Current == false)
        or (msg.Channel == ChatChannel.ChatChannelSystem and ChatManager.Instance()._Channel_System == false) 
        or (msg.Channel == ChatChannel.ChatChannelCombat and ChatManager.Instance()._Channel_Combat == false)   -- 战斗频道的信息不显示在主界面中。
        or (msg.Channel == ChatChannel.ChatChannelSocial and ChatManager.Instance()._Channel_Social == false) 
        or (msg.Channel == ChatChannel.ChatChannelRecruit and ChatManager.Instance()._Channel_Recruit == false) then
			return
        end
        
        self._UniqueMsg[#self._UniqueMsg + 1] = msg  

        if #self._UniqueMsg > ChatManager.Instance():GetMsgListMaxCount() then
            table.remove(self._UniqueMsg, 1)
            self:RemoveAtFirst()
        end

        local PlayerChatobj = self._ItemPool:Get()  --GameObject.Instantiate(item_template)
        self._ChatTemplate[#self._ChatTemplate + 1 ] = PlayerChatobj
        if not IsNil(PlayerChatobj) then
            PlayerChatobj:SetParent(self._ItemContent)
            PlayerChatobj.localPosition = Vector3.zero
            PlayerChatobj.localScale = Vector3.one
            PlayerChatobj.localRotation = Vector3.zero
            PlayerChatobj:SetActive(true)
            GUITools.RegisterGTextEventHandler(self._Panel, PlayerChatobj) 
            GUITools.RegisterButtonEventHandler(self._Panel, PlayerChatobj)        
            
            local PlayerCText = PlayerChatobj:FindChild("Lab_Chat")

            local _strMsg = ""
            if msg.PlayerName ~= "" then
                if msg.RoleId ~= nil and msg.RoleId == hp._ID then
                    msg.PlayerName = "<color=#72B4FF>"..(StringTable.Get(13036)..":").."</color>"
                else
                    msg.PlayerName = RichTextTools.GetElsePlayerNameRichText((msg.PlayerName..":"), false)                    
                end 
                _strMsg = msg.PlayerName..msg.StrMsg      
            else
                _strMsg = msg.StrMsg       
            end
            PlayerCText:GetComponent(ClassType.GText).TextID = msg.UniqueMsgID
            -- warn("_strMsg == ", _strMsg)
            -- warn("lidaming AddItem == " ..msg.Channel .._strMsg)
            if _strMsg ~= nil then
                GUI.SetText(PlayerCText, _strMsg)
            end
            local lab_channel = PlayerChatobj:FindChild("Lab_Chanel")
            local chatcfg = _G.ChatCfgTable.Channel[msg.Channel]
            GUI.SetText(lab_channel, "<color=#".. chatcfg.channelcolor .. ">" .. chatcfg.channelname .."</color>")

            self:ChatContentHeight()
        end
    end
end

--  设置聊天内容显示高度
def.method().ChatContentHeight = function(self)
    if self._ItemContent == nil then return end
    local height = self._ItemContent:GetComponent(ClassType.RectTransform).sizeDelta.y
    local ChatBGHeight = self._PanelChat.sizeDelta.y
    -- warn("lidaming height == ", height, "ChatBGHeight == ", ChatBGHeight)
    if height > ChatBGHeight then 
        self._ItemContent:GetComponent(ClassType.RectTransform).anchoredPosition = Vector2.New(0,0)  
    elseif height <= ChatBGHeight then 
        return
    end    
end

-- 是否背包已满
def.method("=>","boolean").IsSpeakFull = function(self)
	return #ChatManager.Instance():GetMsgList() >= 20
end

def.method().RemoveAtFirst = function(self)    
    -- self._ViewChanel:RemoveItem(0)
    if #self._ChatTemplate > ChatManager.Instance():GetMsgListMaxCount() then
        -- warn("=========================================", #self._ChatTemplate, debug.traceback())
        self._ItemPool:Release(self._ChatTemplate[1])
        table.remove(self._ChatTemplate, 1)
    end
end

def.override('string').OnClick = function(self, id)    
    if id == 'Btn_Friend' then
        self._IsShowQuickMsg = false
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg) 
        game._GUIMan:Open("CPanelFriend",nil)       

    elseif id == "Btn_Email" then
        self._IsShowQuickMsg = false
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg) 
        -- 打开邮件
        local CEmailManager = require "Email.CEmailMan".Instance()
        CEmailManager:OnC2SEmailInfo()        
    elseif id == "Btn_Relax" then
        self._IsShowQuickMsg = false
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg) 
        -- TODO()
        if self._IsShowRelax then
            self._IsShowRelax = false
            self._PageInteractive:SetVisible(false)
        else
            self._IsShowRelax = true
            self._PageInteractive:SetVisible(true)
        end
        
    elseif string.find(id,"Btn_Interactive_") then
        if self._PageInteractive ~= nil then
            local SkillIdex = string.sub(id, string.len("Btn_Interactive_")+1,-1)
            local nSkillIdex = tonumber(SkillIdex)
            self._PageInteractive:ClickSkillBtn(nSkillIdex)
        end
    elseif id == "Btn_Camera" then
        self._IsShowQuickMsg = false
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg) 
        local camera_mode = GameUtil.GetGameCamCtrlMode()
        local next_mode = camera_mode + 1
        if next_mode > EnumDef.CameraCtrlMode.FIX25D then
            next_mode = EnumDef.CameraCtrlMode.FOLLOW
        end

        local bChangeDist = next_mode ~= EnumDef.CameraCtrlMode.FIX3D
        GameUtil.SetGameCamCtrlMode(next_mode, false, true, bChangeDist, false)

        self:SetLabCameraMode(next_mode)

        game:SaveCamParamsToUserData()
        UserData:SaveDataToFile()

    elseif id == "Btn_QuickMsg" then
        self._IsShowQuickMsg = not self._IsShowQuickMsg
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg)
        self._IsShowRelax = false
        self._PageInteractive:SetVisible(false)
        -- if self._QuickMsgList == nil then return end
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
        self._List_QuickMsg:SetItemCount(#self._QuickMsgList)
--[[
        if next_mode ~= EnumDef.CameraCtrlMode.FIX25D then
            local UserData = require "Data.UserData".Instance()
            local dist = UserData:GetField(EnumDef.LocalFields.CameraDistance) 
            if dist ~= nil and dist ~= 0 then
                GameUtil.SetGameCamOwnDestDistOffset(dist, true)
            end
        end
]]
    elseif id == "Btn_Bag" then
        self._IsShowQuickMsg = false
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg) 
        local panelData = 
            {
                PageType = CPanelRoleInfo.PageType.BAG,
                IsByNpcOpenStorage = false,
            }
        game._GUIMan:Open("CPanelRoleInfo",panelData)           
    end    
end

def.method('number', 'number').OnGTextClick = function(self, msgId, linkId)     
    if linkId == 0 then
        -- warn("-------点在了GText上-------")
        if CPanelChatNew.Instance():IsShow() then return end
        game._GUIMan:Open("CPanelChatNew",nil)
    else
        --warn("-------点在了GTextItemLink上-------msgId == ", msgId, "linkId == ", linkId)
        ChatManager.Instance():OnLinkClick(msgId, linkId)
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_QuickMsg' then
        local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
        QuickMsg_Input.text = self._QuickMsgList[index + 1]
        -- QuickMsg_Input.enable(false)
        QuickMsg_Input.enabled = false
        GameUtil.SetInputFieldValidation(QuickMsg_Input , 0)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_QuickMsg' then
        local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
        QuickMsg_Input.enabled = true
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if id_btn == "Btn_SendQuickMsg" then
        local item = self._List_QuickMsg:GetItem(index)
        if item == nil then return end
        local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
        self._IsShowQuickMsg = not self._IsShowQuickMsg
        self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg)
        ChatManager.Instance():ClientSendMsg(ChatChannel.ChatChannelCurrent, QuickMsg_Input.text, true, 0, nil, nil)
        -- self._QuickMsgList[index + 1] = QuickMsg_Input.text
        self:SaveQuickMsgToData()
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
            local item = self._List_QuickMsg:GetItem(i - 1)
            if item == nil then return end
            local QuickMsg_Input = GUITools.GetChild(item , 1):GetComponent(ClassType.InputField)
            local FilterMgr = require "Utility.BadWordsFilter".Filter
            local StrMsg = FilterMgr.FilterChat(QuickMsg_Input.text)
            if StrMsg == "" then
                StrMsg = v
            end
            QuickMsglist[#QuickMsglist + 1] = StrMsg			
        end
    else
        accountInfo[serverName][roleIndex]["QuickMsg"] = nil
    end

    accountInfo[serverName][roleIndex]["QuickMsg"] = QuickMsglist    
    UserData.Instance():SetCfg(EnumDef.LocalFields.QuickMsg, account, accountInfo)
end

--target不为空点击就可以执行  TODO：后续需要加上判断不是文字链接
def.override("userdata").OnPointerClick = function(self,target)
    if target == nil then return end
    if target.name == "panel_Interactive" then 
        self._PageInteractive:SetVisible(false)
    return end
    -- warn("lidaming target == ", target.name)
    if target.name ~= "Img_Mask" and target.name == "View_Chanel" then
        -- TODO()
        if CPanelChatNew.Instance():IsShow() then return end
        game._GUIMan:Open("CPanelChatNew",nil)
    end	     
    self._IsShowQuickMsg = false
    self._Frame_QuickMsg:SetActive(self._IsShowQuickMsg)
end

local OnEntityClick = function(sender, event)
    if event._Param ~= nil and instance:IsShow() and event._Param ~= instance._Panel.name then
        if instance._Frame_QuickMsg.activeSelf then
            instance._Frame_QuickMsg:SetActive(false)
            instance._IsShowQuickMsg = false
        end
    end
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler('NotifyClick', OnEntityClick)	
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler('NotifyClick', OnEntityClick)	
end


def.method("boolean").IsShowRelaxPanel = function(self, isShowRelax)
    self._IsShowRelax = isShowRelax
    self._PageInteractive:SetVisible(isShowRelax)
end

def.method().UpdateExpInfo = function(self)
    local info_data = game._HostPlayer._InfoData
    if info_data == nil then return end
    local levelUpExpTemplate = CElementData.GetLevelUpExpTemplate(info_data._Level)
    local curExp = info_data._Exp
    local maxExp = levelUpExpTemplate.Exp or 1

    local expProp = GUITools.FormatPreciseDecimal((curExp/maxExp) * 100, 1)   --  string.format("%.1f", percent) 
    --warn("expProp == ", expProp)
    self._LabelExp.text = "EXP: " .. expProp .. "%"
    self._ScrollExp.size = curExp/maxExp
end

-- 主界面隐藏时
def.method().OnMoveToHide = function (self)
    
end

--切换相机模式设置文本
def.method("number").SetLabCameraMode = function (self, mode)
    -- local str = ""
    if mode == EnumDef.CameraCtrlMode.FOLLOW then
        -- str = "3D+"
        GUITools.SetGroupImg(self._Img_Camera, 2)
    elseif mode == EnumDef.CameraCtrlMode.FIX3D then
        -- str = "3D"
        GUITools.SetGroupImg(self._Img_Camera, 1)
    elseif mode == EnumDef.CameraCtrlMode.FIX25D then
        -- str = "2.5D"
        GUITools.SetGroupImg(self._Img_Camera, 0)
    end
    -- warn("SSSSSSSSSSSSSSSSetCccc ===>>>", str)
end

-- 更新公会护送
def.method("table").OnUpdateGuildConvoy = function(self, data)
    if data.UpdateType == EConvoyUpdateType.EConvoyUpdateType_EntityInfo then
        self:OnUpdateConvoyBarInfo(data.ConvoyEntity)
    end
end

-- 更新公会护送顶部血条
def.method("table").OnUpdateConvoyBarInfo = function(self, data)
    if self._Should_Set_HPInfo then
        self._Frame_HPBar:SetActive(true)
        local npc = CElementData.GetTemplate("Npc", data.NpcTid)
        GUI.SetText(self._Lab_HPInfo, npc.TextOverlayDisplayName)
        self._Should_Set_HPInfo = false  
    end
    local percent = data.CurrentHp / data.MaxHp
    self._Bar_HP.size = percent

    percent = GUITools.FormatPreciseDecimal(percent * 100, 2)  -- string.format("%.2f", percent * 100)
    GUI.SetText(self._Lab_HPPercent, percent .. "%")
end

-- 更新公会防守顶部血条
def.method("table").OnUpdateGuildDefend = function(self, data)
    if self._Should_Set_HPInfo then
        self._Frame_HPBar:SetActive(true)
        local npc = CElementData.GetTemplate("Monster", data.EntityInfo.NpcTid)
        GUI.SetText(self._Lab_HPInfo, npc.TextDisplayName)
        self._Should_Set_HPInfo = false  
    end
    if data.EntityInfo.CurrentHp <= 0 or data.EntityInfo.MaxHp <= 0 then
        self._Frame_HPBar:SetActive(false)
    else
        self._Frame_HPBar:SetActive(true)
        local percent = data.EntityInfo.CurrentHp / data.EntityInfo.MaxHp
        self._Bar_HP.size = percent

        percent = GUITools.FormatPreciseDecimal(percent * 100, 2)     -- string.format("%.2f", percent * 100)
        GUI.SetText(self._Lab_HPPercent, percent .. "%")
    end
end

-- 隐藏顶部血条
def.method().OnHideBarInfo = function(self)
    self._Frame_HPBar:SetActive(false)
    self._Should_Set_HPInfo = true
end

---------------------------副本辅助显示 start------------------------------
-- 副本辅助显示的进度条
-- @param serverInfo:net.S2CDungeonProgress
def.method("table").OnDungeonProgress = function(self, serverInfo)
    -- warn("=======OnDungeonProgress progressType:" .. serverInfo.progressType, ", notifyType:" .. serverInfo.notifyType, ", curProcess:" .. serverInfo.curProcess, ", maxValue:" .. serverInfo.maxValue)

    local EProgressTypes = require "PB.net".S2CDungeonProgress.ProgressTypes
    local ENotifyTypes = require "PB.net".S2CDungeonProgress.NotifyTypes
    if serverInfo.progressType == EProgressTypes.COMMON or serverInfo.progressType == EProgressTypes.MOBA then
        -- 活动进度条
        if serverInfo.notifyType == ENotifyTypes.OPEN then
            -- 开启进度条
            local textTemplate = CElementData.GetTextTemplate(serverInfo.textTempId)
            if textTemplate ~= nil then
                GUI.SetText(self._Lab_ProgressInfo, textTemplate.TextContent)
            end
            self._Frame_ProgressBar:SetActive(true)
            self:UpdateBarProgress(serverInfo.curProcess / serverInfo.maxValue)
            -- TODO:style
        elseif serverInfo.notifyType == ENotifyTypes.UPDATE then
            -- 更新进度条
            self:UpdateBarProgress(serverInfo.curProcess / serverInfo.maxValue)
        elseif serverInfo.notifyType == ENotifyTypes.CLOSE then
            -- 关闭进度条
            self._Frame_ProgressBar:SetActive(false)
        end
    elseif serverInfo.progressType == EProgressTypes.OCCOPY then
        -- 对抗进度条
        if serverInfo.notifyType == ENotifyTypes.OPEN then
            -- 开启进度条
            self._Frame_CompetitionBar:SetActive(true)
            self:UpdateBarCompetition(serverInfo.curProcess / serverInfo.maxValue) -- 默认各占一半
        elseif serverInfo.notifyType == ENotifyTypes.UPDATE then
            -- 更新进度条
            self:UpdateBarCompetition(serverInfo.curProcess / serverInfo.maxValue)
        elseif serverInfo.notifyType == ENotifyTypes.CLOSE then
            -- 关闭进度条
            self._Frame_CompetitionBar:SetActive(false)
        end
    elseif serverInfo.progressType == EProgressTypes.DUEL then
        -- 决斗进度条
        if serverInfo.notifyType == ENotifyTypes.OPEN then
            -- 开启进度条
            self._Frame_DuelBar:SetActive(true)
            local leftRate = serverInfo.curProcess / serverInfo.maxValue
            local rightRate = serverInfo.curProcess2 / serverInfo.maxValue2
            self:UpdateBarDuel(leftRate, rightRate)
        elseif serverInfo.notifyType == ENotifyTypes.UPDATE then
            -- 更新进度条
            local leftRate = serverInfo.curProcess / serverInfo.maxValue
            local rightRate = serverInfo.curProcess2 / serverInfo.maxValue2
            self:UpdateBarDuel(leftRate, rightRate)
        elseif serverInfo.notifyType == ENotifyTypes.CLOSE then
            -- 关闭进度条
            self._Frame_DuelBar:SetActive(false)
        end
    elseif serverInfo.progressType == EProgressTypes.PVP then
        -- 无畏战场使用活动进度条
        if serverInfo.notifyType == ENotifyTypes.OPEN then
            -- 开启进度条
            local textTemplate = CElementData.GetTextTemplate(serverInfo.textTempId)
            if textTemplate ~= nil and serverInfo.roleName ~= nil then
                GUI.SetText(self._Lab_ProgressInfo, serverInfo.roleName .. textTemplate.TextContent)
            end
            self._Frame_ProgressBar:SetActive(true)
            self:UpdateBarProgress(serverInfo.curProcess / serverInfo.maxValue)
            -- TODO:style
        elseif serverInfo.notifyType == ENotifyTypes.UPDATE then
            -- 更新进度条
            self:UpdateBarProgress(serverInfo.curProcess / serverInfo.maxValue)
        elseif serverInfo.notifyType == ENotifyTypes.CLOSE then
            -- 关闭进度条
            self._Frame_ProgressBar:SetActive(false)
        end
    elseif serverInfo.progressType == EProgressTypes.KILLMONSTER then
        -- 杀怪计数进度条
        if serverInfo.notifyType == ENotifyTypes.OPEN then
            -- 开启进度条
            self._IsKillProgressBossActivated = true
            local textTemplate = CElementData.GetTextTemplate(serverInfo.textTempId)
            if textTemplate ~= nil then
                GUI.SetText(self._Lab_KillProgressInfo, textTemplate.TextContent)
            end
            self._Frame_KillProgress:SetActive(true)
            self:UpdateBarKillProgress(serverInfo.curProcess / serverInfo.maxValue)
        elseif serverInfo.notifyType == ENotifyTypes.UPDATE then
            -- 更新进度条
            self:UpdateBarKillProgress(serverInfo.curProcess / serverInfo.maxValue)
        elseif serverInfo.notifyType == ENotifyTypes.CLOSE then
            -- 关闭进度条
            self._Frame_KillProgress:SetActive(false)
        end
    end
end

-- 更新活动进度条
def.method("number").UpdateBarProgress = function(self, rate)
    self._Bar_Progress.size = rate
    local percent = string.format("%.2f", rate * 100)
    GUI.SetText(self._Lab_ProgressPercent, percent .. "%")
end

-- 更新对抗进度条
-- @param leftRate:左方的占比，右方占比 = 100 - 左方
def.method("number").UpdateBarCompetition = function(self, leftRate)
    self._Bar_Competition.size = leftRate
    local leftPercent = string.format("%.1f", leftRate * 100)
    local rightPercent = 100 - leftPercent
    GUI.SetText(self._Lab_CompetitionLeft, leftPercent .. "%")
    GUI.SetText(self._Lab_CompetitionRight, rightPercent .. "%")
end

-- 更新决斗进度条
def.method("number", "number").UpdateBarDuel = function(self, leftRate, rightRate)
    self._Bar_DuelLeft.size = leftRate
    local leftPercent = string.format("%.1f", leftRate * 100)
    GUI.SetText(self._Lab_DuelLeft, leftPercent .. "%")
    self._Bar_DuelRight.size = rightRate
    local rightPercent = string.format("%.1f", rightRate * 100)
    GUI.SetText(self._Lab_DuelRight, rightPercent .. "%")
end

-- 更新杀怪计数进度条
def.method("number").UpdateBarKillProgress = function(self, rate)
    self._Bar_KillProgress.size = rate
    local percent = string.format("%.2f", rate * 100)
    GUI.SetText(self._Lab_KillProgressPercent, percent .. "%")
    local tweenId = "Boss"
    if rate == 1 then
        if not self._IsKillProgressBossActivated then
            GUITools.SetUIActive(self._Frame_KillProgressBossEffect, true)
            GameUtil.MakeImageGray(self._Img_KillProgressBoss, false)
            self._TweenMan_KillProgressBoss:Restart(tweenId)
            self._IsKillProgressBossActivated = true
        end
    else
        if self._IsKillProgressBossActivated then
            GUITools.SetUIActive(self._Frame_KillProgressBossEffect, false)
            GameUtil.MakeImageGray(self._Img_KillProgressBoss, true)
            self._TweenMan_KillProgressBoss:Stop(tweenId)
            self._IsKillProgressBossActivated = false
        end
    end
end

-- 隐藏通用进度条
def.method().HideDungeonCommonBar = function(self)
    if not IsNil(self._Frame_ProgressBar) then
        self._Frame_ProgressBar:SetActive(false)
    end
    if not IsNil(self._Frame_CompetitionBar) then
        self._Frame_CompetitionBar:SetActive(false)
    end
    if not IsNil(self._Frame_DuelBar) then
        self._Frame_DuelBar:SetActive(false)
    end
    if not IsNil(self._Frame_KillProgress) then
        self._Frame_KillProgress:SetActive(false)
    end
end
----------------------------副本辅助显示 end-------------------------------

--获得背包按钮的坐标。做获得物品tips显示
def.method("=>","table").GetBagBtnPos = function(self)
    if IsNil(self._Btn_Bag) then
        return Vector3.zero
    end

    return self._Btn_Bag.position
end

def.override().OnHide = function(self)
    if self._TimerId ~= 0 then
        _G.RemoveGlobalTimer(self._TimerId) 
        self._TimerId = 0
    end
    self:UnlistenToEvent()
end

def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler("ExpUpdateEvent", OnExpChangedEvent)
    CGame.EventManager:removeHandler("HostPlayerLevelChangeEvent", OnLevelChangeEvent)
    CGame.EventManager:removeHandler('NotifyClick', OnEntityClick)
    CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
    CGame.EventManager:removeHandler(EntityEnterEvent, OnEntityEnterEvent)  
    CGame.EventManager:removeHandler("NotifyFunctionEvent", OnNotifyFunctionEvent)	
    self._UniqueMsg = {}
    --instance = nil --destroy
    if self._PageInteractive ~= nil then
        self._PageInteractive:Destroy()
        self._PageInteractive = nil
    end
    ChatManager.Instance():ClearnMsg()
    
    self._Should_Set_HPInfo = true

    self._Frame_ProgressBar = nil
    self._Bar_Progress = nil
    self._Lab_ProgressPercent = nil
    self._Lab_ProgressInfo = nil
    self._Frame_CompetitionBar = nil
    self._Bar_Competition = nil
    self._Lab_CompetitionLeft = nil
    self._Lab_CompetitionRight = nil
    self._Frame_DuelBar = nil
    self._Bar_DuelLeft = nil
    self._Lab_DuelLeft = nil
    self._Bar_DuelRight = nil
    self._Lab_DuelRight = nil
    self._Frame_KillProgress = nil
    self._Bar_KillProgress = nil
    self._Lab_KillProgressPercent = nil
    self._Lab_KillProgressInfo = nil
    self._TweenMan_KillProgressBoss = nil
    self._Img_KillProgressBoss = nil
    self._Frame_KillProgressBossEffect = nil

    self:SaveQuickMsgToData()
end

CPanelMainChat.Commit()
return CPanelMainChat