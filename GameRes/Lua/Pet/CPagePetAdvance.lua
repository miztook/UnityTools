--宠物进阶

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetAdvance = Lplus.Class("CPagePetAdvance")
local def = CPagePetAdvance.define

local DynamicText = require "Utility.DynamicText"
local CElementData = require "Data.CElementData"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CPetUtility = require "Pet.CPetUtility"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil                   -- 存放UI的集合
def.field("table")._PetData = nil                       -- 当前选中的Pet数据
def.field("table")._CurrentSelectMeterialPetData = nil  -- 当前选中当材料用的宠物索引
def.field("table")._LocalPetList = BlankTable           -- 本地筛选排序的列表
def.field("table")._AdvanceLimitLevelInfo = nil         -- 进阶等级限制
def.field("boolean")._IsMaxAptitude = false             -- 资质是否都达到最大值

local listQuality = 
{
    2, -- 稀有
    3, -- 史诗
    5, -- 传说
}

local instance = nil
def.static("table", "userdata", "=>", CPagePetAdvance).new = function(parent, panel)
    if instance == nil then
        instance = CPagePetAdvance()
        instance._Parent = parent
        instance._Panel = panel
    end
    
    return instance
end

def.method().InitPanel = function(self)
    -- local MaxPropertyCount = CPetUtility.GetMaxPropertyCount()   --属性最大个数
    local MaxAptitudeCount = CPetUtility.GetMaxAptitudeCount()   --资质最大个数
    self._AdvanceLimitLevelInfo = CPetUtility.GetAdvanceLvLimitInfo()

    self._PanelObject = {
        PropertyList = {},
        AptitudeList = {},
        Group_Advance = {},
        Group_AdvanceTalent = {},
        Btn_Advance = self._Parent:GetUIObject("Btn_Advance"),
        Btn_AdvanceTalent = self._Parent:GetUIObject("Btn_AdvanceTalent"),
    }

    --资质
    for i=1, 5 do
        if i <= MaxAptitudeCount then 
            local aptitude = {}
            aptitude.Root = self._Parent:GetUIObject('Frame_Advance_Aptitude'..i)
            aptitude.Lab_Aptitude = aptitude.Root:FindChild('Lab_Aptitude')
            local sld = aptitude.Root:FindChild('Sld_Aptitude')
            aptitude.Sld = sld:GetComponent(ClassType.Slider)
            aptitude.Lab_Value = sld:FindChild('Lab_Value')
            aptitude.Img_AddValue = sld:FindChild('Img_AddValue')
            aptitude.Img_Up = sld:FindChild('Img_Up')
            aptitude.Img_CanReset = aptitude.Root:FindChild("Img_CanReset")

            table.insert(self._PanelObject.AptitudeList, aptitude)
        else
            local obj = self._Parent:GetUIObject('Frame_Advance_Aptitude'..i)
            obj:SetActive(false)
        end
    end

    -- 天赋
    do
        local root = self._PanelObject.Group_AdvanceTalent
        root.TalentIcon = self._Parent:GetUIObject("Img_AdvanceTalentIcon")
        root.Lab_TalentName = self._Parent:GetUIObject('Lab_AdvanceTalentName')
        root.Frame_TalentAdd = self._Parent:GetUIObject('Frame_TalentAdd')
        root.Lab_Add = self._Parent:GetUIObject('Lab_TalentAdd')
        root.Lab_Max = self._Parent:GetUIObject('Lab_AdvanceTalentMaxLevel')
    end

    do
        local root = self._PanelObject.Group_Advance
        root.Root = self._Parent:GetUIObject("Group_Advance")
        --root.Lab_Value = root.Root:FindChild("Lab_Value")
        root.GfxHook = root.Root:FindChild("SelectItemGroup/GfxHook")
        root.SelectPetNeed = self._Parent:GetUIObject("SelectPetNeed")
        root.Img_ItemIcon = root.SelectPetNeed:FindChild("Img_ItemIcon")
        root.Img_Quality = root.SelectPetNeed:FindChild("Img_Quality")
        root.Img_QualityBG = root.SelectPetNeed:FindChild("Img_QualityBG")
        root.Lab_Lv = root.SelectPetNeed:FindChild("Lab_Lv")
        root.Btn_Drop_PetNeed = self._Parent:GetUIObject("Btn_Drop_PetNeed")
        root.Btn_AddPetNeed = self._Parent:GetUIObject("Btn_AddPetNeed")
    end
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end

    if EPetOptType.EPetOptType_advance == event._Type then
        instance:UpdatePanel()
        --instance:UpdateAdvanceLimit()
    end
end

def.method("table").UpdateSelectPet = function(self, data)
    self._Panel:SetActive(data ~= nil)
    self:ResetMeterialPetInfo()

    self._PetData = data
    if self._PetData == nil then return end
    
    self:UpdatePanel()
    --self:UpdateAdvanceLimit()
end

def.method().ResetMeterialPetInfo = function(self)
    self._CurrentSelectMeterialPetData = nil
    self._LocalPetList = {}
    self._Parent:ClearAdvanceMeterialPetList()
    local Group_Advance = self._PanelObject.Group_Advance
    Group_Advance.Img_ItemIcon:SetActive(false)
    Group_Advance.Img_Quality:SetActive(false)
    Group_Advance.Img_QualityBG:SetActive(false)
    Group_Advance.Lab_Lv:SetActive(false)
    Group_Advance.Btn_Drop_PetNeed:SetActive(false)
    Group_Advance.Btn_AddPetNeed:SetActive(true)
    GUITools.SetBtnGray(self._PanelObject.Btn_Advance, true)
end

def.method().UpdateProperty = function(self)
    --warn("UpdatePanel 资质")
    --资质
    local petData = self._PetData
    local materialPetData  = self._CurrentSelectMeterialPetData
    local star = petData:GetStage()
    local root = self._PanelObject.AptitudeList

    if materialPetData ~= nil then 
        local petAptitudes = petData._AptitudeList
        local materialpetAptitudes = materialPetData._AptitudeList
        for i=1, #petData._AptitudeList do
            local inc = petData._AptitudeMaxIncrease[i]
            local addValue = petData._AptitudeIncrease[i]

            local aptitudeMax = petData:GetAptitudeMaxByIndex(i) + inc * math.min(star + 1, 5)

            if i > #materialPetData._AptitudeList then return end
            -- warn("petAptitudes[i].FightPropertyId == materialpetAptitudes[i].FightPropertyId",petAptitudes[i].FightPropertyId,materialpetAptitudes[i].FightPropertyId)
            -- if petAptitudes[i].FightPropertyId == materialpetAptitudes[i].FightPropertyId and materialpetAptitudes[i].Value > 0 then 
            local UIInfo = root[i]
            local aptitudeInfo = petAptitudes[i]
            
            if (aptitudeInfo.Value + addValue) > aptitudeMax then 
                addValue = aptitudeMax - aptitudeInfo.Value
            end
            UIInfo.Img_AddValue:SetActive(true)
            UIInfo.Img_Up:SetActive(true)
            UIInfo.Img_CanReset:SetActive( aptitudeInfo.CanReset ) 
            local imgfill = UIInfo.Img_AddValue:GetComponent(ClassType.Image)
            imgfill.fillAmount = math.clamp((aptitudeInfo.Value + addValue)/aptitudeMax, 0, 1)

            if addValue > 0 then
                GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19088),aptitudeInfo.Value,addValue,aptitudeMax,inc))
            else
                GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19098),aptitudeInfo.Value,aptitudeMax,inc))
            end
        end
    else
        for i=1, #petData._AptitudeList do
            local inc = petData._AptitudeMaxIncrease[i]
            local aptitudeMax = petData:GetAptitudeMaxByIndex(i) + inc * star
            local aptitudeInfo = petData._AptitudeList[i]
            local UIInfo = root[i]
            GUI.SetText(UIInfo.Lab_Aptitude, aptitudeInfo.Name)
            UIInfo.Img_AddValue:SetActive(false)
            UIInfo.Img_Up:SetActive(false)
            UIInfo.Img_CanReset:SetActive( aptitudeInfo.CanReset ) 
            if aptitudeInfo.Value >= aptitudeMax then 
                GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19074), aptitudeMax))
            else
                self._IsMaxAptitude = false
                GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19070), aptitudeInfo.Value, aptitudeMax))
            end
            UIInfo.Sld.value = math.clamp(aptitudeInfo.Value/aptitudeMax, 0, 1)
        end
    end
end

-- 天赋
def.method().UpdateTalent = function(self)
    local data = self._PetData
    local maxTalentLv = CPetUtility.GetMaxPetTalentLevel() 
    local root = self._PanelObject.Group_AdvanceTalent
    if self._CurrentSelectMeterialPetData ~= nil and data._TalentId == self._CurrentSelectMeterialPetData._TalentId and self._CurrentSelectMeterialPetData._TalentLevel > 0 and data._TalentLevel < maxTalentLv then 
        -- local addLevel = self._CurrentSelectMeterialPetData._TalentLevel
        root.Frame_TalentAdd:SetActive(true)
        -- if (data._TalentLevel + addLevel) > maxTalentLv then
            -- addLevel  = maxTalentLv - data._TalentLevel
        -- end
        GUI.SetText(root.Lab_Add, string.format(StringTable.Get(10691), 1))
        return        
    elseif self._CurrentSelectMeterialPetData ~= nil and data._TalentId ~= self._CurrentSelectMeterialPetData._TalentId then
        return
    elseif self._CurrentSelectMeterialPetData ~= nil and data._TalentLevel == maxTalentLv then 
        return
    elseif self._CurrentSelectMeterialPetData == nil then 
        root.Frame_TalentAdd:SetActive(false)
    end 
    local talentTemplate = CElementData.GetTemplate("Talent", data._TalentId)
    GUITools.SetIcon(root.TalentIcon, talentTemplate.Icon)
    GUI.SetText(root.Lab_TalentName, string.format(StringTable.Get(10663), talentTemplate.Name, data._TalentLevel))
    if data._TalentLevel == maxTalentLv then 
        root.Lab_Max:SetActive(true)
        root.Frame_TalentAdd:SetActive(false)
    else
        root.Lab_Max:SetActive(false)
    end
end

def.method().UpdatePanel = function(self)
    self._IsMaxAptitude = true
    self:UpdateProperty()
    -- self:UpdateInfo()
    self:UpdateTalent()
    self:PlayRedDotGfx( self:CalcRedDotState() )
end

def.method().UpdateInfo = function(self)

end

def.method("dynamic").SelectAdvanceMeterialPet = function(self, petItem)
    local root = self._PanelObject.Group_Advance
    root.Img_ItemIcon:SetActive(true)
    root.Img_Quality:SetActive(true)
    root.Img_QualityBG:SetActive(true)
    root.Lab_Lv:SetActive(true)
    GUITools.SetIcon(root.Img_ItemIcon, petItem._IconPath)
    GUITools.SetGroupImg(root.Img_Quality, petItem._Quality)
    GUITools.SetGroupImg(root.Img_QualityBG, petItem._Quality)
    GUI.SetText(root.Lab_Lv, string.format(StringTable.Get(10641), petItem._Level))
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

local function OnInitItem(self, item, data)
    local Frame_SkillbookInfo = item:FindChild("Frame_SkillbookInfo")
    local Frame_PetInfo = item:FindChild("Frame_PetInfo")
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    local Frame_PetIcon = item:FindChild("Btn_Icon/PetIcon")
    local Frame_ItemIcon = item:FindChild("Btn_Icon/ItemIconNew")

    local root = Frame_PetInfo
    local Lab_Fight = root:FindChild("Lab_Fight")
    local Lab_ItemName = root:FindChild("Lab_ItemName")
    local Img_QualityBg = Frame_PetIcon:FindChild("Img_QualityBG")
    local Img_Quality = Frame_PetIcon:FindChild("Img_Quality")
    local Img_ItemIcon = Frame_PetIcon:FindChild("Img_ItemIcon")
    local Lab_Lv = Frame_PetIcon:FindChild("Lab_PetLv")

    Img_UnableClick:SetActive(false)
    Frame_SkillbookInfo:SetActive(false)
    Frame_ItemIcon:SetActive(false)
    Frame_PetInfo:SetActive(true)
    Frame_PetIcon:SetActive(true)

    GUI.SetText(Lab_Fight, string.format(StringTable.Get(19055), data:GetFightScore()))
    GUI.SetText(Lab_ItemName, RichTextTools.GetQualityText(data:GetNickName(), data:GetQuality()))
    GUITools.SetGroupImg(Img_QualityBg, data._Quality)
    GUITools.SetGroupImg(Img_Quality, data._Quality)
    GUITools.SetIcon(Img_ItemIcon, data._IconPath)
    GUI.SetText(Lab_Lv, string.format(StringTable.Get(10641), data._Level))

    local Group_Stars = Frame_PetInfo:FindChild("Group_Stars")
    Group_Stars:SetActive(true)
    local pet_star = data:GetStage()
    local pet_max_star = data._MaxStage
    for i=1, 5 do
        local img_star = Group_Stars:FindChild("Img_Star"..i)
        local bShow = i <= pet_max_star and i <= pet_star
        img_star:SetActive(bShow)
        if bShow then
            GUITools.SetGroupImg(img_star, 0)
        end
    end
end

local function OnSelectItem(self, item, data, bIsConfirm)
    if self._CurrentSelectMeterialPetData == data then return false end

    if bIsConfirm then
        self._CurrentSelectMeterialPetData = data
        self._Parent:UpdateAdvanceMeterialPetList({data._ID})
        self:SelectAdvanceMeterialPet(data)
        self:UpdateProperty()
        self:UpdateTalent()
        local Group_Advance = self._PanelObject.Group_Advance
        Group_Advance.Btn_AddPetNeed:SetActive(false)
        Group_Advance.Btn_Drop_PetNeed:SetActive(true)
        GUITools.SetBtnGray(self._PanelObject.Btn_Advance, false)
    end

    return true
end

local function sortfunction(item1,item2)
    if item1._FightScore > item2._FightScore then 
        return true
    elseif item1._FightScore < item2._FightScore then 
        return false
    else
        return false
    end 
end

local function conditionFunc(self, index)
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local allPetList = petPackage:GetList()
    self._LocalPetList = {}

    local quality = self:ExchangePetQualityByIndex(index-1)

    for i=1, #allPetList do
        local pet = allPetList[i]
        --材料不能为出战 助战宠物
        if (hp:IsFightingPetById(pet._ID) or hp:IsHelpingPetById(pet._ID)) == false then
            if pet._ID ~= self._PetData._ID then
                if quality == -1 then
                    self._LocalPetList[#self._LocalPetList+1] = pet
                elseif pet:GetQuality() == quality then
                    self._LocalPetList[#self._LocalPetList+1] = pet
                end
            end
        end
    end

    if #self._LocalPetList > 0 then
        table.sort(self._LocalPetList , sortfunction)
        return self._LocalPetList
    else
        return StringTable.Get(10938)
    end
end

def.method('number', '=>', 'number').ExchangePetQualityByIndex = function(self, index)
    return listQuality[index] or -1
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

def.method().ShowUIItemList = function(self)
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage
    local allPetList = petPackage:GetList()
    self._LocalPetList = {}

    if self._PetData:IsMaxStage() then
        --满阶
        TeraFuncs.SendFlashMsg(StringTable.Get(19041))
        return
    else
        -- local limitLevel = self._AdvanceLimitLevelInfo[self._PetData:GetStage()+1]
        -- if limitLevel > self._PetData:GetLevel() then
        --     --不满足进阶等级
        --     TeraFuncs.SendFlashMsg(string.format(StringTable.Get(19043), limitLevel))
        --     return
        -- end
    end
    --以上全部为过滤逻辑

    for i=1, #allPetList do
        local pet = allPetList[i]
        
        --材料不能为出战 助战宠物
        if (hp:IsFightingPetById(pet._ID) or hp:IsHelpingPetById(pet._ID)) == false then
            --if pet._Tid == self._PetData._Tid and pet._ID ~= self._PetData._ID and pet:GetStage() == self._PetData:GetStage() then
                --self._LocalPetList[#self._LocalPetList+1] = pet
            --end
            if pet._ID ~= self._PetData._ID and pet._Tid == self._PetData._Tid then
                self._LocalPetList[#self._LocalPetList+1] = pet
            end
        end
    end

    table.sort(self._LocalPetList , sortfunction)
    _G.ItemListMan.ShowItemListManPanel(self, 
                                        self._LocalPetList, 
                                        OnInitItem, 
                                        OnSelectItem, 
                                        _G.ShowTipType.ShowPetTip, 
                                        conditionFunc, 
                                        self:GetQualityGroup(), 
                                        EnumDef.ApproachMaterialType.PetAdvance)
end

--点击进阶按钮逻辑
def.method().OnClickBtn_Advance = function(self)
    local function SendC2SPetStarUp()
        --发送阶级协议
        CPetUtility.SendC2SPetStarUp(self._PetData._ID, self._CurrentSelectMeterialPetData._ID)
        local root = self._PanelObject.Group_Advance
        GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, root.GfxHook, root.GfxHook, 1, 20, 1)
    end

    if self._PetData:IsMaxStage() then
        --满阶
        TeraFuncs.SendFlashMsg(StringTable.Get(19041))
        return
    elseif self._CurrentSelectMeterialPetData == nil then
        --没选材料
        TeraFuncs.SendFlashMsg(StringTable.Get(19009))
        return
    elseif self._IsMaxAptitude and self._PetData._TalentLevel >= CPetUtility.GetMaxPetTalentLevel() then 
        local title, msg, closeType = StringTable.GetMsg(108)
        local  function callback(value)
            if value then 
                SendC2SPetStarUp()
            end
        end
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
        return
    elseif self._CurrentSelectMeterialPetData._Quality >= 3 then
        local title, msg, closeType = StringTable.GetMsg(107)
        local name = self._CurrentSelectMeterialPetData._Name
        msg = string.format(msg, self._CurrentSelectMeterialPetData:GetStage(), 
                             RichTextTools.GetPetNickNameRichText(self._CurrentSelectMeterialPetData._Tid, name, false),
                             tostring(self._CurrentSelectMeterialPetData._Level))

        local  function callback(value)
            if value then 
                SendC2SPetStarUp()
            end
        end
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
        return
    else
        -- local limitLevel = self._AdvanceLimitLevelInfo[self._PetData:GetStage()+1]
        -- if limitLevel > self._PetData:GetLevel() then
        --     --不满足进阶等级
        --     TeraFuncs.SendFlashMsg(string.format(StringTable.Get(19043), limitLevel))
        --     return
        -- end
    end

    --以上全部为过滤逻辑
    SendC2SPetStarUp()
end

--点击天赋 弹出tip逻辑
def.method().OnClickBtn_AdvanceTalent = function(self)
    local panelData = 
    {
        _TalentID = self._PetData._TalentId,
        _TalentLevel = self._PetData._TalentLevel,
        _TipPos = TipPosition.FIX_POSITION,
        _TargetObj = self._PanelObject.Btn_AdvanceTalent,
    }

    CItemTipMan.ShowPetSkillTips(panelData)
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_AddPetNeed" then
        self:ShowUIItemList()
    elseif id == "Btn_Advance" then
        self:OnClickBtn_Advance()
    elseif id == "Btn_Drop_PetNeed" then
        self:ResetMeterialPetInfo()
        self:UpdateProperty()
        -- self:UpdateInfo()
        self:UpdateTalent()

        CSoundMan.Instance():Play2DAudio(PATH.GUISound_UnEquipProcessing, 0)
    elseif id == "Btn_AdvanceTalent" then
        self:OnClickBtn_AdvanceTalent()
    elseif string.find(id, "Frame_Advance_Aptitude") then
        -- 暂时注释，后期修改显示方案
        -- local index = tonumber(string.sub(id, -1))
        -- self:ShowPropertyTip(index)
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
        Obj = self._Parent:GetUIObject("Frame_Advance_Aptitude"..index),
        Value = strDesc,
        AlignType = EnumDef.AlignType.Top,
    }
    game._GUIMan:Open("CPanelRoleInfoTips", param)
end

def.method('string').OnPointerLongPress = function(self,id)
    if id == "Img_ItemIcon" then 
        local panelData = 
            {
                _PetData = self._CurrentSelectMeterialPetData,
                _TipPos = TipPosition.FIX_POSITION,
                _TargetObj = nil , 
            }
            
        CItemTipMan.ShowPetTips(panelData)
    end
end

-- 计算进阶红点状态
def.method('=>', 'boolean').CalcRedDotState = function(self)
    if self._PetData == nil then return false end
    local bShowDot = CPetUtility.CalcPetAdvanceRedDotState(self._PetData)

    return (self._CurrentSelectMeterialPetData == nil and bShowDot)
end

def.method("boolean").PlayRedDotGfx = function(self, bShow)
    local obj = self._PanelObject.Group_Advance.RedDot
    if obj == nil then return end

    if bShow then
        GameUtil.PlayUISfx(PATH.UI_tongyong_tianjia_tishi, obj, obj, -1)
    else
        GameUtil.StopUISfx(PATH.UI_tongyong_tianjia_tishi, obj)
    end
end

def.method().Hide = function(self)
    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)
    
    self._Panel:SetActive(false)
    self._PanelObject = nil
    self._PetData = nil
    self._IsMaxAptitude = false
    self._CurrentSelectMeterialPetData = nil
end

def.method().Destroy = function (self)
    instance = nil
end

CPagePetAdvance.Commit()
return CPagePetAdvance