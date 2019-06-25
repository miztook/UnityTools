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
    [1] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "1130", SecondDelay = "3", DayDelay = "5",},
	[2] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 1, Qualification = "2096", SecondDelay = "3", DayDelay = "5",},
	[3] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 2, Qualification = "20070", SecondDelay = "10", DayDelay = "5",},
	[4] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 3, Qualification = "4", SecondDelay = "3", DayDelay = "5",},
	[5] = {  Title = "玩得开心吗？", Desc1 = "请留下您宝贵的意见，您的意见对Tera Classic有很大帮助！", Desc2 = "如有问题请及时联系我们的客服", IsOpen = true, TriggerConditions = 4, Qualification = "5", SecondDelay = "10", DayDelay = "5",},
}

return AppMsgBoxCfg
