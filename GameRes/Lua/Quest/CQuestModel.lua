local Lplus = require 'Lplus'
local CElementData = require "Data.CElementData"
local CQuestObjectiveModel = require "Quest.CQuestObjectiveModel"
local QuestDef = require "Quest.QuestDef"
local EWorldType = require "PB.Template".Map.EWorldType
local CQuest = Lplus.ForwardDeclare("CQuest")
local CQuestModel = Lplus.Class('CQuestModel')
local def = CQuestModel.define

--当前任务
def.field("number").Id = 0
def.field("number").ProvideTimestamp = 0
def.field("number").Status = 0                                      --此属性前端负责更新，为了不产生冲突前端使用QuestStatus属性
def.field("table").Objectives = BlankTable 
def.field("number").CurrentSubQuestId = 0                           --当前的子任务id
def.field("number").CurrentSubQuestSuccess = 0                      --一共完成的子任务成功次数
def.field("number").CurrentSubQuestFailed = 0
def.field("table").CurrentSubFinishedQuests = BlankTable            --已完成的子任务列表
def.field("number").CurrentRemainingTime = -1                        --当前的子任务剩余时间
def.field("number").CurrentRemainingTimeID = 0                       --当前的子任务剩余时间ID

--完成任务
def.field("number").DeliverTimestamp    = 0
def.field("number").FinishCount			= 0
def.field("number").FinishParam		    = 0

--扩展属性
def.field("number").QuestStatus = QuestDef.Status.InProgress
def.field("boolean").QuestStatusDirty = false                       --任务状态脏标记
def.field("table")._ListObjective = nil                             --当前任务目标列表
def.field("table").GroupData = BlankTable                             --任务组显示数据

local function UpdateQuestModel(obj, sourceTable)
    if sourceTable == nil then return nil end
    local meta = getmetatable(CQuestModel)
    for k, v in pairs(meta.fields) do
        local value = sourceTable[k]
        if value ~= nil then
            obj[k] = value
        end
    end
end

def.static("table", "=>", CQuestModel).new = function(source)
    if not source then return nil end

    local o = CQuestModel()
    UpdateQuestModel(o, source)

    if not source.QuestStatus then
        o.QuestStatusDirty = true
    end
    return o
end

def.method("table").UpdateData = function(self, data)
    UpdateQuestModel(self, data)
end


def.method("=>","table").GetTemplate = function(self)
    return CElementData.GetQuestTemplate(self.Id)
end

--local tmpOpen = false

def.method("=>", "number").CalculateStatus = function(self)
    local quest_data = self:GetTemplate()
    if quest_data.IsPartentQuest then
        if self.CurrentSubQuestSuccess < quest_data.SubQuestRelated.SuccessedCount then
            return QuestDef.Status.InProgress
        end
    else
        if not self:IsAllObjetivesCompleted() then
            return QuestDef.Status.InProgress
        end
    end

    -- if tmpOpen then
    --     print("临时检测当前任务状态的 LOG,查完错后会关闭")
    --     print("如果当前任务状态是任务已经完成 ReadyToDeliver",self.Id)
    --     print("quest_data.IsPartentQuest=",quest_data.IsPartentQuest)
    --     print("self:IsAllObjetivesCompleted()",self:IsAllObjetivesCompleted())
    -- end
    return QuestDef.Status.ReadyToDeliver
end

def.method("=>", "boolean").IsAllObjetivesCompleted = function(self)
    local objectives = self:GetCurrentQuestObjetives()
    for k,v in pairs(objectives) do
        if not v:IsComplete() then
            return false
        end
    end
    return true
end

--判断任务跟随NPC ID
def.method("=>","table").GetAssistNpc = function(self)
    local AssistNpcDatas = {}

    local temp = self:GetTemplate()
    local id = -1

    if temp.EventRelated._is_present_in_parent then
        local events = temp.EventRelated.QuestEvents
        for i = 1, #events do
            if events[i].AssistNpc._is_present_in_parent then
                AssistNpcDatas[#AssistNpcDatas+1] = 
                {
                    NpcTID = events[i].AssistNpc.NpcTID,
                    MapID = events[i].AssistNpc.MapID,
                    RegionID = events[i].AssistNpc.RegionID,
                }
            end
        end

    end
    --print_r(AssistNpcDatas)
    return AssistNpcDatas
end

--找到需要传送到的地图
def.method("number","=>","number","number").GetTargetMapTIDByAssistNpc = function(self,NpcTID)
    local npcs = self:GetAssistNpc()
    for i,v in ipairs(npcs) do
        if NpcTID == v.NpcTID then
            return  v.MapID,v.RegionID     
        end
    end
    return 0,0
end

def.method("=>","number").GetStatus = function(self)
    if self.QuestStatusDirty then
        self.QuestStatus = self:CalculateStatus()
        self.QuestStatusDirty = false
        -- if tmpOpen then
        --     print("临时检测当前任务状态，走了下脏标记",self.QuestStatus)
        -- end
    end
    -- if tmpOpen then
    --     print("临时检测当前任务状态，第二次",self.QuestStatus)
    --     tmpOpen = false
    -- end
    return self.QuestStatus
end

def.method("number").SetStatus = function(self, status)
    self.QuestStatus = status
    self.QuestStatusDirty = false
end

def.method("number", "number", "boolean").UpdateObjectiveCount = function(self, objective_id, count, notify_server)
    local obj = self:GetObjectiveById(objective_id)
    if obj then
        obj:SetCurrentCount(count)
        if obj:IsComplete() and self:IsAllObjetivesCompleted() then
            self.CurrentSubQuestSuccess = self.CurrentSubQuestSuccess + 1
            table.insert(self.CurrentSubFinishedQuests, self.CurrentSubQuestId)
        end
        self.QuestStatusDirty = true

        -- 仅在 物品获取满足条件后，才发送此协议；其他完成条件由服务器判定
        if notify_server and obj:IsComplete() then
            local prot = GetC2SProtocol("C2SQuestReachObj")
            prot.QuestId = self.Id
            SendProtocol(prot)
        end

        --跑去 等待时间类型
        local temp = obj:GetTemplate()
        if not temp.WaitTime._is_present_in_parent then
            local Des = string.format(obj:GetDisplayText() .. "  " .. obj:GetCurrentCount() .. "/" .. obj:GetNeedCount())
            game._GUIMan:ShowAttentionTips(Des, 1, 3)
        end
    end
end

def.method("number","=>", CQuestObjectiveModel).GetObjectiveById = function(self, id)
    local objs = self:GetCurrentQuestObjetives()
    for k,v in pairs(objs) do
        if v.Id == id then
            return v
        end
    end
    return nil
end

def.method("number","=>","table").GetCurrentObjetiveById = function(self, id)
    for k,v in pairs(self.Objectives) do
        if v.Id == id then
            return v
        end
    end
    return nil
end

def.method("number","=>","number").GetObjectiveIndex = function(self, objective_id)
    local objs = self:GetCurrentQuestObjetives()
    for i = 1, #objs do
        if objs[i].Id == objective_id then
            return i
        end
    end
    return 0
end

def.method("=>","table").GetCurrentQuestObjetives = function(self)
    if self._ListObjective == nil then  
        local quest_data = self:GetTemplate()
        if quest_data.IsPartentQuest then
            if self.CurrentSubQuestId == 0 then return {} end
            quest_data = CElementData.GetQuestTemplate(self.CurrentSubQuestId)
        end
        if quest_data ~= nil then
            self._ListObjective = {}
            local datas = quest_data.ObjectiveRelated.QuestObjectives
            if datas and #datas > 0 then
                for i = 1, #datas do
                    local o = datas[i]
                    if o then
                        local objctive = CQuestObjectiveModel.new()
                        objctive:Init(self, quest_data.Id, o, self:GetTemplate().Id)
                        table.insert(self._ListObjective, objctive)
                    end
                end
            end
        end
    end
    return self._ListObjective
end

def.method("=>", CQuestObjectiveModel).GetCurrentObjective = function(self)
    local objs = self:GetCurrentQuestObjetives()
    for i = 1, #objs do
        if not objs[i]:IsComplete() then
            return objs[i]
        end
    end
    return nil
end

def.method("=>", "boolean").IsCompleteAll = function(self)
    return self:GetStatus() == QuestDef.Status.ReadyToDeliver
end

def.method("=>", "boolean").IsQuestInProgress = function(self)
    return self:GetStatus() == QuestDef.Status.InProgress
end

def.method("number", "=>", "boolean").IsSubQuestComplete = function(self, sub_quest_id)
    if self.CurrentSubFinishedQuests then
        local qs = self.CurrentSubFinishedQuests
        for i = 1, #qs do
            if qs[i] == sub_quest_id then
                return true
            end
        end
    end
    return false
end

def.method().DoShortcut = function(self)
    --tmpOpen = true
    local questTemp = self:GetTemplate()

    local status = self:GetStatus()
    if status == QuestDef.Status.NotRecieved then
        self:NavigatToProviderNpc()
    elseif status == QuestDef.Status.InProgress then
        local cur_objective = self:GetCurrentObjective()
        if cur_objective then
            cur_objective:DoShortcut()
        else    
            --如果获取的当前进行目标为空，当作完成处理
            --TERA-2385 注销掉，会引起 当任务完成的协议还没有到达客户端，马上点击，就会去找任务NPC
            warn("该任务寻路目标没有发放，稍等")
        end
    elseif status == QuestDef.Status.ReadyToDeliver then
        if self:IsDeliverViaNpc() then
            self:NavigatToDeliverNpc()
        elseif self:IsDeliverReceive() then
            local function cb()
                CQuest.Instance():DoDeliverQuest2(self.Id)
            end

            local quest_data = self:GetTemplate()
            if quest_data.RewardId ~= 0 then
                game._GUIMan:Open("CPanelUIQuestReward", { _QuestId = self.Id, OnFinish = cb })
                --warn("P2")
                --game._CGameTipsQ:ShowQuestFinishReward(self.Id, cb)
            else
                cb()
            end
        end
        
    elseif status == QuestDef.Status.Completed then
        warn("该任务已经完成，不能寻路")
    elseif status == QuestDef.Status.Failed then
        warn("该任务为失败状态，不能寻路")
    end
end

def.method("=>","number","table").GetShortcutWorldIDAndPos = function(self)
    local sceneID,targetPos = 0,nil
    local cur_objective = self:GetCurrentObjective()
    if cur_objective then
        sceneID,targetPos = cur_objective:GetShortcutWorldIDAndPos()
    end 
    return sceneID,targetPos
end

def.method("=>", "string").GetDeliverText = function(self)
    local result = ""
    if IsNilOrEmptyString(self:GetTemplate().DeliverRelated.DeliverText) then
        if self:GetTemplate().DeliverRelated.ViaNpc._is_present_in_parent then
            local npc_temp = CElementData.GetNpcTemplate(self:GetTemplate().DeliverRelated.ViaNpc.NpcId)
            if npc_temp then
                result = string.format(StringTable.Get(522), npc_temp.TextOverlayDisplayName)
            end
        end
    else
        result = self:GetTemplate().DeliverRelated.DeliverText
    end
    if IsNilOrEmptyString(result) then
        warn("交付文本为空")
    end
    return result
end

def.method("=>", "string").GetProviderText = function(self)
    local result = ""
    if IsNilOrEmptyString(self:GetTemplate().ProvideRelated.ProvideText) then
        if self:GetTemplate().ProvideRelated.ProvideMode.ViaNpc._is_present_in_parent then
            local npc_temp = CElementData.GetNpcTemplate(self:GetTemplate().ProvideRelated.ProvideMode.ViaNpc.NpcId)
            if npc_temp then
                result = string.format(StringTable.Get(534), npc_temp.TextOverlayDisplayName)
            end
        end
    else
        result = self:GetTemplate().ProvideRelated.ProvideText
    end
    if IsNilOrEmptyString(result) then
        warn("领取文本为空")
    end
    return result
end

def.method("number","=>","table").GetObjectiveTemplateById = function(self, objective_id)
    for k,v in pairs(self:GetTemplate().ObjectiveRelated.QuestObjectives) do
        if v.Id == objective_id then
            return v
        end
    end
    return nil
end

--导航找到接任务NPC
def.method().NavigatToProviderNpc = function(self)
    local template = self:GetTemplate()
    local npc_tid = template.ProvideRelated.ProvideMode.ViaNpc.NpcId
    local CQuestNavigation = require "Quest.CQuestNavigation"
    CQuestNavigation.Instance():NavigatToNpc(npc_tid, {EnumDef.ServiceType.ProvideQuest, self.Id})
end

--导航找到交任务NPC
def.method().NavigatToDeliverNpc = function(self)
    local template = self:GetTemplate()
    local npc_tid = template.DeliverRelated.ViaNpc.NpcId

    --不要删除 找到实时跟随NPC 所用
    local map_tid,region_tid = self:GetTargetMapTIDByAssistNpc(npc_tid)

    local IsInMap = false
    if map_tid == 0 or game._CurWorld._WorldInfo.MapTid == map_tid then
        IsInMap = true
    end 

    local IsInRegion = false
    for k, v in ipairs(game._HostPlayer._CurrentRegionIds) do
        if v == region_tid then
           IsInRegion = true
           break
        end
    end
    if region_tid == 0 then
        IsInRegion = true
    end

    if not IsInMap or not IsInRegion then
        local CTransManage = require "Main.CTransManage"        
        print("=====",map_tid,region_tid) 
        if region_tid == 0 then
            CTransManage.Instance():TransToCity(map_tid)
        else
            CTransManage.Instance():TransToRegionIsNeedBroken(map_tid,region_tid,true,nil, true)  
        end
        return
    end

    local CQuestNavigation = require "Quest.CQuestNavigation"
    CQuestNavigation.Instance():NavigatToNpc(npc_tid, {EnumDef.ServiceType.DeliverQuest, self.Id})
end

--是否激活
def.method("=>","boolean").IsActive = function(self)
    return CQuest.Instance():IsActive(self.Id)
end

--是否需要找到交任务的NPC
def.method("=>", "boolean").IsDeliverViaNpc = function(self)
    return CQuest.Instance():IsDeliverViaNpc(self.Id)
end

--是否自动交付
def.method("=>","boolean").IsAutoDeliver = function(self)
    return CQuest.Instance():IsAutoDeliver(self.Id)
end

--是否手动领取奖交付
def.method("=>","boolean").IsDeliverReceive = function(self)
    return CQuest.Instance():IsDeliverReceive(self.Id)
end

--是否自动接任务
def.method("=>","boolean").IsAutoProvider = function(self)
    return CQuest.Instance():IsAutoProvider(self.Id)
end

--是否满足等级条件
def.method("=>", "boolean").IsLevelSatisfy = function(self)
    return CQuest.Instance():IsLevelSatisfy(self.Id)
end

--是否满足前置任务条件
def.method("=>", "boolean").IsPreQuestSatisfy = function(self)
    return CQuest.Instance():IsPreQuestSatisfy(self.Id)
end

CQuestModel.Commit()
return CQuestModel