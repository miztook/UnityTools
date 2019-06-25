local Lplus = require "Lplus"
local CCharmPageBase = require "Charm.CCharmPageBase"
local CCharmFieldPage = require "Charm.CCharmFieldPage"
local CElementData = require "Data.CElementData"
local CCharmMan = require "Charm.CCharmMan"
local Data = require "PB.data"
local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
local CCommonBtn = require "GUI.CCommonBtn"
local CCommonNumInput = require "GUI.CCommonNumInput"

local CCharmPageCompose = Lplus.Extend(CCharmPageBase, "CCharmPageCompose")
local def = CCharmPageCompose.define

local GFXKey = "CCharmPageCompose"
local ComposeType = {
    NomalCompose = 1,       -- 普通的点选合成
    FieldCompose = 2,       -- 合成槽位上的神符
    Max          = 3,       -- 站位
}

-- 插入到self._CharmShowItems 结构是{{Tid = 1, Count = 2}...}  Tid是物品ID
local insert_show_table = function(self, charm)
    local tid = charm._Tid
    local finded = false
    for i,v in ipairs(self._CharmShowItems) do
        if v.Tid == tid then
            v.Count = v.Count + charm:GetCount()
            finded = true
        end
    end
    if not finded then
        local item = {}
        item.Tid = tid
        item.Count = charm:GetCount()
        item.Level = charm._CharmItemTemplate.Level
        item.CharmSize = charm._CharmItemTemplate.CharmSize
        item.CharmColor = charm._CharmItemTemplate.CharmColor
        item.CharmID = charm._CharmItemTemplate.Id
        self._CharmShowItems[#self._CharmShowItems + 1] = item
    end
end

-- 获得self._CharmShowItems 里面Tid为tid的item
local get_show_item = function(self, tid)
    for i,v in ipairs(self._CharmShowItems) do
        if v.Tid == tid then
            return v
        end
    end
    return nil
end

-- 根据神符ID判断可以合成的神符数量（仅通过材料去判断）
local getCanComposeCountByMat = function(charmID)
    local count = 9999999
    local charm_temp = CElementData.GetTemplate("CharmItem", charmID)
    if charm_temp == nil then return count end
    if charm_temp.UpgradeTargetId > 0 then
        local up_temp = CElementData.GetTemplate("CharmUpgrade", charm_temp.UpgradeTargetId)
        if up_temp == nil then return count end
        if up_temp.CostItemTId > 0 then
            local have_count = game._HostPlayer._Package._NormalPack:GetItemCount(up_temp.CostItemTId)
            count = math.floor(have_count/up_temp.CostItemCount)
        end
    end
    return count
end

def.field("table")._CharmShowItems = BlankTable     -- 当前神符槽位可以选择的神符
def.field("table")._CharmAttrItems = BlankTable     -- 在_CharmShowItems之上过滤当前选择的属性drop的神符
def.field("table")._CharmAttrTable = nil            -- 所有背包神符属性，用来设置drop
def.field("number")._MainCharmItemID = 0            -- 放置的主神符ID
def.field("number")._CurComposeNum = 0              -- 当前选择合成的数量
def.field("number")._CurrentAttrID = -1             -- 当前dropdown的属性id
def.field("boolean")._IsScriptDropdown = false      -- 代码正在操作dropdown
def.field("boolean")._IsScriptToggle = false        -- 代码正在操作Toggle
def.field("boolean")._NeedShowSkipFX = false        -- 需要播放合成特效
def.field("number")._ComposeType = 1                -- 当前合成类型（普通合成/合成槽位上的神符）
def.field("number")._FieldID = 0                    -- 合成类型是槽位合成的时候的槽位ID
def.field("number")._ComposeFxTimer = 0             -- 特效timer
def.field(CCommonBtn)._Btn_Compose = nil            -- 合成按钮对象
def.field(CCommonNumInput)._InputComposeNum = nil   -- 合成选择数量控件对象
def.field("table")._UIFXShowItems = nil             -- 播放合成动画的时候应该显示的东西

def.static("=>", CCharmPageCompose).new = function()
    local obj = CCharmPageCompose()
    return obj
end

def.override().OnCreate = function(self)
    if self._PanelCharm == nil then return end
    self._GameObject = self._PanelCharm:GetUIObject("Frame_Compose")
    self._PanelObject._Img_BGFXPoint = self._PanelCharm:GetUIObject("Img_BG_01")
    self._PanelObject._Tab_HaveCharm = self._PanelCharm:GetUIObject("Tab_HaveCharm")
    self._PanelObject._Tab_HaveNoCharm = self._PanelCharm:GetUIObject("Tab_HaveNoCharm")
    self._PanelObject._Tab_ComposeItem = self._PanelCharm:GetUIObject("Tab_ComposeItem")
    self._PanelObject._Rdo_MainMaterial = self._PanelCharm:GetUIObject("Rdo_MainMaterial")
    self._PanelObject._Tab_Info = self._PanelCharm:GetUIObject("Tab_Info")
    self._PanelObject._Lab_NoCharm = self._PanelCharm:GetUIObject("Lab_NoCharm")
    self._PanelObject._Tab_AttrInfo1 = self._PanelCharm:GetUIObject("Tab_AttrInfo1")
    self._PanelObject._Tab_AttrInfo2 = self._PanelCharm:GetUIObject("Tab_AttrInfo2")
    self._PanelObject._Tab_ComposeLevelInfo = self._PanelCharm:GetUIObject("Tab_ComposeLevelInfo")
    self._PanelObject._Btn_PutOnAll = self._PanelCharm:GetUIObject("Btn_PutOnAll")
    self._PanelObject._Btn_ShowDetail = self._PanelCharm:GetUIObject("Btn_ShowDetail")
    self._PanelObject._Frame_DropDown = self._PanelCharm:GetUIObject("Drop_Group_Ride")
    self._PanelObject._Btn_Compose = self._PanelCharm:GetUIObject("Btn_Compose")
    self._PanelObject._List_CharmList = self._PanelCharm:GetUIObject("List_CharmList")
    self._PanelObject._Rdo_ShowGfx = self._PanelCharm:GetUIObject("Toggle_ShowGfx")
    self._PanelObject._Img_Mask_BG = self._PanelCharm:GetUIObject("Img_MaskBG")
    self._PanelObject._Img_Mask_BG:SetActive(false)
    self:InitComposeUIFXGOs()
    self._Btn_Compose = CCommonBtn.new(self._PanelObject._Btn_Compose, nil)
    local countChangeCB = function(count)
        self._CurComposeNum = count
        self:RefreshPageUI()
    end
    self._InputComposeNum = CCommonNumInput.new(self._PanelCharm:GetUIObject("Frame_NumInput"), countChangeCB, 1, 99)
end

-- data = { itemID = 111, Slot = 111, ComposeType = 1 }
def.override("dynamic").OnData = function(self, data)
    CCharmPageBase.OnData(self, data)
    if data ~= nil then
        self._MainCharmItemID = data.itemID
        self._ComposeType = data.ComposeType or ComposeType.NomalCompose
    else
        self._MainCharmItemID = 0
        self._CurComposeNum = 0
    end
    self._NeedShowSkipFX = CCharmMan.Instance():GetCharmComposeSkipGfx()
    self._PanelObject._Rdo_ShowGfx:GetComponent(ClassType.Toggle).isOn = self._NeedShowSkipFX
    self._CurrentAttrID = -1
    self._IsScriptDropdown = true
    self:SetShowCharmItems()
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    if self._MainCharmItemID > 0 then
        local item_value = get_show_item(self, self._MainCharmItemID)
        if item_value ~= nil then
            self._CurComposeNum = math.max(1, math.min(getCanComposeCountByMat(item_value.Tid), math.floor(item_value.Count/3)))
        else
            self._CurComposeNum = 1
        end
    end
    self._IsScriptDropdown = false
end

-- data = { itemID = 111, fieldID = 111, ComposeType = 1, Slot = 111}
def.override("dynamic").ShowPage = function(self, data)
    CCharmPageBase.ShowPage(self, data)
    if data ~= nil then
        self._ComposeType = data.ComposeType
        self._FieldID = data.fieldID or 0
        self._MainCharmItemID = data.itemID or 0
    else
        self._MainCharmItemID = 0
        self._CurComposeNum = 0
    end
    self._CurrentAttrID = -1
    self._IsScriptDropdown = true
    self:SetShowCharmItems()
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    if self._MainCharmItemID > 0 then
        local item_value = get_show_item(self, self._MainCharmItemID)
        if item_value ~= nil then
            self._CurComposeNum = math.max(1, math.min(getCanComposeCountByMat(item_value.Tid), math.floor(item_value.Count/3)))
        else
            self._CurComposeNum = 1
        end
    end
    self._IsScriptDropdown = false
    self:RefreshPageUI()
end

def.method().ResetComposeUIFXGOActive = function(self)
    self._UIFXShowItems["Item_New_Charm"]:SetActive(true)
    self._UIFXShowItems["Item_New_Charm_Fly"]:SetActive(false)
    self._UIFXShowItems["BlurTex"]:SetActive(false)
end

def.method().InitComposeUIFXGOs = function(self)
    self._UIFXShowItems = {}
    self._UIFXShowItems["Item_New_Charm"] = self._PanelCharm:GetUIObject("Item_New_Charm")
    self._UIFXShowItems["Item_New_Charm_Fly"] = self._PanelCharm:GetUIObject("Item_New_Charm_Fly")
    self._UIFXShowItems["BlurTex"] = self._PanelCharm:GetUIObject("BlurTex")
    self._UIFXShowItems["Tab_ComposeItem"] = self._PanelObject._Tab_ComposeItem
    self._UIFXShowItems["Tab_NewCharm"] = self._PanelCharm:GetUIObject("Tab_NewCharm")
    self:ResetComposeUIFXGOActive()
end

-- 播放特效，是否需要材料，回调函数
def.method("boolean", "function").PlayComposeUIFX = function(self, needMat, cb)
    if needMat then
        self._PanelCharm:AddEvt_PlayFx(GFXKey, 0, PATH.UIFX_CharmComposeFlyShort, self._UIFXShowItems["Tab_ComposeItem"], self._UIFXShowItems["Tab_ComposeItem"], 2, 5)
        self._PanelCharm:AddEvt_PlayFx(GFXKey, 0.3, PATH.UIFX_CharmComposeFlyLang, self._UIFXShowItems["Tab_ComposeItem"], self._UIFXShowItems["Tab_ComposeItem"], 2, 5)
    else
        self._PanelCharm:AddEvt_PlayFx(GFXKey, 0, PATH.UIFX_CharmComposeFlyMiddle, self._UIFXShowItems["Tab_ComposeItem"], self._UIFXShowItems["Tab_ComposeItem"], 2, 5)
    end
    local delay_add = needMat and 0.3 or 0
    self._PanelCharm:AddEvt_SetActive(GFXKey, 0.3 + delay_add, self._UIFXShowItems["Item_New_Charm"], false)
    self._PanelCharm:AddEvt_SetActive(GFXKey, 0.3 + delay_add, self._UIFXShowItems["Item_New_Charm_Fly"], true)
    self._PanelCharm:AddEvt_PlayDotween(GFXKey, 0.3 + delay_add, self._UIFXShowItems["Tab_ComposeItem"]:GetComponent(ClassType.DOTweenPlayer), "1")
    self._PanelCharm:AddEvt_SetActive(GFXKey, 0.3 + delay_add, self._UIFXShowItems["BlurTex"], true)
    self._PanelCharm:AddEvt_PlayDotween(GFXKey, 0.3 + delay_add, self._UIFXShowItems["BlurTex"]:GetComponent(ClassType.DOTweenPlayer), "2")
    self._PanelCharm:AddEvt_PlayFx(GFXKey, 0.6 + delay_add, PATH.UIFX_CharmComposeFlash, self._PanelCharm._Panel, self._PanelCharm._Panel, 1, 13)
    if self._ComposeFxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._ComposeFxTimer)
        self._ComposeFxTimer = 0
    end
    local callback = function()
        if cb ~= nil then
            cb()
        end
    end
    self._ComposeFxTimer = _G.AddGlobalTimer(0.6 + delay_add, true, callback)
end

--根据属性ID对Items进行过滤
def.method("number").SelectCharmsByAttrID = function(self, attrID)
    self._CharmAttrItems = {}
    
    if attrID <= 0 then 
        for _,v in ipairs(self._CharmShowItems) do
            repeat
                if v.Tid == self._MainCharmItemID then break end
                self._CharmAttrItems[#self._CharmAttrItems + 1] = v
            until true;
        end
    else
        for _,v in ipairs(self._CharmShowItems) do
            repeat
                local charm_temp = CElementData.GetCharmItemTemplate(v.Tid)
                if charm_temp == nil then break end
                if charm_temp.PropID1 == self._CurrentAttrID or charm_temp.PropID2 == self._CurrentAttrID then
                    if v.Tid == self._MainCharmItemID then break end
                    self._CharmAttrItems[#self._CharmAttrItems + 1] = v
                end
            until true;
        end
    end
    self:SortAttrCharmItems()
end


--针对选择好的神符进行排序，优先级是（神符大小，神符颜色，神符等级，属性ID）
def.method().SortAttrCharmItems = function(self)
    local func = function(item1, item2)
        if item1.Level ~= item2.Level then
            return item1.Level > item2.Level
        else
            if item1.CharmSize ~= item2.CharmSize then
                return item1.CharmSize < item2.CharmSize
            else
                if item1.CharmColor ~= item2.CharmColor then
                    return item1.CharmColor < item2.CharmColor
                else
                    if item1.CharmID ~= item2.CharmID then
                        return item1.CharmID > item2.CharmID
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

    self._CharmShowItems = {}
    for _,v in ipairs(self._CharmItems) do
        local charm_temp = CElementData.GetTemplate("CharmItem", v._Tid)
        if charm_temp.Level < self._PanelCharm._CharmMaxLevel then
            insert_show_table(self, v)
        end
    end
end

--根据要显示的神符来确定dropdown的信息并存到属性table中
def.method().GetAttrTableByShowCharmItems = function(self)
    local charm_attr = {}
    self._CharmAttrTable = {}
    for _,v in ipairs(self._CharmShowItems) do
        local template = CElementData.GetTemplate("CharmItem", v.Tid)
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
    local uiTemplate = self._PanelObject._Tab_ComposeItem:GetComponent(ClassType.UITemplate)
    local main_item_icon = uiTemplate:GetControl(0)
    local img_plus = uiTemplate:GetControl(1)
    local material_item = uiTemplate:GetControl(2)
    local img_arrow = uiTemplate:GetControl(3)
    local item_new_icon = uiTemplate:GetControl(5)
    local lab_compose_num = uiTemplate:GetControl(6)
    local fly_item_icon = uiTemplate:GetControl(7)
    -- 主槽位的
    local item_icon = GUITools.GetChild(main_item_icon, 3)
    local btn_take_off = GUITools.GetChild(main_item_icon, 7)
    local field_bg = GUITools.GetChild(main_item_icon, 4)
    local img_icon_bg = GUITools.GetChild(main_item_icon, 1)
    local img_select = GUITools.GetChild(main_item_icon, 6)
    local lab_need = GUITools.GetChild(main_item_icon, 5)


    img_plus:SetActive(false)
    material_item:SetActive(false)
    item_icon:SetActive(false)
    btn_take_off:SetActive(false)
    item_new_icon:SetActive(false)
    lab_compose_num:SetActive(false)
    lab_need:SetActive(false)
    img_select:SetActive(true)
    if self._MainCharmItemID > 0 then
        item_icon:SetActive(true)
        btn_take_off:SetActive(true)
        lab_need:SetActive(true)
        img_select:SetActive(false)
        local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
        local targetTemp = CElementData.GetTemplate("CharmItem", inlayTemp.TargetCharmId)
        local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayTemp.UpgradeTargetId)
        local itemTemp = CElementData.GetItemTemplate(self._MainCharmItemID)
        local have_value = get_show_item(self,self._MainCharmItemID)
        local have_count = 0
        if have_value ~= nil then
            have_count = (self._ComposeType == ComposeType.FieldCompose) and (have_value.Count + 1) or have_value.Count
        else
            have_count = (self._ComposeType == ComposeType.FieldCompose) and 1 or 0
        end
        GUITools.SetItemIcon(item_icon, itemTemp.IconAtlasPath)
        GUITools.SetGroupImg(field_bg, itemTemp.InitQuality)
        GUITools.SetGroupImg(img_icon_bg, itemTemp.InitQuality)
        if have_count >= self._CurComposeNum * 3 then
            GUI.SetText(lab_need, string.format(StringTable.Get(8104), have_count, self._CurComposeNum * 3))
        else
            GUI.SetText(lab_need, string.format(StringTable.Get(8114), have_count, self._CurComposeNum * 3))
        end

        if composeTemp.CostItemTId > 0 and composeTemp.CostItemCount > 0 then
            img_plus:SetActive(true)
            material_item:SetActive(true)
            IconTools.InitMaterialIconNew(material_item, composeTemp.CostItemTId, composeTemp.CostItemCount * self._CurComposeNum)
        end
        if inlayTemp.TargetCharmId > 0 then
            item_new_icon:SetActive(true)
            lab_compose_num:SetActive(true)
            IconTools.InitItemIconNew(item_new_icon, inlayTemp.TargetCharmId, nil)
            IconTools.InitItemIconNew(fly_item_icon, inlayTemp.TargetCharmId, nil)
            GUI.SetText(lab_compose_num, string.format(StringTable.Get(19364), self._CurComposeNum))
        end
    else
        GUITools.SetGroupImg(field_bg, 0)
        GUITools.SetGroupImg(img_icon_bg, 0)
    end
end

-- 更新合成信息UI
def.method().UpdateComposeInfoUI1 = function(self)
    if self._MainCharmItemID > 0 then
        self._PanelObject._Tab_Info:SetActive(true)
        self._PanelObject._Lab_NoCharm:SetActive(false)
        local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
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
    else
        self._PanelObject._Tab_Info:SetActive(false)
        self._PanelObject._Lab_NoCharm:SetActive(true)
    end
end

-- 更新选择数量和合成按钮
def.method().UpdateComposeInfoUI2 = function(self)
    if self._MainCharmItemID > 0 then
        local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
        local targetTemp = CElementData.GetTemplate("CharmItem", inlayTemp.TargetCharmId)
        local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayTemp.UpgradeTargetId)
        local item_value = get_show_item(self, self._MainCharmItemID)
        local input_max = 0
        if item_value ~= nil then
            local have_count = (self._ComposeType == ComposeType.FieldCompose) and (item_value.Count + 1) or item_value.Count

            input_max = math.max(1, math.min(getCanComposeCountByMat(item_value.Tid), math.floor(have_count/3)))
            self._Btn_Compose:MakeGray(false)
            self._Btn_Compose:SetInteractable(true)
            self._InputComposeNum:ResetMinAndMaxCount(1, input_max)
            self._InputComposeNum:SetCountWithOutCb(self._CurComposeNum)

            if have_count < self._CurComposeNum * 3 then
                self._Btn_Compose:MakeGray(true)
            end
            if composeTemp.CostItemTId > 0 then
                local mat_count = game._HostPlayer._Package._NormalPack:GetItemCount(composeTemp.CostItemTId)
                if mat_count < composeTemp.CostItemCount * self._CurComposeNum then
                    self._Btn_Compose:MakeGray(true)
                end
            end
        else
            self._Btn_Compose:MakeGray(true)
            self._Btn_Compose:SetInteractable(false)
            self._InputComposeNum:ResetMinAndMaxCount(1, 1)
            self._InputComposeNum:SetCountWithOutCb(self._CurComposeNum)
        end

        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(11106),
            [EnumDef.CommonBtnParam.MoneyID] = composeTemp.CostMoneyId,
            [EnumDef.CommonBtnParam.MoneyCost] = composeTemp.CostMoneyCount * self._CurComposeNum,  
        }
        self._Btn_Compose:ResetSetting(setting)
    else
        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(11106),
            [EnumDef.CommonBtnParam.MoneyID] = 1,
            [EnumDef.CommonBtnParam.MoneyCost] = 0 
        }
        self._Btn_Compose:ResetSetting(setting)
        self._Btn_Compose:MakeGray(true)
        self._Btn_Compose:SetInteractable(false)
        self._InputComposeNum:ResetMinAndMaxCount(1, 1)
        self._InputComposeNum:SetCountWithOutCb(self._CurComposeNum)
    end
end

-- 更新UI界面
def.override().RefreshPageUI = function(self)
    self._PanelObject._Btn_PutOnAll:SetActive(false)
    self._PanelObject._Btn_ShowDetail:SetActive(false)
    self:UpdateFieldsUI()
    self:UpdateComposeInfoUI1()
    self:UpdateComposeInfoUI2()
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

-- 处理槽位的操作，主要是根据事件播放特效的
def.override("table").HandleOption = function(self, event)
    if event._Option == "Compose" then
        self:ResetComposeUIFXGOActive()
        local charm_item = CElementData.GetCharmItemTemplate(event._CharmID)
        if charm_item == nil or charm_item.Level >= self._PanelCharm._CharmMaxLevel then
            return
        end
        self._MainCharmItemID = event._CharmID
        self:GetAllCharmItems()
        self:SetShowCharmItems()
        self:SelectCharmsByAttrID(self._CurrentAttrID)
        self:GetAttrTableByShowCharmItems()
        self:SetDropDownInfo()
        if self._MainCharmItemID > 0 then
            local item_value = get_show_item(self, self._MainCharmItemID)
            local have_count = 0
            if item_value ~= nil then
                if self._ComposeType == ComposeType.FieldCompose then
                    have_count = item_value.Count + 1
                else
                    have_count = item_value.Count
                end
            end
            self._CurComposeNum = item_value and math.max(1, math.min(getCanComposeCountByMat(item_value.Tid), math.floor(have_count/3))) or 0
        end
    elseif event._Option == "FieldCompose" then
        self:ResetComposeUIFXGOActive()
        local charm_item = CElementData.GetCharmItemTemplate(event._CharmID)
        if charm_item == nil or charm_item.Level >= self._PanelCharm._CharmMaxLevel then
            return
        end
        self._MainCharmItemID = event._CharmID
        self:GetAllCharmItems()
        self:SetShowCharmItems()
        self:SelectCharmsByAttrID(self._CurrentAttrID)
        self:GetAttrTableByShowCharmItems()
        self:SetDropDownInfo()
        if self._MainCharmItemID > 0 then
            local item_value = get_show_item(self, self._MainCharmItemID)
            local have_count = 0
            if item_value ~= nil then
                if self._ComposeType == ComposeType.FieldCompose then
                    have_count = item_value.Count + 1
                else
                    have_count = item_value.Count
                end
            end
            self._CurComposeNum = item_value and math.max(1, math.min(getCanComposeCountByMat(item_value.Tid), math.floor(have_count/3))) or 0
        end
    end
end

def.override('string').OnClick = function(self, id)
    if self._InputComposeNum:OnClick(id) then
        return
    elseif id == "Btn_Compose" then
        if self._MainCharmItemID == 0 then
            game._GUIMan:ShowTipText(StringTable.Get(19351), true)
        else
            local item_value = get_show_item(self, self._MainCharmItemID)
            local have_count = 0
            if item_value then
                have_count = self._ComposeType == ComposeType.FieldCompose and item_value.Count + 1 or item_value.Count
                if have_count < self._CurComposeNum * 3 then
                    game._GUIMan:ShowTipText(StringTable.Get(19317), true)
                    return
                end
            end
            local inlayCharm = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
            local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayCharm.UpgradeTargetId)
            local compose = function()
                local callback = function()
                    self._PanelObject._Img_Mask_BG:SetActive(false)
                    if self._ComposeType == ComposeType.FieldCompose then
                        CCharmMan.Instance():FieldCompose( self._FieldID, self._MainCharmItemID, self._CurComposeNum)
                        self._MainCharmItemID = 0
                        self._CurComposeNum = 0
                    else
                        CCharmMan.Instance():Compose(self._MainCharmItemID, self._CurComposeNum)
                        self._MainCharmItemID = 0
                        self._CurComposeNum = 0
                    end
                    self:RefreshPageUI()
                end
                if self._NeedShowSkipFX then
                    callback()
                else
                    self:PlayComposeUIFX(composeTemp.CostItemTId > 0 and composeTemp.CostItemCount > 0, callback)
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
                    [EQuickBuyLimit.MatNeedCount] = composeTemp.CostItemCount * self._CurComposeNum,
                }
                MsgBox.ShowQuickBuyBox(composeTemp.CostMoneyId, composeTemp.CostMoneyCount * self._CurComposeNum, callback, limit)
            else
                warn("error !!! 合成数据错误, Tid: ", inlayCharm.UpgradeTargetId)
            end
        end
    elseif id == "Btn_ItemPlus" then
        if self._MainCharmItemID == nil then return end
        local inlayCharm = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
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
        local item_value = get_show_item(self, self._MainCharmItemID)
        if item_value ~= nil then
            table.insert(self._CharmAttrItems, item_value)
        end
        self:SortAttrCharmItems()
        self._MainCharmItemID = 0
        self._CurComposeNum = 0
        self._ComposeType = ComposeType.NomalCompose
        self:RefreshPageUI()
    elseif id == "MaterialIcon" then
        if self._MainCharmItemID > 0 then
            local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
            local composeTemp = CElementData.GetTemplate("CharmUpgrade", inlayTemp.UpgradeTargetId)
            if composeTemp.CostItemTId > 0 and composeTemp.CostItemCount > 0 then
                CItemTipMan.ShowItemTips(composeTemp.CostItemTId, 
                             TipsPopFrom.OTHER_PANEL, 
                             nil, 
                             TipPosition.FIX_POSITION)
            end
        end
    elseif id == "Item_New_Charm" then
        if self._MainCharmItemID > 0 then
            local inlayTemp = CElementData.GetTemplate("CharmItem", self._MainCharmItemID)
            
            if inlayTemp ~= nil and inlayTemp.TargetCharmId > 0 then
                CItemTipMan.ShowItemTips(inlayTemp.TargetCharmId, 
                             TipsPopFrom.OTHER_PANEL, 
                             nil, 
                             TipPosition.FIX_POSITION)
            end
        end
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_CharmList" then
        local charm_item = self._CharmAttrItems[index]
        local setting = {
            [EItemIconTag.Number] = charm_item.Count,
            [EItemIconTag.CanUse] = true
        }
        IconTools.InitItemIconNew(GUITools.GetChild(item, 0), charm_item.Tid, setting)
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_CharmList" then
        local charm_item = self._CharmAttrItems[index]
        local charm_temp = CElementData.GetTemplate("CharmItem", charm_item.Tid)
        if charm_temp.Level >= self._PanelCharm._CharmMaxLevel then
            game._GUIMan:ShowTipText(StringTable.Get(19354), false)
            return
        end
        table.remove(self._CharmAttrItems, index)
        if self._MainCharmItemID > 0 and self._ComposeType == ComposeType.NomalCompose then
            table.insert(self._CharmAttrItems, get_show_item(self, self._MainCharmItemID))
            self:SortAttrCharmItems()
        end
        self._ComposeType = ComposeType.NomalCompose
        self._MainCharmItemID = charm_item.Tid
        self._CurComposeNum = math.max(1, math.min(getCanComposeCountByMat(charm_item.Tid), math.floor(charm_item.Count/3)))
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
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:RefreshPageUI()
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if id == "Toggle_ShowGfx" then
        self._NeedShowSkipFX = checked
        CCharmMan.Instance():SetCharmComposeSkipGfx(checked)
        return
    elseif id == "Rdo_MainMaterial" then
        if self._MainCharmItemID > 0 then
             CItemTipMan.ShowItemTips(self._MainCharmItemID, 
                             TipsPopFrom.OTHER_PANEL, 
                             self._PanelObject._Rdo_MainMaterial,
                             TipPosition.FIX_POSITION)
        end
    end
    self:RefreshPageUI()
end

def.override().OnHide = function(self)
    self._MainCharmItemID = 0
    self._CurrentAttrID = -1
    self._IsScriptToggle = false
    self._ComposeType = ComposeType.NomalCompose
    self._FieldID = 0
end

def.override().OnDestory = function(self)
    if self._Btn_Compose ~= nil then
        self._Btn_Compose:Destroy()
        self._Btn_Compose = nil
    end
    if self._InputComposeNum ~= nil then
        self._InputComposeNum:Destroy()
        self._InputComposeNum = nil
    end
    self._CharmShowItems = nil
    self._CharmAttrItems = nil
    self._CharmAttrTable = nil
    self._UIFXShowItems = nil
    if self._ComposeFxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._ComposeFxTimer)
        self._ComposeFxTimer = 0
    end
    CCharmPageBase.OnDestory(self)
end

CCharmPageCompose.Commit()
return CCharmPageCompose