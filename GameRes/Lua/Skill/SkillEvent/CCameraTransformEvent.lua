local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CVisualEffectMan = require "Effects.CVisualEffectMan"
local CameraTransformType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventCameraTransform.CameraTransformType

local CCameraTransformEvent = Lplus.Extend(CSkillEventBase, "CCameraTransformEvent")
local def = CCameraTransformEvent.define

def.field("number")._TimerId = 0
def.field("boolean")._NeedResetCam = false

def.static("table","table", "=>", CCameraTransformEvent).new = function (event, params)
	local obj = CCameraTransformEvent()
	obj._Params = params
	obj._Event = event.CameraTransform
	return obj
end

def.override().OnEvent = function(self)
	local camMode = GameUtil.GetGameCamCtrlMode() 
	if camMode == EnumDef.CameraCtrlMode.FIX25D then return end

	self._NeedResetCam = true

	if self._Event.Type == CameraTransformType.ChangeCameraDistance then
		CVisualEffectMan.MoveOrRotateCamera(self._Event.Distance, self._Event.ChangeDuration/1000 , self._Event.KeepDuration/1000 , self._Event.ChangeBackDuration/1000 )
	elseif self._Event.Type  == CameraTransformType.ResetCamera then

	elseif self._Event.Type  == CameraTransformType.ChangeCameraAngle then
		local hp = game._HostPlayer
		if camMode == EnumDef.CameraCtrlMode.FOLLOW then
			local duration = (self._Event.ChangeDuration + self._Event.KeepDuration + self._Event.ChangeBackDuration) / 1000 
			GameUtil.SetSkillActCamMode( hp:GetGameObject(), self._Event.AngleOffset, self._Event.Distance, self._Event.ChangeDuration /1000 , self._Event.OriAngle)
			self._TimerId = hp:AddTimer(duration, true, function()
					GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
					GameUtil.SetCamToDefault(true, true, false, true)		
					self._TimerId = 0	
				end)
		end
	end
end

def.override("=>", "number").GetLifeTime = function(self)
	if self._Event == nil then return 0 end
	return (self._Event.ChangeDuration + self._Event.KeepDuration + self._Event.ChangeBackDuration) / 1000
end

-- 释放屏幕效果
def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if not self._NeedResetCam then 
		CSkillEventBase.OnRelease(self, ctype)
		return true 
	end

	if self._Event.Type  == CameraTransformType.ChangeCameraDistance then
		local entity = self._Params.BelongedCreature
		if entity == nil or entity:IsReleased() then
			CVisualEffectMan.StopCameraStretch()
			CSkillEventBase.OnRelease(self, ctype)
			return true
		end

		local stopNow = (ctype == EnumDef.EntitySkillStopType.PerformEnd and self._Event.FinishConditionPerformEnd)
					or (ctype == EnumDef.EntitySkillStopType.SkillEnd and self._Event.FinishConditionSkillEnd)
					or (ctype == EnumDef.EntitySkillStopType.LifeEnd)
		if stopNow then
			CVisualEffectMan.StopCameraStretch()
			CSkillEventBase.OnRelease(self, ctype)
			return true
		else
			return false
		end	
	end	
	
	if self._Event.Type  == CameraTransformType.ChangeCameraAngle then
		if self._TimerId > 0 then
			game._HostPlayer:RemoveTimer(self._TimerId)	
		end

		if GameUtil.GetGameCamCtrlMode() == EnumDef.CameraCtrlMode.FOLLOW then
			GameUtil.SetCameraParams(EnumDef.CAM_CTRL_MODE.GAME)
			GameUtil.SetCamToDefault(true, true, false, true)
		end
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CCameraTransformEvent.Commit()
return CCameraTransformEvent
