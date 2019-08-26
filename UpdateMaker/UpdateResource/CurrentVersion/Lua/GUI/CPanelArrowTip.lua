
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CPanelArrowTip = Lplus.Extend(CPanelBase, 'CPanelArrowTip')
local def = CPanelArrowTip.define
 

local instance = nil
def.static('=>', CPanelArrowTip).Instance = function ()
	if not instance then
        instance = CPanelArrowTip()
        instance._PrefabPath = PATH.UI_ArrowTip
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
end

def.override().OnDestroy = function(self)
	instance = nil 
end
CPanelArrowTip.Commit()
return CPanelArrowTip