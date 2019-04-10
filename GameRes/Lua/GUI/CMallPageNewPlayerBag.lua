local Lplus = require "Lplus"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local EItemEventType = require "PB.data".EItemEventType
local EResourceType = require "PB.data".EResourceType
local EItemType = require "PB.Template".Item.EItemType
local ECostType = require "PB.Template".Goods.ECostType
local ELimitType = require "PB.Template".Goods.ELimitType
local CMallUtility = require "Mall.CMallUtility"
local CMallPageNewPlayerBag = Lplus.Extend(CMallPageBase, "CMallPageNewPlayerBag")
local def = CMallPageNewPlayerBag.define

def.field("userdata")._List_ItemsList = nil
def.field("table")._ItemRewardTable = nil

def.static("=>", CMallPageNewPlayerBag).new = function()
	local pageNew = CMallPageNewPlayerBag()
	return pageNew
end

def.override().OnCreate = function(self)
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    self._List_ItemsList = uiTemplate:GetControl(1):GetComponent(ClassType.GNewListLoop)

end

def.override("dynamic").OnData = function(self, data)
    if data and data.Goods then
        local goodsItem = self._PageData.Goods[1]
        local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._PageData.StoreId, goodsItem.Id)
        self._ItemRewardTable = CMallUtility.GetItemsShowDataByItemID(goodsItem.ItemId, 1)
        self:UpdateNewPlayerBagPanel(hasBuyCount, goodsItem)
    else
        warn("error 新手礼包数据为空")
    end
end

-- 更新面板
def.method("number", "table").UpdateNewPlayerBagPanel = function(self, buyCount, goodsItem)
    if goodsItem == nil then 
        warn("新手礼包面板刷新失败，没有商品数据")    
        return
    end
    local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
    local img_BG = uiTemplate:GetControl(0)
    local lab_cost = uiTemplate:GetControl(2)
    local img_item_icon = uiTemplate:GetControl(3)
    local lab_name = uiTemplate:GetControl(4)
    local lab_buy_title_tip = uiTemplate:GetControl(5)
    local btn_buy = uiTemplate:GetControl(6)
    local img_havebuy = uiTemplate:GetControl(7)
    local lab_des = uiTemplate:GetControl(8)
    local img_buyBG = uiTemplate:GetControl(9)
    local item_temp = CElementData.GetItemTemplate(goodsItem.ItemId)
    local good_temp = CElementData.GetTemplate("Goods", goodsItem.Id)
    if item_temp == nil then return end
    GUITools.SetItemIcon(img_item_icon, item_temp.IconAtlasPath)
    GUI.SetText(lab_name, goodsItem.Name)
    GUI.SetText(lab_des, item_temp.TextDescription)
    if good_temp.LimitType == ELimitType.NoLimit then
        img_buyBG:SetActive(false)
    else
        img_buyBG:SetActive(true)
        local tip_str = ""
        if good_temp.LimitType == ELimitType.Cycle then
            tip_str = StringTable.Get(31020)
        elseif good_temp.LimitType == ELimitType.Forever then
            tip_str = StringTable.Get(31021)
        elseif good_temp.LimitType == ELimitType.ForeverAccount then
            tip_str = StringTable.Get(31022)
        end
        GUI.SetText(lab_buy_title_tip, string.format(StringTable.Get(20061), buyCount, goodsItem.Stock))
    end
end

def.override().RefreshPage = function(self)
    if self._PageData == nil then
        warn(string.format("MallPanel.RefreshPage error, _PageData is nil"))
        return
    end
    if self._PageData and self._PageData.Goods then
        local goodsItem = self._PageData.Goods[1]
        if goodsItem == nil then warn("新手礼包商品数据为空！！") return end
        local hasBuyCount = CMallMan.Instance():GetItemHasBuyCountByID(self._PageData.StoreId, goodsItem.Id)
        self:UpdateNewPlayerBagPanel(hasBuyCount, goodsItem)
    end
end

def.override().OnRegistUIEvent = function(self)
    GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallSuperBagShop"
end

def.override('string').OnClick = function(self, id)
end

def.override('userdata', 'string', 'number').OnInitItem = function(self, item, id, index)
    if id == "List_ItemList" then
        local index = index + 1
        if self._PageData ~= nil then
            local reward = self._ItemRewardTable[index]
            local uiTemplate = item:GetComponent(ClassType.UITemplate)
            local item_icon = uiTemplate:GetControl(0)
            local img_money_icon = uiTemplate:GetControl(1)
            local lab_item_name = uiTemplate:GetControl(2)
            if reward.IsTokenMoney then
                item_icon:SetActive(false)
                img_money_icon:SetActive(true)
                GUITools.SetTokenMoneyIcon(img_money_icon, reward.Data.Id)
                local money_temp = CElementData.GetMoneyTemplate(reward.Data.Id)
                GUI.SetText(lab_item_name, string.format(StringTable.Get(13045), money_temp.TextDisplayName, reward.Data.Count))
            else
                item_icon:SetActive(true)
                img_money_icon:SetActive(false)
                local setting = {
                    [EItemIconTag.Number] = reward.Data.Count,
                }
                IconTools.InitItemIconNew(item_icon, reward.Data.Id, setting, EItemLimitCheck.AllCheck)
                local item_temp = CElementData.GetItemTemplate(reward.Data.Id)
                GUI.SetText(lab_item_name, RichTextTools.GetItemNameRichText(reward.Data.Id, reward.Data.Count, false))
            end
        end
    end
end

def.override("userdata", "string", "string", "number").OnSelectItemButton = function(self, button_obj, id, id_btn, index)
    local index = index + 1
    if id == "List_ItemList" then
        if id_btn == "ItemIconNew" then
            local item = self._ItemRewardTable[index]
            CItemTipMan.ShowItemTips(item.Data.itemID, TipsPopFrom.OTHER_PANEL, button_obj, TipPosition.FIX_POSITION)
        end
    end
end

def.override().OnHide = function(self)
end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)
end

CMallPageNewPlayerBag.Commit()
return CMallPageNewPlayerBag