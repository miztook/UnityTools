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
    [1] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "58", SecondDelay = "1", DayDelay = "999",},
	[2] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "1077", SecondDelay = "1", DayDelay = "999",},
	[3] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "2029", SecondDelay = "1", DayDelay = "999",},
	[4] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "2037", SecondDelay = "1", DayDelay = "999",},
	[5] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "3040", SecondDelay = "1", DayDelay = "999",},
	[6] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "3362", SecondDelay = "1", DayDelay = "999",},
	[7] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "4051", SecondDelay = "1", DayDelay = "999",},
	[8] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "1150", SecondDelay = "1", DayDelay = "999",},
	[9] = {  Title = "재밌으셨나요?", Desc1 = "소중한 의견을 남겨주세요.\n여러분의 의견은 테라 클래식의 발전에 큰 도움이 됩니다!", Desc2 = "도움이 필요하시면 언제든지 저희 고객 센터로 문의해 주세요.", IsOpen = true, TriggerConditions = 1, Qualification = "4111", SecondDelay = "15", DayDelay = "999",},
}

return AppMsgBoxCfg
