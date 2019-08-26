local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local ECharmSize = require "PB.data".ECharmSize
local ECharmColor = require "PB.data".ECharmColor
local CCharmFieldData = Lplus.Class("CCharmFieldData")
local def = CCharmFieldData.define

def.field("number")._FieldID = -1
def.field("number")._CharmID = -1
def.field("number")._ItemID = -1
def.field("number")._CharmFieldColor = -1	--卡槽的颜色
def.field("number")._CharmFieldSize = -1	--卡槽的大小
def.field("number")._UnlockLevel = 0        --解锁等级

def.static("=>", CCharmFieldData).new = function()
    local obj = CCharmFieldData()
    return obj
end

def.method("=>", "dynamic").GetCharmTemplate = function(self)
    if self._FieldID <= 0 then
        return nil
    end
    return CElementData.GetTemplate("CharmField", self._FieldID)
end

def.method("number", "number", "number").Init = function(self, fieldID, charmID, itemID)
    self._FieldID = fieldID
    self._CharmID = charmID
    self._ItemID = itemID
    local fieldTemp = self:GetCharmTemplate()
    if fieldTemp ~= nil then
        self._CharmFieldColor = fieldTemp.CharmColor
        self._CharmFieldSize = fieldTemp.CharmSize
        self._UnlockLevel = fieldTemp.UnlockLevel
    end
end

def.method("=>", "boolean").IsBigField = function(self)
    return self._CharmFieldSize == ECharmSize.ECharmSize_Big
end

def.method("=>", "boolean").IsEmptyField = function(self)
    if self._FieldID < 0 or self._ItemID < 0 or self._CharmID < 0 then
        return true
    else
        return false
    end
end

def.method("number", "=>", "boolean").NeedChangeCharm = function(self, newCharmID)
    local new_charm_temp = CElementData.GetTemplate("CharmItem", newCharmID)

    if not self:IsEmptyField() then        
        local charmTemp = CElementData.GetTemplate("CharmItem", self._CharmID)
        if new_charm_temp.CharmSize == self._CharmFieldSize then
            if self._CharmFieldSize == ECharmSize.ECharmSize_Big then
                if charmTemp.PropID1 == nil and new_charm_temp.PropID1 ~= nil then
                    return true
                elseif charmTemp.PropID2 == nil and new_charm_temp.PropID2 ~= nil then
                    return true
                end
                if new_charm_temp.PropID1 == charmTemp.PropID1 and new_charm_temp.PropID2 == charmTemp.PropID2 then
                    if new_charm_temp.PropValue1 > charmTemp.PropValue1 and new_charm_temp.PropValue2 > charmTemp.PropValue2 then
                        return true
                    end
                end
            else
                if charmTemp.PropID1 == nil and new_charm_temp.PropID1 ~= nil then
                    return true
                elseif charmTemp.PropID2 == nil and new_charm_temp.PropID2 ~= nil then
                    return true
                end
                if new_charm_temp.PropID1 == charmTemp.PropID1 then
                    if new_charm_temp.PropValue1 > charmTemp.PropValue1 then return true end
                elseif new_charm_temp.PropID2 == charmTemp.PropID2 then
                    if new_charm_temp.PropValue2 > charmTemp.PropValue2 then return true end
                end
            end
        end
    else
        if self._CharmFieldSize == ECharmSize.ECharmSize_Big then
            if new_charm_temp.CharmSize == self._CharmFieldSize then return true end
        else
            if new_charm_temp.CharmSize == self._CharmFieldSize and 
                    (new_charm_temp.CharmColor == self._CharmFieldColor or self._CharmFieldColor == ECharmColor.ECharmColor_Colorful) then
                return true
            end
        end
    end
    return false
end

def.method("number").PutOn = function(self, charmID)
    self._ItemID = charmID
    self._CharmID = charmID
end

def.method().PutDown = function(self)
    self._ItemID = -1
    self._CharmID = -1
end

CCharmFieldData.Commit()
return CCharmFieldData