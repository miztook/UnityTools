local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelUIWorldBossTips = Lplus.Extend(CPanelBase, 'CPanelUIWorldBossTips')
local CUIModel = require "GUI.CUIModel"
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelUIWorldBossTips.define
local MapBasicConfig = require "Data.MapBasicConfig"

def.field('userdata')._Lab_BossName = nil
def.field('userdata')._Lab_BossLevel = nil
def.field('userdata')._Lab_BossMark = nil
def.field('userdata')._List_Gift = nil
-- def.field('userdata')._Lab_BossState = nil
def.field('userdata')._Lab_BossLocation = nil
def.field('userdata')._Img_BossIcon = nil
def.field('userdata')._Lab_RecommendPower = nil
def.field('userdata')._Lab_RecommendPlayerNum = nil
def.field("table")._Rewards = BlankTable
-- def.field(CUIModel)._UIModel = nil
def.field('number')._Reason = 0
def.field('table')._WorldBossData = BlankTable
def.field("userdata")._Frame_OtherReward_1 = nil
def.field("userdata")._Img_OtherReward_1 = nil
def.field("userdata")._Lab_OtherReward_1 = nil
def.field("userdata")._Frame_OtherReward_2 = nil
def.field("userdata")._Img_OtherReward_2 = nil
def.field("userdata")._Lab_OtherReward_2 = nil
def.field('userdata')._Lab_CurScore = nil

local instance = nil
def.static('=>', CPanelUIWorldBossTips).Instance = function ()
	if not instance then
        instance = CPanelUIWorldBossTips()
        instance._PrefabPath = PATH.UI_WorldBossTips
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._Lab_BossName = self:GetUIObject('Lab_BossName')
    self._Lab_BossLevel = self:GetUIObject('Lab_BossLevel')
    self._Lab_BossMark = self:GetUIObject('Lab_BossDesc')
    self._Lab_BossLocation = self:GetUIObject('Lab_BossLocation')
    self._List_Gift = self:GetUIObject('List_Reward'):GetComponent(ClassType.GNewList)
    -- self._Lab_BossState = self:GetUIObject('Lab_BossState')
    self._Img_BossIcon = self:GetUIObject('Img_BossIcon')
    self._Lab_RecommendPower = self:GetUIObject('Lab_BossScore')
    self._Lab_RecommendPlayerNum = self:GetUIObject('Lab_BossNumber')
    self._Frame_OtherReward_1 = self:GetUIObject("Frame_OtherReward_1")
	self._Img_OtherReward_1 = self:GetUIObject("Img_OtherReward_1")
	self._Lab_OtherReward_1 = self:GetUIObject("Lab_OtherReward_1")
	self._Frame_OtherReward_2 = self:GetUIObject("Frame_OtherReward_2")
	self._Img_OtherReward_2 = self:GetUIObject("Img_OtherReward_2")
    self._Lab_OtherReward_2 = self:GetUIObject("Lab_OtherReward_2")
    self._Lab_CurScore = self:GetUIObject('Lab_CurScore')
    self._Reason = 0
end

def.override("dynamic").OnData = function(self,data)  
    if data == nil then return end      
    self._WorldBossData = data
    -- warn("bossid == ", self._WorldBossData._Data.Id)
    local WorldBossData = CElementData.GetTemplate("WorldBossConfig", self._WorldBossData._Data.Id)   
    if WorldBossData == nil then return end
    -- warn("WorldBossData.Name ==", WorldBossData.Name)
    local BossLevel = string.format(StringTable.Get(21508), WorldBossData.Level)
    GUI.SetText( self._Lab_BossName, WorldBossData.Name)
    GUI.SetText(self._Lab_BossLevel, BossLevel)
    GUI.SetText(self._Lab_BossMark, WorldBossData.Desc)
    GUI.SetText(self._Lab_RecommendPlayerNum, tostring(WorldBossData.RecommendPlayerNum))
    GUI.SetText(self._Lab_RecommendPower, tostring(WorldBossData.RecommendPower))

    local curScore = GUITools.FormatMoney(game._HostPlayer:GetHostFightScore())
    if game._HostPlayer:GetHostFightScore() > WorldBossData.RecommendPower then
        curScore = "<color=#FFFFFFFF>".. GUITools.FormatMoney(game._HostPlayer:GetHostFightScore()) .."</color>"
    end
    GUI.SetText(self._Lab_CurScore, tostring(curScore))
    --  warn("WorldBossData.SceneId == ", WorldBossData.SceneId)
    --如果所在区域中，显示区域名字，否则显示map名字
	if WorldBossData.SceneId ~= nil then
        -- warn("name == ", MapBasicConfig.GetMapAndRegionName(WorldBossData.SceneId, WorldBossData.RegionId))
        GUI.SetText(self._Lab_BossLocation, MapBasicConfig.GetMapAndRegionName(WorldBossData.SceneId, WorldBossData.RegionId))
	end

    local bossState = ""
    if data._IsDeath == nil then
        bossState = StringTable.Get(21006)
    else
        if data._IsDeath == false then
            bossState = StringTable.Get(21005)
        else
            bossState = StringTable.Get(21003)
        end
    end

    -- warn("bossState == ", bossState)
    -- GUI.SetText(self._Lab_BossState, bossState)
    GUITools.SetSprite(self._Img_BossIcon, WorldBossData.WorldBossTipsPath)
    -- Boss模型加载
-- 	local model_asset_path = WorldBossData.ModelAssetPath
--     if self._UIModel == nil then 
-- --        local cb = function()
-- --            if not self:IsShow() then 
-- --                self._UIModel:Destroy()
-- --                self._UIModel = nil
-- --                return 
-- --            end
-- --            self._UIModel:PlayAnimation(EnumDef.CLIP.COMMON_STAND) 
-- --        end
--         self._UIModel = CUIModel.new(model_asset_path, self._Img_Boss, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI, nil)
--         --self._UIModel:AddLoadedCallback(cb)
--     else
--         self._UIModel:Update(model_asset_path)
--     end
--     --self._UIModel:SetDefaultLookAtMonster()

--     self._UIModel:AddLoadedCallback(function() 
--         self._UIModel:SetModelParam(self._PrefabPath, model_asset_path)
--         end)

    -- 世界boss奖励列表
    local rewardList = GUITools.GetRewardList(WorldBossData.RewardId, true)
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
        -- warn("self._RewardsData == ", #self._RewardsData)
        self._List_Gift:SetItemCount(#self._Rewards)
    end  
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

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == 'List_Reward' then
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
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == 'List_Reward' then
        -- 奖励列表
		local rewardsData = self._Rewards
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
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_FindBoss' then
        -- warn("Onclick self._WorldBossData._IsDeath == ", self._WorldBossData._IsDeath)
        -- 切换分线到1线
        local curWorldInfo = game._CurWorld._WorldInfo
        if curWorldInfo.CurMapLineId ~= 1 then
            -- warn("ttttttttttttttttttttttttt curWorldInfo.CurMapLineId ==", curWorldInfo.CurMapLineId)            
			local C2SMapLineChange = require "PB.net".C2SMapLineChange
            local protocol = C2SMapLineChange()
            protocol.MapLine = 1
            local PBHelper = require "Network.PBHelper"
            PBHelper.Send(protocol)
        end
        
        if self._WorldBossData._IsDeath == false then
            -- 停止任务自动化
            local CQuestAutoMan = require"Quest.CQuestAutoMan"
            CQuestAutoMan.Instance():Stop()
            local CAutoFightMan = require "AutoFight.CAutoFightMan"
            CAutoFightMan.Instance():Pause(_G.PauseMask.TransBroken)

            local function DoCallback()
                CAutoFightMan.Instance():Restart(_G.PauseMask.TransBroken)
                -- warn("Find WorldBoss Callback !!!")
            end
            local WorldBossData = CElementData.GetTemplate("WorldBossConfig", self._WorldBossData._Data.Id)  
            --地图没有限制，直接使用
            if WorldBossData.SceneId == nil or WorldBossData.SceneId == 0 then
                DoCallback()
            else
                local CTransManage = require "Main.CTransManage"                
                --有区域限制
                if WorldBossData.RegionId ~= nil and WorldBossData.RegionId ~= 0 then
                    CTransManage.Instance():TransToRegionIsNeedBroken(WorldBossData.SceneId, WorldBossData.RegionId, true, DoCallback, true)
                else
                --只能小范围使用，一般已点的半径内
                    if WorldBossData.RegionId ~= nil and WorldBossData.RegionId ~= 0 then
                        local pos = require "Data.MapBasicConfig".GetRegionPos(WorldBossData.SceneId, WorldBossData.RegionId)
                        if pos == nil then
                            warn("CPanelWorldBoss: Can't find RegionData in MapBasicConfig")
                        return end
                        CTransManage.Instance():StartMoveByMapIDAndPos(WorldBossData.SceneId, pos, DoCallback, false, true)
                    else
                        DoCallback()
                    end
                end
            end
            local CPanelMap = require "GUI.CPanelMap"
            if CPanelMap.Instance():IsShow() then
                game._GUIMan:Close("CPanelMap")		
            end
            game._GUIMan:Close("CPanelUIWorldBossTips")  
        else
            game._GUIMan: ShowTipText(StringTable.Get(21007),false)
        end
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
	self._Lab_BossName = nil
    self._Lab_BossLevel = nil
    self._Lab_BossMark = nil
    self._List_Gift = nil
    self._Lab_BossLocation = nil
    self._Img_BossIcon = nil
    self._Lab_RecommendPower = nil
    self._Lab_RecommendPlayerNum = nil

    self._Reason = 0
    self._WorldBossData = {}
    self._Frame_OtherReward_1 = nil
    self._Img_OtherReward_1 = nil
    self._Lab_OtherReward_1 = nil
    self._Frame_OtherReward_2 = nil
    self._Img_OtherReward_2 = nil
    self._Lab_OtherReward_2 = nil
    self._Lab_CurScore = nil
    self._Rewards = {}

end

CPanelUIWorldBossTips.Commit()
return CPanelUIWorldBossTips