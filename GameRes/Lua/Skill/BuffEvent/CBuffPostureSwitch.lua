local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"

local CBuffPostureSwitch = Lplus.Extend(CBuffEventBase, "CBuffPostureSwitch")
local def = CBuffPostureSwitch.define

def.static("table", "table", "=>", CBuffPostureSwitch).new = function(host, event)
	local obj = CBuffPostureSwitch()
	obj._Host = host
	local tmp = {
		[1] = event.PostureSwitch.StandAction,
		[2] = event.PostureSwitch.FightStandAction,
		[3] = event.PostureSwitch.MoveAction,
		[4] = event.PostureSwitch.FightMoveAction,
		[5] = event.PostureSwitch.RemoveSkillId,
		[6] = event.PostureSwitch.BeAttackAction,
		[7] = event.PostureSwitch.BeAttackBurstPoint,
	}
	obj._Params = tmp
	return obj	
end

def.override().OnEvent = function(self)
	local entity = self._Host
	if entity and entity:IsPlayerType() then		  		
	    entity:SetChangePoseDate(self._Params)
	    if entity:GetCurStateType() == FSM_STATE_TYPE.IDLE then
	    	entity:StopNaviCal()
	    end
	end
end

def.override().OnBuffEnd = function(self)	
	local entity = self._Host
	if entity and entity:IsPlayerType() then
		entity:SetChangePoseDate(nil)

		if  self._Params[5] > 0 then
			entity:StopNaviCal()

			if entity:IsHostPlayer() then		
				local state = entity:GetCurStateType()
				if state ~= FSM_STATE_TYPE.SKILL then 
					entity:UseSkill(self._Params[5])
				end
			end
		end
	end

	CBuffEventBase.OnBuffEnd(self)
end

CBuffPostureSwitch.Commit()
return CBuffPostureSwitch