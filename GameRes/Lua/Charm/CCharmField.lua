local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CCharmField = Lplus.Class("CCharmField")
local ECharmSize = require "PB.data".ECharmSize
local ECharmColor = require "PB.data".ECharmColor
local def = CCharmField.define

--静态属性
def.field("number")._FieldID = -1		    --神符槽位模板ID
def.field("table")._FieldData = nil         --服务器数据（针对这个槽位的数据）
def.field("number")._State = 0      --开启或者装配状态
def.field("userdata")._FieldUI = nil
def.field("table")._CharmFieldTemp = nil
def.field("number")._CombatNum = 0

def.static("=>", CCharmField).new = function()
	local obj = CCharmField()
	return obj
end

def.method("number", "userdata", "table").Init = function(self, fieldID, fieldUI, fieldData)
    self._FieldID = fieldID
    self._FieldUI = fieldUI
    self._FieldData = fieldData
    self._CharmFieldTemp = self:GetCharmFieldTemplate()
    if self._FieldData == nil then return end
    local hp = game._HostPlayer
    if self._FieldData._UnlockLevel > hp._InfoData._Level or self._FieldID == -1 then
        self._State = EnumDef.CharmEnum.CharmFieldState.Locked
    else
        if self._FieldData._CharmID == -1 or self._FieldData._ItemID == -1 then
            self._State = EnumDef.CharmEnum.CharmFieldState.OpenButNoCharm
        else
            self._State = EnumDef.CharmEnum.CharmFieldState.HaveCharm
        end
    end
end

--获得神符Item的模板
def.method("=>", "dynamic").GetItemTemplate = function (self)
	if self._FieldData._ItemID == -1 then return nil end
	return CElementData.GetTemplate("Item", self._FieldData._ItemID)
end

--获得神符表的模板
def.method("=>", "dynamic").GetCharmItemTemplate = function(self)
    if self._FieldData._CharmID == -1 then return nil end
    return CElementData.GetTemplate("CharmItem", self._FieldData._CharmID)
end

--根据自身的FieldID获得神符槽位模板
def.method("=>", "dynamic").GetCharmFieldTemplate = function (self)
	if self._FieldID == -1 then return nil end
	return CElementData.GetTemplate("CharmField", self._FieldID)
end

--切换状态
def.method("number").ChangeState = function(self, newState)
    self._State = newState
end

--获得解锁或装配状态
def.method("=>", "number").GetState = function(self)
    return self._State
end

def.method("=>", "boolean").IsLock = function(self)
    return self._State == EnumDef.CharmEnum.CharmFieldState.Locked
end

def.method("=>", "boolean").IsBigField = function(self)
    return self._CharmFieldTemp.CharmSize == ECharmSize.ECharmSize_Big
end

def.method("number").PutOnCharmWithOutFx = function(self, itemID)
    if self:IsLock() then return end
    if not self:CanPutOn(itemID) then return end
    self._State = EnumDef.CharmEnum.CharmFieldState.HaveCharm
    self._FieldData._ItemID = itemID
    self._FieldData._CharmID = itemID
end

def.method().PutOffCharmWithOutFx = function(self)
    if self:IsLock() then return end
    self._FieldData._ItemID = -1
    self._FieldData._CharmID = -1
    self._State = EnumDef.CharmEnum.CharmFieldState.OpenButNoCharm
end

--穿上神符
def.method("number").PutOnCharm = function(self, itemID)
--    local package = game._HostPlayer._Package._NormalPack
--    local item = package:GetItemBySlot(itemID)
--    if item:IsCharm() then
--        self._State = EnumDef.CharmEnum.CharmFieldState.HaveCharm
--    end
    self._State = EnumDef.CharmEnum.CharmFieldState.HaveCharm
    self._FieldData._ItemID = itemID
    self._FieldData._CharmID = itemID
    -- TODO 播放特效
    GameUtil.PlayUISfx(PATH.UIFX_CharmInlayFX, self._FieldUI, self._FieldUI, 1)
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_CharmInlay, 0)
end

--卸下神符
def.method().PutOffCharm = function(self)
    if self._State == EnumDef.CharmEnum.CharmFieldState.Locked then
        warn("该槽位还未开启！！")
        return
    end
    self._FieldData._ItemID = -1
    self._FieldData._CharmID = -1
    self._State = EnumDef.CharmEnum.CharmFieldState.OpenButNoCharm
    
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_CharmPutOff, 0)
    -- TODO 播放特效
end

-- 解锁神符槽位
def.method().UnlockField = function(self)
    self._State = EnumDef.CharmEnum.CharmFieldState.OpenButNoCharm
    -- TODO 播放特效
end

-- 是否已经装备有符文了
def.method("=>", "boolean").IsCharmPut = function(self)
    return self._FieldID ~= -1 and self._State == EnumDef.CharmEnum.CharmFieldState.HaveCharm and self._FieldData._ItemID ~= -1
end

-- 当前槽位能否穿上一个神符
def.method("number", "=>", "boolean").CanPutOn = function(self, itemID)
    local charm_item = CElementData.GetTemplate("CharmItem", itemID)
    if self._CharmFieldTemp == nil then return false end
    if charm_item.CharmSize == self._CharmFieldTemp.CharmSize then
        if self:IsBigField() then
            return true
        else
            if self._CharmFieldTemp.CharmColor == ECharmColor.ECharmColor_Colorful then
                return true
            else
                return self._CharmFieldTemp.CharmColor == charm_item.CharmColor
            end
        end
    else
        return false
    end
end

-- 当前穿戴的神符是否比传过来的神符更牛逼
def.method("number", "=>", "boolean").IsBetter = function(self, itemID)
    if not self:IsCharmPut() then
        return true
    end
    local CCharmMan = require "Charm.CCharmMan"
    local self_combat = CCharmMan.Instance():CalculateCharmItemCombatValue(self._FieldData._ItemID)
    local des_combat = CCharmMan.Instance():CalculateCharmItemCombatValue(itemID)
    return des_combat > self_combat
end

-- 计算自身所装备的神符的战斗力
def.method().CalculateSelfCombatValue = function(self)
    if not self:IsCharmPut() then
        self._CombatNum = 0
        return
    end
    local CCharmMan = require "Charm.CCharmMan"
    self._CombatNum = CCharmMan.Instance():CalculateCharmItemCombatValue(self._FieldData._ItemID)
end

--更新界面
def.method().UpdateUI = function(self)
    if self._FieldUI == nil or self._CharmFieldTemp == nil then
        if self._CharmFieldTemp == nil then self._FieldUI:SetActive(false) end
        warn("神符槽位UI为空， ID: ", self._FieldID)
        return
    end
    local uiTemplate = self._FieldUI:GetComponent(ClassType.UITemplate)
    local img_fieldBG = uiTemplate:GetControl(0)
    local img_icon = uiTemplate:GetControl(1)
    local img_lock = uiTemplate:GetControl(2)
    local img_plus = uiTemplate:GetControl(3)
    local lab_levelNeed = uiTemplate:GetControl(4)
    local lab_charm_level = uiTemplate:GetControl(5)
    local item_Temp = self._CharmFieldTemp

    if item_Temp.CharmSize == ECharmSize.ECharmSize_Small then
        GUITools.SetGroupImg(img_fieldBG,item_Temp.CharmColor)
    end
    if self._State == EnumDef.CharmEnum.CharmFieldState.Locked then
        img_icon:SetActive(false)
        img_lock:SetActive(true)
        img_plus:SetActive(false)
        GUI.SetText(lab_levelNeed, string.format(StringTable.Get(20053),item_Temp.UnlockLevel))
    elseif self._State == EnumDef.CharmEnum.CharmFieldState.OpenButNoCharm then
        img_icon:SetActive(false)
        img_lock:SetActive(false)
        img_plus:SetActive(true)
    else
        img_icon:SetActive(true)
        img_lock:SetActive(false)
        img_plus:SetActive(false)
        local itemTemp = self:GetItemTemplate()
        local charm_item_temp = self:GetCharmItemTemplate()
        GUITools.SetItemIcon(img_icon, itemTemp ~= nil and itemTemp.IconAtlasPath or "")
        GUI.SetText(lab_charm_level, string.format(StringTable.Get(20053), charm_item_temp ~= nil and charm_item_temp.Level or 0))
    end
end

def.method("table", "=>", "boolean").FieldShouldShowRedPoint = function(self, items)
    if self._State == EnumDef.CharmEnum.CharmFieldState.Locked then return false end
    if self._FieldData._CharmID > 0 then        
        local charmTemp = CElementData.GetTemplate("CharmItem", self._FieldData._CharmID)
        for i,v in ipairs(items) do
            if v._CharmItemTemplate.CharmSize == self._FieldData._CharmFieldSize then
                if self._FieldData._CharmFieldSize == ECharmSize.ECharmSize_Big then
                    if charmTemp.PropID1 == nil and v._CharmItemTemplate.PropID1 ~= nil then
                        return true
                    elseif charmTemp.PropID2 == nil and v._CharmItemTemplate.PropID2 ~= nil then
                        return true
                    end
                    if v._CharmItemTemplate.PropID1 == charmTemp.PropID1 and v._CharmItemTemplate.PropID2 == charmTemp.PropID2 then
                        if v._CharmItemTemplate.PropValue1 > charmTemp.PropValue1 and v._CharmItemTemplate.PropValue2 > charmTemp.PropValue2 then
                            return true
                        end
                    end
                else
                    if charmTemp.PropID1 == nil and v._CharmItemTemplate.PropID1 ~= nil then
                        return true
                    elseif charmTemp.PropID2 == nil and v._CharmItemTemplate.PropID2 ~= nil then
                        return true
                    end
                    if v._CharmItemTemplate.PropID1 == charmTemp.PropID1 then
                        if v._CharmItemTemplate.PropValue1 > charmTemp.PropValue1 then return true end
                    elseif v._CharmItemTemplate.PropID2 == charmTemp.PropID2 then
                        if v._CharmItemTemplate.PropValue2 > charmTemp.PropValue2 then return true end
                    end
                end
            end
        end
    else
        for i,v in ipairs(items) do
            if self._FieldData._CharmFieldSize == ECharmSize.ECharmSize_Big then
                if v._CharmItemTemplate.CharmSize == self._FieldData._CharmFieldSize then return true end
            else
                if v._CharmItemTemplate.CharmSize == self._FieldData._CharmFieldSize and 
                        (v._CharmItemTemplate.CharmColor == self._FieldData._CharmFieldColor or self._FieldData._CharmFieldColor == ECharmColor.ECharmColor_Colorful) then
                    return true
                end
            end
        end
    end
    return false
end

-- 更新红点，只有CCharmMan里面的_ShowFieldFXAndRedPoint为true才会更新
def.method("table").UpdateRedPoint = function(self, items)
    local showRedPoint = self:FieldShouldShowRedPoint(items)
    local img_red_point = self._FieldUI:GetComponent(ClassType.UITemplate):GetControl(7)
    if showRedPoint then
        img_red_point:SetActive(true)
    else
        img_red_point:SetActive(false)
    end
--    if self._State == EnumDef.CharmEnum.CharmFieldState.OpenButNoCharm then
--        GameUtil.PlayUISfx(PATH.UIFX_CharmFieldNewGet,self._FieldUI,self._FieldUI,-1)
--    else
--        GameUtil.StopUISfx(PATH.UIFX_CharmFieldNewGet,self._FieldUI)
--    end
end

-- 隐藏红点（在CCharmMan里面配置是否更新显示红点）
def.method().HideRedPoint = function(self)
    local img_red_point = self._FieldUI:GetComponent(ClassType.UITemplate):GetControl(7)
    img_red_point:SetActive(false)
end

def.method().Realse = function(self)
    self._FieldUI = nil
    self._FieldData = nil
    self._CharmFieldTemp = nil
end

CCharmField.Commit()
return CCharmField