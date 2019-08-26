local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local EStartPositionType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventResetTargetPosition.EStartPositionType
local SkillMoveType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventSkillMove.SkillMoveType

local CResetTargetPosEvent = Lplus.Extend(CSkillEventBase, "CResetTargetPosEvent")
local def = CResetTargetPosEvent.define

def.static("table", "table", "=>", CResetTargetPosEvent).new = function(event, params)
	local obj = CResetTargetPosEvent()
	obj._Event = event.ResetTargetPosition 
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)	
	if self._Params.BelongedCreature == nil then return end
	
	local entity = self._Params.BelongedCreature
	if not entity:IsHostPlayer() or entity._SkillHdl == nil then return end

	local destPos = entity._SkillHdl:CalcEventModifiedTargetPos(self._Event)

	if destPos ~= nil then
		entity._SkillHdl:ChangeTargetPos(destPos)
		
		local dir = destPos - entity:GetPos()
		if math.abs(dir.x) < 1e-3 and math.abs(dir.z) < 1e-3 then return end
		dir.y = 0
		if self._Event.AutoTurnToTarget then				
			entity:SetDir(dir)

			local msg = CreateEmptyProtocol("C2SRoleTurn")
			msg.EntityId = entity._ID
			msg.TurnToRotation.x = dir.x
			msg.TurnToRotation.y = dir.y
			msg.TurnToRotation.z = dir.z			
			SendProtocol2Server(msg)			
		end
	end
end

CResetTargetPosEvent.Commit()
return CResetTargetPosEvent
