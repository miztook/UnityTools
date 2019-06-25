local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local EElementType = require"PB.data".EElementType
local SkillCategory = require "PB.Template".Skill.SkillCategory
local CElementSkill = require "Data.CElementSkill"
local CElementData = require "Data.CElementData"

local CAutoFightBase = Lplus.Class("CAutoFightBase")
local def = CAutoFightBase.define

def.field('table')._AutoFightConfig = nil
def.field('number')._CurTargetId = 0
def.field('number')._TimerId = 0
def.field('number')._ManualSkillId = 0
def.field('table')._TargetTidList = BlankTable  -- 优先目标列表
def.field('table')._ForbidSkillId = BlankTable  -- 禁止释放的技能ID
def.field("boolean")._Paused = false

local dist_sqr = 1.5 * 1.5
local SqrDistanceH = Vector3.SqrDistanceH_XZ
local DistanceH = Vector3.DistanceH_XZ

def.method().Init = function(self)
    local ret, msg, result = pcall(dofile, "Configs/auto_fight.lua")
    if ret then
        self._AutoFightConfig = result 
    else
        warn(msg)
    end    
    self._ForbidSkillId = {}
    local userSkillMap = game._HostPlayer._MainSkillIDList
    local UserData = require "Data.UserData".Instance()
    for k, v in ipairs(userSkillMap) do
        local skill_is_forbid = UserData:GetField("UserSkillAuto"..v)
        if skill_is_forbid ~= nil then
            if skill_is_forbid == true then
                self._ForbidSkillId[#self._ForbidSkillId + 1] = v
            end
        end
    end
end

def.virtual("number").Start = function(self, param)    
end

def.virtual().Pause = function(self)
    --warn("CAutoFightBase Pause", self._TimerId, self._Paused)
    if self._TimerId > 0 and not self._Paused then
        game._HostPlayer:StopNaviCal()
        self._Paused = true
    end
end

def.virtual().Restart = function(self)
    --warn("CWorldAutoFight Restart", self._Paused, debug.traceback())
    self._Paused = false
end

def.method("number").OnManualSkill = function(self, skill_id)
    self._ManualSkillId = skill_id
end

-- 清理
def.method().ClearPriorityTargets = function(self)
    self._TargetTidList = {}
end

def.method("=>","boolean").IsOn = function(self)
    return self._TimerId > 0
end

def.method("=>","boolean").IsPaused = function(self)
    return self._Paused
end

def.method("=>","boolean").IsLockedCurTarget = function(self)
    local host_player = game._HostPlayer    
    if not host_player then
        return false
    end

    local target = host_player._CurTarget
    if target and not target:IsDead() and not target:IsReleased() and target:CanBeSelected() then        
        if self._CurTargetId == target._ID then
            return true
        end
        
        if host_player._IsTargetLocked then
            self._CurTargetId = target._ID
            return true
        end
    end
   
    return false
end

def.method("=>", "number").GetEnemyDetectRadius = function(self)
    local radius = self._AutoFightConfig.SearchRadius
    if game and game:GetCurMapAutoFightType() == AFT.DungeonGoal then
        radius = self._AutoFightConfig.DungeonSearchRadius
    end
    return radius
end

local max_dis_sqr = 0
local function IsDistanceOk(v)
    if not v:CanBeAttacked() then 
        return false
    end

    local host_player = game._HostPlayer  
    local hostPosX, hostPosY, hostPosZ = host_player:GetPosXYZ()
    local posX, posY, posZ = v:GetPosXYZ()
    if SqrDistanceH(hostPosX, hostPosZ, posX, posZ) > max_dis_sqr then
        return false
    end

    if not GameUtil.PathFindingCanNavigateToXYZ(hostPosX, hostPosY, hostPosZ, posX, posY, posZ, _G.NAV_STEP) then
        return false
    end

    return true
end

local function EnemyFilter(v)
    if not v:CanBeAttacked() then 
        return false
    end

    local host_player = game._HostPlayer  
    local hostPosX, hostPosY, hostPosZ = host_player:GetPosXYZ()
    local posX, posY, posZ = v:GetPosXYZ()
    if SqrDistanceH(hostPosX, hostPosZ, posX, posZ) > max_dis_sqr then
        return false
    end

    if v:GetRelationWithHost() ~= "Enemy" then
       return false
    end

    if not GameUtil.PathFindingCanNavigateToXYZ(hostPosX, hostPosY, hostPosZ, posX, posY, posZ, _G.NAV_STEP) then
        return false
    end

    return true
end

def.method("boolean", "function", "function", "=>", CEntity).FindTarget = function(self, detect_player, disfunc, filterfunc)
    local elseplayer_manager = game._CurWorld._PlayerMan
    local npc_manager = game._CurWorld._NPCMan
    local dis_limit = self:GetEnemyDetectRadius()
    local host_player = game._HostPlayer
    max_dis_sqr =  dis_limit * dis_limit

    local monster_function = IsDistanceOk
    if disfunc ~= nil then
        monster_function = disfunc
    end

    local target = nil
    local hostX, hostZ = host_player:GetPosXZ()
    local dis_mon = 100000
    local filter_monster = npc_manager:GetByFilter("Enemy", monster_function)
    if filter_monster then
        target = filter_monster
        local monster_x, monster_z = filter_monster:GetPosXZ()
        dis_mon = SqrDistanceH(hostX, hostZ, monster_x, monster_z)
    end

    -- 其他玩家
    if detect_player then
        local player_function = EnemyFilter
        if filterfunc then
            player_function = filterfunc
        end

        local filter_player = elseplayer_manager:GetByFilter(player_function)
        if filter_player then
            -- 有仇恨 锁定逻辑
            if not host_player:IsEntityHate(filter_player._ID) then
                local player_x, player_z = filter_player:GetPosXZ()
                local dis_player = SqrDistanceH(hostX, hostZ, player_x, player_z) 
                if dis_player < dis_mon then
                    target = filter_player
                end
            -- 距离优先
            else
                target = filter_player
            end
        end
    end

    return target
end

local function GetTargetDistance(self)
    local ret = 10000
    local host_player = game._HostPlayer 
    if self._CurTargetId > 0 then
        local entity = game._CurWorld:FindObject(self._CurTargetId)
        if entity then             
            local hostPosX, hostPosY, hostPosZ = host_player:GetPosXYZ()
            local posX, posY, posZ = entity:GetPosXYZ()
            ret = DistanceH(hostPosX, hostPosZ, posX, posZ)
        end
    end
    return ret
end

local function MoveTo(self, target)
    local host_player = game._HostPlayer
    -- 瑞龙需求 不给提示
    if not host_player:CanMove() then
        return
    end

    local pos = target:GetPos()
    local offset = host_player:GetRadius() + target:GetRadius() + 1
    local OnReach = function()    
        host_player:StopNaviCal() 
    end
    host_player:Move(pos, offset, OnReach, OnReach) 
end

local function GetRuneEleType(hp, skillId)
    local runeId = 0
    local skillMap = hp._UserSkillMap
    for _,v in ipairs(skillMap) do
        if v.SkillId == skillId then
            for _, m in ipairs(v.SkillRuneInfoDatas) do
                if m.isActivity then
                    runeId = m.runeId 
                    break            
                end
            end
            break
        end
    end

    if runeId == 0 then return 0 end

    local temp = CElementData.GetRuneTemplate(runeId)
    if temp then
        return temp.ElementType
    end
    return 0
end

local function HasAttackPowerIncreaseBuff(hp)
    return (hp:HasState(31) or hp:HasState(205) or hp:HasState(206) or hp:HasState(207))
end

local IsForbidSkill = function(self, skillId)
    local is_forbid = false
    for i,v in ipairs(self._ForbidSkillId) do
        if v == skillId then
            is_forbid = true
        end
    end
    return is_forbid
end

-- 获取可用技能
local function GetProperSkillID(self, target)
    local host_player = game._HostPlayer
    local host_skill = host_player._SkillHdl   

    if self._ManualSkillId ~= 0 and host_skill:CanCastSkillNow(self._ManualSkillId, target) then
        return self._ManualSkillId
    end

    -- changed
    if host_player:IsModelChanged() then
        local changed_skills_list = host_player:GetTransformSkills()
        local skill_cast_indexs = self._AutoFightConfig.ChangedSkillsIndex
        -- 按照配置顺序进行技能筛选
        if changed_skills_list ~= nil and skill_cast_indexs ~= nil then
            for i,v in ipairs(skill_cast_indexs) do
                if v > 0 then
                    local skillid = changed_skills_list[v]
                    if skillid ~= nil and skillid > 0 and host_skill:CanCastSkillNow(skillid, target) then
                        return skillid
                    end
                end
            end
        end
        -- 如果变身后所有技能都是0，则无法释放技能
        return 0
    end

    -- normal
    local config = self._AutoFightConfig.SkillsList
    local hpProf = host_player._InfoData._Prof
    local config_skills = config[hpProf]
    for i = 1, #config_skills do
        local skillId = config_skills[i]
        if not IsForbidSkill(self,skillId) then
            if hpProf == EnumDef.Profession.Aileen then 
                local hpPercent = host_player._InfoData._CurrentHp / host_player._InfoData._MaxHp
                if hpPercent > 0.8 then
                    -- 10号技能装备雷系纹章 或者 无攻击力加成Buff 可释放44
                    if skillId == 44 then
                        local eleType = GetRuneEleType(host_player, 10)
                        if (eleType == EElementType.Lightning_EElementType) or (not HasAttackPowerIncreaseBuff(host_player)) then
                            if host_skill:CanCastSkillNow(44, target) then
                                return 44
                            end
                        end
                    end
                    -- 45号技能装备雷系纹章 或者 暗系纹章 可释放45
                    if skillId == 45 then
                        local eleType = GetRuneEleType(host_player, 45)
                        if eleType == EElementType.Lightning_EElementType or eleType == EElementType.Dark_EElementType then
                            if host_skill:CanCastSkillNow(45, target) then
                                return 45
                            end
                        end
                    end
                end

                if (hpPercent > 0.8 and skillId ~= 44 and skillId ~= 45) or hpPercent <= 0.8 then
                    if host_skill:CanCastSkillNow(skillId, target) then
                        return skillId
                    end
                end
            elseif hpProf == EnumDef.Profession.Archer then
                if host_skill:CanCastSkillNow(skillId, target) then
                    -- 应要求写死 后跳技能检测与目标距离  
                    if config_skills[i] == 50 then
                        if self:HasTarget() and (GetTargetDistance(self) < self._AutoFightConfig.JumpDistance) then
                            return config_skills[i] 
                        end                       
                    else
                        return config_skills[i]
                    end
                end
            else
                if host_skill:CanCastSkillNow(skillId, target) then
                    return skillId
                end
            end
        end
    end

    return 0
end

-- 获取技能模板
local function GetSkillTempData(skill_id)
    local skill_template = nil
    local host_player = game._HostPlayer
    if host_player:IsModelChanged() then
        skill_template = CElementSkill.Get(skill_id) 
    else
        skill_template = host_player:GetEntitySkill(skill_id)
        if not skill_template then
            skill_template = CElementSkill.Get(skill_id) 
            warn("ori model state can not get skill info, get from data skill_id = "..tostring(skill_id),debug.traceback())
        end
    end
    return skill_template
end

local function IsMovingSkill(self, skillId)
    local movingSkillsSet = self._AutoFightConfig.MovableSkills
    if movingSkillsSet == nil or #movingSkillsSet == 0 then return false end

    for i,v in ipairs(movingSkillsSet) do
        if v == skillId then
            return true
        end
    end

    return false
end

-- 释放主角技能
def.method(CEntity).ExecHostSkill = function(self, target)
    -- 目标不对
    if target == nil then return end

    -- 目标不合法
    if target:IsReleased() or target:IsDead() or not target:CanBeAttacked() then
        return
    end

    local hp = game._HostPlayer
    local hpSkill = hp._SkillHdl 

    local dis = Vector3.DistanceH(hp:GetPos(), target:GetPos()) - hp:GetRadius() - target:GetRadius()
    if hpSkill:IsCastingSkill() then
        --如果正在释放技能可移动，向目标移动
        local curSkillId, _ = hpSkill:GetCurSkillInfo()
        if IsMovingSkill(self, curSkillId) then
            local curSkillTemp = GetSkillTempData(curSkillId)
            if curSkillTemp.MaxRange > 0 and dis > curSkillTemp.MaxRange then 
                MoveTo(self, target)
            end
            -- 如果边放技能 边向目标移动，后面的逻辑应该就不用再走了
            return
        end
    end

    local skill_id = GetProperSkillID(self, target) 
    if skill_id <= 0 then return end

    local skill_template = GetSkillTempData(skill_id)
    if skill_template == nil then return end

    if hpSkill:IsCastingSkill() then
        --如果正在释放技能，不释放终结技能 
        if skill_id ~= self._ManualSkillId and skill_template.Category == SkillCategory.Ultimate then
            return
        end
    end

    -- 以下移动逻辑不能交由技能来执行，会卡住遗迹2平台；
    -- 因为技能释放中，如果有目标，移动会通过FollowTarget来进行，出现不按照预定路线进行的情况
    -- 修复方式：修改FollowTarget实现，采用Move类似方式实现  -- added by Jerry
    --技能最大距离检测
    if skill_template.MaxRange < 0 then
        --do nothing
    elseif skill_template.MaxRange == 0 then
        hpSkill:CastSkill(skill_id, false)
        self._ManualSkillId = 0        
    elseif skill_template.MaxRange > 0 then        
        if dis > skill_template.MaxRange then   
            MoveTo(self, target)
        else
            hpSkill:CastSkill(skill_id, false)
            self._ManualSkillId = 0
        end
    end
end

def.method("=>","boolean").HasTarget = function(self)
    if self._CurTargetId ~= 0 then
        local entity = game._CurWorld:FindObject(self._CurTargetId)
        if entity then
            local relation = entity:GetRelationWithHost()
            if not entity:IsReleased() and not entity:IsDead() and entity:CanBeAttacked() and relation ~= "Friendly" then             
                return true
            end
        end
    end
    return false
end

def.method("table").SetForbidSkillList = function(self, forbidTable)
    self._ForbidSkillId = {}
    for i,v in ipairs(forbidTable) do
        self._ForbidSkillId[#self._ForbidSkillId + 1] = v
    end
end

def.virtual().Stop = function(self)
    self._CurTargetId = 0
    if self._TimerId > 0 then
        _G.RemoveGlobalTimer(self._TimerId)
        self._TimerId = 0
    end
    self._ManualSkillId = 0 
    self._TargetTidList = {} 
    self._Paused = false
end

CAutoFightBase.Commit()
return CAutoFightBase