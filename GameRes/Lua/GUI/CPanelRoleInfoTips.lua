local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CPanelRoleInfoTips = Lplus.Extend(CPanelBase, "CPanelRoleInfoTips")
local def = CPanelRoleInfoTips.define

def.field("userdata")._Lab_RoleInfoTips = nil
def.field("userdata")._Img_Background = nil

local MAX_HINT_WIDTH = 262

local instance = nil
def.static("=>",CPanelRoleInfoTips).Instance = function()
    if instance == nil then
        instance = CPanelRoleInfoTips()
        instance._PrefabPath = PATH.Panel_RoleInfoTips
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = false

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._Lab_RoleInfoTips = self._Panel:FindChild("Img_BG/Lab_RoleInfoTips")
    self._Img_Background = self._Panel:FindChild("Img_BG")
end

def.override("dynamic").OnData = function(self,data)
    if data.Value == nil then
        game._GUIMan:Close(self)
    end
    GUI.SetTextAndChangeLayout(self._Lab_RoleInfoTips, data.Value, MAX_HINT_WIDTH)
    GUITools.SetRelativePosition(data.Obj, self._Img_Background, data.AlignType)
end

CPanelRoleInfoTips.Commit()
return CPanelRoleInfoTips