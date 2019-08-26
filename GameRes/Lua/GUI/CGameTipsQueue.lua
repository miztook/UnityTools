--游戏消息排队显示的队列
local Lplus = require 'Lplus'
local CGameTipsQueue = Lplus.Class("CGameTipsQueue")
local def = CGameTipsQueue.define

local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"

local TICK_INTV = 0.33  --tick time interval
local MAX_LEN = 256  --tick time interval

local instance = nil
def.static('=>', CGameTipsQueue).Instance = function()
    if not instance then
        instance = CGameTipsQueue()
    end
    return instance
end

def.field("number")._StateStack = 0
def.field("table")._MsgBox = BlankTable

--def.field("table")._QueueQ = BlankTable     -- quest
def.field("table")._QueueE = BlankTable     -- Evt
def.field("table")._QueueA = BlankTable     -- achieve
def.field("boolean")._AchiSwitch = true     -- 成就开关

def.field("table")._EvtFScore = nil  -- zhanli evt
def.field("table")._Blocker = nil    -- blocker evt
def.field("table")._BlockerA = nil    -- blocker evt

def.field("number")._TickTimerId = 0

--def.field("boolean")._InGuide = false
-- working state bit mask

--local MASK_QUEST = 4
local MASK_DUNGEON = 2
local MASK_CG = 1

local function ConditionalCB(evt)
    evt.blockTime = -1
end

local function GetEventTable()
    local evt = { }
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.CHAPTEROPEN
    evt.blockTime = 0
    return evt
end

-- add evts to msg-box
def.method("table").AddToMsgBox = function(self, evt)
    --特殊需求:QA一键满级, only show lvup once
    if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.LVUP then
        --local evt_old = self:FindEvtByType(EnumDef.NOTICE_EVENT_TYPE.LVUP, self._QueueE)
        local evt_old = nil
        for i= 1, #(self._MsgBox) do
            if self._MsgBox[i] ~= nil and self._MsgBox[i].evtType == evt.evtType then
                evt_old = self._MsgBox[i]
            end
        end

        if evt_old ~= nil then
            evt_old.lv = evt.lv
        else
            table.insert(self._MsgBox, evt)
            --warn("TIPQ AddToMsgBox AT 0 : " .. self:LogEvt(evt))
        end
    else
        --其他消息排队
        local id = 0
        for k, v in ipairs(self._MsgBox) do
            if v.evtType > evt.evtType then
                table.insert(self._MsgBox, k, evt)
            --warn("TIPQ AddToMsgBox  AT " .. k .. " : " .. self:LogEvt(evt))
                return
            end
        end
        table.insert(self._MsgBox, evt)
        --warn("TIPQ AddToMsgBox AT 0 : " .. self:LogEvt(evt))
    end
end

----find type in queue, than msgBox
--def.method("number","table","=>","table").FindEvtByType = function(self, evt_type, queue)
--    for i= 1,#(queue) do
--        if queue[i]~=nil and queue[i].evtType == evt_type then
--            return queue[i]
--        end
--    end
--    for i= 1,#(self._MsgBox) do
--        if self._MsgBox[i]~=nil and self._MsgBox[i].evtType == evt_type then
--            return self._MsgBox[i]
--        end
--    end
--    return nil
--end

--sort type in queue
def.method("table").SortQueue = function(self, queue)
    --warn("SortQueue "..#(queue))

    if #(queue)>1 then
        local tmp=nil
        for i= 1, #(queue) do
            for k= 1, #(queue) - i do
                if queue[k+1].evtType < queue[k].evtType then
                    tmp=queue[k+1]
                    queue[k+1]= queue[k]
                    queue[k]=tmp
                end
            end
        end
    end
end

-- add evts from msg-box to queue
def.method().QueueMsg = function(self)
    if #(self._MsgBox) > 0 then
        for _, v in ipairs(self._MsgBox) do
--            if v.evtType == EnumDef.NOTICE_EVENT_TYPE.QUESTDONE then
--	     	    if #(self._QueueQ) < MAX_LEN then
--                    table.insert(self._QueueQ, v)
--                else
--                    warn("Tips: Quest Queue count excceeds Max "..MAX_LEN)
--            	end
--            else
            if v.evtType == EnumDef.NOTICE_EVENT_TYPE.ACHIEVE then
                if #(self._QueueA) < MAX_LEN then
                    table.insert(self._QueueA, v)
                else
                    warn("Tips: Achievement Queue count excceeds Max "..MAX_LEN)
                end
            elseif v.evtType == EnumDef.NOTICE_EVENT_TYPE.FIGHTSCORE then
--                if self._EvtFScore ~= nil then
--                    self._EvtFScore.increaseValue = self._EvtFScore.increaseValue + v.increaseValue
--                else
                    self._EvtFScore = v
--                end
            else
                if #(self._QueueE) < MAX_LEN then
                    table.insert(self._QueueE, v)
                else
                    warn("Tips: Event Queue count excceeds Max "..MAX_LEN)
                end
            end
        end
        self._MsgBox = { }
    end
end

-- exc evts and collect from msg-box every _checkIntv frames
def.method("=>","boolean").IsInGuide = function(self)
    return game._CGuideMan ~= nil and game._CGuideMan:InGuide() and game._CGuideMan:InGuideIsLimit()
end

-- exc evts and collect from msg-box every _checkIntv frames
def.method("=>","boolean").IsInCG = function(self)
    return bit.band(self._StateStack, MASK_CG)~=0
end


-- exc evts and collect from msg-box every _checkIntv frames
def.method("number").Tick = function(self, dt)
    local is_in_guide=self:IsInGuide()
    if is_in_guide then return end
    if self._StateStack == 0 and(not IsLoadingUI()) and(not self:IsInGuide()) then
        if self._Blocker ~= nil then
            self._Blocker.blockTime = self._Blocker.blockTime - dt
            if self._Blocker.blockTime <= 0 then
                --warn(" TIPQ UnBlock " .. self:LogEvt(self._Blocker) .. " " .. self._Blocker.blockTime)
                self:OnRemoveBlocker(self._Blocker)
                self._Blocker = nil
            end
        end

        if self._BlockerA ~= nil then
            self._BlockerA.blockTime = self._BlockerA.blockTime - dt
            if self._BlockerA.blockTime <= 0 then
                --warn(" TIPQ UnBlock " .. self:LogEvt(self._BlockerA) .. " " .. self._BlockerA.blockTime)
                self._BlockerA = nil
            end
        end

--        -- Quest
--        while #self._QueueQ > 0 do
--            local evt = self._QueueQ[1]
--            if not self:CanDo(evt) then
--                break
--            end
--            table.remove(self._QueueQ, 1)
--            self:Exc(evt)

--[[
            if (self._InGuide ~= is_in_guide) then             	
                local str="TIPQ IsInGuide: "..tostring(self:IsInGuide()).." "..tostring(game._CGuideMan:InGuide()).." "..tostring(game._CGuideMan:InGuideIsLimit()).."\n ".." _CurPanel: "..tostring(game._CGuideMan._CurPanel ~= nil).."_BlackBG: "..tostring(game._CGuideMan._BlackBG ~= nil)
                if game._CGuideMan._BlackBG ~= nil then
                    str=str.." activeSelf: "..tostring(game._CGuideMan._BlackBG.activeSelf)
                end
                str=str.."\n"
                str=str.." _CurPanelTrigger: "..tostring(game._CGuideMan._CurPanelTrigger~= nil).." _CurPanelTrigger._BlackBG: "..tostring(game._CGuideMan._CurPanelTrigger._BlackBG~= nil)
                if self._CurPanelTrigger._BlackBG ~= nil then
                    str=str.. " activeSelf: "..tostring(self._CurPanelTrigger._BlackBG.activeSelf)
                end
                warn(str)
            end
]]

--            self._Blocker = evt
--        end

        -- Achieve
        while #self._QueueA > 0 do
            local evt = self._QueueA[1]
            if not self:CanDo(evt) or (not self._AchiSwitch) then
                break
            end
            table.remove(self._QueueA, 1)
            self:Exc(evt)
            self._BlockerA = evt
        end

        -- FS
        if self._EvtFScore ~= nil then
            if self:CanDo(self._EvtFScore) then
				local evt = self._EvtFScore
                self._EvtFScore = nil
                self:Exc(evt)
            end
        end

        -- Evt
        while #self._QueueE > 0 do
            local evt = self._QueueE[1]
            if not self:CanDo(evt) then
                break
            end
            table.remove(self._QueueE, 1)
            self:Exc(evt)
            self._Blocker = evt
        end

        self:QueueMsg()
    end
    --self._InGuide = is_in_guide
end

def.method("table").OnRemoveBlocker = function(self, evt)
--    if (evt.evtType==EnumDef.NOTICE_EVENT_TYPE.QUESTDONE ) then
--        self:SortQueue(self._QueueE)
--    end
end

-- test can excute event
def.method("table", "=>", "boolean").CanDo = function(self, evt)
    if evt == nil then return false end

    if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.FIGHTSCORE then
--            if (self._Blocker ~= nil and self._Blocker.evtType == EnumDef.NOTICE_EVENT_TYPE.QUESTDONE) then
--                return false
--            end
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.ACHIEVE then
        if self._BlockerA ~= nil then
            return false
--        elseif (self._Blocker ~= nil and self._Blocker.evtType == EnumDef.NOTICE_EVENT_TYPE.QUESTDONE) then
--            return false
        end
    elseif self._Blocker ~= nil then
        if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.MAP then
            if self._Blocker.evtType == EnumDef.NOTICE_EVENT_TYPE.MAP then
                if self._Blocker.data._type == 1 and evt.data._type == 2 then
                    return true
                end
            end
        end

--        if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.QUESTDONE then
--            if self._Blocker.evtType ~= EnumDef.NOTICE_EVENT_TYPE.QUESTDONE then
--                return true
--            end
--        end

        if self._Blocker.blockTime > 0 then return false end
    end

    return true
end

-- excute event
def.method("table").Exc = function(self, evt)
    if evt == nil then return end

    --warn("TIPQ EXC " .. Time.time .. self:LogEvt(evt))

--    if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.QUESTDONE then
--        local function cb()
--            -- warn(Time.time .. " TIPQ QUESTDONE done")
--            ConditionalCB(evt)
--            if evt.cb ~= nil then 
--                evt.cb()
--                evt.cb = nil
--            end
--        end
--        game._GUIMan:Open("CPanelUIQuestReward", { _QuestId = evt.id, OnFinish = cb })
--        self._Blocker = evt
--    else
    if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.FIGHTSCORE then
        local CPanelMainTips = require "GUI.CPanelMainTips"		
        --CPanelMainTips.Instance():ShowFightScoreUp(evt.oldValue, evt.increaseValue, evt.props~=nil and #evt.props or 0)
        CPanelMainTips.Instance():ShowFightScoreDetail(evt.oldValue, evt.increaseValue, evt.props)
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.ACHIEVE then
        local CPanelMainTips = require "GUI.CPanelMainTips"
        local CElementData = require "Data.CElementData"
        local achi_temp = CElementData.GetTemplate("Achievement", evt.nTid)
        if achi_temp == nil then
            warn("error !!! 成就模板数据为空 ID： ", evt.nTid)
            return
        end
        if achi_temp.IsSpecial then
            CPanelMainTips.Instance():ShowSpecialAchieveTips(evt.tipsStr, evt.nTid)
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_AchieveGotSpecial, 0)
        else
            CPanelMainTips.Instance():ShowAchieveTips(evt.tipsStr, evt.nTid)
        end
        --self._BlockerA = evt
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.LVUP then
        local function cb()
            -- warn(Time.time .. " TIPQ LVUP done")
            ConditionalCB(evt)
        end
        OperationTip.ShowLvUpTip(evt.lv, cb)
        --self._Blocker = evt
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.NEWSKILL then
        local function cb()
            -- warn(Time.time .. " TIPQ NEWSKILL done")
            ConditionalCB(evt)
        end
        OperationTip.ShowGainNewSkillTip(evt.skillId, cb)
        --self._Blocker = evt
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.UNLOCKFUNC then
        local function cb()
            -- warn(Time.time .. " TIPQ UNLOCKFUNC done")
            ConditionalCB(evt)
        end
        OperationTip.ShowFuncUnlockTip(evt.funcId, cb)
        --self._Blocker = evt
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.MAP then
        local function cb()
            --warn(Time.time .. " TIPQ MAP done"..evt.data._type)
            ConditionalCB(evt)
        end
        local CPanelEnterMapTips = require "GUI.CPanelEnterMapTips"
        CPanelEnterMapTips.Instance():ShowEnterTips(evt.data, cb)
        --self._Blocker = evt
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.CHAPTEROPEN then
        local function cb()
            -- warn(Time.time .. " TIPQ CHAPTEROPEN done")
            ConditionalCB(evt)
        end
        local CPanelMainTips = require "GUI.CPanelMainTips"
        CPanelMainTips.Instance():ShowQuestChapterOpen(evt.str, cb)
        --self._Blocker = evt
    end

end

-- log evt to string
def.method("table", "=>", "string").LogEvt = function(self, evt)
    if evt == nil then return "" end
--    if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.QUESTDONE then
--        return(Time.time .. " TIPQ QUESTDONE " .. evt.id)
--    else
    if evt.evtType == EnumDef.NOTICE_EVENT_TYPE.FIGHTSCORE then
        return(Time.time .. " TIPQ FIGHTSCORE " .. evt.oldValue .. ", " .. evt.increaseValue)
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.ACHIEVE then
        return(Time.time .. " TIPQ ACHIEVE " .. evt.tipsStr .. ", " .. evt.nTid)
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.LVUP then
        return(Time.time .. " TIPQ LVUP " .. evt.lv)
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.NEWSKILL then
        return(Time.time .. " TIPQ NEWSKILL " .. evt.skillId)
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.UNLOCKFUNC then
        return(Time.time .. " TIPQ UNLOCKFUNC " .. evt.funcId)
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.MAP then
        if evt.data._type == 1 then
            return(Time.time .. " TIPQ MAP " .. evt.data._type .. " M " .. evt.data._Id)
        else
            return(Time.time .. " TIPQ MAP " .. evt.data._type .. " R " .. evt.data._RegionID)
        end
    elseif evt.evtType == EnumDef.NOTICE_EVENT_TYPE.CHAPTEROPEN then
        return(Time.time .. " TIPQ CHAPTEROPEN " .. evt.str)
    end
    return ""
end

--def.method("number", "function").ShowQuestFinishReward = function(self, id, cb)
--    --特殊需求：李卓伦的教学屏蔽任务结算
--    if not self:IsInGuide() then
--        --warn("ShowQuestFinishReward2")
--        local evt = GetEventTable()
--        evt.evtType = EnumDef.NOTICE_EVENT_TYPE.QUESTDONE
--        evt.blockTime = 10
--        evt.id = id
--        evt.cb = cb

--        if #self._QueueQ > 0 or not self:CanDo(evt) then
--            self:AddToMsgBox(evt)
--        else
--            self:Exc(evt)
--            self._Blocker = evt
--        end

--    end
--end

def.method("number", "number", "table").ShowFightScoreTip = function(self, oldValue, increaseValue, props)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.FIGHTSCORE
    evt.blockTime = 10
    evt.oldValue = oldValue
    evt.increaseValue = increaseValue
    evt.props = props
    self:AddToMsgBox(evt)
end

def.method("string", "number").ShowAchieveTip = function(self, tipsStr, nTid)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.ACHIEVE
    evt.blockTime = 2
    evt.tipsStr = tipsStr
    evt.nTid = nTid
    self:AddToMsgBox(evt)
end

def.method("number").ShowLvUpTip = function(self, lv)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.LVUP
    evt.blockTime = 10
    evt.lv = lv
    self:AddToMsgBox(evt)
end

def.method("number").ShowNewSkillTip = function(self, skillId)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.NEWSKILL
    evt.blockTime = 10
    evt.skillId = skillId
    self:AddToMsgBox(evt)
end

def.method("number").ShowUnlockFuncTip = function(self, funcId)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.UNLOCKFUNC
    evt.blockTime = 10
    evt.funcId = funcId
    self:AddToMsgBox(evt)
end

def.method("table").ShowMapTip = function(self, data)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.MAP
    evt.blockTime = 10
    evt.data = data
    self:AddToMsgBox(evt)
end

def.method("string").ShowChapterOpenTip = function(self, str)
    local evt = GetEventTable()
    evt.evtType = EnumDef.NOTICE_EVENT_TYPE.CHAPTEROPEN
    evt.blockTime = 10
    evt.str = str
    self:AddToMsgBox(evt)
end

-- On Events

-- 进入区域后
local function OnEnterRegionEvent(sender, event)
    local self = instance
    if game._CurWorld == nil then return end

    if not game._HostPlayer:InDungeon() then
        self._StateStack = bit.band(self._StateStack, bit.bnot(MASK_DUNGEON))

        --warn("TIPQ DUNGEON OFF "..self._StateStack)
    end
end

-- CG 播放后
local function OnCGEvent(sender, event)
    if game._CurWorld == nil then return end
    local self = instance

    if event.Id ~= 0 then       --special cg not accounted for
        if event.Type == "start" then
            self._StateStack = bit.bor(self._StateStack, MASK_CG)
        else
            self._StateStack = bit.band(self._StateStack, bit.bnot(MASK_CG))
        end
    end
end

-- CG 播放后
local function OnOpenDungeonResult(sender, event)
    if game._CurWorld == nil then return end
    local self = instance

    self._StateStack = bit.bor(self._StateStack, MASK_DUNGEON)
    --warn("TIPQ DUNGEON ON"..self._StateStack)
end

def.method().ListenToEvent = function(self)
    CGame.EventManager:addHandler('NotifyEnterRegion', OnEnterRegionEvent)
    CGame.EventManager:addHandler("NotifyCGEvent", OnCGEvent)
    CGame.EventManager:addHandler("DungeonResultEvent", OnOpenDungeonResult)
end

def.method().UnlistenToEvent = function(self)
    CGame.EventManager:removeHandler('NotifyEnterRegion', OnEnterRegionEvent)
    CGame.EventManager:removeHandler("NotifyCGEvent", OnCGEvent)
    CGame.EventManager:removeHandler("DungeonResultEvent", OnOpenDungeonResult)
end

def.method().Init = function(self)
    self:ListenToEvent()

    self._TickTimerId = _G.AddGlobalTimer(TICK_INTV, false, function()
        self:Tick(TICK_INTV)
    end )
end

def.method().Cleanup = function(self)
    self:UnlistenToEvent()

    if self._TickTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._TickTimerId)
        self._TickTimerId = 0
    end

    self._StateStack = 0
    self._MsgBox = { }
    --self._QueueQ = { }
    self._QueueE = { }
    self._QueueA = { }
    self._EvtFScore = nil
    self._Blocker = nil
    self._BlockerA = nil
end

CGameTipsQueue.Commit()
return CGameTipsQueue
