local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CGame = Lplus.ForwardDeclare("CGame")
local CModel = require "Object.CModel"
local Template = require "PB.Template"
local ACTOR_DIE_MASK = require "Skill.SkillDef".ACTOR_DIE_MASK
local EIndicatorType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillIndicator.EIndicatorType
local bit = require "bit"
local ObjectInfoList = require "Object.ObjectInfoList"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CFxObject = require "Fx.CFxObject"

local CSubobject = Lplus.Extend(CEntity, "CSubobject")
local def = CSubobject.define

def.field(CFxObject)._GfxObject = nil
def.field(CFxObject)._SkillIndicatorFx = nil 		--附带的技能指示器
def.field("number")._Type = 0
def.field("table")._ActorTemplate = nil
def.field("number")._Radius = 0
def.field("number")._SkillId = 0
def.field("table")._Dest = nil             -- GFX生存期和Subobject可能不一致，当GFX回收后，保存当时的位置信息
def.field("number")._OwnerID = 0           -- 所有者
def.field("number")._BelongedActorId = 0    
def.field("number")._TargetID = 0    -- 追踪目标
def.field("number")._Tid = 0          -- 子物体TID
def.field("number")._TrackId = 0     
def.field("table")._TargetPos = nil    
def.field("number")._BirthPlace = 0     
def.field("string")._BirthPlaceParam = ""   

def.field("table")._NormalEndCallbacks = nil
def.field("table")._AbnormalEndCallbacks = nil

def.field("table")._CollisionEvents = nil
def.field("boolean")._IsAttched = false    	-- 是否为跟随
def.field("table")._ActiveEventList = BlankTable

def.static("=>", CSubobject).new = function ()
	local obj = CSubobject()
	obj._InfoData = ObjectInfoList.CObjectInfo()
	return obj
end

-- 改成msg信息init
def.override("table").Init = function (self, msg) 
	local pbPos = msg.MovableInfo.EntityInfo.Position
    local pbOri = msg.MovableInfo.EntityInfo.Orientation
    
    self._InitPos = Vector3.New(pbPos.x,  pbPos.y, pbPos.z)
    self._InitPos.y = GameUtil.GetMapHeight(self._InitPos)
    self._InitDir = Vector3.New(pbOri.x, 0, pbOri.z)

	self._ID = msg.MovableInfo.EntityInfo.EntityId	
	self._OwnerID = msg.BelongerId 
	self._BelongedActorId = msg.BelongedActorId 

	local CElementSkill = require "Data.CElementSkill"
	self._ActorTemplate = CElementSkill.GetActor(msg.SubobjectTid)
	self._Type = self._ActorTemplate.Type
	self._Radius = self._ActorTemplate.ColliderParam
	self._Tid = msg.SubobjectTid

	self._BirthPlace = msg.BirthPlace 
	self._BirthPlaceParam = msg.BirthPlaceParam

	-- 暂时写为0
	self._SkillId = 0 -- info.SkillId

	self._TrackId = msg.TrackId 
	self._TargetPos = msg.TargetPos
end

def.method("=>", "boolean").IsReadyToLoad = function (self)
	if self._ActorTemplate == nil then 
		return false
	end

	-- 子物体会在前后两端对象进入视野时做二次同步
	if self._ActorTemplate.SubType == Template.Actor.SubobjectType.Chain then
		local world = game._CurWorld
		local owner = world:FindObject(self._OwnerID)		
		local target = world:FindObject(self._TrackId)
		return (owner ~= nil and target ~= nil)
	else
		return true
	end
end

-- 设置gfx
def.method(CFxObject, "boolean").SetGfxInfo = function (self, gfx, followHook)
	self._GfxObject = gfx
	self._IsAttched = followHook
end

local function CreateGameObject(self)
	if self._IsReleased then return end

	self._Model = CModel.new()
	self._Model._ModelFxPriority = self:GetModelCfxPriority()
	local root = GameUtil.GetEntityBaseRes()
    root.name = tostring(self:GetTemplateId()) .. "_" .. tostring(self._ID)
    self._GameObject = root
    self._Shadow = nil
    
	GameUtil.AddObjectComponent(self, root, self._ID, self:GetObjectType(), self._Radius)

	local CSkillActorMan = require "Skill.CSkillActorMan"	
	CSkillActorMan.Instance():GenerateSubobjectActor(self)

	if self._GfxObject ~= nil then
		self._Model._GameObject = self._GfxObject:GetGameObject()

		if not self._IsAttched then
			if not IsNil(self._Model._GameObject) then
				self._Model._GameObject.parent = root
			end			
		end
	end

	self._IsReady = true
	self:OnModelLoaded()
end

-- 子物体比较特殊：其模型大多为一个GFX，GFX自己存亡由GfxCache控制
-- 所以此处不需要调用异步加载，完成相关Prefab的加载
def.virtual().Load = function (self)
	if self._ActorTemplate.SubType == Template.Actor.SubobjectType.Chain then
		--warn("===>", self:GetTemplateId(), self._OwnerID, self._TrackId)
		local world = game._CurWorld
		local owner = world:FindObject(self._OwnerID)		
		local target = world:FindObject(self._TrackId)
		if owner ~= nil and target ~= nil then  -- 必须保证的前提
			if owner:IsModelLoaded() and target:IsModelLoaded() then  -- 都已加载好
				CreateGameObject(self)
			elseif owner:IsModelLoaded() and not target:IsModelLoaded() then
				target:AddLoadedCallback(function()
						CreateGameObject(self)
					end)
			elseif not owner:IsModelLoaded() and target:IsModelLoaded() then
				owner:AddLoadedCallback(function()
						CreateGameObject(self)
					end)
			else
				owner:AddLoadedCallback(function()
						if target:IsModelLoaded() then
							CreateGameObject(self)
						end
					end)
				target:AddLoadedCallback(function()
						if owner:IsModelLoaded() then
							CreateGameObject(self)
						end
					end)
			end		
		end
	else
		CreateGameObject(self)
	end
end

def.override().OnModelLoaded = function (self)
    if self._OnLoadedCallbacks then
        for i,v in ipairs(self._OnLoadedCallbacks) do
            v(self)
        end
        self._OnLoadedCallbacks = nil
    end
end

def.override("=>", "table").GetPos = function (self)
    if not self._IsReady then
        return self._InitPos
    end

    if self._GfxObject == nil or self._GfxObject:GetGameObject() == nil then
    	if self._Dest ~= nil then
    		return Vector3.New(self._Dest.x, self._Dest.y, self._Dest.z)
    	else
    	 	return self._InitPos
    	end
    else
    	return self._GfxObject:GetGameObject().position
    end
end

def.override("=>", "number", "number", "number").GetPosXYZ = function (self)
    if not self._IsReady then
        return 0, 0, 0
    end
    
    if self._GfxObject ~= nil and self._GfxObject:GetGameObject() ~= nil then
    	return self._GfxObject:GetGameObject():PositionXYZ()
    end

    if self._Dest ~= nil then
    	return self._Dest.x, self._Dest.y, self._Dest.z
    else
    	return self._InitPos.x, self._InitPos.y, self._InitPos.z
    end
end

def.override("=>", "number", "number").GetPosXZ = function (self)
    if not self._IsReady then
        return 0, 0
    end
    
    if self._GfxObject ~= nil and self._GfxObject:GetGameObject() ~= nil then
    	return self._GfxObject:GetGameObject():PositionXZ()
    end

    if self._Dest ~= nil then
    	return self._Dest.x, self._Dest.z
    else
    	return self._InitPos.x, self._InitPos.z
    end
end

def.override("=>", "table").GetDir = function (self)
    return self._InitDir
end

def.override("=>", "number", "number", "number").GetDirXYZ = function (self)
   return self._InitDir.x, self._InitDir.y, self._InitDir.z
end

def.override("=>", "number", "number").GetDirXZ= function (self)
    return self._InitDir.x, self._InitDir.z
end

def.method("table").OnGfxLifeEnd = function(self, die_pos)
	if self._SkillIndicatorFx ~= nil then
		self._SkillIndicatorFx:Stop()
	end

	if self._Type == Template.Actor.ActorType.Subobject and self._GfxObject ~= nil then
		self._GfxObject:Stop()
	end

	self._GfxObject = nil

	if self._Model ~= nil then
		self._Model._GameObject = nil
	end
	self._Dest = die_pos
end

def.method().ClearActiveEvents = function (self)
	self._ActiveEventList = {}
end

-- 注册到活动事件列表里面
def.method("dynamic").RegistActiveEvent = function (self, event)
	if not event then return end
	if self._ActiveEventList == nil then
		self._ActiveEventList = {}
	end
	table.insert(self._ActiveEventList, event) 
end

def.override("=>", "number").GetObjectType = function (self)
	if self._Type == Template.Actor.ActorType.Subobject then
	    return OBJ_TYPE.SUBOBJECT
	else
		return -1
	end
end

local function OnLifeAbnormalEnd(self)
	if self._AbnormalEndCallbacks ~= nil then
		for i,v in ipairs(self._AbnormalEndCallbacks) do
			v()
		end
	end
end

def.override("=>", "number").GetTemplateId = function(self)
	if self._ActorTemplate == nil then
		return 0
	else
    	return self._ActorTemplate.Id
    end
end

def.override("number", "number", "=>", "boolean").OnCollideWithOther = function(self, colliderId, collideEntityType)
	if colliderId == self._OwnerID then return false end

	if colliderId == 0 then   -- 撞墙上了，消失
		-- TODO

	else  -- 撞Object上了，
		local collider = game._CurWorld:FindObjectByShortID(colliderId)
		if collider == nil or collider:IsDead() then  -- 碰撞体死亡，忽略
			return false
		end

		--[[
		-- 每个Client只负责自己的子物体
		if false and self._OwnerID == host_id and self._ID ~= 0 then
			local msg = CreateEmptyProtocol("C2SEntityCollide")
	    	msg.EntityId = host_id
	    	msg.SubobjectId = self._ID
			msg.ColliderId = colliderId
			SendProtocol2Server(msg)
		end
		]]
	end

	local has_collided = true
	if self._ActorTemplate.SubType == Template.Actor.SubobjectType.TrackingFlight then
		has_collided = self._TargetID ~= 0 and self._TargetID == colliderId
	end

	if not has_collided then return false end

	if self._CollisionEvents ~= nil then
		for i,v in ipairs(self._CollisionEvents) do
			v:OnEvent()
		end
	end

	if self._ActorTemplate.DisappearConditionCollision then
		OnLifeAbnormalEnd(self)
	end

	return true
end

--播放预警指示特效
def.method("number", "number", "number", "number", "=>", "boolean").PlaySkillIndicatorGfx = function (self, skill_indicator_type, duration, param1, param2)
	local gfx_path = nil
	local scale = Vector3.one
	if skill_indicator_type == EIndicatorType.Circular then
		gfx_path = PATH.Etc_Yujing_Ring
		scale.x = param1 + 0.5
		scale.y = 1
		scale.z = param1+ 0.5
	elseif skill_indicator_type == EIndicatorType.Fan then
		gfx_path = PATH["Etc_Yujing_Shanxing"..param2]

		if gfx_path == nil then
			warn("Cannot find path:", "Etc_Yujing_Shanxing"..param2)
			gfx_path = ""
		end

		scale.x = param1+ 0.5
		scale.y = 1
		scale.z = param1+ 0.5
	elseif skill_indicator_type == EIndicatorType.Rectangle then
		gfx_path = PATH.Etc_Yujing_Juxing
		
		scale.x = param1+ 0.5
		scale.y = 1
		scale.z = param2+ 0.5
	-- 环形
	elseif skill_indicator_type == EIndicatorType.Ring then
		gfx_path = PATH.Etc_Yujing_Hollow
		scale.x = param2 + 0.5 -- 外径
		scale.y = 1
		scale.z = param1 - 0.5 -- 内径		
	else
		return false
	end

	local pos = self:GetPos()
	pos.y = pos.y + 0.2
	local dir = self:GetDir()

	if self._SkillIndicatorFx == nil then
		self._SkillIndicatorFx = CFxObject.new()
	end
	local fx, id = GameUtil.PlayEarlyWarningGfx(gfx_path, pos, dir, scale, duration)
	self._SkillIndicatorFx:Init(id, fx, nil)

	return true
end

def.override().Release = function (self)
	if self._NormalEndCallbacks ~= nil then
		for i,v in ipairs(self._NormalEndCallbacks) do
			v()
		end
	end

	for i,v in ipairs(self._ActiveEventList) do
		v:OnRelease()	
	end
	self._ActiveEventList = nil
	
	self._AbnormalEndCallbacks = nil
	self._CollisionEvents = nil	
	self:OnGfxLifeEnd(Vector3.zero)
	CEntity.Release(self)
end

CSubobject.Commit()
return CSubobject
