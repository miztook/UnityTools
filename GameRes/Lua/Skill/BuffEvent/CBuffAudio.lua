local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"

local CBuffAudio = Lplus.Extend(CBuffEventBase, "CBuffAudio")
local def = CBuffAudio.define

def.field("string")._AsName = ""

def.static("table", "table", "=>", CBuffAudio).new = function(host, event)
	local obj = CBuffAudio()
	obj._Event = event
	obj._Host = host
	return obj
end

def.override().OnEvent = function(self)
	local entity = self._Host
	if entity == nil or entity:IsReleased() then return end

	local go = entity:GetGameObject()	
	if go == nil then return end

	self._AsName = CSoundMan.Instance():PlayAttached3DAudio(self._Event.Audio.AssetPath, go, 0)
end

def.override().OnBuffEnd = function(self)	
	if self._AsName ~= "" then
	    CSoundMan.Instance():Stop3DAudio(self._Event.Audio.AssetPath, self._AsName)
	end

	CBuffEventBase.OnBuffEnd(self)
end

CBuffAudio.Commit()
return CBuffAudio