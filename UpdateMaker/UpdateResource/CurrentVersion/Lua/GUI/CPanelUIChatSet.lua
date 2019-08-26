local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local UserData = require "Data.UserData".Instance()
local ChatManager = Lplus.ForwardDeclare("ChatManager")
local CPanelUIChatSet = Lplus.Extend(CPanelBase, "CPanelUIChatSet")
local def = CPanelUIChatSet.define

def.field("userdata")._Img_OpenWorld = nil
def.field("userdata")._Img_OpenGuild = nil
def.field("userdata")._Img_OpenSystem = nil
def.field("userdata")._Img_OpenCurrent = nil
def.field("userdata")._Img_OpenTeam = nil
def.field("userdata")._Img_OpenCombat = nil
def.field("userdata")._Img_OpenSocial = nil
def.field("userdata")._Img_OpenRecruit = nil

def.field("userdata")._Img_OpenWorldVoice = nil
def.field("userdata")._Img_OpenGuildVoice = nil
def.field("userdata")._Img_OpenTeamVoice = nil
def.field("userdata")._Img_OpenCurrentVoice = nil

def.field("boolean")._Channel_World = true
def.field("boolean")._Channel_Guild = true
def.field("boolean")._Channel_System = true
def.field("boolean")._Channel_Team = true
def.field("boolean")._Channel_Current = true
def.field("boolean")._Channel_Combat= false
def.field("boolean")._Channel_Social= true
def.field("boolean")._Channel_Recruit= true

def.field("boolean")._Channel_WorldVoice = true
def.field("boolean")._Channel_GuildVoice = true
def.field("boolean")._Channel_TeamVoice = true
def.field("boolean")._Channel_CurrentVoice = true

local instance = nil
def.static("=>", CPanelUIChatSet).Instance = function()
	if not instance then
		instance = CPanelUIChatSet()
		--instance._DestroyOnHide = false
      	instance._PrefabPath = PATH.UI_ChatSet
        instance._PanelCloseType = EnumDef.PanelCloseType.None

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Img_OpenWorld = self: GetUIObject("Img_OpenWorld")
    self._Img_OpenGuild = self: GetUIObject("Img_OpenGuild")
    self._Img_OpenSystem = self: GetUIObject("Img_OpenSystem")
    self._Img_OpenCurrent = self: GetUIObject("Img_OpenCurrent")
    self._Img_OpenTeam = self: GetUIObject("Img_OpenTeam")
    self._Img_OpenCombat = self: GetUIObject("Img_OpenCombat")
    self._Img_OpenSocial = self: GetUIObject("Img_OpenSocial")
    self._Img_OpenRecruit = self: GetUIObject("Img_OpenRecruit")

    self._Img_OpenWorldVoice = self: GetUIObject("Img_OpenWorldVoice")
    self._Img_OpenGuildVoice = self: GetUIObject("Img_OpenGuildVoice")
    self._Img_OpenTeamVoice = self: GetUIObject("Img_OpenTeamVoice")
    self._Img_OpenCurrentVoice = self: GetUIObject("Img_OpenCurrentVoice")
end

def.override().OnDestroy = function(self)

end

def.override("dynamic").OnData = function(self, data)	
	self:UpdateChatStates()
end

def.override('string').OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
        --保存聊天设置
        UserData:SetField("Channel_World", self._Channel_World)
        UserData:SetField("Channel_Guild", self._Channel_Guild)
        UserData:SetField("Channel_System", self._Channel_System)
        UserData:SetField("Channel_Team", self._Channel_Team)
        UserData:SetField("Channel_Current", self._Channel_Current)
        UserData:SetField("Channel_Combat", self._Channel_Combat)
        UserData:SetField("Channel_Social", self._Channel_Social)
        UserData:SetField("Channel_Recruit", self._Channel_Recruit)

        UserData:SetField("Channel_WorldVoice", self._Channel_WorldVoice)
        UserData:SetField("Channel_GuildVoice", self._Channel_GuildVoice)
        UserData:SetField("Channel_TeamVoice", self._Channel_TeamVoice)
        UserData:SetField("Channel_CurrentVoice", self._Channel_CurrentVoice)
	    UserData:SaveDataToFile()
        ChatManager.Instance():UpdateChatSetStates()
    elseif id == "Btn_World" then
        self._Channel_World = not self._Channel_World
        self._Img_OpenWorld:SetActive(self._Channel_World)
        self:GetUIObject("Img_WorldBg"):SetActive(not self._Channel_World)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_World"), self._Channel_World)
    elseif id == "Btn_Guild" then
        self._Channel_Guild = not self._Channel_Guild
        self._Img_OpenGuild:SetActive(self._Channel_Guild)
        self:GetUIObject("Img_GuildBg"):SetActive(not self._Channel_Guild)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Guild"), self._Channel_Guild)
    elseif id == "Btn_System" then
        self._Channel_System = not self._Channel_System
        self._Img_OpenSystem:SetActive(self._Channel_System)
        self:GetUIObject("Img_SystemBg"):SetActive(not self._Channel_System)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_System"), self._Channel_System)
    elseif id == "Btn_Team" then
        self._Channel_Team = not self._Channel_Team      
        self._Img_OpenTeam:SetActive(self._Channel_Team)
        self:GetUIObject("Img_TeamBg"):SetActive(not self._Channel_Team)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Team"), self._Channel_Team)
    elseif id == "Btn_Current" then
        self._Channel_Current = not self._Channel_Current   
        self._Img_OpenCurrent:SetActive(self._Channel_Current)
        self:GetUIObject("Img_CurrentBg"):SetActive(not self._Channel_Current)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Current"), self._Channel_Current)
    elseif id == "Btn_Combat" then
        self._Channel_Combat = not self._Channel_Combat
        self._Img_OpenCombat:SetActive(self._Channel_Combat)
        self:GetUIObject("Img_CombatBg"):SetActive(not self._Channel_Combat)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Combat"), self._Channel_Combat)
    elseif id == "Btn_Social" then
        self._Channel_Social = not self._Channel_Social
        self._Img_OpenSocial:SetActive(self._Channel_Social)
        self:GetUIObject("Img_SocialBg"):SetActive(not self._Channel_Social)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Social"), self._Channel_Social)
    elseif id == "Btn_Recruit" then
        self._Channel_Recruit = not self._Channel_Recruit
        self._Img_OpenRecruit:SetActive(self._Channel_Recruit)
        self:GetUIObject("Img_RecruitBg"):SetActive(not self._Channel_Recruit)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Recruit"), self._Channel_Recruit)
    elseif id == "Btn_WorldVoice" then
        self._Channel_WorldVoice = not self._Channel_WorldVoice   
        self._Img_OpenWorldVoice:SetActive(self._Channel_WorldVoice)
        self:GetUIObject("Img_WorldVoiceBg"):SetActive(not self._Channel_WorldVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelWorld"), self._Channel_WorldVoice)
    elseif id == "Btn_GuildVoice" then
        self._Channel_GuildVoice = not self._Channel_GuildVoice    
        self._Img_OpenGuildVoice:SetActive(self._Channel_GuildVoice)
        self:GetUIObject("Img_GuildVoiceBg"):SetActive(not self._Channel_GuildVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelGuild"), self._Channel_GuildVoice)
    elseif id == "Btn_TeamVoice" then
        self._Channel_TeamVoice = not self._Channel_TeamVoice     
        self._Img_OpenTeamVoice:SetActive(self._Channel_TeamVoice)
        self:GetUIObject("Img_TeamVoiceBg"):SetActive(not self._Channel_TeamVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelTeam"), self._Channel_TeamVoice)
    elseif id == "Btn_CurrentVoice" then
        self._Channel_CurrentVoice = not self._Channel_CurrentVoice
        self._Img_OpenCurrentVoice:SetActive(self._Channel_CurrentVoice)
        self:GetUIObject("Img_CurrentVoiceBg"):SetActive(not self._Channel_CurrentVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelCurrent"), self._Channel_CurrentVoice)
	end
end

def.method().UpdateChatStates = function (self)
	--更新聊天选中状态
    local Channel_World = ChatManager.Instance()._Channel_World
    if Channel_World ~= nil then
    	self._Channel_World = Channel_World
        self._Img_OpenWorld:SetActive(self._Channel_World)
        self:GetUIObject("Img_WorldBg"):SetActive(not self._Channel_World)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_World"), self._Channel_World)
        ChatManager.Instance()._Channel_World = self._Channel_World
    end
    local Channel_Guild = ChatManager.Instance()._Channel_Guild
    if Channel_Guild ~= nil then
    	self._Channel_Guild = Channel_Guild
        self._Img_OpenGuild:SetActive(self._Channel_Guild)
        self:GetUIObject("Img_GuildBg"):SetActive(not self._Channel_Guild)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Guild"), self._Channel_Guild)
        ChatManager.Instance()._Channel_Guild = self._Channel_Guild
    end
    local Channel_System = ChatManager.Instance()._Channel_System
    if Channel_System ~= nil then
    	self._Channel_System = Channel_System
        self._Img_OpenSystem:SetActive(self._Channel_System)
        self:GetUIObject("Img_SystemBg"):SetActive(not self._Channel_System)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_System"), self._Channel_System)
        ChatManager.Instance()._Channel_System = self._Channel_System
    end
    local Channel_Team = ChatManager.Instance()._Channel_Team
    if Channel_Team ~= nil then
    	self._Channel_Team = Channel_Team
        self._Img_OpenTeam:SetActive(self._Channel_Team)
        self:GetUIObject("Img_TeamBg"):SetActive(not self._Channel_Team)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Team"), self._Channel_Team)
        ChatManager.Instance()._Channel_Team = self._Channel_Team
    end
    local Channel_Current = ChatManager.Instance()._Channel_Current
    if Channel_Current ~= nil then
    	self._Channel_Current = Channel_Current
        self._Img_OpenCurrent:SetActive(self._Channel_Current)
        self:GetUIObject("Img_CurrentBg"):SetActive(not self._Channel_Current)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Current"), self._Channel_Current)
        ChatManager.Instance()._Channel_Current = self._Channel_Current
    end

    local Channel_Combat = ChatManager.Instance()._Channel_Combat
    if Channel_Combat ~= nil then
    	self._Channel_Combat = Channel_Combat
        self._Img_OpenCombat:SetActive(self._Channel_Combat)
        self:GetUIObject("Img_CombatBg"):SetActive(not self._Channel_Combat)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Combat"), self._Channel_Combat)
        ChatManager.Instance()._Channel_Combat = self._Channel_Combat
    end

    local Channel_Social = ChatManager.Instance()._Channel_Social
    if Channel_Social ~= nil then
    	self._Channel_Social = Channel_Social
        self._Img_OpenSocial:SetActive(self._Channel_Social)
        self:GetUIObject("Img_SocialBg"):SetActive(not self._Channel_Social)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Social"), self._Channel_Social)
        ChatManager.Instance()._Channel_Social = self._Channel_Social
    end

    local Channel_Recruit = ChatManager.Instance()._Channel_Recruit
    if Channel_Recruit ~= nil then
    	self._Channel_Recruit = Channel_Recruit
        self._Img_OpenRecruit:SetActive(self._Channel_Recruit)
        self:GetUIObject("Img_RecruitBg"):SetActive(not self._Channel_Recruit)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_Recruit"), self._Channel_Recruit)
        ChatManager.Instance()._Channel_Recruit = self._Channel_Recruit
    end

    local Channel_WorldVoice = UserData:GetField("Channel_WorldVoice")
    if Channel_WorldVoice ~= nil then
    	self._Channel_WorldVoice = Channel_WorldVoice
        self._Img_OpenWorldVoice:SetActive(self._Channel_WorldVoice)
        self:GetUIObject("Img_WorldVoiceBg"):SetActive(not self._Channel_WorldVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelWorld"), self._Channel_WorldVoice)
    end
    local Channel_GuildVoice = UserData:GetField("Channel_GuildVoice")
    if Channel_GuildVoice ~= nil then
    	self._Channel_GuildVoice = Channel_GuildVoice
        self._Img_OpenGuildVoice:SetActive(self._Channel_GuildVoice)
        self:GetUIObject("Img_GuildVoiceBg"):SetActive(not self._Channel_GuildVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelGuild"), self._Channel_GuildVoice)
    end
    local Channel_TeamVoice = UserData:GetField("Channel_TeamVoice")
    if Channel_TeamVoice ~= nil then
    	self._Channel_TeamVoice = Channel_TeamVoice
        self._Img_OpenTeamVoice:SetActive(self._Channel_TeamVoice)
        self:GetUIObject("Img_TeamVoiceBg"):SetActive(not self._Channel_TeamVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelTeam"), self._Channel_TeamVoice)
    end
    local Channel_CurrentVoice = UserData:GetField("Channel_CurrentVoice")
    if Channel_CurrentVoice ~= nil then
    	self._Channel_CurrentVoice = Channel_CurrentVoice
        self._Img_OpenCurrentVoice:SetActive(self._Channel_CurrentVoice)
        self:GetUIObject("Img_CurrentVoiceBg"):SetActive(not self._Channel_CurrentVoice)
        self:UpdateChatLabelColor(self:GetUIObject("Lab_ChannelCurrent"), self._Channel_CurrentVoice)
    end

end

def.method("userdata", "boolean").UpdateChatLabelColor = function (self, ChannelLabel, IsSelect)
    local color = Color.New(144/255, 154/255, 168/255, 1)
    if IsSelect then
        color = Color.New(1, 1, 1, 1)
    end
    GUI.SetTextColor(ChannelLabel, color)
end


def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	--保存聊天设置
    UserData:SetField("Channel_World", self._Channel_World)
    UserData:SetField("Channel_Guild", self._Channel_Guild)
    UserData:SetField("Channel_System", self._Channel_System)
    UserData:SetField("Channel_Team", self._Channel_Team)
    UserData:SetField("Channel_Current", self._Channel_Current)
    UserData:SetField("Channel_Combat", self._Channel_Combat)
    UserData:SetField("Channel_Social", self._Channel_Social)
    UserData:SetField("Channel_Recruit", self._Channel_Recruit)

    UserData:SetField("Channel_WorldVoice", self._Channel_WorldVoice)
    UserData:SetField("Channel_GuildVoice", self._Channel_GuildVoice)
    UserData:SetField("Channel_TeamVoice", self._Channel_TeamVoice)
    UserData:SetField("Channel_CurrentVoice", self._Channel_CurrentVoice)
    UserData:SaveDataToFile()

end

CPanelUIChatSet.Commit()
return CPanelUIChatSet