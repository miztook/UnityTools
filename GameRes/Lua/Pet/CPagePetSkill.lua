--宠物技能

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetSkill = Lplus.Class("CPagePetSkill")
local def = CPagePetSkill.define

local DynamicText = require "Utility.DynamicText"
local CElementData = require "Data.CElementData"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CPetUtility = require "Pet.CPetUtility"
local CCommonBtn = require "GUI.CCommonBtn"
local CTokenMoneyMan = require "Data.CTokenMoneyMan"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil                   -- 存放UI的集合
def.field("table")._PetData = nil                       -- 当前选中的Pet数据
def.field("table")._CurrentSelectSkillBookData = nil    -- 当前选中技能书
def.field("table")._LocalSkillBookList = BlankTable     -- 本地筛选排序的技能书列表
def.field("boolean")._GfxDelay = false
def.field("number")._SelectSkillIndex = 1
def.field("table")._PetSkillTakeOffCostInfo = BlankTable

local gfxGroupName = "CPagePetSkill"
local gfxGroupName1 = "CPagePetSkill1"

local listQuality = 
{   
    0, -- 普通
    1, -- 高级
    2, -- 稀有
    3, -- 史诗
    5, -- 传说
    6, -- 起源
}
local function SendFlashMsg(msg)
    game._GUIMan:ShowTipText(msg, false)
end

local instance = nil
def.static("table", "userdata", "=>", CPagePetSkill).new = function(parent, panel)
    if instance == nil then
        instance = CPagePetSkill()
        instance._Parent = parent
        instance._Panel = panel
    end
    
    return instance
end

def.method().InitPanel = function(self)
    local MaxSkillCount = CPetUtility.GetMaxSkillCount()         --技能最大个数
    self._PetSkillTakeOffCostInfo = CPetUtility.GetPetSkillTakeOffCostInfo()

    self._PanelObject = {
        SkillList = {},
        Group_SkillBook = {},
        BtnSkillLearn = self._Parent:GetUIObject('Btn_SkillLearn'),
        Btn_Replace = self._Parent:GetUIObject('Btn_Replace'),
        Btn_FuncGroup = self._Parent:GetUIObject('Btn_FuncGroup'),
        Btn_TaleDown = self._Parent:GetUIObject("Btn_TaleDown"),
    }

    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(11108),
        [EnumDef.CommonBtnParam.MoneyID] = self._PetSkillTakeOffCostInfo[1][1],
        [EnumDef.CommonBtnParam.MoneyCost] = 0   
    }
    self._PanelObject.CommonBtn_TaleDown = CCommonBtn.new(self._PanelObject.Btn_TaleDown ,setting)

    --技能
    for i=1, MaxSkillCount do
        local skill = {}
        skill.Root = self._Parent:GetUIObject('Frame_Skill_Skill'..i)
        skill.Lab_SkilName = skill.Root:FindChild("Lab_SkilName")
        skill.ItemSkill = skill.Root:FindChild("ItemSkill")
        skill.Img_Quality = skill.ItemSkill:FindChild("Img_Quality")
        skill.Img_ItemIcon = skill.ItemSkill:FindChild("Img_ItemIcon")
        skill.Img_Lock = skill.ItemSkill:FindChild("Img_Lock")
        skill.Lab_Lock = skill.ItemSkill:FindChild("Lab_Lock")
        skill.Img_Select = skill.ItemSkill:FindChild("Img_Select")
        table.insert(self._PanelObject.SkillList, skill)
    end

    do
        local root = self._PanelObject.Group_SkillBook
        root.Root = self._Parent:GetUIObject("Group_SkillBook")
        root.GfxHook = root.Root:FindChild("SelectItemGroup/GfxHook")
        root.SelectSkillBook = self._Parent:GetUIObject("SelectSkillBook")
        root.Img_ItemIcon = root.SelectSkillBook:FindChild("Img_ItemIcon")
        root.Img_Quality = root.SelectSkillBook:FindChild("Img_Quality")
        root.Img_QualityBG = root.SelectSkillBook:FindChild("Img_QualityBG")
        root.Btn_Drop_SkillBook = self._Parent:GetUIObject("Btn_Drop_SkillBook")
        root.Btn_AddSkillBook = self._Parent:GetUIObject("Btn_AddSkillBook")
    end

    -- self:ResetSkillBookInfo()
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end

    if EPetOptType.EPetOptType_talent == event._Type then
        instance:GfxResetSkillBookInfo()
        instance:UpdatePanel()
    end
end

def.method("table").UpdateSelectPet = function(self, data)
    self._Panel:SetActive(data ~= nil)

    self._PetData = data
    if self._PetData == nil then return end
    
    self:UpdatePanel()
end

def.method().GfxResetSkillBookInfo = function(self)
    local function reset()
        instance:ResetSkillBookInfo()
    end

    self._GfxDelay = true
    self._Parent:KillEvts(gfxGroupName)
    self._Parent:AddEvt_LuaCB(gfxGroupName, 0.3, reset)
end

def.method().ResetSkillBookInfo = function(self)
    self._CurrentSelectSkillBookData = nil
    self._LocalSkillBookList = {}
    self._GfxDelay = false

    local info = self._PanelObject
    if info == nil then return end

    info.Group_SkillBook.Img_ItemIcon:SetActive(false)
    info.Group_SkillBook.Img_Quality:SetActive(false)
    info.Group_SkillBook.Img_QualityBG:SetActive(false)
    info.Group_SkillBook.Btn_Drop_SkillBook:SetActive(false)
    info.Group_SkillBook.Btn_AddSkillBook:SetActive(true)
    GUITools.SetBtnGray(info.BtnSkillLearn, true)
    GUITools.SetBtnGray(info.Btn_Replace, true)
end

def.method().UpdateSkill = function(self)
    --技能
    local MaxSkillCount = CPetUtility.GetMaxSkillCount()            --技能最大个数
    local takedownIndex = self._PetData:GetLastTakedownIndex()      --上次拆除技能Index
    local PetSkillUnlockInfo = CPetUtility.GetPetSkillUnlockInfo()        --技能解锁等级

    local root = self._PanelObject.SkillList
    for i=1, MaxSkillCount do
        local skillInfo = self._PetData._SkillList[i]
        local UIInfo = root[i]

        local bSkillOpen = (skillInfo ~= nil)
        local bGotSkill = (bSkillOpen and skillInfo.ID > 0)

        UIInfo.Img_Lock:SetActive( not bSkillOpen )
        UIInfo.Lab_Lock:SetActive( not bSkillOpen )
        UIInfo.Lab_SkilName:SetActive(bGotSkill)
        UIInfo.Img_ItemIcon:SetActive(bGotSkill)
        UIInfo.Img_ItemIcon:SetActive(bGotSkill)
        UIInfo.Img_Quality:SetActive(false)
        UIInfo.Img_Select:SetActive(self._SelectSkillIndex == i)

        if not bSkillOpen then
            GUI.SetText(UIInfo.Lab_Lock, string.format(StringTable.Get(10714), PetSkillUnlockInfo[i-1]))
        end

        if bGotSkill then
            GUITools.SetIcon(UIInfo.Img_ItemIcon, skillInfo.IconPath)
            local TalentData = CElementData.GetTemplate("Talent", skillInfo.ID)
            if TalentData then
                local lv = skillInfo.Level
                local BackItemList = {}
                local ids = string.split(TalentData.ItemTIds, "*")
                for i,v in ipairs(ids) do
                    local tid = tonumber(v)
                    table.insert(BackItemList, tid)
                end
                if BackItemList[lv] == nil then
                    warn("Error:Data is Null, SKill BackItemList SkillID, Lv = ", skillInfo.ID, lv)
                    return
                end
                local itemTemp = CElementData.GetTemplate("Item", BackItemList[lv])
                local strName = RichTextTools.GetQualityText(skillInfo.Name, itemTemp.InitQuality)
                GUI.SetText(UIInfo.Lab_SkilName, string.format(StringTable.Get(19092), strName, lv))
                -- local strLv = ExchangeNum2Chinese(skillInfo.Level)
                -- GUI.SetText(UIInfo.Lab_SkilName, string.format(StringTable.Get(19089), strLv, strName))
                GUITools.SetGroupImg(UIInfo.Img_Quality, TalentData.InitQuality)
            end
        end

        if takedownIndex == i then
            GameUtil.PlayUISfx(PATH.UIFX_Pet_TakeOff, UIInfo.Root, UIInfo.Root, -1)
        end
    end
end

def.method("number").UpdateSelectSkillIndex = function(self, index)
    if self._SelectSkillIndex == index then return end
    if self._PetData._SkillList[index] == nil then return end

    local root = self._PanelObject.SkillList
    local oldUIInfo = root[self._SelectSkillIndex]
    local newUIInfo = root[index]
    oldUIInfo.Img_Select:SetActive(false)
    newUIInfo.Img_Select:SetActive(true)

    self._SelectSkillIndex = index
end

def.method().UpdateButtonState = function(self)
    local bHasSkill = self._PetData._SkillList[self._SelectSkillIndex] ~= nil and
                      self._PetData._SkillList[self._SelectSkillIndex].ID > 0

    local root = self._PanelObject
    root.Btn_FuncGroup:SetActive( bHasSkill )
    root.BtnSkillLearn:SetActive( not bHasSkill )

    if bHasSkill then
        local lv = self._PetData._SkillList[self._SelectSkillIndex].Level
        local moneyNeed = self._PetSkillTakeOffCostInfo[lv][2]
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = moneyNeed   
        }
        root.CommonBtn_TaleDown:ResetSetting(setting)
    end
end

def.method("dynamic").SelectSkillBook = function(self, bookItem)
    local root = self._PanelObject.Group_SkillBook
    root.Img_ItemIcon:SetActive(true)
    root.Img_Quality:SetActive(true)
    root.Img_QualityBG:SetActive(true)
    
    GUITools.SetIcon(root.Img_ItemIcon, bookItem._IconAtlasPath)
    GUITools.SetGroupImg(root.Img_Quality, bookItem._Quality)
    GUITools.SetGroupImg(root.Img_QualityBG, bookItem._Quality)
end

local function OnInitItem(self, item, data)
    local Frame_SkillbookInfo = item:FindChild("Frame_SkillbookInfo")
    local Frame_PetInfo = item:FindChild("Frame_PetInfo")
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    local Frame_PetIcon = item:FindChild("Btn_Icon/PetIcon")
    local Frame_ItemIcon = item:FindChild("Btn_Icon/ItemIconNew")

    local root = Frame_SkillbookInfo

    Frame_SkillbookInfo:SetActive(true)
    Frame_PetInfo:SetActive(false)
    Frame_PetIcon:SetActive(false)
    Frame_ItemIcon:SetActive(true)

    local bHasSkillCell = self._PetData._SkillList[self._SelectSkillIndex].ID > 0
    local skillId = tonumber(data._Template.Type1Param1)
    local skillLv = tonumber(data._Template.Type1Param2)

    local bUnableClick = true
    if bHasSkillCell then
        bUnableClick = self._PetData:HasLearnedSkillByIdAndLevel(skillId, skillLv)
    else
        bUnableClick = self._PetData:HasLearnedSkillById(skillId)
    end
    Img_UnableClick:SetActive(bUnableClick)

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    local count = data:GetCount()
    
    local setting =
    {
        [EItemIconTag.Number] = count,
    }
    IconTools.InitItemIconNew(Frame_ItemIcon, data._Tid, setting)

    local itemTemp = CElementData.GetItemTemplate(data._Tid)
    if itemTemp ~= nil then
        local Lab_ItemName = root:FindChild("Lab_ItemName")
        local Lab_TalentName = root:FindChild("Lab_TalentName")
        local lv = tonumber(itemTemp.Type1Param2)
        local skillId = tonumber(itemTemp.Type1Param1)
        local name = RichTextTools.GetQualityText(itemTemp.TextDisplayName, itemTemp.InitQuality)
        local skillCommonInfo = CElementData.GetSkillInfoByIdAndLevel(skillId, lv, true)
        local skillInfo = DynamicText.GetParseSkillDescTextKeyValue(skillId, lv, true)
        local value = fmtVal2Str(skillInfo.Integer[1].Value)

        local strTalentName = string.format(StringTable.Get(10979), skillCommonInfo.PropertyName, value)
        GUI.SetText(Lab_TalentName, strTalentName)
        GUI.SetText(Lab_ItemName, name)
    end
end

local function OnSelectItem(self, item, data, bIsConfirm)
    local bHasSkillCell = self._PetData._SkillList[self._SelectSkillIndex].ID > 0
    local skillId = tonumber(data._Template.Type1Param1)
    local skillLv = tonumber(data._Template.Type1Param2)

    local bUnableClick = true
    if bHasSkillCell then
        bUnableClick = self._PetData:HasLearnedSkillByIdAndLevel(skillId, skillLv)
    else
        bUnableClick = self._PetData:HasLearnedSkillById(skillId)
    end

    if bUnableClick then
        SendFlashMsg(StringTable.Get(19085))
        return false
    end

    if self._CurrentSelectSkillBookData == data then return false end

    if bIsConfirm then
        self:SelectSkillBook(data)

        local Group_SkillBook = self._PanelObject.Group_SkillBook
        Group_SkillBook.Btn_AddSkillBook:SetActive(false)
        Group_SkillBook.Btn_Drop_SkillBook:SetActive(true)

        self._CurrentSelectSkillBookData = data

        local info = self._PanelObject
        GUITools.SetBtnGray(info.BtnSkillLearn, false)
        GUITools.SetBtnGray(info.Btn_Replace, false)
        -- GameUtil.SetButtonInteractable(info.BtnSkillLearn, true)
    end

    return true
end

local function conditionFunc(self, index)
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    self._LocalSkillBookList = {}

    local quality = self:ExchangePetQualityByIndex(index-1)

    for i=1, #pack._ItemSet do
        local item = pack._ItemSet[i]

        if item:IsPetTalentBook() then
            if quality == -1 then
                self._LocalSkillBookList[#self._LocalSkillBookList+1] = item
            elseif item:GetQuality() == quality then
                self._LocalSkillBookList[#self._LocalSkillBookList+1] = item
            end
        end
    end

    --按品质排序
    local function sortFunc(a, b)
        if self._PetData:HasLearnedSkillByIdAndLevel(tonumber(a._Template.Type1Param1), tonumber(a._Template.Type1Param2)) ~= 
           self._PetData:HasLearnedSkillByIdAndLevel(tonumber(b._Template.Type1Param1), tonumber(b._Template.Type1Param2)) then
            return not self._PetData:HasLearnedSkillByIdAndLevel(tonumber(a._Template.Type1Param1), a._Template.Type1Param2) 
        end

        return a._Quality > b._Quality
    end
    table.sort(self._LocalSkillBookList, sortFunc)

    if #self._LocalSkillBookList > 0 then
        return self._LocalSkillBookList
    else
        return StringTable.Get(10938)
    end
end

def.method("=>", "table").GetQualityGroup = function(self)
    local retTable = {}
    local str = StringTable.Get(10010)

    table.insert(retTable, str)
    for _, v in ipairs(listQuality) do
        local _str = RichTextTools.GetQualityText(StringTable.Get(10000 + v), v)
        table.insert(retTable, _str)
    end

    return retTable
end

def.method('number', '=>', 'number').ExchangePetQualityByIndex = function(self, index)
    return listQuality[index] or -1
end

def.method().ShowUIItemList = function(self)
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    self._LocalSkillBookList = {}

    for i=1, #pack._ItemSet do
        local item = pack._ItemSet[i]

        if item:IsPetTalentBook() then
            self._LocalSkillBookList[#self._LocalSkillBookList+1] = item
        end
    end

    --按品质排序
    local function sortFunc(a, b)
        if self._PetData:HasLearnedSkillByIdAndLevel(tonumber(a._Template.Type1Param1), tonumber(a._Template.Type1Param2)) ~=
           self._PetData:HasLearnedSkillByIdAndLevel(tonumber(b._Template.Type1Param1), tonumber(b._Template.Type1Param2)) then
            return not self._PetData:HasLearnedSkillByIdAndLevel(tonumber(a._Template.Type1Param1), tonumber(a._Template.Type1Param2)) 
        end

        return a._Quality > b._Quality
    end
    table.sort(self._LocalSkillBookList, sortFunc)

    _G.ItemListMan.ShowItemListManPanel(self,
                                        self._LocalSkillBookList, 
                                        OnInitItem, 
                                        OnSelectItem, 
                                        _G.ShowTipType.ShowItemTip, 
                                        conditionFunc, 
                                        self:GetQualityGroup(), 
                                        EnumDef.ApproachMaterialType.PetSkillBook)
end

def.method().UpdatePanel = function(self)
    self:ResetSkillBookInfo()
    self:UpdateSkill()
    self:PlayRedDotGfx( self:CalcRedDotState() )
    self:UpdateButtonState()
end

def.method("dynamic").Show = function(self, data)
    if self._PanelObject == nil then
        self:InitPanel()
    end
    self._SelectSkillIndex = 1
    self._Panel:SetActive(data ~= nil)

    if data ~= nil then
        self:UpdateSelectPet(data)
    end

    CGame.EventManager:addHandler(PetUpdateEvent, OnPetUpdateEvent)
end

def.method("number").ShowSkillTips = function(self, index)
    if self._PetData._SkillList[index] ~= nil then
        if self._PetData._SkillList[index].ID > 0 then
            local panelData = 
            {
                _TalentID = self._PetData._SkillList[index].ID,
                _TalentLevel = self._PetData._SkillList[index].Level,
                _TipPos = TipPosition.FIX_POSITION,
                _TargetObj = self._PanelObject.SkillList[index].Root,
            }

            CItemTipMan.ShowPetSkillTips(panelData)
        end
    end
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_AddSkillBook" then
        self:ShowUIItemList()
    elseif id == "Btn_SkillLearn" or id == "Btn_Replace" then
        if self:CheckCanLearnSkill() == false then return end
        local root = self._PanelObject.Group_SkillBook

        local function callback(ret)
            if ret then
                CPetUtility.SendC2SPetLearnTalent(self._PetData._ID, self._CurrentSelectSkillBookData._Tid, self._SelectSkillIndex - 1)
                GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, root.GfxHook, root.GfxHook, 1, 20, 1)
            end
        end
        local skillInfo = self._PetData._SkillList[self._SelectSkillIndex]

        if skillInfo.ID > 0 then
            local param = {}
            local itemTemplate = CElementData.GetTemplate("Item", self._CurrentSelectSkillBookData._Tid)
            local skillId = tonumber(itemTemplate.Type1Param1)
            local skillLv = tonumber(itemTemplate.Type1Param2)

            param.Old = {ID = skillInfo.ID, Level = skillInfo.Level}
            param.New = {ID = skillId, Level = skillLv}
            param.Callback = callback

            game._GUIMan:Open("CPanelUIPetSkillReplace", param)
        else
            callback(true)
        end
    elseif id == "Btn_TaleDown" then
        local skillInfo = self._PetData._SkillList[self._SelectSkillIndex]
        local lv = skillInfo.Level
        local moneyNeed = self._PetSkillTakeOffCostInfo[lv][2]
        local moneyId = self._PetSkillTakeOffCostInfo[lv][1]

        local function Do( ret )
            if ret then
                CPetUtility.SendC2SPetTakedownTalent(self._PetData._ID, self._SelectSkillIndex - 1)
            end
        end
        local function Callback( ret )
            if ret then
                MsgBox.ShowQuickBuyBox(moneyId, moneyNeed, Do)
            end
        end

        local TalentData = CElementData.GetTemplate("Talent", skillInfo.ID)
        local strName = ""
        if TalentData then
            local BackItemList = {}
            local ids = string.split(TalentData.ItemTIds, "*")
            for i,v in ipairs(ids) do
                local tid = tonumber(v)
                table.insert(BackItemList, tid)
            end
            if BackItemList[lv] == nil then
                warn("Error:Data is Null, SKill BackItemList SkillID, Lv = ", skillInfo.ID, lv)
                return
            end
            local itemTemp = CElementData.GetTemplate("Item", BackItemList[lv])
            strName = RichTextTools.GetQualityText(skillInfo.Name, itemTemp.InitQuality)
            strName = string.format(StringTable.Get(19092), strName, lv)
        end

        local title, msg, closeType = StringTable.GetMsg(139)
        local moneyName = CTokenMoneyMan.Instance():GetEmoji(moneyId)
        msg = string.format(msg, moneyName, moneyNeed, strName)

        local setting = {
            [MsgBoxAddParam.CostMoneyID] = moneyId,
            [MsgBoxAddParam.CostMoneyCount] = moneyNeed,
        }
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, Do, nil, nil, MsgBoxPriority.Normal, setting)
        
    elseif string.find(id, "Frame_Skill_Skill") then
        local index = tonumber(string.sub(id,-1))
        local PetSkillUnlockInfo = CPetUtility.GetPetSkillUnlockInfo()        --技能解锁等级

        local skillInfo = self._PetData._SkillList[index]
        local bSkillOpen = (skillInfo ~= nil)
        if not bSkillOpen then
            local msg = string.format(StringTable.Get(19062), PetSkillUnlockInfo[index-1])
            SendFlashMsg(msg, false)
            return
        end

        self:UpdateSelectSkillIndex(index)
        self:UpdateButtonState()
    elseif id == "Btn_Drop_SkillBook" then
        self:ResetSkillBookInfo()
    end
end

def.method("string").OnPointerLongPress = function(self, id)
    if string.find(id, "Frame_Skill_Skill") > 0 then
        local index = tonumber( string.sub(id, -1) )
        self:ShowSkillTips(index)
    end
end

def.method("=>", "boolean").CheckCanLearnSkill = function(self)
     if self._CurrentSelectSkillBookData == nil then
        --没有可以用于学习的宠物技能书
        SendFlashMsg(StringTable.Get(19071))
        return false
    end

    local bHasSkillCell = self._PetData._SkillList[self._SelectSkillIndex].ID > 0

    local itemTemplate = CElementData.GetTemplate("Item", self._CurrentSelectSkillBookData._Tid)
    local skillId = tonumber(itemTemplate.Type1Param1)
    local skillLv = tonumber(itemTemplate.Type1Param2)

    local bUnableClick = true
    if bHasSkillCell then
        bUnableClick = self._PetData:HasLearnedSkillByIdAndLevel(skillId, skillLv)
    else
        bUnableClick = self._PetData:HasLearnedSkillById(skillId)
    end
    
    if bUnableClick then
        SendFlashMsg(StringTable.Get(19083))
        return false
    end

    return true
end

-- 计算技能学习红点状态
def.method('=>', 'boolean').CalcRedDotState = function(self)
    if self._PetData == nil then return false end
    local bShowDot = CPetUtility.CalcPetSkillCellRedDotState(self._PetData)

    return (self._CurrentSelectSkillBookData == nil and bShowDot)
end

def.method("boolean").PlayRedDotGfx = function(self, bShow)
    local obj = self._PanelObject.Group_SkillBook.RedDot
    if obj == nil then return end

    if bShow then
        GameUtil.PlayUISfx(PATH.UI_tongyong_tianjia_tishi, obj, obj, -1)
    else
        GameUtil.StopUISfx(PATH.UI_tongyong_tianjia_tishi, obj)
    end
end

def.method().PlaySkillLeanGfx = function(self)
    if self._PetData == nil then return end

    local index = self._PetData:GetInsteadSkillIndex()
    local root = self._PanelObject.SkillList
    local UIInfo = root[index]
    GameUtil.PlayUISfx(PATH.UI_jinengshengji, UIInfo.Img_ItemIcon, UIInfo.Img_ItemIcon, 1)
    -- local function DoGfx()
    --     if UIInfo ~= nil then
    --         GameUtil.PlayUISfx(PATH.UI_jinengshengji, UIInfo.Img_ItemIcon, UIInfo.Img_ItemIcon, 1)
    --     end
    -- end

    -- self._Parent:KillEvts(gfxGroupName1)
    -- self._Parent:AddEvt_LuaCB(gfxGroupName1, 0.1, DoGfx)
end

def.method().Hide = function(self)
    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)

    self._Panel:SetActive(false)
    self._PanelObject = nil
    self._PetData = nil
    self._CurrentSelectSkillBookData = nil
    self._GfxDelay = false
end

def.method().Destroy = function (self)
    if self._PanelObject ~= nil then
        if self._PanelObject.CommonBtn_TaleDown ~= nil then
            self._PanelObject.CommonBtn_TaleDown:Destroy()
        end

        self._PanelObject = nil
    end

    instance = nil
end

CPagePetSkill.Commit()
return CPagePetSkill