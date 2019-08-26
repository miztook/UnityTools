local Lplus = require "Lplus"
local CHUDTextPlayer = Lplus.Class("CHUDTextPlayer")
local CPanelDebug = require "GUI.CPanelDebug"
local def = CHUDTextPlayer.define

def.field("number")._Type = -1
def.field("number")._Interval = 0
def.field("table")._Target = nil
def.field("number")._TimerId = 0
def.field("table")._Texts = nil

local function IsNumberZero(num)
    return num > -1 and num < 1
end

local function IsParamExist(self)
    return self._Texts and #self._Texts > 0
end

local function Push(self, param)
	if #self._Texts > 99 then
		table.remove(self._Texts, 1)
	end
    table.insert(self._Texts, param)
end

local function Pop(self)
    if not IsParamExist(self) then return nil end
    return table.remove(self._Texts, 1)
end

local function IsTimerGoing(self)
    return self._TimerId > 0 
end

local function RunOnce(self)
    local function OnTimeOver()
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
        if IsParamExist(self) then
            RunOnce(self)
        end
    end
    
    if not IsNil(self._Target:GetGameObject()) and CPanelDebug.Instance():IsOpenHUD() then
		local item = Pop(self)
		if item ~= nil then
			GameUtil.ShowHUDText(item, self._Target:GetGameObject(), self._Type)
		end
    else
        self:Clear()
    end
    self._TimerId = _G.AddGlobalTimer(self._Interval, true, function() OnTimeOver() end)
end

def.static("table","number","number","=>", CHUDTextPlayer).new = function (target, type, interval)
    local obj = CHUDTextPlayer()
    obj._Target = target
    obj._Type = type
    obj._Interval = interval
    obj._Texts = {}
    return obj
end

def.method("dynamic").Play = function(self, text)
    local t = type(text)
    if t == "number" then
        if IsNumberZero(text) then
            return
        end
    elseif t == "string" then
        if IsNilOrEmptyString(text) then
            return
        end
    end
    Push(self, tostring(text))
    if not IsTimerGoing(self) then
        RunOnce(self)
    end
end

def.method().Clear = function(self)
    self._Texts = {}

    if self._TimerId ~= 0 then
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end
end

def.method().Release = function(self)
    self._Texts = nil

    if self._TimerId ~= 0 then
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end

    self._Target = nil
end

CHUDTextPlayer.Commit()
return CHUDTextPlayer