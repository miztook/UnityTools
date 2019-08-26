local Lplus = require "Lplus"
local CAutoMatch = Lplus.Class("CAutoMatch")
local def = CAutoMatch.define
local instance = nil

def.field("number")._CurType = 0    --EnumDef.AutoMatchType.None
def.field("number")._AutoMatchTimerId = 0
def.field("number")._AutoMatchTickTime = 0
def.field('number')._StartTime = 0
def.field("string")._TargetMatchText = ""
def.field("number")._EndTime = 0
--[[
    Example:
            local CAutoMatch = require "ObjHdl.CAutoMatch"

            Start:
                CAutoMatch.Instance():InitMatchFunctionText("特别正式的快捷匹配")
                --## 基础功能，则default：快捷匹配, 可不调用以上api
                
                CAutoMatch.Instance():Start(EnumDef.AutoMatchType.QuickMatch, nil, nil)

            Stop:
                CAutoMatch.Instance():Stop()
]]

--[[
    AutoMatchType = 
    {
        None = 0,           -- 未匹配
        In3V3Fight = 1,     -- 3v3竞技场
        InTeam = 2,         -- 队伍匹配成员
        SearchTeam = 3,     -- 组队
        QuickMatch = 4,     -- 便捷匹配
        InBattleFight = 5,  -- 无畏战场  
    },    
]]

def.static("=>", CAutoMatch).Instance = function ()
    if instance == nil then
        instance = CAutoMatch()
    end
	return instance
end

def.method("number", "=>", "boolean").IsMatching = function(self, matchType)
    return ((self._CurType == matchType) and (matchType ~= EnumDef.AutoMatchType.None))
end

def.method("=>", "boolean").CanMatch = function(self)
    return self._CurType == EnumDef.AutoMatchType.None
end

def.method("=>","number").GetType = function(self)
    return self._CurType
end

def.method("number", "dynamic", "dynamic").Start = function(self, matchType, startTime, endTime)
    if self:CanMatch() then
        --小地图time显隐
        self:ResetMatch()
        
        self._CurType = matchType
        -- 开始时间
        if startTime ~= nil then
            self._StartTime = startTime
        end
        -- 结束时间
        if endTime ~= nil then
            self._EndTime = endTime
        end

        -- warn("Start:  self._CurType = ", self._CurType)

        if self._CurType == EnumDef.AutoMatchType.In3V3Fight then
            --warn("开启【3v3】匹配管理器")
            self:SetAutoMatching(true)
            self:StartCommonUI()
        elseif self._CurType == EnumDef.AutoMatchType.InBattleFight then
            --warn("开启 无畏战场匹配管理器")
            self:SetAutoMatching(true)
            self:StartCommonUI()
        elseif self._CurType == EnumDef.AutoMatchType.SearchTeam then
            --warn("开启【寻找队伍】匹配管理器")
            self:SetAutoMatching(true)
        elseif self._CurType == EnumDef.AutoMatchType.InTeam then
            --warn("开启【寻找队员】匹配管理器")
            self:SetAutoMatching(true)
        elseif self._CurType == EnumDef.AutoMatchType.QuickMatch then
            -- warn("开启【便捷组队】匹配管理器")
            self:SetAutoMatching(true)
            self:StartCommonUI()
        else
            -- 开启通用逻辑
            self:SetAutoMatching(true)
            self:StartCommonUI()
        end
    else
        --当前存在其他匹配,请取消后再试!
        TeraFuncs.SendFlashMsg(StringTable.Get(22400), false)
    end
end

def.method().StartCommonUI = function(self)
    local CPanelMinimap = require "GUI.CPanelMinimap"
    CPanelMinimap.Instance():SetTargetMatchText(self:GetMatchFunctionText())
    CPanelMinimap.Instance():ShowCommonMatch(true)
end

-- 初始化 功能字符显示
def.method("string").InitMatchFunctionText = function(self, targetMatchText)
    self._TargetMatchText = targetMatchText
end

-- 获取 功能字符显示, default: <[32000] = "便捷匹配">
def.method("=>", "string").GetMatchFunctionText = function(self)
    return string.len(self._TargetMatchText) == 0 and StringTable.Get(32000) or self._TargetMatchText
end

def.method("boolean").SetAutoMatching = function(self, bAuto)
    if bAuto then
        -- 设置开启时间
        if self._StartTime <= 0 then
            self._StartTime = GameUtil.GetServerTime()/1000
        end

        self._AutoMatchTimerId = _G.AddGlobalTimer(1, false, function()
            self:MatchTimeTick()
        end)
    end
end

def.method("=>", "string").GetAutoMatchingTimeStr = function(self)
    return GUITools.FormatTimeFromSecondsToZero(false, self._AutoMatchTickTime)
end

def.method().MatchTimeTick = function(self)
    self._AutoMatchTickTime = GameUtil.GetServerTime()/1000 - self._StartTime

    -- 设置终止时间
    if self._EndTime > 0 and self._AutoMatchTickTime >= self._EndTime then
        self:Stop()
    end
end

def.method().ResetMatch = function(self)
    self._CurType = EnumDef.AutoMatchType.None
    if self._AutoMatchTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._AutoMatchTimerId)
    end
    --小地图time显隐
    local CPanelMinimap = require "GUI.CPanelMinimap"
    CPanelMinimap.Instance():ShowCommonMatch(false)
    self._AutoMatchTimerId = 0
    self._AutoMatchTickTime = 0
end

def.method().Stop = function(self)
    if self._CurType == EnumDef.AutoMatchType.In3V3Fight then
        --关闭【3v3】匹配管理器
        self:SetAutoMatching(false)
    elseif self._CurType == EnumDef.AutoMatchType.InBattleFight then
        --关闭【无畏战场】匹配管理器
        self:SetAutoMatching(false)
    elseif self._CurType == EnumDef.AutoMatchType.SearchTeam then
        --关闭【寻找队伍】匹配管理器
        self:SetAutoMatching(false)
    elseif self._CurType == EnumDef.AutoMatchType.InTeam then
        --关闭【寻找队员】匹配管理器
        self:SetAutoMatching(false)
    else
        -- 关闭通用逻辑
        self:SetAutoMatching(false)
    end

    self:Clear()
end

--关闭
def.method().Clear = function(self)
    self:ResetMatch()
    self._CurType = 0   --EnumDef.AutoMatchType.None
    self._StartTime = 0
    self._EndTime = 0
end

CAutoMatch.Commit()
return CAutoMatch