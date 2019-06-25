local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CGame = Lplus.ForwardDeclare("CGame")
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CAutoFightBase = require "AutoFight.CAutoFightBase"
local CTeamMan = require "Team.CTeamMan"

local CWorldAutoFight = Lplus.Extend(CAutoFightBase, "CWorldAutoFight")
local def = CWorldAutoFight.define

def.field('table')._OriginPos = nil  -- 原点
def.field('boolean')._IsGuardMode = false  -- 守卫模式
def.field('boolean')._IsBacking = false  -- 返回原点中
def.field('number')._ReturnStartTime = 0  -- 返回原点开始时间

local SqrDistanceH = Vector3.SqrDistanceH_XZ

local instance = nil

local function IsTargetProper(tid)
    if instance then
        if #instance._TargetTidList == 0 then 
            return true 
        end

        for i = 1, #instance._TargetTidList do 
            if instance._TargetTidList[i] == tid then                                    
                return true
            end                                
        end
    end
    return false
end

-- 目标优先筛选函数
local function TargetFilter(v)
    if not IsTargetProper(v:GetTemplateId()) then
        return false
    end
    
    local host_player = game._HostPlayer
    if not v:CanBeAttacked() then 
        return false
    end

    local hostPosX, hostPosY, hostPosZ = host_player:GetPosXYZ()
    local posX, posY, posZ = v:GetPosXYZ()

    local dis_limit = instance:GetEnemyDetectRadius()
    local max_dis_sqr =  dis_limit * dis_limit
    if SqrDistanceH(hostPosX, hostPosZ, posX, posZ) > max_dis_sqr then
        return false
    end

    if not GameUtil.PathFindingCanNavigateToXYZ(hostPosX, hostPosY, hostPosZ, posX, posY, posZ, _G.NAV_STEP) then
        return false
    end

    return true
end

local function ChangeTarget(self, target) 
    if target ~= nil then
        self._CurTargetId = target._ID
    else
        self._CurTargetId = 0
    end

    -- 目标清空 重开副本目标 
    -- 如战斗优先 眼前的怪物清干净了 要重启副本目标几率找怪 
    local game = _G.game
    local preferFight = (game:GetCurMapAutoFightType() == AFT.DungeonGoal and game:GetCurDungeonPreferedGoal() == DPG.KillEnemy)
    if self._CurTargetId == 0 and preferFight and not game._HostPlayer._IsAutoPathing then
        local CDungeonAutoMan = require "Dungeon.CDungeonAutoMan"
        CDungeonAutoMan.Instance():ChangeGoal()
    end
end

--Timer
local function Tick()
    if instance._Paused then return end

    local host_player = game._HostPlayer

    if instance._IsBacking then
        --Return2OriginPos中OnReach回调并非100%会调用到，故加强制解除状态逻辑
        if host_player:GetCurStateType() == FSM_STATE_TYPE.IDLE and Time.time - instance._ReturnStartTime > 5 then 
            instance._IsBacking = false
        end
        return
    end

    if instance:IsNeedBack2OringinPos() then
        instance:Return2OriginPos()
        return        
    end
    
    --锁定目标检测
    local target = nil
    if instance:IsLockedCurTarget() then
        target = host_player._CurTarget
        if target:GetRelationWithHost() ~= "Enemy" then return end
    else
        -- 获取目标与位置
        if #instance._TargetTidList > 0 then
            target = instance:FindTarget(true, TargetFilter, nil)
        else
            target = instance:FindTarget(true, nil, nil)
        end

        if target and target:GetObjectType() == OBJ_TYPE.ELSEPLAYER  then
            host_player:UpdateTargetInfo(target, host_player:IsEntityHate(target._ID))
        else
            host_player:UpdateTargetInfo(target, false)
        end
    end

    instance:ExecHostSkill(target)
    ChangeTarget(instance, target)
end

def.static("=>", CWorldAutoFight).Instance = function ()
    if instance == nil then
        instance = CWorldAutoFight()
        CAutoFightBase.Init(instance)
    end
	return instance
end

def.override().Pause = function(self)
    CAutoFightBase.Pause(self)
    self._IsBacking = false    
    self._ReturnStartTime = 0
end

def.override("number").Start = function(self, _)
    local host_player = game._HostPlayer
    if host_player == nil then 
        return 
    end

    --print("CWorldAutoFight Start", self._Paused, debug.traceback())

    self._Paused = false

    if self._TimerId <= 0 then               
        self._TimerId = _G.AddGlobalTimer(0.5, false, Tick)     
    end

    if host_player._CurTarget ~= nil then
        local relation, _ = host_player._CurTarget:GetRelationWithHost()
        if relation ~= "Enemy" then
            host_player:UpdateTargetInfo(nil, false)
        end
    end 

end

def.method("boolean").EnableGuardMode = function(self, enable)
    if self._TimerId <= 0 then 
        return 
    end
    
    if game:GetCurMapAutoFightType() == AFT.DungeonGoal then
        return
    end

    self._IsGuardMode = enable

    if enable then
        local hp = game._HostPlayer
        if hp == nil then return end
        self._OriginPos = hp:GetPos()
    end
end

def.method("=>", "boolean").IsNeedBack2OringinPos = function(self)
    local teamMan = CTeamMan.Instance()
    if not self._IsGuardMode or self._OriginPos == nil or (teamMan and teamMan:IsFollowing()) then
        return false
    end
    
    local host_player = game._HostPlayer 
    local hostPosX, hostPosY, hostPosZ = host_player:GetPosXYZ()
    local distance = SqrDistanceH(hostPosX, hostPosZ, self._OriginPos.x, self._OriginPos.z)
    if distance > self._AutoFightConfig.guard_radius * self._AutoFightConfig.guard_radius then
        return true
    end
    return false
end

def.method().Return2OriginPos = function(self)
    if not self._IsGuardMode or self._OriginPos == nil then
        return 
    end
    
    local hp = game._HostPlayer

    if not hp:CanMove() then return end

    self._IsBacking = true
    self._ReturnStartTime = Time.time
    local function OnReach()    
        self._IsBacking = false 
        self._ReturnStartTime = 0     
        hp:Stand()   
    end
    hp:UpdateTargetInfo(nil, false)
    hp:Move(self._OriginPos, 0, OnReach, OnReach) 
end

-- 设置目标优先列表
def.method("table").UpdatePriorityTargets = function(self, targets)
    if self._TimerId <= 0 then 
        return 
    end
    self._TargetTidList = targets
end

def.override().Stop = function(self)
    if self._TimerId <= 0 then 
        return 
    end
    _G.RemoveGlobalTimer(self._TimerId)
    self._TimerId = 0

    CAutoFightBase.Stop(self)    
    self._IsGuardMode = false
    self._IsBacking = false
    self._OriginPos = nil
end

def.method().Debug = function(self)
    local isFollowing = CTeamMan.Instance():IsFollowing()
    local isBacking = self._IsBacking 
    local isNeedReturn = self:IsNeedBack2OringinPos()

    local msg = string.format("CWorldAutoFight TimerId = %d, GuardMode = %s, Paused = %s, IsFollowing = %s, IsBacking = %s, NeedReturn = %s, OriginPos =", 
        self._TimerId, tostring(self._IsGuardMode), tostring(self._Paused), tostring(isFollowing), tostring(isBacking), tostring(isNeedReturn))

    warn(msg, self._OriginPos)
end

CWorldAutoFight.Commit()
return CWorldAutoFight