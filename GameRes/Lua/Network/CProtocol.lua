local Lplus = require "Lplus"

local CProtocol = Lplus.Class("CProtocol")
local def = CProtocol.define

def.virtual("=>", "number").GetType = function (self)
end

def.virtual("userdata").Marshal = function (self, os)
end

def.virtual("userdata").Unmarshal = function (self, os)
end

CProtocol.Commit()

return CProtocol