local Lplus = require "Lplus"
local CMallMan = require "Mall.CMallMan"
local CMallPageBase = Lplus.Class("CMallPageBase")
local def = CMallPageBase.define

def.field("number")._PageType = 0               --商店类型  （）
def.field("number")._CachedGoodsID = -1          --即将点开的商品ID
def.field("userdata")._Panel = nil              --商城界面的GameObject
def.field("table")._PageData = BlankTable       --Page数据
def.field("table")._PanelMall = BlankTable      --商城界面
def.field("userdata")._GameObject = nil         --实例化出来的Page GameObject
def.field("boolean")._IsShowing = false         --是否正在显示
def.field("boolean")._IsWebView = false         --是否以webView的形式显示
def.field("boolean")._IsHideTabList = false     --是否隐藏左侧的TabList
def.field("boolean")._HasBGVideo = false        --是否有BGVideo
def.field("boolean")._NeedPlayDotween = false   --是否需要播放dotween动画（当刷新的时候）

def.virtual().OnCreate = function(self)
end

def.virtual("dynamic").OnData = function(self, data)
end

def.virtual().OnLoad = function(self)
    self:OnCreate()
    if not self._IsWebView then
        self:OnRegistUIEvent()
    end
    self:Show(self._PageData)
end

def.virtual().OnShow = function(self)
end

def.virtual("number", "table", "table").Init = function(self, pageType, panelMall, pageData)
    self._PageType = pageType
    self._Panel = panelMall._Panel
    self._PanelMall = panelMall
    self._PageData = CMallMan.Instance():ParseMsg(pageData)
    self._IsWebView = pageData.WebViewUrl ~= nil and pageData.WebViewUrl ~= ""
end

def.virtual("dynamic").Show = function(self, data)
    if data and type(data) ~= "table" then
        warn(string.format("MallPanel error, Page data is not table"))
    end
    if self._IsWebView then
        self._PanelMall:ShowWebView(self._PageData.WebViewUrl)
        return
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

def.virtual("number", "number", "number", "number").SetGoodsRefreshTime = function(self, tagID, storeID, goodsID, nextTime)
    if self._PageData ~= nil and self._PageData.Goods ~= nil then
        if self._PageData.StoreTagId == tagID and self._PageData.StoreId == storeID then
            for _,v in ipairs(self._PageData.Goods) do
                if v.Id == goodsID then
                    v.NextRefreshTime = nextTime
                end
            end
        end
    end
end

def.virtual().InitFrameMoney = function(self)
    self._PanelMall:InitFrameMoney(EnumDef.MoneyStyleType.None)
end

local goods_sort_func = function(item1, item2)
    if item1.IsRemainCount ~= item2.IsRemainCount then
        return item1.IsRemainCount
    else
        return item1.Id < item2.Id
    end
    return false
end

def.virtual().RefreshPage = function(self)
    if self._PageData ~= nil and self._PageData.Goods ~= nil then
        for i,v in ipairs(self._PageData.Goods) do
            local buy_count = CMallMan.Instance():GetItemHasBuyCountByID(self._PageData.StoreId, v.Id)
            v.IsRemainCount = v.Stock > 0 and v.Stock > buy_count or v.Stock <= 0
        end
        table.sort(self._PageData.Goods, goods_sort_func)
    end
end

def.virtual("table").OnBuySuccess = function(self, datas)
end

def.virtual("number").OnReceiveRewardSuccess = function(self, storeID)
end

def.virtual("table", "table").OnGainItem = function(self, sender, event)
end

--生成对应Page的预制体的时候动态注册监听（通过CPanelMall得到回调）
def.virtual().OnRegistUIEvent = function(self)
end

def.virtual("=>", "string").GetMallPageTemplatePath = function(self)
    return ""
end

def.virtual("table", "=>", "table").ParseMsg = function(self, data)
    return {}
end

def.virtual("number", "function").PlayDotween = function(self, ttl, callback)
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
    if self._IsWebView and self._PanelMall then
        self._PanelMall:HideWebView()
    else
        self._GameObject:SetActive(false)
    end
    self:OnHide()
end

def.virtual().OnHide = function(self)
end

def.virtual().OnDestory = function(self)
    if self._IsWebView then
        self._GameObject = nil
    end
    self._PageData = nil
    self._IsShowing = false
end

CMallPageBase.Commit()
return CMallPageBase