local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local bit = require "bit"
local CPanelCalendar = Lplus.Extend(CPanelBase, 'CPanelCalendar')
local EWorldType = require "PB.Template".Map.EWorldType
local MapBasicConfig = require "Data.MapBasicConfig" 
-- local CPanelArenaEnter = require"GUI.CPanelArenaEnter"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CQuest = Lplus.ForwardDeclare("CQuest")
local CTeamMan = require "Team.CTeamMan"

local def = CPanelCalendar.define
 
def.field('userdata')._Lab_Liveness = nil
-- def.field('userdata')._List_AchivementMenu = nil
-- def.field('userdata')._Frame_Gift = nil
def.field("userdata")._Front = nil
-- def.field('userdata')._Lab_LvValues = nil
-- def.field('userdata')._Lab_PeopleValues = nil

def.field("table")._RewardsData = BlankTable
def.field("table")._Open_Reward_tips = BlankTable

def.field('userdata')._CurrentSelectImg = nil
-- def.field('userdata')._Img_Open = nil

----------------------new-----------------------
def.field(CFrameCurrency)._Frame_Money = nil
def.field("userdata")._RdoGroup_Main = nil
def.field('userdata')._Frame_Activity = nil
def.field('userdata')._Frame_TimesActivity = nil
def.field('userdata')._Frame_Quest = nil
def.field('userdata')._Frame_ActivityRightDesc = nil    -- 活动描述
-- def.field('userdata')._List_ActivityMenu = nil
def.field('userdata')._List_TimesActivityMenu = nil
def.field('userdata')._List_ActivityMask = nil

def.field('userdata')._Lab_PeopleNum = nil
def.field('userdata')._Lab_ActivityName = nil
def.field('userdata')._Lab_ContentValues = nil
def.field('userdata')._Lab_NumberValues = nil
def.field('userdata')._Lab_TimeLvTitle = nil
def.field('userdata')._Lab_TimeLvValues = nil
def.field('userdata')._FxPoint = nil        -- 选中特效缓存

def.field("table")._ActivityContent = BlankTable         -- 日常活动表
def.field("userdata")._Lab_RewardTips = nil
def.field("userdata")._List_Reward = nil
def.field('userdata')._Pro_Liveness = nil
def.field('userdata')._Btn_Join = nil               --参加按钮
def.field('userdata')._Btn_GiveUp = nil              --任务放弃按钮
def.field('userdata')._Btn_Proceed = nil             --任务前往按钮
def.field("userdata")._FrameTopTabs = nil 

def.field('number')._CurType = -1     --当前打开的分页签
def.field('number')._CurActivityIdx = 0     --当前打开的活动
def.field('table')._CurCalendar = BlankTable --当前打开的活动内容
def.field('table')._ScriptCalendar = BlankTable --脚本日历
def.field("table")._QusetModels = BlankTable           -- 任务数据
def.field('number')._CurActivityState = 0     --当前活动状态
-- 面板类型
local EPageType =
{
    Dungeon = 0,        -- 副本
    Arena = 1,          -- 玩家竞技
    GuildActivity = 2,  -- 公会活动
    DailyActivity = 3,  -- 日常活动
}

local ActivityState = 
{
    Open = 0,
    UnOpened = 1 ,
    NoTeam = 2,
    NoGuild = 3,
    LevelNotEnough = 4,
    TimeNotEnough = 5,
    NoCount = 6,
}


local instance = nil
def.static('=>', CPanelCalendar).Instance = function ()
	if not instance then
        instance = CPanelCalendar()
        instance._PrefabPath = PATH.UI_Calendar
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        
        instance:SetupSortingParam()
	end
	return instance
end

--LivenessValue 和 分页  从小到大排序
local function sortfunction(value1, value2)
	if value1 ~= value2 then
		return value1 > value2
	end	
	return true
end

local function sortLivenessValue(value1, value2)
	if value1.LivenessValue ~= value2.LivenessValue then
		return value1.LivenessValue < value2.LivenessValue
	end	
	return true
end

def.override().OnCreate = function(self)
    self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    self._RdoGroup_Main = self:GetUIObject("Frame_TopTabs")
    self._Frame_Activity = self:GetUIObject('Frame_Activity')
    self._Frame_TimesActivity = self:GetUIObject('Frame_TimesActivity')
    self._Frame_Quest = self:GetUIObject('Frame_Quest')
    self._Frame_ActivityRightDesc = self:GetUIObject('Frame_ActivityRightDesc')
    -- self._List_ActivityMenu = self:GetUIObject('List_ActivityMenu'):GetComponent(ClassType.GNewListLoop)
    self._List_TimesActivityMenu = self:GetUIObject('List_TimesActivityMenu'):GetComponent(ClassType.GNewListLoop)
    self._Lab_ContentValues = self:GetUIObject('Lab_ContentValues')
    self._Lab_TimeLvTitle = self:GetUIObject('Lab_TimeTips')
    self._Lab_TimeLvValues = self:GetUIObject('Lab_TimeLvValues')
    self._Lab_PeopleNum = self:GetUIObject('Lab_PeopleNum')
    self._Lab_ActivityName = self:GetUIObject('Lab_ActivityName')
    self._Lab_NumberValues = self:GetUIObject('Lab_NumberValues')
    self._FxPoint = self:GetUIObject('Fx_Point')    

    self._Lab_Liveness = self:GetUIObject('Lab_Liveness')
    self._List_Reward = self:GetUIObject("List_Reward")  -- 活动对应奖励列表
    self._Lab_RewardTips = self:GetUIObject("Lab_RewardTips")

    self._Btn_Join = self:GetUIObject("Btn_Jion")
    self._Btn_GiveUp = self:GetUIObject("Btn_GiveUp")
    self._Btn_Proceed = self:GetUIObject("Btn_Proceed")

    self._FrameTopTabs = self:GetUIObject("Frame_TopTabs")
    --GameUtil.LayoutTopTabs(self._FrameTopTabs)

    self._Frame_TimesActivity:SetActive(true)
    self._Frame_Quest:SetActive(false)
end

def.override("dynamic").OnData = function(self,data)
    self._HelpUrlType = HelpPageUrlType.Activity
    if data == nil then
        self._CurActivityIdx = 1
        self:ShowFrame(EPageType.Dungeon)  
    elseif tonumber(data) > 0 then         
        local adventureGuideData = game._CCalendarMan:GetCalendarDataByID(tonumber(data))   
        self:InitActivityContent(adventureGuideData._Data.TabType)

        GUI.SetGroupToggleOn(self._FrameTopTabs, adventureGuideData._Data.TabType + 2)

        for i,v in ipairs(self._ActivityContent) do
            if v._Data.Id == adventureGuideData._Data.Id then			
                self._CurActivityIdx = i
                self:ShowFrame(v._Data.TabType)
            end
        end      
    end
    self:UpdateCalendarToggleRedPoint()
end

def.method().RefrashCalendar = function(self)    
    self:ShowFrame(self._CurType)
    if self._CurType == EPageType.Dungeon or
    self._CurType == EPageType.Arena or
    self._CurType == EPageType.GuildActivity or
    self._CurType == EPageType.DailyActivity then
        self:ShowActivityByType(self._CurType, self._CurActivityIdx)
    end
end


def.override('string').OnClick = function(self, id) 
    CPanelBase.OnClick(self,id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
		return  
    elseif id == 'Btn_Back' then
        game._GUIMan:Close("CPanelCalendar")
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == 'Btn_Jion' then 
        if self._CurActivityState == ActivityState.Open then
            local temData = self._ActivityContent[self._CurActivityIdx]
            game._CCalendarMan:OpenPlayByActivityInfo(temData)            
        elseif self._CurActivityState == ActivityState.UnOpened then
            local temData = self._ActivityContent[self._CurActivityIdx]            
            if game._CFunctionMan:IsUnlockByFunTid(temData._Data.FunId) == false then
                game._CGuideMan:OnShowTipByFunUnlockConditions(0, temData._Data.FunId)
                -- game._GUIMan:ShowTipText(StringTable.Get(19496), false)
            elseif temData._IsOpenByTime == false then
                game._GUIMan:ShowTipText(StringTable.Get(19469), false)
            end            
        elseif self._CurActivityState == ActivityState.NoGuild then
            -- game._GUIMan:ShowTipText(StringTable.Get(19471), false)
            -- 未参加公会直接打开开启公会界面
            if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Guild) then
                game._GuildMan:RequestAllGuildInfo()
                game._GUIMan:Close("CPanelCalendar")
            else
                game._CGuideMan:OnShowTipByFunUnlockConditions(1, EnumDef.EGuideTriggerFunTag.Guild)
            end

        -- elseif self._CurActivityState == ActivityState.NoTeam then
            -- game._GUIMan:ShowTipText(StringTable.Get(19354), false)
        elseif self._CurActivityState == ActivityState.LevelNotEnough then
            game._GUIMan:ShowTipText(StringTable.Get(19470), false)
        elseif self._CurActivityState == ActivityState.NoCount then
            game._GUIMan:ShowTipText(StringTable.Get(20908), false)
        else
            warn("ActivityState = ", self._CurActivityState)
        end
    elseif id == 'Btn_Proceed' then
        local temData = self._ActivityContent[self._CurActivityIdx]
        if temData._Data.Id == 11 then
            --如果是赏金任务，在队中 则跟随
            if CTeamMan.Instance():InTeam() and not CTeamMan.Instance():IsTeamLeader() then
                CTeamMan.Instance():FollowLeader(true)
            else
                --如果是赏金任务，是队长则开始任务
                self._QusetModels:DoShortcut()
            end
        elseif temData._Data.Id == 16 then
            self._QusetModels:DoShortcut()
        end

        game._GUIMan:Close("CPanelCalendar")
    elseif id == 'Btn_GiveUp' then
        CQuest.Instance():DoGiveUpQuest(self._QusetModels.Id)
        game._GUIMan:Close("CPanelCalendar")
    else
        warn("OnClick id == "..id)
    end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
    self._CurActivityIdx = 1
    if id == "Rdo_1" and checked then
        self:ShowFrame(EPageType.Dungeon)
    elseif id == "Rdo_2" and checked then 
        self:ShowFrame(EPageType.Arena)
    elseif id == "Rdo_3" and checked then
        self:ShowFrame(EPageType.GuildActivity)
    elseif id == "Rdo_4" and checked then
        self:ShowFrame(EPageType.DailyActivity)
    end 
    -- self._FxPoint:SetActive(false)
    self:UpdateCalendarToggleRedPoint()
end

-- 刷新冒险指南界面Toggle红点
def.method().UpdateCalendarToggleRedPoint = function(self)    
    self:GetUIObject("Img_RedPoint_Dungeon"):SetActive(game._CCalendarMan:GetCalendarRedPointStateByType(EPageType.Dungeon))
    self:GetUIObject("Img_RedPoint_Arena"):SetActive(game._CCalendarMan:GetCalendarRedPointStateByType(EPageType.Arena))
    self:GetUIObject("Img_RedPoint_Guild"):SetActive(game._CCalendarMan:GetCalendarRedPointStateByType(EPageType.GuildActivity))
    self:GetUIObject("Img_RedPoint_DailyCalendar"):SetActive(game._CCalendarMan:GetCalendarRedPointStateByType(EPageType.DailyActivity))
    -- self:GetActivityReward() 
    game._CCalendarMan:MainRedPointState()
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_TimesActivityMenu" then
        self:InitActivityShow(item, index + 1)
    elseif string.find(id, "List_Reward") then
		-- 统一初始化奖励物品，模块的类必须有_RewardData
		local rewardsData = self._RewardsData
		if rewardsData == nil then return end
		local reward = self._RewardsData[index+1]
        if reward ~= nil then
            if reward.IsTokenMoney then
                IconTools.InitTokenMoneyIcon(item, reward.Data.Id, reward.Data.Count)
            else
                IconTools.InitItemIconNew(item, reward.Data.Id, { [EItemIconTag.Number] = reward.Data.Count })
            end
        end     

    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_TimesActivityMenu"  then
        self._CurCalendar = self._ActivityContent[idx]  
        self._CurActivityIdx = idx

        -- if self._CurType == EPageType.Activity and self._List_ActivityMenu ~= nil then   
        --     self._List_ActivityMenu:SetSelection(index)	
        --     -- GUITools.GetChild(item , 1):SetActive(true)
        -- else
        if self._List_TimesActivityMenu ~= nil then
            self._List_TimesActivityMenu:SetSelection(index)	
            -- GUITools.GetChild(item , 1):SetActive(true)
        end       
        local Img_Select = GUITools.GetChild(item , 1)
        if self._FxPoint ~= nil then
            self._FxPoint:SetParent(Img_Select)
            self._FxPoint:SetActive(true)
            self._FxPoint.localPosition = Vector3.one 
        end   
        self:CalendarDesc(self._CurCalendar, index + 1)
    elseif string.find(id, "List_Reward") then
		-- 奖励列表
		local rewardData = self._RewardsData[idx]
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

def.method("number").ShowFrame = function (self, destType)
    local originType = self._CurType
    if destType == originType then return end
    self._CurType = destType
    self:InitActivityContent(self._CurType)
    if self._CurType == EPageType.Dungeon or
    self._CurType == EPageType.Arena or
    self._CurType == EPageType.GuildActivity or
    self._CurType == EPageType.DailyActivity then
        self:ShowActivityByType(self._CurType, self._CurActivityIdx)
    end
end

--初始化日常活动显示
def.method("userdata","number").InitActivityShow = function(self,item, nIndex)
    local temData = self._ActivityContent[nIndex]
    -- self._ScriptCalendar = GameUtil.GetAllTid("ScriptCalendar")
    -- warn("temdata == ", temData._Data.activityName)
    if temData ~= nil then
        local TextType = ClassType.Text
        local Img_Icon = GUITools.GetChild(item , 0)        
        local Lab_Done = GUITools.GetChild(item , 2)
        local Btn_Join = GUITools.GetChild(item , 3)
        local Lab_PlayPos = GUITools.GetChild(item , 6) --玩法定位
        local Lab_CalendarName = GUITools.GetChild(item , 7)
        local Img_TimesBg = GUITools.GetChild(item , 8)
        local Lab_CalendarTimes = GUITools.GetChild(item , 9)
        local Lab_Enhausted=  GUITools.GetChild(item , 10)   -- 次数用尽
        local Img_LevelLockBg =  GUITools.GetChild(item , 11)
        local Lab_OpenLevel =  GUITools.GetChild(item , 12)
        local Img_RedPoint =  GUITools.GetChild(item , 13)
        Lab_Enhausted:SetActive(false)    -- 暂时没用到   Lx
        -- Btn_Join:SetActive(false)  
        GUITools.GetChild(item , 1):SetActive(false)        
        local Level = temData._Data.OpenLevel

        -- warn("temdata == ", temData._Data.Name)
        GUI.SetText(Lab_CalendarName, temData._Data.Name)            
        local PlayPosStr = nil
        if temData._Data.IsSingle == "True" and temData._Data.IsTeam == "True" then
            PlayPosStr = StringTable.Get(19497) .. "/" .. StringTable.Get(19498)
        elseif temData._Data.IsSingle == "True" then
            PlayPosStr = StringTable.Get(19497)
        elseif temData._Data.IsTeam == "True" then
            PlayPosStr = StringTable.Get(19498)
        end
        if PlayPosStr ~= nil then
            GUI.SetText(Lab_PlayPos, PlayPosStr)
        end

        if temData._Data.IconPath ~= "" then
            GUITools.SetSprite(Img_Icon, temData._Data.IconPath)
        end
        
        -- 冒险指南开启使用（ZZY：永久显示）
        if temData._Data.DateDisplayText == "" then
            Img_TimesBg:SetActive(false)
        else
            Img_TimesBg:SetActive(true)
            
            -- local ActivityNumStr = nil
            -- ActivityNumStr = (temData._Data.ActivityNum - temData._CurValue) .. "/" .. temData._Data.ActivityNum

            local NumValurStr = nil
            if temData._Data.ShowNumType == 0 then
                if temData._PlayMaxNum <= 0 then
                    NumValurStr = StringTable.Get(19468)
                else
                    NumValurStr = temData._PlayCurNum.."/"..temData._PlayMaxNum
                end
            elseif temData._Data.ShowNumType == 1 then
                NumValurStr = temData._Data.ShowNumString
            end
            GUI.SetText(Lab_CalendarTimes, string.format(StringTable.Get(19449), NumValurStr))
        end       
        if temData._IsOpen and temData._IsOpenByTime then
            -- if temData._Data.TabType == 0 then
            --     if (temData._CurValue * temData._Data.Liveness) < (temData._Data.ActivityNum * temData._Data.Liveness) then
            --         Img_RedPoint:SetActive(true)
            --     else
            --         Img_RedPoint:SetActive(false)
            --     end
            -- end
            -- warn("遗迹遗迹遗迹遗迹 777799999===>>>", temData._Data.Id, temData._CurValue, game._CCalendarMan:GetActivityRedPointByTemData(temData))
            Img_RedPoint:SetActive(game._CCalendarMan:GetActivityRedPointByTemData(temData))
        else
            if Img_RedPoint ~= nil then
                Img_RedPoint:SetActive(false)
            end
        end

        -- warn("----lidaming Level == ", temData._Data.Name, temData._IsOpen, game._CFunctionMan:IsUnlockByFunTid(temData._Data.FunId), temData._IsOpenByTime, temData._Data.FunId)
        if game._CFunctionMan:IsUnlockByFunTid(temData._Data.FunId) == false then
            Img_LevelLockBg:SetActive(true)
            GUI.SetText(Lab_OpenLevel, StringTable.Get(19496))  
            Img_TimesBg:SetActive(false)
        elseif temData._IsOpenByTime == false then
            Img_LevelLockBg:SetActive(true)
            GUI.SetText(Lab_OpenLevel, StringTable.Get(19469)) 
            Img_TimesBg:SetActive(false)   
        else
            Img_LevelLockBg:SetActive(false)
            Lab_Done:SetActive(false)
            Img_TimesBg:SetActive(true)
        end
        
    end
end

--显示具体活动列表
def.method("number", "number").ShowActivityByType = function(self, curType, selectIndex)    
    self._CurActivityIdx = selectIndex
    self._CurCalendar = self._ActivityContent[self._CurActivityIdx] 
    self:CalendarDesc(self._CurCalendar, self._CurActivityIdx)
    if self._List_TimesActivityMenu ~= nil then
        self._List_TimesActivityMenu: SetItemCount(#self._ActivityContent)
        self._List_TimesActivityMenu:SetSelection(self._CurActivityIdx - 1)
        self._List_TimesActivityMenu:ScrollToStep(self._CurActivityIdx - 1)   
        local item = self._List_TimesActivityMenu:GetItem(self._CurActivityIdx - 1)
        local Img_Select = GUITools.GetChild(item , 1)
        self._List_ActivityMask = self:GetUIObject('List_Activity1')
        if self._FxPoint ~= nil and Img_Select ~= nil then
            -- GameUtil.PlayUISfxClipped(PATH.UIFX_CALENDAR_XuanDing, self._FxPoint, self._FxPoint, self._List_ActivityMask)
            self._FxPoint:SetParent(Img_Select)
            self._FxPoint:SetActive(true)
            self._FxPoint.localPosition = Vector3.one  
        end
    end        
    
end

-- 不需要判断等级和公会...  lidaming 2018/11/12
-- local function sort_func_by_open_level(a, b)
--     if a._Data.OpenLevel ~= b._Data.OpenLevel then
--         -- 根据解锁等级从小到大
--         return a._Data.OpenLevel < b._Data.OpenLevel
--     end
--     return false
-- end

local function sort_func_by_sortindex(a, b)
    if a._Data.SortIndex ~= b._Data.SortIndex then
        -- 根据解锁等级从小到大
        return a._Data.SortIndex < b._Data.SortIndex
    end
    return false
end

-- 初始化冒险日历列表
def.method("number").InitActivityContent = function(self, curType)
    self._ActivityContent = {}
    local not_complete_list = {}
    -- local complete_list = {}
    local lock_by_time_list = {}
    -- local lock_by_level_list = {}
    local activity_sort_by_sortindex = {}
    local SpecialFunHideCheck = function(id)
        if id == 14 and game._IsHideGuildBattle then
            return false
        end
        return true
    end
    for _, v in ipairs(game._CCalendarMan:GetAllCalendarData()) do
        if v._Data.TabType == curType then
            -- 属于冒险指南
            -- 开启等级为 -1  隐藏活动
            if v._Data.OpenLevel ~= -1 and SpecialFunHideCheck(v._Data.Id) then
                if v._IsOpen then
                    if not v._IsOpenByTime then
                        table.insert(lock_by_time_list, v)
                    else
                        table.insert(not_complete_list, v)
                    end
                else
                    if not v._IsOpenByTime then
                        table.insert(lock_by_time_list, v)
                    else
                        table.insert(activity_sort_by_sortindex, v)
                    end
                end
            end
        end
    end
    table.sort(not_complete_list, sort_func_by_sortindex)
    -- table.sort(complete_list, sort_func_by_open_level)
    table.sort(lock_by_time_list, sort_func_by_sortindex)
    -- table.sort(lock_by_level_list, sort_func_by_open_level)
    table.sort(activity_sort_by_sortindex, sort_func_by_sortindex)

    local all_activtiy_list = {}
    -- 未完成的排最前
    for _, data in ipairs(not_complete_list) do
        table.insert(all_activtiy_list, data)
    end
    -- 未到活动时间的排中间
    for _, data in ipairs(lock_by_time_list) do
        table.insert(all_activtiy_list, data)
    end
    -- -- 未到等级解锁的排后面
    -- for _, data in ipairs(lock_by_level_list) do
    --     table.insert(all_activtiy_list, data)
    -- end
    -- -- 已完成的排最后
    -- for _, data in ipairs(complete_list) do
    --     table.insert(all_activtiy_list, data)
    -- end

    -- 未开启的排最后
    for _, data in ipairs(activity_sort_by_sortindex) do
        table.insert(all_activtiy_list, data)
    end
    self._ActivityContent = all_activtiy_list
end

-- 单个活动描述信息
def.method("table","number").CalendarDesc = function(self , DescData, nIndex)
    if DescData == nil then warn("DescData = nil") return end
    local _openTime = ""
    local _openLevel = 0
    local _remarks = DescData._Data.Remarks
    self._QusetModels = {}
    self._Btn_Join:SetActive(true)
    self._Btn_Proceed:SetActive(false)
    self._Btn_GiveUp:SetActive(false)
    GUI.SetText(self._Lab_ActivityName, tostring(DescData._Data.Name))    
    GUI.SetText(self._Lab_ContentValues, tostring(_remarks))     -- luxing:需要剧情配，暂时不显示内容。
    -- warn("lidaming --->> DescData._Data = ", DescData._Data.Name, DescData._CurValue, DescData._PlayCurNum)
    -- GUITools.SetSprite(self._Img_ActivityIcon, DescData._Data.IconPath2)    
    -- if self._CurType == EPageType.Activity then  
    --     GUI.SetText(self._Lab_TimeLvTitle, StringTable.Get(19455))
    --     GUI.SetText(self._Lab_TimeLvValues, (DescData._CurValue * DescData._Data.Liveness.."/"..DescData._Data.ActivityNum * DescData._Data.Liveness))
    -- elseif self._CurType == EPageType.TimesActivity then
    --     GUI.SetText(self._Lab_TimeLvTitle, StringTable.Get(19494))
    --     GUI.SetText(self._Lab_TimeLvValues, tostring(DescData._Data.DateDisplayText))
    -- end  

    GUI.SetText(self._Lab_TimeLvTitle, StringTable.Get(19494))
    GUI.SetText(self._Lab_TimeLvValues, tostring(DescData._Data.DateDisplayText))
    GUI.SetText(self._Lab_PeopleNum, tostring(DescData._Data.PeopleNum))
    
    if not DescData._IsOpen or not DescData._IsOpenByTime then
        -- Btn_Join:SetActive(false)  
        -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_Bg"), true)    
        GUITools.SetBtnGray(self._Btn_Join, true)
        self._CurActivityState = ActivityState.UnOpened                 
    else
        --[[  --不判断公会...  lidaming 2018/11/12
        if not game._GuildMan:IsHostInGuild() and
        (DescData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildDefend or
        DescData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildDungeon or
        DescData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildBattle or
        DescData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildQuest or
        DescData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildConvoy) then 
            -- Btn_Join:SetActive(false)
            GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_BtnBg"), true)
            self._CurActivityState = ActivityState.NoGuild
            return
        end
        ]]
        -- Btn_Join:SetActive(true)
        -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_Bg"), false)   
        GUITools.SetBtnGray(self._Btn_Join, false)
        self._CurActivityState = ActivityState.Open    
    end
    local NumValurStr = nil
    if DescData._Data.ShowNumType == 0 then
        if DescData._PlayMaxNum <= 0 then
            NumValurStr = StringTable.Get(19468)
        else
            NumValurStr = DescData._PlayCurNum.."/"..DescData._PlayMaxNum
        end
    elseif DescData._Data.ShowNumType == 1 then
        NumValurStr = DescData._Data.ShowNumString
    end
    -- local ActivityNumStr = nil
    -- ActivityNumStr = (DescData._Data.ActivityNum - DescData._CurValue) .. "/" .. DescData._Data.ActivityNum
    GUI.SetText(self._Lab_NumberValues, NumValurStr)
    -- 默认显示为冒险指南模版中的值。
    -- local level = DescData._Data.OpenLevel
    local RewardID = DescData._Data.ShowRewardId
    local PlayInfo = game._CCalendarMan:GetPlayInfoByActivityID(DescData._Data.Id)
    local CurPlayId = 0  
    if PlayInfo ~= nil then
        CurPlayId = PlayInfo.playId
        -- RewardID = PlayInfo.rewardId
    end
    self._RewardsData = {}
    -- 单个活动奖励列表
    if RewardID ~= nil then
        self._RewardsData = GUITools.GetRewardList(RewardID, false)
         
        if self._List_Reward ~= nil and #self._RewardsData > 0 then
            -- warn("self._RewardsData == ", #self._RewardsData)
            self._Lab_RewardTips:SetActive(true)
            self._List_Reward:GetComponent(ClassType.GNewList):SetItemCount(#self._RewardsData)
        else
            self._Lab_RewardTips:SetActive(false)
        end
    else
        self._Lab_RewardTips:SetActive(false)
    end

    if DescData._Data.Id == 11 then  -- 赏金任务
        local CyclicQuestData = CQuest.Instance():GetCyclicQuestData()
        local TotalNum = 0
        local FinishNum = 0
        local Group = CQuest.Instance()._CountGroupsQuestData[tonumber(CElementData.GetSpecialIdTemplate(543).Value)]
        if Group ~= nil then
            FinishNum = Group._Count
        end        
        local template = CElementData.GetTemplate("CountGroup",tonumber(CElementData.GetSpecialIdTemplate(543).Value))
        if template ~= nil then
            TotalNum = template.MaxCount
        end
        -- warn(" lidaming =============>>> Reward",CyclicQuestData._CyclicQuestID,FinishNum,TotalNum )
        if CyclicQuestData._CyclicQuestID ~= 0 then
            self._QusetModels = CQuest.Instance():GetInProgressQuestModel(CyclicQuestData._CyclicQuestID)
            self._Btn_Join:SetActive(false)
            self._Btn_Proceed:SetActive(true)
            self._Btn_GiveUp:SetActive(true)
        else
            if FinishNum >= TotalNum and TotalNum ~= 0 then
                -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_Bg"), true)    
                -- GUITools.SetBtnGray(self._Btn_Join, true)
                self._CurActivityState = ActivityState.NoCount
            else                 
                local RewardService = CElementData.GetServiceTemplate(810)
                if game._HostPlayer._OpHdl:JudgeServiceOption(RewardService) then
                    self._Btn_Join:SetActive(true)
                    -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_BtnBg"), false)    
                    -- GUITools.SetBtnGray(self._Btn_Join, false)
                    
                end
            end

            self._Btn_Proceed:SetActive(false)
            self._Btn_GiveUp:SetActive(false)
        end

    elseif DescData._Data.Id == 16 then  -- 公会任务
        --查找工会任务
        local list = CQuest.Instance():GetQuestsRecieved()
        for _,v in pairs(CQuest.Instance()._InProgressQuestMap) do
            if v and (CQuest.Instance():IsQuestInProgress(v.Id) or CQuest.Instance():IsQuestReady(v.Id)) then
                -- warn("v:GetTemplate().Type ==>>>", v:GetTemplate().Type)
                if v:GetTemplate().Type == require "PB.Template".Quest.QuestType.Activity then
                    self._QusetModels = v
                    break
                end
            end
        end

        local FinishNum = 0
        local TotalNum = 0

        local Group = CQuest.Instance()._CountGroupsQuestData[tonumber(CElementData.GetSpecialIdTemplate(435).Value)]
        if Group ~= nil then
            FinishNum = Group._Count
        end
        
        local template = CElementData.GetTemplate("CountGroup",tonumber(CElementData.GetSpecialIdTemplate(435).Value))
        if template ~= nil then
            TotalNum = template.MaxCount
        end
        -- warn( "lidaming =============>>> Activity",FinishNum,TotalNum, self._QusetModels.Id)
        --如果没有进行中的活动任务（工会）
        if self._QusetModels == nil or self._QusetModels.Id == nil then
            local ActivityService = CElementData.GetServiceTemplate(790)
            if game._GuildMan:IsHostInGuild() and game._HostPlayer._OpHdl:JudgeServiceOption(ActivityService) then
                self._Btn_Join:SetActive(true)
                if FinishNum >= TotalNum and TotalNum ~= 0 then
                    -- self._Btn_Join:SetActive(false)
                    -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_Bg"), true)    
                    -- GUITools.SetBtnGray(self._Btn_Join, true)
                    self._CurActivityState = ActivityState.NoCount
                else
                    -- self._Btn_Join:SetActive(true)
                    -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_Bg"), false)
                    -- GUITools.SetBtnGray(self._Btn_Join, false)    
                end
            else
                self._Btn_Join:SetActive(true)
                -- GameUtil.MakeImageGray(self._Btn_Join:FindChild("Img_Bg"), false)  
                -- GUITools.SetBtnGray(self._Btn_Join, false)  
            end
            self._Btn_GiveUp:SetActive(false)
            self._Btn_Proceed:SetActive(false)
        else
            self._Btn_Join:SetActive(false)
            self._Btn_GiveUp:SetActive(true)
            self._Btn_Proceed:SetActive(true)
        end       

    end

end

def.override().OnHide = function(self)
    -- 隐藏时把当前存储的状态清空
    self._Frame_TimesActivity:SetActive(false)
    if self._FxPoint ~= nil then
        -- GameUtil.StopUISfx(PATH.UIFX_CALENDAR_XuanDing, self._FxPoint)
    end
end

def.override().OnDestroy = function(self)
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
    end
    self._CurType = -1
    self._CurCalendar = {}
    self._CurActivityIdx = 0
    self._ScriptCalendar = {}
    self._ActivityContent = nil
    -- self._ActivityValue = nil
    self._RdoGroup_Main = nil
    self._Frame_Activity = nil
    self._Frame_TimesActivity = nil
    self._Frame_Quest = nil
    self._Frame_ActivityRightDesc = nil    -- 活动描述
    -- self._List_ActivityMenu = nil
    self._List_TimesActivityMenu = nil
    self._Lab_PeopleNum = nil
    self._Lab_ActivityName = nil
    self._Lab_ContentValues = nil
    self._Lab_NumberValues = nil
    self._Lab_TimeLvTitle = nil
    self._Lab_TimeLvValues = nil
    self._Lab_RewardTips = nil
    self._List_Reward = nil
    self._FxPoint = nil
    self._List_ActivityMask = nil
    self._QusetModels = {}
    self._CurActivityState = 0
    self._FrameTopTabs = nil 
end

CPanelCalendar.Commit()
return CPanelCalendar