--宠物洗练
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetRecast = Lplus.Class("CPagePetRecast")
local def = CPagePetRecast.define

local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local CElementData = require "Data.CElementData"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local PackageChangeEvent = require "Events.PackageChangeEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CPetUtility = require "Pet.CPetUtility"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil       -- 存放UI的集合
def.field("table")._PetData = nil           -- 当前选中的Pet数据
def.field("table")._RecastNeedInfo = nil    -- 重铸材料

local function SendFlashMsg(msg, bUp)
    game._GUIMan:ShowTipText(msg, bUp)
end

local instance = nil
def.static("table", "userdata", "=>", CPagePetRecast).new = function(parent, panel)
    if instance == nil then
        instance = CPagePetRecast()
        instance._Parent = parent
        instance._Panel = panel
    end
    
    return instance
end

def.method().InitPanel = function(self)
    local CPetUtility = require "Pet.CPetUtility"
    local MaxAptitudeCount = CPetUtility.GetMaxAptitudeCount()  --资质最大个数
    self._RecastNeedInfo = CPetUtility.GetRecastNeedInfo()      --材料信息

    self._PanelObject = {
        AptitudeList = {},
        RecastNeed = {},
        Group_RecastStar = {},
        -- Lab_RecastCountLeft = self._Parent:GetUIObject('Lab_RecastCountLeft'),
        -- Img_BtnFloatFx = self._Parent:GetUIObject("Btn_Recast"):FindChild("Img_Bg/Img_BtnFloatFx"),
        -- Btn_Recast = self._Parent:GetUIObject("Btn_Recast"),
    }

    --资质
    for i=1, MaxAptitudeCount do
        local aptitude = {}
        aptitude.Root = self._Parent:GetUIObject('Frame_Recast_Aptitude'..i)
        aptitude.Lab_Aptitude = aptitude.Root:FindChild('Lab_Aptitude')
        aptitude.Lab_Value = aptitude.Root:FindChild('Lab_Value')
        aptitude.Lab_RandomValue = aptitude.Root:FindChild('Lab_RandomValue')

        table.insert(self._PanelObject.AptitudeList, aptitude)
    end

    --材料
    do
        local root = self._PanelObject.RecastNeed
        root.Root = self._Parent:GetUIObject("RecastNeed")
        root.GfxHook = root.Root:FindChild("GfxHook")
        root.Img_ItemIcon = root.Root:FindChild("Img_ItemIcon")
        root.Img_QualityBG = root.Root:FindChild("Img_QualityBG")
        root.Img_Quality = root.Root:FindChild("Img_Quality")
        root.Lab_Num = root.Root:FindChild("Lab_Num")
    end

    -- 星级类型
    do
        local root = self._PanelObject.Group_RecastStar
        root.Lab_Type = self._Parent:GetUIObject('Lab_RecastType')
        root.Frame_Star = self._Parent:GetUIObject('Frame_RecastStar')
        root.Img_Type = self._Parent:GetUIObject('Img_RecastType')
    end
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end

    if EPetOptType.EPetOptType_recast == event._Type or EPetOptType.EPetOptType_confirmRecast == event._Type then
        instance:UpdateAptitude()
    end
end

local OnPackageChangeEvent = function(sender, event)
    if instance == nil then return end

    instance:UpdateMeterial()
end

def.method("dynamic").Show = function(self, data)
    if self._PanelObject == nil then
        self:InitPanel()
    end

    self._Panel:SetActive(data ~= nil)

    if data ~= nil then
        self:UpdateSelectPet(data)
    end

    CGame.EventManager:addHandler(PetUpdateEvent, OnPetUpdateEvent)
    CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent)
end

def.method("table").UpdateSelectPet = function(self, data)
    self._Panel:SetActive(data ~= nil)
    self._PetData = data
    if self._PetData == nil then return end
    
    self:UpdatePanel()
end

def.method().UpdateAptitude = function(self)
    --资质
    local root = self._PanelObject.AptitudeList
    -- warn("=========================>>> ", #self._PetData._AptitudeList)
    for i=1, #self._PetData._AptitudeList do
        local aptitudeInfo = self._PetData._AptitudeList[i]
        local UIInfo = root[i]
        local curValue = tostring(aptitudeInfo.Value)
        -- if tonumber(aptitudeInfo.Value) == tonumber(aptitudeInfo.MaxValue) then
        --     curValue = string.format("%s %s", curValue, StringTable.Get(19077))
        -- end
        
        GUI.SetText(UIInfo.Lab_Aptitude, aptitudeInfo.Name)
        GUI.SetText(UIInfo.Lab_Value, tostring(curValue))
        GUI.SetText(UIInfo.Lab_RandomValue, string.format(StringTable.Get(19084),aptitudeInfo.MinValue, aptitudeInfo.MaxValue))
        -- UIInfo.Sld.value = math.clamp(aptitudeInfo.Value/aptitudeInfo.MaxValue, 0, 1)
    end

    -- GUI.SetText(self._PanelObject.Lab_RecastCountLeft, tostring(self._PetData._RecastCount))
    -- GUITools.SetBtnGray(self._PanelObject.Btn_Recast, self._PetData._RecastCount <= 0)
end

def.method().UpdateMeterial = function(self)
    local root = self._PanelObject.RecastNeed
    local itemTemplate = CElementData.GetTemplate("Item", self._RecastNeedInfo[1])
    if itemTemplate == nil then return end

    do
        local hp = game._HostPlayer
        local pack = hp._Package._NormalPack
        local MaterialHave = pack:GetItemCount(self._RecastNeedInfo[1])
        local MaterialNeed = self._RecastNeedInfo[2]
        -- GUITools.SetBtnGray(self._PanelObject.Btn_Recast, MaterialHave < MaterialNeed or self._PetData._RecastCount <= 0)
    end
    IconTools.InitMaterialIconNew(root.Root, self._RecastNeedInfo[1], 1)
end

def.method().UpdatePanel = function(self)
    self:UpdateAptitude()
    self:UpdateMeterial()
    self:UpdateInfo()
    -- self:UpdateRedDotState()
end

def.method().DoBtnReset = function(self)
    local info = CPetUtility.GetPetResetRecastCountItem()
    local MaterialId = info[1]
    local hp = game._HostPlayer
    local pack = hp._Package._NormalPack

    local MaterialHave = pack:GetItemCount( MaterialId )
    local MaterialNeed = info[2]

    if MaterialHave < MaterialNeed then
        local template = CElementData.GetTemplate("Item", MaterialId)
        local str = string.format(StringTable.Get(19060), MaterialNeed, template.TextDisplayName)
        SendFlashMsg(str, false)
    else
        CPetUtility.SendC2SPetResetRecastCount( self._PetData._ID )
    end
end

def.method("string").OnClick = function(self, id)
    if id == "RecastNeed" then
        local hp = game._HostPlayer
        local pack = hp._Package._NormalPack
        if self._RecastNeedInfo and self._RecastNeedInfo[1] then
            local itemTid = self._RecastNeedInfo[1]
            local itemData = CIvtrItem.CreateVirtualItem(itemTid)
            if itemData ~= nil then
                local obj = self._PanelObject.RecastNeed.Root
                itemData:ShowTip(TipPosition.FIX_POSITION, obj)
            end
        end
    -- elseif id == "Btn_Recast" then
    --     CPetUtility.SendC2SPetRecast(self._PetData._ID)
    elseif id == "Btn_Reset" then
        local function SendC2SPetRecast()
            CPetUtility.SendC2SPetRecast(self._PetData._ID)
            local root = self._PanelObject.RecastNeed
            GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, root.GfxHook, root.GfxHook, 1, 20, 1)
        end

        --self:DoBtnReset()
        if self._PetData._Stage > 0 then
            game._GUIMan:Open("CPanelUIPetResetRecastCntCost", {data = self._PetData, callback = SendC2SPetRecast})
        else
            local info = CPetUtility.GetRecastNeedInfo()
            local MaterialId = info[1]
            local hp = game._HostPlayer
            local pack = hp._Package._NormalPack

            local MaterialHave = pack:GetItemCount( MaterialId )
            local MaterialNeed = info[2]
            local EnoughMaterial = (MaterialHave >= MaterialNeed) 
            if EnoughMaterial then
                -- CPetUtility.SendC2SPetResetRecastCount( self._PetData._ID )
                SendC2SPetRecast()
            else
                SendFlashMsg(StringTable.Get(10901), false)
            end
        end
    end
end

-- 刷新红点状态
-- def.method().UpdateRedDotState = function(self)
    -- local bShow = CPetUtility.CalcPetRecastRedDotState( self._PetData )
    -- self._PanelObject.Img_BtnFloatFx:SetActive( bShow )
-- end


-- 星级和类型
def.method().UpdateInfo = function(self)
    local root = self._PanelObject.Group_RecastStar
    GUI.SetText(root.Lab_Type,StringTable.Get(19022 + self._PetData._Genus))
    GUITools.SetGroupImg(root.Img_Type,self._PetData._Genus)
    local FrameStar = root.Frame_Star
    for i = 1, 5 do
        if i <= self._PetData._Stage  and i <= self._PetData._MaxStage then 
            local imgStar = FrameStar:FindChild("Img_Star"..i)
            imgStar:SetActive(true)
            GUITools.SetGroupImg(imgStar,0)
        elseif i > self._PetData._Stage  and i <= self._PetData._MaxStage then 
            local imgStar = FrameStar:FindChild("Img_Star"..i)
            imgStar:SetActive(true)
            GUITools.SetGroupImg(imgStar,1)
        elseif i >self._PetData._MaxStage then 
            local imgStar = FrameStar:FindChild("Img_Star"..i)
            imgStar:SetActive(false)
        end
    end
end


def.method().Hide = function(self)
    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)

    self._PanelObject = nil
    self._PetData = nil
    self._Panel:SetActive(false)
end

def.method().Destroy = function (self)
    instance = nil
end

CPagePetRecast.Commit()
return CPagePetRecast