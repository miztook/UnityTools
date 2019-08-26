
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")
local PackageChangeEvent = require "Events.PackageChangeEvent"
local CPanelEvilValueTip = Lplus.Extend(CPanelBase, 'CPanelEvilValueTip')
local EntityEvilNumChangeEvent = require "Events.EntityEvilNumChangeEvent"
local def = CPanelEvilValueTip.define

def.field("number")._IncreaseValue = 20 
def.field("number")._ReduceValue1 =  1
def.field("number")._ReduceValue2 =  20
def.field("number")._UseItemTid = 2021
def.field("number")._UsItemReduceValue = 20
def.field("boolean")._IsLackItem = false
def.field("table")._ItemTemplate = nil
def.field("userdata")._FrameAll = nil 
def.field("userdata")._ImgBtnItem = nil 

def.field("userdata")._LabAdd = nil 
def.field("userdata")._LabReduce1 = nil 
def.field("userdata")._LabReduce2 = nil 
def.field("userdata")._ImgItemIcon = nil 
def.field('userdata')._LabItemNum = nil 
def.field("userdata")._LabEvil = nil
def.field("userdata")._BtnOk = nil
local EvilValue =
{
    [1] = { value = 100, per = 10} ,
    [2] = { value = 200, per = 30} , 
    [3] = { value = 300, per = 50} ,  
}


local instance = nil
def.static('=>', CPanelEvilValueTip).Instance = function ()
	if not instance then
        instance = CPanelEvilValueTip()
        instance._PrefabPath = PATH.UI_EvilValueTip
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end

local OnPackageChangeEvent = function(sender, event)
    if instance ~= nil then
        if not instance:IsShow() then return end
        local count = game._HostPlayer._Package._NormalPack:GetItemCount(instance._UseItemTid)
        GUI.SetText(instance._LabItemNum,tostring(count))
        if count == 0 then 
            instance._IsLackItem = true
            local imgBg = instance._BtnOk:FindChild("Img_Bg")
            GameUtil.MakeImageGray(imgBg,true)
            GUITools.SetBtnExpressGray(instance._BtnOk, true)
        end
    end
end

local OnEntityEvilNumChangeEvent = function (sender, event)
    if instance ~= nil then
        if not instance:IsShow() then return end
        instance:UpdataEvil()
    end
end

def.override().OnCreate = function(self)
    self._LabAdd = self:GetUIObject("Lab_Add")
    -- self._LabReduce1 = self:GetUIObject("Lab_Reduce1")
    -- self._LabReduce2 = self:GetUIObject("Lab_Reduce2")
    self._ImgItemIcon = self:GetUIObject("Img_ItemIcon")
    self._LabItemNum = self:GetUIObject("Lab_ItemNum")
    self._LabEvil = self:GetUIObject("Lab_EvilValue")
    self._BtnOk = self:GetUIObject("Btn_OK")
    self._FrameAll = self:GetUIObject("Frame_All")
    self._ImgBtnItem = self:GetUIObject("Img_BtnItem")
end

def.override("dynamic").OnData = function(self,data)
    CGame.EventManager:addHandler(PackageChangeEvent, OnPackageChangeEvent) 
    CGame.EventManager:addHandler(EntityEvilNumChangeEvent, OnEntityEvilNumChangeEvent) 
    self._ItemTemplate = CElementData.GetItemTemplate(self._UseItemTid)
    GUI.SetText(self._LabAdd,string.format(StringTable.Get(31700),self._IncreaseValue).."；"
        ..string.format(StringTable.Get(31701),self._ReduceValue1).."；"..string.format(StringTable.Get(31702),self._ItemTemplate.TextDisplayName,self._ReduceValue2))
    -- GUI.SetText(self._LabReduce1,string.format(StringTable.Get(31701),self._ReduceValue1))
    -- GUI.SetText(self._LabReduce2,string.format(StringTable.Get(31702),self._ItemTemplate.TextDisplayName,self._ReduceValue2))
    GUITools.SetItemIcon(self._ImgItemIcon,self._ItemTemplate.IconAtlasPath)
    GUITools.SetItemIcon(self._ImgBtnItem,self._ItemTemplate.IconAtlasPath)
    self:UpdataEvil()
    --赎罪券
    local count = game._HostPlayer._Package._NormalPack:GetItemCount(self._UseItemTid)
    GUI.SetText(self._LabItemNum,tostring(count))
    if count == 0 then 
        self._IsLackItem = true
        local imgBg = self._BtnOk:FindChild("Img_Bg")
        local imgIcon = self._BtnOk:FindChild("Img_Bg/Node_Content/Icon_Money/Img_BtnItem")
        GameUtil.MakeImageGray(imgBg,true)
        GameUtil.MakeImageGray(imgIcon,true)
        GUITools.SetBtnExpressGray(self._BtnOk, true)
    end
end

def.method().UpdataEvil = function (self)
    local evilValue = game._HostPlayer:GetEvilValue()
    GUI.SetText(self._LabEvil,tostring(evilValue))
    local maxEvil = tonumber(CSpecialIdMan.Get("MaxEvilValue"))
    for i = 1,3 do 
        local FrameBar = self:GetUIObject("Frame_Bar"..i)
        local uiTemplate = FrameBar:GetComponent(ClassType.UITemplate)
        local labValue1 = uiTemplate:GetControl(0)
        local labValue2 = uiTemplate:GetControl(1)
        local labValue3 = uiTemplate:GetControl(2)
        local bar = uiTemplate:GetControl(3):GetComponent(ClassType.Scrollbar)
        if evilValue <= EvilValue[i].value then 
            if i < 3 then 
                GUI.SetText(labValue1,string.format(StringTable.Get(31708),EvilValue[i].value))
                GUI.SetText(labValue2,string.format(StringTable.Get(31708),EvilValue[i + 1].value))
            else
                GUI.SetText(labValue1,string.format(StringTable.Get(31707),EvilValue[i].value))
            end
            GUI.SetText(labValue3,string.format(StringTable.Get(31703),EvilValue[i].per))
            bar.size = 0
        elseif evilValue > EvilValue[i].value then
            local value = 0 
            local perValue = ""
            if i < 3 then 
                GUI.SetText(labValue1,string.format(StringTable.Get(31705),EvilValue[i].value))
                GUI.SetText(labValue2,string.format(StringTable.Get(31705),EvilValue[i + 1].value))
                value = (evilValue - EvilValue[i].value) / (EvilValue[i + 1].value - EvilValue[i].value)
                if evilValue >= EvilValue[i].value and evilValue <= EvilValue[i + 1].value then 
                    perValue = string.format(StringTable.Get(31704),EvilValue[i].per)
                elseif evilValue > EvilValue[i].value and evilValue > EvilValue[i + 1].value then 
                    perValue = string.format(StringTable.Get(31703),EvilValue[i].per)
                end
            else
                GUI.SetText(labValue1,string.format(StringTable.Get(31706),EvilValue[i].value))
                value = (evilValue - EvilValue[i].value) / (maxEvil - EvilValue[i].value)
                perValue = string.format(StringTable.Get(31704),EvilValue[i].per)
            end
            bar.size = value
            GUI.SetText(labValue3,perValue)
        end
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_OK" then 
        if self._IsLackItem then 
            game._GUIMan:ShowTipText(StringTable.Get(31709),false)
            return
        end
        local itemData = game._HostPlayer._Package._NormalPack:GetItem(self._UseItemTid)
        if itemData ~= nil then 
            itemData:Use()
        end
    elseif id == "Btn_Approach" then 

        local data = 
        {
            ApproachIDs = self._ItemTemplate.ApproachID,
            ParentObj = self._FrameAll
        }
        game._GUIMan:Open("CPanelItemApproach", data)
    end
end

def.override().OnDestroy = function(self)
    CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)  
    CGame.EventManager:removeHandler(EntityEvilNumChangeEvent, OnEntityEvilNumChangeEvent) 
    instance = nil  
end

CPanelEvilValueTip.Commit()
return CPanelEvilValueTip