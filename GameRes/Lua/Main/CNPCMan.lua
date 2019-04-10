local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CNonPlayerCreature = require "Object.CNonPlayerCreature"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local CMonster =  require "Object.CMonster"
local CPlayerMirror =  require "Object.CPlayerMirror"
local CNpc = require "Object.CNpc"
local CElementData = require "Data.CElementData"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local SqrDistanceH = Vector3.SqrDistanceH_XZ

local CNPCMan = Lplus.Extend(CEntityMan, "CNPCMan")
local def = CNPCMan.define

def.field("userdata")._NPCsRoot = nil
def.field("number")._UpdateInterval = 0
def.field("table")._NpcVisibleList = nil

--由于若干个模块都需要遍历npc列表, 因此用一个timer保存enemy, friend列表，避免重复遍历
def.field("number")._CheckNpcListTimer = 0
def.field("table")._EnemyNpcList = BlankTable
def.field("table")._FriendNpcList = BlankTable
def.field("table")._ActiveNpcList = BlankTable

def.field("table")._NpcAnimationList = nil 

def.final("=>", CNPCMan).new = function ()
	local obj = CNPCMan()
	obj:Init(CEntityMan.MAN_ENUM.MAN_NPC)
	obj._NPCsRoot = GameObject.New("NPCs")
	return obj
end

def.override("number").Init = function (self, type)
	CEntityMan.Init(self, type)

	if self._CheckNpcListTimer == 0 then
		self._CheckNpcListTimer = _G.AddGlobalTimer(auto_detector_time, false, function() 
				self:RefreshNpcList() 
			end )
	end
end

def.override("number", "number", "=>", CEntity).Remove = function (self, id, leaveType)
    self._EnemyNpcList[id] = nil
	self._FriendNpcList[id] = nil
	self._ActiveNpcList[id] = nil
    return CEntityMan.Remove(self, id, leaveType)
end

--刷新npc敌对和友善列表
def.method().RefreshNpcList = function(self)

	local NPCs = self._ObjMap

	self._EnemyNpcList = {}
	self._FriendNpcList = {}
	self._ActiveNpcList = {}

	for i,v in pairs(NPCs) do
		if not v:IsReleased() and not v:IsDead() and v:CanBeSelected() then
			local relation = v:GetRelationWithHost()
			if relation == "Enemy" then
				self._EnemyNpcList[i] = v
			elseif relation == "Friendly" then
				self._FriendNpcList[i] = v
			end

			self._ActiveNpcList[i] = v
		end
	end

	--warn("enemyCount: ", enemyCount, "friendCount: ", friendCount)
end

def.method("table", "number", "=>", CNonPlayerCreature).CreateMonster = function (self, info, enterType)
	local id = info.CreatureInfo.MovableInfo.EntityInfo.EntityId
	--print("CreateMonster", id, debug.traceback())
	if self:Get(id) ~= nil then
		--warn("There is another monster with the same id, id = ", id)
		return self:Get(id)
	end

	local monster = nil
	monster = CMonster.new()
	monster:Init(info)
	monster:AddLoadedCallback(function(p)
			if p._GameObject ~= nil then
				p._GameObject.parent = self._NPCsRoot
			end
		end)
	monster:Load(enterType)
	self._ObjMap[id] = monster
	return monster
end

def.method("table", "=>", "boolean").IsNpcCreateble = function(self, msg_npc)
	if msg_npc == nil then
		warn("the npc message is nil.")
		return false
	end
	local id = msg_npc.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
	if self:Get(id) ~= nil then
		--warn("There is another npc with the same id, id = ", id)
		return false
	end
	local npc_template = CElementData.GetNpcTemplate(msg_npc.NpcTid)
	if npc_template == nil then
		warn("OnNpcEnterMap npcTemplate = nil", msg_npc.NpcTid)
		return false
	end
	return true
end

def.method("table", "number", "=>", CNonPlayerCreature).CreateNpc = function (self, info, enterType)
	if self:IsNpcCreateble(info) then
		local npc = nil
		local entity_id = info.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
		npc = CNpc.new()
		npc:Init(info)
		npc:AddLoadedCallback(function(p)
				if p._GameObject ~= nil then
					p._GameObject.parent = self._NPCsRoot
				end
			end)
		npc:Load(enterType)
		self._ObjMap[entity_id] = npc
		return npc
	end
	return nil
end

def.method("table", "=>", CNonPlayerCreature).CreatePlayerMirror = function (self, info)
	local id = info.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
	if self:Get(id) ~= nil then
		return self:Get(id)
	end

	local playerMirror = nil
	playerMirror = CPlayerMirror.new()
	playerMirror:Init(info)
	playerMirror:AddLoadedCallback(function(p)
			if p._GameObject ~= nil then
				p._GameObject.parent = self._NPCsRoot
			end
		end)
	local enterType = EnumDef.SightUpdateType.Unknown
	playerMirror:Load(enterType)
	self._ObjMap[id] = playerMirror
	return playerMirror
end

def.method("number", "=>", CNonPlayerCreature).GetByTid = function (self, tid)
	for _,v in pairs(self._ObjMap) do
		if v:GetTemplateId() == tid then
			return v
		end
	end

	return nil
end

def.method("string", "function", "=>", CNonPlayerCreature).GetByFilter = function (self, relation, filter)
	local npcs = nil
	if relation == "Enemy" then
		npcs = self._EnemyNpcList
	elseif relation == "Friendly" then
		npcs = self._FriendNpcList
	else
		npcs = {}	
	end

	local dis = 9999999
	local hostX, hostZ = game._HostPlayer:GetPosXZ()
	local result = nil

	for _,v in pairs(npcs) do
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

def.method("string", "number", "number", "number", "number", "=>", CNonPlayerCreature).GetByHostAreaCollide = function (self, relation, areaType, radius, length, angle)
	local npcs = nil
	if relation == "Enemy" then
		npcs = self._EnemyNpcList
	elseif relation == "Friendly" then
		npcs = self._FriendNpcList
	else
		npcs = {}	
	end

	local host = game._HostPlayer
	local target_radius = 0.5
	local dis = 9999999
	local hostPosX, hostPosY, hostPosZ = host:GetPosXYZ()
	local hostDirX, hostDirY, hostDirZ = host:GetDirXYZ()
	local result = nil

	local shape = nil
	for _,v in pairs(npcs) do
		local posX, posY, posZ = v:GetPosXYZ()

		local curDis = SqrDistanceH(hostPosX, hostPosZ, posX, posZ)
		if curDis < dis then 
			if shape == nil then shape = SkillCollision.CreateShapeXYZ(areaType, radius, length, angle, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ) end

			if shape:IsCollidedXYZ(posX, posY, posZ, target_radius) and GameUtil.PathFindingCanNavigateToXYZ( hostPosX, hostPosY, hostPosZ, posX, posY, posZ, _G.NAV_STEP) then
				result = v
				dis = curDis
			end
		end
	end

	return result
end

def.method("string", "number", "=>", CNonPlayerCreature).GetByHostQuickTalk = function (self, relation, quicktalk_distance_sqr)
	local npcs = nil
	if relation == "Enemy" then
		npcs = self._EnemyNpcList
	elseif relation == "Friendly" then
		npcs = self._FriendNpcList	
	else
		npcs = {}
	end

	local host = game._HostPlayer
	local hoh = host._OpHdl
	local target_radius = 0.5
	local dis = 9999999
	local hostPosX, hostPosZ = host:GetPosXZ()
	local result = nil

	for _,v in pairs(npcs) do
		if v:GetObjectType() == OBJ_TYPE.NPC then
			local posX, posZ = v:GetPosXZ()
			local d = SqrDistanceH(hostPosX, hostPosZ, posX, posZ)
			if d <= quicktalk_distance_sqr then 
				local curDis = d
				if curDis < dis and hoh:HaveServiceOptions(v, nil) then
					result = v
					dis = curDis
				end
			end
		end
	end

	return result
end

def.override().UpdateAllHeight = function (self)
	local objs = self._ObjMap

    for _,v in pairs(objs) do
        if not v:IsReleased() then
             local pos = v:GetPos()
             v:SetPos(pos)
        end
    end
end

def.method("table").UpdateVisible = function (self, ls)
	
end

-- 通过tid获取stand 和Run动画
def.method("number","=>","table").GetStandAndRunAnimationByNpcTid = function (self,tid)
	if self._NpcAnimationList ~= nil then 
		return self._NpcAnimationList[tid]
	else
		return nil 
	end
end

-- 存储对应tid 的Npc动画
def.method("number","string","string").SaveNPCAnimationName = function (self,tid,standAnimaName,runAnimaName)
	if self._NpcAnimationList == nil then 
		self._NpcAnimationList = {}
	end
	self._NpcAnimationList[tid] = {}
	self._NpcAnimationList[tid].StandAnimaName = standAnimaName
	self._NpcAnimationList[tid].RunAnimaName = runAnimaName
end

-- 服务器通知NPC改变动画
def.method("number","string","string").ControlNpcPlayAnimation = function (self,tid,standAnimaName,runAnimaName)
	for i,v in pairs(self._ObjMap) do 
		if v:GetTemplateId() == tid then
			self:SaveNPCAnimationName(tid,standAnimaName,runAnimaName)
			local state = v:GetCurStateType()
			if state == FSM_STATE_TYPE.MOVE then 
				v:PlayAnimation(EnumDef.CLIP.COMMON_RUN, 0, false, 0,1)
			elseif state == FSM_STATE_TYPE.IDLE then 
				v:PlayAnimation(EnumDef.CLIP.BATTLE_STAND, 0, false, 0, 1)
			end
		end
	end
	
end

-- 清除NPC动画列表
def.method().ClearNPCAnimationList = function (self)
	if self._NpcAnimationList ~= nil then 
		self._NpcAnimationList = nil 
	end
end

def.override("boolean").Release = function (self, is_2_release_root)
	if is_2_release_root then
		if self._CheckNpcListTimer ~= 0 then
			_G.RemoveGlobalTimer(self._CheckNpcListTimer)
			self._CheckNpcListTimer = 0
		end
	end

	self._EnemyNpcList = {}
	self._FriendNpcList = {}
	self._ActiveNpcList = {}

	CEntityMan.Release(self, is_2_release_root)

	if is_2_release_root then
		Object.DestroyImmediate(self._NPCsRoot)
		self._NPCsRoot = nil
	end
end

CNPCMan.Commit()

return CNPCMan
