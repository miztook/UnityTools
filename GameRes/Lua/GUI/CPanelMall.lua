local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CMallPageBase = require "Mall.CMallPageBase"
local CMallPageFactory = require "Mall.CMallPageFactory"
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local EStoreLabelType = require "PB.data".EStoreLabelType

local CPanelMall = Lplus.Extend(CPanelBase, 'CPanelMall')
local def = CPanelMall.define


local instance = nil

def.field("table")._PanelObjects = BlankTable
def.field("number")._CacheMallID = -1                   -- 从外部调用传进来的参数
def.field("number")._CacheGoodsID = -1                  -- 从推荐页传过来的要点击的商品ID
def.field("userdata")._WebView = nil                    -- WebView的载体
def.field("userdata")._List_BigTab = nil                -- 大页签List
def.field("userdata")._TabList_SmallTab = nil           -- 小页签TabList
def.field("number")._CurrentSelectBigTabID = 0          -- 当前选择的大页签ID
def.field("number")._CurrentSelectSmallTabID = 0        -- 当前选择的小页签ID
def.field("number")._CurrentSelectBigTabIndex = 0       -- 当前选择的大页签的index
def.field("number")._CurrentSelectSmallTabIndex = 0     -- 当前选择的小页签的index
def.field("boolean")._IsWebViewInited = false           -- WebView是否已经初始化
def.field("boolean")._IsRunOnWindows = true             -- 是否工作在windows上
def.field("boolean")._IsPanelMallInited = false         -- 商城面板是否初始化完毕
def.field("table")._Pages = BlankTable                  -- 缓存所有的Page
def.field("table")._CurrentPage = nil                   -- 当前显示的Page
def.field("table")._TagTimers = BlankTable              -- 左边小页签的剩余时间计时器
def.field(CFrameCurrency)._Frame_Money = nil

def.static('=>', CPanelMall).Instance = function ()
	if not instance then
        instance = CPanelMall()
        instance._PrefabPath = PATH.UI_Mall
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects.ViewPort = self:GetUIObject("ViewPort")
    self._PanelObjects.Frame_Content = self:GetUIObject("Frame_Content")
    self._PanelObjects._List_BigTab = self:GetUIObject("List_BigMenu")
    self._PanelObjects._TabList = self:GetUIObject("TabList")
    self._WebView = self._PanelObjects.ViewPort:GetComponent(ClassType.GWebView)
    self._List_BigTab = self:GetUIObject("List_BigMenu"):GetComponent(ClassType.GNewList)
    self._TabList_SmallTab = self:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)
end

def.override("dynamic").OnData = function(self, data)
    if data ~= nil then
        self._CacheMallID = tonumber(data) or -1
    end
    --更新货币
    if self._Frame_Money == nil then
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
    else
        self._Frame_Money:Update()
    end
    self._TagTimers = {}
    CMallMan.Instance():RequestMallRoleInfo()
    CMallMan.Instance():RequestTabs()
    --self:ShowWebView("https://www.baidu.com")
end

--------------------------------------------------------
--客户端收到页签数据之后在初始化面板
--------------------------------------------------------
def.method("table").Init = function(self, data)
    if data == nil or data.StoreTagFounds == nil or #data.StoreTagFounds == 0 then
        warn("Error, 商城页签数据为空")
        return
    end
    self:CleanOldPage()
    self:StoreUnlockCheck()
    self:GenerateTabs(data)
    if self._CacheMallID ~= -1 then
        self._CurrentSelectBigTabIndex = 0
        self._CurrentSelectSmallTabIndex = 0
        self:SwitchToShop(self._CacheMallID)
        GUI.SetGroupToggleOn(self._PanelObjects._List_BigTab, self._CurrentSelectBigTabIndex + 2)
        self._TabList_SmallTab:SetSelection(self._CurrentSelectSmallTabIndex - 1, 0)
    else
        self:RequestSmallTabData(self._CurrentSelectBigTabID, self._CurrentSelectSmallTabID)
        GUI.SetGroupToggleOn(self._PanelObjects._List_BigTab, self._CurrentSelectBigTabIndex + 2)
        self._TabList_SmallTab:SetSelection(self._CurrentSelectSmallTabIndex - 1, 0)
    end
    
    self._IsPanelMallInited = true
end

--------------------------------------------------------
--初始化/更新货币栏
--------------------------------------------------------
def.method("number").InitFrameMoney = function(self, styleType)
    if self._Frame_Money == nil then
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), styleType)
    else
        self._Frame_Money:Init(styleType)
    end
    self._Frame_Money:Update()
end

def.override('string').OnClick = function(self, id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
		return
    elseif id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    else
        if self._CurrentPage then
            self._CurrentPage:OnClick(id)
        end
    end
end

def.override("string").OnReceiveWebViewMessage = function(self, msg)
    warn("OnReceiveWebViewMessage 开始解析 ", msg)
    local msgTable = GUITools.ParseWebViewMsg(msg)
    for k,v in pairs(msgTable) do
        warn("OnReceiveWebViewMessage :", k,v)
    end
    self._WebView:EvaluatingJavaScript(msgTable.num2)
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    if list.name == "TabList" then
        if sub_index == -1 then
            local index = main_index + 1
            local labelName1 = item:FindChild("Lab_Layout/Lab_Text")
            local img_corneMark = item:FindChild("Img_CorneMark")
            local lab_remain_time = item:FindChild("Lab_Layout/Lab_Time")
            local storeFound = tab_datas.StoreTagFounds[self._CurrentSelectBigTabIndex].Stores[index]
            local smallTagTemp = CElementData.GetTemplate("Store", storeFound.StoreId)
            do  -- 名称设置
                local smallTabName = ""
                if smallTagTemp == nil then
                    smallTabName = storeFound.StoreName
                else
                    smallTabName = smallTagTemp.Name
                end
                if smallTabName == nil then
                    smallTabName = ""
                end
                GUI.SetText(labelName1, smallTabName)
            end
            do  -- 角标设置
                local label_type = storeFound.LabelType
                if label_type == EStoreLabelType.EStoreLabelType_Normal then
                    img_corneMark:SetActive(false)
                else
                    GUITools.SetGroupImg(img_corneMark, label_type - 1)
                    img_corneMark:SetActive(true)
                end
                if CMallMan.Instance():GetRedPointState(storeFound.StoreId) then
                    item:FindChild("Img_RedPoint"):SetActive(true)
                else
                    item:FindChild("Img_RedPoint"):SetActive(false)
                end
            end
            do  -- 剩余时间设置
                local remain_time = storeFound.ShowEndTime or 0
                local now_time_init = GameUtil.GetServerTime()
                if remain_time ~= nil and remain_time > 0 and now_time_init < remain_time then
                    local callback = function()
                        local now_time = GameUtil.GetServerTime() / 1000
                        local time_str = CMallUtility.GetRemainStringByEndTime(remain_time)
                        GUI.SetText(lab_remain_time, time_str)
                        if now_time >= remain_time/1000 then
                            _G.RemoveGlobalTimer(self._TagTimers[storeFound.StoreId])
                            self._TagTimers[storeFound.StoreId] = nil
                            CMallMan.Instance():RemoveTagsDataFromServer(storeFound.StoreId)
                            local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
                            local smallTabCount = #tab_datas.StoreTagFounds[self._CurrentSelectBigTabIndex].Stores
                            self:RemoveAllSmallTagTimer()
                            self._TabList_SmallTab:SetItemCount(smallTabCount)
                            self._CurrentSelectSmallTabIndex = 0
                            self:OnClickSmallTab(self._CurrentSelectBigTabIndex, 1)
                            self._TabList_SmallTab:SetSelection(0, 0)
                            game._GUIMan:ShowTipText(StringTable.Get(31065), true)
                        end
                    end
                    self._TagTimers[storeFound.StoreId] = _G.AddGlobalTimer(1, false, callback)
                    lab_remain_time:SetActive(true)
                else
                    lab_remain_time:SetActive(false)
                end
            end
        elseif sub_index ~= -1 then
             -- 商城现在还没有子商店
        end
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickSmallTab(self._CurrentSelectBigTabIndex, bigTypeIndex)
        elseif sub_index ~= -1 then
            -- 商城现在还没有子商店
        end
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    if id == "List_BigMenu" then
        local index = index + 1
        local labelName1 = item:FindChild("Img_U/Lab_TagUp1")
        local labelName2 = item:FindChild("Img_D/Lab_TagDown1")
        local img_corneMark = item:FindChild("Img_CorneMark")
        local storeFound = tab_datas.StoreTagFounds[index]
        local bigTagTemp = CElementData.GetTemplate("StoreTag", storeFound.TagId)
        do  -- 名称设置
            local bigTabName = ""
            if bigTagTemp == nil then
                bigTabName = storeFound.TagName
            else
                bigTabName = bigTagTemp.Name
            end
            if bigTabName == nil then
                bigTabName = ""
            end
            GUI.SetText(labelName1, bigTabName)
            GUI.SetText(labelName2, bigTabName)
        end
        do  -- 角标设置
            if self:TagNeedShowRedPoint(storeFound.TagId) then
                item:FindChild("Img_RedPoint"):SetActive(true)
            else
                item:FindChild("Img_RedPoint"):SetActive(false)
            end
            local label_type = storeFound.LabelType
            if label_type == EStoreLabelType.EStoreLabelType_Normal then
                img_corneMark:SetActive(false)
            else
                GUITools.SetGroupImg(img_corneMark, label_type - 1)
                img_corneMark:SetActive(true)
            end
        end
    else
        if self._CurrentPage then
            self._CurrentPage:OnInitItem(item, id, index)
        end
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if id == "List_BigMenu" then
        self:OnClickBigTab(index + 1)
    else
        if self._CurrentPage then
            self._CurrentPage:OnSelectItem(item, id, index)
        end
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if id == "List_BigMenu" then

    else
        if self._CurrentPage then
            self._CurrentPage:OnSelectItemButton(button_obj, id, id_btn, index)
        end
    end
end

def.method().ReGetPageData = function(self)
    self:RequestSmallTabData(self._CurrentSelectBigTabID, self._CurrentSelectSmallTabID)
end

--------------------------------------------------------------
----请求页签数据
--------------------------------------------------------------
def.method().RequestTabsData = function(self)
    CMallMan.Instance():RequestTabs()
end

--------------------------------------------------------------
----请求小页签数据
--------------------------------------------------------------
def.method("number", "number").RequestSmallTabData = function(self, bigType, smallType)
    CMallMan.Instance():RequestSmallTypeData(bigType, smallType)
end

--------------------------------------------------------------
--处理小页签数据
--------------------------------------------------------------
def.method("table").HandleSmallTabData = function(self, data)
    if data.StoreTagId ~= self._CurrentSelectBigTabID or data.StoreId ~= self._CurrentSelectSmallTabID then return end
    local page = nil

    local key = data.StoreId
    if self._Pages ~= nil and self._Pages[key] ~= nil then
        page = self._Pages[key]
        self._CurrentPage = page
        self._CurrentPage._CachedGoodsID = self._CacheGoodsID
        page:Show(data)
    else
        page = CMallPageFactory.Instance():GenerateMallPage(self, data)
        if page then
            self._Pages[key] = page
            self._CurrentPage = page
            self._CurrentPage._CachedGoodsID = self._CacheGoodsID
            page:OnLoad()
        end
    end
    if self._CurrentPage ~= nil then
        if self._CurrentPage._IsHideTabList then
            self._PanelObjects._TabList:SetActive(false)
        else
            self._PanelObjects._TabList:SetActive(true)
        end
    end
    self._CacheGoodsID = -1
    --game._CGuideMan:AnimationEndCallBack(self)
end

--------------------------------------------------------------
--移除所有小页签上面的刷新时间timer
--------------------------------------------------------------
def.method().RemoveAllSmallTagTimer = function(self)
    for k,v in pairs(self._TagTimers) do
        if v ~= nil then
           _G.RemoveGlobalTimer(v)
        end
    end
    self._TagTimers = {}
end

--------------------------------------------------------------
--清除原来的存留的Page
--------------------------------------------------------------
def.method().CleanOldPage = function(self)
    if self._CurrentPage ~= nil then
        self._CurrentPage:Hide()
    end
end

--------------------------------------------------------------
--当前传进来的数据要显示的商店是否解锁
--------------------------------------------------------------
def.method().StoreUnlockCheck = function(self)
    if self._CacheMallID ~= -1 then
        if not CMallMan.Instance():IsStoreUnlock(self._CacheMallID) then
            local store_temp = CElementData.GetTemplate("Store", self._CacheMallID)
            if store_temp == nil then
                game._GUIMan:ShowTipText(StringTable.Get(31039), false)
            else
                game._GUIMan:ShowTipText(string.format(StringTable.Get(31040), store_temp.Name), false)
            end
            self._CacheMallID = -1
        end
    end
end

--------------------------------------------------------------
--生成大页签和小页签
--------------------------------------------------------------
def.method("table").GenerateTabs = function(self, tabDatas)
    local bigSort = -1
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    for i,v in ipairs(tab_datas.StoreTagFounds) do
        if v.TagSort > bigSort then
            bigSort = v.TagSort
            self._CurrentSelectBigTabID = v.TagId
            self._CurrentSelectSmallTabID = tonumber(v.Stores[1].StoreId)
            self._CurrentSelectBigTabIndex = i
            self._CurrentSelectSmallTabIndex = 1
        end
    end
    
    self._List_BigTab:SetItemCount(#tab_datas.StoreTagFounds)
    if self._CurrentSelectBigTabID ~= 0 then
        local smallTabCount = #tab_datas.StoreTagFounds[self._CurrentSelectBigTabIndex].Stores
        self:RemoveAllSmallTagTimer()
        self._TabList_SmallTab:SetItemCount(smallTabCount)
    else
        warn("商城小页签数据为空!!!")
    end
end

--------------------------------------------------------------
--点击大页签操作
--------------------------------------------------------------
def.method("number").OnClickBigTab = function(self, bigType)
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    if self._CurrentSelectBigTabID == tab_datas.StoreTagFounds[bigType].TagId then
        return
    else
        if tab_datas.StoreTagFounds[bigType] ~= nil and #tab_datas.StoreTagFounds[bigType].Stores ~= 0 then
            self:OnClickSmallTab(bigType, 1)
        end
        local smallTabCount = #tab_datas.StoreTagFounds[bigType].Stores
        self:RemoveAllSmallTagTimer()
        self._TabList_SmallTab:SetItemCount(smallTabCount)
        self._TabList_SmallTab:SetSelection(self._CurrentSelectSmallTabIndex - 1, 0)
    end
end

--------------------------------------------------------------
--点击小页签操作
--------------------------------------------------------------
def.method("number", "number").OnClickSmallTab = function(self, bigType, smallType)
    if self._CurrentSelectBigTabIndex == bigType and self._CurrentSelectSmallTabIndex == smallType then
        return
    else
        local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
        self._CurrentSelectBigTabIndex = bigType
        self._CurrentSelectSmallTabIndex = smallType
        self._CurrentSelectBigTabID = tab_datas.StoreTagFounds[bigType].TagId
        self._CurrentSelectSmallTabID = tab_datas.StoreTagFounds[bigType].Stores[smallType].StoreId
        if self._CurrentPage ~= nil then
            self._CurrentPage:Hide()
        end
        self:RequestSmallTabData(self._CurrentSelectBigTabID, self._CurrentSelectSmallTabID)
    end
end

--------------------------------------------------------------
--检测webview是否初始化好
--------------------------------------------------------------
def.method().CheckWebViewInit = function(self)
    if not self._IsWebViewInited then
        if self._WebView ~= nil then
            self._WebView:Init(self._PanelObjects.ViewPort)
            if not self._WebView.IsRunWindows then
                self._IsRunOnWindows = false
            else
                self._IsRunOnWindows = true
            end
            self._IsWebViewInited = true
        end
    end
end

--------------------------------------------------------------
--显示WebView
--------------------------------------------------------------
def.method("string").ShowWebView = function(self, url)
    self:CheckWebViewInit()
    if self._WebView ~= nil then
        if not self._IsRunOnWindows then
            self._WebView:Load(url)
        end
    end
end

--------------------------------------------------------------
--隐藏WebView
--------------------------------------------------------------
def.method().HideWebView = function(self)
    if self._WebView ~= nil and self._IsWebViewInited then
        self._WebView:Hide()
    end
end

--------------------------------------------------------------
--跳转到对应的页签下面(mallID是商城ID)
--------------------------------------------------------------
def.method("number").SwitchToShop = function(self, mallID)
    local bigTab = 1
    local smallTab = 1
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    for i,v in ipairs(tab_datas.StoreTagFounds) do
        for i1,v1 in ipairs(v.Stores) do
            if mallID == v1.StoreId then
                bigTab = i
                smallTab = i1
            end
        end
    end
    self:OnClickSmallTab(bigTab, smallTab)
    self:RemoveAllSmallTagTimer()
    self._TabList_SmallTab:SetItemCount(#tab_datas.StoreTagFounds[bigTab].Stores)
    GUI.SetGroupToggleOn(self._PanelObjects._List_BigTab, bigTab + 2)
    self._TabList_SmallTab:SetSelection(smallTab - 1, 0)
end

def.method("number", "number", "number").DrumpToRightStoreAndSwitchItem = function(self, tagID, storeID, goodsID)
    local big_index = 1
    local small_index = 1
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    for i,v in ipairs(tab_datas.StoreTagFounds) do
        if v.TagId == tagID then
            big_index = i
            for i1,v1 in ipairs(v.Stores) do
                if storeID == v1.StoreId then
                    small_index = i1
                end
            end
        end
    end
    self:OnClickSmallTab(big_index, small_index)
    self:RemoveAllSmallTagTimer()
    self._TabList_SmallTab:SetItemCount(#tab_datas.StoreTagFounds[big_index].Stores)
    GUI.SetGroupToggleOn(self._PanelObjects._List_BigTab, big_index + 2)
    self._TabList_SmallTab:SetSelection(small_index, 0)
end

--------------------------------------------------------------
--处理购买成功
--------------------------------------------------------------
def.method("table").HandleBuyItemSuccess = function(self, data)
    if self._Pages[data.StoreId] ~= nil then
        self._Pages[data.StoreId]:OnBuySuccess(data)
    else
        if self._CurrentPage ~= nil then
            self._CurrentPage:OnBuySuccess(data)
        end
    end
end

--------------------------------------------------------------
--请求刷新
--------------------------------------------------------------
def.method().RequestRefreshPanel = function(self)
    CMallMan.Instance():RefreshMystoryShop(self._CurrentSelectBigTabID, self._CurrentSelectSmallTabID)
end

--------------------------------------------------------------
--刷新处理
--------------------------------------------------------------
def.method("dynamic").RefreshPanel = function(self, data)
    self:UpdatePanelRedPoint()
    if data == nil then 
        if self._CurrentPage ~= nil then
            self._CurrentPage:RefreshPage()
        end
        return
    end
    if self._CurrentSelectBigTabID ~= data.StoreTagId or self._CurrentSelectSmallTabID ~= data.StoreId then return end

    CMallMan.Instance():UpdateGoods(self._CurrentPage._PageData, data)
    self._CurrentPage._PageData.RefreshCount = data.RefreshCount
    if self._CurrentPage._NeedPlayDotween then
        local callback = function()
            self._CurrentPage:Show(self._CurrentPage._PageData)
            self._CurrentPage:OnData(self._CurrentPage._PageData)
        end
        self._CurrentPage:PlayDotween(0.5, callback)
    else
        self._CurrentPage:Show(self._CurrentPage._PageData)
        self._CurrentPage:OnData(self._CurrentPage._PageData)
    end
    self._CurrentPage:InitFrameMoney()
end

def.method("table", "table").OnGainNewItem = function(self, sender, event)
    if self._CurrentPage ~= nil then
        self._CurrentPage:OnGainItem(sender, event)
    end
end

def.method("number", "number", "number", "number").SetGoodsRefreshTime = function(self, tagID, storeID, goodsID, nextTime)
    if self._CurrentPage ~= nil then
        self._CurrentPage:SetGoodsRefreshTime(tagID, storeID, goodsID, nextTime)
    end
end

def.method().UpdatePanelRedPoint = function(self)
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    for i,v in ipairs(tab_datas.StoreTagFounds) do
        local big_item = self._List_BigTab:GetItem(i - 1)
        if self:TagNeedShowRedPoint(v.TagId) then
            big_item:FindChild("Img_RedPoint"):SetActive(true)
        else
            big_item:FindChild("Img_RedPoint"):SetActive(false)
        end
    end
    local big_store = tab_datas.StoreTagFounds[self._CurrentSelectBigTabIndex]
    if big_store == nil then return end
    for i,v in ipairs(big_store.Stores) do
        local small_item = self._TabList_SmallTab:GetItem(i -1)
        if CMallMan.Instance():GetRedPointState(v.StoreId) then
            small_item:FindChild("Img_RedPoint"):SetActive(true)
        else
            small_item:FindChild("Img_RedPoint"):SetActive(false)  
        end
    end
end

def.method("number", "=>", "boolean").TagNeedShowRedPoint = function(self, tagID)
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    for i,v in ipairs(tab_datas.StoreTagFounds) do
        if v.TagId == tagID then
            for i1,v1 in ipairs(v.Stores) do
                if CMallMan.Instance():GetRedPointState(v1.StoreId) then
                    return true
                end
            end
        end
    end
    return false
end

def.method("number", "number", "boolean").ShowRedPoint = function(self, tagID, storeID, isShow)
    if not self:IsShow() then return end
    local tab_datas = CMallMan.Instance():GetTagsDataFromServer()
    local big_index = 0
    local small_index = 0
    for i,v in ipairs(tab_datas.StoreTagFounds) do
        for i1,v1 in ipairs(v.Stores) do
            if v.TagId == tagID and storeID == v1.StoreId then
                big_index = i
                small_index = i1
            end
        end
    end
    if big_index > 0 and small_index > 0 then
        local big_item = self._List_BigTab:GetItem(big_index - 1)
        --local small_item = self._TabList_SmallTab:GetItem(small_index - 1)
        local small_item = self._TabList_SmallTab:GetItem(small_index -1)
        if isShow then
            big_item:FindChild("Img_RedPoint"):SetActive(true)
            small_item:FindChild("Img_RedPoint"):SetActive(true)
        else
            small_item:FindChild("Img_RedPoint"):SetActive(false)
            if self:TagNeedShowRedPoint(tagID) then
                big_item:FindChild("Img_RedPoint"):SetActive(true)
            else
                big_item:FindChild("Img_RedPoint"):SetActive(false)
            end
        end
    end
end

def.override().OnHide = function(self)
    self:RemoveAllSmallTagTimer()
    CPanelBase.OnHide(self)
    self:HideWebView()
end

def.override().OnDestroy = function(self)
    self._PanelObjects = nil
    self._WebView = nil
    self._CurrentSelectBigTabID = 0
    self._CurrentSelectSmallTabID = 0
    self._CurrentSelectSmallTabIndex = 0
    self._CurrentPage = nil
    self._List_BigTab = nil
    self._TabList_SmallTab = nil
    self._CurrentSelectBigTabIndex = 0
    self._IsWebViewInited = false
    self._CacheMallID = -1
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
    if self._Pages ~= nil then
        for _,v in pairs(self._Pages) do
            v:OnHide()
            v:OnDestory()
        end
        self._Pages = {}
    end
    CMallMan.Instance():Clear()
end
CPanelMall.Commit()
return CPanelMall