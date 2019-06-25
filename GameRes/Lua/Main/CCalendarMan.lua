--------------------------------------------
-----------新版冒险指南数据处理
------- 2018/8/13    lidaming
--------------------------------------------


local Lplus = require "Lplus"
local CCalendarMan = Lplus.Class("CCalendarMan")
local def = CCalendarMan.define
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local NotifyActivityEvent = require "Events.NotifyActivityEvent"
local PBHelper = require "Network.PBHelper"
local EBoxType = require "PB.Template".DailyTaskBox.EBoxType
local CQuestNavigation = require"Quest.CQuestNavigation"
local CPanelCalendar = require "GUI.CPanelCalendar"
local CQuest = require "Quest.CQuest"

def.field("table")._CalendarDataTable = BlankTable
def.field("table")._OpenTimeByPlayIdTable = BlankTable
def.field("number")._CurrentActivityValue = 0
def.field("table")._ActivityGainRewardTable = BlankTable
def.field("table")._TaskDayChestTemplateTable = BlankTable
def.field("table")._TaskWeekChestTemplateTable = BlankTable
def.field("boolean")._IsQuestFinish = false
local GuildBFApplyScriptCalendarID = 18
def.static("=>", CCalendarMan).new = function()
    local obj = CCalendarMan()
	return obj
end

local MapType = 
{
	REGION = 0,
	WORLD = 1,}

local function sort_func(value1,value2)
    return value1.openLevel > value2.openLevel
end

--缓存所有冒险指南数据
def.method().LoadAllCalendarData = function(self)
    self._CalendarDataTable = {}
	local cfgPath = _G.ConfigsDir.."AdventureGuideBasicInfo.lua"
    local allInfo = _G.ReadConfigTable(cfgPath)
	if allInfo == nil then return end
	for _,v in pairs(allInfo) do
		if v ~= nil then
			self._CalendarDataTable[#self._CalendarDataTable + 1] =
			{
				_Data = v,				--模板数据
				_IsOpen = true,			--是否开启(根据模版数据)
				-- _IsOpenByLevel = true, 	--是否根据等级开启
				_IsOpenByTime = true, 	--是否根据时间开启
				_CurValue = 0,			--当前已经获取活跃度次数
				_MaxValue = 0,			--最大获取活跃度次数
				_PlayCurNum = 0,		--玩法当前次数
				_PlayMaxNum = 0,		--玩法最大次数
				_CalendarId = 0,		--对应活动日历ID
			}

			if string.len(v.DateDisplayText) > 0 and string.len(v.PlayID) then
				local strPlayIds = string.split(v.PlayID, "*")
				if strPlayIds ~= nil then
					for i=1, #strPlayIds do
						local keyStr = strPlayIds[i]
						self._OpenTimeByPlayIdTable[keyStr] = v.DateDisplayText
					end
				end
			end				
		else
			warn("冒险指南数据错误ID："..v)
		end
	end
	
	_G.Unrequire(cfgPath)

	self._TaskDayChestTemplateTable = {}
	self._TaskWeekChestTemplateTable = {}
    local allTid = GameUtil.GetAllTid("DailyTaskBox")
    for _, tid in ipairs(allTid) do
        local template = CElementData.GetTemplate("DailyTaskBox", tid)
        if template.BoxType == EBoxType.EBoxType_Day then
            table.insert(self._TaskDayChestTemplateTable, template)
        elseif template.BoxType == EBoxType.EBoxType_Week then
            table.insert(self._TaskWeekChestTemplateTable, template)
        end
    end
    -- 按达成数量从小到大排序
    local function sortFunc(a, b)
        if a.ReachCount ~= b.ReachCount then
            return a.ReachCount < b.ReachCount
        end
        return false
    end
    table.sort(self._TaskDayChestTemplateTable, sortFunc)
    table.sort(self._TaskWeekChestTemplateTable, sortFunc)
end

--获取开启时间
def.method('number', '=>', 'string').GetOpenTimeByPlayId = function(self, playId)
	return self._OpenTimeByPlayIdTable[tostring(playId)] or StringTable.Get(22028)
end

-- 发送活动事件
def.method("dynamic").SendActivityEvent = function(self, data)
	local event = NotifyActivityEvent()
	CGame.EventManager:raiseEvent(data, event)
end

--------------------------S2C-----------------------------

--上线 or 更新冒险指南数据
def.method("table", "boolean").UpdateCalendarDataState = function(self, data, is_get)
	if data == nil then return end

	--Open Close doesnt set this value
	if is_get or #data.adventureGuideDatas <= 0 then
		self._CurrentActivityValue = data.totalLiveness
		self._ActivityGainRewardTable = data.gainRewardList
--	else
--		warn("*** "..#data.adventureGuideDatas)
	end
--	warn("-----------------S2C--------------- self._CurrentActivityValue ", self._CurrentActivityValue)

	for _,v in pairs(self._CalendarDataTable) do
		for _,k in pairs(data.adventureGuideDatas) do
			if v._Data.Id == k.TId then
				-- warn("lidaming ------updateCalendarState----->>>", v._Data.Id, v._Data.Name, k.isActivity, k.CalendarId)		
				v._IsOpenByTime = k.isActivity	
				v._CalendarId = k.CalendarId
				
				if game._CFunctionMan:IsUnlockByFunTid(v._Data.FunId) then
					v._IsOpen = true
				else
					v._IsOpen = false
				end		
				break
			end
		end

		for _,k in pairs(data.adventureGuideCount) do
			if v._Data.Id == k.TId then
				-- warn("lidaming ------updateCalendarState----->>>", k.TId, v._Data.Name, k.playCurNum, k.playMaxNum)		
				v._CurValue = k.curNum
				v._MaxValue = v._Data.ActivityNum
				v._PlayCurNum = k.playCurNum
				v._PlayMaxNum = k.playMaxNum
			end
		end
	end
	if CPanelCalendar.Instance():IsShow() then
		CPanelCalendar.Instance():RefrashCalendar()
		CPanelCalendar.Instance():UpdateCalendarToggleRedPoint()		
	end
	local CPanelUIActivity = require "GUI.CPanelUIActivity"
	local panelActivity = CPanelUIActivity.Instance()
	if panelActivity:IsShow() then
		panelActivity:UpdateShow()
	end
	self:MainRedPointState()
end

------------------C2S----------------------------

def.method("number", "number").SendC2SActivityGetReward = function(self, Type, Index)
	local C2SAdventureGuideGetData = require "PB.net".C2SAdventureGuideGetData
	local protocol = C2SAdventureGuideGetData()
	protocol.optCode = Type
	protocol.param = Index
	PBHelper.Send(protocol)
end

----------------------------Client--------------------------------
--获取所有冒险指南
def.method("=>","table").GetAllCalendarData = function(self)
	for _,v in pairs(self._CalendarDataTable) do
		if game._CFunctionMan:IsUnlockByFunTid(v._Data.FunId) then
			v._IsOpen = true
		else
			v._IsOpen = false
		end				
	end
	return self._CalendarDataTable
end

--获取当前冒险指南活跃度值
def.method("=>","number").GetCurActivityValue = function(self)
	return self._CurrentActivityValue
end

--获取当前冒险指南活跃度对应宝箱领取情况
def.method("=>","table").GetActivityGainRewardData = function(self)
	return self._ActivityGainRewardTable
end

--通过ID获取某一冒险指南数据
def.method("number","=>","table").GetCalendarDataByID = function(self, nID)
	for _,v in pairs(self._CalendarDataTable) do
		if v._Data.Id == nID then
            return v 
        end
	end
	return nil
end

--通过玩法ID获取对应活动是否开启
def.method("number","=>","boolean").IsCalendarOpenByPlayID = function(self, pID)
	for _,v in pairs(self._CalendarDataTable) do
		if v._Data.PlayID ~= "" then 
			for i,k in ipairs(v._Data.Play) do 
				if k.playId == pID then
					if game._CFunctionMan:IsUnlockByFunTid(v._Data.FunId) and v._IsOpenByTime then
						return true
					else
						return false
					end
				end
			end  
		end
	end
	return false
end

-- 活跃度红点状态获取
def.method("=>", "boolean").GetCalendarRewardRedPointState = function(self)
    local IsShowRedPoint = false
	-- 有可领取累积活跃度奖励 显示红点
	for i,v in pairs(self._ActivityGainRewardTable) do
		if v == 1 then			
			IsShowRedPoint = true
        end
	end          	
	return IsShowRedPoint
end

def.method("=>", "boolean").GetCalendarRedPointState = function(self)
    local IsShowRedPoint = false
	-- 有可领取累积活跃度奖励 显示红点
	for i,v in pairs(self._ActivityGainRewardTable) do
		if v == 1 then			
			IsShowRedPoint = true
        end
	end          
	for i,v in pairs(self._CalendarDataTable) do
		if v._Data.TabType == 0 and v._IsOpen and v._IsOpenByTime and v._Data.OpenLevel > 0 then
            if (v._CurValue * v._Data.Liveness) < (v._Data.ActivityNum * v._Data.Liveness) then
				IsShowRedPoint = true
				break 
            end
        end
	end
	
	return IsShowRedPoint
end

-- 根据玩法类型获取冒险日历toggle红点
def.method("number", "=>", "boolean").GetCalendarRedPointStateByType = function(self, TabType)
    local IsShowRedPoint = false        
	for i,v in pairs(self._CalendarDataTable) do
		if v._Data.TabType == TabType and v._IsOpen and v._IsOpenByTime and self:GetActivityRedPointByTemData(v) then
			IsShowRedPoint = self:GetActivityRedPointByTemData(v)
			break
        end
	end
	
	return IsShowRedPoint
end

-- 单个活动红点判断
def.method("table", "=>", "boolean").GetActivityRedPointByTemData = function(self, ActivityData)   
	if ActivityData == nil then return false end 
    -- 遗迹普通 and 遗迹噩梦扣除次数总和 < 3 显示红点
	if (ActivityData._Data.Id == 7 or ActivityData._Data.Id == 9) and ActivityData._CurValue < 3 then
        return true
    elseif ActivityData._Data.Id == 1 or 
        ActivityData._Data.Id == 3 or
        ActivityData._Data.Id == 6 or
        ActivityData._Data.Id == 8 or
        ActivityData._Data.Id == 11 or
        ActivityData._Data.Id == 13 or
        ActivityData._Data.Id == 16 or
        ActivityData._Data.Id == 17 or
        ActivityData._Data.Id == 19 or
        ActivityData._Data.Id == 20 then
            if ActivityData._PlayCurNum ~= 0 then
                return true
			end
	elseif ActivityData._Data.Id == 14 then
		-- 活动开启，并且公会已经报过名
		-- warn("aaaaaaa===>>>", ActivityData._IsOpenByTime, game._GuildMan:IsGuildBFApplySign(), ActivityData._CalendarId)
		local playInfo = self:GetPlayInfoByActivityID(ActivityData._Data.Id)
		local data = game._DungeonMan:GetDungeonData(playInfo.playId)
		if ActivityData._IsOpenByTime and game._GuildMan:IsGuildBFApplySign() and ActivityData._CalendarId == GuildBFApplyScriptCalendarID and data.DungeonFinishFlag <= 0 then
			return true
		end
	elseif ActivityData._Data.Id == 5 or ActivityData._Data.Id == 15 or ActivityData._Data.Id == 18 then
		local playInfo = self:GetPlayInfoByActivityID(ActivityData._Data.Id)
		-- warn("1111111111111111111=====>>>", playInfo.playId)
		local data = game._DungeonMan:GetDungeonData(playInfo.playId)
		if ActivityData._IsOpenByTime and data ~= nil and data.DungeonFinishFlag <= 0 then
			return true
		end
    elseif ActivityData._Data.Id == 10 and ActivityData._IsOpen and ActivityData._IsOpenByTime and ActivityData._PlayCurNum ~= 0 then
        return true
    elseif ActivityData._Data.Id == 2 then
        local state = false
        if game._CWorldBossMan:GetWorldBossRedPointState() and game._CWorldBossMan._WorldBossRedPointmark then
            state = true
        else
            state = false
        end
        local mainBossRedPoint = false
        if game._CWorldBossMan:GetEliteBossRedPointState() or state then
            mainBossRedPoint = true
        end
        return mainBossRedPoint
    elseif ActivityData._Data.Id == 12 then
		local ReputationQuestList = CQuest.Instance():GetCurReputationQuestList()
		if #ReputationQuestList > 0 then
			return true
		end
    elseif ActivityData._Data.Id == 24 then
		local result = CQuest.Instance():CanRecieveQuest(40368)   -- 领取讨伐令任务TID 
        return result
    end
    return false
end

def.method().MainRedPointState = function(self)
	local mainCalendarRedPoint = false
	for i,v in pairs(self._CalendarDataTable) do
		if v._IsOpen and v._IsOpenByTime and self:GetActivityRedPointByTemData(v) then
			mainCalendarRedPoint = self:GetActivityRedPointByTemData(v)
			break
        end
	end
	if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Calendar) then
		CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Calendar, mainCalendarRedPoint)
	end
end

------------------------------------------------------------------
--------------------------每日任务---------------------------------
------------------------------------------------------------------


def.field("table")._TaskDatasTable = BlankTable    	-- 每日任务数据
def.field("table")._BoxDrawListTable = BlankTable		-- 宝箱已领取奖励列表
def.field("number")._DayReachCount = 0					-- 每日达成数量
def.field("number")._WeekReachCount = 0					-- 每周达成数量
def.field("number")._LuckRefTimes = 0					-- 运势刷新次数
def.field("number")._TaskRefTimes = 0					-- 任务刷新次数
def.field("number")._LuckId = 0							-- 运势ID

------------------C2S----------------------------
-- 查看每日任务信息
def.method().SendC2SDailyTask = function(self)
	local C2SDailyTaskViewInfo = require "PB.net".C2SDailyTaskViewInfo
	local protocol = C2SDailyTaskViewInfo()
	PBHelper.Send(protocol)
end

--每日任务领取
def.method("number").SendC2SDailyTaskProvide = function(self, taskId)
	local C2SDailyTaskProvide = require "PB.net".C2SDailyTaskProvide
	local protocol = C2SDailyTaskProvide()
	protocol.TaskId = taskId
	PBHelper.Send(protocol)
end

--每日任务完成
def.method("number", "boolean").SendC2SDailyTaskFinish = function(self, taskId, isCostMoney)
	local C2SDailyTaskFinish = require "PB.net".C2SDailyTaskFinish
	local protocol = C2SDailyTaskFinish()
	protocol.TaskId = taskId
	protocol.IsCostMoney = isCostMoney
	PBHelper.Send(protocol)
end

-- 每日任务刷新
def.method().SendC2SDailyTaskRef = function(self)
	local C2SDailyTaskRef = require "PB.net".C2SDailyTaskRef
	local protocol = C2SDailyTaskRef()
	PBHelper.Send(protocol)
end

-- 运势刷新
def.method().SendC2SDailyTaskLuckRef = function(self)
	local C2SDailyTaskLuckRef = require "PB.net".C2SDailyTaskLuckRef
	local protocol = C2SDailyTaskLuckRef()
	PBHelper.Send(protocol)
end

-- 领取宝箱奖励
def.method("number").SendC2SDailyTaskDrawBox = function(self, boxId)
	local C2SDailyTaskDrawBox = require "PB.net".C2SDailyTaskDrawBox
	local protocol = C2SDailyTaskDrawBox()
	protocol.BoxId = boxId
	PBHelper.Send(protocol)
end

--------------------------S2C-----------------------------

-- 查看每日任务信息
def.method("table").DailyTaskViewInfo = function(self, DailyTaskData)
	if DailyTaskData == nil then return end
	self._TaskDatasTable = DailyTaskData.TaskDatas
	self._BoxDrawListTable = DailyTaskData.BoxDrawList
	self._DayReachCount = DailyTaskData.DayReachCount
	self._WeekReachCount = DailyTaskData.WeekReachCount
	self._LuckRefTimes = DailyTaskData.LuckRefTimes
	self._TaskRefTimes = DailyTaskData.TaskRefTimes
	self._LuckId = DailyTaskData.LuckId
	self._IsQuestFinish = false
end

-- 每日任务领取
def.method("number").DailyTaskProvide = function(self, taskId)
	if taskId == nil then return end

	for _,v in ipairs(self._TaskDatasTable) do
		if v.TaskId == taskId then
			v.IsProvide = true
			-- 重置一下领取时间
			v.ProvideTime = GameUtil.GetServerTime() / 1000 -- 单位是秒
			break
		end
	end	
	
	local REPLACE_RANGE = 12 -- 替换任务的任务个数范围
	if self:GetDailyTaskCount() >= REPLACE_RANGE then
		-- 超出范围，修改未接受任务状态
		for i,v in ipairs(self._TaskDatasTable) do
			if not v.IsProvide then
				v.IsDrawReward = true
			end
		end
	end		
	self._IsQuestFinish = false	
end

-- 每日任务完成
def.method("table").DailyTaskFinish = function(self, finishInfo)
	if finishInfo == nil then return end
	local REPLACE_RANGE = 12 -- 替换任务的任务个数范围
	if self:GetDailyTaskCount() < REPLACE_RANGE then
		-- 范围以内，替换任务
		local removeIndex = 0
		for i,v in ipairs(self._TaskDatasTable) do
			if v.TaskId == finishInfo.RemoveTaskId then
				removeIndex = i
				break
			end
		end
		if removeIndex > 0 then
			self._TaskDatasTable[removeIndex] = finishInfo.NewData			
		end
	else
		-- 超出范围，修改状态
		for i,v in ipairs(self._TaskDatasTable) do
			if not v.IsProvide then
				v.IsDrawReward = true
			end

			if v.TaskId == finishInfo.RemoveTaskId then
				v.IsDrawReward = true
			end
		end
	end
	
	self._DayReachCount = finishInfo.DayFinishCount
	self._WeekReachCount = finishInfo.WeekFinishCount
    if CPanelCalendar.Instance():IsShow() then
        CPanelCalendar.Instance():UpdateCalendarToggleRedPoint()
	end
	self._IsQuestFinish = false
end

-- 每日任务刷新
def.method("table").DailyTaskRef = function(self, refInfo)
	if refInfo == nil then return end
	self._TaskDatasTable = refInfo.TaskDatas
	self._TaskRefTimes = refInfo.RefCount
end

-- 运势刷新
def.method("table").DailyTaskLuckRef = function(self, luckRef)
	if luckRef == nil then return end
	self._LuckId = luckRef.LuckId
	self._LuckRefTimes = luckRef.RefCount	
end

-- 领取宝箱奖励
def.method("number").DailyTaskDrawBox = function(self, boxId)
	if boxId == nil then return end
	local IsRreceived = false
	for _,v in ipairs(self._BoxDrawListTable) do
		if v == boxId then
			IsRreceived = true
		end
	end	

	if IsRreceived == false then
		table.insert(self._BoxDrawListTable, boxId)
	end

    if CPanelCalendar.Instance():IsShow() then
        CPanelCalendar.Instance():UpdateCalendarToggleRedPoint()
	end
end

----------------------------Client--------------------------------

--获取所有每日任务
def.method("=>","table").GetAllDailyTaskData = function(self)
	return self._TaskDatasTable
end

--获取当前冒险指南活跃度对应宝箱领取情况
def.method("=>","table").GetDailyTaskDrawBox = function(self)
	return self._BoxDrawListTable
end

-- 根据页签类型和排序索引，获取到对应玩法信息。
def.method("number","=>", "table").GetPlayInfoByActivityID = function(self, calendarId)
    local adventureGuide = game._CCalendarMan:GetCalendarDataByID(calendarId)
    -- warn("adventureGuide._Data.PlayID ==", adventureGuide._Data.PlayID)
    if adventureGuide._Data.PlayID ~= "" then 
        table.sort(adventureGuide._Data.Play , sort_func)
        for _,v in ipairs(adventureGuide._Data.Play) do 
            -- warn("adventureGuide._Data.IndexRules ==", adventureGuide._Data.IndexRules, game._HostPlayer._InfoData._Level, v.openLevel)
            if adventureGuide._Data.IndexRules == 0 then -- 0、最低难度  1、等级索引  
                if v.difficultyMode == 0 then
                    return v
                end
            elseif adventureGuide._Data.IndexRules == 1 then
                if game._HostPlayer._InfoData._Level >= v.openLevel then                                  
					return v
                end
            end
        end  
    end
    return nil
end

def.method("table").OpenPlayByActivityInfo = function(self, temData)
	local CurPlayId = nil 
	local PlayInfo = self:GetPlayInfoByActivityID(temData._Data.Id)
	if PlayInfo ~= nil then
		CurPlayId = PlayInfo.playId
	end
	-- warn("==============lidaming==============>>> temData._Data.Id ==", temData._Data.Id, temData._Data.Name, temData._Data.ContentEventOpenUI, CurPlayId, temData._Data.ContentEventFindMap, temData._Data.ContentEventFindNPC)
	if temData._Data.ContentEventOpenUI ~= -1 then
		-- warn("1111111111111111111111111111111111")
		-- 打开副本
		if temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.InstanceEnter then                                   
			if temData._Data.playId ~= "" and CurPlayId ~= nil then                        
				game._GUIMan:Open("CPanelUIDungeon", CurPlayId) 
			else
				warn("CCalendarMan GetPlayInfo Data == nil!!!")
			end 
		-- 远征
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.Expedition then
			game._GUIMan:Open("CPanelUIExpedition", nil) -- { DungeonID = CurPlayId }
		-- 1V1
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.ArenaOne then
			game._CArenaMan:SendC2SOpenOne()     
			-- CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Champion_Arena, 0)    
		-- 3V3   
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.ArenaThree then
			game._CArenaMan:SendC2SOpenThree()
			-- CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Champion_Arena, 0)
		-- 无畏战场
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.Eliminate then
			game._CArenaMan:OnOpenBattle()
			-- CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Champion_Arena, 0)
		-- 公会防守
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildDefend then
			game._GuildMan:OpenGuildDefend()
		-- 异界之门
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildDungeon then
			game._GuildMan:OpenGuildDungeon()
		-- 世界boss
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.WorldBoss then
			game._CWorldBossMan:SendC2SEliteBossMapStateInfo(true, game._CurWorld._WorldInfo.SceneTid)
			game._GUIMan:Open("CPanelWorldBoss", temData._Data.PageId)
		-- 天空竞技场(公会战场)
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildBattle then
			game._GuildMan:OpenGuildBattle()
		-- -- 公会任务
		-- elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildQuest then
		-- 	-- game._GUIMan:Open("CPanelUIQuestList", nil)			
		-- 	game._GUIMan:Open("CPanelUIQuestList", {OpenIndex = 3})     --1 主线 2支线 3重复任务 4声望任务
		-- -- 赏金任务
		-- elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.RewardQuest then
		-- 	-- game._GUIMan:Open("CPanelUIQuestList", nil)
		-- 	game:StopAllAutoSystems()
		-- 	game._GUIMan:Open("CPanelUIQuestList", {OpenIndex = 3})     --1 主线 2支线 3重复任务 4声望任务
		-- 军资押送
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildConvoy then
			game._GuildMan:OpenGuildConvoy()

		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.ReputationQuest then
			-- game._GUIMan:Open("CPanelUIQuestList", nil)
			game._GUIMan:Open("CPanelUIQuestList", {OpenIndex = 4})     --1 主线 2支线 3重复任务 4声望任务
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.GuildTreasure then
			local hp = game._HostPlayer
			local EWorldType = require "PB.Template".Map.EWorldType
			if hp:IsDead() then
				game._GUIMan:ShowTipText(StringTable.Get(30103), false)
				return
			end
			
			if not game._GuildMan:IsHostInGuild() then
				game._GUIMan:ShowTipText(StringTable.Get(12031), false)
			return end

			if game._HostPlayer:IsInServerCombatState() then
				game._GUIMan:ShowTipText(StringTable.Get(139), false)
			return end

			if game._CurMapType == EWorldType.Pharse then
				local callback = function(val)
					if val then
						game._GuildMan:EnterGuildMap()
						game._GUIMan:CloseByScript(self)	
					end
				end
				local title, msg, closeType = StringTable.GetMsg(82)
				MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)   
			else
				game._GuildMan:EnterGuildMap()
			end
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.SingleHawkeye then
			local MapId = nil
			local SingleHawkeyeMapIds = CElementData.GetSpecialIdTemplate(650).Value
			local function sort_func_by_level(a, b)
				if a ~= b then
			        return a > b
			    end
			    return false
			end
			local MapIds = string.split(SingleHawkeyeMapIds, "*")
			if MapIds ~= nil then
				table.sort(MapIds , sort_func_by_level)
				for _,v in ipairs(MapIds) do					
					local mapData = CElementData.GetMapTemplate(tonumber(v))
					if mapData ~= nil then
						if game._HostPlayer._InfoData._Level >= mapData.LimitEnterLevel then 
							MapId = mapData.Id
							break
						end
					end
				end  
			end
			
			local panelData = 
			{
				_type = MapType.REGION,
				_MapID = MapId,
			}
			game._GUIMan:Open("CPanelMap", panelData)    
		elseif temData._Data.ContentEventOpenUI == EnumDef.ActivityOpenUIType.MultiHawkeye then
			local MapId = nil
			local SingleHawkeyeMapIds = CElementData.GetSpecialIdTemplate(650).Value
			local function sort_func_by_level(a, b)
				if a ~= b then
			        return a > b
			    end
			    return false
			end
			local MapIds = string.split(SingleHawkeyeMapIds, "*")
			if MapIds ~= nil then
				table.sort(MapIds , sort_func_by_level)
				for _,v in ipairs(MapIds) do
					local mapData = CElementData.GetMapTemplate(tonumber(v))
					if mapData ~= nil then
						if game._HostPlayer._InfoData._Level >= mapData.LimitEnterLevel then 
							MapId = mapData.Id
							break
						end
					end
				end  
			end
			local panelData = 
			{
				_type = MapType.REGION,
				_MapID = MapId,
			}
			game._GUIMan:Open("CPanelMap", panelData)   
		end
	elseif temData._Data.ContentEventFindMap ~= -1 or temData._Data.ContentEventFindNPC ~= -1 then  --查找到NPC		
		local hoh = game._HostPlayer._OpHdl
		if temData._Data.Id == 11 then
			-- warn("222222222222222222222222222222222")
			--判断赏金服务 能不能使用 
			--如果可以使用 则找NPC(298赏金服务，1097，赏金服务NPC)
			-- local option = { service_id = 298 }
			-- CNPCServiceHdl.DealServiceOption(option)
			local RewardService = CElementData.GetServiceTemplate(810)
			--local NPC = CElementData:GetNpcTemplate(1097)
			if hoh:JudgeServiceOption(RewardService) then
				game:StopAllAutoSystems()
				CQuestNavigation.Instance():NavigatToNpc(1097, nil)
				game._GUIMan:Close("CPanelCalendar")
				local CPanelUIActivity = require "GUI.CPanelUIActivity"
				if CPanelUIActivity and CPanelUIActivity.Instance():IsShow() then
					game._GUIMan:Close("CPanelUIActivity")
				end	
			else
				local title, msg, closeType = StringTable.GetMsg(72)
				MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
			end

		elseif temData._Data.Id == 16 then
			-- warn("33333333333333333333333333333333333333333333")
			local ActivityService = CElementData.GetServiceTemplate(790)
			--local NPC = CElementData:GetNpcTemplate(1097)
			--判断能不能接工会任务
			local hoh = game._HostPlayer._OpHdl
			local isHave = hoh:HaveServiceOptionsByNPCTid(20005)
			if not game._GuildMan:IsHostInGuild() then                        
				-- game._GUIMan:ShowTipText(StringTable.Get(19471), false)
				-- 未参加公会直接打开开启公会界面
				if game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Guild) then					
					game._GuildMan:RequestAllGuildInfo()
					game._GUIMan:Close("CPanelCalendar")
					local CPanelUIActivity = require "GUI.CPanelUIActivity"
					if CPanelUIActivity and CPanelUIActivity.Instance():IsShow() then
						game._GUIMan:Close("CPanelUIActivity")
					end	
				else
					game._CGuideMan:OnShowTipByFunUnlockConditions(1, EnumDef.EGuideTriggerFunTag.Guild)
				end
			--工会任务服务 可否使用 
			elseif hoh:JudgeServiceOption(ActivityService) and hoh:JudgeServiceOptionIsUse(ActivityService) and isHave then				
				game:StopAllAutoSystems()
				CQuestNavigation.Instance():NavigatToNpc(20005, nil)
				game._GUIMan:Close("CPanelCalendar")
				local CPanelUIActivity = require "GUI.CPanelUIActivity"
				if CPanelUIActivity and CPanelUIActivity.Instance():IsShow() then
					game._GUIMan:Close("CPanelUIActivity")
				end
			else                        
				local title, msg, closeType = StringTable.GetMsg(73)
				MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
			end
		elseif temData._Data.ContentEventFindNPC ~= nil then
			-- warn("///////////////////////////",temData._Data.ContentEventFindNPC)
			game:StopAllAutoSystems()
			CQuestNavigation.Instance():NavigatToNpc(900, nil)			
			game._GUIMan:Close("CPanelCalendar")
			local CPanelUIActivity = require "GUI.CPanelUIActivity"
			if CPanelUIActivity and CPanelUIActivity.Instance():IsShow() then
				game._GUIMan:Close("CPanelUIActivity")
			end	
		else
			warn("Not found NPC !!!", temData._Data.ContentEventFindNPC)
		end

	-- elseif temData._Data.ContentEventEnterDungeon ~= -1 then -- 直接进入某副本
	else
		warn("Not found Panel !!! Please find lidaming add UI")
	end



end


--获取每日达成数量
def.method("=>","number").GetDayReachCount = function(self)
	return self._DayReachCount
end

--获取周达成数量
def.method("=>","number").GetWeekReachCount = function(self)
	return self._WeekReachCount
end

--获取运势ID
def.method("=>","number").GetLuckId = function(self)
	return self._LuckId
end

--获取当前运势刷新次数
def.method("=>", "number").GetLuckRefTime = function(self)
	return self._LuckRefTimes
end

--获取当前任务刷新次数
def.method("=>", "number").GetTaskRefTime = function(self)
	return self._TaskRefTimes
end

--获取每日任务完成个数
def.method("=>", "number").GetDailyTaskCount = function(self)
	local DailyTaskCount = 0
	for i,v in ipairs(self._TaskDatasTable) do
		if v.IsProvide == true then
			DailyTaskCount = DailyTaskCount + 1
		end
	end
	return self._DayReachCount + DailyTaskCount
end

-- 宝箱是否可领取奖励
def.method("number", "number", "=>", "boolean").CanGetChestReward = function(self, chestType, index)
    local canGet = false
    if chestType == EBoxType.EBoxType_Day then
        local template = self._TaskDayChestTemplateTable[index]
        if template ~= nil then
            canGet = template.ReachCount <= self._DayReachCount
        end
    elseif chestType == EBoxType.EBoxType_Week then
        local template = self._TaskWeekChestTemplateTable[index]
        if template ~= nil then
            canGet = template.ReachCount <= self._WeekReachCount
        end
    end
    return canGet
end

-- 获取宝箱模版
def.method("number", "number", "=>", "table").GetBoxTemplate = function(self, chestType, index)
    local boxTemplate = nil
    if chestType == EBoxType.EBoxType_Day then
        boxTemplate = self._TaskDayChestTemplateTable[index]
    elseif chestType == EBoxType.EBoxType_Week then
        boxTemplate = self._TaskWeekChestTemplateTable[index]
    end
    return boxTemplate
end

-- 是否显示每日任务红点
def.method("=>", "boolean").IsShowDailyTaskRedPoint = function(self)	
	do
		-- 检查每日宝箱
		local drawBoxMap = {} -- 已领取的宝箱
		for _, tid in ipairs(self._BoxDrawListTable) do
			drawBoxMap[tid] = true
		end
		for i, v in ipairs(self._TaskDayChestTemplateTable) do
			if self:CanGetChestReward(v.BoxType, i) and drawBoxMap[v.Id] == nil then
				-- 宝箱可以领取且未领取
				return true
			end
		end
		-- 检查每周宝箱
		for i, v in ipairs(self._TaskWeekChestTemplateTable) do
			if self:CanGetChestReward(v.BoxType, i) and drawBoxMap[v.Id] == nil then
				-- 宝箱可以领取且未领取
				return true
			end
		end
	end
	-- 检查是否有可领取奖励的任务
	for i, v in ipairs(self._TaskDatasTable) do
		if v.IsProvide and not v.IsDrawReward then
			-- 已领取任务而且未领取奖励
			local template = CElementData.GetTemplate("DailyTask", v.TaskId)
			if template ~= nil then
				if v.ObjReachCount >= template.ObjCount then
					-- 达到目标数量，可领取奖励
					return true
				end
				-- ProvideTime 单位为秒
				local passTime = GameUtil.GetServerTime() / 1000 - v.ProvideTime
				-- AutoFinishTime 单位为分钟
				local leftTime = template.AutoFinishTime * 60 - passTime
				if leftTime <= 0 then
					-- 自动完成剩余时间为0，可领取奖励
					return true
				end
			end
		end
	end
	if self._IsQuestFinish then
		return true
	end
	return false
end


--获取每日任务是否全部完成
def.method("=>", "boolean").IsDailyTaskAllFinish = function(self)
	local allFinish = true -- 是否任务全部完成
	for i, v in ipairs(self._TaskDatasTable) do
		if not v.IsDrawReward then
			return false
		end
	end
	return allFinish
end

----------------------------------------------------------------------

def.method().Release = function (self)
	self._CalendarDataTable = nil
	self._OpenTimeByPlayIdTable = nil
	self._CurrentActivityValue = 0
	self._ActivityGainRewardTable = nil
	self._TaskDayChestTemplateTable = nil
	self._TaskWeekChestTemplateTable = nil

	self._TaskDatasTable = nil
	self._BoxDrawListTable = nil
	self._DayReachCount = 0
	self._WeekReachCount = 0
	self._LuckRefTimes = 0
	self._TaskRefTimes = 0
	self._LuckId = 0

end

CCalendarMan.Commit()
return CCalendarMan