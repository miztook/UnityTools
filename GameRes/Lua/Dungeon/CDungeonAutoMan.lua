local Lplus = require "Lplus"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CGame = Lplus.ForwardDeclare("CGame")
local CSpecialIdMan = require  "Data.CSpecialIdMan"
local SkillCollision = require "SkillCollision"
local CEntity = require "Object.CEntity"
local CElementData = require "Data.CElementData"
local CPath = require"Path.CPath"
local CAutoFightMan = require "ObjHdl.CAutoFightMan"
local EGoalType = require "PB.data".EObjType
local MapBasicConfig = require "Data.MapBasicConfig" 
local CTransManage = require "Main.CTransManage"
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local CTeamMan = require "Team.CTeamMan"
local DistanceH = Vector3.DistanceH

local CDungeonAutoMan = Lplus.Class("CDungeonAutoMan")
local def = CDungeonAutoMan.define

def.field("boolean")._IsOn = false              --是否副本自动完成中
def.field("boolean")._IsPause = false           --自动任务是否被打断
def.field("number")._PauseMask = 0   

def.field('table')._DungeonGoal = nil           --副本目标
def.field('table')._GoalPos = nil               --副本目标坐标
def.field('table')._SceneInfo = nil             --地图数据
def.field('boolean')._IsOffsetRequired = false   --是否需要2.5的偏移量
def.field('boolean')._IsGoalFinished = false     --是否完成事件中 1.采集 2，NPC对话等

def.field("number")._StateCheckTimerId = -1
def.field("table")._LastHostPos = nil

local StateCheckTime = 5

local instance = nil
def.static("=>", CDungeonAutoMan).Instance = function ()
    if instance == nil then
        instance = CDungeonAutoMan() 
    end
    return instance
end

local function DungeonGoal_filter(v)
    return v:GetTemplateId() == instance._DungeonGoal.TemplateId
end

--设置副本自动寻路目标数据
local function SetDungeonGoalData(self)
    self._DungeonGoal = game._DungeonMan:GetDungeonGoal()
end

-- 判断目标是否有效
local function IsDungeonGoalValid(self) 
    if self._DungeonGoal == nil then return false end
    self._IsGoalFinished = false
    if self._DungeonGoal.CurCount == self._DungeonGoal.MaxCount then
        self._IsGoalFinished = true
        game._HostPlayer:StopNaviCal()  
        return true 
    end

    return true
end

local function GetNearestEntity(entityList)
    local entity = nil
    local cur_dis_sqr = 1000000
    local posx, posz = game._HostPlayer:GetPosXZ()
    for _,v in pairs(entityList) do
        local tposx,tposz = v.x,v.z
        local dis_sqr = SqrDistanceH(posx, posz, tposx, tposz)
        if dis_sqr < cur_dis_sqr then
            entity = v
            cur_dis_sqr = dis_sqr
        end
    end
    return entity  
end

local function SetGoalPos(self,sceneTid)
    self._GoalPos = nil

    if self._DungeonGoal == nil then
        warn("Can not set GoalPos, bcz DungeonGoal is nil")
        return
    end

    local targetID = self._DungeonGoal.TemplateId  
    if self._DungeonGoal.GoalType == EGoalType.ObjType_KillMonster then
        if targetID > 0 then
            if  self._SceneInfo.Monster[targetID] == nil then 
                warn("MapBasicInfo："..sceneTid.."找不到怪物："..targetID) 
                return 
            end

            local monster = GetNearestEntity(self._SceneInfo.Monster[targetID])
            if monster == nil then 
                warn("MapBasicInfo："..sceneTid.."找不到怪物："..targetID) 
                return
            end
            self._GoalPos = Vector3.New(monster.x,monster.y,monster.z)
        elseif targetID == 0 then -- 任意怪，随意找一只就开打
            if self._DungeonGoal.Param == 0 then
                local monster = game._CurWorld._NPCMan:GetByFilter("Enemy", nil)
                if monster ~= nil then
                    self._GoalPos = monster:GetPos()
                else
                    self._GoalPos = game._HostPlayer:GetPos()
                end
            else
                self._GoalPos  = MapBasicConfig.GetEntityPosByMapIDAndTId(0,self._DungeonGoal.Param)
            end    
        end
    elseif self._DungeonGoal.GoalType == EGoalType.ObjType_Gather then
        if self._SceneInfo.Mine[targetID] == nil then 
            warn("MapBasicInfo："..sceneTid.."找不到采集物："..targetID) 
            return
        end

        local mine = GetNearestEntity(self._SceneInfo.Mine[targetID])
        if mine == nil then 
            warn("MapBasicInfo："..sceneTid.."找不到采集物："..targetID) 
            return
        end

        self._GoalPos = Vector3.New(mine.x,mine.y,mine.z) 
    elseif self._DungeonGoal.GoalType == EGoalType.ObjType_ArriveRegion then
        --2 类型是普通区域
        local region =  self._SceneInfo.Region
        if region == nil then 
            warn("MapBasicInfo："..sceneTid.."没有区域信息") return
        end

        if self._SceneInfo.Region[2] ~= nil then
            region =  self._SceneInfo.Region[2][targetID]
        elseif self._SceneInfo.Region[1] ~= nil then
            region = self._SceneInfo.Region[1][targetID]  
        else
            warn("MapBasicInfo："..sceneTid.."找不到区域ID："..targetID)
            return 
        end

        if region == nil then 
            warn("MapBasicInfo："..sceneTid.."找不到区域ID："..targetID) 
            return
        end

        local V2pos = Vector2.New(region.x,region.z)
        local posY = GameUtil.GetMapHeight(V2pos) 
        self._GoalPos = Vector3.New(region.x,posY,region.z)
    elseif self._DungeonGoal.GoalType == EGoalType.ObjType_Conversation then
        if self._SceneInfo == nil or self._SceneInfo.Npc == nil or self._SceneInfo.Npc[targetID] == nil then
            warn("MapBasicInfo："..sceneTid.."找不到NPC："..targetID) 
            return
        end
        local npc = GetNearestEntity(self._SceneInfo.Npc[targetID])
        if npc == nil then 
            warn("MapBasicInfo："..sceneTid.."找不到NPC："..targetID) 
            return
        end
        self._GoalPos = Vector3.New(npc.x,npc.y,npc.z)
    elseif self._DungeonGoal.GoalType == EGoalType.ObjType_Convoy then
        return
    end
end

--到达任务目标点(回掉函数)
local function OnReach() 
    local host_player = game._HostPlayer
    if instance._DungeonGoal == nil then 
        host_player:StopNaviCal()
        return 
    end
    instance._GoalPos = nil
    local npc_manager = game._CurWorld._NPCMan
    if instance._DungeonGoal.GoalType == EGoalType.ObjType_KillMonster then--怪物
        if not CAutoFightMan.Instance():IsOn() then
            host_player:StopNaviCal()
        end
    elseif instance._DungeonGoal.GoalType == EGoalType.ObjType_Gather then--采集
       instance._IsGoalFinished = true
        local m = game._CurWorld._MineObjectMan:GetByFilter(DungeonGoal_filter)
        if m == nil then
            warn("Cannot find mine of template id: ", instance._DungeonGoal.TemplateId)
        else
            -- warn("---CDungeonAutoMan--- OnReach ---采集-----",debug.traceback())
            m:AddLoadedCallback(function() m:OnClick() end)
        end
    elseif instance._DungeonGoal.GoalType == EGoalType.ObjType_Conversation then--NPC对话
        instance._IsGoalFinished = true
        local npc = npc_manager:GetByTid(instance._DungeonGoal.TemplateId)
        if npc ~= nil then
            host_player._OpHdl:TalkToServerNpc(npc, nil)
        end
    else
        host_player:StopNaviCal()    
    end

    --副本目标找不到了，所以站着不动！！
    local curTarget = host_player:GetCurrentTarget()
    if curTarget == nil then
        host_player:StopNaviCal()  
        host_player:SetAutoPathFlag(false)
    end
end

--移动
local function MoveToGoalPos(self)
    if CTeamMan.Instance():IsFollowing() then return end
    -- 打断自动寻路
    CTransManage.Instance():BrokenTrans()

    local host_player = game._HostPlayer
    if self._GoalPos == nil then 
        host_player:StopNaviCal() 
        return 
    end

    if host_player:CanMove() then
        host_player:SetAutoPathFlag(true)
    end
    
    local hostPosX, hostPosY, hostPosZ = host_player:GetPosXYZ()
    local callback = OnReach
    if not self._IsOffsetRequired then         
        -- 瑞龙自动化中不要提示
        if host_player:CanMove() then
            host_player:Move(self._GoalPos, 0, callback, nil)
            CPath.Instance():ShowPath(self._GoalPos) 
        end
    else
        local offset = _G.NAV_OFFSET
        if self._DungeonGoal ~= nil and self._DungeonGoal.GoalType == EGoalType.ObjType_Gather then
            local dis = Vector3.SqrDistanceH_XZ(hostPosX, hostPosZ, self._GoalPos.x, self._GoalPos.z)
            if dis < offset * offset and callback then
                callback()
                self._GoalPos = nil
                return 
            end
        end
        -- 瑞龙自动化中不要提示
        if host_player:CanMove() then
            host_player:MoveAndDonotCareCollision(self._GoalPos, offset, callback, nil)
            CPath.Instance():ShowPath(self._GoalPos)        
        end
    end

end

local function GetSenceInfo(self)
    local sceneTid = game._CurWorld._WorldInfo.SceneTid
    self._SceneInfo = MapBasicConfig.GetMapBasicConfigBySceneID( sceneTid )
end

-- 根据目标类型获取的目标数据信息行动
local function ActionStart(self)
    if self._IsGoalFinished then return end

    GetSenceInfo(self)

    if self._SceneInfo == nil then 
        warn("MapBasicInfo："..game._CurWorld._WorldInfo.SceneTid.."错误") 
        return 
    end

    local sceneTid = game._CurWorld._WorldInfo.SceneTid
    SetGoalPos(self, sceneTid)

    local nGoalType = self._DungeonGoal.GoalType
    if self._GoalPos == nil then
        if nGoalType == EGoalType.ObjType_Convoy then 
            game._DungeonMan:GoalToQuestFollow()
        end
        return
    end
    
    if CAutoFightMan.Instance():IsOn() then
        -- 清除自动战斗优先目标列表
        CAutoFightMan.Instance():ClearPriorityTargets()

        local preferedGoal = game:GetCurDungeonPreferedGoal()
        if preferedGoal == DPG.AchieveGoals then
            -- 目标优先，且当前副本目标是杀怪，需要更换优先目标
            if self._DungeonGoal.TemplateId > 0 then 
                game._HostPlayer:UpdateTargetInfo(nil, false)
                if nGoalType == EGoalType.ObjType_KillMonster then
                    CAutoFightMan.Instance():Restart(_G.PauseMask.DungeonGoalChanged)
                    local list = game._DungeonMan:GetALLMonsterGoal()
                    CAutoFightMan.Instance():SetPriorityTargets(list)
                else
                    CAutoFightMan.Instance():Pause(_G.PauseMask.DungeonGoalChanged)
                end
            end
        elseif preferedGoal == DPG.KillEnemy then
            -- 优先战斗，如果已经存在目标，继续打
            if CAutoFightMan.Instance():HasTarget() then 
                return
            end
        end
    end

    self._IsOffsetRequired = ( nGoalType == EGoalType.ObjType_Conversation or nGoalType == EGoalType.ObjType_Gather or nGoalType == EGoalType.ObjType_KillMonster)
    self._IsGoalFinished = false

    MoveToGoalPos(self)  
end

--监听玩家状态的接口
local function OnBaseStateChangeEvent(sender, event)
    if event.IsEnterState then --主角被控制，不能移动，打断寻路
        instance:Pause(_G.PauseMask.HostBaseState)
    else
        instance:Restart(_G.PauseMask.HostBaseState)
    end
end

local function ClearStateCheckTimer(self)
    if self._StateCheckTimerId > 0 then
        _G.RemoveGlobalTimer(self._StateCheckTimerId)
        self._StateCheckTimerId = 0
    end
end

--停止自动战斗
local function StopAuto()
    instance._DungeonGoal = nil
    instance._IsGoalFinished = false
    instance._IsOn = false
    instance._IsPause = false
    instance._GoalPos = nil                           
    instance._IsOffsetRequired = false
    instance._PauseMask = 0

    local hp = game._HostPlayer
    --hp:StartAutoDetectTarget() 
    hp:StopNaviCal()  
    CGame.EventManager:removeHandler("BaseStateChangeEvent", OnBaseStateChangeEvent) 

    local CPanelTracker = require "GUI.CPanelTracker"
    CPanelTracker.Instance():SyncAutoDungeonUIState(false)
    CPath.Instance():Hide()

    ClearStateCheckTimer(instance)
end

--开始副本自动战斗
def.method().Start = function(self)
    --已经进入自动战斗了。不用重置状态  
    local hp = game._HostPlayer
    if hp:IsDead() then
        local CPanelTracker = require "GUI.CPanelTracker"
        CPanelTracker.Instance():SyncAutoDungeonUIState(false)
        CPath.Instance():Hide()
        return
    end
    
    local oldState = self._IsOn
    self._IsGoalFinished = false
    self._IsOn = true
    self._PauseMask = 0
    self._IsPause = false

    SetDungeonGoalData(self)
    local isValid = IsDungeonGoalValid(self)
    if isValid then
        if not oldState then 
            local CPanelTracker = require "GUI.CPanelTracker"
            CPanelTracker.Instance():SyncAutoDungeonUIState(true)
            CGame.EventManager:addHandler("BaseStateChangeEvent", OnBaseStateChangeEvent)
        end
        ActionStart(self)

        if self._StateCheckTimerId > 0 then
            ClearStateCheckTimer(self)
        end

        self._LastHostPos = hp:GetPos()
        self._StateCheckTimerId = _G.AddGlobalTimer(StateCheckTime, false, function()
                if not self._IsOn then
                    ClearStateCheckTimer(self)
                    return
                end

                if hp:IsDead() or self._IsPause or self._PauseMask ~= 0 then
                    self._LastHostPos = hp:GetPos()
                    return
                end

                local CPanelDialogue = require 'GUI.CPanelDialogue'
                if CPanelDialogue.Instance():IsShow() then
                    self._LastHostPos = hp:GetPos()
                    return
                end

                local curPos = hp:GetPos()
                if DistanceH(curPos, self._LastHostPos) < 0.1 then
                    -- 原地不动，认为时自动化不明原因中断，需要重启
                    self:ChangeGoal()
                else
                    self._LastHostPos = hp:GetPos()
                end
            end)
    else
        StopAuto()
    end 

    print("CDungeonAutoMan Start", debug.traceback())
end

def.method("number").Pause = function(self, reasonMask)    
    if not self._IsOn then return end

    self._PauseMask = bit.bor(self._PauseMask, reasonMask)

    if not self._IsPause then
        game._HostPlayer:StopNaviCal() 
    end
    self._IsPause = true

    if reasonMask ~= _G.PauseMask.SkillPerform then
        print("CDungeonAutoMan Pause", self._PauseMask, debug.traceback())
    end
end

def.method("number").Restart = function(self, reasonMask)   
    if not self._IsOn then return end

    self._PauseMask = bit.band(self._PauseMask,  bit.bnot(reasonMask))
    
    if reasonMask ~= _G.PauseMask.SkillPerform then
        print("CDungeonAutoMan Restart", self._PauseMask, debug.traceback())
    end

    if self._PauseMask ~= 0 then return end 

    self._IsPause = false
    self:ChangeGoal()
end

--副本目标改变，寻路(每次执行副本寻路之前，需要先暂停自动战斗！)
def.method().ChangeGoal = function(self) 
    if not self._IsOn then return end

    -- 目标优先，停止战斗
    --local preferAchieveGoals = (game:GetCurMapAutoFightType() == AFT.DungeonGoal and game:GetCurDungeonPreferedGoal() == DPG.AchieveGoals)
    --if preferAchieveGoals then
    --    self:Stop()
    --end

    SetDungeonGoalData(self)
    local isValid = IsDungeonGoalValid(self)
    if not isValid then return end
    ActionStart(self)
end

--是否副本自动中
def.method("=>","boolean").IsOn = function(self)
    return self._IsOn
end

--获取副本目标点
def.method("=>","table").GetGoalPos = function(self)
    return self._GoalPos
end

--停止自动战斗
def.method().Stop = function(self) 
    if not self._IsOn then return end     
    StopAuto()

    print("CDungeonAutoMan Stop", debug.traceback())
end

def.method().Debug = function(self)
    local msg = string.format("CDungeonAutoMan IsOn = %s, Paused = %s, _PauseMask = %d", tostring(self._IsOn), tostring(self._IsPause), self._PauseMask)

    warn(msg, self._GoalPos)
end

def.method().Release = function(self)
    self:Stop()
    self._SceneInfo = nil        
end

CDungeonAutoMan.Commit()
return CDungeonAutoMan