--[[
【主角技能处理流程】
1、cast skill，调用OnSkillStart

2、在OnSkillStart中启动第一个技能段，调用OnPerformStart()

3、在OnPerformStart中处理以下事情：
   (1)根据技能数据，添加各种event。时间帧相关的时间，添加Timer。碰撞触发事件、按键触发事件、正常结束触发事件和异常结束触发事件单独保存。
   (2)根据当前技能段的时间，添加Perform 结束Timer。

4、如果在Perform执行过程中有碰撞或者按键按下，执行第3步中记录的碰撞触发事件、按键触发事件。

5、当前Perform的Timer到期时，调用OnPerformEnd()

6、在OnPerformEnd中，处理3中记录的正常结束触发事件；此时需要关注正常结束触发事件有没有改变当前技能段序列执行顺序；
   如有改动，确定下一个Perform序号。如果未改动，检查当前技能段是否是最后一个技能段；如果是，结束技能，
   调用OnSkillEnd。如果不是，则将下一个Perform作为即将执行的Perform，调用该perform的OnPerformStart;

7、循环3-6。

其他：
	技能中断时，执行OnSkillInterruptted
	主角技能为客户端先行，如果失败，服务器协议通知，在OnSkillFailed中处理
]]


local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local CHostPlayer = Lplus.ForwardDeclare("CHostPlayer")
local CElementSkill = require "Data.CElementSkill"
local CActiveSkillInfo = require "Skill.CActiveSkillInfo"
local CEntity = require "Object.CEntity"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local SkillDef = require "Skill.SkillDef"
local Template = require "PB.Template"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CElementData = require "Data.CElementData"
local EStartPositionType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventResetTargetPosition.EStartPositionType
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local MapBasicConfig = require "Data.MapBasicConfig"
local SkillMoveType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillMove.SkillMoveType
local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR

local CHostSkillHdl = Lplus.Extend(CObjectSkillHdl, "CHostSkillHdl")
local def = CHostSkillHdl.define

def.field(CActiveSkillInfo)._ActiveBlinkSkill1 = nil   -- 瞬发技能1
def.field(CActiveSkillInfo)._ActiveBlinkSkill2 = nil   -- 瞬发技能2
def.field("table")._ComboInfo = BlankTable

def.field("number")._ChargingTimeLen = 0
def.field("number")._ConsumeCombo = 0

def.field("table")._JudgeParams = nil   -- 记录判定参数，供物理消息回调处理使用

def.field("table")._CurSkill = nil
def.field("number")._CurSkillID = 0
def.field("table")._CachedParams = BlankTable

def.field("table")._MoveEventInfo = BlankTable
def.field("number")._ActingBarTimerId = 0 							-- 进度条id
def.field("number")._ActingBarSkillId = 0 							-- 进度条id

-- { [uipos] = skill_id, ...} 
-- skill_id表示当前有效的技能id，出现QTE或者技能切换时，新技能id会替掉常规技能ID
def.field("table")._ValidSkillsInfo = BlankTable

--def.field("table")._ClientCalcVictims = BlankTable

--复活目标ID
def.field("number")._ResurrectTarget = 0

def.field("table")._ModifiedTargetPos = nil
-- 用于调试
def.field("function")._DebugFunction = nil

local CAST_SKILL_RETCODE =
{
	OK = 0,

	IN_COOLING_STATE = 1,
	LACK_OF_STAMINA = 2,
	LACK_OF_ENERGY = 3, 

	WAIT_FOR_RECONFIRM = 4, -- 等待二次确认
	LACK_OF_TARGET = 5,
	TARGET_IS_INVALID = 6,
	BLOCKED = 7,  -- 障碍阻挡
	DISTANCE_NOT_OK = 8,  
	MOVE_THEN_CAST = 9,  
	POSITION_CAN_NOT_REACH = 10,  -- 不可达

	ENERGY_TYPE_WRONG = 10,  -- 技能消耗的能量与角色自身能量类型不一致
	LACK_OF_STATE = 11,      -- 少前置状态
	LACK_OF_SKILL = 12,      -- 少前置技能
	STATE_LIMIT = 13,      -- 状态限制

	UNDEFINED_ERROR = 100,
}

local SKILL_TARGET_MASK =
{
	M1_SELF = 0x01,  -- 自己
	M2_HOSTILE = 0x02,  -- 敌对
	M3_FRIENDLY = 0x04,  -- 友善
}

local SKILL_CAST_STAGE =
{
	S0_NONE = 0,                -- 非技能流程
	S1_PRECONDITION_CHECK = 1,  -- 使用阶段：冷却 消耗检测
	S2_RECONFIRMATION = 2,      -- 检测阶段：二次确认
	S3_CASTING = 3,             -- 释放阶段：perform执行阶段
}

-- 记录当前的蓄力技能信息: [skill_id] = {TimerId = x, BeginTime = y}
def.field("table")._ChargingInfo = BlankTable

def.field("number")._CurSkillCastStage = SKILL_CAST_STAGE.S0_NONE

def.final(CHostPlayer, "=>", CHostSkillHdl).new = function (hostplayer)
	local obj = CHostSkillHdl()
	obj._Host = hostplayer
	return obj
end

-- 当前释放中技能检查
local function ActiveSkillCheck(self, skill, skill_id, is_combo)
	-- 技能序列已满并且不能打断
	local is_common_skill = true 
	-- TODO:
	if is_common_skill then
		local active_info = self._ActiveCommonSkill
		if active_info ~= nil then
			local cur_skill = active_info._Skill
			local cur_priority = cur_skill.Category
			local new_priority = skill.Category
			if cur_priority < new_priority then 
				self._IsInterruptLastSkill = true
				return true
			else
				local function WaitToCastSkill()
					self._Host:CancelCachedAction()
					self:CastSkill(skill_id, false)
				end

				local perform = cur_skill.Performs[active_info._PerformIdx]
				if perform == nil then
					self._ActiveCommonSkill = nil
					return true
				end
				
				if not perform.IsComboPerform  then
					self._IsInterruptLastSkill = perform.CanBeInterrupted
					if not self._IsInterruptLastSkill and not is_combo then
						self._Host:AddCachedAction(WaitToCastSkill)
					end
					return perform.CanBeInterrupted
				else
					-- 技能执行中，缓存此技能操作
					if not is_combo then
						self._Host:AddCachedAction(WaitToCastSkill)
					end
					return false
				end
			end
		end
	else
		if self._ActiveBlinkSkill1 ~= nil and self._ActiveBlinkSkill2 ~= nil then
			warn("Other skills are going on, and can not be interrupted")
			return false
		end
	end

	return true
end

-- QTE技能检查
local function QTEValidCheck(self, skill)
	local skill_id = skill.Id
	if skill.Category == 0 or skill.Category == 5 then --Skill.SkillCategory.SkillCategoryNone 为通用技能，默认直接可以用
		return true
	end

	for k,v in pairs(self._ValidSkillsInfo) do
		if v == skill_id then
			return true
		end
	end

	return false
end

local ComboSkillLearnLv = 14
local function PreStateAndSkillCheck(self, skill_id)
	local skillLearnTemp = self._Host:GetSkillLearnConditionTemp(skill_id)		
	if skillLearnTemp then
		local comboStateId = skillLearnTemp.ComboStateId
		if comboStateId > 0 and not self._Host:HasStateInGroup(comboStateId) then	
			return CAST_SKILL_RETCODE.LACK_OF_STATE
		elseif comboStateId < 0 and self._Host._InfoData._Level >= ComboSkillLearnLv and self._Host:HasStateInGroup(-comboStateId) then	
			--warn("前置状态限制技能释放", skill_id, comboStateId, self._Host:HasStateInGroup(-comboStateId))
			return CAST_SKILL_RETCODE.STATE_LIMIT
		end

		local comboSkillId = skillLearnTemp.ComboSkillId
		if comboSkillId > 0 and not self._Host:HasActivePreSkill(comboSkillId) then			
			return CAST_SKILL_RETCODE.LACK_OF_SKILL
		end
	end
	return CAST_SKILL_RETCODE.OK
end

-- 冷却和消耗检查
local function CDAndCostCheck(self, skill)
	local skill_cd_id = skill.CooldownId
	if self._Host._CDHdl:IsCoolingDown(skill_cd_id) then return CAST_SKILL_RETCODE.IN_COOLING_STATE, 0, 0 end

	local info_data = self._Host._InfoData
	local cost_stamina = 0  -- 耐力不再消耗
	local cost_energy = skill.EnergyValue
	local energy_type, cur_energy, _ = self._Host:GetEnergy()
	
	if skill.EnergyType ~= energy_type and skill.EnergyValue > 0 then 
		return CAST_SKILL_RETCODE.ENERGY_TYPE_WRONG, 0, 0 
	end

	-- 基础消耗检查
	if cur_energy < skill.EnergyValue then
		return CAST_SKILL_RETCODE.LACK_OF_ENERGY, 0, 0 
	else
		if skill.EnergyPercent > 0 then
			cost_energy = skill.EnergyPercent * cur_energy  
		end		
	end

	if cost_energy == 0 then 
		return CAST_SKILL_RETCODE.OK, cost_stamina, cost_energy 
	end

	-- 连击点可能会触发技能段跳转，需要记录
	local SkillEnergyType = require "PB.Template".Skill.SkillEnergyType
	if energy_type == SkillEnergyType.EnergyTypeCombo then
		self._ConsumeCombo = cost_energy
	else
		self._ConsumeCombo = 0
	end
	return CAST_SKILL_RETCODE.OK, cost_stamina, cost_energy
end

-- 二次操作确认检查
local function ReconfirmCheck(self, skill)
	local cast_mode = skill.CastMode

	-- 直接释放/优先目标 不需要二次确认，直接释放
	if cast_mode == Template.Skill.SkillCastMode.ClickButton or cast_mode == Template.Skill.SkillCastMode.PriorityTarget then
		return CAST_SKILL_RETCODE.OK
	elseif cast_mode == Template.Skill.SkillCastMode.ClickButton or cast_mode == Template.Skill.SkillCastMode.DesignatedTarget then
		return CAST_SKILL_RETCODE.OK
	-- 指定方向 摇杆模式下，有目标，朝向目标，没目标，超前放
	elseif cast_mode == Template.Skill.SkillCastMode.DesignatedDirection then
		return CAST_SKILL_RETCODE.OK
	-- 指定区域 摇杆模式下，有目标，朝向目标，没目标，超前方最大位置
	elseif cast_mode == Template.Skill.SkillCastMode.DesignatedPosition then
		return CAST_SKILL_RETCODE.OK  
	else
		return CAST_SKILL_RETCODE.WAIT_FOR_RECONFIRM
	end
end

local function TargetPreconditionCheck(self, target, skill)
	if target == nil or skill == nil then return false end
    local relation = target:GetRelationWithHost()
    return ( 
    			(skill.RelationshipPreconditionFriendRole and relation == "Friendly" and target:IsRole()and not target:IsDead())
	    		or (skill.RelationshipPreconditionFriendNoneRole and relation == "Friendly" and not target:IsRole())
	    		or (skill.RelationshipPreconditionEnemyRole and relation == "Enemy" and target:IsRole() and not target:IsDead())
	    		or (skill.RelationshipPreconditionEnemyNoneRole and relation == "Enemy" and not target:IsRole())
	    		or (skill.RelationshipPreconditionFriendNoneRole and relation == "Neutral" and not target:IsRole() )
	    		or (skill.RelationshipPreconditionFriendNoneDeadRole and relation == "Enemy" and (target:IsRole() and target:IsDead()) )
	    		or (skill.RelationshipPreconditionFriendDeadRole and relation == "Friendly" and (target:IsRole() and target:IsDead()) )
	    	)
end

local function IsTargetEnemyCheck(self, skill)
	return skill.RelationshipPreconditionEnemyRole or skill.RelationshipPreconditionEnemyNoneRole
end

-- 目标检查
local function TargetValidCheck(self, skill, target)
	local cast_mode = skill.CastMode
	if cast_mode == Template.Skill.SkillCastMode.DesignatedTarget then
		--local mask = skill.TargetPreconditionMask 非lua的参数不是mask了

	    --local bit = require "bit"
		if target == nil then
			return CAST_SKILL_RETCODE.LACK_OF_TARGET

			-- TODO: 技能目标是自己
			--if bit.band(mask, SKILL_TARGET_MASK.M1_SELF) ~= 0 then
				--return CAST_SKILL_RETCODE.OK
			--else
				--return CAST_SKILL_RETCODE.LACK_OF_TARGET
			--end
		else
	    	if TargetPreconditionCheck(self, target, skill) then
	    		return CAST_SKILL_RETCODE.OK
	    	else
	    		return CAST_SKILL_RETCODE.TARGET_IS_INVALID
	    	end
		end
	else
		return CAST_SKILL_RETCODE.OK
	end
end

-- 阻挡检查
local function ObstacleCheck(self, skill, target, pos)
	local cast_mode = skill.CastMode

	if cast_mode ~= Template.Skill.SkillCastMode.DesignatedTarget then
		return CAST_SKILL_RETCODE.OK
	end

	local targetPos = nil
	if cast_mode == Template.Skill.SkillCastMode.DesignatedTarget then
		targetPos = target:GetPos()
	else
		targetPos = target and target:GetPos() or pos
	end

	-- 矿可以布置在不可达区域
	if target ~= nil and target:GetObjectType() == OBJ_TYPE.MINE then
		return CAST_SKILL_RETCODE.OK
	end

	if not GameUtil.IsValidPosition(targetPos) then
		return CAST_SKILL_RETCODE.POSITION_CAN_NOT_REACH
	end

	local hostPos = self._Host:GetPos()
	if skill.IgnoreObstacle or not GameUtil.IsBlockedByObstacle(hostPos, targetPos) then
		return CAST_SKILL_RETCODE.OK
	else
		return CAST_SKILL_RETCODE.BLOCKED
	end
end

-- 目标点连通性检测
local function TargetConnectedCheck(self, targetPos)
	local hostPos = self._Host:GetPos()
	local isConnected = GameUtil.PathFindingIsConnected(hostPos, targetPos)
	local connectedPos = nil
	-- 非直线可达  找可能存在的 可直达点 connectedPos 可能为空
	if not isConnected then
		local ret, pos = GameUtil.FindFirstConnectedPoint(hostPos, targetPos) 
		if ret then connectedPos = pos end
	end
	return isConnected, connectedPos
end


-- 距离检查
local recursionCount = 0
local function DistanceCheck(self, skill_id, skill, target, pos, tryAgainFunc)
	local cast_mode = skill.CastMode
	if cast_mode == Template.Skill.SkillCastMode.ClickButton then
		return CAST_SKILL_RETCODE.OK
	elseif cast_mode == Template.Skill.SkillCastMode.PriorityTarget and target == nil then
		return CAST_SKILL_RETCODE.OK	
	end

	if target ~= nil and not TargetPreconditionCheck(self, target, skill) then
		target = nil
	end
	
	do
		recursionCount = recursionCount + 1
		if recursionCount > 10 then 
			warn("!!! Skill cast condition check enters recursion")
			recursionCount = 0 
			return CAST_SKILL_RETCODE.UNDEFINED_ERROR 
		end
	end
	
	local targetPos = nil
	if target ~= nil and cast_mode == Template.Skill.SkillCastMode.DesignatedTarget then
		targetPos = target:GetPos()
	else
		targetPos = (target ~= nil) and target:GetPos() or pos
	end

	if targetPos ~= nil then
		local isConnected = true
		local connectedPos = nil
		if not skill.IgnoreObstacle then -- 不可无视障碍
			isConnected, connectedPos = TargetConnectedCheck(self, targetPos)     -- 直线可达检测
		end

		local hostPos = self._Host:GetPos()
		local distance = Vector3.DistanceH(hostPos, targetPos) - self._Host:GetRadius()
		if target ~= nil then 			
			distance = distance - target:GetRadius() 			
		end

		-- 客户端做移动的冗余，保证服务器能通过距离检测
		local maxDis = (skill.MaxRange > 0) and (skill.MaxRange * 0.8) or 10000
		local minDis = (skill.MinRange > 0) and (skill.MinRange * 1.2) or 0
		if maxDis <= minDis then minDis = maxDis - 0.2 end

		--[[
		-- 距离小于半径之和，先走到外边来，在放技能
		if distance < 0 and target ~= nil then
			local backDir = self._Host:GetPos() - target:GetPos()
			backDir.y = 0
			backDir = backDir:Normalize()
			local backTargetPos = target:GetPos() + backDir * (maxDis/2  + target:GetRadius() + self._Host:GetRadius())
			isConnected, connectedPos = TargetConnectedCheck(self, backTargetPos)
			if not isConnected then
				if connectedPos ~= nil then
					self._Host:NormalMove(connectedPos, self._Host:GetMoveSpeed(), 0, tryAgainFunc, tryAgainFunc)
				else
					return CAST_SKILL_RETCODE.POSITION_CAN_NOT_REACH
				end
			else
				self._Host:NormalMove(backTargetPos, self._Host:GetMoveSpeed(), 0, tryAgainFunc, tryAgainFunc)
			end
			return CAST_SKILL_RETCODE.MOVE_THEN_CAST
		end
		]]

		-- 连通且距离合适
		if distance <= maxDis and (distance >= minDis and minDis > 0.001 or minDis <= 0.001) and isConnected then
			return CAST_SKILL_RETCODE.OK
		else
			-- 技能不能移动，如果是DesignatedTarget/DesignatedPosition，则检测不通过
			if not skill.AutoMove then
				local ignorePos = (cast_mode ~= Template.Skill.SkillCastMode.DesignatedTarget and cast_mode ~= Template.Skill.SkillCastMode.DesignatedPosition)
				return ignorePos and CAST_SKILL_RETCODE.OK or CAST_SKILL_RETCODE.DISTANCE_NOT_OK
			end

			-- 如果目标未空，到目标位置重新尝试
			if target == nil then	
				self._Host:NormalMove(targetPos, self._Host:GetMoveSpeed(), 0, tryAgainFunc, nil)
				return CAST_SKILL_RETCODE.MOVE_THEN_CAST
			end

			if game._IsUsingJoyStick or (not self._Host:CanMove()) then
				return (cast_mode == Template.Skill.SkillCastMode.PriorityTarget) and CAST_SKILL_RETCODE.OK or CAST_SKILL_RETCODE.DISTANCE_NOT_OK
			end

			-- 距离过近
			if distance < minDis and minDis > 0.001 then
				if math.abs(minDis - distance) < 0.001 then 
					return CAST_SKILL_RETCODE.OK 
				end

				-- 找个合适的位置，去尝试
				local backDir = self._Host:GetPos() - target:GetPos()
				backDir.y = 0
				backDir = backDir:Normalize()
				local backTargetPos = target:GetPos() + backDir * (minDis  + target:GetRadius() + self._Host:GetRadius())
				isConnected, connectedPos = TargetConnectedCheck(self, backTargetPos)
				if not isConnected then
					if connectedPos ~= nil then
						self._Host:NormalMove(connectedPos, self._Host:GetMoveSpeed(), 0, tryAgainFunc, nil)
					else
						return CAST_SKILL_RETCODE.POSITION_CAN_NOT_REACH
					end
				else
					self._Host:NormalMove(backTargetPos, self._Host:GetMoveSpeed(), 0, tryAgainFunc, nil)
				end
				return CAST_SKILL_RETCODE.MOVE_THEN_CAST
			else
				if not isConnected then -- 不直线可达 有直线可达的寻路点 寻路过去打    ->  target在nav上
					if connectedPos ~= nil then
						self._Host:NormalMove(connectedPos, self._Host:GetMoveSpeed(), 0, tryAgainFunc, nil)
					else
						return CAST_SKILL_RETCODE.POSITION_CAN_NOT_REACH
					end
				else
					local maxDestDis = maxDis + self._Host:GetRadius() + target:GetRadius()
					local minDestDis = minDis + self._Host:GetRadius() + target:GetRadius()
					--warn("maxDestDis, minDestDis =", maxDestDis, minDestDis)
					self._Host:FollowTarget(target, maxDestDis, minDestDis, tryAgainFunc, tryAgainFunc)
				end
				return CAST_SKILL_RETCODE.MOVE_THEN_CAST
			end
		end
	end

	return CAST_SKILL_RETCODE.DISTANCE_NOT_OK
end

local function ClearCacheInfo(self, delay_2_clear_indicator)
	if delay_2_clear_indicator then
		self._Host:AddTimer(0.2, true, function()
				CFxMan.Instance():DrawSkillCastIndicator(0, nil, nil, 0, 0, 0)
			end)
	else
		CFxMan.Instance():DrawSkillCastIndicator(0, nil, nil, 0, 0, 0)
	end
	self._CurSkillCastStage = SKILL_CAST_STAGE.S0_NONE
	self._CurSkill = nil
	self._CurSkillID = 0
	self._CachedParams = {}
end

local function RaiseNotifyChargeEvent(skill_id, is_to_start, begin_time, max_time)
	local NotifyChargeEvent = require "Events.NotifyChargeEvent"
    local event = NotifyChargeEvent()
    event.SkillId = skill_id
    event.Is2StartCharging = is_to_start
    event.BeginTime = begin_time
    event.MaxChargeTime = max_time
    CGame.EventManager:raiseEvent(nil, event)
end

-- 在Perform开始时进行检测，如果是蓄力段，则开始蓄力
local function StartCharging(self, skill_id, max_time)
	if self._ChargingInfo[skill_id] ~= nil then
		warn("this skill has been charging")
		return
	end

	if max_time <= 0 then
		warn("charge time can not be less or equal with 0")
		return
	end
	
	self._ChargingInfo[skill_id] = {}
	local info = self._ChargingInfo[skill_id]
	info.BeginTime = Time.time
	info.TimerId = self._Host:AddTimer(max_time, true, function()
			-- 蓄力蓄满，发消息通知
			RaiseNotifyChargeEvent(skill_id, false, 0, max_time)
			self._ChargingInfo[skill_id] = nil
		end)

	-- fire event
	RaiseNotifyChargeEvent(skill_id, true, info.BeginTime, max_time)
end

local function StopCharging(self, skill_id)
	local info = self._ChargingInfo[skill_id]
	if info ~= nil then
		local time = 0
		-- 中间中断蓄力
		local timer_id = info.TimerId
		if timer_id ~= nil and timer_id ~= 0 then
			time = Time.time - info.BeginTime
			self._ChargingTimeLen = time
			local events = self._SpecialEventList[TriggerType.Charge]
			if events ~= nil and #events > 0 then
				for i,v in ipairs(events) do
					v:OnEvent()
					if v._IsToBlockPerformSequence then
						break
					end
				end
				self:ClearSpecialTriggerTypeEvents(TriggerType.Charge)
			end
			self._Host:RemoveTimer(timer_id)
		end
		self._ChargingInfo[skill_id] = nil

		RaiseNotifyChargeEvent(skill_id, false, 0, time)
	end
end

local function ClearChargeTimer(self)
	if self._ActingBarTimerId ~= 0 then
		self._Host:RemoveTimer(self._ActingBarTimerId)
		self._ActingBarTimerId = 0
	end
end

-- 开启进度条
def.method("number", "number").ShowLoadingBar = function(self, skill_id, max_time)
	if max_time <= 0 then
		warn("ShowLoadingBar charge time can not be less or equal with 0")
		return
	end
	 
	local function callback()
		-- 进度条充满
		RaiseNotifyChargeEvent(skill_id, false, 0, max_time)
		ClearChargeTimer(self)	
	end	

	ClearChargeTimer(self)

	-- 启动关闭计时器, 人物销毁或者异常时候会有用
	self._ActingBarTimerId = self._Host:AddTimer(max_time, true, callback)
	self._ActingBarSkillId = skill_id
	-- fire event
	RaiseNotifyChargeEvent(skill_id, true, Time.time, max_time)
end

-- 关闭进度条
def.method("number").CloseLoadingBar = function(self, skill_id)
	if self._ActingBarTimerId ~= 0 and self._ActingBarSkillId == skill_id then
		ClearChargeTimer(self)
		RaiseNotifyChargeEvent(skill_id, false, 0, 0)
		self._ActingBarSkillId = 0
	end
end

-- 是否在采集
def.method("=>", "boolean").IsCollectingMineral = function(self)
	if self._ActingBarTimerId == 0 then return false end
	-- TODO: 这里写死两个采集技能不太好
	return (self._ActingBarSkillId > 0 and (self._ActingBarSkillId == 47 or self._ActingBarSkillId == 77))
end

-- 清除技能移动标记
def.override().ClearSkillMoveState = function(self)
	self._IsSkillMoving = false
	self._SkillMovingDest = nil
end

-- 收集主角技能特效
def.method("=>", "table").CollectSkillMapGfxIds = function(self)
	local ret = {}
	local SkillData = self._Host._UserSkillMap
	for _,v in ipairs(SkillData) do
		if v.Skill and v.Skill.Performs then
			for _, per in ipairs(v.Skill.Performs) do
				if per and per.ExecutionUnits then
					for _, unit in ipairs(per.ExecutionUnits) do
						if unit.Event.GenerateActor._is_present_in_parent then
							if unit.Event.GenerateActor.ActorId and unit.Event.GenerateActor.ActorId > 0 then
								table.insert(ret , unit.Event.GenerateActor.ActorId)
							end
						end
					end
				end
			end
		end
	end
	return ret
end

-- 预加载
def.method().HostSkillGfxPreload = function(self)
	local list = self:CollectSkillMapGfxIds()	
	if list then
		for i = 1, #list do
			if type(list[i]) == "number" then
				local actor_template = CElementSkill.GetActor(list[i])
				if actor_template and actor_template.GfxAssetPath and actor_template.GfxAssetPath ~= "" then
					GameUtil.PreloadFxAsset(actor_template.GfxAssetPath)	
				end
			end
		end
	end	
end

def.method("number", "boolean", "=>", "boolean").CastSkill = function(self, skill_id, ignoreIndicator)
	local skill = nil
	if self._Host:IsModelChanged() then
		skill = self._Host:GetEntitySkill(skill_id)
		if not skill then
			skill = CElementSkill.Get(skill_id) 
		end
	else
		skill = self._Host:GetEntitySkill(skill_id)
		if not skill then
			local skill_tmp = CElementSkill.Get(skill_id) 
			if skill_tmp and skill_tmp.UseNoCheck then
				skill = skill_tmp 
			end
		end		
	end

	if skill == nil then
		warn("Can not find skill with id = " .. skill_id, debug.traceback())
		return false
	end

	do
		local CAutoFightMan = require "AutoFight.CAutoFightMan"
		if not CAutoFightMan.Instance():IsOn() and skill.Category ~= Template.Skill.SkillCategory.Leisure then
			--停止自动跟随
			self._Host:StopAutoFollow()
		end
	end
	
	-- 处于传送过程中
	--if self._Host:GetTransPortalState() then
	--	return false
	--end
		
	if not QTEValidCheck(self, skill) and not skill.UseNoCheck then
		warn("Failed to QTEValidCheck", QTEValidCheck(self, skill), skill.UseNoCheck)
		return false
	end
		
	-- 蓄力技能，如果蓄力中，结束蓄力
	local is_charge_skill = CElementSkill.IsChargeSkill(skill)
	if is_charge_skill and self._ChargingInfo[skill_id] ~= nil then
		StopCharging(self, skill_id)
		return false
	end

	if not self._Host:CanCastSkill(skill_id) then
		if self._Host:GetCurStateType() == FSM_STATE_TYPE.BE_CONTROLLED then
			local function Action()	
				self:CastSkill(skill_id, false)
			end
			self._Host:AddCachedAction(Action)
		end
		game._GUIMan:ShowTipText(StringTable.Get(109), false)
		return false
	end

	-- 通用技能不被自己打断
	if self._ActiveCommonSkill and self._ActiveCommonSkill._SkillID == skill_id 
		and skill.Category == Template.Skill.SkillCategory.SkillCategoryNone then
		return false
	end


	-- 休闲技能不被自己打断
	if self._ActiveCommonSkill and self._ActiveCommonSkill._SkillID == skill_id 
		and skill.Category == Template.Skill.SkillCategory.Leisure then
		return false
	end

	local is_combo = self:UpdateComboInfos(skill_id)

	if not ActiveSkillCheck(self, skill, skill_id, is_combo) then
		ClearCacheInfo(self, false)
		return false
	end

	self._CurSkillCastStage = SKILL_CAST_STAGE.S1_PRECONDITION_CHECK
	-- 冷却&消耗检测
	local ret, cost_stamina, cost_energy = CDAndCostCheck(self, skill)
	if ret ~= CAST_SKILL_RETCODE.OK then
		if ret == CAST_SKILL_RETCODE.IN_COOLING_STATE then
			game._GUIMan:ShowTipText(StringTable.Get(101), false)
		elseif ret == CAST_SKILL_RETCODE.LACK_OF_STAMINA then
			game._GUIMan:ShowTipText(StringTable.Get(102), false)
		elseif ret == CAST_SKILL_RETCODE.LACK_OF_ENERGY then
			game._GUIMan:ShowTipText(StringTable.Get(110), false)
		else
			game._GUIMan:ShowTipText(StringTable.Get(100), false)
		end
		ClearCacheInfo(self, false)
		return false
	end

	-- 前置状态和技能检查
	local retCode = PreStateAndSkillCheck(self, skill_id)
	if retCode ~= CAST_SKILL_RETCODE.OK then
		if retCode == CAST_SKILL_RETCODE.LACK_OF_STATE then
			game._GUIMan:ShowTipText(StringTable.Get(115), false)
		elseif retCode == CAST_SKILL_RETCODE.LACK_OF_SKILL then
			game._GUIMan:ShowTipText(StringTable.Get(116), false)
		elseif retCode == CAST_SKILL_RETCODE.STATE_LIMIT then
			game._GUIMan:ShowTipText(StringTable.Get(173), false)
		end
		
		return false
	end

	self._CurSkillCastStage = SKILL_CAST_STAGE.S2_RECONFIRMATION

	-- 缓存技能信息，等待二次确认
	self._CachedParams[1] = cost_stamina
	self._CachedParams[2] = cost_energy
	self._CurSkill = skill
	self._CurSkillID = skill_id

	-- 绘制指示器
	if not ignoreIndicator then
		local indictor_type = skill.IndicatorRangeType
		local arg1, arg2, arg3 = skill.IndicatorRangeParam1, skill.IndicatorRangeParam2, skill.IndicatorRangeParam3
		if indictor_type == 3 then
			arg1 = skill.MaxRange
		end
		local pos = self._Host:GetPos()
		local dir = self._Host:GetDir()
		CFxMan.Instance():DrawSkillCastIndicator(indictor_type, pos, dir, arg1, arg2, arg3)
	end

	ret = ReconfirmCheck(self, skill)
	if ret == CAST_SKILL_RETCODE.WAIT_FOR_RECONFIRM then
		return true
	elseif ret == CAST_SKILL_RETCODE.OK then
		local target = self._Host._CurTarget
		self:CastSkill_2(target, false)
		return true
	end
end

local function GetJoyStickDir()
	local CPanelRocker = require "GUI.CPanelRocker"
	local x, z = CPanelRocker.Instance():GetCurAxis()			
	return Vector3.New(x, 0, z)
end

local function CalcAttackDirAndPos(self, cast_mode)
	-- 直接释放，摇杆使用中摇杆方向，否则角色当前方向
	if game._IsUsingJoyStick and (cast_mode == Template.Skill.SkillCastMode.ClickButton or cast_mode == Template.Skill.SkillCastMode.DesignatedDirection) then
		return GetJoyStickDir()
	end

	return self._Host:GetDir()
end

local function NotifyCurSkillEnd(self_id, skill_id, is_normal_stop)
	local C2SSkillEnd = require "PB.net".C2SSkillEnd
	local msg = C2SSkillEnd()
	msg.EntityId = self_id
	msg.SkillId = skill_id
	local SKILL_END_TYPE = require "PB.net".SKILL_END_TYPE
	if is_normal_stop then
		msg.SkillEndType = SKILL_END_TYPE.SKILL_END_TYPE_NORMAL
	else
		msg.SkillEndType = SKILL_END_TYPE.SKILL_END_TYPE_INTERRUPT
	end

	local PBHelper = require "Network.PBHelper"
	PBHelper.Send(msg)

	--warn("C2SSkillEnd", skill_id, debug.traceback())
end

def.method(CEntity, "boolean").CastSkill_2 = function(self, target, ignoreIndicator)	
	local skill = self._CurSkill
	recursionCount = 0
	if self._Host:IsDead() or skill == nil then
		ClearCacheInfo(self, false)
		return
	end
	-- 目标前提检测
	local ret = TargetValidCheck(self, skill, target)
	if ret ~= CAST_SKILL_RETCODE.OK then
		if ret == CAST_SKILL_RETCODE.LACK_OF_TARGET then
			game._GUIMan:ShowTipText(StringTable.Get(105), false)
		elseif ret == CAST_SKILL_RETCODE.TARGET_IS_INVALID then
			game._GUIMan:ShowTipText(StringTable.Get(104), false)
		end
		ClearCacheInfo(self, false)
		return
	end

	-- 范导的测试需求
	if not TargetPreconditionCheck(self, target, skill) and IsTargetEnemyCheck(self, skill) then		
		local CTargetDetector = require "ObjHdl.CTargetDetector"
		local newTarget = CTargetDetector.Instance():TryGetAttackableTarget()
		if newTarget then
			target = newTarget
		end	
	end

	local pos = self._Host:GetPos()
	local cast_mode = skill.CastMode
	if cast_mode == Template.Skill.SkillCastMode.DesignatedDirection then
		pos = pos + self._Host:GetDir()
	elseif cast_mode == Template.Skill.SkillCastMode.DesignatedPosition then
		local dis = skill.MaxRange * 0.8
		local dir = self._Host:GetDir()
		dir.y = 0
		dir = dir:Normalize()
		pos = pos + dir * dis

		local isConnected, posConnect = GameUtil.PathFindingIsConnectedWithPoint(self._Host:GetPos(), pos)
		if not isConnected then pos = posConnect end		
	end

	-- 如果是指定位置的技能，画出范围指示器
	if not ignoreIndicator and skill.CastMode == Template.Skill.SkillCastMode.DesignatedPosition and skill.IndicatorRangeType == 3 then
		local position = (target ~= nil) and target:GetPos() or pos
		CFxMan.Instance():DrawSkillRangeIndicator(position, skill.IndicatorRangeParam1)
	end

	local skill_id = self._CurSkillID
	-- 距离检测
	local ret = DistanceCheck(self, skill_id, skill, target, pos, function()
						if self:CastSkill(skill_id, true) then
							self:CastSkill_2(target, true)
						else
							self._Host:Stand()
						end
					end)
	if ret ~= CAST_SKILL_RETCODE.OK then
		if ret == CAST_SKILL_RETCODE.DISTANCE_NOT_OK or ret == CAST_SKILL_RETCODE.POSITION_CAN_NOT_REACH then
			game._GUIMan:ShowTipText(StringTable.Get(107), false)
		end
		if ret ~= CAST_SKILL_RETCODE.MOVE_THEN_CAST then
			ClearCacheInfo(self, false)
		end
		return
	end

	self._CurSkillCastStage = SKILL_CAST_STAGE.S3_CASTING

	local canMoveWithSkill = CElementSkill.CanMoveWithSkill(skill_id, 1)
	local isFsmMoving, destPos = self._Host:GetNormalMovingInfo()
	if not canMoveWithSkill then
		if isFsmMoving then
			self._Host:StopMovementLogic()
			self._Host:StopAutoTrans()
		end

		if self._IsSkillMoving then
			self._IsSkillMoving = false	
			self._SkillMovingDest = nil
			
			GameUtil.RemoveBehavior(self._Host:GetGameObject(), BEHAVIOR.MOVE)
		end
	elseif isFsmMoving then
		self:SkillMove(destPos, nil, nil)
	end

	-- 目标信息
	if TargetPreconditionCheck(self, target, skill) then
		self._AttackTarget = target
	else
		self._AttackTarget = nil	
	end

	self._AttackDir = CalcAttackDirAndPos(self, skill.CastMode)
	-- 角色方向调整
	if self._AttackDir ~= self._Host:GetDir() then
		self._Host:SetDir(self._AttackDir)
	end

	do
		if self._IsInterruptLastSkill then
			local last_skill_id = self._ActiveCommonSkill._SkillID
			NotifyCurSkillEnd(self._Host._ID, last_skill_id, false)
			self:OnSkillInterruptted(false)
			self._Host:StopMovementLogic()
		end
		self:OnSkillStart(skill_id, skill)
	end

	self:ClearComboInfos()
	ClearCacheInfo(self, true)
end

-- 此处不是真正的停止技能，只是清空缓存信息
-- 如果技能处于向目标移动中，此处不会停止移动
def.method().CancelSkill = function(self)
	ClearCacheInfo(self, false)
end

def.method("=>", "number").GetRollSkillID = function(self)
	if self._Host._UserSkillMap == nil then		
		--warn("failed to get roll skill id", debug.traceback())
		return 0
	else
		for i,v in ipairs(self._Host._UserSkillMap) do
			if v.Skill.Category == Template.Skill.SkillCategory.Dodge then
				return v.SkillId
			end 
		end
		--warn("failed to get roll skill id", debug.traceback())
		return 0
	end 
end

def.override("boolean").StopCurActiveSkill = function(self, change2stand)
	if self._ActiveCommonSkill ~= nil then		
		local last_skill_id = self._ActiveCommonSkill._SkillID
		self:OnSkillInterruptted(change2stand)
		self:OnSkillEnd(last_skill_id, false, false)
		self:EnableAutoSystemPause(false)
	end
end

def.method("table").Roll = function(self, pos)
	local roll_skill_id = self:GetRollSkillID()
	if roll_skill_id ~= nil and roll_skill_id ~= 0 then
		self._Host:CancelCachedAction()
		self._IsSkillMoving = false
		self._SkillMovingDest = nil
		if pos ~= nil then
			local dir = pos - self._Host:GetPos()
			self._Host:SetDir(dir)
		end
		self:CastSkill(roll_skill_id, false)
	end
end

def.method("number", CEntity, "=>", "boolean").CanCastSkillNow = function(self, skill_id, target)
	local skill = nil

	if self._Host:IsModelChanged() then
		skill = self._Host:GetEntitySkill(skill_id)
		if not skill then
			skill = CElementSkill.Get(skill_id) 
		end
	else
		skill = self._Host:GetEntitySkill(skill_id)
	end

	if skill == nil then return false end

	-- 普攻可以连普攻
	if self._ActiveCommonSkill ~= nil then
		if self._ActiveCommonSkill._Skill.Category == Template.Skill.SkillCategory.NormalAttack and self._ActiveCommonSkill._Skill.Id == skill_id then
			return true
		end
	end

	-- 仅做最小距离检测（最大距离不满足，可以移动过去后再释放）
	if target ~= nil then
		local hostPos = self._Host:GetPos()
		local distance = Vector3.DistanceH(hostPos, target:GetPos())
		distance = distance - self._Host:GetRadius() - target:GetRadius() 		
		if skill.MinRange > 0 and distance < skill.MinRange then
			return false
		end
	end

	if not QTEValidCheck(self, skill) then 
		return false 
	end

	if not self._Host:CanCastSkill(skill_id) then
		return false
	end

	local retCode = PreStateAndSkillCheck(self, skill_id)
	if retCode ~= CAST_SKILL_RETCODE.OK then
		return false
	end
	
	local ret, _, _ = CDAndCostCheck(self, skill)
	if ret ~= CAST_SKILL_RETCODE.OK then
		return false
	end

	-- 其他技能可以中断普攻
	if self._ActiveCommonSkill ~= nil then
		local active_info = self._ActiveCommonSkill
		local cur_skill = active_info._Skill
		local cur_priority = cur_skill.Category
		local new_priority = skill.Category
		if cur_priority < new_priority then 
			return true
		else
			local perform = cur_skill.Performs[active_info._PerformIdx]
			if not perform.IsComboPerform and perform.CanBeInterrupted then
				return true
			end
		end

		return false
	end

	return true
end

def.override("table", "=>", "boolean").DoesClientCare = function(self,event)
	return true
end

def.override("table", "number", "number").RegisterSingleEvent = function(self, execution_unit, skill_id, target_id)
	if execution_unit == nil then return end
	CObjectSkillHdl.RegisterSingleEvent(self, execution_unit, skill_id, target_id)
	
	local cur_trigger_type = 0
	if execution_unit.Trigger.Operation._is_present_in_parent then
		cur_trigger_type = TriggerType.Operation
	elseif execution_unit.Trigger.Charge._is_present_in_parent then
		cur_trigger_type = TriggerType.Charge
	end

	if cur_trigger_type ~= 0 then
		local EventFactory = require "Skill.SkillEvent.CSkillEventFactory"
		if self._SpecialEventList[cur_trigger_type] == nil then self._SpecialEventList[cur_trigger_type] = {} end
		local e = EventFactory.CreateEvent(self._Host, execution_unit.Event, skill_id, target_id)
		self._SpecialEventList[cur_trigger_type][#self._SpecialEventList[cur_trigger_type] + 1] = e
	end
end

def.method("number", "table").OnSkillStart = function(self, skill_id, skill)
	local is_common_skill = true    -- TODO(lijian)：这里需要判断技能是普通技能还是瞬发技能
	local cur_skill_info = nil
	if is_common_skill then
		if self._ActiveCommonSkill == nil then self._ActiveCommonSkill = CActiveSkillInfo.new() end
		cur_skill_info = self._ActiveCommonSkill
	else
		--cur_skill_info = self._ActiveBlinkSkill1 or self._ActiveBlinkSkill2
	end

	if cur_skill_info == nil then
		warn("failed to start skill")
		return
	end

	cur_skill_info._SkillID = skill_id
	cur_skill_info._IsGoingOn = true
	cur_skill_info._StartTime = Time.time
	cur_skill_info._Skill = skill
	cur_skill_info._PerformIdx = 1

	if self._SkillStartCallbacks ~= nil and #self._SkillStartCallbacks > 0 then
		for i,v in ipairs(self._SkillStartCallbacks) do
			v()
		end
		self._SkillStartCallbacks = nil
	end

	local interruptByCombat = cur_skill_info._Skill.InterruptByCombat
	if not interruptByCombat then
		self:EnableAutoSystemPause(true)
	end
	self:OnPerformStart(skill_id, 1, nil)
	GameUtil.SetGameCamCtrlParams(true, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)
end

local function CalcAttackDirPosWhenPerformStart(self, skill)
	local target = self._AttackTarget

	-- 这里做个self._AttackTarget的更新
	if target and self._Host._CurTarget then
		local relation, _ = self._Host:GetRelationWith(self._Host._CurTarget)		
		if relation == "Enemy"  then
			self._AttackTarget = self._Host._CurTarget
			target = self._AttackTarget
		end
	end

	local dir = self._Host:GetDir()
	local pos = nil

	if target == nil then
		if game._IsUsingJoyStick then		
			dir = GetJoyStickDir()
		end
	else
		local cast_mode = skill.CastMode
		if cast_mode == Template.Skill.SkillCastMode.DesignatedPosition 
		or cast_mode == Template.Skill.SkillCastMode.DesignatedTarget
		or cast_mode == Template.Skill.SkillCastMode.PriorityTarget then
			dir = target:GetPos() - self._Host:GetPos()
			dir.y = 0
			pos = target:GetPos()
		end
	end

	if pos == nil then
		pos = self._Host:GetPos() + dir
	end

	return dir, pos
end

def.method("number", "number", "function").OnPerformStart = function(self, skill_id, perform_idx, end_callback)
	if self._Host:IsDead() then
		return 
	end
	--warn("OnPerformStart", skill_id, perform_idx, Time.time)
	local cur_skill_info = self._ActiveCommonSkill
	if cur_skill_info == nil then warn("skill logic error") return end
	local skill = cur_skill_info._Skill
	local perform = cur_skill_info._Skill.Performs[perform_idx]

	if perform == nil then return end
	
	if (self._Host:HasCachedAction() or self._IsSkillMoving) and perform.CanBeInterrupted then
		self:OnSkillInterruptted(not self._IsSkillMoving)		
		self:OnSkillEnd(skill_id, false, false)
		return
	end

	if perform_idx ~= 1 then  -- 第一个技能段在技能cast开始就做了判断
		local is_normal_moving, dest = self._Host:GetNormalMovingInfo()
		if is_normal_moving then
			if not CElementSkill.CanMoveWithSkill(skill_id, perform_idx) then
				self._Host:StopMovementLogic()
				self._Host:SetAutoPathFlag(false)
			else
				self:SkillMove(dest, nil, nil)
			end
		end

		if not CElementSkill.CanMoveWithSkill(skill_id, perform_idx) and GameUtil.HasBehavior(self._Host:GetGameObject(), BEHAVIOR.JOYSTICK) then
			GameUtil.RemoveBehavior(self._Host:GetGameObject(), BEHAVIOR.JOYSTICK)
		end
	end

	if perform.AutoTurn then
		local dir, pos = CalcAttackDirPosWhenPerformStart(self, skill)
		if dir ~= nil then self._AttackDir = dir end
		if pos ~= nil then self._AttackPoint = pos end

		-- 角色方向调整
		if self._AttackDir ~= self._Host:GetDir() then
			self._Host:SetDir(self._AttackDir)

			-- 相机转角度
			if self._AttackDir and GameUtil.GetGameCamCtrlMode() == EnumDef.CameraCtrlMode.FOLLOW then
				if self._AttackTarget then
					if game._IsOpenCamSkillRecover then
						-- 开启了技能回正的设置
						local cam_host = self._Host:GetPos() - game._MainCamera.position
						cam_host.y = 0
						local host_target = self._AttackTarget:GetPos() - self._Host:GetPos()
						host_target.y = 0
						local angle = math.acos(Vector3.Dot(cam_host:Normalize(), host_target:Normalize())) *( 180 / 3.14)
						if angle > 30 then
							local targetX, targetZ = self._AttackTarget:GetPosXZ()
							GameUtil.QuickRecoverCamToDest( targetX, targetZ )
						end
					end

					-- 释放自动转向技能，需要更新跟随相机锁定状态
					game:UpdateCameraLockState(self._AttackTarget._ID, true)
				end
			end
		end
	end

	-- 蓄力段
	local perform_duration = perform.Duration/1000
	if perform.IsChargePerform then
		StartCharging(self, skill_id, perform_duration)
	-- 开启进度条
	elseif CElementSkill.IsShowLoadingBar(skill_id, perform_idx) then
		self:ShowLoadingBar(skill_id, perform_duration)		
	end

	-- 技能功能为None时，表示通用技能，需要特殊处理
	-- 只在技能开始的时候更新技能导致的客户端战斗状态
	if perform_idx == 1 then
		-- 释放技能必须下马
		if self._Host:IsServerMounting() then
        	SendHorseSetProtocol(-1, false)
		end

		if skill.Category == Template.Skill.SkillCategory.SkillCategoryNone or skill.Category == Template.Skill.SkillCategory.Leisure then
			self._Host:ChangeWeaponHangpoint(true)
			self:SendInteractiveSkillMsg()
		else				
			self._Host:UpdateCombatState(true, true, 0, true, false)				
		end
	end

	local skill_move_event, skill_redest_event, move_start_time = self:AddEvents(skill_id, perform_idx)
	
	if not perform.AutoTurn then
		-- 枪骑士冲锋，可通过摇杆控制朝向；如果是类似技能，在自动战斗中，技能段开始时，自动调整一下方向
		if self._AttackTarget ~= nil and skill_move_event ~= nil and skill_move_event.CanChangeDirection then
			local CAutoFightMan = require "AutoFight.CAutoFightMan"
			if CAutoFightMan.Instance():IsOn() then
				local dir = self._AttackTarget:GetPos() - self._Host:GetPos()
				dir.y = 0
				self._AttackDir = dir
				self._Host:SetDir(dir)
			end
		end 

		if self._AttackDir == nil then
			self._AttackDir = self._Host:GetDir()
		end
	end

	local ani_name = perform.DefaultAnimationName	
	if ani_name ~= "" then
		if perform.MoveCastType == Template.Skill.Perform.PerformMoveCastType.HalfBody then
			self:ChangeToSkillState(ani_name, true)
		else
			self:ChangeToSkillState(ani_name, false)
		end
	end	

	if self._ActiveCommonSkill._PerformTimerID ~= 0 then
		self._Host:RemoveTimer(self._ActiveCommonSkill._PerformTimerID)
	end

	self._ActiveCommonSkill._PerformTimerID = self._Host:AddTimer(perform_duration, true, function()
			if end_callback == nil then
				if self._ActiveCommonSkill ~= nil then
					self._ActiveCommonSkill._PerformTimerID = 0					
					self:OnPerformEnd(self._ActiveCommonSkill._Skill.Id, false)
				end
			else
				end_callback()
			end
		end)
	self:SendPerformExecuteCmd(cur_skill_info._SkillID, perform.Id, skill_move_event, move_start_time, skill_redest_event)
end

def.override("number", "number", "boolean", "number", "table", "table", "table").OnEntityPerformSkill = function(self, skillid, performid, isDeathSkill, targetid, destpos, dir, moveinfo)
	local cur_skill_info = self._ActiveCommonSkill
	if cur_skill_info == nil then return end
	local performidx = self:GetPerformIdxById(skillid, performid)
	local CPanelSkillSlot = require "GUI.CPanelSkillSlot"
	if performidx == 1 then
		CPanelSkillSlot.Instance():OnSkillPerformed(skillid)
		local perform = cur_skill_info._Skill.Performs[performidx]
		if perform ~= nil and not perform.IsChargePerform then
			CPanelSkillSlot.Instance():TriggerComboSkill(0, skillid, true)
		end
	end
	self._IsCastingDeathSkill = isDeathSkill
end

def.method("number", "boolean").OnPerformEnd = function(self, skill_id, force_stop_skill)	
	local cur_skill_info = self._ActiveCommonSkill
	if cur_skill_info ~= nil then
		local skill = cur_skill_info._Skill
		local cur_perform_idx = cur_skill_info._PerformIdx

		-- 停止半身动作
		local perform = cur_skill_info._Skill.Performs[cur_perform_idx]
		if perform ~= nil and perform.MoveCastType == Template.Skill.Perform.PerformMoveCastType.HalfBody then
			self._Host:StopPartialAnimation(perform.DefaultAnimationName)
		end

		-- 判断是否存在由正常结束触发的跳段事件
		local go_to_next_perform = self:TriggerEvents(TriggerType.NormalStop)
		if go_to_next_perform then
			self:ClearSpecialTriggerTypeEvents(TriggerType.All)
			if cur_perform_idx + 1 <= #skill.Performs and not force_stop_skill then					
				self:OnPerformJump(skill_id, cur_perform_idx + 1, false)
			else							
				self:OnSkillEnd(skill_id, true, true)
			end
		end
		--warn("OnPerformEnd", skill_id, cur_perform_idx, Time.time)
	else
		warn("Call OnSkillEnd when OnPerformEnd because of data error")
		self:OnSkillEnd(skill_id, false, true)
	end
end

def.method("number", "number", "boolean").OnPerformJump = function(self, skill_id, perform_idx, cancel_cur_perform_event)	
	--warn("PerformJump", perform_idx, debug.traceback())
	-- 提前处理 不然会被 jump中的start冲掉
	self:StopActiveEvents(EnumDef.EntitySkillStopType.PerformEnd)
	self:StopGfxPlay(EnumDef.EntityGfxClearType.PerformEnd)
	self:CloseLoadingBar(skill_id)

	if cancel_cur_perform_event then
		self:ClearEventTimerList()
	end

	if self._ActiveCommonSkill == nil then
		warn("logic error: self._ActiveCommonSkill can not be nil", skill_id, perform_idx, debug.traceback())
	else
		self._ActiveCommonSkill._PerformIdx = perform_idx
		self:OnPerformStart(skill_id, perform_idx, nil)
	end
end

def.method("number", "boolean", "boolean").OnSkillEnd = function(self, skill_id, is_normal_stop, fsmChanged)
	local skill_category = -1
	local interruptByCombat = true
	if self._ActiveCommonSkill and self._ActiveCommonSkill._Skill.Id == skill_id then
		skill_category = self._ActiveCommonSkill._Skill.Category
		interruptByCombat = self._ActiveCommonSkill._Skill.InterruptByCombat
	end
	
	self._ActiveCommonSkill = nil
	
	self:ClearSpecialTriggerTypeEvents(TriggerType.All)
	self:ClearEventTimerList()
	self._IsInterruptLastSkill = false

	self._AttackPoint = nil
	self._AttackDir = nil
	self._ModifiedTargetPos = nil

	NotifyCurSkillEnd(self._Host._ID, skill_id, is_normal_stop)

	if self._IsSkillMoving and self._SkillMovingDest and GameUtil.IsValidPosition(self._SkillMovingDest) then  -- 如果当前还在移动中，切换至正常移动
		self._Host:NormalMove(self._SkillMovingDest, self._Host:GetMoveSpeed(), 0, nil, nil)
	else  --  否则，切换到站立状态
		if fsmChanged then
			if skill_category == Template.Skill.SkillCategory.Leisure then
				self._Host:ContinueIdleSkill()
			else
				self._Host:Stand()
			end
		end
	end

	self._IsSkillMoving = false
	self._SkillMovingDest = nil
	self._IsCastingDeathSkill = false

	if skill_category == Template.Skill.SkillCategory.SkillCategoryNone or skill_category == Template.Skill.SkillCategory.Leisure then
		self._Host:ChangeWeaponHangpoint(not self._Host:IsInServerCombatState())
	else
		-- 技能正常结束，延迟五秒
		self._Host:UpdateCombatState(false, true, 0, false, true)
	end

	self._AttackTarget = nil
	self:OnSkillEndCallback(true)

	-- 停止效果	
	self:CloseLoadingBar(skill_id)
	self:StopActiveEvents(EnumDef.EntitySkillStopType.SkillEnd)
	self:StopGfxPlay(EnumDef.EntityGfxClearType.SkillEnd)

	GameUtil.SetGameCamCtrlParams(false, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)

	-- 清理整体判定的列表
	self._ClientCalcVictims = nil


	-- 缓冲操作，必须放在EnableAutoSystemPause之前
	self._Host:DoCachedAction()

	-- 恢复自动战斗
	if not interruptByCombat then
		self:EnableAutoSystemPause(false)
	end	

	if self._DebugFunction ~= nil then
		self._DebugFunction()
		self._DebugFunction = nil
	end
end

-- 强行停止perform(失败), 目前没考虑失败时CB ,后续做下perform的数据封装
def.method("number").OnForcePerformEnd = function(self, skill_id)
	if self._ActiveCommonSkill and skill_id == self._ActiveCommonSkill._Skill.Id then
		if self._ActiveCommonSkill._PerformTimerID ~= 0 then
			self._Host:RemoveTimer(self._ActiveCommonSkill._PerformTimerID)
		end
		self._ActiveCommonSkill._PerformTimerID = 0					
		self:OnPerformEnd(skill_id, true)
	end
end

def.method("number", "number", "table", "number", "table").SendPerformExecuteCmd = function(self, skill_id, perform_id, skill_move_event, move_start_time, skill_redest_event)	
	local msg = CreateEmptyProtocol("C2SSkillPerformStart")
	msg.EntityId = self._Host._ID
	msg.SkillId = skill_id
	msg.PerformIdx = perform_id

	if self._AttackTarget ~= nil then 
		msg.TargetId = self._AttackTarget._ID 
	end

	if self._AttackPoint ~= nil then 
		local targetpos = self._AttackPoint 
		msg.DestPosition.x = targetpos.x
		msg.DestPosition.y = 0
		msg.DestPosition.z = targetpos.z
	end

	do
		local dir = self._AttackDir
		msg.Direction.x = dir.x
		msg.Direction.y = dir.y
		msg.Direction.z = dir.z
	end
	
	self._ModifiedTargetPos = self:CalcEventModifiedTargetPos(skill_redest_event)

	-- collect charge info
	if skill_move_event ~= nil then
		local destPos = self:CalcChargeDstPos(skill_move_event)
		msg.MoveInfo.BeginTime = move_start_time
		msg.MoveInfo.MoveSpeed = skill_move_event.Speed
		msg.MoveInfo.Duration = skill_move_event.Duration		
		msg.MoveInfo.DestPosition.x = destPos.x
		msg.MoveInfo.DestPosition.y = 0
		msg.MoveInfo.DestPosition.z = destPos.z	

		self._MoveEventInfo = {}
		self._MoveEventInfo.MoveSpeed = skill_move_event.Speed
		self._MoveEventInfo.DestPosition = destPos
	else
		self._MoveEventInfo = nil
	end
    SendProtocol2Server(msg)
end

def.method("table", "=>", "table").CalcChargeDstPos = function(self, event)
	if event == nil then return nil end

	local destPos = nil
	if event.Type == SkillMoveType.InstantMove then
		if event.PosId > 0 then
			destPos = self._Host:GetPos()
			local nCurMapID = game._CurWorld._WorldInfo.SceneTid
			local posData = MapBasicConfig.GetPosDataByPosID(nCurMapID, event.PosId)
			if posData ~= nil then
				destPos = Vector3.New(posData.posx, posData.posy, posData.posz)
			end
		elseif self._ModifiedTargetPos ~= nil then
			destPos = self._ModifiedTargetPos
		else
			local target = self._AttackTarget
			if target ~= nil then					
				local dir = target:GetPos() - self._Host:GetPos()
				dir.y = 0
				destPos = target:GetPos() - dir:Normalize() * (target:GetRadius() + self._Host:GetRadius())
			else
				local dir = self._Host:GetDir():Normalize()
				local chargeDis = GameUtil.GetChargeDistance(self._Host:GetPos(), dir, self._ActiveCommonSkill._Skill.MaxRange)
				if chargeDis < 0 then chargeDis = 0 end
				destPos = self._Host:GetPos() + dir * chargeDis
			end
		end
	else
		local curPos = self._Host:GetPos()
		local maxDistance = event.Duration * event.Speed / 1000
		
		if event.Type == SkillMoveType.FixedPoint and self._ModifiedTargetPos ~= nil then
			destPos = self._ModifiedTargetPos
			local dis = Vector3.DistanceH(curPos, destPos)
			if dis > maxDistance then
				local dir = destPos - curPos
				dir.y = 0
				dir = dir:Normalize()
				destPos = curPos + dir * maxDistance
			end
		elseif self._AttackTarget ~= nil and not event.PierceTarget then -- 要考虑直线可达
			local target = self._AttackTarget
			local targetPos = target:GetPos()

			local dir = nil
			local disSqr = Vector3.SqrDistanceH(curPos, targetPos)
			if disSqr < 0.01 then -- 太近，按照重合处理
				dir = -self._Host:GetDir()
			else
				dir = (targetPos - curPos)
			end
			dir.y = 0
			dir = dir:Normalize()
			if GameUtil.PathFindingIsConnected(curPos, targetPos) then 		
				local radius = target:GetRadius() + self._Host:GetRadius()
				if disSqr > (maxDistance + radius) * (maxDistance + radius) then
					destPos = curPos + dir * maxDistance
				else
					destPos = targetPos - dir * radius
				end
			end
		end

		if destPos == nil then
			local dashDir = self._AttackDir:Normalize()
			if event.Angle ~= 0 then
				dashDir = Quaternion.Euler(0, event.Angle, 0) * dashDir
			end
			local chargeDis = GameUtil.GetChargeDistance(curPos, dashDir, maxDistance)
			if chargeDis < 0 then chargeDis = 0 end
			destPos = dashDir * chargeDis + curPos
		end
	end

	return destPos
end

def.method("table", "=>", "table").CalcEventModifiedTargetPos = function(self, event)
	if event == nil then return nil end 

	local startPos, destPos, direction, targetRadius = nil, nil, nil, 0
	local EStartPositionType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventResetTargetPosition.EStartPositionType
	local target = self._AttackTarget
	if event.StartPositionType == EStartPositionType.SELF then  -- 自身位置
		startPos = self._Host:GetPos()
		direction = self._Host:GetDir()
	elseif event.StartPositionType == EStartPositionType.TARGET then  -- 目标位置
		if target ~= nil then
			startPos = target:GetPos()
			targetRadius = target:GetRadius() + self._Host:GetRadius()	
			direction = target:GetPos() - self._Host:GetPos()
			direction.y = 0
		else -- 如果没有目
			local dir = self._Host:GetDir():Normalize()
			local chargeDis = GameUtil.GetChargeDistance(self._Host:GetPos(), dir, self._ActiveCommonSkill._Skill.MaxRange)
			if chargeDis < 0 then chargeDis = 0 end
			destPos = self._Host:GetPos() + dir * chargeDis
		end		
	end
	
	if startPos ~= nil and destPos == nil then
		local dis = event.OffsetDistance
		if event.CalcCollisionRadius then 
			if event.OffsetDistance > 0 then
				dis = dis + targetRadius
			else
				dis = dis - targetRadius
			end
		end
		direction = direction:Normalize()
		dis = GameUtil.GetChargeDistance(startPos, direction, dis)

		destPos = startPos + direction * dis
	end
	return destPos
end

def.method("=>", "boolean").IsApproachingTarget = function(self)
	return (self._CurSkillCastStage == SKILL_CAST_STAGE.S2_RECONFIRMATION and self._CurSkill ~= nil)
end

def.method("boolean").EnableAutoSystemPause = function(self, state)
	-- 自动任务通过任务事件进行驱动
	-- 如果在寻路中收到采集成功欢呼时，会停掉Move，中断自动行为
	-- 所以需要在欢呼技能结束后重启任务自动化
	local CQuestAutoMan = require"Quest.CQuestAutoMan"
	local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
	if state then
		CQuestAutoMan.Instance():Pause(_G.PauseMask.SkillPerform)
		CDungeonAutoMan.Instance():Pause(_G.PauseMask.SkillPerform)
	else
		CQuestAutoMan.Instance():Restart(_G.PauseMask.SkillPerform)
		CDungeonAutoMan.Instance():Restart(_G.PauseMask.SkillPerform)
	end
end

def.override("boolean").OnSkillInterruptted = function(self, change2stand)
	if self._ActiveCommonSkill == nil then return end
	local skill_id = self._ActiveCommonSkill._SkillID
	local skillCategory = self._ActiveCommonSkill._Skill.Category
	--local interruptByCombat = self._ActiveCommonSkill._Skill.InterruptByCombat
	CObjectSkillHdl.OnSkillInterruptted(self, change2stand)
	-- 如果蓄力中，则打断蓄力
	StopCharging(self, skill_id)

	-- 进度条打断
	self:CloseLoadingBar(skill_id)

	GameUtil.SetGameCamCtrlParams(false, EnumDef.CAMERA_LOCK_PRIORITY.LOCKED_IN_SKILL_COMMON)

	-- 恢复自动战斗
	--if not interruptByCombat then
	--	self:EnableAutoSystemPause(false)
	--end

	if skillCategory == Template.Skill.SkillCategory.SkillCategoryNone then
		local CQuestAutoGather = require "Quest.CQuestAutoGather"
		CQuestAutoGather.Instance():Stop()
		self._Host:SetMineGatherId(0)
	end
	self._ModifiedTargetPos = nil

	self:OnSkillEndCallback(false)
end

def.method("number", "dynamic").OnSkillFailed = function(self, skill_id, pos)	
	-- 客户端技能已经结束，无需做特殊处理，只需要同步一下位置
	if self._ActiveCommonSkill == nil then
		print("Recv S2CSkillPerformFailed after Client SkillStop")
		self._Host:SetPos(pos)
		return
	end

	-- 异常, 已经切换到了另一个技能，直接忽略当前消息
	if self._ActiveCommonSkill._SkillID ~= skill_id then
		print("Recv S2CSkillPerformFailed when a new Skill is performing " .. skill_id .. " - " .. self._ActiveCommonSkill._SkillID)
		return
	end	

	local interruptByCombat = self._ActiveCommonSkill._Skill.InterruptByCombat

	self._Host:StopMovementLogic()
	self._Host:SetAutoPathFlag(false)
	self:OnForcePerformEnd(skill_id)
	
	self._IsCastingDeathSkill = false
	
	-- 如果蓄力中，则打断蓄力
	StopCharging(self, skill_id)

	-- 进度条打断
	self:CloseLoadingBar(skill_id)

	self:OnSkillEndCallback(false)
	self._ModifiedTargetPos = nil

	-- 归位
	self._Host:SetPos(pos)
	self._Host:SetMineGatherId(0)
	self:OnEntityStopSkill(skill_id, false)

	-- 缓冲操作，必须放在EnableAutoSystemPause之前
	-- 如果是Move，会打断自动化
	-- 如果是传送，会暂停自动化
	-- 如果是采集, ???
	self._Host:DoCachedAction()

	if not interruptByCombat then 
		self:EnableAutoSystemPause(false)
	end

	if self._DebugFunction ~= nil then
		self._DebugFunction()
		self._DebugFunction = nil
	end
end

def.method("number", "=>", "boolean").UpdateComboInfos = function(self, skill_id)
	if self._ActiveCommonSkill == nil or self._ActiveCommonSkill._SkillID ~= skill_id then return false end

	local events = self._SpecialEventList[TriggerType.Operation]
	if events ~= nil and #events > 0 then
		for i,v in ipairs(events) do
			v:OnEvent()
			if v._IsToBlockPerformSequence then
				break
			end
		end
		self:ClearSpecialTriggerTypeEvents(TriggerType.Operation)
	else
		self._ComboInfo._SkillID = skill_id
	end

	return true
end

def.method().ClearComboInfos = function(self)
	self._ComboInfo._SkillID = 0
end

def.override("string", "boolean").ChangeToSkillState = function(self, ani_name, is_half)
	local CFSMHostSkill = require "FSM.HostFSM.CFSMHostSkill"
  	local ss = CFSMHostSkill.new(self._Host, ani_name, is_half)
 	self._Host:ChangeState(ss)
end

def.method("=>", "boolean").CanTriggerCombo = function(self)
	if self._ActiveCommonSkill == nil then return false end
	if self._ComboInfo._SkillID == nil or self._ComboInfo._SkillID == 0 then
		return false
	end

	return true
end

def.override("table", "function", "function").SkillMove = function(self, pos, successcb, failcb)
    if not self._Host:CanMove() then return end

	self._IsSkillMoving = true
	if game._IsUsingJoyStick then		
		GameUtil.AddJoyStickMoveBehavior(self._Host:GetGameObject(), self._Host:GetMoveSpeed(), false)
	elseif pos ~= nil then
		self._SkillMovingDest = pos
		GameUtil.AddMoveBehavior(self._Host:GetGameObject(), pos, self._Host:GetMoveSpeed(), function(ret)
			self:ClearSkillMoveState()
			if ret == EnumDef.BEHAVIOR_RETCODE.Success then
				if successcb then successcb() end
			else
				if failcb then failcb() end
			end
		end, false)
	end
end

def.method("boolean").SetWeaponCollisionFlag = function(self, on)
	local weaponL = self._Host._CurWeaponInfo[4]
	local weaponR = self._Host._CurWeaponInfo[5]
	
	if on then
		if not IsNil(weaponL) then
			weaponL.tag = "Weapon"
			GameUtil.EnablePhysicsCollision(weaponL, true, self._Host._ID)
		end

		if not IsNil(weaponR) then
			weaponR.tag = "Weapon"
			GameUtil.EnablePhysicsCollision(weaponR, true, self._Host._ID)
		end
	else
		if not IsNil(weaponL) then
			weaponL.tag = "Untagged"
			GameUtil.EnablePhysicsCollision(weaponL, false, self._Host._ID)
		end

		if not IsNil(weaponR) then
			weaponR.tag = "Untagged"
			GameUtil.EnablePhysicsCollision(weaponR, false, self._Host._ID)
		end
	end
end

def.override("table", "number", "function", "function").DoMove = function(self, pos, offset, successcb, failcb)
	local skill_id, perform_idx = self:GetCurSkillInfo()
	if CElementSkill.CanMoveWithSkill(skill_id, perform_idx) then
		local perform = self._ActiveCommonSkill._Skill.Performs[perform_idx]
		if perform and perform.MoveCastType == Template.Skill.Perform.PerformMoveCastType.HalfBody then
			self._Host:NormalMove(pos, self._Host:GetMoveSpeed(), offset, successcb, failcb)
		else
			self:SkillMove(pos, successcb, failcb)
		end
	else
		if CElementSkill.CanBeInterrupttedByMoving(skill_id, perform_idx) then
			self:OnSkillInterruptted(false)
			self:OnSkillEnd(skill_id, false, false)
			self:EnableAutoSystemPause(false)
			self._Host:NormalMove(pos, self._Host:GetMoveSpeed(), offset, successcb, failcb)
		else
			if not game._IsUsingJoyStick then
				local function Action()
					self._Host:NormalMove(pos, self._Host:GetMoveSpeed(), offset, successcb, failcb)
				end
				self._Host:AddCachedAction(Action)
			end
		end
	end
end

def.method("=>", "number").GetCurAttackTargetId = function(self)
	if self._AttackTarget ~= nil then
		return self._AttackTarget._ID
	else
		return 0
	end
end

def.method("table").ChangeTargetPos = function (self, dest_pos)
	self._ModifiedTargetPos = dest_pos
end

def.method("=>", "table").GetModifiedTargetPos = function (self)
	return self._ModifiedTargetPos
end

def.method("function").RegisterDebugFunc = function(self, cb)
	self._DebugFunction = cb
end

def.method().OnJoystickDragEnd = function (self)
	self._IsSkillMoving = false	
	self._SkillMovingDest = nil
end

def.override().Release = function(self)
    self._ActiveBlinkSkill1 = nil   -- 瞬发技能1
	self._ActiveBlinkSkill2 = nil   -- 瞬发技能2
	self._ComboInfo = {}

	self._ChargingTimeLen = 0
	self._ConsumeCombo = 0

	self._JudgeParams = nil   -- 记录判定参数，供物理消息回调处理使用

	self._CurSkill = nil
	self._CurSkillID = 0
	self._CachedParams = {}

	self._MoveEventInfo = {}
	self._ActingBarTimerId = 0 							-- 进度条id
	self._ActingBarSkillId = 0 							-- 进度条id

	self._ValidSkillsInfo = {}

	self._ResurrectTarget = 0

	self._ChargingInfo = {}
	self._CurSkillCastStage = SKILL_CAST_STAGE.S0_NONE

	CObjectSkillHdl.Release(self)
end

CHostSkillHdl.Commit()
return CHostSkillHdl