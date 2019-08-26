local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CQuest = require "Quest.CQuest"
local CElementData = require "Data.CElementData"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local EMonsterQuality = require "PB.Template".Monster.EMonsterQuality
local SkillCollision = require "SkillCollision"
local CAutoFightMan = require "AutoFight.CAutoFightMan"

local DistanceH_XZ = Vector3.DistanceH_XZ
local SqrDistanceH_XZ = Vector3.SqrDistanceH_XZ
local WORLD_BOSS_RADIUS = 347
-------------------------------------------------------------------
local CObjectWeightPool = Lplus.Class("CObjectWeightPool")
do 
	local def = CObjectWeightPool.define

	def.field("table")._List = BlankTable
	def.field("table")._Map = BlankTable

	def.method("number", "number").Add = function(self, entity_id, weight)
		--warn("huangxin", "CObjectWeightPool Add", entity_id, " ", weight)
		table.insert(self._List, {entity_id, weight})
		self._Map[entity_id] = weight
	end

	def.method("number").Remove = function(self, entity_id)
		for i=#self._List, 1, -1 do
			if self._List[i][1] == entity_id then
				table.remove(self._List, i)
			end
		end
		self._Map[entity_id] = nil
	end

	def.method().Sort = function(self)
		for j = 1, #self._List - 1 do
			for i = 1, #self._List - j do
				if self._List[i][2] < self._List[i + 1][2] then
					local temp = self._List[i]
					self._List[i] = self._List[i + 1]
					self._List[i + 1] = temp
				end
			end
		end
	end

	def.method().Clear = function(self)
		self._List = {}
		self._Map = {}
	end
end
CObjectWeightPool.Commit()

-------------------------------------------------------------------
local CTargetDetector = Lplus.Class("CTargetDetector")
do
	local def = CTargetDetector.define

	def.field("number")._DetectTimerID = 0
	def.field("number")._RectangularSightLength = 0
	def.field("number")._RectangularSightWidth = 0
	def.field("number")._CircularSightRadius = 0
	def.field("number")._TargetMissDistanceSqr = 0      -- 目标解锁距离

	-- 常量
	local detect_delta_range = 0
	local change_target_view_length = 0
	local change_target_view_width = 0
	local change_target_view_radius = 0
	local npc_quick_service_distance_sqr = 0
	local mine_quick_gather_distance_sqr = 0
	local world_boss_radius_sqr = 0
	
	local instance = nil
	def.static("=>", CTargetDetector).Instance = function ()
		if instance == nil then
			instance = CTargetDetector()
		end

		return instance
	end

	def.method().Start = function(self)
		if self._DetectTimerID ~= 0 then return end

		local host = game._HostPlayer
		self._RectangularSightLength = host._ProfessionTemplate.RectangularSightLength
		self._RectangularSightWidth = host._ProfessionTemplate.RectangularSightWidth * 2
		self._CircularSightRadius = host._ProfessionTemplate.CircularSightRadius

		if detect_delta_range == 0 then
			detect_delta_range = CElementData.GetSpecialIdTemplate(140).Value
		end
		if change_target_view_length == 0 then
			change_target_view_length = CElementData.GetSpecialIdTemplate(137).Value
		end
		if change_target_view_width == 0 then
	 		change_target_view_width = tonumber(CElementData.GetSpecialIdTemplate(138).Value) * 2
		end
		if change_target_view_radius == 0 then
	 		change_target_view_radius = CElementData.GetSpecialIdTemplate(139).Value
		end

		self._DetectTimerID = host:AddTimer(auto_detector_time, false, function()
					self:Detect()
					self:QuickTalkTargetDetect()
				end)
	end

	def.method().Detect = function(self)
		-- 自动战斗中，有自己的目标选择逻辑，关闭此处的目标自动检测
		if CAutoFightMan.Instance():IsOn() then return end

		local host = game._HostPlayer
		
		if host:IsDead() then return end

		-- 更新当前目标（TargetHead显示）
		local cur_target = host:GetCurrentTarget()
		if cur_target ~= nil then		
			-- 锁定单位超出限制距离
			if host._IsTargetLocked and self:IsCurTargetMiss(cur_target) then  
				host:UpdateTargetInfo(nil, false)
				cur_target = nil
			-- 非锁定的目标超出检测范围（世界Boss不在内）
			elseif not host._IsTargetLocked and not self:IsTargetInDetectRange(cur_target) and not self:IsCurTargetWorldBoss(cur_target) then
				host:UpdateTargetInfo(nil, false)
				cur_target = nil
			-- 目标不可达且不在新手副本
			elseif not self:CanNavigateToTarget(cur_target) and not game:IsInBeginnerDungeon() then
				host:UpdateTargetInfo(nil, false)
				cur_target = nil
			-- 弱锁非敌对对象
			elseif cur_target:GetRelationWithHost() ~= "Enemy" and not host._IsTargetLocked then
				host:UpdateTargetInfo(nil, false)
				cur_target = nil
			end
		end
		
		if cur_target == nil then
			-- 新增玩家仇恨锁定机制
			local target = self:TryLockPlayerTarget()
			if target then
				host:UpdateTargetInfo(target, true)
				return
			end

			-- 继承的索敌
			target = self:DetectCurTarget(1)
			if target ~= nil and cur_target ~= target then
				host:UpdateTargetInfo(target, false)
			end
		end
	end

	def.method().DetectOnce = function (self)
		local host = game._HostPlayer
		
		if host:IsDead() then return end

		local cur_target = host:GetCurrentTarget()
		if cur_target ~= nil and not host._IsTargetLocked then
			-- 新增玩家仇恨锁定机制
			local target = self:TryLockPlayerTarget()
			if target then
				host:UpdateTargetInfo(target, true)
				return
			end

			-- 继承的索敌
			target = self:DetectCurTarget(0.5)
			if target ~= nil and cur_target ~= target then
				host:UpdateTargetInfo(target, false)
			end
		end
	end

	def.method(CEntity, "=>", "boolean").IsTargetInDetectRange = function(self, cur_target)
		if cur_target == nil then return false end

		local host = game._HostPlayer
		local hostPosX, hostPosY, hostPosZ = host:GetPosXYZ()
		local hostDirX, hostDirY, hostDirZ = host:GetDirXYZ()
		local targetPosX, targetPosY, targetPosZ = cur_target:GetPosXYZ()

		local target_radius = 0.5 

		-- 先搜索矩形视野区域
		--local rect = SkillCollision.CreateShapeXYZ(0, self._RectangularSightWidth + detect_delta_range, self._RectangularSightLength + detect_delta_range * 2, 0, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ)
		--if rect:IsCollidedXYZ(targetPosX, targetPosY, targetPosZ, target_radius) then return true end

		if SkillCollision.IsShapeCollidedXYZ(0, self._RectangularSightWidth + detect_delta_range, self._RectangularSightLength + detect_delta_range * 2, 0, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ,
			targetPosX, targetPosY, targetPosZ, target_radius) then return true end

		-- 如果矩形视野区域内未找到，搜索圆形区域
		--local circle = SkillCollision.CreateShapeXYZ(2, self._CircularSightRadius + detect_delta_range, 0, 0, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ)
		--if circle:IsCollidedXYZ(targetPosX, targetPosY, targetPosZ, target_radius) then return true end

		if SkillCollision.IsShapeCollidedXYZ(2, self._CircularSightRadius + detect_delta_range, 0, 0, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ,
			targetPosX, targetPosY, targetPosZ, target_radius) then return true end

		return false
	end

	def.method(CEntity, "=>", "boolean").IsCurTargetWorldBoss = function(self, cur_target)
		if cur_target == nil then 
			return false 
		end

		-- 世界boss
		if cur_target:GetObjectType() == OBJ_TYPE.MONSTER  and cur_target:GetMonsterQuality() == EMonsterQuality.BEHEMOTH then
			return not cur_target:IsReleased() and not cur_target:IsDead() and cur_target:CanBeSelected()
		end

		return false
	end

	def.method("number").UpdateTargetMissDistance = function(self, mapTid)
		local map = CElementData.GetMapTemplate(mapTid)
		local d = 0
		if map ~= nil and map.UnlockSightRange ~= 0 then
			d = map.UnlockSightRange
		else
			d = tonumber(CElementData.GetSpecialIdTemplate(1).Value)
		end
		self._TargetMissDistanceSqr = d * d
	end

	def.method(CEntity, "=>", "boolean").IsCurTargetMiss = function(self, cur_target)
		if cur_target == nil then 
			return false 
		end
		local targetPosX, targetPosZ = cur_target:GetPosXZ()
		local max_dis = self._TargetMissDistanceSqr
		-- 世界boss
		if self:IsCurTargetWorldBoss(cur_target) then
			if world_boss_radius_sqr <= 0 then
				local lo_radius = tonumber(CElementData.GetSpecialIdTemplate(WORLD_BOSS_RADIUS).Value)
				world_boss_radius_sqr = lo_radius * lo_radius
			end
			max_dis = world_boss_radius_sqr
		end

		local host = game._HostPlayer
		local hostPosX, hostPosZ = host:GetPosXZ()
		local d = SqrDistanceH_XZ(hostPosX, hostPosZ, targetPosX, targetPosZ)
		return d > max_dis
	end

	def.method(CEntity, "=>", "boolean").CanNavigateToTarget = function(self, cur_target)
		if cur_target == nil then 
			return false 
		end

		if cur_target:GetObjectType() == OBJ_TYPE.MINE then
			return true
		end

		local host = game._HostPlayer
		return GameUtil.PathFindingCanNavigateTo(host:GetPos(), cur_target:GetPos(), _G.NAV_STEP)
	end
	

	local function filterFunc(v)
		local host = game._HostPlayer
		if not host:IsEntityHate(v._ID) or not GameUtil.IsValidPosition(v:GetPos()) then 
			return false 
		end			
		return true
	end

	def.method("=>", CEntity).TryLockPlayerTarget = function(self)
		return game._CurWorld._PlayerMan:GetByFilter(filterFunc)
	end

	def.method("number", "=>", CEntity).DetectCurTarget = function(self, factor)
		local host = game._HostPlayer

		local rectWidth = self._RectangularSightWidth * factor
		local rectHeight = self._RectangularSightLength * factor
		local target = game._CurWorld._NPCMan:GetByHostAreaCollide("Enemy", 0, rectWidth, rectHeight, 0)
		if not target then			
			target = game._CurWorld._PlayerMan:GetByHostAreaCollide(false, 0, rectWidth, rectHeight, 0)
		-- 比较距离
		else 
			local target_player = game._CurWorld._PlayerMan:GetByHostAreaCollide(false, 0, rectWidth, rectHeight, 0)
			if target_player then
				local hostPosX, hostPosZ = host:GetPosXZ()
				local vPosX_p, vPosZ_p = target_player:GetPosXZ()
				local vPosX_m, vPosZ_m = target:GetPosXZ()
				local dis_m = SqrDistanceH_XZ(hostPosX, hostPosZ, vPosX_m, vPosZ_m)
				local dis_p = SqrDistanceH_XZ(hostPosX, hostPosZ, vPosX_p, vPosZ_p)
				if dis_p < dis_m then
					target = target_player
				end
			end
		end
		
		if target == nil then	
			local radius = self._CircularSightRadius * factor
			target = game._CurWorld._NPCMan:GetByHostAreaCollide("Enemy", 2, radius, 0, 0)
			if not target then 
				target = game._CurWorld._PlayerMan:GetByHostAreaCollide(false, 2, radius, 0, 0)
			else
				local target_player = game._CurWorld._PlayerMan:GetByHostAreaCollide(false, 2, radius, 0, 0)
				if target_player then
					local hostPosX, hostPosZ = host:GetPosXZ()
					local vPosX_p, vPosZ_p = target_player:GetPosXZ()
					local vPosX_m, vPosZ_m = target:GetPosXZ()
					local dis_m = SqrDistanceH_XZ(hostPosX, hostPosZ, vPosX_m, vPosZ_m)
					local dis_p = SqrDistanceH_XZ(hostPosX, hostPosZ, vPosX_p, vPosZ_p)
					if dis_p < dis_m then
						target = target_player
					end
				end
			end
		end
		return target
	end

	def.method("=>", CEntity).TryGetAttackableTarget = function(self)
		local host = game._HostPlayer
		local target = self:TryLockPlayerTarget()
		if target then
			host:UpdateTargetInfo(target, true)
		else
			target = self:DetectCurTarget(1)	
			if target then
				host:UpdateTargetInfo(target, false)
			end
		end
		return target
	end

	def.method().QuickTalkTargetDetect = function(self)
		local game = game
		local host = game._HostPlayer
		local world = game._CurWorld

		if npc_quick_service_distance_sqr == 0 then
			npc_quick_service_distance_sqr = CSpecialIdMan.Get("NpcQuickServiceDis") 
			npc_quick_service_distance_sqr = npc_quick_service_distance_sqr * npc_quick_service_distance_sqr
		end
		if mine_quick_gather_distance_sqr == 0 then
			mine_quick_gather_distance_sqr = CSpecialIdMan.Get("MineQuickGatherDis") 
			mine_quick_gather_distance_sqr = mine_quick_gather_distance_sqr * mine_quick_gather_distance_sqr 
		end

		-- 玩家选中一个单位，无视距离直接显示快捷服务
		local cur_target = host._CurTarget
		local hoh = host._OpHdl
		if cur_target ~= nil and not cur_target:IsReleased()  and host._IsTargetLocked then
			if cur_target:GetObjectType() == OBJ_TYPE.NPC and hoh:HaveServiceOptions(cur_target, nil) then
				if cur_target._IsInService then
					EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.DialogEnd, nil)
				else
					EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.DialogStart, cur_target)
				end
				return
			--非任务模式下的对象也显示快捷方式 与原有设计更改
			elseif cur_target:GetObjectType() == OBJ_TYPE.MINE and cur_target:GetCanGather() then
				EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.GatherStart, cur_target)
				return
			elseif cur_target:GetObjectType() == OBJ_TYPE.ELSEPLAYER and cur_target:CanRescue() and cur_target:IsFriendly() and not game._RegionLimit._LimitRescue then
				EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.RescueStart, cur_target)
				return
			end
		end

		local target = world._NPCMan:GetByHostQuickTalk("Friendly", npc_quick_service_distance_sqr)
		local mine = world._MineObjectMan:GetByHostQuickTalk(mine_quick_gather_distance_sqr)
		if target == nil and mine ~= nil then
			target = mine
		elseif mine ~= nil then
			local hostPosX, hostPosZ = host:GetPosXZ()
			local posX1, posZ1 = target:GetPosXZ()
			local d1 = SqrDistanceH_XZ(hostPosX, hostPosZ, posX1, posZ1)
			local posX2, posZ2 = mine:GetPosXZ()
			local d2 = SqrDistanceH_XZ(hostPosX, hostPosZ, posX2, posZ2)
			if d1 > d2 then
				target = mine
			end
		end

		local elseplayer = world._PlayerMan:GetByHostQuickRescue(npc_quick_service_distance_sqr)
		if target == nil and elseplayer ~= nil then
			target = elseplayer
		end

		if target ~= nil and not host:IsDead() then
			if target:GetObjectType() == OBJ_TYPE.NPC then
				if target._IsInService then
					EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.DialogEnd, nil)
				else
					EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.DialogStart, target)
				end
			elseif target:GetObjectType() == OBJ_TYPE.MINE then
				EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.GatherStart, target)
			elseif target:GetObjectType() == OBJ_TYPE.ELSEPLAYER and not game._RegionLimit._LimitRescue then
				EventUntil.RaiseUIShortCutEvent(EnumDef.EShortCutEventType.RescueStart, target)
			end
		else
			local CPanelSkillSlot = require "GUI.CPanelSkillSlot"
			CPanelSkillSlot.Instance():HideBtnTalk()
		end
	end

	def.method().Stop = function(self)
		if self._DetectTimerID == 0 then return end

		local host = game._HostPlayer
		if host ~= nil then
			host:RemoveTimer(self._DetectTimerID)
			self._DetectTimerID = 0
		end

		self._RectangularSightLength = 0
		self._RectangularSightWidth = 0
		self._CircularSightRadius = 0
	end

	--切换目标相关
	--pool结构为CObjectWeightPool(in/out)
	--key为entity_id, value为weight
	--object_type 有两种 role, npc(包括monster)

	def.method(CObjectWeightPool, "string").GetNearbyValidTargetsByType = function(self, pool, object_type)
		local obj_map = nil
		local base_weight = 0
		if object_type == "role" then
			obj_map = game._CurWorld._PlayerMan._EnemyPlayerList
		elseif object_type == "npc" then
			obj_map = game._CurWorld._NPCMan._EnemyNpcList
		end

		local host = game._HostPlayer

		local hostPosX, hostPosY, hostPosZ = host:GetPosXYZ()
		local hostDirX, hostDirY, hostDirZ = host:GetDirXYZ()
		local target_radius = 0.5
		local max_distance_weight = 1000

		--特殊处理新手本的boss
		local bossId = 0
		if game:IsInBeginnerDungeon() then
			for id, entity in pairs(obj_map) do
				if entity:GetObjectType() == OBJ_TYPE.MONSTER  and entity:GetMonsterQuality() == EMonsterQuality.BEHEMOTH and entity:IsVisibleInCamera() then
					bossId = id

					local targetPosX, targetPosZ = entity:GetPosXZ()
					local max_dis = self._TargetMissDistanceSqr
					-- 世界boss
					if self:IsCurTargetWorldBoss(entity) then
						if world_boss_radius_sqr <= 0 then
							local lo_radius = tonumber(CElementData.GetSpecialIdTemplate(WORLD_BOSS_RADIUS).Value)
							world_boss_radius_sqr = lo_radius * lo_radius
						end
						max_dis = world_boss_radius_sqr
					end

					local host = game._HostPlayer
					local hostPosX, hostPosZ = host:GetPosXZ()
					local d = DistanceH_XZ(hostPosX, hostPosZ, targetPosX, targetPosZ)
					if d * d < max_dis then
						local weight = base_weight + max_distance_weight - d
						pool:Add(id, weight)
					end

					break
				end
			end
		end

		--搜索圆形视野区域
		local circle = nil
		base_weight = 0
		for id, entity in pairs(obj_map) do
			--warn("huangxin", entity:IsVisibleInCamera())
			if id ~= bossId and entity:IsVisibleInCamera() then 
				--世界boss特殊处理
				if circle == nil then circle = SkillCollision.CreateShapeXYZ(2, change_target_view_radius, 0, 0, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ) end

				local posX, posY, posZ = entity:GetPosXYZ()
				if circle:IsCollidedXYZ(posX, posY, posZ, target_radius) then
					local distance = DistanceH_XZ(hostPosX, hostPosZ, posX, posZ)
					local weight = base_weight + max_distance_weight - distance
					pool:Add(id, weight)
				end
			end
		end

		--搜索矩形视野区域
		local rect = nil
		base_weight = 1000
		for id, entity in pairs(obj_map) do
			if id ~= bossId and entity:IsVisibleInCamera() then
				if rect == nil then rect = SkillCollision.CreateShapeXYZ(0, change_target_view_width, change_target_view_length, 0, hostPosX, hostPosY, hostPosZ, hostDirX, hostDirY, hostDirZ) end

				local posX, posY, posZ = entity:GetPosXYZ()
				if rect:IsCollidedXYZ(posX, posY, posZ, target_radius) then
					local distance = DistanceH_XZ(hostPosX, hostPosZ, posX, posZ)
					local weight = base_weight + max_distance_weight - distance
					pool:Add(id, weight)
				end
			end
		end
		--warn("huangxin pool size", #pool)
	end


	def.method("=>", CObjectWeightPool).GetNearbyValidTargets = function(self)
		local pool = CObjectWeightPool()
		self:GetNearbyValidTargetsByType(pool, "role")
		self:GetNearbyValidTargetsByType(pool, "npc")
		pool:Sort()
		return pool
	end

	local old_pool = CObjectWeightPool()

	local function GetOne(pool)
		local target_id = pool._List[1][1]
		pool:Remove(target_id)
		pool:Add(target_id, 0)
		return target_id
	end

	def.method().ChangeTarget = function(self)
		local new_pool = self:GetNearbyValidTargets()
		warn("0000000", table.count(new_pool._Map))
		local calc_pool = CObjectWeightPool()
		for _, v in ipairs(old_pool._List) do
			local entity_id = v[1]
			local weight = v[2]
			if new_pool._Map[entity_id] ~= nil then
				if weight ~= 0 then
					calc_pool:Add(entity_id, new_pool._Map[entity_id])
				else
					calc_pool:Add(entity_id, weight)
				end
				new_pool:Remove(entity_id)
			end
		end
		--new_pool中剩余的放到calc_pool中
		for k, v in pairs(new_pool._Map) do
			calc_pool:Add(k,v)
		end
		calc_pool:Sort()
		old_pool = calc_pool
		if #old_pool._List == 0 then return end

		local target_id = GetOne(old_pool)
		--warn("111111111", target_id, table.count(old_pool._Map))
		local host_player = game._HostPlayer
		if host_player._CurTarget ~= nil and target_id == host_player._CurTarget._ID and host_player._IsTargetLocked and #old_pool._List ~= 1 then
			target_id = GetOne(old_pool)
			--warn("2222222", target_id, table.count(old_pool._Map))
		end

		local target = game._CurWorld:FindObject(target_id)
		host_player:UpdateTargetInfo(target, true)
	end

	def.method().Clear = function(self)
		self:Stop()
		old_pool:Clear()
	end

	def.method().Reset = function(self)
		self:Start()
		old_pool:Clear()
	end
end
CTargetDetector.Commit()
return CTargetDetector
