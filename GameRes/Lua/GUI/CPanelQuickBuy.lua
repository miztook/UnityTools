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

def.field("table")._PanelObjects = BlankTable
def.field("number")._NeedMoneyID = 0
def.field("number")._NeedCount = 0
def.field("boolean")._ShouldClose = false
def.field("boolean")._IsMoney = true
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

-- data = {moneyID = 1, count = 2, callback = nil}
def.override("dynamic").OnData = function(self, data)
    if data == nil then warn("请传入快速购买参数") return end
    uid = uid + 1
    self._NeedMoneyID = data.moneyID or 0
    self._NeedCount = data.count
    self._CallBack = data.callback
    self._IsMoney = data.isMoney
    self:UpdatePanel()
end

def.method("number", "=>", "table").GetCostMoneyList = function(self, quickID)
    local quick_temp = CElementData.GetTemplate("QuickStore", quickID)
    if quick_temp == nil then return end
    local ids = {}
    if quick_temp.CostMoneyId1 > 0 then
        ids[#ids + 1] = quick_temp.CostMoneyId1
    end
    if quick_temp.CostMoneyId2 > 0 then
        ids[#ids + 1] = quick_temp.CostMoneyId2
    end
    if quick_temp.CostMoneyId3 > 0 then
        ids[#ids + 1] = quick_temp.CostMoneyId3
    end
    return ids
end

def.method("number", "=>", "string").GetTipString = function(self, quickID)
    local quick_temp = CElementData.GetTemplate("QuickStore", quickID)
    if quick_temp == nil then return "" end
    local str = ""
    local count = 0
    if quick_temp.GainId > 0 then
        if quick_temp.ItemType == 0 then
            local money_temp = CElementData.GetTemplate("Money", quick_temp.GainId)
            str = str..money_temp.TextDisplayName.."->"
            count = count + 1
        else
            str = str..RichTextTools.GetItemNameRichText(quick_temp.GainId, 1, false).."->"
            count = count + 1
        end
    end
    if quick_temp.CostMoneyId1 > 0 then
        local money_temp = CElementData.GetTemplate("Money", quick_temp.CostMoneyId1)
        str = str..money_temp.TextDisplayName.."->"
        count = count + 1
    end
    if quick_temp.CostMoneyId2 > 0 then
        local money_temp = CElementData.GetTemplate("Money", quick_temp.CostMoneyId2)
        str = str..money_temp.TextDisplayName.."->"
        count = count + 1
    end
    if quick_temp.CostMoneyId3 > 0 then
        local money_temp = CElementData.GetTemplate("Money", quick_temp.CostMoneyId3)
        str = str..money_temp.TextDisplayName.."->"
        count = count + 1
    end
    if count > 0 then
        str = string.sub(str, 1, #str - 2)
    end
    str = string.format(StringTable.Get(31067), str)
    return str
end

def.method().UpdatePanel = function(self)
--    if CMallUtility.CanBuyWhenNotEnough(self._NeedMoneyID, true, self._NeedCount) then
    self._PanelObjects._Frame_NotEnough:SetActive(false)
    self._PanelObjects._Frame_Enough:SetActive(true)
    local quick_buy_temp = CMallUtility.GetQuickBuyTemp(self._NeedMoneyID, self._IsMoney)
    if quick_buy_temp == nil then
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
    local have_res_count = 0
    if self._IsMoney then
        have_res_count = game._HostPlayer:GetMoneyCountByType(quick_buy_temp.GainId)
    else
        have_res_count = game._HostPlayer._Package._NormalPack:GetItemCount(quick_buy_temp.GainId)
    end
--    local have_money0 = game._HostPlayer:GetMoneyCountByType(quick_buy_temp.GainId)
    local real_need_count = math.ceil((self._NeedCount - have_res_count)/quick_buy_temp.GainCount) * quick_buy_temp.CostMoneyCount
    print("real_need_count ", real_need_count)
    local quick_cost_ids = self:GetCostMoneyList(quick_buy_temp.Id)
    local lab_cost1 = uiTemplate:GetControl(0)
    local lab_cost2 = uiTemplate:GetControl(1)
    local lab_cost3 = uiTemplate:GetControl(2)
    local lab_tip1 = uiTemplate:GetControl(3)
    local lab_tip2 = uiTemplate:GetControl(4)
    GUI.SetText(lab_cost1, "")
    GUI.SetText(lab_cost2, "")
    GUI.SetText(lab_cost3, "")
    if self._IsMoney then
        local need_money_temp = CElementData.GetMoneyTemplate(self._NeedMoneyID)
        GUI.SetText(lab_tip1, string.format(StringTable.Get(31034), need_money_temp.TextDisplayName))
    else
        GUI.SetText(lab_tip1, string.format(StringTable.Get(31034), RichTextTools.GetItemNameRichText(self._NeedMoneyID, 1, false)))
    end
--    if #quick_cost_ids <= 1 then
--        lab_tip2:SetActive(false)
--    else
--        lab_tip2:SetActive(true)
--    end
    GUI.SetText(lab_tip2, self:GetTipString(quick_buy_temp.Id))
    if CMallUtility.CanBuyWhenNotEnough(self._NeedMoneyID, self._IsMoney, self._NeedCount) then
        for i=1,3 do
            local tab_cost = uiTemplate:GetControl(4+i)
            if i <= #quick_cost_ids then
                tab_cost:SetActive(true)
                local lab_tip = tab_cost:FindChild("Lab_Tip")
                local img_money = tab_cost:FindChild("Img_Money"..i)
                local lab_cost = tab_cost:FindChild("Lab_Cost"..i)
                local money_temp = CElementData.GetMoneyTemplate(quick_cost_ids[i])
                if money_temp == nil then warn("error !!!配的货币ID不存在") return end
                GUI.SetText(lab_tip, string.format(StringTable.Get(31037), money_temp.TextDisplayName))
                GUITools.SetTokenMoneyIcon(img_money, quick_cost_ids[i])
                local have_count = game._HostPlayer:GetMoneyCountByType(quick_cost_ids[i])
                if have_count >= real_need_count then
                    GUI.SetText(uiTemplate:GetControl(i - 1), real_need_count.."")
                    real_need_count = 0
                else
                    GUI.SetText(uiTemplate:GetControl(i - 1), (have_count).."")
                    real_need_count = real_need_count - have_count
                end
            else
                tab_cost:SetActive(false)
            end
        end
        self._ShouldClose = false
        local callback = self._CallBack
        self._CallBack = function(val)
            if val then
                local C2SQuickStoreBuyReq = require "PB.net".C2SQuickStoreBuyReq
                local protocol = C2SQuickStoreBuyReq()
                local tid = CMallUtility.GetQuickBuyTid(self._NeedMoneyID, self._IsMoney)
                local have_count = 0
                if self._IsMoney then
                    have_count = game._HostPlayer:GetMoneyCountByType(self._NeedMoneyID)
                else
                    have_count = game._HostPlayer._Package._NormalPack:GetItemCount(self._NeedMoneyID)
                end
                if tid > 0 then
                    protocol.Tid = tid
                    protocol.Count = math.ceil((self._NeedCount - have_count)/quick_buy_temp.GainCount)
                    protocol.Param = uid
                    SendProtocol(protocol)
                    self._CallBack = callback
                end
            end
        end
    else
        for i=1,3 do
            local tab_cost = uiTemplate:GetControl(4+i)
            if i <= #quick_cost_ids then
                tab_cost:SetActive(true)
                local lab_tip = tab_cost:FindChild("Lab_Tip")
                local img_money = tab_cost:FindChild("Img_Money"..i)
                local lab_cost = tab_cost:FindChild("Lab_Cost"..i)
                local money_temp = CElementData.GetMoneyTemplate(quick_cost_ids[i])
                if money_temp == nil then warn("error !!!配的货币ID不存在") return end
                GUI.SetText(lab_tip, string.format(StringTable.Get(31037), money_temp.TextDisplayName))
                GUITools.SetTokenMoneyIcon(img_money, quick_cost_ids[i])
                local have_count = game._HostPlayer:GetMoneyCountByType(quick_cost_ids[i])
                if have_count >= real_need_count then
                    GUI.SetText(uiTemplate:GetControl(i - 1), real_need_count.."")
                    real_need_count = 0
                else
                    if i == #quick_cost_ids then
                        GUI.SetText(uiTemplate:GetControl(i - 1), (real_need_count).."")
                        real_need_count = 0
                    else
                        GUI.SetText(uiTemplate:GetControl(i - 1), (have_count).."")
                        real_need_count = real_need_count - have_count
                    end
                end
            else
                tab_cost:SetActive(false)
            end
        end
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
    self._NeedMoneyID = 0
    self._NeedCount = 0
end
CPanelQuickBuy.Commit()
return CPanelQuickBuy