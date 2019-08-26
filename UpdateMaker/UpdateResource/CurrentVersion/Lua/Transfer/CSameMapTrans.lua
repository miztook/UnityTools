local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CTransStrategyBase = require "Transfer.CTransStrategyBase"
local CTransDataHandler = require "Transfer.CTransDataHandler"
local EWorldType = require "PB.Template".Map.EWorldType
local CSameMapTrans = Lplus.Extend(CTransStrategyBase, "CSameMapTrans")
local def = CSameMapTrans.define

def.static("=>", CSameMapTrans).new = function()
    local obj = CSameMapTrans()
    --print("创建 CSameMapTrans")
    return obj
end

def.override().StartTransLogic = function(self)
    local curMapID = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
    self._TargetPosition = self._FinalPosition

	local hp = game._HostPlayer
    local is_search_npc = self._TransMan:IsSearchNpc()
    local offset = is_search_npc and _G.NAV_OFFSET or 0
    hp:HaveTransOffset(is_search_npc)

    local change2TransDestPos = false
    if not CTransDataHandler.Instance():CanMoveToTargetPosAtSameMap(self._TargetPosition, false) then  -- 不连通
        local validPos = GameUtil.GetNearestValidPosition(self._TargetPosition, 3)
        if validPos ~= nil then
            if GameUtil.PathFindingCanNavigateTo(hp:GetPos(), validPos, _G.NAV_STEP) then  -- 在同一连通区
                self._TargetPosition = validPos
            else
                -- 非连通区，走传送点
                local movePos = self._TransMan:GetForceTransDestPos(curMapID, self._FinalPosition)
                if movePos ~= nil then
                    self._TargetPosition = movePos
                    change2TransDestPos = true
                else
                    self:BrokenTrans()
                    warn("CSameMapTrans StartTransLogic Failed, bcz 目标点不可达 && 无法在附近找到有效点 && 没有传送区相连")
                    return 
                end
            end
        else
            self:BrokenTrans()
            warn("CSameMapTrans StartTransLogic Failed, bcz 目标点无效")
            return 
        end
    end

    hp:SetAutoPathFlag(true) 
    if hp:CheckAutoHorse(self._TargetPosition) then 
        --寻路自动上马逻辑
        hp:NavMountHorseLogic(self._TargetPosition)
    end

    local offsetDis = 0
	local onReach = nil
    if not change2TransDestPos then
        onReach = function()
                if curMapID ~= self._MapID then
                    self._IsTransOver = false
                else
        		    self:BrokenTrans()
                    if self._CallBack ~= nil then
                        self._CallBack()
                        self._CallBack = nil
                    end
                    self._IsTransOver = true
                end
            end
        offsetDis = offset
    else
        onReach = function() self._IsTransOver = false end
    end
    
    self._IsTransOver = false
    TeraFuncs.NavigatToPos(self._TargetPosition, offsetDis, onReach, nil)

    -- 检测如果是直接连通的，并且已经到当前的地图了，就不再继续寻路，防止点击到了同步传送区域内部而无限来回跑的问题。
    if (self._FinalPosition and CTransDataHandler.Instance():CanMoveToTargetPosAtSameMap(self._FinalPosition, false)) and curMapID == self._MapID then
        self._IsTransOver = true
    end
end

def.override().BrokenTrans = function(self)
    if self._IsTransOver then return end 
    self._IsTransOver = true
end

def.override().ContinueTrans = function(self)
    local cur_scene_tid = game._CurWorld._WorldInfo.SceneTid
    local map_info_data = CTransDataHandler.Instance():GetMapInfoData(self._MapID)
    local cur_info_data = CTransDataHandler.Instance():GetMapInfoData(cur_scene_tid)
    if cur_scene_tid ~= self._MapID and map_info_data.MapType ~= EWorldType.Pharse and cur_info_data.MapType ~= EWorldType.Pharse then
        self._TransMan:BrokenTrans()
        self._IsTransOver = true
        return
    end

    if not self._IsTransOver then
        local onReach = function()
		    self:BrokenTrans()
            if self._CallBack ~= nil then
                self._CallBack()
                self._CallBack = nil
            end
            self._IsTransOver = true
        end
        local is_search_npc = self._TransMan:IsSearchNpc()
	    local offset = is_search_npc and _G.NAV_OFFSET or 0
        local hp = game._HostPlayer
        hp: HaveTransOffset(is_search_npc)	
        hp:SetAutoPathFlag(true) 
        
        if hp:CheckAutoHorse(self._FinalPosition) then  --寻路自动上马逻辑
		    hp:NavMountHorseLogic(self._FinalPosition)
        end
        CTransStrategyBase.RaiseEvent(self, self._MapID, self._FinalPosition)
        self._TransMan:StartMoveByMapIDAndPos(self._MapID, self._FinalPosition, nil, self._TransMan:IsSearchNpc(), self._TransMan:IsIgnoreConnected())
    end
end

CSameMapTrans.Commit()
return CSameMapTrans