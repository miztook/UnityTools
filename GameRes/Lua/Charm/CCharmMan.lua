local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local UserData = require "Data.UserData"
local ECharmSize = require "PB.data".ECharmSize
local ECharmColor = require "PB.data".ECharmColor
local ECharmUnloclType = require "PB.data".ECharmUnloclType
local EItemType = require "PB.Template".Item.EItemType
local CHARM_OPT_TYPE = require "PB.net".CHARM_OPT_TYPE
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local CCharmField = require "Charm.CCharmField"
local CScoreCalcMan = require "Data.CScoreCalcMan"
local CCharmFieldData = require "Charm.CCharmFieldData"
local CharmOptionEvent = require "Events.CharmOptionEvent"

local CCharmMan = Lplus.Class("CCharmMan")
local def = CCharmMan.define

local instance = nil

def.field("table")._RoleCharmFieldsInfo = nil           -- 神符槽位数据
def.field("table")._CharmPageCombatInfo = nil           -- 神符页签战力信息
def.field("table")._PageFieldsInfo = nil                -- 神符页和神符槽位的对应关系
def.field("boolean")._ShowFieldFXAndRedPoint = true     -- 是否显示槽位特效和槽位红点

def.static("=>", CCharmMan).Instance = function()
	if instance == nil then
		instance = CCharmMan()
	end
	return instance
end

----------------------------------------------------------------------
--							Client::Charm Funcs
----------------------------------------------------------------------

local function RefreshPanel(self)
	local CPanelCharm = require "GUI.CPanelCharm"
	if CPanelCharm and CPanelCharm.Instance():IsShow() then
		CPanelCharm.Instance():UpdatePanel()
	end
end

-------------------------------------------------
--增加神符卡槽操作
-------------------------------------------------
local function AddCharmField(self, field)
	local data = CCharmFieldData.new()

	--物品模板
	local itemTemplate = CElementData.GetTemplate("Item", field.ItemTID)
	if itemTemplate == nil then	
        data:Init(field.FieldID, -1, -1)
	elseif itemTemplate ~= nil and itemTemplate.ItemType == EItemType.Charm then
        data:Init(field.FieldID, field.CharmID, field.ItemTID)
	end

    self._RoleCharmFieldsInfo[field.FieldID] = data
end

-------------------------------------------------
--更新卡槽的操作
-------------------------------------------------
local function ChangeCharmField(self, field, bIsTakeOff)
	local charmFieldTemplate = CElementData.GetTemplate("CharmField", field.FieldID)
	if charmFieldTemplate == nil then return end
	if self._RoleCharmFieldsInfo == nil or self._RoleCharmFieldsInfo[field.FieldID] == nil then return end

    local local_field = self._RoleCharmFieldsInfo[field.FieldID]
    if bIsTakeOff then
        local_field:PutDown()
    else
        local_field:PutOn(field.CharmID)
    end
end

-------------------------------------------------
--如果有可以装备的神符或者更牛逼的神符就更新主界面红点显示
-------------------------------------------------
def.method().ShowRedPointIfNeed = function(self)
    local itemSet = game._HostPlayer._Package._NormalPack._ItemSet
    for k,v in pairs(self._RoleCharmFieldsInfo) do
        for i,itemData in ipairs(itemSet) do
            if itemData ~= nil and itemData._Tid ~= 0 then
                if itemData:IsCharm() then
                    if v:NeedChangeCharm(itemData._Tid) then
                        CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Charm, true)
                    end
                end
            end
        end
    end
end

-------------------------------------------------
--重置神符卡槽数据
-------------------------------------------------
def.method("table").InitCharmField = function(self, fields)
	self._RoleCharmFieldsInfo = {}

	for i,field in ipairs( fields ) do
		AddCharmField(self, field)
	end
    self:ShowRedPointIfNeed()
end

-------------------------------------------------
-- 初始化神符页签战力信息
-------------------------------------------------
def.method("table").InitCharmPageCombatInfo = function(self, combats)
    self._CharmPageCombatInfo = {}
    for i,v in ipairs(combats) do
        local page_combat = {}
        page_combat.PageId = v.PageId
        page_combat.FightScore = v.FightScore
        if self._CharmPageCombatInfo[v.PageId] ~= nil then
            self._CharmPageCombatInfo[v.PageId].FightScore = v.FightScore
        else
            self._CharmPageCombatInfo[v.PageId] = page_combat
        end
    end
    RefreshPanel(self)
end

-------------------------------------------------
--初始化神符页和神符槽位的对应关系
-------------------------------------------------
def.method().InitCharmPageField = function(self)
    self._PageFieldsInfo = {}
    local pageIDs = GameUtil.GetAllTid("CharmPage")
    for _,v in ipairs(pageIDs) do
        local page_temp = CElementData.GetTemplate("CharmPage", v)
        if page_temp ~= nil then
            local fieldIDs = string.split(page_temp.CharmFieldIds, '*')
            for _1,v1 in ipairs(fieldIDs) do
                local num_v1 = tonumber(v1)
                if self._PageFieldsInfo[num_v1] == nil then
                    self._PageFieldsInfo[num_v1] = v
                else
                    warn("error !!! 神符页签配置的槽位ID有重复的，重复ID为： ", v1)
                end
            end
        end
    end
end

-------------------------------------------------
--通过卡槽ID查找卡槽数据
-------------------------------------------------
def.method("number", "=>", "table").GetFieldDataByFieldID = function(self, fieldID)
    if self._RoleCharmFieldsInfo == nil or self._RoleCharmFieldsInfo[fieldID] == nil then return nil end
    return self._RoleCharmFieldsInfo[fieldID]
end

-------------------------------------------------
--通过卡槽ID查找所在PageID
-------------------------------------------------
def.method("number", "=>", "number").GetPageIDByFieldID = function(self, fieldID)
    if self._PageFieldsInfo == nil or self._PageFieldsInfo[fieldID] == nil then
        return 0
    end
    return self._PageFieldsInfo[fieldID]
end

-------------------------------------------------
--通过pageid获得该page的战斗力
-------------------------------------------------
def.method("number", "=>", "number").GetPageCombatByPageID = function(self, pageID)
    if self._CharmPageCombatInfo == nil or self._CharmPageCombatInfo[pageID] == nil then
        return 0
    end
    return self._CharmPageCombatInfo[pageID].FightScore
end

------------------------------------------------
--计算属性，返回{ {[属性ID] = {属性值,属性百分比}, ... }
--{
    --[AttrID] = {AttrValue = 0,AttrPercent = 2},
--}
------------------------------------------------
def.method("=>", "table").CalculateAttrTable = function(self)
    local attrTable = {}
    for i,v in pairs(self._RoleCharmFieldsInfo) do
        repeat
            if v ~= nil and v._CharmID ~= -1 then
                local charmItemTemp = CElementData.GetTemplate("CharmItem", v._CharmID)
                local page_id = self:GetPageIDByFieldID(i)
                if attrTable[page_id] == nil then
                    attrTable[page_id] = {}
                end
                if charmItemTemp == nil then break end
                if charmItemTemp.PropID1 and charmItemTemp.PropID1 > 0 and charmItemTemp.PropValue1 > 0 then
                    if attrTable[page_id][charmItemTemp.PropID1] ~= nil then
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then    --（1 是值，2是百分比）
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue1
                        end
                    else
                        attrTable[page_id][charmItemTemp.PropID1] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then
                            attrInfo.AttrValue = charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = charmItemTemp.PropValue1
                        end
                    end
                end
                if charmItemTemp.PropID2 and charmItemTemp.PropID2 > 0 and charmItemTemp.PropValue2 > 0 then
                    if attrTable[page_id][charmItemTemp.PropID2] ~= nil then
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID2]
                        if charmItemTemp.PropType2 == 1 then
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue2
                        elseif charmItemTemp.PropType2 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue2
                        end
                    else
                        attrTable[page_id][charmItemTemp.PropID2] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID2]
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
    for key,value in pairs(attrTable) do
        for k,v in pairs(value) do
            v.AttrValue = v.AttrValue * (1 + v.AttrPercent/10000)
        end
        --value.AttrValue = value.AttrValue * (1 + value.AttrPercent/10000)
    end
    return attrTable
end

------------------------------------------------------
--计算所有神符页签总战斗力
------------------------------------------------------
def.method("=>", "number").CalculateCombatValue = function(self)
    local combat = 0
    local attrSet = self:CalculateAttrTable()
    for key,value in pairs(attrSet) do
        local battle_params = {}
        for k,v in pairs(value) do
            local item = {}
            item.ID = k
            item.Value = v.AttrValue
            table.insert(battle_params, item)
        end
        --combat = combat + CScoreCalcMan.Instance():GetFightPropertyCoefficient(game._HostPlayer._InfoData._Prof, key) * value.AttrValue
        combat = combat + CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, battle_params)
    end
    return math.ceil(combat)
end

------------------------------------------------------
-- 计算单个神符的战斗力
------------------------------------------------------
def.method("number", "=>", "number").CalculateCharmItemCombatValue = function(self, charmID)
    local attrTable = {}
    local charmItemTemp = CElementData.GetTemplate("CharmItem", charmID)
    if charmItemTemp == nil then return 0 end
    if charmItemTemp.PropID1 and charmItemTemp.PropID1 > 0 and charmItemTemp.PropValue1 > 0 then
        if attrTable[charmItemTemp.PropID1] ~= nil then
            local attrInfo = attrTable[charmItemTemp.PropID1]
            if charmItemTemp.PropType1 == 1 then    --（1 是值，2是百分比）
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
    for key,v in pairs(attrTable) do
        v.AttrValue = v.AttrValue * (1 + v.AttrPercent/10000)
    end
    local battle_params = {}
    for k,v in pairs(attrTable) do
        local item = {}
        item.ID = k
        item.Value = v.AttrValue
        table.insert(battle_params, item)
    end
    local combat = CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, battle_params)
    return math.ceil(combat)
end

------------------------------------------------------
-- 计算所有大神符的战斗力
------------------------------------------------------
def.method("=>", "number").CalculateAllBigCharmCombatValue = function(self)
    local combat = 0
    local attrTable = {}
    for i,v in pairs(self._RoleCharmFieldsInfo) do
        repeat
            if v ~= nil and v._CharmID ~= -1 then
                local charmItemTemp = CElementData.GetTemplate("CharmItem", v._CharmID)
                local page_id = self:GetPageIDByFieldID(i)
                if attrTable[page_id] == nil then
                    attrTable[page_id] = {}
                end
                if charmItemTemp.CharmSize ~= ECharmSize.ECharmSize_Big then break end
                if charmItemTemp == nil then break end
                if charmItemTemp.PropID1 and charmItemTemp.PropID1 > 0 and charmItemTemp.PropValue1 > 0 then
                    if attrTable[page_id][charmItemTemp.PropID1] ~= nil then
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then    --（1 是值，2是百分比）
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue1
                        end
                    else
                        attrTable[page_id][charmItemTemp.PropID1] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then
                            attrInfo.AttrValue = charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = charmItemTemp.PropValue1
                        end
                    end
                end
                if charmItemTemp.PropID2 and charmItemTemp.PropID2 > 0 and charmItemTemp.PropValue2 > 0 then
                    if attrTable[page_id][charmItemTemp.PropID2] ~= nil then
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID2]
                        if charmItemTemp.PropType2 == 1 then
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue2
                        elseif charmItemTemp.PropType2 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue2
                        end
                    else
                        attrTable[page_id][charmItemTemp.PropID2] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID2]
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
    local attrSet = self:CalculateAttrTable()
    for key,value in pairs(attrTable) do
        for k,v in pairs(value) do
            v.AttrValue = v.AttrValue * (1 + attrSet[key][k].AttrPercent/10000)
        end
    end
    for key,value in pairs(attrTable) do
        local battle_params = {}
        for k,v in pairs(value) do
            local item = {}
            item.ID = k
            item.Value = v.AttrValue
            table.insert(battle_params, item)
        end
        combat = combat + CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, battle_params)
    end
    return math.ceil(combat)
end

------------------------------------------------------
-- 计算所有小神符的战斗力
------------------------------------------------------
def.method("=>", "number").CalculateAllSmallCharmCombatValue = function(self)
    local combat = 0
    local attrTable = {}
    for i,v in pairs(self._RoleCharmFieldsInfo) do
        repeat
            if v ~= nil and v._CharmID ~= -1 then
                local charmItemTemp = CElementData.GetTemplate("CharmItem", v._CharmID)
                local page_id = self:GetPageIDByFieldID(i)
                if attrTable[page_id] == nil then
                    attrTable[page_id] = {}
                end
                if charmItemTemp.CharmSize ~= ECharmSize.ECharmSize_Small then break end
                if charmItemTemp == nil then break end
                if charmItemTemp.PropID1 and charmItemTemp.PropID1 > 0 and charmItemTemp.PropValue1 > 0 then
                    if attrTable[page_id][charmItemTemp.PropID1] ~= nil then
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then    --（1 是值，2是百分比）
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue1
                        end
                    else
                        attrTable[page_id][charmItemTemp.PropID1] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID1]
                        if charmItemTemp.PropType1 == 1 then
                            attrInfo.AttrValue = charmItemTemp.PropValue1
                        elseif charmItemTemp.PropType1 == 2 then
                            attrInfo.AttrPercent = charmItemTemp.PropValue1
                        end
                    end
                end
                if charmItemTemp.PropID2 and charmItemTemp.PropID2 > 0 and charmItemTemp.PropValue2 > 0 then
                    if attrTable[page_id][charmItemTemp.PropID2] ~= nil then
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID2]
                        if charmItemTemp.PropType2 == 1 then
                            attrInfo.AttrValue = attrInfo.AttrValue + charmItemTemp.PropValue2
                        elseif charmItemTemp.PropType2 == 2 then
                            attrInfo.AttrPercent = attrInfo.AttrPercent + charmItemTemp.PropValue2
                        end
                    else
                        attrTable[page_id][charmItemTemp.PropID2] = {AttrValue = 0, AttrPercent = 0}
                        local attrInfo = attrTable[page_id][charmItemTemp.PropID2]
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
    local attrSet = self:CalculateAttrTable()
    for key,value in pairs(attrTable) do
        --value.AttrValue = value.AttrValue * (1 + attrSet[key].AttrPercent/10000)
        for k,v in pairs(value) do
            v.AttrValue = v.AttrValue * (1 + attrSet[key][k].AttrPercent/10000)
        end
    end

    for key,value in pairs(attrTable) do
        local battle_params = {}
        for k,v in pairs(value) do
            local item = {}
            item.ID = k
            item.Value = v.AttrValue
            table.insert(battle_params, item)
        end
        combat = combat + CScoreCalcMan.Instance():CalcEquipScore(game._HostPlayer._InfoData._Prof, battle_params)
    end
    return math.ceil(combat)
end

------------------------------------------------------
--根据槽位tid得出开启条件的描述
------------------------------------------------------
def.method("number", "=>", "string").CalcFieldOpenNeedDesc = function(self, fieldID)
	local msg = ""
    local fieldTemplate = CElementData.GetTemplate("CharmField", fieldID)
    if fieldTemplate then
        msg = string.format(StringTable.Get(19315), fieldTemplate.UnlockLevel)
    else
        msg = string.format(StringTable.Get(19350), fieldID)
    end
    return msg
end

def.method("dynamic", "number", "=>", "boolean").CompareTwoCharmItem = function(self, id1, id2)
    if id1 == nil and id2 ~= nil then return true end
    if type(id1) ~= "number" or type(id2) ~= "number" then
        warn("error !!! 要比较的两个神符ID必须为Number类型")
        return false
    end
    if id1 <= 0 and id2 > 0 then return true end
    if id1 == id2 then return false end
    local temp1 = CElementData.GetTemplate("CharmItem", id1)
    local temp2 = CElementData.GetTemplate("CharmItem", id2)
    if temp1 == nil or temp2 == nil then
        warn("error !!! 要比较的两个神符的模板数据有的为null")
        return false
    end
    if temp1.CharmSize == temp2.CharmSize then
        if temp1.CharmSize == ECharmSize.ECharmSize_Big then
            if temp1.PropID1 == nil and temp2.PropID1 ~= nil then
                return true
            elseif temp1.PropID2 == nil and temp2.PropID2 ~= nil then
                return true
            end
            if temp1.PropID1 == temp2.PropID1 and temp1.PropID2 == temp2.PropID2 then
                if temp1.PropValue1 < temp2.PropValue1 and temp1.PropValue2 < temp2.PropValue2 then
                    return true
                end
            end
        else
            if temp1.PropID1 == nil and temp2.PropID1 ~= nil then
                return true
            elseif temp1.PropID2 == nil and temp2.PropID2 ~= nil then
                return true
            end
            if temp1.PropID1 == temp2.PropID1 then
                if temp1.PropValue1 < temp2.PropValue1 then return true end
            elseif temp1.PropID2 == temp2.PropID2 then
                if temp1.PropValue2 < temp2.PropValue2 then return true end
            end
        end
    end
    return false
end

-- 获得是否显示神符合成特效的玩家偏好
def.method("=>", "boolean").GetCharmComposeSkipGfx = function(self)
    local account = game._NetMan._UserName
    local curLocalField = EnumDef.LocalFields.CharmSkipGfx_Compose
    return UserData.Instance():GetCfg(curLocalField, account) or false
end

-- 设置是否显示神符合成特效的玩家偏好
def.method("boolean").SetCharmComposeSkipGfx = function(self, bSkip)
    local oldShow = self:GetCharmComposeSkipGfx()
    if oldShow == bSkip then
        return
    end
    local account = game._NetMan._UserName
    local curLocalField = EnumDef.LocalFields.CharmSkipGfx_Compose
    UserData.Instance():SetCfg(curLocalField, account, bSkip)
end
		
----------------------------------------------------------------------
--							C2S::S2Charm Funcs
----------------------------------------------------------------------

--镶嵌
def.method("number", "number").PutOn = function(self, fieldID, charmItemSlot)
	local C2SCharmPutOn = require "PB.net".C2SCharmPutOn
	local protocol = C2SCharmPutOn()
	protocol.FieldId = fieldID
	protocol.ItemIndex = charmItemSlot
	SendProtocol(protocol)
end

--拆除
def.method("number").PutOff = function(self, fieldID)
	local C2SCharmTakeOff = require "PB.net".C2SCharmTakeOff
	local protocol = C2SCharmTakeOff()
	protocol.FieldId = fieldID
	SendProtocol(protocol)
end

--一键穿上所有牛逼的神符
def.method("table").PutOnBatch = function(self, charms)
    local C2SCharmPutOnBatch = require "PB.net".C2SCharmPutOnBatch
    local CharmPutOnStruct = require "PB.net".CharmPutOnStruct
    local protocol = C2SCharmPutOnBatch()
    for i,v in ipairs(charms) do
        local batch = CharmPutOnStruct()
        batch.FieldId = v.FieldId
        batch.ItemIndex = v.ItemIndex
        table.insert(protocol.Charms, batch)
    end
    SendProtocol(protocol)
end

--合成
def.method("number", "number").Compose = function(self, charmTid, count)
    local C2SCharmCompose = require "PB.net".C2SCharmCompose
    local protocol = C2SCharmCompose()
    protocol.CharmTid = charmTid
    protocol.CharmFieldId = 0
    protocol.Count = count
    SendProtocol(protocol)
end

-- 槽位合成
def.method("number", "number", "number").FieldCompose = function(self, fieldID, charmTid, count)
    local C2SCharmCompose = require "PB.net".C2SCharmCompose
    local protocol = C2SCharmCompose()
    protocol.CharmTid = charmTid
    protocol.CharmFieldId = fieldID
    protocol.Count = count
    SendProtocol(protocol)
end

----------------------------------------------------------------------
--							S2C::S2Charm Funcs
----------------------------------------------------------------------

------------------------------------------------
--合成回调
------------------------------------------------
def.method("table", "boolean").CharmComposeResult = function(self, msg, isSuccess)
    local data = {}
    local callback = function()
        local CharmOptionEvent = require "Events.CharmOptionEvent"
        local event = CharmOptionEvent()
        event._CharmID = msg.NewCharmTid

        if msg.CharmFieldId and msg.CharmFieldId > 0 then
            if isSuccess then
                local field = self:GetFieldDataByFieldID(msg.CharmFieldId)
                field:PutOn(msg.NewCharmTid)
            end
            event._Option = "FieldCompose"
        else
            event._Option = "Compose" 
        end
        CGame.EventManager:raiseEvent(nil, event)
	    RefreshPanel(self)
         -- 同步到系统聊天通知
        local ChatManager = require "Chat.ChatManager"
        local msg = ""
        if isSuccess then
            msg = string.format(StringTable.Get(19356), RichTextTools.GetItemNameRichText(data.NewCharmTid, 1, false))
        else
            msg = StringTable.Get(19357)
        end
        ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelSystem, msg, false, 0, nil,nil)
    end
    data.NewCharmTid = msg.NewCharmTid
    data.OldCharmTid = msg.OldCharmTid
    data.IsSuccess = isSuccess
    data.Count = msg.Count
    data.CallBack = callback
    game._GUIMan:Open("CPanelCharmComposeResult",data)

   
    CSoundMan.Instance():Play2DAudio(PATH.GUISound_EquipProcessing_Start, 0)    
end

------------------------------------------------
--更新神符卡槽数据
------------------------------------------------
def.method("table", "number", "number").UpdateCharmField = function(self, field, optType, oldCharmID)
    local CharmOptionEvent = require "Events.CharmOptionEvent"
	local event = CharmOptionEvent()
    event._FieldID = field.FieldID
	if CHARM_OPT_TYPE.CHARM_OPT_PUTON == optType then
        if oldCharmID and oldCharmID > 0 then
            ChangeCharmField(self, field)
            event._Option = "Change"
            event._CharmID = field.CharmID
        else
		    ChangeCharmField(self, field)
            event._Option = "PutOn"
            event._CharmID = field.CharmID
        end
        game._GUIMan:ShowTipText(StringTable.Get(19358), true)
	elseif CHARM_OPT_TYPE.CHARM_OPT_TAKEOFF == optType then
        ChangeCharmField(self, field, true)
        event._Option = "PutOff"
        game._GUIMan:ShowTipText(StringTable.Get(19361), true)
	elseif CHARM_OPT_TYPE.CHARM_OPT_UNLOCK == optType then
		AddCharmField(self, field)
        event._Option = "Unlock"
	end
    event._OldCharmID = oldCharmID
	CGame.EventManager:raiseEvent(nil, event)
	RefreshPanel(self)
end

------------------------------------------------
--一键穿上回调
------------------------------------------------
def.method("table").S2CCharmPutOnBatch = function(self, fields)
    if fields == nil or #fields == 0 then
        return
    end
    for i,v in ipairs(fields) do
        local field = self:GetFieldDataByFieldID(v.FieldID)
        if field ~= nil then
            field:PutOn(v.CharmID)
        end
    end
    local Fields = {}
    for i,v in ipairs(fields) do
        local item = {}
        item.FieldID = v.FieldID
        item.CharmID = v.CharmID
        item.ItemTID = v.ItemTID
        Fields[#Fields + 1] = item
    end
    local CharmOptionEvent = require "Events.CharmOptionEvent"
    local event = CharmOptionEvent()
    event._Option = "PutOnBatch"
    event._Fields = Fields
    CGame.EventManager:raiseEvent(nil, event)
    RefreshPanel(self)
end

----------------------------------------------------------------------
--当前穿戴的铭符数量和
----------------------------------------------------------------------
def.method("=>", "number").GetTotalSmallCharmCount = function(self)
    local totalCount = 0
    for i,v in ipairs(self._RoleCharmFieldsInfo) do
        if not v:IsBigField() and v._CharmID ~= -1 then
            totalCount = totalCount + 1
        end
    end
    return totalCount
end

----------------------------------------------------------------------
--当前穿戴的神符数量和
----------------------------------------------------------------------
def.method("=>", "number").GetTotalBigCharmCount = function(self)
    local totalCount = 0
    for i,v in ipairs(self._RoleCharmFieldsInfo) do
        if v:IsBigField() and v._CharmID ~= -1 then
            totalCount = totalCount + 1
        end
    end
    return totalCount
end

----------------------------------------------------------------------
--计算神符的战斗力加成
----------------------------------------------------------------------
def.method("=>", "number").GetBigCharmCombatValue = function(self)
   -- local proInfo = self:CalcPropertyInfo()
    return 0
end

----------------------------------------------------------------------
--计算铭符的战斗力加成
----------------------------------------------------------------------
def.method("=>", "number").GetSmallCharmCombatValue = function(self)

    return 0
end

CCharmMan.Commit()
return CCharmMan