local Lplus = require "Lplus"
local NotifyMoneyChangeEvent = require "Events.NotifyMoneyChangeEvent"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"

local CFrameCurrency = Lplus.Class("CFrameCurrency")
local def = CFrameCurrency.define

--def.field("table")._Parent = nil
def.field("userdata")._Panel = nil
def.field("userdata")._Item_template = nil
-- def.field("userdata")._Lab_Gold = nil
-- def.field("userdata")._Lab_Diamond = nil
-- def.field("userdata")._Lab_Diamond_Lock = nil
-- def.field("userdata")._Lab_Diamond_Green = nil
def.field("function")._OnCurrencyChange = nil
def.field("number")._OnCurLayoutStyle = -1
def.field("table")._ItemTable = BlankTable

def.static("table", "userdata", "number", "=>", CFrameCurrency).new = function(parent, panel, layoutStyle)
	local frameCurrency = CFrameCurrency()        
	frameCurrency._Panel = panel
	--frameCurrency._Parent = parent
    frameCurrency:Init(layoutStyle)
	frameCurrency:Update()
	return frameCurrency
end


def.method("number").Init = function(self, layoutStyle)
	if self._OnCurLayoutStyle == layoutStyle then return end
	if #self._ItemTable > 0 then 
		for i,v in pairs(self._ItemTable) do 
			Object.DestroyImmediate(v)
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
			self._ItemTable[#self._ItemTable + 1] = Moneyobj			
			-- GUITools.RegisterButtonEventHandler(self._Panel, Moneyobj)						
		end
	end
    -- self._Lab_Gold = uiTemplate:GetControl(0)   --"Lab_Gold"
    -- self._Lab_Diamond =uiTemplate:GetControl(2) --"Lab_Diamond"
    -- self._Lab_Diamond_Lock = uiTemplate:GetControl(4) --"Lab_Diamond_Lock"
    -- self._Lab_Diamond_Green = uiTemplate:GetControl(6)
    if self._OnCurrencyChange == nil then
    	self._OnCurrencyChange = function(sender, event)
	    	self:Update()
	    end
	    CGame.EventManager:addHandler('NotifyMoneyChangeEvent', self._OnCurrencyChange)
    end
end

-- 更新货币
def.method().Update = function(self)  
	-- if self._Lab_Gold == nil or self._Lab_Diamond == nil or self._Lab_Diamond_Lock == nil or self._Lab_Diamond_Green == nil then
	-- 	warn("CFrameCurrency", debug.traceback())
	-- 	return
	-- end
	local hp = game._HostPlayer
	for _,k in pairs(EnumDef.MoneyType[self._OnCurLayoutStyle]) do
		for i,v in pairs(self._ItemTable) do 
			if tonumber(v.name) == k then
				local Lab_MoneyNum = v:FindChild("Lab_MoneyNum")
				local Img_MoneyIcon = v:FindChild("Img_MoneyIcon")
				local Img_AddMoneyIcon = v:FindChild("Btn_AddMoney" .. k .."/Img_AddMoneyIcon")
				if Img_AddMoneyIcon ~= nil then
					Img_AddMoneyIcon:SetActive(false)
				else
					Img_AddMoneyIcon = v:FindChild("Img_AddMoneyIcon")
					Img_AddMoneyIcon:SetActive(false)
				end
				GUITools.SetTokenMoneyIcon(Img_MoneyIcon, k)
				GUI.SetText(Lab_MoneyNum, GUITools.FormatMoney(hp:GetMoneyCountByType(k)))
			end
		end
	end
end

def.method("string", "=>", "boolean").OnClick = function(self,id)
	-- if id == "Btn_Gold" then
	-- 	TODO(StringTable.Get(19))
	-- 	return true
	-- elseif id == "Btn_Diamond" then
	-- 	TODO(StringTable.Get(19))
	-- 	return true
	-- elseif id == "Btn_Diamond_Lock" then
	-- 	TODO(StringTable.Get(19))
	-- 	return true
    -- elseif id == "Btn_Diamond_Green" then
    --     TODO(StringTable.Get(19))
	-- 	return true
	-- else
	if string.find(id, "Btn_AddMoney") then
		local MoneyID = tonumber(string.sub(id, string.len("Btn_AddMoney")+1,-1))   
		TODO(StringTable.Get(19))
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

    -- self._Lab_Gold = nil
    -- self._Lab_Diamond = nil
    -- self._Lab_Diamond_Lock = nil
    -- self._Lab_Diamond_Green = nil
	self._Panel = nil
	self._Item_template = nil
	self._OnCurLayoutStyle = 0
	self._ItemTable = {}
end

CFrameCurrency.Commit()
return CFrameCurrency