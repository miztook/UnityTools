local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = Lplus.ForwardDeclare("CEntity")
local CElementData = require "Data.CElementData"

local CCooldownHdl = Lplus.Class("CCooldownHdl")
local def = CCooldownHdl.define

-- def.field(CEntity)._Host = nil
def.field("table")._CDList = nil

def.static(CEntity, "=>", CCooldownHdl).new = function (host)
	local obj = CCooldownHdl()
	-- obj._Host = host
	return obj
end

def.method("number", "number", "number", "number").UpdateData = function(self, cd_id, accumulate_count, elapsed_time, max_time)
	if self._CDList == nil then self._CDList = {} end
	-- if self._CDList[cd_id] ~= nil then
	-- 	if self._CDList[cd_id].ID ~= nil and self._CDList[cd_id].ID ~= 0 then
	-- 		self._Host:RemoveTimer(self._CDList[cd_id].ID)
	-- 		self._CDList[cd_id].ID = 0
	-- 	end
	-- else
	-- 	self._CDList[cd_id] = {}
	-- end
	if self._CDList[cd_id] == nil then
		self._CDList[cd_id] = {}
	end

	self._CDList[cd_id].StartTime = Time.time
	self._CDList[cd_id].AccumulateCount = accumulate_count
	self._CDList[cd_id].ElapsedTime = elapsed_time
	self._CDList[cd_id].MaxTime = max_time
	-- if accumulate_count == 0 then
	-- 	self._CDList[cd_id].ID = self._Host:AddTimer((max_time - elapsed_time)/1000, true, function()
	-- 				self._CDList[cd_id] = nil
	-- 			end)
	-- end
	local cooldown = CElementData.GetTemplate("Cooldown", cd_id)

	if accumulate_count >= cooldown.MaxAccumulateCount then
		self._CDList[cd_id] = nil
	end
	
end

def.method("number", "=>", "boolean").IsCoolingDown = function(self, cd_id)
	return (self._CDList ~= nil and self._CDList[cd_id] ~= nil and self._CDList[cd_id].AccumulateCount == 0) --and self._CDList[cd_id].ID ~= nil and self._CDList[cd_id].ID ~= 0
end

def.method("number", "=>", "number", "number").GetCurInfo = function(self, cd_id)
	if self._CDList == nil or self._CDList[cd_id] == nil or self._CDList[cd_id].AccumulateCount > 0 then --or self._CDList[cd_id].ID == 0 
		return 0, 1
	end

	local v = self._CDList[cd_id]
	return (Time.time - v.StartTime)*1000 + v.ElapsedTime, v.MaxTime
end

def.method("number", "=>", "number").GetAccumulateCount = function(self, cd_id)
	if self._CDList ~= nil and self._CDList[cd_id] ~= nil then
		return self._CDList[cd_id].AccumulateCount
	else
		local maxCount = 1
		local cooldown = CElementData.GetTemplate("Cooldown", cd_id)
		if cooldown ~= nil then maxCount = cooldown.MaxAccumulateCount end
		return maxCount
	end
end

def.method().Release = function (self)
	if self._CDList ~= nil then
		-- for k,v in pairs(self._CDList) do
		-- 	if v ~= 0 then
		-- 		self._Host:RemoveTimer(k)
		-- 	end
		-- end
		self._CDList = nil
	end
	
	local SkillCDEvent = require "Events.SkillCDEvent"
	local event = SkillCDEvent()
	CGame.EventManager:raiseEvent(nil, event)
	-- self._Host = nil
end

CCooldownHdl.Commit()
return CCooldownHdl
