 -- 外观坐骑页
-- 时间：2017/8/25
-- Add by Yao

local Lplus = require "Lplus"
local CPageRide = Lplus.Class("CPageRide")
local def = CPageRide.define

local CElementData = require "Data.CElementData"
local EHorseQuality = require "PB.Template".Horse.EHorseQuality
local EHorseOptType = require "PB.net".EHorseOptType

def.field("table")._Parent = BlankTable
def.field("userdata")._Panel = nil
-- 界面
def.field("userdata")._Chk_AlreadyHave = nil
def.field("userdata")._Drop_Quality = nil
def.field("userdata")._View_Ride = nil
def.field("userdata")._List_Ride = nil
def.field("userdata")._Frame_Right = nil
def.field("userdata")._Frame_Icon = nil
def.field("userdata")._Lab_RideName = nil
def.field("userdata")._Lab_Quality = nil
def.field("userdata")._Lab_Des = nil
def.field("userdata")._Lab_Attri = nil
def.field("userdata")._Lab_Origin = nil
def.field("userdata")._Btn_Approach = nil
def.field("userdata")._Btn_Launch = nil
def.field("userdata")._Lab_Launch = nil
def.field("userdata")._CurListItem = nil
def.field("table")._ImgTable_New = BlankTable

def.field("table")._RideListShow = BlankTable -- 显示的坐骑列表
def.field("boolean")._IsCheck = false -- 是否筛选已拥有
def.field("table")._ListQuality = BlankTable -- 品质列表
def.field("number")._CurQualityIndex = 0 -- 当前品质索引，从1开始，0代表全部
def.field("number")._CurRideId = 0 -- 当前坐骑的ID
def.field("table")._RedPointChangeStatusCacheMap = BlankTable -- 红点状态发生了改变的缓存表
-- 数据
def.field("table")._RideListAll = BlankTable -- 所有坐骑列表
def.field("table")._RideListHave = BlankTable -- 已拥有的坐骑列表，Key为坐骑品质
def.field("table")._RideListNotHave = BlankTable -- 未拥有的坐骑列表，Key为坐骑品质
def.field("boolean")._IsRideRun = false -- 是否在播放坐骑奔跑动画

local instance = nil
def.static("table", "userdata", "=>", CPageRide).new = function(parent, panel)
    instance = CPageRide()
    instance._Parent = parent
    instance._Panel = panel
    instance:Init()
    return instance
end

def.method().Init = function(self)
    self._Chk_AlreadyHave = self._Parent:GetUIObject("Chk_AlreadyHave_Ride"):GetComponent(ClassType.Toggle)
    self._Drop_Quality = self._Parent:GetUIObject("Drop_Group_Ride")
    self._View_Ride = self._Parent:GetUIObject("View_Ride")
    self._List_Ride = self._Parent:GetUIObject("List_Ride"):GetComponent(ClassType.GNewListLoop)
    self._Frame_Right = self._Parent:GetUIObject("Frame_Right_Ride")
    self._Frame_Icon = self._Parent:GetUIObject("Frame_Icon_Ride")
    self._Lab_RideName = self._Parent:GetUIObject("Lab_RideName")
    self._Lab_Quality  = self._Parent:GetUIObject("Lab_Quality_Ride")
    self._Lab_Des = self._Parent:GetUIObject("Lab_Des_Ride")
    self._Lab_Attri = self._Parent:GetUIObject("Lab_Attri_Ride")
    self._Lab_Origin = self._Parent:GetUIObject("Lab_Origin_Ride")
    self._Btn_Approach = self._Parent:GetUIObject("Btn_Approach_Ride")
    self._Btn_Launch = self._Parent:GetUIObject("Btn_Launch")
    self._Lab_Launch = self._Parent:GetUIObject("Lab_Launch")

    -- 设置下拉菜单层级
    local drop_template = self._Parent:GetUIObject("Drop_Template_Ride")
    GUITools.SetupDropdownTemplate(self._Parent, drop_template)

    self:SetRideList()
    self:SetRideDropGroup()

    self._Chk_AlreadyHave.isOn = false
    self._IsCheck = false
    self._CurQualityIndex = 0
end

-- 设置已拥有与未拥有坐骑列表，Key为坐骑品质
def.method().SetRideList = function (self)
    self._RideListHave = {}
    self._RideListNotHave = {}
    self._RideListAll = {}
    local rideIdAll = GameUtil.GetAllTid("Horse")
    if rideIdAll == nil then return end

    local hp = game._HostPlayer
    if hp == nil then 
        warn("CPageRide:HostPlayer is null")
        return 
    end
    local rideIdHas = {}
    for _, id in ipairs(hp:GetHorseList()) do
        rideIdHas[id] = id
    end
    local curHorseId = hp:GetCurrentHorseId()
    for _, id in ipairs(rideIdAll) do
        local template = CElementData.GetTemplate("Horse", id)
        local info =
        {
            Id = id,
            Template = template,
            IsDefault = id == curHorseId,   -- 是否默认坐骑
            Quality = template.Quality,     -- 坐骑品质
            IsGot = false,                  -- 是否已拥有
        }
        if rideIdHas[id] ~= nil then
            -- 已拥有
            local qualityList = self._RideListHave[template.Quality]
            if qualityList == nil then
                qualityList = {}
            end
            info.IsGot = true
            qualityList[#qualityList+1] = info
            self._RideListHave[template.Quality] = qualityList
        else
            -- 未拥有
            local qualityList = self._RideListNotHave[template.Quality]
            if qualityList == nil then
                qualityList = {}
            end
            info.IsGot = false
            qualityList[#qualityList+1] = info
            self._RideListNotHave[template.Quality] = qualityList
        end
        -- 所有
        self._RideListAll[#self._RideListAll+1] = info
    end
    -- 排序
    local function sortFunc1(x, y)
        if x.IsDefault or y.IsDefault then
            -- 默认坐骑排最前面
            return x.IsDefault
        else
            return x.Id < y.Id
        end
    end
    for _, v in pairs(self._RideListHave) do
        table.sort(v, sortFunc1)
    end
    for _, v in pairs(self._RideListNotHave) do
        table.sort(v, sortFunc1)
    end

    local function sortFunc2(a, b)
        if a.IsDefault ~= b.IsDefault then
            -- 默认坐骑排最前面
            return a.IsDefault
        elseif a.IsGot ~= b.IsGot then
            -- 已获得>未获得
            return a.IsGot
        elseif a.Quality ~= b.Quality then
            -- 高品质>低品质
            return a.Quality > b.Quality
        else
            -- Id从小到大
            return a.Id < b.Id
        end
    end
    table.sort(self._RideListAll, sortFunc2)
end

-- 设置下拉菜单
def.method().SetRideDropGroup = function (self)
    local groupStr = StringTable.Get(10010)
    -- 只留高级，史诗，和传说 其他的暂时先屏蔽掉 
    self._ListQuality = 
    {
        2, -- 稀有
        3, -- 史诗
        5, -- 传说
    }

    -- 所有品质
    -- 从PB表转为可以遍历的常规表
    -- for _, v in pairs(EHorseQuality) do
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

-- 获取红点状态
local function GetRedPointStatus(tid, isChangeStatus)
    local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
    if exteriorMap ~= nil then
        local key = "Ride"
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
    if #self._RideListAll <= 0 then
        warn("坐骑列表为空")
        return
    end
    self:SetRedPointCacheMap()
    if self._CurRideId == 0 then
        self._CurRideId = game._HostPlayer:GetCurrentHorseId()
    end
    self:UpdateRideList(self._CurQualityIndex, self._IsCheck)
    self:EnableRightInfo(self._CurRideId > 0)
    if self._CurRideId > 0 then
        game._HostPlayer:Ride(self._CurRideId, true)
    end
end

def.method("string", "boolean").OnExteriorToggle = function(self, id, checked)
    if string.find(id, "Chk_AlreadyHave") then
        -- Checkbox
        if self._IsCheck == checked then return end
        self._IsCheck = checked
        self:UpdateRideList(self._CurQualityIndex, checked)
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
        self:UpdateRideList(qualityIndex, self._IsCheck)
    end
end

def.method("userdata", "string", "number").OnExteriorInitItem = function(self, item, id, index)
    if string.find(id, "List_Ride") then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        if uiTemplate == nil then return end

        local data = self._RideListShow[index+1]
        local template = data.Template
        -- 图标
        local img_icon = uiTemplate:GetControl(2)
        GUITools.SetItemIcon(img_icon, template.IconPath)
        -- 是否已装备
        local img_equip = uiTemplate:GetControl(3)        
        GUITools.SetUIActive(img_equip, data.IsDefault)
        -- 是否新坐骑
        local isNew = self._RedPointChangeStatusCacheMap[data.Id] == true
        local img_new = uiTemplate:GetControl(8)
        GUITools.SetUIActive(img_new, isNew)
        self._ImgTable_New[index+1] = img_new

        -- 字体变灰
        local function GetGreyColorStr(str)
            return "<color=#909AA8>" .. str .. "</color>"
        end

        local img_bg = uiTemplate:GetControl(0) -- 背景图
        local lab_quality = uiTemplate:GetControl(1) -- 品质
        local lab_name = uiTemplate:GetControl(5) -- 名称
        local lab_attri_val = uiTemplate:GetControl(6) -- 属性值
        local lab_attri = uiTemplate:GetControl(7) -- 属性名

        GameUtil.MakeImageGray(img_bg, not data.IsGot)
        GameUtil.MakeImageGray(img_icon, not data.IsGot)

        local nameStr = RichTextTools.GetQualityText(template.Name, template.Quality)
        local qualityStr = StringTable.Get(10000 + template.Quality)
        local attriValStr = template.AddSpeedRatio * 100 .. "%"
        local attriStr = StringTable.Get(15507)
        if not data.IsGot then
            -- 未获得
            nameStr = GetGreyColorStr(template.Name)
            qualityStr = GetGreyColorStr(qualityStr)
            attriValStr = GetGreyColorStr(attriValStr)
            attriStr = GetGreyColorStr(attriStr)
        else
            qualityStr = RichTextTools.GetQualityText(qualityStr, template.Quality)
        end
        GUI.SetText(lab_name, nameStr)
        GUI.SetText(lab_quality, qualityStr)
        GUI.SetText(lab_attri_val, attriValStr)
        GUI.SetText(lab_attri, attriStr)
    end
end

def.method("userdata", "string", "number").OnExteriorSelectItem = function(self, item, id, index)
    if string.find(id, "List_Ride") then
        local data = self._RideListShow[index+1]
        if self._CurRideId == data.Id then return end

        self._List_Ride:SetSelection(index)
        
        self._CurRideId = data.Id
        self:SelectRide(data)

        -- 更新UI红点
        local isNew = self._RedPointChangeStatusCacheMap[data.Id]
        if isNew then
            self._RedPointChangeStatusCacheMap[data.Id] = nil

            local img_new = self._ImgTable_New[index+1]
            if not IsNil(img_new) then
                GUITools.SetUIActive(img_new, false)
            end
        end

        local hp = game._HostPlayer
        hp:Ride(data.Id, true)
        -- 调整镜头
        local CExteriorMan = require "Main.CExteriorMan"
        CExteriorMan.ChangeCamParams(EnumDef.CamExteriorType.Ride, data.Id)
    end
end

def.method("string").OnExteriorClick = function(self, id)
    if string.find(id, "Btn_Launch") then
        -- 直接上马
        if self._CurRideId > 0 then
            local isDefualt = self._CurRideId == game._HostPlayer:GetCurrentHorseId()
            if not isDefualt then
                -- 设为默认坐骑
                SendHorseSetProtocol(self._CurRideId, false)
                -- 上马
                SendHorseSetProtocol(-1, true)
            else
                -- 下马
                SendHorseSetProtocol(-1, false)
                -- 清空默认坐骑
                SendHorseSetProtocol(0, false)
                self:EnableRightInfo(false)
                self._CurRideId = 0 
            end
        end
    elseif string.find(id, "Btn_Approach_Ride") then
        local template = CElementData.GetTemplate("Horse", self._CurRideId)
        if template == nil then return end
        
        local data = 
        {
            ApproachIDs = template.ApproachIDs,
            ParentObj = self._Frame_Right
        }
        game._GUIMan:Open("CPanelItemApproach", data)
    elseif string.find(id, "Btn_ChangeRideAnim") then
        self:ChangeRideAnimation()
    end
end

def.method().ChangeRideAnimation = function (self)
    local hp = game._HostPlayer
    local mountModel = hp._MountModel
    if hp:IsOnRide() and mountModel ~= nil and not mountModel:IsPlaying(EnumDef.CLIP.BORN) then
        -- 已上马，且不是在播放出生动画中
        local comp = hp:GetHorseStandBehaviourComp()
        if self._IsRideRun then
            -- 停止奔跑
            hp:PlayMountAnimation(EnumDef.CLIP.COMMON_STAND, EnumDef.SkillFadeTime.HostOther, false, 0, 1)
            hp:PlaySpecialMountStandSound(EnumDef.SkillFadeTime.HostOther)
            local animation = hp:GetRideStandAnimationName()
            hp:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, false, 0, 1)
            if comp ~= nil then
                comp:StartIdle()
            end
        else
            hp:PlayMountAnimation(EnumDef.CLIP.COMMON_RUN, EnumDef.SkillFadeTime.HostOther, false, 0, 1)
            hp:PlaySpecialMountMoveSound(0)
            local animation = hp:GetRideRunAnimationName()
            hp:PlayAnimation(animation, EnumDef.SkillFadeTime.HostOther, false, 0, 1)
            if comp ~= nil then
                comp:StopIdle()
            end
        end
        self._IsRideRun = not self._IsRideRun
    end
end

-- 返回当前外观相机类型
def.method("=>", "number").GetCurCamType = function (self)
    return EnumDef.CamExteriorType.Ride
end

-- 页签内是否有红点显示
def.method("=>", "boolean").IsPageHasRedPoint = function (self)
    -- 是否有未显示的
    local exteriorMap = CRedDotMan.GetModuleDataToUserData(RedDotSystemType.Exterior)
    if exteriorMap ~= nil then
        local redDotStatusMap = exteriorMap["Ride"]
        if redDotStatusMap ~= nil then
            for _, status in pairs(redDotStatusMap) do
                -- 有还未显示过的
                return true
            end
        end
    end
    return false
end

-- 返回当前选中的坐骑ID
def.method("=>", "number").GetSelectedHorseId = function (self)
    return self._CurRideId
end

def.method().OnChangeFrame = function (self)
    game._HostPlayer:UnRide()
end

def.method().Hide = function(self)
    self._RedPointChangeStatusCacheMap = {}
    self._IsRideRun = false
end

def.method().Destroy = function (self)
    self._Chk_AlreadyHave = nil
    self._Drop_Quality = nil
    self._View_Ride = nil
    self._List_Ride = nil
    self._Frame_Right = nil
    self._Frame_Icon = nil
    self._Lab_RideName = nil
    self._Lab_Quality = nil
    self._Lab_Des = nil
    self._Lab_Attri = nil
    self._Lab_Origin = nil
    self._Btn_Approach = nil
    self._Btn_Launch = nil
    self._Lab_Launch = nil
    self._CurListItem = nil
    self._ImgTable_New = {}

    self._RideListAll = {}
    self._RideListHave = {}
    self._RideListNotHave = {}
    self._ListQuality = {}
    -- self:Hide()
    instance = nil
end
----------------------------------------------------------------------------------

-- 设置红点状态发生改变的缓存表
def.method().SetRedPointCacheMap = function (self)
    for _, info in ipairs(self._RideListAll) do
        local isNew = GetRedPointStatus(info.Id, true)
        if isNew then
            self._RedPointChangeStatusCacheMap[info.Id] = true
        end
    end
end

-- 更新坐骑列表
def.method("number", "boolean").UpdateRideList = function (self, qualityIndex, isCheck)
    self._RideListShow = {}
    if qualityIndex == 0 then
        -- 全部品质
        for i, v in ipairs(self._RideListAll) do
            if not isCheck or (isCheck and v.IsGot) then
                self._RideListShow[#self._RideListShow+1] = v
            end
        end
    elseif qualityIndex > 0 then
        local qualityList = self._RideListHave[qualityIndex-1]
        if qualityList ~= nil then
            for _, v in ipairs(qualityList) do
                self._RideListShow[#self._RideListShow+1] = v
            end
        end

        if not isCheck then
            -- 没有勾“已拥有”
            qualityList = self._RideListNotHave[qualityIndex-1]
            if qualityList ~= nil then
                for _, v in ipairs(qualityList) do
                    self._RideListShow[#self._RideListShow+1] = v
                end
            end
        end
    end
    if #self._RideListShow > 0 then
        self._View_Ride:SetActive(true)
        self._List_Ride:SetItemCount(#self._RideListShow)

        for index, data in ipairs(self._RideListShow) do
            if self._CurRideId == data.Id then
                self:SelectRide(data)
                self._List_Ride:SetSelection(index - 1)
                break
            end
        end
    else
        self._View_Ride:SetActive(false)
        if self._CurRideId > 0 then
            -- 当左列表为空，但右边信息存在时
            for _, data in ipairs(self._RideListAll) do
                if data.Id == self._CurRideId then
                    self:SelectRide(data)
                end
            end
        end
    end
end

-- 选中坐骑
def.method("table").SelectRide = function (self, data)
    self:EnableRightInfo(true)
    self:SetRideInfo(data)
    self._IsRideRun = false
end

-- 设置坐骑信息
def.method("table").SetRideInfo = function (self, data)
    if data == nil then return end
    local template = data.Template
    -- 图标
    self:SetRideIcon(self._Frame_Icon, data, false)
    -- 名称
    GUI.SetText(self._Lab_RideName, RichTextTools.GetQualityText(template.Name, template.Quality))
    -- GameUtil.SetOutlineColor(EnumDef.Quality2ColorHexStr[template.Quality], self._Lab_RideName)
    -- 品质
    local qualityStr = StringTable.Get(10000 + template.Quality)
    qualityStr = RichTextTools.GetQualityText(qualityStr, template.Quality)
    GUI.SetText(self._Lab_Quality, qualityStr)
    -- 介绍
    GUI.SetText(self._Lab_Des, template.Description)
    -- 属性
    GUI.SetText(self._Lab_Attri, template.AddSpeedRatio * 100 .. "%")
    -- 来源
    if not IsNilOrEmptyString(template.Origin) then
        GUI.SetText(self._Lab_Origin, template.Origin)
    end
    GUITools.SetUIActive(self._Btn_Approach, not data.IsGot)
    GUITools.SetUIActive(self._Btn_Launch, data.IsGot)
    if data.IsGot then
        -- 已拥有
        local btnStr = data.IsDefault and StringTable.Get(19527) or StringTable.Get(22102)
        GUI.SetText(self._Lab_Launch, btnStr)
    end
end

-- 设置坐骑图标
def.method("userdata", "table", "boolean").SetRideIcon = function (self, obj, data, isList)
    if IsNil(obj) or data == nil then return end

    local frame_item_icon = GUITools.GetChild(obj, 3)
    if IsNil(frame_item_icon) then return end

    local template = data.Template

    local img_icon = GUITools.GetChild(frame_item_icon, 3)
    if not IsNil(img_icon) then
        GUITools.SetItemIcon(img_icon, template.IconPath)
        if isList then
            GameUtil.MakeImageGray(img_icon, not data.IsGot)
        end
    end
    local img_quality_bg = GUITools.GetChild(frame_item_icon, 1)
    if not IsNil(img_quality_bg) then
        GUITools.SetGroupImg(img_quality_bg, template.Quality)
        if isList then
            GUITools.SetUIActive(img_quality_bg, data.IsGot)
        end
    end
    local img_quality = GUITools.GetChild(frame_item_icon, 2)
    if not IsNil(img_quality) then
        GUITools.SetGroupImg(img_quality, template.Quality)
        if isList then
            GUITools.SetUIActive(img_quality, data.IsGot)
        end
    end
end

-- 推送导致更新列表
def.method().UpdateDataFromEvent = function (self)
    self:SetRedPointCacheMap()
    self:UpdateRideList(self._CurQualityIndex, self._IsCheck)
end

def.method("boolean").EnableRightInfo = function (self, enable)
    GUITools.SetUIActive(self._Frame_Right, enable)
    self._Parent:EnableRightTips(not enable)
end

CPageRide.Commit()
return CPageRide