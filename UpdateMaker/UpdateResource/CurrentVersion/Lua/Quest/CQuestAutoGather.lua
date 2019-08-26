local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CQuest = require "Quest.CQuest"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local SqrDistanceH = Vector3.SqrDistanceH_XZ

local CQuestAutoGather = Lplus.Class("CQuestAutoGather")
local def = CQuestAutoGather.define

def.field("number")._CollectTimerID = 0
def.field("number")._CollectQuestID = 0        -- 有可能是子任务Id
def.field("number")._CollectParentQuestID = 0  -- 如果_CollectQuestID是子任务，_CollectParentQuestID为父任务
def.field("number")._CollectMineralTid = 0
def.field("number")._CollectingID = 0
def.field("table")._CurObjective = nil

local instance = nil

def.static("=>", CQuestAutoGather).Instance = function ()
    if instance == nil then
        instance = CQuestAutoGather()
    end
	return instance
end

local function MineFilter(mine)
    if not mine:GetCanGather() then return false end

    if instance._CollectMineralTid ~= mine:GetTemplateId() then return false end

    return true
end

local function OnQuestEvents(sender, event)
    local name = event._Name
    local data = event._Data
    if name == EnumDef.QuestEventNames.QUEST_CHANGE then        --任务数量变化
        if instance._CurObjective and (instance._CurObjective.Id == data.ObjectiveId) and (data.QuestId == instance._CollectQuestID) then
            if instance._CurObjective:IsComplete() then
                instance:Stop()
            end            
        end
    end
end

def.method("number", "table").Start = function(self, tid, objective)
    if self._CollectMineralTid == tid then
        return
    end
    local minman = game._CurWorld._MineObjectMan
    local function DetectMineral()
        if not self._CurObjective then
            warn("error occur in auto gather ",debug.traceback())
            self:Stop()
            return
        end
        local isPass = self._CurObjective:IsComplete()
        if isPass then
            --warn("error 该任务节点已经完成！！！。", debug.traceback())
            self:Stop()
            return
        end

        -- 如果当前在向目标矿采集过程中，矿位置未发生移动，不再查询
        local curTarget = nil        
        local hp = game._HostPlayer

        -- 采集过程中 服务器没返回成功
        if hp:GetMineGatherId() > 0 then        
            return
        end

        if self._CollectingID ~= 0 then
            curTarget = minman:Get(self._CollectingID)
            if curTarget ~= nil and not curTarget:IsReleased() and MineFilter(curTarget) then
                if hp:IsCollectingMineral() then
                    return
                end
            end
        end
        
        if hp == nil then 
            _G.RemoveGlobalTimer(self._CollectTimerID)
            self._CollectTimerID = 0
            return
        end 

        
        if hp:IsCollectingMineral() or self._CollectTimerID == 0 then
            return
        end

        local target = minman:GetByFilter(MineFilter) 
        if target and target._IsReady then
            local function Gather()
                target:OnClick()
            end

            local targetX, targetZ = target:GetPosXZ()
            local hostX, hostZ = hp:GetPosXZ()

            local offset = _G.NAV_OFFSET
            local distance = SqrDistanceH(targetX, targetZ, hostX, hostZ)
            if distance > offset * offset then
                hp:Move(target:GetPos(), offset, Gather, nil)                
            else
                Gather()
            end
            self._CollectingID = target._ID
        else
            -- 如果存在多个任务点，尝试去下一个地方
            local questModel = CQuest.Instance():GetInProgressQuestModel(instance._CollectQuestID)
            if questModel ~= nil then
                questModel:DoShortcut() 
            end                 
        end
    end
    self._CurObjective =  objective 
    self._CollectQuestID = objective._BelongQuestId 
    self._CollectMineralTid = tid
    if self._CollectTimerID ~= 0 then
        _G.RemoveGlobalTimer(self._CollectTimerID)   
    end
    self._CollectTimerID = _G.AddGlobalTimer(0.6, false, DetectMineral) 
    CGame.EventManager:addHandler('QuestCommonEvent', OnQuestEvents)
end

def.method().Stop = function(self)
    self._CollectQuestID = 0
    self._CurObjective = nil
    self._CollectMineralTid = 0
    self._CollectingID = 0  
    
    if self._CollectTimerID > 0 then
        _G.RemoveGlobalTimer(self._CollectTimerID)        
        self._CollectTimerID = 0
    end

    CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestEvents)
end


CQuestAutoGather.Commit()
return CQuestAutoGather