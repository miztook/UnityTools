local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelUIEyeEntranceTips = Lplus.Extend(CPanelBase, 'CPanelUIEyeEntranceTips')
local CUIModel = require "GUI.CUIModel"
local CTeamMan = require "Team.CTeamMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CCommonBtn = require "GUI.CCommonBtn"
local def = CPanelUIEyeEntranceTips.define
local MapBasicConfig = require "Data.MapBasicConfig"

def.field('userdata')._Lab_Title = nil
def.field('userdata')._Lab_EntranceLimitLevel = nil
def.field('userdata')._Lab_EntranceLimitTitle = nil
def.field('userdata')._Lab_EntranceLimitEnter = nil
def.field('userdata').Btn_Enter1 = nil
def.field('userdata').Btn_Enter2 = nil
def.field('userdata')._Lab_EntranceRewardCount = nil
def.field(CCommonBtn)._Btn_Team = nil
def.field('userdata')._List_Gift = nil
def.field('table')._ParentUI = nil
def.field("table")._Rewards = BlankTable
def.field("table")._Dungeondata = BlankTable

local instance = nil
def.static('=>', CPanelUIEyeEntranceTips).Instance = function ()
	if not instance then
        instance = CPanelUIEyeEntranceTips()
        instance._PrefabPath = PATH.UI_EyeEntranceTips
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Lab_Title = self:GetUIObject('Lab_Title')
    self._Lab_EntranceLimitLevel = self:GetUIObject('Lab_EntranceLimitLevel')
    self._Lab_EntranceLimitTitle = self:GetUIObject('Lab_EntranceLimitTitle')
    self._Lab_EntranceLimitEnter = self:GetUIObject('Lab_EntranceLimitEnter')
    self.Btn_Enter1 = self:GetUIObject('Btn_Enter1')
    self.Btn_Enter2 = self:GetUIObject('Btn_Enter2')
    
    
    self._Lab_EntranceRewardCount = self:GetUIObject('Lab_EntranceRewardCount')
    self._List_Gift = self:GetUIObject('List_Reward'):GetComponent(ClassType.GNewList)
    self._Btn_Team = CCommonBtn.new(self:GetUIObject('Btn_Team'), nil)
end

def.override("dynamic").OnData = function(self,data)  
    if data == nil then return end      
   
    self._ParentUI = data._ParentUI
    local dungeondata = CElementData.GetInstanceTemplate(data._Data.dungeonId)

    self._Dungeondata = data._Data
    if self._Dungeondata == nil or dungeondata == nil then return end
    self._Dungeondata.MinEnterLevel = dungeondata.MinEnterLevel
    GUI.SetText(self._Lab_Title, dungeondata.TextDisplayName)
    -- GUI.SetText(self._Lab_EntranceLimitLevel, StringTable.Get(12018).." "..dungeondata.MinEnterLevel)
    -- GUI.SetText(self._Lab_EntranceLimitTitle, StringTable.Get(12019).." "..dungeondata.MinRoleNum .. '~'.. dungeondata.MaxRoleNum)
    -- GUI.SetText(self._Lab_EntranceRewardCount, StringTable.Get(12020).." "..data._Data.remainCount)

    local levelStr = tostring(dungeondata.MinEnterLevel)
    if dungeondata.MinEnterLevel <= game._HostPlayer._InfoData._Level then
        levelStr = "<color=#FFFFFF>"..levelStr.."</color>"
    else
        levelStr = "<color=#FF0000>"..levelStr.."</color>"
    end

    if self._Dungeondata.hawkeyeType == 1 then
        GUI.SetText(self._Lab_EntranceLimitLevel, tostring(game._HostPlayer._InfoData._Level))
        self.Btn_Enter1:SetActive(true)
        self.Btn_Enter2:SetActive(false)
    else
        GUI.SetText(self._Lab_EntranceLimitLevel, levelStr)
        self.Btn_Enter1:SetActive(false)
        self.Btn_Enter2:SetActive(true)
    end
    
    GUI.SetText(self._Lab_EntranceLimitTitle, dungeondata.MinRoleNum .. '~'.. dungeondata.MaxRoleNum)

    --CElementData.GetTemplate("Hawkeye", dungeondata.CountGroupTid)
    GUI.SetText(self._Lab_EntranceLimitEnter, tostring(data._Data.challengeCount))
    
    
    local maxCount = CElementData.GetTemplate("CountGroup", dungeondata.CountGroupTid).MaxCount
    GUI.SetText(self._Lab_EntranceRewardCount, tostring(data._Data.remainCount .. '/' .. maxCount))
    -- 副本奖励列表
    self._Rewards = GUITools.GetRewardList(dungeondata.RewardId, false)  
    if self._List_Gift ~= nil then
        -- warn("self._RewardsData == ", #self._RewardsData)
        self._List_Gift:SetItemCount(#self._Rewards)
    end      

    self._Btn_Team:MakeGray( CTeamMan.Instance():InTeam() )
    
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_Reward' then
        -- 统一初始化奖励物品，模块的类必须有_RewardData
		local rewardsData = self._Rewards
		if rewardsData == nil then return end
		local reward = self._Rewards[index+1]
		if reward ~= nil then
            local frame_item_icon = GUITools.GetChild(item, 0)
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_item_icon, reward.Data.Id, 0)
            else
                IconTools.InitItemIconNew(frame_item_icon, reward.Data.Id)
            end
		end 
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_Reward' then
        -- 奖励列表
		local rewardData = self._Rewards[index + 1]
		if not rewardData.IsTokenMoney then
			CItemTipMan.ShowItemTips(rewardData.Data.Id, TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
        else
            local panelData = 
                {
                    _MoneyID = rewardData.Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = item ,
                }
                CItemTipMan.ShowMoneyTips(panelData)
		end
    end

end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Enter1' or id == 'Btn_Enter2' then
        if self._Dungeondata.remainCount > 0 and self._Dungeondata.challengeCount > 0 and self._Dungeondata.MinEnterLevel <= game._HostPlayer._InfoData._Level then
            game:StopAllAutoSystems()
            local CTransManage = require "Main.CTransManage"
            CTransManage.Instance():TransToRegionIsNeedBroken(self._Dungeondata.mapID, self._Dungeondata.regionId, false, nil, true)
            self._ParentUI:ClosePanel()
            game._GUIMan:CloseByScript(self)     
        elseif self._Dungeondata.remainCount == 0 or self._Dungeondata.challengeCount == 0 then
            game._GUIMan:ShowTipText(StringTable.Get(12037), false)
        elseif self._Dungeondata.MinEnterLevel > game._HostPlayer._InfoData._Level then
            game._GUIMan:ShowTipText(StringTable.Get(12038), false)
        end
    elseif id == 'Btn_Team' then
        if self._Dungeondata.remainCount > 0 and self._Dungeondata.challengeCount > 0 and self._Dungeondata.MinEnterLevel <= game._HostPlayer._InfoData._Level then
            if CTeamMan.Instance():InTeam() then
                game._GUIMan:ShowTipText(StringTable.Get(174), false)
            else
                --game._GUIMan:Open("CPanelUITeamCreate", {TargetId = self._Dungeondata.dungeonId})
                game._GUIMan:Open("CPanelUITeamCreate", { TargetMatchId = 49 })
                game._GUIMan:CloseByScript(self)
            end  
        elseif self._Dungeondata.remainCount == 0 or self._Dungeondata.challengeCount == 0 then
            game._GUIMan:ShowTipText(StringTable.Get(12037), false)
        elseif self._Dungeondata.MinEnterLevel > game._HostPlayer._InfoData._Level then
            game._GUIMan:ShowTipText(StringTable.Get(12038), false)
        end
        
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._Rewards = {}
    self._Dungeondata = {}
    self._ParentUI = {}
end

def.override().OnDestroy = function(self)
    if self._Btn_Team ~= nil then
        self._Btn_Team:Destroy()
        self._Btn_Team = nil
    end
    self._Lab_Title = nil
    self._Lab_EntranceLimitLevel = nil
    self._Lab_EntranceLimitTitle = nil
    self._Lab_EntranceLimitEnter = nil
    self._Lab_EntranceRewardCount = nil
    self._List_Gift = nil
end

CPanelUIEyeEntranceTips.Commit()
return CPanelUIEyeEntranceTips