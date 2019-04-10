local Lplus = require "Lplus"
local CTransStrategyBase = Lplus.Class("CTransStrategyBase")
local def = CTransStrategyBase.define

def.field("table")._TransMan = nil
def.field("number")._MapID = 0
def.field("table")._TargetPosition = nil
def.field("table")._FinalPosition = nil
def.field("boolean")._IsTransOver = false
def.field("function")._CallBack = nil

def.method("table", "number", "table", "function").Init = function(self, transMan, mapID, pos, callback)
    self._TransMan = transMan
    self._MapID = mapID
    self._FinalPosition = pos
    self._CallBack = callback
end

def.virtual().StartTransLogic = function(self)
end

def.virtual().BrokenTrans = function(self)
end

def.virtual().ContinueTrans = function(self)
    if self._IsTransOver then return end
end

def.virtual().Release = function(self)
end

def.method("=>", "boolean").IsTransOver = function(self)
    return self._IsTransOver
end

CTransStrategyBase.Commit()
return CTransStrategyBase