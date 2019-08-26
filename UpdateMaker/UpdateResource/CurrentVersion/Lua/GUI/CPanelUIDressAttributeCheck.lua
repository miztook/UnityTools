-- 时装属性库
-- 时间：2019/4/23
-- Add by Yao

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIDressAttributeCheck = Lplus.Extend(CPanelBase, "CPanelUIDressAttributeCheck")
local def = CPanelUIDressAttributeCheck.define

local CDressMan = require "Dress.CDressMan"
local CDressUtility = require "Dress.CDressUtility"
local CElementData = require "Data.CElementData"
local PropertyInfoConfig = require "Data.PropertyInfoConfig" 

def.field("table")._PanelObject = BlankTable
-- 缓存
def.field("number")._TotalCharm = 0 -- 总魅力值
def.field("table")._AllCharmList = BlankTable -- 所有魅力值列表
def.field("table")._AllAttriList = BlankTable -- 所有属性列表
def.field("number")._CurCharmIndex = 0 -- 当前魅力列表项的索引
def.field("number")._LastActivatedCharmIndex = 0 -- 最新激活的魅力列表项的索引

local instance = nil
def.static("=>",CPanelUIDressAttributeCheck).Instance = function ()
    if instance == nil then
        instance = CPanelUIDressAttributeCheck()
        instance._PrefabPath = PATH.UI_DressAttributeCheck
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function (self)
	self._PanelObject =
	{
		Lab_TotalCharmValue = self:GetUIObject("Lab_TotalCharmValue"),
		View_Charm = self:GetUIObject("View_Charm"),
		List_Charm = self:GetUIObject("List_Charm"):GetComponent(ClassType.GNewListLoop),
		Lab_TotalFight = self:GetUIObject("Lab_TotalFight"),
		View_TotalAttri = self:GetUIObject("View_TotalAttri"),
		List_TotalAttri = self:GetUIObject("List_TotalAttri"):GetComponent(ClassType.GNewList),
	}
end

def.override("dynamic").OnData = function (self, data)
	self:InitData()
	self:ShowCharmInfo()
end

def.method().InitData = function (self)
	-- 魅力
	self._TotalCharm = CDressMan.Instance():GetCurCharmScore()
	self._AllCharmList = CDressUtility.GetChramScoreList()
	self._LastActivatedCharmIndex = 0
	-- 战力
	local attriMap = {}
	for i, data in ipairs(self._AllCharmList) do
		if data.Score > self._TotalCharm then break end
		self._LastActivatedCharmIndex = i-1
		for _, attriData in ipairs(data.AttriList) do
			if attriMap[attriData.Id] == nil then
				attriMap[attriData.Id] = 0
			end
			attriMap[attriData.Id] = attriMap[attriData.Id] + attriData.Value
		end
	end
	self._AllAttriList = {}
	for id, value in pairs(attriMap) do
		local temp = { ID = id, Value = value }
		table.insert(self._AllAttriList, temp)
	end
end

def.method().ShowCharmInfo = function (self)
	-- 魅力
	GUI.SetText(self._PanelObject.Lab_TotalCharmValue, GUITools.FormatNumber(self._TotalCharm, false, 7))
	self._PanelObject.List_Charm:SetItemCount(#self._AllCharmList)
	self._PanelObject.List_Charm:ScrollToStep(self._LastActivatedCharmIndex-1)
	-- 战力
	local fightScore = CDressMan.Instance():GetCurFightScore()
	GUI.SetText(self._PanelObject.Lab_TotalFight, GUITools.FormatNumber(fightScore, false, 7))
	self._PanelObject.List_TotalAttri:SetItemCount(#self._AllAttriList)
end

def.override("string").OnClick = function (self, id)
	if id == "Btn_Back" then
		game._GUIMan:Close("CPanelUIDressAttributeCheck")
	end
end

local function GetValueStr(id, value)
	local valueStr = ""
	local isRatio = PropertyInfoConfig.IsRatio(id)
	if isRatio then
		-- 属于百分比属性
		local percent = fixFloat(value * 100)
		valueStr = fixFloatStr(percent, 1) .. "%" -- 修正浮点数，保留小数点后一位
	else
		valueStr = GUITools.FormatNumber(value, false, 7)
	end
	return valueStr
end

def.override("userdata", "string", "number").OnInitItem = function (self, item, id, index)
	if id == "List_Charm" then
		-- 魅力列表
		self._CurCharmIndex = index
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		if uiTemplate == nil then return end

		local charmData = self._AllCharmList[index+1]
		local isActivated = charmData.Score <= self._TotalCharm -- 是否已激活
		-- 整体透明度
		GameUtil.SetCanvasGroupAlpha(item, isActivated and 1 or 0.4)
		-- 背景
		local img_bg_1 = uiTemplate:GetControl(3)
		GameUtil.MakeImageGray(img_bg_1, not isActivated)
		local img_bg_2 = uiTemplate:GetControl(4)
		GameUtil.MakeImageGray(img_bg_2, not isActivated)
		-- 标题
		local titleStr = StringTable.Get(22110)
		local lab_title = uiTemplate:GetControl(0)
		GUI.SetText(lab_title, titleStr)
		-- 魅力值
		local valueStr = GUITools.FormatNumber(charmData.Score, false, 7)
		local lab_charm = uiTemplate:GetControl(1)
		GUI.SetText(lab_charm, valueStr)
		-- 单个属性列表
		local list_attri = uiTemplate:GetControl(2)
		GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, list_attri)
		list_attri:GetComponent(ClassType.GNewList):SetItemCount(#charmData.AttriList)
	elseif id == "List_CharmAttri" then
		-- 特定魅力值增加的属性列表
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		if uiTemplate == nil then return end
		local charmData = self._AllCharmList[self._CurCharmIndex+1]
		local attriData = charmData.AttriList[index+1]
		local attri_temp = CElementData.GetAttachedPropertyTemplate(attriData.Id)
		if attri_temp == nil then return end

		local isActivated = charmData.Score <= self._TotalCharm -- 是否已激活
		-- 属性名
		local lab_title = uiTemplate:GetControl(0)
		GUI.SetText(lab_title, attri_temp.TextDisplayName)
		-- 属性值
		local valueStr = GetValueStr(attriData.Id, attriData.Value)
		local lab_attri = uiTemplate:GetControl(1)
		GUI.SetText(lab_attri, valueStr)
	elseif id == "List_TotalAttri" then
		-- 所有属性列表
		local attri = self._AllAttriList[index+1]
		local attri_temp = CElementData.GetAttachedPropertyTemplate(attri.ID)
		if attri_temp == nil then return end
		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		if uiTemplate == nil then return end
		-- 属性名
		local lab_title = uiTemplate:GetControl(0)
		GUI.SetText(lab_title, attri_temp.TextDisplayName)
		-- 属性值
		local lab_attri = uiTemplate:GetControl(1)
		GUI.SetText(lab_attri, GetValueStr(attri.ID, attri.Value))
	end
end

def.override().OnDestroy = function (self)
	self._PanelObject = {}
	self._AllCharmList = {}
	self._AllAttriList = {}
end

CPanelUIDressAttributeCheck.Commit()
return CPanelUIDressAttributeCheck