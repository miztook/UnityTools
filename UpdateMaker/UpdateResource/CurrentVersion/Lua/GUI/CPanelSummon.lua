local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CMallPageBase = require "Mall.CMallPageBase"
local CSummonPageFactory = require "Mall.CSummonPageFactory"
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local EStoreLabelType = require "PB.data".EStoreLabelType

local CPanelSummon = Lplus.Extend(CPanelBase, 'CPanelSummon')
local def = CPanelSummon.define


local instance = nil

def.field("table")._PanelObjects = BlankTable
def.field("number")._CacheMallID = -1                   -- 从外部调用传进来的参数
def.field("userdata")._TabList_SmallTab = nil           -- 小页签TabList
def.field("userdata")._VideoPlayer_Pet = nil
def.field("userdata")._Img_Screen_Video = nil
def.field("userdata")._VideoPlayer_Elf = nil
def.field("number")._CurrentSelectBigTabID = 0
def.field("number")._CurrentSelectSmallTabID = 0        -- 当前选择的小页签ID
def.field("number")._CurrentSelectSmallTabIndex = 0     -- 当前选择的小页签的index
def.field("table")._Pages = BlankTable                  -- 缓存所有的Page
def.field("table")._CurrentPage = nil                   -- 当前显示的Page
def.field(CFrameCurrency)._Frame_Money = nil

def.static('=>', CPanelSummon).Instance = function ()
	if not instance then
        instance = CPanelSummon()
        instance._PrefabPath = PATH.UI_Summon
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects.Frame_Content = self:GetUIObject("Frame_Content")
    self._PanelObjects._TabList = self:GetUIObject("TabList")
    self._TabList_SmallTab = self:GetUIObject("TabList"):GetComponent(ClassType.GNewTabList)

    self._VideoPlayer_Elf = self:GetUIObject("VideoPlayer_Elf")
    self._VideoPlayer_Pet = self:GetUIObject("VideoPlayer_Pet")
    self._Img_Screen_Video = self:GetUIObject("Img_Video")
    self._Img_Screen_Video:SetActive(false)

    GameUtil.PrepareVideoUnit(self._VideoPlayer_Pet, "Mall_CG02_Loop.mp4")
    GameUtil.PrepareVideoUnit(self._VideoPlayer_Elf, "Mall_CG01_Loop.mp4")
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
    self._HelpUrlType = HelpPageUrlType.MallExtract
    CMallMan.Instance():RequestTabs()
end

--------------------------------------------------------
--客户端收到页签数据之后在初始化面板
--------------------------------------------------------
def.method().Init = function(self)
    self:CleanOldPage()
    self:StoreUnlockCheck()
    self:GenerateTabs()
    if self._CacheMallID ~= -1 then
        self._CurrentSelectBigTabID = 0
        self._CurrentSelectSmallTabIndex = 0
        self:SwitchToShop(self._CacheMallID)
        self._TabList_SmallTab:SetSelection(self._CurrentSelectSmallTabIndex - 1, 0)
    else
        self:RequestSmallTabData(self._CurrentSelectBigTabID, self._CurrentSelectSmallTabID)
        self._TabList_SmallTab:SetSelection(self._CurrentSelectSmallTabIndex - 1, 0)
    end
    self:UpdatePanelRedPoint()
    game._CGuideMan:TriggerDelayCallBack()
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

def.override("string", "boolean").OnToggle = function(self, id, checked)
    if self._CurrentPage then
        self._CurrentPage:OnToggle(id, checked)
    end
end


def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
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

def.method().PlayVideoBG = function(self)
    if self._CurrentPage then
        self._CurrentPage:PlayVideoBG()
    end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    local tab_datas = CMallMan.Instance():GetSummonTagsDataFromServer()
    if list.name == "TabList" then
        if sub_index == -1 then
            local index = main_index + 1
            local labelName1 = item:FindChild("Lab_Text")
            local storeFound = tab_datas[index]
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
           
        elseif sub_index ~= -1 then
             -- 召唤现在还没有子商店
        end
    end
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    if list.name == "TabList" then
        if sub_index == -1 then
            local bigTypeIndex = main_index + 1
            self:OnClickSmallTab(bigTypeIndex)
        elseif sub_index ~= -1 then
            -- 召唤现在还没有子商店
        end
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if self._CurrentPage then
        self._CurrentPage:OnInitItem(item, id, index)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if self._CurrentPage then
        self._CurrentPage:OnSelectItem(item, id, index)
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    if self._CurrentPage then
        self._CurrentPage:OnSelectItemButton(button_obj, id, id_btn, index)
    end
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
        page:Show(data)
    else
        page = CSummonPageFactory.Instance():GenerateSummonPage(self, data)
        if page then
            self._Pages[key] = page
            self._CurrentPage = page
--            page:Hide()
            page:OnLoad()
        end
    end
    if self._CurrentPage ~= nil then
        if self._CurrentPage._IsHideTabList then
            self._PanelObjects._TabList:SetActive(false)
        else
            self._PanelObjects._TabList:SetActive(true)
        end
        if self._CurrentPage._HasBGVideo then
            self._Img_Screen_Video:SetActive(true)
        else
            self._Img_Screen_Video:SetActive(false)
        end
    end
    game._CGuideMan:AnimationEndCallBack(self)
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
--生成小页签
--------------------------------------------------------------
def.method().GenerateTabs = function(self)
    local tab_datas = CMallMan.Instance():GetSummonTagsDataFromServer()
    if #tab_datas > 0 then
        self._CurrentSelectSmallTabID = tonumber(tab_datas[1].StoreId)
        self._CurrentSelectBigTabID = tab_datas[1].BigTagID
        self._CurrentSelectSmallTabIndex = 1
    else
        self._CurrentSelectSmallTabID = 0
        self._CurrentSelectBigTabID = 0
        self._CurrentSelectSmallTabIndex = 0
    end

    local smallTabCount = #tab_datas
    self._TabList_SmallTab:SetItemCount(smallTabCount)
end

--------------------------------------------------------------
--点击小页签操作
--------------------------------------------------------------
def.method("number").OnClickSmallTab = function(self, smallType)
    if self._CurrentSelectSmallTabIndex == smallType then
        return
    else
        local tab_datas = CMallMan.Instance():GetSummonTagsDataFromServer()
        self._CurrentSelectSmallTabIndex = smallType
        self._CurrentSelectSmallTabID = tab_datas[smallType].StoreId
        self._CurrentSelectBigTabID = tab_datas[smallType].BigTagID
        if self._CurrentPage ~= nil then
            self._CurrentPage:Hide()
        end
        self:RequestSmallTabData(self._CurrentSelectBigTabID, self._CurrentSelectSmallTabID)
    end
end

--------------------------------------------------------------
--跳转到对应的页签下面(mallID是商城ID)
--------------------------------------------------------------
def.method("number").SwitchToShop = function(self, mallID)
    local smallTab = 1
    local tab_datas = CMallMan.Instance():GetSummonTagsDataFromServer()
    for i,v in ipairs(tab_datas) do
        if mallID == v.StoreId then
            smallTab = i
        end
    end
    self:OnClickSmallTab(smallTab)
    self._TabList_SmallTab:SetSelection(smallTab - 1, 0)
end

----------------------------------------------------------------
----刷新处理
----------------------------------------------------------------
--def.method("dynamic").RefreshPanel = function(self, data)
--    self:UpdatePanelRedPoint()
--    if data == nil then 
--        if self._CurrentPage ~= nil then
--            self._CurrentPage:RefreshPage()
--        end
--        return
--    end
--    self._CurrentPage:Show(self._CurrentPage._PageData)
--    self._CurrentPage:OnData(self._CurrentPage._PageData)

--    self._CurrentPage:InitFrameMoney()
--end

def.method("table", "table").OnGainNewItem = function(self, sender, event)
    if self._CurrentPage ~= nil then
        self._CurrentPage:OnGainItem(sender, event)
    end
end

def.method().UpdatePanelRedPoint = function(self)
    local tab_datas = CMallMan.Instance():GetSummonTagsDataFromServer()
    for i,v in ipairs(tab_datas) do
        local small_item = self._TabList_SmallTab:GetItem(i -1)
        if CMallMan.Instance():GetSummonRedPointState(v.StoreId) then
            small_item:FindChild("Img_RedPoint"):SetActive(true)
        else
            small_item:FindChild("Img_RedPoint"):SetActive(false)  
        end
    end
end

def.method("number", "boolean").ShowRedPoint = function(self, storeID, isShow)
    if not self:IsShow() then return end
    local tab_datas = CMallMan.Instance():GetSummonTagsDataFromServer()
    local small_index = 0
    for i,v in ipairs(tab_datas) do
        if storeID == v.StoreId then
            small_index = i
        end
    end
    if small_index > 0 then
        local small_item = self._TabList_SmallTab:GetItem(small_index -1)
        if isShow then
            small_item:FindChild("Img_RedPoint"):SetActive(true)
        else
            small_item:FindChild("Img_RedPoint"):SetActive(false)
        end
    end
end

-- 返回键
def.override("=>", "boolean").HandleEscapeKey = function(self)
    if self:IsOpen() then
        if self._CurrentPage ~= nil then 
            if self._CurrentPage:HandleEscapeKey() then
                return true
            end
        end
        game._GUIMan:CloseByScript(self)
        return true
    else
        return false
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    self._PanelObjects = nil
    self._CurrentSelectSmallTabID = 0
    self._CurrentSelectSmallTabIndex = 0
    self._CurrentPage = nil
    self._TabList_SmallTab = nil
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
    GameUtil.ReleaseVideoUnit(self._VideoPlayer_Elf)
    GameUtil.ReleaseVideoUnit(self._VideoPlayer_Pet)
    self._VideoPlayer_Pet = nil
    self._VideoPlayer_Elf = nil
    self._Img_Screen_Video = nil
end
CPanelSummon.Commit()
return CPanelSummon