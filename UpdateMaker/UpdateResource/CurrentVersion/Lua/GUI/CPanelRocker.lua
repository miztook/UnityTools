local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelRocker = Lplus.Extend(CPanelBase, "CPanelRocker")

local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelRocker.define

def.field("userdata")._BtnRide = nil
def.field("boolean")._IsRideBtnHideByDrag = false
def.field("userdata")._JoyStick = nil

local instance = nil

def.final("=>", CPanelRocker).Instance = function()
	if not instance then
		instance = CPanelRocker()
		instance._PrefabPath = PATH.Panel_Main_Move
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

-- 刷新坐骑按钮
local function OnChangeShapeEvent(sender, event)
	if instance then
		--主界面：坐骑功能未开启，隐藏按钮			
		instance:UpdateHorseBtnState()
	end
end

local function OnNotifyFunctionEvent(sender, event)
	if instance then
		if event.FunID == EnumDef.EGuideTriggerFunTag.Mount then
			instance:UpdateHorseBtnState()
		end
	end
end

local function OnRegionLimitChangeEvent(sender, event)
	-- 区域限制
	if instance then
		instance:UpdateHorseBtnState()
	end
end

def.override().OnCreate = function(self)
	self._BtnRide = self:GetUIObject('Btn_Ride')
	self._JoyStick = self:GetUIObject('Joystick')	
	self:UpdateHorseBtnState()

	CGame.EventManager:addHandler("ChangeShapeEvent", OnChangeShapeEvent)
	CGame.EventManager:addHandler("NotifyFunctionEvent", OnNotifyFunctionEvent)
	CGame.EventManager:addHandler("RegionLimitChangeEvent", OnRegionLimitChangeEvent)
end

def.override("dynamic").OnData = function(self,data)
	CPanelBase.OnData(self,data)
end


def.override("string").OnClick = function(self, id)
	if id == "Btn_Ride" then
		-- 副本内允许上马 by 吴游 2019.1.3
		-- if game._HostPlayer:InDungeon() then
		-- 	game._GUIMan:ShowTipText( StringTable.Get( 15551 ), false)
		-- 	return
		-- end

		if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Mount) then
			game._GUIMan:ShowTipText( StringTable.Get( 15506 ), false)
			return
		end

		local hp = game._HostPlayer
		hp._CanNotifyErrorMountHorse = true
		if hp:GetCurrentHorseId() > 0 then
			local bIsOn = not hp:IsServerMounting()
			if bIsOn then
				-- 上马
				if not hp:CanRide() then return end

				if hp:IsInCanInterruptSkill() then
					-- 中断特殊技能
					hp._SkillHdl:StopCurActiveSkill(true)
				end
			end
			
			SendHorseSetProtocol(-1, bIsOn)
		else
			game._GUIMan:ShowTipText( StringTable.Get( 15505 ), false)
		end
	end
end

-- 设置按钮状态
def.method().UpdateHorseBtnState = function(self)	
	if self._BtnRide == nil then return end

	-- 功能未开启
	local shown = not self._IsRideBtnHideByDrag
					and game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.Mount)
					and not game._RegionLimit._LimitRide
					and not game._HostPlayer:IsModelChanged()

	self._BtnRide:SetActive(shown)
end

def.method("=>", "number", "number").GetCurAxis = function(self)
	local x, y = 0,0
	if IsNil(self._Panel) then
		warn("error: Joystick panel is missing")
	else
		local joystick_obj = self._JoyStick
		
		if not IsNil(joystick_obj) then
			x, y = GameUtil.GetJoystickAxis(joystick_obj)
		else
			warn("error: Joystick is missing",debug.traceback())
		end
	end	

	return x, y
end

def.method("boolean").HideUIByDrag = function(self, isHide)
	if self._IsRideBtnHideByDrag == isHide then return end
	self._IsRideBtnHideByDrag = isHide 
	self:UpdateHorseBtnState()
end

--DOTTween CallBack here
def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	CPanelBase.OnDOTComplete(self,go_name,dot_id)

	if dot_id == "1" or dot_id == "2" then
		-- 主界面动效
		game._GUIMan:OnMainUITweenComplete("CPanelRocker")
	end
end

def.override().OnDestroy = function(self)
	--instance
	CGame.EventManager:removeHandler("ChangeShapeEvent", OnChangeShapeEvent)
	CGame.EventManager:removeHandler("NotifyFunctionEvent", OnNotifyFunctionEvent)	
	CGame.EventManager:removeHandler("RegionLimitChangeEvent", OnRegionLimitChangeEvent)
end

CPanelRocker.Commit()
return CPanelRocker
