--[[-----------------------------------------
    任务寻路

       - 提供任务对象寻路（本图+跨图）
       - 针对寻怪，支持多个区域的轮番查找
       - 在寻路中，开启目标检测，如果发现合适目标即可停止，避免ZigZag
 --------------------------------------------
]]

local Lplus = require "Lplus"
local MapBasicConfig = require "Data.MapBasicConfig"
local CTransManage = require "Main.CTransManage"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CPath = Lplus.ForwardDeclare("CPath")

local CQuestNavigation = Lplus.Class("CQuestNavigation")
local def = CQuestNavigation.define

def.field("string")._TargetType = ""         -- 搜索目标类型
def.field('table')._TargetList = BlankTable  -- 搜索目标tid列表
def.field('number')._TargetTid = 0           -- 搜索目标tid
def.field("number")._TargetSceneId = 0
def.field("table")._TargetPos = nil
def.field("function")._OnArrive = nil
def.field("dynamic")._ActionParams = nil

def.field("number")._DetectTimerId = 0       -- 尾端检测定时器
def.field("table")._LastRecord = nil         -- 完成的目的地记录 {上次搜索场景Tid，搜索对象Tid，Index}
def.field("number")._SearchIdx = 0      

local SqrDistanceH = Vector3.SqrDistanceH_XZ
local CHECK_THRESHOLD_SQUARE = 10 * 10   --开启末端检测的阈值

local instance = nil

def.static('=>',CQuestNavigation).Instance = function()
    if instance == nil then
        instance = CQuestNavigation()
        instance._LastRecord = {0, 0, 0, 0}   -- {targetSceneTid, targetTid, idx, type}

        local ret, msg, result = pcall(dofile, "Configs/auto_fight.lua")
        if ret then
            if result.SearchRadius ~= nil and result.SearchRadius > 0 then
                CHECK_THRESHOLD_SQUARE =  result.SearchRadius * result.SearchRadius
            end
        else
            warn(msg)
        end
    end
    return instance
end

local function IsValidTarget(tid)
   do return instance._TargetTid == tid end
end

local function IsValidTargets(tid)
   for k,v in pairs(instance._TargetList) do
       if k == tid then
          return true
       end
   end
   return false
end

local function GetNearestEntity(entityType)
    local entity = nil
    local cur_dis_sqr = 1000000

    local posx, posz = game._HostPlayer:GetPosXZ()
    if entityType == "Npc" then
        local npcs = game._CurWorld._NPCMan._ActiveNpcList
        for _,v in pairs(npcs) do
            if IsValidTarget(v:GetTemplateId()) and v:GetObjectType() == OBJ_TYPE.NPC then
                local tposx,tposz = v:GetPosXZ()
                local dis_sqr = SqrDistanceH(posx, posz, tposx, tposz)
                if dis_sqr < cur_dis_sqr then
                    entity = v
                    cur_dis_sqr = dis_sqr
                end
            end
        end
    elseif entityType == "Monster" then
        local npcs = game._CurWorld._NPCMan._ActiveNpcList
        for _,v in pairs(npcs) do
            if IsValidTarget(v:GetTemplateId()) and v:GetObjectType() == OBJ_TYPE.MONSTER then
                local tposx,tposz = v:GetPosXZ()
                local dis_sqr = SqrDistanceH(posx, posz, tposx, tposz)
                if dis_sqr < cur_dis_sqr then
                    entity = v
                    cur_dis_sqr = dis_sqr
                end
            end
        end

    elseif entityType == "Mine" then
        local mines = game._CurWorld._MineObjectMan._ObjMap
        for _,v in pairs(mines) do
            if IsValidTarget(v:GetTemplateId()) and v:GetCanGather() then
                local tposx,tposz = v:GetPosXZ()
                local dis_sqr = SqrDistanceH(posx, posz, tposx, tposz)
                if dis_sqr < cur_dis_sqr then
                    entity = v
                    cur_dis_sqr = dis_sqr
                end
            end
        end
    elseif entityType == "Generator" then
        local npcs = game._CurWorld._NPCMan._ActiveNpcList
        for _,v in pairs(npcs) do
            if IsValidTargets(v:GetTemplateId()) and v:GetObjectType() == OBJ_TYPE.MONSTER then
                local tposx,tposz = v:GetPosXZ()
                local dis_sqr = SqrDistanceH(posx, posz, tposx, tposz)
                if dis_sqr < cur_dis_sqr then
                    entity = v
                    cur_dis_sqr = dis_sqr
                end
            end
        end
    end

    return entity
end

local function RecordSearchInfo()
    instance._LastRecord[1] = instance._TargetSceneId
    instance._LastRecord[2] = instance._TargetTid
    instance._LastRecord[3] = instance._SearchIdx
end

local function StartAction(target)
    -- 进入尾端逻辑，终止寻路
    local hp = game._HostPlayer
    hp:StopAutoTrans()
    
    if instance._TargetType == "Npc" then        
        local targetPos = target:GetPos()
        if hp:GetCurStateType() == FSM_STATE_TYPE.SKILL and hp._SkillHdl then
            local skill_id, perform_idx = hp._SkillHdl:GetCurSkillInfo()
            local CElementSkill = require "Data.CElementSkill"
            if  CElementSkill.CanMoveWithSkill(skill_id, perform_idx) then
                local curPos = hp:GetPos()    
                local width = target:GetRadius() + hp:GetRadius()    
                targetPos = target:GetPos() - (target:GetPos() - curPos):Normalize() * width
            end
        end

        if hp:CheckAutoHorse(targetPos) then 
            hp:NavMountHorseLogic(targetPos)
        end

        local targetId = target._ID
        local cb = function()
            local npc = game._CurWorld._NPCMan:Get(targetId)
            if npc == nil then
                -- npc没了，需要重新寻路
                instance:NavigatToNpc(instance._TargetTid, instance._ActionParams)
                return
            end
            local npcPosX, npcPosZ = npc:GetPosXZ()
            local hpPosX, hpPosZ = hp:GetPosXZ()
            local disSqr = SqrDistanceH(npcPosX, npcPosZ, hpPosX, hpPosZ)

            if disSqr > _G.NAV_OFFSET * _G.NAV_OFFSET then
                -- npc移动了，需要重新寻路
                instance:NavigatToNpc(instance._TargetTid, instance._ActionParams)
            else
                hp:SetAutoPathFlag(false)
                hp:StopNaviCal()
                hp._OpHdl:TalkToServerNpc(npc, instance._ActionParams)
                RecordSearchInfo()
            end
        end
        hp:UpdateTargetInfo(target, true)
        hp:SetAutoPathFlag(true)
        CTransManage.Instance():StartMoveByMapIDAndPos(game._CurWorld._WorldInfo.SceneTid, targetPos, cb, true, true)
    elseif instance._TargetType == "Monster" or instance._TargetType == "Generator" then        
        -- 没开启功能        
        if not game._CFunctionMan:IsUnlockByFunID(EnumDef.EGuideTriggerFunTag.AutoFight) or game:IsCurMapForbidAutofight() then
            if target then
                local targetX, targetZ = target:GetPosXZ()
                local hostX, hostZ = hp:GetPosXZ()
                local distance = SqrDistanceH(targetX, targetZ, hostX, hostZ)
                if distance > _G.NAV_OFFSET * _G.NAV_OFFSET and hp:CanMove() then
                    hp:MoveAndDonotCareCollision(target:GetPos(), _G.NAV_OFFSET, nil, nil) 
                    CPath.Instance():ShowPath(target:GetPos())
                end
            end
            return
        end
        local CQuestAutoMan = require"Quest.CQuestAutoMan"
        local CAutoFightMan = require "AutoFight.CAutoFightMan"
        if CQuestAutoMan.Instance():IsOn() and CAutoFightMan.Instance():IsOn() then
            CAutoFightMan.Instance():SetMode(EnumDef.AutoFightType.QuestFight, instance._ActionParams[1], false)
        end
        RecordSearchInfo()
    elseif instance._TargetType == "Mine" then
        --hp:UpdateTargetInfo(target, false)
        local CQuestAutoGather = require "Quest.CQuestAutoGather"
        CQuestAutoGather.Instance():Start(instance._TargetTid, instance._ActionParams)
        RecordSearchInfo()
    end
end

local function StartDetect()
    local function Detect()
        if game._CurWorld._WorldInfo.SceneTid ~= instance._TargetSceneId then return end

        local host = game._HostPlayer
        if instance._TargetPos == nil then
            host:RemoveTimer(instance._DetectTimerId)
            instance._DetectTimerId = 0
            --print("马良临时测试-目标为空 退出")
            return
        end

        local posx, posz = host:GetPosXZ()
        if SqrDistanceH(posx, posz, instance._TargetPos.x, instance._TargetPos.z) >= CHECK_THRESHOLD_SQUARE then
            --print("马良临时测试-距离太远 退出")
            return
        end

        local target = GetNearestEntity(instance._TargetType)
        if target == nil then 
            --print("马良临时测试-附近目标为空 退出")
            return 
        end

        -- 视野内找到合适对象，停止检测，超目标走
        host:RemoveTimer(instance._DetectTimerId)
        instance._DetectTimerId = 0
        --print("马良临时测试-找到目标")
        StartAction(target)
    end
    --print("马良临时测试-检查 DetectTimerId=",instance._DetectTimerId)
    if instance._DetectTimerId <= 0 then
        --print("马良临时测试-开启TICK 寻找目标")
        instance._DetectTimerId = game._HostPlayer:AddTimer(0.4, false, Detect)
    end
end

local SqrDistanceH = Vector3.SqrDistanceH_XZ
local function DoNavigat(sceneId, destPos, targetType, targetTid, params)
    instance._TargetType = targetType
    
    local hp = game._HostPlayer
    if targetType == "Region" then
        if instance._DetectTimerId > 0 then
            hp:RemoveTimer(instance._DetectTimerId)
            instance._DetectTimerId = 0
        end
        instance._TargetList = nil
        instance._TargetTid = 0
        instance._ActionParams = nil 
        instance._TargetSceneId = 0
        instance._TargetPos = nil
        CTransManage.Instance():StartMoveByMapIDAndPos(sceneId, destPos, nil, false, true)
    else
        if type(targetTid) == "number" then
            instance._TargetTid = targetTid
        elseif type(targetTid) == "table" then
            instance._TargetList = targetTid
        end
        
        instance._ActionParams = params

        local target = GetNearestEntity(targetType)
        -- 视野内无法找到目标对象
        if target == nil then
            if sceneId <= 0 and targetTid ~= 0 then
                local msg = string.format("未能在场景%d中找到Tid = %d的 %s，可能原因（1）MapBasicInfo数据配置出错（2）跟随NPC跑丢了", sceneId, targetTid, targetType)
                warn(msg)
                return
            end
                
            local host_pos =  hp:GetPos()
            local distanceSqr = 9999
            if destPos then
                distanceSqr = SqrDistanceH(host_pos.x, host_pos.z, destPos.x, destPos.z)
            end
            
            if distanceSqr > (_G.NAV_OFFSET * _G.NAV_OFFSET) then
                -- 开始往目标点寻路
                CTransManage.Instance():StartMoveByMapIDAndPos(sceneId, destPos, RecordSearchInfo, true, true)
                -- 开启末端检测
                instance._TargetSceneId = sceneId
                instance._TargetPos = destPos
                StartDetect()
            else
                --视野内 无法找到对象 并且 目标点 又在自己范围内时 记录点
                -- 开始往目标点寻路
                instance._TargetSceneId = sceneId
                instance._TargetPos = destPos
                -- 如果是在视野内，但是目标是在相位，其实也需要向服务器发送去相位的提示，下面这行会直接调用回调函数而且会给服务器发送进相位的消息，否则进不了相位。
                CTransManage.Instance():StartMoveByMapIDAndPos(sceneId, destPos, RecordSearchInfo, true, true)
--                RecordSearchInfo()
            end
            --print("检测找目标--------------未找到", targetTid)
        else
            StartAction(target)
            --print("检测找目标--------------已找到", targetTid)
        end
    end
end

local function CheckAndResetRecord(navType, navTid)
    if instance._LastRecord[4] ~= navType or instance._LastRecord[2] ~= navTid then
        instance._LastRecord[1] = 0
        instance._LastRecord[2] = 0
        instance._LastRecord[3] = 0
        instance._LastRecord[4] = 0
    end
end

def.method("number", "table").NavigatToNpc = function(self, npc_tid, params)
    CheckAndResetRecord(1, npc_tid)
    local scene_id, dest_pos, idx = MapBasicConfig.GetDestParams("Npc", npc_tid, self._LastRecord)
    -- 公会建设寻路为跳转添加log
    if npc_tid == 20005 then
        warn("lidaming NavigatToNpc npc_tid == npc_tid, scene_id ==>>>", scene_id, "dest_pos ==>>", dest_pos)
    end
    DoNavigat(scene_id, dest_pos, "Npc", npc_tid, params)
    --self._LastRecord[3] = idx
    self._SearchIdx = idx
    self._LastRecord[4] = 1
end

def.method("number", "number").NavigatToMonster = function(self, monster_tid, questTid)
    CheckAndResetRecord(2, monster_tid)
    local scene_id, dest_pos, idx = MapBasicConfig.GetDestParams("Monster", monster_tid, self._LastRecord)
    DoNavigat(scene_id, dest_pos, "Monster", monster_tid, {questTid} )
    self._SearchIdx = idx
    self._LastRecord[4] = 2
end

def.method("number", "table").NavigatToMine = function(self, mine_tid, questGoal)
    CheckAndResetRecord(3, mine_tid)
    local scene_id, dest_pos, idx = MapBasicConfig.GetDestParams("Mine", mine_tid, self._LastRecord)
    DoNavigat(scene_id, dest_pos, "Mine", mine_tid, questGoal)
    --self._LastRecord[3] = idx
    self._SearchIdx = idx
    self._LastRecord[4] = 3
end

def.method("number", "number","number").NavigatToMonsterGenerator = function(self, mapTid, generatorTid, questTid)
    CheckAndResetRecord(4, generatorTid)  
    local dest_pos = MapBasicConfig.GetGeneratorPos(mapTid, generatorTid)
    DoNavigat(mapTid, dest_pos, "Generator", MapBasicConfig.GetGeneratorTargetMonsters(mapTid, generatorTid), {questTid} )
    self._SearchIdx = 1
    self._LastRecord[4] = 4
end

--[[
local function GetCtrlDataById(target_list, ctrl_id)
    if target_list == nil then
        warn("the param 'target_list' is nil.")
        return nil
    end

    local count = #target_list
    for i = 1, count, 1 do
        local item = target_list[i]
        if item ~= nil and item.Id == ctrl_id then
            return item
        end
    end

    return nil
end

def.method("number", "number").NavigatToRegion = function(self, scene_id, region_id)
    local CElementData = require "Data.CElementData"
    local map_model = CElementData.GetSceneTemplate(scene_id)
    if map_model == nil or map_model.RegionRoot == nil or map_model.RegionRoot.Regions == nil then
        warn("can not find the map data with id ".. scene_id)
        return
    end
    local region_model = GetCtrlDataById(map_model.RegionRoot.Regions, region_id)
    if region_model == nil then 
        warn("can not get region_model")
        return 
    end
    local bezier_curve_data = GetCtrlDataById(map_model.BezierCurveRoot.BezierCurves, region_model.BezierCurveId)
    if bezier_curve_data == nil then
        warn("can not find bezier curve with id "..region_model.BezierCurveId)
        return
    end
    local dest_pos = Vector3.New(bezier_curve_data.OriginPositionX, bezier_curve_data.OriginPositionY, bezier_curve_data.OriginPositionZ)
    DoNavigat(scene_id, dest_pos, "Region", 0, nil)
end]]

def.method().Release = function(self)
    if game._HostPlayer ~= nil then
        game._HostPlayer:RemoveTimer(self._DetectTimerId)
    end
    self._DetectTimerId = 0
end

CQuestNavigation.Commit()
return CQuestNavigation