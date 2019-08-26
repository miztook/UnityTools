
local Lplus = require 'Lplus'
local CPanelHintBase = require 'GUI.CPanelHintBase'
local bit = require "bit"
local GUITools = require "GUI.GUITools"
local CGame = Lplus.ForwardDeclare("CGame")
local PBHelper = require "Network.PBHelper"
local CElementData = require "Data.CElementData"
local DynamicText = require "Utility.DynamicText"
local EItemBindMode = require "PB.Template".Item.ItemBindMode
local CPageBag = require "GUI.CPageBag"
local EItemOptLockType = require "PB.data".EItemOptLockType
local ItemComponents = require "Package.ItemComponents"
local CPanelBase = require "GUI.CPanelBase"
local CPanelItemApproach = require "GUI.CPanelItemApproach"
local CPanelEquipHint = Lplus.Extend(CPanelHintBase, 'CPanelEquipHint')   

local def = CPanelEquipHint.define

def.field("userdata")._FrameContent1 = nil 
def.field('userdata')._FrameContent2 = nil 
def.field("userdata")._Mask1 = nil 
def.field("userdata")._Mask2 = nil

def.field("userdata")._FrameQuality1 = nil 
def.field("userdata")._FrameQuality2 = nil 
def.field('userdata')._Frame_Attribute1 = nil
def.field('userdata')._Frame_Attribute2 = nil
def.field('userdata')._Frame_Other1 = nil
def.field('userdata')._Frame_Other2 = nil
def.field('userdata')._Frame_Tips1 = nil
def.field('userdata')._Frame_Tips2 = nil
def.field("userdata")._Frame_BaseAttribute1 = nil
def.field("userdata")._Frame_BaseAttribute2 = nil 
def.field("userdata")._Frame_EnchantAttri1 = nil 
def.field("userdata")._Frame_EnchantAttri2 = nil 
def.field("userdata")._Frame_RefineAttri1 = nil 
def.field("userdata")._Frame_RefineAttri2 = nil 
def.field("userdata")._Frame_Basic2 = nil 
def.field("userdata")._Frame_Basic1 = nil 
def.field("userdata")._RdoLock1 = nil
def.field("userdata")._RdoLock2 = nil
def.field("userdata")._ImgArrow = nil
def.field("userdata")._CurSelectRdo = nil 
def.field("userdata")._FrameBottom1 = nil 
def.field("userdata")._FrameBottom2 = nil 

def.field("string")._BaseProTextDisplayName1 = ""
def.field("string")._BaseProTextDisplayName2 = ""
def.field("number")._CellSlot = 0
def.field("number")._BattleValue = 0
def.field("number")._MaxTipHeight = 563
def.field("number")._ItemCoolDownTimer1 = 0
def.field("number")._ItemExpiredTime1 = 0 
def.field("number")._EnchantExpiredTimer1 = 0 
def.field("number")._ItemCoolDownTimer2 = 0
def.field("number")._ItemExpiredTime2 = 0 
def.field("number")._EnchantExpiredTimer2 = 0
def.field("table")._CompareData = nil 
def.field("table")._LockItemData = nil

local instance = nil
def.static('=>', CPanelEquipHint).Instance = function ()
    if not instance then
        instance = CPanelEquipHint()
        instance._PrefabPath = PATH.UI_EquipmentTips
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end
    return instance
end

local C2SLockItem = function (self,itemData,IsLocked)
    local optType = 0
    if not IsLocked then 
        optType = EItemOptLockType.EItemOptLockType_Unlock 
    else
        optType = EItemOptLockType.EItemOptLockType_Lock
    end
    local C2SItemOptLock = require "PB.net".C2SItemOptLock
    local protocol = C2SItemOptLock()
    local net = require "PB.net"
    local packageType = 0
    if itemData._PackageType == IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK then 
        packageType = net.BAGTYPE.ROLE_EQUIP 
    elseif itemData._PackageType == IVTRTYPE_ENUM.IVTRTYPE_PACK then 
        packageType = net.BAGTYPE.BACKPACK
    elseif itemData._PackageType == IVTRTYPE_ENUM.IVTRTYPE_STORAGE then 
        packageType = net.BAGTYPE.STORAGEPACK
    end

    protocol.Index = itemData._Slot
    protocol.BagType = packageType
    protocol.OptType = optType
    PBHelper.Send(protocol)
end

def.override().OnCreate = function(self)
    self._FrameContent1 = self:GetUIObject("Frame_Content")
    self._FrameContent2 = self:GetUIObject("Frame_Content2")
    self._Lay_Button = self:GetUIObject("Lay_Button")

    self._FrameQuality2 = self:GetUIObject("Frame_Quality2")
    self._Frame_Basic2 = self:GetUIObject("Frame_Basic2")
    self._Frame_BaseAttribute2 = self:GetUIObject("Frame_BaseAttri2")
    self._Frame_Other2 = self:GetUIObject('Frame_Other2')
    self._Frame_Tips2 = self:GetUIObject('Frame_Tips2')
    self._Frame_Attribute2 = self:GetUIObject('Frame_Attribute2')
    self._Frame_EnchantAttri2 = self:GetUIObject("Frame_EnchantAttri2")
    self._Frame_RefineAttri2 = self:GetUIObject("Frame_RefineAttri2")
    self._RdoLock2 = self:GetUIObject("Rdo_Lock2")
    self._FrameBottom2 = self:GetUIObject("Frame_Bottom2")
    GameUtil.RegisterUIEventHandler(self._Panel, self._RdoLock2, ClassType.GNewIOSToggle)

    self._FrameQuality1 = self:GetUIObject("Frame_Quality1")
    self._Frame_Basic1 = self:GetUIObject("Frame_Basic1")
    self._Frame_Attribute1 = self:GetUIObject('Frame_Attribute1')
    self._Frame_BaseAttribute1 = self:GetUIObject("Frame_BaseAttri1")
    self._Frame_Other1 = self:GetUIObject('Frame_Other1')
    self._Frame_Tips1 = self:GetUIObject('Frame_Tips1')
    self._Frame_EnchantAttri1 = self:GetUIObject("Frame_EnchantAttri1")
    self._Frame_RefineAttri1 = self:GetUIObject("Frame_RefineAttri1")
    self._RdoLock1 = self:GetUIObject("Rdo_Lock1")
    self._FrameBottom1 = self:GetUIObject("Frame_Bottom1")
    GameUtil.RegisterUIEventHandler(self._Panel, self._RdoLock1, ClassType.GNewIOSToggle)

    self._ImgArrow = self:GetUIObject('Img_Arrow')
    self._Scroll1 = self:GetUIObject("Scroll1")
    self._Scroll2 = self:GetUIObject("Scroll2")
    self._Mask1 = self:GetUIObject("Mask1")
    self._Mask2 = self:GetUIObject("Mask2")
end

def.override("dynamic").OnData = function(self, data)

    CPanelBase.OnData(self,data)
    self._ItemData = data.itemCellData
    if self._ItemData._Template == nil or self._ItemData._Tid == 0 then 
        warn("CPanelEquipHint InitPanel cannot find tid: " .. self._ItemData._Tid )
        return 
    end
    self._CallWithFuncs = data.withFuncs
    if not data.withFuncs then
        self._PopFrom = data.popFrom
    else
        self._PopFrom = TipsPopFrom.OTHER_PANEL
        self._ValidComponents = data.params
    end
    
    self._IsShowCompare = false
    self:InitPanel()
end

def.override("string").OnClick = function(self,id)
    CPanelBase.OnClick(self,id)
    local component = nil 
   
    if string.find(id,"Rdo_Lock") then 
        local i = tonumber(string.sub(id,-1))
        if i == 1 then 
            self._CurSelectRdo = self._RdoLock1
        else
            self._CurSelectRdo = self._RdoLock2
        end
        local IsLocked = false
        if i == 1 then 
            self._LockItemData = self._ItemData
            IsLocked = not self._ItemData._IsLock
        elseif i == 2 then 
            self._LockItemData = self._CompareData
            IsLocked = not self._CompareData._IsLock
        end
        C2SLockItem(self,self._LockItemData,IsLocked)
    elseif string.find(id,"Btn_GetType") then 
        local i = tonumber(string.sub(id,-1))
        local itemData = nil
        if i == 1 then
            itemData = self._ItemData
        else
            itemData = self._CompareData
        end
        local PanelData = 
        {
            ApproachIDs = itemData._Template.ApproachID,
            ParentObj = self._FrameBottom1,
            IsFromTip = true,
            TipPanel = self,
            ItemId  = itemData._Tid,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData) 
    end
end

def.method().InitPanel = function(self)
    if self._ItemData == nil then
        --print("CPanelEquipHint InitPanel _ItemData is nil")
        return 
    end
    if self._PopFrom == nil then
        printLog("pop")
    end

    self._ImgArrow:SetActive(false)
    if self._PopFrom == TipsPopFrom.BACK_PACK_PANEL or self._PopFrom == TipsPopFrom.OTHER_PALYER then
        self:InitCompareTip()
        self._Scroll2:SetActive(self._IsShowCompare)
        if self._IsShowCompare then
            self:InitBaseInfo(true)
        end
    else
        self._Scroll2:SetActive(false)
    end

    self:InitBaseInfo(false)
    self:InitQualityAndLevel()
    if self._PopFrom == TipsPopFrom.OTHER_PANEL then 
        self:InitVirtualEquip()
    else
        self:InitBaseAttribute()
        self:InitEnchantAttribute()
        self:InitRefineAttribute()
        self:InitFrameAttribute()
        self:InitFrameOther()
        self:InitTips()
        self:InitBottom()
        if self._PopFrom ~= TipsPopFrom.Equip_Process and self._PopFrom ~= TipsPopFrom.CHAT_PANEL and self._PopFrom ~= TipsPopFrom.WithoutButton and self._PopFrom ~= TipsPopFrom.ITEM_DBPANEL then 
            self._Lay_Button:SetActive(true)
            self._IsShowButton = true
            self:InitButtons(self._Lay_Button)
        else
            -- 聊天界面不显示锁
            self._RdoLock1 :SetActive(true)
            if self._PopFrom == TipsPopFrom.CHAT_PANEL then 
                self._RdoLock1 :SetActive(false)
            end
            self._IsShowButton = false
            self._Lay_Button:SetActive(false)
        end
    end
    self:InitMaskHeight(self._FrameContent1, self._Scroll1, self._Mask1, self._FrameBottom1,self._Frame_Tips1,self:GetUIObject("Lab_EquipTips1"),101, 56)
    -- 设置按钮位置
    self:InitButtonPosition( self._FrameBottom1, self._Lay_Button)
    self._Scroll1.localPosition = Vector2.New(0,0)

    -- 设置tip上下居中左右居中
    if self._IsShowCompare then 
        self:InitMaskHeight(self._FrameContent2, self._Scroll2, self._Mask2,self._FrameBottom2,self._Frame_Tips2, self:GetUIObject("Lab_EquipTips2"),101, 0)
        self:IsSetCompareTipCenter(true)
    end  
end

def.method().InitVirtualEquip = function(self)
    local baseId = self._ItemData._Template.AttachedPropertyGeneratorId
    
    -- 基础属性
    local FightProperty = CElementData.GetPropertyInfoById(baseId)
    self._Frame_BaseAttribute1:FindChild("Item2"):SetActive(false)
    self._Frame_BaseAttribute1:FindChild("Item3"):SetActive(false)
    local labName = self._Frame_BaseAttribute1:FindChild("Item1/Lab_AttriTips")
    local labValue = self._Frame_BaseAttribute1:FindChild("Item1/Lab_AttriValues")
    GUI.SetText(labName,FightProperty.Name)
    GUI.SetText(labValue,string.format(StringTable.Get(10679),GUITools.FormatNumber(FightProperty.MinValue),GUITools.FormatNumber(FightProperty.MaxValue)))
    -- 重铸属性
    for i = 1,5 do
        local item = self._Frame_Attribute1:FindChild("Item"..i)
        if item ~= nil then 
            item:SetActive(false)
        end
    end
    local id = self._ItemData._Template.AttachedPropertyGroupGeneratorId
    local GroupTemp = CElementData.GetAttachedPropertyGroupGeneratorTemplateMap(id)
    local count = 0
    if GroupTemp ~= nil then
        for i ,v in ipairs(GroupTemp.CountData.GenerateCounts) do 
            if v.Weight > 0 then
                count = count + 1
            end
        end
    end     
    local ImgEnchant = self:GetUIObject("Img_Tag_Enchant1")
    ImgEnchant:SetActive(false)
    local labTip = self._Frame_Attribute1:FindChild("Lab_Tip")
    if count > 1 then 
        GUI.SetText(labTip,string.format(StringTable.Get(10681),1,count))
    elseif count == 1 then 
        GUI.SetText(labTip,string.format(StringTable.Get(10680)))
    end
    self._Frame_RefineAttri1:SetActive(false)
    self._Frame_EnchantAttri1:SetActive(false)
    self._Frame_Other1:SetActive(false)
    self:InitTips()
    self:InitBottom()
    self:InitButtons(self._Lay_Button)
end

-- mask + bottom 内容加上遮罩最大高度是430
def.method("userdata","userdata","userdata","userdata","userdata","userdata","number","number").InitMaskHeight = function (self, frameContent, scroll, maskObj,bottomObj,frameTip,labDescribe,title_height, btn_height)
    local heightContent = GameUtil.GetTipLayoutHeight(frameContent)
    local heightBottom = GameUtil.GetTipLayoutHeight(bottomObj)
    local height =  heightContent + heightBottom 
    local heightMask = 0
    if height < 0 then warn("C# function is wrong") return end
    local scrollRect = scroll:GetComponent(ClassType.RectTransform)
    local maskRect = maskObj:GetComponent(ClassType.RectTransform)
    local scrollSizeDelta = scrollRect.sizeDelta
    local maskSizeDelta = maskRect.sizeDelta

    if height <= 315 then 
        height = 315
        heightMask = height - heightBottom 
        GameUtil.SetScrollEnabled(scroll,false)
    else
        if height >= 430 then
            height = 430
            heightMask = height - heightBottom 
        elseif height < 430 and height > 315 then 
            heightMask = height - heightBottom 
            GameUtil.SetScrollEnabled(scroll,false)
        end
    end
    maskSizeDelta.y = heightMask
    maskRect.sizeDelta = maskSizeDelta
    scrollSizeDelta.y = height + title_height 
    scrollRect.sizeDelta = scrollSizeDelta
    frameContent.localPosition = Vector3.New(0,0,0)
end 

def.method("boolean").InitBaseInfo = function(self,isCompare)
    local i = 1
    local itemElement = self._ItemData._Template 
    local itemData = self._ItemData
    local Rdo_Lock = self._RdoLock1
    if isCompare then 
        Rdo_Lock = self._RdoLock2
        i = 2
        itemElement = self._CompareData._Template
        itemData = self._CompareData
        self:GetUIObject("Img_Equiped"..i):SetActive(true)
    end
    if itemElement == nil then  return end
    if not isCompare then 
        local imgEquiped = self:GetUIObject("Img_Equiped"..i)
        imgEquiped:SetActive(false)
        if self._PopFrom == TipsPopFrom.ROLE_PANEL then 
            imgEquiped:SetActive(true)
        else 
            imgEquiped:SetActive(false)
        end 
        if self._IsShowCompare then             
            local BattleValue = tonumber (itemData:GetFightScore())
            self._ImgArrow:SetActive(true)
            if BattleValue < self._CompareData:GetFightScore() then 
                GUITools.SetGroupImg(self._ImgArrow,1)
            elseif BattleValue > self._CompareData:GetFightScore() then 
                GUITools.SetGroupImg(self._ImgArrow,0)
            else 
                self._ImgArrow:SetActive(false)
            end
        end
    end
    local labBindMode = self:GetUIObject("Lab_BindType")
    labBindMode:SetActive(false)
    -- 策划需求暂时隐藏
    -- if labBindMode ~= nil then
    --     if self._PopFrom == TipsPopFrom.OTHER_PANEL then 
    --         if itemElement.BindMode == EItemBindMode.OnGain then 
    --             labBindMode:SetActive(true)
    --             GUI.SetText(labBindMode,StringTable.Get(10718))
    --         elseif itemElement.BindMode == EItemBindMode.OnUse then 
    --             labBindMode:SetActive(true)
    --             GUI.SetText(labBindMode,StringTable.Get(10718))
    --         elseif itemElement.BindMode == EItemBindMode.Never then 
    --             labBindMode:SetActive(false)
    --         end
    --     else
    --         labBindMode:SetActive(false)
    --     end
    -- end
    local uiItem = self:GetUIObject("Item"..i)
    local img_item_icon = uiItem:FindChild("Img_ItemIcon")
    GUITools.SetItemIcon(img_item_icon, itemElement.IconAtlasPath)
    local img_Time = uiItem:FindChild("Img_Time")
    local img_bind = uiItem:FindChild("Img_Lock")
    img_bind:SetActive(itemData:IsBind())
    if not itemData:IsBind() then 
        img_Time:SetActive(self._ItemData._SellCoolDownExpired > 0)
    else
        img_Time:SetActive(false)
    end
    -- GUITools.SetItem(uiItem, itemElement, 0, 0, itemData:IsBind())
    GUITools.SetGroupImg(self:GetUIObject("Img_Quality"..i), itemElement.InitQuality)
    local levelstr = string.format(StringTable.Get(10714),itemElement.MinLevelLimit)
    if game._HostPlayer._InfoData._Level < itemElement.MinLevelLimit then
        levelstr = RichTextTools.GetUnavailableColorText( levelstr ) 
    end
    local text = StringTable.Get(17000 + itemElement.ProfessionLimitMask) .. StringTable.Get(10400 + itemElement.Slot)
    GUI.SetText(self:GetUIObject("Lab_LevelValues"..i),tostring(levelstr))
    GUI.SetText(self:GetUIObject("Lab_JobAndPoint"..i),text)
    local frameBattle = self:GetUIObject("Frame_Battle")
    if self._PopFrom ~= TipsPopFrom.OTHER_PANEL then 
        frameBattle:SetActive(true)
        local fight_score = itemData:GetFightScore()
        if fight_score <= 0 then
            frameBattle:SetActive(false)
        end
        GUI.SetText(self:GetUIObject("Lab_BattleValues"..i), GUITools.FormatNumber(itemData:GetFightScore()))
    else
        frameBattle:SetActive(false)
    end
    local labInforce = self:GetUIObject("Lab_InforceValue"..i)
    local labRefine = self:GetUIObject("Lab_RefineValue"..i)
    local inforceLv = itemData:GetInforceLevel()
    local refineLv = itemData:GetRefineLevel()
    if inforceLv > 0 then 
        labInforce:SetActive(true)
        GUI.SetText(labInforce,string.format(StringTable.Get(10631), inforceLv))
    else
        labInforce :SetActive(false)
    end
    if refineLv > 0 then 
        labRefine:SetActive(true)
        GUI.SetText(labRefine,tostring(refineLv))
    else
        labRefine:SetActive(false)
    end

    local name = ""
    if game._IsOpenDebugMode == true then
        name = "(".. itemElement.Id ..")" .. itemElement.TextDisplayName
    else        
        name = itemElement.TextDisplayName
    end
    GUI.SetText(self:GetUIObject("Lab_EquipName"..i), name)
    local imgEquipGrade = self:GetUIObject("Img_EquipGrade"..i)
    if self._PopFrom == TipsPopFrom.OTHER_PANEL  then
        imgEquipGrade:SetActive(false)
        Rdo_Lock:SetActive(false)
        return
    end
    if self._PopFrom ~= TipsPopFrom.OTHER_PALYER then
        Rdo_Lock:SetActive(true)
        Rdo_Lock:GetComponent(ClassType.GNewIOSToggle):SetValue(itemData._IsLock,true)
        local labLockYes = Rdo_Lock:FindChild("Lab_Yes")
        local labLockNo = Rdo_Lock:FindChild("Lab_No")
        if not itemData._IsLock then 
            labLockYes:SetActive(false)
            labLockNo:SetActive(true)
        else
            labLockYes:SetActive(true)
            labLockNo:SetActive(false)
        end
    else
        Rdo_Lock:SetActive(false)
    end
    local imgGrade = self:GetUIObject("Img_Grade"..i)
    GUITools.SetGroupImg(imgGrade,itemData._BaseAttrs.Star)
end

-- 装备品质 和限制等级
def.method().InitQualityAndLevel = function(self)
    if self._IsShowCompare then 
        self:ShowQulityAndLevel(self._FrameQuality2,self._CompareData)
    end
    self:ShowQulityAndLevel(self._FrameQuality1,self._ItemData)
end

def.method("userdata","table").ShowQulityAndLevel = function(self,parentObj,itemData)
    local labQuality  = parentObj:FindChild("Lab_Tip/Lab_Quality")
    local labLv = parentObj:FindChild("Lab_Lv")
    local color = RichTextTools.GetQualityText(StringTable.Get(10000 + itemData._Quality), itemData._Quality)
    GUI.SetText(labQuality,color)
    GUI.SetText(labLv,tostring(itemData._Template.MinLevelLimit))
end

-- 基础属性/强化属性/专精
def.method().InitBaseAttribute = function (self)
    if self._IsShowCompare then 
        self._BaseProTextDisplayName2 = self:ShowBaseAttriData(self._Frame_BaseAttribute2,self._CompareData)
    end
    self._BaseProTextDisplayName1 = self:ShowBaseAttriData(self._Frame_BaseAttribute1,self._ItemData)
end

def.method('userdata','table',"=>","string").ShowBaseAttriData = function (self,parentObj,itemData)
    local fightElement = CElementData.GetAttachedPropertyTemplate(itemData._BaseAttrs.ID)
    if fightElement == nil then
        warn("fightElement is nil : " .. tostring(itemData._BaseAttrs.ID) )
        parentObj:SetActive(false)
        return "NIL"
    end
    parentObj:SetActive(true)
    local BaseProTextDisplayName = fightElement.TextDisplayName or "NIL"
    local item1 = parentObj:FindChild("Item1")
    local labName = item1:FindChild("Lab_AttriTips")
    local labValue = item1:FindChild("Lab_AttriValues")
    GUI.SetText(labName,BaseProTextDisplayName)
    GUI.SetText(labValue,GUITools.FormatNumber(itemData._BaseAttrs.Value))
    -- 强化 
    local item2 = parentObj:FindChild("Item2")
    local item3 = parentObj:FindChild("Item3")
    local inforceLv = itemData:GetInforceLevel()
    if inforceLv > 0 then 
        item2:SetActive(true)
        local labName = item2:FindChild("Lab_AttriTips")
        local labValue = item2:FindChild("Lab_AttriValues")
        local labLevel = item2:FindChild("Lab_Level")
        GUI.SetText(labName,BaseProTextDisplayName)
        GUI.SetText(labValue,GUITools.FormatNumber(itemData:GetBaseInforceIncrease()))
        GUI.SetText(labLevel,string.format(StringTable.Get(10632),inforceLv))
    else
        item2:SetActive(false)
    end
    --专精 (2018.12.27 应策划需求专精不再显示)
    item3:SetActive(false)
   
    return BaseProTextDisplayName
end

-----------------------------------重铸属性Start--------------------------------
def.method().InitFrameAttribute = function(self)
    if self._IsShowCompare then 
       self:CreatFrameAttributeItem(self._Frame_Attribute2,self._CompareData)
    end
   self:CreatFrameAttributeItem(self._Frame_Attribute1,self._ItemData)
end

def.method("userdata","table").CreatFrameAttributeItem = function (self,frameObj,itemData)
    frameObj:SetActive(true)
    local isHas = itemData:HasEquipAttrs()
    local count = #itemData._EquipBaseAttrs
    local labTip = frameObj:FindChild("Lab_Tip")
    if not isHas then 
        frameObj:SetActive(false)
        -- local generatorInfo = CElementData.GetAttachedPropertyGroupGeneratorTemplateMap( itemData._Template.AttachedPropertyGroupGeneratorId ) 
        -- if generatorInfo == nil then
        -- return end
    end
    GUI.SetText(labTip,StringTable.Get(10622)..StringTable.Get(10624))
    for i = 1,5 do
        if i <= count then   
            local item = frameObj:FindChild("Item"..i)
            if item == nil then return end
            local Lab_AttriTips = item:FindChild('Lab_AttriTips')
            local Lab_AttriVlalues = item:FindChild('Lab_AttriVlalues')     
            self:InitFrameAttributeItemData(Lab_AttriTips,Lab_AttriVlalues,itemData,i)
        else
            frameObj:FindChild("Item"..i):SetActive(false)
        end
    end
end

def.method("userdata",'userdata','table','number').InitFrameAttributeItemData = function (self,Lab_AttriTips,Lab_AttriVlalues,itemData,index)
    
    local attrIndex =itemData._EquipBaseAttrs[index].index
    local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate(attrIndex )
    if attachPropertGenerator == nil then
        warn("attachPropertGenerator is nil : " .. tostring(attrIndex) )
        return
    end 

    local fightElement = CElementData.GetAttachedPropertyTemplate(attachPropertGenerator.FightPropertyId )
    if fightElement == nil then
        warn("fightElement is nil : " .. tostring(attachPropertGenerator.FightPropertyId ) )
        return
    end

    local displayname = fightElement.TextDisplayName or "NIL"
    local value = itemData._EquipBaseAttrs[index].value
    GUI.SetText(Lab_AttriTips, displayname)
    GUI.SetText(Lab_AttriVlalues,GUITools.FormatNumber(value))
end
-----------------------------------重铸属性end--------------------------------

-- 精炼属性
def.method().InitRefineAttribute = function(self)
    if self._IsShowCompare then 
        self:ShowRefineAttriData(self._Frame_RefineAttri2,self._CompareData,self._BaseProTextDisplayName2)
    end
    self:ShowRefineAttriData(self._Frame_RefineAttri1,self._ItemData,self._BaseProTextDisplayName1)
end

def.method('userdata','table',"string").ShowRefineAttriData = function (self,parentObj,itemData,baseProName)
    if baseProName == "NIL" then 
        parentObj:SetActive(false)
        return
    end
    if itemData._Template.EquipRefineTId == nil  then 
        parentObj:SetActive(false)
        return
    end
    local equipRefineItem = CElementData.GetTemplate('EquipRefine', itemData._Template.EquipRefineTId)
    if  equipRefineItem == nil then 
        parentObj:SetActive(false)
        return
    end
    local refineLevel = itemData:GetRefineLevel()
    if refineLevel == 0 then 
        parentObj:SetActive(false)
        return
    end   
    parentObj:SetActive(true)
    local labName = parentObj:FindChild("Lab_AttriTips")
    local labValue = parentObj:FindChild("Lab_AttriValues")
    GUI.SetText(labName,baseProName)
    GUI.SetText(labValue,string.format(StringTable.Get(10691),GUITools.FormatMoney(itemData:GetRefineIncrease())))
    for i = 1, 10 do 
        if i <= refineLevel then 
            GUITools.SetGroupImg(parentObj:FindChild("Frame_Start/Img_"..i),1)
        else
            GUITools.SetGroupImg(parentObj:FindChild("Frame_Start/Img_"..i),0)
        end
    end
end

--传奇属性
def.method().InitFrameOther = function(self)
    if self._IsShowCompare then 
        self:GetOtherValue(self._Frame_Other2,self._CompareData)
    end
   self:GetOtherValue(self._Frame_Other1,self._ItemData)
    
end

def.method("userdata","table").GetOtherValue = function (self, parentObj,itemData)
    if itemData._TalentId ~= 0 then
        parentObj:SetActive(true)
        local talentTemplate = CElementData.GetTalentTemplate(itemData._TalentId )
        if talentTemplate == nil then
            warn("itemTemplate.TalentId"..itemData._TalentId)
            return 
        end

        --判断是否穿上装备
        local isPutOn = false
        local itemSet = game._HostPlayer._Package._EquipPack._ItemSet
        for i,v in ipairs( itemSet ) do
            if itemData._Template.Id == v._Tid then
                isPutOn = true
                break
            end
        end

        --技能名称
        local skillName = talentTemplate.Name
        -- 判断是否激活
        local isActive = false
        if itemData._TalentLevel ~= 0 then
            isActive = true
        end  

       
        

        --升级条件 获取被动技能
        local labCondition = parentObj:FindChild("Lab_ConditionContent")
        labCondition:SetActive(false)
        -- local LegendUpgrade = CElementData.GetLegendaryUpgradeTemplate(itemData._TalentId)
        -- local conditionDesStr = ""
        -- if LegendUpgrade == nil then 
            -- labCondition:SetActive(false)
        -- else
        --     local curLevelData = LegendUpgrade.ParamDatas[itemData._TalentLevel+1]
        --     if curLevelData == nil then
        --         labCondition:SetActive(false)
        --     else
        --         labCondition:SetActive(true)
        --         local conditionTips = ""
        --         if not isActive then 
        --             conditionTips = StringTable.Get(140)
        --         else
        --             conditionTips = StringTable.Get(141)
        --         end
        --         --具体条件
        --         local conditionStr = StringTable.Get(150+ LegendUpgrade.UpgradeTypeId)
        --         if LegendUpgrade.UpgradeTypeId == EnumDef.LegendUpgradeType.KILLCOUNT then
        --             conditionDesStr = string.format("%s：%s %d/%d",conditionTips,conditionStr,itemData._TalentParam,curLevelData.Param)
        --         elseif LegendUpgrade.UpgradeTypeId == EnumDef.LegendUpgradeType.QUEST then
        --             local quest = CElementData.GetQuestTemplate(itemData._TalentParam)
        --             conditionDesStr = string.format("%s：%s%s",conditionTips,conditionStr,quest.Name)
        --         elseif LegendUpgrade.UpgradeTypeId == EnumDef.LegendUpgradeType.STRENGHT  then
        --             conditionDesStr = string.format("%s：%s%d",conditionTips,conditionStr,itemData._TalentParam)
        --         elseif LegendUpgrade.UpgradeTypeId == EnumDef.LegendUpgradeType.NPC  then
        --             local npc = CElementData.GetNpcTemplate(itemData._TalentParam)
        --             conditionStr = string.format(conditionStr,npc.Name)
        --             conditionDesStr = string.format("%s：%s",conditionTips,conditionStr)
        --         end
        --     end
        -- end

        local labSkillName = parentObj:FindChild("Lab_SkillContent")
        local labSkillDes = parentObj:FindChild("Lab_OtherTips")
        local skillDes = DynamicText.ParseSkillDescText(itemData._TalentId,itemData._TalentLevel, true)

        -- 控制颜色显示
        -- if isPutOn and isActive then
            --激活 并穿上
            GUI.SetText(labSkillName,string.format(StringTable.Get(10664),skillName,itemData._TalentLevel))
            -- GUI.SetText(labCondition,string.format(StringTable.Get(10659),conditionDesStr))
            --被动技能描述
            GUI.SetText(labSkillDes,string.format(StringTable.Get(10666),skillDes))
    --     else
    --         -- 未激活或未穿上
    --         GUI.SetText(labSkillDes,string.format(StringTable.Get(10665),skillDes))
    --         if not isActive then 
    --             GUI.SetText(labSkillName,string.format(StringTable.Get(10662),skillName))
    --             GUI.SetText(labCondition,string.format(StringTable.Get(10658),conditionDesStr))
    --         else
    --             GUI.SetText(labSkillName,string.format(StringTable.Get(10663),skillName,itemData._TalentLevel))
    --             GUI.SetText(labCondition,string.format(StringTable.Get(10659),conditionDesStr))
    --         end
    --     end    
    -- else
    --     parentObj:SetActive(false)  
    end
end

--附魔属性
def.method().InitEnchantAttribute = function(self)
    if self._IsShowCompare then 
        self:ShowEnchantAttri(self._Frame_EnchantAttri2,self._CompareData,2)
    end
    self:ShowEnchantAttri(self._Frame_EnchantAttri1,self._ItemData,1)
end

def.method("userdata","table","number").ShowEnchantAttri = function (self,frameObj,itemData,index)
    local ImgEnchant = self:GetUIObject("Img_Tag_Enchant"..index)
    if itemData._EnchantAttr == nil or itemData._EnchantAttr.index == 0 then
        frameObj:SetActive(false)
        ImgEnchant:SetActive(false)
        return
    end
    ImgEnchant:SetActive(true)
    frameObj:SetActive(true)
    local fightElement = CElementData.GetPropertyInfoById(itemData._EnchantAttr.index)
    local name = fightElement.Name   
    local value = tonumber(itemData._EnchantAttr.value)
    GUI.SetText(frameObj:FindChild("Frame_AttriTips/Lab_AttriTips"),name)
    GUI.SetText(frameObj:FindChild("Frame_AttriTips/Lab_AttriValues"),GUITools.FormatNumber(value))
    local labTime = frameObj:FindChild("Lab_AttriTime")
    local timerId = 0
    local callBack = function()
        local time = itemData._EnchantExpiredTime - GameUtil.GetServerTime()/1000 
        if time > 0 then
           self:ShowTime(time,nil,labTime)
        else
            GUI.SetText(labTime,"")
            _G.RemoveGlobalTimer(timerId)
            timerId = 0 
        end
    end
    timerId = _G.AddGlobalTimer(1, false, callBack)  
    if index == 1 then 
        self._EnchantExpiredTimer1 = timerId
    else
        self._EnchantExpiredTimer2 = timerId
    end
end

-- 描述面板
def.method().InitTips = function(self)
    if self._IsShowCompare then 
        GUI.SetText(self:GetUIObject("Lab_EquipTips2"),self._CompareData._Template.TextDescription)
    end
    GUI.SetText(self:GetUIObject("Lab_EquipTips1"),self._ItemData._Template.TextDescription)
end

def.method().InitBottom = function(self)
    if self._IsShowCompare then 
        self._ItemCoolDownTimer2,self._ItemExpiredTime2 = self:GetTipsValues(self._Frame_Tips2,self._CompareData,2)
    end
    self._ItemCoolDownTimer1,self._ItemExpiredTime1 = self:GetTipsValues(self._Frame_Tips1,self._ItemData,1)  
end

def.method('userdata','table',"number","=>","number","number").GetTipsValues = function (self,parentObj,itemData,index)
    local itemTemp = itemData._Template
    if itemTemp == nil then return 0,0 end
    parentObj:SetActive(true)
    local btnGet = self:GetUIObject("Btn_GetType"..index)
    btnGet:SetActive(true)
    if itemData._Template.ApproachID == "" then 
        btnGet:SetActive(false)
    end
    local labDecompose = self:GetUIObject("Lab_DecomposeTips"..index)
    local frameSell = self:GetUIObject("Frame_Sell"..index)
    frameSell:SetActive(false)
    if itemData:CanSell() then 
        frameSell:SetActive(true)
        GUI.SetText(self:GetUIObject("Lab_Money"..index),tostring(itemTemp.RecyclePriceInGold))
    end

    labDecompose:SetActive(true)
    if not itemData:CanDecompose() then 
        labDecompose:SetActive(false)
    end
    -- 交易
    local frameTransaction = self:GetUIObject("Frame_Transaction"..index)
    frameTransaction:SetActive(true)
    local lab_CoolTime = frameTransaction:FindChild("Lab_CoolTime")
    local ImgTransaction = frameTransaction:FindChild("Img_Transaction")
    local timerId1, timerId2 = 0,0
    --虚拟物品直接隐藏交易情况
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
                            ImgTransaction:SetActive(false)
                            GUI.SetText(lab_CoolTime,StringTable.Get(10684))
                            _G.RemoveGlobalTimer(timerId1)
                            timerId1 = 0
                        end
                    end
                    timerId1 =  _G.AddGlobalTimer(1, false, callBack1) 
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
    if itemData._ExpireData <= 0 then 
        labExpiredTime:SetActive(false)
    else
        local callBack2 = function()
            local time = itemData._ExpireData - GameUtil.GetServerTime()/1000
            if time > 0 then
                self:ShowTime(time,true,labExpiredTime)
            else
                labExpiredTime:SetActive(false)
                _G.RemoveGlobalTimer(timerId2)
                timerId2 = 0
            end
        end
        timerId2 = _G.AddGlobalTimer(1, false, callBack2) 
    end
    return timerId1,timerId2
end

def.method().InitCompareTip = function (self)
    local itemSet = game._HostPlayer._Package._EquipPack._ItemSet
    if not itemSet then return end

    for i,v in ipairs( itemSet ) do
        --print("v._Tid ====",v._Tid)
        local item = CElementData.GetItemTemplate(v._Tid)
        if item ~= nil and item.Slot == self._ItemData._Template.Slot then
            self._FrameContent2:SetActive(true)
            self._CellSlot = item.Slot
            local pack = game._HostPlayer._Package._EquipPack
            local itemData = pack:GetItemBySlot(item.Slot)         
            self._CompareData = itemData
            self._IsShowCompare = true
        end
    end
end

def.method("table").S2CLockItem = function (self,msg)
    if not self:IsShow() or self._LockItemData == nil then return end
    local labLockYes = self._CurSelectRdo:FindChild("Lab_Yes")
    local labLockNo = self._CurSelectRdo:FindChild("Lab_No")
    if msg.OptType == EItemOptLockType.EItemOptLockType_Unlock then 
        labLockYes:SetActive(false)
        labLockNo:SetActive(true)
        self._CurSelectRdo:GetComponent(ClassType.GNewIOSToggle).Value = false
    elseif msg.OptType == EItemOptLockType.EItemOptLockType_Lock then 
        labLockYes:SetActive(true)
        labLockNo:SetActive(false)
        self._CurSelectRdo:GetComponent(ClassType.GNewIOSToggle).Value = true
    end
end

def.method().Hide = function(self)
    if self._ItemCoolDownTimer1 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer1)
        self._ItemCoolDownTimer1 = 0 
    end
    if self._ItemCoolDownTimer2 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer2)
        self._ItemCoolDownTimer2 = 0 
    end
    if self._ItemExpiredTime1 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemExpiredTime1)
        self._ItemExpiredTime1 = 0 
    end
    if self._ItemExpiredTime2 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemExpiredTime2)
        self._ItemExpiredTime2 = 0 
    end
    if self._EnchantExpiredTimer1 ~= 0 then 
        _G.RemoveGlobalTimer(self._EnchantExpiredTimer1)
        self._EnchantExpiredTimer1 = 0 
    end 
    if self._EnchantExpiredTimer2 ~= 0 then 
        _G.RemoveGlobalTimer(self._EnchantExpiredTimer2)
        self._EnchantExpiredTimer2 = 0 
    end 
    self._BaseProTextDisplayName1 = ""
    game._GUIMan:CloseByScript(self)
end

def.override().OnDestroy = function(self)
      if self._ItemCoolDownTimer1 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer1)
        self._ItemCoolDownTimer1 = 0 
    end
    if self._ItemCoolDownTimer2 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemCoolDownTimer2)
        self._ItemCoolDownTimer2 = 0 
    end
    if self._ItemExpiredTime1 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemExpiredTime1)
        self._ItemExpiredTime1 = 0 
    end
    if self._ItemExpiredTime2 ~= 0 then
        _G.RemoveGlobalTimer(self._ItemExpiredTime2)
        self._ItemExpiredTime2 = 0 
    end
    if self._EnchantExpiredTimer1 ~= 0 then 
        _G.RemoveGlobalTimer(self._EnchantExpiredTimer1)
        self._EnchantExpiredTimer1 = 0 
    end 
    if self._EnchantExpiredTimer2 ~= 0 then 
        _G.RemoveGlobalTimer(self._EnchantExpiredTimer2)
        self._EnchantExpiredTimer2 = 0 
    end 
    game._GUIMan:Close("CPanelItemApproach")
    instance = nil 

    -- self._Lay_Button = nil
    -- self._FrameContent1 = nil
    -- self._FrameContent2 = nil
    -- self._Scroll1 = nil
    -- self._Scroll2 = nil
    -- self._Mask1 = nil
    -- self._Mask2 = nil
    -- self._Frame_Attribute1 = nil
    -- self._Frame_Attribute2 = nil
    -- self._Frame_Other1 = nil
    -- self._Frame_Other2 = nil
    -- self._Frame_Tips1 = nil
    -- self._Frame_Tips2 = nil
    -- self._Frame_BaseAttribute1 = nil
    -- self._Frame_BaseAttribute2 = nil
    -- self._Frame_EnchantAttri1 = nil
    -- self._Frame_EnchantAttri2 = nil
    -- self._Frame_RefineAttri1 = nil
    -- self._Frame_RefineAttri2 = nil
    -- self._Frame_Basic2 = nil
    -- self._Frame_Basic1 = nil
    -- self._RdoLock1 = nil
    -- self._RdoLock2 = nil
    -- self._ImgArrow = nil
    -- self._CurSelectRdo = nil
end

CPanelEquipHint.Commit()
return CPanelEquipHint