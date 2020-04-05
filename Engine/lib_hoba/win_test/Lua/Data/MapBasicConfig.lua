local Lplus = require "Lplus"

local MapBasicConfig = Lplus.Class("MapBasicConfig")
local def = MapBasicConfig.define

local mapInfo = nil 		--地图数据
local mapLinkInfo = nil 	--联通数据
local mapDungeonEnd = nil	--通用结算

--获取地图数据
def.static("=>", "table").Get = function()
	if mapInfo == nil then
		local ret, msg, result = pcall(dofile, "Configs/MapBasicInfo.lua")
		if ret then
			mapInfo = result
		else
			warn(msg)
		end
	end
	
	return mapInfo
end

--获取联通数据
def.static("=>","table").GetLink = function()
	if mapLinkInfo == nil then
		local ret, msg, result = pcall(dofile, "Configs/MapLinkInfo.lua")
		if ret then
			mapLinkInfo = result
		else
			warn(msg)
		end	
	end

	return mapLinkInfo
end

--获取通用结算数据
def.static("=>","table").GetDungeonEnd = function()
	if mapDungeonEnd == nil then
		local ret, msg, result = pcall(dofile, "Configs/MapDungeonEnd.lua")
		if ret then
			mapDungeonEnd = result
		else
			warn(msg)
		end	
	end

	return mapDungeonEnd
end

def.static("string", "number", "=>", "number", "table").GetEntityInfo = function(entityType, entityTid)
	if mapInfo == nil then
		mapInfo = MapBasicConfig.Get()
	end
	-- warn("scene to find is : ", scene_id)
	-- warn("entity type is : ", entityType)
	-- warn("entity id is : ", entityTid)
	local scene_id = game._CurWorld._WorldInfo.SceneTid
	if mapInfo ~= nil then
		-- 先在指定图寻找，找不到，再去其他图遍历寻找
		if scene_id > 0 and mapInfo[scene_id] ~= nil and mapInfo[scene_id][entityType] ~= nil and mapInfo[scene_id][entityType][entityTid] ~= nil then
			return scene_id, mapInfo[scene_id][entityType][entityTid]
		else
			for k,v in pairs(mapInfo) do
				if v[entityType] ~= nil and v[entityType][entityTid] ~= nil then
					return k, v[entityType][entityTid]
				end
			end

			warn("can not find " .. entityType .. " id = " .. entityTid)
			return -1, nil
		end
	end
end

def.static("string", "number", "=>", "number", "table").GetDestParams = function(type, tid)
	local scene_id_cur = game._CurWorld._WorldInfo.SceneTid
	local scene_id, infos = MapBasicConfig.GetEntityInfo(type, tid)
	if scene_id > 0 and infos then
		if scene_id == scene_id_cur then	--同地图
            local cur_pos = game._HostPlayer:GetPos()
            local pos = Vector3.New(infos[1].x, infos[1].y, infos[1].z)
            local nearest_dist = GameUtil.GetNavDistOfTwoPoint(cur_pos, pos, 1, 0.01)
			if nearest_dist then
				local idx = 1
				for i = 2, #infos do
					pos = Vector3.New(infos[i].x, infos[i].y, infos[i].z)
					local dis = GameUtil.GetNavDistOfTwoPoint(cur_pos, pos, 1, 0.01)
					if dis ~= nil and dis < nearest_dist then
						nearest_dist = dis
						idx = i
					end
				end
				pos = Vector3.New(infos[idx].x, infos[idx].y, infos[idx].z)
				return scene_id, pos
			end
		end
		return scene_id, nil
	end
	return -1, nil
end

def.static("number", "string", "number", "=>", "table").GetSpecificEntityInfo = function(dst_scene_id, entityType, entityTid)
	if mapInfo == nil then
		mapInfo = MapBasicConfig.Get()
	end

	if mapInfo ~= nil then
		warn(dst_scene_id, mapInfo[dst_scene_id] , mapInfo[dst_scene_id][entityType] , mapInfo[dst_scene_id][entityType][entityTid])
		-- 先在指定图寻找，找不到，再去其他图遍历寻找
		if dst_scene_id > 0 and mapInfo[dst_scene_id] ~= nil and mapInfo[dst_scene_id][entityType] ~= nil and mapInfo[dst_scene_id][entityType][entityTid] ~= nil then
			return mapInfo[dst_scene_id][entityType][entityTid]
		else
			return nil
		end
	end
end

--获取地图类型
def.static("number","=>","number").GetMapType = function(nMapID)
	if mapInfo == nil or table.nums(mapInfo) < 0 then return -1 end

	if mapInfo[nMapID] == nil then return -1 end

	return mapInfo[nMapID].MapType
end

--[[-----------------------------获取区域数据-----------------------------------------------
			
			因为区域里面很多空数据，所以获取特定类型单写
--]]

--是否显示区域tips
def.static("number","number","=>","boolean").IsShowRegionNameTips = function(nMapID,nRegionID)
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return false end

	if mapInfo[nMapID] == nil or mapInfo[nMapID].Region == "" then return false end

	local regionData = mapInfo[nMapID].Region
	for _,v in pairs(regionData) do
		for i,k in pairs(v) do
			if nRegionID == i then
				return k.isShowName
			end
		end
	end

	return false
end

--获取区域名字
def.static("number","number","=>","string").GetRegionName = function(nMapID,nRegionID)
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return "" end

	if mapInfo[nMapID] == "" or mapInfo[nMapID].Region == "" then return "" end

	local regionData = mapInfo[nMapID].Region
	for _,v in pairs(regionData) do
		for i,k in pairs(v) do
			if nRegionID == i then
				return k.name
			end
		end
	end

	return ""
end

--获取区域坐标
def.static("number","number","=>","table").GetRegionPos = function(nMapID,nRegionID)
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end

	if mapInfo[nMapID] == nil or mapInfo[nMapID].Region == nil then return nil end

	local regionData = mapInfo[nMapID].Region
	for _,v in pairs(regionData) do
		for i,k in pairs(v) do
			if nRegionID == i then
				return Vector3.New(k.x,k.y,k.z)
			end
		end
	end

	return nil
end

MapBasicConfig.Commit()
return MapBasicConfig