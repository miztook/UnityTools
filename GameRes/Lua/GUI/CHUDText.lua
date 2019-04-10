local Lplus = require 'Lplus'
local CHUDText = Lplus.Class('CHUDText')
local def = CHUDText.define
local CHUDTextPlayer = require "GUI.CHUDTextPlayer"

def.field("table")._HUDs = nil
def.field("table")._Target = nil

def.static("table", "=>", CHUDText).new = function(target)
    local instance = CHUDText()
    instance._Target = target
    instance._HUDs = {}
    return instance
end

def.method("number","dynamic").Play = function(self, type, text)
    local hud = self._HUDs[type]
    if hud == nil and self._Target ~= nil then
        hud = CHUDTextPlayer.new(self._Target:GetGameObject(), type, 0.15)
        self._HUDs[type] = hud
    end
    hud:Play(text)
end

def.method().Clear = function(self)
    for k,v in pairs(self._HUDs) do
        v:Clear()
    end
    self._HUDs = {}
end

def.method().Release = function(self)
    for k,v in pairs(self._HUDs) do
        v:Release()
    end
    self._HUDs = nil
    self._Target = nil
end

CHUDText.Commit()
return CHUDText