local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPageEquipLegend = Lplus.Class("CPageEquipLegend")
local def = CPageEquipLegend.define
local EItemType = require "PB.Template".Item.EItemType
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local BAGTYPE = require "PB.net".BAGTYPE

local CConsumeUtil = require "Utility.CConsumeUtil"
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CCommonBtn = require "GUI.CCommonBtn"

local gfxGroupName = "CPageEquipLegend"
local MAX_REFINE_STAR_COUNT = 10    -- 最大星星个数

--存储UI的集合，便于OnHide()时置空
def.field("table")._PanelObject = BlankTable
def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("function")._OnMoneyChanged = nil
def.field("table")._ItemData = nil
def.field("boolean")._IsEnoughChangeMaterial = false
def.field("table")._GfxObjectGroup = BlankTable
def.field("boolean")._GfxBgIsShow = false

local function PlayAddItemAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipAddItem, 0)
end
----------------------装备转化-----------------------

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Parent._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = 11
    root.DoTweenTimeDelay = 1.5 + 0.5
    root.Delay1 = 0.6
    root.Delay2 = 2.3

    root.TweenObjectHook = self._Parent:GetUIObject("SelectLegendItem")
    root.Frame_Remove = root.TweenObjectHook:FindChild("Frame_Remove")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.TweenObjectHook1 = self._Parent:GetUIObject("LegendMaterialIcon")
    root.OrignPosition1 = root.TweenObjectHook1.localPosition
    root.OrignScale1 = root.TweenObjectHook1.localScale
    root.BlurTex = self._Parent:GetUIObject("BlurTex")

    root.GfxHook = self._Parent:GetUIObject("Frame_Legend")
    root.GfxTimeDelay = 1
    root.Gfx = PATH.ETC_Legend_lvjing
    root.TimerId = 0
    root.TimerId1 = 0
    root.TimerId1 = 0

    root.BgGfx = PATH.UI_Legend_BG
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
    root.TweenObjectHook:SetActive(true)
    root.DoTweenPlayer:Restart(root.TweenGroupId)
    GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1)
    root.Frame_Remove:SetActive( false )
    --转化按钮可点击状态
    self._PanelObject.CommonBtn_LegendChange:SetInteractable(false)
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_Drop_Legend, false)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectItem, false)
    GameUtil.SetButtonInteractable(self._PanelObject.LegendMaterialIcon, false)
    
    root.TimerId = _G.AddGlobalTimer(root.DoTweenTimeDelay, true, callback)
    root.TimerId1 = _G.AddGlobalTimer(root.Delay1, true, callback1)
    root.TimerId2 = _G.AddGlobalTimer(root.Delay2, true, callback2)
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
    root.TweenObjectHook1.localPosition = root.OrignPosition1
    root.TweenObjectHook1.localScale = root.OrignScale1

    root.BlurTex:SetActive( false )
    root.Frame_Remove:SetActive( true )
    --转化按钮可点击状态
    self._PanelObject.CommonBtn_LegendChange:SetInteractable(true)
    GameUtil.SetButtonInteractable(self._PanelObject.Btn_Drop_Legend, true)
    GameUtil.SetButtonInteractable(self._PanelObject.SelectItem, true)
    GameUtil.SetButtonInteractable(self._PanelObject.LegendMaterialIcon, true)

    local HideGroup = self._PanelObject.HideGroup
    HideGroup.BorderBG:SetActive(true)
    HideGroup.Img_IconGroup:SetActive(true)

    if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
        local itemData = self._ItemData.ItemData
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(itemData._TalentId, itemData._TalentLevel, true)
        IconTools.SetTags(self._PanelObject.SelectItem, { [EItemIconTag.Legend] = talentInfo ~= nil and talentInfo.Name or "", })
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
---------------------------装备转化------------------------------


def.static("table", "userdata", "=>", CPageEquipLegend).new = function(parent, panel)
    local obj = CPageEquipLegend()
    obj._Parent = parent
    obj._Panel = panel
    obj:Init()

    return obj
end

def.method().Init = function(self)
    self._PanelObject = 
    {
        Group_Legend = {},
        HideGroup = {}
    }

    local root = self._PanelObject
    root.SelectItem = self._Parent:GetUIObject('SelectLegendItem')

    root.LegendMaterialIcon = self._Parent:GetUIObject("LegendMaterialIcon")
    root.LegendMaterialNeed = root.LegendMaterialIcon:FindChild("Lab_Need")

    root.Btn_Drop_Legend = self._Parent:GetUIObject("Btn_Drop_Legend")
    root.Btn_AddLegendItem = self._Parent:GetUIObject("Btn_AddLegendItem")
    root.Btn_LegendChange = self._Parent:GetUIObject('Btn_LegendChange')
    root.Btn_LegendCheckout = self._Parent:GetUIObject("Btn_LegendCheckout")

    root.Lab_None_Selection = self._Parent:GetUIObject("Lab_None_Selection")
    root.Lab_Reason = self._Parent:GetUIObject('Lab_Reason')
    root.LegendChangeTip = self._Parent:GetUIObject('LegendChangeTip')
    root.Lab_ShowTips = self._Parent:GetUIObject("Lab_ShowTips")

    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31358),
        [EnumDef.CommonBtnParam.MoneyID] = 1,
        [EnumDef.CommonBtnParam.MoneyCost] = 0   
    }
    root.CommonBtn_LegendChange = CCommonBtn.new(root.Btn_LegendChange ,setting)

    do
        local Group_Legend = root.Group_Legend
        Group_Legend.Root = self._Parent:GetUIObject("Group_Legend")
        Group_Legend.Lab_Legend = self._Parent:GetUIObject('Lab_Legend')
        Group_Legend.Lab_LegendDesc = self._Parent:GetUIObject('Lab_LegendDesc')
        Group_Legend.Lab_Legend_Lv = self._Parent:GetUIObject("Lab_Legend_Lv")
    end

    do
        -- 显示特效隐藏的组件
        local HideGroup = root.HideGroup
        HideGroup.Root = self._Parent:GetUIObject("Node_Legend")
        HideGroup.BorderBG = self._Parent:GetUIObject("Img_LegendBorderBG")
        HideGroup.Img_IconGroup = HideGroup.Root:FindChild("Img_IconGroup")
    end

    self:InitGfxGroup()
end

--------------------------------------------------------------------------------

def.method("dynamic").Show = function(self, data)
    self._Panel:SetActive(true)
    self._ItemData = nil

    if data then
        self._ItemData = data
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

-- 更新是否显示附魔界面
def.method().UpdateFrame = function(self)
    --warn("CPageEquipLegend::UpdateFrame()")
    local root = self._PanelObject
    root.Lab_Reason:SetActive( false )
    root.Lab_ShowTips:SetActive( false )
    
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
    root.Lab_None_Selection:SetActive( not bShow )
    root.Btn_Drop_Legend:SetActive( bShow )
    root.Btn_AddLegendItem:SetActive( not bShow )
    root.LegendMaterialIcon:SetActive( bShow )
    root.Group_Legend.Root:SetActive( bShow )
    root.LegendChangeTip:SetActive( bShow )

    local bShowCache = bShow and self._ItemData.ItemData:HasUnsaveEquipTalentCache()
    root.Btn_LegendChange:SetActive( not bShowCache )
    root.Btn_LegendCheckout:SetActive( bShowCache )

    if bShow then
        local itemData = self._ItemData.ItemData
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(itemData._TalentId, itemData._TalentLevel, true)
        local strLv = string.format(StringTable.Get(10641), talentInfo.Level)

        local setting = {
            [EItemIconTag.Bind] = self._ItemData.ItemData:IsBind(),
            [EItemIconTag.Legend] = talentInfo ~= nil and string.format("%s\n%s", talentInfo.Name, strLv) or "",
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
    local bShow = (self._ItemData ~= nil) and self._ItemData.ItemData:CanChangeLegendary()
    root.LegendMaterialIcon:SetActive( bShow )
    root.LegendChangeTip:SetActive( bShow )
    
    if bShow then
        local itemData = self._ItemData.ItemData
        bShow = bShow and itemData._TalentId > 0

        -- root.Lab_Reason:SetActive( not bShow )
        root.Group_Legend.Root:SetActive( bShow )
        if bShow then
            local talentInfo = CElementData.GetSkillInfoByIdAndLevel(itemData._TalentId, itemData._TalentLevel, true)
            GUI.SetText(root.Group_Legend.Lab_Legend, talentInfo.Name)
            local strLv = string.format(StringTable.Get(10641), talentInfo.Level)
            GUI.SetText(root.Group_Legend.Lab_Legend_Lv, strLv)
            GUI.SetText(root.Group_Legend.Lab_LegendDesc, talentInfo.Desc)
        else
            -- GUI.SetText(root.Lab_Reason, StringTable.Get(10937))
        end
    else
        -- GUI.SetText(root.Lab_Reason, StringTable.Get(10937))
    end
end
-- 更新材料信息
def.method().UpdateMaterialInfo = function(self)
    local root = self._PanelObject
    local bShow = (self._ItemData ~= nil and self._ItemData.ItemData:CanChangeLegendary())

    root.LegendMaterialIcon:SetActive(bShow)

    if bShow then
        local itemData = self._ItemData.ItemData
        local template = CElementData.GetTemplate('LegendaryGroup', itemData._LegendaryGroupId)
        if template == nil then return end

        local hp = game._HostPlayer
        local pack = hp._Package._NormalPack
        local MaterialId = template.CostItemId
        local MaterialNeed = template.CostItemCount
        local MaterialHave = pack:GetItemCount( MaterialId )

        IconTools.InitMaterialIconNew(root.LegendMaterialIcon, MaterialId, MaterialNeed)
        self._IsEnoughChangeMaterial = MaterialHave >= MaterialNeed
    end

    self._IsEnoughChangeMaterial = bShow and self._IsEnoughChangeMaterial
    root.CommonBtn_LegendChange:MakeGray( not self._IsEnoughChangeMaterial )
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
        root.CommonBtn_LegendChange:ResetSetting(setting)
    else
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = 0   
        }
        root.CommonBtn_LegendChange:ResetSetting(setting)
    end

    if self._ItemData == nil then
        bActive = false
    else
        local itemData = self._ItemData.ItemData
        local MaterialInfo = CEquipUtility.GetEquipChangeNeedInfo(itemData)
        bActive = bActive and MaterialInfo ~= nil and MaterialInfo.MaterialHave >= MaterialInfo.MaterialNeed 
    end

    root.CommonBtn_LegendChange:MakeGray(not bActive)
end

def.method("=>", "table").CalcMoneyNeed = function(self)
    if self._ItemData == nil then return nil end

    local itemData = self._ItemData.ItemData
    local template = CElementData.GetTemplate('LegendaryGroup', itemData._LegendaryGroupId)
    if template == nil then return nil end

    local info = CEquipUtility.GetEquipChangeMoneyNeedInfo(itemData)
    return {info[1],info[2]}
end

def.method("boolean", "=>", "boolean").CheckCanChange = function(self, bShowReason)
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
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack


    if not itemData:CanChangeLegendary() then
        ShowReason(StringTable.Get(31319))
        return false
    end
    local MaterialInfo = CEquipUtility.GetEquipChangeNeedInfo(itemData)
    if MaterialInfo == nil then
        ShowReason(StringTable.Get(31319))
        return false
    end

    if MaterialInfo.MaterialHave < MaterialInfo.MaterialNeed then
        ShowReason(StringTable.Get(31316))
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

def.method("userdata", "number", "table").OnInitItem = function(self, item, index, itemData)
    local idx = index + 1

    local Img_UnableClick = item:FindChild("Img_UnableClick")
    local ItemIconNew = item:FindChild("ItemIconNew")
    if itemData.ItemData:IsEquip() then
        local talentInfo = CElementData.GetSkillInfoByIdAndLevel(itemData.ItemData._TalentId, itemData.ItemData._TalentLevel, true)
        local strLv = string.format(StringTable.Get(10641), talentInfo.Level)
        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.Legend] = talentInfo ~= nil and string.format("%s\n%s", talentInfo.Name, strLv) or "",
            [EItemIconTag.Equip] = (itemData.PackageType == BAGTYPE.ROLE_EQUIP),
        }
        IconTools.InitItemIconNew(ItemIconNew, itemData.ItemData._Tid, setting)
        Img_UnableClick:SetActive(false)
        -- Img_UnableClick:SetActive(self._ItemData ~= nil and self._ItemData ~= itemData)
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
    --warn("CPageEquipLegend::OnClick => ", id)
    if id == "Btn_LegendChange" then
        --warn("OnClick::Btn_LegendChange")
        local CPanelUIEquipLegendResult = require "GUI.CPanelUIEquipLegendResult"
        if CPanelUIEquipLegendResult.Instance():IsShow() then
            return
        end
        
        if self:CheckCanChange(true) then
            local function Do( ret )
                if ret then
                    CEquipUtility.SendC2SItemTalentChange(self._ItemData.PackageType, self._ItemData.ItemData._Slot)
                    --转化按钮可点击状态
                    self._PanelObject.CommonBtn_LegendChange:SetInteractable(false)
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
                local title, msg, closeType = StringTable.GetMsg(114)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
            else
                DoCommonBuy()
            end
        end
    elseif id == "LegendChangeTip" then
        local itemData = self._ItemData.ItemData
        game._GUIMan:Open("CPanelUILegendLibrary", itemData)
    elseif id == "LegendMaterialIcon" then
        self:OnClickLegendMaterialIcon()
    elseif id == "SelectLegendItem" then
        if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
            local root = self._PanelObject
            CItemTipMan.ShowPackbackEquipTip(self._ItemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,root.SelectItem)
        end
    elseif id == "Btn_LegendCheckout" then
        local CPanelUIEquipLegendResult = require "GUI.CPanelUIEquipLegendResult"
        if CPanelUIEquipLegendResult.Instance():IsShow() then
            return
        end
        local itemData = self._ItemData.ItemData
        local data = 
        {
            PackageType = self._ItemData.PackageType,
            ItemData = itemData,
            ShowGfx = false
        }
        game._GUIMan:Open("CPanelUIEquipLegendResult", data)
    end
end

def.method().OnClickLegendMaterialIcon = function(self)
    local itemData = self._ItemData.ItemData
    local template = CElementData.GetTemplate('LegendaryGroup', itemData._LegendaryGroupId)
    if template == nil then return end

    local MaterialId = template.CostItemId
    CItemTipMan.ShowItemTips(MaterialId, 
                             TipsPopFrom.OTHER_PANEL, 
                             self._PanelObject.LegendMaterialIcon, 
                             TipPosition.FIX_POSITION)
end

def.method().UIProcessingLogic = function(self)
    self:DisableEvent()
    local root = self._PanelObject
    IconTools.SetTags(root.SelectItem, { [EItemIconTag.Legend] = "" })

    local delay = self._Parent._ShowGfx and self._GfxObjectGroup.DoTweenTimeDelay or 0.5
    root.Group_Legend.Root:SetActive( false )
    self._Parent:AddEvt_SetActive(gfxGroupName, delay, root.Group_Legend.Root, true)
end

def.method().DisableEvent = function(self)
    self._Parent:KillEvts(gfxGroupName)
end

def.method().Reset = function(self)
    self._ItemData = nil
    self:UpdateFrame()
end

def.method().Hide = function(self)
    self:DisableEvent()
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
        if self._PanelObject.CommonBtn_LegendChange ~= nil then
            self._PanelObject.CommonBtn_LegendChange:Destroy()
        end

        self._PanelObject = nil
    end
end

CPageEquipLegend.Commit()
return CPageEquipLegend