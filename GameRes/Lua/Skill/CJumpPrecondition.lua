local Lplus = require "Lplus"
local CElementSkill = require "Data.CElementSkill"
local CJumpPrecondition = Lplus.Class("CJumpPrecondition")

local def = CJumpPrecondition.define

local _Preconditions = {}

_Preconditions[0] = function(param)   -- 直接跳转
						return true 
					end   

_Preconditions[1] = function(param)   -- 连击跳转
						--do return true end
						do return game._HostPlayer._SkillHdl:CanTriggerCombo() end 
					end   

_Preconditions[2] = function(param)   -- 蓄力跳转
						local charged_time = game._HostPlayer._SkillHdl._ChargingTimeLen
						--warn("charge judge", charged_time,  param)
						return charged_time >  param/1000
					end

_Preconditions[3] = function(param)   -- 技能消耗连击点数量 跳转
						local consume_count = game._HostPlayer._SkillHdl._ConsumeCombo
						return consume_count ==  param
					end

_Preconditions[4] = function(param)   -- 有某个状态时 跳转
						local state_id = param
						return game._HostPlayer:HasState(state_id)
					end

_Preconditions[100] = function(param)   -- 概率跳转
						if type(param) ~= "number" then
							warn("Jump Precondition param is ERROR")
							return false
						end
						local r = math.random(100)
						return r < param
					end  

def.static("number", "dynamic", "=>", "boolean").Check = function (id, param)
	if _Preconditions[id] == nil then
		warn("can not find jump check precondition with id ", id)
		return false
	end
	return _Preconditions[id](param)
end

CJumpPrecondition.Commit()
return CJumpPrecondition