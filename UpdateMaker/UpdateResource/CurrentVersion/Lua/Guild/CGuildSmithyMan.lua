-- 公会铁匠铺管理

local Lplus = require "Lplus"
local CGuildSmithyMan = Lplus.Class("CGuildSmithyMan")
local def = CGuildSmithyMan.define

local bit = require "bit"
local CElementData = require "Data.CElementData"
local EGuildBuildingType = require "PB.data".GuildBuildingType

def.field("table")._MachiningTidMap = BlankTable	-- 所有加工Tid（Key为装备Tid）
def.field("number")._CostPercent = 1				-- 打造消耗百分比
def.field("boolean")._IsInited = false 				-- 是否已初始化数据

local instance = nil
def.static("=>", CGuildSmithyMan).Instance = function()
	if instance == nil then
		instance = CGuildSmithyMan()
	end
	return instance
end

-- 设置所有的加工Tid
def.method().InitMachiningTidMap = function (self)
	self._MachiningTidMap = {}

	local buildingList = game._HostPlayer._Guild._BuildingList
	if buildingList == nil then
		-- warn("Guild has no building")
		return
	end
	local smithyBuilding = buildingList[EGuildBuildingType.Smithy]
	if smithyBuilding == nil then
		warn("Guild smithy building is null")
		return
	end
	local smithyLevel = smithyBuilding._BuildingLevel
	if smithyLevel < 1 then
		warn("Guild smithy building level is wrong, level:", smithyLevel)
		return
	end

	local smithyData = CElementData.GetGuildSmithyTemplate(smithyLevel)
	if smithyData == nil then
		warn("SmithyData is null, smithy level:", smithyLevel)
		return
	end

	self._CostPercent = smithyData.CostPercent / 100
	local profMask = EnumDef.Profession2Mask[game._HostPlayer._InfoData._Prof]
	-- 根据加工ID，获取所有的打造物品ID
	for _, v in ipairs(smithyData.MachiningItems) do
		local itemMachining = CElementData.GetItemMachiningTemplate(v.MachiningID)
		if itemMachining ~= nil then
			if #itemMachining.DestItemData.DestItems == 1 then
				local destItemID = itemMachining.DestItemData.DestItems[1].ItemId
				local itemTemplate = CElementData.GetItemTemplate(destItemID)
				if itemTemplate ~= nil then
					if profMask == bit.band(itemTemplate.ProfessionLimitMask, profMask) then
						-- 自己职业，且属于显示品质的
						self._MachiningTidMap[destItemID] = v.MachiningID
					end
				else
					warn("[GuildSmithy]DestItem template got nil, machining tid: " .. v.MachiningID .. ", item tid:" .. destItemID)
				end
			else
				error("[GuildSmithy]Machining template DestItems not unique, wrong machining tid: " .. v.MachiningID)
			end
		end
	end
	self._IsInited = true
end

def.method("=>", "table").GetMachiningTidMap = function (self)
	if not self._IsInited then
		self:InitMachiningTidMap()
	end
	return self._MachiningTidMap
end

-- 获取当前铁匠铺等级的货币消耗比例
def.method("=>", "number").GetCostPercent = function (self)
	if not self._IsInited then
		self:InitMachiningTidMap()
	end
	return self._CostPercent
end

def.method().Clear = function (self)
	self._MachiningTidMap = {}
	self._CostPercent = 1
	self._IsInited = false
end

CGuildSmithyMan.Commit()
return CGuildSmithyMan