local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPageEquipInherit = Lplus.Class("CPageEquipInherit")
local def = CPageEquipInherit.define

local EItemType = require "PB.Template".Item.EItemType
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local BAGTYPE = require "PB.net".BAGTYPE

local CConsumeUtil = require "Utility.CConsumeUtil"
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CCommonBtn = require "GUI.CCommonBtn"

--存储UI的集合，便于OnHide()时置空
def.field("table")._PanelObject = BlankTable
def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("function")._OnMoneyChanged = nil
def.field("table")._ItemData = nil
def.field("table")._TargetItemData = nil
def.field("boolean")._GfxBgIsShow = false

local function PlayAddItemAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipAddItem, 0)
end
---------------------------装备传承------------------------------
def.field("table")._GfxObjectGroup = BlankTable

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Parent._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = 102
    root.DoTweenTimeDelay = 1.5 + 0.7
    root.TweenObjectHook = self._Parent:GetUIObject("SelectTargetItem")
    root.Frame_Remove = root.TweenObjectHook:FindChild("Frame_Remove")

    root.OrignPosition = root.TweenObjectHook.localPosition
    root.Frame_Remove_Orign = self._Parent:GetUIObject("SelectOrignItem"):FindChild("Frame_Remove")

    root.OrignScale = root.TweenObjectHook.localScale
    root.BlurTex = self._Parent:GetUIObject("BlurTex")

    root.GfxHook = self._Panel
    root.GfxTimeDelay = 1
    root.Gfx = PATH.ETC_Inherit_lvjing
    root.TimerId = 0

    root.BgGfx = PATH.UI_Inherit_BG
    root.BgGfxHook = self._Parent._Panel
end
-- 播放特效
def.method().PlayGfx = function(self)
    if not self._Parent._ShowGfx then 
        self:ResetGfxGroup()
        return 
    end

    local root = self._GfxObjectGroup
    -- root.TweenObjectHook:SetActive(false)
    root.BlurTex:SetActive( true )
    
    local function callback()
        self:StopGfx()
    end

    local function callback1()
        if self._PanelObject == nil or self._PanelObject.HideGroup == nil then
            return
        end
        
        local HideGroup = self._PanelObject.HideGroup
        HideGroup.Img_Next:SetActive( false ) 
        HideGroup.SelectInheritOrignItemGroup:SetActive( false ) 
        HideGroup.SelectInheritTargetItemGroup:SetActive( false ) 
        root.BlurTex:SetActive( true ) 
        root.DoTweenPlayer:Restart(2002)
        
        if root.TimerId1 > 0 then
            _G.RemoveGlobalTimer(root.TimerId1)
        end
    end

    -- _G.AddGlobalTimer(0.05, true, function()
    root.TweenObjectHook:SetActive(true)
    root.DoTweenPlayer:Restart(root.TweenGroupId)
    GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1)
    root.Frame_Remove:SetActive( false )
    root.Frame_Remove_Orign:SetActive( false )

    local UIRoot = self._PanelObject
    self._PanelObject.CommonBtn_Inherit:SetInteractable(false)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectOrignItem, false)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectTargetItem, false)
    root.TimerId = _G.AddGlobalTimer(root.DoTweenTimeDelay, true, callback)
    root.TimerId1 = _G.AddGlobalTimer(0.8, true, callback1)
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
    root.BlurTex:SetActive( false )
    root.Frame_Remove:SetActive( true )
    root.Frame_Remove_Orign:SetActive( true )
    
    local UIRoot = self._PanelObject
    self._PanelObject.CommonBtn_Inherit:SetInteractable(true)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectOrignItem, true)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectTargetItem, true)

    local HideGroup = self._PanelObject.HideGroup
    HideGroup.Img_Next:SetActive( true ) 
    HideGroup.SelectInheritOrignItemGroup:SetActive( true ) 
    HideGroup.SelectInheritTargetItemGroup:SetActive( true ) 
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
---------------------------装备传承------------------------------

def.static("table", "userdata", "=>", CPageEquipInherit).new = function(parent, panel)
    local obj = CPageEquipInherit()
    obj._Parent = parent
    obj._Panel = panel
    obj:Init()

    return obj
end

def.method().Init = function(self)
    self._PanelObject = 
    {
        Group_Property = {},
        SuccessRateInfo = {},
        AttributeInfo = {},
        HideGroup = {},
    }

    local root = self._PanelObject
    root.SelectOrignItem = self._Parent:GetUIObject('SelectOrignItem')
    root.Btn_Drop_OrignItem = self._Parent:GetUIObject("Btn_Drop_OrignItem")
    root.Btn_AddOrignItem = self._Parent:GetUIObject("Btn_AddOrignItem")

    root.SelectTargetItem = self._Parent:GetUIObject('SelectTargetItem')
    root.Btn_Drop_TargetItem = self._Parent:GetUIObject("Btn_Drop_TargetItem")
    root.Btn_AddTargetItem = self._Parent:GetUIObject("Btn_AddTargetItem")

    root.Btn_Inherit = self._Parent:GetUIObject('Btn_Inherit')
    root.Lab_None_Selection = self._Parent:GetUIObject("Lab_None_Selection")
    root.Lab_Reason = self._Parent:GetUIObject('Lab_Reason')
    root.Lab_ShowTips = self._Parent:GetUIObject("Lab_ShowTips")
    root.Lab_InheritTip = self._Parent:GetUIObject("Lab_InheritTip")

    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31353),
        [EnumDef.CommonBtnParam.MoneyID] = 1,
        [EnumDef.CommonBtnParam.MoneyCost] = 0
    }
    root.CommonBtn_Inherit = CCommonBtn.new(root.Btn_Inherit ,setting)

    do
        local Group_Property = root.Group_Property
        Group_Property.Root = self._Parent:GetUIObject("Group_Property")
        Group_Property.Reinforce = 
        {
            Name = self._Parent:GetUIObject('Lab_InheritedReinforceName'),
            Old = self._Parent:GetUIObject('Lab_InheritedReinforceOldValue'),
            New = self._Parent:GetUIObject('Lab_InheritedReinforceNewValue'),
        }
        Group_Property.Property =
        {
            Name = self._Parent:GetUIObject('Lab_InheritedPropertyName'),
            Old = self._Parent:GetUIObject('Lab_InheritedPropertyOldValue'),
            New = self._Parent:GetUIObject('Lab_InheritedPropertyNewValue'),
        }
        Group_Property.PVP_Property = 
        {
            Root = self._Parent:GetUIObject('Img_InheritOrign_PVP_Property'),
            Name = self._Parent:GetUIObject('Lab_InheritedPVPPropertyName'),
            Old = self._Parent:GetUIObject('Lab_InheritedPVPPropertyOldValue'),
            New = self._Parent:GetUIObject('Lab_InheritedPVPPropertyNewValue'),
        }
    end

    do
        -- 显示特效隐藏的组件
        local HideGroup = root.HideGroup
        HideGroup.Root = self._Parent:GetUIObject("Frame_Inherit")
        HideGroup.Img_IconGroup = HideGroup.Root:FindChild("Img_IconGroup")
        HideGroup.Img_Next = HideGroup.Img_IconGroup:FindChild("Img_Next")
        HideGroup.SelectInheritOrignItemGroup = self._Parent:GetUIObject("SelectInheritOrignItemGroup")
        HideGroup.SelectInheritTargetItemGroup = self._Parent:GetUIObject("SelectInheritTargetItemGroup")
    end

    root.Lab_Reason:SetActive( false )
    self:InitGfxGroup()
end

--------------------------------------------------------------------------------

def.method("dynamic").Show = function(self, data)
    self._Panel:SetActive(true)
    self._ItemData = nil
    -- self._TargetItemData = nil
    if data then
        self._ItemData = data
    end

    --更新是否显示分界面
    self:UpdateFrame()

    -- 播放特效
    self:EnableBgGfx()
end

-- 更新是否显示附魔界面
def.method().UpdateFrame = function(self)
    --warn("CPageEquipInherit::UpdateFrame()")
    local root = self._PanelObject
    root.Lab_ShowTips:SetActive( false )
    
    -- 更新选中信息
    self:UpdateSelectItem()
    -- 更新属性信息 材料有可能提升数值，最后计算
    self:UpdateProperty()
    -- 更新金币消耗，按钮状态
    self:UpdateButtonState()
end

-- 更新选中信息
def.method().UpdateSelectItem = function(self)
    local root = self._PanelObject
    local bShow = self._ItemData ~= nil
    local bHasTarget = self._TargetItemData ~= nil
    local bCanInherit = (bShow and bHasTarget and self._ItemData.ItemData:CanInherit())
    local bShowReason = (bShow and not bCanInherit)
    root.Lab_InheritTip:SetActive( bShow )
    root.Lab_None_Selection:SetActive( not bCanInherit )
    root.Btn_Drop_OrignItem:SetActive( bShow )
    root.Btn_AddOrignItem:SetActive( not bShow )

    if not bCanInherit then
        GUI.SetText(root.Lab_None_Selection, StringTable.Get(bShow and 10971 or 10970))
    end

    do
        if bShow then
            local setting = {
                [EItemIconTag.Bind] = self._ItemData.ItemData:IsBind(),
                [EItemIconTag.StrengthLv] = self._ItemData.ItemData:GetInforceLevel(),
                [EItemIconTag.Equip] = (self._ItemData.PackageType == BAGTYPE.ROLE_EQUIP),
                [EItemIconTag.Grade] = self._ItemData.ItemData:GetGrade(),
            }
            IconTools.InitItemIconNew(root.SelectOrignItem, self._ItemData.ItemData._Tid, setting)
        end

        local setting = {
            [EFrameIconTag.ItemIcon] = bShow,
            [EFrameIconTag.Add] = not bShow,
            [EFrameIconTag.Remove] = bShow,
        }
        IconTools.SetFrameIconTags(root.SelectOrignItem, setting)
    end

    do
        if bCanInherit then
            local setting = {
                [EItemIconTag.Bind] = self._TargetItemData.ItemData:IsBind(),
                [EItemIconTag.StrengthLv] = self._TargetItemData.ItemData:GetInforceLevel(),
                [EItemIconTag.Equip] = (self._TargetItemData.PackageType == BAGTYPE.ROLE_EQUIP),
                [EItemIconTag.Grade] = self._TargetItemData.ItemData:GetGrade(),
            }
            IconTools.InitItemIconNew(root.SelectTargetItem, self._TargetItemData.ItemData._Tid, setting)
        end
    
        local setting = {
            [EFrameIconTag.ItemIcon] = bCanInherit,
            [EFrameIconTag.Add] = not bCanInherit,
            [EFrameIconTag.Remove] = bCanInherit,
        }
        IconTools.SetFrameIconTags(root.SelectTargetItem, setting)
    end
end

-- 更新属性信息
def.method().UpdateProperty = function(self)
    local root = self._PanelObject
    local bShow = (self._ItemData ~= nil and
                   self._TargetItemData ~= nil and
                   self._ItemData.ItemData:CanInherit())

    root.Group_Property.Root:SetActive( bShow )

    if bShow then
        local itemData = self._ItemData.ItemData
        local targetItemData = self._TargetItemData.ItemData
        local bHasPVP = targetItemData:HasPVPProperty()

        local Group_Property = root.Group_Property
        Group_Property.PVP_Property.Root:SetActive( bHasPVP )
        GUI.SetText(Group_Property.Reinforce.Name, StringTable.Get(152))
        
        local fightElement = CElementData.GetAttachedPropertyTemplate(targetItemData._BaseAttrs.ID)
        GUI.SetText(Group_Property.Property.Name, fightElement.TextDisplayName)
        if bHasPVP then
            local pvpData = CElementData.GetAttachedPropertyTemplate(targetItemData._PVPFightProperty.ID)
            GUI.SetText(Group_Property.PVP_Property.Name, pvpData.TextDisplayName)
        end

        local baseVal = targetItemData._BaseAttrs.Value
        local basePVPVal = bHasPVP and targetItemData._PVPFightProperty.Value or 0
        local oldLv = 0
        local oldVal = 0
        local oldPVPVal = 0

        do
        -- 旧属性
            local curVal = baseVal
            local curPVPVal = basePVPVal
            local lv = targetItemData._InforceLevel
            GUI.SetText(Group_Property.Reinforce.Old, tostring(lv))

            if lv > 0 then
                local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(targetItemData._ReinforceConfigId, lv)
                local fixedIncVal = math.ceil(baseVal * InforceInfoOld.InforeValue / 100)
                curVal = targetItemData._BaseAttrs.Value + math.max(fixedIncVal, lv)
                curPVPVal = bHasPVP and targetItemData._PVPFightProperty.Value + math.max(fixedIncVal, lv)
            end
            oldLv = lv
            oldVal = curVal
            oldPVPVal = curPVPVal
            GUI.SetText(Group_Property.Property.Old, GUITools.FormatNumber(curVal))
            if bHasPVP then
                GUI.SetText(Group_Property.PVP_Property.Old, GUITools.FormatNumber(curPVPVal))
            end
        end

        do
        -- 新属性
            local curVal = baseVal
            local curPVPVal = basePVPVal

            local inforeLv = itemData._InforceLevel     -- 材料的强化等级
            local itemLv = targetItemData._Level        -- 目标的装备等级
            local inheritInfo = CElementData.GetInheritInfo(itemLv, inforeLv)

            if inheritInfo == nil then
                warn("传承模板是不是配错了...??? 为啥没数据了又...???")
                return
            end
            local nextLv = math.min(inheritInfo.InheritLevel, targetItemData:GetMaxInforceLevel())
            if nextLv > 0 then
                local InforceInfoOld = CEquipUtility.GetInforceInfoByLevel(targetItemData._ReinforceConfigId, nextLv)
                local fixedIncVal = math.ceil(curVal * InforceInfoOld.InforeValue / 100)
                curVal = targetItemData._BaseAttrs.Value + math.max(fixedIncVal, nextLv)
                curPVPVal = bHasPVP and targetItemData._PVPFightProperty.Value + math.max(fixedIncVal, nextLv) or 0
            end

            local fmtId = 0

            if inforeLv > oldLv then
                fmtId = 10975
            elseif inforeLv < oldLv then
                fmtId = 10974
            else
                fmtId = 10976
            end

            GUI.SetText(Group_Property.Property.New, string.format(StringTable.Get(fmtId), GUITools.FormatNumber(curVal)))
            GUI.SetText(Group_Property.Reinforce.New, string.format(StringTable.Get(fmtId), nextLv))
            if bHasPVP then
                GUI.SetText(Group_Property.PVP_Property.New, string.format(StringTable.Get(fmtId), GUITools.FormatNumber(curPVPVal)))
            end
        end
    end
end

--更新 按钮状态, 消耗金币价格
def.method().UpdateButtonState = function(self)
    local root = self._PanelObject
    local hp = game._HostPlayer
    local moneyNeedInfo = self:CalcMoneyNeed()
    local bActive = moneyNeedInfo ~= nil

    if bActive then
        local moneyHave = hp:GetMoneyCountByType(moneyNeedInfo[1])
        local moneyNeed = moneyNeedInfo[2]
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = moneyNeed   
        }
        root.CommonBtn_Inherit:ResetSetting(setting)
        -- root.CommonBtn_Inherit:MakeGray( moneyHave < moneyNeed )
    else
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = 0   
        }
        root.CommonBtn_Inherit:ResetSetting(setting)
        -- root.CommonBtn_Inherit:MakeGray( true )
    end
    root.CommonBtn_Inherit:MakeGray(not bActive)
end

def.method("=>", "table").CalcMoneyNeed = function(self)
    if self._ItemData == nil or self._TargetItemData == nil then return nil end

    local itemData = self._ItemData.ItemData
    local targetItemData = self._TargetItemData.ItemData
    local inforeLv = itemData._InforceLevel     -- 材料的强化等级
    local itemLv = targetItemData._Level        -- 目标的装备等级
    local inheritInfo = CElementData.GetInheritInfo(itemLv, inforeLv)
    if inheritInfo == nil then return nil end

    local moneyId = inheritInfo.CostMoneyId
    local moneyNeed = inheritInfo.CostMoneyCount

    return {moneyId,moneyNeed}
end

def.method("boolean", "=>", "boolean").CheckCanInherit = function(self, bShowReason)
    local bRet = true
    local function ShowReason(msg)
        if bShowReason then
            TeraFuncs.SendFlashMsg(msg, false)
        end
    end

    -- 请先选择装备
    if self._ItemData == nil then
        ShowReason(StringTable.Get(31301))
        return false
    end

    local itemData = self._ItemData.ItemData
    if not itemData:CanInherit() then
        ShowReason(StringTable.Get(31314))
        return false
    end

    -- 请先选择要继承装备
    if self._ItemData ~= nil and self._TargetItemData == nil then
        ShowReason(StringTable.Get(31332))
        return false
    end

    return bRet
end

def.method("userdata", "number", "table").OnInitItem = function(self, item, index, itemData)
    local idx = index + 1
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    local ItemIconNew = item:FindChild("ItemIconNew")

     if itemData.ItemData:IsEquip() then
        if self._ItemData == nil then
            local setting = {
                [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
                [EItemIconTag.StrengthLv] = itemData.ItemData:GetInforceLevel(),
                [EItemIconTag.Equip] = (itemData.PackageType == BAGTYPE.ROLE_EQUIP),
                [EItemIconTag.Grade] = itemData.ItemData:GetGrade(),
            }
            IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
            Img_UnableClick:SetActive(not itemData.ItemData:CanInherit())
        else
            local setting = {
                [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
                [EItemIconTag.StrengthLv] = itemData.ItemData:GetInforceLevel(),
                [EItemIconTag.Equip] = (itemData.PackageType == BAGTYPE.ROLE_EQUIP),
                [EItemIconTag.Grade] = itemData.ItemData:GetGrade(),
            }
            IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
            local bIsOrign = self._ItemData == itemData
            local bIsTarget = self._TargetItemData == itemData
            local bUnableClick = false

            if bIsOrign or bIsTarget then
                -- 已装备 不置灰
                bUnableClick = false
            else
                if self._ItemData ~= nil and self._TargetItemData ~= nil then
                    -- 已全部装备
                    bUnableClick = true
                elseif itemData.ItemData._EquipSlot ~= self._ItemData.ItemData._EquipSlot then
                    -- 不是同部位
                    bUnableClick = true
                elseif itemData.ItemData:GetInforceLevel() >= self._ItemData.ItemData:GetInforceLevel() then
                    -- 低级不允许
                    bUnableClick = true
                end
            end

            Img_UnableClick:SetActive( bUnableClick )
        end
    else
        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.Number] = itemData.ItemData:GetCount(),
        }
        IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
        Img_UnableClick:SetActive( false )
    end
end

def.method("userdata", "number", "table").OnSelectItem = function(self, item, index, itemData)
    local idx = index + 1
    if itemData.ItemData:IsEquip() then

        if self._ItemData == nil then
            if not itemData.ItemData:CanInherit() then
                TeraFuncs.SendFlashMsg(StringTable.Get(31333), false)
                return
            end

            self._ItemData = itemData
            PlayAddItemAudio()
        else
            if self._ItemData == itemData then
                TeraFuncs.SendFlashMsg(StringTable.Get(31334), false)
                return
            end

            if itemData.ItemData._EquipSlot ~= self._ItemData.ItemData._EquipSlot then
                TeraFuncs.SendFlashMsg(StringTable.Get(31335), false)
                return
            end
            if self._ItemData and self._TargetItemData then
                -- 位置已满
                return
            end

            self._TargetItemData = itemData
            PlayAddItemAudio()
        end
    else
        warn("tips?")
    end

    self:UpdateFrame()
end

def.method("string").OnClick = function(self, id)
    --warn("CPageEquipInherit::OnClick => ", id)
    if id == "Btn_Inherit" then
        local CPanelUIEquipInheritResult = require "GUI.CPanelUIEquipInheritResult"
        if CPanelUIEquipInheritResult.Instance():IsShow() then
            return
        end
        
        if self:CheckCanInherit(true) then
            local function Do( ret )
                CEquipUtility.SendC2SItemInherit(self._ItemData.PackageType, self._ItemData.ItemData._Slot,
                                                 self._TargetItemData.PackageType, self._TargetItemData.ItemData._Slot)
            end

            local itemData = self._ItemData.ItemData
            local targetItemData = self._TargetItemData.ItemData
            local targetLv = targetItemData._InforceLevel       -- 目标的强化等级

            local function DoCommonBuy()
                local moneyNeedInfo = self:CalcMoneyNeed()
                if moneyNeedInfo ~= nil then
                    MsgBox.ShowQuickBuyBox(moneyNeedInfo[1], moneyNeedInfo[2], Do)
                end
            end
            local function callback( ret )
                if ret then
                    DoCommonBuy()
                end
            end

            local function DoQuickBuy( ret )
                if ret then
                    if not self._TargetItemData.ItemData:IsBind() then
                        local title, msg, closeType = StringTable.GetMsg(115)
                        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
                    else
                        DoCommonBuy()
                    end
                end
            end

            if targetLv > 0 then
                local title, msg, closeType = StringTable.GetMsg(106)
                msg = string.format(msg, RichTextTools.GetQualityText(itemData:GetNameText(), itemData:GetQuality()))
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, DoQuickBuy)    
            else
                DoQuickBuy( true )
            end
        end
    elseif id == "SelectOrignItem" then
        if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
            local root = self._PanelObject
            CItemTipMan.ShowPackbackEquipTip(self._ItemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,root.SelectItem)
        end
    elseif id == "SelectTargetItem" then
        if self._TargetItemData ~= nil and self._TargetItemData.ItemData ~= nil then
            local root = self._PanelObject
            CItemTipMan.ShowPackbackEquipTip(self._TargetItemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,root.SelectItem)
        end
    elseif id == "Btn_Inherit_Desc" then
        game._GUIMan:Close("CPanelUICommonNotice")
        local data = 
        {
            Title = StringTable.Get(34203),
            Name = StringTable.Get(34200),
            Desc = StringTable.Get(34204),
        }
        game._GUIMan:Open("CPanelUICommonNotice", data)
    end
end

def.method().Reset = function(self)
    self._ItemData = nil
    -- self._TargetItemData = nil
    self:UpdateFrame()
end

def.method().ResetTarget = function(self)
    self._TargetItemData = nil
    self:UpdateFrame()
end

def.method().Hide = function(self)
    self:DisableBgGfx()
    self:StopGfx()
    self._TargetItemData = nil

    if self._OnMoneyChanged ~= nil then
        CGame.EventManager:removeHandler('NotifyMoneyChangeEvent', self._OnMoneyChanged)
        self._OnMoneyChanged = nil
    end
    self._Panel:SetActive(false)
end

def.method().Destroy = function (self)
    if self._PanelObject ~= nil then
        if self._PanelObject.CommonBtn_Inherit ~= nil then
            self._PanelObject.CommonBtn_Inherit:Destroy()
        end

        self._PanelObject = nil
    end
end

CPageEquipInherit.Commit()
return CPageEquipInherit