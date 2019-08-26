local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CEntity = Lplus.ForwardDeclare("CEntity")
local CCloakEvent = Lplus.Extend(CSkillEventBase, "CCloakEvent")
local def = CCloakEvent.define

def.static("table", "table", "=>", CCloakEvent).new = function (event, params)
	local obj = CCloakEvent()
	obj._Event = event.Cloak
	obj._Params = params
	return obj
end

def.override().OnEvent = function(self)
	local caster = self._Params.BelongedCreature
	if caster == nil or caster:IsReleased() then 
		return 
	end
	
	local fadein_time = self._Event.FadeinDuration
	local last_time = self._Event.KeepDuration
	local fadeout_time = self._Event.FadeoutDuration
	local total = fadein_time + last_time + fadeout_time
	
	--隐身后清楚当前选中目标
	caster:Stealth(true)
	game._HostPlayer:CancelTargetSelectedStatus(caster._ID)

	caster:AddTimer(total/1000, true, function()
			if not caster:IsReleased() and not caster:IsDead() then
				caster:Stealth(false)
        	end
		end)
end

CCloakEvent.Commit()
return CCloakEvent
