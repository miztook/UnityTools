local Lplus = require "Lplus"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"

local CFrameCurrency = Lplus.Class("CFrameCurrency")
local def = CFrameCurrency.define

def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("userdata")._Item_template = nil
def.field("function")._OnCurrencyChange = nil
def.field("number")._OnCurLayoutStyle = -1
def.field("table")._ItemTable = BlankTable

def.static("table", "userdata", "number", "=>", CFrameCurrency).new = function(parent, panel, layoutStyle)
	local frameCurrency = CFrameCurrency()        
	frameCurrency._Panel = panel
	frameCurrency._Parent = parent
    frameCurrency:Init(layoutStyle)
	frameCurrency:Update()
	return frameCurrency
end


def.method("number").Init = function(self, layoutStyle)
	if self._OnCurLayoutStyle == layoutStyle then return end
	if #self._ItemTable > 0 then 
		for i,v in pairs(self._ItemTable) do 
			Object.Destroy(v)
		end
	end
	self._ItemTable = {}
	self._OnCurLayoutStyle = layoutStyle
	local  uiTemplate = self._Panel:GetComponent(ClassType.UITemplate)

	self._Item_template = uiTemplate:GetControl(0)
	self._Item_template:SetActive(false)
	for i,k in pairs(EnumDef.MoneyType[self._OnCurLayoutStyle]) do
		local Moneyobj = GameObject.Instantiate(self._Item_template)
		if not IsNil(Moneyobj) then
			Moneyobj:SetParent(self._Panel, false)
			-- Moneyobj.localScale = Vector3.one
			-- Moneyobj.localRotation = Vector3.zero
			Moneyobj:SetActive(true)
			local Btn_AddMoney = Moneyobj:FindChild("Btn_AddMoney")
			Btn_AddMoney.name = "Btn_AddMoney" .. k	
			Moneyobj.name = k
			GUITools.RegisterButtonEventHandler(self._Parent._Panel, Btn_AddMoney)
			self._ItemTable[#self._ItemTable + 1] = Moneyobj
		end
	end
    if self._OnCurrencyChange == nil then
    	self._OnCurrencyChange = function(sender, event)
	    	self:Update()
	    end
	    CGame.EventManager:addHandler('NotifyMoneyChangeEvent', self._OnCurrencyChange)
    end
end

-- 更新货币
def.method().Update = function(self)  
	local hp = game._HostPlayer
	for _,k in pairs(EnumDef.MoneyType[self._OnCurLayoutStyle]) do
		for i,v in pairs(self._ItemTable) do 
			if tonumber(v.name) == k then
				local Lab_MoneyNum = v:FindChild("Lab_MoneyNum")
				local Img_MoneyIcon = v:FindChild("Img_MoneyIcon")
				GUITools.SetTokenMoneyIcon(Img_MoneyIcon, k)
				GUI.SetText(Lab_MoneyNum, GUITools.FormatMoney(hp:GetMoneyCountByType(k)))
			end
		end
	end
end

def.method("string", "=>", "boolean").OnClick = function(self,id)
	if string.find(id, "Btn_AddMoney") then
		local MoneyID = tonumber(string.sub(id, string.len("Btn_AddMoney")+1,-1))
		local MoneyData = CElementData.GetTemplate("Money", MoneyID)
		if MoneyData and MoneyData.OpenPanelId ~= 0 then
			game._AcheivementMan:DrumpToRightPanel(MoneyData.OpenPanelId, 0)
		end
		return true
	else
		return false
	end
end

def.method().Destroy = function (self)
	if self._OnCurrencyChange ~= nil then
	    CGame.EventManager:removeHandler('NotifyMoneyChangeEvent', self._OnCurrencyChange)
    	self._OnCurrencyChange = nil
    end
	self._Panel = nil
	self._Item_template = nil
	self._OnCurLayoutStyle = 0
	self._ItemTable = {}
end

CFrameCurrency.Commit()
return CFrameCurrency