local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPageEquipRefine = Lplus.Class("CPageEquipRefine")
local def = CPageEquipRefine.define
local EItemType = require "PB.Template".Item.EItemType
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local BAGTYPE = require "PB.net".BAGTYPE

local CConsumeUtil = require "Utility.CConsumeUtil"
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CCommonBtn = require "GUI.CCommonBtn"

local MAX_REFINE_STAR_COUNT = 10    -- 最大星星个数

--存储UI的集合，便于OnHide()时置空
def.field("table")._PanelObject = BlankTable
def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("function")._OnMoneyChanged = nil
def.field("table")._ItemData = nil
def.field("table")._GfxObjectGroup = BlankTable
def.field("boolean")._IsEnoughRefineMaterial = false

----------------------装备精炼-----------------------

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Parent._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = 0
    root.GfxHook = nil
    root.Gfx = PATH.ETC_Refine_chenggong
end
def.method().SetGfxInfo = function(self)
    local root = self._GfxObjectGroup
    local itemData = self._ItemData.ItemData
    local lv = itemData:GetRefineLevel()

    root.TweenGroupId = lv
    root.GfxHook = self._PanelObject.Group_Refine.StarList[lv].Root
end
-- 播放特效
def.method().PlayGfx = function(self)
    self:SetGfxInfo()

    local root = self._GfxObjectGroup
    root.DoTweenPlayer:Restart(root.TweenGroupId)
    GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1)
end
-- 关闭特效
def.method().StopGfx = function(self)
    local root = self._GfxObjectGroup
    GameUtil.StopUISfx(root.Gfx, root.GfxHook)
end
---------------------------装备精炼------------------------------


def.static("table", "userdata", "=>", CPageEquipRefine).new = function(parent, panel)
    local obj = CPageEquipRefine()
    obj._Parent = parent
    obj._Panel = panel
    obj:Init()

    return obj
end

def.method().Init = function(self)
    self._PanelObject = 
    {
        Group_Refine = {},
        SuccessRateInfo = {},
        AttributeInfo = {}
    }

    local root = self._PanelObject
    root.SelectItem = self._Parent:GetUIObject('SelectRefineItem')
    root.RefineMaterialIcon = self._Parent:GetUIObject("RefineMaterialIcon")
    root.RefineMaterialNeed = root.RefineMaterialIcon:FindChild("Lab_Need")

    root.Btn_Drop_Refine = self._Parent:GetUIObject("Btn_Drop_Refine")
    root.Btn_AddRefineItem = self._Parent:GetUIObject("Btn_AddRefineItem")
    root.Btn_Refine = self._Parent:GetUIObject('Btn_Refine')
    root.Lab_None_Selection = self._Parent:GetUIObject("Lab_None_Selection")
    root.Lab_Reason = self._Parent:GetUIObject('Lab_Reason')
    root.Lab_ShowTips = self._Parent:GetUIObject("Lab_ShowTips")

    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31354),
        [EnumDef.CommonBtnParam.MoneyID] = 1,
        [EnumDef.CommonBtnParam.MoneyCost] = 0
    }
    root.CommonBtn_Refine = CCommonBtn.new(root.Btn_Refine ,setting)

    do
        local Group_Refine = root.Group_Refine
        Group_Refine.Root = self._Parent:GetUIObject("Group_Refine")
        Group_Refine.Group_Stars = self._Parent:GetUIObject("Group_Stars")
        Group_Refine.StarList = {}

        --精炼星星的集合
        for i=1, MAX_REFINE_STAR_COUNT do
            local root = self._Parent:GetUIObject("Img_Star"..i)
            local star = root:FindChild("Img_Star")
            local data = 
            {
                Root = root,
                Star = star
            }
            table.insert(Group_Refine.StarList, data)
        end
    end

    -- 成功概率信息
    do
        local SuccessRateInfo = root.SuccessRateInfo
        SuccessRateInfo.Root = self._Parent:GetUIObject('Success_Rate_Refine')
        SuccessRateInfo.Lab_Success_Rate = self._Parent:GetUIObject('Lab_Success_Rate_Refine')
    end

    -- 属性信息
    do
        local AttributeInfo = root.AttributeInfo
        AttributeInfo.Name = self._Parent:GetUIObject('Lab_RefineAttributeName')
        AttributeInfo.Old = self._Parent:GetUIObject('Lab_RefinePropertyOld')
        AttributeInfo.New = self._Parent:GetUIObject('Lab_RefinePropertyNew')
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
end

-- 更新是否显示附魔界面
def.method().UpdateFrame = function(self)
    --warn("CPageEquipRefine::UpdateFrame()")

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
    local bCanRefine = (bShow and self._ItemData.ItemData:CanRefine())
    local bShowReason = (bShow and not bCanRefine)

    root.Lab_None_Selection:SetActive( not bShow )
    root.Btn_Drop_Refine:SetActive( bShow )
    root.Btn_AddRefineItem:SetActive( not bShow )
    root.RefineMaterialIcon:SetActive( bCanRefine )
    root.Group_Refine.Root:SetActive( bCanRefine )
    root.Group_Refine.Group_Stars:SetActive( bCanRefine )

    root.Lab_Reason:SetActive( bShowReason )
    if bShowReason then
        GUI.SetText(root.Lab_Reason, StringTable.Get(31314))
    end

    if bShow then
        local setting = {
            [EItemIconTag.Bind] = self._ItemData.ItemData:IsBind(),
            [EItemIconTag.Refine] = self._ItemData.ItemData:GetRefineLevel(),
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
    local bShow = (self._ItemData ~= nil and self._ItemData.ItemData:CanRefine())

    if bShow then
        local itemData = self._ItemData.ItemData
        root.Lab_Reason:SetActive( not bShow )

        local level = itemData:GetRefineLevel()
        for i=1, MAX_REFINE_STAR_COUNT do
            local Img_Star = root.Group_Refine.StarList[i].Star
            Img_Star:SetActive( i <= level )
        end

        local materialInfo = CEquipUtility.GetRefineMaterialInfo(itemData._Template.EquipRefineTId, itemData:GetRefineLevel())
        local fightElement = CElementData.GetAttachedPropertyTemplate(itemData._BaseAttrs.ID)

        local AttributeInfo = root.AttributeInfo
        GUI.SetText(AttributeInfo.Name, fightElement.TextDisplayName)
        GUI.SetText(AttributeInfo.Old, tostring(itemData._BaseAttrs.Value + materialInfo.Old.Increase))
        if materialInfo.New == nil then
            GUI.SetText(AttributeInfo.New, StringTable.Get(10962))
        else
            GUI.SetText(AttributeInfo.New, tostring(itemData._BaseAttrs.Value + materialInfo.New.Increase))
        end
    else
        GUI.SetText(root.Lab_Reason, StringTable.Get(10960))
    end
end
-- 更新材料信息
def.method().UpdateMaterialInfo = function(self)
    local root = self._PanelObject
    local bShow = self._ItemData ~= nil
    
    root.RefineMaterialNeed:SetActive(bShow)

    if bShow then
        local itemData = self._ItemData.ItemData
        if not itemData:CanRefine() then
            return
        end

        local materialInfo = CEquipUtility.GetRefineMaterialInfo(itemData._Template.EquipRefineTId, itemData:GetRefineLevel())
        bShow = (bShow and (materialInfo ~= nil and materialInfo.New ~= nil))

        local SuccessRateInfo = root.SuccessRateInfo
        SuccessRateInfo.Root:SetActive( bShow )

        if bShow then
            GUI.SetText(SuccessRateInfo.Lab_Success_Rate, string.format(StringTable.Get(10961), materialInfo.New.Rate))
        end
        
        root.RefineMaterialIcon:SetActive( bShow )
        if bShow then
            local hp = game._HostPlayer
            local pack = hp._Package._NormalPack
            local MaterialId = materialInfo.New.MaterialId
            local MaterialNeed = materialInfo.New.MaterialNeed
            local MaterialHave = pack:GetItemCount( MaterialId )
            IconTools.InitMaterialIconNew(root.RefineMaterialIcon, MaterialId, MaterialNeed)

            self._IsEnoughRefineMaterial = MaterialHave >= MaterialNeed
        end
    end
    self._IsEnoughRefineMaterial = bShow and self._IsEnoughRefineMaterial
    root.CommonBtn_Refine:MakeGray( not self._IsEnoughRefineMaterial )
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
        root.CommonBtn_Refine:ResetSetting(setting)
        root.CommonBtn_Refine:MakeGray( moneyHave < moneyNeed or not self._IsEnoughRefineMaterial )
    else
        local setting = {
            [EnumDef.CommonBtnParam.MoneyCost] = 0   
        }
        root.CommonBtn_Refine:ResetSetting(setting)
        root.CommonBtn_Refine:MakeGray( true )
    end

    -- 刷新红点
    -- local bShowRedDot = (bActive and
    --                      self._ItemData.PackageType == BAGTYPE.ROLE_EQUIP and
    --                      CEquipUtility.CalcEquipRefineRedDotState(self._ItemData.ItemData._EquipSlot + 1))
    -- root.Img_BtnFloatFx:SetActive( false )
end

def.method("=>", "table").CalcMoneyNeed = function(self)
    if self._ItemData == nil then return nil end

    local itemData = self._ItemData.ItemData

    local materialInfo = CEquipUtility.GetRefineMaterialInfo(itemData._Template.EquipRefineTId, itemData:GetRefineLevel())
    local bShow = (materialInfo ~= nil and materialInfo.New ~= nil)

    if not bShow then return nil end

    local hp = game._HostPlayer
    local moneyId = materialInfo.New.MoneyId
    local moneyNeed = materialInfo.New.MoneyNeed

    return {moneyId,moneyNeed}
end

def.method("boolean", "=>", "boolean").CheckCanRefine = function(self, bShowReason)
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


    if not itemData:CanRefine() then
        ShowReason(StringTable.Get(31314))
        return false
    end

    local materialInfo = CEquipUtility.GetRefineMaterialInfo(itemData._Template.EquipRefineTId, itemData:GetRefineLevel())
    if materialInfo == nil or materialInfo.New == nil then
        ShowReason(StringTable.Get(31315))
        return false
    end

    local MaterialId = materialInfo.New.MaterialId
    local MaterialNeed = materialInfo.New.MaterialNeed
    local MaterialHave = pack:GetItemCount(MaterialId)
    if MaterialHave < MaterialNeed then
        ShowReason(StringTable.Get(31313))
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
        -- 刷新红点
        -- local bShowRedDot = (itemData.PackageType == BAGTYPE.ROLE_EQUIP and
        --                      CEquipUtility.CalcEquipRefineRedDotState(itemData.ItemData._EquipSlot + 1))
        local setting = {
            [EItemIconTag.Bind] = itemData.ItemData:IsBind(),
            [EItemIconTag.Refine] = itemData.ItemData:GetRefineLevel(),
            [EItemIconTag.Equip] = (itemData.PackageType == BAGTYPE.ROLE_EQUIP),
            [EItemIconTag.Grade] = itemData.ItemData:GetGrade(),
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
    else
        warn("tips?")
    end
    self:UpdateFrame()
end

def.method("string").OnClick = function(self, id)
    --warn("CPageEquipRefine::OnClick => ", id)
    if id == "Btn_Refine" then
        if self:CheckCanRefine(true) then
            local function Do( ret )
                if ret then
                    CEquipUtility.SendC2SItemRefine(self._ItemData.PackageType, self._ItemData.ItemData._Slot)
                end
            end
            local moneyNeedInfo = self:CalcMoneyNeed()
            MsgBox.ShowQuickBuyBox(moneyNeedInfo[1], moneyNeedInfo[2], Do)
        end
    elseif id == "RefineMaterialIcon" then
        self:OnClickRefineMaterialIcon()
    elseif id == "SelectRefineItem" then
        if self._ItemData ~= nil and self._ItemData.ItemData ~= nil then
            local root = self._PanelObject
            CItemTipMan.ShowPackbackEquipTip(self._ItemData.ItemData, TipsPopFrom.Equip_Process,TipPosition.FIX_POSITION,root.SelectItem)
        end
    end
end

def.method().OnClickRefineMaterialIcon = function(self)
    local itemData = self._ItemData.ItemData

    local materialInfo = CEquipUtility.GetRefineMaterialInfo(itemData._Template.EquipRefineTId, itemData:GetRefineLevel())
    local bShow = (materialInfo ~= nil and materialInfo.New ~= nil)

    if bShow then
        local MaterialId = materialInfo.New.MaterialId
        CItemTipMan.ShowItemTips(MaterialId, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 self._PanelObject.RefineMaterialIcon, 
                                 TipPosition.FIX_POSITION)
    end
end

def.method().Reset = function(self)
    self._ItemData = nil
    self:UpdateFrame()
end

def.method().Hide = function(self)
    if self._OnMoneyChanged ~= nil then
        CGame.EventManager:removeHandler('NotifyMoneyChangeEvent', self._OnMoneyChanged)
        self._OnMoneyChanged = nil
    end
    self._Panel:SetActive(false)
end

def.method().Destroy = function (self)
    if self._PanelObject ~= nil then
        if self._PanelObject.CommonBtn_Refine ~= nil then
            self._PanelObject.CommonBtn_Refine:Destroy()
        end

        self._PanelObject = nil
    end
end

CPageEquipRefine.Commit()
return CPageEquipRefine