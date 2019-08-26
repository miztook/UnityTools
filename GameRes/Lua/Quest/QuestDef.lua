
--[[
	定义任务相关枚举和常量
]]
local Enum = require "Utility.Enum"
local NetDef = require "PB.net"
local TemplateDef = require "PB.Template"

local Status = 
{
	NotRecieved		= 0,	--未领取

	InProgress		= 1,	--进行中
	ReadyToDeliver	= 2,	--达到交付条件
	Completed		= 3,	--已交付
	Failed			= 4		--失败
}
--[[
	enum QuestType
	{
		Main		= 0;
		Branch		= 1;
		Activity	= 2;
		Reward		= 3;
		Profession  = 4;
	}
]]
local QuestType = TemplateDef.Quest.QuestType

local QuestFunc =
{
	CanDeliver = 1,  -- 可交付
	CanProvide = 2,  -- 可接取
	GoingOn = 3,  -- 进行中
}

local QuestErrCode =
{
	SUCCESS = 0,
	

	UNKNOWN_ERROR = 9999,
}

local ObjectiveType = 
{
	Conversation = 1,
	KillMonster = 2,
	Gather = 3,	
	ArriveRegion = 4,
	FinishDungeon = 5,
	EnterDungeon = 6,
	UseItem = 7,
	HoldItem = 8,
	WaitTime = 9,
	Buy = 10,
}

local UIFxEventType = 
{
    InProgress = 1,         --任务正在进行中
    ObjectCountChange = 2,  --任务目标数目变化
    Completed = 3,          --任务完成
    IdleTimeTooLang = 4,    --没有做任务的时间太长了
    Finish = 5,             --可完成状态
    Fail = 6,              --任务失败
    Recrive = 7,
}

local SortIndex = 
{
	0,2,3,4,5,6,7,8,10,9,11,1
}

return
{
	QuestType = QuestType,
	QuestErrCode = QuestErrCode,
	QuestFunc = QuestFunc,
	Status = Status,
	ObjectiveType = ObjectiveType,
    UIFxEventType = UIFxEventType,
    SortIndex = SortIndex,
}