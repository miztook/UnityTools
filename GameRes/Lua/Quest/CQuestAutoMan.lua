local Lplus = require "Lplus"
local CQuest = require "Quest.CQuest"
local CAutoFightMan = require "AutoFight.CAutoFightMan"
local CTeamMan = require "Team.CTeamMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local EWorldType = require "PB.Template".Map.EWorldType
local QuestDef = require "Quest.QuestDef"
local bit = require "bit"
local DistanceH = Vector3.DistanceH

local CQuestAutoMan = Lplus.Class("CQuestAutoMan")
local def = CQuestAutoMan.define

def.field("number")._QuestId = 0            -- 当前进行任务ID
def.field("boolean")._IsOn = false          -- 任务自动化开启状态
def.field("boolean")._Paused = false
def.field("boolean")._ScriptClickQuestPage = false   -- 任务自动化点击的任务面板

def.field("number")._PauseMask = 0   

def.field("number")._StateCheckTimerId = -1
def.field("table")._LastHostPos = nil

-- 为了表现，触发后，不立即执行，延时
def.field("number")._LaterQuestTimerId = -1

-- 延时时长
local ActionDelayTime = 1
local StateCheckTime = 5

local _instance = nil
def.static("=>", CQuestAutoMan).Instance = function ()
    if _instance == nil then
        _instance = CQuestAutoMan()
    end
    return _instance
end

local function GetNextQuestID(self)
    if self._QuestId <= 0 then return 0 end

    local quest_data = CElementData.GetQuestTemplate(self._QuestId)
    if quest_data and quest_data.DeliverRelated then
        if quest_data.DeliverRelated.NextQuestId > 0 then
            return quest_data.DeliverRelated.NextQuestId
        end
    end
    return 0
end

local function QuestEventHandler(sender, event)
    local name = event._Name
    local data = event._Data
    if name == EnumDef.QuestEventNames.QUEST_RECIEVE then
        _instance:Try2Continue(data.Id, false)
    elseif name == EnumDef.QuestEventNames.QUEST_COMPLETE then  --交任务
        --local nextQuestId = GetNextQuestID(_instance)       
        _instance:Try2Continue(data.Id, true)
    elseif name == EnumDef.QuestEventNames.QUEST_CHANGE then
        _instance:Try2Continue(data.QuestId, false)        
    end
end

local function OnQuestDataChange(sender, event)
    if not _instance:IsOn() then
        return 
    end

    _instance:Restart(0)   
end

local function OnDisconnect(sender, event)
    _instance:Stop()
end

-- model既支持任务Model 也支持目标Model
local function DoShortcutExecute (questId, model)
    if questId <= 0 or model == nil then return end
    _instance._ScriptClickQuestPage = true
    local CPageQuest = require "GUI.CPageQuest"
    CPageQuest.Instance():SetSelectByID(questId, false)
    _instance._ScriptClickQuestPage = false
    --model:DoShortcut()
end

local function ContinueCurQuest(self)
    if self._Paused then return end

    local isInProcess = (CQuest.Instance():GetInProgressQuestModel(self._QuestId) ~= nil)
    if isInProcess then -- 进行中的任务 
        self:Try2Continue(self._QuestId, false)
    else   -- 锁哥要加的 下一任务 
        local nextQuest = CQuest.Instance():FetchQuestModel(self._QuestId)
        if nextQuest ~= nil then
            DoShortcutExecute(self._QuestId, nextQuest)
        else
            warn("Can not restart auto quest, because quest id is invalid, id =", self._QuestId)
        end
    end
end

--监听玩家状态的接口
local function OnBaseStateChangeEvent(sender, event)
    if event.IsEnterState then --主角被控制，不能移动，打断寻路
        _instance:Pause(_G.PauseMask.HostBaseState)
    else
        _instance:Restart(_G.PauseMask.HostBaseState)
    end
end

local function OnItemChangeEvent(sender, event)
    local quest_model = CQuest.Instance():GetInProgressQuestModel(_instance._QuestId)
    if quest_model then
        local itemData = event.ItemUpdateInfo.UpdateItem.ItemData
        local objectives = quest_model:GetCurrentQuestObjetives()
        for j = 1, #objectives do
            local obj = objectives[j]
            if obj:GetTemplate().UseItem._is_present_in_parent then
                if obj:GetTemplate().UseItem.ItemTId == itemData.Tid then
                    _instance:Try2Continue(_instance._QuestId, false)
                end
            elseif obj:GetTemplate().HoldItem._is_present_in_parent then
                if obj:GetTemplate().HoldItem.ItemTId == itemData.Tid then
                    _instance:Try2Continue(_instance._QuestId, false)
                end            
            end
        end
    end
end

local function ClearQuestLaterTimer(self)
    if self._LaterQuestTimerId > 0 then
        _G.RemoveGlobalTimer(self._LaterQuestTimerId)
        self._LaterQuestTimerId = 0
    end
end

local function ClearStateCheckTimer(self)
    if self._StateCheckTimerId > 0 then
        _G.RemoveGlobalTimer(self._StateCheckTimerId)
        self._StateCheckTimerId = 0
    end
end

local function IsCurObjectiveForbided(quest_model)
    if quest_model ~= nil then
        local obj = quest_model:GetCurrentObjective()
        if obj ~= nil then
            if obj:GetTemplate().ArriveLevel._is_present_in_parent then
                return true
            elseif obj:GetTemplate().EnterDungeon._is_present_in_parent then
                if quest_model.QuestStatus == QuestDef.Status.NotRecieved then
                    return false
                end
                -- 任务目标是到达相位副本，可以自动化；其余不可
                local pathID = obj:GetTemplate().EnterDungeon.PathID
                return pathID ~= nil and pathID == 0
            elseif obj:GetTemplate().FinishDungeon._is_present_in_parent then
                if quest_model.QuestStatus == QuestDef.Status.NotRecieved then
                    return false
                end
                local pathID = obj:GetTemplate().FinishDungeon.PathID
                return pathID ~= nil and pathID == 0
            elseif obj:GetTemplate().Guide._is_present_in_parent then  -- 引导任务
                return true 
            elseif obj:GetTemplate().Achievement._is_present_in_parent then  -- 达成成就
                return true 
            end
        end
    end

    return false
end

-- 任务自动化开启 
def.method("table").Start = function(self, quest_model)  
    --print("CQuestAutoMan Start-0", debug.traceback())
    -- 已开启
    if self._IsOn and quest_model ~= nil and quest_model.Id == self._QuestId then
        if IsCurObjectiveForbided(quest_model) then
            self:Stop()
            CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
        end
        return
    end

    local hp = game._HostPlayer
    if hp:IsDead() then
        local CPageQuest = require "GUI.CPageQuest"
        CPageQuest.Instance():ListItemsNoSelect()
        return
    end

    --print("CQuestAutoMan Start", self._QuestId, quest_model.Id, debug.traceback())

    -- 自动战斗功能未解锁 或者 当前场景不支持自动战斗，返回
    if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.AutoFight) or game:IsCurMapForbidAutofight() then
        local CPageQuest = require "GUI.CPageQuest"
        CPageQuest.Instance():ListItemsNoSelect()
        return
    end

    --print("CQuestAutoMan Start-2")
    -- 特殊任务不开启自动化
    if quest_model == nil or IsCurObjectiveForbided(quest_model) then
        local CPageQuest = require "GUI.CPageQuest"
        CPageQuest.Instance():ListItemsNoSelect()
        return
    end

    --print("CQuestAutoMan Start-3", self._IsOn)

    local addEvent = not self._IsOn

    ClearQuestLaterTimer(self)

    self._IsOn = true
    self._QuestId = quest_model.Id
    self._Paused = false
    self._PauseMask = 0

    -- 需要显式的调用一下，在任务界面点“前往”，也可以打开自动化
    self._ScriptClickQuestPage = true
    local CPageQuest = require "GUI.CPageQuest"
    CPageQuest.Instance():SetSelectByID(self._QuestId, true)
    self._ScriptClickQuestPage = false

    if addEvent then
        CGame.EventManager:addHandler('DisconnectEvent', OnDisconnect)  
        CGame.EventManager:addHandler('QuestCommonEvent', QuestEventHandler)
        CGame.EventManager:addHandler('GainNewItemEvent', OnItemChangeEvent)
        CGame.EventManager:addHandler("BaseStateChangeEvent", OnBaseStateChangeEvent)
        CGame.EventManager:addHandler('QuestWaitTimeFinish', OnQuestDataChange)
    end

    if self._StateCheckTimerId > 0 then
        warn("State error: U did not call ClearStateCheckTimer when CQuestAutoMan Stoped")
        ClearStateCheckTimer(self)
    end

    self._LastHostPos = hp:GetPos()
    self._StateCheckTimerId = _G.AddGlobalTimer(StateCheckTime, false, function()
            if not self._IsOn then
                ClearStateCheckTimer(self)
                return
            end

            if self._QuestId <= 0 then return end

            if hp:IsDead() or self._Paused or self._PauseMask ~= 0 then
                self._LastHostPos = hp:GetPos()
                return
            end

            local CPanelDialogue = require 'GUI.CPanelDialogue'
            if CPanelDialogue.Instance():IsShow() then
                self._LastHostPos = hp:GetPos()
                return
            end

            local curPos = hp:GetPos()
            if DistanceH(curPos, self._LastHostPos) < 0.1 then
                -- 原地不动，认为时自动化不明原因中断，需要重启
                ContinueCurQuest(self)
            else
                self._LastHostPos = hp:GetPos()
            end
        end)

    --print("CQuestAutoMan Start", self._QuestId)
end

def.method("table", "=>", "boolean").IsQuestInAuto = function(self, questModel)
    if not self._IsOn then return false end
    if self._QuestId ~= questModel.Id then return false end
    return true
end

-- 自动化暂停
def.method("number").Pause = function(self, reasonMask)
    if not self._IsOn then return end
    if self._QuestId <= 0 then return end

    self._PauseMask = bit.bor(self._PauseMask, reasonMask)

    ClearQuestLaterTimer(self)
    self._Paused = true

    if reasonMask ~= _G.PauseMask.SkillPerform then
        --print("CQuestAutoMan Pause", self._PauseMask, self._QuestId, debug.traceback())
    end
end

-- 自动化重启
def.method("number").Restart = function(self, reasonMask)    
    self._PauseMask = bit.band(self._PauseMask,  bit.bnot(reasonMask))

    if reasonMask ~= _G.PauseMask.SkillPerform then
        --print("CQuestAutoMan Restart", self._PauseMask, self._QuestId, debug.traceback())
    end
    if self._PauseMask ~= 0 then return end

    if self._QuestId <= 0 or not self._IsOn then return end

    self._Paused = false
    ContinueCurQuest(self)
end

-- 任务接续具体执行
local function Try2ContinueImpl()   --_instance 
    if _instance._Paused then return end

    local quest_id = _instance._QuestId
    -- 当前任务完成
    local quest_model = CQuest.Instance():GetInProgressQuestModel(quest_id)
    if quest_model then
        if quest_model:IsCompleteAll() then   
            -- 自动交付类型
            if CQuest.Instance():IsAutoDeliver(quest_id) then
                local quest_data = CElementData.GetQuestTemplate(quest_id)
                if quest_data.DeliverRelated.NextQuestId > 0 then
                    local next_quest_model = CQuest.Instance():GetInProgressQuestModel(quest_data.DeliverRelated.NextQuestId)
                    if next_quest_model then
                        local modelobj = next_quest_model:GetCurrentObjective()
                        if modelobj and not modelobj:IsComplete() then                          
                            DoShortcutExecute(quest_id, modelobj)
                        end                    
                    end
                end
            -- 手动交付
            else
                DoShortcutExecute(quest_id, quest_model)
            end    
        -- 任务没完成 目标不在视野 
        else           
            local modelobj = quest_model:GetCurrentObjective()
            if modelobj and not modelobj:IsComplete() then    
                DoShortcutExecute(quest_id, modelobj)
            end  
        end
    -- page quest页面临时添加的questmodel
    else
        local nextQuestModel = CQuest.Instance():FetchQuestModel(quest_id)
        -- 只执行一次
        if nextQuestModel ~= nil then
            nextQuestModel:DoShortcut()
            local CPageQuest = require "GUI.CPageQuest"
            CPageQuest.Instance():SetSelectByID(quest_id, false)
        end        
    end
end

-- 设置延迟调用
local function LaterCallTry2ContinueImpl(self)
    ClearQuestLaterTimer(self)
    self._LaterQuestTimerId = _G.AddGlobalTimer(ActionDelayTime, true, Try2ContinueImpl)
end

local function IsGuildQuestChain(id1, id2)
    if id1 <= 0 or id2 <= 0 then return false end
    return (CQuest.Instance():IsActivityQuest(id1) and CQuest.Instance():IsActivityQuest(id2))
end

local function IsRewardQuestChain(id1, id2)
    if id1 <= 0 or id2 <= 0 then return false end
    return (CQuest.Instance():IsRewardQuest(id1) and CQuest.Instance():IsRewardQuest(id2))
end

-- 继续任务的下一步检查：
def.method("number", "boolean").Try2Continue = function(self, quest_id, goToNextQuest)  
    --print("AutoQuest Try2Continue", self._IsOn, quest_id, self._QuestId, goToNextQuest)
    if not self._IsOn then
        return
    end

    local isTheSameQuest = (not goToNextQuest and quest_id == self._QuestId)

    -- 需要对quest_id是否属是当前进行的自动化任务 或者 是当前任务的下一个任务
    local isSameQuestChain = false 
    if not isTheSameQuest then  
        if goToNextQuest then
            if quest_id == self._QuestId then
                -- 公会任务是任务组中完成一条随机一条，无前后置任务，不做处理，等待服务器协议
                if CQuest.Instance():IsActivityQuest(quest_id) then
                    return
                end

                -- 赏金任务是任务库中随机，无前后置任务，不做处理，等待服务器协议
                if CQuest.Instance():IsRewardQuest(quest_id) then
                    return
                end

                -- 主线支线任务链，在完成当前任务后，自动添加到任务列表中
                local nextNextQuestId = GetNextQuestID(self)
                if nextNextQuestId <= 0 then  -- 任务链到尽头了，自动化停止
                    self:Stop()
                    CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
                    return
                end

                isSameQuestChain = true
                quest_id = nextNextQuestId
            end
        else
            -- 以上只针对主线&支线任务，公会任务&赏金任务需要特殊处理
            -- 公会任务从人物组中挨个进行，无前后置任务；如果当前进行的是公会任务 且接取的新任务也是公会任务 就认为是同一任务链，自动化继续
            -- 赏金任务是从人物库中随机；如果当前进行的是赏金任务 且接取的新任务也是赏金任务 就认为是同一任务链，自动化继续
            isSameQuestChain = IsGuildQuestChain(self._QuestId, quest_id) or IsRewardQuestChain(self._QuestId, quest_id)
        end
    end

    if not isTheSameQuest and not isSameQuestChain then return end

    -- 如果当前任务是达到某等级/完成某个副本，自动化停止
    if isSameQuestChain then
        local curQuest = CQuest.Instance():FetchQuestModel(quest_id)
        if curQuest ~= nil and IsCurObjectiveForbided(curQuest) then
            self:Stop()
            CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.WorldFight, 0, true)
            return
        end
    end

    self._QuestId = quest_id

    if self._Paused then
        --print("AutoQuest Try2Continue Failed, bcz it's Paused, PauseMask = ", self._PauseMask) 
        return 
    end

    -- 队员跟随队长进行赏金任务
    if CQuest.Instance():IsRewardQuest(quest_id) and CTeamMan.Instance():InTeam() and not CTeamMan.Instance():IsTeamLeader() then
        --print("AutoQuest FollowLeader")
        CTeamMan.Instance():FollowLeader(true)
    else
        --print("LaterCallTry2ContinueImpl")
        LaterCallTry2ContinueImpl(self)
    end
end

def.method("=>", "boolean").IsOn = function(self)
    return self._IsOn
end

def.method("=>", "number").GetCurQuestId = function(self)
    return self._QuestId
end

def.method("=>", "boolean").IsScriptClickQuestPage = function(self)
    return self._ScriptClickQuestPage
end

-- 结束整体逻辑
def.method().Stop = function(self) 
    if not self._IsOn then return end

    -- 任务相关逻辑
    local CPageQuest = require "GUI.CPageQuest"
    CPageQuest.Instance():ListItemsNoSelect()
    
    local CTransManage = require "Main.CTransManage"
    CTransManage.Instance():SyncHostPlayerDestMapInfo(false, 0)        

    ClearQuestLaterTimer(self) -- 关闭任务延迟触发
    ClearStateCheckTimer(self)

    self._IsOn = false     
    self._QuestId = 0
    self._Paused = false 
    self._PauseMask = 0

    CGame.EventManager:removeHandler('QuestCommonEvent', QuestEventHandler)
    CGame.EventManager:removeHandler('DisconnectEvent', OnDisconnect)
    CGame.EventManager:removeHandler('GainNewItemEvent', OnItemChangeEvent)
    CGame.EventManager:removeHandler('BaseStateChangeEvent', OnBaseStateChangeEvent)
    CGame.EventManager:removeHandler('QuestWaitTimeFinish', OnQuestDataChange)

    --print("CQuestAutoMan Stop", debug.traceback())
end

def.method().Debug = function(self)
    local msg = string.format("CQuestAutoMan IsOn = %s, CurQuestTid = %d, PauseMask = %d", tostring(self._IsOn), self._QuestId, self._PauseMask)
    warn(msg)
end

CQuestAutoMan.Commit()
return CQuestAutoMan