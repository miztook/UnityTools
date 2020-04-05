local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local NotifyQuestDataChangeEvent = require "Events.NotifyQuestDataChangeEvent"
-- local CQuestMan = require "Quest.CQuestMan"
local CQuest = require "Quest.CQuest"
local CPageQuest = require "GUI.CPageQuest"

local function DispatcheCommonEvent(name, data)
	local event = require("Events.QuestCommonEvent")()

	if name == nil then
		event._Name = ""
	else 
		event._Name = name
	end

	event._Data = data
	CGame.EventManager:raiseEvent(nil, event)
end

--初始化任务数据
--由于CPageQuest使用了动画，所以任务追踪界面中使用的数据和整个任务模块的数据是不同部的。
--所以，此处将数据源做了两份分支，一份CPageQuest维护，另一份整个任务模块维护。
local function OnS2CQuestData(sender, protocol)
	warn("OnS2CQuestData")
	--print("OnS2CQuestData")
	-- CQuestMan.OnS2CQuestData(protocol.RoleQuestData)

	--初始化任务模块
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_INIT, protocol.RoleQuestData)
end
PBHelper.AddHandler("S2CQuestData", OnS2CQuestData)

--领任务
local function OnS2CQuestProvide(sender, protocol)
	--warn("OnS2CQuestProvide",protocol.CurrentQuest.Id)
	--print("OnS2CQuestProvide")
	-- CQuestMan.OnS2CQuestProvide(protocol.CurrentQuest)

	--新版
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_RECIEVE, protocol.CurrentQuest)
end
PBHelper.AddHandler("S2CQuestProvide", OnS2CQuestProvide)

--交任务
local function OnS2CQuestDeliver(sender, protocol)
	--warn("OnS2CQuestDeliver",protocol.FinishedQuest.Id)
	--print("OnS2CQuestDeliver")
	-- CQuestMan.OnS2CQuestDeliver(protocol.FinishedQuest)

	--新版
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_COMPLETE, protocol.FinishedQuest)
end
PBHelper.AddHandler("S2CQuestDeliver", OnS2CQuestDeliver)

--任务数据变化
local function OnS2CQuestNotify(sender, protocol)
	--warn("OnS2CQuestNotify",protocol.QuestId)
	--print("OnS2CQuestNotify")
	-- CQuestMan.OnS2CQuestNotify(protocol.QuestId, protocol.QuestStatus, protocol.ObjectiveId, protocol.ObjectiveCounter)

	--新版
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_CHANGE, protocol)
end
PBHelper.AddHandler("S2CQuestNotify", OnS2CQuestNotify)

--放弃任务 or 删任务
local function OnS2CQuestGiveUp(sender, protocol)
	--warn("OnS2CQuestGiveUp")
	--print("OnS2CQuestGiveUp")
	-- CQuestMan.OnS2CQuestGiveUp(protocol.QuestId)

	--新版
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_GIVEUP, protocol.QuestId)
end
PBHelper.AddHandler("S2CQuestGiveUp", OnS2CQuestGiveUp)

--打探传闻
local function OnS2CQuestGetHearsay(sender, protocol)
	--warn("OnS2CQuestGetHearsay")
	--print("OnS2CQuestGetHearsay")
	CQuest.Instance():OnS2CQuestGetHearsay(protocol.HearsayID)
end
PBHelper.AddHandler("S2CQuestGetHearsay", OnS2CQuestGetHearsay)

--任务时间相关
local function OnS2CQuestTimeStart(sender, protocol)
    --print("OnS2CQuestTimeStart")
	CQuest.Instance():OnS2CQuestTimeStart(protocol)
end
PBHelper.AddHandler("S2CQuestTimeStart", OnS2CQuestTimeStart)

