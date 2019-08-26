local Lplus = require "Lplus"
local CInventory = require "Package.CInventory"
local CIvtrItems = require "Package.CIvtrItems"


local CPackage = Lplus.Class("CPackage")
local def = CPackage.define

def.field("table")._NormalIvtrs = nil
def.field("number")._GoldCoinCount = 0
def.field("number")._BindDiamondCount = 0
def.field("number")._GreenDiamondCount = 0  --新加货币-绿钻
def.field(CInventory)._EquipPack = nil  --身上的装备
def.field(CInventory)._NormalPack = nil --全部物品
def.field(CInventory)._MaterialPack = nil
def.field(CInventory)._TaskItemPack = nil
def.field(CInventory)._StoragePack = nil
def.field(CInventory)._AllPack = nil

_G.IVTRTYPE_ENUM =
{
    IVTRTYPE_EQUIPPACK = 0,	 -- Equipment 
    IVTRTYPE_PACK = 1,		 -- Normal pack
    IVTRTYPE_MATERIAL = 2,	 -- Material pack
    IVTRTYPE_TASKITEM = 3,	 -- Task Item pack
    IVTRTYPE_STORAGE = 4,	 -- Storage pack
    IVTRTYPE_All     = 5,    -- 全部物品
}

def.static("=>", CPackage).new = function ()
	local obj = CPackage()
	obj._NormalIvtrs = {}
	for k,v in pairs(IVTRTYPE_ENUM) do
		obj._NormalIvtrs[v] = CInventory.new(v)
	end
	
	obj._NormalPack = obj._NormalIvtrs[IVTRTYPE_ENUM.IVTRTYPE_PACK]
	obj._EquipPack = obj._NormalIvtrs[IVTRTYPE_ENUM.IVTRTYPE_EQUIPPACK]
	obj._TaskItemPack = obj._NormalIvtrs[IVTRTYPE_ENUM.IVTRTYPE_TASKITEM]
	obj._MaterialPack = obj._NormalIvtrs[IVTRTYPE_ENUM.IVTRTYPE_MATERIAL]
	obj._StoragePack = obj._NormalIvtrs[IVTRTYPE_ENUM.IVTRTYPE_STORAGE]
	obj._AllPack = obj._NormalIvtrs[IVTRTYPE_ENUM.IVTRTYPE_All]
	return obj
end

--背包类型，本地背包的索引 测试用
def.method("number", "number", "=>", "table").GetItemAttrIndex = function(self, bagType, index )
	local BAGTYPE = require "PB.net".BAGTYPE
	local attrIndexs = {}
	local items = nil
	if bagType == BAGTYPE.ROLE_EQUIP then
		items = self._EquipPack._ItemSet
	else
		items = self._NormalPack._ItemSet
	end
	if items == nil then
		--print("items is nil")
	end
	local itemDB = items[index].ItemData
	if itemDB.Tid ~= 0 then
		for i=1, 2 do
			table.insert(attrIndexs, itemDB.EquipAttrs[i].index)
		end
	end

	return attrIndexs
end

--检索普通背包和任务背包中所需的任务物品数量
def.method("number","=>","number").GetItemCountFromNormalOrTaskPack = function (self,tid)
	local count = 0

	local ItemSet = self._NormalPack._ItemSet
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		if item and item._Tid == tid then
			count = count + item._NormalCount
		end
	end
	if count > 0 then 
		return count
	end
	
	ItemSet = self._TaskItemPack._ItemSet
	for i = 1 ,#ItemSet do 
		local item = ItemSet[i]
		if item and item._Tid == tid then
			count = count + item._NormalCount
		end
	end
	return count 

end

-- 检索普通背包和任务背包中所需的物品数据返回值为CIvtrItem或nil
def.method("number", "=>","dynamic" ).GetItemFromNormalOrTaskPack  = function (self, tid)
	
	local ItemSet = self._NormalPack._ItemSet
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		if item and item._Tid == tid then
			return item
		end
	end
	ItemSet = self._TaskItemPack._ItemSet
	for i = 1, #ItemSet do
		local item = ItemSet[i]
		if item and item._Tid == tid then
			return item
		end
	end
	return nil
end

CPackage.Commit()
return CPackage