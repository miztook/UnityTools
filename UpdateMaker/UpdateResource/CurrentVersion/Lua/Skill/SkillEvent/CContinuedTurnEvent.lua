local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CElementSkill = require "Data.CElementSkill"
local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR
local ETurnType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventContinuedTurn.ETurnType

local CContinuedTurnEvent = Lplus.Extend(CSkillEventBase, "CContinuedTurnEvent")
local def = CContinuedTurnEvent.define

def.static("table", "table", "=>", CContinuedTurnEvent).new = function(event, params)
	local obj = CContinuedTurnEvent()
	obj._Event = event.ContinuedTurn
	obj._Params = params
	return obj
end

-- required int32 TurnType = 1;            // 转向类型
-- required float AngularVelocity = 2;     // 角速度
-- required int32 Duration = 3;            // 持续时间
-- required bool IsCounterclockwise = 4;   // 是否逆时针
def.override().OnEvent = function(self)	
	local entity = self._Params.BelongedCreature
	if entity and entity:IsHostPlayer() and not entity._IsReleased then
		-- 普通转向
		if self._Event.TurnType == ETurnType.NORMAL then
			local angle = self._Event.AngularVelocity * self._Event.Duration/1000
			if not self._Event.IsCounterclockwise then
				angle = angle * (-1)
			end
			GameUtil.AddTurnBehavior(entity._GameObject, entity:GetDir(), self._Event.AngularVelocity, nil, true, angle)
		-- 跟随转向 服务器处理 保证同步
		-- elseif self._Event.TurnType == ETurnType.FOLLOW then
		end
	end
end


def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	local entity = self._Params.BelongedCreature
	if entity and entity:IsHostPlayer() and not entity._IsReleased  then
		GameUtil.RemoveBehavior(entity:GetGameObject(), BEHAVIOR.TURN)
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CContinuedTurnEvent.Commit()
return CContinuedTurnEvent
