
local Lplus = require 'Lplus'
local CPanelHintBase = require 'GUI.CPanelHintBase'
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local DynamicText = require "Utility.DynamicText"
local CElementData = require "Data.CElementData"
local EItemEventType = require "PB.data".EItemEventType
local bit = require "bit"

local EItemType = require "PB.Template".Item.EItemType
local CPanelBase = require "GUI.CPanelBase"
local CPanelItemHint = Lplus.Extend(CPanelHintBase, 'CPanelItemHint')
local def = CPanelItemHint.define

 
def.field('userdata')._Frame_DressScore = nil 
def.field("userdata")._Frame_All = nil
def.field('userdata')._Lab_EquipTips = nil
def.field('userdata')._Lab_TimeTips = nil
def.field("userdata")._Lay_Button = nil 
def.field('userdata')._Frame_Basic = nil
def.field('userdata')._Frame_BaseAttri = nil
def.field("userdata")._Frame_RuneSkill = nil 
def.field("userdata")._Frame_CharmAttri = nil
def.field("userdata")._Frame_RuneEffect = nil
def.field("userdata")._Frame_ColorAttri = nil
def.field('userdata')._Frame_Tips = nil 
def.field("userdata")._Frame_PetRange = nil 
def.field("userdata")._FrameGiftBag =nil 
def.field("userdata")._Frame_PetProperty = nil
def.field("userdata")._Frame_PetTalent = nil 
def.field("userdata")._Frame_Enchant = nil 
def.field('userdata')._List_CharmAttri = nil

def.field("table")._FramesDress = BlankTable
def.field("number")._ItemCoolDownTimer = 0
def.field("table")._TalentData = nil 
def.field("table")._GetItemIds = BlankTable                          -- 礼包获得的物品
def.field("table")._GetItemPers = BlankTable                         -- 开启礼包获得物品的百分比

def.field("userdata")._Scroll = nil

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
    self._Lab_EquipTips = self:GetUIObject('Lab_EquipTips')
    self._Lab_TimeTips = self:GetUIObject('Lab_TimeTips')
    self._Frame_All = self:GetUIObject("Frame_Content")
    self._Frame_Basic = self:GetUIObject('Frame_Basic')
    self._Lay_Button = self:GetUIObject("Lay_Button")
    self._Frame_DressScore = self:GetUIObject("Frame_DressScore")
    self._Frame_BaseAttri = self:GetUIObject('Frame_BaseAttri')
    self._Frame_RuneEffect = self:GetUIObject("Frame_RuneEffect")
    self._Frame_ColorAttri = self:GetUIObject("Frame_ColorAttri")
    self._Frame_Tips = self:GetUIObject("Frame_Tips")
    self._Frame_PetProperty = self:GetUIObject("Frame_PetProperty")
    self._Frame_PetTalent = self:GetUIObject("Frame_PetTalent")
    self._Frame_PetRange = self:GetUIObject("Frame_PetRange")
    self._Frame_RuneSkill = self:GetUIObject("Frame_RuneSkill")
    self._FrameGiftBag = self:GetUIObject("Frame_GiftBag")
    self._Frame_Enchant = self:GetUIObject("Frame_Enchant")
    self._DropButton = self:GetUIObject("Drop_Button")
    self._Scroll = self:GetUIObject("Scroll")
    do
        self._FramesDress = {}
        -- local Frame_Content = self:GetUIObject('Frame_Content')
        self._FramesDress.Frame_Color = self:GetUIObject('Frame_ColorAttri')

        self._FramesDress.Part1 = self:GetUIObject('Frame_PartColor1')
        self._FramesDress.Part2 = self:GetUIObject('Frame_PartColor2')

        self._FramesDress.ImageColor1 = self:GetUIObject('Img_Color1')
        self._FramesDress.ImageColor2 = self:GetUIObject('Img_Color2')
    end

end

def.override("dynamic").OnData = function(self, data)
    CPanelBase.OnData(self,data)

    self._ItemData = data.itemCellData
    if self._ItemData._Template == nil or self._ItemData._Tid == 0 then 
        warn("CPanelItemHint InitPanel cannot find")
        return 
    end

    self._CallWithFuncs = data.withFuncs
    if not data.withFuncs then
        self._PopFrom = data.params
    else
        self._ValidComponents = data.params
    end
    self._IsShowDropButton = false
    self._IsHaveMoreButton = false
    self:InitPanel()

    local mask = self:GetUIObject("Mask")

    self:InitTipSize(self._Frame_All,self._Scroll,mask,self._Frame_Basic,self._Lay_Button)
    -- CItemTipMan.InitTipPosition(frameFixedPosition, self._Scroll, 0)
end

def.method("userdata","userdata","userdata","userdata","userdata").InitTipSize = function (self,obj,scroll,maskObj,titleObj,layButton)
    local scrollRect = scroll:GetComponent(ClassType.RectTransform)
    local maskRect = maskObj:GetComponent(ClassType.RectTransform)
    local titleRect = titleObj:GetComponent(ClassType.RectTransform)
    local ButtonRect = layButton:GetComponent(ClassType.RectTransform)

    local sizeDelta = scrollRect.sizeDelta

    local height = maskRect.sizeDelta.y + titleRect.sizeDelta.y
    if layButton.activeSelf then
        height = height + ButtonRect.sizeDelta.y
    end
    sizeDelta.y = height
    scrollRect.sizeDelta = sizeDelta

    obj.localPosition=Vector3.New(0,0,0)
end

def.override("string").OnClick = function(self,id)
    local component = nil 
    if id == "Btn_More" then
        if not self._IsHaveMoreButton then 
            if self._ValidComponents == nil then return end
            component = self._ValidComponents[2]
            if component == nil then return end
            component:Do()
            CItemTipMan.CloseCurrentTips()      
        else
            if not self._IsShowDropButton then 
                self._DropButton:SetActive(true)
                self._IsShowDropButton = true
            else
                self._DropButton:SetActive(false)
                self._IsShowDropButton = false
            end
        end
    elseif id == "Btn_GetType"then
        local PanelData = 
        {
            ApproachIDs = self._ItemData._Template.ApproachID,
            ParentObj = self._Scroll,
            IsFromTip = true,
            TipPanel = self,
            ItemId = self._ItemData._Tid,
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
                               ItemId = self._GetItemIds[index],
                               Percent = self._GetItemPers[index],
                               TipPanel = self,
                               TargetObj = self._Frame_Basic,
                          }
        game._GUIMan:Open("CPanelGiftItem",PanelData)
    elseif id == "Btn_One" then 
        if self._ValidComponents ~= nil then
            local component = self._ValidComponents[1]
            if component ~= nil then
                component:Do()
                CItemTipMan.CloseCurrentTips() 
            end
        end     
    else
        if self._ValidComponents == nil then return end
        local index = string.sub(id,9)
        local component = self._ValidComponents[tonumber(index)]
        if component == nil then return end
        component:Do()

        if component: IsApproachType() then return end
        CItemTipMan.CloseCurrentTips()      
    end
end

def.method().InitPanel = function(self)
   
    self:InitBaseInfo()
    if self._ItemData._ItemType == EItemType.Rune then
        self:InitRune()
    elseif self._ItemData._ItemType == EItemType.Charm then
        self:InitCharmItem()
    elseif self._ItemData._ItemType == EItemType.Dress then
        self:InitDressItem()
    elseif self._ItemData._ItemType == EItemType.NoramlItem then 
        self:InitNoramlItem()
    elseif self._ItemData._ItemType == EItemType.Pet then 
        self:InitPetEggItem()
    elseif self._ItemData._ItemType == EItemType.TreasureBox then 
        self:InitGiftBag()
    elseif self._ItemData._ItemType == EItemType.EnchantReel then 
        self:InitEnchantReel()
    else
        self:InitUseType()
    end
    self:InitTips()
    if self._PopFrom ~= TipsPopFrom.CHAT_PANEL then 
        self._Lay_Button :SetActive(true)
        self:InitButtons(self._Lay_Button)
    else
        self._Lay_Button:SetActive(false)
    end
end

def.method().InitBaseInfo = function (self)
    if self._ItemData._Tid == 0 then
        return
    end
    local itemElement = self._ItemData._Template
    if itemElement == nil then 
        print("CPanelItemHint InitPanel cannot find tid: " .. self._ItemData._Tid )
        return 
    end

    local uiItem = self:GetUIObject("Item")
    local img_item_icon = uiItem:FindChild("Img_ItemIcon")
    GUITools.SetItemIcon(img_item_icon, itemElement.IconAtlasPath)
    local img_bind = uiItem:FindChild("Img_Lock")
    local img_Time = uiItem:FindChild("Img_Time")
    img_Time:SetActive(self._ItemData._SellCoolDownExpired ~= 0 )
    img_bind:SetActive(self._ItemData:IsBind())
    -- GUITools.SetItem(uiItem, itemElement, self._ItemData:GetCount(), nil, self._ItemData:IsBind())
    GUITools.SetGroupImg(self:GetUIObject("Img_Quality"), itemElement.InitQuality)
    local labType = self:GetUIObject("Lab_ShowType")
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

    GUI.SetText(self:GetUIObject("Lab_ItemName"), name) 
    local LabInitLevel = self:GetUIObject("Lab_InitLevel")
    if itemElement.InitLevel > 0 or game._IsOpenDebugMode == true then 
        LabInitLevel:SetActive(true)
        GUI.SetText(LabInitLevel,string.format(StringTable.Get(10657),itemElement.InitLevel))
    else
        LabInitLevel:SetActive(false)
    end
    local labQuality = self:GetUIObject("Lab_QualityText")
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + self._ItemData._Quality), self._ItemData._Quality)
    GUI.SetText(labQuality,color)
    local lab_UseLevel = self:GetUIObject("Lab_LvText") 
    if itemElement.MinLevelLimit > 0 then 
        lab_UseLevel :SetActive(true)
        GUI.SetText(lab_UseLevel,tostring(itemElement.MinLevelLimit))
    else
        lab_UseLevel:SetActive(false)
    end
end

def.method().InitRune = function(self)  
    self._FrameGiftBag:SetActive(false)
    self._Frame_ColorAttri:SetActive(false)
    self._Frame_Enchant:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_RuneEffect :SetActive(true)
    self._Frame_Tips:SetActive(true)
    self._Frame_DressScore:SetActive(false)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)
    self._Frame_RuneSkill:SetActive(true)
    local labSkillName = self:GetUIObject("Lab_SkillName")
    local labRuneDescribe = self:GetUIObject("Lab_RuneDescribe")
    if self._ItemData._Template.EventType1 == EItemEventType.ItemEvent_Rune then 
        local runeTemplate = CElementData.GetRuneTemplate(tonumber(self._ItemData._Template.Type1Param1))
        if runeTemplate ~= nil then
            GUI.SetText(labSkillName,runeTemplate.SkillName)
            local str = DynamicText.ParseRuneDescText(tonumber(self._ItemData._Template.Type1Param1),tonumber(self._ItemData._Template.Type1Param2)) 
            GUI.SetText(labRuneDescribe, str)
        end
    else 
        warn("RuneTemplate is nil :" ..self._ItemData._Tid)
    end    
end

def.method().InitCharmItem = function(self)
    self._FrameGiftBag:SetActive(false)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_Tips:SetActive(true)
    self._Frame_ColorAttri:SetActive(false)
    self._Frame_RuneEffect :SetActive(false)
    self._Frame_DressScore:SetActive(false)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)
    self._Frame_Enchant:SetActive(false)
    self._Frame_BaseAttri:SetActive( self._ItemData._CharmItemTemplate.PropID1 ~= 0 or self._ItemData._CharmItemTemplate.PropID2 ~= 0 )
    local item1 = self._Frame_BaseAttri:FindChild("Item1")
    local item2 = self._Frame_BaseAttri:FindChild("Item2")
    item1:SetActive(self._ItemData._CharmItemTemplate.PropID1 ~= 0)
    item2:SetActive(self._ItemData._CharmItemTemplate.PropID2 ~= 0)
    if self._ItemData._CharmItemTemplate.PropID1 ~= 0 then
        local Lab_AttriTips = item1:FindChild("Lab_AttriTips")
        local Lab_AttriValues = item1:FindChild("Lab_AttriValues")
        local fightElement = CElementData.GetAttachedPropertyTemplate( self._ItemData._CharmItemTemplate.PropID1 )
        GUI.SetText(Lab_AttriTips,fightElement.TextDisplayName)
        local value = nil 
        if self._ItemData._CharmItemTemplate.PropType1 == 1 then 
            value = string.format(StringTable.Get(10631),self._ItemData._CharmItemTemplate.PropValue1)
        elseif self._ItemData._CharmItemTemplate.PropType1 == 2 then 
            value = string.format(StringTable.Get(10682),self._ItemData._CharmItemTemplate.PropValue1 / 100)
        end
        GUI.SetText(Lab_AttriValues,value)
    end
    if self._ItemData._CharmItemTemplate.PropID2 ~= 0 then
        local Lab_AttriTips = item2:FindChild("Lab_AttriTips")
        local Lab_AttriValues = item2:FindChild("Lab_AttriValues")
        item2:SetActive(true)
        if self._ItemData._CharmItemTemplate.PropID2 == -1 then 
            item2:SetActive(false)
            return
        end
        local fightElement = CElementData.GetAttachedPropertyTemplate( self._ItemData._CharmItemTemplate.PropID2 )
        GUI.SetText(Lab_AttriTips,fightElement.TextDisplayName)
        local value = nil 
        if self._ItemData._CharmItemTemplate.PropType2 == 1 then 
            value = string.format(StringTable.Get(10631),self._ItemData._CharmItemTemplate.PropValue2)
        elseif self._ItemData._CharmItemTemplate.PropType2 == 2 then 
            value = string.format(StringTable.Get(10682),self._ItemData._CharmItemTemplate.PropValue2 / 100)
        end
        GUI.SetText(Lab_AttriValues, value)
    end

end

def.method().InitNoramlItem = function ( self )
    self._FrameGiftBag:SetActive(false)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_ColorAttri:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_Enchant:SetActive(false)
    self._Frame_RuneEffect :SetActive(false)
    self._Frame_Tips:SetActive(true)
    self._Frame_DressScore:SetActive(false)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)
    -- body
end

def.method().InitDressItem = function(self)
    self._FrameGiftBag:SetActive(false)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_Enchant:SetActive(false)
    self._Frame_RuneEffect :SetActive(false)
    self._Frame_Tips:SetActive(true)
    self._Frame_DressScore:SetActive(true)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)

    local CDressUtility = require "Dress.CDressUtility"
    --评分
    local dressId = tonumber(self._ItemData._Template.Type1Param1)
    local dressTemplate = CElementData.GetTemplate("Dress", dressId)
    if dressTemplate == nil then 
        warn("dressTemplate " .. dressId .."is Nil")
    end

    GUI.SetText(self:GetUIObject("Lab_DressScoreValues"),tostring(dressTemplate.Score))
    do
        --颜色
        local colorId1 = dressTemplate.InitColor1
        local bShowColor1 = colorId1 > 0
        local colorId2 = dressTemplate.InitColor2
        local bShowColor2 = colorId2 > 0

        if not bShowColor1 and not bShowColor2 then
           self._Frame_ColorAttri:SetActive(false)
        else
            self._Frame_ColorAttri:SetActive(true)
            self._FramesDress.Part1:SetActive( bShowColor1 )
            if bShowColor1 then
                local color = CDressUtility.GetColorInfoByDyeId( colorId1 )
                GameUtil.SetImageColor(self._FramesDress.ImageColor1, color)
            end
            
            self._FramesDress.Part2:SetActive( bShowColor2 )
            if bShowColor2 then
                local color = CDressUtility.GetColorInfoByDyeId( colorId2 )
                GameUtil.SetImageColor(self._FramesDress.ImageColor2, color)
            end
        end
    end
end

def.method().InitUseType = function(self)
    self._FrameGiftBag:SetActive(false)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_ColorAttri:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_RuneEffect :SetActive(false)
    self._Frame_Tips:SetActive(true)
    self._Frame_DressScore:SetActive(false)
    self._Frame_Enchant:SetActive(false)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)
end

--宠物
def.method().InitPetEggItem = function(self)
    self._FrameGiftBag:SetActive(false)
    self._Frame_PetRange:SetActive(true)
    self._Frame_PetProperty:SetActive(true)
    self._Frame_Enchant:SetActive(false)
    self._Frame_PetTalent:SetActive(true)
    self._Frame_Tips:SetActive(true)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_RuneEffect:SetActive(false)
    self._Frame_DressScore:SetActive(false)
    self._Frame_ColorAttri:SetActive(false)

    local itemElement = self._ItemData._Template
    local petTid = tonumber(itemElement.Type1Param1)
    local petData = CElementData.GetPetGuideById(petTid)
    self._TalentData = petData.TalentList
    -- 资质
    for i,v in ipairs(petData.AptitudeList) do 
        local item = self:GetUIObject("ItemPetRange"..i)
        GUI.SetText(item:FindChild("Lab_AttriTips"),v.Name)
        GUI.SetText(item:FindChild("Lab_AttriValues"),string.format(StringTable.Get(10647),v.MinValue,v.MaxValue))      
    end
    -- 属性
    for i,v in ipairs(petData.PropertyList) do
        local item = self:GetUIObject("PropertyItem"..i)
        GUI.SetText(item:FindChild("Lab_AttriTips"),v.Name)
        GUI.SetText(item:FindChild("Lab_AttriValues"),string.format(StringTable.Get(10647),v.MinValue,v.MaxValue))   
    end
    -- 天赋
    local count = #petData.TalentList
    local frame2 = self:GetUIObject("FrameTalent2")
    if count == 0 then 
        self._Frame_PetTalent:SetActive(false)
    elseif count <= 3 then 
        frame2 :SetActive(false)
    else
        frame2 :SetActive(true)
    end
    for i = 1, 6 do 
        if i <= count then 
            local item = self:GetUIObject("TalentItem"..i)
            item:SetActive(true)
            GUITools.SetIcon(item:FindChild("Btn_Talent"..i.."/Img_Talent"..i),petData.TalentList[i].IconPath)
            GUI.SetText(item:FindChild("Lab_Name"),petData.TalentList[i].Name) 
        else
            local item = self:GetUIObject("TalentItem"..i)
            item:SetActive(false)
        end
    end
   
end

def.method().InitGiftBag = function(self)
    self._FrameGiftBag:SetActive(true)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)
    self._Frame_Tips:SetActive(true)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_RuneEffect:SetActive(false)
    self._Frame_Enchant:SetActive(false)
    self._Frame_DressScore:SetActive(false)
    self._Frame_ColorAttri:SetActive(false)
    if self._ItemData._Template.GetItemIds == "" then 
        self._FrameGiftBag:SetActive(false)
    return end
    local Ids = string.split(self._ItemData._Template.GetItemIds,'*')
    if Ids == nil or #Ids == 0 then 
        self._FrameGiftBag:SetActive(false)
    return end
    self._GetItemPers = string.split(self._ItemData._Template.GetItemPers,'*')
    if self._GetItemPers == nil or #self._GetItemPers== 0 then 
        self._FrameGiftBag:SetActive(false)
    return end
    local numberlist = string.split(self._ItemData._Template.GetItemCounts,'*')
    local labTips = self._FrameGiftBag:FindChild("Lab_Tips")
    GUI.SetText(labTips,self._ItemData._Template.GetTypeDescription)
    local frameItem1 = self:GetUIObject("Frame_Item1")
    local frameItem2 = self:GetUIObject("Frame_Item2")
    local frameItem3 = self:GetUIObject("Frame_Item3")
    frameItem1:SetActive(true)
    frameItem2:SetActive(true)
    local numbers = {}
    for i,v in ipairs(Ids) do 
        local id = tonumber(v)
        local itemTemp = CElementData.GetItemTemplate(id)
        if itemTemp == nil then warn("Item Template id is nil ",v) return end
        local infoData = game._HostPlayer._InfoData
        --职业限制
        local profMask = EnumDef.Profession2Mask[infoData._Prof]
        if profMask == bit.band(itemTemp.ProfessionLimitMask, profMask) then 
            table.insert(self._GetItemIds,id)
            if numberlist[i] ~= nil then 
                table.insert(numbers,tonumber(numberlist[i]))
            end
        end
    end
    numberlist = numbers
    if #self._GetItemIds <= 3 then 
        frameItem2:SetActive(false)
        frameItem3:SetActive(false)
    elseif #self._GetItemIds >= 3 and  #self._GetItemIds <= 6 then 
        frameItem2:SetActive(true)
        frameItem3:SetActive(false)
    elseif #self._GetItemIds >=6 then 
        frameItem2:SetActive(true)
        frameItem3:SetActive(true)
    end
    for i = 1,9 do 
        local item = self:GetUIObject("Item"..i)
        if i > #self._GetItemIds then 
            item:SetActive(false)
        else
            item:SetActive(true)
            local frame_icon = item:FindChild("GiftItemIcon"..i)
            IconTools.SetFrameIconTags(frame_icon, { [EFrameIconTag.Select] = false })
            local bShowProbability = false
            if self._GetItemPers[i] / 100 < 100 then 
                bShowProbability = true
            end
            local setting =
            {
                [EItemIconTag.Number] = tonumber(numberlist[i]),
                [EItemIconTag.Probability] = bShowProbability,
            }
            IconTools.InitItemIconNew(frame_icon, self._GetItemIds[i], setting, EItemLimitCheck.AllCheck)
            
            local itemTemp = CElementData.GetItemTemplate(self._GetItemIds[i])
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
def.method().InitEnchantReel = function(self)
    self._Frame_Enchant:SetActive(true)
    self._Frame_Tips:SetActive(true)

    self._FrameGiftBag:SetActive(false)
    self._Frame_PetRange:SetActive(false)
    self._Frame_PetProperty:SetActive(false)
    self._Frame_PetTalent:SetActive(false)
    self._Frame_RuneSkill:SetActive(false)
    self._Frame_BaseAttri:SetActive(false)
    self._Frame_RuneEffect:SetActive(false)
    self._Frame_DressScore:SetActive(false)
    self._Frame_ColorAttri:SetActive(false)
    local EnchantData = CElementData.GetEquipEquipEnchantInfoMapByItemID(self._ItemData._Tid)
    if EnchantData == nil then warn(" EnchantItem Id Enchant is nil",self._ItemData._Tid) return end

    GUI.SetText(self._Frame_Enchant:FindChild("Lab_AttriValues"),EnchantData.Property.ValueDesc)
    GUI.SetText(self._Frame_Enchant:FindChild("Lab_AttriTips"),EnchantData.Property.Name)
    local labTime = self._Frame_Enchant:FindChild("Lab_AttriTime")
    self:ShowTime(EnchantData.Enchant.ExpiredTime * 60,nil,labTime)
    local lab_UseLevel = self:GetUIObject("Lab_LvText") 
    lab_UseLevel:SetActive(true)
    GUI.SetText(lab_UseLevel,tostring(EnchantData.Enchant.Level))
end

def.method().InitTips = function(self)
    local itemTemp = self._ItemData._Template
    if itemTemp == nil then return end
    local btnGet = self._Frame_Tips:FindChild("Btn_GetType")
    if self._ItemData._Template.ApproachID == "" then
        btnGet:SetActive(false)
    else
        btnGet:SetActive(true)
    end
    local frameSell = self:GetUIObject("Frame_Sell")
    frameSell:SetActive(false)
    if self._ItemData:CanSell() then 
        frameSell:SetActive(true)
        GUI.SetText(self:GetUIObject("Lab_Money"),tostring(self._ItemData._Template.RecyclePriceInGold))
    end
    
    local labDecompose = self._Frame_Tips:FindChild("Lab_DecomposeTips")
    if not self._ItemData :CanDecompose() then 
        labDecompose:SetActive(false)
    else
        labDecompose:SetActive(true)
    end
    if self._ItemData._ItemType == EItemType.PetTalentBook then 
        local TalentTid = tonumber(itemTemp.Type1Param1)
        local TalentTemplate = CElementData.GetTalentTemplate(TalentTid)
        if TalentTemplate == nil then 
            warn("TalentTemplate id "..TalentTid .." is nil")
            return
        end
        GUI.SetText(self._Lab_EquipTips,DynamicText.ParseSkillDescText(TalentTid, 1, true))
    else
        GUI.SetText(self._Lab_EquipTips,itemTemp.TextDescription)
    end
    local time = 0
    -- 判断是到期时间还是售卖冻结时间
    local IsExpireTime = false
    if self._ItemData._SellCoolDownExpired > 0 then 
        time = self._ItemData._SellCoolDownExpired - GameUtil.GetServerTime()/1000 
        IsExpireTime = false
    elseif self._ItemData._ExpireData > 0 then 
        time = self._ItemData._ExpireData 
        IsExpireTime = true
    end
    local FrameDate = self:GetUIObject("Frame_Date")
    if time > 0 then 
        FrameDate:SetActive(true)
        if IsExpireTime == false and self._ItemData._IsBind then
            GUI.SetText(self._Lab_TimeTips,StringTable.Get(10683))
        else
            self:ShowTime(time,IsExpireTime,self._Lab_TimeTips)
            local callBack = function()
                if not IsExpireTime then 
                    time = self._ItemData._SellCoolDownExpired - GameUtil.GetServerTime()/1000 
                else
                    time = self._ItemData._ExpireData 
                end
                if time > 0 then
                    self:ShowTime(time,IsExpireTime,self._Lab_TimeTips)
                else
                    if not IsExpireTime then
                        GUI.SetText(self._Lab_TimeTips,StringTable.Get(10684))
                    end
                    _G.RemoveGlobalTimer(self._ItemCoolDownTimer)
                    self._ItemCoolDownTimer = 0	
                end
            end
            self._ItemCoolDownTimer = _G.AddGlobalTimer(1, false, callBack)	
        end
    else 
        FrameDate:SetActive(false)
    end
end

def.method().Hide = function(self)
    game._GUIMan:CloseByScript(self)
    -- MsgBox.CloseAll()
end

def.override().OnDestroy = function(self)
    if self._ItemCoolDownTimer ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer)
        self._ItemCoolDownTimer = 0	
    end
    instance = nil 

    self._Frame_DressScore = nil
    self._Frame_All = nil
    self._Lab_EquipTips = nil
    self._Lab_TimeTips = nil
    self._Lay_Button = nil
    self._Frame_Basic = nil
    self._Frame_BaseAttri = nil
    self._Frame_RuneSkill = nil
    self._Frame_CharmAttri = nil
    self._Frame_RuneEffect = nil
    self._Frame_ColorAttri = nil
    self._Frame_Tips = nil
    self._Frame_PetRange = nil
    self._Frame_PetProperty = nil
    self._Frame_PetTalent = nil
    self._List_CharmAttri = nil
    self._DropButton = nil
    self._Scroll = nil
end

CPanelItemHint.Commit()
return CPanelItemHint