local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CMallRecommendField = require "Mall.CMallRecommendField"
local CMallPageBase = require "Mall.CMallPageBase"
local CElementData = require "Data.CElementData"

local CMallPageRecommend = Lplus.Extend(CMallPageBase, "CMallPageRecommend")
local def = CMallPageRecommend.define

def.field("table")._FieldTable = nil

def.static("=>", CMallPageRecommend).new = function()
	local pageNew = CMallPageRecommend()
	return pageNew
end

def.override().OnCreate = function(self)
    self._IsHideTabList = true
end

def.override("dynamic").OnData = function(self, data)
    if self._PageData == nil then
        warn(string.format("CMallPageRecommend.OnData error, _PageData is nil"))
        return
    end
    local store_temp = CElementData.GetTemplate("Store", self._PageData.StoreId)
    if store_temp == nil then
        warn("error !!! CMallPageRecommend.OnData 商店模板数据为空！ storeID : ", self._PageData.StoreId)
        return
    end
    self._FieldTable = {}
    for i = 1,3 do
        local field = CMallRecommendField.new()
        local uiTemplate = self._GameObject:GetComponent(ClassType.UITemplate)
        --print("store_temp.RecommendStructs ", store_temp.RecommendStructs[i])
        field:Init(i, uiTemplate:GetControl(i-1), store_temp.RecommendStructs[i])
        self._FieldTable[i] = field
    end
end

def.override().RefreshPage = function(self)
    
end

def.override().OnRegistUIEvent = function(self)
    --GUITools.RegisterGNewListOrLoopEventHandler(self._Panel, self._GameObject, true)
    GUITools.RegisterButtonEventHandler(self._Panel, self._GameObject,true)
end

def.override("=>", "string").GetMallPageTemplatePath = function(self)
    return "UITemplate/Page_MallRecommend"
end

def.override('string').OnClick = function(self, id)
    local field_id = tonumber(string.sub(id, -1))
    if field_id and self._FieldTable[field_id] then
        self._FieldTable[field_id]:OnClick(id)
    end
end

def.override().OnHide = function(self)
    if self._FieldTable ~= nil then
        for i,v in pairs(self._FieldTable) do
            if v then
                v:Realse()
            end
        end
        self._FieldTable = nil
    end
end

def.override().OnDestory = function(self)
    CMallPageBase.OnDestory(self)
    
end

CMallPageRecommend.Commit()
return CMallPageRecommend