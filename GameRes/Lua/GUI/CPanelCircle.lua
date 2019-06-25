--
--网络连接等界面提示
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"

local CPanelCircle = Lplus.Extend(CPanelBase, "CPanelCircle")
local def = CPanelCircle.define

local rotation = Vector3.New(0, 0, -180)
local rotationTime = 0.4
--单纯只有文字提示时展示时间
local showTime = 2
local timerId = 0

--例子:game._GUIMan:Open("CPanelCircle", { text = "测试", show = false})

local instance = nil
def.static("=>", CPanelCircle).Instance = function()
	if not instance then
		instance = CPanelCircle()
		instance._PrefabPath = PATH.Panel_Circle
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
		instance._ForbidESC = true

        instance:SetupSortingParam()
	end
	return instance
end

--数据
def.override("dynamic").OnData = function(self, data)
	local bg = self._Panel:FindChild("Img_BG")
	local circle = self._Panel:FindChild("Img_Circle")
	local lab = self._Panel:FindChild("Lab")
	if data.show then
		circle:SetActive(true)
		bg:GetComponent(ClassType.RectTransform).sizeDelta = Vector2.zero
		lab:GetComponent(ClassType.RectTransform).anchoredPosition = Vector3.New(0, -45, 0)
		GameUtil.DoLoopRotate(circle, rotation, rotationTime)
	else
		circle:SetActive(false)
		bg:GetComponent(ClassType.RectTransform).sizeDelta = Vector2.New(200, 100)
		lab:GetComponent(ClassType.RectTransform).anchoredPosition = Vector3.zero
		local callback = function()
			game._GUIMan:Close("CPanelCircle")
			timerId = 0
		end
		if timerId == 0 then
			timerId = _G.AddGlobalTimer(showTime, true, callback)
		end
	end
	lab:GetComponent(ClassType.Text).text = data.text	
end

def.override().OnDestroy = function(self)
	if timerId ~= 0 then
		_G.RemoveGlobalTimer(timerId)
		timerId = 0
	end

	--instance = nil --destroy
end

CPanelCircle.Commit()
return CPanelCircle