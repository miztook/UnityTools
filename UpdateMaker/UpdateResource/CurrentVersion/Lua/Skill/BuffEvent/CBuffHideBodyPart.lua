-- buff 闪烁事件基类
local Lplus = require "Lplus"
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"

local CBuffHideBodyPart = Lplus.Extend(CBuffEventBase, "CBuffHideBodyPart")
local def = CBuffHideBodyPart.define

def.static("table", "table", "=>", CBuffHideBodyPart).new = function(host, event)
	local obj = CBuffHideBodyPart()
	obj._Event = event
	obj._Host = host
	return obj
end

def.override().OnEvent = function(self)
	local entity = self._Host
	if entity ~= nil and entity:IsReleased() then		
		local md = entity:GetCurModel()
		GameUtil.ChangePartMesh(md:GetGameObject(), self._Event.HideBodyPart.Part + 1, false)
	end
end

CBuffHideBodyPart.Commit()
return CBuffHideBodyPart