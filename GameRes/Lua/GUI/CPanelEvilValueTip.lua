
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelEvilValueTip = Lplus.Extend(CPanelBase, 'CPanelEvilValueTip')
local def = CPanelEvilValueTip.define

def.field("number")._IncreaseValue = 20 
def.field("number")._ReduceValue1 =  1
def.field("number")._ReduceValue2 =  20
def.field("number")._UseItemTid = 2021
def.field("number")._UsItemReduceValue = 20
def.field("number")._Range1 = 100
def.field("number")._Range2 = 200 
def.field("number")._Range3 = 300 
def.field("number")._RangePer1 = 10
def.field("number")._RangePer2 = 30
def.field("number")._RangePer3 = 50

def.field("userdata")._LabAdd = nil 
def.field("userdata")._LabReduce1 = nil 
def.field("userdata")._LabReduce2 = nil 
def.field("userdata")._LabRange1 = nil 
def.field("userdata")._LabRange2 = nil 
def.field("userdata")._LabRange3 = nil 
def.field("userdata")._LabRangeValue1 = nil 
def.field("userdata")._LabRangeValue2 = nil 
def.field("userdata")._LabRangeValue3 = nil 

local instance = nil
def.static('=>', CPanelEvilValueTip).Instance = function ()
	if not instance then
        instance = CPanelEvilValueTip()
        instance._PrefabPath = PATH.UI_EvilValueTip
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._LabAdd = self:GetUIObject("Lab_Add")
    self._LabReduce1 = self:GetUIObject("Lab_Reduce1")
    self._LabReduce2 = self:GetUIObject("Lab_Reduce2")
    self._LabRange1 = self:GetUIObject("Lab_Range1")
    self._LabRange2 = self:GetUIObject("Lab_Range2")
    self._LabRange3 = self:GetUIObject("Lab_Range3")
    self._LabRangeValue1 = self:GetUIObject("Lab_RangeValue1")
    self._LabRangeValue2 = self:GetUIObject("Lab_RangeValue2")
    self._LabRangeValue3 = self:GetUIObject("Lab_RangeValue3")
end

def.override("dynamic").OnData = function(self,data)
    local temp = CElementData.GetItemTemplate(self._UseItemTid)
    GUI.SetText(self._LabAdd,string.format(StringTable.Get(31700),self._IncreaseValue))
    GUI.SetText(self._LabReduce1,string.format(StringTable.Get(31701),self._ReduceValue1))
    GUI.SetText(self._LabReduce2,string.format(StringTable.Get(31702),temp.TextDisplayName,self._ReduceValue2))
    GUI.SetText(self._LabRange1,string.format(StringTable.Get(31703),self._Range1,self._Range2))
    GUI.SetText(self._LabRange2,string.format(StringTable.Get(31703),self._Range2,self._Range3))
    GUI.SetText(self._LabRange3,string.format(StringTable.Get(31704),self._Range3))
    GUI.SetText(self._LabRangeValue1,string.format(StringTable.Get(31705),self._RangePer1))
    GUI.SetText(self._LabRangeValue2,string.format(StringTable.Get(31705),self._RangePer2))
    GUI.SetText(self._LabRangeValue3,string.format(StringTable.Get(31705),self._RangePer3))

end

def.override().OnDestroy = function(self)
    instance = nil  
end

CPanelEvilValueTip.Commit()
return CPanelEvilValueTip