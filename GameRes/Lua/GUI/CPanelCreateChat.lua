
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

local function CheckName(self,text)
    if IsNilOrEmptyString(text) then 
        game._GUIMan:ShowTipText(StringTable.Get(310),false)
        return false
    end
    local Length = GameUtil.GetStringLength(text)
    -- 最短字符定为 4, 最长字符定为 14
    if Length < GlobalDefinition.MinRoleNameLength or Length > GlobalDefinition.MaxRoleNameLength then
        game._GUIMan:ShowTipText(StringTable.Get(311),false)
        return false
    end
    local FilterMgr = require "Utility.BadWordsFilter".Filter
    local strMsg = FilterMgr.FilterName(text)
    if strMsg ~= text then
        game._GUIMan:ShowTipText(StringTable.Get(30317),false)
        return false
    end
    return true
end

def.override().OnCreate = function(self)
    self._InputField = self:GetUIObject("InputField"):GetComponent(ClassType.InputField)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Ok" then 
        if not CheckName(self,self._InputField.text) then return end
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