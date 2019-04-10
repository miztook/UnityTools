local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local CWelfareMan = require "Main.CWelfareMan"
local ECostType = require "PB.Template".Goods.ECostType
local EGoodsType = require "PB.Template".Goods.EGoodsType
local ELimitType = require "PB.Template".Goods.ELimitType
local EStoreLabelType = require "PB.data".EStoreLabelType
local CMallUtility = require "Mall.CMallUtility"

local CMallPageCommonShop = Lplus.Extend(CMallPageBase, "CMallPageCommonShop")
local def = CMallPageCommonShop.define

def.field("userdata")._List_ItemsList = nil
def.field("table")._GoodTimers = nil

def.static("=>", CMallPageCommonShop).new = function()
	local pageNew = CMallPageCommonShop()
	return pageNew
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    self._List_ItemsList = uiTemplate:GetControl(0):GetComponent(ClassType.GNewList)
end

def.override("dynamic").OnData = function(self, data)
    if self._GoodTimers ~= nil then
        self:RemoveAllGoodsTimers()
    else
        self._GoodTimers = {}
    end
    if data and data.Goods then
        self._List_ItemsList:SetItemCount(#data.Goods)
    end

end

def.override().InitFrameMoney = function(self)
    if self._PageData.StoreId == 15 then
        self._PanelMall:InitFrameMoney(EnumDef.MoneyStyleType.ScoreShop)
    elseif self._PageData.StoreId == 28 then
        self._PanelMall:InitFrameMoney(EnumDef.MoneyStyleType.DressShop)
    else
        self._PanelMall:InitFrameMoney(EnumDef.MoneyStyleType.None)
    end
end

def.override().RefreshPage = function(self)
    if self._PageData == nil then
        warn(string.format("MallPanel.RefreshPage error, _PageData is nil"))
        return
    end
    if self._PageData and self._PageData.Goods then
        self:RemoveAllGoodsTimers()
        self._List_ItemsList:SetItemCount(#self._PageData.Goods)
    end
end

def.override().OnRegistUIEvent = function(self)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallCommon"
end

def.override('string').OnClick = function(self, id)
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if self._PageData ~= nil then
        local tag_data = CMallMan.Instance():GetTagDataByTagIDAndStoreID(self._PageData.StoreTagId, self._PageData.StoreId)
        if tag_data ~= nil then
            if CMallUtility.IsStoreActiveEnd(tag_data.ShowEndTime) then
                local title, msg, closeType = StringTable.GetMsg(94)
                MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, nil)    
                return
            end
        end
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local good_item = self._PageData.Goods[index]
        if good_item == nil then warn("商品数据为空，index", index) return end
        local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
        if good_temp == nil then warn("商品模板数据为空，商品id：", good_item.Id) return end
        local item_temp = CElementData.GetItemTemplate(good_temp.ItemId)
        local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._PageData.StoreId, good_item.Id)
        local img_icon = uiTemplate:GetControl(0)
        local lab_item_name = uiTemplate:GetControl(1)
        local frame_remain = uiTemplate:GetControl(2)
        local lab_remain_count = uiTemplate:GetControl(3)
        local lab_remain_tip = uiTemplate:GetControl(4)
        local lab_remain_time = uiTemplate:GetControl(5)
        local img_discount = uiTemplate:GetControl(6)
        local lab_discount = uiTemplate:GetControl(7)
        local frame_cost_diamond = uiTemplate:GetControl(8)
        local img_money_icon = uiTemplate:GetControl(9)
        local lab_cost = uiTemplate:GetControl(10)
        local frame_has_buy = uiTemplate:GetControl(11)
        local img_corner_mark = uiTemplate:GetControl(12)
        local item_icon = uiTemplate:GetControl(13)
        local lab_btn_time = uiTemplate:GetControl(14)
        local lab_cash_cost = uiTemplate:GetControl(15)
        if good_temp.IsBigIcon then
            img_icon:SetActive(true)
            item_icon:SetActive(false)
            GUITools.SetItemIcon(img_icon, good_item.IconPath)
            --GUITools.SetNativeSize(img_icon)
        else
            if good_item.GoodsType == EGoodsType.Item then
                img_icon:SetActive(false)
                item_icon:SetActive(true)
                local setting = {
                    [EItemIconTag.Number] = good_item.ItemCount,
                }
                IconTools.InitItemIconNew(item_icon, good_item.ItemId, setting, EItemLimitCheck.AllCheck)
            else
                warn("error!!!! 数据模板错误，是小图标但是不是物品类型")
            end
        end
        if good_item.CostType == ECostType.Currency then
            lab_cost:SetActive(true)
            lab_cash_cost:SetActive(false)
            if good_item.CostMoneyCount > 0 then
                img_money_icon:SetActive(true)
                GUITools.SetTokenMoneyIcon(img_money_icon, good_item.CostMoneyId)
                GUI.SetText(lab_cost, good_item.CostMoneyCount.."")
            else
                img_money_icon:SetActive(false)
                GUI.SetText(lab_cost, StringTable.Get(31029))
            end
        else
            lab_cost:SetActive(false)
            lab_cash_cost:SetActive(true)
            img_money_icon:SetActive(false)
            if good_item.CashCount > 0 then
                GUI.SetText(lab_cash_cost, string.format(StringTable.Get(31000), good_item.CashCount))
            else
                GUI.SetText(lab_cash_cost, StringTable.Get(31029))
            end
        end
        local name = ""
        if good_temp.IsUseGoodsName then
            name = CMallUtility.GetGoodsItemName(good_item.Id)
        else
            if item_temp ~= nil then
                name = CMallUtility.GetItemName(item_temp.Id)
            end
        end
        GUI.SetText(lab_item_name, name)
        lab_remain_time:SetActive(false)
        if good_temp.LimitType == ELimitType.NoLimit then
            frame_has_buy:SetActive(false)
            lab_btn_time:SetActive(false)
            lab_remain_count:SetActive(false)
            lab_remain_tip:SetActive(false)
        else
            lab_remain_count:SetActive(true)
            lab_remain_tip:SetActive(true)
            GUI.SetText(lab_remain_count, tostring(math.max(0, (good_item.Stock - hasBuyCount))))
            if good_temp.LimitType == ELimitType.Cycle then                     -- 周期性限购
                frame_cost_diamond:SetActive(true)
                frame_has_buy:SetActive(false)
                if hasBuyCount >= good_item.Stock then
                    lab_btn_time:SetActive(true)
                    lab_cost:SetActive(false)
                    lab_cash_cost:SetActive(false)
                    GUI.SetText(lab_remain_count, "")
                    GUI.SetText(lab_remain_tip, StringTable.Get(31066))
                    local callback = function()
                        local time_str = CMallUtility.GetRemainStringByEndTime(good_item.NextRefreshTime or 0)
                        GUI.SetText(lab_btn_time, time_str)
                        if GameUtil.GetServerTime() >= (good_item.NextRefreshTime or 0) then
                            if good_item.CostType == ECostType.Currency then
                                lab_cost:SetActive(true)
                                lab_cash_cost:SetActive(false)
                            else
                                lab_cash_cost:SetActive(true)
                                lab_cost:SetActive(false)
                            end
                            lab_btn_time:SetActive(false)
                            _G.RemoveGlobalTimer(self._GoodTimers[good_item.Id])
                            self._GoodTimers[good_item.Id] = 0
                        end
                    end
                    if self._GoodTimers[good_item.Id] ~= nil and self._GoodTimers[good_item.Id] ~= 0 then
                        _G.RemoveGlobalTimer(self._GoodTimers[good_item.Id])
                        self._GoodTimers[good_item.Id] = 0
                    end
                    self._GoodTimers[good_item.Id] = _G.AddGlobalTimer(1, false, callback)
                else
                    lab_btn_time:SetActive(false)
                    if good_temp.StockCycle == 24 then
                        GUI.SetText(lab_remain_tip, StringTable.Get(31057))
                    elseif good_temp.StockCycle == 168 then
                        GUI.SetText(lab_remain_tip, StringTable.Get(31058))
                    elseif good_temp.StockCycle == 720 then
                        GUI.SetText(lab_remain_tip, StringTable.Get(31059))
                    else
                        GUI.SetText(lab_remain_tip, string.format(StringTable.Get(31060), good_temp.StockCycle))
                    end
                end
            elseif good_temp.LimitType == ELimitType.Forever then               -- 角色限购
                if hasBuyCount >= good_item.Stock then
                    frame_cost_diamond:SetActive(false)
                    frame_has_buy:SetActive(true)
                    GUI.SetText(lab_remain_count, "")
                    GUI.SetText(lab_remain_tip, StringTable.Get(31066))
                else
                    frame_cost_diamond:SetActive(true)
                    frame_has_buy:SetActive(false)
                    GUI.SetText(lab_remain_tip, StringTable.Get(31062))
                end
            elseif good_temp.LimitType == ELimitType.ForeverAccount then        -- 帐号限购
                if hasBuyCount >= good_item.Stock then
                    frame_cost_diamond:SetActive(false)
                    frame_has_buy:SetActive(true)
                    GUI.SetText(lab_remain_count, "")
                    GUI.SetText(lab_remain_tip, StringTable.Get(31066))
                else
                    frame_cost_diamond:SetActive(true)
                    frame_has_buy:SetActive(false)
                    GUI.SetText(lab_remain_tip, StringTable.Get(31061))
                end
            elseif good_temp.LimitType == ELimitType.SlotLimitForStore then     -- 阶段性限购
                if hasBuyCount >= good_item.Stock then
                    frame_cost_diamond:SetActive(false)
                    frame_has_buy:SetActive(true)
                    GUI.SetText(lab_remain_count, "")
                    GUI.SetText(lab_remain_tip, StringTable.Get(31066))
                else
                    frame_cost_diamond:SetActive(true)
                    frame_has_buy:SetActive(false)
                    GUI.SetText(lab_remain_tip, StringTable.Get(31063))
                end
            end
        end
        if good_item.LabelType == EStoreLabelType.EStoreLabelType_Normal then
            img_corner_mark:SetActive(false)
        else
            img_corner_mark:SetActive(true)
            GUITools.SetGroupImg(img_corner_mark, good_item.LabelType - 1)
        end
        if good_item.DiscountType >= 10000 then
            img_discount:SetActive(false)
        else
            img_discount:SetActive(true)
            GUI.SetText(lab_discount, (100 - good_item.DiscountType/100).."%")
        end
        
        if self._CachedGoodsID > 0 then
            if good_item.Id == self._CachedGoodsID then
                local data = {storeID = self._PageData.StoreId, goodData = good_item}
                game._GUIMan:Open("CPanelMallCommonBuy", data)
            end
        end
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local index = index + 1
    if self._PageData ~= nil then
        local good_item = self._PageData.Goods[index]
        if good_item == nil then
            warn("error !! OnSelectItem 商品数据为空，index", index)
            return
        end
        local data = {storeID = self._PageData.StoreId, goodData = good_item}
        game._GUIMan:Open("CPanelMallCommonBuy", data)
    else
        warn("error !! CMallPageCommonShop self._PageData 数据为空")
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local index = index + 1
    if id_btn == "ItemIconNew" then
        local item = self._PageData.Goods[index]
        CItemTipMan.ShowItemTips(item.ItemId, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
    end
end

def.method().RemoveAllGoodsTimers = function(self)
    if self._GoodTimers == nil then return end
    for k,v in pairs(self._GoodTimers) do
--        print("移除计时器", k,v)
        if v ~= nil then
           _G.RemoveGlobalTimer(v)
        end
    end
    self._GoodTimers = {}
end

def.override().OnHide = function(self)
    self:RemoveAllGoodsTimers()
end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)
    self:RemoveAllGoodsTimers()
end

CMallPageCommonShop.Commit()
return CMallPageCommonShop