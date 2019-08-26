local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"

local CPanelUIQuenchDescHint = Lplus.Extend(CPanelBase, "CPanelUIQuenchDescHint")
local def = CPanelUIQuenchDescHint.define

local instance = nil
def.static("=>",CPanelUIQuenchDescHint).Instance = function()
    if instance == nil then
        instance = CPanelUIQuenchDescHint()
        instance._PrefabPath = PATH.UI_QuenchDescHint
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
end

def.override("dynamic").OnData = function(self,data)
    CPanelBase.OnData(self,data)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

CPanelUIQuenchDescHint.Commit()
return CPanelUIQuenchDescHint