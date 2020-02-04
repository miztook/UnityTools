--
--加入申请、创建公会
--
--【孟令康】
--
--2017年9月21日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelUIGuildList = Lplus.Extend(CPanelBase, "CPanelUIGuildList")
local def = CPanelUIGuildList.define
local CFrameCurrency = require "GUI.CFrameCurrency"
local CCommonBtn = require "GUI.CCommonBtn"
local NameChecker = require "Utility.NameChecker"

def.field("number")._GuildCreateDiamondCost = 0
def.field("number")._Text_Type = ClassType.Text
def.field("number")._Input_Type = ClassType.InputField
def.field("number")._List_Type = ClassType.GNewList
-- 旗帜数据
def.field("table")._Guild_Icon_1 = BlankTable
def.field("table")._List_Item_1 = BlankTable
def.field("table")._Guild_Icon_2 = BlankTable
def.field("table")._List_Item_2 = BlankTable
def.field("table")._Guild_Icon_3 = BlankTable
def.field("table")._List_Item_3 = BlankTable

-- 公会列表
def.field("table")._Guild_List = nil
-- 上次点击item
def.field("userdata")._SelectItemButton = nil
---- 是否需要审批
--def.field("boolean")._NeedAgree = false
-- 是否第一次点击列表界面
def.field("boolean")._Is_First_Add = true
-- 是否第一次点击创建界面
def.field("boolean")._Is_First_Create = true
-- 是否是搜索界面
def.field("boolean")._Is_Search = false
-- 搜索数据结果
def.field("table")._Search_Result = nil
-- 创建总费用
def.field("number")._Create_Money = 0
-- 加入所需要的战力值
def.field("number")._Need_Value = 0
-- 通用货币界面
def.field(CFrameCurrency)._Frame_Money = nil
-- 底部按钮
def.field("userdata")._Search = nil
def.field("userdata")._Img_D0 = nil
def.field("userdata")._Img_D1 = nil
-- 加入申请
def.field("userdata")._Frame_Add = nil
def.field("userdata")._Add_List_Rect = nil
def.field("userdata")._Add_List = nil
def.field("userdata")._Search_Success = nil
def.field("userdata")._InputField_Search = nil
-- 创建公会
def.field("userdata")._Frame_Create = nil
def.field("userdata")._Group_List_1 = nil
def.field("userdata")._Group_List_2 = nil
def.field("userdata")._Group_List_3 = nil
def.field("table")._Guild_Icon_Image = BlankTable
def.field("userdata")._InputField_Name = nil
def.field("userdata")._Default_Lab = nil
def.field("userdata")._Frame_Toggle = nil
--def.field("userdata")._Rdo_Check_No = nil
--def.field("userdata")._Rdo_Check_Yes = nil
def.field("userdata")._Rdo_Check = nil     --<GNewIOSToggle>
--def.field("userdata")._Img_Money = nil
--def.field("userdata")._Lab_Create_Money = nil
def.field("userdata")._TagGroup = nil
def.field(CCommonBtn)._Btn_Create = nil
def.field("userdata")._Lab_Count = nil
def.field("userdata")._Lab_Tip = nil 
def.field("userdata")._Btn_Plus = nil
def.field("userdata")._Btn_Minus = nil

local instance = nil
def.static("=>", CPanelUIGuildList).Instance = function()
	if not instance then  
		instance = CPanelUIGuildList()
		instance._PrefabPath = PATH.UI_Guild_List
		instance._PanelCloseType = EnumDef.PanelCloseType.None
        
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
    self:OnInitUIObject()
    self:OnInit()
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
    self._Search_Success:SetActive(false)
    if data._Index == 0 then
        self._Guild_List = {}
        -- 公会人数满了不显示
        for i = 1, #data._Data do
            local guild = CElementData.GetTemplate("GuildLevel", data._Data[i].guildLevel)
            if guild ~= nil then
                if guild.MemberNumber ~= data._Data[i].MemberNum then
                    self._Guild_List[#self._Guild_List + 1] = data._Data[i]
                end
            end
        end
        -- 等级优先显示
        local count = #self._Guild_List
        for i = 1, count do
            for j = 1, count - i do
                if self._Guild_List[j].guildLevel < self._Guild_List[j + 1].guildLevel then
                    local temp = self._Guild_List[j + 1]
                    self._Guild_List[j + 1] = self._Guild_List[j]
                    self._Guild_List[j] = temp
                end
            end
        end
    end
    GUI.SetGroupToggleOn(self._TagGroup, data._Index + 2)
    self:ClickTab(data._Index)
end

-- 当摧毁
def.override().OnDestroy = function(self)
    if self._Frame_Money ~= nil then
        self._Frame_Money:Destroy()
        self._Frame_Money = nil
    end
    if self._Btn_Create ~= nil then
        self._Btn_Create:Destroy()
        self._Btn_Create = nil
    end
    instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
    --print("id ", id)
    if self._Frame_Money ~= nil and self._Frame_Money:OnClick(id) then
        return
    end

    -- if self._Input_Battle ~= nil and self._Input_Battle:OnClick(id) then
    --     return
    -- end
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Exit" then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_Question" then
        TODO(StringTable.Get(19))
 
    elseif id == "Btn_Search_Guild" then
        self:OnBtnSearchGuild()
--    elseif id == "Btn_Sub_Score" then
--        self:OnBtnSubScore()
--    elseif id == "Btn_Plus_Score" then
--        self:OnBtnPlusScore()
--    elseif id == "Btn_Set_Score" then
--        self:OnBtnSetScore()
--    elseif id == "Rdo_Check_No" then
--        self:OnBtnCheckNo()
--    elseif id == "Rdo_Check_Yes" then
--        self:OnBtnCheckYes()
    elseif id == "Btn_Create_Guild" then
        self:OnBtnCreateGuild()
    elseif id == "Btn_Add_Guild" then
        self:OnSearchBtnAddGuild()
--	elseif id == "Rdo_Check" then
--		self:OnBtnCheck()

    elseif id == "Rdo_Check" then  --审批
        self._Rdo_Check:ToggleValue()
        local uiTemplate = self._Frame_Toggle:GetComponent(ClassType.UITemplate)
        local checked = self._Rdo_Check.Value
        local lab_off = uiTemplate:GetControl(0)
        local lab_on = uiTemplate:GetControl(1)
        if checked then
            lab_off:SetActive(true)
            lab_on:SetActive(false)
        else
            lab_off:SetActive(false)
            lab_on:SetActive(true)
        end
    elseif id == "Btn_NumInput" then
        local cb = function(count)
            if not self:IsShow() then return end
            local real_count = (count or 0)
            self._Need_Value = math.max(real_count, 0)
            self._Need_Value = math.min(self._Need_Value, GlobalDefinition.MaxFightScoreNum)
            self:UpdateInputState()
        end
        game._GUIMan:OpenNumberKeyboard(self._Lab_Count,self._Lab_Tip, 0, GlobalDefinition.MaxFightScoreNum, cb, nil)
    elseif id == "Btn_Plus_Score" then
        self:OnBtnPlusScore()
    elseif id == "Btn_Minus_Score" then
        self:OnBtnMinusScore()
	end

end

def.override("string","boolean").OnToggle = function(self, id,checked)
    if id == "Tab_Add" then
        if checked then
            self:ClickTab(0)
        end
    elseif id == "Tab_Create" then
        if checked then
            self:ClickTab(1)
        end
    end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    if id == "Add_List" then
        local data = nil 
        if self._Is_Search then 
            data = self._Search_Result[index + 1]
        else
            data = self._Guild_List[index + 1]
        end
        self:OnSetSingleItem(item, index,data )
    elseif id == "Group_List_1" then
        self:OnSetGroupList1(item, index)
    elseif id == "Group_List_2" then
        self:OnSetGroupList2(item, index)
    elseif id == "Group_List_3" then
        self:OnSetGroupList3(item, index)
    end
end

-- 选中列表
def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "Group_List_1" then
        self._List_Item_1._Item:FindChild("Img_U"):SetActive(false)
        item:FindChild("Img_U"):SetActive(true)
        self._List_Item_1._Item = item
        self._List_Item_1._Index = index + 1
        self:OnSetCreateMoney()
        GameUtil.PlayUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2], self._Guild_Icon_Image[2], -1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Skill, 0)
    elseif id == "Group_List_2" then
        self._List_Item_2._Item:FindChild("Img_U"):SetActive(false)
        item:FindChild("Img_U"):SetActive(true)
        self._List_Item_2._Item = item
        self._List_Item_2._Index = index + 1
        self:OnSetCreateMoney()
        GameUtil.PlayUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2], self._Guild_Icon_Image[2], -1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Skill, 0)
    elseif id == "Group_List_3" then
        self._List_Item_3._Item:FindChild("Img_U"):SetActive(false)
        item:FindChild("Img_U"):SetActive(true)
        self._List_Item_3._Item = item
        self._List_Item_3._Index = index + 1
        self:OnSetCreateMoney()
        GameUtil.PlayUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2], self._Guild_Icon_Image[2], -1)
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Skill, 0)
    end
end

-- 选中列表按钮
def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, item, id, id_btn, index)
    if id == "Add_List" then
        if id_btn == "Btn_Add_Guild" then
            self._SelectItemButton = item
            self:OnBtnAddGuild(index)
        elseif id_btn == "Lab_Leader" then
            local EOtherRoleInfoType = require "PB.data".EOtherRoleInfoType
            local guildList = {}
            if not self._Is_Search then 
                guildList = self._Guild_List[index + 1]
            else
                guildList = self._Search_Result[index + 1] 
            end
            local PBUtil = require "PB.PBUtil"
            PBUtil.RequestOtherPlayerInfo(guildList.leaderID, EOtherRoleInfoType.RoleInfo_Simple, nil)
        end
    end
end

-- 当输入框变化
def.override("string", "string").OnValueChanged = function(self, id, str)
    if id == "InputField_Search" then
        if string.len(str) == 0 then
            self._Is_Search = false
            self._Add_List_Rect:SetActive(true)
            self._Search_Success:SetActive(false)
            self._Add_List:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._Guild_List)
        end
        local ret = NameChecker.SubGuildName(str)
        if ret ~= str then
            self._InputField_Search:GetComponent(self._Input_Type).text = ret
        end
    end
end

----Toggle
--def.override("string", "boolean").OnToggle = function(self, id, checked)
--    if string.find(id, "Rdo_Check") then  --

--    end
--end

-- 初始化基础信息
def.method().OnInit = function(self)
    self._GuildCreateDiamondCost = CSpecialIdMan.Get("GuildCreateDiamondCost")

    local allTid = CElementData.GetAllTid("GuildIcon")
    self._Guild_Icon_1 = {}
    self._Guild_Icon_2 = {}
    self._Guild_Icon_3 = {}
    for i = 1, #allTid do
        local guildIcon = CElementData.GetTemplate("GuildIcon", allTid[i])
        if guildIcon.Type == 1 then
            self._Guild_Icon_1[#self._Guild_Icon_1 + 1] = guildIcon
        elseif guildIcon.Type == 2 then
            self._Guild_Icon_2[#self._Guild_Icon_2 + 1] = guildIcon
        elseif guildIcon.Type == 3 then
            self._Guild_Icon_3[#self._Guild_Icon_3 + 1] = guildIcon
        end
    end

    local setting = {
        [EnumDef.CommonBtnParam.MoneyID] = 3,
    }
    self._Btn_Create:ResetSetting(setting)
    self:UpdateInputState()

--    GUITools.SetTokenMoneyIcon(self._Img_Money, 3)
end

-- 初始化UIObject
def.method().OnInitUIObject = function(self)
    self._Frame_Money = CFrameCurrency.new(self, self:GetUIObject("Frame_Money"), EnumDef.MoneyStyleType.None)

    self._Search = self:GetUIObject("Search")
    self._TagGroup = self:GetUIObject("TagGroup")
    self._Frame_Add = self:GetUIObject("Frame_Add")
    self._Add_List_Rect = self:GetUIObject("Add_List_Rect")
    self._Add_List = self:GetUIObject("Add_List")
    self._Search_Success = self:GetUIObject("Search_Success")
    self._InputField_Search = self:GetUIObject("InputField_Search")

    self._Frame_Create = self:GetUIObject("Frame_Create")
    self._Group_List_1 = self:GetUIObject("Group_List_1")
    self._Group_List_2 = self:GetUIObject("Group_List_2")
    self._Group_List_3 = self:GetUIObject("Group_List_3")
    local img_Flag = self:GetUIObject("Img_Flag2")
    self._Guild_Icon_Image[1] = img_Flag:FindChild("Img_Flag_BG")
    self._Guild_Icon_Image[2] = img_Flag:FindChild("Img_Flag_Flower_1")
    self._Guild_Icon_Image[3] = img_Flag:FindChild("Img_Flag_Flower_2")
    self._InputField_Name = self:GetUIObject("InputField_Name")
    self._Default_Lab = self:GetUIObject("DefaultLab")
    self._Btn_Plus = self:GetUIObject("Btn_Plus_Score")
    self._Btn_Minus = self:GetUIObject("Btn_Minus_Score")
    self._Lab_Count = self:GetUIObject("Lab_Count")
    self._Lab_Tip = self:GetUIObject("Lab_Tip")
    self._Frame_Toggle = self:GetUIObject("Rdo_Check")
	self._Rdo_Check = self._Frame_Toggle:GetComponent(ClassType.GNewIOSToggle)
    GameUtil.RegisterUIEventHandler(self._Panel, self._Frame_Toggle, ClassType.GNewIOSToggle)
    self._Btn_Create = CCommonBtn.new(self:GetUIObject("Btn_Create_Guild"), nil)
    self._Search_Success:SetActive(false)
end

-- 点击下方输入框切换操作
def.method("number").ClickTab = function(self, index)
    if index == 0 then
        if self._Guild_List == nil then
            game._GuildMan:SendC2SGuildList()
        else
            self:ShowTabAdd()
        end
    else
        self:ShowTabCreate()
    end
end

-- 展示一条公会信息
def.method("userdata", "number", "table").OnSetSingleItem = function(self, item, index, data)
    GUI.SetText(item:FindChild("Lab_Name/Lab_Id"), "ID " .. data.guildID)
    local iconId = {}
    iconId[1] = data.guildIcon.BaseColorID
    iconId[2] = data.guildIcon.FrameID
    iconId[3] = data.guildIcon.ImageID
    local iconImage = {}
    iconImage[1] = item:FindChild("Img_Flag/Img_Flag_BG")
    iconImage[2] = item:FindChild("Img_Flag/Img_Flag_Flower_1")
    iconImage[3] = item:FindChild("Img_Flag/Img_Flag_Flower_2")
    game._GuildMan:SetGuildIcon(iconId, iconImage)
    GUI.SetText(item:FindChild("Lab_Level_Des/Lab_Level"), tostring(data.guildLevel))
    GUI.SetText(item:FindChild("Lab_Name"), data.guildName)
    GUI.SetText(item:FindChild("Lab_Leader_Des/Lab_Leader"), data.leaderName)
    local guild = CElementData.GetTemplate("GuildLevel", data.guildLevel)
    GUI.SetText(item:FindChild("Lab_Number_Des/Lab_Number"), data.MemberNum .. "/" .. guild.MemberNumber)
    local battlePower = data.addLimit.battlePower
    if data.MemberNum == guild.MemberNumber or game._HostPlayer:GetHostFightScore() < battlePower then
        GUITools.SetBtnGray(item:FindChild("Btn_Add_Guild"), true)
    else
        GUITools.SetBtnGray(item:FindChild("Btn_Add_Guild"), false)
    end
    local labScore = item:FindChild("Lab_Score_Des/Lab_Score")
    local labLimit = item:FindChild("Lab_Score_Des/Lab_Limit")
    if game._HostPlayer:GetHostFightScore() < battlePower then
        labLimit:SetActive(false)
        labScore:SetActive(true)
        GUI.SetText(labScore, "<color=#FF412DFF>" .. GUITools.FormatNumber(battlePower, false) .. "</color>")
    else
        if battlePower == 0 then
            labLimit:SetActive(true)
            labScore:SetActive(false)
            GUI.SetText(labLimit, StringTable.Get(8086))
        else
            labLimit:SetActive(false)
            labScore:SetActive(true)
            GUI.SetText(labScore, tostring("<color=#97E039FF>" .. GUITools.FormatNumber(battlePower, false) .. "</color>"))
        end
    end
    item:FindChild("Lab_Score_Des/Lab_Remind"):SetActive(false)
    if data.needAgree then
        GUI.SetText(item:FindChild("Btn_Add_Guild/Img_Bg/Lab_Engrave"), StringTable.Get(22409))   
    else
        GUI.SetText(item:FindChild("Btn_Add_Guild/Img_Bg/Lab_Engrave"), StringTable.Get(890))
    end
    local _Guild = game._HostPlayer._Guild
    for i = 1, #_Guild._ApplyList do
        if data.guildID == _Guild._ApplyList[i] then
            GUI.SetText(item:FindChild("Btn_Add_Guild/Img_Bg/Lab_Engrave"), StringTable.Get(887))
            GUITools.SetBtnGray(item:FindChild("Btn_Add_Guild"), true)
            -- GameUtil.SetButtonInteractable(item:FindChild("Btn_Add_Guild"), false)
        end
    end
end

-- 展示加入申请界面
def.method().ShowTabAdd = function(self)
    self._Frame_Add:SetActive(true)
    self._Frame_Create:SetActive(false)
    self._Search:SetActive(true)
    -- self._Img_D0:SetActive(true)
    -- self._Img_D1:SetActive(false)
    if self._Is_First_Add then
        self._Add_List:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._Guild_List)
        self._Is_First_Add = false
    end
end

-- 展示创建公会界面
def.method().ShowTabCreate = function(self)
    self._Frame_Add:SetActive(false)
    self._Frame_Create:SetActive(true)
    self._Search:SetActive(false)
    -- self._Img_D0:SetActive(false)
    -- self._Img_D1:SetActive(true)
    if self._Is_First_Create then
        self._Group_List_1:GetComponent(self._List_Type):SetItemCount(#self._Guild_Icon_1)
        self._Group_List_2:GetComponent(self._List_Type):SetItemCount(#self._Guild_Icon_2)
        self._Group_List_3:GetComponent(self._List_Type):SetItemCount(#self._Guild_Icon_3)  
        self._Is_First_Create = false
        self:OnSetCreateMoney()
    end
    GameUtil.StopUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2])
    local need_Agree = self._Rdo_Check.Value
    local uiTemplate = self._Frame_Toggle:GetComponent(ClassType.UITemplate)
    local lab_off = uiTemplate:GetControl(0)
    local lab_on = uiTemplate:GetControl(1)
    if need_Agree then
        lab_off:SetActive(true)
        lab_on:SetActive(false)
    else
        lab_off:SetActive(false)
        lab_on:SetActive(true)
    end
    --self:ShowNeedAgreeState()
    --GUITools.SetIOSToggleValue(self._Rdo_Check, self._NeedAgree, true)
    --self._Rdo_Check.Value = self._NeedAgree
end

-- 展示旗帜列表
def.method("userdata", "number").OnSetGroupList1 = function(self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local ImgU = uiTemplate:GetControl(6)
    local ImgD = uiTemplate:GetControl(1)
    local ImgLockBg = uiTemplate:GetControl(2)
    local LabCost = uiTemplate:GetControl(7)
    local ImgUseBg = uiTemplate:GetControl(4)
    if index == 0 then
        ImgU:SetActive(true)
        self._List_Item_1._Item = item
        self._List_Item_1._Index = index + 1
    else
        ImgU:SetActive(false)
    end
    local guildIcon = self._Guild_Icon_1[index + 1]
    if guildIcon.CostMoneyNum > 0 then
        ImgLockBg:SetActive(true)
        GUI.SetText(LabCost,tostring(guildIcon.CostMoneyNum))
    else
        ImgLockBg:SetActive(false)
    end
    ImgUseBg:SetActive(false)
    ImgD:SetActive(true)
    GameUtil.SetImageColor(ImgD, guildIcon.ColorValue)
end

def.method("userdata", "number").OnSetGroupList2 = function(self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local ImgU = uiTemplate:GetControl(6)
    local ImgD = uiTemplate:GetControl(1)
    local ImgLockBg = uiTemplate:GetControl(2)
    local LabCost = uiTemplate:GetControl(7)
    local ImgUseBg = uiTemplate:GetControl(4)
    ImgU:SetActive(false)
    if index == 0 then
        ImgU:SetActive(true)
        self._List_Item_2._Item = item
        self._List_Item_2._Index = index + 1
    end
    local guildIcon = self._Guild_Icon_2[index + 1]
    if guildIcon.CostMoneyNum > 0 then
        ImgLockBg:SetActive(true)
        GUI.SetText(LabCost,tostring(guildIcon.CostMoneyNum))
    else
        ImgLockBg:SetActive(false)
    end
    ImgUseBg:SetActive(false)
    GUITools.SetGuildIcon(ImgD, guildIcon.IconPath)
end

def.method("userdata", "number").OnSetGroupList3 = function(self, item, index)
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local ImgU = uiTemplate:GetControl(6)
    local ImgD = uiTemplate:GetControl(1)
    local ImgLockBg = uiTemplate:GetControl(2)
    local LabCost = uiTemplate:GetControl(7)
    local ImgUseBg = uiTemplate:GetControl(4)
    if index == 0 then
        ImgU:SetActive(true)
        self._List_Item_3._Item = item
        self._List_Item_3._Index = index + 1
    end
    local guildIcon = self._Guild_Icon_3[index + 1]
    if guildIcon.CostMoneyNum > 0 then
        ImgLockBg:SetActive(true)
        GUI.SetText(LabCost,tostring(guildIcon.CostMoneyNum))
    else
        ImgLockBg:SetActive(false)
    end
    ImgUseBg:SetActive(false)
    GUITools.SetGuildIcon(ImgD, guildIcon.IconPath)   
end

-- 申请加入公会
def.method("number").OnBtnAddGuild = function(self, index)
    local guild = game._HostPlayer._Guild
    local guildList = nil 
    if not self._Is_Search then 
        guildList = self._Guild_List[index + 1]
    else
        guildList = self._Search_Result[index + 1] 
    end
    if game._HostPlayer:GetHostFightScore() < guildList.addLimit.battlePower then
        game._GUIMan:ShowTipText(StringTable.Get(811), true)
        return
    end
    for i = 1, #guild._ApplyList do
        if guildList.guildID == guild._ApplyList[i] then
            game._GuildMan:SendC2SGuildApplyAdd(guildList.guildID)   
            return
        end
    end
    local callback = function(val)
        if val then
            game._GuildMan:SendC2SGuildApplyAdd(guildList.guildID)
        end
    end
    local title, msg, closeType = StringTable.GetMsg(121)
    msg = string.format(msg, RichTextTools.GetGuildNameRichText(guildList.guildName, false))
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
end

-- 搜索申请加入公会
def.method().OnSearchBtnAddGuild = function(self)
    if self._Is_Search then
        local guild = game._HostPlayer._Guild
        local guildList = self._Search_Result
        if guildList == nil then
            return
        end
        for i = 1, #guild._ApplyList do
            if guildList.guildID == guild._ApplyList[i] then
                return
            end
        end
        if game._HostPlayer:GetHostFightScore() < guildList.addLimit.battlePower then
            game._GUIMan:ShowTipText(StringTable.Get(811), true)
            return
        end
        game._GuildMan:SendC2SGuildApplyAdd(guildList.guildID)
    end 
end

-- 加入公会申请成功
def.method().OnGuildApplyAddSuccess = function(self)
   
    GUI.SetText(self._SelectItemButton:FindChild("Img_Bg/Lab_Engrave"), StringTable.Get(887))
    --self._SelectItemButton:FindChild("Img_Lock"):SetActive(true)
    GUITools.SetBtnGray(self._SelectItemButton, true)
end

-- 搜索公会
def.method().OnBtnSearchGuild = function(self)
    local guildName = self._InputField_Search:FindChild("Text"):GetComponent(self._Text_Type).text
    if string.len(guildName) == 0 then
        game._GUIMan:ShowTipText(StringTable.Get(819), true)
        return
    end
    local guildID = nil
    -- 防止整型越界
    if string.len(guildName) < 9 then
        guildID = tonumber(guildName)
    end

    local protocol = (require "PB.net".C2SGuildBaseInfo)()
    if guildID ~= nil then
        protocol.guildID = guildID  
    else
        protocol.guildName = guildName
    end
    PBHelper.Send(protocol)  
end

-- 搜索公会结果
def.method("table").ShowSearchGuild = function(self, result)
    if result == nil or #result == 0 then
        game._GUIMan:ShowTipText(StringTable.Get(8011), true)
    else
        self._Is_Search = true
        self._Search_Result = result
        self._Add_List:GetComponent(ClassType.GNewListLoop):SetItemCount(#self._Search_Result)
        -- self:OnSetSingleItem(self._Search_Success, 0, result)
    end
end

def.method().OnBtnPlusScore = function(self)
    self._Need_Value = self._Need_Value + 1
    self._Need_Value = math.min(self._Need_Value, GlobalDefinition.MaxFightScoreNum)
    self:UpdateInputState()
end

def.method().OnBtnMinusScore = function(self)
    self._Need_Value = self._Need_Value - 1
    self._Need_Value = math.max(self._Need_Value, 0)
    self:UpdateInputState()
end

def.method().UpdateInputState = function(self)
    if self._Need_Value <= 0 then
        self._Lab_Count:SetActive(false)
        self._Lab_Tip:SetActive(true)
        GameUtil.SetButtonInteractable(self._Btn_Minus, false)
        GUITools.SetBtnGray(self._Btn_Minus, true, true)
    else
        self._Lab_Count:SetActive(true)
        self._Lab_Tip:SetActive(false)
        GUI.SetText(self._Lab_Count, tostring(self._Need_Value))
        GameUtil.SetButtonInteractable(self._Btn_Minus, true)
        GUITools.SetBtnGray(self._Btn_Minus, false, true)
    end
    if self._Need_Value >= GlobalDefinition.MaxFightScoreNum then
        GameUtil.SetButtonInteractable(self._Btn_Plus, false)
        GUITools.SetBtnGray(self._Btn_Plus, true, true)
    else
        GameUtil.SetButtonInteractable(self._Btn_Plus, true)
        GUITools.SetBtnGray(self._Btn_Plus, false, true)
    end
end

---- 点击不需要审批按钮
--def.method().OnBtnCheckNo = function(self)
--    self._Rdo_Check_Yes:SetActive(true)
--    self._Rdo_Check_No:SetActive(false)
--    self._NeedAgree = true
--end

---- 点击需要审批按钮
--def.method().OnBtnCheckYes = function(self)
--    self._Rdo_Check_Yes:SetActive(false)
--    self._Rdo_Check_No:SetActive(true)
--    self._NeedAgree = false
--end

--def.method().ShowNeedAgreeState = function(self)
--    if self._NeedAgree then
--        --self._Rdo_Check_Yes:SetActive(true)
--        --self._Rdo_Check_No:SetActive(false)
--    else
--        --self._Rdo_Check_Yes:SetActive(false)
--        --self._Rdo_Check_No:SetActive(true)
--    end
--end

------ 点击是否需要审批按钮
--def.method().OnBtnCheck = function(self)
--    self._NeedAgree = not self._NeedAgree
--    --self:ShowNeedAgreeState()
--    GUITools.SetIOSToggleValue(self._Rdo_Check, self._NeedAgree, false)
--end

-- 计算当前创建公会所需货币
def.method().OnSetCreateMoney = function(self)
    local iconId = {}
    iconId[1] = self._Guild_Icon_1[self._List_Item_1._Index].Id
    iconId[2] = self._Guild_Icon_2[self._List_Item_2._Index].Id
    iconId[3] = self._Guild_Icon_3[self._List_Item_3._Index].Id
    game._GuildMan:SetGuildIcon(iconId, self._Guild_Icon_Image)
    local cost1 = self._Guild_Icon_1[self._List_Item_1._Index].CostMoneyNum
    local cost2 = self._Guild_Icon_2[self._List_Item_2._Index].CostMoneyNum
    local cost3 = self._Guild_Icon_3[self._List_Item_3._Index].CostMoneyNum  
    self._Create_Money = self._GuildCreateDiamondCost + cost1 + cost2 + cost3
    local setting = {
        [EnumDef.CommonBtnParam.MoneyCost] = self._Create_Money
    }
    self._Btn_Create:ResetSetting(setting)
--    GUI.SetText(self._Lab_Create_Money, tostring(self._Create_Money))  
end

-- 创建公会
def.method().OnBtnCreateGuild = function(self)
    local name = self._InputField_Name:GetComponent(self._Input_Type).text
    if not NameChecker.CheckGuildNameValid(name) then
        self._InputField_Name:GetComponent(self._Input_Type).text = ""
        return  
    end
    local cb = function(val)
        if val then
            if game._HostPlayer:GetBindDiamonds() < self._Create_Money then
                local callback = function(value)
                    if value then
                        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Create, 0)
                        local protocol = (require "PB.net".C2SGuildCreate)()
                        protocol.createInfo.guildName = name
                        protocol.createInfo.guildIcon.BaseColorID = self._Guild_Icon_1[self._List_Item_1._Index].Id
                        protocol.createInfo.guildIcon.FrameID = self._Guild_Icon_2[self._List_Item_2._Index].Id
                        protocol.createInfo.guildIcon.ImageID = self._Guild_Icon_3[self._List_Item_3._Index].Id
                        protocol.createInfo.FightScore = self._Need_Value
                        protocol.createInfo.NeedAgree = self._Rdo_Check.Value --self._NeedAgree
                        PBHelper.Send(protocol)
                    end
                end
                MsgBox.ShowQuickBuyBox(3, self._Create_Money, callback) 
                return
                --game._GUIMan:ShowTipText(StringTable.Get(813), true)
            else   
                CSoundMan.Instance():Play2DAudio(PATH.GUISound_Create, 0) 
                local protocol = (require "PB.net".C2SGuildCreate)()
                protocol.createInfo.guildName = name
                protocol.createInfo.guildIcon.BaseColorID = self._Guild_Icon_1[self._List_Item_1._Index].Id
                protocol.createInfo.guildIcon.FrameID = self._Guild_Icon_2[self._List_Item_2._Index].Id
                protocol.createInfo.guildIcon.ImageID = self._Guild_Icon_3[self._List_Item_3._Index].Id
                protocol.createInfo.FightScore = self._Need_Value
                protocol.createInfo.NeedAgree = self._Rdo_Check.Value --self._NeedAgree
                PBHelper.Send(protocol)
            end
        end
    end
    local title, msg, closeType = StringTable.GetMsg(122)
    msg = string.format(msg, RichTextTools.GetGuildNameRichText(name, false))
    local setting =
    {
        [MsgBoxAddParam.CostMoneyID] = 3,
        [MsgBoxAddParam.CostMoneyCount] = self._Create_Money,
    }
    MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, cb, nil, nil, MsgBoxPriority.Normal, setting)
end

-- 会长请求援助
def.method().OnGuildBegAid = function(self)
    local linkInfo = {}
    local chatLink = {}
    chatLink.LinkType = require "PB.data".ChatLinkType.ChatLinkType_Guild
    chatLink.ContentID = game._HostPlayer._Guild._GuildID
    linkInfo.ChatLink = chatLink
    linkInfo.Msg = "[l]" .. string.format(StringTable.Get(890), game._HostPlayer._InfoData._Name) .. "[-]"
    linkInfo.chatChannel = require "PB.data".ChatChannel.ChatChannelWorld
    require "Chat.ChatManager".Instance():ChatOtherSend(linkInfo)
end

CPanelUIGuildList.Commit()
return CPanelUIGuildList