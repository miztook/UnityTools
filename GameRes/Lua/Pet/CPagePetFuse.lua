--宠物融合

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetFuse = Lplus.Class("CPagePetFuse")
local def = CPagePetFuse.define

local DynamicText = require "Utility.DynamicText"
local CElementData = require "Data.CElementData"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CPetUtility = require "Pet.CPetUtility"

-- 一次融合最大材料个数
local MAX_MATERIAL_COUNT = 5

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil                   -- 存放UI的集合
def.field("table")._PetData = nil                       -- 当前选中的Pet数据
def.field("table")._CurrentSelectMeterialPetData = nil  -- 当前选中当材料用的宠物索引
def.field("table")._LocalPetList = BlankTable           -- 本地筛选排序的列表
def.field("table")._AdvanceLimitLevelInfo = nil         -- 进阶等级限制
def.field("table")._MaterialPetDataList = nil

local listQuality = 
{
    2, -- 稀有
    3, -- 史诗
    5, -- 传说
}

local function SendFlashMsg(msg)
    game._GUIMan:ShowTipText(msg, false)
end

local instance = nil
def.static("table", "userdata", "=>", CPagePetFuse).new = function(parent, panel)
    if instance == nil then
        instance = CPagePetFuse()
        instance._Parent = parent
        instance._Panel = panel
    end
    
    return instance
end

def.method().InitPanel = function(self)
    local MaxAptitudeCount = CPetUtility.GetMaxAptitudeCount()   --资质最大个数
    self._AdvanceLimitLevelInfo = CPetUtility.GetAdvanceLvLimitInfo()

    self._PanelObject = {
        PropertyList = {},
        AptitudeList = {},
        Group_Fuse = {},
        Group_FuseTalent = {},
        Btn_Fuse = self._Parent:GetUIObject("Btn_Fuse"),
        Btn_FuseTalent = self._Parent:GetUIObject("Btn_FuseTalent")
    }

    --资质
    for i=1, 5 do
        if i <= MaxAptitudeCount then 
            local aptitude = {}
            aptitude.Root = self._Parent:GetUIObject('Frame_Fuse_Aptitude'..i)
            aptitude.Lab_Aptitude = aptitude.Root:FindChild('Lab_Aptitude')
            local sld = aptitude.Root:FindChild('Sld_Aptitude')
            aptitude.Sld = sld:GetComponent(ClassType.Slider)
            aptitude.Lab_Value = sld:FindChild('Lab_Value')
            aptitude.Img_AddValue = sld:FindChild('Img_AddValue')
            aptitude.Img_Up = sld:FindChild('Img_Up')
            aptitude.Img_CanReset = aptitude.Root:FindChild("Img_CanReset")

            table.insert(self._PanelObject.AptitudeList, aptitude)
        else
            local obj = self._Parent:GetUIObject('Frame_Fuse_Aptitude'..i)
            obj:SetActive(false)
        end
    end

    -- 天赋
    do
        local root = self._PanelObject.Group_FuseTalent
        root.TalentIcon = self._Parent:GetUIObject('Img_FuseTalentIcon')
        root.Lab_TalentName = self._Parent:GetUIObject('Lab_FuseTalentName')
        root.Frame_TalentAdd = self._Parent:GetUIObject('Frame_FuseTalentAdd')
        root.Lab_Add = self._Parent:GetUIObject('Lab_FuseTalentAdd')
        root.Lab_Max = self._Parent:GetUIObject('Lab_FuseTalentMaxLevel')
    end

    do
        local root = self._PanelObject.Group_Fuse
        root.Root = self._Parent:GetUIObject("Group_Fuse")
        local SelectFuseItemGroup = self._Parent:GetUIObject("SelectFuseItemGroup")

        root.ItemList = {}
        for i=1,5 do
            local info = {}
            info.Item = SelectFuseItemGroup:FindChild("Item"..i)
            info.SelectPetNeed = info.Item:FindChild("SelectFusePetNeed"..i)
            info.Btn_Drop_PetNeed = info.Item:FindChild("Btn_Drop_FusePetNeed"..i)
            info.Btn_AddPetNeed = info.Item:FindChild("Btn_AddFusePetNeed"..i)

            info.Img_ItemIcon = info.SelectPetNeed:FindChild("Img_ItemIcon")
            info.Img_Quality = info.SelectPetNeed:FindChild("Img_Quality")
            info.Img_QualityBG = info.SelectPetNeed:FindChild("Img_QualityBG")
            info.Lab_Lv = info.SelectPetNeed:FindChild("Lab_Lv")

            table.insert(root.ItemList, info)
        end
    end
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end

    if EPetOptType.EPetOptType_advance == event._Type then
        instance:UpdatePanel()
    end
end

def.method("table").UpdateSelectPet = function(self, data)
    self._Panel:SetActive(data ~= nil)
    self:ResetMeterialPetInfo()

    self._PetData = data
    if self._PetData == nil then return end
    
    self:UpdatePanel()
end

def.method().ResetMeterialPetInfo = function(self)
    -- 清空 主列表选中置灰状态
    self._Parent:ClearAdvanceMeterialPetList()

    -- 清空 分页签列表状态
    local root = self._PanelObject.Group_Fuse
    local maxCnt = #root.ItemList

    for i=1, maxCnt do
        local UIInfo = root.ItemList[i]
        local bActive = i == maxCnt
        UIInfo.Item:SetActive( bActive )
        if bActive then
            UIInfo.Btn_Drop_PetNeed:SetActive( false )
            UIInfo.Btn_AddPetNeed:SetActive( true )
            -- icon
            UIInfo.Img_ItemIcon:SetActive( false )
            UIInfo.Img_Quality:SetActive( false )
            UIInfo.Img_QualityBG:SetActive( false )
            UIInfo.Lab_Lv:SetActive( false )
        end
    end
    GUITools.SetBtnGray(self._PanelObject.Btn_Fuse, true)
    self._MaterialPetDataList = {}
end

def.method("=>", "table").CalcMaterialProperty = function(self)
    local retTable = {}

    -- 融合目标主宠
    local petData = self._PetData
    for i=1, #self._MaterialPetDataList do
        local petId = self._MaterialPetDataList[i]
        local materialPetData = self:GetLocalPetDataById(petId)
        if materialPetData then
            local addInfoList = CPetUtility.CalcFuseInfo(petData, materialPetData)
            for aptIndex=1, #petData._AptitudeList do
                if retTable[aptIndex] then
                    retTable[aptIndex] = retTable[aptIndex] + addInfoList[aptIndex]
                else
                    retTable[aptIndex] = addInfoList[aptIndex]
                end
            end
        end
    end

    return retTable
end

def.method().UpdateProperty = function(self)
    --warn("UpdatePanel 资质")
    --资质
    local petData = self._PetData
    local bHasMaterialPet = #self._MaterialPetDataList > 0
    local root = self._PanelObject.AptitudeList

    if bHasMaterialPet then
        local petAptitudes = petData._AptitudeList
        local addInfoList = self:CalcMaterialProperty()

        for i=1, #petData._AptitudeList do
            local UIInfo = root[i]
            local aptitudeInfo = petAptitudes[i]
            local aptitudeMax = aptitudeInfo.MaxValue

            local addValue = addInfoList[i]
            if (aptitudeInfo.Value + addValue) > aptitudeMax then 
                addValue = aptitudeMax - aptitudeInfo.Value
            end
            UIInfo.Img_AddValue:SetActive(addValue > 0)
            UIInfo.Img_Up:SetActive(addValue > 0)
            UIInfo.Img_CanReset:SetActive( aptitudeInfo.CanReset ) 
            local imgfill = UIInfo.Img_AddValue:GetComponent(ClassType.Image)
            imgfill.fillAmount = math.clamp((aptitudeInfo.Value + addValue)/aptitudeMax, 0, 1)
            if addValue > 0 then
                GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19075),aptitudeInfo.Value,addValue,aptitudeMax))
            else
                if aptitudeInfo.Value >= aptitudeMax then 
                    GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19074), aptitudeMax))
                else
                    GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19070), aptitudeInfo.Value, aptitudeMax))
                end
            end
        end
    else
        for i=1, #petData._AptitudeList do
            local aptitudeInfo = petData._AptitudeList[i]
            local aptitudeMax = aptitudeInfo.MaxValue
            local UIInfo = root[i]
            GUI.SetText(UIInfo.Lab_Aptitude, aptitudeInfo.Name)
            UIInfo.Img_AddValue:SetActive(false)
            UIInfo.Img_Up:SetActive(false)
            UIInfo.Img_CanReset:SetActive( aptitudeInfo.CanReset ) 
            if aptitudeInfo.Value >= aptitudeMax then 
                GUI.SetText(UIInfo.Lab_Value, string.format(StringTable.Get(19074), aptitudeMax))
            else
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
    local root = self._PanelObject.Group_FuseTalent
    if self._CurrentSelectMeterialPetData ~= nil and data._TalentId == self._CurrentSelectMeterialPetData._TalentId and self._CurrentSelectMeterialPetData._TalentLevel > 0 and data._TalentLevel < maxTalentLv then 
        local addLevel = self._CurrentSelectMeterialPetData._TalentLevel
        root.Frame_TalentAdd:SetActive(true)
        if (data._TalentLevel + addLevel) > maxTalentLv then 
            addLevel  = maxTalentLv - data._TalentLevel
        end
        GUI.SetText(root.Lab_Add,tostring(addLevel))
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
    self:UpdateProperty()
    -- self:UpdateInfo()
    self:UpdateTalent()
    self:PlayRedDotGfx( self:CalcRedDotState() )
end

-- 更新材料选中状态
def.method().UpdateMaterialPet = function(self)
    local root = self._PanelObject.Group_Fuse
    local maxCnt = #root.ItemList
    local curCnt = #self._MaterialPetDataList
    -- warn("选中的宠物个数 ： ", curCnt)

    for i=1, maxCnt do
        local UIInfo = root.ItemList[i]
        local bActive = curCnt + 1 >= i

        UIInfo.Item:SetActive( bActive )
        if bActive then
            local bHasPet = curCnt >= i
            UIInfo.Btn_Drop_PetNeed:SetActive( bHasPet )
            UIInfo.Btn_AddPetNeed:SetActive( not bHasPet )
            -- icon
            UIInfo.Img_ItemIcon:SetActive( bHasPet )
            UIInfo.Img_Quality:SetActive( bHasPet )
            UIInfo.Img_QualityBG:SetActive( bHasPet )
            UIInfo.Lab_Lv:SetActive( bHasPet )
            if bHasPet then
                local petId = self._MaterialPetDataList[i]
                local petItem = self:GetLocalPetDataById( petId )
                if petItem then
                    GUITools.SetIcon(UIInfo.Img_ItemIcon, petItem._IconPath)
                    GUITools.SetGroupImg(UIInfo.Img_Quality, petItem._Quality)
                    GUITools.SetGroupImg(UIInfo.Img_QualityBG, petItem._Quality)
                    GUI.SetText(UIInfo.Lab_Lv, string.format(StringTable.Get(10641), petItem._Level))
                end
            end
        end
    end
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

def.method("number", "=>", "table").GetLocalPetDataById = function(self, petId)
    for _, petData in ipairs(self._LocalPetList) do
        if petData._ID == petId then
            return petData
        end
    end

    return nil
end

local function OnInitItem(self, item, data)
    local Frame_SkillbookInfo = item:FindChild("Frame_SkillbookInfo")
    local Frame_PetInfo = item:FindChild("Frame_PetInfo")
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    local Frame_PetIcon = item:FindChild("Btn_Icon/PetIcon")
    local Frame_ItemIcon = item:FindChild("Btn_Icon/ItemIconNew")
    local selectBG = item:FindChild("Img_BgHighLight")

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

    local petId = data._ID
    local oldIndex = table.indexof(self._MaterialPetDataList, petId)
    local bSelected = oldIndex~=false
    selectBG:SetActive(bSelected)
end

local function OnSelectItem(self, item, data, bIsConfirm)
    -- confirm时，列表已经准备好，此时有可能没有选中item
    if not bIsConfirm then
        local selectBG = item:FindChild("Img_BgHighLight")
        local petId = data._ID
        local oldIndex = table.indexof(self._MaterialPetDataList, petId)

        if oldIndex then
            table.remove(self._MaterialPetDataList, oldIndex)
        else
            if #self._MaterialPetDataList == MAX_MATERIAL_COUNT then
                SendFlashMsg(StringTable.Get(28003))
                return false
            end

            table.insert(self._MaterialPetDataList, petId)
        end
        selectBG:SetActive(oldIndex==false)
    end

    -- warn("list count = ", #self._MaterialPetDataList)
    if bIsConfirm then
        -- 更新主页签 列表选中状态
        self._Parent:UpdateAdvanceMeterialPetList(self._MaterialPetDataList)
        -- 更新分页签 右侧选中状态
        self:UpdateMaterialPet()
        self:UpdateProperty()
        self:UpdateTalent()
        GUITools.SetBtnGray(self._PanelObject.Btn_Fuse, false)

        return #self._MaterialPetDataList > 0
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

    for i=1, #allPetList do
        local pet = allPetList[i]
        
        --材料不能为出战 助战宠物
        if (hp:IsFightingPetById(pet._ID) or hp:IsHelpingPetById(pet._ID)) == false then
            --if pet._Tid == self._PetData._Tid and pet._ID ~= self._PetData._ID and pet:GetStage() == self._PetData:GetStage() then
                --self._LocalPetList[#self._LocalPetList+1] = pet
            --end
            if pet._ID ~= self._PetData._ID then
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
                                        EnumDef.ApproachMaterialType.PetFuse)
end

--点击进阶按钮逻辑
def.method().OnClickBtn_Fuse = function(self)
    local function SendC2SPetFuse()
        --发送阶级协议
        CPetUtility.SendC2SPetFuse(self._PetData._ID, self._MaterialPetDataList)
        local root = self._PanelObject.Group_Fuse
        -- GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, root.GfxHook, root.GfxHook, 1, 20, 1)
    end

    if #self._MaterialPetDataList == 0 then
        --没选材料
        SendFlashMsg(StringTable.Get(19014))
    elseif self:HasValuableMaterialPet() then
        local title, msg, closeType = StringTable.GetMsg(130)
        local  function callback(value)
            if value then 
                SendC2SPetFuse()
            end
        end
        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL,callback)
    else
        --以上全部为过滤逻辑
        SendC2SPetFuse()
    end
end

def.method("=>", "boolean").HasValuableMaterialPet = function(self)
    local bRet = false
    for i=1, #self._MaterialPetDataList do
        local petId = self._MaterialPetDataList[i]
        local petData = self:GetLocalPetDataById(petId)
        if petData then
            if petData._Quality >= 3 then
                bRet = true
                break
            end
        end
    end

    return bRet
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_Fuse" then
        self:OnClickBtn_Fuse()
    elseif id == "Btn_FuseTalent" then
        self:OnClickBtn_FuseTalent()
    elseif string.find(id, "Btn_AddFusePetNeed") then
        self:ShowUIItemList()
    elseif string.find(id, "Btn_Drop_FusePetNeed") then
        local index = tonumber(string.sub(id, -1))
        self:OnClickBtn_AddFusePetNeed(index)
    elseif string.find(id, "Frame_Fuse_Aptitude") then
        -- 暂时注释，后期修改显示方案
        -- local index = tonumber(string.sub(id, -1))
        -- self:ShowPropertyTip(index)
    end
end

def.method("number").OnClickBtn_AddFusePetNeed = function(self, index)
    table.remove(self._MaterialPetDataList, index)
    self:UpdateMaterialPet()
    self:UpdateProperty()
    self:UpdateTalent()

    self._Parent:UpdateAdvanceMeterialPetList(self._MaterialPetDataList)
end

--点击天赋 弹出tip逻辑
def.method().OnClickBtn_FuseTalent = function(self)
    local panelData = 
    {
        _TalentID = self._PetData._TalentId,
        _TalentLevel = self._PetData._TalentLevel,
        _TipPos = TipPosition.FIX_POSITION,
        _TargetObj = self._PanelObject.Btn_FuseTalent,
    }

    CItemTipMan.ShowPetSkillTips(panelData)
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
        Obj = self._Parent:GetUIObject("Frame_Fuse_Aptitude"..index),
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
    local obj = self._PanelObject.Group_Fuse.RedDot
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
    self._MaterialPetDataList = {}
end

def.method().Destroy = function (self)
    instance = nil
end

CPagePetFuse.Commit()
return CPagePetFuse