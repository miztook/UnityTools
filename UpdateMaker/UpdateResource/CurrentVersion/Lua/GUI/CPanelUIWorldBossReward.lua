local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelUIWorldBossReward = Lplus.Extend(CPanelBase, 'CPanelUIWorldBossReward')
local CUIModel = require "GUI.CUIModel"
local CGame = Lplus.ForwardDeclare("CGame")
local MapBasicConfig = require "Data.MapBasicConfig"
local OperatorType = require "PB.net".S2CWorldBossState.OperatorType
local def = CPanelUIWorldBossReward.define

def.field('userdata')._Img_KillBossIcon = nil
def.field('userdata')._Lab_KillBossName = nil
def.field('userdata')._Img_GuildIcon = nil
def.field('userdata')._Lab_GuildName = nil
def.field('userdata')._Lab_GuildLevel = nil
def.field('userdata')._Lab_SuccessGuildLevel = nil
def.field('userdata')._Lab_SuccessGuildName = nil
def.field('userdata')._Lab_RankingNum = nil
def.field('userdata')._List_GuildReward = nil
def.field('userdata')._List_SingleReward = nil
def.field('userdata')._Img_Arrow = nil
def.field('userdata')._Frame_RankingList = nil
def.field('userdata')._Lab_Ranking = nil
def.field('userdata')._Img_warn = nil
def.field('userdata')._Lab_warn = nil

def.field("table")._KillBossRewardInfo = BlankTable
def.field("table")._BossData = BlankTable
def.field("table")._WorldBossRankInfoList = BlankTable
def.field("table")._LastDamageRankInfo = BlankTable
def.field("table")._GuildRewards = BlankTable
def.field("table")._SingleRewards = BlankTable
def.field("table")._GuildRewardInfo = BlankTable
def.field("string")._DefaultIcon = ""
def.field("number")._CurIndex = 0       -- 当前排名
def.field("number")._MaxListNum = 4    -- 最大排名列表数量

local instance = nil
def.static('=>', CPanelUIWorldBossReward).Instance = function ()
	if not instance then
        instance = CPanelUIWorldBossReward()
        instance._PrefabPath = PATH.UI_WorldBoss_Settlement
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Img_KillBossIcon = self:GetUIObject('Img_KillBossIcon')
    self._Lab_KillBossName = self:GetUIObject('Lab_KillBossName')
    self._Img_GuildIcon = self:GetUIObject('Img_GuildIcon')
    self._Lab_GuildName = self:GetUIObject('Lab_KillName0')   -- 击杀名字
    self._Lab_GuildLevel = self:GetUIObject('Lab_GuildLevel')
    self._Lab_RankingNum = self:GetUIObject('Lab_RankingNum')
    self._List_GuildReward = self:GetUIObject('List_GuildReward'):GetComponent(ClassType.GNewList)
    self._List_SingleReward = self:GetUIObject('List_SingleReward'):GetComponent(ClassType.GNewList)
    self._Frame_RankingList = self:GetUIObject('Frame_RankingList')
    self._Lab_Ranking = self:GetUIObject('Lab_Ranking')
    self._Img_warn = self:GetUIObject('Img_warn')
    self._Lab_warn = self._Img_warn:FindChild('Lab_Warn')

    self._Frame_RankingList:SetActive(false)

    for i = 1, self._MaxListNum do
        local Frame_Ranking = self._Frame_RankingList:FindChild('Frame_Ranking'..i)
        if Frame_Ranking ~= nil then 
            Frame_Ranking:SetActive(false) 
        end
    end
end

def.override("dynamic").OnData = function(self,data)  
    self._SingleRewards = {}
    self._KillBossRewardInfo = {}
    self._BossData = {}
    self._GuildRewards = {}
    self._WorldBossRankInfoList = {}
    self._LastDamageRankInfo = {}
    self._GuildRewardInfo = {}
    self._KillBossRewardInfo = data
    local WorldBossData = CElementData.GetTemplate("Monster", data.BossId)   
    if WorldBossData == nil then return end
    self._BossData = WorldBossData
    self._WorldBossRankInfoList = data.WorldBossRankInfoList
    self._LastDamageRankInfo = data.LastDamageRankInfo
    -- 按伤害从大到小排序
    local function sortFunc(a, b)
        if a.Demage ~= b.Demage then
            return a.Demage > b.Demage
        end
        return false
    end
    table.sort(self._WorldBossRankInfoList, sortFunc)
    for i,v in ipairs(self._WorldBossRankInfoList) do
        local isGuild = IsNilOrEmptyString(v.GuildName)
        if not isGuild then
            if game._GuildMan:IsHostInGuild() and game._HostPlayer._Guild._GuildName == v.GuildName then
                self._GuildRewards = v.GuildRewardItemInfoList   -- 公会奖励
                self._GuildRewardInfo = v
                self._CurIndex = i         
            end
        else
            if game._HostPlayer._InfoData._Name == v.RoleName then
                self._GuildRewardInfo = v
                self._CurIndex = i   
            end
        end
    end

    -- 不在前三没有公会奖励
    if self._GuildRewardInfo.GuildName == nil and self._GuildRewardInfo.RoleName == nil then
        if game._GuildMan:IsHostInGuild() then
            self._GuildRewardInfo.GuildName = game._HostPlayer._Guild._GuildName
            self._GuildRewardInfo.GuildLevel = game._HostPlayer._Guild._GuildLevel
            self._GuildRewardInfo.RoleName = game._HostPlayer._InfoData._Name
            self._GuildRewardInfo.RoleLevel = game._HostPlayer._InfoData._Level
        else
            self._GuildRewardInfo.RoleName = game._HostPlayer._InfoData._Name
            self._GuildRewardInfo.RoleLevel = game._HostPlayer._InfoData._Level
        end
    end
    self._CurIndex = 0 
    self._SingleRewards = data.RoleRewardItemInfoList
    self:UpdateFrameShow()   
    self._DefaultIcon = "Item/defaultItemIcon" 
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_GuildReward' or id == 'List_SingleReward' then
        -- 统一初始化奖励物品，模块的类必须有_RewardData
        local rewardsData = nil
        if id == 'List_GuildReward' then
            rewardsData = self._GuildRewards
        elseif id == 'List_SingleReward' then
            rewardsData = self._SingleRewards
        end
		if rewardsData == nil then return end
		local reward = rewardsData[index + 1]
		if reward ~= nil then
            local frame_item_icon = GUITools.GetChild(item, 0)
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_item_icon, reward.Tid, 0)
            else
                local grade = -1 -- 装备类型的显示评分
                local itemTemplate = CElementData.GetItemTemplate(reward.Tid)
                if itemTemplate ~= nil then
                    local EItemType = require "PB.Template".Item.EItemType
                    if itemTemplate.ItemType == EItemType.Equipment then
                        grade = reward.FightProperty.star
                    end
                end

                IconTools.InitItemIconNew(frame_item_icon, reward.Tid, 
                { 
                    [EItemIconTag.Grade] = grade,
                })
            end
        end 
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Shuaguang , item, item, -1)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_GuildReward' or id == 'List_SingleReward' then
        -- 奖励列表
        local rewardsData = nil
        if id == 'List_GuildReward' then
            rewardsData = self._GuildRewards
        elseif id == 'List_SingleReward' then
            rewardsData = self._SingleRewards
        end
		if rewardsData == nil then return end        
		local rewardData = rewardsData[index + 1]
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
        game._GUIMan:Close("CPanelUIWorldBossReward")
    end
end

--更新是否显示分界面
def.method().UpdateFrameShow = function(self)   
        -- self._Frame_KillBoss:GetComponent(ClassType.DOTweenPlayer):Restart("1")        
        GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Kill_Success , self._Img_Arrow, self._Img_Arrow, -1)

        -- boss名字 boss图标（暂时没有）
        GUI.SetText(self._Lab_KillBossName, self._BossData.TextDisplayName)
        GUITools.SetIcon(self._Img_KillBossIcon, self._BossData.IconAtlasPath)

        local isGuild = IsNilOrEmptyString(self._GuildRewardInfo.GuildName)

        -- GameUtil.PlayUISfx(PATH.UI_WORLDBOSS_Settlement_Title , self._Img_KillBossGuildTitle, self._Img_KillBossGuildTitle, -1)
        if self._CurIndex > 0 then
            GUI.SetText(self._Lab_RankingNum, string.format(StringTable.Get(21015) ,self._CurIndex))
            if not isGuild then
                self._Img_warn:SetActive(false)
            else
                self._Img_warn:SetActive(true)
                GUI.SetText(self._Lab_warn, StringTable.Get(21026))
            end
        else
            GUI.SetText(self._Lab_RankingNum, StringTable.Get(21022))
            self._Img_warn:SetActive(true)
            if not isGuild then
                GUI.SetText(self._Lab_warn, StringTable.Get(21025))
            else
                GUI.SetText(self._Lab_warn, StringTable.Get(21027))
            end
        end
        
        if not isGuild then   -- game._GuildMan:IsHostInGuild()
            
            self:GetUIObject('View_GuildReward'):SetActive(true)
            self:GetUIObject("Img_HeadBG"):SetActive(false)
            self:GetUIObject("Img_GuildBg"):SetActive(true)
            -- 公会等级，公会名字，公会图标        
            GUI.SetText(self._Lab_Ranking, StringTable.Get(21020))
            if self._GuildRewardInfo.GuildName ~= nil then
                GUI.SetText(self._Lab_GuildName, self._GuildRewardInfo.GuildName)
            end
            local GuildLevel = "Lv ".. self._GuildRewardInfo.GuildLevel
            GUI.SetText(self._Lab_GuildLevel, GuildLevel)

            if self._GuildRewardInfo.GuildIcon ~= nil then
                GUITools.SetGuildIcon(self:GetUIObject("Img_GuildBg"), CElementData.GetTemplate("GuildIcon", self._GuildRewardInfo.GuildIcon.BaseColorID).IconPath) 
                GUITools.SetGuildIcon(self:GetUIObject("Img_GuildRound"), CElementData.GetTemplate("GuildIcon", self._GuildRewardInfo.GuildIcon.FrameID).IconPath)  
                GUITools.SetGuildIcon(self._Img_GuildIcon, CElementData.GetTemplate("GuildIcon", self._GuildRewardInfo.GuildIcon.ImageID).IconPath)            
            else
                GUITools.SetGuildIcon(self:GetUIObject("Img_GuildBg"), CElementData.GetTemplate("GuildIcon", game._HostPlayer._Guild._GuildIconInfo._BaseColorID).IconPath) 
                GUITools.SetGuildIcon(self:GetUIObject("Img_GuildRound"), CElementData.GetTemplate("GuildIcon", game._HostPlayer._Guild._GuildIconInfo._FrameID).IconPath)  
                GUITools.SetGuildIcon(self._Img_GuildIcon, CElementData.GetTemplate("GuildIcon", game._HostPlayer._Guild._GuildIconInfo._ImageID).IconPath)            
            end

            
            -- local DemageRate = self._GuildRewardInfo.DemageRate.."%"
            -- GUI.SetText(self._Lab_HurtScale, DemageRate)
            if self._List_GuildReward ~= nil then
                -- warn("self._GuildRewards == ", #self._GuildRewards)
                self._List_GuildReward:SetItemCount(#self._GuildRewards)
            end    
        else
            
            self:GetUIObject('View_GuildReward'):SetActive(false)
            self:GetUIObject("Img_HeadBG"):SetActive(true)
            self:GetUIObject("Img_GuildBg"):SetActive(false)
            GUI.SetText(self._Lab_Ranking, StringTable.Get(21021))
            GUI.SetText(self._Lab_GuildName, self._GuildRewardInfo.RoleName)
            local GuildLevel = "Lv ".. self._GuildRewardInfo.RoleLevel
            GUI.SetText(self._Lab_GuildLevel, GuildLevel)
        end
        if self._List_SingleReward ~= nil then
            -- warn("self._SingleRewards == ", #self._SingleRewards)
            self._List_SingleReward:SetItemCount(#self._SingleRewards)
        end
end

def.override("string").OnPointerDown = function(self, id)
    if id == "Btn_RankingList" then
        self:UpdateFrameRankingList(true)
    end
end

-- def.override("string").OnPointerUp = function(self, id)
--     if id == "Btn_RankingList" then
--         self:UpdateFrameRankingList(false)
--     end
-- end

--target不为空点击就可以执行
def.override("userdata").OnPointerClick = function(self,target)
    if target == nil then return end
    self:UpdateFrameRankingList(false)     
end

def.method("boolean").UpdateFrameRankingList = function(self, IsShowRanking) 
    self._Frame_RankingList:SetActive(IsShowRanking)
    if IsShowRanking then
        for i,v in ipairs(self._WorldBossRankInfoList) do
            local Frame_Ranking = self._Frame_RankingList:FindChild('Frame_Ranking'..i)
            if Frame_Ranking == nil then 
                self._Frame_RankingList:SetActive(false) 
                warn("Frame_Ranking == nil!!!") 
                return 
            end
            Frame_Ranking:SetActive(true)
            local Lab_Ranking = self:GetUIObject('Lab_Ranking'..i)
            local Lab_KillType = self:GetUIObject('Lab_KillType'..i - 1)
            local Lab_Level = self:GetUIObject('Lab_Level'..i - 1)
            local Lab_KillName = self:GetUIObject('Lab_KillName'..i)
            local Lab_Hurt = self:GetUIObject('Lab_Hurt'..i - 1)
            local Lab_HurtScale = self:GetUIObject('Lab_HurtScale'..i - 1)

            if i <= 3 then
                GUI.SetText(Lab_Ranking, tostring(i))
                Lab_HurtScale:SetActive(true)
                GUI.SetText(Lab_HurtScale, tostring(v.DemageRate))
            end

            local isGuild = IsNilOrEmptyString(v.GuildName)
            local GuildLevel = nil
            if not isGuild then
                GUI.SetText(Lab_KillType, StringTable.Get(21018))
                GUI.SetText(Lab_KillName, v.GuildName)
                if game._HostPlayer._Guild._GuildName == v.GuildName then
                    Frame_Ranking:FindChild("Img_Check"):SetActive(true)
                else
                    Frame_Ranking:FindChild("Img_Check"):SetActive(false)
                end
                
                GuildLevel = "Lv ".. v.GuildLevel
            else
                GUI.SetText(Lab_KillType, StringTable.Get(21019))
                GUI.SetText(Lab_KillName, v.RoleName)
                if game._HostPlayer._InfoData._Name == v.RoleName then
                    Frame_Ranking:FindChild("Img_Check"):SetActive(true)
                else
                    Frame_Ranking:FindChild("Img_Check"):SetActive(false)
                end
                GuildLevel = "Lv ".. v.RoleLevel
            end
            if GuildLevel ~= nil then
                GUI.SetText(Lab_Level, GuildLevel)
            end
        end

        -- 最后一击排名信息
        if #self._LastDamageRankInfo ~= 0 or self._LastDamageRankInfo ~= nil then
            local LastDamageRankIndex = 4
            local Frame_Ranking = self._Frame_RankingList:FindChild('Frame_Ranking'..LastDamageRankIndex)
            if Frame_Ranking == nil then 
                self._Frame_RankingList:SetActive(false) 
                warn("Frame_Ranking == nil!!!") 
                return 
            end
            Frame_Ranking:SetActive(true)
            local Lab_Ranking = self:GetUIObject('Lab_Ranking'..LastDamageRankIndex)
            local Lab_KillType = self:GetUIObject('Lab_KillType'..LastDamageRankIndex - 1)
            local Lab_Level = self:GetUIObject('Lab_Level'..LastDamageRankIndex - 1)
            local Lab_KillName = self:GetUIObject('Lab_KillName'..LastDamageRankIndex)
            local Lab_Hurt = self:GetUIObject('Lab_Hurt'..LastDamageRankIndex - 1)
            local Lab_HurtScale = self:GetUIObject('Lab_HurtScale'..LastDamageRankIndex - 1)

            local isGuild = IsNilOrEmptyString(self._LastDamageRankInfo.GuildName)
            local GuildLevel = nil
            if not isGuild then
                GUI.SetText(Lab_KillType, StringTable.Get(21018))
                GUI.SetText(Lab_KillName, self._LastDamageRankInfo.GuildName)
                if game._HostPlayer._Guild._GuildName == self._LastDamageRankInfo.GuildName then
                    Frame_Ranking:FindChild("Img_Check"):SetActive(true)
                else
                    Frame_Ranking:FindChild("Img_Check"):SetActive(false)
                end
                
                GuildLevel = "Lv ".. self._LastDamageRankInfo.GuildLevel
            else
                GUI.SetText(Lab_KillType, StringTable.Get(21019))
                GUI.SetText(Lab_KillName, self._LastDamageRankInfo.RoleName)
                if game._HostPlayer._InfoData._Name == self._LastDamageRankInfo.RoleName then
                    Frame_Ranking:FindChild("Img_Check"):SetActive(true)
                else
                    Frame_Ranking:FindChild("Img_Check"):SetActive(false)
                end
                GuildLevel = "Lv ".. self._LastDamageRankInfo.RoleLevel
            end
            if GuildLevel ~= nil then
                GUI.SetText(Lab_Level, GuildLevel)
            end
        end
    end
end


def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._SingleRewards = {}
    self._KillBossRewardInfo = {}
    self._BossData = {}
    self._GuildRewards = {}
    self._DefaultIcon = ""
    self._WorldBossRankInfoList = {}
    self._LastDamageRankInfo = {}
    self._GuildRewardInfo = {}
end

def.override().OnDestroy = function (self)
    self._Img_KillBossIcon = nil
    self._Lab_KillBossName = nil
    self._Img_GuildIcon = nil
    self._Lab_GuildName = nil
    self._Lab_GuildLevel = nil
    self._Lab_RankingNum = nil
    self._List_GuildReward = nil
    self._Img_Arrow = nil
    self._Frame_RankingList = nil
    self._Lab_Ranking = nil
end

CPanelUIWorldBossReward.Commit()
return CPanelUIWorldBossReward