local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

local CPageBase = Lplus.Class("CPageBase")
local def = CPageBase.define

def.field("table")._Parent = nil         -- 父Panel类
def.field("userdata")._PanelRoot = nil   -- gameobject根节点
def.field("boolean")._IsShown = false	
def.field("table")._EventHandlers = nil        

def.method().Show = function (self)
	if self._IsShown then return end
    self:OnShow()
    self._IsShown = true
end

def.virtual().OnShow = function (self)
end

def.method().Hide = function (self)
    if not self._IsShown then return end
    self:OnHide()
    self._IsShown = false

    -- 清理注册消息
    if self._EventHandlers ~= nil then
    	for k,v in pairs(self._EventHandlers) do
    		CGame.EventManager:removeHandler(k, v)
    	end
    	self._EventHandlers = {}
    end
end

def.virtual().OnHide = function (self)
end

def.method().Destroy = function (self)
    self:OnHide()
    self:OnDestroy()
end

def.virtual().OnDestroy = function (self) 
end

--[[
def.method("string", "function").AddEventHandler = function (self, eventName, func)
	if self._EventHandlers == nil then self._EventHandlers = {} end
	if eventName == nil or eventName == "" or func == nil or self._EventHandlers[eventName] ~= nil then return end
	self._EventHandlers[eventName] = func
	CGame.EventManager:addHandler(eventName, func)
end
]]

CPageBase.Commit()
return CPageBase