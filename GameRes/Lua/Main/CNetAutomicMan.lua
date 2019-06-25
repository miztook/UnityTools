local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local DisconnectEvent = require "Events.DisconnectEvent"
local ConnectEvent = require "Events.ConnectEvent"

-- AutomicItem的逻辑对象
local CAutomicItem = Lplus.Class("CAutomicItem")
do
	local def = CAutomicItem.define

	def.field("number")._ID = -1
    def.field("function")._DisconnectCB = nil
    def.field("function")._ConnectCB = nil

	local _uniqueID = 1
	local function uniqueId()
		local r = _uniqueID
		_uniqueID = _uniqueID + 1
		return r
	end

    def.method().DisconnectHandle = function(self)
        if self._DisconnectCB ~= nil then 
            self._DisconnectCB()
            self._DisconnectCB = nil
        end
    end

    def.method().ReconnectHandle = function(self)
        if self._ConnectCB ~= nil then
            self._ConnectCB()
            self._ConnectCB = nil
        end
    end

	def.static("=>",CAutomicItem).new = function()
		local obj = CAutomicItem()
		obj._ID = uniqueId()
		return obj
	end

    def.method().Release = function(self)
        self._ID = -1
        self._DisconnectCB = nil
        self._ConnectCB = nil
    end
end
CAutomicItem.Commit()


local CNetAutomicMan = Lplus.Class("CNetAutomicMan")
local def = CNetAutomicMan.define

def.field("table")._AutomicItems = nil
def.field("boolean")._IsDisconnecting = false
def.field("function")._DisconnectCB = nil
def.field("function")._ConnectCB = nil

def.static("=>", CNetAutomicMan).new = function()
    local item = CNetAutomicMan()
    item._AutomicItems = {}
    item:RegistEvents()
    return item
end


def.method().RegistEvents = function(self)
    self:UnRegistEvents()
    self._DisconnectCB = function(sender, event)
        if self._AutomicItems == nil then return end
        for i,v in ipairs(self._AutomicItems) do
            if v ~= nil then
                v:DisconnectHandle()
            end
        end
        self._IsDisconnecting = true
    end
    self._ConnectCB = function(sender, event)
        if self._AutomicItems == nil then return end
        for i,v in ipairs(self._AutomicItems) do
            if v ~= nil then
                v:ReconnectHandle()
                v:Release()
            end
        end
        self._AutomicItems = nil
        self._IsDisconnecting = false
    end
    CGame.EventManager:addHandler(DisconnectEvent, self._DisconnectCB)
    CGame.EventManager:addHandler(ConnectEvent, self._ConnectCB)
end

def.method().UnRegistEvents = function(self)
    if self._DisconnectCB ~= nil then
        CGame.EventManager:removeHandler(DisconnectEvent, self._DisconnectCB)
    end
    if self._ConnectCB ~= nil then
        CGame.EventManager:removeHandler(ConnectEvent, self._ConnectCB)
    end

    self._DisconnectCB = nil
    self._ConnectCB = nil
end

def.method("=>", "boolean").IsDisconnecting = function(self)
    return self._IsDisconnecting
end


def.method("function", "function", "=>", "number").RegistAutomicHandle = function(self, onDisconnectCB, onReconnectCB)
    if self._AutomicItems ~= nil then
        for i,v in ipairs(self._AutomicItems) do
            if v ~= nil then
                if v._DisconnectCB == onDisconnectCB and v._ConnectCB == onReconnectCB then
                    return v._ID
                end
            end
        end
    end
    local item = CAutomicItem.new()
    item._DisconnectCB = onDisconnectCB
    item._ConnectCB = onReconnectCB
    if self._AutomicItems == nil then
        self._AutomicItems = {}
    end
    self._AutomicItems[#self._AutomicItems + 1] = item
    return item._ID
end

def.method("number").UnRegistAutomicHandle = function(self, id)
    if self._AutomicItems == nil then return end
    for i,v in ipairs(self._AutomicItems) do
        if v._ID == id then
            v:Release()
            table.remove(self._AutomicItems, i)
            return
        end
    end
end

def.method().Release = function(self)
    self:UnRegistEvents()
    self._AutomicItems = nil
    self._IsDisconnecting = false
end

CNetAutomicMan.Commit()
return CNetAutomicMan
