local Lplus = require "Lplus"

local CEntity = require "Object.CEntity"

local CEntityMan = Lplus.Class("CEntityMan")
local def = CEntityMan.define

def.const("table").MAN_ENUM = 
{
    MAN_PLAYER = 1,
    MAN_NPC = 2,
    MAN_MATTER = 3,
    MAN_SUBOBJECT = 4,
    MAN_DYNOBJECT = 5,  
    MAN_LOOTOBJECT = 6,
    MAN_MINEOBJECT = 7,
    MAN_PETOBJECT = 8,
}

def.field("number")._Type = 0
def.field("table")._ObjMap = nil

def.virtual("number").Init = function (self, type)
	self._Type = type
    self._ObjMap = {}
end

--管理器本身释放掉
def.virtual("boolean").Release = function (self, is_2_release_root)
    local objmap = self._ObjMap
    
    for _,v in pairs(objmap) do
        v:Release()
    end
    
    self._ObjMap = {}
end

def.method("number", "=>", CEntity).Get = function (self, id)
    local obj = self._ObjMap[id]
    if obj ~= nil and not obj:IsReleased() then
        return obj
    else
        return nil
    end
end

--管理器本身的元素
def.virtual("number", "number", "=>", CEntity).Remove = function (self, id, leaveType)
    local obj = self._ObjMap[id]
    if obj ~= nil then
        --obj:DoDisappearEffect(leaveType)
        self._ObjMap[id] = nil
        obj:Release()
    end

    return obj
end

def.method("function").ForEach = function(self, cb)
    if cb == nil then return end
    for k,v in pairs(self._ObjMap) do
        cb(v)
    end
end

def.virtual().UpdateAllHeight = function (self)
    
end

def.virtual().Update = function (self)
end

CEntityMan.Commit()

return CEntityMan