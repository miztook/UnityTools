local Lplus = require "Lplus"
local CPanelBase = require 'GUI.CPanelBase'
local CPanelUIAppMsgBox = Lplus.Extend(CPanelBase, 'CPanelUIAppMsgBox')
local def = CPanelUIAppMsgBox.define

-- 界面
def.field("userdata")._Lab_MsgTitle = nil 
def.field("userdata")._Lab_MsgDesc_01 = nil 
def.field("userdata")._Lab_MsgDesc_02 = nil

def.field("userdata")._Btn_NextTime = nil 
def.field("userdata")._Btn_CustomerService = nil 
def.field("userdata")._Btn_Score = nil 

local instance = nil
def.static('=>', CPanelUIAppMsgBox).Instance = function ()
	if not instance then
        instance = CPanelUIAppMsgBox()
        instance._PrefabPath = PATH.UI_AppMsgbox
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

def.static("=>", "table").GetAppMsgBoxCfg = function()
	local AppMsgBoxTable = _G.AppMsgBoxTable
	if AppMsgBoxTable == nil then return "nil string" end
	return AppMsgBoxTable
end

def.override().OnCreate = function(self)
    self._Lab_MsgTitle = self:GetUIObject('Lab_MsgTitle')
    self._Lab_MsgDesc_01 = self:GetUIObject('Lab_MsgDesc_01')
    self._Lab_MsgDesc_02 = self:GetUIObject('Lab_MsgDesc_02')
    self._Btn_NextTime = self:GetUIObject('Btn_NextTime')
    self._Btn_CustomerService = self:GetUIObject('Btn_CustomerService')
    self._Btn_Score = self:GetUIObject('Btn_Score')

end

def.override("dynamic").OnData = function(self,data)
    if data == nil then return end    
    if self._Lab_MsgTitle ~= nil then
        GUI.SetText(self._Lab_MsgTitle , tostring(data.AppMsgBoxCfg.Title))
    end
    if self._Lab_MsgDesc_02 ~= nil then
        GUI.SetText(self._Lab_MsgDesc_01 , tostring(data.AppMsgBoxCfg.Desc1))
    end
    if self._Lab_MsgDesc_02 ~= nil then
        GUI.SetText(self._Lab_MsgDesc_02 , tostring(data.AppMsgBoxCfg.Desc2))
    end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_NextTime' then
        game._GUIMan:Close("CPanelUIAppMsgBox")
    elseif id == 'Btn_CustomerService' then
        game._GUIMan:Close("CPanelUIAppMsgBox")
        CPlatformSDKMan.Instance():ShowCustomerCenter(function(deepLinkUrl)
            -- TODO:处理DeepLink
            warn("ShowCustomerCenter callback deepLinkUrl:", deepLinkUrl)
        end)
    elseif id == 'Btn_Score' then
        game._GUIMan:Close("CPanelUIAppMsgBox")
        self:ShowMarket() 
    end
end

def.method().ShowMarket = function(self)
    local url = ""
    if _G.IsIOS() then
        local appleId = 1471095711
        url = string.format(StringTable.Get(33000), appleId)
    elseif _G.IsAndroid() then
        local packageName = "com.kakaogames.tera"
        url = string.format(StringTable.Get(33001), packageName)
    end
    warn("ShowMarket url = ", url)
    GameUtil.OpenUrl(url)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function (self)
    self._Lab_MsgTitle = nil
    self._Lab_MsgDesc_01 = nil
    self._Lab_MsgDesc_02 = nil
    self._Btn_NextTime = nil
    self._Btn_CustomerService = nil
    self._Btn_Score = nil
end
----------------------------------------------------------------------------------


CPanelUIAppMsgBox.Commit()
return CPanelUIAppMsgBox