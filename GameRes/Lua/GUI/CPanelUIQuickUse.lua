local Lplus = require 'Lplus'
local CGame = Lplus.ForwardDeclare("CGame")
local net = require "PB.net"
local CPanelBase = require 'GUI.CPanelBase'
local SendUseItemEvent = require "Events.SendUseItemEvent"
local QuestCommonEvent = require "Events.QuestCommonEvent"
local CElementData = require "Data.CElementData"
local PackageChangeEvent = require "Events.PackageChangeEvent"
local CPageBattle = require"GUI.CPageBattle"

local CPanelUIQuickUse = Lplus.Extend(CPanelBase, 'CPanelUIQuickUse')
local def = CPanelUIQuickUse.define

def.field('userdata')._Frame_QuickUse = nil
def.field('userdata')._Lab_Use = nil
def.field('userdata')._Img_Tag_Arrow = nil
def.field('userdata')._Lab_ItemName = nil

def.field('table')._QuickUseItems = BlankTable
def.field('boolean')._IsShowQuickUse = false

local instance = nil
def.static('=>', CPanelUIQuickUse).Instance = function ()
    if not instance then
        instance = CPanelUIQuickUse()
        instance._PrefabPath = PATH.UI_QuickUse
        instance._PanelCloseType = EnumDef.PanelCloseType.None
        instance._DestroyOnHide = false
        instance:SetupSortingParam()
	end
	return instance
end

local OnSendUseItemEvent = function(sender, event)
	if not instance then return end
	for _,v in pairs(instance._QuickUseItems) do
		if v.Index == event._Slot and v.ItemId == event._Tid then
            instance:QuickUseOnBtnClose()
        end
	end
end

local OnPackageChangeEvent = function (sender, event)
	if not instance then return end
	if event.PackageType == net.BAGTYPE.BACKPACK then
		if #instance._QuickUseItems == 0 then return end
		-- warn("lidaming event instance._QuickUseItems", #instance._QuickUseItems , event.PackageType)
    	instance:QuickUseListRefresh()
	end
end

local function sortfunction(item1, item2)
	-- Item是否为空
	if item1 ~= nil and item2 == nil then
        return true
    elseif item1 == nil and item2 ~= nil then
        return false
	end
	
	-- Item同为任务物品
	if item1.IsQuestItem == item2.IsQuestItem then
		return false
	end

	-- Item任务物品 > 普通物品
	if item1.IsQuestItem and not item2.IsQuestItem then
		return false
	else
		return true
	end
end

local function OnQuestEvents(sender, event)	
	local name = event._Name
	local data = event._Data
	if name == EnumDef.QuestEventNames.QUEST_RECIEVE then		--接任务时，刷新一下快捷使用物品列表
		-- warn("CPageQuest -> EventName = EnumDef.QuestEventNames.QUEST_RECIEVE ")
		instance:QuickUseListRefresh()
	end
end

def.override("dynamic").OnData = function(self, data)
    CPanelBase.OnData(self,data)
end

def.override().OnCreate = function(self)    
	self._Frame_QuickUse = self:GetUIObject('Frame_QuickUse')
	self._Lab_Use = self:GetUIObject("Lab_Use")
	self._Img_Tag_Arrow = self:GetUIObject("Img_Tag_ArrowUp")
	self._Lab_ItemName = self:GetUIObject("Lab_ItemName")
	self._QuickUseItems = {}
	self._IsShowQuickUse = false
	CGame.EventManager:addHandler(SendUseItemEvent,OnSendUseItemEvent)
    CGame.EventManager:addHandler('QuestCommonEvent', OnQuestEvents)
	CGame.EventManager:addHandler(PackageChangeEvent,OnPackageChangeEvent)
	self._Frame_QuickUse:SetActive(false)

end

def.static('table', 'table', '=>', 'boolean').IsProbableBetterEquip = function (newItemData, oldItemData)
	--同职业同部位装备,属性条目和类型一致,并且各条目属性和谐变化
	local newVal = newItemData:GetFightScore()
	local oldVal = oldItemData:GetFightScore()
	if newVal > oldVal then
		-- warn("属性高于现有装备", newVal, oldVal)
		return true
	end

	--战斗力裸值判断
	return newItemData:GetFightScore() > oldItemData:GetFightScore()
end

def.method('table').QuickUseTipAddNewItem = function(self, itemUpdateInfo)
	--warn("-----------------lidaming QuickUseTipAddNewItem ------------------", #self._QuickUseItems)
	if not self:IsShow() then return end
	-- if self._QuickUseItems == nil then return end
	local normalPack = nil
	if itemUpdateInfo.BagType == net.BAGTYPE.QUESTPACK then
		normalPack = game._HostPlayer._Package._TaskItemPack
	else
		normalPack = game._HostPlayer._Package._NormalPack
	end	
	local itemData = normalPack:GetItemBySlot(itemUpdateInfo.Index)
	-- warn("itemData == ", itemUpdateInfo.Index)
	if itemData == nil then return end
	-- warn("lidaming itemData == ", itemData._Template.IsPopupShortcut , itemData:CanUse())
    -- warn("lidaming itemData CanUse == ", itemData:CanUse())
	if itemData:CanUse() ~= EnumDef.ItemUseReason.Success then return end
	if itemData:IsEquip() then
		local equipSlot = itemData._EquipSlot
		local equipPack = game._HostPlayer._Package._EquipPack
		local curEquipItemData = equipPack:GetItemBySlot(equipSlot)

		if curEquipItemData and curEquipItemData._Tid > 0 then			
			--身上有装备 判断战力
			if not CPanelUIQuickUse.IsProbableBetterEquip(itemData, curEquipItemData) then return end
		end
	end
	self:QuickUseListPush(itemUpdateInfo)	
end

def.method().QuickUseListSort = function(self)	
	local CQuest = require "Quest.CQuest"
	local questUseItemIds = CQuest.Instance():GetQuestUseItemIDs()
	for i,k in ipairs(self._QuickUseItems) do
		for _,v in ipairs(questUseItemIds) do 			
			if v == k.ItemId then
				k.IsQuestItem = true
			else
				k.IsQuestItem = false
			end					
		end
	end
	-- warn("lidaming QuickUseListSort self._QuickUseItems", #self._QuickUseItems )
	table.sort(self._QuickUseItems , sortfunction)	
	self:QuickUseListRefresh()
end

def.method('table').QuickUseListPush = function(self, item)	
	local itemElement = CElementData.GetTemplate("Item", item.ItemId)
	-- warn("lidaming item.Count == ", item.Count, itemElement.PileLimit)
	if item.Count > itemElement.PileLimit then
		local param = 
		{
			ItemId = item.ItemId,
			Index = item.Index,
			Count = itemElement.PileLimit,
			ItemSrc = item.Src,
			IsQuestItem = false
		}
		-- warn("lidaming v.Count == ", v.Count , itemElement.PileLimit)
		table.insert(self._QuickUseItems, param)	
	else
		table.insert(self._QuickUseItems, item)		
	end
	-- warn("lidaming QuickUseListPush self._QuickUseItems == ", #self._QuickUseItems)
	self:QuickUseListSort()
	-- self:QuickUseListRefresh()
end

def.method().QuickUseListPop = function(self)
	table.remove(self._QuickUseItems, #self._QuickUseItems)
	-- warn("lidaming QuickUseListPop ---->>> #self._QuickUseItems == ",  #self._QuickUseItems)
end


def.method().UseTopItem = function(self)
	-- if #self._QuickUseItems == 0 then return end
	-- warn("#self._QuickUseItems ==", #self._QuickUseItems)
	local item = self._QuickUseItems[#self._QuickUseItems]
	local normalPack = nil
	if item.BagType == net.BAGTYPE.QUESTPACK then
		normalPack = game._HostPlayer._Package._TaskItemPack
	else
		normalPack = game._HostPlayer._Package._NormalPack
	end
	local itemData = normalPack:GetItemBySlot(item.Index)
	if not itemData then return end
	if itemData._Tid == 0 then return end
	-- warn("lidaming itemData.IsEquip == ", itemData:IsEquip())
	-- 当前使用物品是装备，并且在战斗状态中，不可使用。     -- 暂时不限制  2018/09/19  lidaming
	-- if itemData:IsEquip() and game._HostPlayer:IsInServerCombatState() then
	-- 	game._GUIMan:ShowTipText( StringTable.Get(139), false)
	-- 	return
	-- 当前使用物品是装备，并且在无畏战场匹配中，不可使用。
	if itemData:IsEquip() and game._CArenaMan._IsMatchingBattle then 
		game._GUIMan: ShowTipText(StringTable.Get(27004), false)
		return
	else
		itemData:Use()
		self:QuickUseListRefresh()
	end
	
end

def.method().QuickUseOnBtnUse = function(self)
	-- warn("QuickUseOnBtnUse")
	self:UseTopItem()	
end

def.method().QuickUseOnBtnClose = function(self)
	-- warn("QuickUseOnBtnClose")
	self:QuickUseListPop()
	if #self._QuickUseItems == 0 then
		self._Frame_QuickUse:SetActive(false)
		self._IsShowQuickUse = false
	else
		self:QuickUseListRefresh()
	end
end

-- 刷新快捷使用列表
def.method().QuickUseListRefresh = function(self)	
	-- warn("lidaming QuickUseListRefresh", #self._QuickUseItems)
	local item = self._QuickUseItems[#self._QuickUseItems]
	if not item then return end
	local normalPack = nil
	if item.BagType == net.BAGTYPE.QUESTPACK then
		normalPack = game._HostPlayer._Package._TaskItemPack
	else
		normalPack = game._HostPlayer._Package._NormalPack
	end
	local itemData = normalPack:GetItemBySlot(item.Index)  --CIvtrItem
	if itemData == nil then
		for i = #self._QuickUseItems , 1 ,-1 do
			if self._QuickUseItems[i].Index == item.Index then
				-- warn("lidaming ---------------->>> remove ==", i)
				table.remove(self._QuickUseItems, i)
				if #self._QuickUseItems == 0 then
					self:QuickUseOnBtnClose()
				end
			end
		end	
		return	
	end
	if not IsNil(self._Frame_QuickUse) then
		self._Frame_QuickUse:SetActive(true)
		self._IsShowQuickUse = true
	end

	local useStr = nil
	if itemData:IsEquip() then
		useStr = StringTable.Get(11100)
		self._Img_Tag_Arrow:SetActive(true)
	else
		useStr = StringTable.Get(11105)
		self._Img_Tag_Arrow:SetActive(false)
	end
	GUI.SetText(self._Lab_Use, useStr)

	local itemObj = self:GetUIObject('ItemIconNew')
	if IsNil(itemObj) then 
		warn("QuickUseItem GetUIObject: Item Is Nil")
	return end
	-- GUITools.SetItem(itemObj, item.ItemId, item.Count, nil, itemData:IsBind())
	local setting =
    {
        [EItemIconTag.Bind] = itemData:IsBind(),
		[EItemIconTag.Number] = item.Count,
		[EItemIconTag.ArrowUp] = true,
    }
	IconTools.InitItemIconNew(itemObj, item.ItemId, setting)
	GUI.SetText(self._Lab_ItemName, itemData._Template.TextDisplayName)
	--获得道具飞行
	--[[
	local itemTips = GameObject.Instantiate(itemObj)
	
	if not IsNil(itemTips) then
		itemTips: SetParent(itemObj)
		itemTips.localPosition = Vector3.zero
		itemTips.localScale = Vector3.one
		GUITools.SetItem(itemTips, item.ItemId, item.Count, nil, itemData:IsBind())
		itemTips: SetActive(true)

		local endPos = Vector3.New(249,390,0)
		GUITools.DoLocalMove(itemTips,endPos,0.8, nil,function()
 			itemTips:Destroy()
   	 	end)
	end
	]]
end

def.method().ShowTopItemTip = function(self)
	local item = self._QuickUseItems[#self._QuickUseItems]
	local normalPack = nil
	if item.BagType == net.BAGTYPE.QUESTPACK then
		normalPack = game._HostPlayer._Package._TaskItemPack
	else
		normalPack = game._HostPlayer._Package._NormalPack
	end
	local itemData = normalPack:GetItemBySlot(item.Index)
	if not itemData then return end
	if item.ItemId ~= itemData._Tid then return end
	if itemData._Tid == 0 then return end
	-- itemData:ShowTip()
	-- itemData:ShowTip(TipPosition.FIX_POSITION,self._Frame_QuickUse)
	if itemData:IsEquip() then 
		CItemTipMan.ShowPackbackEquipTip(itemData, TipsPopFrom.WithoutButton,TipPosition.FIX_POSITION,self._Frame_QuickUse)
	else
		CItemTipMan.ShowPackbackItemTip(itemData, TipsPopFrom.WithoutButton,TipPosition.FIX_POSITION,self._Frame_QuickUse)
	end
end

def.override('string').OnClick = function(self, id)
    CPanelBase.OnClick(self, id)
	if id == 'Btn_Use' then
		if game._CGuideMan:IsQuickGuide() then return end
		self:QuickUseOnBtnUse()
	elseif id == 'Btn_Close' then
		self:QuickUseOnBtnClose()
	elseif id == 'ItemIconNew' then
		self:ShowTopItemTip()
	end
end

def.override().OnDestroy = function(self)
	CGame.EventManager:removeHandler(SendUseItemEvent,OnSendUseItemEvent)
    CGame.EventManager:removeHandler('QuestCommonEvent', OnQuestEvents)
	CGame.EventManager:removeHandler(PackageChangeEvent, OnPackageChangeEvent)
	self._Frame_QuickUse = nil
	self._IsShowQuickUse = false
	self._Img_Tag_Arrow = nil
end

CPanelUIQuickUse.Commit()
return CPanelUIQuickUse