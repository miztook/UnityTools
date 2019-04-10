--
-- 修改名称
--
--【孟令康】
--
-- 2018年03月15日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelUIRename = Lplus.Extend(CPanelBase, "CPanelUIRename")
local def = CPanelUIRename.define

def.field("userdata")._InputField_Name = nil
def.field("userdata")._Img_Money = nil
def.field("userdata")._Lab_Cost_Num = nil

-- _Name:原名称,可为空;_Min:最小值,可为空;_Max:最大值，可为空,;_Tid:货币Tid;_Cost:修改花费;_Callback:回调
def.field("table")._Data = nil

local instance = nil
def.static("=>", CPanelUIRename).Instance = function()
	if not instance then
		instance = CPanelUIRename()
		instance._PrefabPath = PATH.UI_Rename
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self._InputField_Name = self:GetUIObject("InputField_Name"):GetComponent(ClassType.InputField)
	self._Img_Money = self:GetUIObject("Img_Money")
	self._Lab_Cost_Num = self:GetUIObject("Lab_Cost_Num")
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Data = data
	if self._Data._Name ~= nil then
		self._InputField_Name.text = self._Data._Name
	end
	if self._Data._Tid ~= nil then
		GUITools.SetTokenMoneyIcon(self._Img_Money, self._Data._Tid)
	end
	if self._Data._Cost ~= nil then
		local moneyValue = game._GuildMan:GetMoneyValueByTid(self._Data._Tid)
		if moneyValue >= self._Data._Cost then
			GUI.SetText(self._Lab_Cost_Num, tostring(self._Data._Cost))
		else
			GUI.SetText(self._Lab_Cost_Num, "<color=#ff412d>" .. self._Data._Cost .. "</color>")
		end			
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- 当点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Cancel" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Sure" then
		self:OnBtnSure()
	end
end

-- 点击确定按钮
def.method().OnBtnSure = function(self)
	local moneyValue = game._GuildMan:GetMoneyValueByTid(self._Data._Tid)
	local name = self._InputField_Name.text
	if GUITools.CheckName(name) then
		if self._Data._Cost > moneyValue then
			game._GUIMan:ShowTipText(StringTable.Get(813), true)
			return
		end
		if self._Data._Min ~= nil then
			if GameUtil.GetStringLength(name) < self._Data._Min then
				game._GUIMan:ShowTipText(StringTable.Get(26), true)	
				return
			end
		end
		if self._Data._Max ~= nil then
			if GameUtil.GetStringLength(name) > self._Data._Max then
				game._GUIMan:ShowTipText(StringTable.Get(27), true)
				return
			end
		end
		if self._Data._Callback ~= nil then
			self._Data._Callback(name)
		end
	end
end

CPanelUIRename.Commit()
return CPanelUIRename