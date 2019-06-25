local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local CMineral =  require "Object.CMineral"
local CQuest = require "Quest.CQuest"
local SqrDistanceH = Vector3.SqrDistanceH_XZ

local CMineMan = Lplus.Extend(CEntityMan, "CMineMan")
local def = CMineMan.define

def.field("userdata")._MineObjectsRoot = nil
def.field("number")._UpdateInterval = 0


--[[
message EntityInfo
{
	required int32 EntityId			= 1;
	required vector3 Position		= 2;
	required vector3 Orientation	= 3;
}

message MineInfo
{
	required EntityInfo EntityInfo	= 1;
	optional int32 MineTid			= 2;
}
]]
def.final("=>", CMineMan).new = function ()
	local obj = CMineMan()
	obj:Init(CEntityMan.MAN_ENUM.MAN_MINEOBJECT)
	obj._MineObjectsRoot = GameObject.New("Mines")
	
	return obj
end

def.method("table", "=>", CMineral).CreateMineObject= function (self, info)
	-- warn(debug.traceback())
	-- warn("mine created..")
	local id = info.EntityInfo.EntityId
	if self:Get(id) ~= nil then
		--warn("There is another mine with the same id, id = ", id)
		return self:Get(id)
	end

	local mine = nil
	mine = CMineral.new()
	mine:Init(info)
	mine:AddLoadedCallback(function(p)
			if p._GameObject ~= nil then
				p._GameObject.parent = self._MineObjectsRoot
			end
		end)
	mine:Load()
	self._ObjMap[id] = mine
	-- warn("mine count :",#self._ObjMap)
	return mine
end

def.method("number", "=>", CMineral).GetByTid = function (self, tid)
	for k,v in pairs(self._ObjMap) do
		if v:GetTemplateId() == tid then
			return v
		end
	end

	return nil
end

def.method("function", "=>", CMineral).GetByFilter = function (self, filter)
	local mines = self._ObjMap
	local dis = 9999999
	local hostX, hostZ = game._HostPlayer:GetPosXZ()
	local result = nil

	for _,v in pairs(mines) do
		if filter == nil then
			local vPosX, vPosZ = v:GetPosXZ()
			local curDis = SqrDistanceH(hostX, hostZ, vPosX, vPosZ)
			if curDis < dis then
				result = v
				dis = curDis
			end
		else
			if filter(v) then
				local vPosX, vPosZ = v:GetPosXZ()
				local curDis = SqrDistanceH(hostX, hostZ, vPosX, vPosZ)
				if curDis < dis then
					result = v
					dis = curDis
				end
			end
		end
	end

	return result
end

def.method("number", "=>", CMineral).GetByHostQuickTalk = function (self, quicktalk_distance_sqr)
	local mines = self._ObjMap
	local dis = 9999999
	local hostX, hostZ = game._HostPlayer:GetPosXZ()
	local result = nil

	for _,v in pairs(mines) do
		--非任务模式下的对象也显示快捷方式 与原有设计更改
		--if v:GetCanGather() and CQuest.Instance():IsMyGatherTarget(v:GetTemplateId()) then
		if v:GetCanGather() then
			local posX, posZ = v:GetPosXZ()

			local d = SqrDistanceH(hostX, hostZ, posX, posZ)
			--快捷半径 + 自己得可采集半径
			if d <= quicktalk_distance_sqr + v:GetRadius() * v:GetRadius() then 
				local curDis = d
				if curDis < dis then
					result = v
					dis = curDis
				end
			end
		end
	end

	return result
end

def.override("boolean").Release = function (self, is_2_release_root)
	CEntityMan.Release(self, is_2_release_root)
	if is_2_release_root then
		Object.Destroy(self._MineObjectsRoot)
		self._MineObjectsRoot = nil
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

def.method("table").UpdateVisible = function (self, ls)
end

CMineMan.Commit()

return CMineMan
