local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
local PackageChangeEvent = require "Events.PackageChangeEvent"
local GainNewItemEvent = require "Events.GainNewItemEvent"
local NotifyPropEvent = require "Events.NotifyPropEvent"
local CharmOptionEvent = require "Events.CharmOptionEvent"
local CElementData = require "Data.CElementData"
local ECharmSize = require "PB.data".ECharmSize
local ECharmColor = require "PB.data".ECharmColor
local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
local CCharmMan = require "Charm.CCharmMan"
local CCharmPageInlay = require "Charm.CCharmPageInlay"
local CCharmPageCompose = require "Charm.CCharmPageCompose"
local CFrameCurrency = require "GUI.CFrameCurrency"
local CPanelCharm = Lplus.Extend(CPanelBase, 'CPanelCharm')
local def = CPanelCharm.define
local instance = nil


--当前的页签类型
local FrameType =
{
    CharmInlay     = 1,
    CharmCompose   = 2,
    Max            = 3,
}

local CharmAddAttrColors = {
    Red = Color.New(211/255, 53/255, 31/255, 0),
    Yellow = Color.New(235/255, 183/255, 20/255, 0),
    Blue = Color.New(76/255, 142/255, 255/255, 0),
    Green = Color.New(127/255, 188/255, 58/255, 0),
}

local OnHostPlayerLevelChangeEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdatePanel()
    end
end

local OnOptionFieldEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:HandleOption(event)
    end
end

local OnPackageChangeEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateAllPageItems()
        local CharmOptionEvent = require "Events.CharmOptionEvent"
	    local event = CharmOptionEvent()
        event._Option = "PackageChange"
        instance:HandleOption(event)
        instance:UpdatePanel()
    end
end

local OnGainNewItemEvent = function(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:UpdateAllPageItems()
        local CharmOptionEvent = require "Events.CharmOptionEvent"
	    local newEvent = CharmOptionEvent()
        newEvent._CharmID = event.ItemUpdateInfo.UpdateItem.ItemData.Tid
        newEvent._Option = "GainNewItem"
        newEvent._ItemUpdateInfo = event.ItemUpdateInfo
        instance:HandleOption(newEvent)
        instance:UpdatePanel()
    end
end

def.field("table")._PanelObject = nil                       -- 存储UI的集合，便于OnHide()时置空
def.field("table")._AllPages = nil                          -- 缓存生成的所有Pages
def.field("table")._CurrentPage = nil                       -- 当前打开的Page
def.field("number")._CurPageIndex = FrameType.CharmInlay    -- 当前打开的Page的index
def.field("number")._CharmMaxLevel = 10                     -- 神符的最大等级
def.field("number")._CharmMaxLevelSpecialID = 570           -- 神符的最大等级特殊ID

def.field(CFrameCurrency)._Frame_Money = nil

def.static('=>', CPanelCharm).Instance = function ()
    if not instance then
        instance = CPanelCharm()
        instance._PrefabPath = PATH.UI_Charm
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

def.method("number").SetCurPageIndex = function (self, index)
    self._CurPageIndex = index
end

def.override().OnCreate = function(self)
    self._PanelObject = {}
    self._PanelObject._Rdo_TagGroup = self:GetUIObject("Rdo_TagGroup")
    self._PanelObject._Frame_SideTabs = self:GetUIObject("Frame_SideTabs")
    self._HelpUrlType = HelpPageUrlType.Charm
end

--{pageType = 1, data = nil or 1}
def.override("dynamic").OnData = function (self,data)
    self._AllPages = {}
    self:SetCurPageIndex(FrameType.CharmInlay)
    self._CharmMaxLevel = tonumber(CElementData.GetSpecialIdTemplate(self._CharmMaxLevelSpecialID).Value)
    self:GeneratePages(data)
    if data ~= nil then
        if data.pageType ~= nil and data.pageType < FrameType.Max then
            self:SetCurPageIndex(data.pageType)
        end
        -- self._CurPageIndex + 1 是因为第一个是一个背景图
        GUI.SetGroupToggleOn(self._PanelObject._Rdo_TagGroup, self._CurPageIndex + 1)
    end
    self._CurrentPage = self._AllPages[self._CurPageIndex]
    self._CurrentPage:ShowPage(data.data)
    self:UpdatePanel()
    self:UpdateMoneyPanel()
   
    CGame.EventManager:addHandler("HostPlayerLevelChangeEvent", OnHostPlayerLevelChangeEvent)
    CGame.EventManager:addHandler(CharmOptionEvent, OnOptionFieldEvent)
    CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
    CGame.EventManager:addHandler(GainNewItemEvent, OnGainNewItemEvent)
end

def.method("dynamic").GeneratePages = function(self, data)
    local pageInlay = CCharmPageInlay.new()
    local pageCompose = CCharmPageCompose.new()
    pageInlay:Init(self, data.data)
    pageCompose:Init(self, data.data)
    self._AllPages[#self._AllPages + 1] = pageInlay
    self._AllPages[#self._AllPages + 1] = pageCompose
    for _,v in ipairs(self._AllPages) do
        v:HidePage()
    end
end

def.method("number", "dynamic").ChangePage = function(self, pageIndex, data)
    if pageIndex >= FrameType.Max then return end
    if self._CurrentPage ~= nil then
        self._CurrentPage:HidePage()
    end
    self:SetCurPageIndex(pageIndex)
    self._CurrentPage = self._AllPages[pageIndex]
    self._CurrentPage:ShowPage(data)
    GUI.SetGroupToggleOn(self._PanelObject._Rdo_TagGroup, self._CurPageIndex + 1)
end

def.method("table").HandleOption = function(self, event)
--    for _,v in pairs(self._AllPages) do
--        v:HandleOption(event)
--    end
    self._CurrentPage:HandleOption(event)
end

def.method().UpdateMoneyPanel = function(self)
    if self._Frame_Money == nil then
        self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)
        self._Frame_Money:Update()
	else
    	self._Frame_Money:Update()
    end
end

def.method().UpdateAllPageItems = function(self)
    if self._AllPages ~= nil and #self._AllPages > 0 then
        for _,v in ipairs(self._AllPages) do
            v:GetAllCharmItems()
        end
    end
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
		return
    elseif id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
        return
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
        return
    elseif id == "Btn_MallEnter" then
        local shopID = tonumber(CElementData.GetSpecialIdTemplate(903).Value)
        game._GUIMan:Open("CPanelMall", shopID)
    elseif id == "Btn_Dungeon1" then
        if game._CFunctionMan:IsUnlockByFunTid(14) then
            if game._CCalendarMan:IsCalendarOpenByPlayID(402) then
                game._GUIMan:Open("CPanelUIDungeon", 402)
            else
                game._GUIMan:ShowTipText(StringTable.Get(19469), true)
            end
        else
            game._CGuideMan:OnShowTipByFunUnlockConditions(0, 14)
        end
    elseif id == "Btn_Dungeon2" then
        if game._CFunctionMan:IsUnlockByFunTid(95) then
            if game._CCalendarMan:IsCalendarOpenByPlayID(502) then
                game._GuildMan:OpenGuildBattle()
            else
                game._GUIMan:ShowTipText(StringTable.Get(19469), true)
            end
        else
            game._CGuideMan:OnShowTipByFunUnlockConditions(0, 95)
        end
    elseif id == "Btn_Dungeon3" then
        if game._CFunctionMan:IsUnlockByFunTid(19) then
            if game._CCalendarMan:IsCalendarOpenByPlayID(406) then
                game._CArenaMan:OnOpenBattle()
            else
                game._GUIMan:ShowTipText(StringTable.Get(19469), true)
            end
        else
            game._CGuideMan:OnShowTipByFunUnlockConditions(0, 19)
        end
    elseif id == "Btn_DiamondShopEnter" then
        --local shopID = tonumber(CElementData.GetSpecialIdTemplate(901).Value)
        game._GUIMan:Open("CPanelMall", 22)
    else
        if self._CurrentPage ~= nil then
            self._CurrentPage:OnClick(id)
        end
    end
end


def.override("string", "boolean").OnToggle = function(self,id, checked)
    if id == "Rdo_BtnCharm" then
        self:SetCurPageIndex(FrameType.CharmInlay)
        if self._CurrentPage ~= nil then
            self._CurrentPage:HidePage()
        end
        self._CurrentPage = self._AllPages[self._CurPageIndex]
        self._CurrentPage:ShowPage(nil)
        self:UpdatePanel()
    elseif id == "Rdo_BtnCompose" then
        self:SetCurPageIndex(FrameType.CharmCompose)
        if self._CurrentPage ~= nil then
            self._CurrentPage:HidePage()
        end
        self._CurrentPage = self._AllPages[self._CurPageIndex]
        self._CurrentPage:ShowPage(nil)
        self:UpdatePanel()
    else
        if self._CurrentPage ~= nil then
            self._CurrentPage:OnToggle(id, checked)
        end
    end
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if self._CurrentPage ~= nil then
        self._CurrentPage:OnDropDown(id, index)
    end
end


-------------------------------------------------------
--更新整个神符Panel
-------------------------------------------------------
def.method().UpdatePanel = function(self)
    if self._CurrentPage == nil then
        warn("CPanelCharm.UpdatePanel 当前页签为空~！！")
        return
    end
    self._CurrentPage:RefreshPageUI()
end

-- 更新右侧的背包数量信息（Frame_SideTabs）
def.method("table").UpdateSideTabs = function(self, countTable)
    if countTable == nil or #countTable == 0 then return end
    local num1 = countTable[1]
    local uiTemplate = self._PanelObject._Frame_SideTabs:GetComponent(ClassType.UITemplate)
    local lab_count1 = uiTemplate:GetControl(0)
    GUI.SetText(lab_count1, string.format(StringTable.Get(21516), num1))
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if self._CurrentPage ~= nil then
        self._CurrentPage:OnInitItem(item, id, index)
    end
end
-------------------------------------------------
--点击神符列表Item里面的按钮
-------------------------------------------------
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, list_name, button_name, index)
    if self._CurrentPage ~= nil then
        self._CurrentPage:OnSelectItemButton(button_obj, list_name, button_name, index)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    if self._CurrentPage ~= nil then
        self._CurrentPage:OnSelectItem(item, id, index)
    end
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
    CGame.EventManager:removeHandler("HostPlayerLevelChangeEvent", OnHostPlayerLevelChangeEvent)
    CGame.EventManager:removeHandler(CharmOptionEvent, OnOptionFieldEvent)
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
    CGame.EventManager:removeHandler(GainNewItemEvent, OnGainNewItemEvent)
end

def.override().OnDestroy = function(self)
    if self._Frame_Money ~= nil then
		self._Frame_Money:Destroy()
		self._Frame_Money = nil
	end
    self._PanelObject = {}
    for _,v in ipairs(self._AllPages) do
        v:OnDestory()
    end
    self._CurrentPage = nil
    self._AllPages = nil
end

CPanelCharm.Commit()
return CPanelCharm