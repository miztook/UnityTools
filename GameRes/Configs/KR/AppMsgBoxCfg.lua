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
    [1] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요. 여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "1130", SecondDelay = "5", DayDelay = "3",},
	[2] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요. 여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "2096", SecondDelay = "5", DayDelay = "3",},
	[3] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요. 여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의주세요.", IsOpen = true, TriggerConditions = 2, Qualification = "20070", SecondDelay = "5", DayDelay = "3",},
	[4] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요. 여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의주세요.", IsOpen = true, TriggerConditions = 3, Qualification = "4", SecondDelay = "5", DayDelay = "3",},
	[5] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요. 여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의주세요.", IsOpen = true, TriggerConditions = 4, Qualification = "5", SecondDelay = "5", DayDelay = "3",},
}

return AppMsgBoxCfg
