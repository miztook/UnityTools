local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CGame = Lplus.ForwardDeclare("CGame")
local CWorldAutoFight = require "Main.CWorldAutoFight"
local CQuestAutoFight = require "Quest.CQuestAutoFight"
local CElementData = require "Data.CElementData"
local bit = require "bit"

local CAutoFightMan = Lplus.Class("CAutoFightMan")
local def = CAutoFightMan.define

def.field("number")._CurType = 0          -- none
def.field("boolean")._IsOn = false        -- 是否要自动战斗
def.field("boolean")._InDelayCallback = false
def.field("number")._DelayStartTimerId = 0
def.field("number")._CurQuestTid = 0
def.field("number")._PauseMask = 0   

local instance = nil
def.static("=>", CAutoFightMan).Instance = function ()
    if instance == nil then
        instance = CAutoFightMan()
    end
	return instance
end

local function OnDisconnect(sender, event)
    instance:Stop()
end

local function ClearTimer(self)
    if self._DelayStartTimerId > 0 then
        _G.RemoveGlobalTimer(self._DelayStartTimerId)
        self._DelayStartTimerId = 0
    end
end

local function ShowAutoFightGfx(self, state)    
    local CPanelSkillSlot = require "GUI.CPanelSkillSlot"
    CPanelSkillSlot.Instance():SyncAutoFightUIState(state)
end

local function OnBaseStateChangeEvent(sender, event)
    if not instance:IsOn() then
        return 
    end

    if event.IsEnterState then --主角被控制，不能移动，打断寻路
        instance:Pause(_G.PauseMask.HostBaseState)
    else
        instance:RestartRightNow()
    end
end

def.method().Start = function(self)
    if self._IsOn then return end
    local hp = game._HostPlayer
    if hp == nil then return end

    if hp:IsDead() then
        ShowAutoFightGfx(self, false)
        return
    end

    if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.AutoFight) then
        return    
    end

     -- 不能开启自动战斗
    if game:IsCurMapForbidAutofight() then        
        game._GUIMan:ShowTipText(StringTable.Get(22202), false)
        ShowAutoFightGfx(self, false)
        return   
    end

    ShowAutoFightGfx(self, true) 
    self._IsOn = true
    self._PauseMask = 0

    -- 默认WorldFight类型
    -- self:SetMode(EnumDef.AutoFightType.WorldFight, 0)
    self._CurType = EnumDef.AutoFightType.None

    CGame.EventManager:addHandler('BaseStateChangeEvent', OnBaseStateChangeEvent)
    CGame.EventManager:addHandler('DisconnectEvent', OnDisconnect)  

    print("CAutoFightMan Start", debug.traceback())
end

def.method("number", "number", "boolean").SetMode = function(self, fightType, questTid, needDelay)
    if not self._IsOn then return end

    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        CWorldAutoFight.Instance():Stop()
    elseif self._CurType == EnumDef.AutoFightType.QuestFight then
        CQuestAutoFight.Instance():Stop()        
    end
    
    ClearTimer(self)

    self._CurType = fightType
    self._CurQuestTid = questTid
    self._InDelayCallback = true
    
    local function FightNow()
        if fightType == EnumDef.AutoFightType.WorldFight then
            local CQuestAutoGather = require "Quest.CQuestAutoGather"
            CQuestAutoGather.Instance():Stop()
            CWorldAutoFight.Instance():Start(0) 

            local CQuestAutoMan = require"Quest.CQuestAutoMan"
            local enable = not CQuestAutoMan.Instance():IsOn()
            local curMapTid = game:GetCurMapTid()
            local mapTemplate = CElementData.GetMapTemplate(curMapTid)
            CWorldAutoFight.Instance():EnableGuardMode(enable and curMapTid ~= _G.GuildBaseTid and mapTemplate.AutoFightType == 0)
        elseif fightType == EnumDef.AutoFightType.QuestFight then
            -- 不必再开
            if self._CurType == EnumDef.AutoFightType.QuestFight and CQuestAutoFight.Instance()._QuestTid == questTid then
                return
            end

            CQuestAutoFight.Instance():Start(questTid)         
        end
        self._CurQuestTid = 0
        self._InDelayCallback = false
    end

    if needDelay then
        self._DelayStartTimerId = _G.AddGlobalTimer(1, true, function()
                FightNow()
                self._DelayStartTimerId = 0
            end) 
    else
        FightNow()
    end
end

def.method("number", "=>", "boolean").OnManualSkill = function(self, skill_id)
    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        CWorldAutoFight.Instance():OnManualSkill(skill_id)
        return true
    elseif self._CurType == EnumDef.AutoFightType.QuestFight then 
        CQuestAutoFight.Instance():OnManualSkill(skill_id)
        return true        
    end
    return false
end

def.method("table").SetPriorityTargets = function(self, targets)
    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        CWorldAutoFight.Instance():UpdatePriorityTargets(targets)
    else
        -- QuestFight暂无优先对象更新需求    
    end
end

def.method("number", "number").RemovePriorityTarget = function(self, questId, targetTid)
    if self._CurType == EnumDef.AutoFightType.QuestFight then 
        CQuestAutoFight.Instance():RemovePriorityTarget(questId, targetTid)
    else
        --  WorldFight 暂无优先对象删除需求
    end
end

def.method().ClearPriorityTargets = function(self)
    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        CWorldAutoFight.Instance():ClearPriorityTargets()
    elseif self._CurType == EnumDef.AutoFightType.QuestFight then 
        CQuestAutoFight.Instance():ClearPriorityTargets()     
    end
end

def.method("=>","boolean").HasTarget = function(self)
    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        return CWorldAutoFight.Instance():HasTarget()
    elseif self._CurType == EnumDef.AutoFightType.QuestFight then 
        return CQuestAutoFight.Instance():HasTarget()    
    end

    return false
end

def.method("=>", "boolean").IsOn = function(self)    
    return self._IsOn
end

def.method("number").Pause = function(self, reason)
    if not self._IsOn then return end

    self._PauseMask = bit.bor(self._PauseMask, reason)

    if reason ~= _G.PauseMask.ManualControl then
        print("CAutoFightMan Pause", self._PauseMask, debug.traceback())
    end

    if self._InDelayCallback then
        -- 尚未延迟回调真正启动
        ClearTimer(self)
    else
        if self._CurType == EnumDef.AutoFightType.WorldFight then 
            CWorldAutoFight.Instance():Pause()
        elseif self._CurType == EnumDef.AutoFightType.QuestFight then
            CQuestAutoFight.Instance():Pause()        
        end
    end
end

def.method("number").Restart = function(self, reason)
    if not self._IsOn then return end
    ClearTimer(self)

    self._PauseMask = bit.band(self._PauseMask,  bit.bnot(reason))

    if reason ~= _G.PauseMask.ManualControl then
        print("CAutoFightMan Restart", self._PauseMask, debug.traceback())
    end

    if self._PauseMask ~= 0 then return end

    self._DelayStartTimerId = _G.AddGlobalTimer(1, true, function()
        if not self._InDelayCallback then
            if self._CurType == EnumDef.AutoFightType.WorldFight then 
                CWorldAutoFight.Instance():Restart()
                if reason == _G.PauseMask.ManualControl or reason == _G.PauseMask.WorldLoading then
                    local CQuestAutoMan = require"Quest.CQuestAutoMan"
                    local enable = not CQuestAutoMan.Instance():IsOn()
                    local curMapTid = game:GetCurMapTid()
                    CWorldAutoFight.Instance():EnableGuardMode(enable and curMapTid ~= _G.GuildBaseTid)
                end
            elseif self._CurType == EnumDef.AutoFightType.QuestFight then
                CQuestAutoFight.Instance():Restart()        
            end
        else
            if self._CurType == EnumDef.AutoFightType.WorldFight then 
                CWorldAutoFight.Instance():Start(0)
                if reason == _G.PauseMask.ManualControl or reason == _G.PauseMask.WorldLoading then
                    local CQuestAutoMan = require"Quest.CQuestAutoMan"
                    local enable = not CQuestAutoMan.Instance():IsOn()
                    local curMapTid = game:GetCurMapTid()
                    CWorldAutoFight.Instance():EnableGuardMode(enable and curMapTid ~= _G.GuildBaseTid)
                end
            elseif self._CurType == EnumDef.AutoFightType.QuestFight then
                CQuestAutoFight.Instance():Start(self._CurQuestTid) 
                self._CurQuestTid = 0      
            end 
            self._InDelayCallback = false
        end
    end) 
end

def.method().RestartRightNow = function(self)
    if not self._IsOn then return end
    ClearTimer(self)

    local autoFightInstance = nil
    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        autoFightInstance = CWorldAutoFight.Instance()
    elseif self._CurType == EnumDef.AutoFightType.QuestFight then
        autoFightInstance = CQuestAutoFight.Instance() 
    else
        return      
    end

    self._PauseMask = bit.band(self._PauseMask,  bit.bnot(_G.PauseMask.HostBaseState))
    if self._PauseMask ~= 0 then return end

    --if autoFightInstance == nil or autoFightInstance:IsPaused() then return end

    if not self._InDelayCallback then
        autoFightInstance:Restart()
    else
        if self._CurType == EnumDef.AutoFightType.WorldFight then 
            autoFightInstance:Start(0)
            local CQuestAutoMan = require"Quest.CQuestAutoMan"
            local enable = not CQuestAutoMan.Instance():IsOn()
            local curMapTid = game:GetCurMapTid()
            CWorldAutoFight.Instance():EnableGuardMode(enable and curMapTid ~= _G.GuildBaseTid)
        elseif self._CurType == EnumDef.AutoFightType.QuestFight then
            autoFightInstance:Start(self._CurQuestTid) 
            self._CurQuestTid = 0      
        end 
        self._InDelayCallback = false
    end 
end

def.method().Stop = function(self) 
    if self._DelayStartTimerId > 0 then
        _G.RemoveGlobalTimer(self._DelayStartTimerId)
        self._DelayStartTimerId = 0
    end
    CGame.EventManager:removeHandler('BaseStateChangeEvent', OnBaseStateChangeEvent)
    CGame.EventManager:removeHandler('DisconnectEvent', OnDisconnect)
    if not self._IsOn then return end
    if self._CurType == EnumDef.AutoFightType.WorldFight then 
        CWorldAutoFight.Instance():Stop()
    elseif self._CurType == EnumDef.AutoFightType.QuestFight then
        CQuestAutoFight.Instance():Stop()        
    end

    self:ClearPriorityTargets()

    -- 完全清除
    ShowAutoFightGfx(self, false) 
    self._IsOn = false
    self._InDelayCallback = false
    self._PauseMask = 0

    self._CurType = EnumDef.AutoFightType.None

    -- 如果所有自动化都已经关闭，则需要停止主角移动
    local CQuestAutoMan = require"Quest.CQuestAutoMan"
    local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
    if not CQuestAutoMan.Instance():IsOn() and not CDungeonAutoMan.Instance():IsOn() then
        game._HostPlayer:StopNaviCal()
    end

    print("CAutoFightMan Stop", debug.traceback())
end

def.method().Debug = function(self)
    local msg = string.format("CAutoFightMan IsOn = %s, CurQuestTid = %d, PauseMask = %d", tostring(self._IsOn), self._CurQuestTid, self._PauseMask)
    warn(msg)

    CWorldAutoFight.Instance():Debug()
    CQuestAutoFight.Instance():Debug() 
end

CAutoFightMan.Commit()
return CAutoFightMan