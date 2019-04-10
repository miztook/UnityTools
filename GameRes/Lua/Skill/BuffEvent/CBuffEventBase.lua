-- buff 事件基类
local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")

local CBuffEventBase = Lplus.Class("CBuffEventBase")
local def = CBuffEventBase.define

def.field(CEntity)._Host = nil
def.field("table")._Event = nil
def.field("table")._Params = nil

def.virtual().OnEvent = function(self)
end

def.virtual().OnBuffEnd = function(self)
	self._Host = nil
	self._Event = nil
	self._Params = nil
end

CBuffEventBase.Commit()
return CBuffEventBase
