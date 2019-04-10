-- buff 修改跟随相机视心高度
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CBuffEventBase = require "Skill.BuffEvent.CBuffEventBase"

local CBuffCameraHeightOffset = Lplus.Extend(CBuffEventBase, "CBuffCameraHeightOffset")
local def = CBuffCameraHeightOffset.define

def.static("table", "table", "=>", CBuffCameraHeightOffset).new = function(host, event)
	if host == nil or host._ID ~= game._HostPlayer._ID then return nil end

	local obj = CBuffCameraHeightOffset()
	obj._Event  = event
	return obj
end

def.override().OnEvent = function(self)
	local event = self._Event
	GameUtil.SetGameCamHeightOffsetInterval(event.CameraHeightOffset.minValue, event.CameraHeightOffset.maxValue, false)
end

def.override().OnBuffEnd = function(self)
	local hp = game._HostPlayer
	local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig"
	local heightOffsetMin, heightOffsetMax = ModuleProfDiffConfig.GetFollowCamViewPointHeightOffsetInterval(hp._InfoData._Prof, hp:IsOnRide())
	GameUtil.SetGameCamHeightOffsetInterval(heightOffsetMin, heightOffsetMax, true)

	CBuffEventBase.OnBuffEnd(self)
end

CBuffCameraHeightOffset.Commit()
return CBuffCameraHeightOffset