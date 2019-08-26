
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelRuleDescription = Lplus.Extend(CPanelBase, 'CPanelRuleDescription')
local def = CPanelRuleDescription.define
 
def.field("userdata")._LabIntroduction = nil 

local instance = nil
def.static('=>', CPanelRuleDescription).Instance = function ()
	if not instance then
        instance = CPanelRuleDescription()
        instance._PrefabPath = PATH.UI_RuleDescription
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._LabIntroduction = self:GetUIObject("Lab_Introduction")
end

-- 副本介绍id
def.override("dynamic").OnData = function(self,data)
    local popupTemplate = CElementData.GetTemplate("DungeonIntroductionPopup", data)
    GUI.SetText(self._LabIntroduction,popupTemplate.Introduction)
end

def.override('string').OnClick = function(self, id)
    
    if id == 'Btn_Close' then
        game._GUIMan:CloseByScript(self)
    end

end


CPanelRuleDescription.Commit()
return CPanelRuleDescription