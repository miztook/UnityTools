local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CPetUtility = require "Pet.CPetUtility"
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local PetUpdateEvent = require "Events.PetUpdateEvent"

local CPanelUIPetAptitudeReset = Lplus.Extend(CPanelBase, 'CPanelUIPetAptitudeReset')
local def = CPanelUIPetAptitudeReset.define

def.field("table")._PanelObject = BlankTable    -- 存储界面节点的集合
def.field("table")._RecastNeedInfo = nil        -- 重铸材料
def.field("table")._PetData = nil
def.field("table")._AptitudeList = BlankTable
def.field("table")._CheckBoxList = BlankTable
def.field("number")._SelectCheckBoxIndex = 1
def.field("boolean")._IsInit = false

local instance = nil
def.static('=>', CPanelUIPetAptitudeReset).Instance = function ()
    if not instance then
        instance = CPanelUIPetAptitudeReset()
        instance._PrefabPath = PATH.UI_PetAptitudeReset
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
    end

    return instance
end

--宠物信息变更
local function OnPetUpdateEvent(sender, event)
    local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
    local curType = event._Type
    local hp = game._HostPlayer
    local petPackage = hp._PetPackage

    if curType == EPetOptType.EPetOptType_confirmRecast then
        instance:InitUI()
    end
end

def.override().OnCreate = function(self)
    self._PanelObject = 
    {
        MaterialIcon = {},
        Btn_Reset = self:GetUIObject("Btn_Reset"),
    }

    self._CheckBoxList = {}
    for i=1,2 do
        self._CheckBoxList[i] = 
        {
            Root = self:GetUIObject('Chk_'..i),
            Open = self:GetUIObject('Img_Open_'..i),
            Close = self:GetUIObject('Img_Close_'..i),
            Name = self:GetUIObject('Lab_Aptitude'..i)
        }
    end

    --材料
    do
        local root = self._PanelObject.MaterialIcon
        root.Root = self:GetUIObject("MaterialIcon")
        root.Img_ItemIcon = root.Root:FindChild("Img_ItemIcon")
        root.Img_QualityBG = root.Root:FindChild("Img_QualityBG")
        root.Img_Quality = root.Root:FindChild("Img_Quality")
        root.Lab_Num = root.Root:FindChild("Lab_Num")
    end

    CGame.EventManager:addHandler(PetUpdateEvent, OnPetUpdateEvent)
end

def.override("dynamic").OnData = function(self,data)
    if instance:IsShow() then
        if data ~= nil then
            self._PetData = data
        end

        CPanelBase.OnData(self,data)
    end
    self._IsInit = true

    self._RecastNeedInfo = CPetUtility.GetRecastNeedInfo()      --材料信息
    self:InitUI()
    self:UpdateCheckbox()
    self._IsInit = false
end

def.method().InitUI = function(self)
    self:UpdateAptitude()
    self:UpdateMeterial()
end

-- 更新资质
def.method().UpdateAptitude = function(self)
    self._AptitudeList = {}
    local count = #self._PetData._AptitudeList
    for i=1, count do
        local aptitudeInfo = self._PetData._AptitudeList[i]
        if aptitudeInfo.CanReset then
            table.insert(self._AptitudeList, aptitudeInfo)
        end
    end
    
    for i=1, #self._CheckBoxList do
        local UIInfo = self._CheckBoxList[i]
        local aptitudeInfo = self._AptitudeList[i]
        local fmtNum = self._SelectCheckBoxIndex == i and 19090 or 19091
        local strName = string.format(StringTable.Get(fmtNum), aptitudeInfo.Name)
        GUI.SetText(UIInfo.Name, strName)
        if self._SelectCheckBoxIndex == i and not self._IsInit then
            local hook = UIInfo.Root
            GameUtil.PlayUISfx(PATH.UIFX_PetAptitudeReset, hook, hook, 1)
        end
    end
end

-- 更新材料信息
def.method().UpdateMeterial = function(self)
    local root = self._PanelObject.MaterialIcon
    local itemTemplate = CElementData.GetTemplate("Item", self._RecastNeedInfo[1])
    if itemTemplate == nil then return end

    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack
    local MaterialId = self._RecastNeedInfo[1]
    local MaterialHave = pack:GetItemCount(MaterialId)
    local MaterialNeed = self._RecastNeedInfo[2]
    IconTools.InitMaterialIconNew(root.Root, MaterialId, MaterialNeed)
    GUITools.SetBtnGray(self._PanelObject.Btn_Reset, MaterialNeed > MaterialHave)
end

def.method("number").SelectCheckbox = function(self, index)
    if self._SelectCheckBoxIndex == index then return end
    self._SelectCheckBoxIndex = index
    self:UpdateCheckbox()
end

-- 更新 Checkbox状态
def.method().UpdateCheckbox = function(self)
    for i=1, #self._CheckBoxList do
        local aptitudeInfo = self._AptitudeList[i]
        local checkbox = self._CheckBoxList[i]
        local bActive = self._SelectCheckBoxIndex == i
        checkbox.Open:SetActive( bActive )
        -- checkbox.Close:SetActive( not bActive )

        local fmtNum = self._SelectCheckBoxIndex == i and 19090 or 19091
        local strName = string.format(StringTable.Get(fmtNum), aptitudeInfo.Name)
        GUI.SetText(checkbox.Name, strName)
    end
end

def.override('string').OnClick = function(self, id)
    if id == 'Btn_Reset' then
        local aptitudeId = self._AptitudeList[self._SelectCheckBoxIndex].ID
        CPetUtility.SendC2SPetRecast(self._PetData._ID, aptitudeId)
        -- game._GUIMan:CloseByScript(self)
    elseif id == 'Btn_No' then
        game._GUIMan:CloseByScript(self)
    elseif string.find(id, "Img_Close_") then
        local index = tonumber(string.sub(id, -1))
        self:SelectCheckbox(index)
    elseif id == "MaterialIcon" then
        local hp = game._HostPlayer
        local pack = hp._Package._NormalPack
        if self._RecastNeedInfo and self._RecastNeedInfo[1] then
            local itemTid = self._RecastNeedInfo[1]
            local itemData = CIvtrItem.CreateVirtualItem(itemTid)
            if itemData ~= nil then
                local obj = self._PanelObject.MaterialIcon.Root
                itemData:ShowTip(TipPosition.FIX_POSITION, obj)
            end
        end
    end
    CPanelBase.OnClick(self, id)
end

def.override().OnHide = function(self)
    CPanelBase.OnHide(self)
end

def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)
    instance = nil
end

CPanelUIPetAptitudeReset.Commit()
return CPanelUIPetAptitudeReset