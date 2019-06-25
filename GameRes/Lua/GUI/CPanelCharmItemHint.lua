
local Lplus = require 'Lplus'
local CPanelHintBase = require 'GUI.CPanelHintBase'
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local DynamicText = require "Utility.DynamicText"
local CElementData = require "Data.CElementData"
local EItemEventType = require "PB.data".EItemEventType
local bit = require "bit"

local EItemType = require "PB.Template".Item.EItemType
local CPanelCharmItemHint = Lplus.Extend(CPanelHintBase, 'CPanelCharmItemHint')
local def = CPanelCharmItemHint.define

def.field("table")._PanelObject1 = nil
def.field("table")._PanelObject2 = nil
def.field("table")._ItemEquipData = nil
def.field("number")._ItemCoolDownTimer = 0

local instance = nil
def.static('=>', CPanelCharmItemHint).Instance = function ()
    --print("CPanelCharmItemHint Instance")
	if not instance then
        instance = CPanelCharmItemHint()
        instance._PrefabPath = PATH.UI_CharmItemHint
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

local function InitTipSize(obj,scroll,maskObj,titleObj,layButton)
    local scrollRect = scroll:GetComponent(ClassType.RectTransform)
    local maskRect = maskObj:GetComponent(ClassType.RectTransform)
    local titleRect = titleObj:GetComponent(ClassType.RectTransform)

    local sizeDelta = scrollRect.sizeDelta
    local height = maskRect.sizeDelta.y + titleRect.sizeDelta.y
    if layButton ~= nil then
        local ButtonRect = layButton:GetComponent(ClassType.RectTransform)
        if layButton.activeSelf then
            height = height + ButtonRect.sizeDelta.y
        end
    end
    sizeDelta.y = height
    scrollRect.sizeDelta = sizeDelta

    obj.localPosition=Vector3.New(0,0,0)
end


def.override().OnCreate = function(self)
    self._PanelObject1 = {}
    self._PanelObject2 = {}
    self._PanelObject1._Lab_EquipTips = self:GetUIObject('Lab_EquipTips')
    self._PanelObject1._Lab_TimeTips = self:GetUIObject('Lab_TimeTips')
    self._PanelObject1._Frame_All = self:GetUIObject("Frame_Content")
    self._PanelObject1._Frame_Basic = self:GetUIObject('Frame_Basic')
    self._Lay_Button = self:GetUIObject("Lay_Button")
    self._PanelObject1._Frame_BaseAttri = self:GetUIObject('Frame_BaseAttri')
    self._PanelObject1._Frame_Tips = self:GetUIObject("Frame_Tips")
    self._PanelObject1._DropButton = self:GetUIObject("Drop_Button")
    self._Scroll1 = self:GetUIObject("Scroll")
    self._PanelObject1._Mask = self:GetUIObject("Mask")
    self._PanelObject1.Item = self:GetUIObject("Item")
    self._PanelObject1.Img_Quality = self:GetUIObject("Img_Quality")
    self._PanelObject1.Lab_ShowType = self:GetUIObject("Lab_ShowType")
    self._PanelObject1.Lab_ItemName = self:GetUIObject("Lab_ItemName")
    self._PanelObject1.Lab_InitLevel = self:GetUIObject("Lab_InitLevel")
    self._PanelObject1.Lab_QualityText = self:GetUIObject("Lab_QualityText")
    self._PanelObject1.Lab_LvText = self:GetUIObject("Lab_LvText")
    self._PanelObject1.Frame_Date = self:GetUIObject("Frame_Date")
    self._PanelObject1.Btn_GetType = self:GetUIObject("Btn_GetType")

    self._Scroll2 = self:GetUIObject("Scroll2")
    local uiTemplate = self._Scroll2:GetComponent(ClassType.UITemplate)
    self._PanelObject2._Lab_EquipTips = uiTemplate:GetControl(0)
    self._PanelObject2._Lab_TimeTips = uiTemplate:GetControl(1)
    self._PanelObject2._Frame_All = uiTemplate:GetControl(2)
    self._PanelObject2._Frame_Basic = uiTemplate:GetControl(3)
    self._PanelObject2._Frame_BaseAttri = uiTemplate:GetControl(4)
    self._PanelObject2._Frame_Tips = uiTemplate:GetControl(5)
    self._PanelObject2._Mask = uiTemplate:GetControl(6)
    self._PanelObject2.Item = uiTemplate:GetControl(15)
    self._PanelObject2.Img_Quality = uiTemplate:GetControl(7)
    self._PanelObject2.Lab_ShowType = uiTemplate:GetControl(8)
    self._PanelObject2.Lab_ItemName = uiTemplate:GetControl(9)
    self._PanelObject2.Lab_InitLevel = uiTemplate:GetControl(10)
    self._PanelObject2.Lab_QualityText = uiTemplate:GetControl(11)
    self._PanelObject2.Lab_LvText = uiTemplate:GetControl(12)
    self._PanelObject2.Frame_Date = uiTemplate:GetControl(13)
    self._PanelObject2.Btn_GetType = uiTemplate:GetControl(14)
end

def.override("dynamic").OnData = function(self, data)
    self._ItemData = data.itemCellData
    self._ItemEquipData = data.itemEquipData
    if self._ItemData._Template == nil or self._ItemData._Tid == 0 then 
        warn("CPanelCharmItemHint InitPanel cannot find")
        return 
    end

    self._CallWithFuncs = data.withFuncs
    if not data.withFuncs then
        self._PopFrom = data.params
    else
        self._ValidComponents = data.params
    end
    -- self._IsShowDropButton = false
    -- self._IsHaveMoreButton = false
    self:UpdatePanel()
    -- CItemTipMan.InitTipPosition(frameFixedPosition, self._Scroll1, 0)
end

def.override("string").OnClick = function(self,id)
    local component = nil 
    if id == "Btn_GetType"then
        local PanelData = 
        {
            ApproachIDs = self._ItemData._Template.ApproachID,
            ParentObj = self._Scroll1,
            IsFromTip = true,
            TipPanel = self,
            ItemId = self._ItemData._Tid,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData)
    elseif id == "Btn_GetType1" then
        local PanelData = 
        {
            ApproachIDs = self._ItemEquipData._Template.ApproachID,
            ParentObj = self._Scroll1,
            IsFromTip = true,
            TipPanel = self,
            ItemId = self._ItemEquipData._Tid,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData)
    end
end

def.method().UpdatePanel = function(self)
    self:UpdateRightPanel()
    self:UpdateLeftPanel()
    if self._ItemEquipData == nil then
        self._IsShowCompare = false
        self._Scroll2:SetActive(false)
        self._Scroll1.localPosition = Vector2.New(0,0)
    else
        self._IsShowCompare = true
        self._Scroll2:SetActive(true)
        self:IsSetCompareTipCenter(true)
    end

end

def.method().UpdateRightPanel = function(self)
    self:InitBaseInfo(self._ItemData, self._PanelObject1)
    if self._ItemData._ItemType == EItemType.Charm then
        self:InitCharmItem(self._ItemData, self._PanelObject1)
    end
    self:InitTips(self._ItemData, self._PanelObject1)
    if self._PopFrom ~= TipsPopFrom.CHAT_PANEL then 
        self._Lay_Button:SetActive(true)
        self._IsShowButton = true
        self:InitButtons(self._Lay_Button)
    else
        self._IsShowButton = false
        self._Lay_Button:SetActive(false)
    end
    InitTipSize(self._PanelObject1._Frame_All,self._Scroll1,self._PanelObject1._Mask,self._PanelObject1._Frame_Basic,self._PanelObject1._Lay_Button)
end

def.method().UpdateLeftPanel = function(self)
    if self._ItemEquipData ~= nil then
        self:InitBaseInfo(self._ItemEquipData, self._PanelObject2)
        if self._ItemEquipData._ItemType == EItemType.Charm then
            self:InitCharmItem(self._ItemEquipData, self._PanelObject2)
        end
        self:InitTips(self._ItemEquipData, self._PanelObject2)
    end
    InitTipSize(self._PanelObject2._Frame_All,self._Scroll2,self._PanelObject2._Mask,self._PanelObject2._Frame_Basic)
end


def.method("table", "table").InitBaseInfo = function (self, itemData, panelObject)
    if itemData._Tid == 0 then
        return
    end
    local itemElement = itemData._Template
    if itemElement == nil then 
        print("CPanelCharmItemHint InitPanel cannot find tid: " .. itemData._Tid )
        return 
    end

    local uiItem = panelObject.Item
    local img_item_icon = uiItem:FindChild("Img_ItemIcon")
    GUITools.SetItemIcon(img_item_icon, itemElement.IconAtlasPath)
    local img_bind = uiItem:FindChild("Img_Lock")
    img_bind:SetActive(itemData:IsBind())
    -- GUITools.SetItem(uiItem, itemElement, itemData:GetCount(), nil, itemData:IsBind())
    GUITools.SetGroupImg(panelObject.Img_Quality, itemElement.InitQuality)
    local labType = panelObject.Lab_ShowType
    if itemData._ItemType == EItemType.Pet then 
        local petTemp = CElementData.GetPetTemplate( tonumber(itemElement.Type1Param1))
        if petTemp ~= nil then  
            GUI.SetText(labType, StringTable.Get(19022 + petTemp.Genus))
        end
    else
        if itemElement.ProfessionLimitMask == 15 or itemData._Template.ProfessionLimitMask == 255 or itemData._Template.ProfessionLimitMask == 31 then  
            GUI.SetText(labType,itemData._DescriptionType)
        else
            GUI.SetText(labType,StringTable.Get(17000 + itemElement.ProfessionLimitMask)..itemData._DescriptionType)
        end
    end

    local name = ""
    if game._IsOpenDebugMode == true then
        name = "(".. itemElement.Id ..")" .. itemElement.TextDisplayName
    else        
        name = itemElement.TextDisplayName
    end

    GUI.SetText(panelObject.Lab_ItemName, name) 
    local LabInitLevel = panelObject.Lab_InitLevel
    if itemElement.InitLevel > 0 or game._IsOpenDebugMode == true then 
        LabInitLevel:SetActive(true)
        GUI.SetText(LabInitLevel,string.format(StringTable.Get(10657),itemElement.InitLevel))
    else
        LabInitLevel:SetActive(false)
    end
    local labQuality = panelObject.Lab_QualityText
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + itemData._Quality), itemData._Quality)
    GUI.SetText(labQuality,color)
    local lab_UseLevel = panelObject.Lab_LvText
    if itemElement.MinLevelLimit > 0 then 
        lab_UseLevel :SetActive(true)
        GUI.SetText(lab_UseLevel,tostring(itemElement.MinLevelLimit))
    else
        lab_UseLevel:SetActive(false)
    end
end

def.method("table", "table").InitCharmItem = function(self, itemData, panelObject)
    panelObject._Frame_Tips:SetActive(true)
    panelObject._Frame_BaseAttri:SetActive( itemData._CharmItemTemplate.PropID1 ~= 0 or itemData._CharmItemTemplate.PropID2 ~= 0 )
    local item1 = panelObject._Frame_BaseAttri:FindChild("Item1")
    local item2 = panelObject._Frame_BaseAttri:FindChild("Item2")
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

def.method("table", "table").InitTips = function(self, itemData, panelObject)
    local itemTemp = itemData._Template
    if itemTemp == nil then return end
    local btnGet = panelObject.Btn_GetType
    if itemData._Template.ApproachID == "" then
        btnGet:SetActive(false)
    else
        btnGet:SetActive(true)
    end
    local frameSell = self:GetUIObject("Frame_Sell")
    frameSell:SetActive(false)
    if itemData:CanSell() then 
        frameSell:SetActive(true)
        GUI.SetText(self:GetUIObject("Lab_Money"),tostring(itemData._Template.RecyclePriceInGold))
    end
    
    local labDecompose = panelObject._Frame_Tips:FindChild("Lab_DecomposeTips")
    if not itemData :CanDecompose() then 
        labDecompose:SetActive(false)
    else
        labDecompose:SetActive(true)
    end
    if itemData._ItemType == EItemType.PetTalentBook then 
        local TalentTid = tonumber(itemTemp.Type1Param1)
        local TalentTemplate = CElementData.GetTalentTemplate(TalentTid)
        if TalentTemplate == nil then 
            warn("TalentTemplate id "..TalentTid .." is nil")
            return
        end
        GUI.SetText(panelObject._Lab_EquipTips,DynamicText.ParseSkillDescText(TalentTid, 1, true))
    else
        GUI.SetText(panelObject._Lab_EquipTips,itemTemp.TextDescription)
    end
    local time = 0
    -- 判断是到期时间还是售卖冻结时间
    local IsExpireTime = false
    if itemData._SellCoolDownExpired > 0 then 
        time = itemData._SellCoolDownExpired - GameUtil.GetServerTime()/1000 
        IsExpireTime = false
    elseif itemData._ExpireData > 0 then 
        time = itemData._ExpireData 
        IsExpireTime = true
    end
    local FrameDate = panelObject.Frame_Date
    if time > 0 then 
        FrameDate:SetActive(true)
        self:ShowTime(time,IsExpireTime,panelObject._Lab_TimeTips)
        local callBack = function()
            if not IsExpireTime then 
                time = itemData._SellCoolDownExpired - GameUtil.GetServerTime()/1000 
            else
                time = itemData._ExpireData 
            end
            if time > 0 then
                self:ShowTime(time,IsExpireTime,panelObject._Lab_TimeTips)
            else
                if not IsExpireTime then
                    GUI.SetText(panelObject._Lab_TimeTips,StringTable.Get(10684))
                end
                _G.RemoveGlobalTimer(self._ItemCoolDownTimer)
                self._ItemCoolDownTimer = 0	
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
    self._PanelObject1 = nil
    self._PanelObject2 = nil
    self._ItemEquipData = nil
    instance = nil 
end

CPanelCharmItemHint.Commit()
return CPanelCharmItemHint