
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPanelCreateChat = Lplus.Extend(CPanelBase, 'CPanelCreateChat')
local def = CPanelCreateChat.define

def.field("userdata")._InputField = nil 

local instance = nil
def.static("=>", CPanelCreateChat).Instance = function()
    if not instance then
        instance = CPanelCreateChat()
        instance._PrefabPath = PATH.UI_CreateChat
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._InputField = self:GetUIObject("InputField"):GetComponent(ClassType.InputField)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Ok" then 
        local NameChecker = require "Utility.NameChecker"
        if not NameChecker.CheckRoleNameValid(self._InputField.text) then return end
        game._CFriendMan:DoSearch(self._InputField.text)
    elseif id == "Btn_Cancel" or id == "Btn_Close" then 
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnDestroy = function(self)
    instance = nil 
end

CPanelCreateChat.Commit()
return CPanelCreateChat