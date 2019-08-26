local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CGame = Lplus.ForwardDeclare("CGame")
local CQuest = require "Quest.CQuest"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CAutoFightBase = require "AutoFight.CAutoFightBase"
local CQuestNavigation = require "Quest.CQuestNavigation"
local CTransManage = require "Main.CTransManage"
local CElementData = require "Data.CElementData"
local QuestDef = require "Quest.QuestDef"
local CTeamMan = require "Team.CTeamMan"

local CQuestAutoFight = Lplus.Extend(CAutoFightBase, "CQuestAutoFight")
local def = CQuestAutoFight.define

def.field('number')._QuestTid = -1

local DistanceH = Vector3.DistanceH
local SqrDistanceH = Vector3.SqrDistanceH_XZ

local instance = nil

def.static("=>", CQuestAutoFight).Instance = function ()
    if instance == nil then
        instance = CQuestAutoFight()  
        CAutoFightBase.Init(instance)
        instance._TargetTidList = {}
        instance._QuestTid =  -1
    end
    return instance
end

local function IsTargetProper(tid)
    if instance then
        if #instance._TargetTidList == 0 then 
            return true 
        end

        for i = 1, #instance._TargetTidList do 
            if instance._TargetTidList[i] == tid then                                    
                return true
            end                                
        end
    end
    return false
end

local function IsDistanceOk(v)
    if instance then
        if #instance._TargetTidList > 0 then return true end  
        local searchRadius = instance._AutoFightConfig.SearchRadius     
        local max_dis_sqr =  searchRadius * searchRadius
        local hp = game._HostPlayer
        local pos1x, pos1z = hp:GetPosXZ()
        local pos2x, pos2z = v:GetPosXZ()
        if SqrDistanceH(pos1x, pos1z, pos2x, pos2z) <= max_dis_sqr then
            return true
        end
    end

    return false
end

-- 筛选函数
local function MonsterFilter(v)
    if not IsTargetProper(v:GetTemplateId()) then
        return false
    end

    if v:GetRelationWithHost() ~= "Enemy" or not IsDistanceOk(v) then 
        return false 
    end

    return true
end

-- 筛选函数
local function PlayerFilter(v)
    if v:GetRelationWithHost() ~= "Enemy" or not IsDistanceOk(v) then 
        return false 
    end

    if game._HostPlayer:IsEntityHate(v._ID) then
        return true
    end

    return false
end

local function IsCurQuestKillingEnd(self)  
    if self._QuestTid <= 0 then return true end

    if #instance._TargetTidList == 0 then return true end

    local quest_model = CQuest.Instance():GetInProgressQuestModel(self._QuestTid)
    if quest_model then  
        local quest_objs = quest_model:GetCurrentQuestObjetives()
        for i = 1, #quest_objs do                                             
            local objectiveModel = quest_model:GetObjectiveById(quest_objs[i].Id) 
            if not objectiveModel:IsComplete() and objectiveModel:GetQuestTargetMonsters() ~= nil then
                return false    
            end                                        
        end
    end 

    return true
end

--Timer
local function Tick()
    if instance == nil then 
        return 
    end

    if instance._Paused then return end
    
    if CTeamMan.Instance():IsFollowing() then return end
        
    -- 优先任务目标，任务目标完成后，切换到World模式
    local isPass = IsCurQuestKillingEnd(instance)
    if isPass then 
        -- 任务模式自动战斗在完成当前任务怪击杀目标后，不要做关闭处理，如果调用内部Self.Stop会导致UI状态与行为不一致
        --local CAutoFightMan = require("AutoFight.CAutoFightMan")
        --CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, false)
        --host_player:StartAutoDetectTarget()
        return 
    end

    local host_player = game._HostPlayer
    --锁定目标检测
    local curTarget = nil
    if instance:IsLockedCurTarget() then
        curTarget = host_player._CurTarget
        if curTarget:GetRelationWithHost() ~= "Enemy" then return end
    else
        -- 获取目标与位置
        curTarget = instance:FindTarget(true, MonsterFilter, PlayerFilter)
        if curTarget and curTarget:GetObjectType() == OBJ_TYPE.ELSEPLAYER then
            host_player:UpdateTargetInfo(curTarget, true)
        else
            host_player:UpdateTargetInfo(curTarget, false)
        end
    end
    
    if curTarget ~= nil and (IsTargetProper(curTarget:GetTemplateId()) or instance:IsLockedCurTarget()) then
        -- 找到合适目标 战斗 释放主角技能
        --host_player:StopAutoDetectTarget()
        instance:ExecHostSkill(curTarget)
    else
        -- 继续执行任务逻辑，如果存在多个任务点，去下一个地方尝试
        local questModel = CQuest.Instance():GetInProgressQuestModel(instance._QuestTid)
        if questModel ~= nil then
            --host_player:StartAutoDetectTarget()
            CTransManage.Instance():EnableManualModeOnce(false)
            questModel:DoShortcut() 
        end  
    end
end

def.override("number").Start = function(self, questTid)
    local host_player = game._HostPlayer
    if host_player == nil then 
        return 
    end

    if questTid <= 0 then return end

    self._Paused = false
    self._QuestTid = questTid

    -- 分析任务数据，找出优先目标
    do
        self._TargetTidList = {}

        local quest_model = CQuest.Instance():GetInProgressQuestModel(self._QuestTid)
        if quest_model then  
            local quest_objs = quest_model:GetCurrentQuestObjetives()
            for i = 1, #quest_objs do                         
                local objectiveModel = quest_model:GetObjectiveById(quest_objs[i].Id) 
                local targetsMonters = objectiveModel:GetQuestTargetMonsters()
                if not objectiveModel:IsComplete() and  targetsMonters ~= nil then
                    for i,v in ipairs(targetsMonters) do
                        table.insert(self._TargetTidList, v)  
                    end            
                end                        
            end
        end

        --warn("#self._TargetTidList =", #self._TargetTidList)
    end

    -- 清除开启时 非任务目标
    do
        local curTarget = host_player._CurTarget
        if curTarget ~= nil and IsTargetProper(curTarget:GetTemplateId()) then
            self._CurTargetId = curTarget._ID
        else
            self._CurTargetId = 0
            host_player:UpdateTargetInfo(nil, false)
        end
    end

    if self._TimerId <= 0 then    
        self._TimerId = _G.AddGlobalTimer(0.5, false, Tick) 
    end
end

-- 修改目标
def.method("number", "number").RemovePriorityTarget = function(self, questId, targetTid)    
    if questId == self._QuestTid then
        for i = #self._TargetTidList, 1, -1 do 
            if targetTid == self._TargetTidList[i] then               
                table.remove(self._TargetTidList, i)
                break
            end
        end

        if #self._TargetTidList == 0 then
            self:ClearPriorityTargets()
        end         
    end
end

def.override().Stop = function(self)
    if self._TimerId <= 0 then 
        return 
    end
    _G.RemoveGlobalTimer(self._TimerId)
    self._TimerId = 0

    self._QuestTid = -1

    --local host_player = game._HostPlayer
    --host_player:StartAutoDetectTarget()
    
    CAutoFightBase.Stop(self)
end

def.method().Debug = function(self)
    local isInFollowing = CTeamMan.Instance():IsFollowing()
    local isPass = IsCurQuestKillingEnd(self)

    local msg = string.format("CQuestAutoFight TimerId = %d, QuestTid = %d, Paused = %s, IsFollowing = %s, IsQuestGoalFinished = %s", 
        self._TimerId, self._QuestTid, tostring(self._Paused), tostring(isInFollowing), tostring(isPass))

    warn(msg)
end

CQuestAutoFight.Commit()
return CQuestAutoFight