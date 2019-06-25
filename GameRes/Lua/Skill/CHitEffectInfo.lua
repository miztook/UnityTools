local Lplus = require "Lplus"
local CEntity = Lplus.ForwardDeclare("CEntity")
local JudgementHitType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitType
local CFSMObjBeControlled = require "FSM.ObjectFSM.CFSMObjBeControlled"

local CHitEffectInfo = Lplus.Class("CHitEffectInfo")
local def = CHitEffectInfo.define

def.field(CEntity)._Host = nil
def.field("number")._CurStatus = 0
def.field("number")._StatusClearTimerID = 0
def.field("number")._CurStatusEndTime = 0

def.static(CEntity, "=>", CHitEffectInfo).new = function (o)
	local obj = CHitEffectInfo()
	obj._Host = o
	return obj
end

def.method(CEntity, "number", "table", "table").ChangeEffect = function(self, attacker, hit_type, hit_params, dest)
	local last_time = hit_params[1]/1000  -- 硬直、击倒、眩晕时，第一个参数为时间

	-- 硬直中遇到硬直，取结束事件晚者，计算状态
	if self._CurStatus == JudgementHitType.Stiffness and hit_type == self._CurStatus and Time.time + last_time < self._CurStatusEndTime then
		return
	end

	if hit_type == JudgementHitType.Knockback then 
		last_time = hit_params[2]/1000 -- 被击退，参数2为时间
	elseif hit_type == JudgementHitType.KnockIntoTheAir then
		last_time = hit_params[2]/1000 + hit_params[3]/1000 -- 被击飞时，状态持续时间为参数2击飞时间+参数3倒地时间
	end

	self._CurStatusEndTime = Time.time + last_time

	self._CurStatus = hit_type
	self._Host:StopMovementLogic()

	-- 如果是击倒或者击飞需要调整朝向
	if attacker ~= nil then 
		local dir = attacker:GetPos() - self._Host:GetPos()
		self._Host:SetDir(dir)
	end
	-- stop move and skill
	
	local controlled = CFSMObjBeControlled.new(self._Host, hit_type, hit_params, dest)
	self._Host:ChangeState(controlled)

	if self._StatusClearTimerID ~= 0 then
		self._Host:RemoveTimer(self._StatusClearTimerID)
		self._StatusClearTimerID = 0
	end

	self._Host:OnEnterPhysicalControled()
	self._StatusClearTimerID = self._Host:AddTimer(last_time, true, function()
		--warn("clear _StatusClearTimerID", self._StatusClearTimerID, debug.traceback())
		self._CurStatus = 0
		self._StatusClearTimerID = 0
		self._CurStatusEndTime = 0		
		self._Host:OnLeavePhysicalControled()		
	end)
	--warn("Add _StatusClearTimerID", self._StatusClearTimerID, last_time, debug.traceback())
end

def.method().Clear = function(self)
	if self._StatusClearTimerID ~= 0 then
		self._Host:RemoveTimer(self._StatusClearTimerID)
		self._StatusClearTimerID = 0
		self._Host:OnLeavePhysicalControled()
	end

	self._CurStatus = 0
	self._CurStatusEndTime = 0
end

def.method().Release = function(self)
	self:Clear()
	self._Host = nil
end

CHitEffectInfo.Commit()
return CHitEffectInfo