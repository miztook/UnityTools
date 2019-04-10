local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"

local CBulletTimeEvent = Lplus.Extend(CSkillEventBase, "CBulletTimeEvent")
local def = CBulletTimeEvent.define

def.field("number")._TimerId = 0

def.static("table", "table", "=>", CBulletTimeEvent).new = function(event, params)
	local obj = CBulletTimeEvent()
	obj._Event = event.BulletTime
	obj._Params = params
	--warn("CBulletTimeEvent new")
	return obj
end

local function ChangeGfxSpeed(caster, speed)
	local gfxs = caster._SkillHdl._GfxList
	if gfxs ~= nil and #gfxs > 0 then
		for i = 1, #gfxs do
			local gfx = gfxs[i].Gfx
			if gfx ~= nil then
				gfx:ChangeSpeed(speed)
			end
		end
	end
end

def.override().OnEvent = function(self)
	local caster = self._Params.BelongedCreature
	if caster:IsHostPlayer() then return end

	local speed = self._Event.SlowSpeed
	if speed < 0 then return end

	local go = caster:GetCurModel():GetGameObject()
	GameUtil.EnableAnimationBulletTime(go, true, speed)
	
	local hp = game._HostPlayer
	local go1 = hp:GetCurModel():GetGameObject()
	GameUtil.EnableAnimationBulletTime(go1, true, speed)

	-- 特效慢速
	ChangeGfxSpeed(caster, speed)

	local lastTime = self._Event.Duration/1000
	self._TimerId = caster:AddTimer(lastTime, true, function()
			if not caster:IsReleased() then
				local go = caster:GetCurModel():GetGameObject()
				GameUtil.EnableAnimationBulletTime(go, false, 0)
				ChangeGfxSpeed(caster, 1)
        	end
        	local hp = game._HostPlayer
			local go1 = hp:GetCurModel():GetGameObject()
			GameUtil.EnableAnimationBulletTime(go1, false, 0)

        	self._TimerId = 0
        	
        	--warn("CBulletTimeEvent End1 @ ", Time.time)
		end)
	--warn("CBulletTimeEvent OnEvent", speed, lastTime, "@", Time.time)
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return self._Event.Duration/1000
end

def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if self._TimerId ~= 0 then
		local caster = self._Params.BelongedCreature
		if not caster:IsReleased() then
			caster:RemoveTimer(self._TimerId)
			self._TimerId = 0
			
			ChangeGfxSpeed(caster, 1)
			
			local go = caster:GetCurModel():GetGameObject()
			GameUtil.EnableAnimationBulletTime(go, false, 0)
    	end
    	
    	local hp = game._HostPlayer
		local go1 = hp:GetCurModel():GetGameObject()
		GameUtil.EnableAnimationBulletTime(go1, false, 0)
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CBulletTimeEvent.Commit()
return CBulletTimeEvent
