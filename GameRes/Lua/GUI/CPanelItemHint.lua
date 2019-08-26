
local Lplus = require 'Lplus'
local CPanelHintBase = require 'GUI.CPanelHintBase'
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local DynamicText = require "Utility.DynamicText"
local CElementData = require "Data.CElementData"
local EItemEventType = require "PB.data".EItemEventType
local EItemBindMode = require "PB.Template".Item.ItemBindMode
local bit = require "bit"

local EItemType = require "PB.Template".Item.EItemType
local CPanelBase = require "GUI.CPanelBase"
local CPanelItemHint = Lplus.Extend(CPanelHintBase, 'CPanelItemHint')
local def = CPanelItemHint.define

 
def.field("userdata")._FrameContent1 = nil
def.field("userdata")._Frame_Basic1 = nil
def.field("userdata")._FrameBottom1 = nil 
def.field("userdata")._FrameContent2 = nil
def.field("userdata")._FrameBottom2 = nil 

def.field("table")._FramesDress = BlankTable
def.field("number")._ItemCoolDownTimer1 = 0
def.field("number")._ItemExpireTimer1 = 0 
def.field("number")._ItemCoolDownTimer2 = 0
def.field("number")._ItemExpireTimer2 = 0 
def.field("table")._TalentData = nil 
def.field("table")._GetItemIds = BlankTable                          -- 礼包获得的物品
def.field("table")._GetItemPers = BlankTable                         -- 开启礼包获得物品的百分比
def.field("table")._CompareItemData = nil 

local instance = nil
def.static('=>', CPanelItemHint).Instance = function ()
    --print("CPanelItemHint Instance")
	if not instance then
        instance = CPanelItemHint()
        instance._PrefabPath = PATH.UI_ItemHint
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    -- self._Lab_EquipTips = self:GetUIObject('Lab_EquipTips')
    self._FrameContent1 = self:GetUIObject("Frame_Content1")
    self._Frame_Basic1 = self:GetUIObject('Frame_Basic1')
    self._Lay_Button = self:GetUIObject("Lay_Button")
    
    self._Scroll1 = self:GetUIObject("Scroll1")
    self._Scroll2 = self:GetUIObject("Scroll2")
    self._FrameBottom1 = self:GetUIObject("Frame_Bottom1")
    do
        self._FramesDress = {}
        self._FramesDress[#self._FramesDress + 1] = {}
        -- local Frame_Content = self:GetUIObject('Frame_Content')
        self._FramesDress[#self._FramesDress].Frame_Color = self:GetUIObject('Frame_ColorAttri1')

        self._FramesDress[#self._FramesDress].Part1 = self:GetUIObject('Frame_PartColor11')
        self._FramesDress[#self._FramesDress].Part2 = self:GetUIObject('Frame_PartColor12')

        self._FramesDress[#self._FramesDress].ImageColor1 = self:GetUIObject('Img_Color11')
        self._FramesDress[#self._FramesDress].ImageColor2 = self:GetUIObject('Img_Color12')
        self._FramesDress[#self._FramesDress + 1] = {} 
        self._FramesDress[#self._FramesDress].Frame_Color = self:GetUIObject('Frame_ColorAttri2')

        self._FramesDress[#self._FramesDress].Part1 = self:GetUIObject('Frame_PartColor21')
        self._FramesDress[#self._FramesDress].Part2 = self:GetUIObject('Frame_PartColor22')

        self._FramesDress[#self._FramesDress].ImageColor1 = self:GetUIObject('Img_Color21')
        self._FramesDress[#self._FramesDress].ImageColor2 = self:GetUIObject('Img_Color22')


    end

end

def.override("dynamic").OnData = function(self, data)
    CPanelBase.OnData(self,data)

    self._ItemData = data.itemCellData
    if self._ItemData._Template == nil or self._ItemData._Tid == 0 then 
        warn("CPanelItemHint InitFrame cannot find")
        return 
    end
    self._CompareItemData = data.compareItemData
    self._CallWithFuncs = data.withFuncs
    if not data.withFuncs then
        self._PopFrom = data.params
    else
        self._ValidComponents = data.params
    end

    if self._CompareItemData == nil then
        self._IsShowCompare = false
    else
        self._IsShowCompare = true
    end 
    self:InitPanel()
   
    -- CItemTipMan.InitTipPosition(frameFixedPosition, self._Scroll1, 0)
end

def.method().InitPanel = function (self)
    self._Scroll2:SetActive(false)
    self:InitFrame(false)
    self:InitBaseInfo(false)
    self._ItemCoolDownTimer1,self._ItemExpireTimer1 = self:InitTips(false)
    if self._IsShowCompare then 
        self:InitBaseInfo(self._IsShowCompare)
        self:InitFrame(self._IsShowCompare)
        self._Scroll2:SetActive(true)
        self._ItemCoolDownTimer2,self._ItemExpireTimer2 = self:InitTips(true)
    end
  
    if self._PopFrom ~= TipsPopFrom.CHAT_PANEL and self._PopFrom ~= TipsPopFrom.ITEM_DBPANEL then 
        self._Lay_Button :SetActive(true)
        self:InitButtons(self._Lay_Button)
        self._IsShowButton = true
    else
        self._Lay_Button:SetActive(false)
        self._IsShowButton = false
    end
    
    -- 设置按钮位置
    self:InitButtonPosition( self._FrameBottom1,self._Lay_Button)
    if self._IsShowCompare then 
        self:InitTipSize(true)
        self:IsSetCompareTipCenter(true)
    end  
end

def.method("boolean").InitTipSize = function (self,isShowCompare)
    local index = 1
    if isShowCompare then 
        index = 2
    end
    local scrollObj = self:GetUIObject("Scroll"..index)
    local maskObj = self:GetUIObject("Mask"..index)
    local FrameBase = self:GetUIObject("Frame_Basic"..index)
    local FrameContent = self:GetUIObject("Frame_Content"..index)
    local FrameBottom = self:GetUIObject("Frame_Bottom"..index)
    local scrollRect = scrollObj:GetComponent(ClassType.RectTransform)
    local maskRect = maskObj:GetComponent(ClassType.RectTransform)
    local titleRect = FrameBase:GetComponent(ClassType.RectTransform)
    local heightContent = GameUtil.GetTipLayoutHeight(FrameContent)
    local heightBottom = GameUtil.GetPreferredHeight(FrameBottom:GetComponent(ClassType.RectTransform))
    local height = heightContent + heightBottom

    if height <= 315 then
        height = 315
        GameUtil.SetScrollEnabled(scrollObj,false)
    elseif height >= 430 then
        height = 430
    end
    local maskSizeDelta = maskRect.sizeDelta
    maskSizeDelta.y = height - heightBottom
    maskRect.sizeDelta = maskSizeDelta
    local sizeDelta = scrollRect.sizeDelta
    sizeDelta.y = height + 101
    scrollRect.sizeDelta = sizeDelta

    scrollObj.localPosition = Vector3.New(0,0,0)
end

def.override("string").OnClick = function(self,id)
    local component = nil 
    if string.find(id,"Btn_GetType")then
        local i = tonumber(string.sub(id,-1))
        local itemData = nil
        if i == 1 then
            itemData = self._ItemData
        else
            itemData = self._CompareItemData
        end 
        local PanelData = 
        {
            ApproachIDs = itemData._Template.ApproachID,
            ParentObj = self._Scroll1,
            IsFromTip = true,
            TipPanel = self,
            ItemId = itemData._Tid,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData)
    elseif string.find(id,"Btn_Talent") then
        local index = tonumber(string.sub(id,-1))
        local obj = self:GetUIObject(id)
        local panelData = 
        {
            SkillName = self._TalentData[index].Name,
            SkillDes = self._TalentData[index].Desc,
            TargetObj = obj,
        }
        game._GUIMan:Open("CPanelSkillDes",panelData)
    elseif string.find(id,"GiftItemIcon") then 

        local index = tonumber(string.sub(id,-1))
        local PanelData = {
                               ItemId = self._GetItemIds[1][index],
                               Percent = self._GetItemPers[1][index],
                               TipPanel = self,
                               TargetObj = self._Frame_Basic1,
                          }
        game._GUIMan:Open("CPanelGiftItem",PanelData)
    end
end

def.method("boolean").InitFrame = function(self,isShowCompare)
    local itemData = self._ItemData
    if isShowCompare then 
        itemData = self._CompareItemData
    end
    if itemData._ItemType == EItemType.Rune then
        self:InitRune(isShowCompare)
    elseif itemData._ItemType == EItemType.Charm then
        self:InitCharmItem(isShowCompare)
    elseif itemData._ItemType == EItemType.Dress then
        self:InitDressItem(isShowCompare)
    elseif itemData._ItemType == EItemType.NoramlItem then 
        self:InitNoramlItem(isShowCompare)
    elseif itemData._ItemType == EItemType.Pet then 
        self:InitPetEggItem(isShowCompare)
    elseif itemData._ItemType == EItemType.TreasureBox then 
        self:InitGiftBag(isShowCompare)
    elseif itemData._ItemType == EItemType.EnchantReel then 
        self:InitEnchantReel(isShowCompare)
    else
        self:InitUseType(isShowCompare)
    end
end

def.method("boolean").InitBaseInfo = function (self,isCompare)
    local index = 1
    local itemElement = self._ItemData._Template 
    local itemData = self._ItemData
    if isCompare then 
        index = 2
        itemElement = self._CompareItemData._Template
        itemData = self._CompareItemData
    end
    if itemElement == nil or itemData._Tid == 0 then return end
    local uiItem = self:GetUIObject("Frame_Item"..index)
    local img_item_icon = self:GetUIObject("Img_ItemIcon"..index)
    GUITools.SetItemIcon(img_item_icon, itemElement.IconAtlasPath)
    local img_bind = self:GetUIObject("Img_Lock"..index)
    local img_Time = self:GetUIObject("Img_Time"..index)
    local labBindMode = self:GetUIObject("Lab_BindType"..index)
    labBindMode:SetActive(false)
    -- 策划需求暂时隐藏
    -- if self._PopFrom == TipsPopFrom.OTHER_PANEL then 
    --     if itemElement.BindMode == EItemBindMode.OnGain then 
    --         labBindMode:SetActive(true)
    --         GUI.SetText(labBindMode,StringTable.Get(10718))
    --     elseif itemElement.BindMode == EItemBindMode.OnUse then 
    --         labBindMode:SetActive(true)
    --         GUI.SetText(labBindMode,StringTable.Get(10718))
    --     elseif itemElement.BindMode == EItemBindMode.Never then 
    --         labBindMode:SetActive(false)
    --     end
    -- else
    --     labBindMode:SetActive(false)
    -- end
    img_bind:SetActive(self._ItemData:IsBind())
    if not self._ItemData:IsBind() then 
        img_Time:SetActive(self._ItemData._SellCoolDownExpired ~= 0 )
    else
        img_Time:SetActive(false)
    end
   
    -- GUITools.SetItem(uiItem, itemElement, self._ItemData:GetCount(), nil, self._ItemData:IsBind())
    GUITools.SetGroupImg(self:GetUIObject("Img_Quality"..index), itemElement.InitQuality)
    local labType = self:GetUIObject("Lab_ShowType"..index)
    if self._ItemData._ItemType == EItemType.Pet then 
        local petTemp = CElementData.GetPetTemplate( tonumber(itemElement.Type1Param1))
        if petTemp ~= nil then  
            GUI.SetText(labType, StringTable.Get(19022 + petTemp.Genus))
        end
    else
        if itemElement.ProfessionLimitMask == 15 or self._ItemData._Template.ProfessionLimitMask == 255 or self._ItemData._Template.ProfessionLimitMask == 31 then  
            GUI.SetText(labType,self._ItemData._DescriptionType)
        else
            GUI.SetText(labType,StringTable.Get(17000 + itemElement.ProfessionLimitMask)..self._ItemData._DescriptionType)
        end
    end

    local name = ""
    if game._IsOpenDebugMode == true then
        name = "(".. itemElement.Id ..")" .. itemElement.TextDisplayName
    else        
        name = itemElement.TextDisplayName
    end

    GUI.SetText(self:GetUIObject("Lab_ItemName"..index), name) 
    local LabInitLevel = self:GetUIObject("Lab_InitLevel"..index)
    if itemElement.InitLevel > 0 or game._IsOpenDebugMode == true then 
        LabInitLevel:SetActive(true)
        GUI.SetText(LabInitLevel,string.format(StringTable.Get(10657),itemElement.InitLevel))
    else
        LabInitLevel:SetActive(false)
    end
    local labQuality = self:GetUIObject("Lab_QualityText"..index)
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + self._ItemData._Quality), self._ItemData._Quality)
    GUI.SetText(labQuality,color)
    local lab_UseLevel = self:GetUIObject("Lab_LvText"..index) 
    if itemElement.MinLevelLimit > 0 then 
        lab_UseLevel :SetActive(true)
        GUI.SetText(lab_UseLevel,tostring(itemElement.MinLevelLimit))
    else
        lab_UseLevel:SetActive(false)
    end
end

def.method("boolean").InitRune = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    if isShowCompare then 
        index = 2 
        itemData = self._CompareItemData
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(true)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(true)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
    
    local labSkillName = self:GetUIObject("Lab_SkillName"..index)
    local labRuneDescribe = self:GetUIObject("Lab_RuneDescribe"..index)
    if itemData._Template.EventType1 == EItemEventType.ItemEvent_Rune then 
        local runeTemplate = CElementData.GetRuneTemplate(tonumber(itemData._Template.Type1Param1))
        if runeTemplate ~= nil then
            GUI.SetText(labSkillName,runeTemplate.SkillName)
            local str = DynamicText.ParseRuneDescText(tonumber(itemData._Template.Type1Param1),tonumber(itemData._Template.Type1Param2)) 
            GUI.SetText(labRuneDescribe, str)
        end
    else 
        warn("RuneTemplate is nil :" ..itemData._Tid)
    end    
end

def.method("boolean").InitCharmItem = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    if isShowCompare then 
        index = 2 
        itemData = self._CompareItemData
    end
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
    local frameBaseAttri = self:GetUIObject('Frame_BaseAttri'..index)
    frameBaseAttri:SetActive( itemData._CharmItemTemplate.PropID1 ~= 0 or itemData._CharmItemTemplate.PropID2 ~= 0 )
    local item1 = frameBaseAttri:FindChild("Item1")
    local item2 = frameBaseAttri:FindChild("Item2")
    item1:SetActive(itemData._CharmItemTemplate.PropID1 ~= 0)
    item2:SetActive(itemData._CharmItemTemplate.PropID2 ~= 0)
    if itemData._CharmItemTemplate.PropID1 ~= 0 then
        local Lab_AttriTips = item1:FindChild("Lab_AttriTips")
        local Lab_AttriValues = item1:FindChild("Lab_AttriValues")
        local fightElement = CElementData.GetAttachedPropertyTemplate( itemData._CharmItemTemplate.PropID1 )
        GUI.SetText(Lab_AttriTips,fightElement.TextDisplayName)
        local value = nil 
        if itemData._CharmItemTemplate.PropType1 == 1 then 
            value = string.format(StringTable.Get(10631),itemData._CharmItemTemplate.PropValue1)
        elseif itemData._CharmItemTemplate.PropType1 == 2 then 
            value = string.format(StringTable.Get(10682),itemData._CharmItemTemplate.PropValue1 / 100)
        end
        GUI.SetText(Lab_AttriValues,value)
    end
    if itemData._CharmItemTemplate.PropID2 ~= 0 then
        local Lab_AttriTips = item2:FindChild("Lab_AttriTips")
        local Lab_AttriValues = item2:FindChild("Lab_AttriValues")
        item2:SetActive(true)
        if itemData._CharmItemTemplate.PropID2 == -1 then 
            item2:SetActive(false)
            return
        end
        local fightElement = CElementData.GetAttachedPropertyTemplate( itemData._CharmItemTemplate.PropID2 )
        GUI.SetText(Lab_AttriTips,fightElement.TextDisplayName)
        local value = nil 
        if itemData._CharmItemTemplate.PropType2 == 1 then 
            value = string.format(StringTable.Get(10631),itemData._CharmItemTemplate.PropValue2)
        elseif itemData._CharmItemTemplate.PropType2 == 2 then 
            value = string.format(StringTable.Get(10682),itemData._CharmItemTemplate.PropValue2 / 100)
        end
        GUI.SetText(Lab_AttriValues, value)
    end

end

def.method("boolean").InitNoramlItem = function ( self ,isShowCompare)
    local index = 1 
    if self._IsShowCompare then 
        index = 2 
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
    -- body
end

def.method("boolean").InitDressItem = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    if isShowCompare then 
        index = 2 
        itemData = self._CompareItemData
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(true)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    local frameColor = self:GetUIObject("Frame_ColorAttri"..index)

    local CDressUtility = require "Dress.CDressUtility"
    --评分
    local dressId = tonumber(itemData._Template.Type1Param1)
    local dressTemplate = CElementData.GetTemplate("Dress", dressId)
    if dressTemplate == nil then 
        warn("dressTemplate " .. dressId .."is Nil")
        return
    end

    GUI.SetText(self:GetUIObject("Lab_DressScoreValues"..index),GUITools.FormatNumber(dressTemplate.Score))
    do
        --颜色
        local colorId1 = dressTemplate.InitColor1
        local bShowColor1 = colorId1 > 0
        local colorId2 = dressTemplate.InitColor2
        local bShowColor2 = colorId2 > 0

        if not bShowColor1 and not bShowColor2 then
            frameColor:SetActive(false)
        else
            frameColor:SetActive(true)
            self._FramesDress[index].Part1:SetActive( bShowColor1 )
            if bShowColor1 then
                local color = CDressUtility.GetColorInfoByDyeId( colorId1 )
                GameUtil.SetImageColor(self._FramesDress[index].ImageColor1, color)
            end
            
            self._FramesDress[index].Part2:SetActive( bShowColor2 )
            if bShowColor2 then
                local color = CDressUtility.GetColorInfoByDyeId( colorId2 )
                GameUtil.SetImageColor(self._FramesDress[index].ImageColor2, color)
            end
        end
    end
end

def.method("boolean").InitUseType = function(self,isShowCompare)
    local index = 1 
    if self._IsShowCompare then 
        index = 2 
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
end

--宠物
def.method("boolean").InitPetEggItem = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    if self._IsShowCompare then 
        index = 2 
        itemData = self._CompareItemData
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(true)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
    local Frame_PetTalent = self:GetUIObject("Frame_PetTalent"..index)
    Frame_PetTalent:SetActive(true)

    local itemElement = itemData._Template
    local petTid = tonumber(itemElement.Type1Param1)
    local petData = CElementData.GetPetGuideById(petTid)
    self._TalentData = petData.TalentList
    -- 资质
    for i,v in ipairs(petData.AptitudeList) do 
        local item = self:GetUIObject("ItemPetRange"..index..i)
        GUI.SetText(item:FindChild("Lab_AttriTips"),v.Name)
        GUI.SetText(item:FindChild("Lab_AttriValues"),string.format(StringTable.Get(10647),v.MinValue,v.MaxValue))      
    end
    -- 属性
    for i,v in ipairs(petData.PropertyList) do
        local item = self:GetUIObject("PropertyItem"..index..i)
        GUI.SetText(item:FindChild("Lab_AttriTips"),v.Name)
        GUI.SetText(item:FindChild("Lab_AttriValues"),string.format(StringTable.Get(10647),v.MinValue,v.MaxValue))   
    end
    -- 天赋
    local count = #petData.TalentList
    local frame2 = self:GetUIObject("FrameTalent"..index..2)
    if count == 0 then 
        Frame_PetTalent:SetActive(false)
    elseif count <= 3 then 
        frame2 :SetActive(false)
    else
        frame2 :SetActive(true)
    end
    for i = 1, 6 do 
        if i <= count then 
            local item = self:GetUIObject("TalentItem"..index..i)
            item:SetActive(true)
            -- warn(' --petData.TalentList[i].IconPath---',petData.TalentList[i].IconPath)
            GUITools.SetIcon(item:FindChild("Btn_Talent"..i.."/Img_Talent"),petData.TalentList[i].IconPath)
            GUI.SetText(item:FindChild("Lab_Name"),petData.TalentList[i].Name) 
        else
            local item = self:GetUIObject("TalentItem"..index..i)
            item:SetActive(false)
        end
    end
   
end

def.method("boolean").InitGiftBag = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    if isShowCompare then 
        index = 2 
        itemData = self._CompareItemData
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_Enchant"..index) :SetActive(false) 
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
    local Frame_GiftBag = self:GetUIObject("Frame_GiftBag"..index)
    Frame_GiftBag:SetActive(true)
    if itemData._Template.GetItemIds == "" then 
        Frame_GiftBag:SetActive(false)
    return end
    local Ids = string.split(itemData._Template.GetItemIds,'*')
    if Ids == nil or #Ids == 0 then 
        Frame_GiftBag:SetActive(false)
    return end
    local perList = string.split(itemData._Template.GetItemPers,'*')
    if perList == nil or #perList== 0 then 
        Frame_GiftBag:SetActive(false)
    return end
    local numberlist = string.split(itemData._Template.GetItemCounts,'*')
    local labTips = Frame_GiftBag:FindChild("Lab_Tips")
    GUI.SetText(labTips,itemData._Template.GetTypeDescription)
    local frameItem1 = self:GetUIObject("Frame_Item"..index..1)
    local frameItem2 = self:GetUIObject("Frame_Item"..index..2)
    local frameItem3 = self:GetUIObject("Frame_Item"..index..3)
    frameItem1:SetActive(true)
    frameItem2:SetActive(true)
    local numbers = {}
    self._GetItemPers = {}
    self._GetItemPers[index] = {}
    self._GetItemIds = {}
    self._GetItemIds[index] = {}
    for i,v in ipairs(Ids) do 
        if v == nil then warn ("itemData._Tid itemData._Template.GetItemPers has nil number ",itemData._Tid) return end
        local id = tonumber(v)
        local itemTemp = CElementData.GetItemTemplate(id)
        if itemTemp == nil then warn("Item Template id is nil ",v) return end
        local infoData = game._HostPlayer._InfoData
        --职业限制
        local profMask = EnumDef.Profession2Mask[infoData._Prof]
        if profMask == bit.band(itemTemp.ProfessionLimitMask, profMask) then 
            table.insert(self._GetItemIds[index],id)
            if numberlist[i] ~= nil then  
                table.insert(numbers,tonumber(numberlist[i]))
            end
            if perList[i] ~= nil then 
                table.insert( self._GetItemPers[index],tonumber(perList[i]))
            end
        end
    end
    if #self._GetItemIds[index] <= 3 then 
        frameItem2:SetActive(false)
        frameItem3:SetActive(false)
    elseif #self._GetItemIds[index] >= 3 and  #self._GetItemIds[index] <= 6 then 
        frameItem2:SetActive(true)
        frameItem3:SetActive(false)
    elseif #self._GetItemIds[index] >=6 then 
        frameItem2:SetActive(true)
        frameItem3:SetActive(true)
    end
    for i = 1,9 do 
        local item = self:GetUIObject("Item"..i)
        if i > #self._GetItemIds[index] then 
            item:SetActive(false)
        else
            item:SetActive(true)
            local frame_icon = item:FindChild("GiftItemIcon"..i)
            IconTools.SetFrameIconTags(frame_icon, { [EFrameIconTag.Select] = false })
            local bShowProbability = false
            if self._GetItemPers[index][i] == nil then 
                warn("id and percent is not matching "  )
                return
            end
            if self._GetItemPers[index][i] / 100 < 100 then 
                bShowProbability = true
            end
            local setting =
            {
                [EItemIconTag.Number] = tonumber(numbers[i]),
                [EItemIconTag.Probability] = bShowProbability,
            }
            IconTools.InitItemIconNew(frame_icon, self._GetItemIds[index][i], setting, EItemLimitCheck.AllCheck)
            
            local itemTemp = CElementData.GetItemTemplate(self._GetItemIds[index][i])
            if itemTemp ~= nil then
                local lab_item_name = item:FindChild("Lab_ItemName")
                if not IsNil(lab_item_name) then
                    GUI.SetText(lab_item_name, RichTextTools.GetQualityText(itemTemp.TextDisplayName, itemTemp.InitQuality))
                end
            end
        end
    end
end

-- 附魔卷轴
def.method("boolean").InitEnchantReel = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    if isShowCompare then 
        index = 2 
        itemData = self._CompareItemData
    end
    self:GetUIObject("Frame_RuneEffect"..index):SetActive(false)
    self:GetUIObject("Frame_Tips"..index):SetActive(true) 
    self:GetUIObject("Frame_RuneSkill"..index):SetActive(false)
    self:GetUIObject('Frame_BaseAttri'..index):SetActive(false)
    self:GetUIObject("Frame_ColorAttri"..index):SetActive(false)
    self:GetUIObject("Frame_PetProperty"..index):SetActive(false)
    self:GetUIObject("Frame_PetTalent"..index):SetActive(false)
    self:GetUIObject("Frame_PetRange"..index):SetActive(false)
    self:GetUIObject("Frame_DressScore"..index):SetActive(false)
    self:GetUIObject("Frame_GiftBag"..index):SetActive(false)

    local Frame_Enchant = self:GetUIObject("Frame_Enchant"..index)
    Frame_Enchant:SetActive(true)
    local EnchantData = CElementData.GetEquipEquipEnchantInfoMapByItemID(itemData._Tid)
    if EnchantData == nil then warn(" EnchantItem Id Enchant is nil",itemData._Tid) return end

    GUI.SetText(Frame_Enchant:FindChild("Lab_AttriTips/Lab_AttriValues"),GUITools.FormatNumber(EnchantData.Property.ValueDesc))
    GUI.SetText(Frame_Enchant:FindChild("Lab_AttriTips"),EnchantData.Property.Name)
    local labTime = Frame_Enchant:FindChild("Lab_AttriTime")
    self:ShowTime(EnchantData.Enchant.ExpiredTime * 60,nil,labTime)
    local lab_UseLevel = self:GetUIObject("Lab_LvText"..index) 
    lab_UseLevel:SetActive(true)
    local labTip = lab_UseLevel:FindChild("Lab_Tip")
    GUI.SetText(labTip,StringTable.Get(10720))
    GUI.SetText(lab_UseLevel,tostring(EnchantData.Enchant.Level))
end

def.method("boolean","=>","number","number").InitTips = function(self,isShowCompare)
    local index = 1 
    local itemData = self._ItemData
    local itemTemp = self._ItemData._Template
    if isShowCompare then 
        index = 2 
        itemData = self._CompareItemData
        itemTemp = self._CompareItemData._Template
    end
    
    if itemTemp == nil then return 0,0 end
    local btnGet = self:GetUIObject("Btn_GetType"..index)
    if itemData._Template.ApproachID == "" then
        btnGet:SetActive(false)
    else
        btnGet:SetActive(true)
    end
    local frameSell = self:GetUIObject("Frame_Sell"..index)
    frameSell:SetActive(false)
    if itemData:CanSell() then 
        frameSell:SetActive(true)
        GUI.SetText(self:GetUIObject("Lab_Money"..index),GUITools.FormatNumber(itemData._Template.RecyclePriceInGold))
    end
    
    local labDecompose = self:GetUIObject("Lab_DecomposeTips"..index)
    if not itemData :CanDecompose() then 
        labDecompose:SetActive(false)
    else
        labDecompose:SetActive(true)
    end
    local Lab_EquipTips = self:GetUIObject("Lab_EquipTips"..index)
    if itemData._ItemType == EItemType.PetTalentBook then 
        local TalentTid = tonumber(itemTemp.Type1Param1)
        local TalentLv = tonumber(itemTemp.Type1Param2)
        local TalentTemplate = CElementData.GetTalentTemplate(TalentTid)
        if TalentTemplate == nil then 
            warn("TalentTemplate id "..TalentTid .." is nil")
            return 0,0
        end
        GUI.SetText(Lab_EquipTips,DynamicText.ParseSkillDescText(TalentTid, TalentLv, true))
    else
        GUI.SetText(Lab_EquipTips,itemTemp.TextDescription)
    end
    -- 交易
    local frameTransaction = self:GetUIObject("Frame_Transaction"..index)
    frameTransaction:SetActive(true)
    local lab_CoolTime = frameTransaction:FindChild("Lab_CoolTime")
    local ImgTransaction = frameTransaction:FindChild("Img_Transaction")
    local timeId1 = 0
    local timeId2 = 0
    if self._PopFrom == TipsPopFrom.OTHER_PANEL then 
        frameTransaction:SetActive(false)
    else
        if itemData:IsBind() then 
            ImgTransaction:SetActive(false)
            GUI.SetText(lab_CoolTime,StringTable.Get(10683))
        else
            if game._CAuctionUtil:GetMarketItemIDByItemID(itemData._Tid) > 0 then 
                if itemData._SellCoolDownExpired > 0 then
                    ImgTransaction:SetActive(true)
                    local callBack1 = function()
                        local time = itemData._SellCoolDownExpired - GameUtil.GetServerTime()/1000 
                        if time > 0 then
                            self:ShowTime(time,false,lab_CoolTime)
                        else
                            local img_Time = frameTransaction:FindChild("Img_Time")
                            img_Time:SetActive(false)
                            ImgTransaction:SetActive(false)
                            GUI.SetText(lab_CoolTime,StringTable.Get(10684))
                            _G.RemoveGlobalTimer(timeId1)
                            timeId1 = 0
                        end
                    end
                    timeId1 =  _G.AddGlobalTimer(1, false, callBack1) 
                else
                    ImgTransaction:SetActive(false)
                    GUI.SetText(lab_CoolTime,StringTable.Get(10684))
                end
            else
                -- 可以交易
                ImgTransaction:SetActive(false)
                GUI.SetText(lab_CoolTime,StringTable.Get(10683))
            end               
        end
    end
    -- 到期时间
    local labExpiredTime = self:GetUIObject("Lab_ExpireTime"..index)
    if itemData._ExpireData == 0 then 
        labExpiredTime:SetActive(false)
    else
        if itemData._ExpireData - GameUtil.GetServerTime()/1000 <= 0 then 
            labExpiredTime:SetActive(false)
        end
        local callBack2 = function()
            local time = itemData._ExpireData - GameUtil.GetServerTime()/1000
            if time > 0 then
                self:ShowTime(time,true,labExpiredTime)
            else
                labExpiredTime:SetActive(false)
                _G.RemoveGlobalTimer(timeId2)
                timeId2 = 0
            end
        end
        timeId2 = _G.AddGlobalTimer(1, false, callBack2) 
    end
    return timeId1,timeId2
end

def.method().Hide = function(self)
    game._GUIMan:CloseByScript(self)
    -- MsgBox.ClearAllBoxes()
end

def.override().OnDestroy = function(self)
    if self._ItemCoolDownTimer1 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer1)
        self._ItemCoolDownTimer1 = 0	
    end
    if self._ItemExpireTimer1 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemExpireTimer1)
        self._ItemExpireTimer1 = 0 
    end
    if self._ItemCoolDownTimer2 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer2)
        self._ItemCoolDownTimer2 = 0    
    end
    if self._ItemExpireTimer2 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemExpireTimer2)
        self._ItemExpireTimer2 = 0 
    end
    instance = nil 

end

CPanelItemHint.Commit()
return CPanelItemHint