local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local QuestDef = require "Quest.QuestDef"
local CQuestModel = require "Quest.CQuestModel"
local CNPCServiceHdl = require "ObjHdl.CNPCServiceHdl"
local CQuestNavigation = require"Quest.CQuestNavigation"
local CTeamMan = require "Team.CTeamMan"
local MapBasicConfig = require "Data.MapBasicConfig"
local CTransManage = require "Main.CTransManage"
local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = Lplus.ForwardDeclare("CQuest")
local CQuestAutoMan = require"Quest.CQuestAutoMan"                  
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CDungeonAutoMan = require"Dungeon.CDungeonAutoMan"
local CPanelMap = require "GUI.CPanelMap"
local CCommonBtn = require "GUI.CCommonBtn"

local CPanelUIFrontLine = Lplus.Extend(CPanelBase, 'CPanelUIFrontLine')
local def = CPanelUIFrontLine.define

 
def.field('userdata')._List_QuestMenu = nil                   --任务描述列表
--def.field('userdata')._Lab_RewardTips = nil
def.field('userdata')._List_ElementsReward = nil                  --任务奖励列表
def.field('userdata')._Lab_LvValues = nil                 --进入等级
def.field('userdata')._Lab_TimeLvValues = nil             --进入时间
def.field('userdata')._PorgressFillImg = nil             --进度条
def.field('userdata')._Lab_ProNumber = nil                --总进度
def.field('userdata')._Frame_Time = nil                --活动倒计时
def.field('userdata')._Frame_Open = nil                --活动开启    
def.field('userdata')._Lab_OpenLvValues = nil             --活动开启提示  
          
def.field(CCommonBtn)._Btn_Jion = nil                  --进入按钮

def.field('table')._Current_Data = nil

local instance = nil
def.static('=>', CPanelUIFrontLine).Instance = function ()
    if not instance then
        instance = CPanelUIFrontLine()
        instance._PrefabPath = PATH.UI_FrontLine
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._List_QuestMenu = self:GetUIObject("List_QuestMenu"):GetComponent(ClassType.GNewListLoop)
    self._List_ElementsReward = self:GetUIObject("List_ElementsReward"):GetComponent(ClassType.GNewListLoop)
    self._Lab_LvValues = self:GetUIObject("Lab_LvValues")
    self._Lab_TimeLvValues = self:GetUIObject("Lab_TimeLvValues")
    --self._Lab_RewardTips = self:GetUIObject("Lab_RewardTips")
    self._PorgressFillImg = self:GetUIObject("PorgressFillImg"):GetComponent(ClassType.Image)
    self._Lab_ProNumber = self:GetUIObject("Lab_ProNumber")
    self._Frame_Time = self:GetUIObject("Frame_Time")
    self._Frame_Open = self:GetUIObject("Frame_Open")
    self._Lab_OpenLvValues = self:GetUIObject("Lab_OpenLvValues")
    self._Btn_Jion = CCommonBtn.new(self:GetUIObject("Btn_Jion"), nil)

end

local rewards = nil
def.override("dynamic").OnData = function(self,data)
    CPanelBase.OnData(self,data)
    
    if data == nil then
        warn("FrontLine data is nil")
    end

    self._Current_Data = data

--[[    local FrontLineTemplate = CElementData.GetTemplate("FrontLine", data.tid)
    local GroupTemplate = CElementData.GetTemplate("QuestGroup", 118)
    local InstanceTemplate = CElementData.GetTemplate("Instance", 1533)--]]

    local FrontLineTemplate = CElementData.GetTemplate("FrontLine", data.tid)
    local GroupTemplate = CElementData.GetTemplate("QuestGroup", FrontLineTemplate.QuestGroupId)
    local InstanceTemplate = CElementData.GetTemplate("Instance", FrontLineTemplate.DungeonTID)

--[[    GUI.SetText(self._Lab_ProNumber, 25)
    self._PorgressFillImg.fillAmount = 25 / 100--]]

    self._List_QuestMenu:SetItemCount( #GroupTemplate.GroupFields )

    rewards = GUITools.GetRewardList( InstanceTemplate.RewardId , false)
    if #rewards > 0 then
        --self._Lab_RewardTips:SetActive(true)
        self._List_ElementsReward:SetItemCount(#rewards)
    else
        --self._Lab_RewardTips:SetActive(false)
    end

    GUI.SetText(self._Lab_LvValues, tostring(InstanceTemplate.MinEnterLevel))
    --GUI.SetText(self._Lab_OpenLvValues, FrontLineTemplate.MinEnterLevel)

    self:UpdateState()
end

def.method().UpdateState = function(self)
    local remain_time = (self._Current_Data.endtime - GameUtil.GetServerTime()/1000)
    remain_time = math.floor(remain_time)
    if remain_time > 0 then
        self._Frame_Time:SetActive(true)
        self._Frame_Open:SetActive(false)
        self:AddTimer( self._Lab_TimeLvValues,remain_time )
        self._Btn_Jion:MakeGray(false)
        self._Btn_Jion:SetInteractable(true)
    else
        self._Frame_Time:SetActive(false)
        self._Frame_Open:SetActive(true)
        self._Btn_Jion:MakeGray(true)
        self._Btn_Jion:SetInteractable(false)
    end
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Jion' then
        CQuest.Instance():DoFrontLineEnter ( self._Current_Data.tid )
        game._GUIMan:CloseByScript(self)
    end
end

--添加入侵目标倒计时
local timeID = 0
def.method("userdata","number").AddTimer = function(self,lab_time,time)
    _G.RemoveGlobalTimer(timeID)
    local callback = function()
        if IsNil(lab_time) then return end           

        local strTime = GUITools.FormatTimeFromSecondsToZero(false, time)
        lab_time:SetActive(true)
        GUI.SetText(lab_time, strTime)

        time = time - 1
        if time < 0 then
            lab_time:SetActive(false)
            _G.RemoveGlobalTimer(timeID)  
            self:UpdateState()
            --game._GUIMan:CloseByScript(self)       
        end
    end
    timeID = _G.AddGlobalTimer(1, false, callback)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1

    if id == 'List_QuestMenu' then
        local FrontLineTemplate = CElementData.GetTemplate("FrontLine", self._Current_Data.tid)
        local GroupTemplate = CElementData.GetTemplate("QuestGroup", FrontLineTemplate.QuestGroupId)
        local QuestID = GroupTemplate.GroupFields[idx].QuestId
        local QuestTemplate = CElementData.GetQuestTemplate(QuestID) 

        --print("QuestID=========",idx,QuestID)
        local Lab_QuestDes = item:FindChild("Lab_QuestDes")
        local Lab_QuestFinish = item:FindChild("Lab_QuestFinish")
        local Lab_QuestIng = item:FindChild("Lab_QuestIng")

        local color_code = "FFFFFFFF"
        --判断此任务是否完成 改变字体颜色

        if CQuest.Instance():IsQuestCompleted(QuestID) then
            Lab_QuestFinish:SetActive(true)
            Lab_QuestIng:SetActive(false)
            color_code = "3C4047FF"
        else
            Lab_QuestFinish:SetActive(false)
            --判断此任务是否进行中 或者在可以接取的状态
            --if CQuest.Instance():IsQuestInProgress(QuestID) or CQuest.Instance():IsQuestReady(QuestID) or CQuest.Instance():CanRecieveQuest(QuestID) then
            if CQuest.Instance():IsQuestInProgress(QuestID) or CQuest.Instance():IsQuestReady(QuestID) or CQuest.Instance()._QuestsCanRecievedTalbe[QuestID] ~= nil then
                color_code = "FBF468FF"
                Lab_QuestIng:SetActive(true)
            else
            --不能接
                color_code = "FFFFFFFF"
                Lab_QuestIng:SetActive(false)
            end
        end

        local str =  QuestTemplate.TextDisplayName
        str =  "<color=#" .. color_code ..">" ..str .."</color>"
        GUI.SetText(Lab_QuestDes, str)

    elseif id == 'List_ElementsReward' then
        local rewardData = rewards[idx]
        if rewardData ~= nil then
            local frame_icon = GUITools.GetChild(item, 0)
            if rewardData.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(frame_icon, rewardData.Data.Id, rewardData.Data.Count)
            else
                IconTools.InitItemIconNew(frame_icon, rewardData.Data.Id, { [EItemIconTag.Number] = rewardData.Data.Count })
            end
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == 'List_ElementsReward' then    
        local rewardData = rewards[index + 1]
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

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    local idx = index + 1

    for i = 1 ,4 do 
        if id_btn == "Btn_Reward"..i then
            local rewardData = repeatRewards[idx][i]
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
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    _G.RemoveGlobalTimer(timeID)
end

def.override().OnDestroy = function(self)
    self._Lab_LvValues = nil
    self._Lab_TimeLvValues = nil
    self._Lab_OpenLvValues = nil
    self._List_QuestMenu = nil
    self._List_ElementsReward = nil
    --self._Lab_RewardTips = nil
    self._Lab_ProNumber = nil
    self._Frame_Time = nil
    self._Frame_Open = nil
    if self._Btn_Jion ~= nil then
        self._Btn_Jion:Destroy()
        self._Btn_Jion = nil
    end
end

CPanelUIFrontLine.Commit()
return CPanelUIFrontLine