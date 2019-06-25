local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CMallRecommendField = Lplus.Class("CMallRecommendField")
local def = CMallRecommendField.define

local ttl = 5

def.field("number")._FieldID = -1		    -- 神符槽位模板ID
def.field("number")._CurIndex = 1           -- 当前正在显示的广告Index
def.field("table")._FieldData = nil         -- 服务器数据（针对这个推荐位的数据）
def.field("userdata")._FieldUI = nil        -- FieldUI (GameObject)
def.field("number")._ChangeTimer = 0        -- 变化的Timer

def.static("=>", CMallRecommendField).new = function()
	local obj = CMallRecommendField()
	return obj
end

def.method("number", "userdata", "table").Init = function(self, fieldID, fieldUI, fieldData)
    self._FieldID = fieldID
    self._FieldUI = fieldUI
    self._FieldData = fieldData
    self._CurIndex = 1
    self:RemoveChangeTimer()
    self:AddChangeTimer()
    self:UpdateUI()
end


def.method().AddChangeTimer = function(self)
    local max_count = #self._FieldData.RcommendGoodss
    if max_count <= 1 then return end
    local callback = function()
        self._CurIndex = (self._CurIndex % max_count) + 1
        self:UpdateUI()
    end
    self._ChangeTimer = _G.AddGlobalTimer(ttl, false, callback)
end

def.method().RemoveChangeTimer = function(self)
    if self._ChangeTimer ~= 0 then
        _G.RemoveGlobalTimer(self._ChangeTimer)
        self._ChangeTimer = 0
    end
end

--更新界面
def.method().UpdateUI = function(self)
    if self._FieldUI == nil or self._FieldData == nil then return end
    if self._FieldData.RcommendGoodss == nil or #self._FieldData.RcommendGoodss <= 0 then
        warn("error  !!! 商城推荐页签数据错误,一个推荐位至少有一个推荐")
        return
    end
    local recommend_data = self._FieldData.RcommendGoodss[self._CurIndex]
    if recommend_data == nil then
        warn("error !!! CMallRecommendField.UpdateUI 数组越界")
        return
    end
    local uiTemplate = self._FieldUI:GetComponent(ClassType.UITemplate)
    local img_bg = uiTemplate:GetControl(0)
    local btn_pre = uiTemplate:GetControl(1)
    local btn_next = uiTemplate:GetControl(2)
    local tgp_page_toggels = uiTemplate:GetControl(3)
    local list_rdo_pages = uiTemplate:GetControl(4)
    local list_points = list_rdo_pages:GetComponent(ClassType.GNewList)
    local count = #self._FieldData.RcommendGoodss
    if count > 1 then
        tgp_page_toggels:SetActive(true)
        btn_pre:SetActive(true)
        btn_next:SetActive(true)
        list_points:SetItemCount(#self._FieldData.RcommendGoodss)
        GUI.SetGroupToggleOn(list_rdo_pages, self._CurIndex + 1)
    else
        tgp_page_toggels:SetActive(false)
        btn_pre:SetActive(false)
        btn_next:SetActive(false)
    end
    GUITools.SetItemIcon(img_bg, recommend_data.IconPath)
end

def.method().DrumpToRightStore = function(self)
    if self._FieldData ~= nil and self._FieldData.RcommendGoodss ~= nil then
        local recommend_data = self._FieldData.RcommendGoodss[self._CurIndex]
        if recommend_data ~= nil then
            local CPanelMall = require "GUI.CPanelMall"
            if CPanelMall.Instance():IsShow() and recommend_data.StoreId > 0 then
                CPanelMall.Instance():SwitchToShop(recommend_data.StoreId)
            end
        end
    end
end

def.method("string").OnClick = function(self, id)
    if string.find(id, "Btn_PrePage") then
        self._CurIndex = self._CurIndex - 1 <= 0 and #self._FieldData.RcommendGoodss or self._CurIndex - 1
    elseif string.find(id, "Btn_NextPage") then
        local max_count = #self._FieldData.RcommendGoodss
        self._CurIndex = (self._CurIndex % max_count) + 1
    elseif string.find(id, "Frame_ShowField") then
        self:DrumpToRightStore()
        return
    end
    -- 手动点击切换页签的话需要重置timer的时间
--    self:RemoveChangeTimer()
--    self:AddChangeTimer()
    self:UpdateUI()
end

def.method().Realse = function(self)
    self:RemoveChangeTimer()
    self._FieldUI = nil
    self._FieldData = nil
    self._CurIndex = 1
end

CMallRecommendField.Commit()
return CMallRecommendField