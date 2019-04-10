local Lplus = require "Lplus"
local CCharmPageBase = require "Charm.CCharmPageBase"
local CCharmFieldPage = require "Charm.CCharmFieldPage"
local CElementData = require "Data.CElementData"
local CCharmMan = require "Charm.CCharmMan"
local ItemComponent = require "Package.ItemComponents"
local ECharmColor = require "PB.data".ECharmColor
local ECharmSize = require "PB.data".ECharmSize
local CCharmPageInlay = Lplus.Extend(CCharmPageBase, "CCharmPageInlay")
local def = CCharmPageInlay.define

def.field(CCharmFieldPage)._CurrentPage = nil
def.field("table")._CharmPages = BlankTable
def.field("table")._CharmShowItems = BlankTable     -- 当前神符槽位可以选择的神符
def.field("table")._CharmAttrItems = BlankTable     -- 在_CharmShowItems之上过滤当前选择的属性drop的神符
def.field("table")._CharmAttrTable = nil            -- 所有背包神符属性，用来设置drop
def.field("table")._CharmInlayAttrTable = nil       -- 所有已经镶嵌的神符属性
def.field("number")._FieldPagesCount = 3            -- 神符页的数量
def.field("number")._CurrentPageIndex = 1           -- 当前神符页的Index
def.field("number")._CurrentAttrID = -1             -- 当前dropdown选择的属性ID
def.field("number")._SmallFieldCount = 8            -- 小神符槽位的数量
def.field("boolean")._IsShowAttrInfoPanel = false   -- 属性总览面板是否在显示中
def.field("boolean")._IsSelecting = false           -- 是否是正在属性dropdown操作
def.field("boolean")._IsScriptDropdown = false      -- 代码正在操作dropdown
def.field("boolean")._IsScriptToggelPages = false   -- 是否是手动设置页签toggle
def.field("boolean")._IsChangingAllCharms = false     -- 是否是正在进行一键穿戴的操作
def.field("table")._UIFXTimers = nil                -- 播放UI特效的Timers

def.static("=>", CCharmPageInlay).new = function()
    local obj = CCharmPageInlay()
    return obj    
end

def.override().OnCreate = function(self)
    self._GameObject = self._PanelCharm:GetUIObject("Frame_Charm")
    self._PanelObject._PageToggles = self._PanelCharm:GetUIObject("Tgp_PageToggles")
    self._PanelObject._PrePageBtn = self._PanelCharm:GetUIObject("Btn_PrePage")
    self._PanelObject._NextPageBtn = self._PanelCharm:GetUIObject("Btn_NextPage")
    self._PanelObject._LabPageName = self._PanelCharm:GetUIObject("Lab_CharmPageName")
    self._PanelObject._LabCombatValue = self._PanelCharm:GetUIObject("Lab_CombatValue")
    self._PanelObject._List_CharmList = self._PanelCharm:GetUIObject("List_CharmList")
    self._PanelObject._List_AttrList = self._PanelCharm:GetUIObject("List_AllAttribute")
    self._PanelObject._Tab_CombatDetail = self._PanelCharm:GetUIObject("Tab_CombatDetail")
    self._PanelObject._Tab_HaveNoCharm = self._PanelCharm:GetUIObject("Tab_HaveNoCharm")
    self._PanelObject._Tab_RightHaveCharm = self._PanelCharm:GetUIObject("Tab_HaveCharm")
    self._PanelObject._Frame_DropDown = self._PanelCharm:GetUIObject("Drop_Group_Ride")
    self._PanelObject._Btn_PutOnAll = self._PanelCharm:GetUIObject("Btn_PutOnAll")
    self._PanelObject._Btn_ShowDetail = self._PanelCharm:GetUIObject("Btn_ShowDetail")
    self._PanelObject._Rdo_TabGroup = self._PanelCharm:GetUIObject("Rdo_TagGroup")
    self._PanelObject._Tab_InlayTip = self._PanelCharm:GetUIObject("Tab_InlayTip")
    self._PanelObject._Tab_UnlockTip = self._PanelCharm:GetUIObject("Tab_UnlockTip")
    self._PanelObject._Img_RedPointInlay = self._PanelCharm:GetUIObject("Img_RedPointInlay")
    self._PanelObject._Img_RedPointNextPage = self._PanelCharm:GetUIObject("Img_RedPointNextPage")
    self._PanelObject._Img_RedPointPrePage = self._PanelCharm:GetUIObject("Img_RedPointPrePage")
    self._PanelObject._Img_FieldBG1 = self._PanelCharm:GetUIObject("Img_Bg_02")
    self._PanelObject._Img_FieldBG2 = self._PanelCharm:GetUIObject("Img_Bg_03")
    self._PanelObject._Img_FieldBG0 = self._PanelCharm:GetUIObject("Img_Bg_01")
    self._PanelObject._Tab_CharmFieldPages = {}
    local ids = GameUtil.GetAllTid("CharmPage")
    self._FieldPagesCount = #ids
    for i = 1,self._FieldPagesCount do
        self._PanelObject._Tab_CharmFieldPages[i] = self._PanelCharm:GetUIObject("Tab_CharmPage"..i)
    end
    self._UIFXTimers = {}
end

def.override("dynamic").OnData = function(self, data)
    CCharmPageBase.OnData(self, data)
    self._CharmPages = {}
    self._CurrentAttrID = -1
    self._IsShowAttrInfoPanel = false
    self._PanelObject._Tab_InlayTip:SetActive(false)
    self._PanelObject._Tab_CombatDetail:SetActive(false)
    self._PanelObject._Tab_UnlockTip:SetActive(false)
    self:GenerateFieldPages()
    self:GetCurrentPageInlayAttrTable()
    self:SelectCharmsByFieldType(false, self._CurrentPage._CurField._CharmFieldTemp.CharmColor)
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    self._CurrentPage:Show()
    self:ShowUIFX()
    self._IsScriptDropdown = false
end

-- data = {itemID = 111, Slot = 11}
def.override("dynamic").ShowPage = function(self, data)
    CCharmPageBase.ShowPage(self, data)
    local color = 0
    if data ~= nil then
        if data.itemID ~= nil then
            local item_temp = CElementData.GetTemplate("CharmItem", data.itemID)
            color = item_temp.CharmColor
        end
        local field_index = self:FindANiceFieldForCharm(data.itemID)
        self._CurrentPage:ToggleByScript(field_index)
    else
        color = self._CurrentPage._CurField._CharmFieldTemp.CharmColor
    end
    self._CurrentAttrID = -1
    self:GetCurrentPageInlayAttrTable()
    self:SelectCharmsByFieldType(false, color)
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    self._IsScriptDropdown = false
    self:RefreshPageUI()
end

def.override().ShowUIFX = function(self)
    GameUtil.PlayUISfx(PATH.UIFX_CharmBGFX, self._GameObject, self._GameObject, -1)

end

def.override().HideUIFX = function(self)
    GameUtil.StopUISfx(PATH.UIFX_CharmBGFX, self._GameObject)
end


def.method("number", "=>", "number").FindANiceFieldForCharm = function(self, itemID)
    local item_temp = CElementData.GetTemplate("CharmItem", itemID)
    if item_temp ~= nil then
        local index = self._CurrentPage:FindTheFirstFieldByColor(item_temp.CharmColor)
        return index
    end
    return 1
end

def.method("table").AddToCharmShowItems = function(self, item)
    if self._CharmShowItems == nil then return end
    if #self._CharmShowItems == 0 then 
        self._CharmShowItems[#self._CharmShowItems + 1] = item
        return
    end
    for i,v in ipairs(self._CharmShowItems) do
        if item._Tid == v._Tid then
            return
        end
    end
    self._CharmShowItems[#self._CharmShowItems + 1] = item
end

-- 根据选择的槽位类型进行过滤
def.method("boolean", "number").SelectCharmsByFieldType = function(self,isBig, fieldColor)
    self:GetAllCharmItems()
    self._CharmShowItems = {}
    if fieldColor == -1 then
        self._CharmShowItems = self._CharmItems
    else
        if isBig then
            for _,v in ipairs(self._CharmItems) do
                if v:IsBigCharm() then
                    self:AddToCharmShowItems(v)
                end
            end
        else
            for _,v in ipairs(self._CharmItems) do
                if not v:IsBigCharm() then
                    if fieldColor == ECharmColor.ECharmColor_Colorful then
                        self:AddToCharmShowItems(v)
                    else
                        if fieldColor == v._CharmItemTemplate.CharmColor then
                            self:AddToCharmShowItems(v)
                        end
                    end
                end
            end
        end
    end
end

-- 对最终选好的神符进行排序
def.method().SortAttrCharmItems = function(self)
    local select_index = CCharmFieldPage.GetSelectIndex()
    local sort_func = function(it1, it2)
        if it1._CharmItemTemplate.Level ~= it2._CharmItemTemplate.Level then 
            return it1._CharmItemTemplate.Level > it2._CharmItemTemplate.Level
        else
            if it1._CharmItemTemplate.Id ~= it2._CharmItemTemplate.Id then
                return it1._CharmItemTemplate.Id > it2._CharmItemTemplate.Id
            end
        end
        return false
    end
    table.sort(self._CharmAttrItems, sort_func)
end

-- 根据属性ID对Items进行过滤
def.method("number").SelectCharmsByAttrID = function(self, attrID)
    self._CharmAttrItems = {}
    if attrID <= 0 then 
        self._CharmAttrItems = self._CharmShowItems
    else
        for _,v in ipairs(self._CharmShowItems) do
            if v._CharmItemTemplate.PropID1 == attrID or v._CharmItemTemplate.PropID2 == attrID then
                self._CharmAttrItems[#self._CharmAttrItems + 1] = v
            end
        end
    end

    self:SortAttrCharmItems()
end

-- 根据计算出来的属性table设置dropdown
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
    local dropTemplate = self._PanelObject._Frame_DropDown:FindChild("Drop_Template")
    GUITools.SetupDropdownTemplate(self._PanelCharm, dropTemplate)
    --GameUtil.AdjustDropdownRect(self._PanelObject._Frame_DropDown, #self._CharmAttrTable)
    GUI.SetDropDownOption(self._PanelObject._Frame_DropDown, dropText)
    GameUtil.SetDropdownValue(self._PanelObject._Frame_DropDown, #self._CharmAttrTable -1)

end

--def.method()

-- 根据将要显示的神符计算属性table
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

-- 获得当前神符页的属性table
def.method().GetCurrentPageInlayAttrTable = function(self)
    if self._CurrentPage ~= nil then
        self._CharmInlayAttrTable = self._CurrentPage:CalculateAttrTable()
    else
        warn("当前神符页签为空")
    end
end

-- 生成神符页对象
def.method().GenerateFieldPages = function(self)
    local fieldPages = GameUtil.GetAllTid("CharmPage")
    local hp = game._HostPlayer
    for i,value in ipairs(fieldPages) do
        local fieldPageTemp = CElementData.GetTemplate("CharmPage", value)
        local openState = hp._InfoData._Level >= fieldPageTemp.InlockLevel and EnumDef.CharmEnum.CharmPageState.Opened or EnumDef.CharmEnum.CharmPageState.Locked
        local newPage = CCharmFieldPage.new(self, value, openState, self._PanelObject._Tab_CharmFieldPages[i])
        newPage:Hide()
        self._CharmPages[#self._CharmPages + 1] = newPage
    end
    self._CurrentPageIndex = 1
    self._CurrentPage = self._CharmPages[self._CurrentPageIndex]
    self._CurrentPage:ToggleByScript(1)
end

-- 变更当前神符页
def.method("number").ChangeFieldPage = function(self, pageIndex)
    if #self._CharmPages < pageIndex or pageIndex <= 0 then
        return
    end

    if self._CurrentPage ~= nil then
        self._CurrentPage:Hide()
    end
    self._CurrentPageIndex = pageIndex
    self._CurrentPage = self._CharmPages[pageIndex]
    self._CurrentPage:Show()
    local select_index = CCharmFieldPage.GetSelectIndex()
    if select_index == -1 then
        self:SelectCharmsByFieldType(true, -1)
    else
        self._CurrentPage:ToggleByScript(select_index)
        local charm_field = self._CurrentPage._CharmFields[select_index]
        if not charm_field:IsBigField() then
            self:SelectCharmsByFieldType(false, self._CurrentPage._CurField._FieldData._CharmFieldColor)
        else
            self:SelectCharmsByFieldType(true, 0)
        end
    end
    self._CurrentAttrID = -1
    self:GetCurrentPageInlayAttrTable()
    self:SelectCharmsByAttrID(self._CurrentAttrID)
    self:GetAttrTableByShowCharmItems()
    self:SetDropDownInfo()
    self:RefreshPageUI()
end

-- 刷新UI
def.override().RefreshPageUI = function(self)
    self._PanelObject._Btn_PutOnAll:SetActive(true)
    self._PanelObject._Btn_ShowDetail:SetActive(true)
    if self._IsSelecting then
        self._PanelObject._Tab_HaveNoCharm:SetActive(false)
        self._PanelObject._Tab_RightHaveCharm:SetActive(true)
        self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
        self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
    else
        if self._CharmAttrItems == nil or #self._CharmAttrItems == 0 or self._CurrentPage:IsPageLocked() then
            self._PanelObject._Tab_HaveNoCharm:SetActive(true)
            self._PanelObject._Tab_RightHaveCharm:SetActive(false)
            self._PanelCharm:UpdateSideTabs({0})
        else
            self._PanelObject._Tab_HaveNoCharm:SetActive(false)
            self._PanelObject._Tab_RightHaveCharm:SetActive(true)
            self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
            self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
        end
    end
    if self._CharmInlayAttrTable ~= nil then
        self._PanelObject._List_AttrList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmInlayAttrTable)
    end
    if self._CurrentPageIndex <= 1 then
        GameUtil.SetButtonInteractable(self._PanelObject._PrePageBtn, false)
        self._PanelObject._PrePageBtn:SetActive(false)
    else
        GameUtil.SetButtonInteractable(self._PanelObject._PrePageBtn, true)
        self._PanelObject._PrePageBtn:SetActive(true)
    end
    if self._CurrentPageIndex >= #self._CharmPages then
        GameUtil.SetButtonInteractable(self._PanelObject._NextPageBtn, false)
        self._PanelObject._NextPageBtn:SetActive(false)
    else
        GameUtil.SetButtonInteractable(self._PanelObject._NextPageBtn, true)
        self._PanelObject._NextPageBtn:SetActive(true)
    end
    GUI.SetGroupToggleOn(self._PanelObject._PageToggles, self._CurrentPageIndex)
    GUITools.SetGroupImg(self._PanelObject._Img_FieldBG0, self._CurrentPageIndex - 1)
    self:RefreshFieldsUI()
    if CCharmMan.Instance()._ShowFieldFXAndRedPoint then
        self:UpdateRedPoint()
    else
        self:HideRedPoint()
    end
end

--根据槽位颜色获得当前有的神符个数
def.method("number", "=>", "number").GetSmallCharmCountByColor = function(self, fieldColor)
    local count = 0
    for _,v in ipairs(self._CharmItems) do
        if not v:IsBigCharm() then
            if fieldColor == ECharmColor.ECharmColor_Colorful then
                count = count + 1
            else
                if fieldColor == v._CharmItemTemplate.CharmColor then
                    count = count + 1    
                end
            end
        end
    end
    return count
end

-- 获得当前背包的大神符的数量
def.method("=>", "number").GetBigCharmCount = function(self)
    local count = 0
    for _,v in ipairs(self._CharmItems) do
        if v:IsBigCharm() then
            count = count + 1
        end
    end
    return count
end

-- 根据属性的加成类型和值返回字符串（+ 799 / + 6%）
def.method("dynamic", "dynamic", "=>", "string").GetPropStringByPropTypeAndValue = function(self, propType, propValue)
    if propType == nil or propValue == nil then return "+0" end
    if propType == 1 or propType == 2 then
        if propType == 1 then
            return "+"..propValue
        elseif propType == 2 then
            local value = propValue/100
            local value_str = string.format("+%0.1f%%", value)
            return value_str
        end
    else
        warn("CCharmPageInlay:GetPropStringByPropTypeAndValue() 属性类型错误", propType)
        return "+0"
    end
end

-- 刷新神符槽位UI
def.method().RefreshFieldsUI = function(self)
    if self._CurrentPage ~= nil then
        --local combatValue = self._CurrentPage:CalculateCombatValue()
        local pageTemp = self._CurrentPage:GetFieldPageTemplate(self._CurrentPage._PageID)
        GUI.SetText(self._PanelObject._LabPageName, pageTemp.Name)
        self._CurrentPage:UpdateUI()
    end
end

-- 显示神符替换之后的属性加成信息
def.method("number", "number").ShowCharmChangeTip = function(self, newCharmID, oldCharmID)
    self._PanelObject._Tab_InlayTip:SetActive(true)
    local uiTemplate = self._PanelObject._Tab_InlayTip:GetComponent(ClassType.UITemplate)
    local lab_attr_name1 = uiTemplate:GetControl(0)
    local lab_attr_name2 = uiTemplate:GetControl(1)
    local lab_attr_name3 = uiTemplate:GetControl(2)
    local lab_attr_name4 = uiTemplate:GetControl(3)
    local img_charm_icon = uiTemplate:GetControl(4)
    local img_bg = uiTemplate:GetControl(5)
    local lab_charm_name = uiTemplate:GetControl(6)
    local do_tween_player = self._PanelObject._Tab_InlayTip:GetComponent(ClassType.DOTweenPlayer)
    
    local old_charm_temp = CElementData.GetTemplate("CharmItem", oldCharmID)
    local new_charm_temp = CElementData.GetTemplate("CharmItem", newCharmID)
    local old_attr_temp = nil
    local new_attr_temp = nil
    local old_attr_temp2 = nil
    local new_attr_temp2 = nil
    if old_charm_temp.PropID1 > 0 then
        old_attr_temp = CElementData.GetAttachedPropertyTemplate(old_charm_temp.PropID1)
    end
    if new_charm_temp.PropID1 > 0 then
        new_attr_temp = CElementData.GetAttachedPropertyTemplate(new_charm_temp.PropID1)
    end
    if old_charm_temp.PropID2 > 0 then
        old_attr_temp2 = CElementData.GetAttachedPropertyTemplate(old_charm_temp.PropID2)
    end
    if new_charm_temp.PropID2 > 0 then
        new_attr_temp2 = CElementData.GetAttachedPropertyTemplate(new_charm_temp.PropID2)
    end
    if old_charm_temp ~= nil then

        if old_attr_temp ~= nil then
            lab_attr_name1:SetActive(true)
            GUI.SetText(lab_attr_name1, old_attr_temp.TextDisplayName)
            GUI.SetText(lab_attr_name1:FindChild("Lab_OldValue"), self:GetPropStringByPropTypeAndValue(old_charm_temp.PropType1, old_charm_temp.PropValue1))
        else
            lab_attr_name1:SetActive(false)
        end
        if old_attr_temp2 ~= nil then
            lab_attr_name3:SetActive(true)
            GUI.SetText(lab_attr_name3, old_attr_temp.TextDisplayName)
            GUI.SetText(lab_attr_name3:FindChild("Lab_OldValue"), self:GetPropStringByPropTypeAndValue(old_charm_temp.PropType2, old_charm_temp.PropValue2))
        else
            lab_attr_name3:SetActive(false)
        end
    else
        lab_attr_name1:SetActive(false)
        lab_attr_name3:SetActive(false)
    end

    local is_up = false
    if new_charm_temp ~= nil then
        lab_attr_name2:SetActive(true)
        lab_attr_name4:SetActive(true)
        if new_attr_temp ~= nil then
            lab_attr_name2:SetActive(true)
            GUI.SetText(lab_attr_name2, new_attr_temp.TextDisplayName)
            if old_attr_temp == nil or old_charm_temp.PropValue1 < new_charm_temp.PropValue1 then
                lab_attr_name2:FindChild("Lab_NewValueG"):SetActive(true)
                lab_attr_name2:FindChild("Lab_NewValueR"):SetActive(false)
                lab_attr_name2:FindChild("Lab_NewValueW"):SetActive(false)
                do -- 播放特效
                    local callback = function()
                        local pointer = lab_attr_name2:FindChild("Lab_NewValueG")
                        GameUtil.PlayUISfx(PATH.UI_shengjishuzhi, pointer, pointer, -1)
                    end
                    if self._UIFXTimers["2"] ~= nil then
                        _G.RemoveGlobalTimer(self._UIFXTimers["2"])
                        self._UIFXTimers["2"] = nil
                    end
                    self._UIFXTimers["2"] = _G.AddGlobalTimer(0.75, true, callback)	
                end
                is_up = true
            elseif old_attr_temp ~= nil and old_charm_temp.PropValue1 > new_charm_temp.PropValue1 then
                lab_attr_name2:FindChild("Lab_NewValueG"):SetActive(false)
                lab_attr_name2:FindChild("Lab_NewValueR"):SetActive(true)
                lab_attr_name2:FindChild("Lab_NewValueW"):SetActive(false)
            else
                lab_attr_name2:FindChild("Lab_NewValueG"):SetActive(false)
                lab_attr_name2:FindChild("Lab_NewValueR"):SetActive(false)
                lab_attr_name2:FindChild("Lab_NewValueW"):SetActive(true)
            end
            GUI.SetText(lab_attr_name2:FindChild("Lab_NewValueG"), self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType1, new_charm_temp.PropValue1))
            GUI.SetText(lab_attr_name2:FindChild("Lab_NewValueR"), self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType1, new_charm_temp.PropValue1))
            GUI.SetText(lab_attr_name2:FindChild("Lab_NewValueW"), self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType1, new_charm_temp.PropValue1))
        else
            lab_attr_name2:SetActive(false)
        end
        if new_attr_temp2 ~= nil then
            lab_attr_name4:SetActive(true)
            GUI.SetText(lab_attr_name4, new_attr_temp.TextDisplayName)
            if old_attr_temp2 == nil or old_charm_temp.PropValue2 < new_charm_temp.PropValue2 then
                lab_attr_name4:FindChild("Lab_NewValueG"):SetActive(true)
                lab_attr_name4:FindChild("Lab_NewValueR"):SetActive(false)
                lab_attr_name4:FindChild("Lab_NewValueW"):SetActive(false)
                do -- 播放特效
                    local callback = function()
                        local pointer = lab_attr_name4:FindChild("Lab_NewValueG")
                        GameUtil.PlayUISfx(PATH.UI_shengjishuzhi, pointer, pointer, -1)
                    end
                    if self._UIFXTimers["4"] ~= nil then
                        _G.RemoveGlobalTimer(self._UIFXTimers["4"])
                        self._UIFXTimers["4"] = nil
                    end
                    self._UIFXTimers["4"] = _G.AddGlobalTimer(0.95, true, callback)	
                end
                is_up = true
            elseif old_attr_temp2 ~= nil and old_charm_temp.PropValue2 > new_charm_temp.PropValue2 then
                lab_attr_name4:FindChild("Lab_NewValueG"):SetActive(false)
                lab_attr_name4:FindChild("Lab_NewValueR"):SetActive(true)
                lab_attr_name4:FindChild("Lab_NewValueW"):SetActive(false)
            else
                lab_attr_name4:FindChild("Lab_NewValueG"):SetActive(false)
                lab_attr_name4:FindChild("Lab_NewValueR"):SetActive(false)
                lab_attr_name4:FindChild("Lab_NewValueW"):SetActive(true)
            end
            GUI.SetText(lab_attr_name4:FindChild("Lab_NewValueG"), self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType2, new_charm_temp.PropValue2))
            GUI.SetText(lab_attr_name4:FindChild("Lab_NewValueR"), self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType2, new_charm_temp.PropValue2))
            GUI.SetText(lab_attr_name4:FindChild("Lab_NewValueW"), self:GetPropStringByPropTypeAndValue(new_charm_temp.PropType2, new_charm_temp.PropValue2))
        else
            lab_attr_name4:SetActive(false)
        end
    else
        lab_attr_name2:SetActive(false)
        lab_attr_name4:SetActive(false)
    end
    local new_item_temp = CElementData.GetItemTemplate(newCharmID)
    GUITools.SetItemIcon(img_charm_icon, new_item_temp.IconAtlasPath)
    if new_charm_temp ~= nil and lab_charm_name ~= nil then
        GUI.SetText(lab_charm_name, new_item_temp.TextDisplayName)
    end 

    do  -- 播放特效
        do_tween_player:Restart("1")
        GameUtil.PlayUISfx(PATH.UIFX_CharmComposeResultBGFX, self._PanelObject._Tab_InlayTip, self._PanelObject._Tab_InlayTip, -1, 5, -1)
        GameUtil.PlayUISfx(PATH.UIFX_CharmComposeResultFX, self._PanelObject._Tab_InlayTip, self._PanelObject._Tab_InlayTip, -1)
    end
end

-- 显示神符页未解锁
def.method("number").ShowFieldPageUnlockTip = function(self, unlockLevel)
    local level_tip = self._PanelObject._Tab_UnlockTip:FindChild("Img_BG/Lab_LevelTip")
    GUI.SetText(level_tip, string.format(StringTable.Get(137), unlockLevel))
    self._PanelObject._Tab_UnlockTip:SetActive(true)
    self._PanelObject._Img_FieldBG1:SetActive(false)
    self._PanelObject._Img_FieldBG2:SetActive(false)
end

-- 隐藏神符页未解锁的UI
def.method().HideFieldPageUnlockTip = function(self)
    self._PanelObject._Tab_UnlockTip:SetActive(false)
    self._PanelObject._Img_FieldBG1:SetActive(true)
    self._PanelObject._Img_FieldBG2:SetActive(true)
end

-- 处理槽位的操作，主要是根据事件播放特效的
def.override("table").HandleOption = function(self, event)
    if (event._Option == "PackageChange" or event._Option == "GainNewItem" or 
            event._Option == "Compose" or event._Option == "FieldCompose") and self._IsShow then
        local select_index = CCharmFieldPage.GetSelectIndex()
        if select_index == -1 then
            self:SelectCharmsByFieldType(true, -1)
        else
            local charm_field = self._CurrentPage._CharmFields[select_index]
            if not charm_field:IsBigField() then
                self:SelectCharmsByFieldType(false, self._CurrentPage._CurField._FieldData._CharmFieldColor)
            else
                self:SelectCharmsByFieldType(true, 0)
            end
        end

        self:GetCurrentPageInlayAttrTable()
        self:SelectCharmsByAttrID(self._CurrentAttrID)
        self:GetAttrTableByShowCharmItems()
        self:SetDropDownInfo()
    elseif event._Option == "PutOnBatch" then
        if self._CurrentPage ~= nil then
            for i,v in ipairs(event._Fields) do
                local field = self._CurrentPage:GetFieldByFieldID(v.FieldID)
                print("PutOnBatch ", v.FieldID, v.CharmID, field ~= nil)

                if field ~= nil then
                    if v.CharmID > 0 then
                        field:PutOnCharm(v.CharmID)
                    else
                        field:PutOffCharm()
                    end
                end
            end
        end
        self._IsChangingAllCharms = false
        self:GetCurrentPageInlayAttrTable()
        self:SelectCharmsByAttrID(self._CurrentAttrID)
        self:GetAttrTableByShowCharmItems()
        self:SetDropDownInfo()
    else
        local field = self._CurrentPage:GetFieldByFieldID(event._FieldID)
        if field == nil then return end
        if event._Option == "PutOn" then
            field:PutOnCharm(event._CharmID)
        elseif event._Option == "PutOff" then
            field:PutOffCharm()
        elseif event._Option == "Unlock" then
            field:UnlockField()
        elseif event._Option == "Change" then
            field:PutOnCharm(event._CharmID)
            self:ShowCharmChangeTip(event._CharmID, event._OldCharmID)
        end
        self:GetCurrentPageInlayAttrTable()
    end
    self:RefreshPageUI()
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_NextPage" then
        if self._IsChangingAllCharms then
            game._GUIMan:ShowTipText(StringTable.Get(19362), false)
            return
        end
        CCharmFieldPage.SetSelectIndex(1)
        self._CurrentPageIndex = self._CurrentPageIndex + 1
        self:ChangeFieldPage(self._CurrentPageIndex)
    elseif id == "Btn_PrePage" then
        if self._IsChangingAllCharms then
            game._GUIMan:ShowTipText(StringTable.Get(19362), false)
            return
        end
        CCharmFieldPage.SetSelectIndex(1)
        self._CurrentPageIndex = self._CurrentPageIndex - 1
        self:ChangeFieldPage(self._CurrentPageIndex)
    elseif id == "Btn_ShowDetail" then
        if self._CharmInlayAttrTable ~= nil then
            self._IsShowAttrInfoPanel = not self._IsShowAttrInfoPanel
            if self._IsShowAttrInfoPanel then
                self._PanelObject._Tab_CombatDetail:SetActive(true)
                self._PanelObject._List_AttrList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmInlayAttrTable)
                local combatValue = CCharmMan.Instance():GetPageCombatByPageID(self._CurrentPage._PageID)
                GUI.SetText(self._PanelObject._LabCombatValue, GUITools.FormatNumber(combatValue, false))
            else
                self._PanelObject._Tab_CombatDetail:SetActive(false)
            end
        else
            warn("当前神符页属性为空")
        end
    elseif id == "Btn_PutOnAll" then
        if self._CurrentPage ~= nil then
            self._IsChangingAllCharms = self._CurrentPage:ShortcutPutOnAll(self._CharmItems)
        end
    elseif id == "Img_PanelBG" then
        self._IsShowAttrInfoPanel = false
        self._PanelObject._Tab_CombatDetail:SetActive(false)
        self._PanelObject._Tab_InlayTip:SetActive(false)
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_CharmList" then
        local charm_item = self._CharmAttrItems[index]
        if charm_item == nil then return end
        local is_equiped = false
        if self._CurrentPage._CurField ~= nil and self._CurrentPage._CurField._FieldData._ItemID ~= -1 and self._CurrentPage._CurField._FieldData._ItemID == charm_item._Tid then
            is_equiped = true
        end
        local setting = {
            [EItemIconTag.Number] = game._HostPlayer._Package._NormalPack:GetItemCount(charm_item._Tid),
            [EItemIconTag.Bind] = charm_item:IsBind(),
            [EItemIconTag.Equip] = is_equiped
        }
        IconTools.InitItemIconNew(GUITools.GetChild(item, 0), charm_item._Tid, setting)
    elseif id == "List_AllAttribute" then
        if self._CharmInlayAttrTable == nil then return end
        local combat_data = self._CharmInlayAttrTable[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local attr_temp = CElementData.GetAttachedPropertyTemplate(combat_data.AttrID)
        local attr_name = uiTemplate:GetControl(0)
        local attr_value = uiTemplate:GetControl(1)
        GUI.SetText(attr_name, attr_temp.TextDisplayName)
        GUI.SetText(attr_value, "+".. GUITools.FormatNumber(math.ceil(combat_data.AttrValue), false))
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_CharmList" then
        local inlayCb = function()
            if self._CurrentPage == nil or self._CurrentPage._CurField == nil then
                game._GUIMan:ShowTipText(StringTable.Get(19347), false)
                return
            end
            if self._CurrentPage._CurField:GetState() == EnumDef.CharmEnum.CharmFieldState.Locked then
                local msg = CCharmMan.Instance():CalcFieldOpenNeedDesc(self._CurrentPage._CurField._FieldID)
                game._GUIMan:ShowTipText( msg, false)
                return
            else
                CCharmMan.Instance():PutOn(self._CurrentPage._CurField._FieldID, self._CharmAttrItems[index]._Slot)
            end
        end
        local devourCb = function()
            local charm_temp = CElementData.GetTemplate("CharmItem", self._CharmAttrItems[index]._Tid)
            if charm_temp.Level >= self._PanelCharm._CharmMaxLevel then
                game._GUIMan:ShowTipText(StringTable.Get(19354), false)
                return
            end
            local data = {itemID = self._CharmAttrItems[index]._Tid, ComposeType = 1, Slot = self._CharmAttrItems[index]._Slot}
            self._PanelCharm:ChangePage(2, data)
        end
        local comps = {}
		local inlay_comp = ItemComponent.EmbedComponent.new(self._CharmAttrItems[index])
        local devour_comp = ItemComponent.DevourComponent.new(self._CharmAttrItems[index])
        local link_comp = ItemComponent.SendLinkComponent.new(self._CharmAttrItems[index])
        inlay_comp._Action = inlayCb
        devour_comp._Action = devourCb
        table.insert(comps, inlay_comp)
        table.insert(comps, devour_comp)
        table.insert(comps, link_comp)
    	--CItemTipMan.ShowItemTipWithCertainFunc(self._CharmAttrItems[index], comps, TipPosition.FIX_POSITION,item)
        CItemTipMan.ShowCharmItemTips(self._CharmAttrItems[index]._Tid, self._CurrentPage._CurField._FieldData._CharmID, comps, TipPosition.FIX_POSITION,item)
    end
end

def.override("string", "boolean").OnToggle = function(self,id, checked)
    if string.find(id, "Rdo_Charm_") and checked then
        local index = string.sub(id,-1) + 1
        local can_show_detail = CCharmFieldPage.GetSelectIndex() == index
        if self._CurrentPage ~= nil then
            local field = self._CurrentPage:GetFieldByIndex(index)
            if field ~= nil and field:IsLock() then
                game._GUIMan:ShowTipText(string.format(StringTable.Get(19315), field._CharmFieldTemp.UnlockLevel), false)
                self._CurrentPage:ReBackToggleIndex()
                return
            else
                self._CurrentPage:OnToggleField(index)
            end
        end
        self._IsSelecting = false
        --弹tips
        if can_show_detail and self._CurrentPage ~= nil and self._CurrentPage._CurField ~= nil and self._CurrentPage._CurField:IsCharmPut() then
            local CIvtrItem = require "Package.CIvtrItems".CIvtrItem
            local itemData = CIvtrItem.CreateVirtualItem(self._CurrentPage._CurField._FieldData._ItemID)
            if itemData ~= nil then
                local takeOffCb = function()
                    CCharmMan.Instance():PutOff(self._CurrentPage._CurField._FieldID)
                end
                local devourCb = function()
                    local charm_temp = CElementData.GetTemplate("CharmItem", itemData._Tid)
                    if charm_temp.Level >= self._PanelCharm._CharmMaxLevel then
                        game._GUIMan:ShowTipText(StringTable.Get(19354), false)
                        return
                    end
                    local data = {itemID = self._CurrentPage._CurField._FieldData._ItemID, ComposeType = 2, fieldID = self._CurrentPage._CurField._FieldID}
                    self._PanelCharm:ChangePage(2, data)
                end
                local comps = {}
		        local put_off_comp = ItemComponent.TakeOffComponent.new(itemData)
                local devour_comp = ItemComponent.DevourComponent.new(itemData)
                local linkcomp = ItemComponent.SendLinkComponent.new(itemData)
                put_off_comp._Action = takeOffCb
                devour_comp._Action = devourCb
                table.insert(comps, put_off_comp)
			    table.insert(comps, devour_comp)
                table.insert(comps, linkcomp)
    	        CItemTipMan.ShowItemTipWithCertainFunc(itemData, comps, TipPosition.FIX_POSITION, self._CurrentPage:GetFieldUIByIndex(index))
            end
        end
        --更新神符背包，更新dropdown
        self._CurrentAttrID = -1
        if self._CurrentPage._CurField:IsBigField() then
            self:SelectCharmsByFieldType(true, 0)
        else
            self:SelectCharmsByFieldType(false, self._CurrentPage._CurField._FieldData._CharmFieldColor)
        end
        self:SelectCharmsByAttrID(self._CurrentAttrID)
        self:GetAttrTableByShowCharmItems()
        self:SetDropDownInfo()
        if self._CharmAttrItems == nil or #self._CharmAttrItems == 0 then
            self._PanelObject._Tab_HaveNoCharm:SetActive(true)
            self._PanelObject._Tab_RightHaveCharm:SetActive(false)
        else
            self._PanelObject._Tab_HaveNoCharm:SetActive(false)
            self._PanelObject._Tab_RightHaveCharm:SetActive(true)
            self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
            self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
        end
    elseif string.find(id, "Rdo_Page") and checked then
        if self._IsScriptToggelPages then 
            self._IsScriptToggelPages = false
            return
        end
        local index = string.sub(id, -1) + 0
        CCharmFieldPage.SetSelectIndex(1)
        self._CurrentPageIndex = index
        self._IsScriptToggelPages = true
        self:ChangeFieldPage(self._CurrentPageIndex)
    end
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
        self._PanelObject._Tab_RightHaveCharm:SetActive(false)
    else
        self._PanelObject._Tab_HaveNoCharm:SetActive(false)
        self._PanelObject._Tab_RightHaveCharm:SetActive(true)
        self._PanelObject._List_CharmList:GetComponent(ClassType.GNewList):SetItemCount(#self._CharmAttrItems)
        self._PanelCharm:UpdateSideTabs({#self._CharmAttrItems})
    end
    if CCharmMan.Instance()._ShowFieldFXAndRedPoint then
        self:UpdateRedPoint()
    else
        self:HideRedPoint()
    end
end
------------------------------------红点Start----------------------------------------
def.method().UpdateRedPoint = function(self)
    local inlayShow = false
    local nextShow = false
    local preShow = false
    for i,v in ipairs(self._CharmPages) do
        if v:PageShouldShowRedPoint(self._CharmItems) then
            if i < self._CurrentPageIndex then
                preShow = true
            elseif i > self._CurrentPageIndex then
                nextShow = true
            else
                inlayShow = true
            end
        end
        v:UpdateRedPoint(self._CharmItems)
    end
    self._PanelObject._Img_RedPointInlay:SetActive(inlayShow or nextShow or preShow)
    self._PanelObject._Img_RedPointNextPage:SetActive(nextShow)
    self._PanelObject._Img_RedPointPrePage:SetActive(preShow)
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Charm, inlayShow or nextShow or preShow)
end

def.method().HideRedPoint = function(self)
    for i,v in ipairs(self._CharmPages) do
        v:HideRedPoint()
    end
    self._PanelObject._Img_RedPointInlay:SetActive(false)
    self._PanelObject._Img_RedPointNextPage:SetActive(false)
    self._PanelObject._Img_RedPointPrePage:SetActive(false)
    CRedDotMan.UpdateModuleRedDotShow(RedDotSystemType.Charm, false)
end

-------------------------------------红点End-----------------------------------------

def.override().OnHide = function(self)
    self._IsScriptToggelPages = false
    self._CurrentAttrID = -1
    self._IsShowAttrInfoPanel = false
    self._PanelObject._Tab_CombatDetail:SetActive(false)
    self._PanelObject._Tab_InlayTip:SetActive(false)
    for key,v in pairs(self._UIFXTimers) do
        if v ~= nil then
            _G.RemoveGlobalTimer(v)
            self._UIFXTimers[key] = nil
        end
    end
    self._UIFXTimers ={}
end

def.override().OnDestory = function(self)
    for key,value in pairs(self._CharmPages) do
        value:Realse()
    end
    self._CharmAttrItems = nil
    self._CharmShowItems = nil
    self._CharmAttrTable = nil
    self._CharmInlayAttrTable = nil
    self._CharmPages = nil
    CCharmFieldPage.SetSelectIndex(1)
    CCharmPageBase.OnDestory(self)
end

CCharmPageInlay.Commit()
return CCharmPageInlay