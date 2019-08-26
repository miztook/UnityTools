local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local CWelfareMan = require "Main.CWelfareMan"
local CMallUtility = require "Mall.CMallUtility"
local ECostType = require "PB.Template".Goods.ECostType
local EGoodsType = require "PB.Template".Goods.EGoodsType
local ELimitType = require "PB.Template".Goods.ELimitType
local EStoreLabelType = require "PB.data".EStoreLabelType
local CCommonBtn = require "GUI.CCommonBtn"
local CMallPageMysteryShop = Lplus.Extend(CMallPageBase, "CMallPageMysteryShop")
local def = CMallPageMysteryShop.define

def.field(CCommonBtn)._Btn_Refresh = nil
def.field("userdata")._List_ItemsList = nil
def.field("table")._PanelObjects = BlankTable
def.field("number")._RefreshNeedCostCount = 0
def.field("number")._RefreshMaxCount = 0
def.field("number")._RefreshTimer = 0
def.field("number")._ItemShowCount = 0
def.field("number")._ItemShowMaxCount = 0
def.field("number")._DotweenTimer = 0
def.field("table")._GloryDatas = BlankTable
def.field("table")._GoodTimers = nil
def.field("table")._GoodLifeTimers = nil
def.field("table")._VIPGridsInfo = nil

def.static("=>", CMallPageMysteryShop).new = function()
	local pageNew = CMallPageMysteryShop()
	return pageNew
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    self._List_ItemsList = uiTemplate:GetControl(0):GetComponent(ClassType.GNewList)
    self._PanelObjects._Frame_Group = uiTemplate:GetControl(1)
    self._Btn_Refresh = CCommonBtn.new(uiTemplate:GetControl(2), nil)
end

def.override("dynamic").OnData = function(self, data)
    local refreshTemp = CElementData.GetTemplate("Store", self._PageData.StoreId)
    local needCount = refreshTemp.InitRefreshMoneyCount + refreshTemp.RefreshInc * self._PageData.RefreshCount
    local glory_temp = CElementData.GetTemplate("GloryLevel", game._HostPlayer._InfoData._GloryLevel)
    self._RefreshMaxCount = glory_temp == nil and refreshTemp.RefreshMaxCount or (refreshTemp.RefreshMaxCount + glory_temp.MysticalStoreRefreshCount)
    self._RefreshNeedCostCount = needCount
    self._NeedPlayDotween = true
    self._VIPGridsInfo = CMallUtility.GetMysteryShopVIPGridTable()
    if self._VIPGridsInfo == nil then warn("error !!! 神秘商店模板数据错误，每一级增加的格子数填写错误") return end
    self._ItemShowCount = self._VIPGridsInfo[game._HostPlayer._InfoData._GloryLevel] == nil and refreshTemp.InitCellCount or self._VIPGridsInfo[game._HostPlayer._InfoData._GloryLevel]+refreshTemp.InitCellCount
    self._GloryDatas = game._CWelfareMan:GetGloryGifts()
    self._ItemShowMaxCount = self._VIPGridsInfo[#self._VIPGridsInfo] + refreshTemp.InitCellCount
    if self._GoodTimers ~= nil then
        self:RemoveGoodsTimers()
    else
        self._GoodTimers = {}
    end
    if self._GoodLifeTimers ~= nil then
        self:RemoveAllGoodsLifeTimers()
    else
        self._GoodLifeTimers = {}
    end
    self:UpdatePanel()
end

local UpdateRefreshPanel = function(self)
    local uiTemplate = self._PanelObjects._Frame_Group:GetComponent(ClassType.UITemplate)
    local store_temp = CElementData.GetTemplate("Store", self._PageData.StoreId)
    local lab_remain_time = uiTemplate:GetControl(0)
    local lab_refresh_info = uiTemplate:GetControl(1)
    local img_money_icon = uiTemplate:GetControl(2)
    local lab_cost = uiTemplate:GetControl(3)
    local btn_refresh = uiTemplate:GetControl(4)
    local callback = function()
        local next_refresh_time = self._PageData.NextRefreshTime or 0
        local time_str = CMallUtility.GetRemainStringByEndTime(next_refresh_time)
        GUI.SetText(lab_remain_time, time_str)
        if next_refresh_time > 0 then
            local remain_time = (self._PageData.NextRefreshTime - GameUtil.GetServerTime())/1000
            if remain_time <= 0 then
                self._PanelMall:ReGetPageData()
            end
        end
    end
    if self._RefreshTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RefreshTimer)
        self._RefreshTimer = 0
    end
    self._RefreshTimer = _G.AddGlobalTimer(1, false, callback)

    if self._PageData.RefreshCount >= self._RefreshMaxCount then
        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = string.format(StringTable.Get(31049), self._PageData.RefreshCount, self._RefreshMaxCount),
            [EnumDef.CommonBtnParam.MoneyID] = store_temp.RefreshCostMoneyId,
            [EnumDef.CommonBtnParam.MoneyCost] = self._RefreshNeedCostCount
        }
        self._Btn_Refresh:ResetSetting(setting)
        self._Btn_Refresh:SetInteractable(false)
        self._Btn_Refresh:MakeGray(true)
    else
        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = string.format(StringTable.Get(31048), self._PageData.RefreshCount, self._RefreshMaxCount),
            [EnumDef.CommonBtnParam.MoneyID] = store_temp.RefreshCostMoneyId,
            [EnumDef.CommonBtnParam.MoneyCost] = self._RefreshNeedCostCount
        }
        self._Btn_Refresh:ResetSetting(setting)
        self._Btn_Refresh:SetInteractable(true)
        self._Btn_Refresh:MakeGray(false)
    end
end

def.method().UpdatePanel = function(self)
    if self._PageData and self._PageData.Goods then
        self._List_ItemsList:SetItemCount(self._ItemShowMaxCount)
    end
    UpdateRefreshPanel(self)
end

def.override().RefreshPage = function(self)
    CMallPageBase.RefreshPage(self)
    if self._PageData == nil then
        warn(string.format("MallPanel.RefreshPage error, self._PageData is nil"))
        return
    end
    if self._PageData and self._PageData.Goods then
        self:OnData(self._PageData)
    end
end

def.override().OnRegistUIEvent = function(self)
    GUITools.RegisterButtonEventHandler(self._Panel, self._GameObject,true)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallMysteryShop"
end

def.override("number", "function").PlayDotween = function(self, ttl, callback)
    if self._DotweenTimer ~= 0 then
        _G.RemoveGlobalTimer(self._DotweenTimer)
        self._DotweenTimer = 0
    end
    local dotween_player = self._GameObject:GetComponent(ClassType.DOTweenPlayer)
    for i = 1,self._ItemShowCount do
        dotween_player:FindAndDoRestart(i)
    end
    self._DotweenTimer = _G.AddGlobalTimer(ttl, true, callback)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Refresh" then
        if self._PageData.RefreshCount < self._RefreshMaxCount then
            local callback = function(var)
                if var then
                    if self._PageData == nil then
                        warn("error !!! : CMallPageMysteryShop 的 self._PageData为空！")
                        return
                    end
                    local store_temp = CElementData.GetTemplate("Store", self._PageData.StoreId)
                    local callback1 = function(var1)
                        if var1 then
                            self._PanelMall:RequestRefreshPanel()
                        end
                    end
                    MsgBox.ShowQuickBuyBox(store_temp.RefreshCostMoneyId, self._RefreshNeedCostCount, callback1)
                end
            end
            local title, str, closeType = StringTable.GetMsg(57)
		    local msg = string.format(str, self._RefreshNeedCostCount)
	        MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
        else
            game._GUIMan:ShowTipText(StringTable.Get(31803), true)
        end
    elseif id == "Lab_BuyTips" then
        
    end
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
        local frame_open = uiTemplate:GetControl(14)
        local frame_not_open = uiTemplate:GetControl(15)
        
        if index > self._ItemShowCount or index > #self._PageData.Goods then
            frame_open:SetActive(false)
            frame_not_open:SetActive(true)
            local store_temp = CElementData.GetTemplate("Store", self._PageData.StoreId)
            local msg = ""
            if index > #self._PageData.Goods then
                msg = StringTable.Get(31051)
            else
                msg = string.format(StringTable.Get(31011), self._GloryDatas[CMallUtility.GetVIPLevelByIndex(index)].Name)
            end
            GUI.SetText(frame_not_open:FindChild("Lab_ItemName"), msg)
        else
            local good_item = self._PageData.Goods[index]
            if good_item == nil then
                warn("神秘商店商品数据为空, index:", index)
                return
            end
            local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
            if good_temp == nil then
                warn("商品模板数据为空，商品id：", good_item.Id)
                return
            end
            frame_open:SetActive(true)
            frame_not_open:SetActive(false)
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
            local lab_level_need = uiTemplate:GetControl(16)
            local lab_btn_time = uiTemplate:GetControl(17)
            local lab_cash_cost = uiTemplate:GetControl(18)
            local lab_refresh_tip = uiTemplate:GetControl(19)
            local img_gift_bg = uiTemplate:GetControl(20)
            local lab_gift = uiTemplate:GetControl(21)
            lab_level_need:SetActive(false)
--            lab_remain_time:SetActive(false)
            local now_time = GameUtil.GetServerTime()
            if good_item.ShowEndTime > 0 and good_item.ShowEndTime > now_time then
                lab_remain_time:SetActive(true)
                local callback = function()
                    local time_str = CMallUtility.GetRemainStringByEndTime(good_item.ShowEndTime or 0)
                    GUI.SetText(lab_remain_time, time_str)
                    if GameUtil.GetServerTime() > (good_item.ShowEndTime or 0) then
                        self._PanelMall:RequestSmallTabData(self._PanelMall._CurrentSelectBigTabID, self._PanelMall._CurrentSelectSmallTabID)
                        _G.RemoveGlobalTimer(self._GoodLifeTimers[good_item.Id])
                        self._GoodLifeTimers[good_item.Id] = 0
                    end
                end
                if self._GoodLifeTimers[good_item.Id] ~= nil and self._GoodLifeTimers[good_item.Id] > 0 then
                    _G.RemoveGlobalTimer(self._GoodLifeTimers[good_item.Id])
                    self._GoodLifeTimers[good_item.Id] = 0
                end
                self._GoodLifeTimers[good_item.Id] = _G.AddGlobalTimer(1, false, callback)
            else
                lab_remain_time:SetActive(false)
            end
            do  -- 物品图标和名字
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
                local name = ""
                if good_temp.IsUseGoodsName then
                    name = CMallUtility.GetGoodsItemName(good_item.Id)
                else
                    if item_temp ~= nil then
                        name = CMallUtility.GetItemName(item_temp.Id)
                    end
                end
                GUI.SetText(lab_item_name, name)
            end
            do  -- 该商品的刷新时间和购买限制提示
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
                    local cash_cost = CMallMan.Instance():GetGoodsDataCashCost(good_item)
                    if cash_cost > 0 then
                        GUI.SetText(lab_cash_cost, string.format(StringTable.Get(31000), GUITools.FormatNumber(cash_cost, false)))
                    else
                        GUI.SetText(lab_cash_cost, StringTable.Get(31029))
                    end
                end
                if good_temp.LimitType == ELimitType.NoLimit then
                    frame_has_buy:SetActive(false)
                    lab_refresh_tip:SetActive(false)
                    lab_btn_time:SetActive(false)
                    lab_remain_count:SetActive(false)
                    lab_remain_tip:SetActive(false)
                else
                    lab_remain_count:SetActive(true)
                    lab_remain_tip:SetActive(true)
                    lab_refresh_tip:SetActive(false)
                    lab_btn_time:SetActive(false)
                    GUI.SetText(lab_remain_count, tostring(math.max(0, (good_item.Stock - hasBuyCount))))
                    if good_temp.LimitType == ELimitType.Cycle or good_temp.LimitType == ELimitType.WeekLimit or good_temp.LimitType == ELimitType.MonthLimit then
                        frame_cost_diamond:SetActive(true)
                        frame_has_buy:SetActive(false)
                        if hasBuyCount >= good_item.Stock then
                            lab_refresh_tip:SetActive(true)
                            lab_btn_time:SetActive(true)
                            lab_cost:SetActive(false)
                            lab_cash_cost:SetActive(false)
                            GUI.SetText(lab_remain_count, "")
                            GUI.SetText(lab_remain_tip, StringTable.Get(31066))
                            local callback = function()
                                local time_str = CMallUtility.GetRemainStringByEndTime(good_item.NextRefreshTime or 0)
                                GUI.SetText(lab_btn_time, time_str)
                                if GameUtil.GetServerTime() > (good_item.NextRefreshTime or 0) then
                                    lab_refresh_tip:SetActive(false)
                                    lab_btn_time:SetActive(false)
                                    if good_item.CostType == ECostType.Currency then
                                        lab_cost:SetActive(true)
                                        lab_cash_cost:SetActive(false)
                                    else
                                        lab_cost:SetActive(false)
                                        lab_cash_cost:SetActive(true)
                                    end
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
                            lab_refresh_tip:SetActive(false)
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
                    elseif good_temp.LimitType == ELimitType.ForeverAccount then
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
                    elseif good_temp.LimitType == ELimitType.Forever then
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
                    elseif good_temp.LimitType == ELimitType.SlotLimitForStore then
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
            end
            do  -- 数量、花费、购买限制信息显示
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
                
            end

            local gift_table = CMallUtility.GetGiftItemsByGoodsData(good_item.GiftItemId, good_item.GiftItemCount, good_item.GiftMoneyId, good_item.GiftMoneyCount)
            if #gift_table <= 0 then
                img_gift_bg:SetActive(false)
            else
                img_gift_bg:SetActive(true)
                local gift_data = gift_table[1]
                local str = ""
                if gift_data.IsTokenMoney then
                    local money_temp = CElementData.GetMoneyTemplate(gift_data.Data.Id)
                    if money_temp ~= nil then
                        str = string.format(StringTable.Get(31086), gift_data.Data.Count, money_temp.TextDisplayName)
                    end
                else
                    local item_temp = CElementData.GetItemTemplate(gift_data.Data.Id)
                    if item_temp ~= nil then
                        str = string.format(StringTable.Get(31086), gift_data.Data.Count, item_temp.TextDisplayName)
                    end
                end
                GUI.SetText(lab_gift, str)
            end

            if self._CachedGoodsID > 0 then
                if good_item.Id == self._CachedGoodsID then
                    local data = {storeID = self._PageData.StoreId, goodData = good_item}
                    game._GUIMan:Open("CPanelMallCommonBuy", data)
                end
            end
        end
    end
end

def.override('userdata', 'string', 'number').OnSelectItem = function(self, item, id, index)
    local index = index + 1
    if index > self._ItemShowCount then return end
    if self._PageData ~= nil and self._PageData.Goods[index] ~= nil then
        local good_item = self._PageData.Goods[index]
        local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
        if good_temp == nil then
            warn("error !! OnSelectItem 商品模板数据为空，商品id：", good_item.Id)
            return
        end
        local data = {storeID = self._PageData.StoreId, goodData = good_item}
        game._GUIMan:Open("CPanelMallCommonBuy", data)
    else
        warn("CMallPageMysteryShop self._PageData 数据为空")
    end

	CSoundMan.Instance():Play2DAudio(PATH.GUISound_Btn_Press, 0)
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local index = index + 1
    if index > self._ItemShowCount then return end
    if id_btn == "ItemIconNew" then
        local item = self._PageData.Goods[index]
        CItemTipMan.ShowItemTips(item.ItemId, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
    elseif id_btn == "Btn_Buy" then
        if index > self._ItemShowCount then return end
        if self._PageData ~= nil then
            local good_item = self._PageData.Goods[index]
            local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
            if good_temp == nil then
                warn("error !! OnSelectItem 商品模板数据为空，商品id：", good_item.Id)
                return
            end
            local data = {storeID = self._PageData.StoreId, goodData = good_item}
            game._GUIMan:Open("CPanelMallCommonBuy", data)
        else
            warn("CMallPageMysteryShop self._PageData 数据为空")
        end
    end
end

def.method().RemoveGoodsTimers = function(self)
    if self._GoodTimers == nil then return end
    for k,v in pairs(self._GoodTimers) do
        if v ~= nil then
           _G.RemoveGlobalTimer(v)
        end
    end
    self._GoodTimers = {}
end

def.method().RemoveAllGoodsLifeTimers = function(self)
   if self._GoodLifeTimers == nil then return end
   for k,v in pairs(self._GoodLifeTimers) do
       if v ~= nil then
           _G.RemoveGlobalTimer(v)
       end
   end
   self._GoodLifeTimers = {}
end

def.override().OnHide = function(self)
    if self._RefreshTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RefreshTimer)
        self._RefreshTimer = 0
    end
    self:RemoveGoodsTimers()
    self:RemoveAllGoodsLifeTimers()
end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)
    if self._RefreshTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RefreshTimer)
        self._RefreshTimer = 0
    end
    if self._Btn_Refresh ~= nil then
        self._Btn_Refresh:Destroy()
        self._Btn_Refresh = nil
    end
    self._PanelObjects = nil
    self._GloryDatas = nil
    self:RemoveGoodsTimers()
    self:RemoveAllGoodsLifeTimers()
end

CMallPageMysteryShop.Commit()
return CMallPageMysteryShop