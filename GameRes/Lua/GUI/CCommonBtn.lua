local Lplus = require "Lplus"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CElementData = require "Data.CElementData"
local CGame = Lplus.ForwardDeclare("CGame")

local CCommonBtn = Lplus.Class("CCommonBtn")
local def = CCommonBtn.define

def.field("userdata")._Btn = nil                    -- 通用按钮预设
def.field("function")._OnMoneyChange = nil          -- 金币数量变化的回调（内部使用）
def.field("table")._Setting = nil                   -- 外部传过来的参数
def.field("boolean")._IsGray = false

-- setting = {
      -- [EnumDef.CommonBtnParam.BtnTip] = "1111",
      -- [EnumDef.CommonBtnParam.MoneyID] = 1,
      -- [EnumDef.CommonBtnParam.MoneyCost] = 222   
-- }
def.static("userdata", "dynamic", "=>", CCommonBtn).new = function(btn, setting)
	local new_btn = CCommonBtn()
	new_btn._Btn = btn
    new_btn._Setting = setting or {}
    new_btn:Init()
	new_btn:UpdateUI()
	return new_btn
end

def.method("table").ResetSetting = function(self, setting)
    if self._Setting == nil then
        self._Setting = setting
        self:UpdateUI()
        return
    end
    for k,v in pairs(setting) do
        self._Setting[k] = v
    end
    self:UpdateUI()
end

def.method().Init = function(self)
    if self._OnMoneyChange == nil then
    	self._OnMoneyChange = function(sender, event)
	    	self:UpdateUI()
	    end
	    CGame.EventManager:addHandler('NotifyMoneyChangeEvent', self._OnMoneyChange)
    end
end

-- 更新按钮
def.method().UpdateUI = function(self)
    if self._Btn == nil then
        warn("error!!! 公用按钮组件预设为空或者参数为空！")
        return
    end
    if IsNil(self._Btn) then
        warn("error!!! 有界面的CCommonBtn对象没有销毁！(没有调用CCommonBtn的Destroy())", debug.traceback())
        return
    end
    local uiTemplate = self._Btn:GetComponent(ClassType.UITemplate)
    local img_bg = uiTemplate:GetControl(0)
    local lab_tip = uiTemplate:GetControl(1)
    local img_money = uiTemplate:GetControl(2)
    local lab_cost = uiTemplate:GetControl(3)
    if self._IsGray then
        GUITools.MakeBtnBgGray(img_bg, true)
        GUITools.SetBtnExpressGray(self._Btn, true)
    else
        GUITools.MakeBtnBgGray(img_bg, false)
        GUITools.SetBtnExpressGray(self._Btn, false)
    end
    if self._Setting[EnumDef.CommonBtnParam.BtnTip] ~= nil and lab_tip ~= nil then
        GUI.SetText(lab_tip, tostring(self._Setting[EnumDef.CommonBtnParam.BtnTip]))
    end
    if self._Setting[EnumDef.CommonBtnParam.MoneyID] ~= nil and img_money ~= nil then
        local moneyID = tonumber(self._Setting[EnumDef.CommonBtnParam.MoneyID])
        if not moneyID then
            warn("error!!! 公用按钮组件MoneyID参数不对")
            return
        end
        GUITools.SetTokenMoneyIcon(img_money, moneyID)
        if self._IsGray then
            GUITools.MakeBtnBgGray(img_money, true)
        else
            GUITools.MakeBtnBgGray(img_money, false)
        end
    end
    if self._Setting[EnumDef.CommonBtnParam.MoneyCost] ~= nil and lab_cost ~= nil then
        local money_cost = tonumber(self._Setting[EnumDef.CommonBtnParam.MoneyCost])
        if not money_cost then
            warn("error!!! 公用按钮组件MoneyCost参数不对")
            return
        end
        if self._IsGray then
            GUI.SetText(lab_cost, GUITools.FormatNumber(money_cost, true))
        else
            if self._Setting[EnumDef.CommonBtnParam.MoneyID] ~= nil then
                local have_count = game._HostPlayer:GetMoneyCountByType(self._Setting[EnumDef.CommonBtnParam.MoneyID])
                if have_count >= money_cost then
                    GUI.SetText(lab_cost, GUITools.FormatNumber(money_cost, true))
                else
                    GUI.SetText(lab_cost, string.format(StringTable.Get(20446), GUITools.FormatNumber(money_cost, true)))
                end
            end
        end
    end
end

-- 将按钮置灰
def.method("boolean").MakeGray = function(self, isGray)
    self._IsGray = isGray
    self:UpdateUI()
end

-- 设置按钮的显隐
def.method("boolean").SetActive = function(self, isActive)
    if self._Btn ~= nil then
        self._Btn:SetActive(isActive)
    end
end

-- 闪光
def.method("boolean").ShowFlashFx = function(self, isShow)
    if self._Btn ~= nil then
        local fx = self._Btn:FindChild("Img_Bg/Img_BtnFloatFx")
        if fx ~= nil then
            fx:SetActive(isShow)
        end
    end
end

-- 设置不可点
def.method("boolean").SetInteractable = function(self, interactable)
    if self._Btn ~= nil then
        GameUtil.SetButtonInteractable(self._Btn, interactable)
    end
end

def.method("string", "=>", "boolean").OnClick = function(self,id)
    if self._Btn == nil then
        return false
    end
    if id == self._Btn.name then
        return true
    end
    return false
end

def.method().Destroy = function (self)
    if self._OnMoneyChange ~= nil then
        CGame.EventManager:removeHandler('NotifyMoneyChangeEvent', self._OnMoneyChange)
    	self._OnMoneyChange = nil
    end
    self._Btn = nil
    self._Setting = nil
    self._IsGray = false
end

CCommonBtn.Commit()
return CCommonBtn