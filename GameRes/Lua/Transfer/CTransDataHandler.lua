local Lplus = require "Lplus"
local MapBasicConfig = require "Data.MapBasicConfig" 
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local CElementData = require "Data.CElementData"
local EWorldType = require "PB.Template".Map.EWorldType

local CTransDataHandler = Lplus.Class("CTransDataHandler")
local def = CTransDataHandler.define

--def.field("table")._TableMapInfo = nil --地图数据
def.field("table")._TableMapLink = nil --联通数据

local instance = nil
def.static("=>", CTransDataHandler).Instance = function()
	if instance == nil then
		instance = CTransDataHandler()
        instance:Init()
	end
	return instance
end

--def.static("=>", CTransDataHandler).new = function()
--    local obj = CTransDataHandler()
--    return obj
--end

def.method().Init = function(self)
    self:LoadAllTransTable()
end

def.method().LoadAllTransTable = function (self)
	--self._TableMapInfo = MapBasicConfig.Get()
    self._TableMapLink = MapBasicConfig.GetLink()
end

-- 根据mapID获得地图数据
def.method("number", "=>", "table").GetMapInfoData = function(self, mapID)
    --if self._TableMapInfo == nil then return nil end
    return MapBasicConfig.GetMapBasicConfigBySceneID(mapID)
end

-- 根据mapID获得地图连接数据
def.method("number", "=>", "table").GetMapLinkData = function(self, mapID)
    if self._TableMapLink == nil then return nil end
    return self._TableMapLink[mapID]
end

--传送模式 true 直接跨图  false 发生过传送
def.method("number","=>","boolean","table").IsNonstopTrans = function(self, targetMapID)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	if self._TableMapLink[nCurMapID] == nil then
	    warn("MapLinkInfo数据错误，"..nCurMapID.."不存在！！","tip", 3)
	return false, nil end

	local linkData =  self._TableMapLink[nCurMapID][targetMapID]
	if linkData == nil then return false,nil end	

	return linkData.Nonstop,self:GetNearPortalByData(linkData, nil)
end

-- 地图是否是相位
def.method("number", "=>", "boolean").IsPhaseMap = function(self, mapID)
    local map_info_data = self:GetMapInfoData(mapID)
    return map_info_data.MapType == EWorldType.Pharse
end

-- 地图是否是副本或者及时副本
def.method("number", "=>", "boolean").IsIntanceOrImmediate = function(self, mapID)
    local map_info_data = self:GetMapInfoData(mapID)
    return map_info_data.MapType == EWorldType.Instance or map_info_data.MapType == EWorldType.Immediate
end

-- 直接得到连接地图之间的连接点
def.method("number","number","=>","boolean","table").GetMapJoinPoint = function(self, MapID1,MapID2)
	if self._TableMapLink[MapID1] == nil then
	    warn("MapLinkInfo数据错误，"..MapID1.."不存在！！","tip", 3)
	return false, nil end

	local linkData =  self._TableMapLink[MapID1][MapID2]
	if linkData == nil then return false,nil end	

	return linkData.Nonstop,self:GetNearPortalByData(linkData, nil)
end

--获取联通数据 返回参数 isNone 是否联通 regionPos 联通的区域坐标
def.method("number","table","=>","boolean","table").GetTransLinkDataByMapAndPosition = function(self, targetMapID, targetPos)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	if self._TableMapLink[nCurMapID] == nil then
	    warn("GetTransLinkDataByMapAndPosition：：MapLinkInfo数据错误，"..nCurMapID.."不存在！！","tip")
		game._HostPlayer: SetAutoPathFlag(false)   
	return false, nil end

	--warn("场景:"..nCurMapID.."与"..targetMapID)
	local linkData =  self._TableMapLink[nCurMapID][targetMapID]
	if linkData == nil then
		warn("GetTransLinkDataByMapAndPosition：：场景:"..nCurMapID.."与"..targetMapID.."不连通，没有传送点","tip",3)
		game._HostPlayer: SetAutoPathFlag(false)   
	return false,nil end	

	return linkData.Nonstop,self:GetNearPortalByData(linkData, targetPos)
end

local function GetProtalDataByMapID(nMapID)
	local allTransData = GameUtil.GetAllTid("Trans")
	for _,v in pairs(allTransData) do
		local transData = CElementData.GetTemplate("Trans", v)    
		if transData ~= nil and transData.MapId ~= nil then
			if transData.MapId == nMapID then
				return transData
			end
		end
	end

	return nil
end

local function GetLandRotationAndPosByMapID(nMapID)
	local v = GetProtalDataByMapID(nMapID)
	if v ~= nil then
		return  Vector3.New(v.RotationX,v.RotationY,v.RotationZ), Vector3.New(v.x,v.y,v.z)
	end
	return nil ,nil
end

--通过目标地图联通数据取距离玩家最近的传送点, targetPosition == nil 玩家当前自身坐标
def.method("table", "dynamic", "=>", "table").GetNearPortalByData = function(self, linkData, targetPosition)
	if linkData == nil then return nil end

	if linkData.Portal == nil then
		warn("地图传送点错误！！", "tip", 2, debug.traceback())	
	return nil end

    --只有一个，不用判断
	if #linkData.Portal == 1 then 
		local regionPos = Vector3.New(linkData.Portal[1].x, linkData.Portal[1].y, linkData.Portal[1].z)
		return regionPos
	end

	local targetPos = nil
	if targetPosition then
		targetPos = targetPosition
	else
		targetPos = game._HostPlayer:GetPos()
	end

	local regionPos = Vector3.New(linkData.Portal[1].x, linkData.Portal[1].y, linkData.Portal[1].z)
	local distance = SqrDistanceH(targetPos.x,targetPos.z, regionPos.x,regionPos.z)
	
	for i = 2,#linkData.Portal do
		local pos = linkData.Portal[i] 
		local delta = SqrDistanceH(targetPos.x,targetPos.z, pos.x,pos.z)
		if distance > delta  then
			regionPos = Vector3.New(pos.x, pos.y, pos.z)
			distance = delta
		end	
	end

	return regionPos	
end

def.method("table", "dynamic", "=>", "table").GetNearRegionByData = function(self, linkData, targetPosition)
    if linkData == nil then return nil end

	if linkData.Region == nil then
		warn("地图传送点错误！！", "tip", 2, debug.traceback())	
	return nil end

    --只有一个，不用判断
	if #linkData.Region == 1 then 
		local regionPos = Vector3.New(linkData.Region[1].x, linkData.Region[1].y, linkData.Region[1].z)
		return regionPos
	end

	local targetPos = nil
	if targetPosition then
		targetPos = targetPosition
	else
		targetPos = game._HostPlayer:GetPos()
	end

	local regionPos = Vector3.New(linkData.Portal[1].x, linkData.Portal[1].y, linkData.Portal[1].z)
	local distance = SqrDistanceH(targetPos.x,targetPos.z, regionPos.x,regionPos.z)
	
	for i = 2,#linkData.Portal do
		local pos = linkData.Portal[i] 
		local delta = SqrDistanceH(targetPos.x,targetPos.z, pos.x,pos.z)
		if distance > delta  then
			regionPos = Vector3.New(pos.x, pos.y, pos.z)
			distance = delta
		end	
	end

	return regionPos	
end


--通过目标地图联通数据取距离玩家最近的传送点,以及返回传送之后的初始点,targetPosition == nil 玩家当前自身坐标
local GetNearPortalAndAssociatedPosByMap = function(linkData, targetPosition)
	if linkData == nil then return nil, nil end

	if linkData.Portal == nil then
		warn("地图传送点错误！！", "tip", 2, debug.traceback())	
	return nil, nil end

    --只有一个，不用判断
	if #linkData.Portal == 1 then 
		local regionPos = Vector3.New(linkData.Portal[1].x, linkData.Portal[1].y, linkData.Portal[1].z)
		local AssociatedPos = Vector3.New(linkData.Portal[1].xA,linkData.Portal[1].yA,linkData.Portal[1].zA)
		return regionPos, AssociatedPos
	end

	local targetPos = nil
	if targetPosition then
		targetPos = targetPosition
	else
		targetPos = game._HostPlayer:GetPos()
	end

	local regionPos = Vector3.New(linkData.Portal[1].x, linkData.Portal[1].y, linkData.Portal[1].z)
	local AssociatedPos = Vector3.New(linkData.Portal[1].xA,linkData.Portal[1].yA,linkData.Portal[1].zA)
	local distance = SqrDistanceH(targetPos.x,targetPos.z, regionPos.x,regionPos.z)
	
	for i = 2,#linkData.Portal do
		local pos = linkData.Portal[i] 
		local delta = SqrDistanceH(targetPos.x,targetPos.z, pos.x,pos.z)
		if distance > delta  then
			regionPos = Vector3.New(pos.x, pos.y, pos.z)
			AssociatedPos = Vector3.New(pos.xA, pos.yA, pos.zA)
			distance = delta
		end	
	end

	return regionPos, AssociatedPos	
end

--获取联通数据 返回参数 isNone 是否联通 regionPos 联通的区域坐标  AssociatedPos 传送到新地图的初始坐标
def.method("number","table","=>","boolean","table","table").GetTransLinkAndAssociatedPosByMapAndPos = function(self, targetMapID, targetPos)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	if self._TableMapLink[nCurMapID] == nil then
	    warn("MapLinkInfo数据错误，"..nCurMapID.."不存在！！","tip", 3)
		game._HostPlayer: SetAutoPathFlag(false)   
	return false, nil,nil end

	local linkData =  self._TableMapLink[nCurMapID][targetMapID]
	if linkData == nil then
		warn("场景:"..nCurMapID.."与"..targetMapID.."不连通，没有传送点","tip",debug.traceback())
		game._HostPlayer: SetAutoPathFlag(false)   
	return false,nil,nil end	

	return linkData.Nonstop,GetNearPortalAndAssociatedPosByMap(linkData, targetPos)
end

def.method("table", "boolean", "=>", "boolean").CanMoveToTargetPosAtSameMap = function(self, targetPos, showFailedWarning)
	local playerPos = game._HostPlayer:GetPos()	
	local retcode = GameUtil.PathFindingCanNavigateTo(playerPos, targetPos, _G.NAV_STEP)
	if showFailedWarning and not retcode then
		local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图	
		warn("目标点NavMesh不可达 mapId =", nCurMapID, "from ", playerPos, "to ", targetPos)
	end
	return retcode
end

def.method("number","table","=>","boolean").CanMoveToTargetPosAtOtherMap = function(self, nMapID, targetPos)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图	
	local playerPos = game._HostPlayer:GetPos()	
	if nCurMapID == nMapID then
		warn("error function call, plz replace CanMoveToTargetPosAtOtherMap with CanMoveToTargetPosAtSameMap")
		return false
	end

	local sceneData = MapBasicConfig.GetMapBasicConfigBySceneID(nCurMapID)
	if(sceneData == nil) then return nil end
	if self._TableMapLink[nCurMapID] == nil then
    	warn("MapLinkInfo数据错误，"..nCurMapID.."不存在！！","tip", 3)
		return false 
	end

	local navmeshName = MapBasicConfig.GetNavmeshName(nMapID)
	if navmeshName == nil then return false end
	local isNonstop, regionPos, associatedPos = self:GetTransLinkAndAssociatedPosByMapAndPos(nMapID, nil)
	if isNonstop then					
		if GameUtil.PathFindingCanNavigateTo(playerPos, regionPos) then
			return GameUtil.PathFindingCanNavigateTo(associatedPos, targetPos, _G.NAV_STEP)		
		else
			warn("PathFindingCanNavigateTo:当前点到传送点不可达！")
			return false
		end	
	else
		local rotationPos,landpos = GetLandRotationAndPosByMapID(nMapID)
		if landpos == nil then
			warn("Form::"..nCurMapID.."  TO  "..nMapID.."不连通！！！")
			return false
		else
			return GameUtil.PathFindingCanNavigateTo(landpos, targetPos, _G.NAV_STEP)
		end	
	end
end

--判断某地图的某一个点，是否可达
def.method("number","table","=>","boolean").CanMoveToTargetPos = function(self, nMapID, targetPos)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图	
	local playerPos =  game._HostPlayer:GetPos()		
	if nCurMapID == nMapID then
		return self:CanMoveToTargetPosAtSameMap(targetPos, true)
	else
		return self:CanMoveToTargetPosAtOtherMap(nMapID, targetPos)		
	end
end

--判断传送之后出生点可达性
local function CheckAssociaMoveState(nMapID, targetPos)
	local tableRegionData = MapBasicConfig.GetAllPortalRegion(nMapID)

	if tableRegionData == nil then 
		warn("地图区域数据错误！检查mapbasicinfo,MapID: ",nMapID)
		return false
	end
	
	local navmeshName = MapBasicConfig.GetNavmeshName(nMapID)
	if(navmeshName == nil) then return false end

	for i, v in pairs(tableRegionData) do
		if v ~= nil then
			if GameUtil.CanNavigateToXYZ(navmeshName, v.xA, v.yA, v.zA, targetPos.x, targetPos.y, targetPos.z, _G.NAV_STEP) then
				return true
			end
		end	
	end	

	return false	
end

--判断能否到达，包括了不连通关系的判断
def.method("number","table","=>","boolean").CheckMoveToTargetPosResult = function(self, nMapID, targetPos)
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	local hostPosX, hostPosY, hostPosZ =  game._HostPlayer:GetPosXYZ()

	if nCurMapID == nMapID then
		local isCanMove = GameUtil.PathFindingCanNavigateToXYZ(hostPosX, hostPosY, hostPosZ, targetPos.x, targetPos.y, targetPos.z, _G.NAV_STEP)
		--判断所有的传送点，是否和目标点连通，然后传送到目标点
		if not isCanMove then
			isCanMove = CheckAssociaMoveState(nMapID, targetPos)
		end
		return isCanMove
	else
		local navmeshName = MapBasicConfig.GetNavmeshName(nMapID)
		if(navmeshName == nil) then return false end	

		local isNonstop, regionPos, AssociatedPos = self: GetTransLinkAndAssociatedPosByMapAndPos(nMapID, nil)

		if isNonstop then
			if GameUtil.CanNavigateToXYZ(nil, hostPosX, hostPosY, hostPosZ, regionPos.x, regionPos.y, regionPos.z, _G.NAV_STEP) then
				local isCanMove = GameUtil.CanNavigateToXYZ(navmeshName, AssociatedPos.x, AssociatedPos.y, AssociatedPos.z, targetPos.x, targetPos.y, targetPos.z, _G.NAV_STEP)	
				--判断所有的传送点，是否和目标点连通，然后传送到目标点
				if not isCanMove then
					isCanMove = CheckAssociaMoveState(nMapID, targetPos)
				end

				return isCanMove
			else
				warn("CanMoveToTargetPos:当前点到传送点不可达！")
				return false
			end
 		else
			local rotationPos,landpos = GetLandRotationAndPosByMapID(nMapID)
			if landpos == nil then
				warn("Form::"..nCurMapID.."  TO  "..nMapID.."不连通！！！")
				return false
			else		
				local isCanMove = false
				local navmeshName = MapBasicConfig.GetNavmeshName(nMapID)
				isCanMove = navmeshName ~= nil and GameUtil.CanNavigateToXYZ(navmeshName, landpos.x, landpos.y,landpos.z, targetPos.x, targetPos.y, targetPos.z, _G.NAV_STEP)
				--判断所有的传送点，是否和目标点连通，然后传送到目标点
				if not isCanMove then
					isCanMove = CheckAssociaMoveState(nMapID, targetPos)
				end

				return isCanMove
			end	
		end		
	end
end

--通过目标地图ID取距离玩家最近的传送点
def.method("number", "=>", "table").GetNearPortalByMap = function(self, mapID)
	local nMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
	
	--需要判断目标能不能传送到达
	if self._TableMapLink[nMapID] == nil then
	    warn("MapLinkInfo数据错误，"..nMapID.."不存在！！","tip", 5)
	return nil end

	local linkData =  self._TableMapLink[nMapID][mapID]
	return self:GetNearPortalByData(linkData, nil)
end


CTransDataHandler.Commit()
return CTransDataHandler