--
-- 月光庭院事件
--
--【孟令康】
--
-- 2018年1月23日
--

local Lplus = require "Lplus"
local CPanelBase = require "GUI.CPanelBase"
local CElementData = require "Data.CElementData"
local CPanelUIGuildPrayEvent = Lplus.Extend(CPanelBase, "CPanelUIGuildPrayEvent")
local def = CPanelUIGuildPrayEvent.define

def.field("table")._Data = nil

def.field("userdata")._List_Type = nil
def.field("userdata")._List_MenuType = nil
def.field("userdata")._Lab_Remind = nil

local instance = nil
def.static("=>", CPanelUIGuildPrayEvent).Instance = function()
	if not instance then
		instance = CPanelUIGuildPrayEvent()
		instance._PrefabPath = PATH.UI_Guild_PrayEvent
		instance._PanelCloseType = EnumDef.PanelCloseType.None
		instance._DestroyOnHide = true
        instance:SetupSortingParam()
	end
	return instance
end

-- 当创建
def.override().OnCreate = function(self)
	self._List_Type = self:GetUIObject("List_Type")
	self._List_MenuType = self:GetUIObject("List_MenuType"):GetComponent(ClassType.GNewListLoop)
	self._Lab_Remind = self:GetUIObject("Lab_Remind")
end

-- 当数据
def.override("dynamic").OnData = function(self, data)
	self._Data = data
	local count = #self._Data
	if count == 0 then
		self._List_Type:SetActive(false)
		self._Lab_Remind:SetActive(true)
	else
		self._List_Type:SetActive(true)
		self._List_MenuType:SetItemCount(count)
		self._Lab_Remind:SetActive(false)
	end
end

-- 当摧毁
def.override().OnDestroy = function(self)
	instance = nil
end

-- Button点击
def.override("string").OnClick = function(self, id)
	if id == "Btn_Back" then
		game._GUIMan:CloseByScript(self)
	end
end

-- 初始化列表
def.override("userdata", "string", "number").OnInitItem = function(self, item, id, index)
	index = index + 1
	local uiTemplate = item:GetComponent(ClassType.UITemplate)
	if id == "List_MenuType" then	
		local data = self._Data[index]
		local guildMan = game._GuildMan
		GUI.SetText(uiTemplate:GetControl(0), guildMan:GetServerTimeDes(data.OptTime))
		local item = CElementData.GetTemplate("Item", data.ItemTID)
		local prayItem = CElementData.GetTemplate("GuildPrayItem", item.PrayId)
		local helperName = RichTextTools.GetElsePlayerNameRichText(data.HelperName, false)
		local itemName = RichTextTools.GetItemNameRichText(data.ItemTID, 1, false)
		local timeDes = RichTextTools.GetEventTimeRichText(guildMan:GetTimeDes(prayItem.DecTime), false)
		local des = string.format(StringTable.Get(8038), helperName, itemName, timeDes)
		GUI.SetText(uiTemplate:GetControl(1), des)
	end
end

CPanelUIGuildPrayEvent.Commit()
return CPanelUIGuildPrayEvent