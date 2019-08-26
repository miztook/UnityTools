local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CPanelUIManual = Lplus.Extend(CPanelBase, 'CPanelUIManual')
local def = CPanelUIManual.define
local CElementData = require "Data.CElementData"
local CPageManual = require "GUI.CPageManual"
local CPageAchievement =  require "GUI.CPageAchievement"

def.field("table")._FrameTable = nil  -- 不同frame
def.field("table")._ToggleTable = nil -- 六个页签的toggle
--def.field("userdata")._Frame_Info = nil
def.field("number")._CurFrameType = 1 -- 当前页
def.field("table")._TableFrameIsInit = nil

def.field(CPageManual)._ManualPage = nil  -- 万物志页
def.field(CPageAchievement)._Achievement = nil --成就页

def.field("dynamic")._CurPageClass = nil                -- 当前页的类
def.field("table")._ManualsTable = BlankTable                  -- 所有的表
def.field('userdata')._FrameTopTabs = nil

local instance = nil
def.static('=>', CPanelUIManual).Instance = function ()
    if not instance then
        instance = CPanelUIManual()
        instance._PrefabPath = PATH.UI_Manual
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        
        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    self._FrameTable = {}
    for i = 1,2 do
        self._FrameTable[i] = self:GetUIObject('Frame_'..i)
    end
    self._FrameTopTabs = self:GetUIObject("Frame_TopTabs")
    if next(self._FrameTable) == nil then
        FlashTip("面板UI错误！！","tip",5)
        game._GUIMan:Close("CPanelUIManual")
        return
    end
    for _,v in ipairs(self._FrameTable) do
        if not IsNil(v) then
            v:SetActive(false)
        end
    end

    self._ToggleTable = {}
    for i = 1,2 do
        self._ToggleTable[i] = self: GetUIObject("Rdo_"..i):GetComponent(ClassType.Toggle)
    end

    self._Achievement = CPageAchievement.new(self,self._FrameTable[1])
    self._ManualPage = CPageManual.GetInstance(self, self._FrameTable[2])

    self._ManualsTable =
    {
        [1] = {data = self._Achievement, HelpUrlType = HelpPageUrlType.Achievement},
        [2] = {data = self._ManualPage, HelpUrlType = HelpPageUrlType.Manual},
    }
    self._CurPageClass = nil
    self._CurFrameType = 1
end

-- @param data 结构如下
--        _info 需要传入面板的数据
--        _type 打开的类型
def.override("dynamic").OnData = function(self,data)
    CPanelBase.OnData(self,data)
    --GameUtil.LayoutTopTabs(self._FrameTopTabs)
    local openType = 1 -- 默认开启页面
    local uiData = nil
    if data ~= nil then
        uiData = data._info
        if data._type ~= nil then
        openType = data._type
        end
    end
    if not IsNil(self._ToggleTable[openType]) then
        self._ToggleTable[openType].isOn = true
    end

    self:ShowFrame(openType, uiData)
end

def.method("number", "dynamic").ShowFrame = function (self, nType, uiData)
    if nType ~= self._CurFrameType then
        self._FrameTable[self._CurFrameType]:SetActive(false)
    end
    if IsNil(self._FrameTable[nType]) then 
        FlashTip("UI找不到"..nType.."页面","tip",5)
        game._GUIMan:Close("CPanelUIManual")
        return
    end
    self._FrameTable[nType]:SetActive(true)
    self._CurFrameType = nType
   
    if self._CurPageClass ~= nil then
        self._CurPageClass:Hide()
    end
    if self._ManualsTable[nType] == nil then
        --self._Frame_Info:SetActive(false)
        self._CurPageClass = nil
        -- game._GUIMan:Close("CPanelUIManual")
        return
    else
        --self._Frame_Info:SetActive(true)
    end

    self._CurPageClass = self._ManualsTable[nType].data
    self._HelpUrlType = self._ManualsTable[nType].HelpUrlType
    self._CurPageClass:Show(uiData)
    self:ShowManualRedPoint()
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self,id)
    if id == "Btn_Back" then
        game._GUIMan:Close("CPanelUIManual")
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id ~= self._HelpUrlBtnName then
        self._CurPageClass:ParentClick(id)
    end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if string.find(id, "Rdo_") and checked then
        -- 一级页签
        local rdoIndex = tonumber(string.sub(id, string.len("Rdo_")+1,-1))
        if rdoIndex == nil or rdoIndex == self._CurFrameType then return end
        self:ShowFrame(rdoIndex, nil)
    else
        --self._CurPageClass:ParentToggle(id, checked)
    end
end

--初始化，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListInitItem = function(self, list, item, main_index, sub_index)
    self._CurPageClass:ParentTabListInitItem(list, item, main_index, sub_index)
end

--点中，sub_index为-1时是第一级，否则是二级
def.override("userdata", "userdata", "number", "number").OnTabListSelectItem = function(self, list, item, main_index, sub_index)
    self._CurPageClass:ParentTabListSelectItem(list, item, main_index, sub_index)
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    self._CurPageClass:ParentInitItem(item, id, index)
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    self._CurPageClass:ParentSelectItem(item, id, index)
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    self._CurPageClass:ParentSelectItemButton(item, id, id_btn, index)
end

def.override("userdata", "userdata", "number", "number").OnTabListItemButton  = function(self, list, item, main_index, sub_index)
    self._CurPageClass:ParentSelectTabListItemButton(list,item, main_index,sub_index)
end


def.method("number").RevGetAchievementReward = function(self,achiID)
    if self._CurPageClass == self._Achievement then
        self._Achievement:RevGetReward(achiID)
    end
end

--刷新页面
def.method().FreshAchievementPage = function(self)
    if self._CurPageClass == self._Achievement then
        self._Achievement:FreshPage()
    end

    self: FreshAchievementRedPoint()
end

--刷新成就小红点
def.method().FreshAchievementRedPoint = function(self)
    --成就小红点
    local imgRed = self: GetUIObject("Rdo_1"): FindChild("Img_RedPoint")
    if not IsNil(imgRed) then
        imgRed: SetActive(game._AcheivementMan:NeedShowRedPoint())
    end
end

def.method().ShowManualRedPoint = function (self)
    local imgRed = self:GetUIObject("Rdo_2"):FindChild("Img_RedPoint")
    if not IsNil(imgRed) then
        imgRed:SetActive(game._CManualMan:IsShowManualRedPoint())
    end
end


def.override().OnDestroy = function(self)
    self._FrameTopTabs = nil
    for _, v in pairs(self._ManualsTable) do
        v.data:Destroy()
        v = nil
    end
    self._CurPageClass = nil
    self._ManualsTable = {}
end

CPanelUIManual.Commit()
return CPanelUIManual