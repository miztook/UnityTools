local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CTransStrategyBase = require "Transfer.CTransStrategyBase"
local CTransDataHandler = require "Transfer.CTransDataHandler"
local EWorldType = require "PB.Template".Map.EWorldType
local CLinkedMapTrans = Lplus.Extend(CTransStrategyBase, "CLinkedMapTrans")
local def = CLinkedMapTrans.define

def.field("number")._FinalMapID = -1

def.static("=>", CLinkedMapTrans).new = function()
    local obj = CLinkedMapTrans()
    print("创建 CLinkedMapTrans")
    return obj
end

--def.field("number")._MapID = 0
--def.field("table")._TargetPosition = nil
--def.field("number")._IsTransOver = false
--def.field("function")._CallBack = nil
--def.field("table")._FinalPosition = nil

def.method("number").SetFinalMapID = function(self, finalMapID)
    self._FinalMapID = finalMapID
end

def.override().StartTransLogic = function(self)
    self._IsTransOver = false
    self._TargetPosition = self._FinalPosition
    self._FinalMapID = self._MapID
    local hp = game._HostPlayer
    local nCurMapID = game._CurWorld._WorldInfo.SceneTid
    local map_info_data = CTransDataHandler.Instance():GetMapInfoData(self._MapID)
    local map_link_data = CTransDataHandler.Instance():GetMapLinkData(nCurMapID)
	local linkData =  map_link_data[self._MapID]
    if linkData == nil then 
        warn("error !!! 地图不连通，当前地图ID: ",nCurMapID,"  目标地图ID： ", self._MapID) 
        return 
    end
    local offset = 0
    hp: HaveTransOffset(false)

	--如果目标地图是相位，需要特殊处理
	if map_info_data.MapType == EWorldType.Pharse then			
		if linkData.Portal ~= nil and linkData.Portal[1] ~= nil then
			local isNonstop, _ = CTransDataHandler.Instance():GetTransLinkDataByMapAndPosition(self._MapID,nil)
			if isNonstop then
				local regionPos = Vector3.New(linkData.Portal[1].x, linkData.Portal[1].y, linkData.Portal[1].z)
                hp:SetAutoPathFlag(true)
                if hp:CheckAutoHorse(self._TargetPosition) then 
    		    --寻路自动上马逻辑
				    hp:NavMountHorseLogic(self._TargetPosition)
    		    end  
				game:NavigatToPos(regionPos, 0, nil, nil)
			else
				warn("相位传送错误当前地图ID："..nCurMapID..",目标地图ID：",self._MapID)
			end					
		return end

		if linkData.Region == nil then
			warn("地图:"..nCurMapID.."没有进入相位的区域")
		end

		local RegionData = linkData.Region[1]
		if RegionData == nil then
			warn("地图:"..nCurMapID.."进入相位区域错误")
		return end

		if RegionData.sceneId == nCurMapID then --联通地图，直接寻路
			local regionPos = Vector3.New(RegionData.x, RegionData.y, RegionData.z)
			hp: SetAutoPathFlag(true)
            if hp:CheckAutoHorse(regionPos) then 
				hp:NavMountHorseLogic(regionPos)
    		end
            local function successCb()
                self:ReachTarget() 
            end
            game:NavigatToPos(regionPos, offset, successCb, nil)
		else--不同地图，传送，踩点
			local isNonstop, regionPos = CTransDataHandler.Instance():GetTransLinkDataByMapAndPosition(RegionData.sceneId,nil)
			if isNonstop then
                hp:SetAutoPathFlag(true) 
                if hp:CheckAutoHorse(regionPos) then 
				    hp:NavMountHorseLogic(regionPos)
    		    end  
				game:NavigatToPos(regionPos, offset, nil, nil)
            else
                warn("error !!! 传送联通策略里面的数据确是不连通")
			end
		end
	else
        --直接传送，踩传送点
	    if linkData.Nonstop then	
		    if linkData.Portal == nil then
			    warn("地图"..nCurMapID.."传送点错误！！","tip",2)
			    hp: SetAutoPathFlag(false)   
		    return end

		    local regionPos = CTransDataHandler.Instance():GetNearPortalByData(linkData, nil)
		    if regionPos == nil then return end
            hp:SetAutoPathFlag(true) 
            if hp:CheckAutoHorse(self._TargetPosition) then 
    	    --寻路自动上马逻辑
			    hp:NavMountHorseLogic(self._TargetPosition)
    	    end
            game:NavigatToPos(regionPos, offset, nil, nil)
        else
            warn("error !!! 传送联通策略里面的数据确是不连通(非相位情况)")
	    end
    end
end

def.override().BrokenTrans = function(self)
    self._IsTransOver = true
    self._FinalMapID = -1
end

--到达目标点
def.method().ReachTarget = function(self)
    if self._CallBack ~= nil then
        self._CallBack()
        self._CallBack = nil
    end

    self:BrokenTrans()
end


def.override().ContinueTrans = function(self)
    local hp = game._HostPlayer
	local nCurMapID = game._CurWorld._WorldInfo.SceneTid
    if nCurMapID ~= self._FinalMapID then
        return
    end
    if self._FinalMapID > 0 then
        self._TransMan:StartMoveByMapIDAndPos(self._FinalMapID, self._TargetPosition, nil, self._TransMan:IsSearchNpc(), self._TransMan._IsIgnoreConnected)
        self._FinalMapID = -1
        return
    end

	if self._TargetPosition ~= nil then		
        CTransStrategyBase.RaiseEvent(self, self._MapID, self._TargetPosition)
        if self._MapID == nCurMapID then
            hp: SetAutoPathFlag(true)  
			if hp:CheckAutoHorse(self._TargetPosition) then 
    		--寻路自动上马逻辑
				hp:NavMountHorseLogic(self._TargetPosition)
    		end  
			game:NavigatToPos(self._TargetPosition, 0, function() self:ReachTarget() end, nil)
        else
            --连通的情况下走原来逻辑，不连通走新的传送逻辑
		    if CTransDataHandler.Instance():CanMoveToTargetPosAtOtherMap(self._MapID, self._TargetPosition) then
			    local on_reach = function()      
                    self:ReachTarget()  	
   	            end
   	            local offset = 0
   	            if hp._IsHaveTransOffset or self._TransMan:IsSearchNpc() then offset = _G.NAV_OFFSET end

   	            hp: SetAutoPathFlag(true)
                if hp:CheckAutoHorse(self._TargetPosition) then 
		            hp:NavMountHorseLogic(self._TargetPosition)
                end
	            game:NavigatToPos(self._TargetPosition, offset, on_reach, nil)
	            --需要在地图上显示
	            local cMap = require "GUI.CPanelMap"	      
                cMap.Instance(): TransMapShow(self._TargetPosition)
                if cMap.Instance():IsShow() then
                    game._GUIMan:Open("CPanelMap", nil)
                end

		    else
			    local movePos = self._TransMan:GetForceTransDestPos(nCurMapID,self._TargetPosition)	
			    if movePos == nil then
				    self:ReachTarget()
				    hp: SetAutoPathFlag(false)  
				    warn("同地图不连通。寻找传送点失败") 
			    return end
			    --需要在地图上显示
			    local cMap = require "GUI.CPanelMap"	      
       	 	    cMap.Instance(): TransMapShow(movePos)
        	    if cMap.Instance():IsShow() then
        		    game._GUIMan:Open("CPanelMap", nil)
        	    end
        	    hp: SetAutoPathFlag(true)
        	    if hp:CheckAutoHorse(movePos) then 
    			    --寻路自动上马逻辑
				    hp:NavMountHorseLogic(movePos)
    		    end   			
        	    game:NavigatToPos(movePos, 0, nil, nil)
		    end
        end
	else
		self:ReachTarget()
	end
end

CLinkedMapTrans.Commit()
return CLinkedMapTrans