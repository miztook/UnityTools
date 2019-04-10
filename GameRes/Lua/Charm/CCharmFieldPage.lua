local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CCharmField = require "Charm.CCharmField"
local CElementData = require "Data.CElementData"
local CCharmPageBase = require "Charm.CCharmPageBase"
local CCharmFieldData = require "Charm.CCharmFieldData"
local CCharmMan = require "Charm.CCharmMan"
local CScoreCalcMan = require "Data.CScoreCalcMan"
local CCharmFieldPage = Lplus.Class("CCharmFieldPage")
local def = CCharmFieldPage.define

local select_index = -1

def.field(CCharmPageBase)._CharmPage = nil
def.field("number")._PageID = -1                         --神符槽位页签Index
def.field("table")._CharmFields = BlankTable		     --神符物品模板ID
def.field("number")._OpenState = EnumDef.CharmEnum.CharmPageState.Locked	--卡槽的大小
def.field("table")._CurField = nil
def.field("table")._CustomItems = nil
def.field("userdata")._PageUI = nil

def.static("table", "number", "number", "userdata", "=>", CCharmFieldPage).new = function(pagePanel, pageID, state, pageUI)
	local obj = CCharmFieldPage()
    obj._CharmPage = pagePanel
    obj._PageID = pageID
    obj._OpenState = state
    obj._PageUI = pageUI
    obj._CharmFields = {}
    obj:Init()
	return obj
end

def.static("=>", "number").GetSelectIndex = function()
    return select_index
end

def.static("number").SetSelectIndex = function(newIndex)
    select_index = newIndex
end

def.method().Init = function(self)
    self:GenerateFields()
end

-- 手动Toggle
def.method("number").OnToggleField = function(self, index)
    select_index = index
    self._CurField = self._CharmFields[index]
end

-- 代码Toggle
def.method("number").ToggleByScript = function(self, index)
    select_index = index
    self._CurField = self._CharmFields[index]
    GUI.SetGroupToggleOn(self._PageUI, index)
end

-- 未解锁的时候点击无效，并设置原来的toggele
def.method().ReBackToggleIndex = function(self)
    if select_index <= 0 or self._PageUI == nil then
        warn("error 未选择槽位或者UI为空！！！")
        return
    end
    GUI.SetGroupToggleOn(self._PageUI, select_index)
end

-- 根据槽位颜色找到第一个该颜色的槽位
def.method("number", "=>", "number").FindTheFirstFieldByColor = function(self, fieldColor)
    for i,v in ipairs(self._CharmFields) do
        if v._CharmFieldTemp.CharmColor == fieldColor then
            return i
        end
    end
    return 1
end

--生成槽位
def.method().GenerateFields = function(self)
    self._CharmFields = {}
    local pageTemp = CElementData.GetTemplate("CharmPage", self._PageID)
    local fieldIDs = string.split(pageTemp.CharmFieldIds, '*')
    for i,v in ipairs(fieldIDs) do
        local fieldID = tonumber(v)
        local fieldTemp = CElementData.GetTemplate("CharmField", fieldID)
        if fieldTemp == nil then return end
        local uiTemplate = self._PageUI:GetComponent(ClassType.UITemplate)
        local dataRef = CCharmMan.Instance():GetFieldDataByFieldID(fieldID)
        if dataRef == nil then
            dataRef = CCharmFieldData.new()
            dataRef:Init(fieldID, -1, -1)
        end
        local newField = CCharmField.new()
        newField:Init(fieldID, uiTemplate:GetControl(fieldTemp.Index), dataRef)
        self:AddField(fieldID, newField)
    end
end

--切换开启与否状态
def.method("number").ChangeState = function(self, newState)
    self._OpenState = newState
end

def.method("=>", "boolean").IsPageLocked = function(self)
    return self._OpenState == EnumDef.CharmEnum.CharmPageState.Locked
end

--往神符页签里面添加神符槽位
def.method("number", CCharmField).AddField = function(self, fieldID, field)
    for _,v in ipairs(self._CharmFields) do
        if v._FieldID == fieldID then
            warn("CCharmFieldPage  该槽位页已经有这个槽位了", self._CharmFields[fieldID])
            return
        end
    end
    self._CharmFields[#self._CharmFields + 1] = field
end

--根据FieldID来获得Field
def.method("number", "=>", CCharmField).GetFieldByFieldID = function(self, fieldID)
    for _,v in ipairs(self._CharmFields) do
        if v._FieldID == fieldID then
            return v
        end
    end
    warn("CCharmFieldPage  该槽位页没有ID为",fieldID,"的槽位")
    return nil
end

-- 根据index过得槽位对象
def.method("number", "=>", CCharmField).GetFieldByIndex = function(self, index)
    if self._CharmFields == nil or index > #self._CharmFields then return nil end
    return self._CharmFields[index]
end

-- 获得神符页的模板
def.method("number", "=>", "table").GetFieldPageTemplate = function(self, pageTid)
    if pageTid > 0 then
        return CElementData.GetTemplate("CharmPage", pageTid)
    end
    return nil
end

-- 获得下标为index的槽位UI
def.method("number", "=>", "userdata").GetFieldUIByIndex = function(self, fieldIndex)
    if self._PageUI == nil then return nil end
    local uiTemplate = self._PageUI:GetComponent(ClassType.UITemplate)
    return uiTemplate:GetControl(fieldIndex - 1)
end

--计算属性，返回{ {[属性ID] = {属性值,属性百分比}, ... }
--{
    --[AttrID] = {AttrValue = 0,AttrPercent = 2},
--}
def.method("=>", "table").CalculateAttrTable = function(self)
    local attrTable = {}
    for i,v in ipairs(self._CharmFields) do
        repeat
            if v ~= nil and v:IsCharmPut() then
                local charmItemTemp = v:GetCharmItemTemplate()
                if charmItemTemp == nil then break end
                if charmItemTemp.PropID1 and charmItemTemp.PropID1 > 0 and charmItemTemp.PropValue1 > 0 then
                    if attrTable[charmItemTemp.PropID1] ~= nil then
                        local attrInfo = attrTable[charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue1
                        end
                    else
                        attrTable[charmItemTemp.PropID1] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then
                            attrInfo.AttrValue = charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = charmItemTemp.PropValue1
                        end
                    end
                end
                if charmItemTemp.PropID2 and charmItemTemp.PropID2 > 0 and charmItemTemp.PropValue2 > 0 then
                    if attrTable[charmItemTemp.PropID2] ~= nil then
                        local attrInfo = attrTable[charmItemTemp.PropID2]
                        if charmItemTemp.PropType2 == 1 then
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue2
                        elseif charmItemTemp.PropType2 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue2
                        end
                    else
                        attrTable[charmItemTemp.PropID2] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[charmItemTemp.PropID2]
                        if charmItemTemp.PropType2 == 1 then
                            attrInfo.AttrValue = charmItemTemp.PropValue2
                        elseif charmItemTemp.PropType2 == 2 then
                            attrInfo.AttrPercent = charmItemTemp.PropValue2
                        end
                    end
                end
            end
        until true;
    end
    local attrList = {}
    for key,value in pairs(attrTable) do
        attrList[#attrList + 1] = {}
        attrList[#attrList].AttrID = key
        attrList[#attrList].AttrValue = value.AttrValue * (1 + value.AttrPercent/10000)
    end
    return attrList
end

--计算当前神符页签总战斗力
def.method("=>", "number").CalculateCombatValue = function(self)
    local combat = 0
    local battle_params = {}
    local attrSet = self:CalculateAttrTable()
    for _,value in ipairs(attrSet) do
        local item = {}
        item.ID = value.AttrID
        item.Value = value.AttrValue
        table.insert(battle_params, item)
    end
    combat = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, battle_params)
    return math.ceil(combat)
end

--更新UI界面
def.method().UpdateUI = function(self)
    local page_temp = CElementData.GetTemplate("CharmPage", self._PageID)
    if self._OpenState == EnumDef.CharmEnum.CharmPageState.Locked then
        self._CharmPage:ShowFieldPageUnlockTip(page_temp.InlockLevel)
        if self._PageUI ~= nil then self._PageUI:SetActive(false) end
    elseif self._OpenState == EnumDef.CharmEnum.CharmPageState.Opened then
        self._CharmPage:HideFieldPageUnlockTip()
        if self._PageUI ~= nil then self._PageUI:SetActive(true) end
        --更新槽位UI
        for k,v in ipairs(self._CharmFields) do
            if v ~= nil then
                v:UpdateUI()
            end
        end
    end
end

-- 一键卸下所有的神符
def.method().PutOffCharms = function(self)
    for _,v in ipairs(self._CharmFields) do
        if (not v:IsLock()) and v:IsCharmPut() then
            v:PutOffCharm()
        end
    end
end

-- 一键穿上所有牛逼的神符
def.method("table", "=>", "boolean").ShortcutPutOnAll = function(self, items)
    local sended = false
    self._CustomItems = {}
    local put_on_batch = {}
    for _,v in ipairs(items) do
        local item = {}
        item._Tid = v._Tid
        item._Slot = v._Slot
        item._Count = v._NormalCount
        item._CharmSize = v._CharmItemTemplate.CharmSize
        item._CharmColor = v._CharmItemTemplate.CharmColor
        item._Combat = CCharmMan.Instance():CalculateCharmItemCombatValue(v._Tid)
        self._CustomItems[#self._CustomItems + 1] = item
    end
    local function sort_items(item1, item2)
        return item1._Combat > item2._Combat
    end
    table.sort(self._CustomItems, sort_items)

    -- 计算各个神符槽位自身装备神符的战斗力
    for _,v in ipairs(self._CharmFields) do
        v:CalculateSelfCombatValue()
    end
    -- 根据神符槽位战斗力排序
    local function sort_by_combat(item1, item2)
        if item1._CharmFieldTemp.CharmSize ~= item2._CharmFieldTemp.CharmSize then
            return item1._CharmFieldTemp.CharmSize > item2._CharmFieldTemp.CharmSize
        else
            if item1._CharmFieldTemp.CharmColor ~= item2._CharmFieldTemp.CharmColor then
                return item1._CharmFieldTemp.CharmColor < item2._CharmFieldTemp.CharmColor
            else
                return item1._CombatNum < item2._CombatNum
            end
        end
    end
    table.sort(self._CharmFields, sort_by_combat)

    for _,v in ipairs(self._CharmFields) do
        if not v:IsLock() then
            local now_select = nil
            for _,w in ipairs(self._CustomItems) do
                if w._Count > 0 and v:CanPutOn(w._Tid) and v:IsBetter(w._Tid) then
                    now_select = w
                    break
                end
            end
            if now_select ~= nil then
                now_select._Count = now_select._Count - 1
                local item = {}
                item.FieldId = v._FieldID
                item.ItemIndex = now_select._Slot
                put_on_batch[#put_on_batch + 1] = item
            end
        end
    end

    if #put_on_batch > 0 then
        CCharmMan.Instance():PutOnBatch(put_on_batch)
        sended = true
    end

    local function sort_by_index(item1, item2)
        return item1._FieldID < item2._FieldID
    end
    table.sort(self._CharmFields, sort_by_index)
    return sended
end

--------------------------红点Start----------------------------
def.method("table", "=>", "boolean").PageShouldShowRedPoint = function(self, items)
    if self._OpenState == EnumDef.CharmEnum.CharmPageState.Locked then return false end
    for i,v in ipairs(self._CharmFields) do
        if v:FieldShouldShowRedPoint(items) then
            return true
        end
    end
    return false
end

def.method("table").UpdateRedPoint = function(self, items)
    for i,v in ipairs(self._CharmFields) do
        v:UpdateRedPoint(items)
    end
end

def.method().HideRedPoint = function(self)
    for i,v in ipairs(self._CharmFields) do
        v:HideRedPoint()
    end
end

--------------------------红点End-------------------------------
def.method().Show = function(self)
    if self._PageUI ~= nil then
        self._PageUI:SetActive(true)
        if select_index > 0 then
            self._CurField = self._CharmFields[select_index]
        else
            self._CurField = self._CharmFields[1]
        end
    end
end

def.method().Hide = function(self)
    if self._PageUI ~= nil then
        self._PageUI:SetActive(false)
    end
    self._CharmPage:HideFieldPageUnlockTip()
end

def.method().Realse = function(self)
    for _,v in ipairs(self._CharmFields) do
        v:Realse()
    end
    self._CharmFields = nil
    self._CurField = nil
    self._PageUI = nil
	self._CustomItems = nil
end

CCharmFieldPage.Commit()
return CCharmFieldPage