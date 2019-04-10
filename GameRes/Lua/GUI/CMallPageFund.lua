local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local CCommonBtn = require "GUI.CCommonBtn"
local EGoodsType = require "PB.Template".Goods.EGoodsType
local EEventType = require "PB.Template".Fund.EEventType
local ECostType = require "PB.Template".Goods.ECostType
local ERewardType = require "PB.Template".Fund.ERewardType
local CMallPageFund = Lplus.Extend(CMallPageBase, "CMallPageFund")
local def = CMallPageFund.define

local FundState = {
    GotIt = 0,
    NotReach = 1,
    CanReward = 2,
}

def.field("userdata")._List_ItemsList = nil
def.field("table")._FundData = BlankTable
def.field("table")._FundTemp = BlankTable
def.field("table")._PanelObject = nil
def.field(CCommonBtn)._BuyBtn = nil

def.static("=>", CMallPageFund).new = function()
	local pageNew = CMallPageFund()
	return pageNew
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    self._PanelObject = {}
    self._List_ItemsList = uiTemplate:GetControl(0):GetComponent(ClassType.GNewListLoop)
    self._BuyBtn = CCommonBtn.new(uiTemplate:GetControl(1), nil)
    self._PanelObject._Img_Frame_BG = uiTemplate:GetControl(2)
    self._PanelObject._Lab_PriceNum = uiTemplate:GetControl(3)
    self._PanelObject._Lab_Dianum1 = uiTemplate:GetControl(4)
    self._PanelObject._Lab_Dianum2 = uiTemplate:GetControl(5)
end

def.override("dynamic").OnData = function(self, data)
    if self._PageData ~= nil and self._PageData.Goods ~= nil then
        local goods_data = self._PageData.Goods[1]
        self._FundData = goods_data
        if goods_data.GoodsType == EGoodsType.Fund then
            local good_temp = CElementData.GetTemplate("Goods", goods_data.Id)
            local fund_temp = CElementData.GetTemplate("Fund", good_temp.FundId or 1)
            if fund_temp == nil then
                warn("error !!! 基金数据不存在，ID： ", good_temp.FundId)
                return
            end
            self:ParseFundTemp(fund_temp)
            self:SortFundItems(self._FundTemp)
            self:UpdateTopUI()
            if fund_temp ~= nil and fund_temp.FundRewardDetails ~= nil then
                self._List_ItemsList:SetItemCount(#fund_temp.FundRewardDetails + 1)
            end
        end
    end
end

def.method().UpdateTopUI = function(self)
    local go_btn = self._BuyBtn._Btn
    local uiTemplate = go_btn:GetComponent(ClassType.UITemplate)
    local lab_count = uiTemplate:GetControl(1)
    local good_temp = CElementData.GetTemplate("Goods", self._FundData.Id)
    local fundStruct = CMallMan.Instance():GetFundRoleData(good_temp.FundId)
    local ui_fx = self._PanelObject._Img_Frame_BG:FindChild("Frame_FundTop/Img_FundBG")
    local is_buy = fundStruct ~= nil and fundStruct.IsBuy
    GameUtil.PlayUISfx(PATH.UIFX_Mall_FundTop, ui_fx, ui_fx, -1)
    if self._FundData.CostType == ECostType.Cash then
        GUI.SetText(lab_count, string.format(StringTable.Get(31000), self._FundData.CashCount))
        self._BuyBtn:SetInteractable(not is_buy)
        self._BuyBtn:MakeGray(is_buy)
        GUI.SetText(self._PanelObject._Lab_PriceNum, string.format(StringTable.Get(31053), GUITools.FormatNumber(self._FundData.CashCount, true)))
        GUI.SetText(self._PanelObject._Lab_Dianum1, string.format(StringTable.Get(31053), GUITools.FormatNumber(self._FundTemp.RewardMoneyCount, true)))
        GUI.SetText(self._PanelObject._Lab_Dianum2, string.format(StringTable.Get(31053), GUITools.FormatNumber(self:CalGiftAllCount(), true)))
    else
        --warn("error ！！！ 模板错误，基金必须配成现金购买")
        
        GUI.SetText(lab_count, tostring(self._FundData.CostMoneyCount))
        self._BuyBtn:SetInteractable(not is_buy)
        self._BuyBtn:MakeGray(is_buy)
        GUI.SetText(self._PanelObject._Lab_PriceNum, string.format(StringTable.Get(31053), GUITools.FormatNumber(self._FundData.CostMoneyCount, true)))
        GUI.SetText(self._PanelObject._Lab_Dianum1, string.format(StringTable.Get(31053), GUITools.FormatNumber(self._FundTemp.RewardMoneyCount, true)))
        GUI.SetText(self._PanelObject._Lab_Dianum2, string.format(StringTable.Get(31053), GUITools.FormatNumber(self:CalGiftAllCount(), true)))
    end
end

----------------------------------------------
--更新上方UI显示
----------------------------------------------
def.override().RefreshPage = function(self)
    if self._PageData == nil then
        warn(string.format("MallPanel.RefreshPage error, _PageData is nil"))
        return
    end
    self:OnData(self._PageData)
end

def.override("table").OnBuySuccess = function(self, table)
    self:OnData(self._PageData)
end

def.override().OnRegistUIEvent = function(self)
    GUITools.RegisterButtonEventHandler(self._Panel, self._GameObject,true)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallFundShop"
end

----------------------------------------------
--计算所有基金赠送的货币数量
----------------------------------------------
def.method("=>", "number").CalGiftAllCount = function(self)
    local all_count = 0
    for i,v in ipairs(self._FundTemp.FundRewardDetails) do
        if i ~= 1 then
            if v.RewardType1 == ERewardType.Money then
                all_count = all_count + v.FundRewardCount1
            end
            if v.RewardType2 == ERewardType.Money then
                all_count = all_count + v.FundRewardCount2
            end
            if v.RewardType3 == ERewardType.Money then
                all_count = all_count + v.FundRewardCount3
            end
        end
    end
    return all_count
end

----------------------------------------------
--对缓存的基金数据进行排序
----------------------------------------------
def.method("table").SortFundItems = function(self, fundTemp)
    local func = function(value1, value2)
        if value1.State ~= value2.State then
            return value1.State > value2.State
        else
            return value1.Param < value2.Param
        end
    end
    table.sort(fundTemp.FundRewardDetails, func)
end

----------------------------------------------
--解析基金模板数据，缓存起来
----------------------------------------------
def.method("table").ParseFundTemp = function(self, temp)
    local fundStruct = CMallMan.Instance():GetFundRoleData(temp.Id)
    local is_buy = fundStruct ~= nil and fundStruct.IsBuy
    self._FundTemp = {}
    self._FundTemp.Id = temp.Id
    self._FundTemp.Name = temp.Name
    self._FundTemp.DisplayName = temp.DisplayName
    self._FundTemp.IconPath = temp.IconPath
    self._FundTemp.RewardMoneyId = temp.RewardMoneyId
    self._FundTemp.RewardMoneyCount = temp.RewardMoneyCount
    self._FundTemp.FundRewardDetails = {}
    self._FundTemp.FundRewardDetails[1] = {}
    self._FundTemp.FundRewardDetails[1].Id = 0
    self._FundTemp.FundRewardDetails[1].EventType = 0
    self._FundTemp.FundRewardDetails[1].Param = 0
    self._FundTemp.FundRewardDetails[1].RewardType1 = 1
    self._FundTemp.FundRewardDetails[1].FundRewardId1 = temp.RewardMoneyId
    self._FundTemp.FundRewardDetails[1].FundRewardCount1 = temp.RewardMoneyCount
    self._FundTemp.FundRewardDetails[1].State = is_buy and FundState.GotIt or FundState.NotReach
    for i,v in ipairs(temp.FundRewardDetails) do
        self._FundTemp.FundRewardDetails[i+1] = {}
        self._FundTemp.FundRewardDetails[i+1].Id = v.Id
        self._FundTemp.FundRewardDetails[i+1].EventType = v.EventType
        self._FundTemp.FundRewardDetails[i+1].Param = v.Param
        self._FundTemp.FundRewardDetails[i+1].RewardType1 = v.RewardType1
        self._FundTemp.FundRewardDetails[i+1].FundRewardId1 = v.FundRewardId1
        self._FundTemp.FundRewardDetails[i+1].FundRewardCount1 = v.FundRewardCount1
        self._FundTemp.FundRewardDetails[i+1].RewardType2 = v.RewardType2
        self._FundTemp.FundRewardDetails[i+1].FundRewardId2 = v.FundRewardId2
        self._FundTemp.FundRewardDetails[i+1].FundRewardCount2 = v.FundRewardCount2
        self._FundTemp.FundRewardDetails[i+1].RewardType3 = v.RewardType3
        self._FundTemp.FundRewardDetails[i+1].FundRewardId3 = v.FundRewardId3
        self._FundTemp.FundRewardDetails[i+1].FundRewardCount3 = v.FundRewardCount3
        self._FundTemp.FundRewardDetails[i+1].DisplayText = v.DisplayText
        if fundStruct ~= nil and fundStruct.IsBuy then
            local state = FundState.NotReach
            for i1,v1 in ipairs(fundStruct.CanRewardIds) do
                if v1 == v.Id then
                    state = FundState.CanReward
                end
            end
            for i1,v1 in ipairs(fundStruct.FinishIds) do
                if v1 == v.Id then
                    state = FundState.GotIt
                end
            end
            self._FundTemp.FundRewardDetails[i+1].State = state
        else
            self._FundTemp.FundRewardDetails[i+1].State = FundState.NotReach
        end
    end
end

def.override('string').OnClick = function(self, id)
    if id == "Btn_BuyFund" then
        if self._FundData == nil then 
            warn("（OnClick）基金网络数据为空~") 
            return
        end
        local data = {storeID = self._PageData.StoreId, goodData = self._FundData}
        game._GUIMan:Open("CPanelMallCommonBuy", data)
    elseif id == "Lab_BuyTips" then
        CMallMan.Instance():HandleClickBuyTips()
    end
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    local index = index + 1
    local uiTemplate = item:GetComponent(ClassType.UITemplate)
    local frame_Level = uiTemplate:GetControl(0)
    local frame_Battle = uiTemplate:GetControl(1)
    local frame_quest = uiTemplate:GetControl(11)
    local lab_right_now = uiTemplate:GetControl(10)

    local frame_head_level = uiTemplate:GetControl(13)
    local frame_head_battle = uiTemplate:GetControl(14)
    local frame_head_quest = uiTemplate:GetControl(15)
    local lab_head_right_now = uiTemplate:GetControl(16)

    local labNeedLevel = uiTemplate:GetControl(2)
    local labNeedBattle = uiTemplate:GetControl(3)
    local labNeedQuest = uiTemplate:GetControl(12)
    local lab_head_need_level = uiTemplate:GetControl(17)
    local lab_head_need_battle = uiTemplate:GetControl(18)
    local lab_head_need_quest = uiTemplate:GetControl(19)

    local btnGet = uiTemplate:GetControl(5)
    local lab_btn_get = btnGet:FindChild("Img_Bg/Lab_Engrave")
    local img_btn_fx = btnGet:FindChild("Img_Bg/Img_BtnFloatFx")
    local img_uifx_bg = item:FindChild("Frame_Target/Img_Bg")
    local img_compeleted = uiTemplate:GetControl(6)
    local item_icon1 = uiTemplate:GetControl(7)
    local item_icon2 = uiTemplate:GetControl(8)
    local item_icon3 = uiTemplate:GetControl(9)

    frame_Level:SetActive(false)
    frame_Battle:SetActive(false)
    frame_quest:SetActive(false)
    lab_right_now:SetActive(false)
    frame_head_level:SetActive(false)
    frame_head_battle:SetActive(false)
    frame_head_quest:SetActive(false)
    lab_head_right_now:SetActive(false)
    btnGet:SetActive(false)
    img_compeleted:SetActive(false)
    item_icon1:SetActive(false)
    item_icon2:SetActive(false)
    item_icon3:SetActive(false)
    img_btn_fx:SetActive(false)
    if self._FundTemp ~= nil and self._FundTemp.FundRewardDetails ~= nil then
        local detailItem = self._FundTemp.FundRewardDetails[index]
        if detailItem ~= nil then
            
            local fundStruct = CMallMan.Instance():GetFundRoleData(self._FundTemp.Id)
            local is_buy = (fundStruct ~= nil and fundStruct.IsBuy)
            GUITools.SetBtnExpressGray(item, true)
            if detailItem.Id == 0 then
                lab_head_right_now:SetActive(true)
                lab_right_now:SetActive(true)
                item_icon1:SetActive(true)
                if detailItem.State == FundState.NotReach then
                    GUITools.SetBtnExpressGray(item, false)
                    btnGet:SetActive(true)
                    GUITools.SetBtnGray(btnGet, true)
                    GUI.SetText(lab_btn_get, StringTable.Get(31200))
                else
                    img_compeleted:SetActive(true)
                    GUITools.SetBtnGray(btnGet, false)
                end
                IconTools.InitTokenMoneyIcon(item_icon1, self._FundTemp.RewardMoneyId, self._FundTemp.RewardMoneyCount)
            else
                if detailItem.EventType == EEventType.Level then
                    frame_Level:SetActive(true)
                    frame_head_level:SetActive(true)
                    GUI.SetText(labNeedLevel, detailItem.Param.."")
                    GUI.SetText(lab_head_need_level, string.format(StringTable.Get(31053), detailItem.Param..""))
                elseif detailItem.EventType == EEventType.Fight then
                    frame_Battle:SetActive(true)
                    frame_head_battle:SetActive(true)
                    GUI.SetText(labNeedBattle, detailItem.Param.."")
                    GUI.SetText(lab_head_need_battle, string.format(StringTable.Get(31053), detailItem.Param..""))
                elseif detailItem.EventType == EEventType.Quest then
                    frame_head_quest:SetActive(true)
                    frame_quest:SetActive(true)
                    GUI.SetText(labNeedQuest, detailItem.DisplayText)
                    GUI.SetText(lab_head_need_quest, string.format(StringTable.Get(31053), detailItem.Id..""))              
                end
                if detailItem.FundRewardId1 ~= nil and detailItem.FundRewardId1 > 0 then
                    item_icon1:SetActive(true)
                    if detailItem.RewardType1 == ERewardType.Item then
                        local setting = {
                            [EItemIconTag.Number] = detailItem.FundRewardCount1,
                        }
                        IconTools.InitItemIconNew(item_icon1, detailItem.FundRewardId1, setting)
                    else
                        IconTools.InitTokenMoneyIcon(item_icon1, detailItem.FundRewardId1, detailItem.FundRewardCount1)
                    end
                end
                if detailItem.FundRewardId2 ~= nil and detailItem.FundRewardId2 > 0 then
                    item_icon2:SetActive(true)
                    if detailItem.RewardType2 == ERewardType.Item then
                        local setting = {
                            [EItemIconTag.Number] = detailItem.FundRewardCount2,
                        }
                        IconTools.InitItemIconNew(item_icon2, detailItem.FundRewardId2, setting)
                    else
                        IconTools.InitTokenMoneyIcon(item_icon2, detailItem.FundRewardId2, detailItem.FundRewardCount2)
                    end
                end
                if detailItem.FundRewardId3 ~= nil and detailItem.FundRewardId3 > 0 then
                    item_icon3:SetActive(true)
                    if detailItem.RewardType3 == ERewardType.Item then
                        local setting = {
                            [EItemIconTag.Number] = detailItem.FundRewardCount3,
                        }
                        IconTools.InitItemIconNew(item_icon3, detailItem.FundRewardId3, setting)
                    else
                        IconTools.InitTokenMoneyIcon(item_icon3, detailItem.FundRewardId3, detailItem.FundRewardCount3)
                    end
                end
            end
            GameUtil.StopUISfx(PATH.UIFX_Mall_FundLabelFX, img_uifx_bg)
            if is_buy then
                GUITools.SetBtnGray(btnGet, false)
                GUI.SetText(lab_btn_get, StringTable.Get(31201))
                if detailItem.State == FundState.NotReach then
                    btnGet:SetActive(true)
                    GUITools.SetBtnGray(btnGet, true)
                    GUI.SetText(lab_btn_get, StringTable.Get(31200))
                elseif detailItem.State == FundState.GotIt then
                    img_compeleted:SetActive(true)
                else
                    btnGet:SetActive(true)
                    img_btn_fx:SetActive(true)
                    GameUtil.PlayUISfxClipped(PATH.UIFX_Mall_FundLabelFX, img_uifx_bg, img_uifx_bg, item.parent.parent)
                end
            else
                btnGet:SetActive(true)
                GUITools.SetBtnGray(btnGet, true)
                GUI.SetText(lab_btn_get, StringTable.Get(31200))
                img_compeleted:SetActive(false)
            end
        else
            warn("(CMallPageFund.OnInitItem) 数组越界")
        end
    else
        warn("(CMallPageFund.OnInitItem) 基金模板数据为空！！")
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local index = index + 1
    if id_btn == "Btn_Get" then
        if self._FundTemp ~= nil and self._FundTemp.FundRewardDetails ~= nil then
            local detailItem = self._FundTemp.FundRewardDetails[index]
            if detailItem.State == FundState.NotReach then
                game._GUIMan:ShowTipText(StringTable.Get(31064), false)
            elseif detailItem.State == FundState.CanReward then
                CMallMan.Instance():FundGetReward(self._FundTemp.Id, self._FundTemp.FundRewardDetails[index].Id, self._PageData.StoreId)
            end
        else
            warn("error !!! CMallPageFund.OnSelectItemButton 没有基金模板数据")
        end
    elseif string.find(id_btn, "ItemIconNew") then
        local detailItem = self._FundTemp.FundRewardDetails[index]
        if id_btn == "ItemIconNew1" then
            if detailItem.RewardType1 == ERewardType.Item then
                CItemTipMan.ShowItemTips(detailItem.FundRewardId1, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
            else
                local panelData = 
				{
					_MoneyID = detailItem.FundRewardId1,
					_TipPos = TipPosition.FIX_POSITION,
					_TargetObj = button_obj, 
				} 
			    CItemTipMan.ShowMoneyTips(panelData)
            end
        elseif id_btn == "ItemIconNew2" then
            if detailItem.RewardType2 == ERewardType.Item then
                CItemTipMan.ShowItemTips(detailItem.FundRewardId2, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
            else
                local panelData = 
				{
					_MoneyID = detailItem.FundRewardId2,
					_TipPos = TipPosition.FIX_POSITION,
					_TargetObj = button_obj, 
				} 
			    CItemTipMan.ShowMoneyTips(panelData)
            end
        elseif id_btn == "ItemIconNew3" then
            if detailItem.RewardType3 == ERewardType.Item then
                CItemTipMan.ShowItemTips(detailItem.FundRewardId3, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
            else
                local panelData = 
				{
					_MoneyID = detailItem.FundRewardId3,
					_TipPos = TipPosition.FIX_POSITION,
					_TargetObj = button_obj, 
				} 
			    CItemTipMan.ShowMoneyTips(panelData)
            end
        end
    end
end

def.override().OnHide = function(self)

end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)
    if self._BuyBtn ~= nil then
        self._BuyBtn:Destroy()
    end
    self._FundTemp = nil
    self._FundData = nil
    self._List_ItemsList = nil
    self._PanelObject = nil
end

CMallPageFund.Commit()
return CMallPageFund
