local Lplus = require "Lplus"
local CMallMan = require "Mall.CMallMan"
local CSummonPageBase = Lplus.Class("CSummonPageBase")
local def = CSummonPageBase.define

def.field("number")._PageType = 0               --商店类型  （）
def.field("table")._PanelSummon = BlankTable    --召唤界面
def.field("table")._PageData = BlankTable
def.field("userdata")._GameObject = nil         --实例化出来的Page GameObject
def.field("boolean")._IsShowing = false         --是否正在显示
def.field("boolean")._IsHideTabList = false     --是否隐藏左侧的TabList
def.field("boolean")._HasBGVideo = false        --是否有BGVideo
def.field("boolean")._NeedPlayDotween = false   --是否需要播放dotween动画（当刷新的时候）

def.virtual().OnCreate = function(self)
end

def.virtual("dynamic").OnData = function(self, data)
end

def.virtual().OnLoad = function(self)
    self:OnCreate()
--    self:OnRegistUIEvent()
    self:Show(self._PageData)
end

def.virtual().OnShow = function(self)
end

def.virtual("number", "table", "table").Init = function(self, pageType, panelSummon, pageData)
    self._PageType = pageType
    self._PanelSummon = panelSummon
    self._PageData = CMallMan.Instance():ParseMsg(pageData)
end

def.virtual("dynamic").Show = function(self, data)
    if data and type(data) ~= "table" then
        warn(string.format("MallPanel error, Page data is not table"))
    end

    if self._GameObject == nil then return end
    self._GameObject:SetActive(true)
    if data then
        self._PageData = CMallMan.Instance():ParseMsg(data)
        self:OnData(data)
    end
    self:OnShow()
    self:InitFrameMoney()
    self._IsShowing = true
end

def.virtual().InitFrameMoney = function(self)
    self._PanelSummon:InitFrameMoney(EnumDef.MoneyStyleType.None)
end

def.virtual().RefreshPage = function(self)
end

def.virtual("table").OnBuySuccess = function(self, datas)
end

def.virtual("number").OnReceiveRewardSuccess = function(self, storeID)
end

def.virtual("table", "table").OnGainItem = function(self, sender, event)
end

def.virtual("=>", "string").GetSummonPageTemplateName = function(self)
    return ""
end

def.virtual("table", "=>", "table").ParseMsg = function(self, data)
    return {}
end

def.virtual().PlayVideoBG = function(self)
end

def.virtual('string').OnClick = function(self, id)
end

def.virtual("string", "boolean").OnToggle = function(self, id, checked)
end

def.virtual('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
end

def.virtual('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)  
end

def.virtual("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
end

def.virtual("=>", "boolean").HandleEscapeKey = function(self)
    return false
end

def.virtual().Hide = function(self)
    self._IsShowing = false
    self._GameObject:SetActive(false)
    self:OnHide()
end

def.virtual().OnHide = function(self)
end

def.virtual().OnDestory = function(self)
    self._GameObject = nil
    self._PageData = nil
end

CSummonPageBase.Commit()
return CSummonPageBase