-- 飞翼养成升级页
-- 2018/7/20

local Lplus = require "Lplus"
local CPageWingDevelop = Lplus.Class("CPageWingDevelop")
local CGame = Lplus.ForwardDeclare("CGame")
local def = CPageWingDevelop.define

local CElementData = require "Data.CElementData"
local CWingsManIns = require "Wings.CWingsMan".Instance()
local EWingQuality = require "PB.Template".Wing.EWingQuality
local CUIModel = require "GUI.CUIModel"
local CCommonBtn = require "GUI.CCommonBtn"

def.field("table")._Root = nil
-- 界面
def.field("userdata")._Drop_Quality = nil
def.field("userdata")._View_Wing = nil
def.field("userdata")._List_Wing = nil
def.field("userdata")._Img_WingModel = nil
def.field("userdata")._Frame_Right = nil
def.field("userdata")._Lab_FightScore = nil
def.field("userdata")._Lab_WingLevel = nil
def.field("userdata")._Frame_WingExp = nil
def.field("userdata")._Lab_WingExpValue = nil
def.field("userdata")._Lab_WingExpMax = nil
def.field("userdata")._Sld_WingExp = nil
def.field("userdata")._Frame_WingAttri = nil
def.field("userdata")._List_WingAttri = nil
def.field("userdata")._TweenMan_WingAttri = nil
def.field("userdata")._Img_WingAttriArrow = nil
def.field("userdata")._Frame_Origin = nil
def.field("userdata")._Lab_Origin = nil
def.field("userdata")._Btn_Approach = nil
def.field("userdata")._Frame_Operate = nil
def.field("userdata")._Frame_LevelUp = nil
def.field("userdata")._Frame_MaterialIcon = nil
def.field(CCommonBtn)._Btn_Develop = nil
def.field("userdata")._Lab_Operate = nil
def.field("userdata")._Lab_Unlock = nil
def.field("userdata")._Frame_AddPoint = nil
def.field("userdata")._Lab_AddPoint = nil
def.field("userdata")._Frame_MaxLevel = nil
def.field("userdata")._Frame_GradeUp = nil
def.field("userdata")._Frame_WingIcon = nil
def.field("userdata")._Lab_WingName = nil
def.field("userdata")._Lab_PreLevel = nil
def.field("userdata")._Lab_NextLevel = nil
def.field("userdata")._Frame_WingAttri_GradeUp = nil
def.field("userdata")._List_WingAttri_GradeUp = nil
def.field("userdata")._TweenMan_GradeUp = nil
def.field("userdata")._TweenMan_GradeUp_Attri = nil
def.field("userdata")._Frame_UnlockTips = nil
def.field("userdata")._Btn_Next = nil

def.field("table")._ImgTable_RedPoint = BlankTable
-- 缓存
def.field(CUIModel)._UIModel = nil
def.field("boolean")._IsCheckLeft = false -- 是否筛选已拥有
def.field("table")._ListQuality = BlankTable -- 品质列表
def.field("number")._CurQualityIndex = 0 -- 当前品质索引，从1开始，0代表全部
def.field("table")._WingListShow = BlankTable -- 展示列表
def.field("number")._SelectedWingId = 0 -- 指定的翅膀ID
def.field("table")._CurWingData = nil -- 当前翅膀数据
def.field("table")._CurWingData_Old = nil -- 当前翅膀的前一级数据（进阶展示界面用）
def.field("number")._GradeUpItem_ID = 0 -- 进阶道具ID
def.field("table")._RedPointChangeStatusCacheMap = BlankTable -- 红点状态发生了改变的缓存表
def.field("table")._WingListAll = BlankTable -- 所有翅膀列表
def.field("table")._UIFxDataList = BlankTable -- 特效信息列表
def.field("table")._UIFxTimerList = BlankTable -- 特效计时器列表

local LEVEL_UP_MONEY_ID = 1 -- 灌注/进阶消耗的货币ID，写死金币
local ColorHexStr =
{
    White = "<color=#FFFFFF>%s</color>",
    Grey = "<color=#909AA8>%s</color>",
    Blue = "<color=#2FD7E5>%s</color>",
    Green = "<color=#97E03B>%s</color>"
}

def.static("table", "=>", CPageWingDevelop).new = function(root)
    local obj = CPageWingDevelop()
    obj._Root = root
    obj:Init()
    return obj
end

def.method().Init = function(self)
    self._Drop_Quality = self._Root:GetUIObject("DropDown_Down")
    self._View_Wing = self._Root:GetUIObject("View_Wing")
    self._List_Wing = self._Root:GetUIObject("List_Wing"):GetComponent(ClassType.GNewListLoop)
    self._Img_WingModel = self._Root:GetUIObject("Img_Role_1")
    self._Frame_Right = self._Root:GetUIObject("Frame_MidR_Develop")
    self._Lab_FightScore = self._Root:GetUIObject("Lab_FightScore")
    self._Lab_WingLevel = self._Root:GetUIObject("Lab_WingLevel")
    self._Frame_WingExp = self._Root:GetUIObject("Frame_WingExp")
    self._Lab_WingExpValue = self._Root:GetUIObject("Lab_WingExpValue")
    self._Lab_WingExpMax = self._Root:GetUIObject("Lab_WingExpMax")
    self._Sld_WingExp = self._Root:GetUIObject("Sld_WingExp"):GetComponent(ClassType.Slider)
    self._Frame_WingAttri = self._Root:GetUIObject("Frame_WingAttri")
    local list_attri_go_1 = self._Root:GetUIObject("List_WingAttri")
    self._List_WingAttri = list_attri_go_1:GetComponent(ClassType.GNewList)
    self._TweenMan_WingAttri = list_attri_go_1:GetComponent(ClassType.DOTweenPlayer)
    self._Img_WingAttriArrow = self._Root:GetUIObject("Img_AttriArrow")
    self._Frame_Origin = self._Root:GetUIObject("Frame_Origin")
    self._Lab_Origin = self._Root:GetUIObject("Lab_Origin")
    self._Btn_Approach = self._Root:GetUIObject("Btn_Approach")
    self._Frame_Operate = self._Root:GetUIObject("Frame_Operate")
    self._Frame_LevelUp = self._Root:GetUIObject("Frame_LevelUp")
    self._Frame_MaterialIcon = self._Root:GetUIObject("Frame_MaterialIcon")
    self._Lab_Operate = self._Root:GetUIObject("Lab_Operate")
    self._Lab_Unlock = self._Root:GetUIObject("Lab_Unlock")
    self._Frame_AddPoint = self._Root:GetUIObject("Frame_AddPoint")
    self._Lab_AddPoint = self._Root:GetUIObject("Lab_AddPoint")
    self._Frame_MaxLevel = self._Root:GetUIObject("Frame_MaxLevel")
    self._Frame_GradeUp = self._Root:GetUIObject("Frame_GradeUp")
    self._Frame_WingIcon = self._Root:GetUIObject("Frame_WingIcon")
    self._Lab_WingName = self._Root:GetUIObject("Lab_WingName")
    self._Lab_PreLevel = self._Root:GetUIObject("Lab_PreLevel")
    self._Lab_NextLevel = self._Root:GetUIObject("Lab_NextLevel")
    self._Frame_WingAttri_GradeUp = self._Root:GetUIObject("Frame_WingAttri_GradeUp")
    local list_attri_go_2 = self._Root:GetUIObject("List_WingAttri_GradeUp")
    self._List_WingAttri_GradeUp = list_attri_go_2:GetComponent(ClassType.GNewList)
    self._TweenMan_GradeUp = self._Frame_GradeUp:GetComponent(ClassType.DOTweenPlayer)
    self._TweenMan_GradeUp_Attri = list_attri_go_2:GetComponent(ClassType.DOTweenPlayer)
    self._Frame_UnlockTips = self._Root:GetUIObject("Frame_UnlockTips")
    self._Btn_Next = self._Root:GetUIObject("Btn_Next")
    self:SetWingDropGroup()

    local setting = {
        [EnumDef.CommonBtnParam.MoneyID] = LEVEL_UP_MONEY_ID
    }
    self._Btn_Develop = CCommonBtn.new(self._Root:GetUIObject("Btn_Develop"), setting)

    GUITools.SetUIActive(self._Frame_GradeUp, false)
    self._Frame_GradeUp:SetActive(true)

    -- 设置下拉菜单层级
    local drop_template = self._Root:GetUIObject("Drop_Template")
    GUITools.SetupDropdownTemplate(self._Root, drop_template)

    -- 道具ID读特殊ID表
    local CSpecialIdMan = require "Data.CSpecialIdMan"
    self._GradeUpItem_ID = CSpecialIdMan.Get("WingGradeUpItem")

    self:SetWingList()

    -- 初始化特效信息列表
    self._UIFxDataList =
    {
        [1] =
        {
            Delay = 0.5,
            Path = PATH.ETC_Fortify_Success_BG1,
            Root = self._Frame_WingIcon
        },
        [2] =
        {
            Delay = 0.7,
            Path = PATH.UIFX_DEV_Recast_Inc,
            Root = self._Root:GetUIObject("Img_GradeUpTitle")
        },
    }
    for i=1, #self._UIFxDataList do
        self._UIFxTimerList[i] = 0
    end
end

---------------------------初始化数据 start---------------------------
local function SortFunc(a, b)
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
            Quality = v.Template.WingQuality,   -- 品质
            IsDefault = false,                  -- 是否默认
            IsGot = false,                      -- 是否已拥有
            FightScore = 0,                     -- 战力
            Level = 1,                          -- 实际等级
            CanGradeUp = false,                 -- 能否进阶
            IsMaxLv = false,                    -- 是否达到最大等级
            GradeNum = 0,                       -- 进阶需要消耗的材料数量
            PerfusionItemId = 0,                -- 灌注道具ID
            PerfusionNum = 0,                   -- 灌注需要消耗的材料数量
        }
        listInfo.IsDefault = id == curWingId
        if v.Level > 0 then
            listInfo.IsGot = true
            listInfo.FightScore = v.FightScore
            listInfo.Level = v.Level

            local lvUpTemplate = CWingsManIns:GetWingLevelUpInfo(id, v.Level)
            if lvUpTemplate ~= nil then
                if lvUpTemplate.GradeID > 0 then
                    listInfo.CanGradeUp = true
                    local gradeUpTemplate = CWingsManIns:GetWingGradeUpData(lvUpTemplate.GradeID)
                    if gradeUpTemplate ~= nil then
                        listInfo.GradeNum = gradeUpTemplate.CostItemNum
                    end
                end
                listInfo.PerfusionItemId = lvUpTemplate.NeedItemTID
                listInfo.PerfusionNum = lvUpTemplate.NeedItemNum
            end
            local nextAttri = CWingsManIns:GetWingLevelUpData(id, v.Level+1)
            listInfo.IsMaxLv = next(nextAttri) == nil
        end
        self._WingListAll[#self._WingListAll+1] = listInfo
    end
    table.sort(self._WingListAll, SortFunc)
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
----------------------------初始化数据 end----------------------------
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

    GameUtil.PlayUISfx(PATH.UI_bj_effect, self._Root._Panel, self._Root._Panel, -1)
    self:UpdateUIModel()
end

def.method("string", "boolean").OnToggle = function(self, id, checked)
    if string.find(id, "Chk_AlreadyHave") then
        -- 是否只显示已拥有
        if self._IsCheckLeft == checked then return end
        self._IsCheckLeft = checked
        self:UpdateWingList(self._CurQualityIndex, checked)
    end
end

def.method("string", "number").OnDropDown = function(self, id, index)
    if string.find(id, "DropDown_Down") then
        local qualityIndex = 0
        if index > 0 then
            qualityIndex = self._ListQuality[index] + 1
        end
        if self._CurQualityIndex == qualityIndex then return end
        self._CurQualityIndex = qualityIndex
        self:UpdateWingList(qualityIndex, self._IsCheckLeft)
    end
end

def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "List_Wing" then
        -- 翅膀列表
        self:OnInitWingList(item, index)
    elseif id == "List_WingAttri" then
        -- 翅膀属性
        self:OnInitWingAttriList(item, index)
    elseif id == "List_WingAttri_GradeUp" then
        -- 进阶界面的翅膀属性
        self:OnInitWingAttriGradeUpList(item, index)
    end
end

def.method("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "List_Wing" then
        self:OnSelectWingList(item, index)
    end
end

def.method("string").OnClick = function(self, id)
    if string.find(id, "Btn_ToExterior") then
        local CExteriorMan = require "Main.CExteriorMan"
        if CExteriorMan.Instance():CanEnter() then
            local data = {}
            data.Type = EnumDef.CamExteriorType.Wing
            local curData = self._CurWingData
            if curData ~= nil then
                data.UIData = curData.C_Id
            end
            -- 必须先设置数据，再关闭界面
            -- game._GUIMan:Close("CPanelUIWing")
            CExteriorMan.Instance():Enter(data)
        end
    elseif string.find(id, "Btn_Develop") then
        local curData = self._CurWingData
        if curData == nil then return end

        if curData.C_CanGradeUp then
            self:TryGradeUp(curData.C_Id, curData.C_PerfusionItemId, curData.C_GradeNum, curData.C_MoenyCost)
        else
            self:TryPerfusion(curData.C_Id, curData.C_PerfusionItemId, curData.C_PerfusionNum, curData.C_MoenyCost)
        end
    elseif string.find(id, "Btn_Attribute") then
        -- 所有已拥有的翅膀的加成属性
        game._GUIMan:Open("CPanelUIExteriorAttributeCheck", { Type = 1 })
    elseif string.find(id, "Btn_Material") then
        -- 弹材料Tips
        local curData = self._CurWingData
        if curData == nil then return end

        local materialItemId = curData.C_PerfusionItemId
        -- if curData.C_CanGradeUp then
        --     materialItemId = self._GradeUpItem_ID
        -- else
        --     materialItemId = curData.C_PerfusionItemId
        -- end
        CItemTipMan.ShowItemTips(materialItemId, TipsPopFrom.OTHER_PANEL, self._Frame_MaterialIcon, TipPosition.FIX_POSITION)
    elseif string.find(id, "Btn_Next") then
        -- 关闭进阶成功界面
        GUITools.SetUIActive(self._Frame_GradeUp, false)
    elseif string.find(id, "Btn_Approach") then
        local curData = self._CurWingData
        if curData == nil then return end

        local data = 
        {
            ItemId = curData.C_ItemId,
            ParentObj = self._Btn_Approach
        }
        game._GUIMan:Open("CPanelItemApproach", data)
    elseif string.find(id, "Btn_Operate") then
        local curData = self._CurWingData
        if curData == nil then return end

        local curWingId = game._HostPlayer:GetCurWingId()
        if curData.C_Id == curWingId then
            -- 卸下
            CWingsManIns:C2SWingSelectShow(0)
            game._GUIMan:ShowTipText(StringTable.Get(19554), false)
        else
            -- 穿戴
            CWingsManIns:C2SWingSelectShow(curData.C_Id)
            game._GUIMan:ShowTipText(StringTable.Get(19553), false)
        end
    end
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
                if status then
                    return true
                end
            end
        end
    end
    -- 是否有可进阶的
    if next(self._WingListAll) ~= nil then
        for _, data in ipairs(self._WingListAll) do
            if self:IsShowRedPoint(data) then
                return true
            end
        end
    end

    return false
end

-- 背包物品更新
def.method().OnPackageChangeEvent = function (self)
    -- self:UpdateListRedPoint()
    self:UpdateMaterialNum()
end

def.method().Hide = function(self)
    self._RedPointChangeStatusCacheMap = {}
end

def.method("string", "string").OnDOTComplete = function(self, go_name, dot_id)
    if dot_id == "GradeUp" then
        GUITools.SetUIActive(self._Btn_Next, true)
    end
end

def.method().Destroy = function (self)
    self._ListQuality = {}
    self:Hide()
    self._WingListAll = {}
    self._WingListShow = {}
    self._CurWingData = nil
    self._CurWingData_Old = nil
    self._Root = nil

    if self._UIModel ~= nil then
        self._UIModel:Destroy()
        self._UIModel = nil
    end
    if self._Btn_Develop ~= nil then
        self._Btn_Develop:Destroy()
        self._Btn_Develop = nil
    end

    self._Drop_Quality = nil
    self._View_Wing = nil
    self._List_Wing = nil
    self._Img_WingModel = nil
    self._Frame_Right = nil
    self._Lab_FightScore = nil
    self._Lab_WingLevel = nil
    self._Frame_WingExp = nil
    self._Lab_WingExpValue = nil
    self._Lab_WingExpMax = nil
    self._Sld_WingExp = nil
    self._Frame_WingAttri = nil
    self._List_WingAttri = nil
    self._Img_WingAttriArrow = nil
    self._Frame_Origin = nil
    self._Lab_Origin = nil
    self._Btn_Approach = nil
    self._Frame_Operate = nil
    self._Frame_LevelUp = nil
    self._Frame_MaterialIcon = nil
    self._Lab_Operate = nil
    self._Lab_Unlock= nil
    self._Frame_AddPoint = nil
    self._Lab_AddPoint = nil
    self._Frame_MaxLevel = nil
    self._Frame_GradeUp = nil
    self._Frame_WingIcon = nil
    self._Lab_WingName = nil
    self._Lab_PreLevel = nil
    self._Lab_NextLevel = nil
    self._Frame_WingAttri_GradeUp = nil
    self._List_WingAttri_GradeUp = nil
    self._TweenMan_GradeUp = nil
    self._TweenMan_GradeUp_Attri= nil
    self._Frame_UnlockTips = nil
    self._Btn_Next = nil
    self._ImgTable_RedPoint = {}
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
    -- GameUtil.AdjustDropdownRect(self._Drop_Quality, #self._ListQuality+1)
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
        self._ImgTable_RedPoint = {}
        self._List_Wing:SetItemCount(#self._WingListShow)

        local selectWingId = 0
        if self._SelectedWingId > 0 then
            -- 优先选中指定的翅膀
            selectWingId = self._SelectedWingId
            self._SelectedWingId = 0 
        elseif self._CurWingData ~= nil then
            -- 选中已选择的
            selectWingId = self._CurWingData.C_Id
        else
            -- 选择第一个
            selectWingId = self._WingListShow[1].Id
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
        self._Frame_Right:SetActive(selectWingId > 0)
    else
        self._View_Wing:SetActive(false)
        if self._CurWingData ~= nil then
            -- 当左列表为空，但右边信息存在时
            for _, data in ipairs(self._WingListAll) do
                if data.Id == self._CurWingData.C_Id then
                    self:SelectWing(data)
                end
            end
        else
            self._Frame_Right:SetActive(false)
        end
    end
end

-- 初始化翅膀列表
def.method("userdata", "number").OnInitWingList = function(self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if uiTemplate == nil then return end

    local data = self._WingListShow[index+1]
    local template = CWingsManIns:GetWingData(data.Id)
    -- 图标
    local frame_icon = uiTemplate:GetControl(0)
    self:SetWingIcon(frame_icon, data.Id, not data.IsGot)
    -- 是否已装备
    local img_equip = uiTemplate:GetControl(3)
    GUITools.SetUIActive(img_equip, data.IsDefault)
    -- 红点
    local img_red_point = uiTemplate:GetControl(8)
    GUITools.SetUIActive(img_red_point, self:IsShowRedPoint(data))
    self._ImgTable_RedPoint[index+1] = img_red_point
    -- 是否新翅膀
    local isNew = self._RedPointChangeStatusCacheMap[data.Id] == true
    local img_new = uiTemplate:GetControl(9)
    GUITools.SetUIActive(img_new, isNew)

    local lab_name = uiTemplate:GetControl(5) -- 名称
    local lab_attri = uiTemplate:GetControl(6) -- 属性名
    local lab_attri_val = uiTemplate:GetControl(7) -- 属性值
    lab_attri:SetActive(data.IsGot)

    local nameStr = RichTextTools.GetQualityText(template.WingName, template.WingQuality)
    if not data.IsGot then
        -- 名字变灰
        nameStr = string.format(ColorHexStr.Grey, template.WingName)
    else
        GUI.SetText(lab_attri_val, GUITools.FormatNumber(data.FightScore, false, 7))
    end
    GUI.SetText(lab_name, nameStr)
end

-- 选中翅膀列表
def.method("userdata", "number").OnSelectWingList = function(self, item, index)
    local data = self._WingListShow[index+1]
    if self._CurWingData ~= nil and self._CurWingData.C_Id == data.Id then return end

    self._List_Wing:SetSelection(index)

    self._Frame_Right:SetActive(true)
    self:SelectWing(data)

    -- 更新UI红点
    local isNew = self._RedPointChangeStatusCacheMap[data.Id]
    if isNew then
        self._RedPointChangeStatusCacheMap[data.Id] = nil

        local img_new = GUITools.GetChild(item, 9)
        if not IsNil(img_new) then
            GUITools.SetUIActive(img_new, false)
        end
    end
    self:UpdateUIModel()
end

-- 左列表是否显示红点
def.method("table", "=>", "boolean").IsShowRedPoint = function (self, list_data)
    if list_data == nil then return false end
    if not list_data.IsGot then return false end
    if list_data.IsMaxLv then return false end

    if list_data.CanGradeUp then
        -- 进阶
        return self:IsMaterialNumEnough(list_data.PerfusionItemId, list_data.GradeNum)
    else
        -- 灌注
        return self:IsMaterialNumEnough(list_data.PerfusionItemId, list_data.PerfusionNum)
    end
end

-- 更新列表红点
def.method().UpdateListRedPoint = function (self)
    if next(self._WingListShow) == nil then return end

    for index, data in ipairs(self._WingListShow) do
        local img_red_point = self._ImgTable_RedPoint[index]
        if not IsNil(img_red_point) then
            GUITools.SetUIActive(img_red_point, self:IsShowRedPoint(data))
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
    -- 更新系统菜单红点
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.WingDevelop, CWingsManIns:IsShowRedPoint())
end
------------------------------------左界面（列表）end--------------------------------------

-- 更新UI模型
def.method().UpdateUIModel = function (self)
    local curData = self._CurWingData
    if curData == nil then return end

    local model_asset_path = curData.C_AssetPath
    if self._UIModel == nil then 
        self._UIModel = CUIModel.new(model_asset_path, self._Img_WingModel, EnumDef.UIModelShowType.All, EnumDef.RenderLayer.UI,
            function() end)    --no animation
    else
        self._UIModel:Update(model_asset_path)
    end
    self._UIModel:AddLoadedCallback(function()
        self._UIModel:SetModelParam(self._Root._PrefabPath, model_asset_path)
        self._UIModel:PlayAnimation(EnumDef.CLIP.WING_COMMON_STAND)
    end)
end

---------------------------------右界面：整体 start-----------------------------------
-- 选中
def.method("table").SelectWing = function (self, data)
    self:InitCurWingData(data.Id) -- 设置数据

    self:InitWingRight(self._CurWingData)
end

-- 初始化当前选中的翅膀数据
def.method("number").InitCurWingData = function (self, wingId)
    self._CurWingData = nil
    if wingId <= 0 then return end
    local wingTemplate = CWingsManIns:GetWingData(wingId)
    if wingTemplate == nil then return end
    local curWingId = game._HostPlayer:GetCurWingId()
    local info = 
    {
        C_Id = wingId,
        C_IsDefault = curWingId == wingId,          -- 是否穿戴上
        C_IsGot = false,                            -- 是否已拥有
        C_Name = wingTemplate.WingName,             -- 翅膀名字
        C_Origin = wingTemplate.OriginOfWing,       -- 来源文本
        C_ShowGrade = wingTemplate.ShowGrade,       -- 显示天赋页翅膀模型的阶级
        C_AssetPath = "",                           -- 模型路径
        C_PerfusionItemId = 0,                      -- 灌注道具Id
        C_PerfusionNum = 0,                         -- 灌注道具所需数量
        C_GradeNum = 0,                             -- 进阶道具所需数量
        C_MoenyCost = 0,                            -- 灌注/进阶所需货币数量
        C_AddWingPoint = 0,                         -- 下一阶级增加的魔晶点数
        C_Level = 1,                                -- 实际等级
        C_CanGradeUp = false,                       -- 能否进阶
        C_Attri = {},                               -- 当前等级属性
        C_NextAttri = {},                           -- 下一等级属性（满级为空表）
        C_ItemId = wingTemplate.ItemID,             -- 关联物品ID
        C_FightScore = 0,                           -- 战力
    }

    local serverInfo = CWingsManIns:GetServerData(wingId)
    if serverInfo ~= nil then
        -- 已拥有
        info.C_IsGot = true
        info.C_Level = serverInfo.Level
        info.C_FightScore = serverInfo.FightScore
        info.C_NextAttri = CWingsManIns:GetWingLevelUpData(info.C_Id, info.C_Level+1)
    else
        info.C_FightScore = CWingsManIns:GetWingFightScore(info.C_Id, 1) -- 一级的战力
    end
    local lvUpTemplate = CWingsManIns:GetWingLevelUpInfo(info.C_Id, info.C_Level)
    if lvUpTemplate ~= nil then
        if lvUpTemplate.GradeID > 0 then
            info.C_CanGradeUp = true
            local grade_template = CWingsManIns:GetWingGradeUpData(lvUpTemplate.GradeID)
            if grade_template ~= nil then
                info.C_GradeNum = grade_template.CostItemNum
                info.C_AddWingPoint = grade_template.TalentPoint
            end
        end
        info.C_PerfusionItemId = lvUpTemplate.NeedItemTID
        info.C_PerfusionNum = lvUpTemplate.NeedItemNum
        info.C_MoenyCost = lvUpTemplate.CostMoneyNum
    end
    info.C_Attri = CWingsManIns:GetWingLevelUpData(info.C_Id, info.C_Level)
    local Util = require "Utility.Util"
    local curPageId = game._HostPlayer:GetCurWingPageId()
    info.C_AssetPath = Util.GetWingAssetPath(info.C_Id, info.C_Level, curPageId)

    self._CurWingData = info
end

-- 初始化右界面整体
def.method("table").InitWingRight = function (self, data)
    if data == nil then return end
    -- 属性列表
    self:UpdateAttriList(#data.C_Attri)
    -- 战力
    GUI.SetText(self._Lab_FightScore, GUITools.FormatNumber(data.C_FightScore, false, 7))
    -- 等级
    local curGrade, curTransLv = CWingsManIns:CalcGradeByLevel(data.C_Level)
    GUI.SetText(self._Lab_WingLevel, string.format(StringTable.Get(19529), curGrade, curTransLv))

    if self._Frame_WingExp.activeSelf ~= data.C_IsGot then
        self._Frame_WingExp:SetActive(data.C_IsGot)
    end
    GUITools.SetUIActive(self._Frame_Origin, not data.C_IsGot)
    GUITools.SetUIActive(self._Frame_Operate, data.C_IsGot)
    GUITools.SetUIActive(self._Img_WingAttriArrow, data.C_IsGot)
    if not data.C_IsGot then
        self:ShowOriginInfo(data)
    else
        -- 经验
        self:ShowOperateInfo(data)
    end
    -- 天赋展现等级提示
    GUI.SetText(self._Lab_Unlock, string.format(StringTable.Get(19563), data.C_ShowGrade))
    GUITools.SetUIActive(self._Lab_Unlock, not data.C_IsGot or curGrade < data.C_ShowGrade)
end

-- 更新属性列表
def.method("number").UpdateAttriList = function (self, length)
    if length > 0 then
        GUITools.SetUIActive(self._Frame_WingAttri, true)
        self._List_WingAttri:SetItemCount(length)
    else
        GUITools.SetUIActive(self._Frame_WingAttri, false)
    end
end

-- 初始化翅膀属性列表
def.method("userdata", "number").OnInitWingAttriList = function(self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if uiTemplate == nil then return end

    local curData = self._CurWingData
    if curData == nil then return end

    local lab_attri_title = uiTemplate:GetControl(0) -- 属性名
    local lab_attri_1 = uiTemplate:GetControl(1)     -- 属性值1(左)
    local lab_attri_2 = uiTemplate:GetControl(3)     -- 属性值2(右)
    local img_arrow_2 = uiTemplate:GetControl(4)     -- 箭头2(右)
    GUITools.SetUIActive(lab_attri_1, curData.C_IsGot)

    local isMaxLv = next(curData.C_NextAttri) == nil -- 是否最大级
    if index < #curData.C_Attri then
        -- 属性
        local attri = curData.C_Attri[index+1]
        local attri_temp = CElementData.GetAttachedPropertyTemplate(attri.key)
        if attri_temp == nil then return end

        local isShowAttri2 = true
        local isShowArrow2 = false
        local dataStr = GUITools.FormatNumber(attri.data, false, 7)
        GUI.SetText(lab_attri_title, attri_temp.TextDisplayName)
        if curData.C_IsGot then
            -- 已获得
            GUI.SetText(lab_attri_1, dataStr)
            if isMaxLv then
                GUI.SetText(lab_attri_2, "Max")
            else
                local next_attri = curData.C_NextAttri[index+1]
                if next_attri ~= nil and next_attri.data > attri.data then
                    -- 只显示增加的属性
                    local nextDataStr = GUITools.FormatNumber(next_attri.data, false, 7)
                    local valStr = nextDataStr
                    GUI.SetText(lab_attri_2, valStr)
                    isShowArrow2 = true
                else
                    isShowAttri2 = false
                end
            end
        else
            GUI.SetText(lab_attri_2, string.format(ColorHexStr.White, dataStr))
        end
        GUITools.SetUIActive(lab_attri_2, isShowAttri2)
        GUITools.SetUIActive(img_arrow_2, isShowArrow2)
    end
end

-- 设置翅膀图标
def.method("userdata", "number", "boolean").SetWingIcon = function (self, obj, wingId, enableGrey)
    if IsNil(obj) then return end

    local frame_icon = GUITools.GetChild(obj, 3)
    if IsNil(frame_icon) then return end

    local template = CWingsManIns:GetWingData(wingId)
    if template == nil then return end

    local img_icon = GUITools.GetChild(frame_icon, 3)
    if not IsNil(img_icon) then
        GUITools.SetItemIcon(img_icon, template.IconPath)
        GameUtil.MakeImageGray(img_icon, enableGrey)
    end
    local img_quality_bg = GUITools.GetChild(frame_icon, 1)
    if not IsNil(img_quality_bg) then
        GameUtil.MakeImageGray(img_quality_bg, enableGrey)
        if not enableGrey then
            GUITools.SetGroupImg(img_quality_bg, template.WingQuality)
        end
    end
    local img_quality = GUITools.GetChild(frame_icon, 2)
    if not IsNil(img_quality) then
        GameUtil.MakeImageGray(img_quality, enableGrey)
        if not enableGrey then
            GUITools.SetGroupImg(img_quality, template.WingQuality)
        end
    end
end
---------------------------------右界面：整体 end----------------------------------------

---------------------------------右界面：内部 start----------------------------------------
-- 展示来源信息
def.method("table").ShowOriginInfo = function (self, data)
    if data == nil then return end
    -- 来源
    GUI.SetText(self._Lab_Origin, data.C_Origin)
end

-- 展示操作信息
def.method("table").ShowOperateInfo = function (self, data)
    if data == nil then return end

    local isMaxLv = next(data.C_NextAttri) == nil
    GUITools.SetUIActive(self._Frame_MaxLevel, isMaxLv)
    GUITools.SetUIActive(self._Frame_LevelUp, not isMaxLv)
    self._Btn_Develop:SetActive(not isMaxLv)
    if not isMaxLv then
        -- 未满级
        local _, curTransLv = CWingsManIns:CalcGradeByLevel(data.C_Level)
        local maxLevelInGrade = CWingsManIns:GetMaxLevelInGrade()
        self._Sld_WingExp.value = curTransLv / maxLevelInGrade
        local isMaxInGrade = curTransLv == maxLevelInGrade -- 是否是单阶内最大等级
        GUITools.SetUIActive(self._Lab_WingExpValue, not isMaxInGrade)
        GUITools.SetUIActive(self._Lab_WingExpMax, isMaxInGrade)
        if isMaxInGrade then
            GUI.SetText(self._Lab_WingExpMax, StringTable.Get(19510))
        else
            GUI.SetText(self._Lab_WingExpValue, string.format(ColorHexStr.Green, tostring(curTransLv)) .. " / " .. maxLevelInGrade)
        end 
        GUITools.SetUIActive(self._Frame_AddPoint, data.C_CanGradeUp)
        local isEnough = false
        local developStr = ""
        if data.C_CanGradeUp then
            -- 进阶
            IconTools.InitMaterialIconNew(self._Frame_MaterialIcon, data.C_PerfusionItemId, data.C_GradeNum)
            GUI.SetText(self._Lab_AddPoint, "+" .. data.C_AddWingPoint)
            developStr = StringTable.Get(19533)
            isEnough = self:IsMaterialNumEnough(data.C_PerfusionItemId, data.C_GradeNum)
        else
            -- 灌注
            IconTools.InitMaterialIconNew(self._Frame_MaterialIcon, data.C_PerfusionItemId, data.C_PerfusionNum)
            developStr = StringTable.Get(158)
            isEnough = self:IsMaterialNumEnough(data.C_PerfusionItemId, data.C_PerfusionNum)
        end
        local setting = {
            [EnumDef.CommonBtnParam.MoneyID] = LEVEL_UP_MONEY_ID,
            [EnumDef.CommonBtnParam.MoneyCost] = data.C_MoenyCost,
            [EnumDef.CommonBtnParam.BtnTip] = developStr,
        }
        self._Btn_Develop:ResetSetting(setting)
        self._Btn_Develop:MakeGray(not isEnough)
    else
        GUITools.SetUIActive(self._Frame_AddPoint, false)
        self._Sld_WingExp.value = 1
        GUITools.SetUIActive(self._Lab_WingExpValue, false)
        GUITools.SetUIActive(self._Lab_WingExpMax, true)
        GUI.SetText(self._Lab_WingExpMax, "Max")
    end

    -- 是否已装备
    local operateStr = ""
    if data.C_IsDefault then
        operateStr = StringTable.Get(19527)
    else
        operateStr = StringTable.Get(19526)
    end
    GUI.SetText(self._Lab_Operate, operateStr)
end

-- 更新材料数量
def.method().UpdateMaterialNum = function (self)
    local data = self._CurWingData
    if data == nil then return end
    if next(data.C_NextAttri) == nil then return end -- 已满级

    local itemId = data.C_PerfusionItemId -- 道具ID
    local needNum = 0 -- 所需道具道具
    if data.C_CanGradeUp then
        -- 进阶
        -- itemId = self._GradeUpItem_ID
        needNum = data.C_GradeNum
    else
        -- 灌注
        -- itemId = data.C_PerfusionItemId
        needNum = data.C_PerfusionNum
    end
    IconTools.InitMaterialIconNew(self._Frame_MaterialIcon, itemId, needNum)
    self._Btn_Develop:MakeGray(not self:IsMaterialNumEnough(itemId, needNum))
end
---------------------------------右界面：内部 end----------------------------------------

---------------------------------进阶成功界面 start--------------------------------------
-- 显示进阶成功界面
def.method().ShowGradeUp = function (self)
    local curData = self._CurWingData_Old
    if curData == nil then return end

    GUITools.SetUIActive(self._Btn_Next, false)
    GUITools.SetUIActive(self._Frame_GradeUp, true)
    -- 图标
    self:SetWingIcon(self._Frame_WingIcon, curData.C_Id, false)
    -- 名字
    GUI.SetText(self._Lab_WingName, curData.C_Name)
    -- 升级前等级
    local preGrade, preTransLv = CWingsManIns:CalcGradeByLevel(curData.C_Level)
    local preLvStr = string.format(StringTable.Get(19562), preGrade, preTransLv)
    GUI.SetText(self._Lab_PreLevel, preLvStr)
    -- 升级后等级
    local nextGrade, nextTransLv = CWingsManIns:CalcGradeByLevel(curData.C_Level + 1)
    local nextLvStr = string.format(StringTable.Get(19562), nextGrade, nextTransLv)
    GUI.SetText(self._Lab_NextLevel, nextLvStr)
    -- 属性列表
    local attriNum = #curData.C_Attri
    if attriNum > 0 then
        GUITools.SetUIActive(self._Frame_WingAttri_GradeUp, true)
        self._List_WingAttri_GradeUp:SetItemCount(attriNum)
    else
        GUITools.SetUIActive(self._Frame_WingAttri_GradeUp, false)
    end
    -- 解锁天赋外观提示
    GUITools.SetUIActive(self._Frame_UnlockTips, curData.C_ShowGrade == nextGrade and nextTransLv == 1)
    self:StartGradeUpEffect()
end

def.method().StartGradeUpEffect = function (self)
    self._TweenMan_GradeUp:Restart("GradeUp")
    self._TweenMan_GradeUp_Attri:FindAndDoRestart("GradeUp")

    GameUtil.PlayUISfx(PATH.ETC_Fortify_Success_BG2, self._Frame_GradeUp, self._Frame_GradeUp, -1)
    self:RemoveGradeUpFxTimers()
    for i, fxData in ipairs(self._UIFxDataList) do
        self._UIFxTimerList[i] = _G.AddGlobalTimer(fxData.Delay, true, function()
            GameUtil.PlayUISfx(fxData.Path, fxData.Root, fxData.Root, -1)
        end)
    end
end

def.method().RemoveGradeUpFxTimers = function (self)
    local length = #self._UIFxTimerList
    for i=1, length do
        local timer = self._UIFxTimerList[i]
        if timer > 0 then
            _G.RemoveGlobalTimer(timer)
            self._UIFxTimerList[i] = 0
        end
    end
end

-- 初始化进阶成功的翅膀属性列表
def.method("userdata", "number").OnInitWingAttriGradeUpList = function (self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    if uiTemplate == nil then return end

    local curData = self._CurWingData_Old
    if curData == nil then return end

    local attri = curData.C_Attri[index+1]
    -- 属性名字
    local attri_temp = CElementData.GetAttachedPropertyTemplate(attri.key)
    if attri_temp ~= nil then
        local lab_attri_title = uiTemplate:GetControl(0)
        GUI.SetText(lab_attri_title, attri_temp.TextDisplayName)
    end
    -- 进阶前属性
    local lab_attri_1 = uiTemplate:GetControl(1)
    GUI.SetText(lab_attri_1, GUITools.FormatNumber(attri.data, false, 7))
    -- 进阶后属性
    local next_attri = curData.C_NextAttri[index+1]
    local lab_attri_2 = uiTemplate:GetControl(3)
    GUI.SetText(lab_attri_2, GUITools.FormatNumber(next_attri.data, false, 7))
end
---------------------------------进阶成功界面 end----------------------------------------
-- 材料是否充足
def.method("number", "number", "=>", "boolean").IsMaterialNumEnough = function (self, itemId, needNum)
    if itemId <= 0 then return false end
    local hasNum = game._HostPlayer._Package._NormalPack:GetItemCount(itemId)
    if needNum > hasNum then
        return false
    end
    return true
end

-- 尝试灌注
def.method("number", "number", "number", "number").TryPerfusion = function (self, wingId, itemId, needNum, moneyCost)
    if wingId <= 0 then return end

    if not self:IsMaterialNumEnough(itemId, needNum) then
        -- 灌注材料不足
        game._GUIMan:ShowTipText(StringTable.Get(19542), false)
        return
    end
    MsgBox.ShowQuickBuyBox(LEVEL_UP_MONEY_ID, moneyCost, function(ret)
            if not ret then return end
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_WingLevelUp, 0)
            GameUtil.PlayUISfx(PATH.UIFX_xiaosan, self._Frame_MaterialIcon, self._Frame_MaterialIcon, -1)
            CWingsManIns:C2SWingLevelUp(wingId, false, false)
        end)
end

-- 尝试进阶
def.method("number", "number", "number", "number").TryGradeUp = function (self, wingId, itemId, needNum, moneyCost)
    if wingId <= 0 then return end

    if not self:IsMaterialNumEnough(itemId, needNum) then
        -- 进阶材料不足
        game._GUIMan:ShowTipText(StringTable.Get(19542), false)
        return
    end
    MsgBox.ShowQuickBuyBox(LEVEL_UP_MONEY_ID, moneyCost, function(ret)
            if not ret then return end
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_WingGradeUp, 0)
            GameUtil.PlayUISfx(PATH.UIFX_xiaosan, self._Frame_MaterialIcon, self._Frame_MaterialIcon, -1)
            CWingsManIns:C2SWingGradeUp(wingId)
        end)
end

-- 翅膀数据更新 from 服务器推送
-- @param changeType 0:添加翅膀 1:装备翅膀 2:翅膀升级 3:翅膀进阶
def.method("number").UpdateDataFromEvent = function (self, changeType)
    if #self._WingListAll <= 0 then
        warn("翅膀数据为空")
        return
    end
    self._CurWingData_Old = self._CurWingData
    self:SetRedPointCacheMap()
    self:UpdateWingList(self._CurQualityIndex, self._IsCheckLeft)
    if changeType == 3 then
        -- 进阶
        self:ShowGradeUp()
        self:UpdateUIModel()
    end
    -- 升级/升阶动特效
    if changeType == 2 or changeType == 3 then
        GameUtil.PlayUISfx(PATH.UIFX_WingModelLvUp, self._Img_WingModel, self._Img_WingModel, -1)
        local sld_go = self._Sld_WingExp.gameObject
        GameUtil.PlayUISfx(PATH.UIFX_ExpLvUp, sld_go, sld_go, -1)
        self._TweenMan_WingAttri:FindAndDoRestart("shanshuo")
    end
end

CPageWingDevelop.Commit()
return CPageWingDevelop