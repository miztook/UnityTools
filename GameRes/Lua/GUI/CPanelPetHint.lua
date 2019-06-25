
local Lplus = require 'Lplus'
local CPetClass = require"Pet.CPetClass"
local CPanelHintBase = require 'GUI.CPanelHintBase'
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"

local CPanelPetHint = Lplus.Extend(CPanelHintBase, 'CPanelPetHint')
local def = CPanelPetHint.define

def.field(CPetClass)._PetData = nil 
def.field("table")._SkillList = nil
--def.field("userdata")._Frame_Position = nil 
def.field("number")._TipPosition = 0 
def.field("userdata")._LayLeft = nil 
def.field("userdata")._Mask = nil 
def.field("userdata")._Scroll = nil 
def.field("userdata")._FrameBasic = nil 
def.field("userdata")._FrameSkill  = nil 

local instance = nil
def.static('=>', CPanelPetHint).Instance = function ()
	if not instance then
        instance = CPanelPetHint()
        instance._PrefabPath = PATH.UI_PetHint
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance:SetupSortingParam()
        instance._DestroyOnHide = true
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._LayLeft = self:GetUIObject("Frame_Content")
    self._Scroll = self:GetUIObject("Scroll")
    self._Mask = self:GetUIObject("Mask")
    self._FrameBasic = self:GetUIObject("Frame_Basic")
    self._FrameSkill = self:GetUIObject("Frame_PetSkill")
    self._SkillList = {}
    for i=1, 6 do
        local skill = {}
        skill.Root = self:GetUIObject('SkillItem'..i)
        skill.Img_ItemIcon = skill.Root:FindChild("ItemSkill/Img_ItemIcon")
        skill.Img_Lock = skill.Root:FindChild("ItemSkill/Img_Lock")
        skill.Img_Quality = skill.Root:FindChild("ItemSkill/Img_Quality")
        skill.Lab_SkillName = skill.Root:FindChild("Lab_SkilName")
        table.insert(self._SkillList, skill)
    end
end

--panelData= 
--{
--     _PetData , -- 宠物数据（CPetClass）
--     _TipPos,   -- tips的位置（默认位置和随着Item适配）
--     _TargetObj, -- 目标物体（根据位置不同设定）
--}
def.override("dynamic").OnData = function(self, data)
    self._PetData = data._PetData
    self._TipPosition = data._TipPos
    local name = ""   
    name = self._PetData._Name
    local text = "<color=#" .. EnumDef.Quality2ColorHexStr[self._PetData._Quality] ..">" .. name .."</color>"
    GUI.SetText(self:GetUIObject("Lab_ItemName"),text)
    GUI.SetText(self:GetUIObject("Lab_PetType"),StringTable.Get(19022 + self._PetData._Genus))
    GUI.SetText(self:GetUIObject("Lab_LevelAndClass"),string.format(StringTable.Get(10649),self._PetData._Stage,self._PetData._Level))
    GUITools.SetGroupImg(self:GetUIObject("Img_Quality"),self._PetData._Quality)
    GUITools.SetItemIcon(self:GetUIObject("Img_ItemIcon"),self._PetData._IconPath)
    GUI.SetText(self:GetUIObject("Lab_PetStroy"),self._PetData._PetStroy) 

    self:InitPetAptitude()
    self:InitPetProperty()
    self:InitPetTalent()
    self:InitPetSkill()
    self:SetTipSize(self._LayLeft,self._Scroll,self._Mask,self._FrameBasic)
    -- self:InitTipPosition(data._TargetObj)
end

def.override('string').OnClick = function(self, id)
    --[[
    if string.find("SkillItem",id) then 
        local index = tonumber(string.sub(id,-1))
        local panelData = 
        {
            SkillName = self._PetData._SkillList[index].Name,
            SkillDes = self._PetData._SkillList[index].Desc,
            TargetObj = self._FrameSkill,
        }
        game._GUIMan:Open("CPanel")
    end
    ]]
end

def.method("userdata").InitTipPosition = function (self,target)
    if self._TipPosition == 0 or target == nil then return end
    if self._TipPosition == TipPosition.FIX_POSITION then 
        GameUtil.SetTipsPosition(target,self._Scroll)
    elseif self._TipPosition == TipPosition.DEFAULT_POSITION then  
        self._Scroll.localPosition = target.localPosition
    end
end

def.method("userdata","userdata","userdata","userdata").SetTipSize = function (self,obj,scroll,maskObj,titleObj)
    local height = GameUtil.GetTipLayoutHeight(obj)
    if height< 0 then 
        warn("C# function is wrong")
        return
    end
    local scrollRect = scroll:GetComponent(ClassType.RectTransform)
    local maskRect = maskObj:GetComponent(ClassType.RectTransform)
    local titleRect = titleObj:GetComponent(ClassType.RectTransform)

    local scrollSizeDelta = scrollRect.sizeDelta
    local maskSizeDelta = maskRect.sizeDelta

    if height > 446 then    --555-109
        height = 446
    end
    -- 调整一下Mask 高度 使内容不至于突然间断掉
    maskSizeDelta.y = height + 8
    maskRect.sizeDelta = maskSizeDelta

    scrollSizeDelta.y = maskSizeDelta.y + titleRect.sizeDelta.y
    scrollRect.sizeDelta = scrollSizeDelta

    obj.localPosition = Vector3.New(0,0,0)
end

-- 初始化宠物资质
def.method().InitPetAptitude = function (self)
    for i=1, 5 do
        if #self._PetData._AptitudeList < i then 
            self:GetUIObject("ItemPetRange"..i):SetActive(false)
        else
            local aptitudeInfo = self._PetData._AptitudeList[i]
            local UIInfo = self:GetUIObject("ItemPetRange"..i)
            UIInfo:SetActive(true)
            local labTips = UIInfo:FindChild("Lab_AttriTips")
            local labValue = UIInfo:FindChild("Lab_AttriValues")
            local Slider = UIInfo:FindChild("Slider/Img_Slider"):GetComponent(ClassType.Image)
            GUI.SetText(labTips, aptitudeInfo.Name)
            GUI.SetText(labValue,tostring(aptitudeInfo.Value))
            Slider.fillAmount = aptitudeInfo.Value/aptitudeInfo.MaxValue
        end
    end
end

--初始化宠物属性
def.method().InitPetProperty = function (self)
    for i=1, 5 do
        if #self._PetData._PropertyList < i then 
            self:GetUIObject("PropertyItem"..i):SetActive(false)
        else
            local PropertyInfo = self._PetData._PropertyList[i]
            local UIInfo = self:GetUIObject("PropertyItem"..i)
            UIInfo:SetActive(true)
            local labTips = UIInfo:FindChild("Lab_AttriTips")
            local labValue = UIInfo:FindChild("Lab_AttriValues")
            GUI.SetText(labTips, PropertyInfo.Name)
            GUI.SetText(labValue,tostring(PropertyInfo.Value))
        end
    end
end

--初始化宠物天赋
def.method().InitPetTalent = function (self)
    local talentTemplate = CElementData.GetTemplate("Talent", self._PetData._TalentId)
    if talentTemplate ~= nil then
        local TalentItem = self:GetUIObject("TalentItem")
        GUI.SetText(self:GetUIObject("Lab_TalentNameAndDes"),DynamicText.ParseSkillDescText(self._PetData._TalentId, self._PetData._TalentLevel, true))
        GUI.SetText(TalentItem:FindChild("Lab_Name"), string.format(StringTable.Get(10663), talentTemplate.Name, self._PetData._TalentLevel))
        GUITools.SetIcon(TalentItem:FindChild("Img_Skill"), talentTemplate.Icon)
        -- GUITools.SetGroupImg(TalentItem:FindChild("Img_Quality"), talentTemplate.InitQuality)
    end
end

-- 初始化宠物技能
def.method().InitPetSkill = function (self)
    local CPetUtility = require "Pet.CPetUtility"
    local MaxSkillCount = CPetUtility.GetMaxSkillCount()         --技能最大个数

    local root = self._SkillList
    for i=1, MaxSkillCount do
        local skillInfo = self._PetData._SkillList[i]
        local UIInfo = root[i]

        local bSkillOpen = (skillInfo ~= nil)
        local bGotSkill = ( bSkillOpen and skillInfo.ID > 0)

        UIInfo.Img_Lock:SetActive( not bSkillOpen )
        UIInfo.Lab_SkillName:SetActive(bGotSkill)
        UIInfo.Img_ItemIcon:SetActive(bGotSkill)
        UIInfo.Img_Quality:SetActive(bGotSkill)

        if bGotSkill then
            GUI.SetText(UIInfo.Lab_SkillName, skillInfo.Name)
            GUITools.SetIcon(UIInfo.Img_ItemIcon, skillInfo.IconPath)

            local TalentData = CElementData.GetTemplate("Talent", skillInfo.ID)
            if TalentData then
                GUITools.SetGroupImg(UIInfo.Img_Quality, TalentData.InitQuality)
            end
        end
    end
end

def.method().Hide = function(self)
    game._GUIMan:CloseByScript(self)
    -- MsgBox.CloseAll()
end

CPanelPetHint.Commit()
return CPanelPetHint