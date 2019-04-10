local Lplus = require "Lplus"
local CCharmPageBase = require "Charm.CCharmPageBase"
local CCharmFieldPage = require "Charm.CCharmFieldPage"
local CElementData = require "Data.CElementData"
local CCharmMan = require "Charm.CCharmMan"
local Data = require "PB.data"
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local CCommonBtn = require "GUI.CCommonBtn"

local CCharmPageCompose = Lplus.Extend(CCharmPageBase, "CCharmPageCompose")
local def = CCharmPageCompose.define

local ComposeType = {
    NomalCompose = 1,       -- 普通的点选合成
    FieldCompose = 2,       -- 合成槽位上的神符
    Max          = 3,       -- 站位
}

def.field("table")._CharmShowItems = BlankTable     -- 当前神符槽位可以选择的神符
def.field("table")._CharmAttrItems = BlankTable     -- 在_CharmShowItems之上过滤当前选择的属性drop的神符
def.field("table")._CharmAttrTable = nil            -- 所有背包神符属性，用来设置drop
def.field("table")._MainCharmItemID = nil           -- 放置的主神符ID
def.field("table")._MatItemID1 = nil                -- 放置的材料神符1ID
def.field("table")._MatItemID2 = nil                -- 放置的材料神符2ID
def.field("number")._SelectedIndex = 1              -- 当前选择的神符槽位（默认主神符槽位）
def.field("number")._CurrentAttrID = -1             -- 当前dropdown的属性id
def.field("boolean")._IsSelecting = false           -- 当前这个槽位有没有被选中
def.field("boolean")._IsScriptDropdown = false      -- 代码正在操作dropdown
def.field("boolean")._IsScriptToggle = false        -- 代码正在操作Toggle
def.field("boolean")._NeedShowSkipFX = false     -- 需要播放合成特效
def.field("number")._ComposeType = 1                -- 当前合成类型（普通合成/合成槽位上的神符）
def.field("number")._FieldID = 0                    -- 合成类型是槽位合成的时候的槽位ID
def.field("number")._MatCostID = 0                  -- 合成需要的材料ID
def.field("number")._ComposeFxTimer = 0             -- 特效timer
def.field(CCommonBtn)._Btn_Compose = nil            -- 合成按钮对象

def.static("=>", CCharmPageCompose).new = function()
    local obj = CCharmPageCompose()
    return obj
end

def.override().OnCreate = function(self)
    if self._PanelCharm == nil then return end
    self._GameObject = self._PanelCharm:GetUIObject("Frame_Compose")
    self._PanelObject._Img_BGFXPoint = self._GameObject:FindChild("Tab_ComposeInfo/Img_BG_01/Img_BG")
    self._PanelObject._Tab_HaveCharm = self._PanelCharm:GetUIObject("Tab_HaveCharm")
    self._PanelObject._Tab_HaveNoCharm = self._PanelCharm:GetUIObject("Tab_HaveNoCharm")
    self._PanelObject._Tab_Fields = self._PanelCharm:GetUIObject("Tab_Fields")
    self._PanelObject._Rdo_MainMaterial = self._PanelCharm:GetUIObject("Rdo_MainMaterial")
    self._PanelObject._Rdo_LeftMaterial = self._PanelCharm:GetUIObject("Rdo_LeftMaterial")
    self._PanelObject._Rdo_RightMaterial = self._PanelCharm:GetUIObject("Rdo_RightMaterial")
    self._PanelObject._Lab_ComposeSuccessRate = self._PanelCharm:GetUIObject("Lab_ComposeSuccessRate")
    self._PanelObject._Tab_Info = self._PanelCharm:GetUIObject("Tab_Info")
    self._PanelObject._Lab_NoCharm = self._PanelCharm:GetUIObject("Lab_NoCharm")
    self._PanelObject._Tab_AttrInfo1 = self._PanelCharm:GetUIObject("Tab_AttrInfo1")
    self._PanelObject._Tab_AttrInfo2 = self._PanelCharm:GetUIObject("Tab_AttrInfo2")
    self._PanelObject._Tab_CostInfo = self._PanelCharm:GetUIObject("Tab_CostInfo")
    self._PanelObject._Tab_ComposeLevelInfo = self._PanelCharm:GetUIObject("Tab_ComposeLevelInfo")
    self._PanelObject._Btn_PutOnAll = self._PanelCharm:GetUIObject("Btn_PutOnAll")
    self._PanelObject._Btn_ShowDetail = self._PanelCharm:GetUIObject("Btn_ShowDetail")
    self._PanelObject._Frame_DropDown = self._PanelCharm:GetUIObject("Drop_Group_Ride")
    self._PanelObject._Btn_Compose = self._PanelCharm:GetUIObject("Btn_Compose")
    self._PanelObject._List_CharmList = self._PanelCharm:GetUIObject("List_CharmList")
    self._PanelObject._Tab_FieldsGroup = self._PanelCharm:GetUIObject("Tab_Fields")
    self._PanelObject._Rdo_ShowGfx = self._PanelCharm:GetUIObject("Toggle_ShowGfx")
    self._PanelObject._Img_Mask_BG = self._PanelCharm:GetUIObject("Img_MaskBG")
    self._PanelObject._Img_Mask_BG:SetActive(false)
    self._Btn_Compose = CCommonBtn.new(self._PanelObject._Btn_Compose, nil)
end

-- data = { itemID = 111, Slot = 111, ComposeType = 1 }
def.override("dynamic").OnData = function(self, data)
    CCharmPageBase.OnData(self, data)
    if data ~= nil then
        self._MainCharmItemID = {_Tid = data.itemID, _Slot = data.Slot}
        self._SelectedIndex = 1
        self._ComposeType = data.ComposeType or ComposeType.NomalCompose
    end
    self._NeedShowSkipFX = CCharmMan.Instance():GetCharmComposeSkipGfx()
    self._PanelObject._Rdo_ShowGfx:GetComponent(ClassType.Toggle).isOn = self._NeedShowSkipFX
    self._CurrentAttrID = -1
    self._IsScriptDropdown = false
    self:SetShowCharmItems()
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    self._IsScriptDropdown = false
end

-- data = { itemID = 111, fieldID = 111, ComposeType = 1, Slot = 111}
def.override("dynamic").ShowPage = function(self, data)
    CCharmPageBase.ShowPage(self, data)
    if data ~= nil then
        self._ComposeType = data.ComposeType
        self._FieldID = data.fieldID or 0
        if self._ComposeType == ComposeType.FieldCompose then
            self:ReplaceMainField(data.itemID, nil)
        elseif self._ComposeType == ComposeType.NomalCompose then
            self:ReplaceMainField(data.itemID, data.Slot)
        end
        self._SelectedIndex = 2
    end
    self._CurrentAttrID = -1
    self._IsScriptDropdown = false
    GUI.SetGroupToggleOn(self._PanelObject._Tab_FieldsGroup, self._SelectedIndex)
    self:SetShowCharmItems()
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    self:RefreshPageUI()
end

def.override().ShowUIFX = function(self)
    if self._PanelObject._Img_BGFXPoint == nil then return end
    GameUtil.PlayUISfx(PATH.UIFX_CharmComposeBGFX, self._PanelObject._Img_BGFXPoint, self._PanelObject._Img_BGFXPoint, -1)
end

def.override().HideUIFX = function(self)
    GameUtil.StopUISfx(PATH.UIFX_CharmComposeBGFX, self._PanelObject._Img_BGFXPoint)
end

def.method("number").OnToggleByScript = function(self, index)
    if index > 3 then return end
    self._IsScriptToggle = true
    if index == 1 then
        self:OnToggle("Rdo_MainMaterial", true)
    elseif index == 2 then
        self:OnToggle("Rdo_LeftMaterial", true)
    elseif index == 3 then
        self:OnToggle("Rdo_RightMaterial", true)
    end
    GUI.SetGroupToggleOn(self._PanelObject._Tab_FieldsGroup, index)
end

--根据属性ID对Items进行过滤
def.method("number").SelectCharmsByAttrID = function(self, attrID)
    self._CharmAttrItems = {}
    local mainTag = false
    local matTag1 = false
    local matTag2 = false
    if attrID <= 0 then 
        for _,v in ipairs(self._CharmShowItems) do
            repeat
                local item = {}
                item.Count = v:GetCount()
                item.Slot = v._Slot
                if self._MainCharmItemID ~= nil and v._Tid == self._MainCharmItemID._Tid and v._Slot == self._MainCharmItemID._Slot and mainTag == false then
                    item.Count = item.Count - 1
                    mainTag = true
                    if item.Count <= 0 then break end
                end
                if self._MatItemID1 ~= nil and v._Tid == self._MatItemID1._Tid and v._Slot == self._MatItemID1._Slot and matTag1 == false then
                    item.Count = item.Count - 1
                    matTag1 = true
                    if item.Count <= 0 then break end
                end
                if self._MatItemID2 ~= nil and v._Tid == self._MatItemID2._Tid and self._MatItemID2._Slot and matTag2 == false then
                    item.Count = item.Count - 1
                    matTag2 = true
                    if item.Count <= 0 then break end
                end
                item.CharmItem = v
                self._CharmAttrItems[#self._CharmAttrItems + 1] = item
            until true;
        end
    else
        for _,v in ipairs(self._CharmShowItems) do
            repeat
                if v._CharmItemTemplate.PropID1 == self._CurrentAttrID or v._CharmItemTemplate.PropID2 == self._CurrentAttrID then
                    local item = {}
                    item.Count = v:GetCount()
                    item.Slot = v._Slot
                    if self._MainCharmItemID ~= nil and v._Tid == self._MainCharmItemID._Tid and v._Slot == self._MainCharmItemID._Slot then
                        item.Count = item.Count - 1
                        if item.Count <= 0 then break end
                    end
                    if self._MatItemID1 ~= nil and v._Tid == self._MatItemID1._Tid and v._Slot == self._MatItemID1._Slot then
                        item.Count = item.Count - 1
                        if item.Count <= 0 then break end
                    end
                    if self._MatItemID2 ~= nil and v._Tid == self._MatItemID2._Tid and v._Slot == self._MatItemID2._Slot then
                        item.Count = item.Count - 1
                        if item.Count <= 0 then break end
                    end
                    item.CharmItem = v
                    self._CharmAttrItems[#self._CharmAttrItems + 1] = item
                end
            until true;
        end
    end
    self:SortAttrCharmItems()
end

-- 添加到属性过滤table中，根据dropdown来过滤的。
def.method("number", "dynamic").AddToAttrItemsTable = function(self, itemID, slot)
    for i,v in ipairs(self._CharmAttrItems) do
        if v.CharmItem._Tid == itemID and v.Slot == slot then
            v.Count = v.Count + 1
            return
        end
    end
    local item = {}
    item.Count = 1
    item.Slot = slot
    if slot ~= nil then
        item.CharmItem = game._HostPlayer._Package._NormalPack:GetItemBySlot(slot)
    else
        item.CharmItem = CIvtrItem.CreateVirtualItem(itemID)
    end
    self._CharmAttrItems[#self._CharmAttrItems + 1] = item
    self:SortAttrCharmItems()
end

-- 从属性Items Table中删除。
def.method("number", "number").MinusAttrItemsTable = function(self, itemID, slot)
    if itemID <= 0 then return end
    for i=#self._CharmAttrItems, 1, -1 do
        local v = self._CharmAttrItems[i]
        if v.CharmItem._Tid == itemID and v.Slot == slot then
            v.Count = v.Count - 1
            if v.Count <= 0 then
                table.remove(self._CharmAttrItems, i)
            end
            return
        end
    end
end

-- 清除材料神符槽位的内容
def.method().ClearMat1AndMat2 = function(self)
    if self._MatItemID1 ~= nil then
        self:AddToAttrItemsTable(self._MatItemID1._Tid, self._MatItemID1._Slot)
    end
    if self._MatItemID2 ~= nil then
        self:AddToAttrItemsTable(self._MatItemID2._Tid, self._MatItemID2._Slot)
    end
    self._MatItemID1 = nil
    self._MatItemID2 = nil
end

-- 替换主神符合成槽位的物品
def.method("number", "dynamic").ReplaceMainField = function(self, itemID, slot)
    if self._MainCharmItemID ~= nil then
        if self._ComposeType == ComposeType.NomalCompose then
            self:AddToAttrItemsTable(self._MainCharmItemID._Tid, self._MainCharmItemID._Slot)
        end
        self._MainCharmItemID = nil
    end
    if self._ComposeType == ComposeType.NomalCompose then
        self:MinusAttrItemsTable(itemID, slot)
    end

    self._MainCharmItemID = {_Tid = itemID, _Slot = slot}
end

-- 替换副材料神符槽位1 的物品
def.method("number", "number").ReplaceField1 = function(self, itemID, slot)
    if self._MatItemID1 ~= nil then
        self:AddToAttrItemsTable(self._MatItemID1._Tid, self._MatItemID1._Slot)
        self._MatItemID1 = nil
    end
    self:MinusAttrItemsTable(itemID, slot)
    self._MatItemID1 = {_Tid = itemID, _Slot = slot}
end

-- 替换副材料神符槽位2 的物品
def.method("number", "number").ReplaceField2 = function(self, itemID, slot)
    if self._MatItemID2 ~= nil then
        self:AddToAttrItemsTable(self._MatItemID2._Tid, self._MatItemID2._Slot)
        self._MatItemID2 = nil
    end
    self:MinusAttrItemsTable(itemID, slot)
    self._MatItemID2 = {_Tid = itemID, _Slot = slot}
end

--针对选择好的神符进行排序，优先级是（神符大小，神符颜色，神符等级，属性ID）
def.method().SortAttrCharmItems = function(self)
    local func = function(item1, item2)
        if item1.CharmItem._CharmItemTemplate.Level ~= item2.CharmItem._CharmItemTemplate.Level then
            return item1.CharmItem._CharmItemTemplate.Level > item2.CharmItem._CharmItemTemplate.Level
        else
            if item1.CharmItem._CharmItemTemplate.CharmSize ~= item2.CharmItem._CharmItemTemplate.CharmSize then
                return item1.CharmItem._CharmItemTemplate.CharmSize > item2.CharmItem._CharmItemTemplate.CharmSize
            else
                if item1.CharmItem._CharmItemTemplate.CharmColor ~= item2.CharmItem._CharmItemTemplate.CharmColor then
                    return item1.CharmItem._CharmItemTemplate.CharmColor < item2.CharmItem._CharmItemTemplate.CharmColor
                else
                    if item1.CharmItem._CharmItemTemplate.Id ~= item2.CharmItem._CharmItemTemplate.Id then
                        return item1.CharmItem._CharmItemTemplate.Id > item2.CharmItem._CharmItemTemplate.Id
                    end
                end
            end
        end
        return false
    end
    table.sort(self._CharmAttrItems, func)
end

--根据当前选择的合成位置，过滤右边显示的神符
def.method().SetShowCharmItems = function(self)
    self:GetAllCharmItems()
    if self._SelectedIndex == 1 then
        self._CharmShowItems = {}
        for _,v in ipairs(self._CharmItems) do
            local charm_temp = CElementData.GetTemplate("CharmItem", v._Tid)
            if charm_temp.Level < self._PanelCharm._CharmMaxLevel then
                self._CharmShowItems[#self._CharmShowItems + 1] = v
            end
        end
    else
        if self._MainCharmItemID ~= nil then
            self._CharmShowItems = {}
            local select_charm_temp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID._Tid)
            if select_charm_temp == nil then warn(" error CCharmPageCompose SetShowChgarmItems()  找不到神符ID", self._MainCharmItemID._Tid) end
            for _,v in ipairs(self._CharmItems) do
                local charmTemp = CElementData.GetTemplate("CharmItem", v._Tid)
                if select_charm_temp.Level == charmTemp.Level and select_charm_temp.CharmSize == charmTemp.CharmSize
                            and charmTemp.Level < self._PanelCharm._CharmMaxLevel and select_charm_temp.CharmColor == charmTemp.CharmColor then
                    self._CharmShowItems[#self._CharmShowItems + 1] = v
                end
            end
        end
    end
end

--根据要显示的神符来确定dropdown的信息并存到属性table中
def.method().GetAttrTableByShowCharmItems = function(self)
    local charm_attr = {}
    self._CharmAttrTable = {}
    for _,v in ipairs(self._CharmShowItems) do
        local template = v._CharmItemTemplate
        if template then
            if template.PropID1 ~= nil and template.PropID1 > 0 then
                charm_attr[template.PropID1] = true
            end
            if template.PropID2 ~= nil and template.PropID2 > 0 then
                charm_attr[template.PropID2] = true
            end
        end
    end
    for k,v in pairs(charm_attr) do
        self._CharmAttrTable[#self._CharmAttrTable + 1] = k
    end
    self._CharmAttrTable[#self._CharmAttrTable + 1] = -1
end

-- 根据属性table信息来设置dropdown
def.method().SetDropDownInfo = function(self)
    local dropText = ""
    for _,v in ipairs(self._CharmAttrTable) do
        if v ~= -1 and v ~= nil then
            local attrTemp = CElementData.GetAttachedPropertyTemplate(v)
            dropText = dropText .. attrTemp.TextDisplayName ..","
        end
    end
    dropText = dropText .. StringTable.Get(20500)
    self._IsScriptDropdown = true
    -- 设置下拉菜单层级

    --GameUtil.AdjustDropdownRect(self._PanelObject._Frame_DropDown, #self._CharmAttrTable)
    GUI.SetDropDownOption(self._PanelObject._Frame_DropDown, dropText)
    GameUtil.SetDropdownValue(self._PanelObject._Frame_DropDown, #self._CharmAttrTable - 1)

    local dropTemplate = self._PanelObject._Frame_DropDown:FindChild("Drop_Template")
    GUITools.SetupDropdownTemplate(self._PanelCharm, dropTemplate)
end

-- 更新槽位UI
def.method().UpdateFieldsUI = function(self)
    if self._MainCharmItemID ~= nil then
        local item_icon = self._PanelObject._Rdo_MainMaterial:FindChild("Img_Icon")
        local btn_take_off = self._PanelObject._Rdo_MainMaterial:FindChild("Btn_TakeOff1")
        local field_bg = self._PanelObject._Rdo_MainMaterial:FindChild("Img_Quality")
        local img_icon_bg = self._PanelObject._Rdo_MainMaterial:FindChild("Img_QualityBG")
        self._PanelObject._Rdo_MainMaterial:FindChild("Img_Plus"):SetActive(false)
        item_icon:SetActive(true)
        local itemTemp = CElementData.GetItemTemplate(self._MainCharmItemID._Tid)
        GUITools.SetItemIcon(item_icon, itemTemp.IconAtlasPath)
        GUITools.SetGroupImg(field_bg, itemTemp.InitQuality)
        GUITools.SetGroupImg(img_icon_bg, itemTemp.InitQuality)
        btn_take_off:SetActive(true)
    else
        self._PanelObject._Rdo_MainMaterial:FindChild("Img_Icon"):SetActive(false)
        self._PanelObject._Rdo_MainMaterial:FindChild("Img_Plus"):SetActive(true)
        self._PanelObject._Rdo_MainMaterial:FindChild("Btn_TakeOff1"):SetActive(false)
        GUITools.SetGroupImg(self._PanelObject._Rdo_MainMaterial:FindChild("Img_QualityBG"), 0)
        GUITools.SetGroupImg(self._PanelObject._Rdo_MainMaterial:FindChild("Img_Quality"), 0)
    end
    if self._MatItemID1 ~= nil then
        local item_icon = self._PanelObject._Rdo_LeftMaterial:FindChild("Img_Icon")
        local btn_take_off = self._PanelObject._Rdo_LeftMaterial:FindChild("Btn_TakeOff2")
        local field_bg = self._PanelObject._Rdo_LeftMaterial:FindChild("Img_Quality")
        local img_icon_bg = self._PanelObject._Rdo_LeftMaterial:FindChild("Img_QualityBG")
        self._PanelObject._Rdo_LeftMaterial:FindChild("Img_Plus"):SetActive(false)
        item_icon:SetActive(true)
        local itemTemp = CElementData.GetItemTemplate(self._MatItemID1._Tid)
        GUITools.SetItemIcon(item_icon, itemTemp.IconAtlasPath)
        GUITools.SetGroupImg(field_bg, itemTemp.InitQuality)
        GUITools.SetGroupImg(img_icon_bg, itemTemp.InitQuality)
        btn_take_off:SetActive(true)
    else
        self._PanelObject._Rdo_LeftMaterial:FindChild("Img_Icon"):SetActive(false)
        self._PanelObject._Rdo_LeftMaterial:FindChild("Img_Plus"):SetActive(true)
        self._PanelObject._Rdo_LeftMaterial:FindChild("Btn_TakeOff2"):SetActive(false)
        GUITools.SetGroupImg(self._PanelObject._Rdo_LeftMaterial:FindChild("Img_QualityBG"), 0)
        GUITools.SetGroupImg(self._PanelObject._Rdo_LeftMaterial:FindChild("Img_Quality"), 0)
    end
    if self._MatItemID2 ~= nil then
        local item_icon = self._PanelObject._Rdo_RightMaterial:FindChild("Img_Icon")
        local btn_take_off = self._PanelObject._Rdo_RightMaterial:FindChild("Btn_TakeOff3")
        local field_bg = self._PanelObject._Rdo_RightMaterial:FindChild("Img_Quality")
        local img_icon_bg = self._PanelObject._Rdo_RightMaterial:FindChild("Img_QualityBG")
        self._PanelObject._Rdo_RightMaterial:FindChild("Img_Plus"):SetActive(false)
        item_icon:SetActive(true)
        local itemTemp = CElementData.GetItemTemplate(self._MatItemID2._Tid)
        GUITools.SetItemIcon(item_icon, itemTemp.IconAtlasPath)
        GUITools.SetGroupImg(field_bg, itemTemp.InitQuality)
        GUITools.SetGroupImg(img_icon_bg, itemTemp.InitQuality)
        btn_take_off:SetActive(true)
    else
        self._PanelObject._Rdo_RightMaterial:FindChild("Img_Icon"):SetActive(false)
        self._PanelObject._Rdo_RightMaterial:FindChild("Img_Plus"):SetActive(true)
        self._PanelObject._Rdo_RightMaterial:FindChild("Btn_TakeOff3"):SetActive(false)
        GUITools.SetGroupImg(self._PanelObject._Rdo_RightMaterial:FindChild("Img_QualityBG"), 0)
        GUITools.SetGroupImg(self._PanelObject._Rdo_RightMaterial:FindChild("Img_Quality"), 0)
    end
end

-- 更新合成信息UI
def.method().UpdateComposeInfoUI1 = function(self)
    if self._MainCharmItemID ~= nil then
        self._PanelObject._Lab_ComposeSuccessRate:SetActive(true)
        self._PanelObject._Tab_Info:SetActive(true)
        self._PanelObject._Lab_NoCharm:SetActive(false)
        local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID._Tid)
        local targetTemp = CElementData.GetTemplate("CharmItem", inlayTemp.TargetCharmId)
        local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayTemp.UpgradeTargetId)
        if inlayTemp ~= nil then
            if  inlayTemp.PropID1 and inlayTemp.PropID1 > 0 then
                self._PanelObject._Tab_AttrInfo1:SetActive(true)
                local propTemp1 = CElementData.GetAttachedPropertyTemplate(inlayTemp.PropID1)
                GUI.SetText(self._PanelObject._Tab_AttrInfo1:FindChild("Lab_AttrName1"), propTemp1.TextDisplayName)
                if inlayTemp.PropType1 == 1 then
                    GUI.SetText(self._PanelObject._Tab_AttrInfo1:FindChild("Lab_OldValue1"), inlayTemp.PropValue1.."")
                elseif inlayTemp.PropType1 == 2 then
                    local value = inlayTemp.PropValue1/100
                    GUI.SetText(self._PanelObject._Tab_AttrInfo1:FindChild("Lab_OldValue1"), string.format(StringTable.Get(21703), value))
                end
            else
                self._PanelObject._Tab_AttrInfo1:SetActive(false)
            end
            if inlayTemp.PropID2 and inlayTemp.PropID2 > 0 then
                self._PanelObject._Tab_AttrInfo2:SetActive(true)
                local propTemp2 = CElementData.GetAttachedPropertyTemplate(inlayTemp.PropID2)
                GUI.SetText(self._PanelObject._Tab_AttrInfo2:FindChild("Lab_AttrName2"), propTemp2.TextDisplayName)
                if inlayTemp.PropType2 == 1 then
                    GUI.SetText(self._PanelObject._Tab_AttrInfo2:FindChild("Lab_OldValue2"), inlayTemp.PropValue2.."")
                elseif inlayTemp.PropType2 == 2 then
                    local value = inlayTemp.PropValue2/100
                    GUI.SetText(self._PanelObject._Tab_AttrInfo2:FindChild("Lab_OldValue2"), string.format(StringTable.Get(21703), value))
                end
            else
                self._PanelObject._Tab_AttrInfo2:SetActive(false)
            end
            GUI.SetText(self._PanelObject._Tab_ComposeLevelInfo:FindChild("Lab_OldLevel"), inlayTemp.Level.."")
        end
        if targetTemp ~= nil then
            if targetTemp.PropID1 and targetTemp.PropID1 > 0 then
                local lab_newvalue1 = self._PanelObject._Tab_AttrInfo1:FindChild("Lab_NewValue1")
                lab_newvalue1:SetActive(true)
                if targetTemp.PropType1 == 1 then
                    GUI.SetText(lab_newvalue1, targetTemp.PropValue1.."")
                elseif targetTemp.PropType1 == 2 then
                    local value = targetTemp.PropValue1/100
                    GUI.SetText(lab_newvalue1, string.format(StringTable.Get(21703), value))
                end
            else
                self._PanelObject._Tab_AttrInfo1:FindChild("Lab_NewValue1"):SetActive(false)
            end
            if targetTemp.PropID2 and targetTemp.PropID2 > 0 then
                local lab_newvalue2 = self._PanelObject._Tab_AttrInfo2:FindChild("Lab_NewValue2")
                lab_newvalue2:SetActive(true)
                if targetTemp.PropType2 == 1 then
                    GUI.SetText(lab_newvalue2, targetTemp.PropValue2.."")
                elseif targetTemp.PropType2 == 2 then
                    local value = targetTemp.PropValue2/100
                    GUI.SetText(lab_newvalue2, string.format(StringTable.Get(21703), value))
                end
            else
                self._PanelObject._Tab_AttrInfo2:FindChild("Lab_NewValue2"):SetActive(false)
            end
            GUI.SetText(self._PanelObject._Tab_ComposeLevelInfo:FindChild("Lab_NewLevel"), targetTemp.Level.."")
        else
            self._PanelObject._Tab_AttrInfo1:FindChild("Lab_NewValue1"):SetActive(false)
            self._PanelObject._Tab_AttrInfo2:FindChild("Lab_NewValue2"):SetActive(false)
            self._PanelObject._Tab_ComposeLevelInfo:FindChild("Lab_NewLevel"):SetActive(false)
        end

        if composeTemp ~= nil then
            GUI.SetText(self._PanelObject._Lab_ComposeSuccessRate:FindChild("Lab_SuccessRateValue"), 
                            string.format(StringTable.Get(10961), math.ceil(composeTemp.Rate/100)))
        else
            self._PanelObject._Lab_ComposeSuccessRate:SetActive(false)
        end
    else
        self._PanelObject._Lab_ComposeSuccessRate:SetActive(false)
        self._PanelObject._Tab_Info:SetActive(false)
        self._PanelObject._Lab_NoCharm:SetActive(true)
    end
end

-- 更新合成消耗提示和按钮显示
def.method().UpdateComposeInfoUI2 = function(self)
    if self._MainCharmItemID ~= nil then
        local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID._Tid)
        local targetTemp = CElementData.GetTemplate("CharmItem", inlayTemp.TargetCharmId)
        local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayTemp.UpgradeTargetId)
        if composeTemp.CostItemTId > 0 and composeTemp.CostItemCount > 0 then
--            local have_item_count = game._HostPlayer._Package._NormalPack:GetItemCount(composeTemp.CostItemTId)
--            local img_cost_item = self._PanelObject._Tab_CostInfo:FindChild("Img_CostItem")
--            local lab_count = self._PanelObject._Tab_CostInfo:FindChild("Lab_CountInfo")
--            local item_temp = CElementData.GetItemTemplate(composeTemp.CostItemTId)
--            GUITools.SetItemIcon(img_cost_item, item_temp.IconAtlasPath)
--            if have_item_count >= composeTemp.CostItemCount then
--                GUI.SetText(lab_count, string.format(StringTable.Get(31050), have_item_count, composeTemp.CostItemCount))

--            else
--                GUI.SetText(lab_count, string.format(StringTable.Get(26004), have_item_count, composeTemp.CostItemCount))
--            end
            local mat_icon = self._PanelObject._Tab_CostInfo:FindChild("MaterialIcon")
            IconTools.InitMaterialIconNew(mat_icon, composeTemp.CostItemTId, composeTemp.CostItemCount)
            self._MatCostID = composeTemp.CostItemTId
            self._PanelObject._Tab_CostInfo:SetActive(true)
        else
            self._PanelObject._Tab_CostInfo:SetActive(false)
        end
        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(11117),
            [EnumDef.CommonBtnParam.MoneyID] = composeTemp.CostMoneyId,
            [EnumDef.CommonBtnParam.MoneyCost] = composeTemp.CostMoneyCount   
        }
        self._Btn_Compose:ResetSetting(setting)

        self._PanelObject._Btn_Compose:SetActive(true)
        if self._MatItemID1 == nil or self._MatItemID2 == nil then
            self._Btn_Compose:SetInteractable(false)
            self._Btn_Compose:MakeGray(true)
        else
            self._Btn_Compose:SetInteractable(true)
            self._Btn_Compose:MakeGray(false)
        end
    else
        self._PanelObject._Btn_Compose:SetActive(false)
    end
end

-- 更新UI界面
def.override().RefreshPageUI = function(self)
    self._PanelObject._Btn_PutOnAll:SetActive(false)
    self._PanelObject._Btn_ShowDetail:SetActive(false)
    self:UpdateFieldsUI()
    self:UpdateComposeInfoUI1()
    self:UpdateComposeInfoUI2()
    if self._IsSelecting then
        self._PanelObject._Tab_HaveCharm:SetActive(true)
        self._PanelObject._Tab_HaveNoCharm:SetActive(false)
        self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
        self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
    else
        if self._CharmAttrItems == nil or #self._CharmAttrItems <= 0 then
            self._PanelObject._Tab_HaveCharm:SetActive(false)
            self._PanelObject._Tab_HaveNoCharm:SetActive(true)
        else
            self._PanelObject._Tab_HaveCharm:SetActive(true)
            self._PanelObject._Tab_HaveNoCharm:SetActive(false)
            self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
            self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
        end
    end
end

-- 处理槽位的操作，主要是根据事件播放特效的
def.override("table").HandleOption = function(self, event)
    if event._Option == "Compose" then
        self._MainCharmItemID = nil
        self._MatItemID1 = nil
        self._MatItemID2 = nil
        self:SetShowCharmItems()
        self:SelectCharmsByAttrID(self._CurrentAttrID)
        self:GetAttrTableByShowCharmItems()
        self:SetDropDownInfo()
    elseif event._Option == "GainNewItem" then
        local itemDataInfo = event._ItemUpdateInfo
        if itemDataInfo.UpdateItem.Index < 0 or itemDataInfo.Src ~= Data.ENUM_ITEM_SRC.CHARM_COMPOSE then
            return
        end
        --暂时注释掉合成之后自动把新合成的神符放到主材料位置。
--        local new_charm_temp = CElementData.GetTemplate("CharmItem", event._CharmID) 
--        if new_charm_temp ~= nil then
--            if new_charm_temp.Level >= self._PanelCharm._CharmMaxLevel then
--                self._MainCharmItemID = nil
--                self:OnToggleByScript(1)
--            else
--                self._MainCharmItemID = {_Tid = event._CharmID, _Slot = itemDataInfo.UpdateItem.Index}
--                self:OnToggleByScript(2)
--            end
--        else
--            self._MainCharmItemID = nil
--            self:OnToggleByScript(1)
--        end
        self._MainCharmItemID = nil
        self:OnToggleByScript(1)
    elseif event._Option == "FieldCompose" then
        self._ComposeType = ComposeType.NomalCompose
    end
end


def.override('string').OnClick = function(self, id)
    if id == "Btn_Compose" then
        if self._MainCharmItemID == nil then
            game._GUIMan:ShowTipText(StringTable.Get(19351), true)
        else
            if self._MatItemID1 == nil or self._MatItemID2 == nil then
                game._GUIMan:ShowTipText(StringTable.Get(19352), true)
            else
                local inlayCharm = CElementData.GetTemplate("CharmItem", self._MainCharmItemID._Tid)
                local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayCharm.UpgradeTargetId)
                local compose = function()
                    local callback = function()
                        local np = game._HostPlayer._Package._NormalPack
                        local mat_index1 = self._MatItemID1._Slot
                        local mat_index2 = self._MatItemID2._Slot
                        local mat_table = {mat_index1, mat_index2}
                        self._PanelObject._Img_Mask_BG:SetActive(false)
                        if self._ComposeType == ComposeType.FieldCompose then
                            CCharmMan.Instance():FieldCompose( self._FieldID, mat_table)
                            self._MainCharmItemID = nil
                            self._MatItemID1 = nil
                            self._MatItemID2 = nil
                            self:OnToggleByScript(1)
                        else
                            local main_index = self._MainCharmItemID._Slot
                            print("main_index ", main_index, mat_table.mat_index1, mat_table.mat_index2)
                            CCharmMan.Instance():Compose(main_index, mat_table)
                            self._MainCharmItemID = nil
                            self._MatItemID1 = nil
                            self._MatItemID2 = nil
                            self:OnToggleByScript(1)
                        end
                    end
                    if self._NeedShowSkipFX then
                        callback()
                    else
                        GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, self._PanelObject._Rdo_MainMaterial, self._PanelObject._Rdo_MainMaterial, 2)
                        GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, self._PanelObject._Rdo_LeftMaterial, self._PanelObject._Rdo_LeftMaterial, 2)
                        GameUtil.PlayUISfx(PATH.UIFx_DecompseBg, self._PanelObject._Rdo_RightMaterial, self._PanelObject._Rdo_RightMaterial, 2)
                        if self._ComposeFxTimer ~= 0 then
                            _G.RemoveGlobalTimer(self._ComposeFxTimer)
                            self._ComposeFxTimer = 0
                        end
                        self._ComposeFxTimer = _G.AddGlobalTimer(0.2, true, callback)
                        self._PanelObject._Img_Mask_BG:SetActive(true)
                    end
                end

                if composeTemp ~= nil then
                    local callback = function(val)
                        if val then
                            compose()
                        end
                    end
                    local limit = {
                        [EQuickBuyLimit.MatID] = composeTemp.CostItemTId,
                        [EQuickBuyLimit.MatNeedCount] = composeTemp.CostItemCount,
                    }
                    MsgBox.ShowQuickBuyBox(composeTemp.CostMoneyId, composeTemp.CostMoneyCount, callback, limit)
                else
                    warn("error !!! 合成数据错误, Tid: ", inlayCharm.UpgradeTargetId)
                end
            end
        end
    elseif id == "Btn_ItemPlus" then
        if self._MainCharmItemID == nil then return end
        local inlayCharm = CElementData.GetTemplate("CharmItem", self._MainCharmItemID._Tid)
        local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayCharm.UpgradeTargetId)
        local item_temp = CElementData.GetItemTemplate(composeTemp.CostItemTId)
        local PanelData = 
        {
            ApproachIDs = item_temp.ApproachID or "",
            ParentObj = self._PanelObject._Tab_CostInfo:FindChild("Lab_CountInfo/Btn_ItemPlus"),
            IsFromTip = false,
            TipPanel = self._PanelCharm,
        }
        game._GUIMan:Open("CPanelItemApproach",PanelData)
    elseif id == "Btn_TakeOff1" then
        if self._ComposeType == ComposeType.NomalCompose then
            self:AddToAttrItemsTable(self._MainCharmItemID._Tid, self._MainCharmItemID._Slot)
        end
        self:ClearMat1AndMat2()
        self._MainCharmItemID = nil
        self:OnToggleByScript(1)
        self._ComposeType = ComposeType.NomalCompose
        self:RefreshPageUI()
    elseif id == "Btn_TakeOff2" then
        self:AddToAttrItemsTable(self._MatItemID1._Tid, self._MatItemID1._Slot)
        self._MatItemID1 = nil
        self:OnToggleByScript(2)
        self:RefreshPageUI()
    elseif id == "Btn_TakeOff3" then
        self:AddToAttrItemsTable(self._MatItemID2._Tid, self._MatItemID2._Slot)
        self._MatItemID2 = nil
        self:OnToggleByScript(3)
        self:RefreshPageUI()
    elseif id == "MaterialIcon" then
        if self._MatCostID > 0 then
             CItemTipMan.ShowItemTips(self._MatCostID, 
                             TipsPopFrom.OTHER_PANEL, 
                             nil, 
                             TipPosition.FIX_POSITION)
        end
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_CharmList" then
        local charm_item = self._CharmAttrItems[index]
        if charm_item == nil or charm_item.CharmItem == nil then return end
        local is_dress = (self._MainCharmItemID ~= nil and charm_item.CharmItem._Tid == self._MainCharmItemID._Tid) or (self._MatItemID1 ~= nil and charm_item.CharmItem._Tid == self._MatItemID1._Tid)
                             or (self._MatItemID2 ~= nil and charm_item.CharmItem._Tid == self._MatItemID2._Tid)
        local setting = {
            [EItemIconTag.Number] = charm_item.Count,
            [EItemIconTag.Bind] = charm_item.CharmItem:IsBind(),
            [EItemIconTag.Equip] = false --is_dress
        }
        IconTools.InitItemIconNew(GUITools.GetChild(item, 0), charm_item.CharmItem._Tid, setting)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_CharmList" then
        local charm_item = self._CharmAttrItems[index]
        local charm_temp = CElementData.GetTemplate("CharmItem", charm_item.CharmItem._Tid)
        if charm_temp.Level >= self._PanelCharm._CharmMaxLevel then
            game._GUIMan:ShowTipText(StringTable.Get(19354), false)
            return
        end
        if self._MainCharmItemID == nil then
            self._MainCharmItemID = {_Tid = charm_item.CharmItem._Tid, _Slot = charm_item.CharmItem._Slot}
            charm_item.Count = charm_item.Count - 1
            if charm_item.Count <= 0 then
                table.remove(self._CharmAttrItems, index)
                self:OnToggleByScript(2)
                self:RefreshPageUI()
                return
            end
            local uiTemplate = item:GetComponent(ClassType.UITemplate)
            local item_icon = uiTemplate:GetControl(0)
            local setting =
            {
                [EItemIconTag.Number] = charm_item.Count,
                [EItemIconTag.Bind] = charm_item.CharmItem:IsBind(),
                [EItemIconTag.Equip] = true,
            }
            IconTools.InitItemIconNew(item_icon, charm_item.CharmItem._Tid)
            self:OnToggleByScript(2)
        else
            --if self._MainCharmItemID == charm_item.CharmItem._Tid then return end
            if self._SelectedIndex == 1 then
                if self._MainCharmItemID ~= nil and self._MainCharmItemID._Tid == charm_item.CharmItem._Tid then return end
                if self._ComposeType == ComposeType.NomalCompose then
                    self:ReplaceMainField(charm_item.CharmItem._Tid, charm_item.Slot)
                end
                self:ClearMat1AndMat2()
                self._ComposeType = ComposeType.NomalCompose
                self:OnToggleByScript(2)
            elseif self._SelectedIndex == 2 then
                if self._MatItemID1 ~= nil and self._MatItemID1._Tid == charm_item.CharmItem._Tid then return end
                self:ReplaceField1(charm_item.CharmItem._Tid, charm_item.Slot)
                self:OnToggleByScript(3)
            elseif self._SelectedIndex == 3 then
                if self._MatItemID2 ~= nil and self._MatItemID2._Tid == charm_item.CharmItem._Tid then return end
                self:ReplaceField2(charm_item.CharmItem._Tid, charm_item.Slot)
            end
        end
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Choose_Press, 0)
        self:RefreshPageUI()
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
end

def.override("string", "number").OnDropDown = function(self, id, index)
    if self._IsScriptDropdown then
        self._IsScriptDropdown = false
        return
    end
    if index + 1 > #self._CharmAttrTable then return end
    self._CurrentAttrID = self._CharmAttrTable[index + 1]
    self._IsSelecting = true
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    if self._CharmAttrItems == nil or #self._CharmAttrItems == 0 then
        self._PanelObject._Tab_HaveNoCharm:SetActive(true)
        self._PanelObject._Tab_HaveCharm:SetActive(false)
    else
        self._PanelObject._Tab_HaveNoCharm:SetActive(false)
        self._PanelObject._Tab_HaveCharm:SetActive(true)
        self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
        self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
    end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    local new_index = 1
    if id == "Rdo_MainMaterial" then
        new_index = 1
        if self._MainCharmItemID ~= nil and not self._IsScriptToggle then
            CItemTipMan.ShowItemTips(self._MainCharmItemID._Tid, 
                             TipsPopFrom.OTHER_PANEL, 
                             self._PanelObject._Rdo_MainMaterial, 
                             TipPosition.FIX_POSITION)
        end
        --if new_index == self._SelectedIndex then self._MainCharmItemID = nil end
    elseif id == "Rdo_LeftMaterial" then
        new_index = 2
        if self._MatItemID1 ~= nil and not self._IsScriptToggle then
            CItemTipMan.ShowItemTips(self._MatItemID1._Tid, 
                                 TipsPopFrom.OTHER_PANEL, 
                                 self._PanelObject._Rdo_LeftMaterial, 
                                 TipPosition.FIX_POSITION)
        end
        --if new_index == self._SelectedIndex then self._MatItemID1 = nil end
    elseif id == "Rdo_RightMaterial" then
        new_index = 3
        if self._MatItemID2 ~= nil and not self._IsScriptToggle then
            CItemTipMan.ShowItemTips(self._MatItemID2._Tid,
                                 TipsPopFrom.OTHER_PANEL,
                                 self._PanelObject._Rdo_RightMaterial,
                                 TipPosition.FIX_POSITION)
        end
        --if new_index == self._SelectedIndex then self._MatItemID2 = nil end
    elseif id == "Toggle_ShowGfx" then
        self._NeedShowSkipFX = checked
        CCharmMan.Instance():SetCharmComposeSkipGfx(checked)
        return
    end
    self._SelectedIndex = new_index
    self._CurrentAttrID = -1
    self._IsScriptToggle = false
    self:SetShowCharmItems()
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    self:RefreshPageUI()
end

def.override().OnHide = function(self)
    self._MainCharmItemID = nil
    self:ClearMat1AndMat2()
    self._SelectedIndex = 1
    self._CurrentAttrID = -1
    self._IsSelecting = false
    self._IsScriptToggle = false
    self._ComposeType = 1
    self._FieldID = 0
    self._MatCostID = 0
end

def.override().OnDestory = function(self)
    if self._Btn_Compose ~= nil then
        self._Btn_Compose:Destroy()
        self._Btn_Compose = nil
    end
    self._CharmShowItems = nil
    self._CharmAttrItems = nil
    self._CharmAttrTable = nil
    if self._ComposeFxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._ComposeFxTimer)
        self._ComposeFxTimer = 0
    end
    CCharmPageBase.OnDestory(self)
end

CCharmPageCompose.Commit()
return CCharmPageCompose