local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CGame = Lplus.ForwardDeclare("CGame")
--local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local CMallUtility = require "Mall.CMallUtility"
local CCommonBtn = require "GUI.CCommonBtn"
local CElementData = require "Data.CElementData"
local ECostType = require "PB.Template".Goods.ECostType
local ELimitType = require "PB.Template".Goods.ELimitType

local CPanelActivityMall = Lplus.Extend(CPanelBase, 'CPanelActivityMall')
local def = CPanelActivityMall.define


local instance = nil

def.field("table")._PanelObjects = BlankTable
def.field("number")._CachePageID = 0
def.field("number")._CurIndex = 0
def.field("number")._TimeRemainTimer = 0
def.field("table")._OpenPagesData = BlankTable
def.field(CCommonBtn)._BuyBtnByMoney = nil
def.field(CCommonBtn)._BuyBtnByCash = nil

local function OnActivityMallDataChange(sender, event)
    if instance ~= nil and instance:IsShow() then
        instance:HandleActivityMallDataChange()
    end
end


def.static('=>', CPanelActivityMall).Instance = function ()
	if not instance then
        instance = CPanelActivityMall()
        instance._PrefabPath = PATH.UI_ActivityMall
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end
 
def.override().OnCreate = function(self)
    self._PanelObjects = {}
    self._PanelObjects.DragblePanel = self:GetUIObject("DragblePanel")
    self._PanelObjects.ListToggleGroup = self:GetUIObject("List_PageToggles")
    self._PanelObjects.Lab_LevelLimit = self:GetUIObject("Lab_LevelLimit")
    self._PanelObjects.Lab_LevelValue = self:GetUIObject("Lab_LevelValue")
    self._PanelObjects.Lab_TimeLimit = self:GetUIObject("Lab_TimeLimit")
    self._PanelObjects.Lab_TimeValue = self:GetUIObject("Lab_TimeValue")
    self._PanelObjects.Lab_CountLimit = self:GetUIObject("Lab_CountLimit")
    self._PanelObjects.Lab_CountValue = self:GetUIObject("Lab_CountValue")
    self._PanelObjects.Btn_BuyMoney = self:GetUIObject("Btn_BuyMoney")
    self._PanelObjects.Btn_BuyCash = self:GetUIObject("Btn_BuyCash")
    self._PanelObjects.Btn_Right = self:GetUIObject("Btn_Right")
    self._PanelObjects.Btn_Left = self:GetUIObject("Btn_Left")
    local setting = {
        [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(11115),
    }
    self._BuyBtnByMoney = CCommonBtn.new(self._PanelObjects.Btn_BuyMoney, setting)
    self._BuyBtnByCash = CCommonBtn.new(self._PanelObjects.Btn_BuyCash, nil)
end

def.override("dynamic").OnData = function(self, data)
    if data ~= nil then
        self._CachePageID = tonumber(data) or -1
    end
    self._OpenPagesData = CMallMan.Instance():GetOpenActivityData()
    self._PanelObjects.ListToggleGroup:GetComponent(ClassType.GNewList):SetItemCount(#self._OpenPagesData)
    self._PanelObjects.DragblePanel:GetComponent(ClassType.GDragablePageView):SetPageItemCount(#self._OpenPagesData)
    if self._CachePageID > 0 then
        self:SwitchToPageShop(self._CachePageID)
    else
        self._CurIndex = #self._OpenPagesData > 0 and 1 or 0
        self:UpdatePanel()
    end
    CMallMan.Instance():RequestActivitySynData()
    CGame.EventManager:addHandler("ActivityMallDataChangeEvent", OnActivityMallDataChange)
end

local IsLeftRedPointShow = function(self)
    for i = 1, self._CurIndex do
        if CMallMan.Instance():GetActivityMallPageRedPointState(self._OpenPagesData[i].Id) then
            return true
        end
    end
    return false
end

local IsRightRedPointShow = function(self)
    for i = self._CurIndex, #self._OpenPagesData do
        if CMallMan.Instance():GetActivityMallPageRedPointState(self._OpenPagesData[i].Id) then
            return true
        end
    end
    return false
end

def.method().AddTimeRemainTimer = function(self)
    if self._TimeRemainTimer > 0 then
        self:RemoveRemainTimer()
    end
    local cur_data = self._OpenPagesData[self._CurIndex]
    local callback = function()
        local now_time = GameUtil.GetServerTime()
        if now_time >= cur_data.EndTime then
            local pre_page_id = cur_data.Id
            self._OpenPagesData = CMallMan.Instance():GetOpenActivityData()
            if #self._OpenPagesData <= 0 then
                game._GUIMan:ShowTipText(StringTable.Get(31079), false)
                game._GUIMan:CloseByScript(self)
                return
            end
            self._PanelObjects.ListToggleGroup:GetComponent(ClassType.GNewList):SetItemCount(#self._OpenPagesData)
            self._PanelObjects.DragblePanel:GetComponent(ClassType.GDragablePageView):SetPageItemCount(#self._OpenPagesData)

            local finded = false
            for i,v in ipairs(self._OpenPagesData) do
                if v.Id == pre_page_id then
                    finded = true
                end
            end

            if finded then
                self:SwitchToPageShop(pre_page_id)
            else
                self:SwitchToPageShop(self._OpenPagesData[1].Id)
            end
        else
            local str_time = CMallUtility.GetActivityGoodsEndTime(cur_data.EndTime)
            local remain_sec = math.max((cur_data.EndTime - GameUtil.GetServerTime())/1000, 0 )
            if remain_sec > 86400 * 31 then
                GUI.SetText(self._PanelObjects.Lab_TimeLimit, "")
            else
                GUI.SetText(self._PanelObjects.Lab_TimeLimit, StringTable.Get(31092))
            end
            GUI.SetText(self._PanelObjects.Lab_TimeValue, str_time)
        end
    end
    self._TimeRemainTimer = _G.AddGlobalTimer(1, false, callback)
end

def.method().RemoveRemainTimer = function(self)
    if self._TimeRemainTimer > 0 then
        _G.RemoveGlobalTimer(self._TimeRemainTimer)
        self._TimeRemainTimer = 0
    end
end

def.method().UpdatePanel = function(self)
    if self._OpenPagesData == nil or #self._OpenPagesData <= 0 then
        warn("error !! 没有活动商品数据")
        return
    end
    GUI.SetGroupToggleOn(self._PanelObjects.ListToggleGroup, self._CurIndex + 1)
    local cur_data = self._OpenPagesData[self._CurIndex]
    if cur_data == nil then
        warn("error !! 当前index没有数据，index : ", self._CurIndex)
        return
    end
    local str_level = cur_data.MaxLevel < 1000 and string.format(StringTable.Get(22054), cur_data.MinLevel, cur_data.MaxLevel) or StringTable.Get(31082)
    local str_time = CMallUtility.GetActivityGoodsEndTime(cur_data.EndTime)
    local buy_count = CMallMan.Instance():GetActivityMallGoodsBuyCount(cur_data.Id, cur_data.CurGoodsId)
    local buy_count_tip = StringTable.Get(31085)
    local str_count = ""
    local goods_temp = CElementData.GetTemplate("Goods", cur_data.CurGoodsId)
    if goods_temp ~= nil then
        if goods_temp.Stock > 0 then
            str_count = GUITools.FormatNumber(goods_temp.Stock - buy_count)
        else
            str_count = StringTable.Get(31081)
        end
        if goods_temp.LimitType == ELimitType.Forever then
            buy_count_tip = StringTable.Get(31083)
        elseif goods_temp.LimitType == ELimitType.ForeverAccount then
            buy_count_tip = StringTable.Get(31084)
        end
    else
        warn("error !!! 商品模板数据错误，ID： ", cur_data.CurGoodsId)
        return
    end
    local remain_sec = math.max((cur_data.EndTime - GameUtil.GetServerTime())/1000, 0 )
    if remain_sec > 86400 * 31 then
        GUI.SetText(self._PanelObjects.Lab_TimeLimit, "")
    else
        GUI.SetText(self._PanelObjects.Lab_TimeLimit, StringTable.Get(31092))
    end
    GUI.SetText(self._PanelObjects.Lab_LevelValue, str_level)
    GUI.SetText(self._PanelObjects.Lab_TimeValue, str_time)
    GUI.SetText(self._PanelObjects.Lab_CountValue, str_count)
    GUI.SetText(self._PanelObjects.Lab_CountLimit, buy_count_tip)

    if self._CurIndex <= 1 then
        self._PanelObjects.Btn_Left:SetActive(false)
    else
        self._PanelObjects.Btn_Left:SetActive(true)
    end
    if self._CurIndex >= #self._OpenPagesData then
        self._PanelObjects.Btn_Right:SetActive(false)
    else
        self._PanelObjects.Btn_Right:SetActive(true)
    end
    -- 更新按钮的状态
    if goods_temp ~= nil then
        if goods_temp.CostType == ECostType.Currency then
            self._PanelObjects.Btn_BuyMoney:SetActive(true)
            self._PanelObjects.Btn_BuyCash:SetActive(false)
            local setting = {
                [EnumDef.CommonBtnParam.MoneyID] = goods_temp.CostMoneyId,
                [EnumDef.CommonBtnParam.MoneyCost] = goods_temp.CostMoneyCount,
            }
            self._BuyBtnByMoney:ResetSetting(setting)
        else
            self._PanelObjects.Btn_BuyMoney:SetActive(false)
            self._PanelObjects.Btn_BuyCash:SetActive(true)
            local str = ""
            local language_code = _G.UserLanguageCode
            local cash_cost = CMallMan.Instance():GetGoodsTempCashCost(cur_data.CurGoodsId)
            if language_code == "KR" then
                str = string.format(StringTable.Get(31000), GUITools.FormatNumber(cash_cost, false))
            else
                --str = string.format(StringTable.Get(31001), GUITools.FormatNumber(cash_cost, false))
                str = string.format(StringTable.Get(31000), GUITools.FormatNumber(cash_cost, false))
            end
            local setting = {
                [EnumDef.CommonBtnParam.BtnTip] = str,
            }
            self._BuyBtnByCash:ResetSetting(setting)
        end
    else
        warn("error !!! 商品模板数据错误，ID： ", cur_data.CurGoodsId)
        return
    end

    -- 更新红点状态
    GUITools.GetChild(self._PanelObjects.Btn_Left, 0):SetActive(IsLeftRedPointShow(self))
    GUITools.GetChild(self._PanelObjects.Btn_Right, 0):SetActive(IsRightRedPointShow(self))
end

def.method().BuyCurGoods = function(self)
    local cur_data = self._OpenPagesData[self._CurIndex]
    CMallMan.Instance():BuyActivityGoods(cur_data.Id, cur_data.CurGoodsId)
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_Close" then
        game._GUIMan:CloseByScript(self)
    elseif id == "Btn_Right" then
        self._CurIndex = self._CurIndex + 1
        self._PanelObjects.DragblePanel:GetComponent(ClassType.GDragablePageView):ChangePageIndex(self._CurIndex - 1)
        self:UpdatePanel()
    elseif id == "Btn_Left" then
        self._CurIndex = self._CurIndex - 1
        self._PanelObjects.DragblePanel:GetComponent(ClassType.GDragablePageView):ChangePageIndex(self._CurIndex - 1)
        self:UpdatePanel()
    elseif id == "Btn_BuyMoney" or id == "Btn_BuyCash" then
        local callback = function(val)
            if val then
                self:BuyCurGoods()    
            end
        end

        local cur_data = self._OpenPagesData[self._CurIndex]
        if cur_data == nil then
            warn("error !! 当前index没有数据，index : 11 ", self._CurIndex)
            return
        end
        local goods_temp = CElementData.GetTemplate("Goods", cur_data.CurGoodsId)
        if goods_temp ~= nil then
            MsgBox.ShowQuickBuyBox(goods_temp.CostMoneyId, goods_temp.CostMoneyCount, callback, nil, true, cur_data.CurGoodsId)
        else
            warn("error !!! 数据配置错误，要购买的商品模板数据为空： ID：", cur_data.CurGoodsId)
        end
    elseif id == "Btn_BuyCash" then
        self:BuyCurGoods()
    elseif id == "Lab_BuyTip" then
        CMallMan.Instance():HandleClickBuyTips()
    end
end

-- Banner手动滑或者自动滑的时候，index变化会回调这个方法
def.override("userdata", "string", "number").OnDragablePageIndexChange = function(self, item_go, pageViewName, index)
    local index = index + 1
    if pageViewName == "DragblePanel" then
        self._CurIndex = index
        CMallMan.Instance():UpdateActivityMallPageRedPointState(self._OpenPagesData[self._CurIndex].Id, false)
        self:UpdatePanel()
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    if id == "DragblePanel" then
        local page_data = self._OpenPagesData[index]
        local goods_temp = CElementData.GetTemplate("Goods", page_data.CurGoodsId)
        if page_data ~= nil and goods_temp ~= nil then
            local img_item = GUITools.GetChild(item, 0)
            GUITools.SetItemIcon(img_item, goods_temp.IconPath)
        else
            warn("error !!! 模板数据错误，商品数据或者活动页签数据错误 ，", page_data.CurGoodsId)
        end
    end
end

--------------------------------------------------------------
--跳转到对应的页签下面(mallID是商城ID)
--------------------------------------------------------------
def.method("number").SwitchToPageShop = function(self, pageID)
    if self._OpenPagesData == nil or #self._OpenPagesData <= 0 then
        self._CurIndex = 0
    else
        for i,v in ipairs(self._OpenPagesData) do
            if v.Id == pageID then
                self._CurIndex = i
            end
        end
    end
    self:UpdatePanel()
end

--------------------------------------------------------------
--处理购买成功
--------------------------------------------------------------
def.method().HandleActivityMallDataChange = function(self)
    local pre_page_id = self._OpenPagesData[self._CurIndex].Id
    self._OpenPagesData = CMallMan.Instance():GetOpenActivityData()
    if #self._OpenPagesData <= 0 then
        game._GUIMan:ShowTipText(StringTable.Get(31079), false)
        game._GUIMan:CloseByScript(self)
        return
    end
    self._PanelObjects.ListToggleGroup:GetComponent(ClassType.GNewList):SetItemCount(#self._OpenPagesData)
    self._PanelObjects.DragblePanel:GetComponent(ClassType.GDragablePageView):SetPageItemCount(#self._OpenPagesData)

    local finded = false
    for i,v in ipairs(self._OpenPagesData) do
        if v.Id == pre_page_id then
            finded = true
        end
    end

    if finded then
        self:SwitchToPageShop(pre_page_id)
    else
        self:SwitchToPageShop(self._OpenPagesData[1].Id)
    end
    self._PanelObjects.DragblePanel:GetComponent(ClassType.GDragablePageView):ChangePageIndexRightNow(self._CurIndex > 0 and (self._CurIndex -1) or 0)
end

def.override().OnHide = function(self)
    self._CachePageID = 0
    self._CurIndex = 0
end

def.override().OnDestroy = function(self)
    self:RemoveRemainTimer()
    CGame.EventManager:removeHandler("ActivityMallDataChangeEvent", OnActivityMallDataChange)
    if self._BuyBtnByMoney ~= nil then
        self._BuyBtnByMoney:Destroy()
        self._BuyBtnByMoney = nil
    end
    if self._BuyBtnByCash ~= nil then
        self._BuyBtnByCash:Destroy()
        self._BuyBtnByCash = nil
    end
    self._OpenPagesData = nil
    self._PanelObjects = nil
end
CPanelActivityMall.Commit()
return CPanelActivityMall