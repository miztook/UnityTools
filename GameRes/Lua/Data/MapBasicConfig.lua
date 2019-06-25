local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"

local MapBasicConfig = Lplus.Class("MapBasicConfig")
local def = MapBasicConfig.define

local mapEntityLinkInfo = nil  --怪物所属地图
local mapLinkInfo = nil 	--联通数据
local mapDungeonEnd = nil	--通用结算
local mapBasicInfo = nil
local lastSceneID = -1
local mapOffset = nil       -- 地图偏移量

--获取地图数据
def.static("=>", "table").Get = function()
	local mapBasicInfo = nil 
	local ret, msg, result = pcall(dofile, _G.ConfigsDir.."MapBasicInfo.lua")
	if ret then
		mapBasicInfo = result
	else
		warn(msg)
	end	
	return mapBasicInfo
end

--获取地图数据
def.static("number","=>","table").GetMapBasicConfigBySceneID = function(sceneID)
	if lastSceneID == sceneID then
		return mapBasicInfo
	end
	print("GetMapBasicConfigBySceneID",sceneID)
	lastSceneID = sceneID
	local ret, msg, result = pcall(dofile, _G.ConfigsDir.."MapBasicInfo/"..sceneID..".lua")
	if ret then
		mapBasicInfo = result
	else
		warn(msg)
	end	

	return mapBasicInfo
end

def.static().Reset = function ()
	lastSceneID = -1
	mapBasicInfo = nil
end

--获取怪物所属地图数据
def.static("=>","table").EntityLinkInfo = function()
	if mapEntityLinkInfo == nil then
		local ret, msg, result = pcall(dofile, "Configs/MapBasicInfo/LinkToScene.lua")
		if ret then
			mapEntityLinkInfo = result
		else
			warn(msg)
		end	
	end

	return mapEntityLinkInfo
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
--获取地图偏移量
def.static("=>","table").GetMapOffset = function()
	if mapOffset == nil then
		local ret, msg, result = pcall(dofile, "Configs/MapOffset.lua")
		if ret then
			mapOffset= result
		else
			warn(msg)
		end	
	end
	return mapOffset
end

--[[def.static("string", "number", "=>", "number", "table").GetEntityInfo = function(entityType, entityTid)
	local mapInfo = MapBasicConfig.Get()

	if mapInfo ~= nil then
		local scene_id = game._CurWorld._WorldInfo.SceneTid
		-- 先在指定图寻找，找不到，再去其他图遍历寻找
		if scene_id > 0 then
			local scene_table = mapInfo[scene_id]
			if scene_table ~= nil then
				local entity_table = scene_table[entityType]
				if entity_table ~= nil then
					local v = entity_table[entityTid]
					if v ~= nil then
						return scene_id, v
					end
				end
			end
		end

		do
			local minK = 100000
			local ret = nil
			for k,v in pairs(mapInfo) do
				local entities = v[entityType]
				if entities ~= nil then
					local info = entities[entityTid]
					if info ~= nil and k < minK then
						minK = k
						ret = info
					end
				end
			end

			if ret ~= nil then return minK, ret end

			-- 删除log，游戏中存在很多行为树生成的NPC对象，而这些对象在scene数据中是没有配置的；会因此带来很多错误的log信息
			--warn("can not find " .. entityType .. " id = " .. entityTid, debug.traceback())
			return -1, nil
		end
	end

	return -1, nil
end--]]

def.static("string", "number", "=>", "number", "table").GetEntityInfo = function(entityType, entityTid)
	local scene_id = game._CurWorld._WorldInfo.SceneTid
	-- 先在指定图寻找，找不到，再去其他图遍历寻找
	if scene_id > 0 then
		local scene_table = MapBasicConfig.GetMapBasicConfigBySceneID( scene_id )
		if scene_table ~= nil then
			local entity_table = scene_table[entityType]
			if entity_table ~= nil then
				local v = entity_table[entityTid]
				if v ~= nil then
					return scene_id, v
				end
			end
		end
	end

	do
		local minK = 100000
		local ret = nil

		local mapEntityLinkInfo = MapBasicConfig.EntityLinkInfo()
		if mapEntityLinkInfo == nil then return -1, nil end

		--所属哪些地图上
		local entities = mapEntityLinkInfo[entityType]

		if entities == nil or table.nums(entities) == 0 then return -1, nil end
		local entitie_maps = entities[entityTid]
		if entitie_maps ~= nil then
			for k,v in ipairs(entitie_maps) do
				local scene_id = v
				local scene_table = MapBasicConfig.GetMapBasicConfigBySceneID( scene_id )
				if scene_table ~= nil then
					local entities = scene_table[entityType]
					if entities ~= nil then
						local info = entities[entityTid]
						if info ~= nil then
							minK = scene_id
							ret = info
							return minK, ret
						end
					end
				end
			end
		end
		-- 删除log，游戏中存在很多行为树生成的NPC对象，而这些对象在scene数据中是没有配置的；会因此带来很多错误的log信息
		--warn("can not find " .. entityType .. " id = " .. entityTid, debug.traceback())

		return -1, nil
	end

	return -1, nil
end

def.static("string", "number", "table","=>", "number", "table", "number").GetDestParams = function(type, tid, params)
	local scene_id_cur = game._CurWorld._WorldInfo.SceneTid
	local scene_id, infos = MapBasicConfig.GetEntityInfo(type, tid)
	if scene_id > 0 and infos then
		if scene_id == scene_id_cur then	--同地图
	        local cur_pos = game._HostPlayer:GetPos()
	        --如果上一个记录没有找到则找下一个 否则找最近的
	        if #params == 4 and params[1] == scene_id and params[2] == tid and params[3] ~= 0 then
				local idx = params[3] +1
				if idx > #infos then idx = 1 end
				local pos = nil
				if infos[idx] ~= nil then
					pos = Vector3.New(infos[idx].x, infos[idx].y, infos[idx].z)
				else
					idx = -1
				end
				return scene_id, pos, idx
			else
	            local pos = Vector3.New(infos[1].x, infos[1].y, infos[1].z)
	            local nearest_dist = GameUtil.GetNavDistOfTwoPoint(cur_pos, pos)
	            if nearest_dist == nil then nearest_dist = 100000 end
				if nearest_dist then
					local idx = 1
					for i = 2, #infos do
						pos = Vector3.New(infos[i].x, infos[i].y, infos[i].z)
						local dis = GameUtil.GetNavDistOfTwoPoint(cur_pos, pos)
						if dis ~= nil and dis < nearest_dist then
							nearest_dist = dis
							idx = i
						end
					end
					pos = Vector3.New(infos[idx].x, infos[idx].y, infos[idx].z)
					return scene_id, pos, idx
				end
			end
		else
			--不用判断附属关系了。寻路逻辑里面做过了
			local idx = 1
			local pos = Vector3.New(infos[idx].x, infos[idx].y, infos[idx].z)
			return scene_id, pos, 1

			-- local curMapTid = game._CurWorld._WorldInfo.MapTid
			-- local mapTemp = CElementData.GetMapTemplate(curMapTid)
			-- if mapTemp ~= nil then
			-- 	local mainMapTid = mapTemp.AssociatedPathfindingMainMapId
			-- 	if mainMapTid > 0 then
			-- 		local mainMapTemp = CElementData.GetMapTemplate(mainMapTid)
			-- 		if mainMapTemp ~= nil and mainMapTemp.AssociatedMapId == scene_id then
			-- 			local pos = Vector3.New(infos[1].x, infos[1].y, infos[1].z)
			-- 			return scene_id, pos, 1
			-- 		end
			-- 	end
			-- end
		end

		return scene_id, nil, -1
	end

	return -1, nil, -1
end

def.static("number", "string", "number", "=>", "table").GetSpecificEntityInfo = function(dst_scene_id, entityType, entityTid)
	local mapInfo = MapBasicConfig.GetMapBasicConfigBySceneID(dst_scene_id)

	if mapInfo ~= nil then	
		--区域和其他结构不一样，不能直接用ID取，区域的ID是类型
		if  entityType == "Region" then
			return MapBasicConfig.GetRegionPos(dst_scene_id,entityTid)
		end

		if dst_scene_id > 0 and mapInfo ~= nil and mapInfo[entityType] ~= nil then		
			local infos = mapInfo[entityType][entityTid]
			if infos ~= nil and infos[1] ~= nil then  
       			return Vector3.New(infos[1].x, infos[1].y, infos[1].z) 
       		end	
		else
			warn("MapBasicConfig: Get Data Error: SceneID:"..dst_scene_id.."__type:"..entityType.."__TID:"..entityTid)
			return nil
		end
	end

	return nil
end

def.static("number", "number", "=>", "table").GetGeneratorPos = function(mapTid, generatorTid)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]

	--local map = mapInfo[mapTid]
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(mapTid)
	if map == nil then return nil end

	local generator = map.Entity[generatorTid]
	if generator == nil then return nil end

	return Vector3.New(generator.x, generator.y, generator.z) 
end

def.static("number", "number", "=>", "table").GetGeneratorTargetMonsters = function(mapTid, generatorTid)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]

	--local map = mapInfo[mapTid]
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(mapTid)
	if map == nil then return nil end

	local generator = map.Entity[generatorTid]
	if generator == nil then return nil end

	return generator.Tid
end

--获取地图类型
def.static("number","=>","number").GetMapType = function(nMapID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) < 0 then return -1 end--]]

--[[	if mapInfo[nMapID] == nil then return -1 end

	return mapInfo[nMapID].MapType--]]
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil then return -1 end

	return map.MapType
end

def.static("number", "=>", "string").GetNavmeshName = function(nSceneID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then 
		warn("MapBasicInfo 数据出错")
		return ""
	end

	if mapInfo[nSceneID] == nil then 
		warn("地图数据丢失，mapid =", nSceneID)
		return "" 
	end
	return mapInfo[nSceneID].NavMeshName--]]

	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nSceneID)
	if map == nil then 
		warn("地图数据丢失，mapid =", nSceneID)
		return "" 
	end
	return map.NavMeshName
end

--[[-----------------------------获取区域数据-----------------------------------------------
			
			因为区域里面很多空数据，所以获取特定类型单写
--]]

--是否显示区域tips
def.static("number","number","=>","boolean").IsShowRegionNameTips = function(nMapID,nRegionID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return false end--]]

	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil or map.Region == "" then return false end

	local regionData = map.Region
	for _,v in pairs(regionData) do
		for i,k in pairs(v) do
			if nRegionID == i then
				if k.isShowName == nil then
					return false
				end
				return k.isShowName
			end
		end
	end

	return false
end

--获取区域名字
def.static("number","number","=>","string").GetRegionName = function(nMapID,nRegionID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return "" end--]]
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil or map.Region == "" then return "" end

	local regionData = map.Region
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
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]

	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil or map.Region == nil then return nil end

	local regionData = map.Region
	for _,v in pairs(regionData) do
		for i,k in pairs(v) do
			if nRegionID == i then
				return Vector3.New(k.x, k.y, k.z)
			end
		end
	end

	warn("MapBasicConfig: Get RegionData Error: SceneID:"..nMapID.."__nRegionID:"..nRegionID, debug.traceback())
	return nil
end

def.static("number", "=>", "table").GetAllPortalRegion = function(nMapID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]

	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil or map.Region == nil then return nil end
	return map.Region[1] 
end


def.static("number", "=>", "table").GetAllTargetPosition = function(nMapID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]

	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil then return nil end

	return map.TargetPoint
end

def.static("number", "number", "=>", "table").GetPosDataByPosID = function(mapID, posID)
    local points = MapBasicConfig.GetAllTargetPosition(mapID)    
    if points == nil then return nil end

    return points[posID]
end

--获取 地图·区域 名字
def.static("number","number","=>","string").GetMapAndRegionName = function(nMapID,nRegionID)
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)
	if map == nil then
		warn("Scene template is nil, scene id:", nMapID)
		return ""
	end

	local showName = map.TextDisplayName
	local regions = map.Region
	--倒叙查找最后一个进入的有名字的区域
    for j, w in ipairs(regions) do
        for k, x in pairs(w) do
            if k == nRegionID then
                -- warn("nRegionID = ", w.Id, "Show? = ", w.ShowName, "TextDisplayName = ", x.isShowName)
                if x.name ~= ""  then
                    showName = showName .. "·" .. x.name
                    return showName
                end
            end
        end
    end
	return showName
end

--获取地图生成器的坐标 MapID = 0 默认当前地图
def.static("number","number","=>","table").GetEntityPosByMapIDAndTId = function(MapID, nEntityID)
	local nMapID = 1
	if MapID <= 0 then
		nMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	else	
		nMapID = MapID
	end
	
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]
	
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)

	if map == nil or map.Entity == nil then 
		warn("地图:"..nMapID.."没有生成器")
		return nil 
	end

	local entityPos = map.Entity[nEntityID]
	if entityPos == nil then
		warn("地图:"..nMapID.."中没有对象" ..nEntityID .. "的生成器")
		return nil 
	end

	return  Vector3.New(entityPos.x, entityPos.y, entityPos.z)
end

--获取采集物的坐标 MapID = 0 默认当前地图
def.static("number","number","=>","table").GetMinePosByMapIDAndTId = function(MapID, nMineID)
	local nMapID = 1
	if MapID <= 0 then
		nMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	else	
		nMapID = MapID
	end
	
--[[	local mapInfo = MapBasicConfig.Get()
	if mapInfo == nil or table.nums(mapInfo) <= 0 then return nil end--]]
	
	local map = MapBasicConfig.GetMapBasicConfigBySceneID(nMapID)

	if map == nil or map.Mine == nil then 
		warn("地图:"..nMapID.."没有采集物")
		return nil 
	end

	if map.Mine[nMineID] == nil then
		warn("地图:"..nMapID.."找不到采集物ID："..nMineID)
		return nil
	end
	
	local minePos = map.Mine[nMineID][1]
	return  Vector3.New(minePos.x, minePos.y, minePos.z)
end

--获取联通相位的主地图ID，和区域
def.static("number", "=>","number", "number").GetLinkRegionID = function(nMapID)
	local temData = CElementData.GetMapTemplate(nMapID)

	if temData == nil then				
		warn("mapID:"..nMapID.."模板错误","tip",2)
    return -1, -1 end

   	local mainMapTid = temData.AssociatedPathfindingMainMapId	
	local link = MapBasicConfig.GetLink() 	

	if link[mainMapTid] == nil then
	    warn("MapLinkInfo数据错误，"..mainMapTid.."不存在！！","tip", 3)
		game._HostPlayer: SetAutoPathFlag(false)   
	return -1, -1 end

	local linkData = link[mainMapTid][nMapID]
	if linkData == nil then
		warn("MapLinkInfo数据错误，"..mainMapTid.."和"..nMapID.."不连通")
		game._HostPlayer: SetAutoPathFlag(false)   
	end

	if linkData.Region ~= nil and #linkData.Region > 0 then
		return linkData.Region[1].regionId, linkData.Region[1].sceneId
	else
		return -1, -1
	end
end

MapBasicConfig.Commit()
return MapBasicConfig