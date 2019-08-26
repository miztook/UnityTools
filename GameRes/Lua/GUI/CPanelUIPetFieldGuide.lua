local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"
local CUIModel = require "GUI.CUIModel"
local EItemQuality = require "PB.Template".Item.ItemQuality

local CPanelUIPetFieldGuide = Lplus.Extend(CPanelBase, "CPanelUIPetFieldGuide")
local def = CPanelUIPetFieldGuide.define

def.field("table")._PanelObject = BlankTable                -- 存储界面节点的集合
def.field("userdata")._ItemList = nil                       -- 宠物图鉴列表
def.field("table")._LocalItemList = BlankTable              -- 本地数据结构
def.field("table")._CurrentSelectInfo = BlankTable          -- 当前选择物品的Index,object
def.field("table")._ItemData = nil                          -- 当前选中Item
def.field(CUIModel)._UIModel = nil                          -- 当前的宠物model

def.field("boolean")._IsShowBoardNow = false                -- 当前显示的是 属性面板 | 宠物Model
def.field("number")._CurrentQuality = 0

local listQuality = 
{
    2, -- 稀有
    3, -- 史诗
    5, -- 传说
}
local instance = nil
def.static("=>",CPanelUIPetFieldGuide).Instance = function()
    if instance == nil then
        instance = CPanelUIPetFieldGuide()
        instance._PrefabPath = PATH.UI_PetFieldGuide
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
    end
    return instance
end

def.override().OnCreate = function(self)
    -- UI
    self._PanelObject = 
    {
        Board = self:GetUIObject('ScrollView'),
        Model_Pet = self:GetUIObject('Img_Role'),
        AptitudeList = {},
        PropertyList = {},
        TalentList = {},
        Btn_Open = self:GetUIObject('Btn_Open'),
        Btn_Close = self:GetUIObject('Btn_Close'),
        Lab_OrignDesc = self:GetUIObject('Lab_OrignDesc'),
        Btn_Tips = self:GetUIObject("Btn_Tips"),
        Lab_TalentName = self:GetUIObject('Lab_TalentName'),
        Lab_TalentDesc = self:GetUIObject('Lab_TalentDesc'),
        Lab_Name = self:GetUIObject('Lab_Name'),
        Lab_Genre = self:GetUIObject('Lab_Genre'),
        Img_Genre = self:GetUIObject('Img_Genre')
    }
    
    do
        local root = self._PanelObject
        do
        -- 策划定死的 三个固定
            for i=1, 3 do
                local aptitude = {}
                aptitude.Root = self:GetUIObject('Frame_Aptitude'..i)
                aptitude.Lab_Property = aptitude.Root:FindChild('Lab_Property')
                aptitude.Lab_Value = aptitude.Root:FindChild('Lab_Value')

                table.insert(root.AptitudeList, aptitude)
            end
        end
        do
        -- 策划定死的 三个固定
            for i=1, 3 do
                local property = {}
                property.Root = self:GetUIObject('Frame_Property'..i)
                property.Lab_Property = property.Root:FindChild('Lab_Property')
                property.Lab_Value = property.Root:FindChild('Lab_Value')

                table.insert(root.PropertyList, property)
            end
        end
        do
        -- 策划规定格子数量不会超过10个
            for i=1, 10 do
                local skill = {}
                skill.Root = self:GetUIObject('Frame_Skill'..i)
                skill.Lab_SkilName = skill.Root:FindChild("Lab_SkilName")
                skill.ItemSkill = skill.Root:FindChild("ItemSkill")
                skill.Img_D = skill.ItemSkill:FindChild("Img_D")
                skill.Img_Quality = skill.ItemSkill:FindChild("Img_Quality")
                skill.Img_ItemIcon = skill.ItemSkill:FindChild("Img_ItemIcon")

                table.insert(root.TalentList, skill)
            end
        end
    end

    self._ItemList = self:GetUIObject('List_Item'):GetComponent(ClassType.GNewListLoop)
    local MaxPropertyCount = CPetUtility.GetMaxPropertyCount()   --属性最大个数

    self:SetDorpdownGroup()
end

def.override("dynamic").OnData = function(self,data)
    self:ResetSelectItem()
    -- self:TurnBoard()

    local guideAll = CPetUtility.GetAllPetGuideInfo()

    self._LocalItemList = 
    {
        [EItemQuality.Rare] = {},
        [EItemQuality.Epic] = {},
        [EItemQuality.Legend] = {},
        [888] = guideAll,
    }

    for i=1, #guideAll do
        table.insert(self._LocalItemList[guideAll[i].Quality], clone(guideAll[i]))
    end

    -- 默认选中 全部，不破坏原有设计  用888怼一个先
    self._CurrentQuality = 888

    self:SyncSelectItemData()
    self:UpdateItemList()
    self:UpdateShowBoard()

    CPanelBase.OnData(self,data)
end

def.method("=>", "string").GetQualityGroupStr = function(self)
    local groupStr = StringTable.Get(10010)
    for i, v in ipairs(listQuality) do
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
    GUI.SetDropDownOption(self:GetUIObject('DropDown_Up'), groupStr)
end

-- 同步已选中的 装备
def.method().SyncSelectItemData = function(self)
    if #self._LocalItemList[self._CurrentQuality] > 0 then
        if self._CurrentSelectInfo.Index == 0 then
            self._CurrentSelectInfo.Index = 1
        end
        self._ItemData = self._LocalItemList[self._CurrentQuality][self._CurrentSelectInfo.Index]
    else
        self._ItemData = nil
    end
end

def.method().UpdateItemList = function(self)
    local count = #self._LocalItemList[self._CurrentQuality]
    self._ItemList:SetItemCount( count )
end

def.method("number", "=>", "table").GetItemDataByIndex = function(self, index)
    return self._LocalItemList[self._CurrentQuality][index]
end

--设置宠物格子（获得宠物属性 | 空格子）
def.method("userdata", "number").SetPetInfo = function(self, item, index)
    local img_Quality = item:FindChild("Img_Quality")
    local img_ItemIcon = item:FindChild("Img_ItemIcon")
    local img_PetGenus = item:FindChild("Img_PetGenus")
    local Lab_PetName = item:FindChild("Lab_PetName")
    local petData = self:GetItemDataByIndex(index)

    GUITools.SetIcon(img_ItemIcon, petData.GuideIconPath)
    GUITools.SetGroupImg(img_Quality, petData.Quality)
    GUITools.SetGroupImg(img_PetGenus, petData.Genus)
    GUI.SetText(Lab_PetName, RichTextTools.GetQualityText(petData.Name, petData.Quality))
end

def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Item" then
        self:SetPetInfo(item, idx)
        local currentSelectIndex = self._CurrentSelectInfo.Index
        local img_select = item:FindChild("Img_Select")
        img_select:SetActive(currentSelectIndex == idx)

        if currentSelectIndex == idx then
            self._CurrentSelectInfo.Object = img_select
        end
    end
end

def.override("userdata", "string", "number").OnSelectItem = function(self, item, id, index)
    local idx = index + 1
    if id == "List_Item" then
        if self._CurrentSelectInfo.Object ~= nil then
            self._CurrentSelectInfo.Object:SetActive(false)
        end
        
        self:ResetSelectItem()
        self._ItemData = self:GetItemDataByIndex(idx)

        local img_select = item:FindChild("Img_Select")
        img_select:SetActive(true)
        self._CurrentSelectInfo.Object = img_select
        self._CurrentSelectInfo.Index = idx

        -- 选中逻辑
        self:UpdateShowBoard()

        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
    end
end

def.method().PlayIdelAni = function(self)
    self._UIModel:PlayAnimationQueue(EnumDef.CLIP.TALK_IDLE, false)
    self._UIModel:PlayAnimationQueue(EnumDef.CLIP.COMMON_STAND, true)
end

def.method().UpdateModel = function(self)
    --warn("UpdateModel")
    if self._UIModel == nil then
        self._UIModel = CUIModel.new(self._ItemData.ModelAssetPath, 
                                     self._PanelObject.Model_Pet, 
                                     EnumDef.UIModelShowType.All, 
                                     EnumDef.RenderLayer.UI, 
                                     nil)
    else
        self._UIModel:Update(self._ItemData.ModelAssetPath)
    end

    self._UIModel:AddLoadedCallback(function() 
        self._UIModel:SetModelParam(self._PrefabPath, self._ItemData.ModelAssetPath)
        --先播一次
        self:PlayIdelAni()
        end)
end

def.method().UpdatePetInfoBoard = function(self)
    if self._ItemData == nil then return end
    local root = self._PanelObject
    do
    -- 策划定死的 三个固定
        for i=1, #self._ItemData.AptitudeList do
            local aptitudeInfo = self._ItemData.AptitudeList[i]
            local uiInfo = root.AptitudeList[i]
            GUI.SetText(uiInfo.Lab_Property, aptitudeInfo.Name)
            local MinValue = GUITools.FormatMoney(aptitudeInfo.MinValue)
            local MaxValue = GUITools.FormatMoney(aptitudeInfo.MaxValue)
            local str = string.format("%s ~ %s", MinValue, MaxValue)
            GUI.SetText(uiInfo.Lab_Value, str)
        end
    end
    do
    -- 策划定死的 三个固定
        for i=1, #self._ItemData.PropertyList do
            local propertyInfo = self._ItemData.PropertyList[i]
            local uiInfo = root.PropertyList[i]
            GUI.SetText(uiInfo.Lab_Property, propertyInfo.Name)
            local MinValue = GUITools.FormatMoney(propertyInfo.MinValue)
            local MaxValue = GUITools.FormatMoney(propertyInfo.MaxValue)
            local str = string.format("%s ~ %s", MinValue, MaxValue)
            GUI.SetText(uiInfo.Lab_Value, str)
        end
    end
    do
    -- 策划规定格子数量不会超过10个
        for i=1, 10 do
            local skillInfo = self._ItemData.TalentList[i]
            local uiInfo = root.TalentList[i]

            local bShow = (skillInfo ~= nil)
            uiInfo.Root:SetActive(bShow)
            if bShow then
                GUI.SetText(root.Lab_TalentName, skillInfo.Name)
                GUI.SetText(root.Lab_TalentDesc, skillInfo.Desc)

                -- GUI.SetText(uiInfo.Lab_SkilName, skillInfo.Name)
                GUITools.SetIcon(uiInfo.Img_ItemIcon, skillInfo.IconPath)
                GUITools.SetGroupImg(uiInfo.Img_Quality, skillInfo.Quality)
            end
        end
    end

    GUI.SetText(root.Lab_Name, RichTextTools.GetQualityText(self._ItemData.Name, self._ItemData.Quality))
    GUI.SetText(root.Lab_Genre, StringTable.Get(19022+self._ItemData.Genus))
    GUITools.SetGroupImg(root.Img_Genre, self._ItemData.Genus)
    GUI.SetText(root.Lab_OrignDesc, self._ItemData.PetStroy)
end

def.method().UpdateShowBoard = function(self)
    if self._ItemData == nil then return end

    -- if self._IsShowBoardNow then
    --     self:UpdatePetInfoBoard()
    -- else
    --     self:UpdateModel()
    -- end

    self:UpdatePetInfoBoard()
    self:UpdateModel()
end

def.method().TurnBoard = function(self)
    local root = self._PanelObject
    
    root.Btn_Open:SetActive( self._IsShowBoardNow )
    root.Board:SetActive( self._IsShowBoardNow )
    root.Btn_Close:SetActive( not self._IsShowBoardNow )
    root.Model_Pet:SetActive( not self._IsShowBoardNow )
    self:UpdateShowBoard()
end

-- 切换功能页面
def.method("number").ChangePage = function(self, pageIndex)

    if self._CurrentQuality == pageIndex then return end

    self._CurrentQuality = pageIndex

    local count = #self._LocalItemList[self._CurrentQuality]
    if count > 0 then
        self._CurrentSelectInfo = {Index = 1, Object = nil}
    else
        self:ResetSelectItem()
    end
    self:SyncSelectItemData()
    self:UpdateItemList()
    self:UpdateShowBoard()
end

def.method("number").ShowSkillTips = function(self, index)
    if self._ItemData.TalentList[index] ~= nil then
        if self._ItemData.TalentList[index].ID > 0 then
            local root = self._PanelObject
            local panelData = 
            {
                _TalentID = self._ItemData.TalentList[index].ID,
                _TalentLevel = 1,
                _TipPos = TipPosition.FIX_POSITION,
                _TargetObj = root.TalentList[index].Root,
            }

            CItemTipMan.ShowPetSkillTips(panelData)
        else
            TeraFuncs.SendFlashMsg(StringTable.Get(19052))
        end
    else
        TeraFuncs.SendFlashMsg( string.format(StringTable.Get(19051),CElementData.GetSpecialIdTemplate(624).Value * (index - 1)) )
    end
end

def.method().ShowApproach = function(self)
    local PanelData = 
    {
        ApproachIDs = self._ItemData.ApproachIDs,
        ParentObj = self._PanelObject.Btn_Tips,
    }
    game._GUIMan:Open("CPanelItemApproach",PanelData) 
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Back" then
        game._GUIMan:CloseByScript(self)
    -- elseif id == "Btn_Open" or id == "Btn_Close" then
    --     self._IsShowBoardNow = not self._IsShowBoardNow
    --     self:TurnBoard()
    elseif id == "Btn_Tips" then
        self:ShowApproach()
    elseif string.find(id, "Frame_Skill") then
        --技能tips
        local index = tonumber(string.sub(id,-1))
        self:ShowSkillTips(index)
    end
end

-- def.override("string", "boolean").OnToggle = function(self,id, checked)
--     -- warn("OnToggle = ", id)
--     if id == "Rdo_Rare" and checked then
--         self:ChangePage(EItemQuality.Rare)
--     elseif id == "Rdo_Epic" and checked then
--         self:ChangePage(EItemQuality.Epic)
--     elseif id == "Rdo_Legend" and checked then
--         self:ChangePage(EItemQuality.Legend)
--     end
-- end

def.override("string", "number").OnDropDown = function(self, id, index)
    if id == "DropDown_Up" then
        local quality = self:ExchangePetQualityByIndex(index)
        if quality == listQuality[1] then
            self:ChangePage(EItemQuality.Rare)
        elseif quality == listQuality[2] then
            self:ChangePage(EItemQuality.Epic)
        elseif quality == listQuality[3] then
            self:ChangePage(EItemQuality.Legend)
        else
            self:ChangePage(888)
        end
    end
end

def.method('number', '=>', 'number').ExchangePetQualityByIndex = function(self, index)
    return listQuality[index] or -1
end

-- 当前选择物品的Index列表,按类别分类
def.method().ResetSelectItem = function(self)
    self._CurrentSelectInfo = {Index = 0, Object = nil}
    self._ItemData = nil
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    if self._UIModel ~= nil then
        self._UIModel:Destroy()
        self._UIModel = nil
    end

    instance = nil
end

CPanelUIPetFieldGuide.Commit()
return CPanelUIPetFieldGuide