
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
def.field("userdata")._Lab_CameraMode = nil
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
    local interBtn = self._Panel:FindChild("Btn_Interactive")
    if not IsNil(interBtn) then
        interBtn: SetActive(false)
    end

    -- 背包
    self._Btn_Bag = self:GetUIObject("Btn_Bag")
    if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Bag) then
        self._Btn_Bag :SetActive(false)
    end    

    -- 相机模式
    self._Lab_CameraMode = self:GetUIObject("Lab_CameraMode")
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

    ChatManager.Instance():UpdateChatSetStates()
end

def.override('dynamic').OnData = function(self, data)   
    -- 打开聊天界面就开启离线语音
    local isVoiceEnabled = VoiceUtil.IsVoiceEnabled()
    local voiceMode = VoiceUtil.GetVoiceMode()
    local bSuccess = VoiceUtil.SwitchToVoiceMode(EnumDef.VoiceMode.OffLine);
    voiceMode = VoiceUtil.GetVoiceMode()
    -- 按钮红点
    CRedDotMan.UpdateMainChatRedDotShow(self._Panel)
    
    -- 背包百分比
    self:SetBagCapacityLast(self._BagPercentNum)
    -- 显示时间 电量和网络
    self:SetSystemInfo()
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
        if BatStatus ~= game:GetBatteryStatus() then 
            if game:GetBatteryStatus() == EnumDef.BatteryStatus.Charging then 
                imgRechange:SetActive(true)
                GUITools.SetGroupImg(imgBtttery,1)
            else
                imgRechange:SetActive(false)
                GUITools.SetGroupImg(imgBtttery,0)
            end
            BatStatus = game:GetBatteryStatus()
        end
        if BttteryLv ~= game:GetBatteryLevel() then 
            filled.fillAmount = game:GetBatteryLevel() 
            BttteryLv = game:GetBatteryLevel()
        end
        local imgNetwork = nil
        if game:GetNetworkStatus() == EnumDef.NetworkStatus.DataNetwork then 
            imgData:SetActive(true)
            imgWifi:SetActive(false)
            imgNetwork = imgData
        elseif game:GetNetworkStatus() == EnumDef.NetworkStatus.LocalNetwork then 
            imgData:SetActive(false)
            imgWifi:SetActive(true)
            imgNetwork = imgWifi
        elseif game:GetNetworkStatus() == EnumDef.NetworkStatus.NotReachable then
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
        if msg.RoleId ~= nil and msg.RoleId == hp._ID then
            hp:OnTalkPopTopChange(true, msg.StrMsg, 10)
        else
            local entity = game._CurWorld:FindObject(msg.RoleId)
            if entity then
                entity:OnTalkPopTopChange(true, msg.StrMsg, 10)	    
            end
        end
        if (msg.Channel == ChatChannel.ChatChannelWorld and ChatManager.Instance()._Channel_World == false)            
        or (msg.Channel == ChatChannel.ChatChannelGuild and ChatManager.Instance()._Channel_Guild == false)
        or (msg.Channel == ChatChannel.ChatChannelTeam and ChatManager.Instance()._Channel_Team == false)
        or (msg.Channel == ChatChannel.ChatChannelCurrent and ChatManager.Instance()._Channel_Current == false)
        or (msg.Channel == ChatChannel.ChatChannelSystem and ChatManager.Instance()._Channel_System == false) 
        or (msg.Channel == ChatChannel.ChatChannelCombat and ChatManager.Instance()._Channel_Combat == false)   -- 战斗频道的信息不显示在主界面中。
        or (msg.Channel == ChatChannel.ChatChannelSocial and ChatManager.Instance()._Channel_Social == false) then
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
        game._GUIMan:Open("CPanelFriend",nil)       

    elseif id == "Btn_Email" then
        -- 打开邮件
        local CEmailManager = require "Email.CEmailMan".Instance()
        CEmailManager:OnC2SEmailInfo()        
    elseif id == "Btn_Relax" then
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
        local camera_mode = GameUtil.GetGameCamCtrlMode()
        local next_mode = camera_mode + 1
        if next_mode > EnumDef.CameraCtrlMode.FIX25D then
            next_mode = EnumDef.CameraCtrlMode.FOLLOW
        end

        local bChangeDist = next_mode ~= EnumDef.CameraCtrlMode.FIX3D
        GameUtil.SetGameCamCtrlMode(next_mode, false, true, bChangeDist, false)

        self:SetLabCameraMode(next_mode)

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

--target不为空点击就可以执行  TODO：后续需要加上判断不是文字链接
def.override("userdata").OnPointerClick = function(self,target)
    if target == nil then return end
    if target.name == "panel_Interactive" then 
        self._PageInteractive:SetVisible(false)
    return end
    -- warn("lidaming target == ", target.name)
    if target.name ~= "Img_Mask" then
        -- TODO()
        if CPanelChatNew.Instance():IsShow() then return end
        game._GUIMan:Open("CPanelChatNew",nil)
    end	     
end

def.method("boolean").IsShowRelaxPanel = function(self, isShowRelax)
    self._IsShowRelax = isShowRelax
    self._PageInteractive:SetVisible(isShowRelax)
end

def.method().UpdateExpInfo = function(self)
    local info_data = game._HostPlayer._InfoData
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
    local str = ""
    if mode == EnumDef.CameraCtrlMode.FOLLOW then
        str = "3D+"
    elseif mode == EnumDef.CameraCtrlMode.FIX3D then
        str = "3D"
    elseif mode == EnumDef.CameraCtrlMode.FIX25D then
        str = "2.5D"
    end
    GUI.SetText(self._Lab_CameraMode, str)
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
        local npc = CElementData.GetTemplate("Npc", data.EntityInfo.NpcTid)
        GUI.SetText(self._Lab_HPInfo, npc.TextOverlayDisplayName)
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
            if not self._Frame_ProgressBar.activeSelf then
                self._Frame_ProgressBar:SetActive(true)
            end
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
            if not self._Frame_CompetitionBar.activeSelf then
                self._Frame_CompetitionBar:SetActive(true)
            end
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
            if not self._Frame_DuelBar.activeSelf then
                self._Frame_DuelBar:SetActive(true)
            end
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
            if not self._Frame_ProgressBar.activeSelf then
                self._Frame_ProgressBar:SetActive(true)
            end
            self:UpdateBarProgress(serverInfo.curProcess / serverInfo.maxValue)
            -- TODO:style
        elseif serverInfo.notifyType == ENotifyTypes.UPDATE then
            -- 更新进度条
            self:UpdateBarProgress(serverInfo.curProcess / serverInfo.maxValue)
        elseif serverInfo.notifyType == ENotifyTypes.CLOSE then
            -- 关闭进度条
            self._Frame_ProgressBar:SetActive(false)
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

-- 隐藏通用进度条
def.method().HideDungeonCommonBar = function(self)
    if not IsNil(self._Frame_ProgressBar) then
        if self._Frame_ProgressBar.activeSelf then
            self._Frame_ProgressBar:SetActive(false)
        end
    end
    if not IsNil(self._Frame_CompetitionBar) then
        if self._Frame_CompetitionBar.activeSelf then
            self._Frame_CompetitionBar:SetActive(false)
        end
    end
    if not IsNil(self._Frame_DuelBar) then
        if self._Frame_DuelBar.activeSelf then
            self._Frame_DuelBar:SetActive(false)
        end
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
end

def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler("ExpUpdateEvent", OnExpChangedEvent)
    CGame.EventManager:removeHandler("HostPlayerLevelChangeEvent", OnLevelChangeEvent)
    CGame.EventManager:removeHandler('NotifyClick', OnEntityClick)
    CGame.EventManager:removeHandler(NotifyGuildEvent, OnNotifyGuildEvent)
    CGame.EventManager:removeHandler(EntityEnterEvent, OnEntityEnterEvent)  
    self._UniqueMsg = {}
    --instance = nil --destroy
    if self._PageInteractive ~= nil then
        self._PageInteractive:Destroy()
        self._PageInteractive = nil
    end
    ChatManager.Instance():ClearnMsg()
    
    self._Should_Set_HPInfo = true

    self._Frame_ProgressBar = nil
    self._Frame_CompetitionBar = nil
    self._Frame_DuelBar = nil
end

CPanelMainChat.Commit()
return CPanelMainChat