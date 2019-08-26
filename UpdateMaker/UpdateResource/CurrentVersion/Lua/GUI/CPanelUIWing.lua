-- 飞翼养成
-- 2018/7/20

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIWing = Lplus.Extend(CPanelBase, "CPanelUIWing")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPanelUIWing.define

local CPageWingDevelop = require "GUI.CPageWingDevelop"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CWingsMan = require "Wings.CWingsMan"
local net = require "PB.net"

local PackageChangeEvent = require "Events.PackageChangeEvent"

def.field(CFrameCurrency)._Frame_Money = nil
def.field("table")._AllFrameTable = BlankTable
def.field("table")._AllRdoTable = BlankTable
def.field("table")._ImgTable_RedPoint = BlankTable

def.field(CPageWingDevelop)._DevelopPage = nil
def.field("table")._AllClassTable = BlankTable
def.field("dynamic")._CurPageClass = nil -- 当前页实例
def.field("number")._CurPageType = 0 -- 当前页面类型

local WingPageType =
{
	Develop = 1,	-- 升级页
}

local instance = nil
def.static("=>", CPanelUIWing).Instance = function ()
	if instance == nil then
		instance = CPanelUIWing()
		instance._PrefabPath = PATH.UI_Wing
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function (self)
	-- 预加载翅膀数据
	CWingsMan.Instance():PreloadAllWings()

	self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
	self._AllFrameTable =
	{
		[WingPageType.Develop] = self:GetUIObject("Frame_Develop"),
	}

	local rdo_develop = self:GetUIObject("Rdo_Main_Develop")
	self._AllRdoTable =
	{
		[WingPageType.Develop] = rdo_develop:GetComponent(ClassType.Toggle),
	}
	self._ImgTable_RedPoint =
	{
		[WingPageType.Develop] = rdo_develop:FindChild("Img_RedPoint"),
	}
	local frame_top_tabs = self:GetUIObject("Frame_TopTabs")
	--GameUtil.LayoutTopTabs(frame_top_tabs)

	for _, frame in pairs(self._AllFrameTable) do
		frame:SetActive(false)
	end

	self._DevelopPage = CPageWingDevelop.new(self)
	self._AllClassTable =
	{
		[WingPageType.Develop] = self._DevelopPage,
	}
end

-- 更新系统菜单红点
local function UpdateMainMenuRedPoint()
	CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.WingDevelop, CWingsMan.Instance():IsShowRedPoint())
end

-- 更新页签红点
local function UpdatePageRedPoint(self, pageType)
	local pageClass = self._AllClassTable[pageType]
	local img_red_point = self._ImgTable_RedPoint[pageType]
	if pageClass ~= nil and not IsNil(img_red_point) then
		local bShow = pageClass:IsPageHasRedPoint()
		GUITools.SetUIActive(img_red_point, bShow)
	end
end

-- 监听背包物品变化
local function OnPackageChangeEvent(sender, event)
	if instance ~= nil and instance:IsShow() then
		if event.PackageType == net.BAGTYPE.BACKPACK then
			local self = instance
			if self._CurPageType == WingPageType.Develop then
				UpdatePageRedPoint(self, WingPageType.Develop)
				self._DevelopPage:OnPackageChangeEvent()
			end
		end
	end
end

def.override("dynamic").OnData = function (self, data)
	self._HelpUrlType = HelpPageUrlType.Wing
	local openType = WingPageType.Develop -- 默认打开升级页面
	local uiData = nil
	if data ~= nil then
		if type(data.Type) == "number" then
			openType = data.Type
		end
		if type(data.WingTid) == "number" then
			uiData = data.WingTid
		end
	end

	if self._AllRdoTable[openType] ~= nil then
		self._AllRdoTable[openType].isOn = true
	end
	self:ShowFrame(openType, uiData)

	-- 更新红点
	for _, v in pairs(WingPageType) do
		UpdatePageRedPoint(self, v)
	end

    CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
end

def.method("number", "dynamic").ShowFrame = function (self, openType, uiData)
	local originType = self._CurPageType
	local originFrame = self._AllFrameTable[originType]
	if not IsNil(originFrame) then
		originFrame:SetActive(false)
	end
	local originPage = self._AllClassTable[originType]
	if originPage ~= nil then
		originPage:Hide()
	end

	local newFrame = self._AllFrameTable[openType]
	if not IsNil(newFrame) then
		newFrame:SetActive(true)
	end
	local newPage = self._AllClassTable[openType]
	if newPage == nil then
		warn("UIWing dont have this class, type:", openType)
		return
	end
	self._CurPageType = openType
	self._CurPageClass = newPage
	self._CurPageClass:Show(uiData)
end

def.override("string").OnClick = function (self, id)
    CPanelBase.OnClick(self,id)
	if self._Frame_Money:OnClick(id) then return end

	if string.find(id, "Btn_Back") then
		game._GUIMan:Close("CPanelUIWing")
	elseif string.find(id, "Btn_Exit") then
		game._GUIMan:CloseSubPanelLayer()
	else
		self._CurPageClass:OnClick(id)
	end
end

def.override("string", "boolean").OnToggle = function(self, id, checked)
	if string.find(id, "Rdo_Main") then
		-- 一级页签
		if checked then
			local name = string.sub(id, string.len("Rdo_Main_")+1, -1)
			local openType = 0
			if name == "Develop" then
				openType = WingPageType.Develop
			end
			if openType <= 0 or openType == self._CurPageType then return end

			self:ShowFrame(openType, nil)
		end
	else
		self._CurPageClass:OnToggle(id, checked)
	end
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	self._CurPageClass:OnInitItem(item, id, index)
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
	self._CurPageClass:OnSelectItem(item, id, index)
end

def.override("string", "number").OnDropDown = function(self, id, index)
    self._CurPageClass:OnDropDown(id, index)
end

def.override("string", "string").OnDOTComplete = function(self, go_name, dot_id)
	CPanelBase.OnDOTComplete(self, go_name, dot_id)
	self._CurPageClass:OnDOTComplete(go_name, dot_id)
end

------------------------------外部接口 start--------------------------------
-- 更新翅膀列表
def.method("number").UpdateWingList = function (self, type)
	self._DevelopPage:SetWingList()
	if self._CurPageType == WingPageType.Develop then
		self._DevelopPage:UpdateDataFromEvent(type)
	end

	UpdatePageRedPoint(self, WingPageType.Develop)
	UpdateMainMenuRedPoint()
end
-------------------------------外部接口 end---------------------------------

def.override().OnDestroy = function (self)
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)

	for _, class in pairs(self._AllClassTable) do
		class:Destroy()
	end
	if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
	self._AllFrameTable = {}
	self._AllRdoTable = {}
end

CPanelUIWing.Commit()
return CPanelUIWing