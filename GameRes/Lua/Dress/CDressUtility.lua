local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CDressUtility = Lplus.Class("CDressUtility")
local def = CDressUtility.define

def.static("number", "=>", "table").GetLuaColorRGB = function(colorId)
	local ColorConfig = require "Data.ColorConfig"
	local info = ColorConfig.GetColorInfo(colorId)
	if info == nil then
		warn("Color info got nil, color Id:" .. colorId)
		return nil
	end
	local RGB = Color.New(info[1] / 255, info[2] / 255, info[3] / 255, 1)

	return RGB
end

def.static("number", "=>", "table").GetColorInfoByDyeId = function(dyeId)
	local template = CElementData.GetTemplate("DyeAndEmbroidery", dyeId)
	if template == nil then return nil end

	--Lua表读取数据 RGB
	return CDressUtility.GetLuaColorRGB(template.ColorId)
end

-- 获取所有染色材料列表
-- @param dyeIds 从部位一到部位二的染色Id
def.static("table", "=>", "table").GetDyeStuffItemList = function(dyeIds)
	if dyeIds == nil then return {} end

	local stuffItemMap = {}
	for _, dyeId in ipairs(dyeIds) do
		local template = CElementData.GetTemplate("DyeAndEmbroidery", dyeId)
		if template ~= nil then
			-- 最多四种染色剂
			for i = 1, 4 do
				local itemId = template["ItemId"..i]
				local itemCount = template["ItemCount"..i]
				if itemId > 0 and itemCount > 0 then
					-- 相同的物品，数量相加
					if stuffItemMap[itemId] == nil then
						stuffItemMap[itemId] = 0
					end
					stuffItemMap[itemId] = stuffItemMap[itemId] + itemCount
				end
			end
		end
	end

	local stuffList = {}
	for itemId, itemCount in pairs(stuffItemMap) do
		local data =
		{
			ItemId = itemId,
			ItemCount = itemCount,
		}
		table.insert(stuffList, data)
	end

	local function sortFunc(a, b)
		if a.ItemId < b.ItemId then
			return true
		end
		return false
	end
	table.sort(stuffList, sortFunc)

	return stuffList
end

-- 通过染色Id获取消耗货币Id和数量
-- def.static("number", "=>", "number", "number").GetMoneyIdAndCount = function(dyeId)
-- 	local template = CElementData.GetTemplate("DyeAndEmbroidery", dyeId)
-- 	if template == nil then return 0, 0 end
-- 	-- ItemId5 和 ItemCount5 是货币用字段
-- 	return template.ItemId5, template.ItemCount5
-- end

--获取颜色的结构   lua -> rgb & Data -> iconPath & name
def.static("number", "=>", "table").GetColorInfo = function(colorId)
	local info = {}
	local template = CElementData.GetTemplate("DyeAndEmbroidery", colorId)
	if template == nil then return nil end

	info.ID = colorId
	info.IconPath = template.IconPath
	info.Name = template.Name

	--Lua表读取数据 RGB
	local ColorConfig = require "Data.ColorConfig"
	local colorLuaInfo = ColorConfig.GetColorInfo(colorId)
	info.RGB = Vector3.New(colorLuaInfo[1], colorLuaInfo[2], colorLuaInfo[3])

	return info
end

--获取刺绣的结构
-- def.static("number", "=>", "table").GetStampInfo = function(stampId)
-- 	local info = {}
-- 	local template = CElementData.GetTemplate("DyeAndEmbroidery", stampId)
-- 	if template == nil then return nil end

-- 	info.ID = stampId
-- 	info.IconPath = template.IconPath
-- 	info.Name = template.Name
-- 	info.AssetPath = template.EmbroideryAssetPath

-- 	return info
-- end

--获取染色材料的结构
-- def.static("number", "=>", "table").GetColorNeedInfo = function(id)
-- 	local info = {}
-- 	local template = CElementData.GetTemplate("DyeAndEmbroidery", id)
-- 	if template == nil then return nil end

-- 	-- 最多四种材料
-- 	for i=1,4 do
-- 		if template["ItemId"..i] > 0 and template["ItemCount"..i] > 0 then
-- 			local needInfo = {}
-- 			needInfo.ID = template["ItemId"..i]
-- 			needInfo.Count = template["ItemCount"..i]

-- 			info[#info+1] = needInfo
-- 		end
-- 	end

-- 	return info
-- end

--获取刺绣材料的结构
-- def.static("number", "=>", "table").GetStampNeedInfo = function(id)
-- 	local info = {}
-- 	local template = CElementData.GetTemplate("DyeAndEmbroidery", id)
-- 	if template == nil then return nil end

-- 	if template.ItemId1 > 0 and template.ItemCount1 > 0 then
-- 		info.ID = template.ItemId1
-- 		info.Count = template.ItemCount1
-- 	end

-- 	return info
-- end

-- def.static("userdata", "table").ChangeDressStamp = function(modelObject, info)
-- 	if info.EmbroideryId > 0 then
-- 		local stampInfo = CDressUtility.GetStampInfo(info.EmbroideryId)
-- 		GUITools.ChangeDressEmbroidery(modelObject, stampInfo.AssetPath)
-- 	end
-- end

-- 返回时装评分列表
def.static("=>", "table").GetChramScoreList = function()
	local scoreList = {}
	local allScoreTids = GameUtil.GetAllTid("DressScore")
	for _, tid in ipairs(allScoreTids) do
		local template = CElementData.GetTemplate("DressScore", tid)
		if template ~= nil then
			local attriList = {}
			for i = 1, 4 do
				local attriId = template["AttrId" .. i]
				local attriValue = template["AttrValue" .. i]
				if attriId > 0 and attriValue > 0 then
					attriList[#attriList+1] =
					{
						Id = attriId,
						Value = attriValue,
					}
				end
			end
			scoreList[#scoreList+1] =
			{
				Score = template.Score,
				AttriList = attriList,
			}
		end
	end

	local function sortFunc(a, b)
		if a.Score < b.Score then
			return true
		end
		return false
	end
	table.sort(scoreList, sortFunc)
	
	return scoreList
end

CDressUtility.Commit()
return CDressUtility