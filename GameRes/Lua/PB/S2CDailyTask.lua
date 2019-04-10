--
--S2CDailyTask  每日任务  2018/08/21  lidaming
--
local PBHelper = require "Network.PBHelper"

local function ErrorCodeCheck(error_code)
	game._GUIMan:ShowErrorTipText(error_code)
end

-- 通知界面，刷新面板
local function NotifyUI(type)
	local CPanelUIActivity = require "GUI.CPanelUIActivity".Instance()
	if CPanelUIActivity and CPanelUIActivity:IsShow() then
		CPanelUIActivity:UpdateUIState(type)
	end	
end

-- 查看每日任务信息
local function OnS2CDailyTaskViewInfo(sender, msg)
	-- warn("--------OnS2CDailyTaskViewInfo-------", msg.DailyTaskData.LuckId)
	game._CCalendarMan:DailyTaskViewInfo(msg.DailyTaskData)
	NotifyUI(0)
end
PBHelper.AddHandler("S2CDailyTaskViewInfo", OnS2CDailyTaskViewInfo)

-- 每日任务领取
local function OnS2CDailyTaskProvide(sender, msg)
	-- warn("----OnS2CDailyTaskProvide----", msg.ResCode)
	if msg.ResCode == 0 then
		game._CCalendarMan:DailyTaskProvide(msg.TaskId)

		NotifyUI(1)
	end
end
PBHelper.AddHandler("S2CDailyTaskProvide", OnS2CDailyTaskProvide)

-- 每日任务完成
local function OnS2CDailyTaskFinish(sender, msg)
	-- warn("----OnS2CDailyTaskFinish----", msg.ResCode)
	if msg.ResCode == 0 then
		game._CCalendarMan:DailyTaskFinish(msg)

		NotifyUI(2)
	end
end
PBHelper.AddHandler("S2CDailyTaskFinish", OnS2CDailyTaskFinish)

-- 每日任务刷新
local function OnS2CDailyTaskRef(sender, msg)
	-- warn("----OnS2CDailyTaskRef----", msg.ResCode)
	if msg.ResCode == 0 then
		game._CCalendarMan:DailyTaskRef(msg)
		NotifyUI(3)
	end
end
PBHelper.AddHandler("S2CDailyTaskRef", OnS2CDailyTaskRef)

-- 运势刷新
local function OnS2CDailyTaskLuckRef(sender, msg)
	-- warn("----OnS2CDailyTaskLuckRef----", msg.ResCode)
	if msg.ResCode == 0 then
		game._CCalendarMan:DailyTaskLuckRef(msg)

		NotifyUI(4)
	end
end
PBHelper.AddHandler("S2CDailyTaskLuckRef", OnS2CDailyTaskLuckRef)

-- 领取宝箱奖励
local function OnS2CDailyTaskDrawBox(sender, msg)
	-- warn("----OnS2CDailyTaskDrawBox----", msg.ResCode)
	if msg.ResCode == 0 then
		game._CCalendarMan:DailyTaskDrawBox(msg.BoxId)

		NotifyUI(5)
	end
end
PBHelper.AddHandler("S2CDailyTaskDrawBox", OnS2CDailyTaskDrawBox)
