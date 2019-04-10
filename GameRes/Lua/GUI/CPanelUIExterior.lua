--功能界面：外观
--时间：2017/8/25
--Add by Yao

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIExterior = Lplus.Extend(CPanelBase, "CPanelUIExterior")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelUIExterior.define

local CPageRide = require "GUI.CPageRide"
local CPageWing = require "GUI.CPageWing"
local CPageDress = require "GUI.CPageDress"
local CElementData = require "Data.CElementData"
local CExteriorMan = require "Main.CExteriorMan"
local net = require "PB.net"

local PackageChangeEvent = require "Events.PackageChangeEvent"
local NotifyFunctionEvent = require "Events.NotifyFunctionEvent"

local instance = nil
def.static("=>", CPanelUIExterior).Instance = function ()
	if instance == nil then
		instance = CPanelUIExterior()
		instance._PrefabPath = PATH.UI_Exterior
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance:SetupSortingParam()
	end
	return instance
end

def.field(CPageRide)._RidePage = nil -- 坐骑
def.field(CPageWing)._WingPage = nil -- 翅膀
def.field(CPageDress)._DressPage = nil -- 时装

--------------测试用，之后删--------------
def.field("userdata")._Frame_CameraDebug = nil
def.field("boolean")._IsOpenDebug = true
def.field("userdata")._InputField_Yaw = nil
def.field("userdata")._InputField_Pitch = nil
def.field("userdata")._InputField_Dist = nil
def.field("userdata")._InputField_Height = nil
-----------------------------------------

def.field("userdata")._TweenMan = nil
def.field("table")._Rdo_Group = BlankTable
def.field("table")._ImgTable_RedPoint = BlankTable
def.field("table")._FrameTable_RdoLock = BlankTable
def.field("table")._Frame_Group = BlankTable
def.field("userdata")._TipPosition = nil
def.field("userdata")._Frame_RightTips = nil
def.field("userdata")._Lab_RightTips = nil
def.field("userdata")._Btn_Show = nil

def.field("table")._ETweenType = BlankTable
def.field("table")._ExteriorTable = BlankTable
def.field("number")._CurFrameType = 0
def.field("dynamic")._CurPageClass = nil
def.field("boolean")._IsPlayingDoTween = false		-- 是否正在播放动效
def.field("function")._OnTweenCompleteCallback = nil

local ExteriorPageType =
{
	_Ride	= 1,	-- 坐骑
	_Dress	= 2,	-- 时装
	_Wing	= 3,	-- 翅膀
}

-- 功能对应到教学功能模版TID，写死
local Page2FuncTid =
{
	[ExteriorPageType._Ride] = 21,
	[ExteriorPageType._Dress] = 22,
	[ExteriorPageType._Wing] = 23,
}

def.override().OnCreate = function (self)
	self._TweenMan = self:GetUIObject("Frame_TweenMan"):GetComponent(ClassType.DOTweenPlayer)
	for _, v in pairs(ExteriorPageType) do
		self._Frame_Group[v] = self:GetUIObject("Frame_" .. v)
		local rdoObj = self:GetUIObject("Rdo_Main_" .. v)
		self._ImgTable_RedPoint[v] = rdoObj:FindChild("Img_RedPoint")
		self._FrameTable_RdoLock[v] = rdoObj:FindChild("Frame_Lock")
		self._Rdo_Group[v] = rdoObj:GetComponent(ClassType.Toggle)
	end
	for _, v in pairs(self._Frame_Group) do
		v:SetActive(false)
	end
	self._TipPosition = self:GetUIObject("TipPositionExterior")
	self._Frame_RightTips = self:GetUIObject("Frame_RightTips")
	self._Lab_RightTips = self:GetUIObject("Lab_RightTips")
	self._Btn_Show = self:GetUIObject("Btn_Show")
	self._Frame_RightTips:SetActive(true)
	GUITools.SetUIActive(self._Frame_RightTips, false)
	self._Btn_Show:SetActive(false)

	self._RidePage = CPageRide.new(self, self._Frame_Group[ExteriorPageType._Ride])
	self._WingPage = CPageWing.new(self, self._Frame_Group[ExteriorPageType._Wing])
	self._DressPage = CPageDress.new(self, self._Frame_Group[ExteriorPageType._Dress])

	self._ExteriorTable =
	{
		[ExteriorPageType._Ride] = self._RidePage,
		[ExteriorPageType._Wing] = self._WingPage,
		[ExteriorPageType._Dress] = self._DressPage,
	}

	self._ETweenType = 
	{
		MoveOut = "1",
		MoveIn = "2"
	}

	--------------测试用，之后删--------------
	self._Frame_CameraDebug = self:GetUIObject("Frame_CameraDebug")
	GUITools.SetUIActive(self._Frame_CameraDebug, false)
	self._IsOpenDebug = false
    local InputField = ClassType.InputField
    self._InputField_Yaw = self:GetUIObject("InputField_Yaw"):GetComponent(InputField)
    self._InputField_Pitch = self:GetUIObject("InputField_Pitch"):GetComponent(InputField)
    self._InputField_Dist = self:GetUIObject("InputField_Dist"):GetComponent(InputField)
    self._InputField_Height = self:GetUIObject("InputField_Height"):GetComponent(InputField)
    --------------------------------------
end

-- 更新页签红点
local function UpdatePageRedPoint(self, pageType)
	local pageClass = self._ExteriorTable[pageType]
	local img_red_point = self._ImgTable_RedPoint[pageType]
	if pageClass ~= nil and not IsNil(img_red_point) then
		local isUnlock = game._CFunctionMan:IsUnlockByFunTid(Page2FuncTid[pageType])
		local bShow = isUnlock and pageClass:IsPageHasRedPoint()
		GUITools.SetUIActive(img_red_point, bShow)
	end
end

-- 更新页签解锁状态
local function UpdatePageLockState(self, pageType, isLock)
	local frame_lock = self._FrameTable_RdoLock[pageType]
	if not IsNil(frame_lock) then
		GUITools.SetUIActive(frame_lock, isLock)
	end
end

-- 监听背包物品变化
local function OnPackageChangeEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		if event.PackageType == net.BAGTYPE.BACKPACK then
			if instance._CurFrameType == ExteriorPageType._Dress then
				instance._DressPage:OnPackageChangeEvent()
			end
		end
	end
end

-- 监听功能解锁
local function OnNotifyFunctionEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		for pageType, tid in pairs(Page2FuncTid) do
			if event.FunID == tid then
				UpdatePageLockState(instance, pageType, false)
				UpdatePageRedPoint(instance, pageType)
				break
			end
		end
	end
end

-- 更新系统菜单红点
local function UpdateMainMenuRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Exterior, CExteriorMan.Instance():IsShowRedPoint())
end

def.override("dynamic").OnData = function(self, data)
	local openType = ExteriorPageType._Ride -- 默认打开坐骑页面
	local camType = CExteriorMan.Instance():GetEnterCamType()
	if camType == EnumDef.CamExteriorType.Wing then
		openType = ExteriorPageType._Wing
	elseif camType > EnumDef.CamExteriorType.Wing then
		openType = ExteriorPageType._Dress
		data = camType
	end

	if IsNil(self._Rdo_Group[openType]) then
		warn("UI_Exterior找不到" .. openType .. "底页签")
		return
	end
	self._CurFrameType = openType
	self._Rdo_Group[openType].isOn = true
	self:ShowFrame(openType, data)
	self:SetRdoRedPoint()
	self:SetRdoLockState()
	self:RestartDoTween(self._ETweenType.MoveIn, nil)

	CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
	CGame.EventManager:addHandler(NotifyFunctionEvent, OnNotifyFunctionEvent)
end

-- 设置页签红点
def.method().SetRdoRedPoint = function (self)
	for _, pageType in pairs(ExteriorPageType) do
		UpdatePageRedPoint(self, pageType)
	end
end

-- 设置页签红点
def.method().SetRdoLockState = function (self)
	for _, pageType in pairs(ExteriorPageType) do
		local fun_tid = Page2FuncTid[pageType]
		local isLock = not game._CFunctionMan:IsUnlockByFunTid(fun_tid)
		UpdatePageLockState(self, pageType, isLock)
	end
end

def.method("number", "dynamic").ShowFrame = function (self, openType, uiData)
	if not IsNil(self._Frame_Group[openType]) then
		self._Frame_Group[openType]:SetActive(true)
	end
   
	if self._ExteriorTable[openType] == nil then
		self._CurPageClass = nil
		warn("UIExterior dont have this class, type:", openType)
		return
	end
	self._CurPageClass = self._ExteriorTable[openType]
	self._CurPageClass:Show(uiData)

	UpdateMainMenuRedPoint()

	CPanelBase.OnData(self,nil)
end

def.method().HideFrame = function (self)
	if not IsNil(self._Frame_Group[self._CurFrameType]) then
		self._Frame_Group[self._CurFrameType]:SetActive(false)
	end
	if self._CurPageClass ~= nil then
		self._CurPageClass:Hide()
	end
end

def.override("string").OnClick = function(self, id)
	CPanelBase.OnClick(self,id)
    if string.find(id, "Btn_Back") then
		CExteriorMan.Instance():Quit()
	elseif string.find(id, "Btn_Exit") then
		CExteriorMan.Instance():Quit()
		game._GUIMan:CloseSubPanelLayer()
	elseif string.find(id, "Btn_Hide") then
		self:RestartDoTween(self._ETweenType.MoveOut, function()
			GameUtil.EnableBlockCanvas(false)
			self._Btn_Show:SetActive(true)
		end)
	elseif string.find(id, "Btn_Show") then
		self._Btn_Show:SetActive(false)
		self:RestartDoTween(self._ETweenType.MoveIn, nil)
	--------------策划调试用，之后删----------
	elseif string.find(id, "Btn_CameraDebug") then
		self._IsOpenDebug = not self._IsOpenDebug
		GUITools.SetUIActive(self._Frame_CameraDebug, self._IsOpenDebug)
    elseif string.find(id, "Btn_YawLeft") then
        GameUtil.AddOrSubForTest(1, false)
    elseif string.find(id, "Btn_YawRight") then
        GameUtil.AddOrSubForTest(1, true)
    elseif string.find(id, "Btn_PitchUp") then
        GameUtil.AddOrSubForTest(2, false)
    elseif string.find(id, "Btn_PitchDown") then
        GameUtil.AddOrSubForTest(2, true)
    elseif string.find(id, "Btn_DistanceUp") then
        GameUtil.AddOrSubForTest(3, true)
    elseif string.find(id, "Btn_DistanceDown") then
        GameUtil.AddOrSubForTest(3, false)
    elseif string.find(id, "Btn_HeightUp") then
        GameUtil.AddOrSubForTest(4, true)
    elseif string.find(id, "Btn_HeightDown") then
        GameUtil.AddOrSubForTest(4, false)
    elseif string.find(id, "Btn_Change") then
        local yawDeg = tonumber(self._InputField_Yaw.text)
        local pitchDeg = tonumber(self._InputField_Pitch.text)
        local distance = tonumber(self._InputField_Dist.text)
        local height = tonumber(self._InputField_Height.text)
        if yawDeg == nil or pitchDeg == nil or distance == nil or height == nil then
            return
        end
        GameUtil.SetExteriorDebugParams(yawDeg, pitchDeg, distance, height)
    -----------------------------------------

	else
		self._CurPageClass:OnExteriorClick(id)
	end
end

def.method("number").ChangeFrame = function(self, openType)
	-- 特殊处理Toggle显示
	if self._Rdo_Group[self._CurFrameType] ~= nil then
		self._Rdo_Group[self._CurFrameType].isOn = true
	end
	-- 通知各个页签
	self._CurPageClass:OnChangeFrame()
	-- 镜头
	local camType = nil
	local destPageClass = self._ExteriorTable[openType] -- 目标页签类
	if destPageClass ~= nil then
		camType = destPageClass:GetCurCamType()
	end
	if camType ~= nil then
		local horseId = 0
		if self._RidePage ~= nil then
			horseId = self._RidePage:GetSelectedHorseId()
		end
		CExteriorMan.ChangeCamParams(camType, horseId)
	end
	-- 动效
	self:RestartDoTween(self._ETweenType.MoveOut, function()
		-- 页签之间切换
		self:HideFrame()

		self._CurFrameType = openType
		if self._Rdo_Group[openType] ~= nil then
			self._Rdo_Group[openType].isOn = true
		end
		self:ShowFrame(openType, nil)
		UpdatePageRedPoint(self, openType) -- 更新新页签的红点

		self:RestartDoTween(self._ETweenType.MoveIn, nil)
	end)
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if string.find(id, "Rdo_Main_") then
		-- 一级页签
		if checked then
			local pageType = tonumber(string.sub(id, string.len("Rdo_Main_")+1, -1))
			if pageType == nil or pageType == self._CurFrameType then return end

			local fun_tid = Page2FuncTid[pageType]
			if not game._CFunctionMan:IsUnlockByFunTid(fun_tid) then
				-- 功能未解锁
				game._CGuideMan:OnShowTipByFunUnlockConditions(0, fun_tid)
				local rdo = self._Rdo_Group[self._CurFrameType]
				if rdo ~= nil then
					rdo.isOn = true
				end
			else
				self:ChangeFrame(pageType)
			end
		end
	else
		self._CurPageClass:OnExteriorToggle(id, checked)
	end
	CPanelBase.OnToggle(self, id, checked)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	self._CurPageClass:OnExteriorInitItem(item, id, index)
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	self._CurPageClass:OnExteriorSelectItem(item, id, index)
end

def.override("string", "number").OnDropDown = function(self, id, index)
    self._CurPageClass:OnExteriorDropDown(id, index)
end

--DOTTween CallBack here
def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	--特例 不掉 CPanelBase.OnDOTComplete(self,go_name,dot_id)

	self._IsPlayingDoTween = false

	if dot_id == self._ETweenType.MoveOut then
		if self._OnTweenCompleteCallback ~= nil then
			self._OnTweenCompleteCallback()
			self._OnTweenCompleteCallback = nil
		end
	elseif dot_id == self._ETweenType.MoveIn then
		GameUtil.EnableBlockCanvas(false)
		if self._OnTweenCompleteCallback ~= nil then
			self._OnTweenCompleteCallback()
			self._OnTweenCompleteCallback = nil
		end
		game._CGuideMan:AnimationEndCallBack(self)
	end
end

def.method("string", "function").RestartDoTween = function(self, dot_id, callback)
	if self._IsPlayingDoTween then return end

	GameUtil.EnableBlockCanvas(true) -- 阻挡点击
	self._IsPlayingDoTween = true
	if self._OnTweenCompleteCallback == nil then
		self._OnTweenCompleteCallback = callback
	end

	self._TweenMan:Restart(dot_id)
end

def.method().UpdateCurPageRedPoint = function (self)
	UpdatePageRedPoint(self, self._CurFrameType)
end
--------------------------------外部接口-----------------------------
-- 更新坐骑数据
def.method().UpdateRideData = function (self)
	self._RidePage:SetRideList()
	if self._CurFrameType == ExteriorPageType._Ride then
		self._RidePage:UpdateDataFromEvent()
	end
	
	UpdatePageRedPoint(self, ExteriorPageType._Ride)
	UpdateMainMenuRedPoint()
end

-- 更新翅膀列表
def.method().UpdateWingList = function (self)
	self._WingPage:SetWingList()
	if self._CurFrameType == ExteriorPageType._Wing then
		self._WingPage:UpdateDataFromEvent()
	end

	UpdatePageRedPoint(self, ExteriorPageType._Wing)
	UpdateMainMenuRedPoint()
end

-- 点击人物
def.method().ClickHostPlayer = function (self)
	if self._CurFrameType == ExteriorPageType._Ride then
		self._RidePage:ClickHostPlayer()
	end
end

-- 刷新时装列表
-- @param updateType 更新类型 0:列表初始化 1:添加时装 2:时装过期 3:时装分解 4:时装穿戴或卸下 5:时装染色
def.method("number").UpdateDressList = function(self, updateType)
    self._DressPage:InitShowData()
    if updateType == 1 then
    	self._DressPage:UpdateSelectDress(false)
    elseif updateType == 2 or updateType == 3 then
    	self._DressPage:UpdateSelectDress(true)
    end
	if self._CurFrameType == ExteriorPageType._Dress then
		self._DressPage:UpdateDressList()
	end

	UpdatePageRedPoint(self, ExteriorPageType._Dress)
	UpdateMainMenuRedPoint()
end

-- 尝试关闭界面
def.method().DoQuitTween = function (self)
	local function quit_exterior()
		CExteriorMan.Instance():OnQuitTweenComplete()
	end

	if not self._IsPlayingDoTween then
		self:RestartDoTween(self._ETweenType.MoveOut, quit_exterior)
	else
		-- 直接结束动效，关闭界面
		quit_exterior()
	end
end

-- 是否开启右边的提示
def.method("boolean").EnableRightTips = function (self, enable)
	GUITools.SetUIActive(self._Frame_RightTips, enable)
	if enable then
		local tipStr = StringTable.Get(22115)
		if self._CurFrameType == ExteriorPageType._Ride then
			tipStr = tipStr .. StringTable.Get(22112)
		elseif self._CurFrameType == ExteriorPageType._Dress then
			tipStr = tipStr .. StringTable.Get(22113)
		elseif self._CurFrameType == ExteriorPageType._Wing then
			tipStr = tipStr .. StringTable.Get(22114)
		end
		GUI.SetText(self._Lab_RightTips, tipStr)
	end
end

-------------------------------------------------------------------

def.override("=>","boolean").HandleEscapeKey=function(self)
	CExteriorMan.Instance():Quit()
	return true
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
	if self._CurPageClass ~= nil then
		self._CurPageClass:Hide()
	end
	CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
	CGame.EventManager:removeHandler(NotifyFunctionEvent, OnNotifyFunctionEvent)
end

def.override().OnDestroy = function (self)
	for _, v in pairs(self._ExteriorTable) do
		v:Destroy()
		v = nil
	end
	self._ExteriorTable = {}
	self._CurPageClass = nil
	self._IsPlayingDoTween = false
	self._OnTweenCompleteCallback = nil

	self._Frame_CameraDebug = nil
	self._IsOpenDebug = false
	self._InputField_Yaw = nil
	self._InputField_Pitch = nil
	self._InputField_Dist = nil
	self._InputField_Height = nil

	self._TweenMan = nil
	self._Rdo_Group = {}
	self._ImgTable_RedPoint = {}
	self._FrameTable_RdoLock = {}
	self._Frame_Group = {}
	self._TipPosition = nil
	self._Frame_RightTips = nil
	self._Lab_RightTips = nil
	self._Btn_Show = nil
end

CPanelUIExterior.Commit()
return CPanelUIExterior