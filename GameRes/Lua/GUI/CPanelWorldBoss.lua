local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelWorldBoss = Lplus.Extend(CPanelBase, 'CPanelWorldBoss')
local CUIModel = require "GUI.CUIModel"
local CGame = Lplus.ForwardDeclare("CGame")
local MapBasicConfig = require "Data.MapBasicConfig"
local OperatorType = require "PB.net".S2CWorldBossState.OperatorType
local CMallUtility = require "Mall.CMallUtility"

local def = CPanelWorldBoss.define
def.field('userdata')._List_BossView = nil
def.field('userdata')._List_EliteBossView = nil
def.field('userdata')._List_Boss = nil
def.field('userdata')._List_EliteBoss = nil
def.field('userdata')._Lab_BossName = nil
def.field('userdata')._Lab_BossLevel = nil
def.field('userdata')._Lab_BossMark = nil
def.field('userdata')._Lab_BossLocation = nil
def.field('userdata')._Lab_RecommendPower = nil
def.field('userdata')._Lab_RecommendPlayerNum = nil
def.field('userdata')._List_Gift = nil
-- def.field('userdata')._Lab_BossState = nil
def.field('userdata')._Img_BossIcon = nil
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field('userdata')._Lab_CurScore = nil
def.field('userdata')._Img_BossUpdate = nil
def.field('userdata')._FrameTopTabs = nil
def.field("userdata")._Btn_FindBoss = nil
def.field("userdata")._List_Buff = nil		--状态List
def.field("userdata")._Frame_BuffTips = nil
def.field("userdata")._Lab_TipsTitle = nil 	--状态名称
def.field("userdata")._Img_BuffIcon = nil
def.field("userdata")._Lab_TipsDesc = nil 	--状态描述
def.field("userdata")._Lab_BuffTitle = nil
def.field("userdata")._Lab_RemainingTimes = nil
def.field("table")._Rewards = BlankTable
-- def.field(CUIModel)._UIModel = nil
def.field("table")._Table_WorldBoss = BlankTable
def.field("number")._CurSelectBossIndex = 1
def.field("number")._CurType = 1
def.field("table")._Table_EliteBoss = BlankTable
def.field("table")._BossAffixDataList = BlankTable --精英Boss词缀
def.field("userdata")._Btn_RewardList = nil

def.field("table")._BossTimers = BlankTable

local instance = nil
def.static('=>', CPanelWorldBoss).Instance = function ()
	if not instance then
        instance = CPanelWorldBoss()
        instance._PrefabPath = PATH.UI_WorldBoss
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance:SetupSortingParam()
	end
	return instance
end

-- 面板类型
local EPageType =
{
    EliteBoss = 1,          -- 精英boss
    WorldBoss = 2,          -- 世界boss
}

def.override().OnCreate = function(self)
    self._List_BossView = self:GetUIObject('List_BossView')
    self._List_EliteBossView = self:GetUIObject('List_EliteBossView')
    self._List_Boss = self:GetUIObject('List_Boss'):GetComponent(ClassType.GNewList)
    self._List_EliteBoss = self:GetUIObject('List_EliteBoss'):GetComponent(ClassType.GNewList)
    self._Lab_BossName = self:GetUIObject('Lab_BossName')
    self._Lab_BossLevel = self:GetUIObject('Lab_BossLevel')
    self._Lab_BossMark = self:GetUIObject('Lab_BossDesc')
    self._Lab_BossLocation = self:GetUIObject('Lab_BossLocation')
    self._Lab_RecommendPower = self:GetUIObject('Lab_BossScore')
    self._Lab_RecommendPlayerNum = self:GetUIObject('Lab_BossNumber')
    self._List_Gift = self:GetUIObject('List_Reward'):GetComponent(ClassType.GNewList)
    -- self._Lab_BossState = self:GetUIObject('Lab_BossState')
    self._Img_BossIcon = self:GetUIObject('Img_BossIcon')
    self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
    self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
    self._Lab_CurScore = self:GetUIObject('Lab_CurScore')
    self._Img_BossUpdate = self:GetUIObject("Img_BossUpdate")
    self._FrameTopTabs = self:GetUIObject("Frame_TopTabs")
    self._Lab_RemainingTimes = self:GetUIObject("Lab_RemainingTimes")
    self._Frame_BuffTips = self:GetUIObject("Frame_BuffTips")
    self._Lab_TipsTitle = self:GetUIObject("Lab_TipsTitle")
    self._Img_BuffIcon = self:GetUIObject("Img_BuffIcon")
    self._Lab_TipsDesc = self:GetUIObject("Lab_TipsDesc")
    self._Lab_BuffTitle = self:GetUIObject("Lab_BuffTitle")
    self._Btn_FindBoss = self:GetUIObject("Btn_FindBoss")
    self._Btn_RewardList = self:GetUIObject("Btn_RewardList")
    self._List_Buff = self:GetUIObject("List_Buff"):GetComponent(ClassType.GNewList)
    local do_tween_player = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    if do_tween_player ~= nil then
        do_tween_player:Restart("fudong")
        do_tween_player:Restart("UI_OPEN")
    end
    self._Frame_BuffTips:SetActive(true)
    GUITools.SetUIActive(self._Frame_BuffTips, false)
    self._Btn_RewardList:SetActive(false)
end

def.override("dynamic").OnData = function(self,data)  
    self._HelpUrlType = HelpPageUrlType.WorldBoss
    self._Table_WorldBoss = game._CWorldBossMan:GetAllWorldBossContents()
    self._Table_EliteBoss = game._CWorldBossMan:GetAllEliteBossContents()
    game._CWorldBossMan:SendC2SWorldBossNextOpenTime()
    -- warn("----lidaming---- self._Table_WorldBoss == ", #self._Table_WorldBoss)
    if self._List_Boss ~= nil then
        if data == nil or data == "" then
            self._List_BossView:SetActive(false)
            self._Btn_RewardList:SetActive(false)
            self._List_EliteBossView:SetActive(true)
            self._CurSelectBossIndex = 1
            self._CurType = EPageType.EliteBoss
            self._List_EliteBoss:SetItemCount(#self._Table_EliteBoss) 
        else
            local BossIndex = 1
            if tonumber(data) == EPageType.WorldBoss or tostring(data) == "WorldBoss" then
                self._List_BossView:SetActive(true)
                self._Btn_RewardList:SetActive(true)
                self._List_EliteBossView:SetActive(false)
                self._CurType = EPageType.WorldBoss
                if self._BossTimers ~= nil then
                    self:RemoveAllBossTimers()
                else
                    self._BossTimers = {}
                end
                self._List_Boss:SetItemCount(#self._Table_WorldBoss) 
            elseif tonumber(data) == EPageType.EliteBoss or tostring(data) == "EliteBoss" then
                self._List_BossView:SetActive(false)
                self._Btn_RewardList:SetActive(false)
                self._List_EliteBossView:SetActive(true)
                self._CurType = EPageType.EliteBoss
                self._List_EliteBoss:SetItemCount(#self._Table_EliteBoss) 
            else
                for i,v in pairs(self._Table_WorldBoss) do                
                    if v._Data.WorldBossTid == tonumber(data) then
                        BossIndex = i
                        self._CurType = EPageType.WorldBoss
                        break
                    end
                end
                for i,v in pairs(self._Table_EliteBoss) do                
                    if v._Data.EliteBossTid == tonumber(data) then
                        BossIndex = i
                        self._CurType = EPageType.EliteBoss
                        break
                    end
                end
                -- warn("==============>>>", data, self._CurType, BossIndex, #self._Table_WorldBoss, #self._Table_EliteBoss)
                if self._CurType == EPageType.WorldBoss then
                    self._List_BossView:SetActive(true)
                    self._Btn_RewardList:SetActive(true)
                    self._List_EliteBossView:SetActive(false)
                    if self._BossTimers ~= nil then
                        self:RemoveAllBossTimers()
                    else
                        self._BossTimers = {}
                    end
                    self._List_Boss:SetItemCount(#self._Table_WorldBoss) 
                elseif self._CurType == EPageType.EliteBoss then       
                    self._List_BossView:SetActive(false)
                    self._Btn_RewardList:SetActive(false)
                    self._List_EliteBossView:SetActive(true)     
                    self._List_EliteBoss:SetItemCount(#self._Table_EliteBoss) 
                    
                end
            end
            self._CurSelectBossIndex = tonumber(BossIndex)
        end
    end  
    GUI.SetGroupToggleOn(self._FrameTopTabs, self._CurType + 1)
    self:OnCurrentSelectWorldBoss(self._CurType, self._CurSelectBossIndex)
    self:UpdateBossToggleRedPoint()
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    GUITools.SetUIActive(self._Frame_BuffTips, false)
    if id == "Rdo_1" then
        self._List_BossView:SetActive(false)
        self._Btn_RewardList:SetActive(false)
        self._List_EliteBossView:SetActive(true)
        self._CurType = EPageType.EliteBoss
        self._CurSelectBossIndex = 1
        self._List_EliteBoss:SetItemCount(#self._Table_EliteBoss) 
        self:OnCurrentSelectWorldBoss(self._CurType, self._CurSelectBossIndex)
    elseif id == "Rdo_2" then
        self._List_BossView:SetActive(true)
        self._Btn_RewardList:SetActive(true)
        self._List_EliteBossView:SetActive(false)
        self._CurType = EPageType.WorldBoss
        self._CurSelectBossIndex = 1
        if self._BossTimers ~= nil then
            self:RemoveAllBossTimers()
        else
            self._BossTimers = {}
        end
        self._List_Boss:SetItemCount(#self._Table_WorldBoss) 
        self:OnCurrentSelectWorldBoss(self._CurType, self._CurSelectBossIndex)
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_Boss' or id == 'List_EliteBoss' then
        local nType = index + 1
        local Img_BossBg = GUITools.GetChild(item , 0)
        -- local Img_BossIcon = GUITools.GetChild(item , 1) -- boss列表中的图标
        local Lab_BossName = GUITools.GetChild(item , 2)
        local Lab_BossState = GUITools.GetChild(item , 4)
        local Img_BossStateBg = GUITools.GetChild(item , 5)
        -- local SelectImg_Boss = GUITools.GetChild(item , 3)
        local Lab_BossLevel = GUITools.GetChild(item , 6)
        local Lab_SelectBossName = GUITools.GetChild(item , 7)
        local Lab_SelectBossLevel = GUITools.GetChild(item , 8)
        -- SelectImg_Boss:SetActive(false)
        Img_BossStateBg:SetActive(false)
        Lab_BossName:SetActive(true)

        local temData = nil
        if self._CurType == EPageType.WorldBoss then
            temData = self._Table_WorldBoss[index + 1]
            GUI.SetText(Lab_BossName , temData._Data.Name)   
            -- warn("==========>>>", temData._Data.Name, temData._Isopen , temData._IsDeath, temData._LineId)  
            local BossLevel = string.format(StringTable.Get(21500), temData._Data.Level)
            GUI.SetText(Lab_BossLevel, BossLevel)
            GUI.SetText(Lab_SelectBossName , temData._Data.Name) 
            GUI.SetText(Lab_SelectBossLevel , BossLevel) 
            GameUtil.MakeImageGray(Img_BossBg, false)   
            if not temData._Isopen or temData._IsDeath then
                Img_BossStateBg:SetActive(true)
                -- GUI.SetText(Lab_BossState , StringTable.Get(21014))   
                GameUtil.MakeImageGray(Img_BossBg, true) 
                
                local callback = function()
                    local BossNextOpenTime = (game._CWorldBossMan:GetWorldBossNextOpenTime() - GameUtil.GetServerTime()/1000)
                    local next_refresh_time = BossNextOpenTime or 0
                    local time_str = GUITools.FormatTimeFromSecondsToZero(true, BossNextOpenTime)
                    GUI.SetText(Lab_BossState, time_str)
                    -- if next_refresh_time > 0 then
                    --     local remain_time = (BossNextOpenTime - GameUtil.GetServerTime())/1000
                    --     if remain_time <= 0 then
                    --         Img_BossStateBg:SetActive(false)
                    --     end
                    -- end
                end
                if self._BossTimers[temData._Data.Id] ~= nil and self._BossTimers[temData._Data.Id] ~= 0 then
                    _G.RemoveGlobalTimer(self._BossTimers[temData._Data.Id])
                    self._BossTimers[temData._Data.Id] = 0
                end
                self._BossTimers[temData._Data.Id] = _G.AddGlobalTimer(1, false, callback)
            end

        elseif self._CurType == EPageType.EliteBoss then            
            temData = self._Table_EliteBoss[index + 1]
            -- warn("lidaming OnInitItem", temData._Data.Name)
            GUI.SetText(Lab_BossName , temData._Data.Name)     
            local BossLevel = string.format(StringTable.Get(21500), temData._Data.Level)
            GUI.SetText(Lab_BossLevel, BossLevel)
            GUI.SetText(Lab_SelectBossName , temData._Data.Name) 
            GUI.SetText(Lab_SelectBossLevel , BossLevel) 
            if temData._BossLeftDropCount > 0 then
                Img_BossStateBg:SetActive(false)
                GameUtil.MakeImageGray(Img_BossBg, false) 
            else
                Img_BossStateBg:SetActive(true)
                GUI.SetText(Lab_BossState , StringTable.Get(21014))
                GameUtil.MakeImageGray(Img_BossBg, true) 

            end
            
        end
        
    elseif id == 'List_Reward' then        
        -- 统一初始化奖励物品，模块的类必须有_RewardData
		local rewardsData = self._Rewards
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
    elseif string.find(id, "List_Buff") then
        local talentData = self._BossAffixDataList[index + 1]
        if talentData == nil then return end
        local img_icon = GUITools.GetChild(item, 2)
        GUITools.SetIcon(img_icon, talentData._Icon)
        
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    GUITools.SetUIActive(self._Frame_BuffTips, false)
    if id == 'List_Boss' or id == 'List_EliteBoss' then
        self:OnCurrentSelectWorldBoss(self._CurType, index + 1)   
    elseif id == 'List_Reward' then
        -- 奖励列表
		local rewardsData = self._Rewards
		if rewardsData == nil then
			warn("Rewards data is null on select item in WorldBoss")
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
    elseif string.find(id, "List_Buff") then
        local talentData = self._BossAffixDataList[index + 1]
        if talentData == nil then return end

        GameUtil.SetTipsPosition(item, self._Frame_BuffTips)
        GUI.SetText(self._Lab_TipsTitle, talentData._Name)
        GUI.SetText(self._Lab_TipsDesc, talentData._Describe)
        GUITools.SetIcon(self._Img_BuffIcon, talentData._Icon)
        GUITools.SetUIActive(self._Frame_BuffTips, true)
    end

end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    GUITools.SetUIActive(self._Frame_BuffTips, false)
    if id == 'Btn_Back' then
        game._GUIMan:Close("CPanelWorldBoss")
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_BattleRule" then
        -- 暂时没有介绍数据， 放的远征系统介绍。。。。lidaming
        if self._CurType == EPageType.WorldBoss then
            game._GUIMan:Open("CPanelRuleDescription", 12)
        elseif self._CurType == EPageType.EliteBoss then            
            game._GUIMan:Open("CPanelRuleDescription", 11)
        end
    elseif id == 'Btn_FindBoss' then
        -- warn("lidaming onclick _CurSelectBossIndex= ", self._CurSelectBossIndex)
        if self._CurType == EPageType.WorldBoss and self._Table_WorldBoss[self._CurSelectBossIndex]._Isopen == true and self._Table_WorldBoss[self._CurSelectBossIndex]._IsDeath == false then
            -- 世界boss强制切换分线到1线
            local curWorldInfo = game._CurWorld._WorldInfo
            local IsDeathByCurLine = game._CWorldBossMan:GetWorldBossByLineAndID(curWorldInfo.CurMapLineId, self._Table_WorldBoss[self._CurSelectBossIndex]._BossID)
            if IsDeathByCurLine then
                local LineID = game._CWorldBossMan:GetLineByCurLineAndID(curWorldInfo.CurMapLineId, self._Table_WorldBoss[self._CurSelectBossIndex]._BossID)
                if LineID > 0 then
                    local C2SMapLineChange = require "PB.net".C2SMapLineChange
                    local protocol = C2SMapLineChange()
                    protocol.MapLine = LineID
                    local PBHelper = require "Network.PBHelper"
                    PBHelper.Send(protocol)
                end
            end
            
            -- 停止任务自动化
            local CQuestAutoMan = require"Quest.CQuestAutoMan"
            CQuestAutoMan.Instance():Stop()
            local CAutoFightMan = require "AutoFight.CAutoFightMan"
            CAutoFightMan.Instance():Stop()
            -- CAutoFightMan.Instance():Pause(_G.PauseMask.TransBroken)

            local function DoCallback()
                CAutoFightMan.Instance():Restart(_G.PauseMask.TransBroken)
                -- warn("Find WorldBoss Callback !!!")
            end
            local template = self._Table_WorldBoss[self._CurSelectBossIndex]._Data
            --地图没有限制，直接使用
            if template.SceneId == nil or template.SceneId == 0 then
                DoCallback()
            else
                local CTransManage = require "Main.CTransManage"
                
                --有区域限制
                if template.RegionId ~= nil and template.RegionId ~= 0 then
                    CTransManage.Instance():TransToRegionIsNeedBroken(template.SceneId, template.RegionId, true, DoCallback, true)
                else
                --只能小范围使用，一般已点的半径内
                    if template.RegionId ~= nil and template.RegionId ~= 0 then
                        local pos = require "Data.MapBasicConfig".GetRegionPos(template.SceneId,template.RegionId)
                        if pos == nil then
                            warn("CPanelWorldBoss: Can't find RegionData in MapBasicConfig")
                        return end
                        CTransManage.Instance():StartMoveByMapIDAndPos(template.SceneId,pos ,DoCallback,false, true)
                    else
                        DoCallback()
                    end
                end
            end
            game._GUIMan:Close("CPanelWorldBoss")
            game._GUIMan:CloseSubPanelLayer()
        elseif self._CurType == EPageType.EliteBoss then   --and not self._Table_EliteBoss[self._CurSelectBossIndex]._IsDeath 
            local CQuestAutoMan = require"Quest.CQuestAutoMan"
            CQuestAutoMan.Instance():Stop()
            local CAutoFightMan = require "AutoFight.CAutoFightMan"
            CAutoFightMan.Instance():Stop()
            -- CAutoFightMan.Instance():Pause(_G.PauseMask.TransBroken)

            local function DoCallback()
                CAutoFightMan.Instance():Restart(_G.PauseMask.TransBroken)
                -- warn("Find WorldBoss Callback !!!")
            end
            local template = self._Table_EliteBoss[self._CurSelectBossIndex]._Data
            --地图没有限制，直接使用
            if template.SceneId == nil or template.SceneId == 0 then
                DoCallback()
            else
                local CTransManage = require "Main.CTransManage"
                
                --有区域限制
                if template.RegionId ~= nil and template.RegionId ~= 0 then
                    CTransManage.Instance():TransToRegionIsNeedBroken(template.SceneId, template.RegionId, true, DoCallback, true)
                else
                --只能小范围使用，一般已点的半径内
                    if template.RegionId ~= nil and template.RegionId ~= 0 then
                        local pos = require "Data.MapBasicConfig".GetRegionPos(template.SceneId,template.RegionId)
                        if pos == nil then
                            warn("CPanelWorldBoss: Can't find RegionData in MapBasicConfig")
                        return end
                        CTransManage.Instance():StartMoveByMapIDAndPos(template.SceneId,pos ,DoCallback,false, true)
                    else
                        DoCallback()
                    end
                end
            end
            game._GUIMan:Close("CPanelWorldBoss")
            game._GUIMan:CloseSubPanelLayer()
        else
            game._GUIMan: ShowTipText(StringTable.Get(21007),false) 
        end
    elseif id == 'Btn_RewardList' then
        game._GUIMan:Open("CPanelUIInquireReward", self._Table_WorldBoss[self._CurSelectBossIndex]._Data.Id) 
    end
end

def.override("userdata").OnPointerClick = function(self, target)
	if target.name ~= "Frame_BuffTips" then
		GUITools.SetUIActive(self._Frame_BuffTips, false)
	end
end

--世界boss列表选中状态
def.method("number", "number").OnCurrentSelectWorldBoss = function(self, bossType, bossIndex)
    self._CurSelectBossIndex = bossIndex
    self:UpdateBossToggleRedPoint()
    if self._List_Boss ~= nil then
        if self._CurType == EPageType.WorldBoss then
            self._List_Boss:SetSelection(self._CurSelectBossIndex - 1)
        elseif self._CurType == EPageType.EliteBoss then 
            self._List_EliteBoss:SetSelection(self._CurSelectBossIndex - 1)    
        end

        
        -- self._List_Boss:ScrollToStep(self._CurSelectBossIndex - 1) 
    end
    local temData = nil
    if bossType == EPageType.WorldBoss then
        temData = self._Table_WorldBoss[bossIndex]
        game._CWorldBossMan._WorldBossRedPointmark = false
        self._Img_BossUpdate:SetActive(true)
        local bossState = ""
        --warn("1111111 temData._Isopen == ", temData._Data.Id , temData._Isopen)
        if temData._Isopen == false then
            bossState = StringTable.Get(21006)
            GUITools.SetBtnGray(self._Btn_FindBoss, true)
        elseif temData._Isopen == true then
            if temData._IsDeath == true then
                bossState = StringTable.Get(21003)
                GUITools.SetBtnGray(self._Btn_FindBoss, true)
            else
                bossState = StringTable.Get(21005)
                GUITools.SetBtnGray(self._Btn_FindBoss, false)
            end
        end
        -- warn("lidaming ----->>> bossState == ", bossState, temData._Data.WorldBossPath)
        -- GUI.SetText(self._Lab_BossState, bossState)
        self._Lab_BossMark:SetActive(true)
        self._Lab_BuffTitle:SetActive(false)
        GUI.SetText(self._Lab_BossMark, temData._Data.Desc)
        GUITools.SetSprite(self._Img_BossIcon, temData._Data.WorldBossPath)
        GUI.SetText(self._Lab_RemainingTimes, tostring(game._CWorldBossMan:GetWorldBossDropCount()))
    elseif bossType == EPageType.EliteBoss then
        temData = self._Table_EliteBoss[bossIndex]
        self._Img_BossUpdate:SetActive(false)
        self._Lab_BossMark:SetActive(false)
        self._Lab_BuffTitle:SetActive(true)
        GUITools.SetBtnGray(self._Btn_FindBoss, false)
        -- 精英boss词缀列表
        self._BossAffixDataList = {}
        local TalentGroupTmp = CElementData.GetTemplate("TalentGroup", temData._Data.TalentGroupId)
        for _, k in ipairs(TalentGroupTmp.TalentItems) do
            local talentTemplate = CElementData.GetTemplate("Talent", k.TalentId)
            if talentTemplate ~= nil then
                local temp = 
                {
                    _TID = k.TalentId,
                    _Name =  talentTemplate.Name,
                    _Icon = talentTemplate.Icon,
                    _Describe = talentTemplate.TalentDescribtion,
                }
                table.insert(self._BossAffixDataList, temp)
            end
        end

        -- 初始化精英boss Buff
        if #self._BossAffixDataList > 0 then
            self._List_Buff:SetItemCount(#self._BossAffixDataList)
        end

        GUITools.SetSprite(self._Img_BossIcon, temData._Data.EliteBossPath)
    end
    self:UpdateBossToggleRedPoint()
    local BossLevel = string.format(StringTable.Get(21508), temData._Data.Level)
    GUI.SetText( self._Lab_BossName, temData._Data.Name)
    GUI.SetText(self._Lab_BossLevel, BossLevel)
    
    GUI.SetText(self._Lab_RecommendPlayerNum, tostring(temData._Data.RecommendPlayerNum))
    GUI.SetText(self._Lab_RecommendPower, GUITools.FormatNumber(temData._Data.RecommendPower, false, 7))
    local curScore = GUITools.FormatMoney(game._HostPlayer:GetHostFightScore())
    if game._HostPlayer:GetHostFightScore() > temData._Data.RecommendPower then
        curScore = "<color=#5CBE37FF>".. GUITools.FormatMoney(game._HostPlayer:GetHostFightScore()) .."</color>"
    else
        curScore = "<color=#F70000FF>".. GUITools.FormatMoney(game._HostPlayer:GetHostFightScore()) .."</color>"
    end
    GUI.SetText(self._Lab_CurScore, tostring(curScore))
    --如果所在区域中，显示区域名字，否则显示map名字
	if temData._Data.SceneId ~= nil then
        GUI.SetText(self._Lab_BossLocation, MapBasicConfig.GetMapAndRegionName(temData._Data.SceneId, temData._Data.RegionId))
	end
    

    -- 世界boss奖励列表
    local rewardList = GUITools.GetRewardList(temData._Data.RewardId, true)
    self._Rewards = {}
    local moneyRewardList = {}
    for _, v in ipairs(rewardList) do
        if v.IsTokenMoney then
            table.insert(moneyRewardList, v.Data)
        else
            table.insert(self._Rewards, v)
        end
    end
    self:SetMoneyRewards(moneyRewardList) -- 设置货币奖励
    if self._List_Gift ~= nil then
        self._List_Gift:SetItemCount(#self._Rewards)
    end
end


-- 刷新世界boss界面Toggle红点
def.method().UpdateBossToggleRedPoint = function(self)    
    self._FrameTopTabs:FindChild("Rdo_1/Img_RedPoint"):SetActive(game._CWorldBossMan:GetEliteBossRedPointState())    --精英boss红点
    local state = false
    if game._CWorldBossMan:GetWorldBossRedPointState() and game._CWorldBossMan._WorldBossRedPointmark then
        state = true
    else
        state = false
    end
    -- warn("state ===>>", state, game._CWorldBossMan:GetWorldBossRedPointState())
    self._FrameTopTabs:FindChild("Rdo_2/Img_RedPoint"):SetActive(state)        -- 世界boss红点

    local mainBossRedPoint = false
    if game._CWorldBossMan:GetEliteBossRedPointState() or state then
        mainBossRedPoint = true
    end
    local CPanelUIBuffEnter = require "GUI.CPanelUIBuffEnter"
	local img_RedPoint = CPanelUIBuffEnter.Instance():GetUIObject("Frame_ToolBar"):FindChild("Btn_WorldBoss/Img_Icon/Img_RedPoint")
	if img_RedPoint == nil then return end
    img_RedPoint:SetActive(mainBossRedPoint)

end

-- 设置货币奖励
-- @param rewardsData 结构如下
--        Id:货币ID
--        Count:货币数量
def.method("table").SetMoneyRewards = function (self, rewardsData)
	local enable = false
	if rewardsData ~= nil and rewardsData[1] ~= nil then
		enable = true
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_1, rewardsData[1].Id)
		GUI.SetText(self._Lab_OtherReward_1, tostring(rewardsData[1].Count))
	end
	GUITools.SetUIActive(self._Frame_OtherReward_1, enable)

	enable = false
	if rewardsData ~= nil and rewardsData[2] ~= nil then
		enable = true
		GUITools.SetTokenMoneyIcon(self._Img_OtherReward_2, rewardsData[2].Id)
		GUI.SetText(self._Lab_OtherReward_2, tostring(rewardsData[2].Count))
	end
	GUITools.SetUIActive(self._Frame_OtherReward_2, enable)
end

def.method().RemoveAllBossTimers = function(self)
    if self._BossTimers == nil then return end
    for k,v in pairs(self._BossTimers) do
        if v ~= nil then
           _G.RemoveGlobalTimer(v)
        end
    end
    self._BossTimers = {}
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:RemoveAllBossTimers()
end

def.override().OnDestroy = function(self)
	self._List_Boss = nil
    self._Lab_BossName = nil
    self._Lab_BossLevel = nil
    self._Lab_BossMark = nil
    self._Lab_BossLocation = nil
    self._Lab_RecommendPower = nil
    self._Lab_RecommendPlayerNum = nil
    self._List_Gift = nil
    -- self._Lab_BossState = nil
    self._Img_BossIcon = nil
    self._Frame_OtherReward_1 = nil
    self._Img_OtherReward_1 = nil
    self._Lab_OtherReward_1 = nil
    self._Frame_OtherReward_2 = nil
    self._Img_OtherReward_2 = nil
    self._Lab_OtherReward_2 = nil
    self._Lab_CurScore = nil
    self._Rewards = {}
    self._Table_WorldBoss = {}
    self._CurSelectBossIndex = 0
    self._CurType = 1
    self._Table_EliteBoss = {}
    self._Img_BossUpdate = nil
    self._FrameTopTabs = nil
    self._BossAffixDataList = {}
    self._Btn_FindBoss = nil
	self._List_Buff = nil
    self._Frame_BuffTips = nil
	self._Lab_TipsTitle = nil
	self._Img_BuffIcon = nil
    self._Lab_TipsDesc = nil
    self._Lab_BuffTitle = nil
    self._Lab_RemainingTimes = nil
    self:RemoveAllBossTimers()
end

CPanelWorldBoss.Commit()
return CPanelWorldBoss