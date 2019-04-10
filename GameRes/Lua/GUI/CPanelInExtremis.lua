
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'

local CPanelInExtremis = Lplus.Extend(CPanelBase, 'CPanelInExtremis')
local def = CPanelInExtremis.define
 

local instance = nil
def.static('=>', CPanelInExtremis).Instance = function ()
	if not instance then
        instance = CPanelInExtremis()
        instance._PrefabPath = PATH.Panel_InExtremis
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
end

def.override().OnDestroy = function (self)
	
end

CPanelInExtremis.Commit()
return CPanelInExtremis