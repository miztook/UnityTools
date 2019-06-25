-- 冒险指南  --> 每日任务
-- 2018/08/24    lidaming

local Lplus = require "Lplus"
local CPageDailyTask = Lplus.Class("CPageDailyTask")
local def = CPageDailyTask.define
local CCommonBtn = require "GUI.CCommonBtn"
local CElementData = require "Data.CElementData"
local EBoxType = require "PB.Template".DailyTaskBox.EBoxType

def.field("table")._Parent = nil
-- 界面
def.field("userdata")._Frame_Quest = nil 
def.field("userdata")._Frame_Bottom = nil 
def.field("userdata")._Frame_QuestComplete = nil
def.field('userdata')._Frame_QuestList = nil
def.field("userdata")._Lab_DailyTaskLuck = nil        -- 今日运势
def.field("userdata")._Lab_DailyTaskLuckDesc = nil      -- 今日运势描述
def.field("userdata")._Lab_DayQuestCount = nil      -- 每日完成任务总数
def.field("userdata")._Lab_WeekQuestCount = nil      -- 每周完成任务总数
def.field("userdata")._Img_DayQuestIcon = nil      -- 每日完成任务图标
def.field("userdata")._Img_WeekQuestIcon = nil      -- 每周完成任务图标
def.field("userdata")._Img_DayQuestIconOpen = nil      -- 每日完成任务图标开启
def.field("userdata")._Img_WeekQuestIconOpen = nil      -- 每周完成任务图标开启
def.field("userdata")._Lab_QuestLiveness = nil          -- 今日任务数量
def.field("userdata")._Lab_RefNeedMoney = nil      -- 刷新每日任务需要钱数
def.field("userdata")._ProBar_Quest = nil        -- 任务进度条
def.field("userdata")._Btn_Refresh = nil
def.field("userdata")._Btn_RefreshDailyTaskLuck = nil
def.field("userdata")._Lab_FreeRefreshDailyTaskLuck = nil
def.field("userdata")._Lab_FreeRefresh = nil

def.field("table")._BtnTable_DayChest = BlankTable
def.field("table")._ImgTable_DayChest = BlankTable
def.field("table")._OpenImgTable_DayChest = BlankTable

def.field("table")._DailyTaskInfo = BlankTable         -- 每日任务信息
def.field("number")._CurTaskLuckTid = 0                -- 当前运势ID
def.field("table")._DailyTaskDrawBox = BlankTable      -- 获取当前冒险指南活跃度对应宝箱领取情况
def.field("number")._DayReachCount = 0                 -- 每天完成数量
def.field("number")._WeekReachCount = 0                -- 每周完成数量
def.field("table")._DayChestDataList = BlankTable      -- 每天宝箱模版列表
def.field("table")._WeekChestDataList = BlankTable     -- 每周宝箱模版列表
-- 常量
def.field("number")._MaxDayChestNum = 4                 -- 每天宝箱的最大数量
def.field("number")._MaxQuestLiveness = 12              -- 每天进度的最大数量
def.field("number")._FreeRefreshQuestNum = 3            -- 免费刷新任务次数
def.field("number")._FreeChangeLuckNum = 1              -- 免费更换运势次数
def.field("number")._LuckRefMoneyId = 3                 -- 运势刷新消耗货币ID
def.field("number")._QuestRefMoneyId = 1                -- 任务刷新消耗货币ID
def.field("number")._MaxLuckRefnum = 0                  -- 运势最大刷新次数
def.field("table")._LuckRefCostList = BlankTable        -- 运势刷新消耗
def.field("table")._QuestRefCostList = BlankTable       -- 任务刷新消耗
def.field("boolean")._IsNoProvide = false               -- 是否没有可接受任务

def.field(CCommonBtn)._Btn_RefTaskLuck = nil
def.field(CCommonBtn)._Btn_Ref = nil    

def.static("table", "=>", CPageDailyTask).new = function(parent)
    local instance = CPageDailyTask()
    instance._Parent = parent
    instance:Init()
    return instance
end


local DailyQuestLuckSfx = 
{
    [1] = PATH.UIFX_DAILYTASK_Yunshijia,
    [2] = PATH.UIFX_DAILYTASK_Yunshihao,
    [3] = PATH.UIFX_DAILYTASK_Yunshiyiban,
    [4] = PATH.UIFX_DAILYTASK_Yunshicha,
    [5] = PATH.UIFX_DAILYTASK_Yunshijicha,
}

def.method().Init = function(self)
    self._Frame_Quest = self._Parent._PageRoot:FindChild("PageDailyTask/Frame_Quest")
    self._Frame_QuestComplete = self._Frame_Quest:FindChild("Frame_QuestComplete")
    self._Frame_QuestList = self._Frame_Quest:FindChild("Frame_QuestList")
    self._Lab_DailyTaskLuck = self._Frame_Quest:FindChild("Frame_Left/Frame_DailyTaskLuck/Lab_DailyTaskLuck")
    self._Lab_DailyTaskLuckDesc = self._Frame_Quest:FindChild("Frame_Left/Frame_DailyTaskLuck/Lab_DailyTaskLuck/Lab_DailyTaskLuckDesc")
    self._Frame_Bottom = self._Frame_Quest:FindChild("Frame_Bottom")
    self._Lab_DayQuestCount = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_DayGoalReward/Lab_QuestCount1")
    self._Lab_WeekQuestCount = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_WeekGoalReward/Lab_QuestCount2")
    self._Img_DayQuestIcon = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_DayGoalReward/Img_DayGoalRewardIocn1")
    self._Img_WeekQuestIcon = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_WeekGoalReward/Img_WeekGoalRewardBg2")
    self._Img_DayQuestIconOpen = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_DayGoalReward/Img_DayGoalRewardIocn1open")
    self._Img_WeekQuestIconOpen = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_WeekGoalReward/Img_WeekGoalRewardBg2open")
    self._Lab_QuestLiveness = self._Frame_Bottom:FindChild("Frame_QuestLiveness/Lab_CurDayQuest/Lab_QuestLiveness")
    
    self._ProBar_Quest = self._Frame_Bottom:FindChild("Frame_QuestLiveness/Pro_QuestLiveness"):GetComponent(ClassType.Scrollbar)
    self._Btn_Refresh = self._Frame_Bottom:FindChild("Btn_Refresh")
    self._Btn_RefreshDailyTaskLuck = self._Frame_Quest:FindChild("Frame_Left/Btn_RefreshDailyTaskLuck")
    self._Lab_FreeRefresh = self._Btn_Refresh:FindChild("Img_Bg/Lab_FreeRefresh")
    self._Lab_FreeRefreshDailyTaskLuck = self._Btn_RefreshDailyTaskLuck:FindChild("Img_Bg/Lab_FreeRefreshDailyTaskLuck")
    self._Lab_RefNeedMoney = self._Frame_Bottom:FindChild("Btn_Refresh/Img_Bg/Img_NeedMoneyBg/Lab_RefreshNeedMoney")

    self._Btn_Ref = CCommonBtn.new(self._Btn_Refresh, nil)
    self._Btn_RefTaskLuck = CCommonBtn.new(self._Btn_RefreshDailyTaskLuck, nil)

    for i=1, self._MaxDayChestNum do
        table.insert(self._BtnTable_DayChest, self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. i .."/Btn_Quest_Item_0" .. i))
        table.insert(self._ImgTable_DayChest, self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. i .."/Btn_Quest_Item_0" .. i .."/Img_Quest_Item_0" .. i))
        table.insert(self._OpenImgTable_DayChest, self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. i .."/Btn_Quest_Item_0" .. i .."/Img_Quest_Item_0" .. i .."open"))
    end

    local CSpecialIdMan = require "Data.CSpecialIdMan"
    self._MaxLuckRefnum = CSpecialIdMan.Get("DailyLuckRefreshUpperLimit")
    local costStrList = string.split(CSpecialIdMan.Get("DailyLuckRefreshCost"), "*")
    for index, cost in ipairs(costStrList) do
        self._LuckRefCostList[index] = tonumber(cost)
    end
    costStrList = string.split(CSpecialIdMan.Get("DailyQuestRefreshCost"), "*")
    for index, cost in ipairs(costStrList) do
        self._QuestRefCostList[index] = tonumber(cost)
    end
     -- 每日任务  
     game._CCalendarMan:SendC2SDailyTask()
end

def.method("=>", "boolean").ShowRedPoint = function(self)
    return game._CCalendarMan:IsShowDailyTaskRedPoint()
end

--------------------------------------------------------------------------------
def.method().Show = function(self)
    -- 每次打开界面都请求一次数据
    game._CCalendarMan:SendC2SDailyTask()
    self._CurTaskLuckTid = game._CCalendarMan:GetLuckId()
    local curTaskLuckData = CElementData.GetTemplate("TaskLuck", self._CurTaskLuckTid)
    -- GetDailyQuestLuckColorText
    if curTaskLuckData == nil then return end
    GameUtil.StopUISfx(DailyQuestLuckSfx[curTaskLuckData.Id], self._Lab_DailyTaskLuck)
    self:UpdateQuestList()
    self:UpdateLuckShow()
    self:UpdateChestState()
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_RefreshDailyTaskLuck" then       -- 更换运势

        self._CurTaskLuckTid = game._CCalendarMan:GetLuckId()
        local curTaskLuckData = CElementData.GetTemplate("TaskLuck", self._CurTaskLuckTid)
        -- GetDailyQuestLuckColorText
        if curTaskLuckData == nil then return end
        GameUtil.StopUISfx(DailyQuestLuckSfx[curTaskLuckData.Id], self._Lab_DailyTaskLuck)

        local limit = {
            [EQuickBuyLimit.LuckRefMaxCount] = self._MaxLuckRefnum,
        }
        local IsHaveFreeCount, cost = self:GetCurLuckRefCost()
        local needMoney = 0
        if IsHaveFreeCount then
            needMoney = 0
        else
            needMoney = tonumber(cost)
        end

        local have_count = game._HostPlayer:GetMoneyCountByType(self._LuckRefMoneyId)
        if have_count >= needMoney and needMoney ~= 0 then
            local title, msg, closeType = StringTable.GetMsg(102)
            local setting = {
                [MsgBoxAddParam.NotShowTag] = "CPageDailyTask_1",
                [MsgBoxAddParam.CostMoneyID] = 3,
                [MsgBoxAddParam.CostMoneyCount] = needMoney,
            }
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, function(ret)
                if not ret then return end
                game._CCalendarMan:SendC2SDailyTaskLuckRef()
            end, nil, nil, MsgBoxPriority.Normal, setting)
        else
            -- 快速货币兑换弹窗
            MsgBox.ShowQuickBuyBox(self._LuckRefMoneyId, needMoney, function(ret)
                if not ret then return end
                game._CCalendarMan:SendC2SDailyTaskLuckRef()
            end, limit)
        end
    elseif id == "Btn_Refresh" then
        if not self._IsNoProvide then
            -- 快速货币兑换弹窗
            local IsHaveFreeCount, cost = self:GetCurQuestRefCost()
            local needMoney = 0
            if IsHaveFreeCount then
                needMoney = 0
            else
                needMoney = tonumber(cost)
            end
            MsgBox.ShowQuickBuyBox(self._QuestRefMoneyId, needMoney, function(ret)
                if not ret then return end
                game._CCalendarMan:SendC2SDailyTaskRef()
                CSoundMan.Instance():Play2DAudio(PATH.GUISound_DailyTaskRefresh, 0)
            end)
        end
    elseif id == "Btn_DayGoalReward" then
        self:TryGetChestReward(EBoxType.EBoxType_Week, 1)
    elseif id == "Btn_WeekGoalReward" then
        self:TryGetChestReward(EBoxType.EBoxType_Week, 2)
    elseif string.find(id, "Btn_Quest_Item") then
        local index = tonumber(string.sub(id, -1))
        if index == nil then return end
        self:TryGetChestReward(EBoxType.EBoxType_Day, index)

    elseif string.find(id, "Btn_Finish") then
        local index = tonumber(string.sub(id, -1))
        local taskInfo = self:GetTaskInfoByIndex(index)
        if taskInfo == nil then return end
        game._CCalendarMan:SendC2SDailyTaskFinish(taskInfo.TaskId, false)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_DailyTaskReward, 0)
    elseif string.find(id, "Btn_QuickFinish") then
        local index = tonumber(string.sub(id, -1))
        local taskInfo = self:GetTaskInfoByIndex(index)
        if taskInfo == nil then return end
        local template = CElementData.GetTemplate("DailyTask", taskInfo.TaskId)
        if template == nil then return end
        -- 快速货币兑换弹窗
        MsgBox.ShowQuickBuyBox(self._QuestRefMoneyId, template.FinishCost, function(ret)
            if not ret then return end
            game._CCalendarMan:SendC2SDailyTaskFinish(taskInfo.TaskId, true)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_DailyTaskRefresh, 0)
        end)
    elseif string.find(id, "Btn_GetQuest") then
        local index = tonumber(string.sub(id, -1))
        local taskInfo = self:GetTaskInfoByIndex(index)
        if taskInfo == nil then return end

        game._CCalendarMan:SendC2SDailyTaskProvide(taskInfo.TaskId)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_DailyTaskReward, 0)
    end
end

def.method("userdata", "number").OnInitQuestInfo = function(self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if uiTemplate == nil then return end

    local taskInfo = self:GetTaskInfoByIndex(index) -- taskInfo 结构: PB.net.DailyTaskData
    if taskInfo == nil then return end

    -- 有任务数据
    local dailyTaskTemplate = CElementData.GetTemplate("DailyTask", taskInfo.TaskId)
    if dailyTaskTemplate == nil then return end

    local Btn_Finish = uiTemplate:GetControl(0)
    local Lab_QuestName = uiTemplate:GetControl(1)
    local Img_Quest_Decorate = uiTemplate:GetControl(2)  -- 任务评分
    local Btn_GetQuest = uiTemplate:GetControl(3)
    local Btn_QuickFinish = uiTemplate:GetControl(4)
    local Lab_QuickFinishNeedMoney = uiTemplate:GetControl(6)    -- 快速完成需要钱数
    local Lab_GoalQuest = uiTemplate:GetControl(7)
    local Lab_GoalQuestNum= uiTemplate:GetControl(8)
    local Img_QuestRewardIcon1 = uiTemplate:GetControl(11)  -- 任务奖励货币图标1
    local Lab_QuestReward1 = uiTemplate:GetControl(12)
    local Img_QuestRewardIcon2 = uiTemplate:GetControl(14)  -- 任务奖励货币图标2
    local Lab_QuestReward2 = uiTemplate:GetControl(15)
    local Lab_QuestTime = uiTemplate:GetControl(16)
    local Frame_Done = uiTemplate:GetControl(17)
    local Img_BG = uiTemplate:GetControl(19)
    local Img_Quest_Line = uiTemplate:GetControl(20)
    local List_QuestReward = uiTemplate:GetControl(22)
    -- 名称
    GUI.SetText(Lab_QuestName, dailyTaskTemplate.DisplayName)
    -- 评级
    GUITools.SetGroupImg(Img_Quest_Decorate, dailyTaskTemplate.Grade - 1)
    GUITools.SetGroupImg(Img_BG, dailyTaskTemplate.Grade - 1)    
    
    GUITools.SetGroupImg(Img_Quest_Line, dailyTaskTemplate.Grade - 1)
    -- 描述
    GUI.SetText(Lab_GoalQuest, dailyTaskTemplate.Description)
    -- 目标数量
    GUI.SetText(Lab_GoalQuestNum, taskInfo.ObjReachCount .. "/" .. dailyTaskTemplate.ObjCount)
    -- 是否已完成
    GUITools.SetUIActive(Frame_Done, taskInfo.IsDrawReward)
    -- 奖励
    local rewardTemplate = GUITools.GetRewardList(dailyTaskTemplate.RewardID, true)
    if rewardTemplate ~= nil then
        List_QuestReward:GetComponent(ClassType.GNewList):SetItemCount(#rewardTemplate)
    end

    local timeStr = ""
    if taskInfo.IsDrawReward then
        -- 已领取奖励
        GUITools.SetUIActive(Btn_GetQuest, false)
        GUITools.SetUIActive(Btn_QuickFinish, false)
        GUITools.SetUIActive(Btn_Finish, false)
        timeStr = string.format(StringTable.Get(603), 0)
    else      
        GUITools.SetUIActive(Btn_GetQuest, not taskInfo.IsProvide)
        if taskInfo.IsProvide then
            GUITools.SetUIActive(Btn_GetQuest, false)
            -- 已接受任务
            local minuteStr = StringTable.Get(603)
            local passTime = GameUtil.GetServerTime() / 1000 - taskInfo.ProvideTime
            local leftTime = dailyTaskTemplate.AutoFinishTime * 60 - passTime -- AutoFinishTime 单位为分钟
            if leftTime <= 0 then
                -- 已到时间, 显示“0分钟”
                timeStr = string.format(minuteStr, 0)
            else
                GUI.SetText(Lab_QuickFinishNeedMoney, GUITools.FormatMoney(dailyTaskTemplate.FinishCost))
                if leftTime / 60 <= 1 then
                    -- 剩余时间小于1分钟，显示“不足1分钟”
                    timeStr = StringTable.Get(31802) .. string.format(minuteStr, 1)
                else
                    timeStr = string.format(minuteStr, math.floor(leftTime / 60))
                end
            end

            local isNumEnough = taskInfo.ObjReachCount >= dailyTaskTemplate.ObjCount
            GUITools.SetUIActive(Btn_Finish, isNumEnough or leftTime <= 0)
            GUITools.SetUIActive(Btn_QuickFinish, not isNumEnough and leftTime > 0)
        else
            GUITools.SetUIActive(Btn_GetQuest, true)
            GUITools.SetUIActive(Btn_Finish, false)
            GUITools.SetUIActive(Btn_QuickFinish, false)

            timeStr = string.format(StringTable.Get(603), dailyTaskTemplate.AutoFinishTime)
        end 
        
    end
    GUI.SetText(Lab_QuestTime, timeStr) -- 剩余时间
end

def.method('userdata', 'string', 'number').OnInitItem = function (self, item, id, index)
    local taskIndex = tonumber(string.sub(id, -1))
    local taskInfo = self:GetTaskInfoByIndex(taskIndex)
    if taskInfo == nil then return end
    -- local Lab_Number = GUITools.GetChild(item , 3)
    -- 有任务数据
    local dailyTaskTemplate = CElementData.GetTemplate("DailyTask", taskInfo.TaskId)
    if dailyTaskTemplate == nil then return end
    local rewardTemplate = GUITools.GetRewardList(dailyTaskTemplate.RewardID, true)
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
end


def.method('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    -- 奖励列表
    local taskIndex = tonumber(string.sub(id, -1))
    local taskInfo = self:GetTaskInfoByIndex(taskIndex)
    if taskInfo == nil then return end
    -- 有任务数据
    local dailyTaskTemplate = CElementData.GetTemplate("DailyTask", taskInfo.TaskId)
    if dailyTaskTemplate == nil then return end

    local rewardTemplate = GUITools.GetRewardList(dailyTaskTemplate.RewardID, true)
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
end

def.method().Hide = function(self)    
end

def.method().Destroy = function (self)
    self:Hide()
    self._Frame_Quest = nil
    self._Frame_QuestComplete = nil
    self._Frame_QuestList = nil
    self._Lab_DailyTaskLuck = nil
    self._Lab_DailyTaskLuckDesc = nil
    self._Lab_DayQuestCount = nil
    self._Lab_WeekQuestCount = nil
    self._Img_DayQuestIcon = nil
    self._Img_WeekQuestIcon = nil
    self._Lab_QuestLiveness = nil
    self._Lab_RefNeedMoney = nil
    self._ProBar_Quest = nil
    self._ImgTable_DayChest = {}
    self._BtnTable_DayChest = {}
    self._OpenImgTable_DayChest = {}
    self._Btn_Refresh = nil
    self._Btn_RefreshDailyTaskLuck = nil
    self._Lab_FreeRefreshDailyTaskLuck = nil
    self._Lab_FreeRefresh = nil
    self._Frame_Bottom = nil
    self._Img_DayQuestIconOpen = nil
    self._Img_WeekQuestIconOpen = nil
    if self._Btn_RefTaskLuck ~= nil then
        self._Btn_RefTaskLuck:Destroy()
        self._Btn_RefTaskLuck = nil
    end
    if self._Btn_Ref ~= nil then
        self._Btn_Ref:Destroy()
        self._Btn_Ref = nil
    end
end

-- 接收服务器推送事件
-- @param eventType 0: 查看每日任务信息
--                  1: 每日任务领取
--                  2: 每日任务完成
--                  3: 每日任务刷新
--                  4: 运势刷新
--                  5: 领取宝箱奖励
-- @param data 自定义数据
def.method("number").DailyTaskEventFormServer = function(self, eventType)
    if eventType == 0 then
        self:UpdateQuestList()
        self:UpdateLuckShow()
        self:UpdateChestState()
    elseif eventType == 1 then
        self:UpdateQuestList()
    elseif eventType == 2 then
        self:UpdateQuestList()
        self:UpdateChestState()
    elseif eventType == 3 then
        self:UpdateQuestList()
    elseif eventType == 4 then
        self:UpdateLuckShow()
        self._CurTaskLuckTid = game._CCalendarMan:GetLuckId()
        local curTaskLuckData = CElementData.GetTemplate("TaskLuck", self._CurTaskLuckTid)
        -- GetDailyQuestLuckColorText
        if curTaskLuckData == nil then return end
        GameUtil.PlayUISfx(DailyQuestLuckSfx[curTaskLuckData.Id], self._Lab_DailyTaskLuck, self._Lab_DailyTaskLuck, -1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_DailyTaskLuck, 0)
    elseif eventType == 5 then
        self:UpdateChestState()
    end
end
----------------------------------------------------------------------------------
-- 更新任务列表
def.method().UpdateQuestList = function(self)
    self._DailyTaskInfo = game._CCalendarMan:GetAllDailyTaskData()
    local IsAllProvide = true
    if #self._DailyTaskInfo > 0 then     
        local allFinish = true -- 是否任务全部完成   
        for i, v in ipairs(self._DailyTaskInfo) do
            if not v.IsDrawReward then
                allFinish = false
                break
            end
        end

        for i, v in ipairs(self._DailyTaskInfo) do
            if not v.IsDrawReward and not v.IsProvide then
                IsAllProvide = false
                break
            end
        end

        for i, v in ipairs(self._DailyTaskInfo) do
            self:OnInitQuestInfo(self._Parent._PageRoot:FindChild("PageDailyTask/Frame_Quest/Frame_QuestList/List_QuestMenu/Quest_"..i), i)
        end

        GUITools.SetUIActive(self._Frame_QuestComplete, allFinish)        
        local alpha = allFinish and 0.3 or 1 -- 任务全部完成时透明度变30%
        GameUtil.SetCanvasGroupAlpha(self._Frame_QuestList, alpha)
    end
    -- GUI.SetText(self._Lab_RefNeedMoney, self:GetCurQuestRefCost())

    local IsHaveFreeCount, cost = self:GetCurQuestRefCost()
    if IsHaveFreeCount then
        self._Lab_FreeRefresh:SetActive(true)
        self._Btn_Refresh:FindChild("Img_Bg/Node_Content"):SetActive(false)
        GUI.SetText(self._Lab_FreeRefresh, cost)
    else
        self._Lab_FreeRefresh:SetActive(false)
        self._Btn_Refresh:FindChild("Img_Bg/Node_Content"):SetActive(true)
        -- GUI.SetText(self._Lab_RefNeedMoney, GUITools.FormatMoney(tonumber(cost)))

        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = 1,
            [EnumDef.CommonBtnParam.MoneyCost] = cost
        }
        self._Btn_Ref:ResetSetting(setting)
    end

    self:UpdateRefreshLuckLab()
    self._Btn_Ref:MakeGray(IsAllProvide)
    GameUtil.SetButtonInteractable(self._Btn_Refresh, not IsAllProvide)   
end

-- 更新运势相关
def.method().UpdateLuckShow = function(self)
    self._CurTaskLuckTid = game._CCalendarMan:GetLuckId()
    local curTaskLuckData = CElementData.GetTemplate("TaskLuck", self._CurTaskLuckTid)
    -- GetDailyQuestLuckColorText
    if curTaskLuckData == nil then return end
    GUI.SetText(self._Lab_DailyTaskLuck, RichTextTools.GetDailyQuestLuckColorText(curTaskLuckData.Name, curTaskLuckData.Id))
    GUI.SetText(self._Lab_DailyTaskLuckDesc, curTaskLuckData.Description)
    self:UpdateRefreshLuckLab()
end

-- 更新更改运势的描述
def.method().UpdateRefreshLuckLab = function(self)
    local IsHaveLuckFreeCount, Luckcost = self:GetCurLuckRefCost()
    if IsHaveLuckFreeCount then
        self._Lab_FreeRefreshDailyTaskLuck:SetActive(true)
        self._Btn_RefreshDailyTaskLuck:FindChild("Img_Bg/Node_Content"):SetActive(false)
        GUI.SetText(self._Lab_FreeRefreshDailyTaskLuck, Luckcost)        
    else
        self._Lab_FreeRefreshDailyTaskLuck:SetActive(false)
        self._Btn_RefreshDailyTaskLuck:FindChild("Img_Bg/Node_Content"):SetActive(true)
        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = 3,
            [EnumDef.CommonBtnParam.MoneyCost] = Luckcost
        }
        self._Btn_RefTaskLuck:ResetSetting(setting)
    end
end

--  更新宝箱相关
def.method().UpdateChestState = function(self)
    self._DailyTaskDrawBox = game._CCalendarMan:GetDailyTaskDrawBox()
    self._DayReachCount = game._CCalendarMan:GetDayReachCount()
    self._WeekReachCount = game._CCalendarMan:GetWeekReachCount()

    local drawBoxMap = {}
    for _, tid in ipairs(self._DailyTaskDrawBox) do
        drawBoxMap[tid] = true
    end

    if self._DayReachCount >= 12 then   
        self._Btn_RefTaskLuck:MakeGray(true)
        GameUtil.SetButtonInteractable(self._Btn_RefreshDailyTaskLuck, false)
    else   
        self._Btn_RefTaskLuck:MakeGray(false)
        GameUtil.SetButtonInteractable(self._Btn_RefreshDailyTaskLuck, true)
    end
    -- 每天宝箱
    do
        GUI.SetText(self._Lab_QuestLiveness, tostring(self._DayReachCount .. "/" .. self._MaxQuestLiveness))
        self._ProBar_Quest.size = self._DayReachCount / self._MaxQuestLiveness
        
        -- TODO:处理每天宝箱的领取状态
        for i=1, self._MaxDayChestNum do
            local template = game._CCalendarMan:GetBoxTemplate(EBoxType.EBoxType_Day, i)
            local btn_chest = self._BtnTable_DayChest[i]
            local img_chest = self._ImgTable_DayChest[i]
            local bgImg_chest = self._OpenImgTable_DayChest[i]
            if template ~= nil and not IsNil(btn_chest) and not IsNil(img_chest) then
                local hasDraw = drawBoxMap[template.Id] == true -- 是否已领取
                img_chest:SetActive(not hasDraw)
                bgImg_chest:SetActive(hasDraw)
                local canGet = game._CCalendarMan:CanGetChestReward(1, i) -- 是否领取
                if canGet and not hasDraw then
                    GameUtil.PlayUISfx(PATH.UIFX_CALENDAR_LingQu, btn_chest, btn_chest, -1)
                else
                    GameUtil.StopUISfx(PATH.UIFX_CALENDAR_LingQu, btn_chest)
                end
            end
        end
    end
    -- 每周宝箱
    do
        local boxTemplate1 = game._CCalendarMan:GetBoxTemplate(EBoxType.EBoxType_Week, 1)
        if boxTemplate1 ~= nil then
            local WeekReachCount = nil
            if self._WeekReachCount > boxTemplate1.ReachCount then
                WeekReachCount = boxTemplate1.ReachCount
            else
                WeekReachCount = self._WeekReachCount
            end
            if WeekReachCount ~= nil then
                GUI.SetText(self._Lab_DayQuestCount, WeekReachCount .. "/" .. boxTemplate1.ReachCount)
            end

            local canGet = game._CCalendarMan:CanGetChestReward(EBoxType.EBoxType_Week, 1) -- 是否可领取
            local hasDraw = drawBoxMap[boxTemplate1.Id] == true -- 是否已领取
            if canGet == false then
                self._Img_DayQuestIcon:SetActive(true)
                self._Img_DayQuestIconOpen:SetActive(false)
            else
                if hasDraw then
                    self._Img_DayQuestIcon:SetActive(false)
                    self._Img_DayQuestIconOpen:SetActive(true)
                else
                    self._Img_DayQuestIcon:SetActive(true)
                    self._Img_DayQuestIconOpen:SetActive(false)
                end
            end
            local Btn_DayGoalReward = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_DayGoalReward")
            if canGet and not hasDraw then
                GameUtil.PlayUISfx(PATH.UIFX_DAILYTASK_LingQu, Btn_DayGoalReward, Btn_DayGoalReward, -1)
            else                
                GameUtil.StopUISfx(PATH.UIFX_DAILYTASK_LingQu, Btn_DayGoalReward)
            end
        end

        
        local boxTemplate2 = game._CCalendarMan:GetBoxTemplate(EBoxType.EBoxType_Week, 2)
        if boxTemplate2 ~= nil then
            GUI.SetText(self._Lab_WeekQuestCount, self._WeekReachCount .. "/" .. boxTemplate2.ReachCount)
            local canGet = game._CCalendarMan:CanGetChestReward(EBoxType.EBoxType_Week, 2) -- 是否领取
            local hasDraw = drawBoxMap[boxTemplate2.Id] == true -- 是否已领取

            if canGet == false then
                self._Img_WeekQuestIcon:SetActive(true)
                self._Img_WeekQuestIconOpen:SetActive(false)
            else
                if hasDraw then
                    self._Img_WeekQuestIcon:SetActive(false)
                    self._Img_WeekQuestIconOpen:SetActive(true)
                else
                    self._Img_WeekQuestIcon:SetActive(true)
                    self._Img_WeekQuestIconOpen:SetActive(false)
                end
            end
            local Btn_WeekGoalReward = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_WeekGoalReward")
            if canGet and not hasDraw then
                GameUtil.PlayUISfx(PATH.UIFX_DAILYTASK_LingQu, Btn_WeekGoalReward, Btn_WeekGoalReward, -1)
            else
                GameUtil.StopUISfx(PATH.UIFX_DAILYTASK_LingQu, Btn_WeekGoalReward)
            end
        end
    end
end

def.method("number", "=>", "table").GetTaskInfoByIndex = function(self, index)
    local taskInfo = nil
    for _, info in ipairs(self._DailyTaskInfo) do
        -- warn("taskId:", info.TaskId, "index:", info.Index, ", isProvide:", info.IsProvide)
        if info.Index + 1 == index then
            taskInfo = info
            break
        end
    end
    return taskInfo
end

-- 尝试获取宝箱奖励
def.method("number", "number").TryGetChestReward = function(self, chestType, index)
    local canGet = game._CCalendarMan:CanGetChestReward(chestType, index)
    local boxTemplate = game._CCalendarMan:GetBoxTemplate(chestType, index) -- 每日任务宝箱表Tid
    if boxTemplate == nil then return end
    local reward_template = GUITools.GetRewardList(boxTemplate.RewardId, true)
    if not canGet then
        -- 未达到次数
        -- game._GUIMan:ShowTipText(StringTable.Get(31801), false)
        
        if reward_template ~= nil and #reward_template > 0 then            
            if not reward_template[1].IsTokenMoney then
            -- if reward_template.ItemRelated.RewardItems[1] and reward_template.ItemRelated.RewardItems[1].Id > 0 then
                local RewardId = reward_template[1].Data.Id                
                CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL ,self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. index .."/Btn_Quest_Item_0"..index),TipPosition.FIX_POSITION) 
            else
                -- TODO("货币不是 Item了,统一UE时记得改！")
                local panelData = {}
                panelData = 
                {
                    _MoneyID = reward_template[1].Data.Id ,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. index - 1 .."/Btn_Quest_Item_0"..index-1) ,   
                }
                CItemTipMan.ShowMoneyTips(panelData)
            end 
        end
        return
    end

    local boxTid = boxTemplate.Id
    for _, tid in ipairs(self._DailyTaskDrawBox) do
        if tid == boxTid then
            -- 已领取
            -- game._GUIMan:ShowTipText(StringTable.Get(31800), false)
            if reward_template ~= nil then 
                if not reward_template[1].IsTokenMoney then
                -- if reward_template.ItemRelated.RewardItems[1] and reward_template.ItemRelated.RewardItems[1].Id > 0 then
                    local RewardId = reward_template[1].Data.Id
                    CItemTipMan.ShowItemTips(RewardId, TipsPopFrom.OTHER_PANEL ,self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. index .."/Btn_Quest_Item_0"..index),TipPosition.FIX_POSITION) 
                else
                    -- TODO("货币不是 Item了,统一UE时记得改！")
                    local panelData = {}
                    panelData = 
                    {
                        _MoneyID = reward_template[1].Data.Id ,
                        _TipPos = TipPosition.FIX_POSITION ,
                        _TargetObj = self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. index-1 .."/Btn_Quest_Item_0"..index-1) ,   
                    }
                    CItemTipMan.ShowMoneyTips(panelData)
                end 
            end
            return
        end
    end
    local Btn_Item = nil
    if chestType == EBoxType.EBoxType_Day then
        Btn_Item = self._Frame_Bottom:FindChild("Frame_QuestLiveness/Frame_Quest_0".. tostring(index) .."/Btn_Quest_Item_0".. tostring(index))
    elseif chestType == EBoxType.EBoxType_Week then
        if index == 1 then
            Btn_Item = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_DayGoalReward")
        elseif index == 2 then
            Btn_Item = self._Frame_Bottom:FindChild("Frame_WeekGoal/Btn_WeekGoalReward")
        end
    end
    -- if Btn_Item == nil then return end
    GameUtil.PlayUISfx(PATH.UIFX_WELFARE_Baoxiang_Baokai, Btn_Item, Btn_Item, -1)
    game._CCalendarMan:SendC2SDailyTaskDrawBox(boxTid)
end

-- 货币是否充足
def.method("number", "number", "=>", "boolean").IsMoneyEnough = function(self, moneyId, needNum)
    if moneyId <= 0 then return false end

    local moneyHave = game._HostPlayer:GetMoneyCountByType(moneyId)
    if moneyHave >= needNum then
        return true
    end
    return false
end

-- 获取当前运势刷新消耗数量
def.method("=>", "boolean", "string").GetCurLuckRefCost = function(self)
    local curRefTime = game._CCalendarMan:GetLuckRefTime()
    local cost = nil
    local IsHaveFreeCount = true    
    if curRefTime < self._FreeChangeLuckNum then   
        cost = string.format(StringTable.Get(31805), (curRefTime.."/"..self._FreeChangeLuckNum))
        IsHaveFreeCount = true
    else        
        
        cost = tostring(self._LuckRefCostList[curRefTime+1])
        if self._LuckRefCostList[curRefTime+1] == nil then
            -- 找不到下次消耗时，找最后一次的消耗
            cost = tostring(self._LuckRefCostList[#self._LuckRefCostList])
        end
        IsHaveFreeCount = false
    end
    return IsHaveFreeCount, cost
end

-- 获取当前任务刷新消耗数量
def.method("=>", "boolean", "string").GetCurQuestRefCost = function(self)
    local curRefTime = game._CCalendarMan:GetTaskRefTime()
    local IsHaveFreeCount = true
    local cost = nil    
    if curRefTime < self._FreeRefreshQuestNum then
        cost = string.format(StringTable.Get(31806), (curRefTime.."/"..self._FreeRefreshQuestNum))
        IsHaveFreeCount = true
    else        
        cost = tostring(self._QuestRefCostList[curRefTime+1])
        if self._QuestRefCostList[curRefTime+1] == nil then
            -- 找不到下次消耗时，找最后一次的消耗
            cost = tostring(self._QuestRefCostList[#self._QuestRefCostList])
        end
        IsHaveFreeCount = false
    end
    return IsHaveFreeCount, cost
end

CPageDailyTask.Commit()
return CPageDailyTask