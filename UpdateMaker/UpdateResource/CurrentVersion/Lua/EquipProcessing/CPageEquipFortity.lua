local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local EItemType = require "PB.Template".Item.EItemType
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local BAGTYPE = require "PB.net".BAGTYPE
local CConsumeUtil = require "Utility.CConsumeUtil"
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CCommonBtn = require "GUI.CCommonBtn"

local CPageEquipFority = Lplus.Class("CPageEquipFority")
local def = CPageEquipFority.define

local gfxGroupName = "CPageEquipFority"

--存储UI的集合，便于OnHide()时置空
def.field("table")._PanelObject = BlankTable
def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("function")._OnMoneyChanged = nil
def.field("table")._MaterialSelectList = BlankTable
def.field("table")._ItemData = nil
def.field("table")._GfxObjectGroup = BlankTable
def.field("boolean")._GfxBgIsShow = false

local function PlayAddItemAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipAddItem, 0)
end

def.static("table", "userdata", "=>", CPageEquipFority).new = function(parent, panel)
    local obj = CPageEquipFority()
    obj._Parent = parent
    obj._Panel = panel
    obj:Init()
    return obj
end

def.method().Init = function(self)
    --warn("CPageEquipFority::Init()")
    self._PanelObject = 
    {
        FortifyInfo = {},
        AttributeInfo = {},
        PVPAttributeInfo = {},
        Item_FortifyMaterialGroup = {},
        Btn_Drop_FortifyMaterialGroup = {},
        Btn_AddFortifyMaterialGroup = {},
        SuccessRateInfo = {},
        HideGroup = {}
    }

    local root = self._PanelObject
    root.SelectItem = self._Parent:GetUIObject('SelectFortifyItem')
    root.Btn_Drop_Fortify = self._Parent:GetUIObject("Btn_Drop_Fortify")
    root.Btn_AddFortifyItem = self._Parent:GetUIObject("Btn_AddFortifyItem")
    root.Btn_Fortify = self._Parent:GetUIObject('Btn_Fortify')
    root.Btn_AutoSelectMateral = self._Parent:GetUIObject("Btn_AutoSelectMateral")
    root.Img_FortifySale = self._Parent:GetUIObject("Img_FortifySale")
    root.Lab_FortifySaleCutOff = self._Parent:GetUIObject("Lab_FortifySaleCutOff")
    root.Img_FortifyMaxBG = self._Parent:GetUIObject("Img_FortifyMaxBG")
    root.Img_FortifyBG = self._Parent:GetUIObject("Img_FortifyBG")
    root.Img_AttributeBG = self._Parent:GetUIObject("Img_AttributeBG")
    root.Group_Fortify = self._Parent:GetUIObject("Group_Fortify")
    root.Lab_None_Selection = self._Parent:GetUIObject("Lab_None_Selection")
    root.Lab_Reason = self._Parent:GetUIObject('Lab_Reason')
    root.Lab_ShowTips = self._Parent:GetUIObject("Lab_ShowTips")
    root.Lab_Fortify_Desc = self._Parent:GetUIObject('Lab_Fortify_Desc')
    -- root.MoneyNeed = self._Parent:GetUIObject('Lab_FortifyNeed')

    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31357),
        [EnumDef.CommonBtnParam.MoneyID] = 1,
        [EnumDef.CommonBtnParam.MoneyCost] = 0   
    }
    root.CommonBtn_Fortify = CCommonBtn.new(root.Btn_Fortify ,setting)

    do
        -- 强化材料 Item集合
        local Item_FortifyMaterialGroup = root.Item_FortifyMaterialGroup
        table.insert(Item_FortifyMaterialGroup, self._Parent:GetUIObject('Item_FortifyMaterial1'))
        table.insert(Item_FortifyMaterialGroup, self._Parent:GetUIObject('Item_FortifyMaterial2'))
        table.insert(Item_FortifyMaterialGroup, self._Parent:GetUIObject('Item_FortifyMaterial3'))
    end
    
    do
        -- 强化材料 放弃结合
        local Btn_Drop_FortifyMaterialGroup = root.Btn_Drop_FortifyMaterialGroup
        table.insert(Btn_Drop_FortifyMaterialGroup, self._Parent:GetUIObject('Btn_Drop_FortifyMaterial1'))
        table.insert(Btn_Drop_FortifyMaterialGroup, self._Parent:GetUIObject('Btn_Drop_FortifyMaterial2'))
        table.insert(Btn_Drop_FortifyMaterialGroup, self._Parent:GetUIObject('Btn_Drop_FortifyMaterial3'))
    end

    do
        -- 强化材料 增加集合
        local Btn_AddFortifyMaterialGroup = root.Btn_AddFortifyMaterialGroup
        table.insert(Btn_AddFortifyMaterialGroup, self._Parent:GetUIObject('Btn_AddFortifyMaterial1'))
        table.insert(Btn_AddFortifyMaterialGroup, self._Parent:GetUIObject('Btn_AddFortifyMaterial2'))
        table.insert(Btn_AddFortifyMaterialGroup, self._Parent:GetUIObject('Btn_AddFortifyMaterial3'))
    end

    --强化信息
    do
        local FortifyInfo = root.FortifyInfo
        FortifyInfo.Root = self._Parent:GetUIObject("Img_FortifyBG")
        FortifyInfo.NewVal = self._Parent:GetUIObject('Lab_FortifyNew')
        FortifyInfo.OldVal = self._Parent:GetUIObject('Lab_FortifyOld')
    end
    --属性信息
    do
        local AttributeInfo = root.AttributeInfo
        AttributeInfo.Root = self._Parent:GetUIObject('Img_AttributeBG')
        AttributeInfo.Name = self._Parent:GetUIObject('Lab_AttributeName')
        AttributeInfo.NewVal = self._Parent:GetUIObject('Lab_PropertyNew')
        AttributeInfo.OldVal = self._Parent:GetUIObject('Lab_PropertyOld')
    end
    --PVP属性信息
    do
        local PVPAttributeInfo = root.PVPAttributeInfo
        PVPAttributeInfo.Root = self._Parent:GetUIObject('Img_PVP_AttributeBG')
        PVPAttributeInfo.Name = self._Parent:GetUIObject('Lab_PVP_AttributeName')
        PVPAttributeInfo.NewVal = self._Parent:GetUIObject('Lab_PVP_PropertyNew')
        PVPAttributeInfo.OldVal = self._Parent:GetUIObject('Lab_PVP_PropertyOld')
    end
    -- 成功概率信息
    do
        local SuccessRateInfo = root.SuccessRateInfo
        SuccessRateInfo.Root = self._Parent:GetUIObject('Success_Rate_Fortify')
        SuccessRateInfo.Lab_Success_Rate = self._Parent:GetUIObject('Lab_Success_Rate_Fortify')
    end
    -- 显示特效隐藏的组件
    do
        local HideGroup = root.HideGroup
        HideGroup.Root = self._Parent:GetUIObject("Node_Fortify")
        HideGroup.BorderBG = self._Parent:GetUIObject("Img_FortifyBorderBG")
        HideGroup.Img_IconGroup = HideGroup.Root:FindChild("Img_IconGroup")
    end


    -- 暂时先注掉，UE不修改，待需求确认
    root.Img_FortifyMaxBG:SetActive( false )
    -- 初始化特效所需组件信息
    self:InitGfxGroup()
end

----------------------装备强化-----------------------

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Parent._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = 1
    root.DoTweenTimeDelay = 1.5 + 0.5
    root.Delay1 = 0.6
    root.Delay2 = 2.3

    root.TweenObjectHook = self._Parent:GetUIObject("SelectFortifyItem")
    root.Frame_Remove = root.TweenObjectHook:FindChild("Frame_Remove")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.BlurTex = self._Parent:GetUIObject("BlurTex")
    root.GfxHook = self._Panel
    root.GfxTimeDelay = 1
    root.Gfx = PATH.ETC_Fortify_lvjing
    root.TimerId = 0
    root.TimerId1 = 0
    root.TimerId1 = 0

    root.BgGfx = PATH.UI_Fortify_BG
    root.BgGfxHook = self._Parent._Panel
    -- root.BgGfxHook = self._Parent:GetUIObject("Fx_Pos_Fortify")
end

-- 播放特效
def.method().PlayGfx = function(self)
    if not self._Parent._ShowGfx then 
        self:ResetGfxGroup()
        return 
    end

    local root = self._GfxObjectGroup
    -- root.TweenObjectHook:SetActive(false)

    local function callback()
        self:StopGfx()
    end
    
    local function callback1()
        GameUtil.ShakeUIScreen(10, 10, 0.01, 0.01, 0.05)
        if root.TimerId1 > 0 then
            _G.RemoveGlobalTimer(root.TimerId1)
        end
    end
    
    local function callback2()
        GameUtil.ShakeUIScreen(15, 10, 0.01, 0.01, 0.05)
        if root.TimerId2 > 0 then
            _G.RemoveGlobalTimer(root.TimerId2)
        end
    end

    local function callback3()
        if self._PanelObject == nil or self._PanelObject.HideGroup == nil then
            return
        end
        local HideGroup = self._PanelObject.HideGroup
        HideGroup.BorderBG:SetActive(false)
        HideGroup.Img_IconGroup:SetActive(false)
        root.BlurTex:SetActive( true ) 
        root.DoTweenPlayer:Restart(2002)
        
        if root.TimerId3 > 0 then
            _G.RemoveGlobalTimer(root.TimerId3)
        end
    end

    -- _G.AddGlobalTimer(0.05, true, function()
        -- root.TweenObjectHook:SetActive(true)
    IconTools.SetTags(self._PanelObject.SelectItem, { [EItemIconTag.StrengthLv] = 0 })
    root.Frame_Remove:SetActive( false )
    root.DoTweenPlayer:Restart(root.TweenGroupId)
    GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1)

    --强化按钮可点击状态
    self._PanelObject.CommonBtn_Fortify:SetInteractable(false)
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_AutoSelectMateral, false)
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_Drop_Fortify, false)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectItem, false)
    
    root.TimerId = _G.AddGlobalTimer(root.DoTweenTimeDelay, true, callback)
    root.TimerId1 = _G.AddGlobalTimer(root.Delay1, true, callback1)
    root.TimerId3 = _G.AddGlobalTimer(0.5, true, callback3)
    -- end)
end
-- 关闭特效
def.method().StopGfx = function(self)
    local root = self._GfxObjectGroup
    if root.TimerId > 0 then
        _G.RemoveGlobalTimer(root.TimerId)
    end

    GameUtil.StopUISfx(root.Gfx, root.GfxHook)
    self:ResetGfxGroup()
end
-- 重置 组件和位置信息
def.method().ResetGfxGroup = function(self)
    local root = self._GfxObjectGroup

    root.TweenObjectHook.localPosition = root.OrignPosition
    root.TweenObjectHook.localScale = root.OrignScale
    root.Frame_Remove:SetActive( true )
    root.BlurTex:SetActive( false )

    --强化按钮可点击状态
    self._PanelObject.CommonBtn_Fortify:SetInteractable(true)
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_AutoSelectMateral, true)
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_Drop_Fortify, true)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectItem, true)

    local HideGroup = self._PanelObject.HideGroup
    HideGroup.BorderBG:SetActive(true)
    HideGroup.Img_IconGroup:SetActive(true)

    if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
        IconTools.SetTags(self._PanelObject.SelectItem, { [EItemIconTag.StrengthLv] = self._ItemData.ItemData:GetInforceLevel() })
    end
end

def.method().EnableBgGfx = function(self)
    if self._GfxBgIsShow then return end
    local root = self._GfxObjectGroup

    GameUtil.PlayUISfx(root.BgGfx, root.BgGfxHook, root.BgGfxHook, -1)
    self._GfxBgIsShow = true
end

def.method().DisableBgGfx = function(self)
    local root = self._GfxObjectGroup
    GameUtil.StopUISfx(root.BgGfx, root.BgGfxHook)

    self._GfxBgIsShow = false
end

def.method("dynamic").Show = function(self, data)
    self._Panel:SetActive(true)
    self._ItemData = nil

    if data then
        self._ItemData = data
        --warn("CPageEquipFority::Show", data.ItemData:GetNameText())
    else
        self:ClearSelectMaterialList()
    end

    local root = self._PanelObject
    GUI.SetText(root.Lab_None_Selection, StringTable.Get(10970))
    
    --更新是否显示分界面
    self:UpdateFrame()

    if self._OnMoneyChanged == nil then
        local function OnMoneyChanged()
            self:UpdateFrame()
        end
        self._OnMoneyChanged = OnMoneyChanged
    end
    CGame.EventManager:addHandler('NotifyMoneyChangeEvent', self._OnMoneyChanged)
    
    -- 播放特效
    self:EnableBgGfx()
end

def.method().UIProcessingLogic = function(self)
    self:DisableEvent()

    local root = self._PanelObject
    local delay = self._Parent._ShowGfx and self._GfxObjectGroup.DoTweenTimeDelay or 0.5
    root.Group_Fortify:SetActive( false )
    self._Parent:AddEvt_SetActive(gfxGroupName, delay, root.Group_Fortify, true)

end

def.method().DisableEvent = function(self)
    self._Parent:KillEvts(gfxGroupName)
end

def.method().DisablePropertyItem = function(self)
    local info = self._PanelObject.Group_Recast.Items

    for i=1, #info do
        info[i]:SetActive(false)
    end
end

-- 更新是否显示附魔界面
def.method().UpdateFrame = function(self)
    local root = self._PanelObject
    root.Lab_Reason:SetActive( false )
    root.Lab_ShowTips:SetActive( true )
    
    -- 更新选中信息
    self:UpdateSelectItem()
    -- 更新材料信息
    self:UpdateMaterialInfo()
    -- 更新属性信息 材料有可能提升数值，最后计算
    self:UpdateProperty()
    -- 更新金币消耗，按钮状态
    self:UpdateButtonState()
end

-- 更新选中信息
def.method().UpdateSelectItem = function(self)
    local root = self._PanelObject
    local bShow = self._ItemData ~= nil
    local bCanFortity = (bShow and self._ItemData.ItemData:CanFortity())
    local bShowReason = (bShow and not bCanFortity)

    root.Lab_Reason:SetActive( bShowReason )
    if bShowReason then
        GUI.SetText(root.Lab_Reason, StringTable.Get(31318))
    end

    root.Btn_Drop_Fortify:SetActive( bShow )
    root.Btn_AddFortifyItem:SetActive( not bShow )
    root.Lab_None_Selection:SetActive( not bShow )
    if bShow then
        local setting = {
            [EItemIconTag.Bind] = self._ItemData.ItemData:IsBind(),
            [EItemIconTag.StrengthLv] = self._ItemData.ItemData:GetInforceLevel(),
            [EItemIconTag.Equip] = (self._ItemData.PackageType == BAGTYPE.ROLE_EQUIP),
            [EItemIconTag.Grade] = self._ItemData.ItemData:GetGrade(),
        }
        IconTools.InitItemIconNew(root.SelectItem, self._ItemData.ItemData._Tid, setting)
    end

    local setting = {
        [EFrameIconTag.ItemIcon] = bShow,
        [EFrameIconTag.Add] = not bShow,
        [EFrameIconTag.Remove] = bShow,
    }
    IconTools.SetFrameIconTags(root.SelectItem, setting)
end
-- 更新属性信息
def.method().UpdateProperty = function(self)
    local root = self._PanelObject
    local bShow = self._ItemData ~= nil
    local bCanFortity = (bShow and self._ItemData.ItemData:CanFortity())
    local bHasSaveStore = self:HasSaveStore()
    local bHasPvp = bShow and self._ItemData.ItemData:HasPVPProperty()

    root.Group_Fortify:SetActive( bCanFortity )
    root.Lab_Fortify_Desc:SetActive( bShow and bCanFortity)
    root.PVPAttributeInfo.Root:SetActive( bHasPvp )

    if bCanFortity then
        local itemData = self._ItemData.ItemData
        local lv = itemData._InforceLevel
        local fightElement = CElementData.GetAttachedPropertyTemplate(itemData._BaseAttrs.ID)
        GUI.SetText(root.AttributeInfo.Name, fightElement.TextDisplayName)

        if bHasPvp then
            local pvpData = CElementData.GetAttachedPropertyTemplate(itemData._PVPFightProperty.ID)
            GUI.SetText(root.PVPAttributeInfo.Name, pvpData.TextDisplayName)
        end

        local EquipInforceData = CElementData.GetEquipInforceInfoMap(itemData._ReinforceConfigId)
        local safeLv = EquipInforceData.SafeLevel
        local bSafe = safeLv >= lv

        --是否为最大强化等级
        local bIsMaxLevel = itemData:IsMaxReinforceLevel()
        --root.Img_FortifyMaxBG:SetActive( bIsMaxLevel )
        root.SuccessRateInfo.Root:SetActive( not bIsMaxLevel )

        local ReinforceInfo = self:CalcReinforceInfo()

        root.CommonBtn_Fortify:MakeGray(bIsMaxLevel)
        -- root.Lab_Fortify_Desc:SetActive( not bIsMaxLevel and not bHasSaveStore )
        root.Lab_Fortify_Desc:SetActive(not bIsMaxLevel)

        if bIsMaxLevel then
            GUI.SetText(root.FortifyInfo.NewVal, StringTable.Get(10908))
            GUI.SetText(root.AttributeInfo.NewVal, StringTable.Get(10908))
            if bHasPvp then
                GUI.SetText(root.PVPAttributeInfo.NewVal, StringTable.Get(10908))
            end

            local setting = {
                [EnumDef.CommonBtnParam.MoneyCost] = 0   
            }
            root.CommonBtn_Fortify:ResetSetting(setting)
        else
            local nextLv = ReinforceInfo.Next
            local nextVal = GUITools.FormatNumber(ReinforceInfo.NextValue)
            local nextPVPVal = GUITools.FormatNumber(ReinforceInfo.NextPVPValue)

            local nextMaxLv = ReinforceInfo.NextMaxLv
            local nextMaxVal = GUITools.FormatNumber(ReinforceInfo.NextMaxValue)
            local nextPVPMaxVal = GUITools.FormatNumber(ReinforceInfo.NextPVPMaxValue)

            local strNextLv = ""
            local strNextVal = ""
            local strNextPVPVal = ""

            if nextMaxLv > nextLv then
                strNextLv = string.format("%s ~ %s", nextLv, nextMaxLv)
                strNextVal = string.format("%s ~ %s", nextVal, nextMaxVal)
                strNextPVPVal = string.format("%s ~ %s", nextPVPVal, nextPVPMaxVal)
            else
                strNextLv = tostring(nextLv)
                strNextVal = tostring(nextVal)
                strNextPVPVal = tostring(nextPVPVal)
            end
            GUI.SetText(root.FortifyInfo.NewVal, strNextLv)
            GUI.SetText(root.AttributeInfo.NewVal, strNextVal)
            if bHasPvp then
                GUI.SetText(root.PVPAttributeInfo.NewVal, strNextPVPVal)
            end
            -- 成功率
            local rate = self:CalcSuccessRate()
            -- root.Lab_Fortify_Desc:SetActive( not bSafe and rate < 100 and not bHasSaveStore )
            GUI.SetText(root.Lab_Fortify_Desc, self:GetFortifyDesc(bSafe or rate >= 100 or bHasSaveStore))
            local strSuccessRate = string.format("%s%%", rate)

            GUI.SetText(root.SuccessRateInfo.Lab_Success_Rate, strSuccessRate)
        end
        GUI.SetText(root.AttributeInfo.OldVal, GUITools.FormatNumber(ReinforceInfo.Value))
        GUI.SetText(root.FortifyInfo.OldVal, tostring(lv))

        if bHasPvp then
            GUI.SetText(root.PVPAttributeInfo.OldVal, GUITools.FormatNumber(ReinforceInfo.PVPValue))
        end
    end
end

def.method("boolean", "=>", "string").GetFortifyDesc = function(self, bSafe)
    local str = ""

    if bSafe then
        str = StringTable.Get(31343)
    else
        str = StringTable.Get(31342)
    end

    return str
end

-- 更新材料信息
def.method().UpdateMaterialInfo = function(self)
    local root = self._PanelObject

    local function SetMaterialInfo(item, itemData)
        local bShow = (itemData ~= nil and itemData.ItemData ~= nil and itemData.ItemData.ItemData ~= nil)
        local bCanFortity = (bShow and self._ItemData.ItemData:CanFortity())
        if bCanFortity then
            local materialItemData = itemData.ItemData.ItemData
            -- Item 需要刷新个数
            local setting = {
                [EItemIconTag.Bind] = materialItemData:IsBind(),
            }
            IconTools.InitItemIconNew(item, materialItemData._Tid, setting)        
        end
        
        local setting = {
            [EFrameIconTag.ItemIcon] = bCanFortity,
            [EFrameIconTag.Add] = not bCanFortity,
            [EFrameIconTag.Remove] = bCanFortity,
        }
        IconTools.SetFrameIconTags(item, setting)
    end

    local bShow = self._ItemData ~= nil
    local bCanFortity = (bShow and self._ItemData.ItemData:CanFortity())

    for i=1, #self._MaterialSelectList do
        local materialInfo = self._MaterialSelectList[i]
        self._Parent:GetUIObject("FortifyMaterialIcon"..i):SetActive( bCanFortity )

        if bCanFortity then
            root.Btn_Drop_FortifyMaterialGroup[i]:SetActive(materialInfo.ItemData ~= nil)
            root.Btn_AddFortifyMaterialGroup[i]:SetActive(materialInfo.ItemData == nil)

            -- 设置材料信息
            SetMaterialInfo(root.Item_FortifyMaterialGroup[i], materialInfo)
        end
    end
end
--更新 按钮状态, 消耗金币价格
def.method().UpdateButtonState = function(self)
    local root = self._PanelObject
    local hp = game._HostPlayer
    local moneyNeedInfo = self:CalcMoneyNeed()

    local hasSale = (moneyNeedInfo ~= nil and moneyNeedInfo[3] ~= 1)
    root.Img_FortifySale:SetActive( hasSale )

    if moneyNeedInfo == nil then
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = 0   
        }
        root.CommonBtn_Fortify:ResetSetting(setting)
    else
        local moneyHave = hp:GetMoneyCountByType(moneyNeedInfo[1])
        local moneyNeed = moneyNeedInfo[2]
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = moneyNeed   
        }
        root.CommonBtn_Fortify:ResetSetting(setting)
        if hasSale then
            local strCutOff = tostring(math.ceil(moneyNeedInfo[3] * 100))
            GUI.SetText(root.Lab_FortifySaleCutOff, strCutOff)
        end
    end
    root.CommonBtn_Fortify:MakeGray(not self:HasReinforceStore())
    GUITools.SetBtnGray(self._PanelObject.Btn_AutoSelectMateral, self._ItemData == nil)
end

def.method("=>", "number").CalcSuccessRate = function(self)
    local iRet = 0

    if self._ItemData ~= nil then
        local InforceValue = 0
        local itemData = self._ItemData.ItemData

        for i=1, #self._MaterialSelectList do
            local materialInfo = self._MaterialSelectList[i]
            if materialInfo.ItemData ~= nil and
               materialInfo.ItemData.ItemData ~= nil and
               materialInfo.ItemData.ItemData:IsInforceStone() then

                local stoneInforceId = materialInfo.ItemData.ItemData._Template.StoneInforceId
                local stoneInforceTemplate = CEquipUtility.GetStoneInforceInfoByLevel(stoneInforceId, itemData:GetInforceLevel()+1)
                if stoneInforceTemplate ~= nil then
                    InforceValue = InforceValue + stoneInforceTemplate.PercentValue
                end
            end
        end

        iRet = InforceValue / 10000
    end

    return math.clamp(iRet*100, 0, 100)
end

def.method("=>", "boolean").HasSaveStore = function(self)
    local bRet = false
    for i=1, #self._MaterialSelectList do
        local materialInfo = self._MaterialSelectList[i]
        if materialInfo.ItemData ~= nil and
           materialInfo.ItemData.ItemData ~= nil and
           materialInfo.ItemData.ItemData:IsSafeStone() then
            bRet = true
        end
    end

    return bRet
end

def.method("=>", "boolean").HasReinforceStore = function(self)
    local bRet = false
    for i=1, #self._MaterialSelectList do
        local materialInfo = self._MaterialSelectList[i]
        if materialInfo.ItemData ~= nil and
           materialInfo.ItemData.ItemData ~= nil and
           materialInfo.ItemData.ItemData:IsInforceStone() then
            bRet = true
        end
    end

    return bRet
end

def.method("=>", "table").CalcReinforceInfo = function(self)
    local luckyStone = nil

    for i=1, #self._MaterialSelectList do
        local materialInfo = self._MaterialSelectList[i]
        if materialInfo.ItemData ~= nil and materialInfo.ItemData.ItemData ~= nil then
            if materialInfo.ItemData.ItemData:IsLuckyStone() then
                luckyStone = materialInfo.ItemData.ItemData
            end
        end
    end

    local itemData = self._ItemData.ItemData
    local bHasPvp = itemData:HasPVPProperty()

    local maxLv = itemData:GetMaxInforceLevel()
    local curLv = itemData:GetInforceLevel()
    local addLv = 1
    local addMaxLv = 1

    if luckyStone ~= nil then
        local LuckyInforceTemplate = CElementData.GetTemplate("LuckyInforce", luckyStone._Template.LuckyInforceId)
        if LuckyInforceTemplate ~= nil then
            addLv = 2
            addMaxLv = (LuckyInforceTemplate.LuckIncs[#LuckyInforceTemplate.LuckIncs]).Inc
        end
    end

    local curVal = itemData._BaseAttrs.Value
    local curPVPVal = bHasPvp and itemData._PVPFightProperty.Value or 0

    if curLv > 0 then
        local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(itemData._ReinforceConfigId, curLv)
        local fixedIncVal = math.ceil(curVal * InforceInfoOld.InforeValue / 100)
        curVal = itemData._BaseAttrs.Value + math.max(fixedIncVal, curLv)
        curPVPVal = bHasPvp and itemData._PVPFightProperty.Value + math.max(fixedIncVal, curLv) or 0
    end

    local nextLv = math.clamp(curLv+addLv, curLv, maxLv)
    local InforceInfoNew = CEquipUtility.GetInforceInfoByLevel(itemData._ReinforceConfigId, nextLv)
    local fixedIncVal1 = math.ceil(itemData._BaseAttrs.Value * InforceInfoNew.InforeValue / 100)
    local fixedPVPIncVal1 = bHasPvp and math.ceil(itemData._PVPFightProperty.Value * InforceInfoNew.InforeValue / 100) or 0

    local nextVal = itemData._BaseAttrs.Value + math.max(fixedIncVal1, nextLv)
    local nextPVPVal = bHasPvp and itemData._PVPFightProperty.Value + math.max(fixedPVPIncVal1, nextLv) or 0

    local nextMaxValue = nextVal
    local nextPVPMaxValue = bHasPvp and nextPVPVal or 0

    local nextMaxLv = math.clamp(curLv+addMaxLv, curLv, maxLv)
    if nextMaxLv > nextLv then
        local InforceInfoMaxNew = CEquipUtility.GetInforceInfoByLevel(itemData._ReinforceConfigId, nextMaxLv)
        local fixedIncVal2 = math.ceil(itemData._BaseAttrs.Value * InforceInfoMaxNew.InforeValue / 100)
        local fixedPVPIncVal2 = bHasPvp and math.ceil(itemData._PVPFightProperty.Value * InforceInfoMaxNew.InforeValue / 100) or 0

        nextMaxValue = itemData._BaseAttrs.Value + math.max(fixedIncVal2, nextMaxLv)
        nextPVPMaxValue = bHasPvp and itemData._PVPFightProperty.Value + math.max(fixedIncVal2, nextMaxLv) or 0
    end

    return {    
                Lv = curLv, 
                Max = maxLv, 
                Add = addLv, 
                AddMax = addMaxLv,
                Next = nextLv,
                NextMaxLv = nextMaxLv,
                Value = curVal,
                PVPValue = curPVPVal,
                NextValue = nextVal,
                NextPVPValue = nextPVPVal,
                NextMaxValue = nextMaxValue,
                NextPVPMaxValue = nextPVPMaxValue,
            }
end

def.method("=>", "table").CalcMoneyNeed = function(self)
    if self._ItemData == nil then return nil end

    local cutOffRatio = 1
    local gloryLevelData = game._CWelfareMan:GetCurGloryLevelData()
    if gloryLevelData ~= nil then
        cutOffRatio = gloryLevelData.EquipStrengthenCostDiscount / 10000
    end

    local itemData = self._ItemData.ItemData
    local curLv = itemData:GetInforceLevel()
    local InforceInfo = CEquipUtility.GetInforceInfoByLevel(self._ItemData.ItemData._ReinforceConfigId, curLv+1)
    if InforceInfo == nil then  return nil end

    return {InforceInfo.CostMoneyId, math.ceil(InforceInfo.CostMoneyCount * cutOffRatio), cutOffRatio}
end

def.method().CalcOptimalMaterialSolution = function(self)
-- warn("计算最优概率组合...")
    -- 第一步 清理还原
    self:RestoneMaterialList()

    local inforceStoneList = {}
    local hp = game._HostPlayer
    local hpPack = hp._Package._NormalPack
    local normalPackList = hpPack._ItemSet
    local normalPackCnt = #normalPackList
    local itemData = self._ItemData.ItemData

    if normalPackCnt > 0 then
        for i=1, normalPackCnt do
            local item = normalPackList[i]
            -- warn("材料等级 = ", item._Level, "装备等级 = ", self._ItemData.ItemData._Level)
            if item:IsInforceStone() and item._InforceStoneLevel >= self._ItemData.ItemData._Level then
                local stoneInforceId = item._Template.StoneInforceId
                local stoneInforceTemplate = CEquipUtility.GetStoneInforceInfoByLevel(stoneInforceId, itemData:GetInforceLevel()+1)
                if stoneInforceTemplate ~= nil then
                    local incVal = stoneInforceTemplate.PercentValue / 10000
                    local maxCount = math.clamp(item:GetCount(), 1, 3)
                    for j = 1,maxCount do
                        inforceStoneList[#inforceStoneList+1] = {item._Tid, incVal, item._InforceStoneLevel, item._Quality}
                    end
                end
            end
        end
    end

    if next(inforceStoneList) == nil then
        game._GUIMan:ShowTipText(StringTable.Get(31322), false)
        return
    end

    -- 最多三个格子，同一元素最多三个，放入一维数组
    local allResultList = {}
    -- 一块石头
    for i = 1, #inforceStoneList do
        local result = { inforceStoneList[i] }
        table.insert(allResultList, result)
    end
    -- 两块石头
    for i = 1, #inforceStoneList-1 do
        for j = i+1, #inforceStoneList do
            local result = {inforceStoneList[i], inforceStoneList[j]}
            table.insert(allResultList, result)
        end
    end
    -- 3块石头
    for i = 1, #inforceStoneList-2 do
        for j = i+1, #inforceStoneList-1 do
            for k = j+1, #inforceStoneList do
                local result = {inforceStoneList[i], inforceStoneList[j], inforceStoneList[k]}
                table.insert(allResultList, result)
            end
        end
    end

    local function IsBetter(l, r)
        local leftPercent, rightPercent = 0, 0
        for i,v in ipairs(l) do
            leftPercent = leftPercent + v[2]
        end
        for i,v in ipairs(r) do
            rightPercent = rightPercent + v[2]
        end

        if leftPercent >= 1 and rightPercent >= 1 then
            local leftQuality, rightQuality = 0, 0
            for i,v in ipairs(l) do
                leftQuality = leftQuality + v[4]
            end
            for i,v in ipairs(r) do
                rightQuality = rightQuality + v[4]
            end

            if leftQuality / #l ~= rightQuality / #r then
                return leftQuality / #l < rightQuality / #r
            else
                return leftQuality < rightQuality
            end
        elseif leftPercent >= 1 then
            return true
        elseif rightPercent >= 1 then
            return false
        else
            return leftPercent > rightPercent
        end
    end

    local result = allResultList[1]
    for i,v in ipairs(allResultList) do
        if IsBetter(v, result) then
            result = v
        end
    end

    for i, data in ipairs(result) do
        local item = self._Parent:GetInforceStoneItemDataByTid(data[1])
        if item then
            item.ItemData._NormalCount = item.ItemData._NormalCount - 1
            self._MaterialSelectList[i].ItemData = item
        end
    end

    self:UpdateFrame()
    self._Parent:UpdateItemList()
end

def.method("table", "boolean", "=>", "boolean").CheckCanSelectMaterial = function(self, itemData, bShowReason)
    local bRet = true

    local function ShowReason(msg)
        if bShowReason then
            game._GUIMan:ShowTipText(msg, false)
        end
    end

    if self._ItemData.ItemData:IsMaxReinforceLevel() then
        -- Max Level
        ShowReason(StringTable.Get(10903))
        return false
    else
        local materialItemData = itemData.ItemData
        
        -- 强化材料判断
        if not (materialItemData:IsInforceStone() or
                materialItemData:IsLuckyStone() or
                materialItemData:IsSafeStone()) then

            ShowReason(StringTable.Get(31307))

           return false
        end

        -- 材料位满了
        local cnt = 0
        for i=1,#self._MaterialSelectList do
            if self._MaterialSelectList[i].ItemData ~= nil then
                cnt = cnt + 1
            end
        end
        if cnt >= #self._MaterialSelectList then
            ShowReason(StringTable.Get(31302))
            return false
        end

        if not materialItemData:IsLuckyStone() then
            -- 强化成功率100%
            local rate = self:CalcSuccessRate()
            if rate >= 100 then
                ShowReason(StringTable.Get(31341))
                return false
            end
        end

        -- 数量不足
        if materialItemData:GetCount() == 0 then
            ShowReason(StringTable.Get(31306))
            return false
        end

        -- 强化石
        if materialItemData:IsInforceStone() then
            -- 等级不得大于当前装备等级
            -- 2018.12.21 强化石去除等级，不同品质可以合成
            if materialItemData._InforceStoneLevel < self._ItemData.ItemData._Level then
                ShowReason(StringTable.Get(31303))
                return false
            end
        end

        -- 幸运符
        if materialItemData:IsLuckyStone() then
            -- 只能有一个幸运符
            for i=1,#self._MaterialSelectList do
                if self._MaterialSelectList[i] ~= nil and
                   self._MaterialSelectList[i].ItemData ~= nil and
                   self._MaterialSelectList[i].ItemData.ItemData ~= nil and
                   self._MaterialSelectList[i].ItemData.ItemData:IsLuckyStone() then

                    ShowReason(StringTable.Get(31304))
                    return false
                end
            end
        end
        -- 保底石
        if materialItemData:IsSafeStone() then
            if materialItemData._Template.SafeStoneLevel < self._ItemData.ItemData:GetInforceLevel() then
                ShowReason(StringTable.Get(31345))
                return false
            end

            -- 只能有一个保底石
            for i=1,#self._MaterialSelectList do
                if self._MaterialSelectList[i] ~= nil and
                   self._MaterialSelectList[i].ItemData ~= nil and
                   self._MaterialSelectList[i].ItemData.ItemData ~= nil and
                   self._MaterialSelectList[i].ItemData.ItemData:IsSafeStone() then

                    ShowReason(StringTable.Get(31305))
                    return false
                end
            end
        end
    end

    return bRet
end

def.method("boolean", "=>", "boolean").CheckCanInforce = function(self, bShowReason)
    local bRet = true

    local function ShowReason(msg)
        if bShowReason then
            game._GUIMan:ShowTipText(msg, false)
        end
    end

    -- 请先选择装备
    if self._ItemData == nil then
        ShowReason(StringTable.Get(31301))
        return false
    end

    if self._ItemData.ItemData:IsMaxReinforceLevel() then
        ShowReason(StringTable.Get(31331))
        return false
    end

    -- 至少放入一个强化材料
    local bGotInforceStone = false
    for i=1,#self._MaterialSelectList do
        if self._MaterialSelectList[i] ~= nil and
           self._MaterialSelectList[i].ItemData ~= nil and
           self._MaterialSelectList[i].ItemData.ItemData ~= nil and
           self._MaterialSelectList[i].ItemData.ItemData:IsInforceStone() then
           bGotInforceStone = true
       end
    end
    if bGotInforceStone == false then
        ShowReason(StringTable.Get(31308))
        return false
    end
--[[
    -- 所需货币不足
    local moneyNeedInfo = self:CalcMoneyNeed()
    if moneyNeedInfo == nil then
        return false
    else
        local hp = game._HostPlayer
        local moneyHave = hp:GetMoneyCountByType(moneyNeedInfo[1])
        local moneyNeed = moneyNeedInfo[2]
        if moneyNeed > moneyHave then
            ShowReason(StringTable.Get(260))
            return false
        end
    end
]]
    return bRet
end

-- 获取有效的材料位置
def.method("=>", "number").GetValidMaterialHoleIndex = function(self)
    local iRet = 0
    for i=1, #self._MaterialSelectList do
        if self._MaterialSelectList[i].ItemData == nil then
            iRet = i
            break
        end
    end

    return iRet
end

-- 尝试选择材料, 按规则顺序填入数据
def.method("number", "table").TryToSelectMaterial = function(self, index, itemData)
    local validIndex = self:GetValidMaterialHoleIndex()
    --warn("TryToSelectMaterial :: ",itemData.ItemData:GetNameText())
    if validIndex == 0 then
        game._GUIMan:ShowTipText(StringTable.Get(31302), false)
    elseif self:CheckCanSelectMaterial(itemData, true) then
        local materialItemData = itemData.ItemData
        -- 数量需要 自减
        materialItemData._NormalCount = materialItemData._NormalCount - 1
        self._MaterialSelectList[validIndex].Index = index
        self._MaterialSelectList[validIndex].ItemData = itemData
        PlayAddItemAudio()
    end
end

def.method("table", "=>", "number").GetLocalMaterialCount = function(self, itemData)
    local result = itemData.ItemData:GetCount()
    for i, materialData in ipairs(self._MaterialSelectList) do
        if materialData ~= nil and materialData.ItemData ~= nil and materialData.ItemData.ItemData ~= nil then
            local data = materialData.ItemData.ItemData
            if data._Guid == itemData.ItemData._Guid then
                result = data:GetCount()
                break
            end
        end
    end

    return result
end

def.method("userdata", "number", "table").OnInitItem = function(self, item, index, itemData)
    local idx = index + 1
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    
    local ItemIconNew = item:FindChild("ItemIconNew")
    if itemData.ItemData:IsEquip() then
        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.StrengthLv] = itemData.ItemData:GetInforceLevel(),
            [EItemIconTag.Equip] = (itemData.PackageType == BAGTYPE.ROLE_EQUIP),
            [EItemIconTag.Grade] = itemData.ItemData:GetGrade(),
        }
        IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
        Img_UnableClick:SetActive(false)
        -- Img_UnableClick:SetActive(self._ItemData ~= nil and self._ItemData ~= itemData)
    else
        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.Number] = self:GetLocalMaterialCount(itemData)--.ItemData:GetCount(),
        }
        IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
        local rate = self:CalcSuccessRate()

        if itemData.ItemData:IsSafeStone() then
            local rate = self:CalcSuccessRate()
            Img_UnableClick:SetActive( self._ItemData == nil or
                                       rate >= 100 or
                                       not self._ItemData.ItemData:CanFortity() or
                                       not self:CheckCanSelectMaterial(itemData, false))
        elseif itemData.ItemData:IsInforceStone() then
            local rate = self:CalcSuccessRate()
            Img_UnableClick:SetActive( self._ItemData == nil or
                                       rate >= 100 or
                                       not self._ItemData.ItemData:CanFortity() or
                                       not self:CheckCanSelectMaterial(itemData, false))
        else
            Img_UnableClick:SetActive( self._ItemData == nil or
                                       not self._ItemData.ItemData:CanFortity() or
                                       not self:CheckCanSelectMaterial(itemData, false))
            -- Img_UnableClick:SetActive( self._ItemData == nil or
            --                            not self._ItemData.ItemData:CanFortity() or
            --                            not self:CheckCanSelectMaterial(itemData, false))
        end
        
    end
end

def.method("userdata", "number", "table").OnSelectItem = function(self, item, index, itemData)
    local idx = index + 1

    if itemData.ItemData:IsEquip() then
        self._ItemData = itemData
        PlayAddItemAudio()
    else
        self:TryToSelectMaterial(idx, itemData)
    end
    self:UpdateFrame()
end

def.method("string").OnClick = function(self, id)
    --warn("CPageEquipFority::OnClick => ", id)
    if id == "Btn_Fortify" then
        local CPanelUIEquipFortityResult = require "GUI.CPanelUIEquipFortityResult"
        if CPanelUIEquipFortityResult.Instance():IsShow() then
            return
        end
        
        if self:CheckCanInforce(true) then
            local function Do( ret )
                if ret then
                    CEquipUtility.SendC2SItemInforce(self._ItemData.PackageType, self._ItemData.ItemData._Slot, self._MaterialSelectList)
                    --强化按钮可点击状态
                    self._PanelObject.CommonBtn_Fortify:SetInteractable(false)
                end
            end

            local function DoCommonBuy()
                local moneyNeedInfo = self:CalcMoneyNeed()
                MsgBox.ShowQuickBuyBox(moneyNeedInfo[1], moneyNeedInfo[2], Do)
            end

            local function callback( ret )
                if ret then
                    DoCommonBuy()
                end
            end
            if not self._ItemData.ItemData:IsBind() then
                local title, msg, closeType = StringTable.GetMsg(92)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
            else
                DoCommonBuy()
            end
        end
    elseif id == "Btn_AutoSelectMateral" then
        -- 请先选择装备
        if self._ItemData == nil or self._ItemData.ItemData == nil then
            game._GUIMan:ShowTipText(StringTable.Get(31301), false)
        elseif self._ItemData.ItemData:IsMaxReinforceLevel() then
            game._GUIMan:ShowTipText(StringTable.Get(31331), false)
        else
            self:CalcOptimalMaterialSolution()
        end
    elseif string.find(id, "Btn_Drop_FortifyMaterial") then
        local index = tonumber(string.sub(id,-1))
        self:DropMaterialItem(index)
        self:UpdateFrame()
    elseif id == "SelectFortifyItem" then
        if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
            local root = self._PanelObject
            CItemTipMan.ShowPackbackEquipTip(self._ItemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,root.SelectItem)
        end
    elseif string.find(id, "FortifyMaterialIcon") then
        local index = tonumber(string.sub(id,-1))
        if self._MaterialSelectList[index] ~= nil and
           self._MaterialSelectList[index].ItemData ~= nil and
           self._MaterialSelectList[index].ItemData.ItemData ~= nil then
            local materialItemData = self._MaterialSelectList[index].ItemData.ItemData
            materialItemData:ShowTip(TipPosition.FIX_POSITION, self._Parent:GetUIObject(id))
       end
    elseif id == "Btn_Fortify_Desc" then
        game._GUIMan:Close("CPanelUICommonNotice")
        local data = 
        {
            Title = StringTable.Get(34201),
            Name = StringTable.Get(34200),
            Desc = StringTable.Get(34202),
        }
        game._GUIMan:Open("CPanelUICommonNotice", data)
    end
end

def.method("number").DropMaterialItem = function(self, index)
    if self._MaterialSelectList[index].ItemData ~= nil and self._MaterialSelectList[index].ItemData.ItemData ~= nil then
        local materialItemData = self._MaterialSelectList[index].ItemData.ItemData
        -- 数量需要 自增
        materialItemData._NormalCount = materialItemData._NormalCount + 1
    end
    self._MaterialSelectList[index] = {Index = 0, ItemData = nil}
end

-- 回复没有使用的 材料
def.method().RestoneMaterialList = function(self)
    for i=1, #self._MaterialSelectList do
        local materialInfo = self._MaterialSelectList[i]
        if materialInfo ~= nil and materialInfo.ItemData ~= nil and materialInfo.ItemData.ItemData ~= nil then
            local materialItemData = materialInfo.ItemData.ItemData
            -- 数量需要 自增
            materialItemData._NormalCount = materialItemData._NormalCount + 1
        end
    end
    self:ClearSelectMaterialList()
end

-- 清空材料
def.method().ClearSelectMaterialList = function(self)
    self._MaterialSelectList = 
    {
        [1] = {Index = 0, ItemData = nil},
        [2] = {Index = 0, ItemData = nil},
        [3] = {Index = 0, ItemData = nil},
    }
end

def.method().Reset = function(self)
    self._ItemData = nil
    self:ClearSelectMaterialList()
end

def.method().Hide = function(self)
    self:DisableEvent()
    self:RestoneMaterialList()
    self:DisableBgGfx()
    self:StopGfx()

    if self._OnMoneyChanged ~= nil then
        CGame.EventManager:removeHandler('NotifyMoneyChangeEvent', self._OnMoneyChanged)
        self._OnMoneyChanged = nil
    end
    self._Panel:SetActive(false)
end

def.method().Destroy = function (self)
    self:DisableEvent()

    if self._PanelObject ~= nil then
        if self._PanelObject.CommonBtn_Fortify ~= nil then
            self._PanelObject.CommonBtn_Fortify:Destroy()
        end

        self._PanelObject = nil
    end
end

CPageEquipFority.Commit()
return CPageEquipFority