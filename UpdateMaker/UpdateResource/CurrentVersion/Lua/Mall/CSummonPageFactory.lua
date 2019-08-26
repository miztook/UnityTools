local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CMallMan = require "Mall.CMallMan"
local EFormatType = require "PB.Template".Store.EFormatType

local CSummonPagePetEgg = require "GUI.CSummonPagePetEgg"
local CSummonPageElf = require "GUI.CSummonPageElf"


local CSummonPageFactory = Lplus.Class("CSummonPageFactory")
local def = CSummonPageFactory.define
local instance = nil

def.static("=>", CSummonPageFactory).Instance = function()
	if instance == nil then
		instance = CSummonPageFactory()
	end
	return instance
end

def.method("table", "table", "=>", "table").GenerateSummonPage = function(self, panelSummon, pageData)
    local page = nil
    local pageType = pageData.FormatType
    if pageType == EFormatType.SprintGiftTemp then
        page = CSummonPageElf.new()
    elseif pageType == EFormatType.PetDropRuleTemp then
        page = CSummonPagePetEgg.new()
    end
    if page then
        page:Init(pageType, panelSummon, pageData)
        if pageData.WebViewUrl == nil or pageData.WebViewUrl == "" then
            local tempGO = panelSummon._PanelObjects.Frame_Content
            page._GameObject = tempGO:FindChild(page:GetSummonPageTemplateName())
        end
    else
        warn("未找到召唤子页签，请更新客户端")
    end

    return page
end

CSummonPageFactory.Commit()
return CSummonPageFactory
