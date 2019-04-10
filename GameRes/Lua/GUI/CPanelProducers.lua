local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelProducers = Lplus.Extend(CPanelBase, "CPanelProducers")
local def = CPanelProducers.define

local instance = nil

def.field('userdata')._Frame_All = nil
def.field('userdata')._Rc_Frame_All = nil
-- def.field('userdata')._Go_ResetPos = nil
def.field('userdata')._Rc_ScrollView = nil
def.static("=>", CPanelProducers).Instance = function()
	if not instance then
		instance = CPanelProducers()
		instance._LoadAssetFromBundle = true
		instance._PrefabPath = PATH.Panel_Producers
		instance._DestroyOnHide = true
		instance:SetupSortingParam()
	end
	return instance
end

local BEGIN_DELAY = 1
local DIST_BORDER = 40
local startPos
local endPos
local speed = 70
local dur = 1

def.field('number')._TimerId = -1

def.override().OnCreate = function(self)
	if IsNil(self._Panel) then return end
	self._Frame_All = self:GetUIObject('Frame_All')
	self._Rc_Frame_All = self._Frame_All:GetComponent(ClassType.RectTransform)
	-- self._Go_ResetPos = self:GetUIObject('ResetPos')
	self._Rc_ScrollView = self:GetUIObject('Scroll_View'):GetComponent(ClassType.RectTransform)

	local h = self._Rc_ScrollView.rect.height + self._Rc_Frame_All.rect.height
	startPos = Vector3.New(0, - DIST_BORDER, 0)
	endPos = Vector3.New(0, h + DIST_BORDER, 0)
	dur = (endPos.y - startPos.y) / speed

	self:Restart()
end

def.method().Restart = function(self)
	if self._TimerId > 0 then
		_G.RemoveGlobalTimer(self._TimerId)
		self._TimerId=0
	end

	--warn(" ".. tostring(endPos)..", "..dur)

	self._TimerId = _G.AddGlobalTimer(BEGIN_DELAY, true, function()
		self._Frame_All.localPosition = startPos
		GameUtil.DoLocalMove(self._Frame_All, endPos, dur, EnumDef.Ease.Linear, function()
			self:Restart()
		end )
	end )
end

def.override().OnDestroy = function(self)
	if self._TimerId > 0 then
		_G.RemoveGlobalTimer(self._TimerId)
	end

	self._Frame_All = nil
	self._Rc_Frame_All = nil
	self._Rc_ScrollView = nil
end

-- def.override("dynamic").OnData = function(self,data)
-- 	if data == nil then return end
-- end

def.override("string").OnClick = function(self, id)
	if id == "BackBtn" then
		game._GUIMan:CloseByScript(self)
	end
end

CPanelProducers.Commit()
return CPanelProducers