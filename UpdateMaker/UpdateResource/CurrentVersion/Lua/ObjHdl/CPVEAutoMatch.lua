--[[
    PVP之间的匹配需要互斥，PVP和PVE之间不互斥，因此分成两个管理器
    PVP主界面统一使用小地图旁边的loading圈，PVE使用左侧loading圈
    Example:
        local CPVEAutoMatch = require "ObjHdl.CPVEAutoMatch"

        Start:
            CPVEAutoMatch.Instance():SendC2SMatching(targetID)
        Stop:
            CPVEAutoMatch.Instance():SendC2SMatchRemove(-1)
        StopOne:
            CPVEAutoMatch.Instance():SendC2SMatchRemove(id)
]]

local Lplus = require "Lplus"
local EMatchType = require "PB.net".EMatchType
local CGame = Lplus.ForwardDeclare("CGame")
local CTeamMan = require "Team.CTeamMan"
local CElementData = require "Data.CElementData"
local ServerMessageMatch = require "PB.data".ServerMessageMatch
local CPVEAutoMatch = Lplus.Class("CPVEAutoMatch")
local def = CPVEAutoMatch.define
local instance = nil

def.field("table")._PVEMatchingTable = nil
def.field("number")._AutoMatchTimerId = 0
def.field("number")._AutoMatchTickTime = 0
def.field('number')._StartTime = 0
def.field("string")._TargetMatchText = ""
def.field("number")._EndTime = 0
def.field("table")._BlockEndTimeList = BlankTable

local LOCK_TIME = 10 * 1000 --10s

local function ParseMatchTable(self, info)
    local new_table = {}
    for i,v in ipairs(info.MatchList) do
        local item = {}
        item.StartTime = v.SignUpTime
        item.TargetId = v.TargetId
        local target_temp = CElementData.GetTemplate("TeamRoomConfig", v.TargetId)
        if target_temp ~= nil then
            new_table[#new_table + 1] = item
        end
    end
    return new_table
end

def.static("=>", CPVEAutoMatch).Instance = function ()
    if instance == nil then
        instance = CPVEAutoMatch()
    end
	return instance
end

def.method("number", "=>", "boolean").IsBlocking = function(self, targetId)
    local bRet = false
    if self._BlockEndTimeList[targetId] then
        local endTime = self._BlockEndTimeList[targetId]
        local leftTime = (endTime - GameUtil.GetServerTime())/1000
        leftTime = math.floor(leftTime)

        if leftTime > 0 then
            bRet = true
            TeraFuncs.SendFlashMsg(StringTable.Get(22417), false)
        else
            self._BlockEndTimeList[targetId] = nil
        end
    end

    return bRet
end

def.method("number").Lock = function(self, targetId)
    local endTime = GameUtil.GetServerTime() + LOCK_TIME
    self._BlockEndTimeList[targetId] = endTime
end

def.method("number").UnLock = function(self, targetId)
    if self._BlockEndTimeList[targetId] then
        self._BlockEndTimeList[targetId] = nil
    end
end

def.method("=>", "table").GetAllMatchingTable = function(self)
    return self._PVEMatchingTable
end

-- 查看整体是否在匹配中
def.method("=>", "boolean").IsMatching = function(self)
    return self._PVEMatchingTable ~= nil and #self._PVEMatchingTable > 0
end

-- 查看某个roomID是否是正在匹配中
def.method("number", "=>", "boolean").IsRoomMatching = function(self, targetID)
    if self._PVEMatchingTable == nil or #self._PVEMatchingTable <= 0 then
        return false
    end
    for i,v in ipairs(self._PVEMatchingTable) do
        if v.TargetId == targetID then
            return true
        end
    end
    return false
end

def.method("=>", "boolean").CanMatch = function(self)
    return (not (game._HostPlayer:InDungeon() or game._HostPlayer:InImmediate())) 
        and CTeamMan.Instance():InTeam()
        and CTeamMan.Instance():IsTeamLeader()
end

def.method("table").Add = function(self, data)
    if self._PVEMatchingTable == nil then
        self._PVEMatchingTable = {}
    end
    if #self._PVEMatchingTable <= 0 then
        game._GUIMan:ShowTipText(StringTable.Get(22079), false)
    end
    local finded = false
    for i,v in ipairs(self._PVEMatchingTable) do
        if v.TargetId == data.TargetId then
            v.StartTime = data.StartTime
            finded = true
        end
    end
    if not finded then
        local item = {}
        item.StartTime = data.StartTime
        item.TargetId = data.TargetId
        self._PVEMatchingTable[#self._PVEMatchingTable + 1] = item
    end

    local PVEMatchEvent = require "Events.PVEMatchEvent"
    local event = PVEMatchEvent()
    event._Type = EnumDef.PVEMatchEventType.Add
    event._RoomID = data.TargetId
    CGame.EventManager:raiseEvent(nil, event)
end

def.method().Stop = function(self)
    self._PVEMatchingTable = {}
    local PVEMatchEvent = require "Events.PVEMatchEvent"
    local event = PVEMatchEvent()
    event._Type = EnumDef.PVEMatchEventType.StopAll
    CGame.EventManager:raiseEvent(nil, event)
end

def.method("number").StopByID = function(self, targetID)
    if self._PVEMatchingTable ~= nil then
        for i = #self._PVEMatchingTable, 1, -1 do
            local v = self._PVEMatchingTable[i]
            if v.TargetId == targetID then
                table.remove(self._PVEMatchingTable, i)
                local PVEMatchEvent = require "Events.PVEMatchEvent"
                local event = PVEMatchEvent()
                event._Type = EnumDef.PVEMatchEventType.StopByID
                event._RoomID = targetID
                CGame.EventManager:raiseEvent(nil, event)
                return
            end
        end
    end
end

--================= C2S Start ==================
-- 请求副本匹配的列表数据
def.method().SendC2SMatchList = function(self)
    local C2SMatchGetMatchList = require "PB.net".C2SMatchGetMatchList
    local protocol = C2SMatchGetMatchList()
    SendProtocol(protocol)
end

-- 向服务器发送添加一个到匹配列表
def.method("number").SendC2SMatching = function(self, targetID)
    local C2SMatching = require "PB.net".C2SMatching
    local protocol = C2SMatching()
    protocol.MatchType = EMatchType.EMatchType_Dungeon
    protocol.TargetId = targetID
    SendProtocol(protocol)
end

-- 向服务器发送从匹配列表中移除一个或多个(传-1)
def.method("number").SendC2SMatchRemove = function(self, targetID)
    local C2SMatchReqCancel = require "PB.net".C2SMatchReqCancel
    local protocol = C2SMatchReqCancel()
    protocol.MatchType = EMatchType.EMatchType_Dungeon
    protocol.TargetId = targetID
    SendProtocol(protocol)
end

-- 向服务器发送取消所有匹配的消息
def.method().SendC2SMatchRemoveAll = function(self)
    local C2SMatchReqCancel = require "PB.net".C2SMatchReqCancel
    local protocol = C2SMatchReqCancel()
    protocol.MatchType = EMatchType.EMatchType_Dungeon
    protocol.TargetId = -1
    SendProtocol(protocol)
end
--------------------- C2S END ---------------------


--================= S2C Start ==================

-- 解析副本匹配列表数据并缓存
def.method("table").OnS2CMatchList = function(self, msg)
    if msg.Info and msg.Info.MatchList then
        self._PVEMatchingTable = ParseMatchTable(self, msg.Info)

        local PVEMatchEvent = require "Events.PVEMatchEvent"
        local event = PVEMatchEvent()
        event._Type = EnumDef.PVEMatchEventType.UpdateList
        CGame.EventManager:raiseEvent(nil, event)
    end
end

-- 添加一个target到列表消息回调
def.method("table").OnS2CMatching = function(self, msg)
    if msg.MatchType == EMatchType.EMatchType_Dungeon then
        self:Add(msg)
    end
end

-- 移除一个target从匹配列表
def.method("table").OnS2CMatchCancle = function(self, msg)
    if msg.MatchType == EMatchType.EMatchType_Dungeon then
        if msg.TargetId == -1 then
            if msg.Reason ~= ServerMessageMatch.Match_EnterLocalDungeon then
                TeraFuncs.SendFlashMsg(StringTable.Get(22082), false)
            end
            self:Stop()
        else
            self:StopByID(msg.TargetId)
            if msg.Reason ~= ServerMessageMatch.Match_EnterLocalDungeon then
                if #self._PVEMatchingTable > 0 then
                    local target_temp = CElementData.GetTemplate("TeamRoomConfig", msg.TargetId)
                    if target_temp ~= nil then
                        local str = string.format(StringTable.Get(22083), target_temp.DisplayName)
                        TeraFuncs.SendFlashMsg(str, false)
                    end
                else
                    TeraFuncs.SendFlashMsg(StringTable.Get(22082), false)
                end
            end
        end
    end
end

-- 匹配成功，进入副本协议处理
def.method().OnMatchStartLoading = function(self)
    self:Stop()
    game._GUIMan:CloseToMain()
end

------------------- S2C END ---------------------

CPVEAutoMatch.Commit()
return CPVEAutoMatch