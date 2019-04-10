local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local CPetUtility = require "Pet.CPetUtility"

local CPanelCommonConltivate = Lplus.Extend(CPanelBase, 'CPanelCommonConltivate')
local def = CPanelCommonConltivate.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("userdata")._LabTitle = nil 
def.field("userdata")._Frame_Advance = nil 
def.field("userdata")._Frame_Recast = nil 
def.field("number")._CounterTimer = 0 
def.field("number")._CounterNum = 0
def.field("number")._CounterMax = 5

local OpenType = {
                   PetAdvanceResult = 1,
                   PetRecastResult = 2,
                }
def.const("table").OpenType = OpenType

local gfxBgDelay = 0.6
local gfxStarUpDelay = 1.05
local gfxStarDownDelay = 1.6
local ImgGroupType = 
{
    On = 0,
    Off = 1,
}

----------------------------------------------------------------------------------
--                                特效处理 Begin
----------------------------------------------------------------------------------
def.field("table")._GfxObjectGroup = nil
local gfxGroupName = "CPanelCommonConltivate"

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    if self._GfxObjectGroup ~= nil then
        self:StopGfx()
        self:StopGfxBg()
    end

    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.bgPanel = self._Panel
    root.GfxBgHook1 = self:GetUIObject("SelectItemGroup")
    root.GfxBgHook2 = self._Panel
    root.GfxBgHook3 = self:GetUIObject("Img_Title")

    root.GfxBg1 = PATH.UIFX_PET_AdvanceResult_BG1
    root.GfxBg2 = PATH.UIFX_PET_AdvanceResult_BG2
    root.GfxBg3 = PATH.UIFX_DEV_Recast_Inc
end

-- 播放背景特效
def.method().PlayGfxBg = function(self)
    local root = self._GfxObjectGroup
    if root~=nil then
        self:AddEvt_PlayFx(gfxGroupName, gfxBgDelay, root.GfxBg1, root.GfxBgHook1, root.GfxBgHook1, -1, 1)
        self:AddEvt_PlayFx(gfxGroupName, gfxBgDelay, root.GfxBg2, root.GfxBgHook2, root.GfxBgHook2, -1, 1)
        self:AddEvt_PlayFx(gfxGroupName, gfxBgDelay, root.GfxBg3, root.GfxBgHook3, root.GfxBgHook3, -1, 1)
    end
end
-- 关闭背景特效
def.method().StopGfxBg = function(self)
    self:KillEvts(gfxGroupName)
end
-- 播放特效
def.method().PlayGfx = function(self)
    local root = self._GfxObjectGroup
    if root~=nil then
        self:AddEvt_Shake(gfxGroupName, 0, 15, 0.5)
    end
end
-- 关闭特效
def.method().StopGfx = function(self)
end
-- 重置 组件和位置信息
def.method().ResetGfxGroup = function(self)
    local root = self._GfxObjectGroup
end

def.method().GfxLogic = function(self)
    local root = self._GfxObjectGroup
    if root~=nil then
        self:PlayGfx()
        self:PlayGfxBg()
    end
end

local instance = nil
def.static('=>', CPanelCommonConltivate).Instance = function ()
    if not instance then
        instance = CPanelCommonConltivate()
        instance._PrefabPath = PATH.UI_CommonCultivate
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

def.override().OnCreate = function(self)    
    self._LabTitle = self:GetUIObject("Lab_Text")
    self._Frame_Advance = self:GetUIObject("Frame_Advance") 
    self._Frame_Recast = self:GetUIObject("Frame_Recast") 

    self._PanelObject = 
    {
        PetIcon = self:GetUIObject("PetIcon"),
        Star = {},
        Aptitude = {},
        Talent = {},
        Lab_Next = self:GetUIObject("Lab_Next"),
        Btn_OK = self:GetUIObject('Btn_OK'),
    }

    -- 初始化特效组件
    self:InitGfxGroup()
end

local function SetClickType()
    instance._PanelCloseType = EnumDef.PanelCloseType.ClickAnyWhere
end
local function BtnActice()
    instance._PanelObject.Btn_OK:SetActive(true)
end
def.override("dynamic").OnData = function(self,data)
    local MaxAptitudeCount = CPetUtility.GetMaxAptitudeCount()   --资质最大个数
    -- 星级
    do
        local root = self._PanelObject.Star
        --最大星级为5
        for i= 1 ,5 do
            local str_On = string.format("Img_Star%d_On", i)
            local str_Bg = string.format("Img_Star%d_BG", i)
            local data = {}
            data.On = self:GetUIObject(str_On)
            data.BG = self:GetUIObject(str_Bg)
            table.insert(root, data)
        end
    end

    --资质
    for i=1, 5 do
        if i <= MaxAptitudeCount then 
            local aptitude = {}
            if data.Type == OpenType.PetAdvanceResult then 
                aptitude.Root = self._Frame_Advance:FindChild('Frame_PetValue'..i)
            elseif data.Type == OpenType.PetRecastResult then 
                aptitude.Root = self._Frame_Recast:FindChild('Frame_PetValue'..i)
                aptitude.Img_New = aptitude.Root:FindChild('Img_New')
            end
            
            aptitude.Lab_Aptitude = aptitude.Root:FindChild('Lab_Aptitude')
            aptitude.Lab_OldValue = aptitude.Root:FindChild('Lab_OldValue')
            aptitude.Lab_NewValue = aptitude.Root:FindChild('Lab_NewValue')
            aptitude.Img_Arrow = aptitude.Root:FindChild('Img_Arrow')
            aptitude.Img_Equal = aptitude.Root:FindChild('Img_Equal')
            aptitude.Lab_Range = aptitude.Root:FindChild('Lab_Range')            
            table.insert(self._PanelObject.Aptitude, aptitude)
        else
            local obj = self:GetUIObject('Frame_PetValue'..i)
            obj:SetActive(false)
        end
    end

     --天赋
    do
        local root = self._PanelObject.Talent
        root.Root = self:GetUIObject("Group_Talent")
        root.Lab_TalentName = self:GetUIObject("Lab_TalentName")
        root.Lab_Max = self:GetUIObject("Lab_TalentLevelMax")
        root.Talent_Change = self:GetUIObject("Frame_Change")
        root.Img_Up = self:GetUIObject("Img_TalentArrow")
        root.Img_Equal = self:GetUIObject("Img_TalentEqual")
        root.Lab_Add = self:GetUIObject("Lab_TalentChange")
        root.Lab_Des = self:GetUIObject("Lab_TalentDesc")
    end

    if data.Type == OpenType.PetAdvanceResult then 
        self._Frame_Advance:SetActive(true)
        self._Frame_Recast:SetActive(false)
        GUI.SetText(self._LabTitle,StringTable.Get(19079))
        self:ShowPetAdvanceResult(data.NewData,data.OldData)
    elseif data.Type == OpenType.PetRecastResult then 
        self._Frame_Advance:SetActive(false)
        self._Frame_Recast:SetActive(true)
        GUI.SetText(self._LabTitle,StringTable.Get(19160))
        self:ShowPetRecastResult(data.NewData,data.OldData)
    end

    self:GfxLogic()
    self:AddEvt_LuaCB(gfxGroupName, self._CounterMax, SetClickType)
    -- self:StartCounter()
    self._PanelObject.Btn_OK:SetActive(false)
    self:AddEvt_LuaCB(gfxGroupName, 0.65, BtnActice)
end

local function CounterTick(self)
    if instance:IsShow() then
        instance._CounterNum = instance._CounterNum - 1

        if instance._CounterNum <= 0 then
            local str = StringTable.Get(31607)
            GUI.SetText(instance._PanelObject.Lab_Next, str)
            instance:StopCounter()
        else
            local str = string.format(StringTable.Get(31606), instance._CounterNum)
            GUI.SetText(instance._PanelObject.Lab_Next, str)
        end
    end
end
def.method().StartCounter = function(self)
    self:StopCounter()
    self._CounterNum = self._CounterMax + 1
    self._CounterTimer = _G.AddGlobalTimer(1, false, CounterTick)
end
def.method().StopCounter = function(self)
    if self._CounterTimer > 0 then
        _G.RemoveGlobalTimer(self._CounterTimer)
    end    
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Back' then
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Exit' then
        game._GUIMan:CloseSubPanelLayer()
    elseif id == "Btn_OK" then
        game._GUIMan:CloseByScript(self)
    end
    CPanelBase.OnClick(self, id)
end

-- 天赋
local function InitTalent(self,NewPetData,OldPetData)
    local root = self._PanelObject.Talent
    local talentTemplate = CElementData.GetTemplate("Talent", NewPetData.specialTalentSkillId)
    if talentTemplate == nil then 
        root.Root:SetActive(false)
        return
    end
    GUI.SetText(root.Lab_TalentName, string.format(StringTable.Get(10663), talentTemplate.Name, NewPetData.specialTalentSkillLevel))
    GUI.SetText(root.Lab_Des, DynamicText.ParseSkillDescText(NewPetData.specialTalentSkillId, NewPetData.specialTalentSkillLevel, true))
    if NewPetData.specialTalentSkillLevel == OldPetData.specialTalentSkillLevel then 
        root.Talent_Change:SetActive(true)
        root.Img_Equal:SetActive(true)
        root.Img_Up:SetActive(false)
        root.Lab_Add:SetActive(false)
    elseif NewPetData.specialTalentSkillLevel > OldPetData.specialTalentSkillLevel then 
        root.Talent_Change:SetActive(true)
        root.Img_Equal:SetActive(false)
        root.Img_Up:SetActive(true)
        root.Lab_Add:SetActive(true)
        GUI.SetText(root.Lab_Add,tostring(NewPetData.specialTalentSkillLevel - OldPetData.specialTalentSkillLevel))
    end
    if NewPetData.specialTalentSkillLevel == CPetUtility.GetMaxPetTalentLevel() then 
        root.Lab_Max:SetActive(true)
    else
        root.Lab_Max:SetActive(false)
    end
end

-- 资质
local function InitAptitude(self,NewPetData,OldPetData)
    local root = self._PanelObject.Aptitude
    local template = CElementData.GetTemplate("Pet", NewPetData.tId)
    local ids = string.split(template.AttachedPropertyGeneratorIds, "*")

    for i=1, #NewPetData.aptitudes do
        local NewAptitudeInfo = NewPetData.aptitudes[i]
        local OldAptitudeInfo = OldPetData.aptitudes[i]
        local UIInfo = root[i]
        local propertyInfo = CElementData.GetPropertyInfoById( NewAptitudeInfo.id )
        if propertyInfo == nil then return nil end
        GUI.SetText(UIInfo.Lab_Aptitude, propertyInfo.Name)
        if UIInfo.Img_New ~= nil then 
            UIInfo.Img_New:SetActive(false)
        end  
        if UIInfo.Lab_Range ~= nil then
            local limitInfoId = tonumber(ids[i])    
            local propertyInfo = CElementData.GetPropertyInfoById( limitInfoId )
            GUI.SetText(UIInfo.Lab_Range, string.format(StringTable.Get(19084),propertyInfo.MinValue, propertyInfo.MaxValue))
        end       
        if NewAptitudeInfo.value > OldAptitudeInfo.value then 
            UIInfo.Img_Arrow:SetActive(true)
            UIInfo.Img_Equal:SetActive(false)
            GUITools.SetGroupImg(UIInfo.Img_Arrow,1)
            GUI.SetText(UIInfo.Lab_NewValue,  string.format(StringTable.Get(19080),NewAptitudeInfo.value))
        elseif NewAptitudeInfo.value < OldAptitudeInfo.value then
            UIInfo.Img_Arrow:SetActive(true)
            UIInfo.Img_Equal:SetActive(false)
            GUITools.SetGroupImg(UIInfo.Img_Arrow,0)
            GUI.SetText(UIInfo.Lab_NewValue,  string.format(StringTable.Get(19081),NewAptitudeInfo.value))
        elseif NewAptitudeInfo.value == OldAptitudeInfo.value then
            UIInfo.Img_Arrow:SetActive(false)
            UIInfo.Img_Equal:SetActive(true)
            GUI.SetText(UIInfo.Lab_NewValue,  tostring(NewAptitudeInfo.value))
        end
        GUI.SetText(UIInfo.Lab_OldValue,  tostring(OldAptitudeInfo.value))
        if NewAptitudeInfo.value == NewAptitudeInfo.maxValue then 
            GUI.SetText(UIInfo.Lab_NewValue,  StringTable.Get(19077))
        end
        if OldAptitudeInfo.value == OldAptitudeInfo.maxValue then 
            GUI.SetText(UIInfo.Lab_OldValue,  StringTable.Get(19077))
        end 
    end
end

local function InitBaseInfo(self,newPet,oldPet)
    --图标
    do
        local PetIcon = self._PanelObject.PetIcon 
        local img_ItemIcon = PetIcon:FindChild("Img_ItemIcon")
        local img_Quality = PetIcon:FindChild("Img_Quality")
        local lab_Lv = PetIcon:FindChild("Lab_Lv")
        local petTemp = CElementData.GetTemplate("Pet", newPet.tId)
        GUITools.SetIcon(img_ItemIcon, petTemp.IconPath)
        GUITools.SetGroupImg(img_Quality, petTemp.Quality)
        GUI.SetText(lab_Lv, string.format(StringTable.Get(19078),newPet.level))
    end

    local oldStage = oldPet.stage
    local newStage = newPet.stage

    -- oldStage = 1
    -- newStage = 5

    local incStageCnt = newStage - oldStage
    local delayInterval = 0.2
    local MaxStage = CPetUtility.GetMaxPetStage()
    local root = self._PanelObject.Star
    -- warn("old = ", oldStage, "newStage = ", newStage)

    -- reset
    for i = 1, 5 do
        local bShow = i <= MaxStage
        local imgStar = root[i]
        imgStar.On:SetActive(bShow)
        imgStar.BG:SetActive(bShow)

        if bShow then
            local tag = (incStageCnt == 0 and newStage >= i) and ImgGroupType.On or ImgGroupType.Off
            GUITools.SetGroupImg(imgStar.On, tag)
        end
    end

    local processIndex = 1
    local function ShowUpGfx()
        local imgStar = root[processIndex].On
        GUITools.SetGroupImg(imgStar,ImgGroupType.On)
        processIndex = processIndex + 1
    end
    local function ShowDownGfx()
        -- warn("processIndex ------- ", processIndex)
        local imgStar = root[processIndex].On
        GUITools.SetGroupImg(imgStar,ImgGroupType.Off)
        processIndex = processIndex - 1
    end

    if incStageCnt > 0 then
        local incIndex = 0
        for i = 1, newStage do
            local imgStar = root[i].On
            if oldStage >= i then
                GUITools.SetGroupImg(imgStar,ImgGroupType.On)
                processIndex = i + 1
            else
                local delayTime = incIndex * delayInterval + gfxStarUpDelay
                local tweenId = string.format("%d1", i)
                local gfx = PATH.UIFX_PET_Advance_shengxing

                self:AddEvt_LuaCB(gfxGroupName, delayTime, ShowUpGfx)
                self:AddEvt_PlayFx(gfxGroupName, delayTime+1.55, gfx, imgStar,imgStar, -1, 1)
                self:AddEvt_PlayDotween(gfxGroupName, delayTime, self._GfxObjectGroup.DoTweenPlayer, tweenId)

                incIndex = incIndex + 1
            end
        end
    elseif incStageCnt < 0 then
        local decIndex = 0
        processIndex = oldStage
        for i = 1, oldStage do
            local index = oldStage - i + 1
            -- warn("oldStage = ", oldStage, index)
            local imgStar = root[index].On
            if newStage >= index then
                GUITools.SetGroupImg(imgStar,ImgGroupType.On)
                processIndex = 5 - index + 1
                -- warn("Set :: processIndex = ", processIndex, index)
            else
                -- warn("oldStage >= index = ", oldStage >= index , oldStage ,index)
                if oldStage >= index then
                    GUITools.SetGroupImg(imgStar, ImgGroupType.On)
                end

                local delayTime = decIndex * delayInterval + gfxStarDownDelay
                local tweenId = string.format("%d0", index)
                local gfx = PATH.UIFX_PET_Advance_jiangxing

                self:AddEvt_LuaCB(gfxGroupName, gfxStarDownDelay, ShowDownGfx)
                self:AddEvt_PlayDotween(gfxGroupName, gfxStarDownDelay + 1.4, self._GfxObjectGroup.DoTweenPlayer, tweenId)
                self:AddEvt_PlayFx(gfxGroupName, gfxStarDownDelay, gfx, imgStar,imgStar, -1, 1)

                decIndex = decIndex + 1
            end
        end
    end
end

def.method("table","table").ShowPetAdvanceResult = function(self,NewPetData,OldPetData)
    InitBaseInfo(self,NewPetData,OldPetData)
    InitAptitude(self,NewPetData,OldPetData)
    InitTalent(self,NewPetData,OldPetData)
end

def.method("table","table").ShowPetRecastResult = function(self,NewPetData,OldPetData)
    InitBaseInfo(self,NewPetData,OldPetData)
    InitAptitude(self,NewPetData,OldPetData)
    local root = self._PanelObject.Talent
    root.Root:SetActive(false)
end

def.override().OnHide = function(self)
    self:StopCounter()
    self:StopGfx()
    self:StopGfxBg()
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    instance = nil
end

CPanelCommonConltivate.Commit()
return CPanelCommonConltivate