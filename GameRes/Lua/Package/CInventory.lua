local Lplus = require "Lplus"
local CIvtrItems = require "Package.CIvtrItems"
local CIvtrItem = CIvtrItems.CIvtrItem
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local PBHelper = require "Network.PBHelper"
local CInventory = Lplus.Class("CInventory")
local def = CInventory.define

def.field("table")._ItemSet = nil
def.field("number")._PackageType = -1
def.field("number")._EffectSize = 0 --CurrentUnlockNum 当前开启的格子个数

def.static("number", "=>", CInventory).new = function(type)
    local inventory = CInventory()
	inventory._ItemSet = { }
	inventory._PackageType = type		--value of IVTRTYPE_ENUM
	return inventory
end

def.virtual("=>", "boolean").IsNormalPack = function (self)
	return self._PackageType == IVTRTYPE_ENUM.IVTRTYPE_PACK
end

def.virtual("=>", "boolean").IsStoragePack = function (self)
	return self._PackageType == IVTRTYPE_ENUM.IVTRTYPE_STORAGE
end

def.virtual("=>", "boolean").IsTaskItemPack = function (self)
	return self._PackageType == IVTRTYPE_ENUM.IVTRTYPE_TASKITEM
end

def.method("=>","boolean").IsFull = function (self)
	if self._ItemSet == nil then return false end
	local count = 0
	for k,v in pairs(self._ItemSet) do
		if v ~= nil and v._Tid ~= 0 then count = count + 1 end
	end

	return count >= self._EffectSize
end

--获取物品使用或是其他用途 先获取堆叠少的
def.method("number", "=>", CIvtrItem).GetItem = function (self, tid)
	local ItemSet = self._ItemSet
	local count,index = 0,0
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		if item and item._Tid == tid then
			if count == 0 then 
				count = item._NormalCount 
				index = i
			end
			if count > item._NormalCount then 
				index = i
				count = item._NormalCount
			end
		end
	end
	if index == 0 then 
		return nil
	else
		return ItemSet[index]
	end
end

def.method("number", "=>", "table").GetItems = function (self, tid)
	local ItemSet = self._ItemSet
	local res = {}
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		if item and item._Tid == tid then
			res[item._Slot] = item
		end
	end

	return res
end

def.method("number", "=>", "table").GetItemBySlot = function (self, slot)
	local ItemSet = self._ItemSet
	for _, v in ipairs(ItemSet) do
		if v._Slot == slot then
			return v
		end
	end

	return nil
end

--通过服务器位置索引 获取单个item堆叠个数
def.method("number", "=>", "number").GetItemCountBySlot = function(self, slot)
	local nRet = 0
	local item = self:GetItemBySlot(slot)
	if item ~= nil then
		nRet = item._NormalCount
	end

	return nRet
end

def.method("number", "=>", "number").GetItemCount = function (self, tid)
	local total = self._EffectSize
	local ItemSet = self._ItemSet
	
	local count = 0
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		if item and item._Tid == tid then
			count = count + item._NormalCount
		end
	end
	
	return count
end

-- 获取包中某一类物品物品列表
def.method("number","=>","table").GetItemListByType = function(self,ItemType)
	local itemSet = self._ItemSet
	local itemList = {}
	for i = 1, #itemSet do
		local item = itemSet[i]
		if item and item._ItemType == ItemType then
			table.insert(itemList,item)
		end
	end
	return itemList
end

--index是背包index 从1开始
def.method("number", "=>", "number").GetItemServerIndex = function(self, index)
	if index > self._EffectSize then
		return -1
	end

	return self._ItemSet[index]._Slot
end

def.method("=>", "boolean").HasEmptySpace = function(self)
	if self:GetEmptySlotNum() then
		return true
	else
		return false
	end
end

def.method("number", "boolean", "=>", "table").GetItemIndexs = function(self, tid, bIsBand)
	local idtable = {}
	for i=1, #self._ItemSet do
		local itemData = self._ItemSet[i]
		if itemData._Tid == tid and itemData._IsBind == bIsBand then
			idtable[#idtable + 1] = i
		end
	end
	return idtable
end

def.method("number", "boolean", "=>", "table").GetItemList = function(self, tid, bIsBand)
	local itemtable = {}
	for i=1, #self._ItemSet do
		local itemData = self._ItemSet[i]
		if itemData._Tid == tid and itemData._IsBind == bIsBand then
			itemtable[#itemtable + 1] = itemData
		end
	end
	return itemtable
end

def.method("number", "boolean", "number", "=>", "boolean").HasEnoughSpace = function(self, tid, bIsBand, count)
	local itemElement = CElementData.GetTemplate("Item", tid)
	if itemElement == nil then
		return false
	end
	local pileLimit = itemElement.PileLimit

	if pileLimit == 1 then
		local emptySlotNum = self:GetEmptySlotNum()
		if emptySlotNum < count then
			return false
		else
			return true
		end
	else
		local temp = count
		local idtable = self:GetItemIndexs(tid, bIsBand)
		for i,v in ipairs(idtable) do
			temp = temp - (pileLimit - self._ItemSet[v]._NormalCount )
			if temp <= 0 then
				return true
			end
		end

		local needEmptyCellNum = math.ceil(temp/pileLimit)
		local currentEmptyCellNum = self:GetEmptySlotNum()
		if currentEmptyCellNum >= needEmptyCellNum then
			return true
		else
			return false
		end		
	end
end

--[[
	查找包裹中的第一个空格子，如果没有 返回-1
]]
def.method("=>", "number").SearchEmpty = function (self)
	local ItemSet = self._ItemSet
	local total = self._EffectSize
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		
		if item == nil or item._Tid == 0 then
			return i
		end
	end
	
	return -1
end

--[[
	包裹中空格数量
]]
def.method("=>", "number").GetEmptySlotNum = function (self)
	local count = #self._ItemSet
	local total = self._EffectSize

	return total - count
end

def.static("table", "=>", CIvtrItem).CreateItem = function(bagCellDB)
	local tid = bagCellDB.ItemData.Tid
	if tid == 0 then
		return CIvtrItems.CIvtrUnknown.new(bagCellDB)
	end

	local template = CElementData.GetTemplate("Item", tid)
	if template == nil then
		return CIvtrItems.CIvtrUnknown.new(bagCellDB)
	end

	local item_type = template.ItemType

	local pItem = nil
	local class = CIvtrItems.ItemTypeToClass[item_type]
	if class ~= nil then
		pItem = class.new(bagCellDB)
	else
		pItem = CIvtrItems.CIvtrUnknown.new(bagCellDB)
	end

	return pItem
end

local function sortfunction(item1, item2)
	if item1._Tid == 0 then
		return false
	end
	if item2._Tid == 0 then
		return true
	end
end

def.method(CIvtrItem).UpdateItem = function(self, item)
	if item == nil then return end

	if self._ItemSet == nil then
		self._ItemSet = {}
	end
	-- 未新开格子 不显示new
	local index = 0
	for i, v in ipairs(self._ItemSet) do
		if v._Slot == item._Slot then
			index = i
			item._IsNewGot = false
			break
		end
	end

	-- 新开了一个格子(先判断来源然后判断是否新开了一个格子)
	if index == 0 then
		index = #self._ItemSet + 1
	end

	self._ItemSet[index] = item
	--如果为空item，从本地列表中移除 , 暂时只有普通背包需要删除操作 
	--【装备背包是对应的8个，不能被删除】
	if item._Tid == 0 and self:IsNormalPack() then
		table.remove(self._ItemSet, index)
	end
	if item._Tid == 0 and self:IsStoragePack() then 
		table.remove(self._ItemSet, index)
	end
	if item._Tid == 0 and self:IsTaskItemPack() then 
		table.remove(self._ItemSet, index)
	end
end

def.method().SortItemList = function(self)
	table.sort(self._ItemSet , sortfunction)
end

CInventory.Commit()
return CInventory