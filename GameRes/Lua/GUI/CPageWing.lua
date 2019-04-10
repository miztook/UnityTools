-- 外观翅膀页
-- 时间：2017/9/8
-- Add by Yao

local Lplus = require "Lplus"
local CPageWing = Lplus.Class("CPageWing")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPageWing.define

local CElementData = require "Data.CElementData"
local CWingsManIns = require "Wings.CWingsMan".Instance()
local EWingQuality = require "PB.Template".Wing.EWingQuality

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Chk_AlreadyHave = nil
def.field("userdata")._Drop_Quality = nil
def.field("userdata")._View_Wing = nil
def.field("userdata")._List_Wing = nil
def.field("userdata")._Frame_Right = nil
def.field("userdata")._Frame_Icon = nil 
def.field("userdata")._Lab_WingName = nil
def.field("userdata")._Lab_Quality = nil
def.field("userdata")._Lab_Des = nil
def.field("userdata")._Lab_Level = nil
def.field("userdata")._Lab_Origin = nil
def.field("userdata")._Frame_SpecialTips = nil
def.field("userdata")._Lab_SpecialTips = nil
def.field("userdata")._Btn_Operate = nil
def.field("userdata")._Lab_Operate = nil
def.field("userdata")._Btn_Approach = nil
def.field("table")._ImgTable_New = BlankTable
-- 缓存
def.field("boolean")._IsCheckLeft = false -- 是否筛选已拥有
def.field("table")._ListQuality = BlankTable -- 品质列表
def.field("number")._CurQualityIndex = 0 -- 当前品质索引，从1开始，0代表全部
def.field("table")._WingListShow = BlankTable -- 展示列表
def.field("number")._SelectedWingId = 0 -- 指定的翅膀ID
def.field("table")._CurWingData = nil -- 当前翅膀数据
def.field("table")._RedPointChangeStatusCacheMap = BlankTable -- 红点状态发生了改变的缓存表
-- 数据
def.field("table")._WingListAll = BlankTable -- 所有翅膀列表

def.static("table", "userdata", "=>", CPageWing).new = function(parent, panel)
    local instance = CPageWing()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    local toggle = ClassType.Toggle
    self._Chk_AlreadyHave = self._Parent:GetUIObject("Chk_AlreadyHave_Wing"):GetComponent(toggle)
    self._Drop_Quality = self._Parent:GetUIObject("Drop_Group_Wing")
    self._View_Wing = self._Parent:GetUIObject("View_Wing")
    self._List_Wing = self._Parent:GetUIObject("List_Wing"):GetComponent(ClassType.GNewListLoop)
    self._Frame_Right = self._Parent:GetUIObject("Frame_Right_Wing")
    self._Frame_Icon = self._Parent:GetUIObject("Frame_Icon_Wing")
    self._Lab_WingName = self._Parent:GetUIObject("Lab_WingName")
    self._Lab_Quality = self._Parent:GetUIObject("Lab_Quality_Wing")
    self._Lab_Des = self._Parent:GetUIObject("Lab_Des_Wing")
    self._Lab_Level = self._Parent:GetUIObject("Lab_Level")
    self._Lab_Origin = self._Parent:GetUIObject("Lab_Origin_Wing")
    self._Frame_SpecialTips = self._Parent:GetUIObject("Frame_SpecialTips")
    self._Lab_SpecialTips = self._Parent:GetUIObject("Lab_SpecialTips")
    self._Btn_Operate = self._Parent:GetUIObject("Btn_Operate")
    self._Lab_Operate = self._Parent:GetUIObject("Lab_Operate")
    self._Btn_Approach = self._Parent:GetUIObject("Btn_Approach_Wing")
    self:SetWingDropGroup()

    -- 设置下拉菜单层级
    local drop_template = self._Parent:GetUIObject("Drop_Template_Wing")
    GUITools.SetupDropdownTemplate(self._Parent, drop_template)

    self._IsCheckLeft = false
    self._CurQualityIndex = 0

    self:SetWingList()
end

-- 设置数据
def.method().SetWingList = function (self)
    self._WingListAll = {}
    local hp = game._HostPlayer
    if hp == nil then return end
    local allWingInfo = CWingsManIns:GetWingShowList()
    local curWingId = hp:GetCurWingId()
    for _, v in ipairs(allWingInfo) do
        local id = v.Tid
        local listInfo =
        {
            Id = id,
            Quality = v.Template.WingQuality,       -- 品质
            IsDefault = false,                      -- 是否默认
            IsGot = false,                          -- 是否已拥有
            FightScore = 0,                         -- 战力
            Level = 1,                              -- 实际等级
            Grade = 1,                              -- 阶级
            TransLevel = 1,                         -- 阶级下的等级
            ItemId = v.Template.ItemID,             -- 关联物品ID
        }
        listInfo.IsDefault = id == curWingId
        if v.Level > 0 then
            listInfo.IsGot = true
            listInfo.FightScore = v.FightScore
            listInfo.Level = v.Level
            listInfo.Grade, listInfo.TransLevel = CWingsManIns:CalcGradeByLevel(v.Level)
        else
            listInfo.IsGot = false
            listInfo.FightScore = CWingsManIns:GetWingFightScore(id, 1)
        end
        self._WingListAll[#self._WingListAll+1] = listInfo
    end

    local function sortFunc(a, b)
        if a.IsDefault ~= b.IsDefault then
            -- 默认排最前面
            return a.IsDefault
        elseif a.IsGot ~= b.IsGot then
            -- 已获得>未获得
            return a.IsGot
        elseif a.FightScore ~= b.FightScore then
            -- 战力从高到低
            return a.FightScore > b.FightScore
        else
            -- Id从小到大
            return a.Id < b.Id
        end
    end
    table.sort(self._WingListAll, sortFunc)
end


local function SortFunc(x, y)
    if x.FightScore ~= y.FightScore then
        -- 战力从高到低
        return x.FightScore > y.FightScore
    else
        -- Id从小到大
        return x.Id < y.Id
    end
end

-- 获取特定品质的已拥有的翅膀列表
def.method("number", "=>", "table").GetWingListHave = function (self, quality)
    local list_have = {} -- 已拥有列表
    for _, v in pairs(self._WingListAll) do
        if v.IsGot and v.Quality == quality then
            table.insert(list_have, v)
        end
    end
    table.sort(list_have, SortFunc)
    return list_have
end

-- 获取特定品质的未拥有的翅膀列表
def.method("number", "=>", "table").GetWingListDontHave = function (self, quality)
    local list_dont_have = {} -- 未拥有列表
    for _, v in pairs(self._WingListAll) do
        if not v.IsGot and v.Quality == quality then
            table.insert(list_dont_have, v)
        end
    end
    table.sort(list_dont_have, SortFunc)
    return list_dont_have
end

-- 获取红点状态
local function GetRedPointStatus(tid, isChangeStatus)
    local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
    if exteriorMap ~= nil then
        local key = "Wing"
        local redDotStatusMap = exteriorMap[key]
        if redDotStatusMap ~= nil and redDotStatusMap[tid] == true then
            if isChangeStatus then
                redDotStatusMap[tid] = nil

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
    return false
end

-- 获取灰色字体
local function GetGreyColorStr(str)
    return "<color=#909AA8>" .. str .. "</color>"
end

------------------------------以下方法不能删除--------------------------------
def.method("dynamic").Show = function(self, data)
    if #self._WingListAll <= 0 then
        warn("翅膀数据为空")
        return
    end

    if type(data) == "number" then
        self._SelectedWingId = data
    end

    self:SetRedPointCacheMap()
    self:UpdateWingList(self._CurQualityIndex, self._IsCheckLeft)
end

def.method("string", "boolean").OnExteriorToggle = function(self, id, checked)
    if string.find(id, "Chk_AlreadyHave") then
        -- 是否只显示已拥有
        if self._IsCheckLeft == checked then return end
        self._IsCheckLeft = checked
        self:UpdateWingList(self._CurQualityIndex, checked)
    end
end

def.method("string", "number").OnExteriorDropDown = function(self, id, index)
    if string.find(id, "Drop_Group") then
        local qualityIndex = 0
        if index > 0 then
            qualityIndex = self._ListQuality[index] + 1
        end
        if self._CurQualityIndex == qualityIndex then return end
        self._CurQualityIndex = qualityIndex
        self:UpdateWingList(qualityIndex, self._IsCheckLeft)
    end
end

def.method("userdata", "string", "number").OnExteriorInitItem = function(self, item, id, index)
    if id == "List_Wing" then
        -- 翅膀列表
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        if uiTemplate == nil then return end

        local data = self._WingListShow[index+1]
        local template = CWingsManIns:GetWingData(data.Id)
        
        -- 是否已装备
        local img_equip = uiTemplate:GetControl(3)
        GUITools.SetUIActive(img_equip, data.IsDefault)
        -- 是否新翅膀
        local isNew = self._RedPointChangeStatusCacheMap[data.Id] == true
        local img_new = uiTemplate:GetControl(8)
        GUITools.SetUIActive(img_new, isNew)
        self._ImgTable_New[index+1] = img_new

        local img_bg = uiTemplate:GetControl(0) -- 背景
        local lab_quality = uiTemplate:GetControl(1) -- 品质
        local img_icon = uiTemplate:GetControl(2) -- 图标
        local lab_name = uiTemplate:GetControl(5) -- 名称

        GameUtil.MakeImageGray(img_bg, not data.IsGot)
        GUITools.SetUIActive(lab_quality, data.IsGot)
        GUITools.SetItemIcon(img_icon, template.IconPath)
        GameUtil.MakeImageGray(img_icon, not data.IsGot)
        
        local nameStr = RichTextTools.GetQualityText(template.WingName, template.WingQuality)
        if not data.IsGot then
            -- 名字变灰
            nameStr = GetGreyColorStr(template.WingName)
        else
            local qualityStr = StringTable.Get(10000 + template.WingQuality)
            qualityStr = RichTextTools.GetQualityText(qualityStr, template.WingQuality)
            GUI.SetText(lab_quality, qualityStr)
        end
        GUI.SetText(lab_name, nameStr)
    end
end

def.method("userdata", "string", "number").OnExteriorSelectItem = function(self, item, id, index)
    if id == "List_Wing" then
        local data = self._WingListShow[index+1]
        if self._CurWingData ~= nil and self._CurWingData.Id == data.Id then return end

        self._List_Wing:SetSelection(index)

        self:EnableRightInfo(true)
        self:SelectWing(data)

        -- 更新UI红点
        local isNew = self._RedPointChangeStatusCacheMap[data.Id]
        if isNew then
            self._RedPointChangeStatusCacheMap[data.Id] = nil

            local img_new = self._ImgTable_New[index+1]
            if not IsNil(img_new) then
                GUITools.SetUIActive(img_new, false)
            end
        end
    end
end

def.method("string").OnExteriorClick = function(self, id)
    if string.find(id, "Btn_Operate") then
        local curData = self._CurWingData
        if curData == nil then return end

        local curWingId = game._HostPlayer:GetCurWingId()
        if curData.Id == curWingId then
            -- 卸下
            CWingsManIns:C2SWingSelectShow(0)
            self:EnableRightInfo(false)
            self._CurWingData = nil
        else
            -- 穿戴
            CWingsManIns:C2SWingSelectShow(self._CurWingData.Id)
        end
    elseif string.find(id, "Btn_ToDevelop") then
        local CExteriorMan = require "Main.CExteriorMan"
        CExteriorMan.Instance():Quit()

        local data = nil
        if self._CurWingData ~= nil then
            data =
            {
                WingTid = self._CurWingData.Id
            }
        end
        game._GUIMan:Open("CPanelUIWing", data)
    elseif string.find(id, "Btn_Approach_Wing") then
        local curData = self._CurWingData
        if curData == nil then return end

        local data =
        {
            ItemId = curData.ItemId,
            ParentObj = self._Btn_Approach
        }
        game._GUIMan:Open("CPanelItemApproach", data)
    end
end

-- 返回当前外观相机类型
def.method("=>", "number").GetCurCamType = function (self)
    return EnumDef.CamExteriorType.Wing
end

-- 页签内是否有红点显示
def.method("=>", "boolean").IsPageHasRedPoint = function (self)
    -- 是否有未显示的
    local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
    if exteriorMap ~= nil then
        local redDotStatusMap = exteriorMap["Wing"]
        if redDotStatusMap ~= nil then
            for _, status in pairs(redDotStatusMap) do
                -- 有还未显示过的
                return true
            end
        end
    end
    return false
end

def.method().OnChangeFrame = function (self)
end

def.method().Hide = function(self)
    self._RedPointChangeStatusCacheMap = {}
end

def.method().Destroy = function (self)
    self._ListQuality = {}
    self:Hide()
    self._WingListAll = {}
    self._WingListShow = {}
    self._CurWingData = nil
    self._Parent = nil

    self._Panel = nil
    self._Chk_AlreadyHave = nil
    self._Drop_Quality = nil
    self._View_Wing = nil
    self._List_Wing = nil
    self._Frame_Right = nil
    self._Frame_Icon = nil
    self._Lab_WingName = nil
    self._Lab_Quality = nil
    self._Lab_Des = nil
    self._Lab_Level = nil
    self._Lab_Origin = nil
    self._Frame_SpecialTips = nil
    self._Lab_SpecialTips = nil
    self._Btn_Operate = nil
    self._Lab_Operate = nil
    self._Btn_Approach = nil
    self._ImgTable_New = {}
end
----------------------------------------------------------------------------------

------------------------------------左界面（列表） start--------------------------------------
-- 设置下拉菜单
def.method().SetWingDropGroup = function (self)
    local groupStr = StringTable.Get(10010)
    self._ListQuality = {}
    -- 暂时只显示三种品质
    self._ListQuality = 
    {
        2, -- 稀有
        3, -- 史诗
        5, -- 传说
    }

    -- 所有品质
    -- 从PB表转为可以遍历的常规表
    -- for _, v in pairs(EWingQuality) do
    --     if type(v) == "number" then
    --         self._ListQuality[#self._ListQuality+1] = v
    --     end
    -- end
    -- table.sort(self._ListQuality)

    for _, v in ipairs(self._ListQuality) do
        local str = StringTable.Get(10000 + v)
        str = RichTextTools.GetQualityText(str, v)
        groupStr = groupStr .. "," .. str
    end
    GUI.SetDropDownOption(self._Drop_Quality, groupStr)
end

-- 更新翅膀列表
def.method("number", "boolean").UpdateWingList = function (self, qualityIndex, isCheck)
    self._WingListShow = {}
    if qualityIndex == 0 then
        -- 全部品质
        for _, v in ipairs(self._WingListAll) do
            if not isCheck or (isCheck and v.IsGot) then
                self._WingListShow[#self._WingListShow+1] = v
            end
        end
    elseif qualityIndex > 0 then
        local wingList = self:GetWingListHave(qualityIndex-1)
        for _, v in ipairs(wingList) do
            self._WingListShow[#self._WingListShow+1] = v
        end

        if not isCheck then
            -- 没有勾“已拥有”
            wingList = self:GetWingListDontHave(qualityIndex-1)
            for _, v in ipairs(wingList) do
                self._WingListShow[#self._WingListShow+1] = v
            end
        end
    end
    if #self._WingListShow > 0 then
        self._View_Wing:SetActive(true)
        self._List_Wing:SetItemCount(#self._WingListShow)

        local selectWingId = 0
        if self._SelectedWingId > 0 then
            -- 优先选中指定的翅膀
            selectWingId = self._SelectedWingId
            self._SelectedWingId = 0 
        elseif self._CurWingData ~= nil then
            -- 选中已选择的
            selectWingId = self._CurWingData.Id
        else
            -- 选择默认的
            selectWingId = game._HostPlayer:GetCurWingId()
        end
        if selectWingId > 0 then
            for index, data in ipairs(self._WingListShow) do
                if data.Id == selectWingId then
                    self._List_Wing:SetSelection(index - 1)
                    self:SelectWing(data)
                    break
                end
            end
        end
        self:EnableRightInfo(selectWingId > 0)
    else
        self._View_Wing:SetActive(false)
        if self._CurWingData ~= nil then
            -- 当左列表为空，但右边信息存在时
            for _, data in ipairs(self._WingListAll) do
                if data.Id == self._CurWingData.Id then
                    self:SelectWing(data)
                end
            end
        end
    end
end

-- 设置红点状态发生改变的缓存表
def.method().SetRedPointCacheMap = function (self)
    for _, info in ipairs(self._WingListAll) do
        local isNew = GetRedPointStatus(info.Id, true)
        if isNew then
            self._RedPointChangeStatusCacheMap[info.Id] = true
        end
    end
end
------------------------------------左界面（列表）end--------------------------------------

---------------------------------右界面：整体 start-----------------------------------
-- 选中
def.method("table").SelectWing = function (self, data)
    self._CurWingData = data
    self:InitWingRight(data)

    -- 更新模型
    local curPageId = game._HostPlayer:GetCurWingPageId()
    game._HostPlayer:UpdateWingModel(data.Id, data.Level, curPageId)
end

-- 初始化右界面整体
def.method("table").InitWingRight = function (self, curData)
    if curData == nil then return end
    local template = CWingsManIns:GetWingData(curData.Id)
    if template == nil then return end
    -- 图标
    self:SetWingIcon(self._Frame_Icon, curData.Id, false)
    GUI.SetText(self._Lab_WingName, RichTextTools.GetQualityText(template.WingName, template.WingQuality))
    -- GameUtil.SetOutlineColor(EnumDef.Quality2ColorHexStr[template.WingQuality],self._Lab_WingName)
    -- 品质
    local qualityStr = StringTable.Get(10000 + template.WingQuality)
    qualityStr = RichTextTools.GetQualityText(qualityStr, template.WingQuality)
    GUI.SetText(self._Lab_Quality, qualityStr)
    -- 背景
    GUI.SetText(self._Lab_Des, template.DescribText)
    -- 等阶
    local levelStr = ""
    if curData.IsGot then
        levelStr = string.format(StringTable.Get(19529), curData.Grade, curData.TransLevel)
    else
        levelStr = StringTable.Get(19546)
    end
    GUI.SetText(self._Lab_Level, levelStr)
    -- 来源
    GUI.SetText(self._Lab_Origin, template.OriginOfWing)
    -- 特殊说明
    local isShowTips = not curData.IsGot or curData.Grade < template.ShowGrade
    GUITools.SetUIActive(self._Frame_SpecialTips, isShowTips)
    if isShowTips then
        GUI.SetText(self._Lab_SpecialTips, string.format(StringTable.Get(19564), template.ShowGrade))
    end
    -- 按钮状态
    GUITools.SetUIActive(self._Btn_Operate, curData.IsGot)
    GUITools.SetUIActive(self._Btn_Approach, not curData.IsGot)
    -- 按钮文字
    if curData.IsGot then
        -- 是否已装备
        local operateStr = ""
        if curData.IsDefault then
            operateStr = StringTable.Get(19527)
        else
            operateStr = StringTable.Get(19526)
        end
        GUI.SetText(self._Lab_Operate, operateStr)
    end
end

-- 设置翅膀图标
def.method("userdata", "number", "boolean").SetWingIcon = function (self, obj, wingId, enableGrey)
    if IsNil(obj) then return end

    local frame_item_icon = GUITools.GetChild(obj, 3)
    if IsNil(frame_item_icon) then return end
    
    local template = CWingsManIns:GetWingData(wingId)
    if template == nil then return end

    local img_icon = GUITools.GetChild(frame_item_icon, 3)
    if not IsNil(img_icon) then
        GUITools.SetItemIcon(img_icon, template.IconPath)
        GameUtil.MakeImageGray(img_icon, enableGrey)
    end
    local img_quality_bg = GUITools.GetChild(frame_item_icon, 1)
    if not IsNil(img_quality_bg) then
        GUITools.SetUIActive(img_quality_bg, not enableGrey)
        if not enableGrey then
            GUITools.SetGroupImg(img_quality_bg, template.WingQuality)
        end
    end
    local img_quality = GUITools.GetChild(frame_item_icon, 2)
    if not IsNil(img_quality) then
        GUITools.SetUIActive(img_quality, not enableGrey)
        if not enableGrey then
            GUITools.SetGroupImg(img_quality, template.WingQuality)
        end
    end
end

def.method("boolean").EnableRightInfo = function (self, enable)
    GUITools.SetUIActive(self._Frame_Right, enable)
    -- self._Frame_Right:SetActive(enable)
    self._Parent:EnableRightTips(not enable)
end
---------------------------------右界面：整体 end----------------------------------------

-- 翅膀数据更新 from 服务器推送
def.method().UpdateDataFromEvent = function (self)
    if #self._WingListAll <= 0 then
        warn("翅膀数据为空")
        return
    end
    self:SetRedPointCacheMap()
    self:UpdateWingList(self._CurQualityIndex, self._IsCheckLeft)
end

CPageWing.Commit()
return CPageWing