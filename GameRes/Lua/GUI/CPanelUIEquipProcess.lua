local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local bit = require "bit"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local CConsumeUtil = require "Utility.CConsumeUtil"
local CFrameCurrency = require "GUI.CFrameCurrency"
local UserData = require "Data.UserData"

local BAGTYPE = require "PB.net".BAGTYPE
local EResourceType = require "PB.data".EResourceType
local EItemDevType = require "PB.data".ItemDev
local ERROR_CODE = require "PB.data".ServerMessageEquip

local CPageEquipFortity = require "EquipProcessing.CPageEquipFortity"
local CPageEquipRecast = require "EquipProcessing.CPageEquipRecast"
local CPageEquipRefine = require "EquipProcessing.CPageEquipRefine"
local CPageEquipLegend = require "EquipProcessing.CPageEquipLegend"
local CPageEquipInherit = require "EquipProcessing.CPageEquipInherit"

local EquipProcessingChangeEvent = require "Events.EquipProcessingChangeEvent"

local CPanelUIEquipProcess = Lplus.Extend(CPanelBase, 'CPanelUIEquipProcess')
local def = CPanelUIEquipProcess.define

def.field("table")._PanelObject = BlankTable                -- 存储界面节点的集合
def.field(CFrameCurrency)._Frame_Money = nil                -- 金币通用组件
def.field("userdata")._ItemList = nil                       -- 背包列表
def.field("userdata")._List_NoneMaterial = nil              -- 获取途径列表
def.field("number")._CurrentSortQuality = -1                -- 当前筛选品质

def.field("table")._AllLocalItemList = BlankTable           -- 本地全部数据结构
def.field("table")._LocalItemList = BlankTable              -- 本地数据结构
def.field("table")._ProcessFrames = BlankTable              -- 加工的界面集合
def.field("table")._CategoryToggleList = BlankTable         -- 右侧类别栏toggle的集合
def.field("table")._PageToggleList = BlankTable             -- 左上功能栏toggle的集合
def.field("table")._PageRedDotList = BlankTable             -- 页签红点的集合
def.field("userdata")._Tab_NoneMaterial = nil               -- 没有强化材料时，出现的获取途径
def.field("table")._InforceStoreFromInfo = BlankTable       -- 强化石来源信息表

def.field("number")._CurrentPage = 0                        -- 当前选择的界面
def.field("number")._CurrentCategory = 0                    -- 当前选择的类别
def.field("table")._CurrentSelectIndexList = BlankTable     -- 当前选择物品的Index列表,按类别分类
def.field("table")._CurrentTargetSelectInfo = BlankTable   -- 当前继承物品
def.field("table")._ItemData = nil                          -- 当前选中Item
def.field("table")._InheritTargetItemData = nil             -- 
def.field("number")._InheritDotweenTimeDelay = 2
def.field("number")._InheritTimerId = 0
def.field("boolean")._ShowGfx = false
def.field("number")._fristSortItemID = -1

local listQuality = 
{   
    0, -- 普通
    1, -- 高级
    2, -- 稀有
    3, -- 史诗
    5, -- 传说
    6, -- 起源
}
--[[
    -- 物品 分类 集合标志(用于装备加工界面)
    ItemCategory =
    {
        Weapon = 1,     -- 武器
        Armor = 2,      -- 防具
        Jewelry = 3,    -- 首饰
        EquipProcessMaterial = 4,   -- 材料
    },
]]

local instance = nil
def.static('=>', CPanelUIEquipProcess).Instance = function ()
    if not instance then
        instance = CPanelUIEquipProcess()
        instance._PrefabPath = PATH.UI_EquipProcess
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

local RemoveInheritTimer = function()
    if instance and instance:IsShow() then
        if instance._InheritTimerId > 0 then
            _G.RemoveGlobalTimer(instance._InheritTimerId)
        end
    end
end

local OnEquipProcessingChangeEvent = function(sender, event)
    if instance:IsShow() then
        local itemData = clone(instance._ItemData)

        local function DoRefresh()
            -- 重置界面内容
            instance:GetCurrentPage():Reset()
            -- 同步背包数据
            instance:SyncPackageData(nil)
            -- 更新类别数据个数
            instance:UpdateCategoryCount()
            -- 同步选中装备
            instance:SyncSelectItemData()
            -- 刷新
            instance:UpdateFrameShow()
            -- 刷新item
            instance:UpdateItemList()
            -- 更新功能页签红点信息
            --instance:UpdatePageRedDot()
        end

        if event._Msg.devTpye ~= EItemDevType.INHERIT then
            DoRefresh()
        end

        if event._Msg ~= nil then
            local result = event._Msg.result

            if event._Msg.devTpye == EItemDevType.REBUILD then
            -- 重铸
                if result == 0 then
                    game._GUIMan:Close("CPanelUIEquipRecastResult")
                    instance:GetCurrentPage():PlayGfx()
                    
                    local data = 
                    {
                        PackageType = instance._ItemData.PackageType,
                        ItemData = instance._ItemData.ItemData,
                        ShowGfx = instance._ShowGfx
                    }
                    game._GUIMan:Open("CPanelUIEquipRecastResult", data)
                    if instance._ShowGfx then
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Start, 0)
                    end
                end
            elseif event._Msg.devTpye == EItemDevType.QUENCH then
            -- 淬火
                if result == 0 then
                    instance:GetCurrentPage():UpdateQuenchData(itemData)
                end
            elseif event._Msg.devTpye == EItemDevType.SURMOUNT then
            -- 突破
            elseif event._Msg.devTpye == EItemDevType.INHERIT then
            -- 继承
                instance:GetCurrentPage():PlayGfx()

                local data = 
                {
                    Old = event._Msg.itemCell.ItemData,
                    New = event._Msg.itemCell2.ItemData,
                    ShowGfx = instance._ShowGfx
                }
                game._GUIMan:Open("CPanelUIEquipInheritResult", data)

                local function callback()
                    DoRefresh()

                    instance._ProcessFrames[EnumDef.UIEquipPageState.PageInherit]:ResetTarget()
                    instance:ResetTargetSelect()
                    instance:ResetSelectList()
                    instance:UpdateFrameShow()
                    instance:UpdateItemList()
                end
                RemoveInheritTimer()
                if instance._ShowGfx then
                    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Start, 0)
                end

                if instance._ShowGfx then
                    instance._InheritTimerId = _G.AddGlobalTimer(instance._InheritDotweenTimeDelay, true, callback)
                else
                    callback()
                end
            elseif event._Msg.devTpye == EItemDevType.REFINE then
            -- 精炼
                instance:GetCurrentPage():PlayGfx()
            elseif event._Msg.devTpye == EItemDevType.TALENTCHANGE then
            -- 传奇属性转化
                if result == 0 then
                    game._GUIMan:Close("CPanelUIEquipLegendResult")
                    instance:GetCurrentPage():UIProcessingLogic()
                    instance:GetCurrentPage():PlayGfx()
                    
                    local data = 
                    {
                        PackageType = instance._ItemData.PackageType,
                        ItemData = instance._ItemData.ItemData,
                        ShowGfx = instance._ShowGfx
                    }
                    game._GUIMan:Open("CPanelUIEquipLegendResult", data)
                    if instance._ShowGfx then
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Start, 0)
                    end
                end
            elseif event._Msg.devTpye == EItemDevType.INFORCE then
            -- 强化
                --warn("OnEquipProcessingChangeEvent::强化")
                if result == 0 or 
                   result == ERROR_CODE.EquipInforceFaild or
                   result == ERROR_CODE.EquipInforceFaildButSafe or
                   result == ERROR_CODE.EquipInforceFaildDown then

                    instance:GetCurrentPage():UIProcessingLogic()
                    instance:GetCurrentPage():PlayGfx()

                    local data = 
                    {
                        Old = itemData.ItemData,
                        New = event._Msg.itemCell.ItemData,
                        Success = result == 0,
                        Restitution = result == ERROR_CODE.EquipInforceFaild,
                        ShowGfx = instance._ShowGfx
                    }
                    game._GUIMan:Open("CPanelUIEquipFortityResult", data)
                    if instance._ShowGfx then
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Start, 0)
                    end
                end
            else
                -- warn("Unknown ItemDevType : CPanelUIEquipProcess:OnEquipProcessingChangeEvent")
                return
            end
        else
            -- warn("Unknown event msg : CPanelUIEquipProcess:OnEquipProcessingChangeEvent")
            return
        end
    end
end

def.override().OnCreate = function(self)
    self._ProcessFrames = {}
    self._ProcessFrames[EnumDef.UIEquipPageState.PageFortify] = CPageEquipFortity.new(self, self:GetUIObject("Frame_Fortify"))
    self._ProcessFrames[EnumDef.UIEquipPageState.PageRecast] = CPageEquipRecast.new(self, self:GetUIObject("Frame_Recast"))
    self._ProcessFrames[EnumDef.UIEquipPageState.PageRefine] = CPageEquipRefine.new(self, self:GetUIObject("Frame_Refine"))
    self._ProcessFrames[EnumDef.UIEquipPageState.PageLegendChange] = CPageEquipLegend.new(self, self:GetUIObject("Frame_Legend"))
    self._ProcessFrames[EnumDef.UIEquipPageState.PageInherit] = CPageEquipInherit.new(self, self:GetUIObject("Frame_Inherit"))
    -- 当前选择物品的Index列表,按类别分类
    self:ResetSelectList()

    -- UI
    self._CategoryToggleList = {}
    self._CategoryToggleList[EnumDef.ItemCategory.Weapon] = self:GetUIObject('Rdo_Weapon')      -- 武器
    self._CategoryToggleList[EnumDef.ItemCategory.Armor] = self:GetUIObject('Rdo_Armor')        -- 防具
    self._CategoryToggleList[EnumDef.ItemCategory.Jewelry] = self:GetUIObject('Rdo_Jewelry')    -- 首饰
    self._CategoryToggleList[EnumDef.ItemCategory.EquipProcessMaterial] = self:GetUIObject('Rdo_Material')  -- 材料

    -- 功能页签
    self._PageToggleList = {}
    self._PageToggleList[EnumDef.UIEquipPageState.PageFortify] = self:GetUIObject("Rdo_Fortify"):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIEquipPageState.PageRecast] = self:GetUIObject("Rdo_Recast"):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIEquipPageState.PageRefine] = self:GetUIObject("Rdo_Refine"):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIEquipPageState.PageLegendChange] = self:GetUIObject("Rdo_Legend"):GetComponent(ClassType.Toggle)
    self._PageToggleList[EnumDef.UIEquipPageState.PageInherit] = self:GetUIObject("Rdo_Inherit"):GetComponent(ClassType.Toggle)
    
--[[
    -- 功能页签红点
    self._PageRedDotList = {}
    self._PageRedDotList[EnumDef.UIEquipPageState.PageFortify] = self:GetUIObject("Rdo_Fortify"):FindChild("Img_RedPoint_Elf")
    self._PageRedDotList[EnumDef.UIEquipPageState.PageRecast] = self:GetUIObject("Rdo_Recast"):FindChild("Img_RedPoint_Elf")
    self._PageRedDotList[EnumDef.UIEquipPageState.PageRefine] = self:GetUIObject("Rdo_Refine"):FindChild("Img_RedPoint_Elf")
    self._PageRedDotList[EnumDef.UIEquipPageState.PageLegendChange] = self:GetUIObject("Rdo_Legend"):FindChild("Img_RedPoint_Elf")
]]
    self._ItemList = self:GetUIObject('List_Item'):GetComponent(ClassType.GNewList)
    self._List_NoneMaterial = self:GetUIObject('List_NoneMaterial'):GetComponent(ClassType.GNewList)
    self._Tab_NoneMaterial = self:GetUIObject("Tab_NoneMaterial")
    local dropTemplate = self:GetUIObject("Drop_Template")
    GUITools.SetupDropdownTemplate(self, dropTemplate)
    self:SetDorpdownGroup()

    -- 2018.12.21 关闭精炼模块
    self:GetUIObject("Rdo_Refine"):SetActive(false)
    self:GetUIObject("BlurTex"):SetActive(false)

    self._PanelObject = {}
    self._PanelObject.CheckBox_ShowGfx = self:GetUIObject('CheckBox_ShowGfx'):GetComponent(ClassType.Toggle)
    self._PanelObject.DropDown_Up = self:GetUIObject('DropDown_Up')
end

def.override("dynamic").OnData = function(self,data)
    self._HelpUrlType = HelpPageUrlType.Fortify

    -- 教学特殊处理
    if game._CGuideMan._CurGuideTrigger ~= nil then
        local CGuideMan = require "Guide.CGuideMan"
        local guideConfig = CGuideMan.GetGuideTrigger()
        local BigStepConfig = guideConfig[game._CGuideMan._CurGuideTrigger._ID]
        --local SmallStepConfig = BigStepConfig.Steps[game._CGuideMan._CurGuideTrigger._Step]
        if BigStepConfig ~= nil and BigStepConfig.fristSortItemIDs ~= nil then
            local hpProf = game._HostPlayer._InfoData._Prof
            self._fristSortItemID = BigStepConfig.fristSortItemIDs[hpProf]
        end
    end


    if instance:IsShow() then
--[[
Parameters
----------
data: Table
    外部跳转装备类型, default: nil
    data = 
    {
        PackageType,
        UIEquipPageState,
        ItemData,
    }
]]         

        -- 初始化通用金币
        if self._Frame_Money == nil then
            local Frame_Money = self:GetUIObject("Frame_Money")
            Frame_Money:SetActive(true)
            self._Frame_Money = CFrameCurrency.new(self, Frame_Money, EnumDef.MoneyStyleType.None)
        else
            self._Frame_Money:Update()
        end

        -- 默认功能页签
        local page = EnumDef.UIEquipPageState.PageFortify
        if data ~= nil and data.UIEquipPageState ~= nil then
            page = data.UIEquipPageState
            self._PageToggleList[page].isOn = true
        end

        -- 同步背包数据
        self:SyncPackageData(page)
        -- 跳转功能页签
        self:ChangePage(page)

        -- 跳转 选中装备的 类别页签
        if data ~= nil and data.ItemData ~= nil then
            local itemData = self:StructureLocalItem(data.PackageType, data.ItemData)
            local category = itemData.ItemData:GetCategory()
            if category ~= EnumDef.ItemCategory.EquipProcessMaterial and
               category ~= EnumDef.ItemCategory.Others then
                category = EnumDef.ItemCategory.Weapon
            end

            -- 跳转类别页签
            self:ChangeCategory(category)
        
            -- 同步已选中的 装备 Index
            self:SyncSelectItemDataIndexInfo(itemData)
        else
            
        end

        -- 同步选中装备
        self:SyncSelectItemData()
        -- 更新类别数据个数
        self:UpdateCategoryCount()
        -- 更新功能页签红点信息
        --self:UpdatePageRedDot()

        --GameUtil.LayoutTopTabs(self:GetUIObject('Frame_TopTabs'))
        CPanelBase.OnData(self,data)

        CGame.EventManager:addHandler(EquipProcessingChangeEvent, OnEquipProcessingChangeEvent)

        -- 获取 当前page的历史变量
        self:SyncSkipState()
        -- 同步skip动画按钮状态
        self:UpdateSkipGfxToggle(true)
    end
end

-- 品质过滤器
def.method().QualityFilter = function(self)
    if self._CurrentSortQuality ~= -1 and #self._AllLocalItemList > 0 then
        local quality = self._CurrentSortQuality
        local map = {}
        map[EnumDef.ItemCategory.Weapon] = {}
        map[EnumDef.ItemCategory.Armor] = {}
        map[EnumDef.ItemCategory.Jewelry] = {}
        map[EnumDef.ItemCategory.EquipProcessMaterial] = {}

        for i, item in ipairs(self._AllLocalItemList[EnumDef.ItemCategory.Weapon]) do
            if item.ItemData._Quality == quality then
                table.insert(map[EnumDef.ItemCategory.Weapon], item)
            end
        end
        for i, item in ipairs(self._AllLocalItemList[EnumDef.ItemCategory.Armor]) do
            if item.ItemData._Quality == quality then
                table.insert(map[EnumDef.ItemCategory.Armor], item)
            end
        end
        for i, item in ipairs(self._AllLocalItemList[EnumDef.ItemCategory.Jewelry]) do
            if item.ItemData._Quality == quality then
                table.insert(map[EnumDef.ItemCategory.Jewelry], item)
            end
        end
        for i, item in ipairs(self._AllLocalItemList[EnumDef.ItemCategory.EquipProcessMaterial]) do
            -- if item.ItemData._Quality == quality then
            table.insert(map[EnumDef.ItemCategory.EquipProcessMaterial], item)
            -- end
        end

        self._LocalItemList = map
    else
        self._LocalItemList = self._AllLocalItemList
    end
end

-- 矫正Index
def.method().FixSelectInfo = function(self)
    if self._ItemData ~= nil then
        self._CurrentSelectIndexList[self._CurrentCategory].Index = 0

        for i, item in ipairs(self._LocalItemList[self._CurrentCategory]) do
            if self._ItemData.ItemData._Guid == item.ItemData._Guid then
                self._CurrentSelectIndexList[self._CurrentCategory].Index = i
                break
            end
        end
    end
end

def.method("=>", "string").GetQualityGroupStr = function(self)
    local groupStr = StringTable.Get(10010)
    for _, v in ipairs(listQuality) do
        local str = StringTable.Get(10000 + v)
        str = RichTextTools.GetQualityText(str, v)
        groupStr = groupStr .. "," .. str
    end

    return groupStr
end

-- 设置下拉菜单
def.method().SetDorpdownGroup = function(self)
    local Drop_Template = self:GetUIObject("Drop_Template")
    GUITools.SetupDropdownTemplate(self, Drop_Template)

    local groupStr = self:GetQualityGroupStr()
    GUI.SetDropDownOption(self:GetUIObject("DropDown_Up"), groupStr)
end

--[[
    local data =
    {
        PackageType,
        ItemData,
    }
]]
def.method("number", "table", "=>", "table").StructureLocalItem = function(self, packageType, itemData)
    local localItem = 
    {
        PackageType = packageType,
        ItemData = clone(itemData),
    }

    return localItem
end

-- 同步背包数据
def.method("dynamic").SyncPackageData = function(self, page)
    self._AllLocalItemList = {}
    self._AllLocalItemList[EnumDef.ItemCategory.Weapon] = {}
    self._AllLocalItemList[EnumDef.ItemCategory.Armor] = {}
    self._AllLocalItemList[EnumDef.ItemCategory.Jewelry] = {}
    self._AllLocalItemList[EnumDef.ItemCategory.EquipProcessMaterial] = {}

    self._LocalItemList = {}
    -- self._LocalItemList[EnumDef.ItemCategory.Weapon] = {}
    -- self._LocalItemList[EnumDef.ItemCategory.Armor] = {}
    -- self._LocalItemList[EnumDef.ItemCategory.Jewelry] = {}
    -- self._LocalItemList[EnumDef.ItemCategory.EquipProcessMaterial] = {}

    local function AppendItem(localItem)
        local itemCategoryType = localItem.ItemData:GetCategory()
        if itemCategoryType == EnumDef.ItemCategory.Weapon or
           itemCategoryType == EnumDef.ItemCategory.Armor or
           itemCategoryType == EnumDef.ItemCategory.Jewelry then

            table.insert(self._AllLocalItemList[EnumDef.ItemCategory.Weapon], localItem)
        elseif itemCategoryType == EnumDef.ItemCategory.EquipProcessMaterial then
            table.insert(self._AllLocalItemList[itemCategoryType], localItem)
        end
    end

    local hp = game._HostPlayer
    local profMask = EnumDef.Profession2Mask[hp._InfoData._Prof]
    local function ProfCanUse(item)
        local bRet = false
        --职业限制
        if item._Tid > 0 then
            local realPage = page or self._CurrentPage

            if item:IsEquip() then
                bRet = profMask == bit.band(item._Template.ProfessionLimitMask, profMask)

                if bRet then
                    if realPage == EnumDef.UIEquipPageState.PageFortify then
                        bRet = item:CanFortity()
                    elseif realPage == EnumDef.UIEquipPageState.PageRecast then
                        bRet = item:CanRecast()
                    elseif realPage == EnumDef.UIEquipPageState.PageRefine then
                        bRet = item:CanRefine()
                    elseif realPage == EnumDef.UIEquipPageState.PageLegendChange then
                        bRet = item:CanChangeLegendary()
                    else
                        bRet = true
                    end
                end
            else
                if realPage == EnumDef.UIEquipPageState.PageFortify then
                    bRet = item:IsInforceStone() or 
                           item:IsLuckyStone() or 
                           item:IsSafeStone()
                elseif realPage == EnumDef.UIEquipPageState.PageRecast then
                    bRet = item:IsRebuildStore()
                elseif realPage == EnumDef.UIEquipPageState.PageRefine then
                    bRet = item:IsRefineStore()
                elseif realPage == EnumDef.UIEquipPageState.PageLegendChange then
                    bRet = item:IsTalentChange()
                else
                    bRet = true
                end
            end
        end

        return bRet
    end

    local hp = game._HostPlayer
    do
    -- 装备背包
        local equipPackList = hp._Package._EquipPack._ItemSet
        local equipPackCnt = #equipPackList
        if equipPackCnt > 0 then
            for i=1, equipPackCnt do
                local item = equipPackList[i]
                if ProfCanUse(item) then
                    local localItem = self:StructureLocalItem(BAGTYPE.ROLE_EQUIP, item)
                    AppendItem(localItem)
                end
            end
        end
    end

    do
    -- 普通背包
        local normalPackList = hp._Package._NormalPack._ItemSet
        local normalPackCnt = #normalPackList
        if normalPackCnt > 0 then
            for i=1, normalPackCnt do
                local item = normalPackList[i]
                if ProfCanUse(item) then
                    local localItem = self:StructureLocalItem(BAGTYPE.BACKPACK, item)
                    AppendItem(localItem)
                end
            end
        end
    end

    self._LocalItemList = self._AllLocalItemList
    self:UpdateSortList()
    self:QualityFilter()
    self:UpdateCategoryCount()
end

-- 模拟点击事件
def.method("number").SimulateOnSelectItem = function(self, index)
    local item = self._ItemList:GetItem(index - 1)
    local id = "List_Item"

    self:OnSelectItem(item, id, index - 1)
end

-- 同步已选中的 装备 Index
def.method("table").SyncSelectItemDataIndexInfo = function(self, itemData)
    --warn("SyncSelectItemDataIndexInfo-----------------------")

    local bFind = false
    if itemData ~= nil and self._CurrentCategory > 0 then
        for i,v in ipairs(self._LocalItemList[self._CurrentCategory]) do
            if itemData.ItemData._Guid == v.ItemData._Guid then
                self._CurrentSelectIndexList[self._CurrentCategory].Index = i
                bFind = true
                break
            end
        end
    end

    if bFind then
        self:SimulateOnSelectItem(self._CurrentSelectIndexList[self._CurrentCategory].Index)
    end
end

-- 同步已选中的 装备
def.method().SyncSelectItemData = function(self)
    if self._ItemData ~= nil then
        for itemCategory=1, 3 do
            for i=1, #self._LocalItemList[itemCategory] do
                local item = self._LocalItemList[itemCategory][i]
                if item == nil then
                    warn("Can not get item at page weapon, index =", i, debug.traceback())
                end
                if item ~= nil and item.PackageType == self._ItemData.PackageType and
                   item.ItemData._Slot == self._ItemData.ItemData._Slot then

                    self._ItemData = item
                    return
                end
            end
        end
    end
end

def.method("=>", "boolean").IsGfxShowing = function(self)
    local bRet = false
    local CPanelUIEquipRecastResult = require "GUI.CPanelUIEquipRecastResult"
    local CPanelUIEquipLegendResult = require "GUI.CPanelUIEquipLegendResult"
    local CPanelUIEquipFortityResult = require "GUI.CPanelUIEquipFortityResult"
    local CPanelUIEquipInheritResult = require "GUI.CPanelUIEquipInheritResult"

    bRet = CPanelUIEquipRecastResult.Instance():IsShow() or
           CPanelUIEquipLegendResult.Instance():IsShow() or
           CPanelUIEquipInheritResult.Instance():IsShow() or
           CPanelUIEquipFortityResult.Instance():IsShow()

    return bRet
end

-- 刷新背包 排序规则
def.method().UpdateSortList = function(self)
    local function sortfunction(item1, item2)
        if item1.ItemData._Tid == self._fristSortItemID then
            return true
        end
        if item2.ItemData._Tid == self._fristSortItemID then
            return false
        end
        if item1.PackageType ~= item2.PackageType then
            return item1.PackageType == BAGTYPE.ROLE_EQUIP and true or false
        end

        if item1.ItemData._Tid == 0 then
            return false
        end
        if item2.ItemData._Tid == 0 then
            return true
        end

        local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof] 

        if item1.ItemData._ProfessionMask == profMask and item2.ItemData._ProfessionMask == profMask then
            if item1.ItemData._SortId == item2.ItemData._SortId then
                return item1.ItemData._Slot < item2.ItemData._Slot
            else
                return item1.ItemData._SortId > item2.ItemData._SortId
            end
        elseif item1.ItemData._ProfessionMask == profMask then
            return true
        elseif item2.ItemData._ProfessionMask == profMask then
            return false
        else
            if item1.ItemData._SortId == item2.ItemData._SortId then
                return item1.ItemData._Slot < item2.ItemData._Slot
            else
                return item1.ItemData._SortId > item2.ItemData._SortId
            end
        end
    end

    table.sort(self._LocalItemList[EnumDef.ItemCategory.Weapon], sortfunction)
    table.sort(self._LocalItemList[EnumDef.ItemCategory.Armor], sortfunction)
    table.sort(self._LocalItemList[EnumDef.ItemCategory.Jewelry], sortfunction)
    table.sort(self._LocalItemList[EnumDef.ItemCategory.EquipProcessMaterial], sortfunction)
end

-- 切换功能页面
def.method("number").ChangePage = function(self, pageIndex)
    --warn("ChangePage = ", pageIndex)
    local hp = game._HostPlayer
    hp._ShowFightScoreBoard = ((pageIndex == EnumDef.UIEquipPageState.PageRecast) or
                              (pageIndex == EnumDef.UIEquipPageState.PageLegendChange))

    if self._CurrentPage == pageIndex then return end
    self._CurrentPage = pageIndex

    local bIsFortify = self._CurrentPage == EnumDef.UIEquipPageState.PageFortify
    local bIsInherit = self._CurrentPage == EnumDef.UIEquipPageState.PageInherit

    local obj = self._CategoryToggleList[EnumDef.ItemCategory.EquipProcessMaterial]
    obj:SetActive( bIsFortify )
    if not bIsFortify then
        obj:GetComponent(ClassType.Toggle).isOn = false
    end
    if not bIsInherit then
        self._CurrentTargetSelectInfo = {}
    end

    self:GetCurrentPage():Reset()
    self:SyncPackageData(nil)
    self:ResetSelectList()
    self:UpdateItemList()
    self:UpdateFrameShow()
    self:TurnToEquipProcessWeaponPage()
    self:UpdateCategoryCount()

    -- 获取 当前page的历史变量
    self:SyncSkipState()
    -- 同步skip动画按钮状态
    self:UpdateSkipGfxToggle(true)
end

-- 切换类别
def.method("number").ChangeCategory = function(self, categoryIndex)
    if self._CurrentCategory == categoryIndex then return end

    self._CurrentCategory = categoryIndex
    local bIsMaterialCategory = self._CurrentCategory == EnumDef.ItemCategory.EquipProcessMaterial
    local bShowNoneMaterial = self._CurrentPage == EnumDef.UIEquipPageState.PageFortify and
                              bIsMaterialCategory and
                              self:GetCurrentCategoryCount() == 0

    
    self._PanelObject.DropDown_Up:SetActive(not bIsMaterialCategory)
    self:GetUIObject('List_Item'):SetActive( not bShowNoneMaterial )
    self._Tab_NoneMaterial:SetActive( bShowNoneMaterial )
    if bShowNoneMaterial then
        -- 显示强化石来源界面
        self:ShowNoneMaterialUI()
    end

    self:UpdateItemList()
end

-- 显示强化石来源界面
def.method().ShowNoneMaterialUI = function(self)
    self._InforceStoreFromInfo = CEquipUtility.GetInforceStoreFromInfo()
    local count = #self._InforceStoreFromInfo
    self._List_NoneMaterial:SetItemCount( count )
end

-- 获取当前类别数量
def.method("=>", "number").GetCurrentCategoryCount = function(self)
    return (self._LocalItemList[self._CurrentCategory] ~= nil and #self._LocalItemList[self._CurrentCategory] or 0)
end

-- 重置背包 List
def.method().UpdateItemList = function(self)
    local count = self:GetCurrentCategoryCount()
    self._ItemList:SetItemCount( count )
end

-- 重置背包分类 个数
def.method().UpdateCategoryCount = function(self)
    local MAX_CATEGORY_COUNT = #self._CategoryToggleList
    for i=1, MAX_CATEGORY_COUNT do
        local labValue1 = self._CategoryToggleList[i]:FindChild("Label")
        local labValue2 = self._CategoryToggleList[i]:FindChild("Label")
        GUI.SetText(labValue1, tostring(#self._LocalItemList[i]))
        GUI.SetText(labValue2, tostring(#self._LocalItemList[i]))
    end
end

--更新是否显示分界面
def.method().UpdateFrameShow = function(self)
    self:HideAllFramesExceptCurrent()
    self:GetCurrentPage():Show(self._ItemData)
end

def.method("=>", "dynamic").GetCurrentPage = function(self)
    return self._ProcessFrames[self._CurrentPage]
end

def.method("number", "=>", "table").GetItemDataByIndex = function(self, index)
    return self._LocalItemList[self._CurrentCategory][index]
end

def.method("number", "=>", "table").GetInforceStoneItemDataByTid = function(self, tid)
    local resultData = nil
    for i=1, #self._LocalItemList[EnumDef.ItemCategory.EquipProcessMaterial] do
        local item = self._LocalItemList[EnumDef.ItemCategory.EquipProcessMaterial][i]
        if item.ItemData._Tid == tid then
            resultData = item

            break 
        end
    end

    return resultData
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Item" then
        local itemData = self:GetItemDataByIndex(idx)
        self:GetCurrentPage():OnInitItem(item, index, itemData)

        local currentTargetSelectIndex = self._CurrentTargetSelectInfo.Index or 0
        local currentSelectIndex = self._CurrentSelectIndexList[self._CurrentCategory].Index
        local setting = {
            [EFrameIconTag.Select] = currentSelectIndex == idx or currentTargetSelectIndex == idx,
            [EFrameIconTag.RedPoint] = false,
        }
        local ItemIconNew = item:FindChild("ItemIconNew")
        IconTools.SetFrameIconTags(ItemIconNew, setting)
        if currentSelectIndex == idx then
            self._CurrentSelectIndexList[self._CurrentCategory].Object = ItemIconNew
        end
    elseif id == "List_NoneMaterial" then
        local info = self._InforceStoreFromInfo[idx]
        GUI.SetText(item:FindChild("Img_Bg/Lab_Name"), info.Name)
        GUITools.SetIcon(item:FindChild("Img_Bg/Img_Icon"), info.IconPath)
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if self:IsGfxShowing() then return end
    
    local idx = index + 1
    if id == "List_Item" then
        -- 选装备，换装备 限制
        if self._CurrentCategory == EnumDef.ItemCategory.EquipProcessMaterial then
            --warn("OnSelectItem 材料")
            if self._ItemData == nil then
                TeraFuncs.SendFlashMsg(StringTable.Get(31301), false)
                return
            else
                self:GetCurrentPage():OnSelectItem(item, index, self:GetItemDataByIndex(idx))
            end
        else
            --warn("OnSelectItem 装备")
            local function DoSelect()
                if self._CurrentSelectIndexList[self._CurrentCategory].Object ~= nil then
                    local setting = {
                        [EFrameIconTag.Select] = false,
                    }
                    IconTools.SetFrameIconTags(self._CurrentSelectIndexList[self._CurrentCategory].Object, setting)
                end                
                local ItemIconNew = item:FindChild("ItemIconNew")
                local setting = {
                    [EFrameIconTag.Select] = true,
                }
                IconTools.SetFrameIconTags(ItemIconNew, setting)
                self._CurrentSelectIndexList[self._CurrentCategory].Object = ItemIconNew
                self._CurrentSelectIndexList[self._CurrentCategory].Index = idx
                self._ItemData = self:GetItemDataByIndex(idx)
                self:GetCurrentPage():OnSelectItem(item, index, self._ItemData)
            end

            -- 装备
            if self._ItemData == nil then
                if self._CurrentPage == EnumDef.UIEquipPageState.PageInherit then
                    local dataSelect = self:GetItemDataByIndex(idx)

                    if not dataSelect.ItemData:CanInherit() then
                        TeraFuncs.SendFlashMsg(StringTable.Get(31333), false)
                        return
                    end
                end
                -- 选中物品逻辑
                DoSelect()

            elseif self._CurrentPage == EnumDef.UIEquipPageState.PageInherit then
                if self._CurrentSelectIndexList[self._CurrentCategory].Index == idx then
                    -- 源装备相同 卸下
                    self:ResetSelectList()
                    self:GetCurrentPage():ResetTarget()
                    self:UpdateFrameShow()
                    self:UpdateItemList()
                else
                    local newInheritTargetItemData = self:GetItemDataByIndex(idx)
                    local bSelected = false

                    if self._InheritTargetItemData == nil then
                        -- 继承需要两个装备位置
                        if self._ItemData.ItemData._EquipSlot == newInheritTargetItemData.ItemData._EquipSlot then
                            if newInheritTargetItemData.ItemData:GetInforceLevel() >= self._ItemData.ItemData:GetInforceLevel() then
                                TeraFuncs.SendFlashMsg(StringTable.Get(31347), false)
                            else
                                self._InheritTargetItemData = newInheritTargetItemData

                                self:GetCurrentPage():OnSelectItem(item, index, self._InheritTargetItemData)
                                bSelected = true
                            end
                        else
                            TeraFuncs.SendFlashMsg(StringTable.Get(31335), false)
                        end
                    elseif self._InheritTargetItemData == newInheritTargetItemData then
                        -- 目标装备相同 卸下
                        self._InheritTargetItemData = nil
                        self:GetCurrentPage():ResetTarget()
                        self:UpdateItemList()
                    else
                        TeraFuncs.SendFlashMsg(StringTable.Get(31335), false)
                        return
                    end

                    local ItemIconNew = item:FindChild("ItemIconNew")
                    local setting = {
                        [EFrameIconTag.Select] = bSelected,
                    }
                    IconTools.SetFrameIconTags(ItemIconNew, setting)

                    self._CurrentTargetSelectInfo.Object = bSelected and ItemIconNew or nil
                    self._CurrentTargetSelectInfo.Index = bSelected and idx or 0
                end
                
            elseif self._CurrentSelectIndexList[self._CurrentCategory].Index == idx then
                local function DoClear()
                    self:ResetSelectList()
                    self:UpdateFrameShow()
                    self:UpdateItemList()
                end

                -- 选中同一个物品，卸下物品
                if self._CurrentPage == EnumDef.UIEquipPageState.PageFortify then
                    DoClear()
                    self:TurnToEquipProcessWeaponPage()
                elseif self._CurrentPage == EnumDef.UIEquipPageState.PageRecast then
                    DoClear()
                elseif self._CurrentPage == EnumDef.UIEquipPageState.PageRefine then
                    DoClear()
                elseif self._CurrentPage == EnumDef.UIEquipPageState.PageLegendChange then
                    DoClear()
                end

                return
            elseif self._CurrentPage == EnumDef.UIEquipPageState.PageFortify then
                -- 强化则必须取消原选中物品，因优化无法提高使用效率。故不做处理
                -- TeraFuncs.SendFlashMsg(StringTable.Get(31300), false)
                -- return
                self:ResetSelectList()
                self:UpdateFrameShow()
                self:UpdateItemList()
                -- self:TurnToEquipProcessWeaponPage()
                -- 选中物品逻辑
                DoSelect()
            else
                -- 清空物品逻辑
                self:ResetSelectList()
                self:UpdateItemList()
                -- 选中物品逻辑
                DoSelect()
            end

            -- 只有装备强化界面，选择装备后跳转至 材料背包
            if self._CurrentPage == EnumDef.UIEquipPageState.PageFortify then
                self:TurnToEquipProcessMaterialPage()
            end            
        end
    elseif id == "List_NoneMaterial" then
        local info = self._InforceStoreFromInfo[idx]
        game._AcheivementMan:DrumpToRightPanel(info.ID,0)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
    end

    -- 操作完材料后，需要强制刷新 材料背包， 自维护的个数和可点击状态需要重新计算
    self:UpdateItemList()
end

def.override('userdata','string','number').OnLongPressItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Item" then
        local itemData = self:GetItemDataByIndex(idx)
        if itemData.ItemData:IsEquip() then
            CItemTipMan.ShowPackbackEquipTip(itemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,item)
        else
            itemData.ItemData:ShowTip(TipPosition.FIX_POSITION, item)
        end
    end
end

-- 跳转至 材料背包
def.method().TurnToEquipProcessMaterialPage = function(self)
    self:ChangeCategory(EnumDef.ItemCategory.EquipProcessMaterial)
    local obj = self._CategoryToggleList[EnumDef.ItemCategory.EquipProcessMaterial]
    if obj ~= nil then
        obj:GetComponent(ClassType.Toggle).isOn = true
    end
end
-- 跳转至 武器背包
def.method().TurnToEquipProcessWeaponPage = function(self)
    self:ChangeCategory(EnumDef.ItemCategory.Weapon)
    local obj = self._CategoryToggleList[EnumDef.ItemCategory.Weapon]
    if obj ~= nil then
        obj:GetComponent(ClassType.Toggle).isOn = true
    end
end

-- 获取当前的本地数据 标志位
def.method("=>", "string").GetCurrentLocalField = function(self)
    local localField = ""

    if self._CurrentPage == EnumDef.UIEquipPageState.PageFortify then
        -- 强化
        localField = EnumDef.LocalFields.EquipSkipGfx_Fortify
    elseif self._CurrentPage == EnumDef.UIEquipPageState.PageRecast then
        -- 重铸
        localField = EnumDef.LocalFields.EquipSkipGfx_Recast
    elseif self._CurrentPage == EnumDef.UIEquipPageState.PageRefine then
        -- 精炼
        localField = EnumDef.LocalFields.EquipSkipGfx_Refine
    elseif self._CurrentPage == EnumDef.UIEquipPageState.PageLegendChange then
        -- 转化
        localField = EnumDef.LocalFields.EquipSkipGfx_LegendChange
    elseif self._CurrentPage == EnumDef.UIEquipPageState.PageInherit then
        -- 继承
        localField = EnumDef.LocalFields.EquipSkipGfx_Inherit
    end

    return localField
end

-- 设置 本地跳过动画 变量
def.method("boolean").SetLocalSkipGfxState = function(self, bSkip)
    local account = game._NetMan._UserName
    local curLocalField = self:GetCurrentLocalField()
    local oldState = self:GetLocalSkipGfxState()

    if oldState == nil or oldState == bSkip then
        return
    end

    UserData.Instance():SetCfg(curLocalField, account, bSkip)
end
-- 获取 本地跳过动画 变量
def.method("=>", "boolean").GetLocalSkipGfxState = function(self)
    local account = game._NetMan._UserName
    local curLocalField = self:GetCurrentLocalField()

    return UserData.Instance():GetCfg(curLocalField, account) or false
end
def.method().SyncSkipState = function(self)
    local bSkip = self:GetLocalSkipGfxState()
    self._ShowGfx = not bSkip
end
-- 更新 跳过动画按钮状态 
def.method("boolean").UpdateSkipGfxToggle = function(self, bInit)
    local bSkip = self:GetLocalSkipGfxState()
    -- warn("UpdateSkipGfxToggle", self:GetCurrentLocalField(), bSkip)
    if not bInit and self._ShowGfx == not bSkip then return end

    self._PanelObject.CheckBox_ShowGfx.isOn = bSkip
    self._ShowGfx = not bSkip
end
-- 清空物品逻辑

def.override('string').OnClick = function(self, id)
    if self:IsGfxShowing() then return end

    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then

    elseif id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == 'Btn_DescLibrary' then
        --TODO("显示各模块描述的按钮")
    elseif id == "Btn_Drop_Fortify" then
        self:ResetSelectList()
        self:UpdateFrameShow()
        self:UpdateItemList()
        self:TurnToEquipProcessWeaponPage()

        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    elseif id == "Btn_Drop_Recast" then
        self:ResetSelectList()
        self:UpdateFrameShow()
        self:UpdateItemList()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    elseif id == "Btn_Drop_Refine" then
        self:ResetSelectList()
        self:UpdateFrameShow()
        self:UpdateItemList()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    elseif id == "Btn_Drop_Legend" then
        self:ResetSelectList()
        self:UpdateFrameShow()
        self:UpdateItemList()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    elseif id == "Btn_Drop_OrignItem" then
        self:ResetSelectList()
        self:ResetTargetSelect()
        self:GetCurrentPage():ResetTarget()
        self:UpdateFrameShow()
        self:UpdateItemList()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    elseif id == "Btn_Drop_TargetItem" then
        self:ResetTargetSelect()
        self:GetCurrentPage():ResetTarget()
        self:UpdateItemList()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    elseif string.find(id, "Btn_AddFortifyMaterial") then
        self:TurnToEquipProcessMaterialPage()
    elseif id == "Btn_AddFortifyItem" then
        self:TurnToEquipProcessWeaponPage()
    elseif id == "Btn_AddRecastItem" then
        self:ChangeCategory(EnumDef.ItemCategory.Weapon)
        local obj = self._CategoryToggleList[EnumDef.ItemCategory.Weapon]
        if obj ~= nil then
            obj:GetComponent(ClassType.Toggle).isOn = true
        end
    elseif id == "Btn_AddRefineItem" then
        self:ChangeCategory(EnumDef.ItemCategory.Weapon)
        local obj = self._CategoryToggleList[EnumDef.ItemCategory.Weapon]
        if obj ~= nil then
            obj:GetComponent(ClassType.Toggle).isOn = true
        end
    elseif id == "Btn_AddLegendItem" then
        self:ChangeCategory(EnumDef.ItemCategory.Weapon)
        local obj = self._CategoryToggleList[EnumDef.ItemCategory.Weapon]
        if obj ~= nil then
            obj:GetComponent(ClassType.Toggle).isOn = true
        end
    elseif string.find(id, "Btn_Drop_FortifyMaterial") then
        self:GetCurrentPage():OnClick(id)
        -- 操作完材料后，需要强制刷新 材料背包， 自维护的个数和可点击状态需要重新计算
        self:UpdateItemList()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
        return
    else
        self:GetCurrentPage():OnClick(id)
    end
    CPanelBase.OnClick(self, id)

    CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    --warn("OnToggle = ", id)
    if id == "Rdo_Fortify" and checked then
        self:ChangePage(EnumDef.UIEquipPageState.PageFortify)
    elseif id == "Rdo_Recast" and checked then
        self:ChangePage(EnumDef.UIEquipPageState.PageRecast)
    elseif id == "Rdo_Refine" and checked then
        self:ChangePage(EnumDef.UIEquipPageState.PageRefine)
    elseif id == "Rdo_Legend" and checked then
        self:ChangePage(EnumDef.UIEquipPageState.PageLegendChange)
    elseif id == "Rdo_Inherit" and checked then
        self:ChangePage(EnumDef.UIEquipPageState.PageInherit)
    elseif id == "Rdo_Weapon" and checked then
        self:ChangeCategory(EnumDef.ItemCategory.Weapon)
    elseif id == "Rdo_Armor" and checked then
        self:ChangeCategory(EnumDef.ItemCategory.Armor)
    elseif id == "Rdo_Jewelry" and checked then
        self:ChangeCategory(EnumDef.ItemCategory.Jewelry)
    elseif id == "Rdo_Material" and checked then
        self:ChangeCategory(EnumDef.ItemCategory.EquipProcessMaterial)
    elseif id == "CheckBox_ShowGfx" then
        self:SetLocalSkipGfxState(checked)
        self:UpdateSkipGfxToggle(false)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Tab_Press, 0)
    end
end

def.method('number', '=>', 'number').ExchangeQualityByIndex = function(self, index)
    return listQuality[index] or -1
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if id == "DropDown_Up" then
        local quality = self:ExchangeQualityByIndex(index)
        if quality == self._CurrentSortQuality then return end

        self._CurrentSortQuality = quality

        self:ResetSelectList()
        self:UpdateFrameShow()
        self:QualityFilter()
        self:UpdateCategoryCount()
        self:UpdateItemList()

        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
    end
end

--[[
--更新功能页签红点信息
def.method().UpdatePageRedDot = function(self)
    self._PageRedDotList[EnumDef.UIEquipPageState.PageRecast]:SetActive( CEquipUtility.CalcEquipRecastPageRedDotState() )
    self._PageRedDotList[EnumDef.UIEquipPageState.PageRefine]:SetActive( CEquipUtility.CalcEquipRefinePageRedDotState() )
end
]]

-- 当前选择物品的Index列表,按类别分类
def.method().ResetSelectList = function(self)
    if self._CurrentSelectIndexList[self._CurrentCategory] ~= nil and 
       self._CurrentSelectIndexList[self._CurrentCategory].Object ~= nil then
        local setting = {
            [EFrameIconTag.Select] = false,
        }
        IconTools.SetFrameIconTags(self._CurrentSelectIndexList[self._CurrentCategory].Object, setting)
    end

    if self._CurrentPage == EnumDef.UIEquipPageState.PageFortify then
        self._ProcessFrames[EnumDef.UIEquipPageState.PageFortify]:RestoneMaterialList()
    end

    self._CurrentSelectIndexList[EnumDef.ItemCategory.Weapon] = {Index = 0, Object = nil}
    self._CurrentSelectIndexList[EnumDef.ItemCategory.Armor] = {Index = 0, Object = nil}
    self._CurrentSelectIndexList[EnumDef.ItemCategory.Jewelry] = {Index = 0, Object = nil}
    self._CurrentSelectIndexList[EnumDef.ItemCategory.EquipProcessMaterial] = {Index = 0, Object = nil}
    self._CurrentTargetSelectInfo = {Index = 0, Object = nil}

    self._ItemData = nil
end

def.method().ResetTargetSelect = function(self)
    self._InheritTargetItemData = nil
    self._CurrentTargetSelectInfo = {}
end

-- 关闭所有界面-除了当前界面
def.method().HideAllFramesExceptCurrent = function(self)
    for i=1, #self._ProcessFrames do
        if self._ProcessFrames[i] ~= nil and self._CurrentPage ~= i then
            self._ProcessFrames[i]:Hide()
        end
    end
end

-- 关闭所有界面
def.method().HideAllFrames = function(self)
    for i=1, #self._ProcessFrames do
        if self._ProcessFrames[i] ~= nil then
            self._ProcessFrames[i]:Hide()
        end
    end
end

def.override().OnHide = function(self)
    local hp = game._HostPlayer
    hp._ShowFightScoreBoard = true
    self._fristSortItemID = -1
    self:HideAllFrames()
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    RemoveInheritTimer()
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end

    CGame.EventManager:removeHandler(EquipProcessingChangeEvent, OnEquipProcessingChangeEvent)

    for k,v in pairs(self._ProcessFrames) do
        v:Destroy()
    end

    instance = nil
end

CPanelUIEquipProcess.Commit()
return CPanelUIEquipProcess