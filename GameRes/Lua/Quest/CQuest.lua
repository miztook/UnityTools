local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local QuestDef = require "Quest.QuestDef"
local CQuestModel = require "Quest.CQuestModel"
local CPanelMainTips = require "GUI.CPanelMainTips"

local NotifyQuestDataChangeEvent = require "Events.NotifyQuestDataChangeEvent"
local EventTriggerType = require "PB.Template".Quest.QuestEventRelated.QuestEvent.EventTriggerType
local CElementData = require "Data.CElementData"
local QuestTypeDef = require "Quest.QuestDef".QuestType
local CQuest = Lplus.Class('CQuest')
local def = CQuest.define

-- 任务数据相关
def.field("table")._InProgressQuestMap = nil
def.field("table")._CompletedMap = nil
def.field("table")._CyclicQuestData = nil
def.field("table")._HangQuestMap = nil
def.field("table")._CountGroupsQuestData = nil
def.field("table")._GroupRewardList = nil
def.field("table")._ReputationQuest = nil

def.field("boolean")._IsInitialized = false
def.field("boolean")._IsFollowingCliend = false
def.field("table")._TempQuestModelMap = BlankTable

-- 自动采集相关
def.field("number")._CollectTimerID = 0
def.field("number")._CollectQuestID = 0
def.field("number")._CollectMineralID = 0
def.field("number")._CollectIngID = 0

-- 自动杀怪任务相关
def.field("table")._HangQuestData = nil

local instance = nil

def.static("=>", CQuest).Instance = function()
	if not instance then
		instance = CQuest()
		instance._InProgressQuestMap = {}
		instance._CompletedMap = {}
		instance._CyclicQuestData = {}
		instance._HangQuestMap = {}
		instance._CountGroupsQuestData = {}
		instance._GroupRewardList = {}
		instance._ReputationQuest = {}
		
	end
	return instance
end

local function IsCurrentNpcServiceContainQuest(quest_id)
	local services = game._HostPlayer._OpHdl:GetCurServiceNPC()._NpcTemplate.Services
	if services ~= nil then
		for i, v in ipairs(services) do
			local service_id = v.Id
			local service = CElementData.GetServiceTemplate(service_id)
			local option = nil
			if service.ProvideQuest._is_present_in_parent then
				for _, quest in ipairs(service.ProvideQuest.Quests) do
					if quest.Id == quest_id then
						return true
					end
				end
			end
		end
	end
	return false
end

--满足条件播放cg，不满足直接回调
local function CheckAndTriggerCGEvent(quest_id, triggerType, on_complete)
	local cgcomplete = function()
		-- warn("=========CG complete!!!")
		-- game._HostPlayer:Stand()
		if on_complete then
			on_complete()
		end
	end
	local temp = CElementData.GetQuestTemplate(quest_id)

	local quest_events = temp.EventRelated.QuestEvents
	if quest_events ~= nil then
		for k, v in pairs(quest_events) do
			if v ~= nil and v.triggerType == triggerType and v.PlayCG ~= nil and v.PlayCG.CgID ~= nil and type(v.PlayCG.CgID) == "number" and v.PlayCG.CgID > 0 then
				--warn("=========CG run quest id is : "..quest_id..", triggerType : "..tostring(triggerType)..", cg id is : "..v.PlayCG.CgID)
				CGMan.PlayById(v.PlayCG.CgID, cgcomplete, 1)
				return
			end
		end
	end
    --warn("=========CG not found, quest id is : "..quest_id..", triggerType : "..tostring(triggerType))
	cgcomplete()
end

local function CheckAndTriggerDialogueEvent(quest_id, triggerType, on_complete)
	local temp = CElementData.GetQuestTemplate(quest_id)
	local quest_events = temp.EventRelated.QuestEvents
	if quest_events ~= nil then
		for k, v in pairs(quest_events) do
			if v ~= nil and v.triggerType == triggerType and v.NpcDialogue ~= nil and v.NpcDialogue.DialogueId ~= nil and type(v.NpcDialogue.DialogueId) == "number" and v.NpcDialogue.DialogueId > 0 then
				--warn("=========CG run quest id is : "..quest_id..", triggerType : "..tostring(triggerType)..", cg id is : "..v.PlayCG.CgID)
				game._GUIMan:Open("CPanelDungeonNpcTalk",v.NpcDialogue.DialogueId)
				local CPanelTracker = require "GUI.CPanelTracker"
				CPanelTracker.Instance():ShowSelfPanel(false)
				return
			end
		end
	end
end

--任务数量变化
local function OnQuestChangeCount(quest_id, objective_id, count, notify_server)
	local quest_model = instance:GetInProgressQuestModel(quest_id)
	if quest_model then
		quest_model:UpdateObjectiveCount(objective_id, count, notify_server)
		local quest_object = quest_model:GetObjectiveById(objective_id)
		if quest_object then
			if quest_object:IsComplete() then
				CSoundMan.Instance():Play2DAudio(PATH.GUISound_Quest_Addition, 0)
			end
		end
		CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())
	end
end

local function OnItemChangeEvent(sender, event)
	local itemData = event.ItemUpdateInfo.UpdateItem.ItemData
	for k, v in pairs(instance._InProgressQuestMap) do
		local objectives = v:GetCurrentQuestObjetives()
		for j = 1, #objectives do
			local obj = objectives[j]
			if obj:GetTemplate().HoldItem._is_present_in_parent then
				if obj:GetTemplate().HoldItem.ItemTId == itemData.Tid then
					OnQuestChangeCount(v.Id, obj.Id, itemData.Count, true)
					break
				end
			end
		end
	end
end

--任务等待时间完成
local function OnQuestWaitTimeFinish(sender, event)
	local quest_model = instance:GetInProgressQuestModel(event._QuestId)
	if quest_model then
		quest_model.QuestStatusDirty = true
	end
end


local function OnHostPlayerLevelChangeEvent(sender, event)
	--local isShow = instance:IsShowRepeatQuestRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())
end

local function OnNotifyGuildEvent(sender, event)
	--local isShow = instance:IsShowRepeatQuestRedPoint()
	--print("OnNotifyGuildEvent")
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())
end

--整个任务模块的初始化
def.method().Init = function(self)
	if not self._IsInitialized then
		--监听任务相关事件
		CGame.EventManager:addHandler('GainNewItemEvent', OnItemChangeEvent)
		--CGame.EventManager:addHandler('NotifyEnterRegion', OnEnterRegionEvent)
		CGame.EventManager:addHandler('QuestWaitTimeFinish', OnQuestWaitTimeFinish)
		
		CGame.EventManager:addHandler('PlayerGuidLevelUp', OnHostPlayerLevelChangeEvent)
		CGame.EventManager:addHandler('NotifyGuildEvent', OnNotifyGuildEvent)
		self._IsInitialized = true
	end
end

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

def.method("table").OnS2CCountGroupReset = function(self, cgs)
	self._CountGroupsQuestData[cgs.Tid] = 
	{
	    _Count = cgs.Count,
   		_NextResetSecond = cgs.NextResetSecond
	}
end

def.method("table").OnS2CQuestUpdateReputationList = function(self, cgs)
	--print("OnS2CQuestUpdateReputationList======================")
	self._ReputationQuest = {}
	for k, v in pairs( cgs.ReputationQuests ) do
		if v and v.ReputationId and v.ReputationId > 0 then
			local QuestIDs = {}
			for i, v2 in ipairs(v.QuestList) do
				if v2 and v2 > 0 then
					QuestIDs[#QuestIDs + 1] = v2
				end
			end
			self._ReputationQuest[#self._ReputationQuest + 1] = { ReputationId = v.ReputationId, QuestList = QuestIDs }
		end
	end
	--print_r( self._ReputationQuest )
end


--任务模块'服务器数据'的初始化
def.method("table").OnS2CQuestData = function(self, protocol)
	local data = protocol.RoleQuestData

	self._InProgressQuestMap = {}
	for k, v in pairs(data.CurrentQuests) do
		if v and v.Id and v.Id > 0 then
			local current = CQuestModel.new(v)
			if current:GetTemplate() ~= nil then
				--if current.Type == QuestDef.QuestType.Hang then
				--	self._HangQuestMap[v.Id] = current
				--else
					self._InProgressQuestMap[v.Id] = current
				--end
			end
		end
	end

	self._CompletedMap = {}
	for k, v in pairs(data.FinishedQuests) do
		if v and v.Id and v.Id > 0 then
			self._CompletedMap[v.Id] = v.Count
		end
	end

	self._CyclicQuestData = 
	{
		_CyclicQuestID = data.CyclicQuestID,				    --环任务ID
		_CyclicQuestFinishNum = data.CyclicQuestFinishNum,      --环任务当前次数
		_HearsayID = data.HearsayID                             --传闻ID
    }


    local countGroup = protocol.CountGroups                     --任务完成特定次数组
    self._CountGroupsQuestData = {}
	for k, v in pairs(countGroup) do
		if v and v.Tid and v.Tid > 0 then
			self._CountGroupsQuestData[v.Tid] = 
			{ 
			   _Count = v.Count,
			   _NextResetSecond = v.NextResetSecond
			}
		end
	end

	self._GroupRewardList = {}
	--print_r(data.GroupRewardList)
	for k, v in ipairs(data.GroupRewardList) do
		if v and v > 0 then
			self._GroupRewardList[v] = v
		end
	end

    -- raise event
	CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_INIT, data)
end

def.method("table").OnS2CQuestProvide = function(self, data)
	local quest_model = nil
	if self._TempQuestModelMap[data.Id] ~= nil then
		quest_model = self._TempQuestModelMap[data.Id]
		quest_model:UpdateData(data)
		self._TempQuestModelMap[data.Id] = nil
	else
		quest_model = CQuestModel.new(data)
	end
	quest_model:SetStatus(QuestDef.Status.InProgress)

	--if current.Type == QuestDef.QuestType.Hang then
	--	self._HangQuestMap[v.Id] = quest_model
	--else
		self._InProgressQuestMap[data.Id] = quest_model
	--end
	

	--如果完成的任务是赏金类型
	local quest_data = CElementData.GetQuestTemplate(data.Id)
	if quest_data.Type == QuestDef.QuestType.Reward then
		self._CyclicQuestData._CyclicQuestID = data.Id
	end

	--接取任务后重新判断 是否有重复任务接取红点
	--local isShow = instance:IsShowRepeatQuestRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())

    if quest_model.CurrentSubQuestSuccess == 0 then 
    	local chapterTip = string.split(quest_data.QuestChapterInfo, ".")
    	if chapterTip ~= nil and chapterTip[1] ~= "nil"  and chapterTip[1] ~= "" then
	    	local ChapterTemplate = CElementData.GetTemplate("QuestChapter", tonumber(chapterTip[1]))
	        local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(chapterTip[2]))
	        if ChapterTemplate ~= nil then
		        local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
		         if Groups ~= nil and Groups[1] ~= "" then 
		         	--print("222222222222",Groups[1],GroupTemplate.Id,GroupTemplate.GroupFields[1])
		    		if GroupTemplate.GroupFields[1].QuestId == data.Id and (tonumber(chapterTip[1]) ~= 1 or tonumber(chapterTip[2]) ~= 1) then
		    			local GroupsIndex = 1
		    			for i,v in ipairs(Groups) do
		    				if v == chapterTip[2] then
		    					GroupsIndex = i
		    					break
		    				end
		    			end
		    			local str = ""
		    			if quest_data.Type == QuestDef.QuestType.Main then
			    			str = "["
			    			if ChapterTemplate.OpenNotify ~= nil then
			    				--str = str.."<color=#FFAE00FF>"..ChapterTemplate.ChapterId..'-'..GroupsIndex..' '..ChapterTemplate.OpenNotify.."</color>"
			    				str = str..ChapterTemplate.ChapterId..'-'..GroupsIndex..' '..ChapterTemplate.OpenNotify
			    			end
			    			str = str .." - "
			    			if GroupTemplate.OpenNotify ~= nil then
			    			   str = str..GroupTemplate.OpenNotify
			    			end
			    			str = str.."]"
			    		else
			    			str = "["
			    			if ChapterTemplate.OpenNotify ~= nil then
			    				str = str..ChapterTemplate.OpenNotify
			    			end
			    			str = str .." - "
			    			if GroupTemplate.OpenNotify ~= nil then
			    			   str = str..GroupTemplate.OpenNotify
			    			end
			    			str = str.."]"
			    		end
		    			--CPanelMainTips.Instance():ShowQuestChapterOpen( str )
		    			game._CGameTipsQ:ShowChapterOpenTip(str)
		    		end
		    	end
		    end
		end
    end

	-- 如果完成的任务是讨伐令类型
	if quest_data.Type == QuestDef.QuestType.Punitive then
		local CQuestAutoMan = require"Quest.CQuestAutoMan"
		local questAutoMan = CQuestAutoMan.Instance()
		questAutoMan:Start(quest_model)
		quest_model:DoShortcut()
	end

	CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_RECIEVE, data)

	
	if data.CurrentSubQuestId > 0 then
		CheckAndTriggerCGEvent(data.CurrentSubQuestId, EventTriggerType.PROVIDE, nil)
	else
		CheckAndTriggerCGEvent(data.Id, EventTriggerType.PROVIDE, nil)
	end
	CheckAndTriggerDialogueEvent(data.Id, EventTriggerType.PROVIDE, nil)
	game._HostPlayer:JudgeIsUseHawEye(false)
	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Quest_Accept, 0)

	local str = "Quest_Enter_"..data.Id
	CPlatformSDKMan.Instance():SetBreakPoint(str)
end

def.method("table").OnS2CQuestDeliver = function(self, data)
	self._InProgressQuestMap[data.Id] = nil
	self._CompletedMap[data.Id] = data.Count

	local quest_data = CElementData.GetQuestTemplate(data.Id)
	--(取消功能)--判断是否是 完成副本的任务，不是完成副本的任务 弹任务奖励，防止与副本奖励冲突
	-- local isFinishDungeon = false
 --    local datas = quest_data.ObjectiveRelated.QuestObjectives
 --    if datas and #datas > 0 then
 --        for i = 1, #datas do
 --            local o = datas[i]
 --            if o and o.FinishDungeon._is_present_in_parent then
 --            	isFinishDungeon = true
 --                break
 --            end
 --        end
 --    end
	-- if not isFinishDungeon and (quest_data.Type == QuestDef.QuestType.Main or quest_data.Type == QuestDef.QuestType.Branch) then
	-- 	--game._GUIMan:Open("CPanelUIQuestFinishReward",{_QuestId = data.Id})
	-- 	game._CGameTipsQ:ShowQuestFinishReward(data.Id)
	-- end

	--次数组赋值
	local CountGroupId = 0
	if quest_data.Type == QuestDef.QuestType.Activity then
		CountGroupId = tonumber(CElementData.GetSpecialIdTemplate(435).Value)
	elseif quest_data.Type == QuestDef.QuestType.Reward then
		CountGroupId = tonumber(CElementData.GetSpecialIdTemplate(543).Value)
	else
		CountGroupId = quest_data.CountGroupTid
	end

	if CountGroupId > 0 then
		if self._CountGroupsQuestData[CountGroupId] == nil then
			self._CountGroupsQuestData[CountGroupId] = 
			{
			   _Count = 1
			}
		else
			self._CountGroupsQuestData[CountGroupId]._Count = self._CountGroupsQuestData[CountGroupId]._Count + 1
		end
	end

	-- 如果完成的任务是赏金类型
	if quest_data.Type == QuestDef.QuestType.Reward then
		self._CyclicQuestData._CyclicQuestFinishNum = self._CyclicQuestData._CyclicQuestFinishNum + 1
		self._CyclicQuestData._CyclicQuestID = 0
		--服务器自己算，不需要客户端发
		--self:ProvideCyclic()
	end

	--交任务后检测后置任务
	if not self:IsDeliverViaNpc(data.Id) then
		if quest_data.DeliverRelated.DialogueId > 0 then
			local dialogue_data = 
			{
				dialogue_id = quest_data.DeliverRelated.DialogueId,
				is_camera_change = false,
			}
			game._GUIMan:Open("CPanelDialogue", dialogue_data)
		end
	end

	 -- print("questid===",data.Id)
	 -- print(quest_data.DeliverRelated.NextQuestId)
	 -- print(quest_data.DeliverRelated.NextSubQuestIds)
	-- --判断是否有可以接的分支
	-- if quest_data.DeliverRelated.NextSubQuestIds ~= nil then
	-- 	local subQuests = string.split(quest_data.DeliverRelated.NextSubQuestIds, "*")
	-- 	-- print("=======================",subQuests)
	-- 	--print_r(subQuests)
	-- 	local result = false
	-- 	if subQuests ~= nil and subQuests[1] ~= "" then
	-- 		for i,v in ipairs(subQuests) do
	-- 			result = self:CanRecieveQuest(tonumber(v))
	-- 			if result then
	-- 				-- 保存红点显示状态
	-- 				local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
	-- 				if Map == nil then
	-- 					Map = {}
	-- 				end
	-- 				if Map[QuestDef.QuestType.Branch+1] == nil then
	-- 					Map[QuestDef.QuestType.Branch+1] = {}
	-- 				end
	-- 				--新支线任务红点
	-- 				if Map[QuestDef.QuestType.Branch+1][1] == nil then
	-- 					Map[QuestDef.QuestType.Branch+1][1] = {}
	-- 				end
	-- 				Map[QuestDef.QuestType.Branch+1][1][tonumber(v)] = true
	-- 				CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
	-- 				CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Quest,CQuest.Instance():IsShowQuestRedPoint())
	-- 				break
	-- 			end
	-- 		end
	-- 	end
	-- end

	-- --判断有无可以领取奖励的主线章节
 --    local chapterTip = string.split(quest_data.QuestChapterInfo, ".")
 --    if chapterTip ~= nil and chapterTip[1] ~= "nil"  and chapterTip[1] ~= "" then
 --    	local ChapterTemplate = CElementData.GetTemplate("QuestChapter", tonumber(chapterTip[1]))
 --        local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(chapterTip[2]))
 --        if ChapterTemplate ~= nil then
	--         local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
 --            for i,v in ipairs(Groups) do
	-- 	        local tmpGroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(Groups[i]))
	-- 	        local groupID = tonumber(v)


	-- 	        local FinishCount = 0
	-- 		    --判断是否已经领取
	-- 		    if CQuest.Instance()._GroupRewardList[groupID] == nil then
	-- 			    for i2,v2 in ipairs(tmpGroupTemplate.GroupFields) do
	--             		local QuestID = v2.QuestId
	-- 	            	--判断此任务是否完成
	-- 	            	if CQuest.Instance():IsQuestCompleted(QuestID) then
	-- 	            		FinishCount = FinishCount + 1
	-- 	            	end
	--             	end
	-- 		    end

	-- 		    --判断是否已经达到领取要求
	-- 			if FinishCount == #tmpGroupTemplate.GroupFields then			
	-- 				-- 保存红点显示状态	        					
	-- 				local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
	-- 				if Map == nil then
	-- 					Map = {}
	-- 				end
	-- 				if Map[quest_data.Type+1] == nil then
	-- 					Map[quest_data.Type+1] = {}
	-- 				end
	-- 				if quest_data.Type == QuestDef.QuestType.Main then
	-- 					Map[quest_data.Type+1][tonumber(chapterTip[1])] = true
	-- 					CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
	-- 				elseif quest_data.Type == QuestDef.QuestType.Branch then
	-- 					--可领取奖励红点
	-- 					if Map[QuestDef.QuestType.Branch+1][2] == nil then
	-- 						Map[QuestDef.QuestType.Branch+1][2] = {}
	-- 					end
	-- 					Map[quest_data.Type+1][2][tonumber(chapterTip[1])] = true
	-- 					CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Quest, Map)
	-- 				end
	-- 				break
	-- 			end
	-- 	    end
	--     end
	-- end

	-- raise event
	CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_COMPLETE, data)
	CheckAndTriggerCGEvent(data.Id, EventTriggerType.DELIVER, nil)
	CheckAndTriggerDialogueEvent(data.Id, EventTriggerType.DELIVER, nil)
	--CSoundMan.Instance():Play2DAudio(PATH.GUISound_Quest_Complete, 0)
	local str = "Quest_End_"..data.Id
	CPlatformSDKMan.Instance():SetBreakPoint(str)
end

def.method("table").OnS2CQuestNotify = function(self, data)
	OnQuestChangeCount(data.QuestId, data.ObjectiveId, data.ObjectiveCounter, false)
	local model = self:GetInProgressQuestModel(data.QuestId)
	if self:JudgeObjectiveIsComplete(data.QuestId, data.ObjectiveId, data.ObjectiveCounter) then	
		-- 清理自动战斗目标
		local objectiveModel = model:GetObjectiveById(data.ObjectiveId) 		
		if objectiveModel and objectiveModel:IsComplete() then
			
			local monsterId = objectiveModel:GetTargetMonsterId()
			if monsterId > 0 then	
				local CAutoFightMan = require "ObjHdl.CAutoFightMan"							
				CAutoFightMan.Instance():RemovePriorityTarget(data.QuestId, monsterId)
			end

			--目标完成 关闭所有相关特效（目标区域指示特效）
			objectiveModel:ObjectiveModelEffectClose()
		end
		CheckAndTriggerCGEvent(data.QuestId, EventTriggerType.REACHOBJ, nil)
		CheckAndTriggerDialogueEvent(data.QuestId, EventTriggerType.REACHOBJ, nil)

		local temp = model:GetTemplate()
		if temp.Type == QuestDef.QuestType.Hang then
			local CAutoFightMan = require "ObjHdl.CAutoFightMan"
			CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true) 
		end
	end

	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_CHANGE, data)
end

def.method("number").OnS2CQuestGiveUp = function(self, data)
	-- 如果完成的任务是赏金类型
	local quest_data = CElementData.GetQuestTemplate(data)
	if quest_data.Type == QuestDef.QuestType.Reward then
		self._CyclicQuestData._CyclicQuestID = 0
	elseif quest_data.Type == QuestDef.QuestType.Punitive then
		game._GUIMan:ShowTipText(StringTable.Get(596), false)
	end

	self._InProgressQuestMap[data] = nil
	
	CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_GIVEUP, data)

	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Quest_Reject, 0)
end

def.method("number","=>","string").GetQuesthapterStr = function(self, Id)
	local str = ""
	local quest_data = CElementData.GetQuestTemplate(Id)
	--if quest_data.Type == QuestDef.QuestType.Reward then
	local chapterTip = string.split(quest_data.QuestChapterInfo, ".")
	if chapterTip ~= nil and chapterTip[1] ~= "" then
		--print_r(chapterTip)
    	local ChapterTemplate = CElementData.GetTemplate("QuestChapter", tonumber(chapterTip[1]))
        local GroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(chapterTip[2]))
        if ChapterTemplate ~= nil then
	        local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
	         if Groups ~= nil and Groups[1] ~= "" then 
	         	for i,v in ipairs(Groups) do
	         		if v == chapterTip[2] then
		    			local str_type = StringTable.Get(550+quest_data.Type)
		    			local str_chapter = string.format(StringTable.Get(569),ChapterTemplate.ChapterId,i)
		    			str = str .. str_type
		    			str = str .. str_chapter
		    			return str
	         		end
	         	end
	    	end
	    end
	end
	return str
end

-- 替锁哥加的1 赏金任务
def.method("number", "=>", "boolean").IsRewardQuest = function(self, id)
	local ret = false
	local quest_data = CElementData.GetQuestTemplate(id)
	if quest_data and quest_data.Type == QuestDef.QuestType.Reward then
		ret = true
	end
	return ret
end

-- 替锁哥加的2 工会任务
def.method("number", "=>", "boolean").IsActivityQuest = function(self, id)
	local ret = false
	local quest_data = CElementData.GetQuestTemplate(id)
	if quest_data and quest_data.Type == QuestDef.QuestType.Activity then
		ret = true
	end
	return ret
end

def.method("number", "=>", "boolean").IsGuideQuest = function(self, id)
	local ret = false
	local quest_data = CElementData.GetQuestTemplate(id)
	if quest_data and quest_data.Type == QuestDef.QuestType.Guide then
		ret = true
	end
	return ret
end

--打探传闻
def.method("number").OnS2CQuestGetHearsay = function(self,hearsayID)
	self._CyclicQuestData._HearsayID = hearsayID

	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_GETHEARSAY, { _hearsayID = hearsayID })
end

--任务时间限制
def.method("table").OnS2CQuestTimeStart = function(self,data)
	DispatcheCommonEvent(EnumDef.QuestEventNames.QUEST_TIME, data)
end

--领取任务奖励
def.method("number").OnS2CQuestGroupDrawReward = function(self,QuestGroupId)
	self._GroupRewardList[QuestGroupId] = QuestGroupId

	 local CPanelUIQuestList = require "GUI.CPanelUIQuestList"
  	CPanelUIQuestList.Instance():OnDataRecieveChange(QuestGroupId)
end

--判断 子目标是否完成 
def.method("number","number","number","=>","boolean").JudgeObjectiveIsComplete = function(self,quest_id, objective_id, count)
	local quest_model = self:GetInProgressQuestModel(quest_id)
	if quest_model then
		--quest_model:UpdateObjectiveCount(objective_id, count)  -- 判断类接口不要添加改变数据的逻辑 （added by lijian）
		local quest_object = quest_model:GetObjectiveById(objective_id)
		if quest_object then
			if quest_object:IsComplete() then
				return true
			end
		end
	end
	return false
end

--任务默认排序方法 主线任务 > 支线任务 > 日常任务> 悬赏 > 职业
local function DefaultQuestDataSortFunc(e1, e2)	
	if e1.Type ~= e2.Type then	
		return e1.Type < e2.Type
	end
	return e1.Id < e2.Id
end

--通过id获取任务
def.method("number", "=>", CQuestModel).FetchQuestModel = function(self, id)
	-- 进行中的任务
	--print( "FetchQuestModel",id )
	local model = self:GetInProgressQuestModel(id)
	if model ~= nil then
		model.QuestStatusDirty = true
	end

	if model ~= nil then return model end

	-- 已经完成的任务
	if self._CompletedMap[id] ~= nil then
		if self._TempQuestModelMap[id] == nil then
			local baseData =
	            {
	                Id = id,
	                QuestStatus = QuestDef.Status.Completed
	            }
	        self._TempQuestModelMap[id] = CQuestModel.new(baseData)
	    end
	    local model = self._TempQuestModelMap[id]
	    model.QuestStatus = QuestDef.Status.Completed
	    return model
	end

	-- 尚未接取的任务
    if CElementData.GetQuestTemplate(id) ~= nil then
	    if self._TempQuestModelMap[id] == nil then
			local baseData =
	            {
	                Id = id,
	                QuestStatus = QuestDef.Status.NotRecieved
	            }
	        self._TempQuestModelMap[id] = CQuestModel.new(baseData)
	    end
	    local model = self._TempQuestModelMap[id]
	    model.QuestStatus = QuestDef.Status.NotRecieved
    	return model
	end

	return nil
end

--通过id获取正在进行中的任务
def.method("number", "=>", CQuestModel).GetInProgressQuestModel = function(self, id)
	if self._InProgressQuestMap ~= nil then
		return self._InProgressQuestMap[id]
	else
		return nil
	end
end

--通过某种声望类型与ID获取任务
def.method("number", "=>", CQuestModel).GetQuestModelByReputationID = function(self, reputationID)
	if self._InProgressQuestMap ~= nil then
		for k,v in pairs(self._InProgressQuestMap) do
			if v:GetTemplate().Type == QuestDef.QuestType.Reputation then
				print("====",v:GetTemplate().ProvideRelated.ReputationLimit.ReputationId,reputationID)
				if v:GetTemplate().ProvideRelated.ReputationLimit._is_present_in_parent and v:GetTemplate().ProvideRelated.ReputationLimit.ReputationId == reputationID then
					return v
				end
 			end
		end
		return nil
	else
		return nil
	end
end

--是否声望任务已经完成
def.method("=>", "table").GetCurReputationQuestList = function(self)
	--print( "@@@@@@@@@@@@@@",reputationID )
	--print_r(self._ReputationQuest)
	local rst = {}
	if self._ReputationQuest ~= nil then
		for i,v in ipairs(self._ReputationQuest) do
			--print("==========",v.ReputationId,reputationID)
			--判断此任务链 是否达到次数组
			for i1,v1 in ipairs(v.QuestList) do
				local temp = CElementData.GetQuestTemplate(v1)
				if temp ~= nil and temp.IsRepeated then
					--只有重复任务才有次数组限制
					local v = CElementData.GetTemplate("CountGroup",temp.CountGroupTid)

					local count = 0
					if self._CountGroupsQuestData[temp.CountGroupTid] ~= nil then
						count = self._CountGroupsQuestData[temp.CountGroupTid]._Count
					end

					if v ~= nil and count < v.MaxCount then
						rst[#rst+1] = v1
					end
				end
			end
		end
	end
	return rst
end

--通过某种声望类型与ID获取任务列表
def.method("number", "=>", "table").GetQuestIDsByReputationID = function(self, reputationID)
	--print( "@@@@@@@@@@@@@@",reputationID )
	--print_r(self._ReputationQuest)
	local rst = {}
	if self._ReputationQuest ~= nil then
		for i,v in ipairs(self._ReputationQuest) do
			--print("==========",v.ReputationId,reputationID)
			if v.ReputationId == reputationID then
				--print("22222222222222")
				--rst = v.QuestList
				--print_r(v.QuestList)
				--判断此任务链 是否达到次数组
				for i1,v1 in ipairs(v.QuestList) do
					local temp = CElementData.GetQuestTemplate(v1)
					if temp ~= nil and temp.IsRepeated then
						--只有重复任务才有次数组限制
						local v = CElementData.GetTemplate("CountGroup",temp.CountGroupTid)

						local count = 0
						if self._CountGroupsQuestData[temp.CountGroupTid] ~= nil then
							count = self._CountGroupsQuestData[temp.CountGroupTid]._Count
						end

						if v ~= nil and count < v.MaxCount then
							rst[#rst+1] = v1
						end
					end
				end
				break
 			end
		end
	end
	return rst
end

--通过某种声望类型与ID获取任务列表
def.method("number", "=>", "table").GetReputationQuestIDsByMapID = function(self, MapID)
	local rst = {}
	if self._ReputationQuest ~= nil then
		for i,v in ipairs(self._ReputationQuest) do
			local template = CElementData.GetTemplate("Reputation", v.ReputationId)
			if template.MapTId == MapID then
				--rst = v.QuestList
				for i1,v1 in ipairs(v.QuestList) do
					local temp = CElementData.GetQuestTemplate(v1)
					if temp ~= nil and temp.IsRepeated then
						--只有重复任务才有次数组限制
						local v = CElementData.GetTemplate("CountGroup",temp.CountGroupTid)

						local count = 0
						if self._CountGroupsQuestData[temp.CountGroupTid] ~= nil then
							count = self._CountGroupsQuestData[temp.CountGroupTid]._Count
						end

						if v ~= nil and count < v.MaxCount then
							rst[#rst+1] = v1
						end
					end
				end
 			end
		end
	end
	return rst
end

--是否有这个ID的声望任务
def.method("number", "=>", "boolean").isReputationQuestByID = function(self, questId)
	local result = false
	if self._ReputationQuest ~= nil then
		for i,v in ipairs(self._ReputationQuest) do
			for i2,v2 in ipairs(v.QuestList) do
				if questId == v2 then
					result = true
					break
				end
			end
		end
	end
	return result
end

--是否有这个ID的声望任务 以及 后续链
def.method("number", "=>", "boolean").isReputationQuestOrSubByID = function(self, questId)
	local result = false
	if self._ReputationQuest ~= nil then
		for i,v in ipairs(self._ReputationQuest) do
			for i2,v2 in ipairs(v.QuestList) do
				if questId == v2 then
					result = true
					break
				end

				local tmpNextQuestId = v2
			    --找到此循环任务链
			    local quest_template = CElementData.GetQuestTemplate(tmpNextQuestId)
			    if quest_template ~= nil then
			        while true do
			            tmpNextQuestId = quest_template.DeliverRelated.NextQuestId
                        if questId == tmpNextQuestId then
							result = true
							break
						end

						--没有下一步了。跳出
			            if tmpNextQuestId > 0 then
			                local template = CElementData.GetQuestTemplate(tmpNextQuestId)
			                --下一步任务模板为空 跳出
			                if template ~= nil then
				            	quest_template = template
				            else
				            	break
				            end
				        else
				        	break
			            end
			        end
			    end

			end
		end
	end
	return result
end

--获得任务链 进行得最后一步
def.method("number", "=>", "number").GetReputationListCurQuestID = function(self, questId)
	local lastID = questId
					
    --找到此循环任务链
    while true do
    	print("=======",lastID)
    	if not self:IsQuestCompleted(lastID) then
    		break
    	end

    	local quest_template = CElementData.GetQuestTemplate(lastID)
        local tmpNextQuestId = quest_template.DeliverRelated.NextQuestId
		--没有下一步了。跳出
        if tmpNextQuestId > 0 then
            lastID = tmpNextQuestId
        else
        	break
        end
    end

	return lastID
end

--在现有任务重获取某种任务状态的任务
def.method("number", "=>", "table").GetAllQuestModelByStatus = function(self, status)
	local rst = {}
	for _,v in pairs(self._InProgressQuestMap) do
		if v:GetStatus() == status then
			table.insert(rst, v)
		end
	end
	if #rst > 2 then
		table.sort(rst, function(e1, e2) 
			return DefaultQuestDataSortFunc(e1:GetTemplate(),e2:GetTemplate())
		end)
	end
	return rst
end

--获取所有已接的任务
def.method("=>", "table").GetQuestsRecieved = function(self)
	local list = {}
	for _,v in pairs(self._InProgressQuestMap) do
		if v and (self:IsQuestInProgress(v.Id) or self:IsQuestReady(v.Id)) then
			table.insert(list, v:GetTemplate())
		end
	end
	if #list > 1 then
		table.sort(list, DefaultQuestDataSortFunc)
	end
	return list
end

--获取所有已接的某类型任务
def.method("number","=>", "table").GetQuestsRecievedByType = function(self,questType)
	local list = {}
	for _,v in pairs(self._InProgressQuestMap) do
		if v and self:GetQuestType(v.Id)+1 == questType and (self:IsQuestInProgress(v.Id) or self:IsQuestReady(v.Id)) then
			table.insert(list, v:GetTemplate())
		end
	end
	if #list > 1 then
		table.sort(list, DefaultQuestDataSortFunc)
	end
	return list
end

--获取所有当前状态可接的任务
def.method("=>", "table").GetQuestsCanRecieved = function(self)
	local list = {}
	local ids = GameUtil.GetAllTid("Quest")

	for _,v in pairs(ids) do
		if v and self:CanRecieveQuest(v) then
			local tmp = CElementData.GetQuestTemplate(v)

			if not tmp.IsSubQuest then
				table.insert(list, CElementData.GetQuestTemplate(v))
			end
		end
	end
	if #list > 1 then
		table.sort(list, DefaultQuestDataSortFunc)
	end
	return list
end

--获取所有当前状态可接的某类型任务
def.method("number","=>", "table").GetQuestsCanRecievedByType = function(self,questType)
	local list = {}
	local ids = GameUtil.GetAllTid("Quest")

	for _,v in pairs(ids) do
		if v and self:GetQuestType(v)+1 == questType and self:CanRecieveQuest(v) then
			local tmp = CElementData.GetQuestTemplate(v)

			if not tmp.IsSubQuest then
				list[v] = v
			end
		end
	end
	return list
end

--获取当前可以交付任务使用的道具ID
def.method("=>", "table").GetQuestUseItemIDs = function(self)
	local ids = {}
	for k, v in pairs(self._InProgressQuestMap) do
		local objectives = v:GetCurrentQuestObjetives()
		for j = 1, #objectives do
			local obj = objectives[j]
			if obj:GetTemplate().UseItem._is_present_in_parent then
				ids[#ids+1] = obj:GetTemplate().UseItem.ItemTId
			end
		end
	end
	return ids
end

--获取所有已接的任务
def.method("=>", "table").GetCyclicQuestData = function(self)
	return self._CyclicQuestData
end

--还没接
def.method("number", "=>", "boolean").IsQuestNotRecieve = function(self, id)
	local quest = self:GetInProgressQuestModel(id)
	return quest == nil or quest:GetStatus() == QuestDef.Status.NotRecieved
end

--相同次数组的任务还没接
def.method("number", "=>", "boolean").IsQuestGroupNotRecieve = function(self, id)
	local questTemplate = CElementData.GetQuestTemplate(id)
	for k, v in pairs(self._InProgressQuestMap) do
		if v:GetStatus() ~= QuestDef.Status.NotRecieved and v:GetTemplate().CountGroupTid ~= 0 and v:GetTemplate().CountGroupTid == questTemplate.CountGroupTid then
			return false
		end
	end
	return true
end

--进行中且目标没完成
def.method("number", "=>", "boolean").IsQuestInProgress = function(self, id)
	local quest = self:GetInProgressQuestModel(id)
	return quest ~= nil and quest:GetStatus() == QuestDef.Status.InProgress
end

--通过子任务id获取任务
local function GetQuestModelBySubId(self, subid)
	if self._InProgressQuestMap ~= nil then
		for k,v in pairs(self._InProgressQuestMap) do
			if v:GetTemplate().IsPartentQuest then
				if v.CurrentSubQuestId == subid then
					return v
				end
 			end
		end
		return nil
	else
		return nil
	end
end

--进行中且目标没完成 传入子任务ID 查询
def.method("number", "=>", "boolean").IsQuestInProgressBySubID = function(self, subid)
	local quest = GetQuestModelBySubId(self, subid)
	return quest ~= nil and quest:GetStatus() == QuestDef.Status.InProgress
end

--进行中且目标完成
def.method("number", "=>", "boolean").IsQuestReady = function(self, id)
	local quest = self:GetInProgressQuestModel(id)
	return quest ~= nil and quest:GetStatus() == QuestDef.Status.ReadyToDeliver
end

--进行中且目标完成 传入子任务ID 查询
def.method("number", "=>", "boolean").IsQuestReadyBySubID = function(self, subid)
	local quest = GetQuestModelBySubId(self, subid)
	return quest ~= nil and quest:GetStatus() == QuestDef.Status.ReadyToDeliver
end

--任务是否交付
def.method("number", "=>", "boolean").IsQuestCompleted = function(self, id)
	if self._CompletedMap == nil then
		return false
	end
	return self._CompletedMap[id] ~= nil
end

--任务失败
def.method("number", "=>", "boolean").IsQuestFailed = function(self, id)
	local quest = self:GetInProgressQuestModel(id)
	return quest ~= nil and quest:GetStatus() == QuestDef.Status.Failed
end

--任务目标是否完成(parentTid仅在tid是子任务清空下起作用)
def.method("number", "number", "=>", "boolean").IsQuestGoalSatified = function(self, tid, parentTid)
	if tid <= 0 then return false end

	local qt = CElementData.GetQuestTemplate(tid)
	if qt == nil then return false end

    if qt.IsSubQuest then
        local model = self:GetInProgressQuestModel(parentTid)
        return model ~= nil and model:IsSubQuestComplete(tid)
    else
        local model = self:GetInProgressQuestModel(tid)
        return model ~= nil and model:IsCompleteAll()
    end
end

--能不能领
def.method("number", "=>", "boolean").CanRecieveQuest = function(self, id)
	--先判断 有没有次数组 的限制
	local temp = CElementData.GetQuestTemplate(id)
	if temp == nil then return false end

	local isGroupLimit = false
	--只有重复任务才有次数组限制 并且类型不是 声望任务
	if temp.IsRepeated and temp.Type ~= QuestDef.QuestType.Reputation then			--重复任务
		local v = CElementData.GetTemplate("CountGroup",temp.CountGroupTid)

		local count = 0
		if self._CountGroupsQuestData[temp.CountGroupTid] ~= nil then
			count = self._CountGroupsQuestData[temp.CountGroupTid]._Count
		end

		if v == nil or count >= v.MaxCount then
			return false
		end
	end

	--如果没有超过次数组的限制 才继续判断是否满足可接取条件
	--if not isGroupLimit then
		if self:IsQuestNotRecieve(id) and self:IsQuestGroupNotRecieve(id) then	--还没领取过
			--如果是重复任务 或者 没有完成过
			if (temp.IsRepeated and temp.Type ~= QuestDef.QuestType.Reputation) or self._CompletedMap[id] == nil   then
				--判断是否符合条件
				if self:IsActive(id) and not self:IsAutoProvider(id) and self:IsLevelSatisfy(id) and self:IsPreQuestSatisfy(id) and self:IsReputationSatisfy(id) then
					return true
				end
			end

		end
	--end

	return false
end

--能不能交
def.method("number", "=>", "boolean").CanDeliverQuest = function(self, id)
	local quest = self:GetInProgressQuestModel(id)
	return quest ~= nil and quest:GetStatus() == QuestDef.Status.ReadyToDeliver
end

def.method("number", "number", "=>", "boolean").IsMyQuestTarget = function(self, objective_type, tid)
	for _,v in pairs(self._InProgressQuestMap) do
		if self:IsQuestInProgress(v.Id) then
			local ojbs = v:GetCurrentQuestObjetives()
			for _,o in pairs(ojbs) do
				if o:IsQuestTarget(objective_type, tid) and not o:IsComplete() then
					return true
				end
			end
		end
	end
	return false
end

--是否有讨伐任务
def.method("=>", "boolean").IsHasQuestPunitive = function(self)
	for _,v in pairs(self._InProgressQuestMap) do
		print("IsHasQuestPunitive",v.Id,self:GetQuestType(v.Id))
		if self:GetQuestType(v.Id) == QuestDef.QuestType.Punitive then
			return true
		end
	end
	return false
end

--是否有某类型任务
def.method("number","=>", "boolean").IsHasQuestByType = function(self,questType)
	for _,v in pairs(self._InProgressQuestMap) do
		if self:GetQuestType(v.Id) == questType then
			return true
		end
	end
	return false
end

def.method("=>", "boolean").IsThereAGatherQuestGoingOn = function(self)
	for _,v in pairs(self._InProgressQuestMap) do
		if self:IsQuestInProgress(v.Id) then
			local ojbs = v:GetCurrentQuestObjetives()
			for _,o in pairs(ojbs) do
				if o:GetTemplate().Gather._is_present_in_parent and not o:IsComplete() then
					return true
				end
			end
		end
	end
	return false
end

--是不是任务对话npc
def.method("number", "=>", "boolean").IsMyConversationTarget = function(self, npc_tid)
	return self:IsMyQuestTarget(QuestDef.ObjectiveType.Conversation, npc_tid)
end

--是不是任务物品没有时候的购买npc
def.method("number", "=>", "boolean").IsMyBuyTarget = function(self, npc_tid)
	return self:IsMyQuestTarget(QuestDef.ObjectiveType.Buy, npc_tid)
end

-- 判断当前Npc是不是任务目标
def.method("number", "=>", "boolean").IsMyNpcTarget = function(self, npc_tid)
	return self:IsMyQuestTarget(QuestDef.ObjectiveType.Conversation, npc_tid) or self:IsMyQuestTarget(QuestDef.ObjectiveType.Buy, npc_tid)
end

-- 判断当前对象是不是任务采集目标
def.method("number", "=>", "boolean").IsMyGatherTarget = function(self, mine_tid)
	return self:IsMyQuestTarget(QuestDef.ObjectiveType.Gather, mine_tid)
end

-- 判断当前对象是不是任务击杀目标
def.method("number", "=>", "boolean").IsMyKillTarget = function(self, monster_tid)
	return self:IsMyQuestTarget(QuestDef.ObjectiveType.KillMonster, monster_tid)
end

-- 判断当前对象是不是任务采集目标, 不需要判断是否采集完成
def.method("number", "=>", "boolean").IsMyGatherQuestTarget = function(self, mine_tid)
	for _,v in pairs(self._InProgressQuestMap) do
		local ojbs = v:GetCurrentQuestObjetives()
		for _,o in pairs(ojbs) do
			if o:IsQuestTarget(QuestDef.ObjectiveType.Gather, mine_tid) then
				return true
			end
		end
	end
	return false
end

-- 判断当前区域是不是任务到达区域
def.method("number","=>","boolean").IsMyArriveRegionTarget = function(self,region_tid)
	return self:IsMyQuestTarget(QuestDef.ObjectiveType.ArriveRegion, region_tid)
end

--
-- 获取任务类型 - 主线任务>日常任务>支线任务> 悬赏 > 职业
--
def.method("number", "=>", "number").GetQuestType = function (self, questid)
	return CElementData.GetQuestTemplate(questid).Type
end

--是否能接声望任务
def.method("number","=>","boolean").HaveReputationQuest = function (self,reputationID)
	local tabIds = self:GetQuestIDsByReputationID(reputationID)
	return #tabIds > 0
end
--[[def.method("number","=>","boolean").HaveReputationQuest = function (self,reputationID)
	local template = CElementData.GetTemplate("Reputation", reputationID)
	local NPCTemplate = CElementData.GetNpcTemplate(template.AssociatedNpcTId)
	local services = NPCTemplate.Services
	if services ~= nil and #services > 0 then
		local hp = game._HostPlayer
		for i, v in ipairs(services) do
			--是否有接任务服务
			local service_id = v.Id
			local service = CElementData.GetServiceTemplate(service_id)
			if service.ProvideQuest._is_present_in_parent then
				for _, quest in ipairs(service.ProvideQuest.Quests) do
					--是否可以接
					if CQuest.Instance():CanRecieveQuest(quest.Id) then
						local quest_template = CElementData.GetQuestTemplate(quest.Id)
						--是否是声望类型
						if quest_template.Type == QuestDef.QuestType.Reputation then
							return true
						end
					end
				end
			end
		end
	end
	return false
end--]]

--[[
	主线任务>日常任务>支线任务> 悬赏 > 职业

	可交付 > 可领取 > 进行中
	
	绿色叹号：日常任务怪。
	黄色叹号：支线任务怪。
	红色叹号：主线任务怪。

	没有任务的前提下，NPC有功能显示功能图标
]]

def.method("table", "=>", "table").CalcNPCQuestList = function (self, npc_template)
	if npc_template == nil then return nil end
	local provide_quests = {}
	local deliver_quests = {}
	local service_count = #npc_template.Services
	if service_count ~= 0 then
		for i = 1, service_count do
			local service_id = npc_template.Services[i].Id
			local service = CElementData.GetServiceTemplate(service_id)
			if service ~= nil then
				if service.ProvideQuest ~= nil then
					local count = #service.ProvideQuest.Quests
					for j = 1,count do
						provide_quests[#provide_quests + 1] = service.ProvideQuest.Quests[j].Id
					end
				end
				
				--如果有赏金任务服务 没有具体的赏金ID
				if service.CyclicQuest._is_present_in_parent then
					provide_quests[#provide_quests + 1] = -1
				end

				if service.DeliverQuest ~= nil then
					local count = #service.DeliverQuest.Quests
					for j = 1,count do
						deliver_quests[#deliver_quests + 1] = service.DeliverQuest.Quests[j].Id
					end
				end
			end
		end
	end
	
	local quest_list = {}
	-- 	交付任务
	for i = 1, #deliver_quests do
		local quest_id = deliver_quests[i]
		--local questModel = CQuest.Instance():GetInProgressQuestModel(quest_id)
		--if questModel then
		--	questModel.QuestStatusDirty = true
		--end

		if self:CanDeliverQuest(quest_id) then
			quest_list[#quest_list + 1] = { quest_id, QuestDef.QuestFunc.CanDeliver, self:GetQuestType(quest_id) }
		elseif self:IsQuestInProgress(quest_id) then
			quest_list[#quest_list + 1] = { quest_id, QuestDef.QuestFunc.GoingOn, self:GetQuestType(quest_id) }
		end
	end

	-- 接取任务
	for i = 1, #provide_quests do
		local quest_id = provide_quests[i]
		--local questModel = CQuest.Instance():GetInProgressQuestModel(quest_id)
		--if questModel then
		--	questModel.QuestStatusDirty = true
		--end

		--是-1 代表赏金任务 没有具体哪个赏金任务ID
		if quest_id == -1 then
			quest_list[#quest_list + 1] = { -1, QuestDef.QuestFunc.CanProvide, QuestDef.QuestType.Reward }
		elseif self:CanRecieveQuest(quest_id) then
			quest_list[#quest_list + 1] = { quest_id, QuestDef.QuestFunc.CanProvide, self:GetQuestType(quest_id) }
		end
	end

	table.sort(quest_list, function (left, right)
			if left[2] ~= right[2] then  -- 可交付 > 可领取 > 进行中
				return left[2] < right[2]
			end
			
			if left[3] ~= right[3] then -- 主线任务 > 支线任务 > 日常任务> 悬赏 > 职业
				return left[3] < right[3]
			end
			
			return left[1] < right[1]  -- 按照id从小到大排序
		end )

	return quest_list
end

def.method("table", "=>", "table").GetNPCFirstQuest = function (self, npc_template)
	local questList = self:CalcNPCQuestList(npc_template)
	local firstQuest = nil
	if questList ~= nil and #questList > 0 then
		firstQuest = questList[1] -- 优先级最高的任务显示
	end

	return firstQuest
end

def.method("number","=>","number").GetQuestChapter = function (self,quest_id)
	if quest_id ~= 0 then
		local template = CElementData.GetQuestTemplate(quest_id)
	    local chapterTip = string.split(template.QuestChapterInfo, ".")
	    if chapterTip ~= nil and chapterTip[1] ~= "nil"  and chapterTip[1] ~= "" then
	    	return tonumber(chapterTip[1])
	    end
	end
    return -1
end

--2322new 模板数据分析
local EnumPreQuestRelation =
{ 
    AND  = 0,
    OR   = 1
}

def.method("number","=>","boolean").IsActive = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
	if template == nil then
		return false
	end
    return template.ActiveRelated.Always._is_present_in_parent
end

def.method("number","=>", "boolean").IsDeliverViaNpc = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
    return template.DeliverRelated.ViaNpc and template.DeliverRelated.ViaNpc._is_present_in_parent
end

def.method("number","=>","boolean").IsAutoDeliver = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
    return template.DeliverRelated.Auto._is_present_in_parent
end

def.method("number","=>","boolean").IsDeliverReceive = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
    return template.DeliverRelated.Manual ~= nil and template.DeliverRelated.Manual._is_present_in_parent
end

def.method("number", "=>", "boolean", "number").IsQuest2BuyItem = function(self, questid)
	local ret = false
	local itemID = 0
	if questid <= 0 then
		return ret, itemID
	end
	
	-- 锁哥加的
	local template = self:GetInProgressQuestModel(questid)
	if template then
		local objectives = template:GetCurrentQuestObjetives()
		for j = 1, #objectives do
			local obj = objectives[j]
			if obj:GetTemplate().HoldItem._is_present_in_parent then
				ret = true
				itemID = obj:GetTemplate().HoldItem.ItemTId
				break
			end
		end
	end

	return ret, itemID
end

def.method("number","=>","boolean").IsAutoProvider = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
    return template.ProvideRelated.ProvideMode.AutoProvide._is_present_in_parent
end

def.method("number","=>", "boolean").IsLevelSatisfy = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
    local level = game._HostPlayer._InfoData._Level
    return level >= template.ProvideRelated.MinLevelLimit and level <= template.ProvideRelated.MaxLevelLimit
end

def.method("number","=>", "boolean").IsPreQuestSatisfy = function(self,questid)
    local template = CElementData.GetQuestTemplate(questid)
    if template.ProvideRelated and template.ProvideRelated.PredecessorQuest and template.ProvideRelated.PredecessorQuest.PreQuests then
        local ql = template.ProvideRelated.PredecessorQuest.PreQuests
        for k,v in pairs(ql) do
            if v.PreQuestRelation == EnumPreQuestRelation.OR then
                if v.Id and self:IsQuestCompleted(v.Id) then
                    return true
                end
            else
                if v.Id and not self:IsQuestCompleted(v.Id) then
                    return false
                end
            end
        end
    end
    return true
end

def.method("number","=>", "boolean").IsReputationSatisfy = function(self,questid)
	local template = CElementData.GetQuestTemplate(questid)
	if template.ProvideRelated.ReputationLimit._is_present_in_parent and template.ProvideRelated.ReputationLimit.ReputationId ~= 0 then
		local data = game._CReputationMan:GetAllReputation()
		--如果 目前此声望等级还为空 哲哲 小于 目标限制声望等级 则不通过
		if data[template.ProvideRelated.ReputationLimit.ReputationId] == nil or 
			data[template.ProvideRelated.ReputationLimit.ReputationId].Level < template.ProvideRelated.ReputationLimit.ReputationLevel
			then
			--print(questid,template.ProvideRelated.ReputationLimit.ReputationId,template.ProvideRelated.ReputationLimit.ReputationLevel,"false")
			return false
		end 
	end


	if self:GetQuestType(questid) == QuestTypeDef.Reputation then
		if not self:isReputationQuestOrSubByID(questid) then
			return false
		end
	end

	--如果没有配置声望限制等级 通过
	--print(questid,"true")
	return true

end

def.method("=>","boolean").IsShowQuestRedPoint = function (self)
    local isShow = self:IsShowMainQuestRedPoint()
    local isShow2 = self:IsShowBranchQuestRedPoint()
    local isShow3 = self:IsShowRepeatQuestRedPoint()
    local isShow4 = false
	
    local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
    if Map ~= nil then
        -- local redDotStatusMap = Map[1]
        -- if redDotStatusMap ~= nil then
        --     for k,v in pairs(redDotStatusMap) do
        --         if v == true then
        --             isShow = true
        --             break
        --         end
        --     end
        -- end

        -- redDotStatusMap = Map[QuestDef.QuestType.Branch+1]
        -- if redDotStatusMap ~= nil then
        --     for k,v in pairs(redDotStatusMap) do
        --         if v == true then
        --             isShow2 = true
        --             break
        --         end
        --     end
        -- end

        -- redDotStatusMap = Map[3]
        -- if redDotStatusMap ~= nil then
        --     if redDotStatusMap == true then
        --         isShow3 = true
        --     end
        -- end

        -- local redDotStatusMap = Map[4]
        -- if redDotStatusMap ~= nil then
        --     for k,v in pairs(redDotStatusMap) do
        --         if v == true then
        --             isShow4 = true
        --             break
        --         end
        --     end
        -- end
    end
    --print(isShow,isShow2,isShow3)
    return isShow or isShow2 or isShow3 or isShow4
end

--是否有主任务红点
def.method("=>","boolean").IsShowMainQuestRedPoint = function (self)

	local isShow = false
    local ChaptersTemplate_id_list = GameUtil.GetAllTid("QuestChapter")
	for i = 1, #ChaptersTemplate_id_list do 
		local ChapterTemplate = CElementData.GetTemplate("QuestChapter", i)
		if ChapterTemplate.QuestType == QuestDef.QuestType.Main then
		    isShow = self:IsGiveRewardByQuestChapter( i )
		    if isShow then
		    	break
		    end
		end
	end

	return isShow
end

--是否有支线任务红点
def.method("=>","boolean").IsShowBranchQuestRedPoint = function (self)
	--新的支线任务
    local NewQuestIsShow = false

    --未领取支线奖励
    local RewardQuestIsShow = false
    -- local Map = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Quest)
    -- if Map ~= nil then
    --     local redDotStatusMap = Map[2]

        -- if redDotStatusMap ~= nil and redDotStatusMap[1] ~= nil then
        --     for k,v in pairs(redDotStatusMap[1]) do
        --         if v == true then
        --             NewQuestIsShow = true
        --             break
        --         end
        --     end
        -- end

        -- if redDotStatusMap ~= nil and redDotStatusMap[2] ~= nil then
        --     for k,v in pairs(redDotStatusMap[2]) do
        --         if v == true then
        --             RewardQuestIsShow = true
        --             break
        --         end
        --     end
        -- end
        local ChaptersTemplate_id_list = GameUtil.GetAllTid("QuestChapter")
		for i = 1, #ChaptersTemplate_id_list do 
			local ChapterTemplate = CElementData.GetTemplate("QuestChapter", i)
			if ChapterTemplate.QuestType == QuestDef.QuestType.Branch then
			    RewardQuestIsShow = self:IsGiveRewardByQuestChapter( i )
			    if RewardQuestIsShow then
			    	break
			    end
			end
		end
    --end
 	local isShow = NewQuestIsShow or RewardQuestIsShow
    return isShow
end

def.method("number","=>","boolean").IsGiveRewardByQuestChapter = function (self,QuestChapterID)
    local ChapterTemplate = CElementData.GetTemplate("QuestChapter", QuestChapterID)
    local Groups = string.split(ChapterTemplate.QuestGroupId, "*")
    --print("IsGiveRewardByQuestChapter========",QuestChapterID)
    for i,v in ipairs(Groups) do
        local tmpGroupTemplate = CElementData.GetTemplate("QuestGroup", tonumber(Groups[i]))
        local groupID = tonumber(v)
        --print("groupID========",groupID)
        --如果没有领取过
        if CQuest.Instance()._GroupRewardList[groupID] == nil then
        	--判断是否可以领取 所有相关任务全部完成
        	local isAllFinish = true
        	for i2,v2 in ipairs(tmpGroupTemplate.GroupFields) do
            	if CQuest.Instance()._CompletedMap[v2.QuestId] == nil then
            		--print("v2.QuestId===========",v2.QuestId)
            		isAllFinish = false
            		break
            	end
            end
            if isAllFinish then
            	--print("IsGiveRewardByQuestChapter========",QuestChapterID,true)
            	return true
            end
        end
    end
    --print("IsGiveRewardByQuestChapter========",QuestChapterID,true)
    return false
end


--是否可以接重复任务
def.method("=>","boolean").IsShowRepeatQuestRedPoint = function (self)
	return false
  --   local hoh = game._HostPlayer._OpHdl

  --   local CyclicQuestIsShow = false
  --   local CyclicQuestData = CQuest.Instance():GetCyclicQuestData()
  --   local TotalNum = 0
  --   local FinishNum = 0
  --   local Group = CQuest.Instance()._CountGroupsQuestData[tonumber(CElementData.GetSpecialIdTemplate(543).Value)]
  --   if Group ~= nil then
  --       FinishNum = Group._Count
  --   end
    
  --   local template = CElementData.GetTemplate("CountGroup",tonumber(CElementData.GetSpecialIdTemplate(543).Value))
  --   if template ~= nil then
  --       TotalNum = template.MaxCount
  --   end
            
  --   if CyclicQuestData._CyclicQuestID == 0 and FinishNum < TotalNum and TotalNum ~= 0 then
  --       local RewardService = CElementData.GetServiceTemplate(810)
  --       if hoh:JudgeServiceOption(RewardService) then
  --           CyclicQuestIsShow = true
  --       end
  --   end


  --   local RecievedQuestIsShow = false
  --   --查找工会任务
  --   local list = CQuest.Instance():GetQuestsRecieved()
  --   local questmodel = nil 
  --   for _,v in pairs(CQuest.Instance()._InProgressQuestMap) do
  --       if v and (CQuest.Instance():IsQuestInProgress(v.Id) or CQuest.Instance():IsQuestReady(v.Id)) then
  --           if v:GetTemplate().Type == QuestDef.QuestType.Activity then
  --               questmodel = v
  --               break
  --           end
  --       end
  --   end

  --   FinishNum = 0
  --   TotalNum = 0

  --   local Group = CQuest.Instance()._CountGroupsQuestData[tonumber(CElementData.GetSpecialIdTemplate(435).Value)]
  --   if Group ~= nil then
  --       FinishNum = Group._Count
  --   end
    
  --   local template = CElementData.GetTemplate("CountGroup",tonumber(CElementData.GetSpecialIdTemplate(435).Value))
  --   if template ~= nil then
  --       TotalNum = template.MaxCount
  --   end


  --   --如果没有进行中的活动任务（工会）
  --   if questmodel == nil then
  --       local ActivityService = CElementData.GetServiceTemplate(790)
  --       if hoh:JudgeServiceOption(ActivityService) and game._GuildMan:IsHostInGuild() and FinishNum < TotalNum and TotalNum ~= 0 then
  --           RecievedQuestIsShow = true
  --       end
  --   end
  --   --print("game._GuildMan:IsHostInGuild()=",game._GuildMan:IsHostInGuild(),CyclicQuestIsShow,RecievedQuestIsShow)
 	-- local isShow = CyclicQuestIsShow or RecievedQuestIsShow
  --   return isShow
end
---------------------------------------------------------------------------------
---------------------------Client to server--------------------------------------
---------------------------------------------------------------------------------
--领任务
def.method("number", "number", "number").DoReceiveQuest = function(self, npc_id, service_id, quest_id)
	if not self:CanRecieveQuest(quest_id) then return end
	local prot = GetC2SProtocol("C2SServiceRequest")
	prot.NpcId = npc_id
	prot.ServiceId = service_id
	prot.ProvideQuest.QuestId = quest_id
	SendProtocol(prot)
end

--交任务
def.method("number", "number", "number", "number").DoDeliverQuest = function(self, npc_id, service_id, quest_id, award_id)
	if not self:CanDeliverQuest(quest_id) then return end
	local prot = GetC2SProtocol("C2SServiceRequest")
	prot.NpcId = npc_id
	prot.ServiceId = service_id
	prot.DeliverQuest.QuestId = quest_id
	prot.DeliverQuest.AwardId = award_id or 0
	SendProtocol(prot)
end

--交任务2 (直接交 不用走NPC)
def.method("number").DoDeliverQuest2 = function(self, quest_id)
	if not self:CanDeliverQuest(quest_id) then return end
	local prot = GetC2SProtocol("C2SQuestDeliver")
	prot.QuestId = quest_id

	SendProtocol(prot)
end


--放弃任务
def.method("number").DoGiveUpQuest = function(self, quest_id)
	local prot = GetC2SProtocol("C2SGiveUpQuest")
	prot.QuestId = quest_id
	SendProtocol(prot)
end

--完成对话
def.method("number", "number", "number").FinishConversationWithNpc = function(self, npc_id, service_id, dialogue_id)
	local prot = GetC2SProtocol("C2SServiceRequest")
	prot.NpcId = npc_id
	prot.ServiceId = service_id
	prot.Conversation.DialogueId = dialogue_id
	SendProtocol(prot)
end

--领赏金任务
def.method().ProvideCyclic = function(self)
	local CTeamMan = require "Team.CTeamMan"
	local CyclicQuestData = CQuest.Instance():GetCyclicQuestData()
	if CyclicQuestData._CyclicQuestID ~= 0 then
		local title, msg, closeType = StringTable.GetMsg(68)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
	elseif not game._HostPlayer:InTeam() then
		local title, msg, closeType = StringTable.GetMsg(23)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
		return
	elseif not CTeamMan.Instance():IsTeamLeader() then
		local title, msg, closeType = StringTable.GetMsg(24)
		MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OK)
		return
	elseif CTeamMan.Instance():GetMemberCount() < 3 then
		local title, msg, closeType = StringTable.GetMsg(25)
		local str = string.format(msg, 3)
		MsgBox.ShowMsgBox(str, title, closeType, MsgBoxType.MBBT_OK)
		return
	end
	local prot = GetC2SProtocol("C2SQuestProvideCyclic")
	SendProtocol(prot)
	--print("ProvideCyclic")
end

--打探传闻
def.method().QuestGetHearsay = function(self)
	local prot = GetC2SProtocol("C2SQuestGetHearsay")
	SendProtocol(prot)
	--print("QuestGetHearsay")
end

--开启跟随
def.method("boolean","number").QuestFollow = function(self,isFollow,questid)
	--print("QuestFollow",isFollow,self._IsFollowingCliend,debug.traceback())
	local CTeamMan = require "Team.CTeamMan"
	if self._IsFollowingCliend ~= isFollow then
		self._IsFollowingCliend = isFollow
	    local C2SQuestFollow = require "PB.net".C2SQuestFollow
	    local protocol = C2SQuestFollow()
	    protocol.IsFollow = isFollow

	    local hp = game._HostPlayer
	    local pos = hp:GetPos()
	    protocol.Position.x = pos.x
	    protocol.Position.y = pos.y
	    protocol.Position.z = pos.z
	    protocol.QuestId = questid
	    SendProtocol(protocol)
	end
end

--发送 NPC 服务组
def.method("number").QuestGroupProvide = function(self,npcServiceId)
	local prot = GetC2SProtocol("C2SQuestGroupProvide")
	prot.NpcServiceId = npcServiceId
	SendProtocol(prot)
end

--领奖
def.method("number").QuestGroupDrawReward = function(self,QuestGroupId)
	local prot = GetC2SProtocol("C2SQuestGroupDrawReward")
	prot.QuestGroupId = QuestGroupId
	SendProtocol(prot)
end

def.method().Release = function(self)
	self._InProgressQuestMap = nil
	self._CompletedMap = nil
	self._CyclicQuestData = nil
	self._CountGroupsQuestData = nil
	self._GroupRewardList = nil
	self._ReputationQuest = nil
	self._CollectTimerID = 0
	self._CollectQuestID = 0
	self._CollectMineralID = 0
	self._CollectIngID = 0
	self._TempQuestModelMap = {}

	if self._IsInitialized then
		--监听任务相关事件
		CGame.EventManager:removeHandler('GainNewItemEvent', OnItemChangeEvent)
		--CGame.EventManager:removeHandler('NotifyEnterRegion', OnEnterRegionEvent)
		CGame.EventManager:removeHandler('QuestWaitTimeFinish', OnQuestWaitTimeFinish)

		CGame.EventManager:removeHandler("PlayerGuidLevelUp", OnHostPlayerLevelChangeEvent)
		CGame.EventManager:removeHandler('NotifyGuildEvent', OnNotifyGuildEvent)
		self._IsInitialized = false
	end
end

CQuest.Commit()
return CQuest 