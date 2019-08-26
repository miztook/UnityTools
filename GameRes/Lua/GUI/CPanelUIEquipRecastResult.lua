local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CEquipUtility = require "EquipProcessing.CEquipUtility"
local BAGTYPE = require "PB.net".BAGTYPE

local CPanelUIEquipRecastResult = Lplus.Extend(CPanelBase, 'CPanelUIEquipRecastResult')
local def = CPanelUIEquipRecastResult.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._ItemData = nil
def.field("number")._PackageType = 0
def.field("boolean")._ShowGfx = true
def.field("function")._OnMoneyChanged = nil
----------------------------------------------------------------------------------
--                                特效处理 Begin
----------------------------------------------------------------------------------
def.field("table")._GfxObjectGroup = nil
local gfxGroupName = "RecastResult"

-- 初始化 需要用到的 组件和位置信息
def.method().InitGfxGroup = function(self)
    if self._GfxObjectGroup ~= nil then
        self:StopGfx()
        self:StopGfxBg()
    end

    self._GfxObjectGroup = {}
    local root = self._GfxObjectGroup

    root.DoTweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer)
    root.TweenGroupId = "2"
    root.DoTweenTimeDelay = 1.8
    root.TweenObjectHook = self:GetUIObject("SelectItem")
    root.OrignPosition = root.TweenObjectHook.localPosition
    root.OrignScale = root.TweenObjectHook.localScale
    root.TweenTimerId = 0

    root.GfxHook = self._Panel
    root.GfxTimeDelay = 0
    root.Gfx = PATH.ETC_Recast_juqi
    root.GfxTimerId = 0

    root.bgPanel = self:GetUIObject("Img_PanelBG")

    root.GfxBgHook1 = self:GetUIObject("SelectItem")
    root.GfxBgHook2 = self._Panel

    root.GfxBg1 = PATH.ETC_Fortify_Success_BG1
    root.GfxBg2 = PATH.ETC_Fortify_Success_BG2
end

-- 播放背景特效
def.method().PlayGfxBg = function(self)
    local root = self._GfxObjectGroup
    if root~=nil then
        self:AddEvt_PlayFx(gfxGroupName, self._ShowGfx and 1.8 or 0, root.GfxBg1, root.GfxBgHook1, root.GfxBgHook1, -1, 1)
        self:AddEvt_PlayFx(gfxGroupName, self._ShowGfx and 1.8 or 0, root.GfxBg2, root.GfxBgHook2, root.GfxBgHook2, -1, 1)
    end
end
-- 关闭背景特效
def.method().StopGfxBg = function(self)
    self:KillEvts(gfxGroupName)
end
-- 播放特效
def.method().PlayGfx = function(self)
    local root = self._GfxObjectGroup
    if root~=nil then
        if self._ShowGfx then
            GameUtil.PlayUISfx(root.Gfx, root.GfxHook, root.GfxHook, -1, 20 , 3)
        end
        self:AddEvt_SetActive(gfxGroupName, self._ShowGfx and 1.8 or 0, root.bgPanel, true)
        self:AddEvt_PlayDotween(gfxGroupName, self._ShowGfx and 1.8 or 0, root.DoTweenPlayer, root.TweenGroupId)
        self:AddEvt_Shake(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 0.5, 15, 0.05)
    end
end
-- 关闭特效
def.method().StopGfx = function(self)
    local root = self._GfxObjectGroup
    GameUtil.StopUISfx(root.Gfx, root.GfxHook)
end
-- 重置 组件和位置信息
def.method().ResetGfxGroup = function(self)
    local root = self._GfxObjectGroup
    if root~=nil then
        root.GfxHook.localPosition = root.OrignPosition
    end
end

def.method().GfxLogic = function(self)
    local root = self._GfxObjectGroup

    if root~=nil then
        root.bgPanel:SetActive( false )
        self:PlayGfx()
    end
end

----------------------------------------------------------------------------------
--                                特效处理 End
----------------------------------------------------------------------------------

local instance = nil
def.static('=>', CPanelUIEquipRecastResult).Instance = function ()
    if not instance then
        instance = CPanelUIEquipRecastResult()
        instance._PrefabPath = PATH.UI_EquipRecastResult
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

local function PlayAudio()
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Succees, 0)
end
local function BtnActive()
    instance._PanelObject.Btn_Save:SetActive(true)
    instance._PanelObject.Btn_Cancel:SetActive(true)
    instance._PanelObject.Btn_RecastAgain:SetActive(true)
    instance:UpdateBtnRecastState()
end

def.override().OnCreate = function(self)
    self._PanelObject = 
    {
        SelectItem = self:GetUIObject('SelectItem'),
        Img_UpOrDown = self:GetUIObject('Img_UpOrDown'),
        Lab_AddValue = self:GetUIObject('Lab_AddValue'),
        Btn_RecastAgain = self:GetUIObject("Btn_RecastAgain"),
        Btn_Save = self:GetUIObject('Btn_Save'),
        Btn_Cancel = self:GetUIObject('Btn_Cancel'),

        ItemGroupNew = {},
        ItemGroupOld = {},
        FightScoreNew = {},
        FightScoreOld = {},
    }

    do
        local ItemGroupNew = self._PanelObject.ItemGroupNew
        ItemGroupNew.Root = self:GetUIObject('Frame_NewProperty')
        ItemGroupNew.ItemList = {}
        table.insert(ItemGroupNew.ItemList, ItemGroupNew.Root:FindChild("item"))
    end

    do
        local ItemGroupOld = self._PanelObject.ItemGroupOld
        ItemGroupOld.Root = self:GetUIObject('Frame_OldProperty')
        ItemGroupOld.ItemList = {}
        table.insert(ItemGroupOld.ItemList, ItemGroupOld.Root:FindChild("item"))
    end

    do
        local FightScoreNew = self._PanelObject.FightScoreNew
        FightScoreNew.Root = self:GetUIObject('FightScoreRight')
        FightScoreNew.Value = FightScoreNew.Root:FindChild("Lab_FightScore")
    end

    do
        local FightScoreOld = self._PanelObject.FightScoreOld
        FightScoreOld.Root = self:GetUIObject('FightScoreLeft')
        FightScoreOld.Value = FightScoreOld.Root:FindChild("Lab_FightScore")
    end
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._PackageType = data.PackageType
            self._ItemData = data.ItemData
            self._ShowGfx = data.ShowGfx
        end

        CPanelBase.OnData(self,data)
    end

    -- 初始化特效所需组件信息
    self:InitGfxGroup()
    -- 更新UI组件
    self:UpdateUI()
    -- 特效逻辑
    self:GfxLogic()
    -- 播放背景特效
    self:PlayGfxBg()
    self:AddEvt_LuaCB(gfxGroupName, self._ShowGfx and 1.8 or 0, PlayAudio)

    local root = self._PanelObject
    root.Btn_Save:SetActive(false)
    root.Btn_Cancel:SetActive(false)
    root.Btn_RecastAgain:SetActive(false)
    self:AddEvt_LuaCB(gfxGroupName, (self._ShowGfx and 1.8 or 0) + 0.65, BtnActive)
end

def.method().UpdateUI = function(self)
    local root = self._PanelObject

    local setting =
    {
        [EItemIconTag.StrengthLv] = self._ItemData:GetInforceLevel(),
        [EItemIconTag.Bind] = self._ItemData:IsBind(),
        [EItemIconTag.Grade] = self._ItemData:GetGrade(),
    }
    IconTools.InitItemIconNew(root.SelectItem, self._ItemData._Tid, setting)

    --设置
    self:UpdateNewProperty()
    self:UpdateOldProperty()
    self:UpdateFightScoreBoard(true)
    self:UpdateFightScoreBoard(false)
    self:UpdateFightScoreIncreaseBoard()
    self:UpdateBtnRecastState()
end

def.method().UpdateBtnRecastState = function(self)
    local bCanRecast = self:CheckCanRecast()
    GUITools.SetBtnGray(self._PanelObject.Btn_RecastAgain, not bCanRecast)
end

--更新战斗力
def.method("boolean").UpdateFightScoreBoard = function(self, bIsNewProperty)
    local info

    if bIsNewProperty then
        info = self._PanelObject.FightScoreNew
    else
        info = self._PanelObject.FightScoreOld
    end

    local socre = self:CalcFightScore(bIsNewProperty)
    GUI.SetText(info.Value, GUITools.FormatNumber(socre))
end
--更新 上下箭头和战斗力提高数值
def.method().UpdateFightScoreIncreaseBoard = function(self)
    local oldVal = self:CalcFightScore(false)
    local newVal = self:CalcFightScore(true)

    local incVal = newVal - oldVal
    local root = self._PanelObject

    root.Img_UpOrDown:SetActive(incVal ~= 0)
    root.Lab_AddValue:SetActive(incVal ~= 0)

    if incVal ~= 0 then
        local processStatus = incVal > 0 and EnumDef.EquipProcessStatus.Success or EnumDef.EquipProcessStatus.Failed
        GUI.SetText(root.Lab_AddValue, RichTextTools.GetEquipProcessColorText(GUITools.FormatNumber(incVal), processStatus))
        GUITools.SetGroupImg(root.Img_UpOrDown, incVal > 0 and 1 or 0)
    end
end
--计算战斗力
def.method("boolean", "=>", "number").CalcFightScore = function(self, bIsNewProperty)
    local CIvtrEquip = require "Package.CIvtrItems".CIvtrEquip

    local result = 0
    local info = {}
    local attrs = nil
    if bIsNewProperty then
        attrs = self._ItemData._EquipBaseAttrsCache
    else
        attrs = self._ItemData._EquipBaseAttrs
    end
    
    local result = 0
    for i,v in ipairs( attrs ) do
        result = result + CIvtrEquip.GetFightPropertyFightScore(v.index, v.value)
    end

    return result
end
--更新新属性
def.method().UpdateNewProperty = function(self)
    local itemData = self._ItemData

    local function SetCellInfo(idx, attr)
        local item = self:GetPropertyItem(idx, true)
        item:SetActive(true)

        local attrId = attr.index
        local attrValue = attr.value
        local attrStar = attr.star
        local attrMaxValue = attr.MaxStarValue

        local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate( attrId )
        local fightPropertyId = attachPropertGenerator.FightPropertyId
        local fightElement = CElementData.GetAttachedPropertyTemplate(fightPropertyId)

        local Lab_AttriTipsOld = item:FindChild("Lab_AttriTips")
        local Lab_AttriValuesOld = item:FindChild("Sld_Attr/Lab_AttriValues")

        local strValue = string.format("%s / %s", attrValue, attrMaxValue)
        GUI.SetText(Lab_AttriValuesOld, strValue)
        GUI.SetText(Lab_AttriTipsOld, fightElement.TextDisplayName)
        --GUI.SetText(Lab_AttriTipsOld, RichTextTools.GetAttrColorText(fightElement.TextDisplayName, attrStar))

        local Sld_Attr = item:FindChild("Sld_Attr")
        local val = attrValue/attrMaxValue
        Sld_Attr:GetComponent(ClassType.Slider).value = val
        --GUITools.DoSlider(Sld_Attr, val, 0.5, nil, nil)

        local Img_Recommend = item:FindChild("Img_Recommend")
        Img_Recommend:SetActive(self._ItemData:IsRecommendProperty(fightPropertyId))
    end
   
    self:DisablePropertyItem(true)
    --设置
    for i,v in ipairs(itemData._EquipBaseAttrsCache) do
        SetCellInfo(i, v)
    end
end
--更新旧属性
def.method().UpdateOldProperty = function(self)
    local itemData = self._ItemData

    local function SetCellInfo(idx, attr)
        local item = self:GetPropertyItem(idx, false)
        item:SetActive(true)

        local attrId = attr.index
        local attrValue = attr.value
        local attrStar = attr.star
        local attrMaxValue = attr.MaxStarValue

        local attachPropertGenerator = CElementData.GetAttachedPropertyGeneratorTemplate( attrId )
        local fightPropertyId = attachPropertGenerator.FightPropertyId
        local fightElement = CElementData.GetAttachedPropertyTemplate(fightPropertyId)

        local Lab_AttriTipsOld = item:FindChild("Lab_AttriTips")
        local Lab_AttriValuesOld = item:FindChild("Sld_Attr/Lab_AttriValues")

        local strValue = string.format("%s / %s", attrValue, attrMaxValue)
        GUI.SetText(Lab_AttriValuesOld, strValue)
        GUI.SetText(Lab_AttriTipsOld, fightElement.TextDisplayName)
        --GUI.SetText(Lab_AttriTipsOld, RichTextTools.GetAttrColorText(fightElement.TextDisplayName, attrStar))

        local Sld_Attr = item:FindChild("Sld_Attr")
        Sld_Attr:GetComponent(ClassType.Slider).value = 0
        local val = attrValue/attrMaxValue
        GUITools.DoSlider(Sld_Attr, val, 0.5, nil, nil)

        local Img_Recommend = item:FindChild("Img_Recommend")
        Img_Recommend:SetActive(self._ItemData:IsRecommendProperty(fightPropertyId))
    end
   
    self:DisablePropertyItem(true)
    --设置
    for i,v in ipairs(itemData._EquipBaseAttrs) do
        SetCellInfo(i, v)
    end
end

--获取旧属性item组件，动态创建，自行维护
def.method("number", "boolean","=>", "userdata").GetPropertyItem = function(self, index, bIsNewItem)
    local info = nil
    if bIsNewItem then
        info = self._PanelObject.ItemGroupNew.ItemList
    else
        info = self._PanelObject.ItemGroupOld.ItemList
    end
    if index > #info then
        local itemNew = GameObject.Instantiate(info[1])
        table.insert(info, itemNew)
        itemNew:SetParent(info[1].parent, false)
    end

    return info[index]
end

def.method("boolean").DisablePropertyItem = function(self, bIsNewItem)
    local info = nil
    if bIsNewItem then
        info = self._PanelObject.ItemGroupNew
    else
        info = self._PanelObject.ItemGroupOld
    end

    for i=1, #info do
        info[i]:SetActive(false)
    end
end

def.method("=>","boolean").CheckCanRecast = function(self)
    local bRet = false
    local RecastNeedInfo = CEquipUtility.GetEquipRecastNeedInfo(self._ItemData)
    bRet = RecastNeedInfo.MaterialHave >= RecastNeedInfo.MaterialNeed
    if bRet then
        local hp = game._HostPlayer

        local MoneyNeedInfo = CEquipUtility.GetEquipRecastMoneyNeedInfo(self._ItemData)
        local moneyHave = hp:GetMoneyCountByType(MoneyNeedInfo[1])
        local moneyNeed = MoneyNeedInfo[2]
        bRet = bRet and (moneyHave >= moneyNeed)
    end

    return bRet
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Save' then
        local function Do()
            CEquipUtility.SendC2SItemRebuildConfirm(self._PackageType, self._ItemData._Slot, true)
        end
        local function Cancel()
            CEquipUtility.SendC2SItemRebuildConfirm(self._PackageType, self._ItemData._Slot, false)
        end
        local function callback( ret )
            if ret then
                Do()
            else
                Cancel()
            end
        end

        if self._ItemData:HasSurmount() then
            local title, msg, closeType = StringTable.GetMsg(90)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)    
        elseif self._ItemData:HasQuench() then
            local title, msg, closeType = StringTable.GetMsg(91)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
        else
            Do()
        end

        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_Cancel' then
        CEquipUtility.SendC2SItemRebuildConfirm(self._PackageType, self._ItemData._Slot, false)
        game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_RecastAgain' then
        self:OnClickRecast()
    end
    CPanelBase.OnClick(self, id)
end

def.method().OnClickRecast = function(self)
    local function Do( ret )
        if ret then
            CEquipUtility.SendC2SItemRebuild(self._PackageType, self._ItemData._Slot)
        end
    end

    local MoneyNeedInfo = CEquipUtility.GetEquipRecastMoneyNeedInfo(self._ItemData)
    MsgBox.ShowQuickBuyBox(MoneyNeedInfo[1], MoneyNeedInfo[2], Do)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    self:StopGfx()
    self:StopGfxBg()
    self._GfxObjectGroup = nil
    instance = nil
end

CPanelUIEquipRecastResult.Commit()
return CPanelUIEquipRecastResult