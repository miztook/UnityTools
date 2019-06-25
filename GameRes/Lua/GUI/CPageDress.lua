-- 外观时装页
-- 时间：2017/11/2
-- Add by Yao
local CDress = require "Dress.CDress"
local CDressMan = require "Dress.CDressMan"
local CDressUtility = require "Dress.CDressUtility"
local Util = require "Utility.Util"
local OutwardUtil = require "Utility.OutwardUtil"
local bit = require "bit"
local EDressType = require "PB.Template".Dress.eDressType
local CElementData = require "Data.CElementData"

local Lplus = require "Lplus"
local CPageDress = Lplus.Class("CPageDress")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPageDress.define

def.field("table")._Parent = BlankTable
def.field("userdata")._Panel = nil
def.field(CDressMan)._CDressManIns = nil

def.field("table")._PanelObject = BlankTable -- 存放UI的集合
-- 数据
def.field("table")._AllShowMap = BlankTable -- 所有部位的时装展示列表(Key为 LeftPageType )
-- 缓存
def.field("number")._CurrentLeftPage = 0 -- 当前左页签
def.field("number")._CurrentRightPage = 0 -- 当前右页签
def.field("table")._SelectedDressMap = BlankTable -- 当前选中的时装数据(Key为 LeftPageType )
def.field("table")._SelectedDyeMap = BlankTable -- 所有部位的选中时装的当前染色Id列表(Key为 LeftPageType )
def.field("number")._SelectedIndex = -1 -- 左列表里已选择的时装索引（从0开始）
def.field("table")._RedPointChangeStatusCacheMap = BlankTable -- 红点状态发生了改变的缓存表
def.field("boolean")._CurCombatState = false -- 当前是否处于战斗状态
def.field("number")._CombatChangeAniLength = 0
def.field("number")._CombatChangingTimerId = 0

-- 左页签类型
local LeftPageType = {
    Armor = 1,
    Helmet = 2,
    Weapon = 3,
}

-- 右页签类型
local RightPageType = {
    DressInfo = 1,
    DyeInfo = 2,
}

local DYE_STUFF_MAX_NUM = 2 -- 染色剂种类最大数量

local instance = nil
def.static("table", "userdata", "=>", CPageDress).new = function(parent, panel)
    instance = CPageDress()
    instance._Parent = parent
    instance._Panel = panel

    instance._CDressManIns = CDressMan.Instance()
    instance._CurCombatState = game._HostPlayer:IsInCombatState()
    instance._CombatChangeAniLength = game._HostPlayer:GetAnimationLength(EnumDef.CLIP.UNLOAD_WEAPON)
    instance:InitPanel()
    instance:InitShowData()

    return instance
end

def.method().InitPanel = function(self)
    self._PanelObject = {
        Frame_Right = self._Parent:GetUIObject('Frame_Right_Dress'),
        RdoGroup_Left = self._Parent:GetUIObject('Rdo_DressGroupLeft'),
        ListObj_Dress = self._Parent:GetUIObject('List_Dress'),
        List_Dress = self._Parent:GetUIObject('List_Dress'):GetComponent(ClassType.GNewListLoop),
        Frame_Icon = self._Parent:GetUIObject('Frame_Icon_Dress'),
        Lab_DressName = self._Parent:GetUIObject('Lab_DressName'),
        Lab_Quality = self._Parent:GetUIObject('Lab_Quality_Dress'),
        RdoGroup_Right = self._Parent:GetUIObject('Rdo_DressGroupRight'),
        Frame_DressInfo = self._Parent:GetUIObject('Frame_Dress_Info'),
        Lab_Des = self._Parent:GetUIObject('Lab_Des_Dress'),
        Lab_CharmValue = self._Parent:GetUIObject('Lab_CharmValue'),
        Lab_Origin = self._Parent:GetUIObject('Lab_Origin_Dress'),
        Frame_DecomposeTips = self._Parent:GetUIObject('Frame_DecomposeTips'),
        Img_DecomposeMoney = self._Parent:GetUIObject('Img_DecomposeMoney'),
        Lab_DecomposeMoney = self._Parent:GetUIObject('Lab_DecomposeMoney'),
        Btn_Approach = self._Parent:GetUIObject('Btn_Approach_Dress'),
        Btn_PutOn = self._Parent:GetUIObject('Btn_PutOn_Dress'),
        Lab_PutOn = self._Parent:GetUIObject('Lab_PutOn_Dress'),
        Btn_Decompose = self._Parent:GetUIObject('Btn_Decompose'),
        Frame_DyeInfo = self._Parent:GetUIObject('Frame_Dress_Dye'),
        Lab_CantTint = self._Parent:GetUIObject('Lab_CantTint'),
        Frame_TintPos_1 = self._Parent:GetUIObject('Frame_TintPos_1'),
        List_TintPos_1 = self._Parent:GetUIObject('List_TintPos_1'):GetComponent(ClassType.GNewList),
        Frame_TintPos_2 = self._Parent:GetUIObject('Frame_TintPos_2'),
        List_TintPos_2 = self._Parent:GetUIObject('List_TintPos_2'):GetComponent(ClassType.GNewList),
        Frame_DyeStuff = self._Parent:GetUIObject('Frame_DyeStuff'),
        DyeStuffObjList = {}, -- 染色剂材料列表
        Btn_Tint = self._Parent:GetUIObject('Btn_Tint'),
        Img_Tint = self._Parent:GetUIObject('Img_Tint'),
        Lab_GetDress = self._Parent:GetUIObject('Lab_GetDress'),
        ImgNewObjList = {},
        RdoRedPointObjList = {}
    }

    local stuffList = {}
    -- 最多四种染色剂
    for i = 1, DYE_STUFF_MAX_NUM do
        local stuffObj = self._Parent:GetUIObject('Btn_DyeStuff_' .. i)
        if IsNil(stuffObj) then break end
        stuffList[#stuffList+1] = stuffObj
    end
    self._PanelObject.DyeStuffObjList = stuffList

    self._PanelObject.RdoRedPointObjList =
    {
        [LeftPageType.Armor] = self._Parent:GetUIObject('Img_RedPoint_Armor'),
        [LeftPageType.Helmet] = self._Parent:GetUIObject('Img_RedPoint_Helmet'),
        [LeftPageType.Weapon] = self._Parent:GetUIObject('Img_RedPoint_Weapon')
    }
end

-- 整合已拥有数据和模版的自己职业的所有数据
def.method().InitShowData = function (self)
    local _, bIsInit = self._CDressManIns:GetDressDBInfoList()
    if not bIsInit then
        warn("Dress List has not init, can not show dress")
        return
    end

    for _, pageType in pairs(LeftPageType) do
        self:InitPageData(pageType)
    end
    self._SelectedDyeMap =
    {
        [LeftPageType.Armor] = {},
        [LeftPageType.Helmet] = {},
        [LeftPageType.Weapon] = {},
    }
end

def.method("number").InitPageData = function (self, pageType)
    local dressDBList, isInited = self._CDressManIns:GetDressDBInfoList()
    if not isInited then return end

    local allTemplateList = self._CDressManIns:GetAllDressList()
    local templateList = nil
    local slot1, slot2 = -1, -1
    if pageType == LeftPageType.Armor then
        slot1 = EDressType.Armor
        templateList = allTemplateList.Armor
    elseif pageType == LeftPageType.Helmet then
        slot1 = EDressType.Headdress
        slot2 = EDressType.Hat
        templateList = allTemplateList.Helmet
    elseif pageType == LeftPageType.Weapon then
        slot1 = EDressType.Weapon
        templateList = allTemplateList.Weapon
    end

    local slotList = {}
    do
        local function sortFunc(a, b)
            if a._Template.Quality ~= b._Template.Quality then
                return a._Template.Quality > b._Template.Quality -- 品质高到低
            elseif a._Template.Score ~= b._Template.Score then
                return a._Template.Score > b._Template.Score -- 魅力值高到低
            elseif #a._Colors > 0 and #b._Colors > 0 then
                return a._Colors[1] < b._Colors[1] -- 当前染色部位1的染色Id从小到大
            end
            return false
        end

        local haveMap = {}
        local curDressData = nil
        -- 添加已拥有的
        for _, v in ipairs(dressDBList) do
            if v._DressSlot == slot1 or v._DressSlot == slot2 then
                local data = CDress.CreateVirtual(v._Template.Id) -- 模板ID代表是原始的Tid，非关联的时装Tid 
                -- 以下四项属于服务器数据，需要重新设置
                data._ID = v._ID
                data._IsWeared = v._IsWeared
                data._TimeLimit = v._TimeLimit
                data._Colors = CDress.CopyColors(v)

                if data._IsWeared then
                    curDressData = data
                else
                    table.insert(slotList, data)
                end
                haveMap[v._Tid] = true
            end
        end
        table.sort(slotList, sortFunc) -- 排序已拥有的
        if curDressData ~= nil then
            table.insert(slotList, 1, curDressData)
        end
        -- 添加未拥有的
        local dontHaveList = {}
        if templateList ~= nil then
            for _, v in ipairs(templateList) do
                if not haveMap[v._Tid] then
                    -- 模版里排除已拥有的，就是未拥有的
                    local data = CDress.CreateVirtual(v._Tid)
                    table.insert(dontHaveList, data)
                end
            end
            -- 排序未拥有的
            table.sort(dontHaveList, sortFunc)
        end
        -- 合并
        for _, v in ipairs(dontHaveList) do
            table.insert(slotList, v)
        end
    end
    self._AllShowMap[pageType] = slotList
end

-- 时装的图标路径和品质字段不同于物品的，需要单独设置
local function SetDressIcon(obj, iconPath, quality, enableGrey)
    if IsNil(obj) then return end

    local iconObj = GUITools.GetChild(obj, 3)
    if IsNil(iconObj) then return end
    -- 图标
    local img_icon = GUITools.GetChild(iconObj, 3)
    if not IsNil(img_icon) then
        if not IsNilOrEmptyString(iconPath)  then
            GUITools.SetItemIcon(img_icon, iconPath)
        else
            GUITools.SetItemIcon(img_icon, PATH.ICON_ITEM_MARK) -- 写死一个默认的图片
        end
        GameUtil.MakeImageGray(img_icon, enableGrey)
    end
    local img_quality_bg = GUITools.GetChild(iconObj, 1)
    if not IsNil(img_quality_bg) then
        GUITools.SetUIActive(img_quality_bg, not enableGrey)
        if not enableGrey then
            GUITools.SetGroupImg(img_quality_bg, quality)
        end
    end
    local img_quality = GUITools.GetChild(iconObj, 2)
    if not IsNil(img_quality) then
        GUITools.SetUIActive(img_quality, not enableGrey)
        if not enableGrey then
            GUITools.SetGroupImg(img_quality, quality)
        end
    end
end

-- 获取部位红点状态
local function GetSlotRedPointStatus(slot)
    -- local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
    -- if exteriorMap ~= nil then
    --     local dressMap = exteriorMap["Dress"]
    --     if dressMap ~= nil then
    --         local redDotStatusMap = dressMap[slot]
    --         if redDotStatusMap ~= nil then
    --             for _, status in pairs(redDotStatusMap) do
    --                 if status then
    --                     return true
    --                 end
    --             end
    --         end
    --     end
    -- end
    return false
end

-- 获取红点状态
local function GetRedPointStatus(slot, id, isChangeStatus)
    local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
    if exteriorMap ~= nil then
        local key = "Dress"
        local dressMap = exteriorMap[key]
        if dressMap ~= nil then
            local redDotStatusMap = dressMap[slot]
            if redDotStatusMap ~= nil and redDotStatusMap[id] == true then
                if isChangeStatus then
                    redDotStatusMap[id] = nil

                    if next(exteriorMap[key][slot]) == nil then
                        exteriorMap[key][slot] = nil
                    end
                    if next(exteriorMap[key]) == nil then
                        exteriorMap[key] = nil
                    end
                    if next(exteriorMap) == nil then
                        exteriorMap = nil
                    end
                    CRedDotMan.SaveModuleDataToUserData(RedDotSystemType.Exterior, exteriorMap)
                end
                return true
            end
        end
    end
    return false
end

-- 根据页签返回外观相机类型
local function GetCamType(pageType)
    if pageType == LeftPageType.Helmet then
        return EnumDef.CamExteriorType.Helmet
    elseif pageType == LeftPageType.Weapon then
        return EnumDef.CamExteriorType.Weapon
    end
    return EnumDef.CamExteriorType.Armor
end

------------------------------以下方法不能删除--------------------------------
def.method("dynamic").Show = function(self, data)
    if type(data) == "number" then
        -- 转换枚举
        local map = 
        {
            [EnumDef.CamExteriorType.Armor] = LeftPageType.Armor,
            [EnumDef.CamExteriorType.Helmet] = LeftPageType.Helmet,
            [EnumDef.CamExteriorType.Weapon] = LeftPageType.Weapon
        }
        if map[data] ~= nil then
            self._CurrentLeftPage = map[data]
        end
    end
    if self._CurrentLeftPage <= 0 then
        -- 默认打开衣服
        self._CurrentLeftPage = LeftPageType.Armor
    end
    GUI.SetGroupToggleOn(self._PanelObject.RdoGroup_Left, self._CurrentLeftPage)

    local slotList = self._AllShowMap[self._CurrentLeftPage]
    self:SetLeftList(slotList)

    -- 更新所有左页签的红点UI
    for _, pageType in pairs(LeftPageType) do
        self:UpdateLeftPageRedPoint(pageType)
    end

    self:ChangeCombatState(self._CurrentLeftPage == LeftPageType.Weapon, true)
end

def.method("boolean", "number").ChangePage = function(self, bIsLeft, pageIndex)
    if bIsLeft then
        if self._CurrentLeftPage == pageIndex then return end
        self:ChangeLeftPage(pageIndex)
    else
        if self._CurrentRightPage == pageIndex then return end
        self._CurrentRightPage = pageIndex

        if pageIndex == RightPageType.DressInfo then
            self:ShowDressInfo(self._SelectedDressMap[self._CurrentLeftPage])
        elseif pageIndex == RightPageType.DyeInfo then
            self:ShowDyeInfo(self._SelectedDressMap[self._CurrentLeftPage])
        end
    end
end

def.method("string").OnExteriorClick = function(self, id)
    if string.find(id, "Btn_Addition") then
        -- 打开加成界面
        game._GUIMan:Open("CPanelUIDressAttributeCheck", nil)
    elseif string.find(id, "Btn_ChangePose") then
        -- 切换战斗状态
        if self._CombatChangingTimerId ~= 0 then return end
        self:AddCombatChangingTimer() -- 防止快速点击
        self:ChangeCombatState(not game._HostPlayer:IsInCombatState(), false)
    elseif string.find(id, "Btn_PutOn") then
        local data = self._SelectedDressMap[self._CurrentLeftPage]
        if data == nil then return end

        local dressId = self._CDressManIns:GetCurDressIdBySlot(data._DressSlot)
        if data._ID ~= dressId then
            -- 穿戴时装
            self._CDressManIns:PutOn(data._ID)
        else
            -- 卸下时装
            self._CDressManIns:TakeOff(dressId)
            self:EnableRightInfo(false)
            self._Parent:EnableRightTips(true)
            -- 清空选中数据
            self._SelectedDressMap[self._CurrentLeftPage] = nil
            self._SelectedDyeMap[self._CurrentLeftPage] = {}
        end
    elseif string.find(id, "Btn_Decompose") then
        -- 分解
        local data = self._SelectedDressMap[self._CurrentLeftPage]
        if data == nil or data._ID <= 0 then return end

        local function callback(ret)
            if ret then
                self._CDressManIns:C2SDecomposeDress(data._ID)
            end
        end
        local title, msg, closeType = StringTable.GetMsg(118)
        local specStr = StringTable.Get(20711)
        local setting = {
            [MsgBoxAddParam.SpecialStr] = specStr,
            [MsgBoxAddParam.GainMoneyID] = data._Template.DecomposeMoneyId,
            [MsgBoxAddParam.GainMoneyCount] = data._Template.DecomposeMoneyCount,
        }
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback,nil,nil,nil,setting)
    elseif string.find(id, "Btn_Tint") then
        -- 染色
        if not self:IsDyeStuffsEnough() then
            game._GUIMan:ShowTipText(StringTable.Get(20712), false)
            return
        end
        self:TryDyeDress()
    elseif string.find(id, "Btn_Approach_Dress") then
        local dressInfo = self._SelectedDressMap[self._CurrentLeftPage]
        if dressInfo == nil then return end
        
        local data = 
        {
            ApproachIDs = dressInfo._Template.ApproachIDs,
            ParentObj = self._PanelObject.Frame_DressInfo
        }
        game._GUIMan:Open("CPanelItemApproach", data)
    elseif string.find(id, "Btn_DyeStuff_") then
        local index = tonumber(string.sub(id, -1))
        if index == nil then return end

        local btn_stuff = self._PanelObject.DyeStuffObjList[index]
        if IsNil(btn_stuff) then return end

        local newDyeIds = self:GetNewDyeIdList()
        if newDyeIds == nil then return end

        local stuffItemList = CDressUtility.GetDyeStuffItemList(newDyeIds)
        local data = stuffItemList[index]
        if data ~= nil then
            CItemTipMan.ShowItemTips(data.ItemId, TipsPopFrom.OTHER_PANEL, btn_stuff, TipPosition.FIX_POSITION)
        end
    end
end

def.method("string", "boolean").OnExteriorToggle = function(self, id, checked)
    if id == "Rdo_Armor" and checked then
        self:ChangePage(true, LeftPageType.Armor)
    elseif id == "Rdo_Helmet" and checked then
        self:ChangePage(true, LeftPageType.Helmet)
    elseif id == "Rdo_Weapon" and checked then
        self:ChangePage(true, LeftPageType.Weapon)
    elseif id == "Rdo_DressInfo" and checked then
        self:ChangePage(false, RightPageType.DressInfo)
    elseif id == "Rdo_Dye" and checked then
        self:ChangePage(false, RightPageType.DyeInfo)
    end
end

def.method("userdata", "string", "number").OnExteriorInitItem = function(self, item, id, index)
    if id == "List_Dress" then
        self:OnInitLeftList(item, index)
    elseif string.find(id, "List_TintPos_") then
        self:OnInitTintPosList(item, id, index)
    end
end

def.method("userdata", "string", "number").OnExteriorSelectItem = function(self, item, id, index)
    if id == "List_Dress" then
        self:OnClickLeftList(item, index)
    elseif string.find(id, "List_TintPos_") then
        self:OnClickTintPosList(item, id, index)
    end
end

-- 返回当前外观相机类型
def.method("=>", "number").GetCurCamType = function (self)
    return GetCamType(self._CurrentLeftPage)
end

-- 页签内是否有红点显示
def.method("=>", "boolean").IsPageHasRedPoint = function (self)
    -- 检查所有数据表
    for _, slot in pairs(EDressType) do
        if type(slot) == "number" then
            local bHasRedPoint = GetSlotRedPointStatus(slot)
            if bHasRedPoint then
                return true
            end
        end
    end
    return false
end

-- 背包物品更新
def.method().OnPackageChangeEvent = function (self)
    self:UpdateDyeStuff()
    self:UpdateButtonTint()
end

def.method().OnChangeFrame = function (self)
    self:ChangeCombatState(false, true)
end

def.method().Hide = function(self)
    self:RemoveCombatChangingTimer()
    self._RedPointChangeStatusCacheMap = {}
end

def.method().Destroy = function (self)
    self._Parent = {}
    self._Panel = nil
    self._PanelObject = {}
    self._AllShowMap = {}
    self._CurrentLeftPage = 0
    self._CurrentRightPage = 0
    self._SelectedDressMap = {}
    self._SelectedDyeMap = {}
end
-------------------------------以上方法不能删除----------------------------------

---------------------------------左列表 start------------------------------------
def.method("table").SetLeftList = function (self, slotList)
    if slotList == nil then return end

    if #slotList > 0 then
        self._PanelObject.ListObj_Dress:SetActive(true)

        -- 设置缓存表
        for _, data in ipairs(slotList) do
            local isNew = GetRedPointStatus(data._DressSlot, data._ID, true)
            if isNew then
                self._RedPointChangeStatusCacheMap[data._ID] = true
            end
        end
        -- 设置选中索引
        self:SetLeftSelectedIndex(slotList)
        self:EnableRightInfo(self._SelectedIndex >= 0)
        self._PanelObject.List_Dress:SetItemCount(#slotList)
        -- 初始化结束
        if self._SelectedIndex >= 0 then
            --  滑动至选中索引
            self._PanelObject.List_Dress:ScrollToStep(self._SelectedIndex)
            self._PanelObject.List_Dress:SetSelection(self._SelectedIndex)

            for index, data in ipairs(slotList) do
                if self._SelectedIndex == index - 1 then
                    -- 找到选中
                    if next(self._SelectedDyeMap[self._CurrentLeftPage]) == nil then
                        -- 第一次进入此左页签
                        -- 设置此左页签的染色数据
                        local initColors = {}
                        for _, dyeId in ipairs(data._Colors) do
                            table.insert(initColors, dyeId)
                        end
                        self._SelectedDyeMap[self._CurrentLeftPage] = initColors

                        self:UpdateHostPlayerDress(data)
                    end

                    self:SelectDress(data)
                    break
                end
            end
        end
    else
        self._PanelObject.ListObj_Dress:SetActive(false)
        self:EnableRightInfo(false)
    end
end

-- 设置左列表的选中项
def.method("table").SetLeftSelectedIndex = function (self, slotList)
    self._SelectedIndex = -1 -- 重置
    local dressInfo = self._SelectedDressMap[self._CurrentLeftPage]
    if dressInfo ~= nil then
        local isGot = dressInfo._ID > 0
        for i, v in ipairs(slotList) do
            if isGot then
                -- 对于已获得的，对比实例Id
                if v._ID == dressInfo._ID then
                    self._SelectedIndex = i - 1
                    break
                end
            else
                -- 对于未获得的，对比模版Id
                if v._ID <= 0 and v._Tid == dressInfo._Tid then
                    self._SelectedIndex = i - 1
                    break
                end
            end
        end
    else
        -- 第一次进入此左页签
        -- 找到正穿戴的时装
        for i, v in ipairs(slotList) do
            if v._IsWeared then
                self._SelectedIndex = i - 1
                break
            end
        end
        -- if self._SelectedIndex < 0 then
        --     -- 没有穿戴时装默认选择第一个
        --     self._SelectedIndex = 0
        -- end
    end
end

-- 获取时限的显示文本
local function GetShowTimeStr(time)
    local day = math.floor(time / 86400)
    local hour = math.floor(time % 86400 / 3600)
    local minute = math.floor(time % 3600 / 60)
    local str = ""
    if day > 0 then
        str = string.format(StringTable.Get(601), day)
        if hour > 0 then
            str = str .. string.format(StringTable.Get(602), hour)
        end
    elseif hour > 0 then
        str = string.format(StringTable.Get(602), hour)
        if minute > 0 then
            str = str .. string.format(StringTable.Get(603), minute)
        end
    elseif minute > 0 then
        str = string.format(StringTable.Get(603), minute)
    end
    str = str .. StringTable.Get(20708)
    return str
end

def.method("userdata", "number").OnInitLeftList = function (self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if uiTemplate == nil then return end

    local slotList = self._AllShowMap[self._CurrentLeftPage]
    if slotList == nil then return end

    local data = slotList[index+1]
    local isGot = data._ID > 0 -- 是否已拥有
    -- 背景
    local img_bg = uiTemplate:GetControl(0)
    GameUtil.MakeImageGray(img_bg, not isGot)
    -- 图标
    local img_icon = uiTemplate:GetControl(2)
    GUITools.SetItemIcon(img_icon, data._Template.IconPath)
    GameUtil.MakeImageGray(img_icon, not isGot)
    -- 是否已装备
    local img_tag_equip = uiTemplate:GetControl(3)
    GUITools.SetUIActive(img_tag_equip, data._IsWeared)
    -- 是否新时装
    local isNew = self._RedPointChangeStatusCacheMap[data._ID] == true
    local img_new = uiTemplate:GetControl(9)
    GUITools.SetUIActive(img_new, isNew)
    self._PanelObject.ImgNewObjList[index+1] = img_new
    -- 染色部位颜色，一共两个
    for i = 1, 2 do
        local isHide = true
        local img_color_obj = uiTemplate:GetControl(7 + i - 1)
        if isGot then
            local dyeId = data._Colors[i]
            if dyeId ~= nil then
                local color = CDressUtility.GetColorInfoByDyeId(dyeId)
                if color ~= nil then
                    GameUtil.SetImageColor(img_color_obj, color)
                    isHide = false
                end
            end
        end
        GUITools.SetUIActive(img_color_obj, not isHide)
    end
    local quality = data._Template.Quality
    local nameStr = RichTextTools.GetQualityText(data._Template.ShowName, quality)
    local qualityStr = StringTable.Get(10000 + quality)
    -- 时限
    local lab_left_time = uiTemplate:GetControl(6)
    GUITools.SetUIActive(lab_left_time, isGot)
    if isGot then
        qualityStr = RichTextTools.GetQualityText(qualityStr, quality)
        if data._TimeLimit == 0 then
            -- 永久
            GUI.SetText(lab_left_time, StringTable.Get(22109))
        else
            -- print("ServerTime:", GameUtil.GetServerTime())
            local leftTime = (data._TimeLimit - GameUtil.GetServerTime()) / 1000
            -- print("leftTime", leftTime)
            GUI.SetText(lab_left_time, GetShowTimeStr(leftTime))
        end
    else
        -- 字体变灰
        nameStr = "<color=#909AA8>" .. data._Template.ShowName .. "</color>"
        qualityStr = "<color=#909AA8>" .. qualityStr .. "</color>"
    end
    -- 名字
    local lab_name = uiTemplate:GetControl(5)
    GUI.SetText(lab_name, nameStr)
    -- 品质
    local lab_quality = uiTemplate:GetControl(1)
    GUI.SetText(lab_quality, qualityStr)
end

def.method("userdata", "number").OnClickLeftList = function (self, item, index)
    local slotList = self._AllShowMap[self._CurrentLeftPage]
    if slotList == nil then return end

    if self._SelectedIndex == index then return end

    self._PanelObject.List_Dress:SetSelection(index)

    local data = slotList[index+1]
    -- 更新UI红点
    if self._RedPointChangeStatusCacheMap[data._ID] == true then
        self._RedPointChangeStatusCacheMap[data._ID] = nil

        local img_new_list = self._PanelObject.ImgNewObjList[index+1]
        if not IsNil(img_new_list) then
            GUITools.SetUIActive(img_new_list, false)
        end
    end

    self:UpdateHostPlayerDress(data)
    -- 重新设置此左页签的染色数据
    local initColors = {}
    for _, dyeId in ipairs(data._Colors) do
        table.insert(initColors, dyeId)
    end
    self._SelectedDyeMap[self._CurrentLeftPage] = initColors
    self._SelectedIndex = index

    self:EnableRightInfo(true)
    self:SelectDress(data)
end

-- 更新主角时装模型和染色
def.method(CDress).UpdateHostPlayerDress = function (self, data)
    if data == nil then return end

    local hp = game._HostPlayer
    hp:UpdateDressModel(data, true)
    hp:PlayDressFightFx(data)
end

def.method("boolean", "boolean").ChangeCombatState = function (self, is_in_combat_state, ignoreLerp)
    local hp = game._HostPlayer
    hp:UpdateCombatState(is_in_combat_state, true, 0, ignoreLerp, false)
    if is_in_combat_state ~= self._CurCombatState then
        local weaponDressInfo = self._SelectedDressMap[LeftPageType.Weapon]
        if weaponDressInfo == nil then
            -- 没有缓存的数据，取人物身上的数据
            weaponDressInfo = hp:GetCurDressInfoByPart(EnumDef.PlayerDressPart.Weapon)
        end
        hp:PlayDressFightFx(weaponDressInfo)
    end
    self._CurCombatState = is_in_combat_state
end

def.method("number").ChangeLeftPage = function (self, pageType)
    self:RemoveCombatChangingTimer()
    -- 特殊处理Toggle显示
    GUI.SetGroupToggleOn(self._PanelObject.RdoGroup_Left, self._CurrentLeftPage)
    -- 镜头
    local CExteriorMan = require "Main.CExteriorMan"
    local camType = GetCamType(pageType)
    CExteriorMan.ChangeCamParams(camType, 0)
    if pageType == LeftPageType.Weapon then
        -- 进入武器页签
        self:ChangeCombatState(true, true)
    elseif self._CurrentLeftPage == LeftPageType.Weapon then
        -- 离开武器页签
        self:ChangeCombatState(false, true)
    end

    -- 动效
    -- self._Parent:RestartDoTween(self._Parent._ETweenType.MoveOut, function()
        self._RedPointChangeStatusCacheMap = {}

        self._CurrentLeftPage = pageType
        GUI.SetGroupToggleOn(self._PanelObject.RdoGroup_Left, pageType)

        local slotList = self._AllShowMap[pageType]
        self:SetLeftList(slotList)
        self:UpdateLeftPageRedPoint(pageType) -- 更新新左页签的红点UI
        self._Parent:UpdateCurPageRedPoint() -- 更新当前底部页签的红点UI

    --     self._Parent:RestartDoTween(self._Parent._ETweenType.MoveIn, nil)
    -- end)
end

-- 更新单个左页签红点
def.method("number").UpdateLeftPageRedPoint = function (self, pageType)
    local slot1, slot2 = -1, -1
    if pageType == LeftPageType.Armor then
        slot1 = EDressType.Armor
    elseif pageType == LeftPageType.Weapon then
        slot1 = EDressType.Weapon
    elseif pageType == LeftPageType.Helmet then
        slot1 = EDressType.Hat
        slot2 = EDressType.Headdress
    end

    local bShow = false
    if slot1 > -1 then
        bShow = GetSlotRedPointStatus(slot1)
    end
    if not bShow and slot2 > -1 then
        bShow = GetSlotRedPointStatus(slot2)
    end
    self:EnableRdoImgRedPoint(pageType, bShow)
end

def.method("number", "boolean").EnableRdoImgRedPoint = function (self, pageType, enable)
    local img_new_rdo = self._PanelObject.RdoRedPointObjList[pageType]
    if not IsNil(img_new_rdo) then
        GUITools.SetUIActive(img_new_rdo, enable)
    end
end
---------------------------------左列表 end------------------------------------

---------------------------------右信息 start------------------------------------
-- 选中某件时装
def.method(CDress).SelectDress = function (self, data)
    if data == nil then return end

    self._SelectedDressMap[self._CurrentLeftPage] = data
    self:SetRightInfo(data)
end

-- 设置右边框信息
def.method(CDress).SetRightInfo = function (self, data)
    if data == nil then return end
    -- 图标
    local iconPath = data._Template.IconPath
    SetDressIcon(self._PanelObject.Frame_Icon, iconPath, data._Template.Quality, false)
    -- 染色部位颜色，一共两个
    for i = 1, 2 do
        local isHide = true
        local img_color_obj = self._Parent:GetUIObject("Img_IconColor_" .. i)
        if data._ID > 0 then
            local dyeId = data._Colors[i]
            if dyeId ~= nil then
                local color = CDressUtility.GetColorInfoByDyeId(dyeId)
                if color ~= nil then
                    GameUtil.SetImageColor(img_color_obj, color)
                    isHide = false
                end
            end
        end
        GUITools.SetUIActive(img_color_obj, not isHide)
    end
    -- 名字
    GUI.SetText(self._PanelObject.Lab_DressName, RichTextTools.GetQualityText(data._Template.ShowName, data._Template.Quality))
    -- 品质
    local quality = data._Template.Quality
    local qualityStr = RichTextTools.GetQualityText(StringTable.Get(10000 + quality), quality)
    GUI.SetText(self._PanelObject.Lab_Quality, qualityStr)
    -- 页签
    local rightPage = self._CurrentRightPage
    if rightPage <= 0 then
        -- 默认打开信息页签
        rightPage = RightPageType.DressInfo    
    end
    self._CurrentRightPage = 0
    GUI.SetGroupToggleOn(self._PanelObject.RdoGroup_Right, rightPage)
    self:ChangePage(false, rightPage)
end

-- 显示信息页签
def.method(CDress).ShowDressInfo = function (self, data)
    if data == nil then return end

    GUITools.SetUIActive(self._PanelObject.Frame_DressInfo, true)
    self._PanelObject.Frame_DyeInfo:SetActive(false)
    -- 介绍
    GUI.SetText(self._PanelObject.Lab_Des, data._Template.Description)
    -- 魅力值
    GUI.SetText(self._PanelObject.Lab_CharmValue, tostring(data._Template.Score))
    -- 来源
    GUI.SetText(self._PanelObject.Lab_Origin, data._Template.Origin)
    local isGot = data._ID > 0
    -- 分解提示
    GUITools.SetUIActive(self._PanelObject.Frame_DecomposeTips, isGot)
    if isGot then
        GUITools.SetTokenMoneyIcon(self._PanelObject.Img_DecomposeMoney, data._Template.DecomposeMoneyId)
        GUI.SetText(self._PanelObject.Lab_DecomposeMoney, tostring(data._Template.DecomposeMoneyCount))
    end
    -- 按钮
    -- GameUtil.SetButtonInteractable(self._PanelObject.Btn_PutOn, data._ID > 0)
    GUITools.SetUIActive(self._PanelObject.Btn_Approach, not isGot)
    GUITools.SetUIActive(self._PanelObject.Btn_PutOn, isGot)
    GUITools.SetUIActive(self._PanelObject.Btn_Decompose, isGot)
    if data._ID > 0 then
        -- 已拥有
        local btnStr = data._IsWeared and StringTable.Get(20702) or StringTable.Get(20701)
        GUI.SetText(self._PanelObject.Lab_PutOn, btnStr)
    end
end

-- 显示染色页签
def.method(CDress).ShowDyeInfo = function (self, data)
    if data == nil then return end

    GUITools.SetUIActive(self._PanelObject.Frame_DressInfo, false)
    self._PanelObject.Frame_DyeInfo:SetActive(true)

    local isCanTint = #data._Colors > 0 -- 是否可以染色
    local isGot = data._ID > 0 -- 是否已拥有
    GUITools.SetUIActive(self._PanelObject.Lab_CantTint, not isCanTint)
    GUITools.SetUIActive(self._PanelObject.Frame_DyeStuff, isCanTint)
    GUITools.SetUIActive(self._PanelObject.Lab_GetDress, not isGot and isCanTint)
    self._PanelObject.Btn_Tint:SetActive(isGot and isCanTint)
    self._PanelObject.Frame_TintPos_1:SetActive(isCanTint)
    self._PanelObject.Frame_TintPos_2:SetActive(isCanTint)

    if isCanTint then
        local dyeColorList_1 = data._CanDyeColors[1] -- 部位一染色列表
        if #dyeColorList_1 > 0 then
            self._PanelObject.List_TintPos_1:SetItemCount(#dyeColorList_1)
            -- 选中效果
            local curColorInfo = self._SelectedDyeMap[self._CurrentLeftPage]
            local curDyeId_1 = curColorInfo[1]
            if curDyeId_1 ~= nil then
                for i, dyeId in ipairs(dyeColorList_1) do
                    if curDyeId_1 == dyeId then
                        self._PanelObject.List_TintPos_1:ScrollToStep(i-1)
                        self._PanelObject.List_TintPos_1:SetSelection(i-1)
                        break
                    end
                end
            end
            -- 部位一有染色，部位二才有可能有染色
            local dyeColorList_2 = data._CanDyeColors[2] -- 部位二染色列表
            if dyeColorList_2 ~= nil and #dyeColorList_2 > 0 then
                self._PanelObject.List_TintPos_2:SetItemCount(#dyeColorList_2)
                -- 选中效果
                local curDyeId_2 = curColorInfo[2]
                if curDyeId_2 ~= nil then
                    for i, dyeId in ipairs(dyeColorList_2) do
                        if curDyeId_2 == dyeId then
                            self._PanelObject.List_TintPos_2:ScrollToStep(i-1)
                            self._PanelObject.List_TintPos_2:SetSelection(i-1)
                            break
                        end
                    end
                end
            else
                self._PanelObject.Frame_TintPos_2:SetActive(false)
            end
        else
            self._PanelObject.Frame_TintPos_1:SetActive(false)
        end

        self:UpdateDyeStuff()
        if isGot then
            self:UpdateButtonTint()
        end
    end
end

-- 初始化部位染色列表
def.method("userdata", "string", "number").OnInitTintPosList = function(self, item, id, index)
    local pos = tonumber(string.sub(id, -1))
    if pos == nil then return end

    local dressInfo = self._SelectedDressMap[self._CurrentLeftPage]
    if dressInfo == nil then return end

    local dyeIds = dressInfo._CanDyeColors[pos]
    if dyeIds == nil then
        warn("ExteriorDress TintPos is wrong, wrong pos:" ..  pos .. ", DyePos length:" .. #dressInfo._CanDyeColors)
        return
    end

    local dyeId = dyeIds[index+1]
    local color = CDressUtility.GetColorInfoByDyeId(dyeId)
    if color == nil then
        warn("ExteriorDress DyeAndEmbroidery template is nil, id:", dyeId)
        return
    end

    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if uiTemplate == nil then return end
    -- 图标
    local img_icon = uiTemplate:GetControl(0)
    GameUtil.SetImageColor(img_icon, color)
    -- 是否当前染色
    local isCurTint = false
    if dressInfo._ID > 0 then
        -- 对于已获得的时装
        local initDyeId = dressInfo._Colors[pos]
        if initDyeId > 0 and initDyeId == dyeId then
            -- 是当前时装的颜色
            isCurTint = true
        end
    end
    local lab_cur_tint = uiTemplate:GetControl(3)
    GUITools.SetUIActive(lab_cur_tint, isCurTint)
end

def.method("userdata", "string", "number").OnClickTintPosList = function(self, item, id, index)
    local pos = tonumber(string.sub(id, -1))
    if pos == nil then return end

    self:ChangeDye(item, pos, index)
end

-- 选择染色
def.method("userdata", "number", "number").ChangeDye = function (self, item, pos, index)
    local dressInfo = self._SelectedDressMap[self._CurrentLeftPage]
    if dressInfo == nil then return end

    local dyeIds = dressInfo._CanDyeColors[pos]
    if dyeIds == nil or #dyeIds <= 0 then return end

    local curDyeId = self._SelectedDyeMap[self._CurrentLeftPage][pos]
    local selectDyeId = dyeIds[index+1]
    if curDyeId == selectDyeId then return end -- 点击同一色块

    -- 选中效果
    if pos == 1 then
        self._PanelObject.List_TintPos_1:SetSelection(index)
    elseif pos == 2 then
        self._PanelObject.List_TintPos_2:SetSelection(index)
    end

    local dyeIdList = { 0, 0 }
    dyeIdList[pos] = selectDyeId
    game._HostPlayer:UpdateDressColors(dressInfo._DressSlot, dyeIdList)

    self._SelectedDyeMap[self._CurrentLeftPage][pos] = selectDyeId

    self:UpdateDyeStuff()
    if dressInfo._ID > 0 then
        self:UpdateButtonTint()
    end
end

-- 更新染色材料
def.method().UpdateDyeStuff = function (self)
    if self._CurrentRightPage ~= RightPageType.DyeInfo then return end

    local newDyeIds = self:GetNewDyeIdList() -- 新修改的染色
    if newDyeIds == nil then return end

    local stuffItemList = CDressUtility.GetDyeStuffItemList(newDyeIds)
    GUITools.SetUIActive(self._PanelObject.Frame_DyeStuff, #stuffItemList > 0)
    if #stuffItemList > 0 then
        local objIndex = 1
        for _, data in ipairs(stuffItemList) do
            local btn_stuff = self._PanelObject.DyeStuffObjList[objIndex]
            if IsNil(btn_stuff) then break end

            btn_stuff:SetActive(true)
            IconTools.InitMaterialIconNew(btn_stuff, data.ItemId, data.ItemCount)
            objIndex = objIndex + 1
        end
        -- 隐藏多余的GameObject
        for i = objIndex, DYE_STUFF_MAX_NUM do
            local btn_stuff = self._PanelObject.DyeStuffObjList[i]
            if IsNil(btn_stuff) then break end

            btn_stuff:SetActive(false)
        end
    end
end

-- 更新按钮
def.method().UpdateButtonTint = function (self)
    if self._CurrentRightPage ~= RightPageType.DyeInfo then return end

    local newDyeIds = self:GetNewDyeIdList()
    if newDyeIds == nil then return end

    local isBtnEnable = false
    if #newDyeIds > 0 then
        isBtnEnable = self:IsDyeStuffsEnough()
    end
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_Tint, #newDyeIds > 0)
    GUITools.SetBtnExpressGray(self._PanelObject.Btn_Tint, not isBtnEnable)
    GameUtil.MakeImageGray(self._PanelObject.Img_Tint, not isBtnEnable)
end
---------------------------------右信息 end------------------------------------
-- 材料是否足够
def.method("=>", "boolean").IsDyeStuffsEnough = function (self)
    local newDyeIds = self:GetNewDyeIdList() -- 新修改的染色
    if newDyeIds == nil then return false end
    -- 检查材料
    local stuffItemList = CDressUtility.GetDyeStuffItemList(newDyeIds)
    local normalPack = game._HostPlayer._Package._NormalPack -- 普通背包
    for _, data in pairs(stuffItemList) do
        if data.ItemCount > normalPack:GetItemCount(data.ItemId) then
            return false
        end
    end
    return true
end

-- 获取新修改的（未保存的）染色Id列表
-- _SelectedDressMap[pageType]._Colors 保存了时装的服务器数据的颜色
-- _SelectedDyeMap[pageType] 保存了时装目前显示的颜色
def.method("=>", "table").GetNewDyeIdList = function (self)
    local curData = self._SelectedDressMap[self._CurrentLeftPage]
    if curData == nil or #curData._Colors <= 0 then return nil end

    local curDyeIds = self._SelectedDyeMap[self._CurrentLeftPage]
    if curDyeIds == nil or #curDyeIds <= 0 then return nil end

    local newDyeIds = {}
    for i, originDyeId in ipairs(curData._Colors) do
        if curDyeIds[i] ~= nil and originDyeId ~= curDyeIds[i] then
            -- 当前选择的染色Id不等于初始的染色Id，属于新的染色
            table.insert(newDyeIds, curDyeIds[i])
        end
    end
    return newDyeIds
end

-- 尝试进行染色
def.method().TryDyeDress = function (self)
    local curData = self._SelectedDressMap[self._CurrentLeftPage]
    if curData == nil or #curData._Colors <= 0 then return end

    local curDyeIds = self._SelectedDyeMap[self._CurrentLeftPage]
    if curDyeIds == nil or #curDyeIds <= 0 then return end

    local dyeIds = {}
    -- 从部位一到部位二
    for i = 1, 2 do
        local curDyeId = curDyeIds[i] -- 当前选择的染色Id
        local originDyeId = curData._Colors[i] -- 原来的染色Id
        if curDyeId ~= nil and originDyeId ~= nil and curDyeId > 0 and originDyeId > 0 and curDyeId ~= originDyeId then
            dyeIds[i] = curDyeId -- 新的染色
        else
            dyeIds[i] = -1 -- 不染
        end
    end

    if dyeIds[1] > 0 or dyeIds[2] > 0 then
        -- 至少有一个部位染色
        self._CDressManIns:DyeDress(curData._ID, dyeIds[1], dyeIds[2])
    end
end

def.method("boolean").EnableRightInfo = function (self, enable)
    GUITools.SetUIActive(self._PanelObject.Frame_Right, enable)
    -- self._PanelObject.Frame_Right:SetActive(enable)
    self._Parent:EnableRightTips(not enable)
end

def.method().AddCombatChangingTimer = function (self)
    self:RemoveCombatChangingTimer()
    if self._CombatChangeAniLength > 0 then
        self._CombatChangingTimerId = _G.AddGlobalTimer(self._CombatChangeAniLength, true, function()
            self:RemoveCombatChangingTimer()
        end)
    end
end

def.method().RemoveCombatChangingTimer = function (self)
    if self._CombatChangingTimerId ~= 0 then
        _G.RemoveGlobalTimer(self._CombatChangingTimerId)
        self._CombatChangingTimerId = 0
    end
end

---------------------------外部接口--------------------------
-- 更新时装列表
def.method().UpdateDressList = function (self)
    if self._CurrentLeftPage <= 0 then return end

    local slotList = self._AllShowMap[self._CurrentLeftPage]
    self:SetLeftList(slotList)

    -- 更新所有左页签的红点UI
    for _, pageType in pairs(LeftPageType) do
        self:UpdateLeftPageRedPoint(pageType)
    end
    -- 更新底部页签的红点UI
    self._Parent:UpdateCurPageRedPoint()
end

-- 更新选中数据
def.method("boolean").UpdateSelectDress = function (self, isRemove)
    if self._CurrentLeftPage <= 0 then return end

    local curDressInfo = self._SelectedDressMap[self._CurrentLeftPage]
    if curDressInfo ~= nil then
        if isRemove then
            if curDressInfo._ID > 0 then
                -- 之前选中了已拥有时装
                local newDressInfo = nil
                local hasRemove = true -- 原来选择的时装是否被移除
                for _, dressInfo in ipairs (self._AllShowMap[self._CurrentLeftPage]) do
                    if dressInfo._Tid == curDressInfo._Tid then
                        if newDressInfo == nil then
                            -- 记录第一个找到的相同TID时装
                            newDressInfo = dressInfo
                        end
                        if dressInfo._ID == curDressInfo._ID then
                            hasRemove = false
                        end
                    end
                end
                if hasRemove then
                    self._SelectedDressMap[self._CurrentLeftPage] = newDressInfo
                end
            end
        else
            if curDressInfo._ID <= 0 then
                -- 之前选中了未拥有时装
                for _, dressInfo in ipairs (self._AllShowMap[self._CurrentLeftPage]) do
                    if dressInfo._Tid == curDressInfo._Tid and dressInfo._ID > 0 then
                        self._SelectedDressMap[self._CurrentLeftPage] = dressInfo
                        break
                    end
                end
            end
        end
    end
end

CPageDress.Commit()
return CPageDress