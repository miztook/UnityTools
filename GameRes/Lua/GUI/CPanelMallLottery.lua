local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPanelBase = require "GUI.CPanelBase"

--============================ CLotteryField ==================================
local CLotteryField = Lplus.Class("CLotteryField")
local def = CLotteryField.define
local FieldState = {
    WaitClick   = 1,    -- 等待被点
    Clicked     = 2,    -- 点击过了
}

def.field("userdata")._UI = nil
def.field("table")._Data = nil
def.field("number")._State = FieldState.WaitClick
def.field("table")._Timers = nil

def.static("=>", CLotteryField).new = function()
    local o = CLotteryField()
    return o
end

def.method("userdata", "table").Init = function(self, ui, data)
    self._UI = ui
    self._Data = data
    self._State = FieldState.WaitClick
    self._Timers = {}
    if self._UI ~= nil then
        local uiTemplate = self._UI:GetComponent(ClassType.UITemplate)
        local item_icon = uiTemplate:GetControl(0)
        local lab_name = uiTemplate:GetControl(1)
        local img_mask = uiTemplate:GetControl(2)
        item_icon:SetActive(false)
        lab_name:SetActive(false)
        GameUtil.PlayUISfx(PATH.UIFX_MallLottery_FieldFX, img_mask, img_mask, -1)
    end
end

def.method().UpdateField = function(self)
    if self._UI == nil or self._Data == nil then return end
    local uiTemplate = self._UI:GetComponent(ClassType.UITemplate)
    local item_icon = uiTemplate:GetControl(0)
    local lab_name = uiTemplate:GetControl(1)
    local img_mask = uiTemplate:GetControl(2)
    if self._Data.IsMoney then
        local money_temp = CElementData.GetMoneyTemplate(self._Data.ItemId)
        if money_temp ~= nil then
            GUI.SetText(lab_name, money_temp.TextDisplayName)
            IconTools.InitTokenMoneyIcon(item_icon, self._Data.ItemId, self._Data.Count)
        end
    else
        local item_temp = CElementData.GetItemTemplate(self._Data.ItemId)
        if item_temp ~= nil then
            GUI.SetText(lab_name, item_temp.TextDisplayName)
        end
        local setting = {
            [EItemIconTag.Number] = self._Data.Count,
        }
        IconTools.InitItemIconNew(item_icon, self._Data.ItemId, setting, EItemLimitCheck.AllCheck)
    end
end

def.method("number").ChangeState = function(self, state)
    self._State = state
end

def.method("=>", "boolean").IsClicked = function(self)
    return self._State == FieldState.Clicked
end

def.method().OnSelectItem = function(self)
    if self._UI == nil then return end
    if self._State ~= FieldState.WaitClick then return end
    local uiTemplate = self._UI:GetComponent(ClassType.UITemplate)
    local item_icon = uiTemplate:GetControl(0)
    local lab_name = uiTemplate:GetControl(1)
    local img_mask = uiTemplate:GetControl(2)
    GameUtil.PlayUISfx(PATH.UIFX_MallLottery_FieldExpFX, img_mask,img_mask, -1)
    local callback = function()
        GameUtil.StopUISfx(PATH.UIFX_MallLottery_FieldFX, img_mask)
        item_icon:SetActive(true)
        local do_tween_player = self._UI:GetComponent(ClassType.DOTweenPlayer)
        if do_tween_player ~= nil then
            do_tween_player:Restart("1")
        end
    end
    self._Timers[#self._Timers + 1] = _G.AddGlobalTimer(0.62, true, callback)

    local callback1 = function()
        lab_name:SetActive(true)
        local do_tween_player = self._UI:GetComponent(ClassType.DOTweenPlayer)
        if do_tween_player ~= nil then
            do_tween_player:Restart("2")
        end
        self._State = FieldState.Clicked
        local CPanelMallLottery = require "GUI.CPanelMallLottery"
        if CPanelMallLottery.Instance():IsShow() then
            CPanelMallLottery.Instance():UpdatePanel()
        end
    end
    self._Timers[#self._Timers + 1] = _G.AddGlobalTimer(1.02, true, callback1)

end

def.method("string").OnSelectItemButton = function(self, id_btn)
    if id_btn == "ItemIcon" then
        if self._Data == nil then return end
        if self._State ~= FieldState.Clicked then return end
        if self._Data.IsMoney then
            local panelData = 
                {
                    _MoneyID = self._Data.ItemId,
                    _TipPos = TipPosition.FIX_POSITION ,
                    _TargetObj = self._UI ,   
                }
            CItemTipMan.ShowMoneyTips(panelData)
        else
            CItemTipMan.ShowItemTips(self._Data.ItemId, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
        end
    end
end

def.method().OnDestory = function(self)
    for _,v in ipairs(self._Timers) do
        if v ~= nil then
            _G.RemoveGlobalTimer(v)
        end
    end
    self._Timers = nil
    self._UI = nil
    self._Data = nil
    self._Timers = nil
end

CLotteryField.Commit()

--============================ CPanelMallLottery ==================================

local CPanelMallLottery = Lplus.Extend(CPanelBase, "CPanelMallLottery")
local def = CPanelMallLottery.define
local instance = nil
local GiftItemID = 20101

def.field("table")._PanelObjects = nil          -- Userdatas
def.field("table")._RewardDatas = nil           -- 获得奖励的数据
def.field("table")._Fields = nil                -- 槽位们
def.field("number")._FxTimer = 0

def.static('=>', CPanelMallLottery).Instance = function ()
	if not instance then
        instance = CPanelMallLottery()
        instance._PrefabPath = PATH.UI_MallLottery
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects._List_Items = self:GetUIObject("List_Items"):GetComponent(ClassType.GNewList)
    self._PanelObjects._Img_Shadow = self:GetUIObject("Img_Shadow")
    self._PanelObjects._Lab_Skip = self:GetUIObject("Lab_Skip")
    self._PanelObjects._Btn_Skip = self:GetUIObject("Btn_Skip")
end

def.override("dynamic").OnData = function(self, data)
    self._RewardDatas = {}
    if data ~= nil then
        self._RewardDatas = self:TransData(data)
    end

    if self._FxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._FxTimer)
        self._FxTimer = 0
    end

    local callback = function()
        self._PanelObjects._List_Items:SetItemCount(#self._RewardDatas)
        self:GenerateFields()
        self:UpdatePanel()
        game._CGuideMan:AnimationEndCallBack(self)
    end
    self._FxTimer = _G.AddGlobalTimer(0.2, true, callback)
    GameUtil.PlayUISfx(PATH.UIFX_MallLottery_Get, self:GetUIObject("List_Items"),self:GetUIObject("List_Items"), -1)
end

def.method("table", "=>", "table").TransData = function(self, data)
    local new_table = {}
    for _,v in ipairs(data.MoneyList) do
        local item = {}
        item.ItemId = v.MoneyId
        item.Count = v.Count
        item.IsMoney = true
        new_table[#new_table + 1] = item
    end
    for _,v in ipairs(data.ListItem) do
        repeat
            if v.ItemId == GiftItemID and (v.Count == 1 or v.Count == 10) then break end
            local item = {}
            item.ItemId = v.ItemId
            item.Count = v.Count
            item.IsMoney = false
            new_table[#new_table + 1] = item
        until true;
    end

    return new_table
end

def.method().GenerateFields = function(self)
    self._Fields = {}
    for i,v in ipairs(self._RewardDatas) do
        local field = CLotteryField.new()
        field:Init(self._PanelObjects._List_Items:GetItem(i - 1), v)
        self._Fields[#self._Fields + 1] = field
    end
end

def.method().UpdatePanel = function(self)
    local is_all_clicked = true
    for _,v in ipairs(self._Fields) do
        v:UpdateField()
        if not v:IsClicked() then
            is_all_clicked = false
        end
    end
    if is_all_clicked then
        self._PanelObjects._Img_Shadow:SetActive(false)
        GUI.SetText(self._PanelObjects._Lab_Skip, StringTable.Get(31046))
        instance._PanelCloseType = EnumDef.PanelCloseType.ClickAnyWhere
    else
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        self._PanelObjects._Img_Shadow:SetActive(true)
        GUI.SetText(self._PanelObjects._Lab_Skip, StringTable.Get(31045))
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Skip" then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_MallLotteryClick, 0)
        for _,v in ipairs(self._Fields) do
            if v ~= nil and v._State == FieldState.WaitClick then
                v:OnSelectItem()
            end
        end
        if self._PanelObjects._Btn_Skip then
            self._PanelObjects._Btn_Skip:SetActive(false)
        end
        self:UpdatePanel()
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local index = index + 1
    if index > #self._Fields then return end
    if id == "List_Items" then
        local field = self._Fields[index]
        if field ~= nil then
            field:OnSelectItem()
            CSoundMan.Instance():Play2DAudio(PATH.GUISound_MallLotteryClick, 0)
        end
    end
    self:UpdatePanel()
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local index = index + 1
    if id == "List_Items" then
        if index > #self._Fields then return end
        local field = self._Fields[index]
        field:OnSelectItemButton(id_btn)
    end
end

def.override().OnDestroy = function(self)
    if self._Fields ~= nil then
        for _,v in ipairs(self._Fields) do
            v:OnDestory()
        end
    end
    if self._FxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._FxTimer)
        self._FxTimer = 0
    end
    self._Fields = nil
    self._PanelObjects = nil
    self._RewardDatas = nil
end

CPanelMallLottery.Commit()
return CPanelMallLottery