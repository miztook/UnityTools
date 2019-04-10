local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPageEquipRecast = Lplus.Class("CPageEquipRecast")
local def = CPageEquipRecast.define
local EItemType = require "PB.Template".Item.EItemType
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local BAGTYPE = require "PB.net".BAGTYPE

local CConsumeUtil = require "Utility.CConsumeUtil"
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CCommonBtn = require "GUI.CCommonBtn"
local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

--存储UI的集合，便于OnHide()时置空
def.field("table")._PanelObject = BlankTable
def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("function")._OnMoneyChanged = nil
def.field("table")._MaterialSelectList = BlankTable
def.field("table")._ItemData = nil
def.field("boolean")._IsSurmount = false
def.field("boolean")._IsEnoughRecastMaterial = false
def.field("boolean")._IsEnoughQuenchMaterial = false
def.field("table")._IteamOld = nil
def.field("boolean")._GfxBgIsShow = false


local function PlayAddItemAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipAddItem, 0)
end

---------------------------装备重铸------------------------------
def.field("table")._GfxObjectGroup = BlankTable

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Parent._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = 2
    root.DoTweenTimeDelay = 1.5 + 0.5
    root.TweenObjectHook = self._Parent:GetUIObject("SelectRecastItem")
    root.Frame_Remove = root.TweenObjectHook:FindChild("Frame_Remove")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.BlurTex = self._Parent:GetUIObject("BlurTex")

    root.GfxHook = self._Panel
    root.GfxTimeDelay = 1
    root.Gfx = PATH.ETC_Recast_lvjing
    root.TimerId = 0

    root.BgGfx = PATH.UI_Recast_BG
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

    -- _G.AddGlobalTimer(0.05, true, function()
    root.TweenObjectHook:SetActive(true)
    root.DoTweenPlayer:Restart(root.TweenGroupId)
    GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1)
    root.Frame_Remove:SetActive( false )
    local UIRoot = self._PanelObject
    self._PanelObject.CommonBtn_Recast:SetInteractable(false)
    self._PanelObject.CommonBtn_Quench:SetInteractable(false)
    GameUtil.SetButtonInteractable(UIRoot.Btn_RecastCheckout, false)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectItem, false)
    root.TimerId = _G.AddGlobalTimer(root.DoTweenTimeDelay, true, callback)
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
    
    local UIRoot = self._PanelObject
    self._PanelObject.CommonBtn_Recast:SetInteractable(true)
    self._PanelObject.CommonBtn_Quench:SetInteractable(true)
    GameUtil.SetButtonInteractable(UIRoot.Btn_RecastCheckout, true)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectItem, true)
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
---------------------------装备重铸------------------------------

def.static("table", "userdata", "=>", CPageEquipRecast).new = function(parent, panel)
    local obj = CPageEquipRecast()
    obj._Parent = parent
    obj._Panel = panel
    obj:Init()

    return obj
end

def.method().Init = function(self)
    self._PanelObject = 
    {
        Group_Recast = {},
    }

    local root = self._PanelObject
    root.SelectItem = self._Parent:GetUIObject('SelectRecastItem')
    root.RecastMaterialItem1 = self._Parent:GetUIObject("RecastMaterialItem1")
    root.RecastMaterialItem2 = self._Parent:GetUIObject("RecastMaterialItem2")
    root.RecastMaterialNeed = root.RecastMaterialItem1:FindChild("Lab_Need")
    root.QuenchMaterialNeed = root.RecastMaterialItem2:FindChild("Lab_Need")

    root.Btn_Drop_Recast = self._Parent:GetUIObject("Btn_Drop_Recast")
    root.Btn_AddRecastItem = self._Parent:GetUIObject("Btn_AddRecastItem")
    root.Btn_Recast = self._Parent:GetUIObject('Btn_Recast')
    root.Btn_Quench = self._Parent:GetUIObject('Btn_Quench')
    root.Btn_RecastCheckout = self._Parent:GetUIObject("Btn_RecastCheckout")
    root.Lab_None_Selection = self._Parent:GetUIObject("Lab_None_Selection")
    root.Lab_Reason = self._Parent:GetUIObject('Lab_Reason')
    root.Lab_ShowTips = self._Parent:GetUIObject("Lab_ShowTips")

    local settingRecast = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31350),
        [EnumDef.CommonBtnParam.MoneyID] = 1,
        [EnumDef.CommonBtnParam.MoneyCost] = 0   
    }
    root.CommonBtn_Recast = CCommonBtn.new(root.Btn_Recast ,settingRecast)
    local settingQuench = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31351),
        [EnumDef.CommonBtnParam.MoneyID] = 1,
        [EnumDef.CommonBtnParam.MoneyCost] = 0   
    }
    root.CommonBtn_Quench = CCommonBtn.new(root.Btn_Quench ,settingQuench)

    do
        local Group_Recast = root.Group_Recast
        Group_Recast.Root = self._Parent:GetUIObject("Group_Recast")
        Group_Recast.Items = {}
        local item = self._Parent:GetUIObject('Recastitem')
        table.insert(Group_Recast.Items, item)
    end

    -- 初始化特效所需组件信息
    self:InitGfxGroup()
end

--------------------------------------------------------------------------------

def.method("dynamic").Show = function(self, data)
    self._Panel:SetActive(true)
    self._ItemData = nil

    if data then
        self._ItemData = data
    end

    --更新是否显示分界面
    self:UpdateFrame()

    if self._OnMoneyChanged == nil then
        local function OnMoneyChanged()
            self:UpdateButtonState()
        end
        CGame.EventManager:addHandler('NotifyMoneyChangeEvent', OnMoneyChanged)
        self._OnMoneyChanged = OnMoneyChanged
    end

    -- 播放特效
    self:EnableBgGfx()
end

-- 更新是否显示界面
def.method().UpdateFrame = function(self)
    --warn("CPageEquipRecast::UpdateFrame()")
    local root = self._PanelObject
    root.Lab_ShowTips:SetActive( false )

    -- 更新选中信息
    self:UpdateSelectItem()
    -- 更新材料信息
    self:UpdatrMaterialInfo()
    -- 更新属性信息 材料有可能提升数值，最后计算
    self:UpdateProperty()
    -- 更新金币消耗，按钮状态
    self:UpdateButtonState()
end

-- 更新选中信息
def.method().UpdateSelectItem = function(self)
    local root = self._PanelObject
    local bShow = self._ItemData ~= nil
    local bCanRecast = (bShow and self._ItemData.ItemData:CanRecast())
    local bShowReason = (bShow and not bCanRecast)

    root.Lab_Reason:SetActive( bShowReason )
    if bShowReason then
        GUI.SetText(root.Lab_Reason, StringTable.Get(31317))
    end

    root.Lab_None_Selection:SetActive( not bShow )
    root.Btn_Drop_Recast:SetActive( bShow )
    root.Btn_AddRecastItem:SetActive( not bShow )
    root.RecastMaterialItem1:SetActive( not bShowReason )
    root.RecastMaterialItem2:SetActive( not bShowReason )
    root.Group_Recast.Root:SetActive( bShow )

    if bShow then
        local setting = {
            [EItemIconTag.Bind] = self._ItemData.ItemData:IsBind(),
            [EItemIconTag.StrengthLv] = self._ItemData.ItemData:GetInforceLevel(),
            [EItemIconTag.Equip] = (self._ItemData.PackageType == BAGTYPE.ROLE_EQUIP),
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
    local bShow = (self._ItemData ~= nil and self._ItemData.ItemData:CanRecast())

    self:DisablePropertyItem()

    if bShow then
        local itemData = self._ItemData.ItemData

        local function SetCellInfo(idx)
            local item = self:GetRecastPropertyItem(idx)
            item:SetActive(true)

            local attrId = itemData._EquipBaseAttrs[idx].index
            local attrValue = itemData._EquipBaseAttrs[idx].value
            local attrStar = itemData._EquipBaseAttrs[idx].star
            local attrMaxValue = itemData._EquipBaseAttrs[idx].MaxStarValue

            local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate( attrId )
            local fightPropertyId = attachPropertGenerator.FightPropertyId
            local fightElement = CElementData.GetAttachedPropertyTemplate(fightPropertyId)

            local Lab_AttriTips = item:FindChild("Lab_AttriTips")
            local Lab_AttriValues = item:FindChild("Sld_Attr/Lab_AttriValues")
            local Img_AddValue = item:FindChild("Sld_Attr/Img_AddValue")
            local Lab_Increase = item:FindChild("Sld_Attr/Lab_Increase")

            local strValue = string.format(StringTable.Get(19070), attrValue, attrMaxValue)
            GUI.SetText(Lab_AttriValues, strValue)
            GUI.SetText(Lab_AttriTips, fightElement.TextDisplayName)

            local sld = item:FindChild("Sld_Attr")
            local Sld_Attr = sld:GetComponent(ClassType.Slider)

            if self._IteamOld ~= nil and self._IteamOld.ItemData ~= nil then
                local attrValueOld = self._IteamOld.ItemData._EquipBaseAttrs[idx].value
                local bActive = attrValueOld < attrValue

                if bActive then
                    local imgfill = Img_AddValue:GetComponent(ClassType.Image)
                    imgfill.fillAmount = attrValue/attrMaxValue
                    Sld_Attr.value = attrValueOld/attrMaxValue
                    local inc = attrValue - attrValueOld
                    GUI.SetText(Lab_Increase, string.format(StringTable.Get(10973), inc))
                    GameUtil.PlayUISfx(PATH.UIFX_DEV_Fortify_Inc, sld, sld, -1)
                else
                    Sld_Attr.value = attrValue/attrMaxValue
                end
                Img_AddValue:SetActive(bActive)
                Lab_Increase:SetActive(bActive)
            else
                Sld_Attr.value = attrValue/attrMaxValue
                Img_AddValue:SetActive(false)
                Lab_Increase:SetActive(false)
            end
        end

        --设置
        for i,v in ipairs(itemData._EquipBaseAttrs) do
            SetCellInfo(i)
        end
        self._IteamOld = nil
    end
end
-- 更新材料信息
def.method().UpdatrMaterialInfo = function(self)
    local root = self._PanelObject
    local bShow = (self._ItemData ~= nil and self._ItemData.ItemData:CanRecast())
    local bHasAttrCache = bShow and self._ItemData.ItemData:HasUnsaveEquipAttrsCache()

    root.Btn_Recast:SetActive( not bHasAttrCache )
    root.Btn_RecastCheckout:SetActive( bHasAttrCache )
    root.RecastMaterialItem1:SetActive( bShow and not bHasAttrCache )
    root.RecastMaterialItem2:SetActive(bShow)

    if bShow then
        local itemData = self._ItemData.ItemData
        local hp = game._HostPlayer
        local pack = hp._Package._NormalPack

        -- 重铸材料
        if not bHasAttrCache then
            local recastTemplate = CElementData.GetTemplate("EquipConsumeConfig", itemData._Template.RecastCostId)
            if recastTemplate == nil then return nil end

            local MaterialId = recastTemplate.Item.ConsumePairs[1].ConsumeId
            local MaterialNeed = recastTemplate.Item.ConsumePairs[1].ConsumeCount
            local MaterialHave = pack:GetItemCount( MaterialId )
            IconTools.InitMaterialIconNew(root.RecastMaterialItem1, MaterialId, MaterialNeed)

            self._IsEnoughRecastMaterial = MaterialHave >= MaterialNeed
            root.CommonBtn_Recast:MakeGray( not self._IsEnoughRecastMaterial )
        end
        
        -- 淬火 or 突破
        do
            if itemData:IsAttrAllMax() then
            -- 突破
                if itemData:CanSurmount() then
                    local SurmountNeedInfo = CEquipUtility.GetEquipSurmountNeedInfo(itemData)
                    local MaterialId = SurmountNeedInfo.MaterialId
                    local MaterialNeed = SurmountNeedInfo.MaterialNeed
                    local MaterialHave = SurmountNeedInfo.MaterialHave

                    IconTools.InitMaterialIconNew(root.RecastMaterialItem2, MaterialId, MaterialNeed)
                    self._IsEnoughQuenchMaterial = MaterialHave >= MaterialNeed

                    self._IsSurmount = true
                else
                    self._IsEnoughQuenchMaterial = false
                    root.RecastMaterialItem2:SetActive(false)
                end
            else
            -- 淬火
                local RecastNeedInfo = CEquipUtility.GetEquipQuenchNeedInfo(itemData)
                local MaterialId = RecastNeedInfo.MaterialId
                local MaterialNeed = RecastNeedInfo.MaterialNeed
                local MaterialHave = RecastNeedInfo.MaterialHave
                IconTools.InitMaterialIconNew(root.RecastMaterialItem2, MaterialId, MaterialNeed)
                self._IsEnoughQuenchMaterial = MaterialHave >= MaterialNeed

                self._IsSurmount = false
            end

            root.CommonBtn_Quench:MakeGray( not self._IsEnoughQuenchMaterial )
        end
    end
end
--更新 按钮状态, 消耗金币价格
def.method().UpdateButtonState = function(self)
    local root = self._PanelObject
    local hp = game._HostPlayer
    -- 重铸
    do
        local bShow = (self._ItemData ~= nil and self._ItemData.ItemData:CanRecast())
        local recastMoneyNeedInfo = self:CalcRecastMoneyNeed()
        local bActive = (bShow and recastMoneyNeedInfo ~= nil)

        if bActive then
            local moneyHave = hp:GetMoneyCountByType(recastMoneyNeedInfo[1])
            local moneyNeed = recastMoneyNeedInfo[2]
            local setting = {
                [EnumDef.CommonBtnParam.MoneyCost] = moneyNeed   
            }
            root.CommonBtn_Recast:ResetSetting(setting)
            root.CommonBtn_Recast:MakeGray( (moneyHave < moneyNeed) or not self._IsEnoughRecastMaterial ) 
        else
            local setting = {
                [EnumDef.CommonBtnParam.MoneyCost] = 0   
            }
            root.CommonBtn_Recast:ResetSetting(setting)
            root.CommonBtn_Recast:MakeGray(true) 
        end
    end

    -- 淬火 or 突破
    do
        local bShow = (self._ItemData ~= nil and self._ItemData.ItemData:CanRecast())
        local quenchOrSurmountMoneyNeedInfo = self:CalcQuenchOrSurmountMoneyNeed()
        local bActive = (bShow and quenchOrSurmountMoneyNeedInfo ~= nil)

        if bActive then
            local moneyHave = hp:GetMoneyCountByType(quenchOrSurmountMoneyNeedInfo[1])
            local moneyNeed = quenchOrSurmountMoneyNeedInfo[2]
            local setting = {
                [EnumDef.CommonBtnParam.BtnTip] = quenchOrSurmountMoneyNeedInfo[3] == true and StringTable.Get(31352) or StringTable.Get(31351),
                [EnumDef.CommonBtnParam.MoneyCost] = moneyNeed   
            }
            root.CommonBtn_Quench:ResetSetting(setting)
            root.CommonBtn_Quench:MakeGray( (moneyHave < moneyNeed) or not self._IsEnoughQuenchMaterial )
        else
            local setting = {
                [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31351),
                [EnumDef.CommonBtnParam.MoneyCost] = 0   
            }
            root.CommonBtn_Quench:ResetSetting(setting)
            root.CommonBtn_Quench:MakeGray(true)
        end
        -- 刷新红点
        -- local bShowRedDot = (bActive and
        --                      self._ItemData.PackageType == BAGTYPE.ROLE_EQUIP and
        --                      (CEquipUtility.CalcEquipQuenchRedDotState(self._ItemData.ItemData._EquipSlot + 1) or
        --                      CEquipUtility.CalcEquipSurmountRedDotState(self._ItemData.ItemData._EquipSlot + 1)))
        -- root.Img_BtnFloatFx:SetActive( false )
    end
end

def.method("=>", "table").CalcRecastMoneyNeed = function(self)
    if self._ItemData == nil then return nil end

    local itemData = self._ItemData.ItemData
    local recastTemplate = CElementData.GetTemplate("EquipConsumeConfig", itemData._Template.RecastCostId)
    if recastTemplate == nil then return nil end
    
    local hp = game._HostPlayer
    local moneyId = recastTemplate.Money.ConsumePairs[1].ConsumeId
    local moneyNeed = recastTemplate.Money.ConsumePairs[1].ConsumeCount

    return {moneyId,moneyNeed}
end

def.method("=>", "table").CalcQuenchOrSurmountMoneyNeed = function(self)
    if self._ItemData == nil then return nil end

    local itemData = self._ItemData.ItemData
    local info = nil

    if itemData:IsAttrAllMax() then
    -- 突破
        if itemData:CanSurmount() then
            local quenchTemplate = CEquipUtility.GetSurmountInfoByLevel(itemData._SurmountTid, itemData:GetSurmountLevel())
            local moneyId = quenchTemplate.CostMoneyId
            local moneyNeed = quenchTemplate.CostMoneyCount
            info = {moneyId, moneyNeed, true}
        end
    else
        local quenchTemplate = CEquipUtility.GetQuenchInfoByLevel(itemData._QuenchTid, itemData:GetSurmountLevel())
        if quenchTemplate ~= nil then
            local moneyId = quenchTemplate.CostMoneyId
            local moneyNeed = quenchTemplate.CostMoneyCount
            info = {moneyId, moneyNeed, false}
        end
    end

    return info
end

--获取重铸item组件，动态创建，自行维护
def.method("number", "=>", "userdata").GetRecastPropertyItem = function(self, index)
    local info = self._PanelObject.Group_Recast.Items

    if index > #info then
        local itemNew = GameObject.Instantiate(info[1])
        table.insert(info, itemNew)
        itemNew:SetParent(info[1].parent, false)
    end

    return info[index]
end
def.method().DisablePropertyItem = function(self)
    local info = self._PanelObject.Group_Recast.Items

    for i=1, #info do
        info[i]:SetActive(false)
    end
end

def.method("userdata", "number", "table").OnInitItem = function(self, item, index, itemData)
    local idx = index + 1
    local Img_UnableClick = item:FindChild("Img_UnableClick")
    local ItemIconNew = item:FindChild("ItemIconNew")
    if itemData.ItemData:IsEquip() then
        -- local bShowRedDot = (itemData.PackageType == BAGTYPE.ROLE_EQUIP and
        --                      (CEquipUtility.CalcEquipQuenchRedDotState(itemData.ItemData._EquipSlot + 1) or
        --                      CEquipUtility.CalcEquipSurmountRedDotState(itemData.ItemData._EquipSlot + 1)))

        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.StrengthLv] = itemData.ItemData:GetInforceLevel(),
            [EItemIconTag.Equip] = (itemData.PackageType == BAGTYPE.ROLE_EQUIP),
        }
        IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
        Img_UnableClick:SetActive(self._ItemData ~= nil and self._ItemData ~= itemData)
    else
        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.Number] = itemData.ItemData:GetCount(),
        }
        IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
        Img_UnableClick:SetActive(false)
    end
end

def.method("userdata", "number", "table").OnSelectItem = function(self, item, index, itemData)
    local idx = index + 1

    if itemData.ItemData:IsEquip() then
        self._ItemData = itemData
        PlayAddItemAudio()
    else
        warn("tips?")
    end
    self:UpdateFrame()
end

def.method("string").OnClick = function(self, id)
    --warn("CPageEquipRecast::OnClick => ", id)
    if id == "Btn_Recast" then
        --warn("OnClick::Btn_Recast")
        self:OnClickBtnRecast()
    elseif id == "Btn_Quench" then
        self:OnClickBtnQuench()
    elseif id == "Btn_RecastCheckout" then
        local CPanelUIEquipRecastResult = require "GUI.CPanelUIEquipRecastResult"
        if CPanelUIEquipRecastResult.Instance():IsShow() then
            return
        end

        local data = 
        {
            PackageType = self._ItemData.PackageType,
            ItemData = self._ItemData.ItemData,
            ShowGfx = false
        }
        game._GUIMan:Open("CPanelUIEquipRecastResult", data)
    elseif id == "Btn_DesMaterialItem1" then
        local itemData = self._ItemData.ItemData
        game._GUIMan:Open("CPanelUIRecastLibrary", itemData)
    elseif id == "Btn_DesMaterialItem2" then
        local itemData = self._ItemData.ItemData
        game._GUIMan:Open("CPanelUIQuenchDescHint", itemData)
    elseif id == "RecastMaterialItem1" then
        self:OnClickRecastMaterialItem1()
    elseif id == "RecastMaterialItem2" then
        self:OnClickRecastMaterialItem2()
    elseif id == "SelectRecastItem" then
        if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
            local root = self._PanelObject
            CItemTipMan.ShowPackbackEquipTip(self._ItemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,root.SelectItem)
        end
    end
end

def.method().OnClickBtnQuench = function(self)
    if self:CheckCanQuenchOrSurmount(true) then
        local function Do( ret )
            if ret then
                if self._IsSurmount then
                    CEquipUtility.SendC2SItemSurmount(self._ItemData.PackageType, self._ItemData.ItemData._Slot)
                else
                    CEquipUtility.SendC2SItemQuench(self._ItemData.PackageType, self._ItemData.ItemData._Slot)
                end
            end
        end

        local function DoCommonBuy()
            local moneyNeedInfo = self:CalcQuenchOrSurmountMoneyNeed()
            MsgBox.ShowQuickBuyBox(moneyNeedInfo[1], moneyNeedInfo[2], Do)
        end

        local function callback( ret )
            if ret then
                DoCommonBuy()
            end
        end

        if not self._ItemData.ItemData:IsBind() then
            local title, msg, closeType = StringTable.GetMsg(113)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
        else
            DoCommonBuy()
        end

        self._PanelObject.CommonBtn_Quench:SetInteractable(false)
        _G.AddGlobalTimer(0.2, true, function()
            self._PanelObject.CommonBtn_Quench:SetInteractable(true)
        end)
    end
end

def.method().OnClickBtnRecast = function(self)
    if self:CheckCanRecast(true) then
        local function Do( ret )
            if ret then
                CEquipUtility.SendC2SItemRebuild(self._ItemData.PackageType, self._ItemData.ItemData._Slot)
                local UIRoot = self._PanelObject
                self._PanelObject.CommonBtn_Recast:SetInteractable(false)
                self._PanelObject.CommonBtn_Quench:SetInteractable(false)
                GameUtil.SetButtonInteractable(UIRoot.Btn_RecastCheckout, false)
            end
        end

        local function DoCommonBuy()
            local moneyNeedInfo = self:CalcRecastMoneyNeed()
            MsgBox.ShowQuickBuyBox(moneyNeedInfo[1], moneyNeedInfo[2], Do)
        end

        local function callback( ret )
            if ret then
                DoCommonBuy()
            end
        end

        if not self._ItemData.ItemData:IsBind() then
            local title, msg, closeType = StringTable.GetMsg(112)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
        else
            DoCommonBuy()
        end
    end
end

def.method().OnClickRecastMaterialItem1 = function(self)
    local itemData = self._ItemData.ItemData
    local recastTemplate = CElementData.GetTemplate("EquipConsumeConfig", itemData._Template.RecastCostId)
    if recastTemplate == nil then return nil end
    local MaterialId = recastTemplate.Item.ConsumePairs[1].ConsumeId

    CItemTipMan.ShowItemTips(MaterialId, 
                             TipsPopFrom.OTHER_PANEL, 
                             self._PanelObject.RecastMaterialItem1, 
                             TipPosition.FIX_POSITION)
end

def.method().OnClickRecastMaterialItem2 = function(self)
    local itemData = self._ItemData.ItemData
    local MaterialId = 0
    if itemData:IsAttrAllMax() then
    -- 突破
        if itemData:CanSurmount() == false then return end

        local surmountTemplate = CEquipUtility.GetSurmountInfoByLevel(itemData._SurmountTid, itemData:GetSurmountLevel())
        MaterialId = surmountTemplate.CostItemId
    else
    -- 淬火
        local quenchTemplate = CEquipUtility.GetQuenchInfoByLevel(itemData._QuenchTid, itemData:GetSurmountLevel())
        if quenchTemplate == nil then return end
        MaterialId = quenchTemplate.CostItemId
    end

    CItemTipMan.ShowItemTips(MaterialId, 
                             TipsPopFrom.OTHER_PANEL, 
                             self._PanelObject.RecastMaterialItem2, 
                             TipPosition.FIX_POSITION)
end

def.method("boolean", "=>", "boolean").CheckCanRecast = function(self, bShowReason)
    local bRet = true
    local function ShowReason(msg)
        if bShowReason then
            SendFlashMsg(msg, false)
        end
    end

    -- 请先选择装备
    if self._ItemData == nil then
        ShowReason(StringTable.Get(31301))
        return false
    end

    local itemData = self._ItemData.ItemData
    if not itemData:CanRecast() then
        ShowReason(StringTable.Get(31317))
        return false
    end

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    local recastTemplate = CElementData.GetTemplate("EquipConsumeConfig", itemData._Template.RecastCostId)
    local MaterialId = recastTemplate.Item.ConsumePairs[1].ConsumeId
    local MaterialNeed = recastTemplate.Item.ConsumePairs[1].ConsumeCount
    local MaterialHave = pack:GetItemCount(MaterialId)
    if MaterialHave < MaterialNeed then
        ShowReason(StringTable.Get(31309))
        return false
    end
--[[
    -- 所需货币不足
    local moneyNeedInfo = self:CalcRecastMoneyNeed()
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

def.method("boolean", "=>", "boolean").CheckCanQuenchOrSurmount = function(self, bShowReason)
    local bRet = true

    local function ShowReason(msg)
        if bShowReason then
            SendFlashMsg(msg, false)
        end
    end

    -- 请先选择装备
    if self._ItemData == nil then
        ShowReason(StringTable.Get(31301))
        return false
    end

    local itemData = self._ItemData.ItemData
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    if itemData:IsAttrAllMax() then
    -- 突破
        if itemData:CanSurmount() == false then
            ShowReason(StringTable.Get(31321))
            return false
        end

        local surmountTemplate = CEquipUtility.GetSurmountInfoByLevel(itemData._SurmountTid, itemData:GetSurmountLevel())
        local MaterialId = surmountTemplate.CostItemId
        local MaterialNeed = surmountTemplate.CostItemCount
        local MaterialHave = pack:GetItemCount(MaterialId)

        if MaterialHave < MaterialNeed then
            ShowReason(StringTable.Get(31311))
            return false
        end
    else
    -- 淬火
        local quenchTemplate = CEquipUtility.GetQuenchInfoByLevel(itemData._QuenchTid, itemData:GetSurmountLevel())
        if quenchTemplate == nil then
            ShowReason(StringTable.Get(31320))
            return false
        end

        local MaterialId = quenchTemplate.CostItemId
        local MaterialNeed = quenchTemplate.CostItemCount
        local MaterialHave = pack:GetItemCount(MaterialId)

        if MaterialHave < MaterialNeed then
            ShowReason(StringTable.Get(31312))
            return false
        end
    end
--[[
    -- 所需货币不足
    local moneyNeedInfo = self:CalcQuenchOrSurmountMoneyNeed()
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

def.method("table").UpdateQuenchData = function(self, data)
    self._IteamOld = data
    self:UpdateProperty()
end


def.method().Reset = function(self)
    self._ItemData = nil
    self:UpdateFrame()
end

def.method().Hide = function(self)
    self:DisableBgGfx()

    if self._OnMoneyChanged ~= nil then
        CGame.EventManager:removeHandler('NotifyMoneyChangeEvent', self._OnMoneyChanged)
        self._OnMoneyChanged = nil
    end

    self._Panel:SetActive(false)
end

def.method().Destroy = function (self)
    if self._PanelObject ~= nil then
        if self._PanelObject.CommonBtn_Quench ~= nil then
            self._PanelObject.CommonBtn_Quench:Destroy()
        end
        if self._PanelObject.CommonBtn_Recast ~= nil then
            self._PanelObject.CommonBtn_Recast:Destroy()
        end
        self._IteamOld = nil
        self._PanelObject = nil
    end
end

CPageEquipRecast.Commit()
return CPageEquipRecast