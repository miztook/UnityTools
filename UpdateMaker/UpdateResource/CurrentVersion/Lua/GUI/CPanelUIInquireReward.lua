local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelUIInquireReward = Lplus.Extend(CPanelBase, 'CPanelUIInquireReward')
local CUIModel = require "GUI.CUIModel"
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelUIInquireReward.define
local MapBasicConfig = require "Data.MapBasicConfig"

def.field("table")._RewardImgObjList = BlankTable
def.field("table")._RewardObjList = BlankTable
def.field("table")._GuildReward = BlankTable
def.field("table")._SingleReward = BlankTable
def.field("number")._MaxListNum = 5    -- 最大奖励列表数量
def.field('number')._CurType = -1     --当前打开的分页签

local instance = nil
def.static('=>', CPanelUIInquireReward).Instance = function ()
	if not instance then
        instance = CPanelUIInquireReward()
        instance._PrefabPath = PATH.UI_InquireReward
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance:SetupSortingParam()
	end
	return instance
end

-- 面板类型
local EPageType =
{
    GuildReward = 0,            -- 公会奖励
    SingleReward = 1,           -- 个人奖励
}

def.override().OnCreate = function(self)
    for i=1, self._MaxListNum do
        table.insert(self._RewardImgObjList, self:GetUIObject('Img_Reward'..i))
        table.insert(self._RewardObjList, self:GetUIObject('List_Reward'..i))
    end


end

def.override("dynamic").OnData = function(self,data)  
    if data == nil then warn("bossid == nil !!!") return end
    -- warn("bossid == ", data)
    local WorldBossData = CElementData.GetTemplate("WorldBossConfig", data)   
    if WorldBossData == nil then return end
    string.gsub(WorldBossData.GuildRewardRankIds, '[^*]+', function(w) table.insert(self._GuildReward, w) end )
    string.gsub(WorldBossData.RoleRewardRankIds, '[^*]+', function(w) table.insert(self._SingleReward, w) end )
    if WorldBossData.LastBloodId ~= nil and WorldBossData.LastBloodId > 0 then
        self._SingleReward[#self._SingleReward + 1 ] = WorldBossData.LastBloodId
    end
    
    if WorldBossData.PartiRewardId ~= nil and WorldBossData.PartiRewardId > 0 then
        self._SingleReward[#self._SingleReward + 1 ] = WorldBossData.PartiRewardId
    end
    
    self:InitRewardContent(EPageType.GuildReward)
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if id == "Rdo_1" and checked then
        self:InitRewardContent(EPageType.GuildReward)
    elseif id == "Rdo_2" and checked then 
        self:InitRewardContent(EPageType.SingleReward)
    end 
end

def.method("number").InitRewardContent = function(self, destType)
    local originType = self._CurType
    if destType == originType then return end
    self._CurType = destType
    if destType == EPageType.GuildReward then
        for i = 1, self._MaxListNum do
            local GuildRewardId = tonumber(self._GuildReward[i])            
            local Img_Reward = self._RewardImgObjList[i]
            local List_Reward = self._RewardObjList[i]
            if GuildRewardId ~= nil then
                Img_Reward:SetActive(true)
                local rewardList = GUITools.GetRewardList(GuildRewardId, true)
                if rewardList ~= nil then
                    List_Reward:GetComponent(ClassType.GNewList):SetItemCount(#rewardList)
                end
            else
                Img_Reward:SetActive(false)
            end
        end
    elseif destType == EPageType.SingleReward then
        for i = 1, self._MaxListNum do
            local SingleRewardId = tonumber(self._SingleReward[i])
            local Img_Reward = self._RewardImgObjList[i]
            local List_Reward = self._RewardObjList[i]
            if SingleRewardId ~= nil then
                Img_Reward:SetActive(true)
                local rewardList = GUITools.GetRewardList(SingleRewardId, true)
                if rewardList ~= nil then
                    List_Reward:GetComponent(ClassType.GNewList):SetItemCount(#rewardList)
                end
            else
                Img_Reward:SetActive(false)
            end
        end
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if string.find(id, "List_Reward") then
        -- 统一初始化奖励物品，模块的类必须有_RewardData
        local rewardId = tonumber(string.sub(id, string.len("List_Reward")+1,-1))  
        local rewardsData = nil 
        if self._CurType == EPageType.GuildReward then
            rewardsData = GUITools.GetRewardList(tonumber(self._GuildReward[rewardId]), false)
        elseif self._CurType == EPageType.SingleReward then
            rewardsData = GUITools.GetRewardList(tonumber(self._SingleReward[rewardId]), false)
        end

		if rewardsData == nil then
			warn("Rewards data is null on init item in WorldBoss!!!")
			return
		end
		local reward = rewardsData[index+1]
        if reward ~= nil then
			local frame_icon = GUITools.GetChild(item, 0)
            if not IsNil(frame_icon) then
                local setting =
                {
                    [EItemIconTag.Probability] = reward.Data.ProbabilityType == EnumDef.ERewardProbabilityType.Low,
                }
                IconTools.InitItemIconNew(frame_icon, reward.Data.Id, setting)
			end
		end
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if string.find(id, "List_Reward") then
        -- 奖励列表        
        local rewardId = tonumber(string.sub(id, string.len("List_Reward")+1,-1))  
        local rewardsData = nil 
        if self._CurType == EPageType.GuildReward then
            rewardsData = GUITools.GetRewardList(tonumber(self._GuildReward[rewardId]), false)
        elseif self._CurType == EPageType.SingleReward then
            rewardsData = GUITools.GetRewardList(tonumber(self._SingleReward[rewardId]), false)
        end

		if rewardsData == nil then
			warn("Rewards data is null on select item in WworldBoss")
			return
		end
		local reward = rewardsData[index + 1]
		if not reward.IsTokenMoney then
			CItemTipMan.ShowItemTips(reward.Data.Id, TipsPopFrom.OTHER_PANEL, item, TipPosition.FIX_POSITION)
		else
			local panelData = {
				_MoneyID = reward.Data.Id,
				_TipPos = TipPosition.FIX_POSITION,
				_TargetObj = item,
			}
			CItemTipMan.ShowMoneyTips(panelData)
		end
    end

end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Close' then
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    self._RewardImgObjList = {}
    self._RewardObjList = {}
    self._GuildReward = {}
    self._SingleReward = {}
    self._MaxListNum = 5
    self._CurType = -1
end

CPanelUIInquireReward.Commit()
return CPanelUIInquireReward