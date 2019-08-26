--宠物属性

local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local CPetUtility = require "Pet.CPetUtility"

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetInfo = Lplus.Class("CPagePetInfo")
local def = CPagePetInfo.define

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil   -- 存放UI的集合
def.field("table")._PetData = nil       -- 当前选中的Pet数据

local instance = nil
def.static("table", "userdata", "=>", CPagePetInfo).new = function(parent, panel)
    if instance == nil then
        instance = CPagePetInfo()
        instance._Parent = parent
        instance._Panel = panel
    end

    return instance
end

def.method("dynamic").Show = function(self, data)
    if self._PanelObject == nil then
        self:InitPanel()
    end
    self._Panel:SetActive(data ~= nil)

    if data ~= nil then
        self:UpdateSelectPet(data)
    end
end

def.method().InitPanel = function(self)
    local MaxAptitudeCount = CPetUtility.GetMaxAptitudeCount()   --资质最大个数
    local MaxPropertyCount = CPetUtility.GetMaxPropertyCount()   --属性最大个数
    local MaxSkillCount = CPetUtility.GetMaxSkillCount()         --技能最大个数

    self._PanelObject = {
        AptitudeList = {},
        PropertyList = {},
        Talent = {},
        SkillList = {},
    }
    --资质
    for i=1, MaxAptitudeCount do
        local aptitude = {}
        aptitude.Root = self._Parent:GetUIObject('Frame_PetInfo_Aptitude'..i)
        aptitude.Lab_Aptitude = aptitude.Root:FindChild('Lab_Aptitude')
        local sld = aptitude.Root:FindChild('Sld_Aptitude')
        aptitude.Sld = sld:GetComponent(ClassType.Slider)
        aptitude.Lab_Value = sld:FindChild('Lab_Value')
        aptitude.Img_CanReset = aptitude.Root:FindChild("Img_CanReset")

        table.insert(self._PanelObject.AptitudeList, aptitude)
    end
    --属性
    for i=1, MaxPropertyCount do
        local property = {}
        property.Root = self._Parent:GetUIObject('Frame_Attribute_Property'..i)
        property.Lab_Property = property.Root:FindChild("Lab_Property")
        property.Lab_Value = property.Root:FindChild("Lab_Value")

        table.insert(self._PanelObject.PropertyList, property)
    end
    --天赋
    do
        local root = self._PanelObject.Talent
        root.Item = self._Parent:GetUIObject("TalentSkillItem")
        root.Img_ItemIcon = root.Item:FindChild("Img_ItemIcon")
        root.Img_Quality = root.Item:FindChild("Img_Quality")
        root.Desc = self._Parent:GetUIObject("Lab_TalentDesc")
        root.Lab_TalentName = self._Parent:GetUIObject("Lab_TalentName")
    end
    --技能
    for i=1, MaxSkillCount do
        local skill = {}
        skill.Root = self._Parent:GetUIObject('Frame_Attribute_Skill'..i)
        skill.Lab_SkilName = skill.Root:FindChild("Lab_SkilName")
        skill.ItemSkill = skill.Root:FindChild("ItemSkill")
        skill.Img_D = skill.ItemSkill:FindChild("Img_D")
        skill.Img_Quality = skill.ItemSkill:FindChild("Img_Quality")
        skill.Img_ItemIcon = skill.ItemSkill:FindChild("Img_ItemIcon")
        skill.Img_Lock = skill.ItemSkill:FindChild("Img_Lock")

        table.insert(self._PanelObject.SkillList, skill)
    end
end

def.method("table").UpdateSelectPet = function(self, data)
    self._Panel:SetActive(data ~= nil)
    self._PetData = data

    if self._PetData == nil then return end

    self:UpdatePanel()
end

def.method().UpdatePanel = function(self)
    do
        --warn("UpdatePanel 资质")
        --资质
        local root = self._PanelObject.AptitudeList
        for i=1, #self._PetData._AptitudeList do
            local aptitudeInfo = self._PetData._AptitudeList[i]
            local aptitudeMax = aptitudeInfo.MaxValue

            local UIInfo = root[i]
            GUI.SetText(UIInfo.Lab_Aptitude, aptitudeInfo.Name)

            local strVal = math.ceil(aptitudeInfo.Value)
            local strMax = aptitudeMax --math.ceil(aptitudeInfo.MaxValue)
            GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19070), strVal, strMax))
            UIInfo.Sld.value = math.clamp(aptitudeInfo.Value/aptitudeMax, 0, 1)
            UIInfo.Img_CanReset:SetActive( aptitudeInfo.CanReset ) 
        end
    end

    do
        --warn("UpdatePanel 属性")
        --属性
        local root = self._PanelObject.PropertyList
        for i=1, #self._PetData._PropertyList do
            local propertyInfo = self._PetData._PropertyList[i]
            local UIInfo = root[i]

            GUI.SetText(UIInfo.Lab_Property, propertyInfo.Name)
            local val = math.ceil(propertyInfo.Value)
            GUI.SetText(UIInfo.Lab_Value, GUITools.FormatNumber(val))
        end
    end

    do
        --warn("UpdatePanel 天赋")
        --天赋
        local root = self._PanelObject.Talent
        local talentTemplate = CElementData.GetTemplate("Talent", self._PetData._TalentId)
        if talentTemplate ~= nil then
            GUI.SetText(root.Lab_TalentName, string.format(StringTable.Get(10663), talentTemplate.Name, self._PetData._TalentLevel))
            GUITools.SetIcon(root.Img_ItemIcon, talentTemplate.Icon)
            GUITools.SetGroupImg(root.Img_Quality, talentTemplate.InitQuality)
            GUI.SetText(root.Desc, DynamicText.ParseSkillDescText(self._PetData._TalentId, self._PetData._TalentLevel, true))
        end
    end

    do
        --warn("UpdatePanel 技能")
        --技能
        local MaxSkillCount = CPetUtility.GetMaxSkillCount()         --技能最大个数

        local root = self._PanelObject.SkillList
        for i=1, MaxSkillCount do
            local skillInfo = self._PetData._SkillList[i]
            local UIInfo = root[i]

            local bSkillOpen = (skillInfo ~= nil)
            local bGotSkill = (bSkillOpen and skillInfo.ID > 0)

            UIInfo.Img_Lock:SetActive( not bSkillOpen )
            UIInfo.Lab_SkilName:SetActive(bGotSkill)
            UIInfo.Img_ItemIcon:SetActive(bGotSkill)
            UIInfo.Img_Quality:SetActive(bGotSkill)

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
        end
    end

    do  -- 按钮状态
        local hp = game._HostPlayer
        local btn_delate = self._Parent:GetUIObject("Btn_Delete")
        if hp:IsFightingPetById(self._PetData._ID) or hp:IsHelpingPetById(self._PetData._ID) then
            GUITools.SetBtnGray(btn_delate, true)
        else
            GUITools.SetBtnGray(btn_delate, false)
        end
    end

end

def.method("string").OnClick = function(self, id)
    if id == "Btn_ResetAptitude" then
        game._GUIMan:Open("CPanelUIPetAptitudeReset", self._PetData)
    elseif string.find(id, "Frame_PetInfo_Aptitude") then
        -- 暂时注释，后期修改显示方案
        -- local index = tonumber(string.sub(id, -1))
        -- self:ShowPropertyTip(index)
    elseif string.find(id, "Frame_Attribute_Skill") then
        --技能tips
        local index = tonumber(string.sub(id,-1))
        self:ShowSkillTips(index)
    end
end

def.method("string").OnPointerLongPress = function(self, id)
    -- if string.find(id, "Frame_Attribute_Skill") > 0 then
    --     local index = tonumber( string.sub(id, -1) )
    --     self:ShowSkillTips(index)
    -- end
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

def.method("number").ShowPropertyTip = function(self, index)
    local fightPropertyId = self._PetData._AptitudeList[index].FightPropertyId
    local fix_id = CPetUtility.ExchangeToPropertyTipsID(fightPropertyId)
    local data = CElementData.GetTemplate("FightPropertyConfig", fix_id)

    if data == nil or data.DetailDesc == "" then return end

    local cnt = 0
    local replaceIdStr = data.ReplaceIdStr
    local strIds = {}

    if replaceIdStr ~= nil and replaceIdStr ~= "" then
        strIds = string.split(replaceIdStr, "*")
        cnt = #strIds
    end

    local exchangeIndex1 = index
    local exchangeIndex2 = 0
    local strDesc = ""

    if cnt == 1 then
        exchangeIndex1 = tonumber(strIds[1])
    elseif cnt == 2 then
        exchangeIndex1 = tonumber(strIds[1])
        exchangeIndex2 = tonumber(strIds[2])
    end

    local value = self._PetData._AptitudeList[index].Value
    if value == nil then return end

    if exchangeIndex2 == 0 then
        local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
        local config = ModuleProfDiffConfig.GetModuleInfo("FightProperty")
        if config ~= nil and config.DESC ~= nil and config.DESC[index] ~= nil then
            strDesc = config.DESC[index][game._HostPlayer._InfoData._Prof]
        else
            local exchangeData = CElementData.GetTemplate("FightPropertyConfig", exchangeIndex1)
            if string.sub(exchangeData.ValueFormat, -1) == "%" then
                value = value * 100
            end
            
            strDesc = string.format(data.DetailDesc, value)
        end     
    else
        local value1 = value*100
        local value2 = self._PetData._AptitudeList[index].Value * 100
        strDesc = string.format(data.DetailDesc, value1, value2)
    end

    local param = 
    {
        Obj = self._Parent:GetUIObject("Frame_PetInfo_Aptitude"..index),
        Value = strDesc,
        AlignType = EnumDef.AlignType.Top,
    }
    game._GUIMan:Open("CPanelRoleInfoTips", param)
end

def.method().Hide = function(self)
    self._Panel:SetActive(false)
    self._PanelObject = nil
    self._PetData = nil
end

def.method().Destroy = function (self)
    instance = nil
end

CPagePetInfo.Commit()
return CPagePetInfo