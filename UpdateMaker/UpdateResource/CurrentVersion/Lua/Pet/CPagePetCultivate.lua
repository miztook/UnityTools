--宠物培养

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CPagePetCultivate = Lplus.Class("CPagePetCultivate")
local def = CPagePetCultivate.define

local CElementData = require "Data.CElementData"
local PetUpdateEvent = require "Events.PetUpdateEvent"
local PackageChangeEvent = require "Events.PackageChangeEvent"
local EPetOptType = require "PB.net".S2CPetUpdate.EPetOptType
local CPetUtility = require "Pet.CPetUtility"

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("table")._PanelObject = nil   -- 存放UI的集合
def.field("table")._PetData = nil       -- 当前选中的Pet数据
def.field("table")._MedicineList = nil  -- 宠物经验药物
def.field("number")._TimerID = 0        -- timer
def.field("boolean")._CanNotifyOnClick = true
def.field("number")._SelectMaterialIndex = 1
def.field("boolean")._Inited = false

local instance = nil
def.static("table", "userdata", "=>", CPagePetCultivate).new = function(parent, panel)
    if instance == nil then
        instance = CPagePetCultivate()
        instance._Parent = parent
        instance._Panel = panel
    end

    return instance
end

def.method().InitPanel = function(self)
    local CPetUtility = require "Pet.CPetUtility"
    local MaxPropertyCount = CPetUtility.GetMaxPropertyCount()   --属性最大个数
    local index_s = 0

    self._PanelObject = {
        PropertyList = {},
        Group_CultivateLevelInfo = {},
        Btn_Feed_Once = self._Parent:GetUIObject("Btn_Feed_Once"),
        Btn_Feed_Several = self._Parent:GetUIObject("Btn_Feed_Several"),
        DotweenPlayer = self._Panel:GetComponent(ClassType.DOTweenPlayer),
    }

    --属性
    for i=1, MaxPropertyCount do
        local property = {}
        property.Root = self._Parent:GetUIObject('Frame_Cultivate_Property'..i)
        property.Lab_Property = property.Root:FindChild("Lab_Property")
        property.Lab_OldValue = property.Root:FindChild("Lab_OldValue")
        property.Lab_NewValue = property.Root:FindChild("Lab_NewValue")
        property.Img_CanReset = property.Root:FindChild("Img_CanReset")

        table.insert(self._PanelObject.PropertyList, property)
    end

    do
        local root = self._PanelObject.Group_CultivateLevelInfo
        local sld = self._Parent:GetUIObject('Frame_Cultivate_Sld_Exp')
        root.GfxHook = sld:FindChild("Fill Area")
        root.Sld = sld:GetComponent(ClassType.Slider)
        root.Value = sld:FindChild("Lab_Value")
    end

    do
        --药物
        self._MedicineList = {}
        local petExpMedicineList = CPetUtility.GetPetExpMedicineList()
        local normalPack = game._HostPlayer._Package._NormalPack
        for i,tid in ipairs(petExpMedicineList) do
            --local tid = tonumber(v)
            local itemTemplate = CElementData.GetTemplate("Item", tid)
            if itemTemplate ~= nil then
                local Medicine = {}
                Medicine.Tid = tid
                Medicine.Template = itemTemplate
                Medicine.AddExp = itemTemplate.PetItemExp
                Medicine.Obj = self._Parent:GetUIObject("Medicine"..i)
                Medicine.GfxHook = Medicine.Obj:FindChild("GfxHook")

                Medicine.SelectObj = Medicine.Obj:FindChild("Img_Tag_Selected")
                GameUtil.SetButtonInteractable(Medicine.Obj, true)
                table.insert(self._MedicineList, Medicine)
            end
            local materialHave = normalPack:GetItemCount(tid)
            if index_s == 0 and materialHave > 0 then
                index_s = i
            end
        end
    end

    self._SelectMaterialIndex = (index_s == 0 and 1 or index_s)
end

local OnPetUpdateEvent = function(sender, event)
    if instance == nil then return end

    if EPetOptType.EPetOptType_exp == event._Type then
        instance:UpdateExp()
        instance:UpdateSelectMaterial()
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Pet_Eating, 0)
    elseif EPetOptType.EPetOptType_levelup == event._Type then
        instance:UpdateExp()
        instance:UpdateProperty()
        instance:UpdateSelectMaterial()
    end
end

local OnPackageChangeEvent = function(sender, event)
    if instance == nil then return end

    instance:UpdateMedicine()
end

def.method("dynamic").Show = function(self, data)
    self._PetData = data
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

--更新属性
def.method().UpdateProperty = function(self)
    --warn("UpdatePanel 属性")
    --属性
    local root = self._PanelObject.PropertyList
    for i=1, #self._PetData._PropertyList do
        local propertyInfo = self._PetData._PropertyList[i]
        local Aptitude = self._PetData:GetAptitudeInfoByPropertyId(propertyInfo.ID)
        local coefficient = CPetUtility.GetPetAptitudeIncFixCoefficientById(Aptitude.FightPropertyId)

        local UIInfo = root[i]

        local val = Aptitude.Value * coefficient
        local addValue = math.ceil( math.clamp(val, 1, val) )
        local oldVal = math.ceil(propertyInfo.Value)

        GUI.SetText(UIInfo.Lab_Property, propertyInfo.Name)
        GUI.SetText(UIInfo.Lab_OldValue, GUITools.FormatNumber(oldVal))
        GUI.SetText(UIInfo.Lab_NewValue, GUITools.FormatNumber(oldVal + addValue))
        UIInfo.Img_CanReset:SetActive( Aptitude.CanReset ) 
    end
end

def.method().UpdateExp = function(self)
    local root = self._PanelObject.Group_CultivateLevelInfo

    if self._PetData._MaxExp == 0 then
        root.Sld.value = 1
        GUI.SetText(root.Value, StringTable.Get(19008))
    else
        root.Sld.value = math.clamp(self._PetData._Exp/self._PetData._MaxExp, 0, 1)
        GUI.SetText(root.Value, string.format(StringTable.Get(19069), self._PetData._Exp, self._PetData._MaxExp))
    end
end

def.method().UpdatePanel = function(self)
    self:UpdateProperty()
    self:UpdateExp()
    self:UpdateMedicine()
    self:UpdateSelectMaterial()

    self._Inited = true
end

local function SetMedicineItem(Medicine)
    local item = Medicine.Obj
    if instance._Inited then
        IconTools.SetMaterialNum(item:FindChild("MaterialIcon"), Medicine.Tid, 1)
    else
        IconTools.InitMaterialIconNew(item:FindChild("MaterialIcon"), Medicine.Tid, 1)
        local str = string.format( StringTable.Get(19108), GUITools.FormatNumber(Medicine.AddExp))
        GUI.SetText(item:FindChild("Lab_EXP"), str)
    end
end

local function CheckCount(self, medicineTid, count)
    local normalPack = game._HostPlayer._Package._NormalPack
    local materialHave = normalPack:GetItemCount( medicineTid )

    return materialHave >= count
end

local function IsPetLevelTooHigh(self)
    return self._PetData._Level >= game._HostPlayer._InfoData._Level
end

local function UseMedicine(self, medicineTid, count, isIgnoreCount)
    if isIgnoreCount then
        local normalPack = game._HostPlayer._Package._NormalPack
        local have_count = normalPack:GetItemCount( medicineTid )
        if have_count <= 0 then
            if not CheckCount(self, medicineTid, count) then
                TeraFuncs.SendFlashMsg( StringTable.Get(932) )
                return
            end
        else
            if have_count >= count then
                CPetUtility.SendC2SPetLevelUp(self._PetData._ID, medicineTid, count)
            else
                CPetUtility.SendC2SPetLevelUp(self._PetData._ID, medicineTid, have_count)
            end

            self:ShowFeedGfx()
        end
    else
        if not CheckCount(self, medicineTid, count) then
            TeraFuncs.SendFlashMsg( StringTable.Get(932) )
            return
        end
    
        CPetUtility.SendC2SPetLevelUp(self._PetData._ID, medicineTid, count)
        self:ShowFeedGfx()
    end
    
end

def.method("=>", "boolean").CheckCanFeed = function(self)
    local bRet = true
    if self._PetData._Level >= game._HostPlayer._InfoData._Level then
        TeraFuncs.SendFlashMsg( StringTable.Get(19082) )
        bRet = false
    end

    return bRet
end

def.method().ShowFeedGfx = function(self)
    local medicine = self._MedicineList[self._SelectMaterialIndex]

    if medicine ~= nil then
    --[[
        -- kill dotween
        GUITools.DoKill(medicine.GfxHook)
        -- reset position
        medicine.GfxHook.localPosition = Vector3.zero
        -- Hook active
        medicine.GfxHook:SetActive(true)
        -- add gfx
        GameUtil.PlayUISfx(PATH.UIFX_Pet_Feed, medicine.GfxHook, medicine.GfxHook, -1)-- DoMove
        -- DoMove
        local root = self._PanelObject.Group_CultivateLevelInfo
        GUITools.DoMove(medicine.GfxHook, root.Value.position, 0.6, nil, 0, function()
            GameUtil.StopUISfx(PATH.UIFX_Pet_Feed, medicine.GfxHook)
            medicine.GfxHook:SetActive(false)
        end)
    ]]
        GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, medicine.Obj, medicine.Obj, 1, 20, 1)
    end
end

def.method().ShowLevelUpGfx = function(self)
    local hook = self._PanelObject.Group_CultivateLevelInfo.GfxHook
    GameUtil.PlayUISfx(PATH.UIFX_Pet_LevelUp, hook, hook, 1)
    self._PanelObject.DotweenPlayer:Restart(2)
end

-- local function CancelTick(self)
--     if self._TimerID ~= 0 then
--         _G.RemoveGlobalTimer(self._TimerID)
--         self._TimerID = 0
--     end
-- end

-- local function AddTick(self, medicineTid)
--     CancelTick(self)

--     local timeCnt = 0
--     local timeDelay = 1 --吃药长按 Delay  写死一秒
--     self._TimerID = _G.AddGlobalTimer(EnumDef.ButtonHold.Tick, false, function()
--         timeCnt = timeCnt + EnumDef.ButtonHold.Tick
--         if timeCnt < timeDelay then return end

--         self._CanNotifyOnClick = false

--         local normalPack = game._HostPlayer._Package._NormalPack
--         local count = normalPack:GetItemCount( medicineTid )

--         if count <= 1 then
--             CancelTick(self)
--         end

--         UseMedicine(self, medicineTid)
--     end)
-- end

def.method().UpdateMedicine = function(self)
    for i,v in ipairs(self._MedicineList) do
        local Medicine = v
        SetMedicineItem(Medicine)
    end
end

def.method().UpdateSelectMaterial = function(self)
    for i=1,#self._MedicineList do
        self._MedicineList[i].SelectObj:SetActive(i == self._SelectMaterialIndex)
    end

    local Medicine = self._MedicineList[self._SelectMaterialIndex]
    local item = Medicine.Obj
    IconTools.SetMaterialNum(item:FindChild("MaterialIcon"), Medicine.Tid, 1)
    GUITools.SetBtnGray(self._PanelObject.Btn_Feed_Once, not CheckCount(self, Medicine.Tid, 1) or IsPetLevelTooHigh(self))
    GUITools.SetBtnGray(self._PanelObject.Btn_Feed_Several, not CheckCount(self, Medicine.Tid, 10) or IsPetLevelTooHigh(self))
end

def.method("string").OnClick = function(self, id)
    if id == "Btn_Feed_Once" then
        local Medicine = self._MedicineList[self._SelectMaterialIndex]
        if Medicine ~= nil and self:CheckCanFeed() then
            local medicineTid = Medicine.Tid
            UseMedicine(self, medicineTid, 1)
        end
    elseif id == "Btn_Feed_Several" then
        local Medicine = self._MedicineList[self._SelectMaterialIndex]
        if Medicine ~= nil and self:CheckCanFeed() then
            local medicineTid = Medicine.Tid
            UseMedicine(self, medicineTid, 10)
        end
    elseif string.find(id, "Frame_Cultivate_Property") then
        -- 暂时注释，后期修改显示方案
        -- local index = tonumber(string.sub(id, -1))
        -- self:ShowPropertyTip(index)
    elseif string.find(id, "Medicine") then
        local index = tonumber( string.sub(id, -1) )
        if index == self._SelectMaterialIndex then
            local Medicine = self._MedicineList[self._SelectMaterialIndex]
            if Medicine ~= nil then
                CItemTipMan.ShowItemTips(Medicine.Tid, TipsPopFrom.OTHER_PANEL, Medicine.Obj)
            end
        else
            self._SelectMaterialIndex = index
            self:UpdateSelectMaterial()
        end
    end
end

def.method("number").ShowPropertyTip = function(self, index)
    local fightPropertyId = self._PetData._AptitudeList[index].FightPropertyId
    local fix_id = CPetUtility.ExchangeToPropertyTipsID(fightPropertyId)
    local data = CElementData.GetTemplate("FightPropertyConfig", fix_id)

    if data == nil or data.DetailDesc == "" then return end
    
    local cnt = 0
    local replaceIdStr = data.ReplaceIdStr
    local strIds = {}

    if replaceIdStr ~= nil and replaceIdStr ~= "" then
        strIds = string.split(replaceIdStr, "*")
        cnt = #strIds
    end

    local exchangeIndex1 = index
    local exchangeIndex2 = 0
    local strDesc = ""

    if cnt == 1 then
        exchangeIndex1 = tonumber(strIds[1])
    elseif cnt == 2 then
        exchangeIndex1 = tonumber(strIds[1])
        exchangeIndex2 = tonumber(strIds[2])
    end

    local value = self._PetData._AptitudeList[index].Value
    if value == nil then return end

    if exchangeIndex2 == 0 then
        local ModuleProfDiffConfig = require "Data.ModuleProfDiffConfig" 
        local config = ModuleProfDiffConfig.GetModuleInfo("FightProperty")
        if config ~= nil and config.DESC ~= nil and config.DESC[index] ~= nil then
            strDesc = config.DESC[index][game._HostPlayer._InfoData._Prof]
        else
            local exchangeData = CElementData.GetTemplate("FightPropertyConfig", exchangeIndex1)
            if string.sub(exchangeData.ValueFormat, -1) == "%" then
                value = value * 100
            end
            
            strDesc = string.format(data.DetailDesc, value)
        end     
    else
        local value1 = value*100
        local value2 = self._PetData._AptitudeList[index].Value * 100
        strDesc = string.format(data.DetailDesc, value1, value2)
    end

    local param = 
    {
        Obj = self._Parent:GetUIObject("Frame_Cultivate_Property"..index),
        Value = strDesc,
        AlignType = EnumDef.AlignType.Top,
    }
    game._GUIMan:Open("CPanelRoleInfoTips", param)
end

def.method("string").OnPointerLongPress = function(self, id)
    if string.find(id, "Medicine") then
        local index = tonumber( string.sub(id, -1) )
        self._SelectMaterialIndex = index
        self:UpdateSelectMaterial()

        local Medicine = self._MedicineList[self._SelectMaterialIndex]
        if Medicine ~= nil then
            CItemTipMan.ShowItemTips(Medicine.Tid, TipsPopFrom.OTHER_PANEL, Medicine.Obj)
        end
    end
end
--[[
def.method("string").OnPointerDown = function(self,id)
    if string.find(id, "Medicine") > 0 then
        self._CanNotifyOnClick = true

        local index = tonumber( string.sub(id, -1) )
        local Medicine = self._MedicineList[index]

        if Medicine ~= nil then
            local medicineTid = Medicine.Tid
            
            if CheckCount(self, medicineTid) then
                AddTick(self, medicineTid)
            end
        end
    end
end

def.method("string").OnPointerUp = function(self,id)
    if string.find(id, "Medicine") > 0 then
        CancelTick(self)
    end   
end

def.method("string").OnPointerExit = function(self,id)
    if string.find(id, "Medicine") > 0 then
        CancelTick(self)
    end   
end
]]
def.method('userdata','string','number').OnLongPressItem = function(self, item, id, index)
    if string.find(id, "Medicine") > 0 then
        local index = tonumber( string.sub(id, -1) )
        local Medicine = self._MedicineList[index]

        if Medicine ~= nil then
            local medicineTid = Medicine.Tid
            CItemTipMan.ShowItemTips(medicineTid, TipsPopFrom.OTHER_PANEL,medicineTid.Obj)
        end
    end
end

def.method().Hide = function(self)
    -- CancelTick(self)

    CGame.EventManager:removeHandler(PetUpdateEvent, OnPetUpdateEvent)
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
    
    self._PanelObject = nil
    self._PetData = nil
    self._Panel:SetActive(false)
    self._Inited = false
end

def.method().Destroy = function (self)
    instance = nil
    self._Panel = nil
end

CPagePetCultivate.Commit()
return CPagePetCultivate