-- CHUDDrugUseComp

local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"

local CHUDDrugUseComp = Lplus.Class("CHUDDrugUseComp")
local def = CHUDDrugUseComp.define

-- 父Panel类
def.field("table")._Parent = nil

-- UI对象缓存
def.field("userdata")._SkillDoTween = nil
def.field("userdata")._FrameItemBg = nil                       -- Frame_Item_Bg
def.field("table")._DrugNodeTweenItems = nil              
def.field("userdata")._EmptyIcon = nil                      
def.field("userdata")._LabNumber = nil                       
def.field("userdata")._DrugBtnIcon = nil                       
def.field("userdata")._ImgCoolDown = nil                       
def.field("userdata")._LabCoolDown = nil                       

-- 数据成员
def.field("number")._DrugItemShowTimer = 0
def.field("boolean")._IsDrugListShow = false

def.static("table", "=>", CHUDDrugUseComp).new = function(root)
    local obj = CHUDDrugUseComp()
    obj._Parent = root
    obj:InitUIObjs()
    return obj 
end

def.method().InitUIObjs = function(self)
    self._FrameItemBg = self._Parent:GetUIObject("Frame_Item_Bg")
    self._FrameItemBg:SetActive(false)
    self._SkillDoTween = self._FrameItemBg:GetComponent(ClassType.DOTweenPlayer)
    self._DrugNodeTweenItems = 
        {
            self._Parent:GetUIObject("Btn_Drug_Item_1"),
            self._Parent:GetUIObject("Btn_Drug_Item_2"),
            self._Parent:GetUIObject("Btn_Drug_Item_3")
        }

    self._EmptyIcon = self._Parent:GetUIObject("Img_Icon0")
    self._LabNumber = self._Parent:GetUIObject("Lab_Number")
    self._DrugBtnIcon = self._Parent:GetUIObject("Img_DrugItemIcon")
    self._ImgCoolDown = self._Parent:GetUIObject("Img_Item_CoolDown")
    self._LabCoolDown = self._Parent:GetUIObject("Lab_Item_CD")
end

def.method().Update = function(self)
    local empty_icon = self._EmptyIcon
    empty_icon:SetActive(false)
    local labCount = self._LabNumber
    labCount:SetActive(true)    
    self._DrugBtnIcon:SetActive(false)

    local equip_drug_id =  game._HostPlayer:GetEquipedPotion()
    local normalPack = game._HostPlayer._Package._NormalPack
    -- 未装备
    if equip_drug_id <= 0 then
        empty_icon:SetActive(true)
        GUI.SetText(labCount, "")
    else
        local template = CElementData.GetTemplate("Item", equip_drug_id)
        local drugCount = normalPack:GetItemCount(equip_drug_id)
        if template and drugCount > 0 then
            self._DrugBtnIcon:SetActive(true)
            GUITools.SetIcon(self._DrugBtnIcon, template.IconAtlasPath)
            GUI.SetText(labCount, tostring(drugCount))          
            self:UpdateCDInfo()
        else
            empty_icon:SetActive(true)
            GUI.SetText(labCount, "")
            self:UpdateCDInfo()
        end
    end

    if self._IsDrugListShow then
        self:RefreshDrugItems()
    end
end

def.method().UpdateCDInfo = function(self)
    local hp = game._HostPlayer
    local drugId = hp:GetEquipedPotion()
    if drugId <= 0 then
        self._ImgCoolDown:SetActive(false)
        GUI.SetText(self._LabCoolDown, "")
        return
    end

    local normalPack = hp._Package._NormalPack
    local drugCount = normalPack:GetItemCount(drugId)  
    if drugCount > 0 then
        local item = normalPack:GetItem(drugId) 
        local cdid = item._CooldownId       
        local CDHdl = hp._CDHdl
        if CDHdl:IsCoolingDown(cdid) then
            if not self._ImgCoolDown.activeSelf then
                local elapsed, max = CDHdl:GetCurInfo(cdid)
                GameUtil.AddCooldownComponent(self._ImgCoolDown, elapsed, max, self._LabCoolDown, function () end, false)
            end
        else
            self._ImgCoolDown:SetActive(false)
            GUI.SetText(self._LabCoolDown, "")
        end
    else
        self._ImgCoolDown:SetActive(false)
        GUI.SetText(self._LabCoolDown, "")
    end
end

-- 开启item界面
def.method().OpenItemsList = function(self) 
    if self._DrugItemShowTimer > 0 then
        _G.RemoveGlobalTimer(self._DrugItemShowTimer)
        self._DrugItemShowTimer = 0
    end

    self:RefreshDrugItems()
    self._SkillDoTween:Restart(3)
    self._DrugItemShowTimer = _G.AddGlobalTimer(2, true, function()
        self:CloseItemsList()
    end)
    self._IsDrugListShow = true
end

-- 关闭item界面
def.method().CloseItemsList = function(self)
    self._SkillDoTween:Restart(4)
    if self._DrugItemShowTimer > 0 then
        _G.RemoveGlobalTimer(self._DrugItemShowTimer)
        self._DrugItemShowTimer = 0
    end
    self._IsDrugListShow = false
end

def.method().RefreshDrugItems = function(self)  
    self._FrameItemBg:SetActive(true)
    for i,v in ipairs(self._DrugNodeTweenItems) do
        v:SetActive(false)
    end

    local avildPotions = game._HostPlayer:GetNoEquipedPotions(true)
    for i,v in ipairs(avildPotions) do
        if i > 3 then break end
        local node = self._DrugNodeTweenItems[i]
        node:SetActive(true)       
        local template = CElementData.GetItemTemplate(v[1])
        if template then
            local icon = node:FindChild("Img_DrugItemIcon")
            local quality = node:FindChild("Img_DrugQuality")
            local numTxt = node:FindChild("Drug_Item_Num")
            GUITools.SetIcon(icon, template.IconAtlasPath)
            GUITools.SetGroupImg(quality, template.InitQuality - 1) 
            GUI.SetText(numTxt, tostring(v[2]))
        end
    end
end

-- 刷新药品置灰状态
def.method().UpdateDrugForbiddenState = function(self)
    local enable = game:IsCurMapForbidDrug() or game._HostPlayer:GetForbidDrugState()
    GameUtil.MakeImageGray(self._DrugBtnIcon, enable)
end

def.method().UseDrug = function (self)
    if game._RegionLimit._LimitUseBlood then -- 地图限制禁止使用药瓶
        game._GUIMan:ShowTipText(StringTable.Get(15555), false)
        return
    end

    local hp = game._HostPlayer
    local equip_drug_id = hp:GetEquipedPotion()
    local normalPack = hp._Package._NormalPack
    local drugCount = normalPack:GetItemCount(equip_drug_id)
    
    if drugCount <= 0 then
        local ENpcSaleServiceType = require "PB.data".ENpcSaleServiceType
        local drug_id = game._HostPlayer:GetEquipedPotion()
        local panelData =
        {
            OpenType = 1,
            ShopId = 10,
            ItemId = drug_id,
            Count  = 1,
        }
        game._GUIMan:Open("CPanelNpcShop",panelData)
    else
        local drug = normalPack:GetItem(equip_drug_id)
        if drug ~= nil then
            drug:Use()
        end
    end
end

def.method("string").OnClick = function (self, id)
    if id == "Btn_Item" then -- 使用药瓶
        self:UseDrug()
    else
        local idx = tonumber(string.sub(id,-1))
        if idx ~= nil and idx > 0 then
            local hp = game._HostPlayer
            local drugList = hp:GetNoEquipedPotions(false)
            local selectDrugTid = drugList[idx] 
            if selectDrugTid ~= nil and selectDrugTid > 0 then      
                hp:EquipDrugItem(selectDrugTid)
            end
            self:CloseItemsList()
        end
    end
end

def.method().Clear = function (self)
    self._IsDrugListShow = false    
    if self._DrugItemShowTimer > 0 then
        _G.RemoveGlobalTimer(self._DrugItemShowTimer)
        self._DrugItemShowTimer = 0
    end 
end

def.method().Release = function (self)
    self._Parent = nil
    self._SkillDoTween = nil
    self._FrameItemBg = nil                       -- Frame_Item_Bg
    self._DrugNodeTweenItems = nil              
    self._EmptyIcon = nil                       -- Frame_Item_Bg
    self._LabNumber = nil 
    self._DrugBtnIcon = nil
    self._ImgCoolDown = nil                       
    self._LabCoolDown = nil 
end

CHUDDrugUseComp.Commit()
return CHUDDrugUseComp