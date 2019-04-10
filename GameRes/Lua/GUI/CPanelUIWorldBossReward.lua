local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelUIWorldBossReward = Lplus.Extend(CPanelBase, 'CPanelUIWorldBossReward')
local CUIModel = require "GUI.CUIModel"
local CGame = Lplus.ForwardDeclare("CGame")
local MapBasicConfig = require "Data.MapBasicConfig"
local OperatorType = require "PB.net".S2CWorldBossState.OperatorType
local def = CPanelUIWorldBossReward.define

def.field('userdata')._Frame_KillBoss = nil
def.field('userdata')._Img_KillBossIcon = nil
def.field('userdata')._Lab_KillBossName = nil
def.field('userdata')._Frame_KillBossGuild = nil
def.field('userdata')._Img_GuildIcon = nil
def.field('userdata')._Lab_GuildName = nil
def.field('userdata')._Lab_GuildLevel = nil
def.field('userdata')._Frame_SuccessGuild = nil
def.field('userdata')._Img_SuccessGuildIcon = nil
def.field('userdata')._Lab_SuccessGuildLevel = nil
def.field('userdata')._Lab_SuccessGuildName = nil
def.field('userdata')._Lab_BossName = nil
def.field('userdata')._Img_BossIcon = nil
def.field('userdata')._Lab_Hurt = nil
def.field('userdata')._Lab_HurtScale = nil
def.field('userdata')._List_Gift = nil
def.field('userdata')._Frame_Reward = nil
def.field('userdata')._Img_SettlementBG = nil
def.field('userdata')._Img_Title = nil
def.field('userdata')._Img_Arrow = nil
def.field('userdata')._Img_KillBossGuildTitle = nil

def.field("table")._KillBossRewardInfo = BlankTable
def.field("table")._BossData = BlankTable
def.field("table")._Rewards = BlankTable
def.field("number")._CurShowPage = 1
def.field("string")._DefaultIcon = ""
def.field("number")._CloseTimerID = 0 --副本timerID

local PageState = 
{
    PageKillBoss = 1,
    -- PageSuccessGuild = 2,
    PageRewardInfo = 2,
    PageClose = 3,
}

local instance = nil
def.static('=>', CPanelUIWorldBossReward).Instance = function ()
	if not instance then
        instance = CPanelUIWorldBossReward()
        instance._PrefabPath = PATH.UI_WorldBoss_Settlement
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Frame_KillBoss = self:GetUIObject('Frame_KillBoss')
    self._Img_KillBossIcon = self:GetUIObject('Img_KillBossIcon')
    self._Lab_KillBossName = self:GetUIObject('Lab_KillBossName')
    self._Frame_KillBossGuild = self:GetUIObject('Frame_KillBossGuild')
    self._Img_GuildIcon = self:GetUIObject('Img_GuildIcon')
    self._Lab_GuildName = self:GetUIObject('Lab_GuildName')
    self._Lab_GuildLevel = self:GetUIObject('Lab_GuildLevel')
    self._Frame_SuccessGuild = self:GetUIObject('Frame_SuccessGuild')
    self._Img_SuccessGuildIcon = self:GetUIObject('Img_SuccessGuildIcon')
    self._Lab_SuccessGuildLevel = self:GetUIObject('Lab_SuccessGuildLevel')
    self._Lab_SuccessGuildName = self:GetUIObject('Lab_SuccessGuildName')
    self._Lab_BossName = self:GetUIObject('Lab_BossName')
    self._Img_BossIcon = self:GetUIObject('Img_BossIcon')
    self._Lab_Hurt = self:GetUIObject('Lab_Hurt')
    self._Lab_HurtScale = self:GetUIObject('Lab_HurtScale')
    self._Frame_Reward = self:GetUIObject('View_Reward')
    self._Img_SettlementBG = self:GetUIObject('Img_SettlementBG')
    self._List_Gift = self:GetUIObject('List_Reward'):GetComponent(ClassType.GNewList)
    self._Img_Title = self:GetUIObject('Img_Title')
    self._Img_KillBossGuildTitle = self:GetUIObject('Img_KillBossGuildTitle')

    self._Frame_KillBoss:SetActive(false)
    self._Frame_KillBossGuild:SetActive(false)
    self._Frame_SuccessGuild:SetActive(false)
    self._Frame_Reward:SetActive(false)

end

local function OnRemoveCloseTimer()
	if instance._CloseTimerID ~= 0 then
        _G.RemoveGlobalTimer(instance._CloseTimerID)
        instance._CloseTimerID = 0
    end
end

--添加结算关闭倒计时 10秒  -----> 教练
local function OnAddCloseTimer()     
    if instance._CloseTimerID == 0 then
        local time = 10
        local callback = function()   
            time = time - 1        
            if time <= 0 then
                OnRemoveCloseTimer()
                instance._CurShowPage = instance._CurShowPage + 1
                instance:ChangePage(instance._CurShowPage) 
            end
        end
        instance._CloseTimerID = _G.AddGlobalTimer(1, false, callback)
    end
end

def.override("dynamic").OnData = function(self,data)  
    self._KillBossRewardInfo = data
    self._CurShowPage = 1
    local WorldBossData = CElementData.GetTemplate("Monster", data.BossId)   
    if WorldBossData == nil then return end
    self._BossData = WorldBossData
    self._Rewards = data.ItemInfo
    self:ChangePage(self._CurShowPage)     
    self._DefaultIcon = "Item/defaultItemIcon" 
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_Reward' then
        -- 统一初始化奖励物品，模块的类必须有_RewardData
		local rewardsData = self._Rewards
		if rewardsData == nil then return end
		local reward = self._Rewards[index + 1]
		if reward ~= nil then
            local frame_item_icon = GUITools.GetChild(item, 0)
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_item_icon, reward.Tid, 0)
            else
                IconTools.InitItemIconNew(frame_item_icon, reward.Tid)
            end
        end 
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Shuaguang , item, item, -1)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_Reward' then
        -- 奖励列表
		local rewardData = self._Rewards[index + 1]
		if not rewardData.IsTokenMoney then
			CItemTipMan.ShowItemTips(rewardData.Tid, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
        else
            local panelData = 
                {
                    _MoneyID = rewardData.Tid ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = item ,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
		end
    end

end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_ChangePage' then
        self._CurShowPage = self._CurShowPage + 1
        self:ChangePage(self._CurShowPage) 
    end
end


--切换功能页面
def.method("number").ChangePage = function(self, pageIndex)
    self._CurShowPage = pageIndex
    --更新是否显示分界面
    self:UpdateFrameShow()
end

--更新是否显示分界面
def.method().UpdateFrameShow = function(self)
    if self._CurShowPage == PageState.PageKillBoss then        
        self._Frame_KillBoss:SetActive(true)
        self._Frame_KillBossGuild:SetActive(false)
        self._Frame_SuccessGuild:SetActive(false)
        self._Frame_Reward:SetActive(false)
        self._Frame_KillBoss:GetComponent(ClassType.DOTweenPlayer):Restart("1")        
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Kill_Success , self._Img_Arrow, self._Img_Arrow, -1)

        -- boss名字 boss图标（暂时没有）
        GUI.SetText(self._Lab_KillBossName, self._BossData.TextDisplayName)
        GUITools.SetIcon(self._Img_KillBossIcon, self._BossData.IconAtlasPath)
        OnAddCloseTimer()

        --[[
    elseif self._CurShowPage == PageState.PageSuccessGuild then
        self._Frame_KillBoss:SetActive(false)
        self._Frame_KillBossGuild:SetActive(true)
        self._Frame_SuccessGuild:SetActive(false)
        self._Frame_Reward:SetActive(false)
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Title , self._Img_KillBossGuildTitle, self._Img_KillBossGuildTitle, -1)

        -- 公会等级，公会名字，公会图标        
        if self._KillBossRewardInfo.GuildName ~= "" then
            GUI.SetText(self._Lab_GuildName, self._KillBossRewardInfo.GuildName)
            self._Lab_GuildLevel:SetActive(true)
            local GuildLevel = "Lv ".. self._KillBossRewardInfo.GuildLevel
            GUI.SetText(self._Lab_GuildLevel, GuildLevel)
            GUITools.SetGuildIcon(self:GetUIObject("Img_GuildBg"), CElementData.GetTemplate("GuildIcon", self._KillBossRewardInfo.GuildIcon.BaseColorID).IconPath) 
            GUITools.SetGuildIcon(self:GetUIObject("Img_GuildRound"), CElementData.GetTemplate("GuildIcon", self._KillBossRewardInfo.GuildIcon.FrameID).IconPath)  
            GUITools.SetGuildIcon(self._Img_GuildIcon, CElementData.GetTemplate("GuildIcon", self._KillBossRewardInfo.GuildIcon.ImageID).IconPath)
        else
            GUI.SetText(self._Lab_GuildName, self._KillBossRewardInfo.RoleName)
            self._Lab_GuildLevel:SetActive(false)
            GUITools.SetIcon(self._Img_GuildIcon, self._DefaultIcon)
        end
        OnAddCloseTimer()
        ]]
    elseif self._CurShowPage == PageState.PageRewardInfo then
        self._Frame_KillBoss:SetActive(false)
        self._Frame_KillBossGuild:SetActive(false)
        self._Frame_SuccessGuild:SetActive(true)
        self._Frame_Reward:SetActive(true)
        self._Frame_SuccessGuild:GetComponent(ClassType.DOTweenPlayer):Restart("1")
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Bg , self._Img_SettlementBG, self._Img_SettlementBG, -1)
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Title , self._Img_Title, self._Img_Title, -1)
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Touxiang , self._Img_SuccessGuildIcon, self._Img_SuccessGuildIcon, -1)

        local isGuild = self._KillBossRewardInfo.GuildName ~= ""
        self:GetUIObject("Img_GuildBg1"):SetActive(isGuild)
        self:GetUIObject("Img_GuildRound1"):SetActive(isGuild)
        self._Lab_SuccessGuildLevel:SetActive(isGuild)
        self._Img_SuccessGuildIcon:SetActive(isGuild)
        -- 公会等级，公会名字，公会图标        
        if self._KillBossRewardInfo.GuildName ~= "" then
            GUI.SetText(self._Lab_SuccessGuildName, self._KillBossRewardInfo.GuildName)
            local GuildLevel = "Lv ".. self._KillBossRewardInfo.GuildLevel
            GUI.SetText(self._Lab_SuccessGuildLevel, GuildLevel)
            GUITools.SetGuildIcon(self:GetUIObject("Img_GuildBg1"), CElementData.GetTemplate("GuildIcon", self._KillBossRewardInfo.GuildIcon.BaseColorID).IconPath)  
            GUITools.SetGuildIcon(self:GetUIObject("Img_GuildRound1"), CElementData.GetTemplate("GuildIcon", self._KillBossRewardInfo.GuildIcon.FrameID).IconPath) 
            GUITools.SetGuildIcon(self._Img_SuccessGuildIcon, CElementData.GetTemplate("GuildIcon", self._KillBossRewardInfo.GuildIcon.ImageID).IconPath)
        else
            GUI.SetText(self._Lab_SuccessGuildName, self._KillBossRewardInfo.RoleName)
        end

        -- boss名字 
        GUI.SetText(self._Lab_BossName, self._BossData.TextDisplayName)
        GUITools.SetIcon(self._Img_BossIcon, self._BossData.IconAtlasPath)
        GUI.SetText(self._Lab_Hurt, tostring(self._KillBossRewardInfo.Demage))
        local DemageRate = self._KillBossRewardInfo.DemageRate.."%"
        GUI.SetText(self._Lab_HurtScale, DemageRate)
        if self._List_Gift ~= nil then
            warn("self._Rewards == ", #self._Rewards)
            self._List_Gift:SetItemCount(#self._Rewards)
        end    
        OnAddCloseTimer()  
    elseif self._CurShowPage == PageState.PageClose then    
        if self._Img_Arrow ~= nil and self._Img_KillBossGuildTitle ~= nil and self._Img_SettlementBG ~= nil and self._Img_Title ~= nil and self._Img_SuccessGuildIcon ~= nil then
            GameUtil.StopUISfx(PATH.UI_WORLDBOSS_Kill_Success , self._Img_Arrow)
            GameUtil.StopUISfx(PATH.UI_WORLDBOSS_Settlement_Title, self._Img_KillBossGuildTitle)
            GameUtil.StopUISfx(PATH.UI_WORLDBOSS_Settlement_Bg , self._Img_SettlementBG)
            GameUtil.StopUISfx(PATH.UI_WORLDBOSS_Settlement_Title , self._Img_Title)
            GameUtil.StopUISfx(PATH.UI_WORLDBOSS_Settlement_Touxiang , self._Img_SuccessGuildIcon)   
        end
        game._GUIMan:Close("CPanelUIWorldBossReward")      
    end

end


def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._Rewards = {}
    self._KillBossRewardInfo = {}
    self._BossData = {}
    self._Rewards = {}
    self._CurShowPage = 1
    self._DefaultIcon = ""
    OnRemoveCloseTimer()
end

def.override().OnDestroy = function (self)
    self._Frame_KillBoss = nil
    self._Img_KillBossIcon = nil
    self._Lab_KillBossName = nil
    self._Frame_KillBossGuild = nil
    self._Img_GuildIcon = nil
    self._Lab_GuildName = nil
    self._Lab_GuildLevel = nil
    self._Frame_SuccessGuild = nil
    self._Img_SuccessGuildIcon = nil
    self._Lab_SuccessGuildLevel = nil
    self._Lab_SuccessGuildName = nil
    self._Lab_BossName = nil
    self._Img_BossIcon = nil
    self._Lab_Hurt = nil
    self._Lab_HurtScale = nil
    self._List_Gift = nil
    self._Frame_Reward = nil
    self._Img_SettlementBG = nil
    self._Img_Title = nil
    self._Img_Arrow = nil
    self._Img_KillBossGuildTitle = nil
end

CPanelUIWorldBossReward.Commit()
return CPanelUIWorldBossReward