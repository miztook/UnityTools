--
--数字虚拟小键盘
--
--【孟令康】
--
--2016年09月18日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelNumberKeyboard = Lplus.Extend(CPanelBase, "CPanelNumberKeyboard")
local def = CPanelNumberKeyboard.define

def.field("string")._LabelNumberContent = ""	-- 最终输入值
def.field("userdata")._Label = nil				-- 要输入的Label
def.field("userdata")._DefaultLabel = nil		-- 默认存在Label
def.field("number")._Max = 0					-- 可输入的最大值
def.field("number")._Min = 0					-- 可输入的最小值:这决定了默认显示内容与可显示的最小值
def.field("function")._EndCb = nil				-- 结束时回调函数
def.field("function")._CountChangeCb = nil      -- 数量变化回调函数
def.field("boolean")._IsFirst = true			-- 第一次输入新值要覆盖旧值

local instance = nil
def.static("=>", CPanelNumberKeyboard).Instance = function()
	if not instance then
		instance = CPanelNumberKeyboard()
		instance._PrefabPath = PATH.UI_NumberKeyboard
		instance._PanelCloseType = EnumDef.PanelCloseType.ClickEmpty
		instance._DestroyOnHide = true

        instance:SetupSortingParam()
	end
	return instance
end

-- 当接收数据
def.override("dynamic").OnData = function(self, data)
	self._Label = data.label
	self._Max = data.max
	self._Min = data.min
	self._EndCb = data.endCb
    self._CountChangeCb = data.changeCb
    self._IsFirst = true
	if self._Max < self._Min then
		self._Max = self._Min
	end	
	local labelSize = self._Label:GetComponent(ClassType.RectTransform).rect.height
	local img_BGSize = self._Panel:FindChild("Img_BG"):GetComponent(ClassType.RectTransform).sizeDelta
	local worldPos = GameUtil.WorldPositionToCanvas(self._Label)
	local yPos = labelSize * 0.5 + img_BGSize.y * 0.5
	local deltaSize = img_BGSize.y + worldPos.y
	if deltaSize >= 320 then
		yPos = -yPos
	end
	self._Panel:FindChild("Img_BG"):GetComponent(ClassType.RectTransform).anchoredPosition3D = Vector3.New(0, yPos, 0) + worldPos
	self._LabelNumberContent = self._Label:GetComponent(ClassType.Text).text
	if tonumber(self._LabelNumberContent) == nil then
		self._LabelNumberContent = ""
	end
	if not IsNil(data.defaultLabel) then
		self._DefaultLabel = data.defaultLabel
	end
end

-- 当摧毁的时候
def.override().OnDestroy = function(self)
    self._Label = nil
    self._DefaultLabel = nil
    self._IsFirst = true
	if self._EndCb ~= nil then
        local num = tonumber(self._LabelNumberContent)
        if num then
            self._EndCb(num)
        else
            self._EndCb()
        end
		self._EndCb = nil
	end
    
	instance = nil
end

local NumberButton = { "Btn_1", "Btn_2", "Btn_3", "Btn_4", "Btn_5", "Btn_6", "Btn_7", "Btn_8", "Btn_9" }
-- Button点击
def.override("string").OnClick = function(self, id)
	for i,v in ipairs(NumberButton) do
		if id == v then
			if self._IsFirst then
				self._IsFirst = false
                if i > self._Max then
                    game._GUIMan:ShowTipText(StringTable.Get(31047), false)
                end
				self._LabelNumberContent = string.format("%d", math.min(i, self._Max))
			else
				if tonumber(self._LabelNumberContent .. i) <= self._Max then
					if tonumber(self._LabelNumberContent) < self._Min then
						local num = 0
						if i > self._Min then
							num = i
						else
							num = self._Min
						end
						self._LabelNumberContent = tostring(num)
					else
						if self._LabelNumberContent == "0" then
							self._LabelNumberContent = ""
						end
						self._LabelNumberContent = self._LabelNumberContent .. string.format("%d", i)
					end
				else
                    game._GUIMan:ShowTipText(StringTable.Get(31047), false)
					self._LabelNumberContent = tostring(self._Max)
				end
			end

		end
	end

	if id == "Btn_0" then
		if tonumber(self._LabelNumberContent) ~= nil and tonumber(self._LabelNumberContent) > 0 then
			if not self._IsFirst then
				if tonumber(self._LabelNumberContent .. "0") <= self._Max then
					self._LabelNumberContent = self._LabelNumberContent .. "0"
				else
                    game._GUIMan:ShowTipText(StringTable.Get(31047), false)
					self._LabelNumberContent = tostring(self._Max)
				end
			end
		end
	elseif id == "Btn_Delete" then
		local length = string.len(self._LabelNumberContent)
		if length > 0 then
			self._LabelNumberContent = string.sub(self._LabelNumberContent, 1, length - 1)
		end
	elseif id == "Btn_Max" then
		self._LabelNumberContent = string.format("%d", self._Max)
	elseif id == "Btn_Sure" then
	    if self._LabelNumberContent == "0" or self._LabelNumberContent == "" then
            self._LabelNumberContent = tostring(self._Min)
		    GUI.SetText(self._Label, self._LabelNumberContent)
	    else
		    GUI.SetText(self._Label, self._LabelNumberContent)
	    end
		game._GUIMan:CloseByScript(self)
		return
	end
    if self._LabelNumberContent == "0" or self._LabelNumberContent == "" then
        self._IsFirst = true
    end
    GUI.SetText(self._Label, self._LabelNumberContent)
	if not IsNil(self._DefaultLabel) then
		if tonumber(self._LabelNumberContent) < self._Min then
			self._Label:SetActive(false)
			self._DefaultLabel:SetActive(true)
		else
			self._Label:SetActive(true)
			self._DefaultLabel:SetActive(false)
		end
	end
    if self._CountChangeCb ~= nil then
        local num = tonumber(self._LabelNumberContent)
        if num then
            self._CountChangeCb(num)
        end
    end
end

CPanelNumberKeyboard.Commit()
return CPanelNumberKeyboard