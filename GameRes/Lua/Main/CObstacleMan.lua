local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CObstacle = require "Object.CObstacle"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"

local CObstacleMan = Lplus.Extend(CEntityMan, "CObstacleMan")
local def = CObstacleMan.define

def.field("userdata")._DynObjectsRoot = nil

def.final("=>", CObstacleMan).new = function ()
	local obj = CObstacleMan()
	obj:Init(CEntityMan.MAN_ENUM.MAN_DYNOBJECT)
	obj._DynObjectsRoot = GameObject.New("DynObjects")
	return obj
end

def.method("table", "=>", CObstacle).CreateDynObject = function (self, info)
	local id = info.EntityInfo.EntityId
	if self:Get(id) ~= nil then
		return self:Get(id)
	end
	
	local dyn = CObstacle.new()
	dyn:Init(info)
	dyn:AddLoadedCallback(function(p)
			if p._GameObject ~= nil then
				p._GameObject.parent = self._DynObjectsRoot
			end
		end)
	dyn:Load()
	self._ObjMap[id] = dyn
	return dyn
end

def.override("boolean").Release = function (self, is_2_release_root)
	CEntityMan.Release(self, is_2_release_root)
	if is_2_release_root then
		Object.DestroyImmediate(self._DynObjectsRoot)
		self._DynObjectsRoot = nil
	end
end

def.override().UpdateAllHeight = function (self)
    local objs = self._ObjMap

    for _,v in pairs(objs) do
        if not v:IsReleased() then
             v:UpdateHeight()
        end
    end
end

CObstacleMan.Commit()

return CObstacleMan
