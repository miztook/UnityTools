local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"

local CPanelUICommonNotice = Lplus.Extend(CPanelBase, "CPanelUICommonNotice")
local def = CPanelUICommonNotice.define

def.field("userdata")._Lab_Title = nil
def.field("userdata")._Lab_Name = nil
def.field("userdata")._Lab_Desc = nil

local instance = nil
def.static("=>",CPanelUICommonNotice).Instance = function()
    if instance == nil then
        instance = CPanelUICommonNotice()
        instance._PrefabPath = PATH.UI_CommonNotice
        instance._PanelCloseType = EnumDef.PanelCloseType.Tip
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)

end

def.override("dynamic").OnData = function(self,data)
	if data == nil then
        game._GUIMan:CloseByScript(self)
	end

	-- self._Lab_Title = self:GetUIObject('Lab_Title')
	-- self._Lab_Name = self:GetUIObject('Lab_Name')
	-- self._Lab_Desc = self:GetUIObject('Lab_Desc')

	GUI.SetText(self:GetUIObject('Lab_Title'), data.Title)
	GUI.SetText(self:GetUIObject('Lab_Desc'), data.Desc)
	if data.Name ~= nil then
		GUI.SetText(self:GetUIObject('Lab_Name'), data.Name)
	end
    CPanelBase.OnData(self,data)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

CPanelUICommonNotice.Commit()
return CPanelUICommonNotice