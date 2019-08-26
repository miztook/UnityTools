
local Lplus = require "Lplus"

local BaseStateChangeEvent = Lplus.Class("BaseStateChangeEvent")
local def = BaseStateChangeEvent.define

def.field("boolean").IsEnterState = false

BaseStateChangeEvent.Commit()
return BaseStateChangeEvent