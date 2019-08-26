local Lplus = require "Lplus"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CElementData = require "Data.CElementData"

local CCommonNumInput = Lplus.Class("CCommonNumInput")
local def = CCommonNumInput.define

def.field("userdata")._InputGO = nil                    -- 通用数量输入组件的预设
def.field("function")._OnCountChangeCb = nil            -- 输入之后数量变化的回调（function cb(count) ... end）
def.field("number")._MinCount = 0                       -- 最小输入的数量
def.field("number")._MaxCount = 0                       -- 最大输入的数量
def.field("number")._CurCount = 0                       -- 当前输入的数量

def.static("userdata", "function", "number", "number", "=>", CCommonNumInput).new = function(input, onCountChangeCb, minCount, maxCount)
	local new_btn = CCommonNumInput()
	new_btn._InputGO = input
    new_btn._OnCountChangeCb = onCountChangeCb
    new_btn._MinCount = minCount
    new_btn._MaxCount = maxCount
    new_btn._CurCount = minCount
	new_btn:UpdateUI()
	return new_btn
end

-- 重新设置最大值和最小值
def.method("number", "number").ResetMinAndMaxCount = function(self, min, max)
    self._MinCount = min
    self._MaxCount = max
    if self._CurCount > self._MaxCount then
        self._CurCount = self._MaxCount
    end
    if self._CurCount < self._MinCount then
        self._CurCount = self._MinCount
    end
    self:UpdateUI()
end

-- 设置不可点击
def.method("boolean").SetInteractable = function(self, interactable)
    if self._InputGO == nil then return end
    local uiTemplate = self._InputGO:GetComponent(ClassType.UITemplate)
    local btn_max = uiTemplate:GetControl(1)
    local btn_min = uiTemplate:GetControl(2)
    local btn_input = self._InputGO:FindChild("Btn_NumInput")
    if interactable then
        GameUtil.SetButtonInteractable(btn_max, true)
        GUITools.SetBtnGray(btn_max, false, true)
        GameUtil.SetButtonInteractable(btn_min, true)
        GUITools.SetBtnGray(btn_min, false, true)
        GameUtil.SetButtonInteractable(btn_input, true)
        self:UpdateUI()
    else
        GameUtil.SetButtonInteractable(btn_max, false)
        GUITools.SetBtnGray(btn_max, true, true)
        GameUtil.SetButtonInteractable(btn_min, false)
        GUITools.SetBtnGray(btn_min, true, true)
        GameUtil.SetButtonInteractable(btn_input, false)
    end
end

-- 直接设置当前数量
def.method("number").SetCount = function(self, count)
    self._CurCount = math.min(count, self._MaxCount)
    self._CurCount = math.max(self._CurCount, self._MinCount)
    self:UpdateUI()
    if self._OnCountChangeCb ~= nil then
        self._OnCountChangeCb(self._CurCount)
    end
end

def.method("number").SetCountWithOutCb = function(self, count)
    self._CurCount = math.min(count, self._MaxCount)
    self._CurCount = math.max(self._CurCount, self._MinCount)
    self:UpdateUI()
end

def.method("string").SetTextWithOutCb = function(self, str)
    if self._InputGO == nil then
        warn("error!!! 公用数字输入组件预设为空！")
        return
    end
    local uiTemplate = self._InputGO:GetComponent(ClassType.UITemplate)
    local lab_count = uiTemplate:GetControl(0)
    GUI.SetText(lab_count, str)
end

def.method().UpdateUI = function(self)  
    if self._InputGO == nil then
        warn("error!!! 公用数字输入组件预设为空！")
        return
    end
    local uiTemplate = self._InputGO:GetComponent(ClassType.UITemplate)
    local lab_count = uiTemplate:GetControl(0)
    local btn_max = uiTemplate:GetControl(1)
    local btn_min = uiTemplate:GetControl(2)
    GUI.SetText(lab_count, GUITools.FormatNumber(self._CurCount, false))
    if self._CurCount <= self._MinCount then
        GameUtil.SetButtonInteractable(btn_min, false)
        GUITools.SetBtnGray(btn_min, true, true)
    else
        GameUtil.SetButtonInteractable(btn_min, true)
        GUITools.SetBtnGray(btn_min, false, true)
    end
    if self._CurCount >= self._MaxCount then
        GameUtil.SetButtonInteractable(btn_max, false)
        GUITools.SetBtnGray(btn_max, true, true)
    else
        GameUtil.SetButtonInteractable(btn_max, true)
        GUITools.SetBtnGray(btn_max, false, true)
    end
end

def.method("string", "=>", "boolean").OnClick = function(self,id)
    if self._InputGO == nil then
        return false
    end
    if id == "Btn_NumInput" then
        local cb = function(count)
            self._CurCount = (count or 0)
            self:UpdateUI()
            if self._OnCountChangeCb ~= nil then
                self._OnCountChangeCb(self._CurCount)
            end
        end
        local uiTemplate = self._InputGO:GetComponent(ClassType.UITemplate)
        local lab_count = uiTemplate:GetControl(0)
        game._GUIMan:OpenNumberKeyboard(lab_count,nil, self._MinCount, self._MaxCount, cb, nil)
        return true
    elseif id == "Btn_NumInputMax" then
        self._CurCount = self._MaxCount
        self:UpdateUI()
        if self._OnCountChangeCb ~= nil then
            self._OnCountChangeCb(self._CurCount)
        end
        return true
    elseif id == "Btn_NumInputMin" then
        self._CurCount = self._MinCount
        self:UpdateUI()
        if self._OnCountChangeCb ~= nil then
            self._OnCountChangeCb(self._CurCount)
        end
        return true
    end
    return false
end

def.method().Destroy = function (self)
    self._InputGO = nil
    self._OnCountChangeCb = nil
    self._MinCount = 0
    self._MaxCount = 0
    self._CurCount = 0
end

CCommonNumInput.Commit()
return CCommonNumInput