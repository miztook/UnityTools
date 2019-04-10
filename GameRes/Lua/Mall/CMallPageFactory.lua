local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local EFormatType = require "PB.Template".Store.EFormatType
local CMallPageCommonShop = require "GUI.CMallPageCommonShop"
local CMallPageFund = require "GUI.CMallPageFund"
local CMallPageMontylyCard = require "GUI.CMallPageMontylyCard"
local CMallPageMysteryShop = require "GUI.CMallPageMysteryShop"
local CMallPageNewPlayerBag = require "GUI.CMallPageNewPlayerBag"
local CMallPagePetEggShop = require "GUI.CMallPagePetEggShop"
local CMallPageWebView = require "GUI.CMallPageWebView"
local CMallPageElf = require "GUI.CMallPageElf"
local CMallPageCommonTipShop = require "GUI.CMallPageCommonTipShop"
local CMallPageRecommend = require "GUI.CMallPageRecommend"

local CMallPageFactory = Lplus.Class("CMallPageFactory")
local def = CMallPageFactory.define
local instance = nil

def.static("=>", CMallPageFactory).Instance = function()
	if instance == nil then
		instance = CMallPageFactory()
	end
	return instance
end

def.method("table", "table", "=>", "table").GenerateMallPage = function(self, panelMall, pageData)
    local page = nil
    local pageType = pageData.FormatType
    if pageType == EFormatType.CommonTemp then
        page = CMallPageCommonShop.new()
    elseif pageType == EFormatType.NewPlayerBagTemp then
        page = CMallPageNewPlayerBag.new()
    elseif pageType == EFormatType.MysticalStoreTemp then
        page = CMallPageMysteryShop.new()
    elseif pageType == EFormatType.FundTemp then
        page = CMallPageFund.new()
    elseif pageType == EFormatType.MonthlyCardTemp then
        page = CMallPageMontylyCard.new()
    elseif pageType == EFormatType.WebViewTemp then
        page = CMallPageWebView.new()
    elseif pageType == EFormatType.SprintGiftTemp then
        page = CMallPageElf.new()
    elseif pageType == EFormatType.PetDropRuleTemp then
        page = CMallPagePetEggShop.new()
    elseif pageType == EFormatType.RandomGiftBagTemp then
        page = CMallPageCommonTipShop.new()
    elseif pageType == EFormatType.RecommendTemp then
        page = CMallPageRecommend.new()
    end
    if page then
        page:Init(pageType, panelMall, pageData)
        if pageData.WebViewUrl == nil or pageData.WebViewUrl == "" then
            local tempGO = panelMall._PanelObjects.Frame_Content
            page._GameObject = GameObject.Instantiate(tempGO:FindChild(page:GetMallPageTemplatePath()))
            page._GameObject:SetParent(tempGO)
            page._GameObject.localPosition = tempGO.localPosition
            page._GameObject.localScale = tempGO.localScale
            page._GameObject.localRotation = tempGO.localRotation
            GUITools.UISetRectTransformStretch(page._GameObject)
        end
    else
        warn("未找到商城子页签，请更新客户端")
    end

    return page
end

CMallPageFactory.Commit()
return CMallPageFactory
