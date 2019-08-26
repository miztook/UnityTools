local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = Lplus.ForwardDeclare("CEntity")

local CSkillSealInfo = Lplus.Class("CSkillSealInfo")
local def = CSkillSealInfo.define

def.field(CEntity)._Host = nil
def.field("number")._CurStateMask = 0

-- CAN_MOVE =          1,  -- 是否可以移动
-- CAN_SKILL =         2,  -- 是否可以释放技能
-- CAN_NORMAL_SKILL  = 3,  -- 是否可以使用普攻
-- CAN_USE_ITEM =      4,  -- 是否可以使用物品
-- CAN_BE_SELECTED =   5,  -- 是否可以被选中
-- CAN_BE_ATTACKED =   6,  -- 是否可以被攻击
-- CAN_BE_INTERACTIVE = 7， -- 是否可以交互
def.field("table")._StatesList = BlankTable

def.static(CEntity, "=>", CSkillSealInfo).new = function (host)
	local obj = CSkillSealInfo()
	obj._Host = host
	return obj
end

-- 某个状态是否OK
def.method("number", "=>", "boolean").IsStateProper = function(self, state_type)
	if self._StatesList then
		local ret = self._StatesList[state_type]
		if ret ~= nil then return ret end
	end

	-- warn("error occur in IsStateProper, StatesList or StatesList[state_type] is nil", debug.traceback())
	return false
end

def.method("table").CatDebugLog = function(self, states)
	for i = 1 ,#states do 
		if i == 2 then
			warn("[ CAN_MOVE ] state is ======= [".. tostring(states[i]).."]")
		elseif i == 3 then
			warn("[ CAN_SKILL ] state is ======= [".. tostring(states[i]).."]")			
		elseif i == 4 then
			warn("[ CAN_NORMAL_SKILL ] state is ======= [".. tostring(states[i]).."]")			
		elseif i == 5 then
			warn("[ CAN_USE_ITEM ] state is ======= [".. tostring(states[i]).."]")
		elseif i == 6 then
			warn("[ CAN_BE_INTERACTIVE ] state is ======= [".. tostring(states[i]).."]")
		elseif i == 7 then
			warn("[ CAN_BE_SELECTED ] state is ======= [".. tostring(states[i]).."]")
		elseif i == 8 then
			warn("[ CAN_BE_ATTACKED ] state is ======= [".. tostring(states[i]).."]")
		end
	end
end


def.method("table", "number").UpdateStates = function(self, states, id)
	if #states <= 0 then
		warn("error data occur in UpdateStates, states lenth is 0")
		return
	end

	local oldState = self._StatesList
	local newState = states

	local CAN_BE_SELECTED = EnumDef.EBASE_STATE.CAN_BE_SELECTED
	if self._StatesList[CAN_BE_SELECTED] ~= nil and self._StatesList[CAN_BE_SELECTED] and states[CAN_BE_SELECTED] == false then
		game._HostPlayer:CancelTargetSelectedStatus(id)
	end
	self._StatesList = states

	if self._Host:IsHostPlayer() then
    	local CAN_MOVE = EnumDef.EBASE_STATE.CAN_MOVE
		if oldState[CAN_MOVE] ~= newState[CAN_MOVE] then
			local isEnter = not newState[CAN_MOVE]
			self._Host:SendBaseStateChangeEvent(isEnter)
		end

    	local CAN_SKILL = EnumDef.EBASE_STATE.CAN_SKILL
    	local CAN_NORMAL_SKILL = EnumDef.EBASE_STATE.CAN_NORMAL_SKILL
		if oldState[CAN_SKILL] ~= newState[CAN_SKILL] or oldState[CAN_NORMAL_SKILL] ~= newState[CAN_NORMAL_SKILL] then
			local SkillStateUpdateEvent = require "Events.SkillStateUpdateEvent"
			CGame.EventManager:raiseEvent(nil, SkillStateUpdateEvent())
		end
	end
end

def.method().Release = function(self)
	self._Host = nil
	self._StatesList = {}
end

CSkillSealInfo.Commit()
return CSkillSealInfo