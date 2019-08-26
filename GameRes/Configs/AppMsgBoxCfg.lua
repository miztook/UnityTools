--[[
TriggerTag =     --触发条件
{
    FinishAchievement        = 0, -- 完成成就
    FinishQuest              = 1, -- 完成任务
    GetIDItem                = 2, -- 获得指定ID物品
    ReachGloryLevel          = 3, -- 达到荣耀等级
    GetQualityItem           = 4, -- 获得指定品质物品
}
]]

local AppMsgBoxCfg = 
{
    [1] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "58", SecondDelay = "1", DayDelay = "999",},
	[2] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "1077", SecondDelay = "1", DayDelay = "999",},
	[3] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "2029", SecondDelay = "1", DayDelay = "999",},
	[4] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "2037", SecondDelay = "1", DayDelay = "999",},
	[5] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "3040", SecondDelay = "1", DayDelay = "999",},
	[6] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "3362", SecondDelay = "1", DayDelay = "999",},
	[7] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "4051", SecondDelay = "1", DayDelay = "999",},
	[8] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "1150", SecondDelay = "1", DayDelay = "999",},
	[9] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "4111", SecondDelay = "15", DayDelay = "999",},
}

return AppMsgBoxCfg
