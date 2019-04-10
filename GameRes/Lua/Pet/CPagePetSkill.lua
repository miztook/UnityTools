--宠物技能

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetSkill = Lplus.Class("CPagePetSkill")
local def = CPagePetSkill.define

local CElementData = require "Data.CElementData"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CPetUtility = require "Pet.CPetUtility"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil                   -- 存放UI的集合
def.field("table")._PetData = nil                       -- 当前选中的Pet数据
def.field("table")._CurrentSelectSkillBookData = nil    -- 当前选中技能书
def.field("table")._LocalSkillBookList = BlankTable     -- 本地筛选排序的技能书列表
def.field("boolean")._GfxDelay = false

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

    self._PanelObject = {
        SkillList = {},
        Group_SkillBook = {},
        BtnSkillLearn = self._Parent:GetUIObject('Btn_SkillLearn'),
    }

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

    self:ResetSkillBookInfo()
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
    self._Parent:AddEvt_LuaCB(gfxGroupName, 1.2, reset)
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
end

def.method().UpdateSkill = function(self)
    --技能
    local MaxSkillCount = CPetUtility.GetMaxSkillCount()         --技能最大个数

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

        if not bSkillOpen then
            GUI.SetText(UIInfo.Lab_Lock, string.format(StringTable.Get(10714), CElementData.GetSpecialIdTemplate(624).Value * (i - 1)))
        end

        if bGotSkill then
            GUITools.SetIcon(UIInfo.Img_ItemIcon, skillInfo.IconPath)
            local TalentData = CElementData.GetTemplate("Talent", skillInfo.ID)
            if TalentData then
                GUI.SetText(UIInfo.Lab_SkilName, RichTextTools.GetQualityText(skillInfo.Name, TalentData.InitQuality))
                GUITools.SetGroupImg(UIInfo.Img_Quality, TalentData.InitQuality)
            end
        end
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
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    Img_UnableClick:SetActive(self._PetData:HasLearnedSkillById(tonumber(data._Template.Type1Param1)))

    local Group_Stars = item:FindChild("Group_Stars")
    Group_Stars:SetActive(false)

    local Frame_PetIcon = GUITools.GetChild(item, 5)
    Frame_PetIcon:SetActive(false)

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    local count = pack:GetItemCount(data._Tid)
    local Frame_ItemIcon = GUITools.GetChild(item, 1)
    Frame_ItemIcon:SetActive(true)
    local setting =
    {
        [EItemIconTag.Number] = count,
    }
    IconTools.InitItemIconNew(Frame_ItemIcon, data._Tid, setting)

    local Lab_Des = GUITools.GetChild(item, 4)
    local Lab_Fight = GUITools.GetChild(item, 3)
    Lab_Fight:SetActive(false)
    Lab_Des:SetActive(false)

    local itemTemp = CElementData.GetItemTemplate(data._Tid)
    if itemTemp ~= nil then
        local Lab_ItemName = GUITools.GetChild(item, 2)
        local name = RichTextTools.GetQualityText(itemTemp.TextDisplayName, itemTemp.InitQuality)
        local lv = itemTemp.InitLevel
        if lv > 0 then
            local size = GUITools.GetTextSize(Lab_ItemName)
            if size == nil then
                GUI.SetText(Lab_ItemName, name)
            else
                local strLv = string.format(StringTable.Get(19073), lv)
                strLv = GUITools.FormatRichTextSize(size-2, strLv)
                GUI.SetText(Lab_ItemName, name..strLv)
            end
        else
            GUI.SetText(Lab_ItemName, name)
        end
    end
end

local function OnSelectItem(self, item, data, bIsConfirm)
    if self._PetData:HasLearnedSkillById(tonumber(data._Template.Type1Param1)) then
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
        if self._PetData:HasLearnedSkillById(tonumber(a._Template.Type1Param1)) ~= self._PetData:HasLearnedSkillById(tonumber(b._Template.Type1Param1)) then
            return not self._PetData:HasLearnedSkillById(tonumber(a._Template.Type1Param1)) 
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

        -- if item:IsPetTalentBook() and not self._PetData:HasLearnedSkillById(tonumber(item._Template.Type1Param1))then
        if item:IsPetTalentBook() then
            self._LocalSkillBookList[#self._LocalSkillBookList+1] = item
        end
    end

    --按品质排序
    local function sortFunc(a, b)
        if self._PetData:HasLearnedSkillById(tonumber(a._Template.Type1Param1)) ~= self._PetData:HasLearnedSkillById(tonumber(b._Template.Type1Param1)) then
            return not self._PetData:HasLearnedSkillById(tonumber(a._Template.Type1Param1)) 
        end

        return a._Quality > b._Quality
    end
    table.sort(self._LocalSkillBookList, sortFunc)

    if #self._LocalSkillBookList > 0 then
        _G.ItemListMan.ShowItemListManPanel(self, self._LocalSkillBookList, OnInitItem, OnSelectItem, _G.ShowTipType.ShowItemTip, conditionFunc, self:GetQualityGroup())
    else
        --没有可以用于学习的宠物技能书
        SendFlashMsg(StringTable.Get(19042))
    end
end

def.method().UpdatePanel = function(self)
    self:UpdateSkill()
    self:PlayRedDotGfx( self:CalcRedDotState() )
end

def.method("dynamic").Show = function(self, data)
    if self._PanelObject == nil then
        self:InitPanel()
    end

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
        else
            SendFlashMsg(StringTable.Get(19052))
        end
    else
        SendFlashMsg( string.format(StringTable.Get(19051),CElementData.GetSpecialIdTemplate(624).Value * (index - 1)) )
        --SendFlashMsg(StringTable.Get(19051))
    end
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_AddSkillBook" then
        self:ShowUIItemList()
    elseif id == "Btn_SkillLearn" then
        if self:CheckCanLearnSkill() == false then return end
        CPetUtility.SendC2SPetLearnTalent(self._PetData._ID, self._CurrentSelectSkillBookData._Tid)
        local root = self._PanelObject.Group_SkillBook
        GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, root.GfxHook, root.GfxHook, 1, 20, 1)
    elseif string.find(id, "Frame_Skill_Skill") then
        --技能tips
        local index = tonumber(string.sub(id,-1))
        self:ShowSkillTips(index)
    elseif id == "Btn_Drop_SkillBook" then
        self:ResetSkillBookInfo()
    end
end

def.method("=>", "boolean").CheckCanLearnSkill = function(self)
     if self._CurrentSelectSkillBookData == nil then
        --没有可以用于学习的宠物技能书
        SendFlashMsg(StringTable.Get(19071))
        return false
    end

    local itemTemplate = CElementData.GetTemplate("Item", self._CurrentSelectSkillBookData._Tid)
    local skillId = tonumber(itemTemplate.Type1Param1)
    for i,v in ipairs(self._PetData._SkillList) do
        if v.ID == skillId then
            SendFlashMsg(StringTable.Get(19083))
            return false
        end
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

    local function DoGfx()
        if UIInfo ~= nil then
            GameUtil.PlayUISfx(PATH.UI_jinengshengji, UIInfo.Img_ItemIcon, UIInfo.Img_ItemIcon, 1)
        end
    end

    self._Parent:KillEvts(gfxGroupName1)
    self._Parent:AddEvt_LuaCB(gfxGroupName1, 0.3, DoGfx)
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
    instance = nil
end

CPagePetSkill.Commit()
return CPagePetSkill