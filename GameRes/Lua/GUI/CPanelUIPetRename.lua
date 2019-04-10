local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CPanelUIPetRename = Lplus.Extend(CPanelBase, "CPanelUIPetRename")
local def = CPanelUIPetRename.define

def.field("userdata")._InputField_Name = nil
def.field("userdata")._Img_Money = nil
def.field("userdata")._Lab_Cost_Num = nil
def.field("userdata")._Lab_Cost = nil

-- _Name:原名称,可为空;_Min:最小值,可为空;_Max:最大值，可为空,;_Tid:货币Tid;_Cost:修改花费;_Callback:回调
def.field("table")._Data = nil

local instance = nil
def.static("=>", CPanelUIPetRename).Instance = function()
	if not instance then
		instance = CPanelUIPetRename()
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
	self._Lab_Cost = self:GetUIObject('Lab_Cost')

	GUI.SetText(self:GetUIObject("InputField_Name"):FindChild("Placeholder"), StringTable.Get(19061))	
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Data = data
	if self._Data._Name ~= nil then
		self._InputField_Name.text = self._Data._Name
	end

	self._Lab_Cost:SetActive(self._Data._Cost ~= nil)

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

def.override("string").OnClick = function(self, id)
	if id == "Btn_Cancel" then
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Sure" then
		self:OnBtnSure()
		game._GUIMan:CloseByScript(self)
	end
end

def.method().OnBtnSure = function(self)
	local name = self._InputField_Name.text
	if GUITools.CheckName(name) then
		if self._Data._Callback ~= nil then
			self._Data._Callback(name)
		end
	end
end

def.override().OnDestroy = function(self)
	instance = nil
end

CPanelUIPetRename.Commit()
return CPanelUIPetRename