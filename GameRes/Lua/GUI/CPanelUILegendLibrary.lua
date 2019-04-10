local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"

local CPanelUILegendLibrary = Lplus.Extend(CPanelBase, "CPanelUILegendLibrary")
local def = CPanelUILegendLibrary.define

def.field("table")._ItemData = nil
def.field("table")._ObjectList = BlankTable
def.field('table')._LegendaryInfoList = BlankTable

local TextType = ClassType.Text
local RectTransform = ClassType.RectTransform
local instance = nil
def.static("=>",CPanelUILegendLibrary).Instance = function()
    if instance == nil then
        instance = CPanelUILegendLibrary()
        instance._PrefabPath = PATH.UI_LegendLibraryHint
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
	local item = self:GetUIObject('item')
	self._ObjectList = {}
	table.insert(self._ObjectList, item)
end

def.override("dynamic").OnData = function(self,data)
    CPanelBase.OnData(self,data)
	self._ItemData = data
	self:InitItem()	
end

def.method().InitItem = function(self)
	local legendLibrary = CElementData.GetLegendaryGroupInfoById( self._ItemData._LegendaryGroupId )
	self._LegendaryInfoList = {}
	for k,v in pairs(legendLibrary) do
		table.insert(self._LegendaryInfoList, v)
	end

	for i=1, #self._LegendaryInfoList do
		local legendInfo = self._LegendaryInfoList[i]
		local item = self:GetLegendaryItem(i)

		self:SetItem(item, legendInfo)
	end
end

def.method("userdata", "table").SetItem = function(self, item, data)
	local Lab_Name = item:FindChild("Lab_Name")
	local Lab_Desc = item:FindChild("Lab_Desc")
	local Lab_Lv = item:FindChild("Lab_Lv")
	local descText = Lab_Desc:GetComponent(TextType)
	local nameText = Lab_Name:GetComponent(TextType)
	
	GUI.SetText(Lab_Name, data.Name)
	GUI.SetText(Lab_Desc, data.SkillDesc)
	GUI.SetText(Lab_Lv, data.LvDesc)
	GameUtil.SetLayoutElementPreferredSize(item, -1, descText.preferredHeight + nameText.preferredHeight)

	item:SetActive(true)
end

--获取属性库 item组件，动态创建，自行维护
def.method("number", "=>", "userdata").GetLegendaryItem = function(self, index)
    if index > #self._ObjectList then
        local itemNew = GameObject.Instantiate(self._ObjectList[1])
        table.insert(self._ObjectList, itemNew)
        itemNew:SetParent(self._ObjectList[1].parent, false)
    end

    return self._ObjectList[index]
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._ItemData = nil
	self._ObjectList = nil
	self._LegendaryInfoList = nil
end

CPanelUILegendLibrary.Commit()
return CPanelUILegendLibrary