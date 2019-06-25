local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local NameChecker = require "Utility.NameChecker"
local CPageGuildSet = Lplus.Class("CPageGuildSet")
local def = CPageGuildSet.define

-- 旗帜数据
def.field("table")._Guild_Icon_1 = BlankTable
def.field("table")._List_Item_1 = BlankTable
def.field("table")._Guild_Icon_2 = BlankTable
def.field("table")._List_Item_2 = BlankTable
def.field("table")._Guild_Icon_3 = BlankTable
def.field("table")._List_Item_3 = BlankTable

def.field("table")._Parent = nil
def.field("userdata")._FrameRoot = nil

def.field("number")._TotalCostMoney = 0
def.field("number")._NeedScore = 0

def.field("userdata")._Group_List_1 = nil
def.field("userdata")._Group_List_2 = nil
def.field("userdata")._Group_List_3 = nil

def.field("table")._Guild_Icon_Image = BlankTable
def.field("userdata")._InputField_Name = nil

def.field("userdata")._Rdo_Check = nil  
def.field("userdata")._Img_Money = nil
def.field("userdata")._Lab_Set_Money = nil
def.field("userdata")._Img_Lock8 = nil
def.field("userdata")._Lab_Count = nil
def.field("userdata")._Btn_Plus = nil
def.field("userdata")._Btn_Minus = nil
def.field("userdata")._Frame_Toggle = nil

def.static("table", "userdata", "=>", CPageGuildSet).new = function(parent, frame)
	local obj = CPageGuildSet()
	obj._Parent = parent
	obj._FrameRoot = frame
	return obj
end

-- 展示时调用
def.method().Show = function(self)
    self._FrameRoot:SetActive(true)
    self:InitConfig()
    self:InitUIObject()
    self:Update()
end

-- 初始化UIObject
def.method().InitUIObject = function(self)
    if #self._Guild_Icon_Image > 0 then return end

	local parent = self._Parent
    local img_Set_Flag = parent:GetUIObject("Set_Img_Flag")
    self._Guild_Icon_Image[1] = img_Set_Flag:FindChild("Set_Img_Flag_BG")
    self._Guild_Icon_Image[2] = img_Set_Flag:FindChild("Set_Img_Flag_Flower_1")
    self._Guild_Icon_Image[3] = img_Set_Flag:FindChild("Set_Img_Flag_Flower_2")
    self._InputField_Name = parent:GetUIObject("InputField_Name"):GetComponent(ClassType.InputField)


    self._Frame_Toggle = parent:GetUIObject("Rdo_Check")
	self._Rdo_Check = self._Frame_Toggle:GetComponent(ClassType.GNewIOSToggle)
    GameUtil.RegisterUIEventHandler(parent._Panel, self._Frame_Toggle, ClassType.GNewIOSToggle)

    self._Img_Money = parent:GetUIObject("Img_Money")
    self._Lab_Set_Money = parent:GetUIObject("Lab_Set_Money")
    self._Img_Lock8 = parent:GetUIObject("Img_Lock8")

    local List_Type = ClassType.GNewList
    self._Group_List_1 = parent:GetUIObject("Group_List_1"):GetComponent(List_Type)
    self._Group_List_2 = parent:GetUIObject("Group_List_2"):GetComponent(List_Type)
    self._Group_List_3 = parent:GetUIObject("Group_List_3"):GetComponent(List_Type)
    self._Lab_Count = parent:GetUIObject("Lab_Count")
    self._Btn_Plus = parent:GetUIObject("Btn_Plus_Score")
    self._Btn_Minus = parent:GetUIObject("Btn_Minus_Score")
end

-- 初始化信息
def.method().InitConfig = function(self)
    if #self._Guild_Icon_1 > 0 then return end
    self._NeedScore = game._HostPlayer._Guild._AddLimit._BattlePower or 0
    local allTid = GameUtil.GetAllTid("GuildIcon")
    self._Guild_Icon_1 = {}
    self._Guild_Icon_2 = {}
    self._Guild_Icon_3 = {}
    for i = 1, #allTid do
        local guildIcon = CElementData.GetTemplate("GuildIcon", allTid[i])
        if guildIcon.Type == 1 then
            local index = #self._Guild_Icon_1 + 1
            self._Guild_Icon_1[index] = {}
            self._Guild_Icon_1[index]._Icon = guildIcon
        elseif guildIcon.Type == 2 then
            local index = #self._Guild_Icon_2 + 1
            self._Guild_Icon_2[index] = {}
            self._Guild_Icon_2[index]._Icon = guildIcon
        elseif guildIcon.Type == 3 then
            local index = #self._Guild_Icon_3 + 1
            self._Guild_Icon_3[index] = {}
            self._Guild_Icon_3[index]._Icon = guildIcon
        end
    end
end

-- 初始化信息
def.method().Update = function(self)
    GUITools.SetTokenMoneyIcon(self._Img_Money, 3)
    local _Guild = game._HostPlayer._Guild
    self._InputField_Name.text = _Guild._GuildName
    self._Rdo_Check.Value = _Guild._NeedAgree
    self._Img_Lock8:SetActive(true)
    self._InputField_Name.text = _Guild._GuildName
    self._Group_List_1:SetItemCount(#self._Guild_Icon_1)
    self._Group_List_2:SetItemCount(#self._Guild_Icon_2)
    self._Group_List_3:SetItemCount(#self._Guild_Icon_3)

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

    self:UpdateInputState()
    self:UpdateCostMoney()
end

def.method().UpdatePageRedPoint = function(self)
end

-- 公会旗帜显示
def.method("userdata", "number").InitGroupList1 = function(self, item, index)
    local guildIcon = self._Guild_Icon_1[index]._Icon
    local _Guild = game._HostPlayer._Guild
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local ImgU = uiTemplate:GetControl(6)
    local ImgUseBg = uiTemplate:GetControl(4)
    local ImgD = uiTemplate:GetControl(1)
    local ImgLockBg = uiTemplate:GetControl(2)
    local LabCost = uiTemplate:GetControl(7)
    if guildIcon.Id == _Guild._GuildIconInfo._BaseColorID then
        ImgU:SetActive(true)
        self._List_Item_1._Item = item
        self._List_Item_1._Index = index
        ImgUseBg:SetActive(true)
    else
        ImgUseBg:SetActive(false)
    end
    local lock = true
    if guildIcon.CostMoneyNum == 0 then
        lock = false
    else
        if guildIcon.CostMoneyNum > 0 then
            for i = 1, #_Guild._IconList do
                if guildIcon.Id == _Guild._IconList[i] then
                    lock = false
                end
            end
        end
    end
    self._Guild_Icon_1[index]._Lock = lock
    if lock then
        ImgLockBg:SetActive(true)
        GUI.SetText(LabCost,tostring(guildIcon.CostMoneyNum))
    else
        ImgLockBg:SetActive(false) 
    end
    GameUtil.SetImageColor(ImgD, guildIcon.ColorValue)
end

def.method("userdata", "number").InitGroupList2 = function(self, item, index)
    local guildIcon = self._Guild_Icon_2[index]._Icon
    local _Guild = game._HostPlayer._Guild
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local ImgU = uiTemplate:GetControl(6)
    local ImgUseBg = uiTemplate:GetControl(4)
    local ImgD = uiTemplate:GetControl(1)
    local ImgLockBg = uiTemplate:GetControl(2)
    local LabCost = uiTemplate:GetControl(7)
    if guildIcon.Id == _Guild._GuildIconInfo._FrameID then
        ImgU:SetActive(true)
        self._List_Item_2._Item = item
        self._List_Item_2._Index = index
        ImgUseBg:SetActive(true)
    else
        ImgUseBg:SetActive(false)
    end
    local lock = true
    if guildIcon.CostMoneyNum == 0 then
        lock = false
    else
        if guildIcon.CostMoneyNum > 0 then
            for i = 1, #_Guild._IconList do
                if guildIcon.Id == _Guild._IconList[i] then
                    lock = false
                end
            end
        end
    end
    self._Guild_Icon_2[index]._Lock = lock
    if lock then
        ImgLockBg:SetActive(true)
        GUI.SetText(LabCost,tostring(guildIcon.CostMoneyNum))
    else
        ImgLockBg:SetActive(false) 
    end
    GUITools.SetGuildIcon(ImgD, guildIcon.IconPath)  
end

def.method("userdata", "number").InitGroupList3 = function(self, item, index)
    local guildIcon = self._Guild_Icon_3[index]._Icon
    local _Guild = game._HostPlayer._Guild
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local ImgU = uiTemplate:GetControl(6)
    local ImgUseBg = uiTemplate:GetControl(4)
    local ImgD = uiTemplate:GetControl(1)
    local ImgLockBg = uiTemplate:GetControl(2)
    local LabCost = uiTemplate:GetControl(7)
    if guildIcon.Id == _Guild._GuildIconInfo._ImageID then
        ImgU:SetActive(true)
        self._List_Item_3._Item = item
        self._List_Item_3._Index = index
        ImgUseBg:SetActive(true)
    else
        ImgUseBg:SetActive(false)
    end
    local lock = true 
    if guildIcon.CostMoneyNum == 0 then
        lock = false
    else
        if guildIcon.CostMoneyNum > 0 then
            for i = 1, #_Guild._IconList do
                if guildIcon.Id == _Guild._IconList[i] then
                    lock = false
                end
            end
        end
    end
    self._Guild_Icon_3[index]._Lock = lock
    if lock then
        ImgLockBg:SetActive(true)
        GUI.SetText(LabCost,tostring(guildIcon.CostMoneyNum))
    else
        ImgLockBg:SetActive(false) 
    end
    GUITools.SetGuildIcon(ImgD, guildIcon.IconPath)
end


def.method().OnBtnPlusScore = function(self)
    self._NeedScore = self._NeedScore + 1
    self._NeedScore = math.min(self._NeedScore, GlobalDefinition.MaxFightScoreNum)
    self:UpdateInputState()
end

def.method().OnBtnMinusScore = function(self)
    self._NeedScore = self._NeedScore - 1
    self._NeedScore = math.max(self._NeedScore, 0)
    self:UpdateInputState()
end

-- 当点击
def.method("string").OnClick = function(self, id)
	if id == "Btn_Rename_Guild" then

    elseif id == "Btn_NumInput" then
		local cb = function(count)
            local real_count = (count or 0)
            self._NeedScore = math.max(real_count, 0)
            self._NeedScore = math.min(self._NeedScore, GlobalDefinition.MaxFightScoreNum)
            self:UpdateInputState()
        end
        game._GUIMan:OpenNumberKeyboard(self._Lab_Count, nil, 0, GlobalDefinition.MaxFightScoreNum, cb, nil)
	elseif id == "Btn_Plus_Score" then
		self:OnBtnPlusScore()
    elseif id == "Btn_Minus_Score" then
        self:OnBtnMinusScore()
	elseif id == "Btn_Save_Setting" then
        local callback = function(val)
            if val then
        		self:SaveSettings()
            end
        end
        local title, msg, closeType = StringTable.GetMsg(119)
        local setting = {
            [MsgBoxAddParam.CostMoneyID] = 3,
            [MsgBoxAddParam.CostMoneyCount] = self._TotalCostMoney,
        }
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback, nil, nil, MsgBoxPriority.Normal, setting)   
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
	end
    self:Refresh()
end


-- 当输入框有变化
def.method("string", "string").OnValueChanged = function(self, id, str)
    if id == "InputField_Name" then
        local ret = NameChecker.SubGuildName(str)
        if ret ~= str then
            self._InputField_Name.text = ret
        end
        self:UpdateCostMoney()
    end
    self:Refresh() 
end

-- 当输入框结束操作
def.method("string", "string").OnEndEdit = function(self, id, str)
    if id == "InputField_Name" then
        self:UpdateCostMoney()
    end
    self:Refresh()
end

-- 初始化列表
def.method("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    index = index + 1
    if id == "Group_List_1" then
        self:InitGroupList1(item, index)
    elseif id == "Group_List_2" then
        self:InitGroupList2(item, index)
    elseif id == "Group_List_3" then
        self:InitGroupList3(item, index)
    end
end

-- 选中列表
def.method("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    if id == "Group_List_1" then
        self._List_Item_1._Item:FindChild("Img_U"):SetActive(false)
        self._List_Item_1._Item = item 
        self._List_Item_1._Index = index + 1
        item:FindChild("Img_U"):SetActive(true)
        self:UpdateCostMoney()
        GameUtil.PlayUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2], self._Guild_Icon_Image[2], -1)
    elseif id == "Group_List_2" then
        self._List_Item_2._Item:FindChild("Img_U"):SetActive(false)
        self._List_Item_2._Item = item 
        self._List_Item_2._Index = index + 1
        item:FindChild("Img_U"):SetActive(true)
        self:UpdateCostMoney()
        GameUtil.PlayUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2], self._Guild_Icon_Image[2], -1)
    elseif id == "Group_List_3" then
        self._List_Item_3._Item:FindChild("Img_U"):SetActive(false)
        self._List_Item_3._Item = item 
        self._List_Item_3._Index = index + 1
        item:FindChild("Img_U"):SetActive(true)
        self:UpdateCostMoney()
        GameUtil.PlayUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2], self._Guild_Icon_Image[2], -1)
    end
    self:Refresh()
end

-- 假设信息有刷新，保存按钮高亮
def.method().Refresh = function(self)
    local flag = true
    local guild = game._HostPlayer._Guild
    if self._InputField_Name.text ~= guild._GuildName then
        flag = false
    end
    --if tonumber(self._Lab19_Type.text) ~= guild._AddLimit._BattlePower then
    --    flag = false
    --end
    if self._Rdo_Check.Value ~= guild._NeedAgree then
        flag = false
    end
    if self._Guild_Icon_1[self._List_Item_1._Index]._Icon.Id ~= guild._GuildIconInfo._BaseColorID then
        flag = false
    end
    if self._Guild_Icon_2[self._List_Item_2._Index]._Icon.Id ~= guild._GuildIconInfo._FrameID then
        flag = false
    end
    if self._Guild_Icon_3[self._List_Item_3._Index]._Icon.Id ~= guild._GuildIconInfo._ImageID then
        flag = false
    end

    self._Img_Lock8:SetActive(flag)
end

def.method().UpdateInputState = function(self)
    if self._NeedScore <= 0 then
        GUI.SetText(self._Lab_Count, StringTable.Get(8110))
        GameUtil.SetButtonInteractable(self._Btn_Minus, false)
        GUITools.SetBtnGray(self._Btn_Minus, true, true)
--        GUITools.SetGroupImg(self._Btn_Minus:FindChild("Img_BG"), 1)
    else
        GUI.SetText(self._Lab_Count, tostring(self._NeedScore))
        GameUtil.SetButtonInteractable(self._Btn_Minus, true)
        --GUITools.SetGroupImg(self._Btn_Minus:FindChild("Img_BG"), 0)
        GUITools.SetBtnGray(self._Btn_Minus, false, true)
    end
    if self._NeedScore >= GlobalDefinition.MaxFightScoreNum then
        GameUtil.SetButtonInteractable(self._Btn_Plus, false)
        --GUITools.SetGroupImg(self._Btn_Plus:FindChild("Img_BG"), 1)
        GUITools.SetBtnGray(self._Btn_Plus, true, true)
    else
        GameUtil.SetButtonInteractable(self._Btn_Plus, true)
        --GUITools.SetGroupImg(self._Btn_Plus:FindChild("Img_BG"), 0)
        GUITools.SetBtnGray(self._Btn_Plus, false, true)
    end
end

-- 计算当前保存信息所需货币
def.method().UpdateCostMoney = function(self)
    local iconId = {}
    iconId[1] = self._Guild_Icon_1[self._List_Item_1._Index]._Icon.Id
    iconId[2] = self._Guild_Icon_2[self._List_Item_2._Index]._Icon.Id
    iconId[3] = self._Guild_Icon_3[self._List_Item_3._Index]._Icon.Id
    game._GuildMan:SetGuildIcon(iconId, self._Guild_Icon_Image)
    local cost1 = 0
    local guildIcon = self._Guild_Icon_1[self._List_Item_1._Index]
    if guildIcon._Lock then
        cost1 = guildIcon._Icon.CostMoneyNum
    end
    local cost2 = 0
    local guildIcon = self._Guild_Icon_2[self._List_Item_2._Index]
    if guildIcon._Lock then
        cost2 = guildIcon._Icon.CostMoneyNum
    end
    local cost3 = 0
    local guildIcon = self._Guild_Icon_3[self._List_Item_3._Index]
    if guildIcon._Lock then
        cost3 = guildIcon._Icon.CostMoneyNum
    end
    local createMoney = 0
    if game._HostPlayer._Guild._GuildName ~= self._InputField_Name.text then
        createMoney = CSpecialIdMan.Get("GuildRenameDiamondCost")
    end
    self._TotalCostMoney = createMoney + cost1 + cost2 + cost3
    GUI.SetText(self._Lab_Set_Money, tostring(self._TotalCostMoney))
end

-- 保存修改
def.method().SaveSettings = function(self)
    local name = self._InputField_Name.text
    if not NameChecker.CheckGuildNameValid(name) then
        self._InputField_Name.text = game._HostPlayer._Guild._GuildName
        return
    end
    if game._HostPlayer:GetBindDiamonds() < self._TotalCostMoney then
        local callback = function(value)
            if value then
                local protocol = (require "PB.net".C2SGuildSetDisplayInfo)()
                protocol.DisplayInfo.AddLimit.battlePower = self._NeedScore
                protocol.DisplayInfo.Name = name
                protocol.DisplayInfo.NeedAgree = self._Rdo_Check.Value --self._NeedAgree
                protocol.DisplayInfo.Icon.BaseColorID = self._Guild_Icon_1[self._List_Item_1._Index]._Icon.Id
                protocol.DisplayInfo.Icon.FrameID = self._Guild_Icon_2[self._List_Item_2._Index]._Icon.Id
                protocol.DisplayInfo.Icon.ImageID = self._Guild_Icon_3[self._List_Item_3._Index]._Icon.Id
                PBHelper.Send(protocol)
            end
        end
        MsgBox.ShowQuickBuyBox(3, self._TotalCostMoney, callback)
        return
    else
        local flag = false
        local _Guild = game._HostPlayer._Guild
        if _Guild._GuildName ~= name then
            flag = true
        end
        if _Guild._GuildIconInfo._BaseColorID ~= self._Guild_Icon_1[self._List_Item_1._Index]._Icon.Id or
            _Guild._GuildIconInfo._FrameID ~= self._Guild_Icon_2[self._List_Item_2._Index]._Icon.Id or
            _Guild._GuildIconInfo._ImageID ~= self._Guild_Icon_3[self._List_Item_3._Index]._Icon.Id then
            flag = true
        end

        if _Guild._AddLimit._BattlePower ~= self._NeedScore then
            flag = true
        end

        if _Guild._NeedAgree ~= self._Rdo_Check.Value then
            flag = true
        end
        if flag then
            local protocol = (require "PB.net".C2SGuildSetDisplayInfo)()
            protocol.DisplayInfo.AddLimit.battlePower = self._NeedScore
            protocol.DisplayInfo.Name = name
            protocol.DisplayInfo.NeedAgree = self._Rdo_Check.Value --self._NeedAgree
            protocol.DisplayInfo.Icon.BaseColorID = self._Guild_Icon_1[self._List_Item_1._Index]._Icon.Id
            protocol.DisplayInfo.Icon.FrameID = self._Guild_Icon_2[self._List_Item_2._Index]._Icon.Id
            protocol.DisplayInfo.Icon.ImageID = self._Guild_Icon_3[self._List_Item_3._Index]._Icon.Id
            PBHelper.Send(protocol)
        else
            game._GUIMan:ShowTipText(StringTable.Get(865), true)
        end
    end
end

-- 隐藏时调用
def.method().Hide = function(self)
    self._TotalCostMoney = 0
    self._FrameRoot:SetActive(false)
    if self._Guild_Icon_Image[2] ~= nil then
        GameUtil.StopUISfx(PATH.UIFX_QiZhiGengHuan, self._Guild_Icon_Image[2])
    end

    if self._List_Item_1._Item then
        self._List_Item_1._Item:FindChild("Img_U"):SetActive(false)
        self._List_Item_1 = {}
    end

    if self._List_Item_2._Item then
        self._List_Item_2._Item:FindChild("Img_U"):SetActive(false)
        self._List_Item_2 = {}
    end

    if self._List_Item_3._Item then
        self._List_Item_3._Item:FindChild("Img_U"):SetActive(false)
        self._List_Item_3 = {}
    end
end

-- 摧毁时调用
def.method().Destroy = function(self)
    
end

CPageGuildSet.Commit()
return CPageGuildSet