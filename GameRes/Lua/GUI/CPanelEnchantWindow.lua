
local Lplus = require 'Lplus'
local CPanelBase = require 'GUI.CPanelBase'
local CElementData = require "Data.CElementData"

local CPanelEnchantWindow = Lplus.Extend(CPanelBase, 'CPanelEnchantWindow')
local def = CPanelEnchantWindow.define

def.field("userdata")._LabNewValue = nil 
def.field("userdata")._LabOldValue = nil 
def.field("userdata")._LabTip = nil 
def.field("table")._EnchantItemData = nil 
def.field("table")._EquipData = nil 
def.field("userdata")._Item = nil

local instance = nil
def.static('=>', CPanelEnchantWindow).Instance = function ()
	if not instance then
        instance = CPanelEnchantWindow()
        instance._PrefabPath = PATH.UI_EnchantWindow
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = true
        instance:SetupSortingParam()
        -- TO DO
	end
	return instance
end
 
def.override().OnCreate = function(self)
	self._LabNewValue = self:GetUIObject("Lab_NewValue")
	self._LabOldValue = self:GetUIObject("Lab_OldlValue")
	self._LabTip = self:GetUIObject("Lab_Tip")
	self._Item = self:GetUIObject("Item")
end

-- local PanelData = 
-- 				{
-- 					EquipData = itemData,
-- 					EnchantItemData = 附魔物品data,
-- 					EnchantInfo = EnchantData,
-- 				}
def.override("dynamic").OnData = function(self, data)
	local equipName =  "<color=#" .. EnumDef.Quality2ColorHexStr[data.EquipData._Quality] ..">" .. data.EquipData._Name .."</color>"
	local itemName = "<color=#" .. EnumDef.Quality2ColorHexStr[data.EnchantItemData._Quality] ..">" .. data.EnchantItemData._Name .."</color>"
	GUI.SetText(self._LabTip,string.format(StringTable.Get(10978),equipName,itemName))
	self._EnchantItemData = data.EnchantItemData
	self._EquipData = data.EquipData
    local value  = tonumber(data.EnchantInfo.Property.ValueDesc)
  	if self._EquipData._EnchantAttr == nil or self._EquipData._EnchantAttr.index == 0 then
    	GUI.SetText(self._LabOldValue,StringTable.Get(10980)) 
    else
    	local fightElement = CElementData.GetPropertyInfoById(self._EquipData._EnchantAttr.index)
    	GUI.SetText(self._LabOldValue,string.format(StringTable.Get(10979),fightElement.Name,tostring(self._EquipData._EnchantAttr.value)))
    end
    GUI.SetText(self._LabNewValue,string.format(StringTable.Get(10979),data.EnchantInfo.Property.Name,tostring(value)))

	local frame_item_icon = GUITools.GetChild(self._Item, 0)
    local bShowArrowUp = false
	local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
	if profMask == bit.band(self._EquipData._ProfessionMask, profMask) then
		for _, v in ipairs(game._HostPlayer._Package._EquipPack._ItemSet) do
			if v._Tid ~= 0 then
				if v._EquipSlot == self._EquipData._EquipSlot then
					local equipedFight = v:GetFightScore()
					local curFight = self._EquipData:GetFightScore()
					if equipedFight < curFight then
						bShowArrowUp = true
					end
					break
				end
			end
		end
	end
	local inforceLv = self._EquipData:GetInforceLevel()
	local refineLv = self._EquipData:GetRefineLevel()
	local icon_setting = {
		            [EItemIconTag.Bind] = self._EquipData:IsBind(),
					[EItemIconTag.Number] = self._EquipData:GetCount(),
					[EItemIconTag.New] = self._EquipData._IsNewGot,
					[EItemIconTag.StrengthLv] = inforceLv,
					[EItemIconTag.Refine] = refineLv,
					[EItemIconTag.ArrowUp] = bShowArrowUp,
					[EItemIconTag.Enchant] = self._EquipData._EnchantAttr ~= nil and self._EquipData._EnchantAttr.index ~= 0,
		        }
	IconTools.InitItemIconNew(frame_item_icon, self._EquipData._Tid, icon_setting, EItemLimitCheck.AllCheck)
	IconTools.SetLimit(frame_item_icon, self._EquipData._Tid, EItemLimitCheck.AllCheck)
end

def.override('string').OnClick = function(self, id)	
	if id == "Btn_Ok" then
		self._EnchantItemData:RealUse()
		game._GUIMan:CloseByScript(self)
	elseif id == "Btn_Cancel" then 
		game._GUIMan:CloseByScript(self)
	elseif id == "Img_ItemIcon" then 
		self._EquipData:ShowTipWithFuncBtns(TipsPopFrom.ROLE_PANEL,TipPosition.DEFAULT_POSITION,nil,nil)
	end
end

def.override().OnDestroy = function(self)
	instance = nil 
end

CPanelEnchantWindow.Commit()
return CPanelEnchantWindow