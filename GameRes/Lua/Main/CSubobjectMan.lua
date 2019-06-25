local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local CSubobject = require "Object.CSubObject"
local ObjectDieEvent = require "Events.ObjectDieEvent"
local Template = require "PB.Template"

local CSubobjectMan = Lplus.Extend(CEntityMan, "CSubobjectMan")
local def = CSubobjectMan.define

def.field("userdata")._SubobjectsRoot = nil

def.final("=>", CSubobjectMan).new = function ()
	local obj = CSubobjectMan()
	obj:Init(CEntityMan.MAN_ENUM.MAN_SUBOBJECT)
	obj._SubobjectsRoot = GameObject.New("Subobjects")	
	return obj	
end

-- 统一接口命名规则，此接口提供外部调用
def.method("table").CreateSubobject = function(self, msg)
	local id = msg.MovableInfo.EntityInfo.EntityId	
	-- 已经创建, 客户端预先创建机制已经移除, 属于异常情况
	if self._ObjMap[id] ~= nil then return end

	local so = CSubobject.new()
	so:Init(msg)

	if so:IsReadyToLoad() then
		so:AddLoadedCallback(function(p)
				if p._GameObject ~= nil then
					p._GameObject.parent = self._SubobjectsRoot
				end
			end)
		so:Load()
		self._ObjMap[id] = so
	end
end

def.override("boolean").Release = function (self, is_2_release_root)
	CEntityMan.Release(self, is_2_release_root)
	if is_2_release_root then
		Object.Destroy(self._SubobjectsRoot)
		self._SubobjectsRoot = nil
	end
end

CSubobjectMan.Commit()

return CSubobjectMan
