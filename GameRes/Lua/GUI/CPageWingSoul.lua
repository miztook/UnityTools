-- 飞翼养成秘晶页
-- 2018/7/20

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPageWingSoul = Lplus.Class("CPageWingSoul")
local def = CPageWingSoul.define

local CWingsMan = require "Wings.CWingsMan"
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local EResourceType = require "PB.data".EResourceType
local CElementSkill     = require "Data.CElementSkill"

def.field("table")._Root = nil
def.field("userdata")._Frame_Soul_C = nil
def.field("userdata")._Frame_Soul_L = nil
def.field("userdata")._Frame_Soul_R = nil

-- 界面
def.field("userdata")._Btn_Reset = nil
def.field("userdata")._Lab_PageDesc = nil
def.field("userdata")._Lab_PointNum = nil
def.field("userdata")._Lab_Title = nil
def.field("userdata")._Lab_Number = nil
def.field("userdata")._Lab_SkillDesc = nil
def.field("userdata")._FrameDes = nil
def.field("userdata")._Lab_LevelNumber = nil
def.field("userdata")._Lab_OpenLimit = nil
def.field("userdata")._Sel_SoulIcon = nil
def.field("userdata")._Btn_PointUp = nil
def.field("userdata")._Btn_PointDown = nil
def.field("userdata")._Btn_Use = nil
def.field("userdata")._Lab_Use = nil
def.field("userdata")._Btn_Save = nil
def.field("userdata")._Btn_CloseHint = nil
def.field("userdata")._CurSelectItem = nil -- 当前选中的天赋GameObject
def.field("userdata")._FrameAdjust = nil
def.field("userdata")._FramePoint = nil
def.field("userdata")._LabMaxDes = nil
-- 数据
def.field("number")._ResetCostNum = 0 -- 重置消耗的货币数量
def.field("number")._Cur_Talent_Page = -1
def.field("number")._TalentId = -1
def.field("number")._CurAddNum = 0
def.field("number")._MaxAddNum = 0
def.field("number")._Soul_Icon_Sel = 1
def.field("table")._PageUnlockTable = BlankTable
def.field("table")._PageTempAddPointTable = BlankTable

local TALENT_SKILL_NUM = 9 -- 单页天赋的技能数量
local ALL_TALENT_PAGE_NUM = 3 -- 天赋页总量
local RESET_MONEY_ID = 3 -- 重置消耗的货币ID，写死红钻
local COLOR_RED_HEX = "<color=#F70000>%s</color>" -- 红色

def.static("table", "=>", CPageWingSoul).new = function(root)
	local obj = CPageWingSoul()
	obj._Root = root
	obj:Init()
	return obj 
end

def.method().Init = function(self)
    self._Frame_Soul_C = self._Root:GetUIObject("Frame_Soul_C")
    self._Frame_Soul_L = self._Root:GetUIObject("Frame_Soul_L")
    self._Frame_Soul_R = self._Root:GetUIObject("Frame_SoulInfo")

	self._Btn_Reset = self._Root:GetUIObject("Btn_Reset")
    self._Lab_PageDesc = self._Root:GetUIObject("Lab_Desc_Page")
    self._Lab_PointNum = self._Root:GetUIObject("Lab_PointNum")
    self._FramePoint = self._Lab_PointNum.parent
    self._LabMaxDes = self._FramePoint.parent:FindChild("Lab_Max_Des")
	self._Lab_Title = self._Root:GetUIObject("Lab_Name_Soul")
	self._Lab_Number = self._Root:GetUIObject("Lab_Number_Soul")
	self._Lab_LevelNumber = self._Root:GetUIObject("Lab_Level_Soul")
    self._Lab_SkillDesc = self._Root:GetUIObject("Lab_Desc_Soul")
    self._FrameDes = self._Lab_SkillDesc.parent:FindChild("Frame_Des")
    GUI.SetText(self._FrameDes:FindChild("Lab_Prof_Des"), StringTable.Get(112))
	self._Lab_OpenLimit = self._Root:GetUIObject("LabOpen_Limit")
	self._Sel_SoulIcon = self._Root:GetUIObject("Img_CurIcon")
	self._Btn_PointUp = self._Root:GetUIObject("Btn_PointUp")
    self._Btn_PointDown = self._Root:GetUIObject("Btn_PointDown")
    self._FrameAdjust = self._Btn_PointDown.parent
	self._Btn_Use = self._Root:GetUIObject("Btn_Use")
	self._Lab_Use = self._Root:GetUIObject("Lab_Use")
    self._Btn_Save = self._Root:GetUIObject("Btn_Save")
	self._Btn_CloseHint = self._Root:GetUIObject("Btn_CloseSoulHint")
    self._Btn_CloseHint:SetActive(false)
    local frame_gift_1 = self._Root:GetUIObject("Frame_Gift1")
    local img_new = GUITools.GetChild(frame_gift_1, 4)
    if not IsNil(img_new) then
        GUITools.SetUIActive(img_new, false) -- 第一个不会出现New
    end

    -- 重置消耗货币数量读特殊ID表
    local CSpecialIdMan = require "Data.CSpecialIdMan"
    self._ResetCostNum = CSpecialIdMan.Get("WingClearProf")
end

-- 打开是否放弃临时修改的弹窗
local function OpenGiveUpTempMsg(callback)
    local title, msg, closeType = StringTable.GetMsg(43)
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, function(ret)
        callback(ret)
    end)
end

----------------------- 以下方法不能删除---------------------
def.method("dynamic").Show = function (self, data)
	CWingsMan.Instance():ResetTempTalentListData()

    self._Frame_Soul_C:SetActive(true)
    self._Frame_Soul_L:SetActive(true)
    self._Frame_Soul_R:SetActive(true)

    self:OpenSoulPanel()
    self._Root:UpdateTabRedDotState()
end

def.method("string").OnClick = function (self, id)
    if id == "Btn_Save" then
        if not CWingsMan.Instance():WingSoulChanged(self._Cur_Talent_Page) then
            -- 没有修改的点
            game._GUIMan:ShowTipText(StringTable.Get(19559), false)
        else
            -- 保存有临时加点的天赋
            self._PageTempAddPointTable = {}
            local talent_data = CWingsMan.Instance():GetTalentListData()
            local talent_lvl_data = talent_data[self._Cur_Talent_Page].WingTalents
            local talent_temp_data = CWingsMan.Instance():GetTempTalentListData()
            local talent_temp_lvl_data = talent_temp_data[self._Cur_Talent_Page].WingTalents
            if talent_lvl_data ~= nil and talent_temp_lvl_data ~= nil then    
                for i = 1, #talent_lvl_data do
                    if talent_lvl_data[i].AddPoint < talent_temp_lvl_data[i].AddPoint then
                        self._PageTempAddPointTable[talent_lvl_data[i].WingTalentID] = true
                    end
                end
            end

            CWingsMan.Instance():C2SWingTalentAddPoint(self._Cur_Talent_Page)
        end
    elseif id == "Btn_Reset" then
        --[[if CWingsMan.Instance():WingSoulChanged(self._Cur_Talent_Page) then
            -- 有新加点的重置确认弹窗
            local function callback(ret)
                if ret then
                    -- 重置所有未保存的加点
                    self:RefreshToggleByIndex(self._Cur_Talent_Page)
                end
            end
            local title, msg, closeType = StringTable.GetMsg(105)
            MsgBox.ShowMsgBox(msg, title, closeType, bit.bor(MsgBoxType.MBBT_OKCANCEL, MsgBoxType.MBT_NOTSHOW),callback,nil,nil,nil,nil,"CPanelUIWing_1")
        else --]]if CWingsMan.Instance():SoulDataAdded(self._Cur_Talent_Page) then
            -- 没有新加点的重置确认弹窗
            local function callback(ret1)
                if ret1 then
                    MsgBox.ShowQuickBuyBox(RESET_MONEY_ID, self._ResetCostNum, function(ret2)
                        if not ret2 then return end
                        CWingsMan.Instance():C2SWingTalentWashPoint(self._Cur_Talent_Page)
                    end)
                end
            end
            local title, msg, closeType = StringTable.GetMsg(78)
            local setting = {
                -- [MsgBoxAddParam.NotShowTag] = "CPanelUIWing_2",
                [MsgBoxAddParam.CostMoneyID] = RESET_MONEY_ID,
                [MsgBoxAddParam.CostMoneyCount] = self._ResetCostNum,
            }
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback,nil,nil,nil,setting)
        else
            -- 没有天赋加点
            game._GUIMan:ShowTipText(StringTable.Get(19560), false)
        end
    elseif id == "Btn_Use" then
        local curPageId = game._HostPlayer:GetCurWingPageId()
        if self:ReviewTalentCheckState(curPageId) then
            -- 已启用
            game._GUIMan:ShowTipText(StringTable.Get(19558), false)
            return
        end
        if game._HostPlayer:IsInServerCombatState() then
            -- 战斗中不能启用
            game._GUIMan:ShowTipText(StringTable.Get(19565), false)
            return
        end

        CWingsMan.Instance():C2SWingTalentSelect(self._Cur_Talent_Page)
    elseif string.find(id, "Btn_Icon") then
        -- 天赋图标按钮
        local index = tonumber(string.sub(id, -1))
        if index == nil then return end

        self:TalentSkillClickCallBack(index)
    elseif id == "Btn_PointUp" then
        self:AddTalentPoint()
    elseif id == "Btn_PointDown" then
        self:MinusTalentPoint()
    elseif id == "Btn_PointHint" then
    	-- 打开秘晶点提示
    	self._Btn_CloseHint:SetActive(true)
    elseif id == "Btn_CloseSoulHint" then
    	-- 关闭秘晶点提示
    	self._Btn_CloseHint:SetActive(false)
    end
end

def.method("string", "boolean").OnToggle = function(self, id, checked)
    if string.find(id, "Rdo_List") and checked then
        local index = tonumber(string.sub(id, string.len("Rdo_List")+1, -1))
        if index == nil or self._Cur_Talent_Page == index then return end

        if CWingsMan.Instance():WingSoulChanged(self._Cur_Talent_Page) then
            OpenGiveUpTempMsg(function(state)
                if state then
                    self:RefreshToggleByIndex(index)
                else
                    self._Root:GetUIObject("Rdo_List" .. self._Cur_Talent_Page):GetComponent(ClassType.Toggle).isOn = true
                end
            end)
        else
            self:RefreshToggleByIndex(index)
        end
        self._Soul_Icon_Sel = 1
    end
end

-- 尝试隐藏界面，若成功回调参数未 true， 反则 false
def.method("function").TryHidePage = function (self, callback)
	if CWingsMan.Instance():WingSoulChanged(self._Cur_Talent_Page) then
		OpenGiveUpTempMsg(callback)
	else
		callback(true)
	end
end

-- 页签内是否有红点显示
def.method("=>", "boolean").IsPageHasRedPoint = function (self)
    return CWingsMan.Instance():IsTalentHasRedPoint()
end

def.method().Hide = function (self)
    self._Frame_Soul_C:SetActive(false)
    self._Frame_Soul_L:SetActive(false)
    self._Frame_Soul_R:SetActive(false)
end

def.method().Destroy = function (self)
    self._Lab_PointNum = nil
    self._Cur_Talent_Page = -1
    self._Lab_Title = nil
    self._TalentId = -1
    self._CurAddNum = 0
    self._MaxAddNum = 0
    self._Soul_Icon_Sel = 1
    self._Lab_Number = nil
    self._Lab_SkillDesc = nil
    self._FrameDes = nil
    self._Lab_LevelNumber = nil
    self._Lab_OpenLimit = nil
    self._Sel_SoulIcon = nil
    self._CurSelectItem = nil
	self._Btn_PointUp = nil
	self._Btn_PointDown = nil
    self._Btn_Use = nil
    self._Lab_Use = nil
    self._Btn_Save = nil
    self._Btn_Reset = nil
    self._Btn_CloseHint = nil
    self._Lab_PageDesc = nil

    self._Frame_Soul_C = nil
    self._Frame_Soul_L = nil
    self._Frame_Soul_R = nil
end
-------------------------------------------------------------

-- 天赋技能check
def.method("boolean").SetTalentCheckBox = function(self, state)
    GUITools.SetBtnGray(self._Btn_Use, state)
    local str = state and StringTable.Get(19528) or StringTable.Get(19543)
    GUI.SetText(self._Lab_Use, str)

    self:RefreshSelectTag(game._HostPlayer:GetCurWingPageId())
end

-- 天赋技能icon点击反馈
def.method("number").TalentSkillClickCallBack = function(self, index)
    -- 这里用临时数据做模拟
    local data =  CWingsMan.Instance():GetTempTalentListData()
    if not data then
        warn("error occor in TalentSkillClickCallBack !")
        return
    end

    local talent_data 
    for i = 1, #data[self._Cur_Talent_Page].WingTalents do 
        local id = data[self._Cur_Talent_Page].WingTalents[i].WingTalentID
        local wing_talent_data = CWingsMan.Instance():GetTalentLevelTemplate(id)
        if wing_talent_data.SequenceNum == index then
            talent_data = data[self._Cur_Talent_Page].WingTalents[i]
            break
        end
    end

    if talent_data then
        local function EnableImgSelect(item, enable)
            if IsNil(item) then return end
            local img_select_1 = GUITools.GetChild(item, 0)
            GUITools.SetUIActive(img_select_1, enable)
        end
        EnableImgSelect(self._CurSelectItem, false)

        local wing_talent_data = CWingsMan.Instance():GetTalentLevelTemplate(talent_data.WingTalentID)
        if wing_talent_data then
            local skill_icon = self._Root:GetUIObject("Frame_Gift" .. index)
            self._CurSelectItem = skill_icon
            -- 选中状态
            EnableImgSelect(skill_icon, true)
            -- 技能名称
            GUI.SetText(self._Lab_Title, tostring(wing_talent_data.Name))
            self._TalentId = wing_talent_data.Id
            -- 当前加点
            self._CurAddNum = talent_data.AddPoint
            GUI.SetText(self._Lab_Number, tostring(self._CurAddNum))
            -- 最大等级
            local pre_limit_list = wing_talent_data.TalentPreLimits
            local max_level = pre_limit_list[#pre_limit_list].MaxLevel
            self._MaxAddNum = max_level
            GUI.SetText(self._Lab_LevelNumber, self._CurAddNum.."/"..self._MaxAddNum)
            -- 技能描述
            local descStr = DynamicText.ParseSkillDescText(wing_talent_data.TalentID, self._CurAddNum, true)
            GUI.SetText(self._Lab_SkillDesc, descStr)

            local makeShow = function(parsedText, val)
                local tag = "talentlevelup1%%"
                local isFloat = string.find(parsedText, tag)
                if isFloat then
                    val = val * 100
                end
                val = math.abs(val)
                local replStr = fmtVal2Str(tonumber(fmtVal2Str(val)))
                if isFloat then
                    replStr = string.format("%s%%", replStr)
                end
                return replStr
            end

            -- 图片icon设置
            local skill_data = CElementData.GetTemplate("Talent", wing_talent_data.TalentID)
            if skill_data then
                GUITools.SetItemIcon(self._Sel_SoulIcon, skill_data.Icon)
            end
            -- 限制条件
            local isMaxLv = talent_data.AddPoint == max_level
            local isShowLimit = false
            local canPointUp = CWingsMan.Instance():CheckTalentPointUp(talent_data.WingTalentID, self._Cur_Talent_Page, false)
            if not isMaxLv then
                local description = ""
                -- 找到当前等级的限制描述
                for _, limit_data in ipairs(pre_limit_list) do
                    if talent_data.AddPoint < limit_data.MaxLevel then
                        description = limit_data.UnlockDescribe
                        break
                    end
                end
                if not IsNilOrEmptyString(description) then
                    isShowLimit = not canPointUp
                    if not canPointUp then
                        -- 只有当无法加点时才显示限制
                        GUI.SetText(self._Lab_OpenLimit, description)
                    end
                end
            end
            GUITools.SetUIActive(self._Lab_OpenLimit, isShowLimit)

            -- 更新加减点按钮状态
            local hasLeftPoint = CWingsMan.Instance():CheckTempPointLeft(self._Cur_Talent_Page)
            local enableBtnUp = canPointUp and hasLeftPoint
            GUITools.SetBtnGray(self._Btn_PointUp, not enableBtnUp, true)
            local enableBtnDown = CWingsMan.Instance():CheckTalentPointDown(talent_data.WingTalentID, self._Cur_Talent_Page, false)
            GUITools.SetBtnGray(self._Btn_PointDown, not enableBtnDown, true)

            local showMax = CWingsMan.Instance():GetStaticAddPoint(self._Cur_Talent_Page, talent_data.WingTalentID) >= max_level
            self._FrameDes:SetActive(true)
            -- if enableBtnUp then
            do
                -- 升级数值预览
                local talentID = wing_talent_data.TalentID
                local valuenow = CElementSkill.GetTalentLevelUpValue(talentID, 1, self._CurAddNum)
                local valuenext = CElementSkill.GetTalentLevelUpValue(talentID, 1, self._CurAddNum + 1)
                local parsedText = DynamicText.GetSkillDesc(talentID, true)
                valuenow = makeShow(parsedText, valuenow)
                valuenext = makeShow(parsedText, valuenext)
                local nowShow = self._FrameDes:FindChild("Lab_Prof_Des/Lab_ProfNow")
                GUI.SetText(nowShow, valuenow)
                local nowShow = self._FrameDes:FindChild("Lab_Prof_Des/Lab_ProfNext")
                GUI.SetText(nowShow, valuenext)
            end

            self._FrameAdjust:SetActive(not showMax)
            self._FramePoint:SetActive(not showMax)
            self._LabMaxDes:SetActive(showMax)
            self._Soul_Icon_Sel = index
        end
    else
        warn("error occur in func TalentSkillClickCallBack")
    end
end

-- 
def.method("number","=>","boolean").ReviewTalentCheckState = function(self, pageId)
    local ret = false
    local talent_temp_data =  CWingsMan.Instance():GetTempTalentListData()
    if talent_temp_data then
        local curpage = talent_temp_data[self._Cur_Talent_Page].PageId
        if pageId == curpage then
            ret = true
        end
    end
    return ret
end

-- 天赋连线整体 置灰
def.method().TalentConnectFade = function(self)
    local line_prefix = "Frame_line"
    for i = 2, TALENT_SKILL_NUM do
        local index_st  = i
        local index_ori = i
        while (index_st - 1) > 0 do
            -- 只扫描到 3个元素
            if (index_ori - index_st) > 5  then
                break
            end
            -- 判断下
            if self._Root:HasUIObject(line_prefix .. index_ori ..  (index_st - 1)) then
                local line_obj = self._Root:GetUIObject(line_prefix .. index_ori ..  (index_st - 1))
                GUITools.SetUIActive(line_obj, false)
            end
            index_st = index_st - 1
        end
    end
    -- 特殊处理
    GUITools.SetUIActive(self._Root:GetUIObject(line_prefix .. 0 .. 9), false)
    GUITools.SetUIActive(self._Root:GetUIObject(line_prefix .. 0 .. 8), false)
end

def.method("table").SoulPanelUpdate = function(self, data)
    if not data or #data <= 0 then
        return
    end
     
    local prefix = "Rdo_List"
    local label_name_prefix ="Lab_List"

    for i = 1, 3 do  
        local label = self._Root:GetUIObject(prefix ..i):GetComponent(ClassType.Toggle)
        if label then
            label.isOn = false
        end
    end

    local show_index = 1
    for i = 1, #data do
        local page_data = CWingsMan.Instance():GetWingPageData(data[i].PageId)
        
        -- 查找选择页
        if game._HostPlayer:GetCurWingPageId() == data[i].PageId then
            show_index = i
        end

        if page_data then
            local label = self._Root:GetUIObject(prefix ..i)
            local lab_list = GUITools.GetChild(label, 1)
            if not IsNil(lab_list) then
                GUI.SetText(lab_list,tostring(page_data.TalentName))
            end
            local img_icon = GUITools.GetChild(label, 4)
            if not IsNil(img_icon) then
                GUITools.SetIcon(img_icon, page_data.IconPath)
            end
            if i == 1 then
               local sel = label:GetComponent(ClassType.Toggle)
               if sel then
                    sel.isOn = true
               end
            end
        end
    end
    self:RefreshToggleByIndex(show_index)
    -- self._Cur_Talent_Page = show_index
    -- -- 初始化第一页
    -- self:InitTalentItemsPage(data[show_index])
    -- self:SetToggleSelIndex(show_index)
    -- self:RefreshIconState()
    -- self._Cur_Talent_Page = show_index
end

def.method().OpenSoulPanel = function(self)
    if self._Cur_Talent_Page == -1 then
        self._Cur_Talent_Page = 1
    end    

    local data = CWingsMan.Instance():GetTalentListData()
    self:SoulPanelUpdate(data)
end

-- 刷新new 标识
def.method("boolean", "number").UpdateNewTag = function(self, is_unlock, sequenceNum)
    local tab_prefix = "Frame_Gift"
    -- 临时数据
    local talent_temp_data =  CWingsMan.Instance():GetTempTalentListData()
    local talent_lvl_data = talent_temp_data[self._Cur_Talent_Page].WingTalents
    
    -- 服务器数据
    local talent_static_data =  CWingsMan.Instance():GetTalentListData()
    local talent_server_data = talent_static_data[self._Cur_Talent_Page].WingTalents

    local tab = self._Root:GetUIObject(tab_prefix .. sequenceNum)
    local img_new = GUITools.GetChild(tab, 4)
    if not IsNil(img_new) then
        local oldState = self._PageUnlockTable[sequenceNum]
        if not oldState and is_unlock then
            local enable = false
            for _, data in pairs(talent_lvl_data) do
                local talentLvTemplate = CWingsMan.Instance():GetTalentLevelTemplate(data.WingTalentID)
                if talentLvTemplate ~= nil then
                    if talentLvTemplate.SequenceNum == sequenceNum then
                        enable = data.AddPoint == 0
                        break
                    end
                end
            end
            GUITools.SetUIActive(img_new, enable)
        else
            GUITools.SetUIActive(img_new, false)
        end
    end
end

-- 刷新单个连线
def.method("number", "number", "boolean").RefreshSingleConnect = function(self, ori, pre, state)
    local line_prefix = "Frame_line"
    -- 判断下
    if self._Root:HasUIObject(line_prefix .. ori .. pre) and pre > 0 then
        local line_obj = self._Root:GetUIObject(line_prefix .. ori .. pre)
        GUITools.SetUIActive(line_obj, state)
    end
end

-- 刷新天赋连接线
def.method().UpdateTalentConnect = function(self)    
    local talent_temp_data =  CWingsMan.Instance():GetTempTalentListData()        
    local talent_lvl_data = talent_temp_data[self._Cur_Talent_Page].WingTalents
    if talent_lvl_data then
        -- 从2开始扫描
        for i = 2, #talent_lvl_data do 
            -- 先索引到数据
            local wing_talent_data = nil
            for j = 1, #talent_lvl_data do 
                local id = talent_lvl_data[j].WingTalentID
                wing_talent_data = CWingsMan.Instance():GetTalentLevelTemplate(id)
                if wing_talent_data.SequenceNum == i then
                    break
                end
                wing_talent_data = nil
            end

            if wing_talent_data then                    
                -- 蓝色activeSelf                    
                local ret, state1, state2, sq1, sq2 = CWingsMan.Instance():CheckTalentUnlock(wing_talent_data.Id, self._Cur_Talent_Page)
                -- 刷新
                local sequenceNum = wing_talent_data.SequenceNum
                if sq1 > 0 and sq2 > 0 then
                    -- 被两个指向
                    self:RefreshSingleConnect(0, sequenceNum, state1 or state2)
                end
                self:RefreshSingleConnect(sequenceNum, sq1, state1)
                self:RefreshSingleConnect(sequenceNum, sq2, state2)
                self:UpdateNewTag(ret, sequenceNum)
            end
        end
    end
end

-- 初始化天赋技能 icon
-- PageId
-- TalentPoint 
-- WingTalents 
def.method("table").InitTalentItemsPage = function(self, data)
    -- 剩余天赋点数    
    if data and data.TalentPoint then
        local pointStr = tostring(data.TalentPoint)
        if data.TalentPoint <= 0 then
            -- 没有点数时字体变红
           pointStr = string.format(COLOR_RED_HEX, pointStr)
        end
        GUI.SetText(self._Lab_PointNum, pointStr)
    end

    -- 处理天赋页选择
    if game._HostPlayer:GetCurWingPageId() == data.PageId then
        self:SetTalentCheckBox(true)
    else
        self:SetTalentCheckBox(false)
    end

    -- 连接线处理
    self:TalentConnectFade()

    self:UpdateBtnReset()
    self:UpdateBtnSave()

    self._PageUnlockTable = {}
    -- icon处理
    local item_prefix = "Frame_Gift"
    for i = 1, #data.WingTalents do
        local wing_talent_data = CWingsMan.Instance():GetTalentLevelTemplate(data.WingTalents[i].WingTalentID)
        if wing_talent_data ~= nil then
            local item = self._Root:GetUIObject(item_prefix .. wing_talent_data.SequenceNum)
            if not IsNil(item) then
                -- 图片icon设置
                local uiTemplate = item:GetComponent(ClassType.UITemplate)
                if uiTemplate ~= nil then
                    local skill_data = CElementData.GetTemplate("Talent", wing_talent_data.TalentID)           
                    if skill_data ~= nil then
                        local img_icon = uiTemplate:GetControl(2) -- 正常图标
                        local img_icon_lock = uiTemplate:GetControl(6) -- 未解锁图标
                        GUITools.SetItemIcon(img_icon, skill_data.Icon)
                        GUITools.SetItemIcon(img_icon_lock, skill_data.Icon)
                    end
                    -- 是否解锁
                    local btn_normal = uiTemplate:GetControl(1) -- 正常图标按钮
                    local btn_lock = uiTemplate:GetControl(5) -- 未解锁图标按钮
                    local is_unlock = CWingsMan.Instance():CheckTalentUnlock(wing_talent_data.Id, self._Cur_Talent_Page)
                    btn_normal:SetActive(is_unlock)
                    btn_lock:SetActive(not is_unlock)
                    if is_unlock then
                        -- 等级
                        local lab_num = uiTemplate:GetControl(3)
                        GUI.SetText(lab_num, tostring(data.WingTalents[i].AddPoint))
                        -- 动/特效
                        local canAddPoint = CWingsMan.Instance():CheckTalentPointUp(wing_talent_data.Id, self._Cur_Talent_Page, false) and data.TalentPoint > 0
                        local img_lv_up = uiTemplate:GetControl(7)
                        img_lv_up:SetActive(canAddPoint)
                        local tween_id = "TalentLvUp"
                        local tween_man = img_lv_up:GetComponent(ClassType.DOTweenPlayer)
                        if canAddPoint then
                            tween_man:Restart(tween_id)
                        else
                            tween_man:Stop(tween_id)
                        end
                    end

                    self._PageUnlockTable[wing_talent_data.SequenceNum] = is_unlock
                end
            end
        end
    end
    self:UpdateTalentConnect()
    self:TalentSkillClickCallBack(self._Soul_Icon_Sel) 
    if #data.WingTalents ~= TALENT_SKILL_NUM then
        warn("init error occur in InitTalentItemsPage talent not 10!")
    end
end

def.method("table").PlayUISfxOnPointChange = function(self, data)
    if data == nil then return end

    local item_prefix = "Frame_Gift"
    for i = 1, #data.WingTalents do
        local lvTid = data.WingTalents[i].WingTalentID
        if self._PageTempAddPointTable[lvTid] then
            local wing_talent_data = CWingsMan.Instance():GetTalentLevelTemplate(data.WingTalents[i].WingTalentID)
            if wing_talent_data ~= nil then
                local item = self._Root:GetUIObject(item_prefix .. wing_talent_data.SequenceNum)
                if not IsNil(item) then
                    local btn_normal = GUITools.GetChild(item, 1)
                    GameUtil.PlayUISfx(PATH.UIFX_WenZhangZhuanJingShengJi, btn_normal, btn_normal, -1)
                end
            end
        end
    end
    self._PageTempAddPointTable = {}
end

-- 刷新页
def.method("number").SetSoulPanelByIndex = function(self, index)
    -- 这里用真实数据
    local data =  CWingsMan.Instance():GetTalentListData()
    if not data or #data < index then
        return
    end
    -- 这里重置下 前一页缓冲数据
    CWingsMan.Instance():ResetSkillTempList(self._Cur_Talent_Page)

    -- 更新天赋页描述
    local pageTemplate = CWingsMan.Instance():GetWingPageData(data[index].PageId)
    if pageTemplate ~= nil then
        local titleStr = string.format(StringTable.Get(19534), pageTemplate.TalentName)
        local descStr = titleStr .."  "..pageTemplate.DescribeText -- 标题和具体描述中间隔两个空格
        GUI.SetText(self._Lab_PageDesc, descStr)
    end

    -- 刷新
    self:InitTalentItemsPage(data[index])
    self:RefreshIconState()
end

-- 更新加点
def.method("number", "number").UpdateTalentIconNum = function(self, point, id)
    local tab_prefix = "Frame_Gift"
    local tab = nil
    local talent_temp_data =  CWingsMan.Instance():GetTempTalentListData()   
    local talent_lvl_data = talent_temp_data[self._Cur_Talent_Page].WingTalents
    if talent_lvl_data then    
        for i = 1, #talent_lvl_data do             
            if talent_lvl_data[i].WingTalentID == id then
                local wing_talent_data =  CWingsMan.Instance():GetTalentLevelTemplate(talent_lvl_data[i].WingTalentID)                
                tab = self._Root:GetUIObject(tab_prefix..wing_talent_data.SequenceNum )
                break
            end             
        end
    end
    local left_point = talent_temp_data[self._Cur_Talent_Page].TalentPoint
    local left_point_str = tostring(left_point)
    if left_point <= 0 then
        left_point_str = string.format(COLOR_RED_HEX, left_point_str)
    end
    GUI.SetText(self._Lab_PointNum, left_point_str)
    if not IsNil(tab) then
        local lab_num = GUITools.GetChild(tab, 3)
        if not IsNil(lab_num) then
            GUI.SetText(lab_num, tostring(point))
            local isChange = CWingsMan.Instance():WingSoulChangedSpecial(self._Cur_Talent_Page, id)
            local color = Color.white
            if isChange then
                color = Color.green
            end
            GUI.SetTextColor(lab_num, color)
        end
    end
   -- 更新连接线状态
   self:UpdateTalentConnect()
end

def.method().RefreshIconState = function(self)
    -- 这里用临时数据做模拟
    local data =  CWingsMan.Instance():GetTempTalentListData()
    if not data then
        warn("error occor in RefreshIconState !")
        return
    end

    for index = 1, TALENT_SKILL_NUM do          
        local talent_data = nil
        for i = 1, #data[self._Cur_Talent_Page].WingTalents do             
            local id = data[self._Cur_Talent_Page].WingTalents[i].WingTalentID
            local wing_talent_data = CWingsMan.Instance():GetTalentLevelTemplate(id)
            if wing_talent_data.SequenceNum == index then
                talent_data = data[self._Cur_Talent_Page].WingTalents[i]
                break
            end
        end

        if talent_data then                
            local prefix = "Frame_Gift" .. index  
            local skill_icon = self._Root:GetUIObject(prefix)
            if not IsNil(skill_icon) then
                -- 是否解锁
                local btn_normal = GUITools.GetChild(skill_icon, 1) -- 正常图标按钮
                local btn_lock = GUITools.GetChild(skill_icon, 5) -- 未解锁图标按钮
                local is_unlock = CWingsMan.Instance():CheckTalentUnlock(talent_data.WingTalentID, self._Cur_Talent_Page)
                btn_normal:SetActive(is_unlock)
                btn_lock:SetActive(not is_unlock)
                if is_unlock then
                    -- 等级
                    local lab_num = GUITools.GetChild(skill_icon, 3)
                    GUI.SetText(lab_num, tostring(talent_data.AddPoint))

                    local isChange = CWingsMan.Instance():WingSoulChangedSpecial(self._Cur_Talent_Page, talent_data.WingTalentID)
                    local color = Color.white
                    if isChange then
                        color = Color.green
                    end
                    GUI.SetTextColor(lab_num, color)

                    -- 动/特效
                    local canAddPoint = CWingsMan.Instance():CheckTalentPointUp(talent_data.WingTalentID, self._Cur_Talent_Page, false) and data[self._Cur_Talent_Page].TalentPoint > 0
                    local img_lv_up = GUITools.GetChild(skill_icon, 7)
                    img_lv_up:SetActive(canAddPoint)
                    local tween_man = img_lv_up:GetComponent(ClassType.DOTweenPlayer)
                    local tween_id = "TalentLvUp"
                    if canAddPoint then
                        tween_man:Restart(tween_id)
                    else
                        tween_man:Stop(tween_id)
                    end
                end
            end
        else
            warn("error occur in func RefreshIconState")
        end
    end    
end

-- 加点
def.method().AddTalentPoint = function(self)
    if CWingsMan.Instance():CheckTempPointLeft(self._Cur_Talent_Page) then
        -- 点数足够
        -- 前置等级检查
        local ret = CWingsMan.Instance():CheckTalentPointUp(self._TalentId, self._Cur_Talent_Page, true)
        if ret then
            if self._CurAddNum < self._MaxAddNum then
                self._CurAddNum = self._CurAddNum + 1
                GUI.SetText(self._Lab_Number, self._CurAddNum.."/"..self._MaxAddNum)
                CWingsMan.Instance():SetSkillTempData(self._TalentId, self._CurAddNum, self._Cur_Talent_Page)
                self:UpdateTalentIconNum(self._CurAddNum, self._TalentId)
                self:TalentSkillClickCallBack(self._Soul_Icon_Sel) 
                self:RefreshIconState()

                self:UpdateBtnReset()
                self:UpdateBtnSave()
            end
        end
    else
	    -- 点数不足
        game._GUIMan:ShowTipText(StringTable.Get(19520), false)
    end
end

-- 减点
def.method().MinusTalentPoint = function(self)
    --后置技能等级检查
    local ret = CWingsMan.Instance():CheckTalentPointDown(self._TalentId, self._Cur_Talent_Page, true)
    if ret then
        if self._CurAddNum <= self._MaxAddNum and self._CurAddNum > 0 then
            self._CurAddNum = self._CurAddNum - 1                    
            GUI.SetText(self._Lab_Number, self._CurAddNum.."/"..self._MaxAddNum)
            CWingsMan.Instance():MinusSkillTempData(self._TalentId, self._CurAddNum, self._Cur_Talent_Page)
            self:UpdateTalentIconNum(self._CurAddNum, self._TalentId)
            self:TalentSkillClickCallBack(self._Soul_Icon_Sel) 
            self:RefreshIconState()

            self:UpdateBtnReset()
            self:UpdateBtnSave()
        end
    end
end

-- 刷新已装备标签
def.method("number").RefreshSelectTag = function(self, sel)
    local rdo_btn_prefix = "Rdo_List"
    for index = 1, 3 do 
        local radio_btn = self._Root:GetUIObject(rdo_btn_prefix .. index)
        local data =  CWingsMan.Instance():GetTalentListData()
        if not IsNil(radio_btn) and data[index] then
            local tag = GUITools.GetChild(radio_btn, 0)
            if not IsNil(tag) then
                GUITools.SetUIActive(tag, sel == data[index].PageId)
            end
        end
    end
end

def.method("number").SetToggleSelIndex = function(self, index)
    local toggle_prefix = "Rdo_List"
    for i = 1, ALL_TALENT_PAGE_NUM do
        local to = self._Root:GetUIObject(toggle_prefix..i)
        if to then
            local sel = to:FindChild("Img_D")
            if sel then
                sel:SetActive(false)
            end
        end
    end

    local cur_to = self._Root:GetUIObject(toggle_prefix..index)
    if cur_to then
        local sel = cur_to:FindChild("Img_D")
        if sel then
            sel:SetActive(true)
        end
    end
end

def.method("number").RefreshToggleByIndex = function(self, index)
    self:SetToggleSelIndex(index)
    self._Cur_Talent_Page = index
    self:SetSoulPanelByIndex(index)
end

-- 更新重置按钮状态
def.method().UpdateBtnReset = function (self)
    local hasAddPoint = CWingsMan.Instance():SoulDataAdded(self._Cur_Talent_Page)
    local hasTempAddPoint = CWingsMan.Instance():WingSoulChanged(self._Cur_Talent_Page)
    GUITools.SetBtnGray(self._Btn_Reset, not hasAddPoint and not hasTempAddPoint)
end

-- 更新保存按钮状态
def.method().UpdateBtnSave = function (self)
    local hasPointChange = CWingsMan.Instance():WingSoulChanged(self._Cur_Talent_Page)
    GUITools.SetBtnGray(self._Btn_Save, not hasPointChange)
    self:RefreshIconState()
end

-----------------------服务器推送更新-----------------------
-- 天赋点获取
def.method().OnTalentGetPoint = function (self)
	self:TalentSkillClickCallBack(self._Soul_Icon_Sel)
end

-- 天赋页被选中
def.method("number").OnWingTalentSelect = function (self, pageId)
	if self:ReviewTalentCheckState(pageId) then
		self:SetTalentCheckBox(true)
	end
end

-- 天赋点更新
def.method().OnWingTalentPointChange = function (self)
	local data = CWingsMan.Instance():GetTalentListData()
	if data ~= nil then
		self:InitTalentItemsPage(data[self._Cur_Talent_Page])
        self:PlayUISfxOnPointChange(data[self._Cur_Talent_Page])
	end
end

-- 天赋页洗点
def.method("number").OnWingTalentPointWash = function (self, pageId)
	local data = CWingsMan.Instance():GetTalentListData()
	if data ~= nil then
		local curData = data[self._Cur_Talent_Page]
		if curData ~= nil and curData.PageId == pageId then
			self:InitTalentItemsPage(curData)
			self:RefreshIconState()
		end
	end
end

CPageWingSoul.Commit()
return CPageWingSoul