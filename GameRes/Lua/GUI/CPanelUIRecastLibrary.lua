local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"

local CPanelUIRecastLibrary = Lplus.Extend(CPanelBase, "CPanelUIRecastLibrary")
local def = CPanelUIRecastLibrary.define

def.field("table")._ItemData = nil
def.field("userdata")._ItemList = nil
def.field('table')._AttrInfoList = BlankTable
def.field("table")._RecommendPropertyList = BlankTable

local instance = nil
def.static("=>",CPanelUIRecastLibrary).Instance = function()
    if instance == nil then
        instance = CPanelUIRecastLibrary()
        instance._PrefabPath = PATH.UI_RecastLibraryHint
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
	self._ItemList = self:GetUIObject('List_Attribute'):GetComponent(ClassType.GNewListLoop)
end

def.override("dynamic").OnData = function(self,data)
    CPanelBase.OnData(self,data)
	self._ItemData = data
	self:UpdateUI()	
end

def.method().UpdateUI = function(self)
	self._AttrInfoList = {}

	local Lab_Title = self:GetUIObject('Lab_Title')
--[[	local name = RichTextTools.GetQualityText(self._ItemData:GetNameText(), self._ItemData:GetQuality())
	GUI.SetText(Lab_Title, string.format(StringTable.Get(10982), name))--]]
	local name = RichTextTools.GetQualityText(self._ItemData:GetNameText(), self._ItemData:GetQuality())
	GUI.SetText(Lab_Title, name)

	local attrInfoList = CElementData.GetEquipAttrInfoById( self._ItemData._Template.AttachedPropertyGroupGeneratorId )
	for k,v in pairs(attrInfoList) do
		if not self._ItemData:IsRecommendProperty(v.FightPropertyId) then
			table.insert(self._AttrInfoList, v)
		end
	end

	self._RecommendPropertyList = self._ItemData:GetRecommendPropertyList()
	local recommendCount = #self._RecommendPropertyList
	local addCount = recommendCount > 0 and 2 + recommendCount or 0
	local realCount = #self._AttrInfoList + addCount

	self._ItemList:SetItemCount(realCount)
end

def.method("userdata", "table").SetItem = function(self, item, data)
	local Lab_Name = item:FindChild("Lab_Name")
	local Lab_MinValue = item:FindChild("Lab_MaxValue/Lab_MinValue")
	local Lab_MaxValue = item:FindChild("Lab_MaxValue")
	local Lab_tips = item:FindChild("Lab_MaxValue/Lab_tips")
	
	local propertyCoefficient = self._ItemData:GetPropertyCoefficient()
	local min = math.ceil(data.MinValue * propertyCoefficient)
	local max = math.ceil(data.MaxValue * propertyCoefficient)
	min = math.clamp(min, 1, min)
	max = math.clamp(max, 1, max)

	local bIsRecommend = self._ItemData:IsRecommendProperty(data.FightPropertyId)
	local strMin = GUITools.FormatNumber(min)
	local strMax = GUITools.FormatNumber(max)

	GUI.SetText(Lab_MinValue, bIsRecommend and string.format(StringTable.Get(10985), strMin) or strMin)
	GUI.SetText(Lab_MaxValue, bIsRecommend and string.format(StringTable.Get(10985), strMax) or strMax)
	GUI.SetText(Lab_tips, bIsRecommend and string.format(StringTable.Get(10985), '-') or '-')
	GUI.SetText(Lab_Name, bIsRecommend and string.format(StringTable.Get(10984), data.Name) or data.Name)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Attribute" then
    	local Lab_Recommend_Begin = item:FindChild("Lab_Recommend_Begin")
		local Lab_Recommend_End = item:FindChild("Lab_Recommend_End")
		local Property = item:FindChild("Property")

		local RecommendCount = #self._RecommendPropertyList

		local bShowBegin = (idx == 1 and RecommendCount > 0)
		local bShowEnd = (RecommendCount > 0 and RecommendCount + 2 == idx)
		local bShowProperty = (not bShowBegin and not bShowEnd)

		Lab_Recommend_Begin:SetActive(bShowBegin)
		Lab_Recommend_End:SetActive(bShowEnd)
		Property:SetActive(bShowProperty)

		if bShowProperty then
			local data = nil
			if RecommendCount > 0 then
				if idx > RecommendCount + 2 then
					data = self._AttrInfoList[idx - (RecommendCount + 2)]
				else
					data = self._RecommendPropertyList[idx-1]
				end
			else
				data = self._AttrInfoList[idx]
			end

			self:SetItem(Property, data)
		end
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self._ItemData = nil
	self._AttrInfoList = nil
end

CPanelUIRecastLibrary.Commit()
return CPanelUIRecastLibrary