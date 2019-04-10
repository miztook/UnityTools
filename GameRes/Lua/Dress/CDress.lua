local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local CDress = Lplus.Class("CDress")
local def = CDress.define

def.field("number")._ID = -1						--时装实例ID
def.field("number")._Tid = -1						--时装TID
def.field("table")._Template = nil 					--时装模板
def.field("number")._DressSlot = -1 				--时装部位
def.field("boolean")._IsWeared = false				--是否已装备
def.field("boolean")._IsCanDyeColors = false		--是否可以染色

def.field("number")._TimeLimit = 0					--限时
def.field("table")._Colors = BlankTable				--染色List
def.field("table")._CanDyeColors = BlankTable		--可染色的色号

def.static("table", "=>", CDress).new = function (serverData)
	if serverData == nil then return nil end
	local obj = CDress()
	if obj:InitById(serverData.InsId, serverData.Tid) then
		obj:SetServerData(serverData)
		return obj
	else
		return nil
	end
end

-- 创建虚拟的时装结构
def.static("number", "=>", CDress).CreateVirtual = function (tid)
	local obj = CDress()
	if obj:InitById(-1, tid) then
		return obj
	else
		return nil
	end
end

def.method("number", "number", "=>", "boolean").InitById = function(self, id, tid)
	local template = CElementData.GetTemplate("Dress", tid)
	if template == nil then
		warn("Dress can not find template id = ", tid)
		return false
	end

	self._ID = id
	if template.TimeLimit > 0 then
		-- 属于限时时装，使用关联的永久时装Tid
		self._Tid = template.AssociatedDressId
	else
		self._Tid = tid
	end
	self._Template = template
	self._DressSlot = template.Slot
	self._Colors = {}
	self._CanDyeColors = {}

	local colorFieldMax = 2
	local colorCanDyeCnt = 0
	for i=1, colorFieldMax do
		if template["InitColor"..i] <= 0 then break end
		colorCanDyeCnt = colorCanDyeCnt + 1
	end
	if colorCanDyeCnt > 0 then
		for i=1, colorCanDyeCnt do
			self._Colors[#self._Colors+1] = template["InitColor"..i]

			--可染色的色号
			local strColors = template["DyeColors"..i]
			if strColors ~= nil and strColors ~= "" then
				local colors = string.split(strColors, "*")
				local tmpColors = {}
				for _,v in ipairs(colors) do
					tmpColors[#tmpColors+1] = tonumber(v)
				end

				self._IsCanDyeColors = true
				self._CanDyeColors[#self._CanDyeColors+1] = tmpColors
			end
		end
	end

	return true
end

-- 设置服务器数据
-- @param	serverData	结构是net.DressStruct
def.method("table").SetServerData = function (self, serverData)
	if serverData == nil then return end
	-- 当前染色
	if #self._Colors > 0 then
		-- 有染色部位（可以染色）
		for i, color in ipairs(serverData.DyeColors) do
			if color <= 0 then break end
			self._Colors[i] = color
		end
	end
	-- 到期时间
	-- print("serverData tid: ", serverData.Tid, "TimeLimit: ", LuaUInt64.ToDouble(serverData.TimeLimit), "Limit Type: ", type(serverData.TimeLimit))
	if type(serverData.TimeLimit) == "string" then
		self._TimeLimit = LuaUInt64.ToDouble(serverData.TimeLimit)
	else
		warn("Dress time limit type wrong, wrong type:", type(serverData.TimeLimit), " dress tid:" .. serverData.Tid, "dress instanceId:" .. serverData.InsId)
	end
end

-- 对比内容是否相等
def.method(CDress, "=>", "boolean").Equals = function (self, otherDress)
	if self._Tid == otherDress._Tid and self._ID == otherDress._ID and #self._Colors == #otherDress._Colors then
		for i, dyeId in ipairs(self._Colors) do
			local otherDyeId = otherDress._Colos[i]
			if otherDyeId ~= dyeId then
				return false
			end
		end
		return true
	end
	return false
end

def.static(CDress, "=>", "table").CopyColors = function (data)
	local dyeIdList = {}
	if data ~= nil then
		for _, dyeId in ipairs(data._Colors) do
			dyeIdList[#dyeIdList+1] = dyeId
		end
	end
	-- if next(dyeIdList) ~= nil then
		return dyeIdList
	-- end
	-- return nil
end

def.method().Reset = function (self)
	self._ID = -1
	self._Tid = -1
	self._Template = nil
	self._DressSlot = -1
	self._IsWeared = false
	self._IsCanDyeColors = false
	self._TimeLimit = 0
	self._Colors = BlankTable
	self._CanDyeColors = BlankTable
end

CDress.Commit()
return CDress