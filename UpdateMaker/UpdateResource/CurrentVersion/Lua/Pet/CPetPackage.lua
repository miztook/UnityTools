local Lplus = require "Lplus"

local CPetPackage = Lplus.Class("CPetPackage")
local def = CPetPackage.define

def.field("table")._ItemSet = BlankTable
def.field("number")._EffectSize = 0 --CurrentUnlockNum 当前开启的格子个数
def.field("number")._MaxSize = 0 	--服务器下发 最大格子数量
def.field("table")._UnlockCellPriceInfo = BlankTable  --解锁价格信息
def.field("number")._TotalFightScore = 0

def.static("=>", CPetPackage).new = function ()
	local obj = CPetPackage()
	return obj
end

--初始化宠物背包
def.method("table").Init = function(self, data)
	local CSpecialIdMan = require  "Data.CSpecialIdMan"
	local CPetUtility = require "Pet.CPetUtility"

	self._MaxSize = tonumber(CSpecialIdMan.Get("PetPackageMaxSize"))
	self._EffectSize = data.bagCount
	self._UnlockCellPriceInfo = CPetUtility.GetUnlockPriceInfo()
	--warn("初始化宠物背包 Max Size = ", self._MaxSize, " Unlock Size = ", self._EffectSize)
end

def.method("number").ReSize = function(self, effectSize)
	-- warn("CPetPackage::ReSize ", effectSize)
	self._EffectSize = effectSize
end

def.method("=>","boolean").IsFull = function (self)
	if self._ItemSet == nil then return false end
	local count = 0

	for k,v in pairs(self._ItemSet) do
		if v ~= nil and v._ID ~= 0 then
			count = count + 1
		end
	end

	return count >= self._EffectSize
end

def.method("number", "=>", "table").GetItemById = function (self, slot)
	local ItemSet = self._ItemSet
	for _, v in ipairs(ItemSet) do
		if v._Slot == slot then
			return v
		end
	end

	return nil
end

--宠物列表
def.method("=>", "table").GetList = function (self)
	return self._ItemSet
end
--获取单个宠物信息
def.method("number", "=>", "table").GetPetById = function (self, petId)
	if next(self._ItemSet) == nil then return nil end
	for i=1, #self._ItemSet do
		if self._ItemSet[i]._ID == petId then
 			return self._ItemSet[i]
		end
	end

	return nil
end
--获取当前列表个数
def.method("=>", "number").GetListCount = function (self)
	return #self._ItemSet
end
--获取宠物背包最大个数
def.method("=>", "number").GetMaxSize = function(self)
	return self._MaxSize
end
def.method("=>", "number").GetEffectSize = function(self)
	return self._EffectSize
end
--获取宠物背包开启价格
def.method("=>", "table").GetUnlockCellPriceInfo = function(self)
	return self._UnlockCellPriceInfo
end

--初始化宠物列表，服务器同步后会被重置
def.method("table").InitPetList = function (self, data)
	local CPetClass = require "Pet.CPetClass"
	self._ItemSet = {}

	for i, petDetail in ipairs(data) do
		local pet = CPetClass.new()
		pet:Init(petDetail)

		if pet ~= nil then
			table.insert(self._ItemSet, pet)
		end
	end
end

def.method("number").SetTotalFightScore = function(self, socre)
	self._TotalFightScore = socre
end

def.method("=>", "number").GetTotalFightScore = function(self)
	return self._TotalFightScore
end

--更新宠物列表，增加or删除
def.method("boolean", "dynamic").UpdatePetList = function (self, bIsAdd, param)
	if bIsAdd then
		local CPetClass = require "Pet.CPetClass"
		local pet = CPetClass.new()
		pet:Init(param)
		--弹出获取提示
		TeraFuncs.SendFlashMsg( string.format(StringTable.Get(19107), pet:GetName()), false)
		table.insert(self._ItemSet, pet)
	else
		local index = nil
		for i, oldPet in ipairs(self._ItemSet) do
			if oldPet._ID == param then
				index = i
			end
		end
		if index then
			--弹出放生提示
			table.remove(self._ItemSet, index)
		end
	end
end

CPetPackage.Commit()
return CPetPackage