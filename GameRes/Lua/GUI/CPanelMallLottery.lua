local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CPanelBase = require "GUI.CPanelBase"
local CMallMan = require "Mall.CMallMan"
local CPanelMall = require "GUI.CPanelMall"
local ItemQuality= require"PB.Template".Item.ItemQuality

--============================ CLotteryField ==================================
local CLotteryField = Lplus.Class("CLotteryField")
local def = CLotteryField.define
local FieldState = {
    None        = 0,    -- 还没有进场
    WaitClick   = 1,    -- 等待被点
    Clicked     = 2,    -- 点击过了
}

local DotweenDeltTime = 0.15

def.field("userdata")._UI = nil
def.field("table")._Data = nil
def.field("number")._State = FieldState.WaitClick
def.field("number")._Index = 0
def.field("table")._Timers = nil
def.field("table")._LotteryPanel = nil

def.static("=>", CLotteryField).new = function()
    local o = CLotteryField()
    return o
end

local GetEnterDelayByIndex = function(self, index)
    local index = index - 1
    if index > 4 then
        return (9-index) * 0.1
    else
        return index * 0.1
    end
end

-- 获得品质延迟。
local GetQulityDelay = function(itemID, isMoney)
    local qulity = 0
    if isMoney then
        local money_temp = CElementData.GetMoneyTemplate(itemID)
        if money_temp == nil then return 0 end
        qulity = money_temp.Quality
    else
        local item_temp = CElementData.GetItemTemplate(itemID)
        if item_temp == nil then return 0 end

        qulity = item_temp.InitQuality
    end
    local qulity_delay_time = 0

    if qulity == ItemQuality.Epic then
        qulity_delay_time = 0.5
    elseif qulity == ItemQuality.Legend then
        qulity_delay_time = 1
    end
 
    return qulity_delay_time
end

-- 获得不同品质的翻牌特效
local GetQulityTurnBackFXPath = function(itemID, isMoney)
    local qulity = 0
    local fx_path = ""
    if isMoney then
        local money_temp = CElementData.GetMoneyTemplate(itemID)
        if money_temp == nil then return fx_path end
        qulity = money_temp.Quality
    else
        local item_temp = CElementData.GetItemTemplate(itemID)
        if item_temp == nil then return fx_path end

        qulity = item_temp.InitQuality
    end
    if qulity == ItemQuality.Senior then
        fx_path = PATH.UIFX_Mall_LotteryItemGreen
    elseif qulity == ItemQuality.Rare then
        fx_path = PATH.UIFX_Mall_LotteryItemBlue
    elseif qulity == ItemQuality.Epic then
        fx_path = PATH.UIFX_Mall_LotteryItemPurple
    elseif qulity == ItemQuality.Legend then
        fx_path = PATH.UIFX_Mall_LotteryItemYellow
    end
    return fx_path
end

-- 获得不同品质的遮挡特效
local GetQulityMaskFXPath = function(itemID, isMoney)
    local qulity = 0
    local fx_path = PATH.UIFX_Mall_LotteryItemMask
    if not isMoney then
        local item_temp = CElementData.GetItemTemplate(itemID)
        if item_temp == nil then return fx_path end

        qulity = item_temp.InitQuality
        local have = item_temp.RareEffectPath ~= nil and item_temp.RareEffectPath ~= ""
        if qulity == ItemQuality.Epic and have then
            fx_path = PATH.UIFX_Mall_LotteryItemMaskPurple
        elseif qulity == ItemQuality.Legend and have then
            fx_path = PATH.UIFX_Mall_LotteryItemMaskYellow
        end
    end
    
    return fx_path
end

-- 获得不同品质色的卡牌翻开时候的声音
local GetQulityEnterSoundPath = function(itemID, isMoney)
    local qulity = 0
    local sort_num = 0
    local audio_path = ""
    if isMoney then
        local money_temp = CElementData.GetMoneyTemplate(itemID)
        if money_temp == nil then return audio_path end
        qulity = money_temp.Quality
    else
        local item_temp = CElementData.GetItemTemplate(itemID)
        if item_temp == nil then return audio_path end
        qulity = item_temp.InitQuality
    end
    if qulity == ItemQuality.Senior then
        audio_path = PATH.GUISound_Gacha_Blue
        sort_num = 0
    elseif qulity == ItemQuality.Rare then
        audio_path = PATH.GUISound_Gacha_Blue
        sort_num = 1
    elseif qulity == ItemQuality.Epic then
        audio_path = PATH.GUISound_Gacha_Purple
        sort_num = 2
    elseif qulity == ItemQuality.Legend then
        audio_path = PATH.GUISound_Gacha_Yellow
        sort_num = 3
    end
    return audio_path, sort_num
end

local GetQulityExplorFXPath = function(itemID, isMoney)
    local qulity = 0
    local fx_path = ""
    if isMoney then
        local money_temp = CElementData.GetMoneyTemplate(itemID)
        if money_temp == nil then return qulity end
        qulity = money_temp.Quality
    else
        local item_temp = CElementData.GetItemTemplate(itemID)
        if item_temp == nil then return qulity end

        qulity = item_temp.InitQuality
    end
    if qulity == ItemQuality.Epic then
        fx_path = PATH.UIFX_Mall_LotteryItemExplorPurple
    elseif qulity == ItemQuality.Legend then
        fx_path = PATH.UIFX_Mall_LotteryItemExplorYellow
    end
    return fx_path
end

-- 根据品质获得爆炸延迟时间
local GetExplorDelayTime = function(itemID, isMoney)
    local delay_time = 0
    local qulity = 0
    local fx_path = PATH.UIFX_Mall_LotteryItemMask
    if isMoney then
        local money_temp = CElementData.GetMoneyTemplate(itemID)
        if money_temp == nil then return qulity end
        qulity = money_temp.Quality
    else
        local item_temp = CElementData.GetItemTemplate(itemID)
        if item_temp == nil then return qulity end

        qulity = item_temp.InitQuality
    end
    if qulity == ItemQuality.Epic then
        delay_time = 0.6
    elseif qulity == ItemQuality.Legend then
        delay_time = 1.2
    end
end

local GfxKey = "CPanelMallLottery"

def.method("table", "userdata", "table", "number").Init = function(self, panel, ui, data, index)
    self._UI = ui
    self._Data = data
    self._State = FieldState.None
    self._LotteryPanel = panel
    self._Index = index
    self._Timers = {}
    if self._UI ~= nil then
        local uiTemplate = self._UI:GetComponent(ClassType.UITemplate)
        local item_icon = uiTemplate:GetControl(0)
        local lab_name = uiTemplate:GetControl(1)
        local img_mask = uiTemplate:GetControl(2)
        local img_card = uiTemplate:GetControl(3)
        item_icon:SetActive(false)
        lab_name:SetActive(false)

        local callback = function()
            self._State = FieldState.WaitClick
            self._LotteryPanel:OnFieldStateChange(self._State)
        end
        local is_single = CMallMan.Instance():GetIsSingle()
        local dotween_player = self._UI:GetComponent(ClassType.DOTweenPlayer)
        dotween_player:GoToStartPos("Enter")
        dotween_player:GoToStartPos("1")

        dotween_player:Restart("Enter")
        if is_single then
            self._Timers[#self._Timers + 1] = _G.AddGlobalTimer(0.85, true, callback)
            self._LotteryPanel:AddEvt_PlayFx(GfxKey, 0.85, PATH.UIFX_Mall_LotterySingleFX, self._UI, self._UI, 3, 1)
        else
            self._Timers[#self._Timers + 1] = _G.AddGlobalTimer(GetEnterDelayByIndex(self, index), true, callback)
            --self._LotteryPanel:AddEvt_PlayFx(GfxKey, GetEnterDelayByIndex(self, index) + 0.12, PATH.UIFX_Mall_LotteryDropCard, self._UI, self._UI, 3, 1)
        end
        self._LotteryPanel:AddEvt_PlayFx(GfxKey, 0, PATH.UIFX_Mall_LotteryCardBack, img_card, img_card, -1, 1)
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
            GUI.SetText(lab_name, RichTextTools.GetMoneyNameRichText(self._Data.ItemId))
            IconTools.InitTokenMoneyIcon(item_icon, self._Data.ItemId, self._Data.Count)
        end
    else
        local item_temp = CElementData.GetItemTemplate(self._Data.ItemId)
        if item_temp ~= nil then
            GUI.SetText(lab_name, RichTextTools.GetItemNameRichText(self._Data.ItemId, 1, false))
        end
        local setting = {
            [EItemIconTag.Number] = self._Data.Count,
        }
        IconTools.InitItemIconNew(item_icon, self._Data.ItemId, setting, EItemLimitCheck.AllCheck)
    end
end

def.method("=>", "number").GetState = function(self)
    return self._State
end 

def.method("number").ChangeState = function(self, state)
    self._State = state
end

def.method("=>", "boolean").IsClicked = function(self)
    return self._State == FieldState.Clicked
end

def.method("number").OnSelectItem = function(self, delay)
    if self._UI == nil then return end
    if self._State ~= FieldState.WaitClick then return end
    if self._Data == nil then return end
    local uiTemplate = self._UI:GetComponent(ClassType.UITemplate)
    local item_icon = uiTemplate:GetControl(0)
    local lab_name = uiTemplate:GetControl(1)
    local img_mask = uiTemplate:GetControl(2)
    lab_name:SetActive(false)
    local callback = function()
--        local do_tween_player = self._UI:GetComponent(ClassType.DOTweenPlayer)
--        if do_tween_player ~= nil then
--            do_tween_player:Restart("1")
--        end
        local fx_path = GetQulityExplorFXPath(self._Data.ItemId, self._Data.IsMoney)
        if fx_path ~= "" then
            self._LotteryPanel:AddEvt_PlayFx(GfxKey, 0, fx_path, self._UI, self._UI, 3, 3)
        end
        GameUtil.StopUISfx(PATH.UIFX_Mall_LotteryCardBack,self._UI, true)
        local audio_path, srot_n = GetQulityEnterSoundPath(self._Data.ItemId, self._Data.IsMoney)
        CSoundMan.Instance():Play2DAudio(audio_path, srot_n)
    end
    self._Timers[#self._Timers + 1] = _G.AddGlobalTimer(delay, true, callback)

    local qulity_delay = GetQulityDelay(self._Data.ItemId, self._Data.IsMoney)
    local callback1 = function()
        item_icon:SetActive(true)
        self._LotteryPanel:AddEvt_SetActive(GfxKey, 0.5, lab_name, true)
        local do_tween_player = self._UI:GetComponent(ClassType.DOTweenPlayer)
        if do_tween_player ~= nil then
            do_tween_player:Restart("1")
        end
        -- 特效
        local fx_path = GetQulityTurnBackFXPath(self._Data.ItemId, self._Data.IsMoney)
        if fx_path ~= "" then
            self._LotteryPanel:AddEvt_PlayFx(GfxKey, 0.18, fx_path, self._UI, self._UI, 3, 1)
        end
        local qulity_mask_path = GetQulityMaskFXPath(self._Data.ItemId, self._Data.IsMoney)
        self._LotteryPanel:AddEvt_PlayFx(GfxKey, 0.23, qulity_mask_path, item_icon, item_icon, -1, 1)

        self._State = FieldState.Clicked
        if self._LotteryPanel:IsShow() then
            self._LotteryPanel:UpdatePanel()
        end
    end
    self._Timers[#self._Timers + 1] = _G.AddGlobalTimer(delay + qulity_delay, true, callback1)
end

def.method().OnSelectItemButton = function(self)
    if self._Data == nil then return end
    if self._State ~= FieldState.Clicked then return end
    if self._Data.IsMoney then
        local panelData = 
            {
                _MoneyID = self._Data.ItemId,
                _TipPos = TipPosition.FIX_POSITION ,
                _TargetObj = self._UI,   
            }
        CItemTipMan.ShowMoneyTips(panelData)
    else
        CItemTipMan.ShowItemTips(self._Data.ItemId, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
    end
end

-- 关闭背景特效
def.method().StopAllGfx = function(self)
    self._LotteryPanel:KillEvts(GfxKey)
    local qulity_mask_path = GetQulityMaskFXPath(self._Data.ItemId, self._Data.IsMoney)
    local is_single = CMallMan.Instance():GetIsSingle()
    if is_single then
        GameUtil.StopUISfx(PATH.UIFX_Mall_LotterySingleFX,self._UI, true)
    else
        GameUtil.StopUISfx(PATH.UIFX_Mall_LotteryCardBack,self._UI, true)
        GameUtil.StopUISfx(PATH.UIFX_MallLottery_Get,self._UI, true)
    end

    GameUtil.StopUISfx(qulity_mask_path,GUITools.GetChild(self._UI, 0), true)
--    local do_tween_player = self._UI:GetComponent(ClassType.DOTweenPlayer)
    GameUtil.ChangeGraphicAlpha(GUITools.GetChild(self._UI, 3), 1)
    GUITools.GetChild(self._UI, 3).localRotation = Vector3.zero
end

def.method().OnDestory = function(self)
    for _,v in ipairs(self._Timers) do
        if v ~= nil then
            _G.RemoveGlobalTimer(v)
        end
    end
    self:StopAllGfx()
    self._Timers = nil
    self._UI = nil
    self._Data = nil
end

CLotteryField.Commit()

--============================ CPanelMallLottery ==================================
local Data = require "PB.data"
local CMallUtility = require "Mall.CMallUtility"
local CMallMan = require "Mall.CMallMan"
local CPanelMallLottery = Lplus.Extend(CPanelBase, "CPanelMallLottery")
local def = CPanelMallLottery.define
local instance = nil
local GiftItemID = 20101
local OneRewardSpecialID = 441
local TenRewardSpecialID = 572
local OnePetDroupSpecialId = 458
local TenPetDroupSpecialId = 573


def.field("table")._PanelObjects = nil          -- Userdatas
def.field("table")._RewardDatas = nil           -- 获得奖励的数据
def.field("table")._Fields = nil                -- 槽位们
def.field("number")._FxTimer = 0
def.field("number")._ItemSrc = -1               -- 抽奖来源

def.static('=>', CPanelMallLottery).Instance = function ()
	if not instance then
        instance = CPanelMallLottery()
        instance._PrefabPath = PATH.UI_MallLottery
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false

        instance:SetupSortingParam()
	end
	return instance
end

def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects._Lab_Skip = self:GetUIObject("Lab_Skip")
    self._PanelObjects._Btn_OnceMore = self:GetUIObject("Btn_OnceMore")
    self._PanelObjects._Btn_OpenAll = self:GetUIObject("Btn_OpenAll")
    self._PanelObjects._Btn_TenMore = self:GetUIObject("Btn_TenMore")
    self._PanelObjects._Btn_Back = self:GetUIObject("Btn_Back")
    self._PanelObjects._Btn_ElfOne = self:GetUIObject("Btn_ElfOne")
    self._PanelObjects._Btn_ElfTen = self:GetUIObject("Btn_ElfTen")
    self._PanelObjects._List_Item = self:GetUIObject("List_Item")
    self._PanelObjects._List_TenItems = self:GetUIObject("List_TenItems")
end

local ResetPanelObjectsStatus = function(self)
    self._PanelObjects._Lab_Skip:SetActive(false)
    self._PanelObjects._Btn_OnceMore:SetActive(false)
    self._PanelObjects._Btn_OpenAll:SetActive(false)
    self._PanelObjects._Btn_TenMore:SetActive(false)
    self._PanelObjects._Btn_Back:SetActive(false)
    self._PanelObjects._Btn_ElfOne:SetActive(false)
    self._PanelObjects._Btn_ElfTen:SetActive(false)
    self._PanelObjects._List_Item:SetActive(false)
    self._PanelObjects._List_TenItems:SetActive(false)
end

def.override("dynamic").OnData = function(self, data)
    ResetPanelObjectsStatus(self)
    self._RewardDatas = {}
    if data ~= nil then
        self._RewardDatas = self:TransData(data)
        self:BreakSequeue()
    end
    self._ItemSrc = data.ItemSrc
    if self._FxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._FxTimer)
        self._FxTimer = 0
    end
    local src = EnumDef.LocalFields.PetEggSkipGfx_PetEgg
    if data.ItemSrc == Data.ENUM_ITEM_SRC.PETDROP then
        src = EnumDef.LocalFields.PetEggSkipGfx_PetEgg
    elseif data.ItemSrc == Data.ENUM_ITEM_SRC.SPRINTGIFT then
        src = EnumDef.LocalFields.MallSkipGfx_Springift
    end
    local is_single = CMallMan.Instance():GetIsSingle()
    local point_go = self:GetUIObject("Img_BG")
    local callback = function()
        self:GenerateFields()
        self:UpdatePanel()
    end

    self._FxTimer = _G.AddGlobalTimer(1, true, callback)
    GameUtil.PlayUISfx(PATH.UIFX_MallLottery_Get, point_go, point_go, -1)
    local is_single = CMallMan.Instance():GetIsSingle()
    if is_single then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Gacha_OneEnter, 0)
    else
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_Gacha_TenEnter, 0)
    end
    --self:AddEvt_PlayFx(GfxKey, 0, PATH.UIFX_MallLottery_Get, point_go, point_go, 3, 1)
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

-- 打乱顺序
def.method().BreakSequeue = function(self)
    local new_table = {}
    if self._RewardDatas ~= nil and (#self._RewardDatas > 0) then
        for i = #self._RewardDatas,1,-1 do
            local random = math.random(1, #self._RewardDatas)
            self._RewardDatas[i],self._RewardDatas[random] = self._RewardDatas[random],self._RewardDatas[i]
        end
    end
end

def.method("number").OnFieldStateChange = function(self, newState)
    if newState == FieldState.WaitClick then
        for i,v in ipairs(self._Fields) do
            if v:GetState() ~= FieldState.WaitClick then
                return
            end
        end
    end
    game._CGuideMan:AnimationEndCallBack(self)
    local is_single = CMallMan.Instance():GetIsSingle()
    if not is_single then
        self._PanelObjects._Btn_OpenAll:SetActive(true)
    end
end

def.method().GenerateFields = function(self)
    self._Fields = {}
    local is_single = CMallMan.Instance():GetIsSingle()
    local list_go = nil
    if is_single then
        list_go = self._PanelObjects._List_Item
        self._PanelObjects._List_Item:SetActive(true)
        self._PanelObjects._List_TenItems:SetActive(false)
        GUITools.GetChild(list_go, 0):SetActive(false)
    else
        list_go = self._PanelObjects._List_TenItems
        self._PanelObjects._List_Item:SetActive(false)
        self._PanelObjects._List_TenItems:SetActive(true)
        for i = 1,10 do
            GUITools.GetChild(list_go, i-1):SetActive(false)
        end
    end
    for i,v in ipairs(self._RewardDatas) do
        local item_go = GUITools.GetChild(list_go, i-1)
        item_go:SetActive(true)
        if item_go ~= nil then
            local field = CLotteryField.new()
            field:Init(self, item_go, v, i)
            self._Fields[#self._Fields + 1] = field
        else
            warn("error !!! 抽奖给的物品数量大于十个")
        end
    end
end

def.method().UpdateElfBtns = function(self)
    local DropRuleId = tonumber(CElementData.GetSpecialIdTemplate(OneRewardSpecialID).Value)
    local TenDropRuleId = tonumber(CElementData.GetSpecialIdTemplate(TenRewardSpecialID).Value)
    local one_drop_temp = CElementData.GetTemplate("DropRule",DropRuleId)
    local ten_drop_temp = CElementData.GetTemplate("DropRule", TenDropRuleId)
    if one_drop_temp == nil then
        warn("error !! CPanelMallLottery.UpdateElfBtns 精灵献礼使用的掉落模板数据为空")
        return
    end
    if ten_drop_temp == nil then
        warn("error !! CPanelMallLottery.InitElfData 精灵献礼使用的十连抽掉落模板数据为空")
        return
    end
    local itemFlower = CElementData.GetItemTemplate(one_drop_temp.CostItemId2)
    local itemMaterial = CElementData.GetItemTemplate(one_drop_temp.CostItemId1)
    local ten_item_flower = CElementData.GetItemTemplate(ten_drop_temp.CostItemId2)
    local ten_item_material = CElementData.GetItemTemplate(ten_drop_temp.CostItemId1)

    local flowerItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(one_drop_temp.CostItemId2)
    local materialItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(one_drop_temp.CostItemId1)
    local tenFlowerItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(ten_drop_temp.CostItemId2)
    local tenMaterialItemCount = game._HostPlayer._Package._NormalPack:GetItemCount(ten_drop_temp.CostItemId1)

    local img_flower = GUITools.GetChild(self._PanelObjects._Btn_ElfOne, 0)
    local lab_flower = GUITools.GetChild(self._PanelObjects._Btn_ElfOne, 1)
    local img_item = GUITools.GetChild(self._PanelObjects._Btn_ElfOne, 2)
    local lab_item = GUITools.GetChild(self._PanelObjects._Btn_ElfOne, 3)
    local img_flower_ten = GUITools.GetChild(self._PanelObjects._Btn_ElfTen, 0)
    local lab_flower_ten = GUITools.GetChild(self._PanelObjects._Btn_ElfTen, 1)
    local img_item_ten = GUITools.GetChild(self._PanelObjects._Btn_ElfTen, 2)
    local lab_item_ten = GUITools.GetChild(self._PanelObjects._Btn_ElfTen, 3)

    GUITools.SetItemIcon(img_flower, itemFlower.IconAtlasPath)
    GUI.SetText(lab_flower, flowerItemCount >= one_drop_temp.CostItemCount2 and string.format(StringTable.Get(30340), flowerItemCount, one_drop_temp.CostItemCount2) 
        or string.format(StringTable.Get(26004), flowerItemCount, one_drop_temp.CostItemCount2))
    GUITools.SetItemIcon(img_item, itemMaterial.IconAtlasPath)
    GUI.SetText(lab_item, materialItemCount >= one_drop_temp.CostItemCount2 and string.format(StringTable.Get(30340), materialItemCount, one_drop_temp.CostItemCount1) 
        or string.format(StringTable.Get(26004), materialItemCount, one_drop_temp.CostItemCount1))
    GUITools.SetItemIcon(img_flower_ten, ten_item_flower.IconAtlasPath)
    GUI.SetText(lab_flower_ten, tenFlowerItemCount >= ten_drop_temp.CostItemCount2 and string.format(StringTable.Get(30340), tenFlowerItemCount, ten_drop_temp.CostItemCount2) 
        or string.format(StringTable.Get(26004), tenFlowerItemCount, ten_drop_temp.CostItemCount2))
    GUITools.SetItemIcon(img_item_ten, ten_item_material.IconAtlasPath)
    GUI.SetText(lab_item_ten, tenMaterialItemCount >= ten_drop_temp.CostItemCount2 and string.format(StringTable.Get(30340), tenMaterialItemCount, ten_drop_temp.CostItemCount1) 
        or string.format(StringTable.Get(26004), tenMaterialItemCount, ten_drop_temp.CostItemCount1))
end

def.method().UpdatePetButtons = function(self)
    local dropRuleId = tonumber(CElementData.GetSpecialIdTemplate(OnePetDroupSpecialId).Value)
    local dropTenRuleId = tonumber(CElementData.GetSpecialIdTemplate(TenPetDroupSpecialId).Value)
    local dropRuleTemplate = CElementData.GetTemplate("DropRule",dropRuleId)
    local dropTenRuleTemplate = CElementData.GetTemplate("DropRule", dropTenRuleId)
    if dropRuleTemplate == nil then warn(" droupRule id".. dropRuleId .." is nil") return end
    local one_have_count = game._HostPlayer:GetMoneyCountByType(dropRuleTemplate.CostMoneyId)
    local ten_have_count = game._HostPlayer:GetMoneyCountByType(dropTenRuleTemplate.CostMoneyId)

    if one_have_count >= dropRuleTemplate.CostMoneyCount then
        GUI.SetText(GUITools.GetChild(self._PanelObjects._Btn_OnceMore, 3), tostring(dropRuleTemplate.CostMoneyCount))
    else
        GUI.SetText(GUITools.GetChild(self._PanelObjects._Btn_OnceMore, 3), string.format(StringTable.Get(20414), dropRuleTemplate.CostMoneyCount))
    end
    if ten_have_count >= dropTenRuleTemplate.CostMoneyCount then
        GUI.SetText(GUITools.GetChild(self._PanelObjects._Btn_TenMore, 3),tostring(dropTenRuleTemplate.CostMoneyCount))
    else
        GUI.SetText(GUITools.GetChild(self._PanelObjects._Btn_TenMore, 3),tostring(dropTenRuleTemplate.CostMoneyCount))
    end
    GUITools.SetTokenMoneyIcon(GUITools.GetChild(self._PanelObjects._Btn_OnceMore, 2),dropRuleTemplate.CostMoneyId)
    GUITools.SetTokenMoneyIcon(GUITools.GetChild(self._PanelObjects._Btn_TenMore, 2),dropTenRuleTemplate.CostMoneyId)
end

def.method().UpdatePanel = function(self)
    local is_all_clicked = true
    local is_single = CMallMan.Instance():GetIsSingle()
    for _,v in ipairs(self._Fields) do
        v:UpdateField()
        if not v:IsClicked() then
            is_all_clicked = false
        end
    end

    self._PanelObjects._Lab_Skip:SetActive(false)
    self._PanelObjects._Btn_OnceMore:SetActive(false)
    self._PanelObjects._Btn_TenMore:SetActive(false)
    self._PanelObjects._Btn_Back:SetActive(false)
    self._PanelObjects._Btn_ElfOne:SetActive(false)
    self._PanelObjects._Btn_ElfTen:SetActive(false)

    if is_all_clicked then
        self._PanelObjects._Btn_Back:SetActive(true)
        if self._ItemSrc == Data.ENUM_ITEM_SRC.PETDROP then
            if is_single then
                self._PanelObjects._Btn_OnceMore:SetActive(true)
            else
                self._PanelObjects._Btn_TenMore:SetActive(true)
            end
        elseif self._ItemSrc == Data.ENUM_ITEM_SRC.SPRINTGIFT then
            if is_single then
                self._PanelObjects._Btn_ElfOne:SetActive(true)
            else
                self._PanelObjects._Btn_ElfTen:SetActive(true)
            end
        end
        self._PanelObjects._Btn_OpenAll:SetActive(false)
    else
        self._PanelObjects._Lab_Skip:SetActive(true)
        GUI.SetText(self._PanelObjects._Lab_Skip, StringTable.Get(31045))
    end

    self:UpdatePetButtons()
    self:UpdateElfBtns()
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_OpenAll" then
        CSoundMan.Instance():Play2DAudio(PATH.GUISound_MallLotteryClick, 0)
        -- 开启的时候每一个item需要加一个0.15s的间隔，然后在根据品质色判断再需要额外加多少s，紫色0.5s 橙色1s。
        local time = 0
        for i,v in ipairs(self._Fields) do
            if v ~= nil and v._State == FieldState.WaitClick then
                v:OnSelectItem(time)
                time = time + DotweenDeltTime
            end
        end
        self:UpdatePanel()
    elseif id == "Btn_Back"then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_OnceMore" then
        local callback = function(val)
            if val then
                CMallMan.Instance():PetExtract(1)
                game._GUIMan:CloseByScript(self)
            end
        end
        local dropRuleId = tonumber(CElementData.GetSpecialIdTemplate(OnePetDroupSpecialId).Value)
        local dropRuleTemplate = CElementData.GetTemplate("DropRule",dropRuleId)
        MsgBox.ShowQuickBuyBox(dropRuleTemplate.CostMoneyId, dropRuleTemplate.CostMoneyCount, callback)
    elseif id == "Btn_TenMore" then
        local callback = function(val)
            if val then
                CMallMan.Instance():PetExtract(10)
                game._GUIMan:CloseByScript(self)
            end
        end
        local dropTenRuleId = tonumber(CElementData.GetSpecialIdTemplate(TenPetDroupSpecialId).Value)
        local dropTenRuleTemplate = CElementData.GetTemplate("DropRule", dropTenRuleId)
        MsgBox.ShowQuickBuyBox(dropTenRuleTemplate.CostMoneyId, dropTenRuleTemplate.CostMoneyCount, callback)
    elseif id == "Btn_ElfOne" then
        local callback = function(val)
            if val then
                CMallMan.Instance():ElfExtract(1)
                game._GUIMan:CloseByScript(self)
            end
        end
        local DropRuleId = tonumber(CElementData.GetSpecialIdTemplate(OneRewardSpecialID).Value)
        local one_drop_temp = CElementData.GetTemplate("DropRule",DropRuleId)
        local rewardTable = {
            {
                ID = one_drop_temp.CostItemId2,
                Count = one_drop_temp.CostItemCount2,
                IsMoney = false
            },
            {
                ID = one_drop_temp.CostItemId1,
                Count = one_drop_temp.CostItemCount1,
                IsMoney = false
            },
        }
        MsgBox.ShowQuickMultBuyBox(rewardTable, callback)
    elseif id == "Btn_ElfTen" then
        local callback = function(val)
            if val then
                CMallMan.Instance():ElfExtract(10)
                game._GUIMan:CloseByScript(self)
            end
        end
        local TenDropRuleId = tonumber(CElementData.GetSpecialIdTemplate(TenRewardSpecialID).Value)
        local ten_drop_temp = CElementData.GetTemplate("DropRule", TenDropRuleId)
        local rewardTable = {
            {
                ID = ten_drop_temp.CostItemId2,
                Count = ten_drop_temp.CostItemCount2,
                IsMoney = false
            },
            {
                ID = ten_drop_temp.CostItemId1,
                Count = ten_drop_temp.CostItemCount1,
                IsMoney = false
            },
        }
        MsgBox.ShowQuickMultBuyBox(rewardTable, callback)
    elseif string.find(id, "ItemIcon") then
        local index = tonumber(string.sub(id, -1))
        if (index + 1) > #self._Fields then return end
        local field = self._Fields[index + 1]
        field:OnSelectItemButton()
    elseif string.find(id, "Item") then
        local index = tonumber(string.sub(id, -1))
        if index == nil then return end
        local field = self._Fields[index + 1]
        if field ~= nil then
            field:OnSelectItem(0)
            --CSoundMan.Instance():Play2DAudio(PATH.GUISound_MallLotteryClick, 0)
        end
        self:UpdatePanel()
    end
end

def.override().OnHide = function(self)
    if self._Fields ~= nil then
        for _,v in ipairs(self._Fields) do
            v:OnDestory()
        end
    end
    if self._FxTimer ~= 0 then
        _G.RemoveGlobalTimer(self._FxTimer)
        self._FxTimer = 0
    end
    if CPanelMall.Instance():IsShow() then
        CPanelMall.Instance():PlayVideoBG()
    end
    self._Fields = nil
    self._RewardDatas = nil
end

def.override().OnDestroy = function(self)
    self._PanelObjects = nil
end

CPanelMallLottery.Commit()
return CPanelMallLottery