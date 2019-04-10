local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local EGoodsType = require "PB.Template".Goods.EGoodsType
local ECostType = require "PB.Template".Goods.ECostType
local CMallUtility = require "Mall.CMallUtility"
local CCommonBtn = require "GUI.CCommonBtn"
local CMallPageMontylyCard = Lplus.Extend(CMallPageBase, "CMallPageMontylyCard")
local def = CMallPageMontylyCard.define

def.field("table")._MonthlyCardData = BlankTable
def.field("table")._MonthlyCardTemp = BlankTable
def.field("number")._RemainTimeTimer = 0
def.field("boolean")._CanGetReward = false
def.field("number")._MonthlyCardTid = 0
def.field(CCommonBtn)._BuyBtn = nil
def.field(CCommonBtn)._GetRewardBtn = nil

def.static("=>", CMallPageMontylyCard).new = function()
	local pageNew = CMallPageMontylyCard()
	return pageNew
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    local btn_buy = uiTemplate:GetControl(3)
    local btn_get_reward = uiTemplate:GetControl(8)
    self._BuyBtn = CCommonBtn.new(btn_buy, nil)
    self._GetRewardBtn = CCommonBtn.new(btn_get_reward, nil)
end

def.override("dynamic").OnData = function(self, data)
    if self._RemainTimeTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RemainTimeTimer)
        self._RemainTimeTimer = 0
    end
    if self._PageData ~= nil and self._PageData.Goods ~= nil then
        local goods_item = self._PageData.Goods[1]
        self._MonthlyCardData = goods_item
        if goods_item.GoodsType == EGoodsType.MonthlyCard then
            local good_temp = CElementData.GetTemplate("Goods", goods_item.Id)
            if good_temp == nil then
                warn("error !!! 月卡的商品数据为空")
                return
            end
            self._MonthlyCardTid = good_temp.MonthlyCardId or 1
            local monthlyTemp = CElementData.GetTemplate("MonthlyCard", self._MonthlyCardTid)
            self._MonthlyCardTemp = monthlyTemp
            if monthlyTemp ~= nil then
                self:UpdatePanelByTemp(monthlyTemp)
            end
        end
    end
end

def.override().RefreshPage = function(self)
    if self._PageData == nil then
        warn(string.format("MallPanel.RefreshPage error, _PageData is nil"))
        return
    end
    self:OnData(self._PageData)
end

def.override("table").OnBuySuccess = function(self, data)
    print("data.MonthlyExpired", data.Monthly.ExpiredTime)
    --CMallMan.Instance()._MallRoleInfo.RoleStoreData.MonthlyCardData.ExpiredTime = data.Monthly.ExpiredTime
    self:OnData(self._PageData)
end

def.override().OnRegistUIEvent = function(self)
    GUITools.RegisterButtonEventHandler(self._Panel, self._GameObject,true)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallMonthlyShop"
end

-- 更新面板
def.method("table").UpdatePanelByTemp = function(self, temp)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    local img_BG = uiTemplate:GetControl(7)
    local img_icon = uiTemplate:GetControl(0)
    --local img_icon = uiTemplate:GetControl(1)   -- 预设暂时不对 1 还没对应上label
    local lab_end_time = uiTemplate:GetControl(2)
    local btn_buy = uiTemplate:GetControl(3)
    local btn_get_reward = uiTemplate:GetControl(8)
    local item1 = uiTemplate:GetControl(4)
    local item2 = uiTemplate:GetControl(5)
    local item3 = uiTemplate:GetControl(6)
    GUITools.SetIcon(img_BG, self._MonthlyCardTemp.IconPath)
    GameUtil.PlayUISfx(PATH.UIFX_Mall_MonthlyBG, img_icon, img_icon, -1)
--    local expiredTime = CMallMan.Instance()._MallRoleInfo.RoleStoreData.MonthlyCardData.ExpiredTime or 0
    print("self._MonthlyCardTid ", self._MonthlyCardTid)
    local monthly_data = CMallMan.Instance():GetMonthCardRoleData(self._MonthlyCardTid)
    if monthly_data ~= nil and monthly_data.ExpiredTime > GameUtil.GetServerTime() then
        local expiredTime = monthly_data.ExpiredTime or 0
        if self._RemainTimeTimer ~= 0 then
            _G.RemoveGlobalTimer(self._RemainTimeTimer)
            self._RemainTimeTimer = 0
        end
        local time_str = CMallUtility.GetRemainStringForMonthlyCard(expiredTime)
        GUI.SetText(lab_end_time, time_str)
        local callback = function()
            local time_str = CMallUtility.GetRemainStringForMonthlyCard(expiredTime)
            GUI.SetText(lab_end_time, time_str)
            if expiredTime <=  GameUtil.GetServerTime() then
                if self._RemainTimeTimer ~= 0 then
                    _G.RemoveGlobalTimer(self._RemainTimeTimer)
                    self._RemainTimeTimer = 0
                end
                GUI.SetText(lab_end_time, StringTable.Get(31054))
            end
        end
        self._RemainTimeTimer = _G.AddGlobalTimer(1, false, callback)
        btn_buy:SetActive(false)
        btn_get_reward:SetActive(true)
        self._CanGetReward = CMallMan.Instance():CanGetMonthlyCardReward(self._MonthlyCardTemp.Id)
        if self._CanGetReward then
            self._GetRewardBtn:MakeGray(false)
            local setting = {
                [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31201),
            }
            self._GetRewardBtn:ResetSetting(setting)
        else
            self._GetRewardBtn:MakeGray(true)
            local setting = {
                [EnumDef.CommonBtnParam.BtnTip] = StringTable.Get(31055),
            }
            self._GetRewardBtn:ResetSetting(setting)
        end
    else
        btn_buy:SetActive(true)
        btn_get_reward:SetActive(false)
        GUI.SetText(lab_end_time, StringTable.Get(31054))
        local setting = {
            [EnumDef.CommonBtnParam.BtnTip] = string.format(StringTable.Get(31000), self._MonthlyCardData.CashCount),
        }
        self._BuyBtn:ResetSetting(setting)
    end
    do  -- 设置三个奖励图标
        item1:SetActive(false)
        item2:SetActive(false)
        item3:SetActive(false)
        if temp.MoneyId1 > 0 then
            item1:SetActive(true)
            IconTools.InitTokenMoneyIcon(item1:FindChild("ItemIconNew"), temp.MoneyId1, temp.MoneyCount1)
        else
            item1:SetActive(false)
        end
        if temp.MoneyId2 > 0 then
            item2:SetActive(true)
            IconTools.InitTokenMoneyIcon(item2:FindChild("ItemIconNew"), temp.MoneyId2, temp.MoneyCount2)
        else
            item2:SetActive(false)
        end
        if temp.ItemId > 0 then
            item3:SetActive(true)
            local setting = {
                [EItemIconTag.Number] = temp.ItemCount,
            }
            IconTools.InitItemIconNew(item3:FindChild("ItemIconNew"), temp.ItemId, setting, EItemLimitCheck.AllCheck)
        else
            item3:SetActive(false)
        end
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_BuyMonthlyCard" then
        if self._MonthlyCardData == nil then 
            warn("（OnClick）月卡数据为空~") 
            return
        end
        local data = {storeID = self._PageData.StoreId, goodData = self._MonthlyCardData}
        game._GUIMan:Open("CPanelMallCommonBuy", data)
    elseif id == "Btn_GetReward" then
        if self._CanGetReward then
            CMallMan.Instance():MonthlyCardGetReward(self._MonthlyCardTid, self._PageData.StoreId)
        else
            game._GUIMan:ShowTipText(StringTable.Get(31056), false)
        end
    elseif id == "Lab_BuyTip" then
        -- TODO 跳转到连接
        CMallMan.Instance():HandleClickBuyTips()
    elseif string.find(id, "Item") then
        local index = tonumber(string.sub(id, -1))
        if index then
            if index <= 1 then
                local panelData = 
				{
					_MoneyID = self._MonthlyCardTemp.MoneyId1,
					_TipPos = TipPosition.FIX_POSITION,
					_TargetObj = nil, 
				} 
			    CItemTipMan.ShowMoneyTips(panelData)
            elseif index == 2 then
                local panelData = 
				{
					_MoneyID = self._MonthlyCardTemp.MoneyId2,
					_TipPos = TipPosition.FIX_POSITION,
					_TargetObj = nil, 
				} 
			    CItemTipMan.ShowMoneyTips(panelData)
            elseif index == 3 then
                CItemTipMan.ShowItemTips(self._MonthlyCardTemp.ItemId, TipsPopFrom.OTHER_PANEL, nil, TipPosition.FIX_POSITION)
            end
        end
    end
end

def.override().OnHide = function(self)
    if self._RemainTimeTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RemainTimeTimer)
        self._RemainTimeTimer = 0
    end
end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)
    if self._BuyBtn ~= nil then
        self._BuyBtn:Destroy()
        self._BuyBtn = nil
    end
    if self._GetRewardBtn ~= nil then
        self._GetRewardBtn:Destroy()
        self._GetRewardBtn = nil
    end
    self._MonthlyCardData = nil
    self._MonthlyCardTemp = nil
    if self._RemainTimeTimer ~= 0 then
        _G.RemoveGlobalTimer(self._RemainTimeTimer)
        self._RemainTimeTimer = 0
    end
end

CMallPageMontylyCard.Commit()
return CMallPageMontylyCard
