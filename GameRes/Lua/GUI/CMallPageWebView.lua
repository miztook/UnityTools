local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CMallPageWebView = Lplus.Extend(CMallPageBase, "CMallPageWebView")
local def = CMallPageWebView.define

def.static("=>", CMallPageWebView).new = function()
	local pageWebView = CMallPageWebView()
	return pageWebView
end

def.override().OnCreate = function(self)
    self._IsWebView = true
end

def.override("dynamic").OnData = function(self, data)
end

def.override().RefreshPage = function(self)
    if self._PageData == nil then
        warn(string.format("MallPanel.RefreshPage error, _PageData is nil"))
        return
    end
end

def.override().OnHide = function(self)
end

def.override().OnDestory = function(self)
end

CMallPageWebView.Commit()
return CMallPageWebView