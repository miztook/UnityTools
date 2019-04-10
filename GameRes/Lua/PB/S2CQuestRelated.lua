local Lplus = require "Lplus"
local PBHelper = require "Network.PBHelper"
local CQuest = require "Quest.CQuest"
local CElementData = require "Data.CElementData"
--初始化任务数据
local function OnS2CQuestData(sender, protocol)
	CQuest.Instance():OnS2CQuestData(protocol)
end
PBHelper.AddHandler("S2CQuestData", OnS2CQuestData)

--领任务
local function OnS2CQuestProvide(sender, protocol)
	warn("领任务",protocol.CurrentQuest.Id)
	CQuest.Instance():OnS2CQuestProvide(protocol.CurrentQuest)
end
PBHelper.AddHandler("S2CQuestProvide", OnS2CQuestProvide)

--交任务
local function OnS2CQuestDeliver(sender, protocol)
	warn("交任务",protocol.FinishedQuest.Id)
	CQuest.Instance():OnS2CQuestDeliver(protocol.FinishedQuest)
	-- 弹出app弹窗
	game:OnAppMsgBoxStatic(EnumDef.TriggerTag.FinishQuest, protocol.FinishedQuest.Id)
end
PBHelper.AddHandler("S2CQuestDeliver", OnS2CQuestDeliver)

--任务数据变化
local function OnS2CQuestNotify(sender, protocol)
	print("任务数据变化",protocol.QuestId, protocol.ObjectiveId, protocol.ObjectiveCounter)
	CQuest.Instance():OnS2CQuestNotify(protocol)
end
PBHelper.AddHandler("S2CQuestNotify", OnS2CQuestNotify)

--放弃任务 or 删任务
local function OnS2CQuestGiveUp(sender, protocol)
	print("任务放弃",protocol.QuestId)
	CQuest.Instance():OnS2CQuestGiveUp(protocol.QuestId)
end
PBHelper.AddHandler("S2CQuestGiveUp", OnS2CQuestGiveUp)

--打探传闻
local function OnS2CQuestGetHearsay(sender, protocol)
	CQuest.Instance():OnS2CQuestGetHearsay(protocol.HearsayID)
end
PBHelper.AddHandler("S2CQuestGetHearsay", OnS2CQuestGetHearsay)

--任务时间相关
local function OnS2CQuestTimeStart(sender, protocol)
	CQuest.Instance():OnS2CQuestTimeStart(protocol)
end
PBHelper.AddHandler("S2CQuestTimeStart", OnS2CQuestTimeStart)

--领取任务组奖励
local function OnS2CQuestGroupDrawReward(sender, protocol)
	CQuest.Instance():OnS2CQuestGroupDrawReward(protocol.QuestGroupId)
end
PBHelper.AddHandler("S2CQuestGroupDrawReward", OnS2CQuestGroupDrawReward)

local function OnS2CQuestUpdateReputationList(sender, protocol)
	CQuest.Instance():OnS2CQuestUpdateReputationList(protocol)
end
PBHelper.AddHandler("S2CQuestUpdateReputationList", OnS2CQuestUpdateReputationList)

--任务对话同步
local function OnS2CNpcDialogueSyn(sender, protocol)
	--protocol.DialogueType
	--
	local autoProvide = false
	local quest_template = CElementData.GetQuestTemplate(protocol.Tid)
	--print("protocol.Tid==========",protocol.Tid,protocol.DialogueType)

	local dlgid = 0
	-- if quest_template.ProvideRelated.ProvideMode.ViaNpc._is_present_in_parent then
	-- 	autoProvide = quest_template.ProvideRelated.ProvideMode.ViaNpc.IsAuto
	-- end
	
	if quest_template.ProvideRelated ~= nil then
		dlgid = quest_template.ProvideRelated.DialogueId
	elseif quest_template.DeliverRelated ~= nil then
		dlgid = quest_template.DeliverRelated.DialogueId
	end
	local function on_dialogue_close()
		game._HostPlayer._OpHdl:EndNPCService(nil)
	end

	local dialogue_data = 
	{
		dialogue_id = dlgid,
		on_close = on_dialogue_close,
		is_provide = true,
		is_autoProvide = false,
		is_camera_change = false,
	}

	game._GUIMan:Open("CPanelDialogue", dialogue_data)
end
PBHelper.AddHandler("S2CNpcDialogueSyn", OnS2CNpcDialogueSyn)

