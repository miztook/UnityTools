local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")

local CPanelUICommonWebView = Lplus.Extend(CPanelBase, 'CPanelUICommonWebView')
local def = CPanelUICommonWebView.define

local instance = nil

def.field("table")._PanelObjects = BlankTable
def.field("userdata")._WebView = nil                --WebView的载体
def.field("boolean")._IsWebViewInited = false       --WebView是否已经初始化
def.field("boolean")._IsRunOnWindows = true         --是否工作在windows上

def.static('=>', CPanelUICommonWebView).Instance = function ()
	if not instance then
        instance = CPanelUICommonWebView()
        instance._PrefabPath = PATH.UI_CommonWebView
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects.ViewPort = self:GetUIObject("ViewPort")
    self._WebView = self._PanelObjects.ViewPort:GetComponent(ClassType.GWebView)
end

def.override("dynamic").OnData = function(self, data)
    if data == nil then
        game._GUIMan:CloseByScript(self)
        return
    end

    self:ShowWebView(data)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    end
end

def.method().CheckWebViewInit = function(self)
    if not self._IsWebViewInited then
        if self._WebView ~= nil then
            self._WebView:Init(self._PanelObjects.ViewPort)
            warn("Webview Init successed !!!")
            if not self._WebView.IsRunWindows then
                self._IsRunOnWindows = false
            else
                self._IsRunOnWindows = true
            end
            self._IsWebViewInited = true
        end
    end
end

def.method("string").ShowWebView = function(self, url)
    self:CheckWebViewInit()
    if self._WebView ~= nil then
        if not self._IsRunOnWindows then
            warn("Webview Load(url), url is : ",url)
            self._WebView:Load(url)
        end
    end
end

def.method().HideWebView = function(self)
    if self._WebView ~= nil and self._IsWebViewInited then
        self._WebView:Hide()
        self._IsWebViewInited = false
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    self:HideWebView()
end

def.override().OnDestroy = function(self)
    self._PanelObjects = nil
    self._WebView = nil
end

CPanelUICommonWebView.Commit()
return CPanelUICommonWebView