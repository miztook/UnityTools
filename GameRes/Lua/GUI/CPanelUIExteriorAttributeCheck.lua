-- 外观属性库
-- 时间：2017/9/12
-- Add by Yao

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelUIExteriorAttributeCheck = Lplus.Extend(CPanelBase, "CPanelUIExteriorAttributeCheck")
local def = CPanelUIExteriorAttributeCheck.define

local CWingsMan = require "Wings.CWingsMan"
local CScoreCalcMan = require "Data.CScoreCalcMan"
local CElementData = require "Data.CElementData"

def.field("userdata")._Lab_Title = nil
def.field("userdata")._Lab_TitleVal = nil
def.field("userdata")._View_Attri = nil
def.field("userdata")._View_Charm = nil
def.field("userdata")._List_Attri = nil
def.field("userdata")._Template_Charm = nil
def.field("userdata")._Lab_DownTip = nil

def.field("table")._AttriList = BlankTable
def.field("table")._CharmList = BlankTable

local ColorHexStr =
{
	Gray = "<color=#636B74>%s</color>",
	White = "<color=#EBE8EC>%s</color>",
	Blue = "<color=#789BC8>%s</color>"
}

local instance = nil
def.static("=>",CPanelUIExteriorAttributeCheck).Instance = function ()
    if instance == nil then
        instance = CPanelUIExteriorAttributeCheck()
        instance._PrefabPath = PATH.UI_Exterior_AttributeCheck
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function (self)
	self._Lab_Title = self:GetUIObject("Lab_Title")
	self._Lab_TitleVal = self:GetUIObject("Lab_TitleValue")
	self._View_Attri = self:GetUIObject("View_Attribute")
	self._List_Attri = self:GetUIObject("List_Attribute"):GetComponent(ClassType.GNewList)
	self._View_Charm = self:GetUIObject("View_Charm")
	self._Template_Charm = self:GetUIObject("Charm_Template")
	self._Lab_DownTip = self:GetUIObject("Lab_DownTip")

	self._Template_Charm:SetActive(false)
	self._View_Attri:SetActive(true)
	self._View_Charm:SetActive(true)
end

-- @param data结构如下:
--        Type   		1:翅膀 2:时装
--        AttriList   	翅膀显示的属性列表
def.override("dynamic").OnData = function (self, data)
	if data == nil then
		game._GUIMan:CloseByScript(self)
		return
	end
	if data.Type == 1 then
		self._View_Charm:SetActive(false)
		self:SetAttriData()
		self:ShowWingAttriInfo()
	elseif data.Type == 2 then
		self._View_Attri:SetActive(false)
		self:ShowDressCharmInfo()
	end
end

def.override("userdata", "string", "number").OnInitItem = function (self, item, id, index)
	if id == "List_Attribute" then
		local attri = self._AttriList[index+1]
        local attri_temp = CElementData.GetAttachedPropertyTemplate(attri.ID)
        if attri_temp == nil then return end

		local uiTemplate = item:GetComponent(ClassType.UITemplate)
		if uiTemplate == nil then return end

		local lab_tip = uiTemplate:GetControl(0)
        GUI.SetText(lab_tip, attri_temp.TextDisplayName)

        local lab_attri = uiTemplate:GetControl(1)
        GUI.SetText(lab_attri, tostring(attri.Value))
	end
end

def.override().OnDestroy = function (self)
	self._AttriList = {}
	self._CharmList = {}
end

----------------------------------翅膀相关 start------------------------
-- 设置属性数据
def.method().SetAttriData = function (self)
	self._AttriList = {}
	-- 获取已有的翅膀数据
	local serverInfos = CWingsMan.Instance():GetAllServerData()
	local levelUpData = {}
	for _, v in ipairs(serverInfos) do
		local data = CWingsMan.Instance():GetWingLevelUpData(v.Tid, v.Level)
		table.insert(levelUpData, data)
	end


	local list = {}
	for _, attri in ipairs(levelUpData) do
		for _, val in ipairs(attri) do
			if list[val.key] == nil then
				list[val.key] = val.data
			else
				list[val.key] = list[val.key] + val.data
			end
		end
	end

	-- 整理结构
	for i, v in pairs(list) do
		if v > 0 then
			local info =
			{
				ID = i,
				Value = v,
			}
			self._AttriList[#self._AttriList+1] = info
		end
	end

	local function SortById(a, b)
		if a.ID < b.ID then
			return true
		else
			return false
		end
	end
	table.sort(self._AttriList, SortById)
end

-- 展示翅膀属性
def.method().ShowWingAttriInfo = function (self)
	-- 标题
	GUI.SetText(self._Lab_Title, StringTable.Get(22107))
	GUI.SetText(self._Lab_TitleVal, tostring(CWingsMan.Instance():GetAllWingsFightScore()))
	if #self._AttriList > 0 then
		self._List_Attri:SetItemCount(#self._AttriList)
		self._View_Attri:SetActive(true)
	else
		self._View_Attri:SetActive(false)
	end
	-- 底部提示
	GUI.SetText(self._Lab_DownTip, StringTable.Get(22105))
end
------------------------------------翅膀相关 end--------------------------

-----------------------------------时装相关 start-------------------------
local function InstantiateObjByTemplate(template)
	if IsNil(template) then return end
	local obj = GameObject.Instantiate(template)
	obj:SetParent(template.parent)
	obj.localPosition = template.localPosition
	obj.localScale = template.localScale
	obj.localRotation = template.localRotation
	obj:SetActive(true)
	return obj
end

-- 设置属性名和属性值
local function SetTipsAndValue(item, tipStr, valStr)
	if IsNil(item) then return end

	local lab_tip = item:FindChild("Lab_Tips")
	if not IsNil(lab_tip) then
		GUI.SetText(lab_tip, tipStr)
	end
	local lab_val = item:FindChild("Lab_Values")
	if not IsNil(lab_val) then
		GUI.SetText(lab_val, valStr)
	end
end

-- 展示时装魅力值
def.method().ShowDressCharmInfo = function (self)
	local CDressUtility = require "Dress.CDressUtility"
	local CDressMan = require "Dress.CDressMan"
	local scoreList = CDressUtility.GetChramScoreList() -- 魅力值列表
	local curScore = CDressMan.Instance():GetCurCharmScore() -- 当前魅力值
	-- 标题
	GUI.SetText(self._Lab_Title, StringTable.Get(22108))
	GUI.SetText(self._Lab_TitleVal, tostring(curScore))
	-- 魅力值
	local PropertyInfoConfig = require "Data.PropertyInfoConfig" 
	for _, data in ipairs(scoreList) do
		local frameObj = InstantiateObjByTemplate(self._Template_Charm)
		local isHighLight = curScore >= data.Score -- 已达成的高亮
		local charmStr = StringTable.Get(22110)
		local charmVal = tostring(data.Score)
		if isHighLight then
			charmStr = string.format(ColorHexStr.Blue, charmStr)
			charmVal = string.format(ColorHexStr.White, charmVal)
		else
			charmStr = string.format(ColorHexStr.Gray, charmStr)
			charmVal = string.format(ColorHexStr.Gray, charmVal)
		end
		SetTipsAndValue(GUITools.GetChild(frameObj, 0), charmStr, charmVal)

		local attriObjTemp = GUITools.GetChild(frameObj, 1)
		attriObjTemp:SetActive(false)
		-- 设置属性
		for _, attriData in ipairs(data.AttriList) do
	        local attri_temp = CElementData.GetAttachedPropertyTemplate(attriData.Id)
	        if attri_temp ~= nil then
				local attriObj = InstantiateObjByTemplate(attriObjTemp)
				local tipStr = attri_temp.TextDisplayName .. StringTable.Get(22111)
				local valStr = ""
				local isRatio = PropertyInfoConfig.IsRatio(attriData.Id)
				if isRatio then
					-- 属于百分比属性
					local percent = fixFloat(attriData.Value * 100)
					valStr = fixFloatStr(percent, 1) .. "%" -- 修正浮点数，保留小数点后一位
				else
					valStr = tostring(attriData.Value)
				end
				if isHighLight then
					tipStr = string.format(ColorHexStr.Blue, tipStr)
					valStr = string.format(ColorHexStr.White, valStr)
				else
					tipStr = string.format(ColorHexStr.Gray, tipStr)
					valStr = string.format(ColorHexStr.Gray, valStr)
				end
				SetTipsAndValue(attriObj, tipStr, valStr)
	        end
		end
	end
	-- 底部提示
	GUI.SetText(self._Lab_DownTip, StringTable.Get(22106))
end
------------------------------------时装相关 end--------------------------

CPanelUIExteriorAttributeCheck.Commit()
return CPanelUIExteriorAttributeCheck