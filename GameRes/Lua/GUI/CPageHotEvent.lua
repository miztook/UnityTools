-- 热点活动  --> 骰子
-- 2019/8/8    lidaming

local Lplus = require "Lplus"
local CPanelRoleInfo = require "GUI.CPanelRoleInfo"
local CPageHotEvent = Lplus.Class("CPageHotEvent")
local def = CPageHotEvent.define
local CElementData = require "Data.CElementData"
local CWelfareMan = require "Main.CWelfareMan"
local EStyle = require "PB.Template".HotActivity.EStyle
local EScriptEventType = require "PB.data".EScriptEventType

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Frame_HotEvent = nil 
def.field("userdata")._Frame_HotEventType1 = nil 
def.field("userdata")._Frame_HotEventType2 = nil 
def.field("userdata")._Frame_HotEventType3 = nil 

def.field("userdata")._List_HotEventReward = nil
def.field("userdata")._List_HotEventInfo2 = nil 
def.field("userdata")._List_HotEventInfo3 = nil

def.field("userdata")._Img_HotEventBg = nil
def.field("userdata")._Lab_HotEventName = nil               -- 活动名称
def.field("userdata")._Lab_HotEventActivityTime = nil        -- 活动时间描述

def.field("userdata")._Frame_HotEventInfo = nil 

def.field("table")._HotEventInfo = BlankTable
def.field("table")._HotActivityTemp = BlankTable
def.field("table")._AchieveIds = BlankTable

def.field("table")._FinishHotEventIds = BlankTable          --已经完成
def.field("table")._RewardHotEventIds = BlankTable          --已经领取


def.static("table", "userdata", "=>", CPageHotEvent).new = function(parent, panel)
    local instance = CPageHotEvent()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    self._Frame_HotEvent = self._Parent:GetUIObject("Frame_HotEvent")

    self._Frame_HotEventType1 = self._Parent:GetUIObject("Frame_HotEventType1")
    self._Frame_HotEventType2 = self._Parent:GetUIObject("Frame_HotEventType2")
    self._Frame_HotEventType3 = self._Parent:GetUIObject("Frame_HotEventType3")

    self._Lab_HotEventName = self._Parent:GetUIObject("Lab_HotEventName")
    self._Lab_HotEventActivityTime = self._Parent:GetUIObject("Lab_HotEventActivityTime")

    self._Img_HotEventBg = self._Frame_HotEvent:FindChild("Img_HotEventBg")

    self._Frame_HotEventInfo = self._Frame_HotEventType1:FindChild("Frame_HotEventInfo")

    self._List_HotEventReward = GUITools.GetChild(self._Frame_HotEventInfo, 12):GetComponent(ClassType.GNewList)
    self._List_HotEventInfo2 = self._Parent:GetUIObject('List_HotEventInfo2'):GetComponent(ClassType.GNewList)
    self._List_HotEventInfo3 = self._Parent:GetUIObject('List_HotEventInfo3'):GetComponent(ClassType.GNewList)
end

--------------------------------------------------------------------------------

def.method("number").Show = function(self, HotEventTid)
    self._Panel:SetActive(true)
    self._HotEventInfo = {}    

    self._HotEventInfo = game._CWelfareMan:GetHotEventInfo(HotEventTid)

    self._HotActivityTemp = CElementData.GetTemplate("HotActivity", self._HotEventInfo._Tid)

    if self._Lab_HotEventName ~= nil then
        GUI.SetText(self._Lab_HotEventName , tostring(self._HotActivityTemp.Name))
    end

    if self._Lab_HotEventActivityTime ~= nil then
        GUI.SetText(self._Lab_HotEventActivityTime , tostring(self._HotActivityTemp.TimeDes))
    end

    if self._Img_HotEventBg ~= nil and self._HotActivityTemp.BackgroundImg ~= "" then
        GUITools.SetSprite(self._Img_HotEventBg, self._HotActivityTemp.BackgroundImg)
    end
    
    string.gsub(self._HotActivityTemp.Achieves, '[^*]+', function(w) table.insert(self._AchieveIds, w) end )
    string.gsub(self._HotEventInfo._FinishHotEventID, '[^*]+', function(w) table.insert(self._FinishHotEventIds, w) end )
    string.gsub(self._HotEventInfo._RewardHotEventID, '[^*]+', function(w) table.insert(self._RewardHotEventIds, w) end )
    self:UpdateHotEventType(self._HotActivityTemp.Style)
    
end


-- 更新活动样式
def.method("number").UpdateHotEventType = function(self, HotEventType)
    if HotEventType == EStyle.EStyle_1 then
        self._Frame_HotEventType1:SetActive(true)
        self._Frame_HotEventType2:SetActive(false)
        self._Frame_HotEventType3:SetActive(false)

        local Lab_HotEventName = GUITools.GetChild(self._Frame_HotEventInfo, 1)
        local Lab_GoalHotEvent = GUITools.GetChild(self._Frame_HotEventInfo, 6)
        local Lab_HotEventNumber = GUITools.GetChild(self._Frame_HotEventInfo, 7)
        local ItemIconNew = GUITools.GetChild(self._Frame_HotEventInfo, 9)
        local Btn_GetReward = GUITools.GetChild(self._Frame_HotEventInfo, 2)
        local Img_Done = GUITools.GetChild(self._Frame_HotEventInfo, 8)
        local Img_Get = GUITools.GetChild(self._Frame_HotEventInfo, 22)

        local achievementTemp = CElementData.GetTemplate("Achievement", tonumber(self._AchieveIds[1]))
        if achievementTemp == nil then return end
        GUI.SetText(Lab_HotEventName , achievementTemp.DisPlayName)
        GUI.SetText(Lab_GoalHotEvent , achievementTemp.Description)
        -- achievementData._State._CurValueList, achievementTemp.Condition, achievementTemp.ReachParm
        local achievementData = game._AcheivementMan:GetAchieventMentByID(achievementTemp.Id)

        local CurCount = game._AcheivementMan:GetTargetAchievementCurrent(achievementTemp.Id)
        local MaxCount = game._AcheivementMan:GetAchievementReachCount(achievementTemp.Id)
        GUI.SetText(Lab_HotEventNumber , CurCount .. "/" .. MaxCount)

        local item_data = GUITools.GetRewardList(achievementTemp.RewardId, true)
        if item_data ~= nil then
            self._List_HotEventReward:SetItemCount(#item_data)
        end

        local isFinish = false          -- 是否完成
        local isReceive = false         -- 是否已领取

        if #self._RewardHotEventIds > 0 then
            for _,v in pairs(self._RewardHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[1]) then
                    isReceive = true
                    break
                end
            end
        end
        if #self._FinishHotEventIds > 0 then
            for _,v in pairs(self._FinishHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[1]) then
                    isFinish = true
                    break
                end
            end
        end
        if isReceive then
            Img_Done:SetActive(true)
            Img_Get:SetActive(true)
            Btn_GetReward:SetActive(false)
        else
            Img_Done:SetActive(false)
            Img_Get:SetActive(false)
            Btn_GetReward:SetActive(true)
            if isFinish then
                GUITools.SetBtnGray(Btn_GetReward, false)
            else
                GUITools.SetBtnGray(Btn_GetReward, true)
            end
        end


    elseif HotEventType == EStyle.EStyle_2 then
        self._Frame_HotEventType1:SetActive(false)
        self._Frame_HotEventType2:SetActive(true)
        self._Frame_HotEventType3:SetActive(false)
        self._List_HotEventInfo2:SetItemCount(#self._AchieveIds) 
    elseif HotEventType == EStyle.EStyle_3 then
        self._Frame_HotEventType1:SetActive(false)
        self._Frame_HotEventType2:SetActive(false)
        self._Frame_HotEventType3:SetActive(true)
        self._List_HotEventInfo3:SetItemCount(#self._AchieveIds) 
    else
        self._Frame_HotEventType1:SetActive(false)
        self._Frame_HotEventType2:SetActive(false)
        self._Frame_HotEventType3:SetActive(false)
    end
end


def.method('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_HotEventReward" then
        local achievementTemp = CElementData.GetTemplate("Achievement", tonumber(self._AchieveIds[1]))
        if achievementTemp == nil then return end
        local rewardTemplate = GUITools.GetRewardList(achievementTemp.RewardId, true)
        local CanversGroupObj = GUITools.GetChild(item, 3)
        -- 统一初始化奖励物品，模块的类必须有_RewardData    
        if rewardTemplate == nil then return end
        local reward = rewardTemplate[index + 1]
        if reward ~= nil then
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(item, reward.Data.Id, reward.Data.Count)
            else
                IconTools.InitItemIconNew(item, reward.Data.Id, { [EItemIconTag.Number] = reward.Data.Count })
            end
        end  
        local isReceive = false         -- 是否已领取
        if #self._RewardHotEventIds > 0 then
            for _,v in pairs(self._RewardHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[1]) then
                    isReceive = true
                    break
                end
            end
        end
        if isReceive then
            GameUtil.SetCanvasGroupAlpha(CanversGroupObj, 0.5)
        else
            GameUtil.SetCanvasGroupAlpha(CanversGroupObj, 1)
        end

    elseif id == "List_HotEventInfo2" then
        local Lab_HotEventName = GUITools.GetChild(item, 1)
        local Lab_GoalHotEvent = GUITools.GetChild(item, 3)
        local Lab_HotEventNumber = GUITools.GetChild(item, 4)
        local ItemIconNew = GUITools.GetChild(item, 9)
        local Btn_GetReward = GUITools.GetChild(item, 5)
        local Img_Done = GUITools.GetChild(item, 15)
        local Lab_ItemNum = GUITools.GetChild(item, 13)
        local Img_Get = GUITools.GetChild(item, 16)

        local CanversGroupObj = GUITools.GetChild(ItemIconNew, 3)

        local achievementTemp = CElementData.GetTemplate("Achievement", tonumber(self._AchieveIds[index]))
        if achievementTemp == nil then return end
        GUI.SetText(Lab_HotEventName , achievementTemp.DisPlayName)
        GUI.SetText(Lab_GoalHotEvent , achievementTemp.Description)
        -- achievementData._State._CurValueList, achievementTemp.Condition, achievementTemp.ReachParm
        local achievementData = game._AcheivementMan:GetAchieventMentByID(achievementTemp.Id)

        local CurCount = game._AcheivementMan:GetTargetAchievementCurrent(achievementTemp.Id)
        local MaxCount = game._AcheivementMan:GetAchievementReachCount(achievementTemp.Id)
        if CurCount > MaxCount then
            CurCount = MaxCount
        end
        GUI.SetText(Lab_HotEventNumber , CurCount .. "/" .. MaxCount)

        local item_data = GUITools.GetRewardList(achievementTemp.RewardId, true)
        local reward = item_data[1]
        if reward ~= nil then
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(ItemIconNew, reward.Data.Id, 0)
                GUI.SetText(Lab_ItemNum, GUITools.FormatNumber(reward.Data.Count)) 
            else
                IconTools.InitItemIconNew(ItemIconNew, reward.Data.Id)
                GUI.SetText(Lab_ItemNum, GUITools.FormatNumber(reward.Data.Count)) 
            end
        end  

        local isFinish = false          -- 是否完成
        local isReceive = false         -- 是否已领取

        if #self._RewardHotEventIds > 0 then
            for _,v in pairs(self._RewardHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[index]) then
                    isReceive = true
                    break
                end
            end
        end
        if #self._FinishHotEventIds > 0 then
            for _,v in pairs(self._FinishHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[index]) then
                    isFinish = true
                    break
                end
            end
        end
        if isReceive then
            Img_Done:SetActive(true)
            Img_Get:SetActive(true)
            Btn_GetReward:SetActive(false)
            GameUtil.SetCanvasGroupAlpha(CanversGroupObj, 0.5)
        else
            Img_Done:SetActive(false)
            Img_Get:SetActive(false)
            Btn_GetReward:SetActive(true)
            GameUtil.SetCanvasGroupAlpha(CanversGroupObj, 1)
            if isFinish then
                GUITools.SetBtnGray(Btn_GetReward, false)
            else
                GUITools.SetBtnGray(Btn_GetReward, true)
            end
        end

    elseif id == "List_HotEventInfo3" then
        local Lab_GoalHotEvent = GUITools.GetChild(item, 2)
        local Lab_HotEventNumber = GUITools.GetChild(item, 3)
        local ItemIconNew = GUITools.GetChild(item, 5)
        local Btn_GetReward = GUITools.GetChild(item, 11)
        local Img_Done = GUITools.GetChild(item, 14)
        local Lab_ItemNum = GUITools.GetChild(item, 9)
        local Img_Get = GUITools.GetChild(item, 15)
        local CanversGroupObj = GUITools.GetChild(ItemIconNew, 3)

        local achievementTemp = CElementData.GetTemplate("Achievement", tonumber(self._AchieveIds[index]))
        if achievementTemp == nil then return end
        GUI.SetText(Lab_GoalHotEvent , achievementTemp.Description)
        -- achievementData._State._CurValueList, achievementTemp.Condition, achievementTemp.ReachParm
        local achievementData = game._AcheivementMan:GetAchieventMentByID(achievementTemp.Id)

        local CurCount = game._AcheivementMan:GetTargetAchievementCurrent(achievementTemp.Id)
        local MaxCount = game._AcheivementMan:GetAchievementReachCount(achievementTemp.Id)
        if CurCount > MaxCount then
            CurCount = MaxCount
        end
        GUI.SetText(Lab_HotEventNumber , CurCount .. "/" .. MaxCount)

        local item_data = GUITools.GetRewardList(achievementTemp.RewardId, true)
        local reward = item_data[1]
        if reward ~= nil then
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(ItemIconNew, reward.Data.Id, 0)
                GUI.SetText(Lab_ItemNum, GUITools.FormatNumber(reward.Data.Count)) 
            else
                IconTools.InitItemIconNew(ItemIconNew, reward.Data.Id)
                GUI.SetText(Lab_ItemNum, GUITools.FormatNumber(reward.Data.Count)) 
            end
        end  

        -- _isFinish = false,      -- 是否完成
        -- _IsReceive = false,     -- 是否已领取
        if achievementData._State._IsReceive then
            Img_Done:SetActive(true)
            Img_Get:SetActive(true)
            Btn_GetReward:SetActive(false)
            GameUtil.SetCanvasGroupAlpha(CanversGroupObj, 0.5)
        else
            Img_Done:SetActive(false)
            Img_Get:SetActive(false)
            Img_Done:SetActive(true)
            GameUtil.SetCanvasGroupAlpha(CanversGroupObj, 1)
            Btn_GetReward:SetActive(true)
            if achievementData._State._isFinish then
                GUITools.SetBtnGray(Btn_GetReward, false)
            else
                GUITools.SetBtnGray(Btn_GetReward, true)
            end
        end



    end
end

def.method('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == "List_HotEventReward" then
        local achievementTemp = CElementData.GetTemplate("Achievement", tonumber(self._AchieveIds[1]))
        if achievementTemp == nil then return end
        local rewardTemplate = GUITools.GetRewardList(achievementTemp.RewardId, true)
        -- 统一初始化奖励物品，模块的类必须有_RewardData    
        if rewardTemplate == nil then return end
        local rewardData = rewardTemplate[index + 1]
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
    elseif id == "List_HotEventInfo2" then

    elseif id == "List_HotEventInfo3" then

    end
end

def.method("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if id_btn == "Btn_Finish_1" then
        local isFinish = false          -- 是否完成
        local isReceive = false         -- 是否已领取
        if #self._RewardHotEventIds > 0 then
            for _,v in pairs(self._RewardHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[index]) then
                    isReceive = true
                    break
                end
            end
        end
        if #self._FinishHotEventIds > 0 then
            for _,v in pairs(self._FinishHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[index]) then
                    isFinish = true
                    break
                end
            end
        end
        if not isReceive and isFinish then
            game._CWelfareMan:OnC2SScriptExec(self._HotEventInfo._ScriptID, EScriptEventType.HA_GainReward, tonumber(self._AchieveIds[index]))
        end

    elseif id_btn == "ItemIconNew" then
        local achievementTemp = CElementData.GetTemplate("Achievement", tonumber(self._AchieveIds[index]))
        if achievementTemp == nil then return end
        local rewardTemplate = GUITools.GetRewardList(achievementTemp.RewardId, true)
        -- 统一初始化奖励物品，模块的类必须有_RewardData    
        if rewardTemplate == nil then return end
        local rewardData = rewardTemplate[1]
        if not rewardData.IsTokenMoney then
            CItemTipMan.ShowItemTips(rewardData.Data.Id, TipsPopFrom.OTHER_PANEL,button_obj,TipPosition.FIX_POSITION)
        else
            local panelData = 
                {
                    _MoneyID = rewardData.Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = button_obj,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
        end
    end
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_HotEventDesc" then
        game._GUIMan:Close("CPanelUICommonNotice")        
        local data = 
        {
            Title = self._HotActivityTemp.Name,
            Name = StringTable.Get(34200),
            Desc = self._HotActivityTemp.ContentDes,
        }
        game._GUIMan:Open("CPanelUICommonNotice", data)
    elseif id == "Btn_Finish_1" then
        local isFinish = false          -- 是否完成
        local isReceive = false         -- 是否已领取
        if #self._RewardHotEventIds > 0 then
            for _,v in pairs(self._RewardHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[1]) then
                    isReceive = true
                    break
                end
            end
        end
        if #self._FinishHotEventIds > 0 then
            for _,v in pairs(self._FinishHotEventIds) do
                if tonumber(v) == tonumber(self._AchieveIds[1]) then
                    isFinish = true
                    break
                end
            end
        end
        if not isReceive and isFinish then
            game._CWelfareMan:OnC2SScriptExec(self._HotEventInfo._ScriptID, EScriptEventType.HA_GainReward, tonumber(self._AchieveIds[1]))
        end
    end
end

def.method().Hide = function(self)
    self._Panel:SetActive(false)
    
end

def.method().Destroy = function (self)
    self:Hide()
end
----------------------------------------------------------------------------------


CPageHotEvent.Commit()
return CPageHotEvent