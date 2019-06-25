--[[
【非主角技能处理流程】
1、收到服务器技能段开始协议，处理OnEntityPerformSkill

2、在OnEntityPerformSkill中处理以下事情：（类似主角的OnPerformStart） 
   (1)根据技能数据，添加各种event。时间帧相关的时间，添加Timer。碰撞触发事件、按键触发事件、正常结束触发事件和异常结束触发事件单独保存。
   (2)根据当前技能段的时间，添加Perform 结束Timer。

3、如果在Perform执行过程中有特殊事件，执行第3步中记录的特定类型事件。

4、收到技能结束协议时，调用OnEntityStopSkill，执行清理逻辑

其他：
	技能中断时，执行OnSkillInterruptted
]]

local Lplus = require "Lplus"
local CActiveSkillInfo = require "Skill.CActiveSkillInfo"
local CElementSkill = require "Data.CElementSkill"
local Template = require "PB.Template"
local EIndicatorType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillIndicator.EIndicatorType
local SkillMoveType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillMove.SkillMoveType
local CEntity = Lplus.ForwardDeclare("CEntity")
local CGame = Lplus.ForwardDeclare("CGame")
local CFxObject = require "Fx.CFxObject"
local CElementData = require "Data.CElementData"
local SkillDef = require "Skill.SkillDef"
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR

local CObjectSkillHdl = Lplus.Class("CObjectSkillHdl")
local def = CObjectSkillHdl.define

def.field(CEntity)._Host = nil

def.field("table")._AttackPoint = nil     -- 技能释放点
def.field("table")._AttackDir = nil     -- 技能释放方向
def.field(CActiveSkillInfo)._ActiveCommonSkill = nil   -- 普通技能
def.field(CEntity)._AttackTarget = nil
def.field("boolean")._IsCastingDeathSkill = false

def.field("table")._SpecialEventList = BlankTable  -- trigger_type
def.field("table")._ActiveEventList = BlankTable
def.field("table")._JudgementEventsGroup = BlankTable  -- {[groupId] = {e1, e2, ...}, ...}
-- 帧事件 循环帧事件Timer列表，在技能跳转、中断时，需要将未执行的event清理掉
def.field("table")._EventTimerList = BlankTable
def.field("table")._GfxList = BlankTable
def.field("boolean")._IsInterruptLastSkill = false

def.field("boolean")._IsSkillMoving = false
def.field("table")._SkillMovingDest = nil

-- 主角之外的
def.field("function")._CachedSkillAction = nil
def.field("number")._CachedSkillId = 0  -- Host模型加载过程，要执行的技能

def.field("table")._SkillStartCallbacks = nil
def.field("table")._SkillEndCallbacks = nil

def.field("table")._ClientCalcVictims = BlankTable

def.field(CFxObject)._SkillIndicatorFx = nil 
def.field("number")._DashTimerId = 0                

def.final(CEntity, "=>", CObjectSkillHdl).new = function (o)
	local obj = CObjectSkillHdl()
	obj._Host = o
	return obj
end

local function PerformSkill(self, skillid, performid, targetid, destpos, dir, moveinfo)
	self:StopGfxPlay(EnumDef.EntityGfxClearType.PerformEnd)
	self:StopActiveEvents(EnumDef.EntitySkillStopType.PerformEnd)

	if self._Host:IsDead() and not self:IsCastingDeathSkill() then return end

	local skill_info = self._ActiveCommonSkill
	if skill_info == nil then 
		skill_info = CActiveSkillInfo.new() 
		self._ActiveCommonSkill = skill_info
	end
	skill_info._SkillID = skillid
	skill_info._IsGoingOn = true
	skill_info._StartTime = Time.time
	skill_info._Skill = self._Host:GetEntitySkill(skillid)
	if not skill_info._Skill then
		skill_info._Skill = CElementSkill.Get(skillid) 
	end

	local cur_skill_info = self._ActiveCommonSkill
	if cur_skill_info == nil then warn("cur skill data is error") return end
	
	if cur_skill_info._Skill == nil then
		warn("Entity", self._Host._ID, "failed to perform skill, not skill with id", skillid,debug.traceback()) 
		return
	end

	local performidx = self:GetPerformIdxById(skillid, performid)
	cur_skill_info._PerformIdx = performidx
	local perform = cur_skill_info._Skill.Performs[performidx]
	
	if perform == nil then
		warn("Entity", self._Host._ID, "failed to get perform, skill_id =", skillid, "performIdx =", performidx) 
		return
	end

	self._AttackPoint = destpos
	self._AttackDir = dir     
	self._AttackTarget = game._CurWorld:FindObject(targetid) 

	if dir ~= nil then self._Host:SetDir(dir) end

	if performidx == 1 then
		-- 技能功能为None时，表示通用技能，需要特殊处理，仅对玩家类对象有效；NPC技能未使用这一字段，默认为None
		local SkillCategory = Template.Skill.SkillCategory
		if self._Host:IsPlayerType() and (cur_skill_info._Skill.Category == SkillCategory.SkillCategoryNone or cur_skill_info._Skill.Category == SkillCategory.Leisure) then
			self._Host:ChangeWeaponHangpoint(true)
			self:SendInteractiveSkillMsg()
		else
			self._Host:UpdateCombatState(true, true, 0, true, false)	
		end
	end

	local skill_move_event, _, _ = self:AddEvents(skillid, performidx)
	local ani_name = perform.DefaultAnimationName
	if ani_name ~= "" then
		if perform.MoveCastType == Template.Skill.Perform.PerformMoveCastType.HalfBody then
			self:ChangeToSkillState(ani_name, true)
		else
			self:ChangeToSkillState(ani_name, false)
		end
	end

	-- SkillMoveType.InstantMove 瞬移通过强制位移同步消息实现
	if moveinfo ~= nil and skill_move_event ~= nil and skill_move_event.Type ~= SkillMoveType.InstantMove then
		local startTime = moveinfo.BeginTime
		local destPos = Vector3.New(moveinfo.DestPosition.x, 0, moveinfo.DestPosition.z) 
		local hostX, hostZ = self._Host:GetPosXZ()
		local distance = SqrDistanceH(hostX, hostZ, destPos.x, destPos.z)
		if distance > 0 then
			if self._DashTimerId ~= 0 then
				self._Host:RemoveTimer(self._DashTimerId)
				self._DashTimerId = 0
			end

			local duration = moveinfo.Duration /1000
			self._DashTimerId = self._Host:AddTimer(startTime/1000, true, function()
					if self._Host:IsReleased() then return end
					if not self:IsCastingDeathSkill() and self._Host:IsDead() then return end
					local go = self._Host:GetGameObject()
					local skill_cast_situation = false
					if go ~= nil then
						if self:GetEntitySkillType(skillid) == EnumDef.EntitySkillType.Dead then
							GameUtil.AddDashBehavior(go, destPos, duration, skill_move_event.PierceTarget, skill_move_event.KillTargetGoOnMove)
						else
							if self._Host:CanMove() then
								GameUtil.AddDashBehavior(go, destPos, duration, skill_move_event.PierceTarget, skill_move_event.KillTargetGoOnMove)
							end
						end
					end
				end)
		end
	end
end

-- 技能段开始，服务器协议驱动
def.virtual("number", "number", "boolean", "number", "table", "table", "table").OnEntityPerformSkill = function(self, skillid, performid, isDeathSkill, targetid, destpos, dir, moveinfo)	
	self._IsCastingDeathSkill = isDeathSkill
	if self._Host._IsReady then 
		--warn("OnEntityPerformSkill", skillid, performid, Time.time)
		PerformSkill(self, skillid, performid, targetid, destpos, dir, moveinfo)
	else
		self._CachedSkillAction = function()
				PerformSkill(self, skillid, performid, targetid, destpos, dir, moveinfo)
			end		
		self._CachedSkillId = skillid		
		self._Host:AddLoadedCallback(function(e)
				if self._CachedSkillId > 0 and self._CachedSkillAction ~= nil then
					self._CachedSkillAction()
				end
				self._CachedSkillAction = nil
				self._CachedSkillId = 0
			end)
	end
end

def.virtual().SendInteractiveSkillMsg = function(self)
	local cur_skill_info = self._ActiveCommonSkill
	if cur_skill_info == nil then return end

	if cur_skill_info._Skill.Category ~= Template.Skill.SkillCategory.SkillCategoryNone then return end

	-- 广播玩家对玩家休闲动作发送队伍频道消息
	do 
		local playerName = RichTextTools.GetElsePlayerNameRichText(self._Host._InfoData._Name, false)
		local strInteractive = nil 

		local skilldata = self._ActiveCommonSkill._Skill

		if self._AttackTarget ~= nil then
			if skilldata.SkillLevelUpDescription ~= nil and skilldata.SkillLevelUpDescription ~= "" then
				local targetName = nil
				if self._AttackTarget:IsHostPlayer() then
					targetName = StringTable.Get(13036)
				else
					targetName = RichTextTools.GetElsePlayerNameRichText(self._AttackTarget._InfoData._Name, false)   
				end
				strInteractive = string.format(skilldata.SkillLevelUpDescription, playerName, targetName)
			end
		else
			if skilldata.SkillDescription ~= nil and skilldata.SkillDescription ~= "" then
				strInteractive = string.format(skilldata.SkillDescription, playerName)
			end
		end
		local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
		local ChatManager = require "Chat.ChatManager"
		if strInteractive ~= nil and strInteractive ~= "" then
			ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelCurrent, strInteractive, false, 0, nil,nil)
		end
	end
end

-- 技能结束，服务器协议驱动
def.method("number", "boolean").OnEntityStopSkill = function(self, skillid, isNormalStop)
	if self._CachedSkillId > 0 and self._CachedSkillId == skillid then
		self._CachedSkillAction = nil
		self._CachedSkillId = 0
	end

	if self._ActiveCommonSkill == nil or self._ActiveCommonSkill._SkillID ~= skillid then
		return
	end

	if isNormalStop then
		self:TriggerEvents(TriggerType.NormalStop)
	else
		self:TriggerEvents(TriggerType.AbnormalStop)
	end
	self:ClearSpecialTriggerTypeEvents(TriggerType.All)
	self:ClearEventTimerList()

	self._IsInterruptLastSkill = false
	self:StopActiveEvents(EnumDef.EntitySkillStopType.SkillEnd)
	self:StopGfxPlay(EnumDef.EntityGfxClearType.SkillEnd)
	
	local SkillCategory = Template.Skill.SkillCategory
	local curSkillTemp = self._ActiveCommonSkill._Skill
	if self._Host:IsPlayerType() and (curSkillTemp.Category == SkillCategory.SkillCategoryNone or curSkillTemp.Category == SkillCategory.Leisure) then
		self._Host:ChangeWeaponHangpoint(not self._Host:IsInServerCombatState())
	else
		-- 延迟五秒
		self._Host:UpdateCombatState(false, true, 0, false, true)
	end

	self._ActiveCommonSkill = nil
	self._AttackTarget = nil
	self._IsCastingDeathSkill = false

	if not self._Host:IsPhysicalControled() and not self._Host:IsMagicControled() then
		self._Host:Stand()
	end
end

-- 获取技能类性
def.virtual("number", "=>", "number").GetEntitySkillType = function(self, skill_id)
	local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
	if self._Host:GetObjectType() == OBJ_TYPE.MONSTER then
		local tmpData = self._Host:GetMonsterTemplate()
		if tmpData then
			if tmpData.BirthSkillId == skill_id then
				return EnumDef.EntitySkillType.Birth
			elseif tmpData.DeathSkillId == skill_id then
				return EnumDef.EntitySkillType.Dead
			end
		end
	end
	return EnumDef.EntitySkillType.Normal
end

def.method("=>", "boolean").IsCastingDeathSkill = function(self)
	return self._IsCastingDeathSkill
end

-- 打断技能
def.virtual("boolean").OnSkillInterruptted = function(self, change2stand)
	if self._ActiveCommonSkill == nil then
		self:StopSkillIndicatorGfx()			--停止技能指示器特效
	 	self:OnSkillEndCallback(false) 	 	
		return 
	end
	
	if self._ActiveCommonSkill._PerformTimerID ~= 0 then
		self._Host:RemoveTimer(self._ActiveCommonSkill._PerformTimerID)
		self._ActiveCommonSkill._PerformTimerID = 0
	end

	self:ClearEventTimerList()
	self._IsInterruptLastSkill = false
	self:StopSkillIndicatorGfx()			--停止技能指示器特效

	self:StopGfxPlay(EnumDef.EntityGfxClearType.SkillInterrupted)

	local skill_id, perform_idx = self:GetCurSkillInfo()
	local curSkillTemp = self._ActiveCommonSkill._Skill

	if curSkillTemp ~= nil then
		local perform = curSkillTemp.Performs[perform_idx]
		if perform.MoveCastType == Template.Skill.Perform.PerformMoveCastType.HalfBody then
			self._Host:StopPartialAnimation(perform.DefaultAnimationName)		
		end
	end

	local SkillCategory = Template.Skill.SkillCategory
	if self._Host:IsPlayerType() and curSkillTemp ~= nil and (curSkillTemp.Category == SkillCategory.SkillCategoryNone or curSkillTemp.Category == SkillCategory.Leisure) then
		self._Host:ChangeWeaponHangpoint(not self._Host:IsInServerCombatState())
	else
		-- 延迟五秒
		self._Host:UpdateCombatState(false, true, 0, false, true)
	end

	self._ActiveCommonSkill = nil
	self._IsCastingDeathSkill = false
	self:StopActiveEvents(EnumDef.EntitySkillStopType.PerformEnd)
	self:ClearSpecialTriggerTypeEvents(TriggerType.All)

	self:OnSkillEndCallback(false)
	
	if change2stand then
		self._Host:Stand()
	end
end

-- 打断休闲 交互等技能
def.virtual().InterruptSpecialSkill = function(self)
	if not self:IsInCommonOrLeisureSkill() then return end

	-- 进战斗打断
	if self._ActiveCommonSkill._Skill.InterruptByCombat then
		self:OnSkillInterruptted(true)
	end
end

-- 是否正在释放通用或休闲技能
def.method("=>", "boolean").IsInCommonOrLeisureSkill = function(self)
	if not self._ActiveCommonSkill or not self._ActiveCommonSkill._Skill then
		return false
	end

	if self._ActiveCommonSkill._Skill.Category == Template.Skill.SkillCategory.SkillCategoryNone or
			self._ActiveCommonSkill._Skill.Category == Template.Skill.SkillCategory.Leisure then
			return true
	end
	return false
end

-- 是否处于可能被战斗打断的技能
def.method("=>", "boolean").IsInSkillCanInterruptByCombat = function (self)
	local cur_skill_info = self._ActiveCommonSkill
	if cur_skill_info ~= nil and cur_skill_info._Skill ~= nil and
	   cur_skill_info._Skill.InterruptByCombat then
		return true
	end
	return false
end

def.method().ClearDashBehavior = function(self)
	if self._DashTimerId ~= 0 then
		self._Host:RemoveTimer(self._DashTimerId)
		self._DashTimerId = 0
	end

	GameUtil.RemoveBehavior(self._Host:GetGameObject(), BEHAVIOR.DASH)
end

-- 清除技能移动标记
def.virtual().ClearSkillMoveState = function(self)
	self._IsSkillMoving = false
	self._SkillMovingDest = nil
end

def.virtual().ClearEventTimerList = function(self)
	for i,v in ipairs(self._EventTimerList) do
		self._Host:RemoveTimer(v)
	end		
	self._EventTimerList = {}
end

def.virtual("boolean").StopCurActiveSkill = function(self, change2stand)
	if self._ActiveCommonSkill ~= nil then		
		self:OnSkillInterruptted(change2stand)
	end
end

def.virtual("string", "boolean").ChangeToSkillState = function(self, ani_name, is_half)
	local CFSMObjSkill = require "FSM.ObjectFSM.CFSMObjSkill"
  	local ss = CFSMObjSkill.new(self._Host, ani_name, is_half)
 	self._Host:ChangeState(ss)
end

def.method("number", "number", "=>", "number").GetPerformIdxById = function(self, skill_id, perform_id)
	local skill = self._Host:GetEntitySkill(skill_id)
	if not skill then 
		skill = CElementSkill.Get(skill_id) 		
	end
	
	if not skill then
		return 0
	end

	local performs = skill.Performs
	for i,v in ipairs(performs) do
		if v.Id == perform_id then
			return i
		end
	end

	return 0
end

def.virtual("table", "=>", "boolean").DoesClientCare = function(self,event)
	return (event.GenerateActor._is_present_in_parent 
		or event.Animation._is_present_in_parent 
		or event.CameraShake._is_present_in_parent 
		or event.Audio._is_present_in_parent 
		or event.Cloak._is_present_in_parent 
		or event.SkillIndicator._is_present_in_parent 
		or event.GenerateKnifeLight._is_present_in_parent
		or event.Mirages._is_present_in_parent
		or event.PopSkillName._is_present_in_parent		
		or event.CameraEffect._is_present_in_parent
		or event.BulletTime._is_present_in_parent
		or event.PopSkillTips._is_present_in_parent
		)
end

def.virtual("table", "number", "number").RegisterSingleEvent = function(self, execution_unit, skill_id, targetId)
	if execution_unit == nil then return end
	local cur_trigger_type = 0
	if execution_unit.Trigger.Collision._is_present_in_parent then
		cur_trigger_type = TriggerType.Collision
	elseif execution_unit.Trigger.NormalStop._is_present_in_parent then
		cur_trigger_type = TriggerType.NormalStop
	elseif execution_unit.Trigger.AbnormalStop._is_present_in_parent then
		cur_trigger_type = TriggerType.AbnormalStop
	elseif execution_unit.Trigger.BeHited._is_present_in_parent then
		cur_trigger_type = TriggerType.BeHited
	elseif execution_unit.Trigger.KillMonster._is_present_in_parent then
		cur_trigger_type = TriggerType.KillMonster
	end

	if cur_trigger_type ~= 0 then
		local EventFactory = require "Skill.SkillEvent.CSkillEventFactory"
		if self._SpecialEventList[cur_trigger_type] == nil then self._SpecialEventList[cur_trigger_type] = {} end
		local e = EventFactory.CreateEvent(self._Host, execution_unit.Event, skill_id, targetId)
		self._SpecialEventList[cur_trigger_type][#self._SpecialEventList[cur_trigger_type] + 1] = e
	end
end

local function RemoveActiveEvents(self, e)
	for i = #self._ActiveEventList, 1, -1 do
		local v = self._ActiveEventList[i]
		if v == e then
			table.remove(self._ActiveEventList, i)
			break
		end
	end
end

local UniqueId = 0
def.method("number", "number", "=>", "table", "table", "number").AddEvents = function(self, skill_id, perform_idx)

	--warn("AddEvents ".. skill_id..","..perform_idx)

	local cur_skill_info = self._ActiveCommonSkill
	local skill = cur_skill_info._Skill

	-- for debug
	if skill == nil or skill.Performs == nil or skill.Performs[perform_idx] == nil then
		warn(skill_id, perform_idx, skill, skill.Performs, skill.Performs[perform_idx])
		return nil, nil, 0
	end

	self._SpecialEventList = {}
	self._EventTimerList = {}	
	local targetId = 0
	if self._AttackTarget ~= nil then targetId = self._AttackTarget._ID end
	local skillMoveInfo = nil
	local resetTargetPosInfo = nil
	local startTime = 0
	
	local EventFactory = require "Skill.SkillEvent.CSkillEventFactory"
	local execution_units = skill.Performs[perform_idx].ExecutionUnits
	for _,v in ipairs(execution_units) do
		if self:DoesClientCare(v.Event) then
			if v.Trigger.Timeline._is_present_in_parent then
				local id = #self._EventTimerList + 1
				self._EventTimerList[id] = self._Host:AddTimer(v.Trigger.Timeline.StartTime/1000, true, function()
					local e = EventFactory.CreateEvent(self._Host, v.Event, skill_id, targetId)
					if e ~= nil then
					 	e:OnEvent()
					 	local lifeTime = e:GetLifeTime()
					 	if lifeTime > 0 then
							table.insert(self._ActiveEventList, e)
							self._Host:AddTimer(lifeTime + 0.1, true, function()
									RemoveActiveEvents(self, e)
									if not e:IsReleased() then
										e:OnRelease(EnumDef.EntitySkillStopType.LifeEnd)
									end
								end)
						end 
					end
				end)
			elseif v.Trigger.Loop._is_present_in_parent then						
			  	local add2Group = v.Event.Judgement._is_present_in_parent and v.Trigger.Loop.Count > 1   --_JudgementEventsGroup
				if add2Group then UniqueId = UniqueId + 1 end

				local interval = v.Trigger.Loop.Interval
				local total = v.Trigger.Loop.Count
				for i = 1, v.Trigger.Loop.Count do
					local id = #self._EventTimerList + 1
					local t = (v.Trigger.Loop.StartTime + (i-1) * interval)/1000
					local function callback()
						local e = EventFactory.CreateEvent(self._Host, v.Event, skill_id, targetId)
						if e ~= nil then
							if add2Group then
								if self._JudgementEventsGroup[UniqueId] == nil then
									self._JudgementEventsGroup[UniqueId] = {}
								end
								e:AddJudgementInfo(UniqueId, i, total, interval)
								self._JudgementEventsGroup[UniqueId][#self._JudgementEventsGroup[UniqueId] + 1] = e
							end
							e:OnEvent()
							local lifeTime = e:GetLifeTime()
						 	if lifeTime > 0 then
								table.insert(self._ActiveEventList, e)
								self._Host:AddTimer(lifeTime + 0.1, true, function()
										RemoveActiveEvents(self, e)
										if not e:IsReleased() then
											e:OnRelease(EnumDef.EntitySkillStopType.LifeEnd)
										end
									end)
							end
						end				
					end
					self._EventTimerList[id] = self._Host:AddTimer(t, true, callback)
				end
			else
				--warn("RegisterSingleEvent "..skill_id)
				self:RegisterSingleEvent(v, skill_id, targetId)
			end
		end
		if v.Event.SkillMove._is_present_in_parent then
			if skillMoveInfo ~= nil then
				warn("this perform has too many skill_move infos")
			end
			skillMoveInfo = v.Event.SkillMove
			if v.Trigger.Timeline._is_present_in_parent then
				startTime = v.Trigger.Timeline.StartTime
			else
				warn("Skill move only can be triggerred by timeline")
			end
		end

		-- Perform开始时只处理第一帧的ResetTargetPosition事件，因为影响SkillMove事件的位置信息
		if v.Event.ResetTargetPosition._is_present_in_parent and v.Trigger.Timeline.StartTime <= 0 then
			if resetTargetPosInfo ~= nil then
				warn("this perform has too many resetTargetPosInfo infos")
			end
			resetTargetPosInfo = v.Event.ResetTargetPosition
		end		
	end

	return skillMoveInfo, resetTargetPosInfo, startTime
end

def.method("number", "=>", "boolean").TriggerEvents = function(self, cur_trigger_type)
	local events = self._SpecialEventList[cur_trigger_type]
	if events == nil then return true end

	local go_to_next_perform = true
	for _,v in ipairs(events) do
		v:OnEvent()
		if v._IsToBlockPerformSequence then
			go_to_next_perform = false
		end
	end

	if cur_trigger_type ~= TriggerType.NormalStop and go_to_next_perform == false then
		self._SpecialEventList[cur_trigger_type] = nil
	end

	return go_to_next_perform
end

def.method("number").ClearSpecialTriggerTypeEvents = function(self, cur_trigger_type)
	if cur_trigger_type == TriggerType.All then
		self._SpecialEventList = {}
	else
		local events = self._SpecialEventList[cur_trigger_type]
		if events == nil then return end
		self._SpecialEventList[cur_trigger_type] = nil
	end
end

def.virtual("table", "number", "function", "function").DoMove = function(self, pos, offset, successcb, failcb)
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
			self._Host:NormalMove(pos, self._Host:GetMoveSpeed(), offset, successcb, failcb)
		end
	end
end

-- 仅在此类内部使用
-- 停止非即时性的Event,比如震屏
def.method("number").StopActiveEvents = function(self, triggerType)
	for i = #self._ActiveEventList, 1, -1 do
		local v = self._ActiveEventList[i]
		if v:OnRelease(triggerType) then
			table.remove(self._ActiveEventList, i)	
		end
	end
end

-- 仅在此类内部使用
-- 关闭与此技能先关的特效
def.method("number").StopGfxPlay = function(self, trigger_type)	
	for i = #self._GfxList, 1, -1 do
		local v = self._GfxList[i]
		if trigger_type == EnumDef.EntityGfxClearType.PerformEnd then  -- 执行单元结束 
			if v and v.StopWhenPerformInterrupted then	
				CFxMan.Instance():Stop(v.Gfx)				
				table.remove(self._GfxList, i)						
			end
		elseif trigger_type == EnumDef.EntityGfxClearType.SkillEnd then  -- 技能结束
			if v and (v.StopWhenSkillInterrupted or v.StopWhenPerformInterrupted) then
				CFxMan.Instance():Stop(v.Gfx)
				table.remove(self._GfxList, i)		
			end
			-- 清理掉剩余的Lua GFX对象，不需要调用Stop，结束时机由特效生命长度自己决定
			-- 否则，会出现Lua对象堆积，造成Lua内存持续增长
			self._GfxList = {}  
		elseif trigger_type == EnumDef.EntityGfxClearType.BackToPeace then  -- 脱战
			if v and v.StopWhenBackToPeace then
				CFxMan.Instance():Stop(v.Gfx)
				table.remove(self._GfxList, i)		
			end
		elseif trigger_type == EnumDef.EntityGfxClearType.SkillInterrupted then -- 技能打断
			if v and (v.StopWhenSkillInterrupted or v.StopWhenPerformInterrupted) then
				CFxMan.Instance():Stop(v.Gfx)
				table.remove(self._GfxList, i)		
			end
			-- 清理掉剩余的Lua GFX对象，不需要调用Stop，结束时机由特效生命长度自己决定
			-- 否则，会出现Lua对象堆积，造成Lua内存持续增长
			self._GfxList = {}  
		elseif trigger_type == EnumDef.EntityGfxClearType.LifeEnd then
			CFxMan.Instance():Stop(v.Gfx)
			table.remove(self._GfxList, i)
		end	
	end
end

def.method("boolean").OnSkillEndCallback = function(self, success)
	if self._SkillEndCallbacks ~= nil and #self._SkillEndCallbacks > 0 then
		for i,v in ipairs(self._SkillEndCallbacks) do
			v(success)
		end
		self._SkillEndCallbacks = nil
	end
end

def.method().OnHostBeHitted = function(self)
	self:TriggerEvents(TriggerType.BeHited)
end

def.method("boolean", "function").RegisterCallback = function(self, is_on_start, cb)
	if is_on_start then
		if self._SkillStartCallbacks == nil then self._SkillStartCallbacks = {} end
		self._SkillStartCallbacks[#self._SkillStartCallbacks + 1] = cb
	else
		if self._SkillEndCallbacks == nil then self._SkillEndCallbacks = {} end
		self._SkillEndCallbacks[#self._SkillEndCallbacks + 1] = cb
	end
end

def.method("=>", "boolean").IsCastingSkill = function(self)
	return self._ActiveCommonSkill ~= nil
end

def.method("=>", "number", "number").GetCurSkillInfo = function(self)
	if self._ActiveCommonSkill == nil then return 0,0 end
	return self._ActiveCommonSkill._SkillID, self._ActiveCommonSkill._PerformIdx
end

def.virtual("table", "function", "function").SkillMove = function(self, pos, successcb, failcb)
    if not self._Host:CanMove() then
        return 
    end
	self._IsSkillMoving = true
	
	if pos ~= nil then
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

--播放预警指示特效
def.method("number", "number", "number", "number","boolean", "=>", "boolean").PlaySkillIndicatorGfx = function (self, skill_indicator_type, duration, param1, param2,IsNotCloseToGround)
	local gfx_path = nil
	local scale = Vector3.one
	if skill_indicator_type == EIndicatorType.Circular then
		if not IsNotCloseToGround then 
			gfx_path = PATH.Etc_Yujing_Ring_Decl
		else
			gfx_path = PATH.Etc_Yujing_Ring
		end
		
		scale.x = param1 + self._Host:GetRadius() + 0.5
		scale.y = 1
		scale.z = param1 + self._Host:GetRadius() + 0.5
	elseif skill_indicator_type == EIndicatorType.Fan then
		if not IsNotCloseToGround then 
			gfx_path = PATH["Etc_Yujing_Shanxing"..param2.."_Decl"]
		else
			gfx_path = PATH["Etc_Yujing_Shanxing"..param2]
		end

		if gfx_path == nil then
			warn("Cannot find path:", "Etc_Yujing_Shanxing"..param2)
			gfx_path = ""
		end

		scale.x = param1 + self._Host:GetRadius() + 0.5
		scale.y = 1
		scale.z = param1 + self._Host:GetRadius() + 0.5
	elseif skill_indicator_type == EIndicatorType.Rectangle then
		if not IsNotCloseToGround then 
			gfx_path = PATH.Etc_Yujing_Juxing_Decl
		else
			gfx_path = PATH.Etc_Yujing_Juxing
		end

		scale.x = param1 + 1

		scale.y = 1
		scale.z = param2 + self._Host:GetRadius() + 0.5
	-- 环形
	elseif skill_indicator_type == EIndicatorType.Ring then
		gfx_path = PATH.Etc_Yujing_Hollow
		scale.x = self._Host:GetRadius() + param2 + 0.5 -- 外径
		scale.y = 1
		scale.z = self._Host:GetRadius() + param1 - 0.5 -- 内径		
	else
		return false
	end

	local go = self._Host:GetGameObject()
	local pos = go.position
	pos.y = GameUtil.GetMapHeight(pos) + 0.2
	local dir = self._Host._SkillDestDir or go.forward
	-- warn("gfx_path，scale ，IsNotCloseToGround ",gfx_path,scale.x,scale.y,scale.z,IsNotCloseToGround)
	local fx, id = GameUtil.PlayEarlyWarningGfx(gfx_path, pos, dir, scale, duration,IsNotCloseToGround)
	if fx ~= nil then
		if self._SkillIndicatorFx == nil then
			self._SkillIndicatorFx = CFxObject.new()
		end
		self._SkillIndicatorFx:Init(id, fx, nil)
	else
		warn("can not play gfx, gfx_path =", gfx_path)
	end
	return true
end

def.method().StopSkillIndicatorGfx = function (self)
	if self._SkillIndicatorFx ~= nil then
		self._SkillIndicatorFx:Stop()
		self._SkillIndicatorFx = nil
	end
end

-- 出生同步技能
def.method("table").PerformInitedSkill = function (self, SkillInfo)
	if not SkillInfo or SkillInfo.SkillId <= 0 then
		return
	end
	
	-- 不应该处理的数据	注释掉这个处理  服务器会保证准确性 在出生技能上从s2cperform后 主角进入 使用creature info
	-- if SkillInfo.IsDeadskill or SkillInfo.IsBornkill then
	-- 	warn("msg error occur in SkillId = "..SkillInfo.SkillId .. "   id  = "..self._Host._ID,debug.traceback())
	-- 	return
	-- end

	local destPosition = Vector3.New(SkillInfo.DestPosition.x, SkillInfo.DestPosition.y, SkillInfo.DestPosition.z)
	local direction = Vector3.New(SkillInfo.Direction.x, SkillInfo.Direction.y, SkillInfo.Direction.z)
	local moveInfo = SkillInfo.MoveInfo	
	self:OnEntityPerformSkill(SkillInfo.SkillId, SkillInfo.PerformId, false, SkillInfo.TargetId, destPosition, direction, moveInfo)	
end

def.virtual().Release = function(self)
	self._IsSkillMoving = false
	self._SkillMovingDest = nil
	self._CachedSkillAction = nil
	self._IsCastingDeathSkill = false

	self._AttackPoint = nil     -- 技能释放点
	self._AttackDir = nil     -- 技能释放方向
	self._ActiveCommonSkill = nil   -- 普通技能
	self._AttackTarget = nil

	self._SkillStartCallbacks = nil
	self._SkillEndCallbacks = nil
	
	self._IsInterruptLastSkill = false

	self._SpecialEventList = {}
	self._ActiveEventList = {}
	self:ClearEventTimerList()

	self:StopGfxPlay(EnumDef.EntityGfxClearType.LifeEnd)

	self._ClientCalcVictims = {}
	self._JudgementEventsGroup = nil

	for i,v in ipairs(self._GfxList) do
		v.Gfx:Stop()
	end
	self._GfxList = {}

	self:StopSkillIndicatorGfx()

	self._Host:RemoveTimer(self._DashTimerId)
	self._DashTimerId = 0

	self._Host = nil
end

CObjectSkillHdl.Commit()
return CObjectSkillHdl