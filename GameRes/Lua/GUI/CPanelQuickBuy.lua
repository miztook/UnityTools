local Lplus = require 'Lplus'
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local ECostType = require "PB.Template".Goods.ECostType
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPanelQuickBuy = Lplus.Extend(CPanelBase, 'CPanelQuickBuy')
local def = CPanelQuickBuy.define
local instance = nil
local uid = 0

--[[ 需要设置为如下结构
    {
        {ID = 1, Count = 2, IsMoney = true},
        {ID = 1, Count = 2, IsMoney = true},
    }
]]
def.field("table")._TargetRewardTable = BlankTable
--[[ 需要消耗的货币类型及数量信息
    {
        {MoneyID = 1, Count = 2},
        {MoneyID = 1, Count = 2},
    }
]]
def.field("table")._CostMoneyInfoTable = nil
def.field("table")._CostMoneyIDs = nil

def.field("table")._PanelObjects = BlankTable
def.field("boolean")._ShouldClose = false
def.field("function")._CallBack = nil

def.static('=>', CPanelQuickBuy).Instance = function ()
	if not instance then
        instance = CPanelQuickBuy()
        instance._PrefabPath = PATH.UI_QuickBuy
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects._LabName = self:GetUIObject("Lab_Name")
    self._PanelObjects._Frame_NotEnough = self:GetUIObject("Frame_NotEnough")
    self._PanelObjects._Frame_Enough = self:GetUIObject("Frame_Enough")
    self._PanelObjects._Frame_CommonBtns = self:GetUIObject("Frame_CommonBtns")
end

-- 如果不够的话才会去兑换
local HandleRewardTable = function(rewardTable)
    local new_table = {}
    for i,v in ipairs(rewardTable) do
        if v.IsMoney then
            local have_count = game._HostPlayer:GetMoneyCountByType(v.ID)
            if have_count < v.Count then
                local item = {}
                item.ID = v.ID
                item.Count = v.Count - have_count
                item.IsMoney = v.IsMoney
                new_table[#new_table + 1] = item
            end
        else
            local have_count = game._HostPlayer._Package._NormalPack:GetItemCount(v.ID)
            if have_count < v.Count then
                local item = {}
                item.ID = v.ID
                item.Count = v.Count - have_count
                item.IsMoney = v.IsMoney
                new_table[#new_table + 1] = item
            end
        end
    end
    return new_table
end
-- data = {targetRewardTable = { {ID = 1, Count = 2, IsMoney = true}, 
                               --{ID = 1, Count = 2, IsMoney = true},
                               -- }, callback = nil }
def.override("dynamic").OnData = function(self, data)
    if data == nil then warn("请传入快速购买参数") return end
    uid = uid + 1
    self._TargetRewardTable = HandleRewardTable(data.targetRewardTable)
    self._CostMoneyIDs = CMallUtility.GetCostMoneyIDs(self._TargetRewardTable)
    self._CostMoneyInfoTable = {}
    self._CallBack = data.callback
    self:UpdatePanel()
end

def.method("=>", "string").GetFirstLineTipString = function(self)
    local str = ""
    for i,v in ipairs(self._TargetRewardTable) do
        if v.IsMoney then
            local need_money_temp = CElementData.GetMoneyTemplate(v.ID)
            if v.Count > 0 then
                str =  str .. "【" .. need_money_temp.TextDisplayName .. "】"
            end
        else
            local need_item_temp = CElementData.GetItemTemplate(v.ID)
            if v.Count > 0 then
                str = str .. "【" .. RichTextTools.GetItemNameRichText(v.ID, 1, false) .. "】"
            end
        end
    end
    return string.format(StringTable.Get(31034), str)
end

def.method("=>", "string").GetSecondLineTipString = function(self)
    local str = ""
    for i,v in ipairs(self._TargetRewardTable) do
        if v.IsMoney then
            local need_money_temp = CElementData.GetMoneyTemplate(v.ID)
            if need_money_temp ~= nil then
                str = str .. need_money_temp.TextDisplayName .. ","
            end
        else
            str = str .. RichTextTools.GetItemNameRichText(v.ID, 1, false) .. ","
        end
    end
    if str ~= "" then
        str = string.sub(str, 1, #str - 1)
    end

    for i,v in ipairs(self._CostMoneyIDs) do
        local need_money_temp = CElementData.GetMoneyTemplate(v)
        if need_money_temp ~= nil then
            str = str .. "->" .. need_money_temp.TextDisplayName
        end
    end
    
    str = string.format(StringTable.Get(31067), str)
    return str
end

def.method("number", "=>", "number").GetMoneyChangeCount = function(self, moneyID)
    for i,v in ipairs(self._CostMoneyInfoTable) do
        if v.MoneyID == moneyID then
            return v.Count
        end
    end
    return 0
end


def.method().UpdatePanel = function(self)
    self._PanelObjects._Frame_NotEnough:SetActive(false)
    self._PanelObjects._Frame_Enough:SetActive(true)
    if not CMallUtility.IsAllQuickBuyHaveTemp(self._TargetRewardTable) then
        warn("没有找到对应的兑换Id")
        self._PanelObjects._Frame_NotEnough:SetActive(true)
        self._PanelObjects._Frame_Enough:SetActive(false)
        local uiTemplate = self._PanelObjects._Frame_NotEnough:GetComponent(ClassType.UITemplate)
        local lab_not_enough = uiTemplate:GetControl(0)
        GUI.SetText(lab_not_enough, StringTable.Get(31031))
        self._ShouldClose = false
        self._CallBack = function(val)
            if val then
                -- TODO 跳转到蓝钻充值界面
                game._GUIMan:ShowTipText(StringTable.Get(31032), true)    
                self._ShouldClose = true
            end
        end
        return
    end
    local uiTemplate = self._PanelObjects._Frame_Enough:GetComponent(ClassType.UITemplate)
    local lab_tip1 = uiTemplate:GetControl(0)
    local lab_tip2 = uiTemplate:GetControl(1)
    local list_cost = uiTemplate:GetControl(2):GetComponent(ClassType.GNewList)
    GUI.SetText(lab_tip1, self:GetFirstLineTipString())
    GUI.SetText(lab_tip2, self:GetSecondLineTipString())

    if CMallUtility.CanBuyWhenNotEnough(self._TargetRewardTable) then
        self._CostMoneyInfoTable = CMallUtility.GetQuickBuyNeedCostMoneyTable(self._TargetRewardTable)
        self._ShouldClose = false
        local callback = self._CallBack
        self._CallBack = function(val)
            if val then
                local C2SQuickStoreBuyReq = require "PB.net".C2SQuickStoreBuyReq
                local QuickStoreStruct = require "PB.net".QuickStoreStruct
                local protocol = C2SQuickStoreBuyReq()
                for i,v in ipairs(self._TargetRewardTable) do
                    local tid = CMallUtility.GetQuickBuyTid(v.ID, v.IsMoney)
                    if tid > 0 then
                        local lead_temp = CElementData.GetTemplate("QuickStore", tid)
                        if lead_temp ~= nil then
                            local item = QuickStoreStruct()
                            item.Tid = tid
                            item.Count = math.ceil(v.Count/lead_temp.GainCount)
                            table.insert(protocol.Datas, item)
                        end
                    end
                end
                protocol.Param = uid
                self._CallBack = callback
                SendProtocol(protocol)
            end
        end
    else
        self._CostMoneyInfoTable = CMallUtility.GetQuickBuyNeedCostMoneyTable(self._TargetRewardTable)
        self._ShouldClose = false
        self._CallBack = function(val)
            if val then
                self._PanelObjects._Frame_NotEnough:SetActive(true)
                self._PanelObjects._Frame_Enough:SetActive(false)
                local uiTemplate = self._PanelObjects._Frame_NotEnough:GetComponent(ClassType.UITemplate)
                local lab_not_enough = uiTemplate:GetControl(0)
                GUI.SetText(lab_not_enough, StringTable.Get(31031))
                self._ShouldClose = false
                self._CallBack = function(val)
                    if val then
                        -- TODO 跳转到蓝钻充值界面
                        game._GUIMan:ShowTipText(StringTable.Get(31032), true)    
                        self._ShouldClose = true
                    end
                end
            end
        end
        
    end
    print("#self._CostMoneyIDs ", #self._CostMoneyIDs)
    list_cost:SetItemCount(#self._CostMoneyIDs)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Cancel" then
        if self._CallBack ~= nil then
            self._CallBack(false)
        end
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Ok" then
        if self._CallBack ~= nil then
            self._CallBack(true)
        end
        if self._ShouldClose then
            game._GUIMan:CloseByScript(self)
        end
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_Cost" then
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local lab_tip = uiTemplate:GetControl(0)
        local img_money = uiTemplate:GetControl(1)
        local lab_cost = uiTemplate:GetControl(2)
        local money_id = self._CostMoneyIDs[index]
        local num = self:GetMoneyChangeCount(money_id)
        local money_temp = CElementData.GetMoneyTemplate(money_id)
        if money_temp ~= nil then
            GUI.SetText(lab_tip, string.format(StringTable.Get(31077), money_temp.TextDisplayName))
        end
        GUITools.SetTokenMoneyIcon(img_money, money_id)
        GUI.SetText(lab_cost, GUITools.FormatNumber(num, true))
    end
end

-- 处理快速购买之后的回调
def.method("number", "boolean").HandleQuickStoreSuccess = function(self, id, isSuccess)
    self._ShouldClose = true
    if uid == id then
        if self._CallBack ~= nil then
            self._CallBack(isSuccess)
        end
        if self._ShouldClose then
            game._GUIMan:CloseByScript(self)
        end
    else
        if self._CallBack ~= nil then
            self._CallBack(false)
        end
        game._GUIMan:CloseByScript(self)
    end
end

def.override().OnHide = function(self)
    self._ShouldClose = false
end

def.override().OnDestroy = function(self)
    self._CallBack = nil
    self._PanelObjects = nil
    self._TargetRewardTable = nil
    self._CostMoneyInfoTable = nil
    self._CostMoneyIDs = nil
end
CPanelQuickBuy.Commit()
return CPanelQuickBuy