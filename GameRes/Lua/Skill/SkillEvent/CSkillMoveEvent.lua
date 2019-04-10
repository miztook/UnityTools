local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CElementSkill = require "Data.CElementSkill"
local SkillMoveType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillMove.SkillMoveType
local MapBasicConfig = require "Data.MapBasicConfig" 

local CSkillMoveEvent = Lplus.Extend(CSkillEventBase, "CSkillMoveEvent")
local def = CSkillMoveEvent.define

def.static("table", "table", "=>", CSkillMoveEvent).new = function(event, params)
	local obj = CSkillMoveEvent()
	obj._Event = event.SkillMove
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	local caster = self._Params.BelongedCreature

	if caster == nil or not caster:CanMove() or not caster:IsHostPlayer() then return end
	if caster._SkillHdl == nil or caster._SkillHdl._MoveEventInfo == nil then return end

	local event = self._Event
	
	if event.Type == SkillMoveType.InstantMove then -- 瞬间移动		
		local pos = caster:GetPos()
		local rot = caster:GetDir()			
		if event.PosId > 0 then
			local nCurMapID = game._CurWorld._WorldInfo.SceneTid
			local posData = MapBasicConfig.GetPosDataByPosID(nCurMapID, event.PosId)
			if posData then
				pos.x = posData.posx
				pos.y = posData.posy
				pos.z = posData.posz
				rot = Vector3.New(posData.rotx, posData.roty, posData.rotz)
			end
		elseif caster._SkillHdl:GetModifiedTargetPos() ~= nil then				
			pos = caster._SkillHdl:GetModifiedTargetPos()
			rot = pos - caster:GetPos()
			if math.abs(rot.x) < 1e-3 and math.abs(rot.z) < 1e-3 then
				rot = caster:GetDir()
			end
		end
		caster:SetPos(pos)
		caster:SetDir(rot)
		GameUtil.SetCamToDefault(true, false, false, true)
		return
	end

	local casterPos = caster:GetPos()
	local destPos = nil

	if event.CanChangeDirection then
		local dis = event.Speed * event.Duration / 1000
		destPos = casterPos + caster:GetDir() * dis
		GameUtil.AddDashBehavior(caster:GetGameObject(), destPos, event.Duration/1000, event.PierceTarget, event.KillTargetGoOnMove, event.CollisionCurrentTarget, true)
		return
	end
	
	if event.Type == SkillMoveType.FixedPoint then -- 关联了定点		
		destPos = caster._SkillHdl:GetModifiedTargetPos()
		if destPos ~= nil then
			local dis = Vector3.DistanceH(casterPos, destPos)
			local maxDis = event.Speed * event.Duration / 1000
			if dis > maxDis then
				local dir = destPos - casterPos
				dir.y = 0
				dir = dir:Normalize()
				destPos = casterPos + dir * maxDis
			end
		end
	end

	if destPos == nil then
		destPos = caster._SkillHdl._MoveEventInfo.DestPosition
	end
	
	local distance = 0
	if destPos ~= nil then
		distance = Vector3.DistanceH(casterPos, destPos)
	end

	if distance > 0.01 then
		local info = caster._SkillHdl._MoveEventInfo
		local time = distance/event.Speed
		GameUtil.AddDashBehavior(caster:GetGameObject(), destPos, time, event.PierceTarget, event.KillTargetGoOnMove, event.CollisionCurrentTarget, false)
	end
end

CSkillMoveEvent.Commit()
return CSkillMoveEvent
