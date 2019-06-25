local Lplus = require "Lplus"
local CEntityMan = require "Main.CEntityMan"
local CElsePlayer = require "Object.CElsePlayer"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local UserData = require "Data.UserData".Instance()
local SqrDistanceH = Vector3.SqrDistanceH_XZ

local CPlayerMan = Lplus.Extend(CEntityMan, "CPlayerMan")
local def = CPlayerMan.define

def.field("userdata")._PlayersRoot = nil
def.field("number")._UpdateInterval = 0

--由于若干个模块都需要遍历npc列表, 因此用一个timer保存enemy, friend列表，避免重复遍历
def.field("number")._CheckPlayerListTimer = 0
def.field("table")._EnemyPlayerList = BlankTable
def.field("table")._FriendPlayerList = BlankTable
def.field("table")._ActivePlayerList = BlankTable
def.field("table")._OrderPlayerList = BlankTable

def.final("=>", CPlayerMan).new = function ()
	local obj = CPlayerMan()
	obj:Init(CEntityMan.MAN_ENUM.MAN_PLAYER)
	obj._PlayersRoot = GameObject.New("Players")
	return obj
end

def.override("number").Init = function (self, type)
	CEntityMan.Init(self, type)

	if self._CheckPlayerListTimer == 0 then
		self._CheckPlayerListTimer = _G.AddGlobalTimer(auto_detector_time, false, function() 
				self:RefreshPlayerList() 
			end )
	end
end

def.override("number", "number", "=>", CEntity).Remove = function (self, id, leaveType)
    self._EnemyPlayerList[id] = nil
	self._FriendPlayerList[id] = nil
	self._ActivePlayerList[id] = nil
    return CEntityMan.Remove(self, id, leaveType)
end

--刷新npc敌对和友善列表
def.method().RefreshPlayerList = function(self)
	local players = self._ObjMap

	local hp = game._HostPlayer
	local hostX, hostZ = hp:GetPosXZ()

	self._EnemyPlayerList = {}
	self._FriendPlayerList = {}
	self._ActivePlayerList = {}
	self._OrderPlayerList = {}

	for i,v in pairs(players) do
		if not v:IsReleased() and not v:IsDead() and v:CanBeSelected() then
			local relation = v:GetRelationWithHost()
			if relation == "Enemy" then
				self._EnemyPlayerList[i] = v
			elseif relation == "Friendly" then
				self._FriendPlayerList[i] = v
			end

			self._ActivePlayerList[i] = v

			local posX, posZ = v:GetPosXZ()
			v._SqrDistanceHToHost = SqrDistanceH(hostX, hostZ, posX, posZ)
			self._OrderPlayerList[#self._OrderPlayerList + 1] = v
		end
	end
	--warn("enemyCount: ", enemyCount, "friendCount: ", friendCount)
end

def.method("table", "=>", CElsePlayer).CreateElsePlayer = function (self, info)
	local id = info.CreatureInfo.MovableInfo.EntityInfo.EntityId
	if self._ObjMap[id] ~= nil then
		return self._ObjMap[id]
	else
		local player = CElsePlayer.new()
		player:AddLoadedCallback(function(p)
				if p._GameObject ~= nil then
					p._GameObject.parent = self._PlayersRoot
				end		
			end)
		player:Init(info)
		self._ObjMap[id] = player		
		return player
	end
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

def.method("function", "=>", CElsePlayer).GetByFilter = function (self, filter)
	local players = self._ActivePlayerList
	local dis = 9999999
	local hostX, hostZ = game._HostPlayer:GetPosXZ()
	local result = nil

	for _,v in pairs(players) do
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

def.method("boolean", "number", "number", "number", "number", "=>", CElsePlayer).GetByHostAreaCollide = function (self, hateState, areaType, radius, length, angle)
	local dis = 9999999
	local target_radius = 0.5
	local result = nil
	local host = game._HostPlayer
	local hostPosX, hostPosY, hostPosZ = host:GetPosXYZ()
	local hostDirX, hostDirY, hostDirZ = host:GetDirXYZ()

	local shape = nil
	if hateState then
		local players = self._ActivePlayerList
		for _,v in pairs(players) do
			if host:IsEntityHate(v._ID) then
				local posX, posY, posZ = v:GetPosXYZ()
				local curDis = SqrDistanceH(hostPosX, hostPosZ, posX, posZ)
				if curDis < dis then
					if shape == nil then shape = SkillCollision.CreateShapeXYZ(areaType, radius, length, angle, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ) end

					if shape:IsCollidedXYZ(posX, posY, posZ, target_radius) and GameUtil.PathFindingCanNavigateToXYZ(hostPosX, hostPosY, hostPosZ, posX, posY, posZ, _G.NAV_STEP) then
						result = v
						dis = curDis
					end
				end
			end
		end
	else
		local players = self._EnemyPlayerList
		for _,v in pairs(players) do
			if GameUtil.IsValidPosition(v:GetPos()) then
				local posX, posY, posZ = v:GetPosXYZ()
				local curDis = SqrDistanceH(hostPosX, hostPosZ, posX, posZ)
				if curDis < dis then
					if shape == nil then shape = SkillCollision.CreateShapeXYZ(areaType, radius, length, angle, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ) end

					if shape:IsCollidedXYZ(posX, posY, posZ, target_radius) then 
						result = v
						dis = curDis
					end
				end
			end
		end
	end

	return result
end

def.method("number", "=>", CElsePlayer).GetByHostQuickRescue = function (self, quicktalk_distance_sqr)
	local players = self._ObjMap
	local dis = 9999999
	local result = nil
	local host = game._HostPlayer
	local hostPosX, hostPosZ = host:GetPosXZ()

	for _,v in pairs(players) do
		if not v:IsReleased() and v:CanRescue() and v:IsFriendly() then
			local posX, posZ = v:GetPosXZ() 
			local d = SqrDistanceH(hostPosX, hostPosZ, posX, posZ)
			if d <= quicktalk_distance_sqr then 
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

local function SortPlayers(a, b)
	if a ~= nil and b ~= nil then
		return a._SqrDistanceHToHost < b._SqrDistanceHToHost
	end
	return true
end

local random = math.random
local sort = table.sort

-- 玩家隐藏后，他的宠物也应做相应的处理，故将显隐逻辑放在CWorld层
def.override().Update = function (self)
	--do return end
	local maxPlayerCount = game._MaxPlayersInScreen - 1  -- 去除主角计数 1
	local orderPlayersList = self._OrderPlayerList
	local needLimit = (#orderPlayersList >= maxPlayerCount)

	-- 人数不达限制，全部显示
	if not needLimit then
		for i,v in ipairs(orderPlayersList) do
			v:EnableCullingVisible(true)
		end
		return
	end

	--人数超出限制
	sort(orderPlayersList, SortPlayers)

	-- 方案1：显示最近的maxPlayerCount个，简单粗暴
	--[[
	for i,v in ipairs(orderPlayersList) do
		if not v:IsReleased() and not v:IsDead() then
			v:EnableCullingVisible(i <= maxPlayerCount)
		end
	end
	]]

	-- 方案2：分层显示，内层全部显示，外层挑选显示
	local totalCount = #orderPlayersList
	-- 优先显示内圈选手，数量控制在总量的某个比例，全部显示
	local maxVisiblePlayerInner = math.floor(maxPlayerCount * _G.VISIBLE_PLAYER_INNER_RATIO)
	for i,v in ipairs(orderPlayersList) do
		if i > maxVisiblePlayerInner then break end
		if not v:IsReleased() and not v:IsDead() then
			v:EnableCullingVisible(true)
		end
	end

	-- 外圈选手随机选择
	local maxVisiblePlayerOuter = maxPlayerCount - maxVisiblePlayerInner
	local selectedIndex = {}
	-- 搜寻当前已经显示的玩家
	for i = maxVisiblePlayerInner+1, totalCount do
		local p = orderPlayersList[i]
		if not p:IsReleased() and not p:IsDead() then
			if p:IsCullingVisible() then
				selectedIndex[i] = 1
			end
		end
	end

	local curCount = table.count(selectedIndex)
	if curCount < maxVisiblePlayerOuter then
		local count = 0
		while count < maxVisiblePlayerOuter - curCount do
			local index = random(maxVisiblePlayerInner+1, totalCount)
			if selectedIndex[index] == nil then
				selectedIndex[index] = 1
				count = count + 1
			end
		end
	end

	local count = 0
	for i = maxVisiblePlayerInner+1, totalCount do
		local p = orderPlayersList[i]
		if not p:IsReleased() and not p:IsDead() then
			if count >= maxVisiblePlayerOuter then
				p:EnableCullingVisible(false)
			else
				p:EnableCullingVisible(selectedIndex[i] ~= nil)
				if selectedIndex[i] ~= nil then
					count = count + 1
				end
			end
		end
	end

	--warn(maxVisiblePlayerInner .. " VS " .. totalCount-maxVisiblePlayerInner)
	do
		-- TODO: 需要增加特殊角色处理，比如玩家当前目标  added by lijian
	end
end

def.override("boolean").Release = function (self, is_2_release_root)
	if is_2_release_root then
		if self._CheckPlayerListTimer ~= 0 then
			_G.RemoveGlobalTimer(self._CheckPlayerListTimer)
			self._CheckPlayerListTimer = 0
		end
	end

	self._EnemyPlayerList = {}
	self._FriendPlayerList = {}
	self._ActivePlayerList = {}
	self._OrderPlayerList = {}

	CEntityMan.Release(self, is_2_release_root)

	if is_2_release_root then
		Object.Destroy(self._PlayersRoot)
		self._PlayersRoot = nil
	end
end

CPlayerMan.Commit()

return CPlayerMan
