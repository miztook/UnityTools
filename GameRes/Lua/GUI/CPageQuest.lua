local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPath = Lplus.ForwardDeclare("CPath")
local QuestDef = require "Quest.QuestDef"
local CQuestAutoMan = require"Quest.CQuestAutoMan"
local CQuest = Lplus.ForwardDeclare("CQuest")
local EItemType = require "PB.Template".Item.EItemType
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local CQuestModel = require "Quest.CQuestModel"
local CQuestObjectiveModel = require"Quest.CQuestObjectiveModel"
local CTransManage = require "Main.CTransManage"

local CPageQuest = Lplus.Class("CPageQuest")
local def = CPageQuest.define

local MAX_OBJECTIVE_COUNT = 4

def.field("userdata")._Panel = nil
def.field("userdata")._List = nil
def.field("userdata")._ListObject = nil
def.field("table")._QuestCurrent = nil
def.field("table")._QuestTimer = nil
def.field("table")._IdleTipTimer = nil
def.field("number")._IdleTotalTime = 12
def.field("boolean")._IsShow = false
def.field('number')._Quest_ClickTimer_id = -1   
def.field("table")._ResetPos = nil
def.field("boolean")._FirstShow = true
def.field("number")._SelectQuestID = 0
def.field("table")._ObjectiveTimerList = BlankTable

def.field("table")._SpecialDungeonGoal = nil
def.field("userdata")._SpecialDungeonGoalItem = nil
def.field('number')._SpecialDungeonGoalTime = -1 
def.field('number')._SpecialDungeonGoalTimeId = 0 

def.field("boolean")._OnlyTrunOnGfxWhenItemSel = false

local instance = nil

local function GetInProcessQuest(id)
	return CQuest.Instance():GetInProgressQuestModel(id)
end

local function GetInProcessOrNotRecvQuest(id)
	local model = CQuest.Instance():FetchQuestModel(id)
	if model.QuestStatus == QuestDef.Status.Completed then
		warn("error: Quest Status is Completed", id)
	end
	return model
end

--是不是任务接了还没有交付(目标完没完成都算）
local function IsQuestInProgress(quest_id)
	for k, v in pairs(instance._QuestCurrent) do
		if v == quest_id then
			return true
		end
	end
	return false
end

--获取插入位置索引
local function GetInsertIndex(id)
	if id > 0 then
		local template = CElementData.GetQuestTemplate(id)
		local model = CQuest.Instance():FetchQuestModel(id)

		if template ~= nil then
			for i = 1, #instance._QuestCurrent do
				local curTemp = CElementData.GetQuestTemplate(instance._QuestCurrent[i])
				local curModel = CQuest.Instance():FetchQuestModel(instance._QuestCurrent[i])
				--类型放前
				--类型放前
				if  QuestDef.SortIndex[curTemp.Type+1] > QuestDef.SortIndex[template.Type+1] then
					return i
				end

				--状态进行中放前
				if curTemp.Type == template.Type and curModel.QuestStatus == QuestDef.Status.NotRecieved and model.QuestStatus ~= QuestDef.Status.NotRecieved then
					return i
				end

				--任务ID 序号放前
				if curTemp.Type == template.Type and curTemp.Id < template.Id then
					return i
				end

				local nextQuestId = instance._QuestCurrent[i + 1]
				if nextQuestId == nil then
					return i + 1
				end
			end
		end
	end
	return 1
end

local function GetQuestIndex(id)
	for i = 1, #instance._QuestCurrent do
		if instance._QuestCurrent[i] == id then
			return i
		end
	end
	return -1
end

local function UpdateList()
	--为0 的时候也要刷新
	local count = #instance._QuestCurrent
	--如果有特殊副本目标特殊处理
	if instance._SpecialDungeonGoal ~= nil then
		count = count + 1
	end
	instance._OnlyTrunOnGfxWhenItemSel = false
	instance._List:SetItemCount(count)
end

--------------------------------------------------------------
------------------------任务列表基础操作-----------------------
--------------------------------------------------------------
local function OnQuestData(data)
	local source = data
	instance._QuestCurrent = {}
	local hasMainQuest = false
	for k, v in pairs(source.CurrentQuests) do
		if v and v.Id and v.Id > 0 then
			
			local current = GetInProcessQuest(v.Id)
			if current and current:GetTemplate()~=nil and not current:GetTemplate().IsSubQuest and not (current:GetTemplate().Type == QuestDef.QuestType.Hang) then
				if current:GetTemplate().Type == QuestDef.QuestType.Main then
					hasMainQuest = true
				end
				table.insert(instance._QuestCurrent, v.Id)
			end
		end
	end
	
	local next_quest_id = 0
	local finished = source.FinishedQuests
	for i = #finished, 1, - 1 do
		local finishedQuestTmp = CElementData.GetQuestTemplate(finished[i].Id)
		if finishedQuestTmp ~= nil then
			next_quest_id = finishedQuestTmp.DeliverRelated.NextQuestId
			if next_quest_id > 0 then
				local isShowNextQuest = false
				--如果 是主线 没有进行中的主线任务 （主线任务 只显示一个未接的）
				if not hasMainQuest and finishedQuestTmp.Type == QuestDef.QuestType.Main then
					isShowNextQuest = true
					hasMainQuest = true
				end

				--如果 是分支 完成列表中没有 并且 也没在正进行中列表
				if finishedQuestTmp.Type == QuestDef.QuestType.Branch or finishedQuestTmp.Type == QuestDef.QuestType.Reputation then
--[[					local isHasCurrent = false
					for i,v in ipairs(instance._QuestCurrent) do
						if v == next_quest_id then
							isHasCurrent = true
						end
					end

					if not CQuest.Instance():IsQuestCompleted(next_quest_id) and not isHasCurrent then
						isShowNextQuest = true
					end--]]

					local result = CQuest.Instance():CanRecieveQuest( next_quest_id )
					local index = table.indexof(instance._QuestCurrent, next_quest_id )
					if result and not index then
						isShowNextQuest = true
					end
				end

				if isShowNextQuest then
					table.insert(instance._QuestCurrent, #instance._QuestCurrent + 1, next_quest_id)
				end
			end

			--添加可以接的新支线
			local subQuests = string.split(finishedQuestTmp.DeliverRelated.NextSubQuestIds, "*")
			local result = false
			if subQuests ~= nil and subQuests[1] ~= "" then
				for i,v in ipairs(subQuests) do
					result = CQuest.Instance():CanRecieveQuest(tonumber(v))
					local index = table.indexof(instance._QuestCurrent, tonumber(v))
					if result and not index then
						table.insert(instance._QuestCurrent, #instance._QuestCurrent + 1, tonumber(v))
					end
				end
			end
		end
	end

	--sort
	if #instance._QuestCurrent > 1 then
		local SortFunc = function(left, right)
			local tl = CElementData.GetQuestTemplate(left) --left:GetTemplate()
			local tr = CElementData.GetQuestTemplate(right) --right:GetTemplate()
			local ml = CQuest.Instance():FetchQuestModel(left)
			local mr = CQuest.Instance():FetchQuestModel(right)
			if tl.Type ~= tr.Type then	-- 主线任务 > 支线任务 > 日常任务> 悬赏 > 职业
				--return tl.Type < tr.Type
				return QuestDef.SortIndex[tl.Type+1] < QuestDef.SortIndex[tr.Type+1] 
			end
			if ml.QuestStatus ~= mr.QuestStatus then
				 return ml.QuestStatus ~= QuestDef.Status.NotRecieved and mr.QuestStatus == QuestDef.Status.NotRecieved
			end
			return tl.Id < tr.Id
		end
		table.sort(instance._QuestCurrent, SortFunc)
	end
end

--添加单个任务
local function QuestAdd(questId)
	local index = GetInsertIndex(questId)
	table.insert(instance._QuestCurrent, index, questId)
	--如果界面还没显示，只更新数据
	if instance._IsShow then
		--如果有特殊副本目标特殊处理
		if instance._SpecialDungeonGoal ~= nil then
			index = index + 1
		end
		--instance._Queue:Push(CListAddOpera.new({}, instance._List, index - 1))
		instance._List:AddItem(index - 1)
		--print("AddItem",index - 1)
	end
end

--删除单个任务
local function QuestRemove(quest_id)
	instance:RemoveQuestTimer(quest_id)

	local index = GetQuestIndex(quest_id)
	table.remove(instance._QuestCurrent, index)
	--如果界面还没显示，只更新数据
	if instance._IsShow then
		--如果有特殊副本目标特殊处理
		if instance._SpecialDungeonGoal ~= nil then
			index = index + 1
		end
		--instance._Queue:Push(CListRemoveOpera.new({}, instance._List, index - 1))
		instance._List:RemoveItem(index - 1)
		print("RemoveItem",index - 1)
	end
end

--子任务变化
local function QuestUpdate(quest_id)
	local index = GetQuestIndex(quest_id)
	instance._QuestCurrent[index] = quest_id
	--如果界面还没显示，只更新数据
	if instance._IsShow then
		--如果有特殊副本目标特殊处理
		if instance._SpecialDungeonGoal ~= nil then
			index = index + 1
		end
		instance._List:RefreshItem(index - 1)
	end
end

--任务数量
local function QuestChangeCount(quest_id, objective_id, count)
	local model = GetInProcessQuest(quest_id)
	if model == nil then
		warn("任务面板更新出现错误1=",quest_id,objective_id,count)
		return
	end
	--TERA-2941 判断次目标有没有完成 原先没有判断是否是单挑目标完成
	local objectiveModel = model:GetObjectiveById(objective_id) 
	if objectiveModel == nil then
		warn("can not get objectiveModel, id = " .. objective_id)
		return
	end
    local quest_index = GetQuestIndex(quest_id)
    local item = nil
    if quest_index ~= -1 then
		--如果有特殊副本目标特殊处理
		if instance._SpecialDungeonGoal ~= nil then
			quest_index = quest_index + 1
		end
        item = instance._List:GetItem(quest_index - 1)
    else
    	quest_index = 0
    	--如果有特殊副本目标特殊处理
		if instance._SpecialDungeonGoal ~= nil then
			quest_index = quest_index + 1
		end
        item = instance._List:GetItem(quest_index)
    end
	--2322new
	if model:IsCompleteAll() and not model:IsAutoDeliver() then
		--虽然是整体刷新，但是这里的目标是刷新文字颜色
		QuestUpdate(quest_id)
        if instance._IsShow then
            instance:ShowQuestUIFX(QuestDef.UIFxEventType.Completed, item)
        end
	elseif objectiveModel:IsComplete() then
		QuestUpdate(quest_id)
		local objective_index = model:GetObjectiveIndex(objective_id)
		--如果界面还没显示，只更新数据
		if instance._IsShow then
			if item == nil then
				warn("任务面板更新出现错误2=",quest_id,objective_id,count)
				return
			end
            --完成任务特效 
			instance:ShowQuestUIFX(QuestDef.UIFxEventType.Completed, item)

			local obj = item:FindChild("Lyout_Content/Fram_Targets/Fram_Targets" .. tostring(objective_index) .. "/Lab_Current")
			if obj then
				--instance._Queue:Push(CTextChangeOpera.new({}, obj, tostring(count)))
				GUI.SetText(obj, tostring(count))
			end
		end
	else
		local objective_index = model:GetObjectiveIndex(objective_id)
		--如果界面还没显示，只更新数据
		if instance._IsShow then
			if item == nil then
				warn("任务面板更新出现错误3=",quest_id,objective_id,count)
				return
			end
            instance:ShowQuestUIFX(QuestDef.UIFxEventType.ObjectCountChange, item)
			local obj = item:FindChild("Lyout_Content/Fram_Targets/Fram_Targets" .. tostring(objective_index) .. "/Lab_Current")
			if obj then
				--instance._Queue:Push(CTextChangeOpera.new({}, obj, tostring(count)))
				GUI.SetText(obj, tostring(count))
			end
		end
	end
end

--任务时间
local function QuestChangeTime(quest_id, time)
	local quest_index = GetQuestIndex(quest_id)
    --如果有特殊副本目标特殊处理
	if instance._SpecialDungeonGoal ~= nil then
		quest_index = quest_index + 1
	end
	local item = instance._List:GetItem(quest_index - 1)
	local Lab_TimeTips = item:FindChild("Lyout_Content/Lab_TimeTips")
	instance:AddQuestTimer(quest_id, Lab_TimeTips, time)
end

--------------------------------------------------------------
------------------------任务事件------------------------------
--------------------------------------------------------------
local function SortFunc(left, right)
	local tl = CElementData.GetQuestTemplate(left) --left:GetTemplate()
	local tr = CElementData.GetQuestTemplate(right) --right:GetTemplate()
	if tl.Type ~= tr.Type then	-- 主线任务 > 支线任务 > 日常任务> 悬赏 > 职业
		--return tl.Type < tr.Type
		return QuestDef.SortIndex[tl.Type+1] < QuestDef.SortIndex[tr.Type+1] 
	end

	local ml = CQuest.Instance():FetchQuestModel(left)
	local mr = CQuest.Instance():FetchQuestModel(right)
	if ml.QuestStatus ~= mr.QuestStatus then
		 return ml.QuestStatus ~= QuestDef.Status.NotRecieved and mr.QuestStatus == QuestDef.Status.NotRecieved
	end

	return tl.Id < tr.Id
end

local function OnQuestEvents(sender, event)
	local name = event._Name
	local data = event._Data
	if name == EnumDef.QuestEventNames.QUEST_INIT then
		OnQuestData(data)
	elseif name == EnumDef.QuestEventNames.QUEST_RECIEVE then		--接任务
		local quest_data = CElementData.GetQuestTemplate(data.Id)

		if quest_data.Type == QuestDef.QuestType.Hang then
			return
		end

		instance:ListItemsNoSelect()
		if IsQuestInProgress(data.Id) then	--如果任务进行中 -> 子任务变化
			--虽然是整体刷新，但是这里的目标是刷新交付文本
			QuestUpdate(data.Id)
			--sort
			if #instance._QuestCurrent > 1 then
				table.sort(instance._QuestCurrent, SortFunc)
			end
			UpdateList()
		else							--如果任务不是进行中，当新任务处理（1.新任务。2.cmd发的任务。3.可多次领取的任务）	
			QuestAdd(data.Id)
		end
	elseif name == EnumDef.QuestEventNames.QUEST_COMPLETE then		--交任务
		local quest_data = CElementData.GetQuestTemplate(data.Id)

		if quest_data.Type == QuestDef.QuestType.Hang then
			return
		end

		instance:ListItemsNoSelect()
		QuestRemove(data.Id)
		
--[[		local quest_data_next = CElementData.GetQuestTemplate(quest_data.DeliverRelated.NextQuestId)
		if quest_data and quest_data_next and not CQuest.Instance():IsAutoProvider(quest_data_next.Id) then
			QuestAdd(quest_data_next.Id)
			-- CQuestAutoMan中已经监听了该消息，直接在相关逻辑中处理，这里不处理自动化逻辑
		end--]]
		
		local result = CQuest.Instance():CanRecieveQuest( quest_data.DeliverRelated.NextQuestId )
		local index = table.indexof(instance._QuestCurrent, quest_data.DeliverRelated.NextQuestId )
		if result and not index then
			QuestAdd(quest_data.DeliverRelated.NextQuestId)
		end

		--添加可以接的新支线
		local subQuests = string.split(quest_data.DeliverRelated.NextSubQuestIds, "*")
		result = false
		if subQuests ~= nil and subQuests[1] ~= "" then
			for i,v in ipairs(subQuests) do
				result = CQuest.Instance():CanRecieveQuest(tonumber(v))
				local index = table.indexof(instance._QuestCurrent, tonumber(v))
				if result and not index then
				--if result then
					QuestAdd(tonumber(v))
					--table.insert(instance._QuestCurrent, #instance._QuestCurrent + 1, tonumber(v))
				end
			end
		end
	elseif name == EnumDef.QuestEventNames.QUEST_CHANGE then		--任务数量变化
		local quest_data = CElementData.GetQuestTemplate(data.QuestId)

		if quest_data.Type == QuestDef.QuestType.Hang then
			return
		end

		QuestChangeCount(data.QuestId, data.ObjectiveId, data.ObjectiveCounter)
	elseif name == EnumDef.QuestEventNames.QUEST_GIVEUP then		--放弃任务
		local quest_id = data
		local quest_data = CElementData.GetQuestTemplate(quest_id)

		if quest_data.Type == QuestDef.QuestType.Hang then
			return
		end

		instance:ListItemsNoSelect()

		QuestRemove(quest_id)
		if not CQuest.Instance():IsAutoProvider(quest_id) and quest_data.Type == QuestDef.QuestType.Main then
			QuestAdd(quest_id)
		end

		--主线任务放弃 播放特效 
		if quest_data.Type == QuestDef.QuestType.Main then
			local item = instance._List:GetItem(0)
			if item ~= nil then
				instance:ShowQuestUIFX(QuestDef.UIFxEventType.Fail, item)
			end
		end
	elseif name == EnumDef.QuestEventNames.QUEST_TIME then		--任务时间
		QuestChangeTime(data.QuestID, data.Seconds)
	end
end

local function OnHostPlayerLevelChangeEvent(sender, event)
	for k,v in pairs( CQuest.Instance()._CompletedMap ) do
		local finishedQuestTmp = CElementData.GetQuestTemplate( k )
		if finishedQuestTmp ~= nil then
			--添加可以接的新支线
			local subQuests = string.split(finishedQuestTmp.DeliverRelated.NextSubQuestIds, "*")
			local result = false
			if subQuests ~= nil and subQuests[1] ~= "" then
				for i1,v1 in ipairs(subQuests) do
					result = CQuest.Instance():CanRecieveQuest(tonumber(v1))
					local index = table.indexof(instance._QuestCurrent, tonumber(v1))
					if result and not index then
						QuestAdd(tonumber(v1))
						--table.insert(instance._QuestCurrent, #instance._QuestCurrent + 1, tonumber(v))
					end
				end
			end
		end
	end
end

local function OnItemChangeEvent(sender, event)
	local itemData = event.ItemUpdateInfo.UpdateItem.ItemData
	for i = 1, #instance._QuestCurrent do
		local quest_model = GetInProcessQuest(instance._QuestCurrent[i])
		if quest_model ~= nil then
			local objectives = quest_model:GetCurrentQuestObjetives()
			local count = 0
			for j = 1, #objectives do
				local obj = objectives[j]
				if obj:GetTemplate().HoldItem._is_present_in_parent then
					if obj:GetTemplate().HoldItem.ItemTId == itemData.Tid then
						QuestChangeCount(quest_model.Id, obj.Id, game._HostPlayer._Package:GetItemCountFromNormalOrTaskPack(itemData.Tid))
					end
				end
			end
		end
	end
end

local function OnNotifyClickEvent(sender, event)
    if event._Param == "Ground" and instance._IdleTipTimer == nil then
        instance:AddIdleTipTimer()
    end
end

-- 开启debug模式刷新任务列表
local function OnOpenDebugModeEvent(sender, event)
	if instance._IsShow then
		UpdateList()
	end
end
--------------------------------------------------------------
------------------------界面基础结构---------------------------
--------------------------------------------------------------
def.static("=>", CPageQuest).Instance = function()
	if instance == nil then
		instance = CPageQuest()
	end
	return instance
end

def.method().Init = function(self)
	self._QuestCurrent = {}
	self._QuestTimer = {}
	CGame.EventManager:addHandler('QuestCommonEvent', OnQuestEvents)
	CGame.EventManager:addHandler('GainNewItemEvent', OnItemChangeEvent)
	CGame.EventManager:addHandler('DebugModeEvent', OnOpenDebugModeEvent)
	CGame.EventManager:addHandler('PlayerGuidLevelUp', OnHostPlayerLevelChangeEvent)
	
end

--添加副本倒计时
def.method("number","userdata","number").AddQuestTimer = function(self, quest_id, lab_time, time)
    self:RemoveQuestTimer(quest_id)
    local callback = function()
        if IsNil(lab_time) then return end          
        lab_time:SetActive(true)
        local strTime = GUITools.FormatTimeFromSecondsToZero(false, time)
        GUI.SetText(lab_time, StringTable.Get(702)..strTime )

        time = time - 1
        if self._QuestTimer[quest_id] ~= nil then
        	self._QuestTimer[quest_id].CurrentRemainingTime = time
        end
        
        if time < 0 then
        	lab_time:SetActive(false)
            self:RemoveQuestTimer(quest_id)
        end
    end
    self._QuestTimer[quest_id] = {}
	self._QuestTimer[quest_id].CurrentRemainingTime = time
    self._QuestTimer[quest_id].CurrentRemainingTimeID = _G.AddGlobalTimer(1, false, callback)
end

def.method("number").RemoveQuestTimer = function(self, questId)
   	if self._QuestTimer[questId] ~= nil then
	    _G.RemoveGlobalTimer(self._QuestTimer[questId].CurrentRemainingTimeID)
	    self._QuestTimer[questId] = nil
	end
end

def.method("userdata").SetRoot = function(self, root)
	self._Panel = root
	self._List = root:GetComponent(ClassType.GNewLayoutTable)
	self._ResetPos = self._Panel.localPosition
end

def.method().Show = function(self)
	if not self._IsShow then
		self._Panel:SetActive(true)
		if self._ResetPos ~= nil then
			self._Panel.localPosition = self._ResetPos
		end
		UpdateList()
	end

	-- 默认切换会打开GFX
	local CQuestAutoMan = require"Quest.CQuestAutoMan"
	if not CQuestAutoMan.Instance():IsOn() then
		self:ListItemsNoSelect()
	end

	self._IsShow = true
end

def.method().ListItemsNoSelect = function(self)
	if self._List ~= nil then
		self._List:SelectItem(-1)
	end
	--print("Clear Selected Quest Item", debug.traceback())
end

def.method("number", "boolean").SetSelectByID = function(self, quest_id, onlyShowGfx)
	if self._List ~= nil then
		local index = GetQuestIndex(quest_id)
		--self._List:NotifyOthers(nil)
		self._List:SelectItem(-1)
		--如果有特殊副本目标特殊处理
		if instance._SpecialDungeonGoal ~= nil then
			index = index + 1
		end
		if index > 0 then
			self._OnlyTrunOnGfxWhenItemSel = onlyShowGfx
			self._List:SelectItem(index-1)
		end

		if onlyShowGfx then CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0) end
		--print("Select Quest Item, index =", index, debug.traceback())
	end
end

local function SetOneObjective(object, data)
	local color = data:GetTextColor()
	local lab_desc = object:FindChild("Lab_Desc")
	GUI.SetText(lab_desc, data:GetDisplayText())
	GUI.SetTextColor(lab_desc, color)
	local count_cur = data:GetCurrentCount()
	if data:IsCountOnce() then
		object:FindChild("Lab_Current"):SetActive(false)
		object:FindChild("Lab_Max"):SetActive(false)
		object:FindChild("Lab_Slash"):SetActive(false)
		object:FindChild("Lab_Time"):SetActive(false)
	elseif data:GetWaitTime() > 0 then
		local remainingTime = data:GetRemainingTime()
		object:FindChild("Lab_Current"):SetActive(false)
		object:FindChild("Lab_Max"):SetActive(false)
		object:FindChild("Lab_Slash"):SetActive(false)
		if remainingTime > 0 then
			object:FindChild("Lab_Time"):SetActive(true)
			instance:AddQuestObjectiveTimer(data,object:FindChild("Lab_Time"),remainingTime)
		else
			object:FindChild("Lab_Time"):SetActive(false)
			instance:RemoveQuestObjectiveTimer(data)
		end
	else
		local lab_cur = object:FindChild("Lab_Current")
		lab_cur:SetActive(true)
		GUI.SetText(lab_cur, tostring(count_cur))
		local lab_max = object:FindChild("Lab_Max")
		lab_max:SetActive(true)
		GUI.SetText(lab_max, tostring(data:GetNeedCount()))
		local lab_slash = object:FindChild("Lab_Slash")
		lab_slash:SetActive(true)
		GUI.SetTextColor(lab_cur, color)
		GUI.SetTextColor(lab_max, color)
		GUI.SetTextColor(lab_slash, color)
		object:FindChild("Lab_Time"):SetActive(false)
	end
end

local function SetObjectives(object, data)
	local status = data:GetStatus()
	if status == QuestDef.Status.NotRecieved then
		object:FindChild("Fram_Targets2"):SetActive(false)
		object:FindChild("Fram_Targets3"):SetActive(false)
		object:FindChild("Fram_Targets4"):SetActive(false)
		local frame = object:FindChild("Fram_Targets1")
		frame:SetActive(true)
		frame:FindChild("Lab_Current"):SetActive(false)
		frame:FindChild("Lab_Max"):SetActive(false)
		frame:FindChild("Lab_Slash"):SetActive(false)
		--frame:FindChild("Gro_Tag"):SetActive(false)
		local lab_desc = frame:FindChild("Lab_Desc")
		GUI.SetText(lab_desc, data:GetProviderText())
		GUI.SetTextColor(lab_desc, EnumDef.QuestObjectiveColor.InProgress)
	--2322new
	elseif status == QuestDef.Status.ReadyToDeliver and data:IsDeliverViaNpc() then
		object:FindChild("Fram_Targets2"):SetActive(false)
		object:FindChild("Fram_Targets3"):SetActive(false)
		object:FindChild("Fram_Targets4"):SetActive(false)
		local frame = object:FindChild("Fram_Targets1")
		frame:SetActive(true)
		frame:FindChild("Lab_Current"):SetActive(false)
		frame:FindChild("Lab_Max"):SetActive(false)
		frame:FindChild("Lab_Slash"):SetActive(false)
		--local img_tag = frame:FindChild("Gro_Tag")
		--img_tag:SetActive(true)
		--GUITools.SetGroupImg(img_tag, 5)
		local lab_desc = frame:FindChild("Lab_Desc")
		GUI.SetText(lab_desc, data:GetDeliverText())
		GUI.SetTextColor(lab_desc, EnumDef.QuestObjectiveColor.Finish)
	elseif status == QuestDef.Status.ReadyToDeliver and data:IsDeliverReceive() then
		local objs = data:GetCurrentQuestObjetives()
		local obj_count = #objs
		for i = 1, MAX_OBJECTIVE_COUNT do
			local frame = object:FindChild(string.format("Fram_Targets%d", i))
			if i > obj_count then
				frame:SetActive(false)
			else
				frame:SetActive(true)
				SetOneObjective(frame, objs[i])
			end
		end
	else
		local objs = data:GetCurrentQuestObjetives()
		local obj_count = #objs
		for i = 1, MAX_OBJECTIVE_COUNT do
			local frame = object:FindChild(string.format("Fram_Targets%d", i))
			if i > obj_count then
				frame:SetActive(false)
			else
				frame:SetActive(true)
				SetOneObjective(frame, objs[i])
			end
		end
	end
end

--添加副本目标倒计时
def.method(CQuestObjectiveModel).RemoveQuestObjectiveTimer = function(self, quest_objectiveModel)
    _G.RemoveGlobalTimer(quest_objectiveModel.CurrentRemainingTimeID)
    quest_objectiveModel.CurrentRemainingTimeID = 0
    self._ObjectiveTimerList[quest_objectiveModel] = 0
end

def.method(CQuestObjectiveModel,"userdata","number").AddQuestObjectiveTimer = function(self, quest_objectiveModel,lab_time,time)
    self:RemoveQuestObjectiveTimer(quest_objectiveModel)
    local callback = function()
        if IsNil(lab_time) then return end           
        local minute = math.floor(time / 60)
        if minute < 10 then
            minute = "0" .. minute
        end
        local second = math.floor(time % 60)
        if second < 10 then
            second = "0" .. second
        end

        lab_time:SetActive(true)
        GUI.SetText(lab_time, minute .. ":" .. second)

        time = time - 1
        if time <= 0 then
        	lab_time:SetActive(false)
            self:RemoveQuestObjectiveTimer(quest_objectiveModel)
            local id = quest_objectiveModel._QuestModel.Id
            QuestUpdate(id)
            local NotifyQuestDataChangeEvent = require "Events.NotifyQuestDataChangeEvent"
            CGame.EventManager:raiseEvent(nil, NotifyQuestDataChangeEvent())

            local QuestWaitTimeFinish = require "Events.QuestWaitTimeFinish"
			local event = QuestWaitTimeFinish()    
			event._QuestId = id
            CGame.EventManager:raiseEvent(nil, event)            
        end
    end
    local timerId = _G.AddGlobalTimer(1, false, callback)
    quest_objectiveModel.CurrentRemainingTimeID = timerId
    self._ObjectiveTimerList[quest_objectiveModel] = timerId
end

------------------------------------------------------
--增加长时间不去执行任务，就播放任务点击提示
------------------------------------------------------
def.method().AddIdleTipTimer = function(self)
    if self._IdleTipTimer then
        self._IdleTipTimer.CurrentRemainingTime = self._IdleTotalTime
    else
        self._IdleTipTimer = {
            CurrentRemainingTime = self._IdleTotalTime,
            CurrentRemainingTimeID = -1
        }
        local startTime = GameUtil.GetServerTime()/1000
        local time = 0
        local callback = function()
            self._IdleTipTimer.CurrentRemainingTime = self._IdleTipTimer.CurrentRemainingTime - 3
            if self._IdleTipTimer.CurrentRemainingTime <= 0 then
		        --如果有特殊副本目标特殊处理
		        local index = 0
				if instance._SpecialDungeonGoal ~= nil then
					index = index + 1
				end
                local item = self._List:GetItem(index)
                self:ShowQuestUIFX(QuestDef.UIFxEventType.IdleTimeTooLang, item)
                _G.RemoveGlobalTimer(self._IdleTipTimer.CurrentRemainingTimeID)
            end
        end
        self._IdleTipTimer.CurrentRemainingTimeID = _G.AddGlobalTimer(3, false, callback)
    end
end
------------------------------------------------------
--移除特效计时
------------------------------------------------------
def.method().RemoveIdleTipTimer = function(self)
    if self._IdleTipTimer ~= nil then
        local item = self._List:GetItem(0)
        if item ~= nil then
            self:StopQuestUIFX(QuestDef.UIFxEventType.IdleTimeTooLang, item)
            _G.RemoveGlobalTimer(self._IdleTipTimer.CurrentRemainingTimeID)
            self._IdleTipTimer = nil
        end
    end
end

def.method("userdata", "number").OnInitItem = function(self, item, index)
	--如果有特殊副本目标特殊处理
	if self._SpecialDungeonGoal ~= nil then
		index = index - 1 
		if index == 0 then
			self:OnInitItemSpecialDungeonGoal(item)
			return
		end
	end
	local data = GetInProcessOrNotRecvQuest(self._QuestCurrent[index])

	local lab_type = item:FindChild("Frame_Top/Lab_Type")
	local str_type = StringTable.Get(536+data:GetTemplate().Type)
	GUI.SetText(lab_type, RichTextTools.GetQuestTypeColorText(str_type, data:GetTemplate().Type) )

	local lab_name = item:FindChild("Frame_Top/Lab_Name")
	local name = ""
	local repeatCount = ""
	if data:GetTemplate().IsRepeated and data:GetTemplate().Type ~= QuestDef.QuestType.Reputation then
		if data.GroupData ~= nil and data.GroupData.MaxFinisNum ~= nil and data.GroupData.MaxFinisNum > 0 and data.GroupData.MaxFinisNum < 999 then
				repeatCount = "(".. data.GroupData.CurFinishNum+1 .. "/"..data.GroupData.MaxFinisNum..")"
		else
			local CompletedCount = data.FinishCount
			local v = CElementData.GetTemplate("CountGroup",data:GetTemplate().CountGroupTid)
			if v ~= nil and v.MaxCount < 999 then
				repeatCount = "(".. CompletedCount+1 .. "/"..v.MaxCount..")"
			end
		end
	end

	if game._IsOpenDebugMode == true then
		name = "(".. data:GetTemplate().Id ..")" .. data:GetTemplate().TextDisplayName..repeatCount
	else
		name = data:GetTemplate().TextDisplayName..repeatCount
	end
	GUI.SetText(lab_name, RichTextTools.GetQuestTypeColorText(name, data:GetTemplate().Type))

    self:ShowQuestUIFX(QuestDef.UIFxEventType.InProgress, item)
    --self:RemoveIdleTipTimer()
	local frame_targets = item:FindChild("Lyout_Content/Fram_Targets")
	local Lab_TimeTips = item:FindChild("Lyout_Content/Lab_TimeTips")
	if Lab_TimeTips ~= nil then
		Lab_TimeTips:SetActive(false)
	end
	if self._QuestTimer[data.Id] ~= nil then
		self:AddQuestTimer(data.Id,Lab_TimeTips,self._QuestTimer[data.Id].CurrentRemainingTime)
	end

	SetObjectives(frame_targets, data)
	
	--任务奖励
	local obj_Prop = item:FindChild("ItemIcon")
	local btn_Prop = item:FindChild("Btn_ItemIcon")
	if obj_Prop ~= nil then
		if data:GetTemplate().RewardId == 0 then
			obj_Prop:SetActive(false)
			btn_Prop:SetActive(false)
		else
			--判断是否为装备
			local rewards = GUITools.GetRewardList(data:GetTemplate().RewardId, false)
			if rewards ~= nil then
				local item = nil
				for i,v in ipairs(rewards) do
					if not v.IsTokenMoney then
						item = CElementData.GetItemTemplate(v.Data.Id)
						if item ~= nil and item.ItemType == EItemType.Equipment then
							break
						end
					end
					item = nil
				end
			
				if item ~= nil then
					obj_Prop:SetActive(true)
					btn_Prop:SetActive(true)
					IconTools.InitItemIconNew(obj_Prop, item.Id)
				else
					obj_Prop:SetActive(false)
					btn_Prop:SetActive(false)
				end
			end
		end 
	end

	--完成 或者 领取 标识
	local obj_Receive = item:FindChild("Img_Receive")
	local obj_Finish = item:FindChild("Img_Finish")
	if obj_Receive ~= nil then
		local status = data:GetStatus()
		if status == QuestDef.Status.NotRecieved then
			obj_Receive:SetActive(true)
			obj_Finish:SetActive(false)
			if obj_Prop ~= nil then
				obj_Prop:SetActive(false)
				btn_Prop:SetActive(false)
			end
		elseif status == QuestDef.Status.ReadyToDeliver and data:IsDeliverViaNpc() then
			obj_Receive:SetActive(false)
			obj_Finish:SetActive(true)
			instance:ShowQuestUIFX(QuestDef.UIFxEventType.Finish, item)
			if obj_Prop ~= nil then
				obj_Prop:SetActive(false)
				btn_Prop:SetActive(false)
			end
		elseif status == QuestDef.Status.ReadyToDeliver and data:IsDeliverReceive() then
			obj_Receive:SetActive(false)
			obj_Finish:SetActive(true)
			instance:ShowQuestUIFX(QuestDef.UIFxEventType.Finish, item)
			if obj_Prop ~= nil then
				obj_Prop:SetActive(false)
				btn_Prop:SetActive(false)
			end
		else
			obj_Receive:SetActive(false)
			obj_Finish:SetActive(false)
		end
	end
end

def.method("userdata", "number").OnSelectItem = function(self, item, index)
	if self._OnlyTrunOnGfxWhenItemSel then
		self._OnlyTrunOnGfxWhenItemSel = false
		return
	end

	local hp = game._HostPlayer
	if hp:IsDead() then
		game._GUIMan:ShowTipText(StringTable.Get(30103), false)
	    return
	end
	
	--采集状态 点击页面后特殊处理
	hp:SetMineGatherId(0)
	
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	local CAutoFightMan = require "ObjHdl.CAutoFightMan"
	local CQuestAutoMan = require "Quest.CQuestAutoMan"

	--如果有特殊副本目标特殊处理
	if self._SpecialDungeonGoal ~= nil then
		index = index - 1 
		if index == 0 then
			hp:StopAutoFollow()
			CQuestAutoMan.Instance():Stop()
			CAutoFightMan.Instance():Start() 
			CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, false) 
		    CDungeonAutoMan.Instance():Start()
			return
		end
	end

	local data = GetInProcessOrNotRecvQuest(self._QuestCurrent[index])
	if data then
		self._SelectQuestID = data.Id

		--如果在队中 并且 不是队长 完成赏金任务		
		if CTeamMan.Instance():InTeam() and not CTeamMan.Instance():IsTeamLeader() and data:GetTemplate().Type == QuestDef.QuestType.Reward then
			CTeamMan.Instance():FollowLeader(true)
		else
			hp:StopAutoFollow()
            if CQuestAutoMan.Instance():IsScriptClickQuestPage() then
                CTransManage.Instance():EnableManualModeOnce(false)
            end

			local CQuestAutoGather = require "Quest.CQuestAutoGather"
			if CQuestAutoGather.Instance()._CollectQuestID ~= data.Id then
				CQuestAutoGather.Instance():Stop()
			end
			CDungeonAutoMan.Instance():Stop()

			local function AutoLogic()
				hp:Stand()
				CAutoFightMan.Instance():Start()
				CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.QuestFight, self._QuestCurrent[index], false)
				local questAutoMan = CQuestAutoMan.Instance()
				-- 如果当前任务处于自动化中，忽略
				--if not questAutoMan:IsQuestInAuto(data) then
					questAutoMan:Start(data)
					data:DoShortcut()
				--end
			end
			if hp:IsInCanNotInterruptSkill() then   -- 技能状态
				hp:AddCachedAction(AutoLogic)
			else
				AutoLogic()
			end
		end
	end
end

def.method("userdata", "string", "number").OnSelectItemButton = function(self, item, button, index)
	local data = GetInProcessOrNotRecvQuest(self._QuestCurrent[index])
	if button == "Btn_ItemIcon" then
		local rewards = GUITools.GetRewardList(data:GetTemplate().RewardId, false)
		local prop = nil
		for i,v in ipairs(rewards) do
			prop = CElementData.GetItemTemplate(v.Data.Id)
			if prop ~= nil and prop.ItemType == EItemType.Equipment then
				break
			end
			prop = nil
		end

		if prop ~= nil then
			CItemTipMan.ShowItemTips(prop.Id,TipsPopFrom.OTHER_PANEL,item,TipPosition.FIX_POSITION)
		end
	end
end

----------------------------------------------------
--显示任务状态的UI特效
----------------------------------------------------
def.method("number", "userdata").ShowQuestUIFX = function(self, stateType, item)
    if item == nil then return end
    if stateType == QuestDef.UIFxEventType.InProgress then
        --任务选中特效 
        local anchor_up = item:FindChild("Fx_Up")
        local anchor_down = item:FindChild("Fx_Down")
        if anchor_up ~= nil and anchor_down~= nil then
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Current_Mission_1, anchor_up, anchor_up, self._Panel)
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Current_Mission_2, anchor_down, anchor_down, self._Panel)
        end
    elseif stateType == QuestDef.UIFxEventType.ObjectCountChange then
        --任务变化特效 
		local anchor_mid = item:FindChild("Fx_Up")
		if anchor_mid ~= nil then
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Mission_Change, anchor_mid, item, self._Panel)
            local obj_fx1 = item:FindChild("Img_EffectFinish1")
            local obj_fx2 = item:FindChild("Img_EffectFinish2")
            obj_fx1:SetActive(true)
            obj_fx2:SetActive(true)
            obj_fx1:GetComponent(ClassType.DOTweenAnimation):DORestart(false)
            obj_fx2:GetComponent(ClassType.DOTweenAnimation):DORestart(false)
		end
    elseif stateType == QuestDef.UIFxEventType.Completed then
        --任务完成特效显示
        local anchor_mid = item:FindChild("Fx_Up")
		if anchor_mid ~= nil then
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Mission_Complete, anchor_mid, item, self._Panel)
		end
	elseif stateType == QuestDef.UIFxEventType.Finish then
        --任务完成特效显示
        local anchor_mid = item:FindChild("Img_Finish")
		if anchor_mid ~= nil then
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Mission_Finish, anchor_mid, item, self._Panel)
		end
	elseif stateType == QuestDef.UIFxEventType.Fail then
        --任务完成特效显示
--[[        local anchor_mid = item:FindChild("Fx_Up")
		if anchor_mid ~= nil then
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Mission_Fail, anchor_mid, item.parent, self._Panel)
		end--]]
        local anchor_mid = item:FindChild("Fx_Up")
		if anchor_mid ~= nil then
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Mission_Fail, anchor_mid, item, item)
		end
    elseif stateType == QuestDef.UIFxEventType.IdleTimeTooLang then
        local anchor_point = item
        if anchor_point ~= nil then 
            GameUtil.PlayUISfxClipped(PATH.UIFX_QuestN_Mission_IdleTooLang, anchor_point, anchor_point , self._Panel)
        end
    end
end
----------------------------------------------------
--隐藏任务状态的UI特效
----------------------------------------------------
def.method("number", "userdata").StopQuestUIFX = function(self, stateType, item)
    if stateType == QuestDef.UIFxEventType.IdleTimeTooLang then
        local anchor_point = item
        if anchor_point ~= nil then
            GameUtil.StopUISfx(PATH.UIFX_QuestN_Mission_IdleTooLang, anchor_point)
        end
    end
end

def.method("table").AddSpecialDungeonGoal = function(self,DungeonGoal)
	--如果界面还没显示，只更新数据
	if self._SpecialDungeonGoal ~= nil and self._SpecialDungeonGoalItem ~= nil then
		self:OnInitItemSpecialDungeonGoal(self._SpecialDungeonGoalItem)
	else
		self._SpecialDungeonGoal = DungeonGoal
		if instance._IsShow then
			--instance._Queue:Push(CListAddOpera.new({}, instance._List, 0))
			instance._List:AddItem(0)
		end
	end
end

local function SetGoalShow(object, goalData, dungeonGoal)
	--EnumDef.QuestObjectiveColor.Finish or EnumDef.QuestObjectiveColor.InProgress
	--local img_tag = object:FindChild("Gro_Tag")
	--img_tag:SetActive(false)

	local color = EnumDef.QuestObjectiveColor.InProgress
	local lab_desc = object:FindChild("Lab_Desc")

	local strDescrip = CElementData.GetTextTemplate(goalData.TextID)
	if strDescrip ~= nil and strDescrip.TextContent ~= nil then
		GUI.SetText(lab_desc, strDescrip.TextContent)
	else
		GUI.SetText(lab_desc, dungeonGoal.Description)
	end
	GUI.SetTextColor(lab_desc, color)

	local count_cur = goalData.CurCount
	local lab_cur = object:FindChild("Lab_Current")
	lab_cur:SetActive(true)
	GUI.SetText(lab_cur, tostring(count_cur))
	local lab_max = object:FindChild("Lab_Max")
	lab_max:SetActive(true)
	GUI.SetText(lab_max, tostring(goalData.MaxCount))
	local lab_slash = object:FindChild("Lab_Slash")
	lab_slash:SetActive(true)
	GUI.SetTextColor(lab_cur, color)
	GUI.SetTextColor(lab_max, color)
	GUI.SetTextColor(lab_slash, color)
	object:FindChild("Lab_Time"):SetActive(false)
end


def.method("userdata").OnInitItemSpecialDungeonGoal = function(self,item)
	self._SpecialDungeonGoalItem = item
	local dungeonID = game._DungeonMan:GetDungeonID()
	local dungeonInfo = CElementData.GetInstanceTemplate(dungeonID) 
	local allGoals = game._DungeonMan:GetAllDungeonGoal()

	local lab_type = item:FindChild("Frame_Top/Lab_Type")
	local str_type = StringTable.Get(536+QuestDef.QuestType.Activity)
	GUI.SetText(lab_type, RichTextTools.GetQuestTypeColorText(str_type, QuestDef.QuestType.Activity) )

	local lab_name = item:FindChild("Frame_Top/Lab_Name")
	local name = ""
	name = dungeonInfo.TextDisplayName
	GUI.SetText(lab_name, RichTextTools.GetQuestTypeColorText(name, QuestDef.QuestType.Activity))

    self:ShowQuestUIFX(QuestDef.UIFxEventType.InProgress, item)


	local frame_targets = item:FindChild("Lyout_Content/Fram_Targets")
	local Lab_TimeTips = item:FindChild("Lyout_Content/Lab_TimeTips")
	if Lab_TimeTips ~= nil then
		Lab_TimeTips:SetActive(false)
	end

	if self._SpecialDungeonGoalTime == -1 then
		self._SpecialDungeonGoalTime = math.round((game._DungeonMan:GetInstanceEndTime() - GameUtil.GetServerTime())/1000) 
	end

	_G.RemoveGlobalTimer(self._SpecialDungeonGoalTimeId)
    local callback = function()
        if IsNil(Lab_TimeTips) then return end          
        Lab_TimeTips:SetActive(true)
        local strTime = GUITools.FormatTimeFromSecondsToZero(false, self._SpecialDungeonGoalTime)
        GUI.SetText(Lab_TimeTips, StringTable.Get(702)..strTime )

        self._SpecialDungeonGoalTime = self._SpecialDungeonGoalTime - 1
        --self._SpecialDungeonGoalTime = time
        
        if self._SpecialDungeonGoalTime < 0 then
        	Lab_TimeTips:SetActive(false)
           	if self._SpecialDungeonGoalTimeId ~= 0 then
			    --_G.RemoveGlobalTimer(self._SpecialDungeonGoalTimeId)
			    --self._SpecialDungeonGoalTimeId = 0
			    self:RemoveSpecialDungeonGoal()
			end
        end
    end
    self._SpecialDungeonGoalTimeId = _G.AddGlobalTimer(1, false, callback)

	local obj_count = #allGoals
	for i = 1, MAX_OBJECTIVE_COUNT do
		local frame = frame_targets:FindChild(string.format("Fram_Targets%d", i))
		if i > obj_count then
			frame:SetActive(false)
		else
			frame:SetActive(true)
			SetGoalShow(frame, allGoals[i], dungeonInfo)
		end
	end

	--任务奖励
	local obj_Prop = item:FindChild("ItemIcon")
	local btn_Prop = item:FindChild("Btn_ItemIcon")
	if obj_Prop ~= nil then
		obj_Prop:SetActive(false)
		btn_Prop:SetActive(false)
	end
end

def.method().RemoveSpecialDungeonGoal = function(self)
	--如果有特殊副本目标特殊处理
	if self._SpecialDungeonGoal ~= nil then
		self._SpecialDungeonGoal = nil
		self._SpecialDungeonGoalItem = nil
		_G.RemoveGlobalTimer(self._SpecialDungeonGoalTimeId)
		self._SpecialDungeonGoalTime = -1
		self._SpecialDungeonGoalTimeId = 0
		--instance._Queue:Push(CListRemoveOpera.new({}, instance._List, 0))
		instance._List:RemoveItem(0)
	end
end

def.method("number").UpdateSpecialDungeonGoal = function(self,nIndex)
	--如果有特殊副本目标特殊处理
	if self._SpecialDungeonGoal ~= nil then
	 	local dungeonGoal = game._DungeonMan:GetDungeonGoalByIndex(nIndex)
		local dungeonID = game._DungeonMan:GetDungeonID()


		local frame_targets = self._SpecialDungeonGoalItem:FindChild("Lyout_Content/Fram_Targets")
		local dungeonPanel = frame_targets:FindChild(string.format("Fram_Targets%d", nIndex))

		--目标当前个数
		local labCount =  dungeonPanel: FindChild("Lab_Current")
		local labDescribe = dungeonPanel:FindChild("Lab_Desc")
		local labMaxCount =  dungeonPanel:FindChild("Lab_Max")
		local labSlash = dungeonPanel:FindChild("Lab_Slash")
		if not IsNil(labCount) then
			GUI.SetText(labCount, tostring(dungeonGoal.CurCount))
		end

		self:ShowQuestUIFX(QuestDef.UIFxEventType.ObjectCountChange, self._SpecialDungeonGoalItem)

		if dungeonGoal.CurCount >= dungeonGoal.MaxCount then
			GameUtil.SetTextColor(labCount:GetComponent(ClassType.Text), EnumDef.QuestObjectiveColor.Finish)
			GameUtil.SetTextColor(labDescribe:GetComponent(ClassType.Text), EnumDef.QuestObjectiveColor.Finish)
			GameUtil.SetTextColor(labMaxCount:GetComponent(ClassType.Text), EnumDef.QuestObjectiveColor.Finish)
			GameUtil.SetTextColor(labSlash:GetComponent(ClassType.Text), EnumDef.QuestObjectiveColor.Finish)
		end
	end
end

def.method().Hide = function(self)
	if self._IsShow then
		self._Panel.localPosition = Vector3.New(10000,10000,10000)
		--self._Panel:SetActive(false)
	end
	self._IsShow = false

	if self._Quest_ClickTimer_id ~= 0 then
    	_G.RemoveGlobalTimer(self._Quest_ClickTimer_id)
    	self._Quest_ClickTimer_id = 0
	end
	self._SelectQuestID = 0
end

def.method().Release = function(self)
	self:Hide()

	for k,v in pairs(self._QuestTimer) do
		self:RemoveQuestTimer(k)
	end
	self._QuestTimer = {}

    if self._IdleTipTimer ~= nil then
        _G.RemoveGlobalTimer(self._IdleTipTimer.CurrentRemainingTimeID)
        self._IdleTipTimer = nil
    end

	self._QuestCurrent = {}

	for k,v in pairs(self._ObjectiveTimerList) do
		_G.RemoveGlobalTimer(v)
	end
	self._ObjectiveTimerList = {}

	CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestEvents)
	CGame.EventManager:removeHandler('GainNewItemEvent', OnItemChangeEvent)
	CGame.EventManager:removeHandler('DebugModeEvent', OnOpenDebugModeEvent)
	CGame.EventManager:removeHandler('PlayerGuidLevelUp', OnHostPlayerLevelChangeEvent)
	
end

def.method().Destroy = function(self)
	self:Release()

	self._Panel = nil
	self._List = nil
	self._ListObject = nil

	instance = nil
end

CPageQuest.Commit()
return CPageQuest 