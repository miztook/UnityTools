local Lplus = require "Lplus"
local CElementData = require "Data.CElementData"
local CEntity = require "Object.CEntity"
local MapBasicConfig = require "Data.MapBasicConfig" 
local CTransDataHandler = require "Transfer.CTransDataHandler"
local EWorldType = require "PB.Template".Map.EWorldType
local CSameMapTrans = require "Transfer.CSameMapTrans"
local CLinkedMapTrans = require "Transfer.CLinkedMapTrans"
local CRightNowTrans = require "Transfer.CRightNowTrans"
local CTransUtility = require "Transfer.CTransUtility"
local ServerMessageMap = require "PB.data".ServerMessageMap
local CGame = Lplus.ForwardDeclare("CGame")

local CTransManage = Lplus.Class("CTransManage")
local def = CTransManage.define

def.field("function")._OnEnd = nil                      -- 到达回调
def.field("function")._OnMsgboxCB = nil                 -- 如果在副本或者相位内寻到大世界，弹msgbox之后点击取消需要做的事。
def.field('boolean')._IsIgnoreConnected = false         -- 是否忽略连通关系(如果是连通地图，而且这个bool为true的时候也要传送过去，而不是跑路)
def.field("table")._TransStrategy = nil                 -- 当前策略
def.field("table")._TransStrategyCache = nil            -- 策略缓存
def.field("table")._EnterRegionData = nil               -- 区域寻路数据结构 isbroken = 是否边界打断  regionID = 寻路区域ID
def.field("table")._TableMapOpenData = nil              -- 区域地图开启状态
def.field("number")._TransMapID = 0                     -- 传送到城镇的ID
def.field("boolean")._IsSearchNpc = false               -- 是否正在进行npc传送
def.field("boolean")._IsInManualMode = true             -- 是否是手动开启寻路（当在相位中，用来检测是否弹离开相位tip）
def.field("table")._TransRegionPos = nil                -- 传送区域的坐标
def.field("number")._TransRegionPosMapID = 0            -- 传送区域的坐标存在的MapID
def.field("boolean")._IsSyncAutoPath = false            -- 是否是正在寻路（向服务器发送AutoPath）
def.field("boolean")._IsShowingMsgBox = false           -- 是否正在提示玩家当前是相位，是否离开相位。（如果正在提示的话，外部再调寻路接口不让它寻路）

local instance = nil
def.static("=>", CTransManage).Instance = function () 	
	if instance == nil then
		instance = CTransManage()
	end

	return instance
end

--到达目标点
local function ReachTarget()
    if instance._OnEnd ~= nil then
        instance._OnEnd()
        instance._OnEnd = nil
    end

    instance:BrokenTrans()
end

--进入区域事件
local function OnEnterRegionEvent(sender, event)
    local regionID = event.RegionID
    local isEnter = event.IsEnter
    if instance._EnterRegionData ~= nil and instance._EnterRegionData._isBroken and instance._EnterRegionData._RegionID == regionID then
        game._HostPlayer:StopNaviCal()
        instance._EnterRegionData = nil
        ReachTarget()
    end
end

-- 设置传送策略
local function SetStrategyTrans(self, strategy)
    if self._TransStrategy ~= nil then
        self._TransStrategy:BrokenTrans()
        self._TransStrategy = nil
    end
    self._TransStrategy = strategy
    self._TransStrategy:StartTransLogic()
end

local function CheckIsInPharse(self, mapID, cb, syncServer)
    if self._IsShowingMsgBox then print("正在弹提示，不要再寻路了。。。。。") return end
    local callback = function(val)
        if val then
            if cb ~= nil then
                cb()
            end
            if syncServer then
                self:SyncHostPlayerDestMapInfo(true, mapID)
            end
        else
--            local CAutoFightMan = require "AutoFight.CAutoFightMan"
--            local CQuestAutoMan = require "Quest.CQuestAutoMan"
--            local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
--            CAutoFightMan.Instance():Start()
--		    CDungeonAutoMan.Instance():Start()
--		    CQuestAutoMan.Instance():Restart(_G.PauseMask.UIShown)
            if self._OnMsgboxCB ~= nil then
                self._OnMsgboxCB(val)
            end
        end
        self._OnMsgboxCB = nil
        self._IsInManualMode = true
        self._IsShowingMsgBox = false
    end

    if game._CurWorld._WorldInfo.SceneTid ~= mapID then
        if game._CurMapType == EWorldType.Pharse and self._IsInManualMode then
            local title, msg, closeType = StringTable.GetMsg(82)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
            self._IsShowingMsgBox = true
        elseif game._CurMapType == EWorldType.Immediate and self._IsInManualMode then
            local title, msg, closeType = StringTable.GetMsg(97)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
            self._IsShowingMsgBox = true
        elseif game._CurMapType == EWorldType.Instance and self._IsInManualMode then
            local title, msg, closeType = StringTable.GetMsg(97)
            MsgBox.ShowMsgBox(msg, title, closeType, MsgBoxType.MBBT_OKCANCEL, callback)
            self._IsShowingMsgBox = true
        end
        if self._IsShowingMsgBox then
            game:StopAllAutoSystems()
            return
        end
    end

    callback(true)
end

local function SelectAGoodMapLinkedDesMap(self, desmapID)
    local map_link_data = CTransDataHandler.Instance():GetMapLinkData(desmapID)
    local cur_scene_tid = game._CurWorld._WorldInfo.SceneTid
    if map_link_data == nil then return -1 end
    for k,v in pairs(map_link_data) do
        repeat
            local map_temp = CElementData.GetMapTemplate(k)
            if map_temp == nil then break end
            if map_temp.WorldType == EWorldType.Pharse or map_temp.WorldType == EWorldType.Instance then break end
            if self:HaveReachToMap(k) and k ~= cur_scene_tid and k ~= game._GuildMan:GetGuildSceneTid() then
                return k
            end
        until true;
    end
    return -1
end

-- 不能到达弹提示未解锁
local function ShowCantTransMsgBox()
    local template = CElementData.GetSystemNotifyTemplate(ServerMessageMap.TransPosNotUnlock)
    local message = ""
    if template == nil then
        message = "Unkownn message"
    else
        message = template.TextContent
    end
    
    -- 在任务自动战斗中，如果点击另外未曾到达地图的任务，弹出无法直达的提示
    -- 此时需要暂停自动战斗，因为Tick逻辑会一直弹出该MsgBox
    local CAutoFightMan = require "AutoFight.CAutoFightMan"
    local CQuestAutoMan = require "Quest.CQuestAutoMan"
    local function cb()
        CAutoFightMan.Instance():Restart(_G.PauseMask.UIShown)
    end

    CAutoFightMan.Instance():Pause(_G.PauseMask.UIShown)
    CQuestAutoMan.Instance():Stop()
    local title = template and template.Title or "Unknown title"
    local close_type = EnumDef.CloseType.ClickAnyWhere
    if template and template.IsShowCloseBtn then
        close_type = EnumDef.CloseType.CloseBtn
    else
        close_type = EnumDef.CloseType.ClickAnyWhere
    end
    MsgBox.ShowMsgBox(message, title, close_type, MsgBoxType.MBBT_OK, cb)
end

-- 移动到同图某点
-- 自动显示“自动寻路”标志，自动检查 是否需要上马
local function StartMoveToPosAtSameMap(self, mapID, targetPos, callback)
    local cb = function()
        local strategy = nil
        if self._TransStrategyCache["CSameMapTrans"] ~= nil then
            strategy = self._TransStrategyCache["CSameMapTrans"]
        else
            strategy = CSameMapTrans.new()
            self._TransStrategyCache["CSameMapTrans"] = strategy
        end

        local function realCallback()
            if callback ~= nil then
                callback()
            end
            self._TransStrategy = nil
        end
        strategy:Init(self, mapID, targetPos, realCallback)
        SetStrategyTrans(self, strategy)
    end
    CheckIsInPharse(self, mapID, cb, true)
end

-- 移动到本地图连通的某地图某点
local function TransToLinkedMap(self, mapID, pos, functionName, finalMapID)
    --print("联通地图寻路",mapID, debug.traceback())
    local callback = function()
        local strategy = nil
        if self._TransStrategyCache["CLinkedMapTrans"] ~= nil then
            strategy = self._TransStrategyCache["CLinkedMapTrans"]
        else
            strategy = CLinkedMapTrans.new()
            self._TransStrategyCache["CLinkedMapTrans"] = strategy
        end
        
        local function realCallback()
            if functionName ~= nil then
                functionName()
            end
            self._TransStrategy = nil
        end
        strategy:Init(self, mapID, pos, realCallback)
        strategy:SetFinalMapID(finalMapID or -1)
        SetStrategyTrans(self, strategy)
    end
    CheckIsInPharse(self, mapID, callback, true)
end


-- 直接传送到某地图，然后移动到某点
local function RightNowTransToMap(self, transType, transIdOrMapId, pos, rot, functionName, finalMapID)
    if (transIdOrMapId <= 0) then return end
    if game._HostPlayer:GetTransPortalState() then return end
    if game._HostPlayer:IsInGlobalZone() then
        game._GUIMan:ShowTipText(StringTable.Get(15556), false)
        return
    end
    local callback = function()
        local strategy = nil
        if self._TransStrategyCache["CRightNowTrans"] ~= nil then
            strategy = self._TransStrategyCache["CRightNowTrans"]
            strategy:ReSetData(transType, rot, finalMapID or -1)
        else
            strategy = CRightNowTrans.new(transType, rot, finalMapID or -1)
            self._TransStrategyCache["CRightNowTrans"] = strategy
        end

        local function realCallback()
            if functionName ~= nil then
                functionName()
            end
            self._TransStrategy = nil
        end

        strategy:Init(self, transIdOrMapId, pos, realCallback)
        SetStrategyTrans(self, strategy)
        game._HostPlayer:SetTransPortalState(true)
    end
    CheckIsInPharse(self, transIdOrMapId, callback, false)
end

--通过传送点ID前往地图的传送点
local function TransToMapPortalByTransID(self, ntransID)
    if game._HostPlayer:GetTransPortalState() then return end
    local nMapID = CTransUtility.GetTransToPortalMapID(ntransID)
    local trans_temp = CElementData.GetTemplate("Trans", ntransID)
    local new_pos = Vector3.New(trans_temp.x, trans_temp.y, trans_temp.z)
    local new_rot = Vector3.New(trans_temp.RotationX, trans_temp.RotationY, trans_temp.RotationZ)
    if ntransID <= 0 then
        self:BrokenTrans() 
        warn("不连通，地图"..nMapID.."传送门也不存在！","tip", 5)
    return end

    if self:HaveReachToMap(nMapID) then
        self._TransMapID = nMapID
        game._GUIMan:Close("CPanelMap")
        self:SyncHostPlayerDestMapInfo(true, self._TransMapID)
        RightNowTransToMap(self, EnumDef.ETransType.TransToPortal, ntransID, nil, new_rot, nil)
    else
        ShowCantTransMsgBox()
    end
end

--通过地图ID前往地图的传送点
local function TransToMapPortalByMapID(self, nMapID, pos, callback)
    local host = game._HostPlayer
    if nMapID <= 0 then 
        warn("传送地图ID错误！","tip", 3)
        --host: SetAutoPathFlag(false) 
        self:BrokenTrans()
    return end

    if game._HostPlayer:GetTransPortalState() then return end

    local ntransID = CTransUtility.GetPortalIDByMapID(nMapID)
    if ntransID <= 0 then
        warn("地图"..nMapID.."没有传送门！","tip", 3)
        --host: SetAutoPathFlag(false) 
        self:BrokenTrans()
    return end

    if (not self:HaveReachToMap(nMapID)) and nMapID ~= game._GuildMan:GetGuildSceneTid() then
        local template = CElementData.GetSystemNotifyTemplate(ServerMessageMap.TransPosNotUnlock)
        local message = ""
        if template == nil then
            message = "Unkownn message"
        else
            message = template.TextContent
        end
        
        local title = template and template.Title or "Unknow title"
        local close_type = EnumDef.CloseType.ClickAnyWhere
        if template and template.IsShowCloseBtn then
            close_type = EnumDef.CloseType.CloseBtn
        else
            close_type = EnumDef.CloseType.ClickAnyWhere
        end
        MsgBox.ShowMsgBox(message, title, close_type, MsgBoxType.MBBT_OK)
    else
        self._TransMapID = nMapID
        game._GUIMan:Close("CPanelMap")
        --self:SyncHostPlayerDestMapInfo(true, self._TransMapID)
        RightNowTransToMap(self, EnumDef.ETransType.TransToPortal, ntransID, pos, nil, callback)
    end
end

-- 不同场景ID传送逻辑
local function RunDifferentMapIDLogic(self, nCurMapID, mapID, targetPos, functionName)
    --if game._HostPlayer:GetTransPortalState() then warn("正在传送中。。。") return end
    local cur_map_temp = CElementData.GetMapTemplate(game._CurWorld._WorldInfo.MapTid)
    local des_map_temp = CElementData.GetMapTemplate(mapID)
    if cur_map_temp == nil then 
        warn("mapID:"..mapID.."模板错误","tip",2)
        return 
    end
    if des_map_temp == nil then
        warn("目标地图模板错误，mapID:"..mapID,"tip",2)
    end

    local hp = game._HostPlayer
    local map_info_data = CTransDataHandler.Instance():GetMapInfoData(mapID)
    local map_link_data = CTransDataHandler.Instance():GetMapLinkData(nCurMapID)

    --需要判断目标能不能传送到达
    if map_link_data == nil then
        warn("MapLinkInfo数据错误，"..nCurMapID.."不存在！！","tip", 3)
        hp: SetAutoPathFlag(false)
    return end

    if map_info_data == nil then
        warn("目标地图数据错误，"..mapID.."不存在！！","tip", 3)
        hp: SetAutoPathFlag(false)
    return end
    -- 如果是即时副本或者副本的话，走副本传送逻辑
    if map_info_data.MapType == EWorldType.Instance or map_info_data.MapType == EWorldType.Immediate then
        --print("地图是副本")
        self:TransToInstance(mapID, targetPos, functionName, self._IsSearchNpc)
        return
    end

    -- 如果目标地图是相位
    if map_info_data.MapType == EWorldType.Pharse then
        -- 如果当前地图是相位
        if game._CurMapType == EWorldType.Pharse then
            -- 两个相位大世界是同一个
            if cur_map_temp.AssociatedPathfindingMainMapId == des_map_temp.AssociatedPathfindingMainMapId then
                StartMoveToPosAtSameMap(self, mapID, targetPos,functionName)
            else
                local asso_map_link_data = CTransDataHandler.Instance():GetMapLinkData(cur_map_temp.AssociatedPathfindingMainMapId)
                if asso_map_link_data == nil then
                    warn("MapLinkData is nil, cur_map_temp.AssociatedPathfindingMainMapId =", cur_map_temp.AssociatedPathfindingMainMapId)
                    return
                end
                -- 当前相位和目标相位的附属大世界是否联通 or  当前相位附属地图和目标相位的附属大世界是否联通
                if (map_link_data[des_map_temp.AssociatedPathfindingMainMapId] ~= nil or asso_map_link_data[des_map_temp.AssociatedPathfindingMainMapId] ~= nil) then
                    -- 走连通逻辑之前先判断是否是忽略连通，如果忽略连通，直接传过去
                    if self._IsIgnoreConnected then
                        -- 虽然你是忽略连通，但是你没到过那个地图，还是要走连通逻辑----跑过去。
                        if self:HaveReachToMap(des_map_temp.AssociatedPathfindingMainMapId) then
                            RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, des_map_temp.AssociatedPathfindingMainMapId, targetPos, nil, functionName, mapID)
                        else
                            TransToLinkedMap(self, des_map_temp.AssociatedPathfindingMainMapId, targetPos, functionName, mapID)
                        end
                    else
                        TransToLinkedMap(self, des_map_temp.AssociatedPathfindingMainMapId, targetPos, functionName, mapID)
                    end
                else
                    if self:HaveReachToMap(des_map_temp.AssociatedPathfindingMainMapId) then
                        RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, des_map_temp.AssociatedPathfindingMainMapId, targetPos, nil, functionName, mapID)
                    else
                        local new_des_map = SelectAGoodMapLinkedDesMap(self, des_map_temp.AssociatedPathfindingMainMapId)
                        if new_des_map > 0 then
                            RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, new_des_map, targetPos, nil, functionName, mapID)
                        else
                            ShowCantTransMsgBox()
                        end
                    end
                end
            end
        else
            if des_map_temp.AssociatedPathfindingMainMapId == nCurMapID then
                --warn("StartMoveToPosAtSameMap", mapID, targetPos)
                StartMoveToPosAtSameMap(self, mapID, targetPos, functionName)
            else
                -- 当前地图和目标相位的附属大世界是否联通
                if map_link_data[des_map_temp.AssociatedPathfindingMainMapId] ~= nil then
                    if self._IsIgnoreConnected then
                        if self:HaveReachToMap(des_map_temp.AssociatedPathfindingMainMapId) then
                            RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, des_map_temp.AssociatedPathfindingMainMapId, targetPos, nil, functionName, mapID)
                        else
                            TransToLinkedMap(self, des_map_temp.AssociatedPathfindingMainMapId, targetPos, functionName, mapID)
                        end
                    else
                        TransToLinkedMap(self, des_map_temp.AssociatedPathfindingMainMapId, targetPos, functionName, mapID)
                    end
                else
                    --RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, des_map_temp.AssociatedPathfindingMainMapId, targetPos, nil, functionName)
                    if self:HaveReachToMap(des_map_temp.AssociatedPathfindingMainMapId) then
                        RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, des_map_temp.AssociatedPathfindingMainMapId, targetPos, nil, functionName, mapID)
                    else
                        local new_des_map = SelectAGoodMapLinkedDesMap(self, des_map_temp.AssociatedPathfindingMainMapId)
                        if new_des_map > 0 then
                            RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap,new_des_map, targetPos, nil, functionName, mapID)
                        else
                            ShowCantTransMsgBox()
                        end
                    end
                end
            end
        end
    else
        if game._CurMapType == EWorldType.Pharse then
            --当前地图是相位，特殊处理 如果相位是目标地图的附属地图，当做同场景传送
            if cur_map_temp.AssociatedPathfindingMainMapId == mapID then
                StartMoveToPosAtSameMap(self, mapID, targetPos,functionName)   
            else
                local asso_map_link_data = CTransDataHandler.Instance():GetMapLinkData(cur_map_temp.AssociatedPathfindingMainMapId)
                if (map_link_data[mapID] ~= nil or asso_map_link_data[mapID] ~= nil) then
                    if self._IsIgnoreConnected then
                        if self:HaveReachToMap(mapID) then
                            RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, mapID, targetPos, nil, functionName)
                        else
                            TransToLinkedMap(self, mapID, targetPos, functionName)
                        end
                    else
                        TransToLinkedMap(self, mapID, targetPos, functionName)
                    end
                else
                    --RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, mapID, targetPos, nil, functionName)
                    if self:HaveReachToMap(mapID) then
                        RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, mapID, targetPos, nil, functionName)
                    else
                        local new_des_map = SelectAGoodMapLinkedDesMap(self, mapID)
                        if new_des_map > 0 then
                            RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, new_des_map, targetPos, nil, functionName, mapID)
                        else
                            ShowCantTransMsgBox()
                        end
                    end
                end
            end
        else
            if map_link_data[mapID] ~= nil then
                if self._IsIgnoreConnected then
                    if self:HaveReachToMap(mapID) then
                        RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, mapID, targetPos, nil, functionName)
                    else
                        TransToLinkedMap(self, mapID, targetPos, functionName)
                    end
                else
                    TransToLinkedMap(self, mapID, targetPos, functionName)
                end
            else
                --RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, mapID, targetPos, nil, functionName)
                if self:HaveReachToMap(mapID) then
                    RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, mapID, targetPos, nil, functionName)
                else
                    local new_des_map = SelectAGoodMapLinkedDesMap(self, mapID)
                    if new_des_map > 0 then
                        RightNowTransToMap(self, EnumDef.ETransType.TransToWorldMap, new_des_map, targetPos, nil, functionName, mapID)
                    else
                        ShowCantTransMsgBox()
                    end
                end
            end
        end
    end
end

def.method().Init = function(self)
    self._TransStrategyCache = {}
    CGame.EventManager:addHandler('NotifyEnterRegion', OnEnterRegionEvent)
end

-- 加载数据
def.method().LoadAllTransTable = function (self)
    CTransDataHandler.Instance():LoadAllTransTable()
end

--传送到城市
def.method("number").TransToCity = function (self, nMapID)
    local hp = game._HostPlayer
    hp:StopAutoFollow()
    self:BrokenTrans()
    if hp:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), false)
    return end
    local map_temp = CElementData.GetMapTemplate(nMapID)
    local map_info_data = CTransDataHandler.Instance():GetMapInfoData(nMapID)
    local map_link_data = CTransDataHandler.Instance():GetMapLinkData(map_temp.AssociatedPathfindingMainMapId)
    if map_info_data == nil then
        warn("目标地图数据错误，"..nMapID.."不存在！！","tip", 3)
        hp: SetAutoPathFlag(false)
    return end
    -- 如果是即时副本或者副本的话，走副本传送逻辑
    if map_info_data.MapType == EWorldType.Instance or map_info_data.MapType == EWorldType.Immediate then
        self:TransToInstance(nMapID, nil, nil, false)
        return
    end

    if map_info_data.MapType == EWorldType.Pharse then
        if map_link_data[nMapID] ~= nil and map_link_data[nMapID].Region ~= nil then
            --print(map_temp.AssociatedPathfindingMainMapId,nMapID, map_link_data[nMapID], map_link_data[nMapID].x, map_link_data[nMapID].y, map_link_data[nMapID].z)
            local region = map_link_data[nMapID].Region[1]
            local pos = Vector3.New(region.x, region.y, region.z)
            self:StartMoveByMapIDAndPos(nMapID, pos, nil, false, false)
        else
            warn("error !!! CTransMange.TransToCity 传入的地图ID是相位，但是该地图联通坐标")
        end
        return
    end
    self:TransToPortalTargetByMapID(nMapID, nil)
end

--通过地图ID传送到地图传送门
def.method("number", "function").TransToPortalTargetByMapID = function(self, nMapID, callback)
    local hp = game._HostPlayer
    hp:StopAutoFollow()

    if hp:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), false)
    return end
    TransToMapPortalByMapID(self, nMapID, nil, callback)
end

--通过传送ID传送到地图传送门
def.method("number").TransToPortalTargetByTransID = function(self,ntransID)
    local hp = game._HostPlayer
    hp:StopAutoFollow()

    if hp:IsInServerCombatState() then
        game._GUIMan:ShowTipText(StringTable.Get(139), false)
    return end
    TransToMapPortalByTransID(self, ntransID)
end

--通过mapID和目标对象进行传送
def.method("number","string", "number","function","boolean").TransToSpecificEntity = function(self, mapID, entityType, entityTid,functionName,bIgnorConnect)
    local pos = MapBasicConfig.GetSpecificEntityInfo(mapID, entityType, entityTid)

    if pos ~= nil then
        local hp = game._HostPlayer
        hp:StopAutoFollow()   
        --self:BrokenTrans()   
        self:StartMoveByMapIDAndPos(mapID, pos,functionName, true,bIgnorConnect)

        if hp:CheckAutoHorse(pos) then 
            --寻路自动上马逻辑
            hp:NavMountHorseLogic(pos)
        end
    else
        warn("can not trans to " .. entityType .. " " .. entityTid .. " in map " .. mapID)
    end
end

--传送到区域。isBroken = 是否到区域打断 
def.method("number","number","boolean","function","boolean").TransToRegionIsNeedBroken = function(self,mapID,regionID,isBroken,functionName, bIgnorConnect)
    local pos = MapBasicConfig.GetRegionPos(mapID,regionID)
    if pos == nil then 
        warn("MapBasicConfig错误，区域："..regionID.."不存在！！","tip", 3)
        self._EnterRegionData = nil
        return 
    end
    --self:BrokenTrans()
    self._EnterRegionData = 
    {
      _isBroken = isBroken,
      _RegionID = regionID
    }

    self:StartMoveByMapIDAndPos(mapID,pos,functionName,false,bIgnorConnect)
end

--------------------------------------------------------------------------
-- 此函数只用作相位或大世界的传送和寻路规则
-- <mapID>目标场景</mapID>
-- <targetPos>目标地点</targetPos>
-- <functionName>到达之后回调函数</functionName>
-- <bSearchEntity>是否是在寻找npc或怪物,决定是否有offset</bSearchEntity>
-- <bIgnorConnect>当地图联通时，次参数决定传送过去与否</bIgnorConnect>
--------------------------------------------------------------------------
def.method("number","table","function","boolean","boolean").StartMoveByMapIDAndPos = function(self, mapID, targetPos, functionName, bSearchEntity, bIgnorConnect)
    --print("要寻路的地方是 mapID, targetPos, bSearchEntity, bIgnorConnect, " , mapID, targetPos, bSearchEntity, bIgnorConnect,debug.traceback())
    if mapID == nil or mapID <= 0 then
        warn("<color=#ff0000>注意!寻路地图非法是 NIL</color>")
        return 
    end

    if targetPos == nil then
        warn("<color=#ff0000>注意!地图ID："..mapID.."的寻路坐标是 NIL</color>")
        return 
    end

    local hp = game._HostPlayer

    local nLevel = hp._InfoData._Level
    local worldData = CElementData.GetMapTemplate(mapID)
    if worldData == nil then return end

    local nLimitedLV =  worldData.LimitEnterLevel
    if nLevel < nLimitedLV then
        game._GUIMan:ShowTipText(StringTable.Get(12008), false)
        return
    end
    
    hp:StopAutoFollow()

    self._OnEnd = functionName
    self._TransMapID = mapID
    self._IsIgnoreConnected = bIgnorConnect
    self._IsSearchNpc = bSearchEntity

    local cur_scene_tid = game._CurWorld._WorldInfo.SceneTid --玩家当前所在地图
    local function Action()
        --同场景传送和不同场景传送
        if cur_scene_tid == mapID then
            StartMoveToPosAtSameMap(self, cur_scene_tid, targetPos,self._OnEnd)  
        else
            RunDifferentMapIDLogic(self, cur_scene_tid, mapID, targetPos, self._OnEnd)
        end
    end

    if hp:IsInCanNotInterruptSkill() then
        hp:AddCachedAction(Action)
    else
        Action()
    end
end

--------------------------------------------------------------------------
-- 此函数只用作副本和及时副本的传送
-- <mapID>目标场景</mapID>
-- <targetPos>目标地点</targetPos>
-- <functionName>到达之后回调函数</functionName>
-- <bSearchEntity>是否是在寻找npc或怪物,决定是否有offset</bSearchEntity>
--------------------------------------------------------------------------
def.method("number","table","function","boolean").TransToInstance = function(self, mapID, targetPos, functionName, bSearchEntity)
    --print("传送到副本")
    self._OnEnd = functionName
    self._TransMapID = mapID
    self._IsSearchNpc = bSearchEntity
    local cur_scene_tid = game._CurWorld._WorldInfo.SceneTid
    local des_map_temp = CElementData.GetMapTemplate(mapID)
    local map_info_data = CTransDataHandler.Instance():GetMapInfoData(mapID)
    if des_map_temp == nil then warn("error 要传送的副本模板数据为空", mapID) return end
    if cur_scene_tid == mapID then warn("error  要传送的副本是当前副本") return end
    if map_info_data.MapType == EWorldType.Instance or map_info_data.MapType == EWorldType.Immediate then
        RightNowTransToMap(self, EnumDef.ETransType.TransToInstance, mapID, targetPos, nil, functionName)
    else
        warn("error 要传送到类型不是副本，但是调了传送到副本的接口")
    end
end

def.method().BrokenTrans = function(self)
    if self._TransStrategy == nil then return end

    --print("打断寻路",debug.traceback())

    self._TransStrategy:BrokenTrans()
    self._TransStrategy = nil
    self._TransMapID = 0    
    self._IsIgnoreConnected = false
    self._OnEnd = nil

    local hp = game._HostPlayer
    hp:ClearAutoPathTargetPos()
    hp:SetAutoPathFlag(false)
    hp:StopNaviCal()
    
    if self._IsSyncAutoPath then
        --print("BrokenTrans", debug.traceback())
        self:SyncHostPlayerDestMapInfo(false, 0)
        self._IsSyncAutoPath = false
    end

    local CPath = require"Path.CPath"
    if not CPath.Instance()._IsDungeonPath then 
        CPath.Instance():Hide()
    end
end

--跨图完成继续寻路
def.method().ContinueTrans = function(self)
    local host = game._HostPlayer
    if host == nil then return end
    host:SetTransPortalState(false)
    --game._GUIMan:SetNormalUIMoveToHide(false, 0, "", nil)
    GameUtil.SetCamToDefault(true, false, false, true) -- 重置相机水平方向

    if self._TransStrategy ~= nil then
        self._TransStrategy:ContinueTrans()
    end
end

--自动寻路中
def.method("=>","boolean").IsTransState = function(self)
    if self._TransStrategy == nil then return false end
	return not self._TransStrategy:IsTransOver()
end

def.method("=>", "boolean").IsSearchNpc = function(self)
    return self._IsSearchNpc
end

def.method("=>", "boolean").IsIgnoreConnected = function(self)
    return self._IsIgnoreConnected
end

def.method("function").SetLeaveMsgboxCB = function(self, cb)
    if self._OnMsgboxCB ~= nil then
        self._OnMsgboxCB(false)
        self._OnMsgboxCB = nil
    end
    self._OnMsgboxCB = cb
end

-- 设置是否是手动开启的任务自动化，仅对一次寻路请求有效
def.method("boolean").EnableManualModeOnce = function(self, isManual)
    self._IsInManualMode = isManual
end

--获取寻路数据，寻路地图ID， 寻路目标点
def.static("=>","number","table").GetTransData = function()
    if instance._TransStrategy == nil then return 0,nil end
	return instance._TransMapID,instance._TransStrategy._FinalPosition
end

--不连通的情况下，非要给他传过去！！！！！
def.method("number", "table", "=>", "table").GetForceTransDestPos = function(self, nMapID, targetPos)
	local tableRegionData = MapBasicConfig.GetAllPortalRegion(nMapID)
	if tableRegionData == nil then
		game._HostPlayer:StopNaviCal()  
		warn("地图区域数据错误！检查mapbasicinfo,MapID: ",nMapID)
		return nil
	end
	local navmeshName = MapBasicConfig.GetNavmeshName(nMapID)
	if(navmeshName == nil) then return nil end

	local hostX, hostY, hostZ = game._HostPlayer:GetPosXYZ()
    local path_table = {}
    local InPath = function(key)
        for i,v in ipairs(path_table) do
            if v == key then
                return true
            end
        end
        return false
    end

    -- 如果所到地方需要穿过好多navmesh， 递归地去寻找目标点，最终找到一个通路。
    local function RecursionFindTargetPos(fromX, fromY, fromZ, toX, toY, toZ)
        if GameUtil.CanNavigateToXYZ(navmeshName, fromX, fromY, fromZ, toX, toY, toZ, _G.NAV_STEP) then
            return Vector3.New(toX, toY, toZ)
        end
        for k, v in pairs(tableRegionData) do
		    if v ~= nil and (not InPath(k)) then
			    if GameUtil.CanNavigateToXYZ(navmeshName, v.xA, v.yA, v.zA, toX, toY, toZ, _G.NAV_STEP) then
                    path_table[#path_table + 1] = k
                    return RecursionFindTargetPos(fromX, fromY, fromZ, v.x, v.y, v.z)
                end
		    end	
	    end
    end

    local next_pos = RecursionFindTargetPos(hostX, hostY, hostZ, targetPos.x, targetPos.y, targetPos.z)

--	--判断所有的传送点，是否和目标点连通，然后传送到目标点
--	for k, v in pairs(tableRegionData) do
--		if v ~= nil then
--			if GameUtil.CanNavigateToXYZ(navmeshName, v.xA, v.yA, v.zA, targetPos.x, targetPos.y, targetPos.z, _G.NAV_STEP) and
--			   GameUtil.CanNavigateToXYZ(navmeshName, v.x, v.y, v.z, hostX, hostY, hostZ, _G.NAV_STEP) then
--				local regionPos = Vector3.New(v.x, v.y, v.z)
--				return regionPos
--			end
--		end	
--	end
    return next_pos
end

-- 策划需求：寻路的目的地不是客户端要进入的地图 就不让进入相位
-- 通过此协议告诉服务器玩家想自动寻路去哪里
def.method("boolean", "number").SyncHostPlayerDestMapInfo = function(self, isStart, mapId)
    --print("真正发送消息 SyncHostPlayerDestMapInfo ", mapId, isStart, debug.traceback())
    local C2SAutoPath = require "PB.net".C2SAutoPath
    local protocol = C2SAutoPath()
    protocol.IsStartPath = isStart
    protocol.MapId = mapId
    SendProtocol(protocol)
    self._IsSyncAutoPath = isStart
end

--地图开启数据
def.method("number").AddMapData = function(self,nMapID)
    if self._TableMapOpenData == nil then 
    	self._TableMapOpenData = {}
    end

	self._TableMapOpenData[nMapID] = true
end

def.method("number", "=>", "boolean").HaveReachToMap = function(self, mapID)
    if self._TableMapOpenData == nil then return false end
    if mapID == nil then return false end
    local guild_scene_id = game._GuildMan:GetGuildSceneTid()
    if guild_scene_id == mapID then
        return game._GuildMan:IsHostInGuild()
    end
    local map_info_data = CTransDataHandler.Instance():GetMapInfoData(mapID)
    local des_map_temp = CElementData.GetMapTemplate(mapID)
    if map_info_data.MapType == EWorldType.Pharse or map_info_data.MapType == EWorldType.Instance or map_info_data.MapType == EWorldType.Immediate then
        if des_map_temp.AssociatedPathfindingMainMapId ~= nil and des_map_temp.AssociatedPathfindingMainMapId > 0 then
            return self._TableMapOpenData[des_map_temp.AssociatedPathfindingMainMapId] ~= nil
        else
            return true
        end
    else
        return self._TableMapOpenData[mapID] ~= nil
    end
end

def.method().Cleanup = function(self)
    self._OnEnd = nil
    self._IsIgnoreConnected = false
    self._IsSyncAutoPath = false
    self._TransStrategy = nil
    self._EnterRegionData = nil
    self._TableMapOpenData = nil
    self._TransRegionPos = nil
    for _,v in pairs(self._TransStrategyCache) do
        v:Release()
    end

	CGame.EventManager:removeHandler('NotifyEnterRegion', OnEnterRegionEvent)
end

CTransManage.Commit()
return CTransManage