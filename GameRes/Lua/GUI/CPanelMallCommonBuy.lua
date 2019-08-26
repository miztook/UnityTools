local Lplus = require 'Lplus'
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local ECostType = require "PB.Template".Goods.ECostType
local EItemType = require "PB.Template".Item.EItemType
local EItemEventType = require "PB.data".EItemEventType
local EGoodsType = require "PB.Template".Goods.EGoodsType
local EGoodsShowType = require "PB.Template".Goods.EGoodsShowType
local ELimitType = require "PB.Template".Goods.ELimitType
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CCommonBtn = require "GUI.CCommonBtn"
local CPanelMallCommonBuy = Lplus.Extend(CPanelBase, 'CPanelMallCommonBuy')
local def = CPanelMallCommonBuy.define
local instance = nil

def.field("table")._PanelObjects = BlankTable
def.field("number")._StoreID = 0                    -- 要购买的商品的StoreID
def.field("table")._GoodData = nil                  -- 商品数据，服务器发送过来的GoodsDataTemp结构
def.field("number")._RemainTimeTimer = 0            -- 商品剩余刷新时间timer
def.field("number")._LifeTimeTimer = 0              -- 商品剩余生命时间timer
def.field("table")._GainItems = nil                 -- 获得的东西们
def.field("table")._GainItemsM = nil                -- 概率获得的东西们
def.field("table")._GiftItems = nil                 -- 赠送的东西们
def.field("number")._MinCount = 1                   -- 可以选择的数量的下限
def.field("number")._MaxCount = 1                   -- 可以选择的数量的上限
def.field("number")._CurCount = 1                   -- 当前选择的数量
def.field("function")._GoodsInfoHandleFunc = nil    -- 商品信息右侧显示函数
def.field(CCommonBtn)._Btn_OK = nil                 -- 确定按钮

def.static('=>', CPanelMallCommonBuy).Instance = function ()
	if not instance then
        instance = CPanelMallCommonBuy()
        instance._PrefabPath = PATH.UI_MallCommonBuy
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects._LabName = self:GetUIObject("Lab_Name")
    self._PanelObjects._Frame_Left = self:GetUIObject("Frame_Left")
    self._PanelObjects._Frame_Right = self:GetUIObject("Frame_Right")
    self._PanelObjects._Frame_CommonBtns = self:GetUIObject("Frame_CommonBtns")
    self._Btn_OK = CCommonBtn.new(self:GetUIObject("Btn_OK"), nil)
end

-- data = {storeID = 1, goodData = goodItem}
def.override("dynamic").OnData = function(self, data)
    if data == nil then warn("商品数据为空，请传入正确的数据") return end
    self._StoreID = data.storeID or 0
    self._GoodData = data.goodData
    self._GainItems = {}
    self._GainItemsM = {}
    self._GiftItems = {}
    self:GenerateItemsByGoodsData()
    self:UpdatePanel()
end

-- 根据金币ID和数量生成一个reward的结构
local GetMoneyItemsDataByMoneyID = function(moneyID, count)
    if moneyID <= 0 then return nil end
    return {
             {   IsTokenMoney = true,
				Data = 
				{
					Id = moneyID, 
					Count = count
				}
              }
            }
end

local InsertToSelfTable = function(selfTable, targetTable)
    if selfTable == nil or targetTable == nil then return end
    for _,v in ipairs(targetTable) do
        selfTable[#selfTable + 1] = v
    end
end

-- 商品显示类型为普通类型时，右边的特殊显示操作函数
local RightPanelShowNormalFunc = function(self, uiTemplate)
    uiTemplate:GetControl(8):SetActive(false)
    uiTemplate:GetControl(9):SetActive(false)
    GUI.SetText(uiTemplate:GetControl(6), StringTable.Get(31068))
end

-- 商品显示类型为掉落礼包类型时，右边的特殊显示操作函数
local RightPanelShowDropBagFunc = function(self, uiTemplate)
    if self._GoodData == nil then warn("error 商品数据为空") return end
    if self._StoreID <=0 then warn("error 商店ID为0") return end
    local good_item = self._GoodData
    local goods_temp = CElementData.GetTemplate("Goods", self._GoodData.Id)
    if goods_temp == nil then
        warn("error !!! 该商品不存在，请仔细检查商品数据表")
        return
    end
    local str = string.format(StringTable.Get(31069), RichTextTools.GetItemNameRichText(good_item.ItemId, 1, false))
    GUI.SetText(uiTemplate:GetControl(6), str)
    GUI.SetText(uiTemplate:GetControl(8), StringTable.Get(31070))
end

-- 商品显示类型为权重礼包类型时，右边的特殊显示操作函数
local RightPanelShowWeightBagFunc = function(self, uiTemplate)
    uiTemplate:GetControl(8):SetActive(false)
    uiTemplate:GetControl(9):SetActive(false)
    if self._GoodData == nil then warn("error 商品数据为空") return end
    if self._StoreID <=0 then warn("error 商店ID为0") return end
    local good_item = self._GoodData
    local goods_temp = CElementData.GetTemplate("Goods", self._GoodData.Id)
    if goods_temp == nil then
        warn("error !!! 该商品不存在，请仔细检查商品数据表 -- RightPanelShowWeightBagFunc")
        return
    end
    local item_temp = CElementData.GetItemTemplate(good_item.ItemId)
    if item_temp == nil then
        return
    end
    local EItemType = require "PB.Template".Item.EItemType
    local EItemEventType = require "PB.data".EItemEventType
    if item_temp.ItemType == EItemType.TreasureBox and item_temp.EventType1 ~= nil and item_temp.EventType1 == EItemEventType.ItemEvent_OpenBox then
        local drup_ID = tonumber(item_temp.Type1Param1)
        if drup_ID > 0 then
            local drup_temp = CElementData.GetTemplate("DropRule", drup_ID)
            if drup_temp == nil then warn("彩票规则id配置错误,物品ID是：", drup_ID) return end
            if drup_temp.DropLibWeights == nil or #drup_temp.DropLibWeights <= 0 then warn("彩票规则掉落随机列表库为空，ID：", drup_ID) end
            local drup_lib_temp = CElementData.GetTemplate("DropLibrary", drup_temp.DropLibWeights[1].DropLibId)
            if drup_lib_temp == nil then warn("掉落库为空，掉落库ID为：", drup_temp.DropLibWeights[1].DropLibId) return end
            if drup_lib_temp.DropLibType ~= 2 then warn("商品表里面配的是权重掉落，但是掉落库不是权重掉落，商品ID：", self._GoodData.Id) return end
            if drup_lib_temp.DropMinNum == drup_lib_temp.DropMaxNum then
                local str = string.format(StringTable.Get(31071), RichTextTools.GetItemNameRichText(good_item.ItemId, 1, false), drup_lib_temp.DropMinNum)
                GUI.SetText(uiTemplate:GetControl(6), str)
            else
                local str = string.format(StringTable.Get(31072), RichTextTools.GetItemNameRichText(good_item.ItemId, 1, false), drup_lib_temp.DropMinNum, drup_lib_temp.DropMaxNum)
                GUI.SetText(uiTemplate:GetControl(6), str)
            end
        end
    end
end

-- 商品显示类型为月卡类型时，右边的特殊显示操作函数
local RightPanelShowMonthlyCardFunc = function(self, uiTemplate)
    uiTemplate:GetControl(7):SetActive(false)
    uiTemplate:GetControl(1):SetActive(false)
    local goods_temp = CElementData.GetTemplate("Goods", self._GoodData.Id)
    if goods_temp == nil then
        warn("error !!! 该商品不存在，请仔细检查商品数据表 -- RightPanelShowMonthlyCardFunc")
        return
    end
    local monthly_temp = CElementData.GetTemplate("MonthlyCard", goods_temp.MonthlyCardId)
    if monthly_temp == nil then warn("月卡数据为空，ID：", goods_temp.MonthlyCardId) return end
    local str = string.format(StringTable.Get(31073), monthly_temp.DisplayName)
    GUI.SetText(uiTemplate:GetControl(6), str)
    str = string.format(StringTable.Get(31074), monthly_temp.Days)
    GUI.SetText(uiTemplate:GetControl(8), str)
end

-- 商品显示类型为基金类型时，右边的特殊显示操作函数
local RightPanelShowFundFunc = function(self, uiTemplate)
    uiTemplate:GetControl(7):SetActive(false)
    uiTemplate:GetControl(1):SetActive(false)
    uiTemplate:GetControl(8):SetActive(true)
    uiTemplate:GetControl(9):SetActive(false)
    local goods_temp = CElementData.GetTemplate("Goods", self._GoodData.Id)
    if goods_temp == nil then
        warn("error !!! 该商品不存在，请仔细检查商品数据表 -- RightPanelShowFundFunc")
        return
    end
    local fund_temp = CElementData.GetTemplate("Fund", goods_temp.FundId)
    if fund_temp == nil then warn("基金数据为空，ID: ", goods_temp.FundId) return end
    local str = string.format(StringTable.Get(31073), fund_temp.DisplayName)
    GUI.SetText(uiTemplate:GetControl(6), str)
    GUI.SetText(uiTemplate:GetControl(8), StringTable.Get(31075))
end

-- 生成可获得的物品的数据
def.method().GenerateItemsByGoodsData = function(self)
    if self._GoodData == nil then warn("error 商品数据为空") return end
    if self._StoreID <=0 then warn("error 商店ID为0") return end

    local goods_temp = CElementData.GetTemplate("Goods", self._GoodData.Id)
    if goods_temp == nil then
        warn("error !!! 该商品不存在，请仔细检查商品数据表 -- GenerateItemsByGoodsData")
        return
    end
    local good_item = self._GoodData
    if good_item.CostType == ECostType.Currency then
        self._MinCount = 1
        self._CurCount = 1
        local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._StoreID, good_item.Id)
        local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
        if good_temp.LimitType == ELimitType.NoLimit then
            self._MaxCount = 99
        else
            self._MaxCount = good_item.Stock - hasBuyCount
        end
    else
        -- send receipt cache
        CPlatformSDKMan.Instance():ProcessPurchaseCache()

        self._MinCount = 1
        self._MaxCount = 1
        self._CurCount = 1
    end
    if goods_temp.GoodsShowType == EGoodsShowType.GoodsShowType_Normal then
        InsertToSelfTable(self._GainItems, CMallUtility.GetItemsShowDataByItemID(good_item.ItemId, good_item.ItemCount))
        InsertToSelfTable(self._GainItems, GetMoneyItemsDataByMoneyID(good_item.GainMoneyId, good_item.GainMoneyCount))
        InsertToSelfTable(self._GiftItems, CMallUtility.GetItemsShowDataByItemID(good_item.GiftItemId, good_item.GiftItemCount))
        InsertToSelfTable(self._GiftItems, GetMoneyItemsDataByMoneyID(good_item.GiftMoneyId, good_item.GiftMoneyCount))
        self._GoodsInfoHandleFunc = RightPanelShowNormalFunc
    elseif goods_temp.GoodsShowType == EGoodsShowType.GoodsShowType_DropBag then
        InsertToSelfTable(self._GainItems, CMallUtility.GetNonRandomShowDataByItemID(good_item.ItemId, good_item.ItemCount))
        InsertToSelfTable(self._GainItems, GetMoneyItemsDataByMoneyID(good_item.GainMoneyId, good_item.GainMoneyCount))
        InsertToSelfTable(self._GainItemsM, CMallUtility.GetRandomShowDataByItemID(good_item.ItemId, good_item.ItemCount))
        InsertToSelfTable(self._GiftItems, CMallUtility.GetItemsShowDataByItemID(good_item.GiftItemId, good_item.GiftItemCount))
        InsertToSelfTable(self._GiftItems, GetMoneyItemsDataByMoneyID(good_item.GiftMoneyId, good_item.GiftMoneyCount))
        self._GoodsInfoHandleFunc = RightPanelShowDropBagFunc
    elseif goods_temp.GoodsShowType == EGoodsShowType.GoodsShowType_WeightBag then
        InsertToSelfTable(self._GainItems, CMallUtility.GetItemsShowDataByItemID(good_item.ItemId, good_item.ItemCount))
        InsertToSelfTable(self._GainItems, GetMoneyItemsDataByMoneyID(good_item.GainMoneyId, good_item.GainMoneyCount))
        InsertToSelfTable(self._GiftItems, CMallUtility.GetItemsShowDataByItemID(good_item.GiftItemId, good_item.GiftItemCount))
        InsertToSelfTable(self._GiftItems, GetMoneyItemsDataByMoneyID(good_item.GiftMoneyId, good_item.GiftMoneyCount))
        self._GoodsInfoHandleFunc = RightPanelShowWeightBagFunc
    elseif goods_temp.GoodsShowType == EGoodsShowType.GoodsShowType_MonthlyCard then
        local monthly_temp = CElementData.GetTemplate("MonthlyCard", goods_temp.MonthlyCardId)
        if monthly_temp ~= nil then
            InsertToSelfTable(self._GainItemsM, GetMoneyItemsDataByMoneyID(monthly_temp.MoneyId1, monthly_temp.MoneyCount1))
            InsertToSelfTable(self._GainItemsM, GetMoneyItemsDataByMoneyID(monthly_temp.MoneyId2, monthly_temp.MoneyCount2))
            InsertToSelfTable(self._GainItemsM, CMallUtility.GetItemsShowDataByItemID(monthly_temp.ItemId, monthly_temp.ItemCount))
            InsertToSelfTable(self._GainItems, GetMoneyItemsDataByMoneyID(monthly_temp.GainMoneyId, monthly_temp.GainMoneyCount))
            InsertToSelfTable(self._GainItems, CMallUtility.GetItemsShowDataByItemID(monthly_temp.GainItemId1, monthly_temp.GainItemCount1))
            InsertToSelfTable(self._GainItems, CMallUtility.GetItemsShowDataByItemID(monthly_temp.GainItemId2, monthly_temp.GainItemCount2))
        end
        self._GoodsInfoHandleFunc = RightPanelShowMonthlyCardFunc
        self._MaxCount = 1
        self._CurCount = 1
    elseif goods_temp.GoodsShowType == EGoodsShowType.GoodsShowType_Fund then
        local fund_temp = CElementData.GetTemplate("Fund", goods_temp.FundId)
        if fund_temp ~= nil then
            InsertToSelfTable(self._GainItems, GetMoneyItemsDataByMoneyID(fund_temp.RewardMoneyId, fund_temp.RewardMoneyCount))
        end
        self._GoodsInfoHandleFunc = RightPanelShowFundFunc
        self._MaxCount = 1
        self._CurCount = 1
    end
end

-- 更新左侧商品信息
local UpdateLeftTab = function(self)
    if self._GoodData == nil then warn("error 商品数据为空") return end
    if self._StoreID <=0 then warn("error 商店ID为0") return end
    local uiTemplate = self._PanelObjects._Frame_Left:GetComponent(ClassType.UITemplate)
    local good_item = self._GoodData
    local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
    local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._StoreID, good_item.Id)
    local glory_level = game._HostPlayer._InfoData._GloryLevel
    local frame_remain = uiTemplate:GetControl(0)
    local lab_remain_tip = uiTemplate:GetControl(1)
    local lab_remain_count = uiTemplate:GetControl(2)
    local img_icon = uiTemplate:GetControl(3)
    local frame_cost_diamond = uiTemplate:GetControl(4)
    local img_money = uiTemplate:GetControl(5)
    local lab_cost = uiTemplate:GetControl(6)
    local img_mask = uiTemplate:GetControl(7)
    local lab_mask_tip = uiTemplate:GetControl(8)
    local item_icon = uiTemplate:GetControl(9)
    local lab_remain_time = uiTemplate:GetControl(10)
    local img_discount = uiTemplate:GetControl(11)
    local lab_discount = uiTemplate:GetControl(12)
    local img_speci_icon = uiTemplate:GetControl(13)
    local lab_remain_time_tip = uiTemplate:GetControl(14)
    if good_temp == nil then
        warn("error : 商品模板数据为空 ID：", good_item.Id)
        return
    end
    local name = ""
    if good_temp.IsUseGoodsName then
        name = CMallUtility.GetGoodsItemName(good_item.Id)
    else
        local item_temp = CElementData.GetItemTemplate(good_temp.ItemId)
        if item_temp ~= nil then
            name = CMallUtility.GetItemName(item_temp.Id)
        end
    end
    GUI.SetText(self._PanelObjects._LabName, name)
    if good_temp.GoodsShowType == EGoodsShowType.GoodsShowType_MonthlyCard or
            good_temp.GoodsShowType == EGoodsShowType.GoodsShowType_Fund then
        frame_remain:SetActive(false)
    else
        frame_remain:SetActive(true)
    end
    if good_temp.IsBigIcon then
        if img_speci_icon then
            if good_temp.GoodsShowType == EGoodsShowType.GoodsShowType_MonthlyCard or
                    good_temp.GoodsShowType == EGoodsShowType.GoodsShowType_Fund then
                img_speci_icon:SetActive(true)
                img_icon:SetActive(false)
                GUITools.SetIcon(img_speci_icon, good_temp.IconPath)
            else
                img_speci_icon:SetActive(false)
                img_icon:SetActive(true)
                GUITools.SetIcon(img_icon, good_temp.IconPath)
            end
        else
            img_icon:SetActive(true)
            GUITools.SetIcon(img_icon, good_temp.IconPath)
        end
        item_icon:SetActive(false)
        --GUITools.SetNativeSize(img_icon)
    else
        if good_item.GoodsType == EGoodsType.Item then
            img_icon:SetActive(false)
            if img_speci_icon then
                img_speci_icon:SetActive(false)
            end
            item_icon:SetActive(true)
            local setting = {
                [EItemIconTag.Number] = good_item.ItemCount,
            }
            IconTools.InitItemIconNew(item_icon, good_item.ItemId, setting, EItemLimitCheck.AllCheck)
        else
            warn("error!!!! 数据模板错误，是小图标但是不是物品类型")
        end
    end

    if good_item.ShowEndTime ~= nil and good_item.ShowEndTime > 0 then
        lab_remain_time:SetActive(true)
        lab_remain_time_tip:SetActive(true)
        local time_str = CMallUtility.GetRemainStringByEndTime(good_item.ShowEndTime)
        GUI.SetText(lab_remain_time, time_str)
        local callback = function()
            local time_str = CMallUtility.GetRemainStringByEndTime(good_item.ShowEndTime)
            GUI.SetText(lab_remain_time, time_str)
        end
        if self._LifeTimeTimer > 0 then
            _G.RemoveGlobalTimer(self._LifeTimeTimer)
            self._LifeTimeTimer = 0
        end
        self._LifeTimeTimer = _G.AddGlobalTimer(1, false, callback)
    else
        lab_remain_time:SetActive(false)
        lab_remain_time_tip:SetActive(false)
    end
    if good_item.LimitType == ELimitType.NoLimit then
        GUI.SetText(lab_remain_tip, StringTable.Get(31030))
        GUI.SetText(lab_remain_count, "")
    else
        GUI.SetText(lab_remain_count, tostring(math.max(0, good_item.Stock - hasBuyCount)))
		frame_cost_diamond:SetActive(true)
        GUI.SetText(lab_remain_tip, StringTable.Get(31038))
    end
    if good_item.DiscountType >= 10000 then
        img_discount:SetActive(false)
    else
        img_discount:SetActive(true)
        GUI.SetText(lab_discount, (100-good_item.DiscountType/100).."%")
    end
    if good_item.CostType == ECostType.Currency then
        if good_item.CostMoneyCount > 0 then
            img_money:SetActive(true)
            GUITools.SetTokenMoneyIcon(img_money, good_item.CostMoneyId)
            GUI.SetText(lab_cost, GUITools.FormatNumber(good_item.CostMoneyCount * self._CurCount, false))
        else
            img_money:SetActive(false)
            GUI.SetText(lab_cost, StringTable.Get(31029))
        end
    else
        img_money:SetActive(false)
        local cash_cost = CMallMan.Instance():GetGoodsDataCashCost(good_item)
        if cash_cost > 0 then
            GUI.SetText(lab_cost, string.format(StringTable.Get(31000), GUITools.FormatNumber(cash_cost * self._CurCount, false)))
        else
            GUI.SetText(lab_cost, StringTable.Get(31029))
        end
    end
end

-- 更新右侧商品里面可获得哪些东西
local UpdateRightTab = function(self)
    if self._GoodData == nil then warn("error 商品数据为空") return end
    if self._StoreID <=0 then warn("error 商店ID为0") return end
    local good_item = self._GoodData
    local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
    local uiTemplate = self._PanelObjects._Frame_Right:GetComponent(ClassType.UITemplate)
    local list_item_list = uiTemplate:GetControl(0)
    local list_reward_list = uiTemplate:GetControl(1)
    local tab_num_input = uiTemplate:GetControl(2)
    local btn_input = uiTemplate:GetControl(3)
    local btn_max = uiTemplate:GetControl(4)
    local btn_min = uiTemplate:GetControl(5)
    local lab_tip1 = uiTemplate:GetControl(6)
    local lab_tip2 = uiTemplate:GetControl(7)
    local lab_tipM = uiTemplate:GetControl(8)
    local list_item_listM = uiTemplate:GetControl(9)
    local lab_count = btn_input:FindChild("Lab_Count")
    
    lab_tip1:SetActive(#self._GainItems > 0)
    list_item_list:SetActive(#self._GainItems > 0)
    lab_tipM:SetActive(#self._GainItemsM > 0)
    list_item_listM:SetActive(#self._GainItemsM > 0)
    lab_tip2:SetActive(#self._GiftItems > 0)
    list_reward_list:SetActive(#self._GiftItems > 0)
    list_item_list:GetComponent(ClassType.GNewList):SetItemCount(#self._GainItems)
    list_reward_list:GetComponent(ClassType.GNewList):SetItemCount(#self._GiftItems)
    list_item_listM:GetComponent(ClassType.GNewList):SetItemCount(#self._GainItemsM)
    if self._GoodsInfoHandleFunc ~= nil then
        self._GoodsInfoHandleFunc(self, uiTemplate)
    end

    if good_item.CostType == ECostType.Currency then
        tab_num_input:SetActive(true)
    else
        tab_num_input:SetActive(false)
    end
    if self._MaxCount < self._MinCount or self._MaxCount < self._CurCount then
        GameUtil.SetButtonInteractable(btn_max,false)
        GameUtil.SetButtonInteractable(btn_min,false)
    else
        if self._CurCount <= self._MinCount then
            GameUtil.SetButtonInteractable(btn_min,false)
            GUITools.SetBtnGray(btn_min, true, true)
        else
            GameUtil.SetButtonInteractable(btn_min,true)
            GUITools.SetBtnGray(btn_min, false, true)
        end
        if self._CurCount >= self._MaxCount then
            GameUtil.SetButtonInteractable(btn_max,false)
            GUITools.SetBtnGray(btn_max, true, true)
        else
            GameUtil.SetButtonInteractable(btn_max,true)
            GUITools.SetBtnGray(btn_max, false, true)
        end
    end
    GUI.SetText(lab_count, self._CurCount.."")
end

-- 更新按钮UI
local UpdateBtns = function(self)
    local good_item = self._GoodData
    local good_temp = CElementData.GetTemplate("Goods", good_item.Id)
    local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._StoreID, good_item.Id)
    if good_temp.LimitType == ELimitType.NoLimit then
        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(21302)
        }
        self._Btn_OK:ResetSetting(setting)
        self._Btn_OK:SetInteractable(true)
        self._Btn_OK:MakeGray(false)
    else
        if hasBuyCount >= good_item.Stock and good_item.Stock > 0 then
            if good_item.LimitType == ELimitType.Cycle or good_temp.LimitType == ELimitType.WeekLimit or good_temp.LimitType == ELimitType.MonthLimit then
                local time_str = CMallUtility.GetRemainStringByEndTime(good_item.NextRefreshTime or 0)
                local final_str = string.format(StringTable.Get(31087), time_str)
                local setting = {
                    [EnumDef.CommonBtnParam.BtnTip] = final_str
                }
                self._Btn_OK:ResetSetting(setting)
                self._Btn_OK:SetInteractable(true)
                self._Btn_OK:MakeGray(false)
                local callback = function()
                    local now_time = GameUtil.GetServerTime()
                    if good_item.NextRefreshTime > now_time then
                        local time_str = CMallUtility.GetRemainStringByEndTime(good_item.NextRefreshTime or 0)
                        local final_str = string.format(StringTable.Get(31087), time_str)
                        local setting = {
                            [EnumDef.CommonBtnParam.BtnTip] = final_str
                        }
                        self._Btn_OK:ResetSetting(setting)
                    else
                        _G.RemoveGlobalTimer(self._RemainTimeTimer)
                        self._RemainTimeTimer = 0
                        local setting = {
                            [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(21302)
                        }
                        self._Btn_OK:ResetSetting(setting)
                    end
                end
                if self._RemainTimeTimer ~= 0 then
                    _G.RemoveGlobalTimer(self._RemainTimeTimer)
                    self._RemainTimeTimer = 0
                end
                self._RemainTimeTimer = _G.AddGlobalTimer(1, false, callback)
            else
                local setting = {
                    [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31052)
                }
                self._Btn_OK:ResetSetting(setting)
                --self._Btn_OK:SetInteractable(false)
                self._Btn_OK:MakeGray(true)
            end
        else
            local setting = {
                [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(21302)
            }
            self._Btn_OK:ResetSetting(setting)
            self._Btn_OK:SetInteractable(true)
            self._Btn_OK:MakeGray(false)
        end
    end
end

-- 更新界面
def.method().UpdatePanel = function(self)
    UpdateLeftTab(self)
    UpdateRightTab(self)
    UpdateBtns(self)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Max" then
        self._CurCount = self._MaxCount
        self:UpdatePanel()
    elseif id == "Btn_Min" then
        self._CurCount = self._MinCount
        self:UpdatePanel()
    elseif id == "Btn_Input" then
        local uiTemplate = self._PanelObjects._Frame_Right:GetComponent(ClassType.UITemplate)
        local lab_number = uiTemplate:GetControl(3):FindChild("Lab_Count")
        local function callback(count)
            if not self:IsShow() then return end
    		self._CurCount = count or 0
            if self._CurCount > self._MaxCount then self._CurCount = self._MaxCount end
            if self._CurCount < self._MinCount then self._CurCount = self._MinCount end
    		self:UpdatePanel()
    	end
    	game._GUIMan:OpenNumberKeyboard(lab_number,nil, self._MinCount, self._MaxCount, callback, callback)
    elseif id == "Btn_Cancel" or id == "Btn_Close" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_OK" then
        local good_item = self._GoodData
        local now_time = GameUtil.GetServerTime()
        local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._StoreID, good_item.Id)
        if good_item.LimitType ~= ELimitType.Cycle and good_item.LimitType ~= ELimitType.NoLimit and hasBuyCount >= good_item.Stock then
            game._GUIMan:ShowTipText(StringTable.Get(31093), false)
            return
        end
        if good_item.ShowEndTime ~= nil and good_item.ShowEndTime > 0 and good_item.ShowEndTime <= now_time then
            game._GUIMan:ShowTipText(StringTable.Get(31088), false)
            game._GUIMan:CloseByScript(self)
        elseif hasBuyCount >= good_item.Stock and good_item.Stock > 0 and good_item.LimitType == ELimitType.Cycle and now_time < good_item.NextRefreshTime then
            game._GUIMan:ShowTipText(StringTable.Get(31089), false)
        else
            if good_item.CostType == ECostType.Currency then
                local have_count = game._HostPlayer:GetMoneyCountByType(good_item.CostMoneyId)
                if have_count >= good_item.CostMoneyCount * self._CurCount then
                    CMallMan.Instance():BuyGoodsItem(self._StoreID ,good_item.Id, self._CurCount)
                else
                    local callback = function(val)
                        if val then
                            CMallMan.Instance():BuyGoodsItem(self._StoreID ,good_item.Id, self._CurCount)
                        end
                    end
                    MsgBox.ShowQuickBuyBox(good_item.CostMoneyId, good_item.CostMoneyCount * self._CurCount, callback, nil, true, good_item.Id)
                end
            else
                CMallMan.Instance():BuyItemByRMB(self._StoreID, good_item.Id, good_item.AND_ProductId, good_item.IOS_ProductId)
            end
            game._GUIMan:CloseByScript(self)
        end
    elseif id == "ItemIconNew" then
        local good_item = self._GoodData
        local uiTemplate = self._PanelObjects._Frame_Left:GetComponent(ClassType.UITemplate)
        CItemTipMan.ShowItemTips(good_item.ItemId, TipsPopFrom.OTHER_PANEL, uiTemplate:GetControl(9), TipPosition.FIX_POSITION)
    elseif id == "Lab_BuyTips" then
        CMallMan.Instance():HandleClickBuyTips()
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "List_ItemList" then
        local item_data = self._GainItems[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local lab_info = uiTemplate:GetControl(0)
        if item_data.IsTokenMoney then
            local str = string.format(StringTable.Get(31025), RichTextTools.GetMoneyNameRichText(item_data.Data.Id), GUITools.FormatNumber(tonumber(item_data.Data.Count), false))
            GUI.SetText(lab_info, str)
        else
            local str = string.format(StringTable.Get(31025), RichTextTools.GetItemNameRichText(item_data.Data.Id, 1, false), GUITools.FormatNumber(item_data.Data.Count, false))
            GUI.SetText(lab_info, str)
        end
    elseif id == "List_ItemListM" then
        local item_data = self._GainItemsM[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local lab_info = uiTemplate:GetControl(0)
        if item_data.IsTokenMoney then
            local str = string.format(StringTable.Get(31025), RichTextTools.GetMoneyNameRichText(item_data.Data.Id), GUITools.FormatNumber(tonumber(item_data.Data.Count), false))
            GUI.SetText(lab_info, str)
        else
            local str = string.format(StringTable.Get(31025), RichTextTools.GetItemNameRichText(item_data.Data.Id, 1, false), GUITools.FormatNumber(item_data.Data.Count, false))
            GUI.SetText(lab_info, str)
        end
    elseif id == "List_GiftList" then
        local item_data = self._GiftItems[index]
        local uiTemplate = item:GetComponent(ClassType.UITemplate)
        local lab_info = uiTemplate:GetControl(0)
        if item_data.IsTokenMoney then
            local str = string.format(StringTable.Get(31025), RichTextTools.GetMoneyNameRichText(item_data.Data.Id), GUITools.FormatNumber(tonumber(item_data.Data.Count), false))
            GUI.SetText(lab_info, str)
        else
            local str = string.format(StringTable.Get(31025), RichTextTools.GetItemNameRichText(item_data.Data.Id, 1, false), GUITools.FormatNumber(item_data.Data.Count, false))
            GUI.SetText(lab_info, str)
        end
    end
end

def.override().OnHide = function(self)
    if self._RemainTimeTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RemainTimeTimer)
        self._RemainTimeTimer = 0
    end
    if self._LifeTimeTimer ~= 0 then
        _G.RemoveGlobalTimer(self._LifeTimeTimer)
        self._RemainTimeTimer = 0
    end
end

def.override().OnDestroy = function(self)
    if self._Btn_OK ~= nil then
        self._Btn_OK:Destroy()
        self._Btn_OK = nil
    end
    self._GoodsInfoHandleFunc = nil
end
CPanelMallCommonBuy.Commit()
return CPanelMallCommonBuy