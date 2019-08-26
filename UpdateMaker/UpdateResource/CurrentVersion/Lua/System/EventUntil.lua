local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")

--local CElementData = require "Data.CElementData"
--local CPath = require "Path.CPath"

local click_event = nil
local function raiseNotifyClickEvent(obj)
	if click_event == nil then
		local NotifyClick = require "Events.NotifyClick"
    	click_event = NotifyClick()
    end
    click_event._Param = obj
    CGame.EventManager:raiseEvent(nil, click_event)
end


local uiShortcutEvent = nil
local function raiseUIShortCutEvent(type, data)
	if uiShortcutEvent == nil then
		local NotifyClick = require "Events.UIShortCutEvent"
    	uiShortcutEvent = NotifyClick()
    end
    uiShortcutEvent._Type = type
    uiShortcutEvent._Data = data
    CGame.EventManager:raiseEvent(nil, uiShortcutEvent)
end


local function raiseConnectEvent()
    local ConnectEvent = require "Events.ConnectEvent"
    local event = ConnectEvent()
    CGame.EventManager:raiseEvent(nil, event)
end


local function raiseDisconnectEvent()
	local DisconnectEvent = require "Events.DisconnectEvent"
    local event = DisconnectEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

local function raiseQuitGameEvent()
	local ApplicationQuitEvent = require "Events.ApplicationQuitEvent"
    local event = ApplicationQuitEvent()
    CGame.EventManager:raiseEvent(nil, event)
end

local closeTipsEvent = nil
local function raiseCloseTipsEvent()
	if closeTipsEvent == nil then
		local CloseTipsEvent = require "Events.CloseTipsEvent"
    	closeTipsEvent = CloseTipsEvent()
    end
    CGame.EventManager:raiseEvent(nil, closeTipsEvent)
end

local carePlayerListChangeEvent = nil
local function raiseCarePlayerListChangeEvent()
    if carePlayerListChangeEvent == nil then
        local CarePlayerListChangeEvent = require "Events.CarePlayerListChangeEvent"
        carePlayerListChangeEvent = CarePlayerListChangeEvent()
    end
    CGame.EventManager:raiseEvent(nil, carePlayerListChangeEvent)
end

_G.EventUntil =
{
	RaiseNotifyClickEvent = raiseNotifyClickEvent,
	RaiseUIShortCutEvent = raiseUIShortCutEvent,
	RaiseConnectEvent = raiseConnectEvent,
	RaiseDisconnectEvent = raiseDisconnectEvent,
	RaiseQuitGameEvent = raiseQuitGameEvent,

    RaiseCloseTipsEvent = raiseCloseTipsEvent,
	RaiseCarePlayerListChangeEvent = raiseCarePlayerListChangeEvent,
}