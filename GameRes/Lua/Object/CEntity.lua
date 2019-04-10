local Lplus = require "Lplus"
local CModel = require "Object.CModel"
local CStateMachine = require "FSM.CStateMachine"
local CFSMStateBase = require "FSM.CFSMStateBase"
local ObjectInfoList = require "Object.ObjectInfoList"
local CCooldownHdl = require "ObjHdl.CCooldownHdl"
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local CSkillSealInfo = require "Skill.CSkillSealInfo"
local CMagicContolInfo = require "Skill.CMagicContolInfo"
local CElementData = require "Data.CElementData"
local CElementSkill = require "Data.CElementSkill"
local JudgementHitType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitType
local CPateBase = require "GUI.CPate".CPateBase
local Template = require "PB.Template"
local ClinetData = require "PB.data"
local CSharpEnum = require "Main.CSharpEnum"
local CGame = Lplus.ForwardDeclare("CGame")
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local EDEATH_STATE = require "PB.net".DEATH_STATE    --死亡状态类型
local CHUDText = require "GUI.CHUDText"
local SkillCategory = require "PB.Template".Skill.SkillCategory
local StateSubType = require "PB.Template".State.StateSubType
local StateType = require "PB.Template".State.StateType
local BuffChangeEvent = require "Events.BuffChangeEvent"
local CBuff = require "Skill.CBuff"
local NotifyQuestDataChangeEvent = require "Events.NotifyQuestDataChangeEvent"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local CFxObject = require "Fx.CFxObject"
  
local CEntity = Lplus.Class("CEntity")
local def = CEntity.define

def.field("number")._ID = 0
def.field("number")._TransformID = 0
def.field("userdata")._GameObject = nil   -- CModel父节点，逻辑控制节点
def.field(CModel)._Model = nil            -- 原模型
def.field("table")._OnLoadedCallbacks = nil
def.field(ObjectInfoList.CObjectInfo)._InfoData = nil
def.field("table")._InitPos = nil
def.field("table")._InitDir = nil
def.field("table")._SkillDestDir = nil
def.field("table")._InitRotation = nil        --矿物等直接用rotation
--def.field("table")._ServerPos = nil         --取消_ServerPos

def.field(CModel)._TransformerModel = nil         -- 变化后的模型
def.field("boolean")._IsModelChanging = false
def.field("table")._OnTransformerLoadedCallbacks = nil

def.field(CStateMachine)._FSM = nil
def.field(CHitEffectInfo)._HitEffectInfo = nil
def.field(CSkillSealInfo)._SealInfo = nil
def.field(CPateBase)._TopPate = nil
def.field(CCooldownHdl)._CDHdl = nil
def.field(CObjectSkillHdl)._SkillHdl = nil
def.field(CMagicContolInfo)._MagicControlinfo = nil    -- 魔法控制列表

def.field("boolean")._IsReady = false
def.field("boolean")._IsReleased = false
def.field("boolean")._IsCullingVisible = true

def.field("boolean")._LoadedIsShow = true
def.field("number")._DeathState = 1  --net.DEATH_STATE
def.field("boolean")._IsFlaw = false --破绽
def.field("userdata")._Shadow = nil
def.field("boolean")._FadeOutWhenLeave = true
def.field("boolean")._IsStealth = false         -- 隐身

-- 战斗状态
def.field("boolean")._IsInCombatState = false
def.field("number")._CurrentTargetId = 0
def.field("number")._AnimationLockerTimerID = 0   -- 顿帧时使用 

def.field("number")._MoveType = 0 --移动状态
def.field("table")._BuffStates = BlankTable

def.field("table")._HangPointCache = BlankTable

def.field(CHUDText)._HUDText = nil

--技能信息（仅对Palyer和PlayerMirror有效）
def.field("table")._UserSkillMap = BlankTable
def.field("number")._CurLogoType = -2

-- { LeftHand需要武器， RightHand需要武器，InHand, 左手武器GameObject，右手武器GameObject }
def.field("table")._CurWeaponInfo = nil

def.field("boolean")._IsEnableShadow = false
def.field("function")._OnNotifyQuestDataChangeEvent = nil

def.field("number")._MaxMoveRate = 0                       -- 移动速率上限和动画播放速率上限
def.field("number")._MaxPlayAnimationRate = 0
def.field("number")._MinPlayAnimationRate = 0

def.field("table")._AnimationReplaceTable = nil
def.field("table")._HeadInstructionTable = nil 
def.field(CFxObject)._HeadEffectObject = nil 
def.field("number")._SqrDistanceHToHost = 0
def.field("number")._HeightOffsetY = 0              --比地表高度高多少,飞行宠物使用

-- def.field("number")._OldObjPlayRate = 0 -- 测试用
def.field("number")._CampId = 0
def.field("table")._EnemyCampTable = BlankTable       -- 敌对阵营列表。
def.field("number")._CollisionRadius = 0 -- 碰撞体半径

def.field("table")._StopMovePos = nil   --是否处于stopmove的强制位移中，如果是，则需要在MoveBeahavior结束时同步一下位置

def.field("table")._HitGfxs = BlankTable

def.virtual("table").Init = function(self, entityInfo)
	self._ID = entityInfo.EntityId

    --pb转vector3
    local pbPos = entityInfo.Position
    local pbOri = entityInfo.Orientation
    local pbRot = entityInfo.Rotation
    self._InitPos = Vector3.New(pbPos.x, pbPos.y, pbPos.z)
    self._InitDir = Vector3.New(pbOri.x, pbOri.y, pbOri.z)
    self._InitRotation = Vector3.New(pbRot.x, pbRot.y, pbRot.z)

    self._HeadInstructionTable = {}
    self._HeadInstructionTable.IsHeadInstructionShow = entityInfo.IsHeadInstructionShow
    self._HeadInstructionTable.HeadInstructionOffSet = entityInfo.HeadInstructionOffSet
end

def.method("table").InitAnimationTable = function (self, animationInfos)
    if animationInfos ~= nil then 
        self:SaveReplaceAnimations(animationInfos)
    end
end

def.method("function").AddLoadedCallback = function (self, cb)
    if self:IsModelLoaded() then
        cb(self)
    else
        if not self._IsModelChanging then
            if self._OnLoadedCallbacks == nil then
                self._OnLoadedCallbacks = {}
            end
            self._OnLoadedCallbacks[#self._OnLoadedCallbacks+1] = cb
        else
            if self._OnTransformerLoadedCallbacks == nil then
                self._OnTransformerLoadedCallbacks = {}
            end
            self._OnTransformerLoadedCallbacks[#self._OnTransformerLoadedCallbacks+1] = cb
        end
    end
end

def.method("boolean", "number").AddObjectComponent = function (self, is_host, radius)
    local root = GameUtil.GetEntityBaseRes()
    if is_host then
        root.name = "HostPlayer"
    else
        root.name = tostring(self:GetTemplateId()) .. "_" .. tostring(self._ID)
    end
    
    local main_model_go = self._Model._GameObject
    if main_model_go ~= nil then
        main_model_go.parent = root
    end

    self._GameObject = root

    if self._InitPos ~= nil then
        self._InitPos.y = GameUtil.GetMapHeight(self._InitPos)
        self._GameObject.position = self._InitPos
        --self._InitPos = nil
    end
    
    if self._InitDir ~= nil then
        self._GameObject.forward = self._InitDir
    end
    
    if not IsNil(self._GameObject) then
        self._Shadow = self._GameObject:FindChild("Shadow")
    end

    self._IsReady = true
    GameUtil.AddObjectComponent(self, root, self._ID, self:GetObjectType(), radius)
end

def.method("=>", "boolean").IsModelLoaded = function(self)
    return self._IsReady and not self._IsModelChanging
end

def.virtual("table").UpdateTransformSkills = function(self, data)
end

def.virtual("=>", "table").GetTransformSkills = function(self)
    return nil
end

def.virtual().OnModelLoaded = function (self)
    --默认隐藏头部信息
    if not self:IsNeedHideHpBarAndName() then
        self:CreatePate()
    end
    --控制播放头顶特效
    self:PlayEntityHeadEffect()
    --加载后是否立刻显示
    self:SetActive(self._LoadedIsShow)

    if self._OnLoadedCallbacks then
        for i,v in ipairs(self._OnLoadedCallbacks) do
            v(self)
        end
        self._OnLoadedCallbacks = nil
    end
    
    if self._MagicControlinfo ~= nil then
        self._MagicControlinfo:Refresh()
    end
end

def.virtual("=>", "table").GetPos = function (self)
    if not self._IsReady then
        if self._InitPos ~= nil then 
            return Vector3.New(self._InitPos.x, self._InitPos.y, self._InitPos.z) 
        else 
            return Vector3.zero
        end
    end
    
    return self._GameObject.position
end

def.virtual("=>", "number", "number", "number").GetPosXYZ = function (self)
    if not self._IsReady then
        local pos = self._InitPos 
        if pos ~= nil then
            return pos.x, pos.y, pos.z
        else
            return 0, 0, 0
        end
    end
    
    return self._GameObject:PositionXYZ()
end

def.virtual("=>", "number", "number").GetPosXZ = function (self)
    if not self._IsReady then
        local pos = self._InitPos 
        if pos ~= nil then
            return pos.x, pos.z
        else
            return 0, 0
        end
    end
    
    return self._GameObject:PositionXZ()
end

def.virtual("table").SetPos = function (self, pos)
    if pos == nil then
        warn("SetPos's pos is nil", debug.traceback())
        return
    end
    
    if not self._IsReady then
        self._InitPos = pos
        return
    end
    pos.y = GameUtil.GetMapHeight(pos) + self._HeightOffsetY

    self._GameObject.position = pos
end

def.virtual("=>", "table").GetDir = function (self)
    if not self._IsReady then
        return self._InitDir or Vector3.forward
    end
    
    return self._GameObject.forward
end

def.virtual("=>", "number", "number", "number").GetDirXYZ = function (self)
    if not self._IsReady then
        local dir = self._InitDir 
        if dir ~= nil then
            return dir.x, dir.y, dir.z
        else
            return 0, 0, 1
        end
    end
    
    return self._GameObject:ForwardXYZ()
end

def.virtual("=>", "number", "number").GetDirXZ = function (self)
    if not self._IsReady then
        local dir = self._InitDir 
        if dir ~= nil then
            return dir.x, dir.z
        else
            return 0, 1
        end
    end
    
    return self._GameObject:ForwardXZ()
end

def.virtual("table").SetDir = function (self, dir)
    if dir == nil then
        warn("Setdir's dir is nil", debug.traceback())
    return end

    dir.y = 0
    dir = dir:Normalize()
    if not self._IsReady then
        self._InitDir = dir
        return
    end

    self._GameObject.forward = dir
end

-- 过程切换
def.virtual("table", "number").ChangeDirContinued = function (self, dir, speed)
end

--上线同步buff
def.method("table").InitStates = function(self, buffList)
    self:ReleaseBuffStates()
    
    if buffList == nil then return end
    for i,v in ipairs(buffList) do
        --获取状态信息State数据
        local info = {}
        if v.SkillId and v.SkillLevel then
            info.Skill = 
            { 
                ID = v.SkillId,
                Level = v.SkillLevel,
            }
        end
        if v.TalentId and v.TalentLevel then
            info.Talent = 
            {
                ID = v.TalentId,
                Level = v.TalentLevel,
            }
        end
        if v.RuneId and v.RuneLevel then
            info.Rune = 
            {
                ID = v.RuneId,
                Level = v.RuneLevel,
            }
        end
        local buff = CBuff.new(self, v.Id, v.Duration, v.OriginId, info)
        
        if buff ~= nil then                    
            table.insert(self._BuffStates, buff)
        end
    end
end

def.method().RefreshMagicControl = function (self)
    -- 更新可能的魔法控制状态, 写死9999, 等服务器刷掉
    if self._MagicControlinfo then
        self._MagicControlinfo:Refresh()
    end
end

-- 整体初始化
def.virtual("table").InitMagicControls = function (self, states)
    if self._MagicControlinfo == nil then
        self._MagicControlinfo = CMagicContolInfo.new(self)
    end

    self._MagicControlinfo:Init(states)
end

-- 单体更新
def.virtual("number").AddMagicControl = function (self, state)
    if self._MagicControlinfo == nil then
        self._MagicControlinfo = CMagicContolInfo.new(self)
    end

    if not self:IsMagicControled() and not self:IsPhysicalControled() then
        -- 打断技能
        self:InterruptSkill(false)
        self:Stand()
        if self:IsHostPlayer() then
            self:SendBaseStateChangeEvent(true)
        end
    end

    self._MagicControlinfo:Add(state)
    self._MagicControlinfo:Refresh()
end

-- 移除状态
def.virtual("number").RemoveMagicControl = function (self, state)
    if self._MagicControlinfo then
        self._MagicControlinfo:Remove(state)
        self._MagicControlinfo:Refresh()
    end

    -- 受控状态结束，转到Stand状态
    if not self:IsMagicControled() and not self:IsDead() and not self:IsPhysicalControled() then
        self:Stand() 
        if self:IsHostPlayer() then
            self:SendBaseStateChangeEvent(false)
        end
    end
end

def.method("=>", "boolean").IsMagicControled = function (self)
    if self._MagicControlinfo then
        return (self._MagicControlinfo:GetLength() > 0)
    end
    return false
end

def.method("=>", "boolean").IsPhysicalControled = function(self)
    return self:GetCurStateType() == FSM_STATE_TYPE.BE_CONTROLLED
end

def.virtual().OnEnterPhysicalControled = function(self)
end

def.virtual().OnLeavePhysicalControled = function(self)
    -- case dead: 不可能出现，在OnDie中会先Clear受击状态
    -- case move: 不可能出现，受控中不会Move
    -- case skill: 不可能出现，受控中不会Move
    -- case stand: stand中会播放 
        -- 处于魔法受控 -> 需要刷新魔法表现？（需要根据物理受控vs魔法受控优先级处理）
        -- 处于正常状态 -> Stand
        -- 受伤动画只有在 stand 和 move中才会播放，所以不用考虑

    -- 受控状态结束，转到Stand状态
    if not self:IsMagicControled() and not self:IsDead() then
        self:Stand() 
    elseif self:IsMagicControled() then
        self:RefreshMagicControl()
    end
end

-- 变身
def.virtual("number").ChangeShape = function (self, monster_id)
    self:AddLoadedCallback(function(entity)
        if self._TransformerModel ~= nil and self._TransformID == monster_id then           --无需重新加载
            warn("same model not need to change")
        else
            --删除原来的model
            if self._TransformerModel ~= nil then
                self._TransformerModel:Destroy()
                self._TransformerModel = nil
            end

            self._TransformID = monster_id
            local data = CElementData.GetMonsterTemplate(monster_id)
            local model_path = data.ModelAssetPath
            if model_path ~= "" then
                local function callback( ret )
                    -- 变身模型加载中再次变身
                    if monster_id == self._TransformID then
                        if not self._IsReleased then 
                            if ret then
                                self:OnTransformerModelLoaded()
                            else
                                self._TransformID = 0
                                self._TransformerModel:Destroy()
                                self._TransformerModel = nil
                            end
                        else
                            self._TransformID = 0   
                            self._TransformerModel:Destroy()
                            self._TransformerModel = nil
                        end
                    end
                end

                -- 与范导新增规则 变身清除 受击rim效果
                local CVisualEffectMan = require "Effects.CVisualEffectMan"
                CVisualEffectMan.StopTwinkleWhiteEffect(self)

                local model = CModel.new()
                model._ModelFxPriority = self:GetModelCfxPriority()
                self._TransformerModel = model
                self._IsModelChanging = true
                model:Load(model_path, callback)   
            end
        end    
    end)    
end

-- 变身切回
def.virtual().ResetModelShape = function (self)
    if self._TransformID == 0 then
        warn("shape is original , not need to reset")
        return
    end 
    --删除原来的mount model
    if self._TransformerModel ~= nil then     
        -- 模型可能正在加载中 gameobject null
        if self:IsModelLoaded() and not IsNil( self._TransformerModel:GetGameObject()) then
            GameUtil.RefreshObjectEffect(self._Model:GetGameObject(), self._TransformerModel:GetGameObject())
        end
        self._TransformerModel:Destroy()
        self._TransformerModel = nil
    end

    self._TransformID = 0

    if self._SkillHdl then
        self._SkillHdl:StopCurActiveSkill(false)
    end

    -- 显示
    if self._Model then
        self._Model._GameObject:SetActive(true)        
        if self:IsDead() then
            self:Dead()
        else
            self:Stand()
        end

        local pate = self._TopPate
        if pate ~= nil then    
            local follow = pate._FollowComponent 
            if follow ~= nil then  
                if self:IsMonster() == true then
                    local monsterData = CElementData.GetTemplate("Monster", self:GetTemplateId())
                    follow:AdjustOffsetWithScale(self._Model._GameObject, 0, monsterData.BodyScale)
                else
                    follow:AdjustOffset(self._Model._GameObject, 0)    
                end              
                           
            end
        end        
    end
end

def.virtual().OnTransformerModelLoaded = function (self)
    if self._IsReleased then return end 
    local go = self._TransformerModel._GameObject
    if not IsNil(go) then
        go.name = "Transformer"
        GameUtil.SetLayerRecursively(go, self:GetRenderLayer())
        go.parent = self._GameObject
        go.localPosition = Vector3.zero
        go.localRotation = Quaternion.identity
        GameUtil.RefreshObjectEffect(go, self._Model:GetGameObject())
        local data = CElementData.GetMonsterTemplate(self._TransformID)
        if data then            
            go.localScale = Vector3.one * data.BodyScale
        end
    end

    -- 隐藏
    if self._Model ~= nil then
        self._Model._GameObject:SetActive(false)
    end

    self._IsModelChanging = false

    if self:IsDead() then
        self:Dead() 
    else
        self:Stand()       
    end

    if self._OnTransformerLoadedCallbacks then
        for i,v in ipairs(self._OnTransformerLoadedCallbacks) do
            v(self)
        end
        self._OnTransformerLoadedCallbacks = nil
    end

    local pate = self._TopPate
    if pate ~= nil then    
        local follow = pate._FollowComponent 
        if follow ~= nil then
            if self:IsMonster() == true then
                local monsterData = CElementData.GetTemplate("Monster", self:GetTemplateId())
                follow:AdjustOffsetWithScale(go, 0, monsterData.BodyScale)
            else
                follow:AdjustOffset(go, 0)
            end
        end
    end

    if self._SkillHdl then
        self._SkillHdl:StopCurActiveSkill(false)
    end
end

def.virtual("=>", "number").GetRenderLayer = function (self)
    return EnumDef.RenderLayer.Default
end


def.method("=>", "boolean").IsCullingVisible = function (self)
    return self._IsCullingVisible
end

def.method("=>", "boolean").IsLogicInvisible = function (self)
    return self._IsStealth
end

def.method("=>", "boolean").IsVisible = function (self)
    return self:IsCullingVisible() and not self:IsLogicInvisible()
end

def.virtual("boolean").EnableCullingVisible = function (self, visible)
    --if self._IsCullingVisible ~= visible then
        self._IsCullingVisible = visible
        if self._Model ~= nil and not self:IsLogicInvisible() then
            self._Model:SetVisible(visible)
        end
    --end
    self:EnableShadow(self._IsEnableShadow)     --刷新
end

def.method("=>", "dynamic", "dynamic").GetCurAniClip = function (self) 
    local md = self:GetCurModel()
    local ani, time
    if md then
        ani, time = md:GetCurAniClip()
    end
    return ani, time
end

-- 播放一个制定的动作片段
def.method("string", "number").PlayAssignedAniClip = function (self, ani_name, start_time) 
    local md = self:GetCurModel()  
    if ani_name ~= "" and start_time >=0 then
        if md then
            md:PlayAssignedAniClip(ani_name, start_time)
        end
    else
        warn("error occur in entity PlayAssignedAniClip!")
    end
end

def.virtual("=>", "boolean").IsInServerCombatState = function(self)
    return  self._IsInCombatState
end

def.virtual("table", "function").ChangeAllPartShape = function(self, part_shape_map, callback)
    warn("CEntity can not call ChangeAllPartShape function")
end

def.virtual("=>", "number").GetEntityBodyScale = function(self)
    return 1
end

-- 还原部分身体的变化 小怪没有
def.virtual("function").ResetPartShape = function(self, callback)
    warn("CEntity can not call ResetPartShape function")
end

def.virtual("=>", "boolean").IsBodyPartChanged = function (self)
    warn("CEntity can not call IsBodyPartChanged function")
    return false
end

--是否是骑乘状态(表现)
def.virtual("=>", "boolean").IsOnRide = function (self)
    return false
end

--获得坐骑TID
def.virtual("=>", "number").GetMountTid = function (self)
    return 0
end

def.method("boolean").SetActive = function (self,isShow)
    if self._GameObject ~= nil then
        self._GameObject:SetActive(isShow)
    end
end

def.virtual("=>", "boolean").CanRide = function (self)
    if (self:IsDead() or not self:IsModelLoaded() or self._IsInCombatState ) then
        return false
    end

    local cur_fsm_state = self:GetCurStateType()
    if cur_fsm_state == FSM_STATE_TYPE.MOVE or cur_fsm_state == FSM_STATE_TYPE.IDLE then
        return true
    end
    
    return false
end

def.virtual("number", "boolean").Ride = function (self, tid, isPlayBornAnim)
end

def.virtual().UnRide = function (self)
end

def.method("=>", "boolean").IsVisibleInCamera = function (self)
    if self._GameObject == nil then return false end
    return GameUtil.IsGameObjectInCamera(self._GameObject, Vector3.New(0.1, 0.1, 0.1))
end

def.virtual("=>", "number").GetTemplateId = function(self)
    return 0
end

-- 更新护盾值
def.virtual("number").UpdateShield = function(self, val)
    -- warn("更新护盾值 UpdateShield ...", self._InfoData._Name,self._InfoData._CurShield, val)
    self._InfoData._CurShield = val

    self:UpdateTopPate(EnumDef.PateChangeType.HP)
    local EntityHPUpdateEvent = require "Events.EntityHPUpdateEvent"
    local event = EntityHPUpdateEvent()
    event._EntityId = self._ID
    CGame.EventManager:raiseEvent(nil, event)
end

def.virtual("table", "boolean").UpdateFightProperty = function(self, properties, isNotifyFightScore)
    if self._InfoData == nil then return end

    local ENUM_FIGHTPROPERTY = require "PB.data".ENUM_FIGHTPROPERTY
    for k,v in pairs(properties) do
        if v.Index == ENUM_FIGHTPROPERTY.MOVESPEED then
            --self._InfoData._MoveSpeed = v.Value
            self:SetMoveSpeed(v.Value)
        elseif v.Index == ENUM_FIGHTPROPERTY.MAXHP then
            self._InfoData._MaxHp = v.Value
        elseif v.Index == ENUM_FIGHTPROPERTY.CURRENTHP then
            self._InfoData._CurrentHp = v.Value
        elseif v.Index == ENUM_FIGHTPROPERTY.MAXSTAMINA then
            self._InfoData._MaxStamina = v.Value
            
        elseif v.Index == ENUM_FIGHTPROPERTY.CURRENTSTAMINA then
            self._InfoData._CurrentStamina = v.Value
        end
    end
end

def.virtual("table", "boolean").UpdateFightProperty_Simple = function(self, properties, isNotifyFightScore)
    self:UpdateFightProperty(properties, isNotifyFightScore)
end

--获得当前耐力值
def.method("=>", "number").GetCurrentStamina = function (self)
    return self._InfoData._CurrentStamina
end

def.method("=>", "userdata").GetGameObject = function (self)
    if not self._IsReady or self._IsReleased then
        return nil
    end
    
    return self._GameObject
end

-- 获得声望图像路径。PS：目前只有怪物和NPC，Player暂时没有，以后相应玩法出了之后有可能修改（彭仲天）
def.method("=>", "string").GetReputationIconPath = function(self)
    local str = ""
    -- warn("lidaming GetReputationIconPath self:GetReputation() == ", self:GetReputation())

    -- 彭仲天:: 声望数据 没配置完，为0时先写死18   2018-06-07
    local id = (self:GetReputation() == 0 and 18 or self:GetReputation())
    local template = CElementData.GetTemplate("Reputation", id)

    if template then
        str = template.IconAtlasPath
    end
    -- str不能等于nil、
    if str == nil then
        str = ""
    end
    -- warn("lidaming GetReputationIconPath str == ", str)
    return str
end


def.method("table", "number").TurnToDir = function (self, dir, speed)
    dir.y = 0
    dir = dir:Normalize()
    if not self._IsReady then
        self._InitDir = dir
        return
    end
    
    self:PlayAnimation(EnumDef.CLIP.BATTLE_RUN, EnumDef.SkillFadeTime.MonsterOther, false, 0, 1)
    GameUtil.AddTurnBehavior(self._GameObject, dir, speed, function()
        if self:GetCurStateType() == FSM_STATE_TYPE.IDLE then
            self:Stand()
        end
    end, false, 0)
end

def.method().ShowRenerInfo = function (self)
    local rds = self:GetCurModel().m_renderers
    for i = 1, #rds do
        local mat = rds[i].sharedMaterial
        if mat then
            warn("mat " .. tostring(mat))
            warn("tex " .. tostring(mat.mainTexture))
            warn("shader " .. tostring(mat.shader))
        else
            warn("sharedMaterial is null")
        end
    end
end

local function HUDTextDoPlay(self, hud_type, content)
    if self._HUDText == nil then
        self._HUDText = CHUDText.new(self)
    end
    self._HUDText:Play(hud_type, content)
end

def.virtual("number", "number", "boolean", "number").OnHurt = function(self, damage, attacker_id, is_critical_hit, elem_type)
	if game._HostPlayer._ID == attacker_id then
		if damage<=-1 or damage>=1 then
			local hud_type = -1
			local s_text = tostring(damage)

			--warn("OnHurt "..damage..", "..tostring( is_critical_hit)..", "..elem_type)

			if elem_type>0 then
				if elem_type == EnumDef.DamageElemType.light then
					hud_type = is_critical_hit and EnumDef.HUDType.attack_elem_light_c or EnumDef.HUDType.attack_elem_light
				elseif elem_type == EnumDef.DamageElemType.dark then
					hud_type = is_critical_hit and EnumDef.HUDType.attack_elem_dark_c or EnumDef.HUDType.attack_elem_dark
				elseif elem_type == EnumDef.DamageElemType.ice then
					hud_type = is_critical_hit and EnumDef.HUDType.attack_elem_ice_c or EnumDef.HUDType.attack_elem_ice
				elseif elem_type == EnumDef.DamageElemType.fire then
					hud_type = is_critical_hit and EnumDef.HUDType.attack_elem_fire_c or EnumDef.HUDType.attack_elem_fire
				elseif elem_type == EnumDef.DamageElemType.wind then
					hud_type = is_critical_hit and EnumDef.HUDType.attack_elem_wind_c or EnumDef.HUDType.attack_elem_wind
				elseif elem_type == EnumDef.DamageElemType.thunder then
					hud_type = is_critical_hit and EnumDef.HUDType.attack_elem_thunder_c or EnumDef.HUDType.attack_elem_thunder
				end
				s_text = "A"..s_text
			else		
        			hud_type = is_critical_hit and EnumDef.HUDType.attack_crit or EnumDef.HUDType.attack_normal
			end

			if hud_type > -1 then
				HUDTextDoPlay(self, hud_type, s_text)
			end
		end
	end
end

def.virtual("number", "number").OnHealed = function(self, type, hp_healed)
    HUDTextDoPlay(self, type, "+"..tostring(hp_healed))
end

def.virtual().OnAbsorb = function(self)                 --吸收
    local hud_type = self:IsHostPlayer() and EnumDef.HUDType.under_attack_absorb or EnumDef.HUDType.attack_absorb
    HUDTextDoPlay(self, hud_type, "A")
end

def.virtual().OnBlock = function(self)                 --格挡
    local hud_type = (self:IsHostPlayer() and EnumDef.HUDType.under_attack_block or EnumDef.HUDType.attack_block)
    HUDTextDoPlay(self, hud_type, "B")
end

def.virtual().OnSkillCanceled = function(self)
	if self._SkillHdl:IsCastingSkill() then
		warn("OnSkillCanceled ".. self._ID)            --打断
		local hud_type = ( self:IsHostPlayer() and EnumDef.HUDType.attacked_skill_canceled or EnumDef.HUDType.skill_canceled)
		HUDTextDoPlay(self, hud_type, "C")
	end
end

def.method("=>", "boolean").IsDead = function (self)
    return (self._DeathState ~= EDEATH_STATE.LIVE )
end

def.method("=>", "boolean").IsReleased = function (self)
    return self._IsReleased
end

def.method("=>", "boolean").CanRescue = function (self)
    return false --self._DeathState == EDEATH_STATE.DEATH
end

def.method("=>", "boolean").IsInCombatState = function (self)
    return self._IsInCombatState
end

def.virtual("table", "number", "number", "function", "function").NormalMove = function (self, pos, speed, offset, successcb, failcb )
    self._StopMovePos = nil

    if not self:CanMove() then return end
    local CFSMObjMove = require "FSM.ObjectFSM.CFSMObjMove"
    local move = CFSMObjMove.new(self, pos, speed, successcb, failcb)
    self:ChangeState(move)
end

-- 仅改变C#移动逻辑
def.virtual().StopMovementLogic = function(self)
    --warn("StopMovementLogic", debug.traceback())
    if not self._IsReady or self._IsReleased then return end
    local BEHAVIOR = require "Main.CSharpEnum".BEHAVIOR
    GameUtil.RemoveBehavior(self:GetGameObject(), BEHAVIOR.MOVE)  
    GameUtil.RemoveBehavior(self:GetGameObject(), BEHAVIOR.FOLLOW)  
    GameUtil.RemoveBehavior(self:GetGameObject(), BEHAVIOR.JOYSTICK)
    GameUtil.RemoveBehavior(self:GetGameObject(), BEHAVIOR.DASH)
    
    if self._FSM and self._FSM._CurState and self._FSM._CurState._Type == FSM_STATE_TYPE.MOVE then        
        self._FSM._CurState._TargetPos = nil
    end
end

def.virtual(CEntity, "number", "number", "function", "function").FollowTarget = function (self, target, maxdis, mindis, successcb, failcb)
    if not self:CanMove() then return end
    local speed =  self:GetMoveSpeed()
    local CFSMObjMove = require "FSM.ObjectFSM.CFSMObjMove"
    local move = CFSMObjMove.new(self, target, speed, successcb, failcb)
    move._FollowParams = {MaxDis = maxdis, MinDis = mindis}
    self:ChangeState(move)
end

def.virtual().Stand = function (self)
    local CFSMObjStand = require "FSM.ObjectFSM.CFSMObjStand"
    local stand = CFSMObjStand.new(self)
    stand._IsAniQueued = false
    self:ChangeState(stand)
end

def.virtual("number", "=>", "string", "string", "number").GetEntityFsmAnimation = function (self, fsm_type)
    local animation, wingAnimation = "", ""
    local rate = 1
    if fsm_type == FSM_STATE_TYPE.IDLE then                
        if self:IsInCombatState() then
            animation = EnumDef.CLIP.BATTLE_STAND
        else
            animation = EnumDef.CLIP.COMMON_STAND
        end
    elseif fsm_type == FSM_STATE_TYPE.MOVE then
        local baseSpeed,fightSpeed = self:GetBaseSpeedAndFightSpeed()     
        if self:IsInCombatState() then                   
            animation, rate = self:CheckRunBattleAnimation(fightSpeed)   
        else
            animation, rate = self:CheckRunAnimation(baseSpeed,fightSpeed)            
        end
    else
        warn("only idle & move support in GetEntityFsmAnimation")
    end
    return animation, wingAnimation, rate
end

-- 打断寻路位移
def.virtual().StopNaviCal = function (self)
    if self:GetCurStateType() == FSM_STATE_TYPE.SKILL then   -- 技能状态
        self:StopMovementLogic()
        if self._SkillHdl ~= nil then
            self._SkillHdl:ClearSkillMoveState()
        end
    elseif self:IsPhysicalControled() or self:IsMagicControled() then  -- 受控状态
        -- Do nothing，控制状态开始结束时会自动处理
    else  -- 一般状态
        self:Stand()
    end     
end

def.virtual("number", "number", "number").Die = function (self, element_type, hit_type, corpse_stay_duration)
    local CFSMObjDead = require "FSM.ObjectFSM.CFSMObjDead"
    local dead = CFSMObjDead.new(self, element_type, hit_type, corpse_stay_duration, false)
    self:ChangeState(dead)
end

def.virtual().Dead = function(self)
    local CFSMObjDead = require "FSM.ObjectFSM.CFSMObjDead"
    local dead = CFSMObjDead.new(self, 0, 0, 0, true)
    self:ChangeState(dead)
end

def.method("string", "=>", "boolean").HasAnimation = function (self, aniname) 
    if not self:IsModelLoaded() then return false end 
    local model = self:GetCurModel()
    if model ~= nil then
        return model:HasAnimation(aniname)
    else
        return false
    end
end

def.virtual("=>", "boolean").GetChangePoseState = function(self)
    return false
end

def.virtual( "=>", "string", "number").GetChangePoseHurtData = function(self)
    return "", -1
end

def.virtual("=>", "string").GetHurtAnimation = function(self)
    local hurt_ani, _ = "", nil
    if self:IsPlayerType() and self._InfoData._Prof == EnumDef.Profession.Lancer and self:GetChangePoseState() then
        hurt_ani, _ =  self:GetChangePoseHurtData()
    end
    return hurt_ani
end

def.virtual().PlayHurtAnimation = function(self)
    if not self:IsModelLoaded() or self:IsDead() then return end 
    --技能过程中不播受伤动作
    local cur_state = self:GetCurStateType()
    if cur_state ==  FSM_STATE_TYPE.SKILL or cur_state == FSM_STATE_TYPE.BE_CONTROLLED then return end

    -- 受了魔法控制
    if self:IsMagicControled() then        
        return 
    end
    
    local model = self:GetCurModel()
    if cur_state == FSM_STATE_TYPE.IDLE then
        model:PlayHurtAnimation(false, self:GetHurtAnimation()) 
    elseif cur_state == FSM_STATE_TYPE.MOVE then
        model:PlayHurtAnimation(true, self:GetHurtAnimation()) 
    end        

    CSoundMan.Instance():Play3DAudio(self:GetAudioResPathByType(EnumDef.EntityAudioType.HurtAudio), self:GetPos(), 0)
end

def.virtual("string", "number", "boolean", "number","number").PlayMountAnimation = function(self, aniname, fade_time, is_queued, life_time,aniSpeed)
end

def.method("string", "=>", "boolean").IsPlayingAnimation = function(self, aniname)
    if not self:IsModelLoaded() then return false end 

    local model = self:GetCurModel()
    if model ~= nil then
        return model:IsPlaying(aniname)
    else
        return false
    end
end

--检测站立动画有无其他配置动画名称（Npc有重载）
def.virtual("=>","string").GetStandAnimationName = function(self)
    local animation ,isReplace = self:GetAnimationName(EnumDef.CLIP.COMMON_STAND)
    return animation
end

-- ---检测跑步动画有无其他配置动画名称（monster、Npc有重载）
-- def.virtual("=>","string").GetRunAnimationName = function(self)
--     return EnumDef.CLIP.COMMON_RUN
-- end
--[[--
动画播放统一接口
@param aniname - 动画名称
@param fade_time - cross fade时间
@param is_queued - 是否是加入动画队列
@param life_time - 动画播放时间，等于0时，按照动画原始速率播放；大于0时，调整动画speed
]]

-- 切换动画机制：
-- 1)通过服务器协议(任务事件/AI行为树/巡逻)新动作替换旧动作
-- 2)怪物、Npc模板支持新动作替换旧动作 
-- 3)服务器协议优先于模板配置
-- 除run和run_battle外 所有动画不做速度适配 默认动画播放速率为1
-- 4)根据速度变换动画速率和动画的功能 切换的是Run 和Run_battle 计算的也是针对二者的速率 不可用于其他动画 
-- 5)只要是切换到run或是run_Battle 就需要计算动画播放速率
def.virtual("string","=>","string","boolean").GetAnimationName = function (self,nowAniname)
    local isReplace = false
    if self._AnimationReplaceTable == nil then return nowAniname,isReplace end
    for k,v in ipairs(self._AnimationReplaceTable) do 
        if v.OldAniname == nowAniname then 
            isReplace = true
            return v.NewAniname,isReplace
        end
    end
    return nowAniname,isReplace
end

def.virtual("string", "number", "boolean", "number", "number").PlayAnimation = function(self, aniname, fade_time, is_queued, life_time, aniSpeed)
    if not self:IsModelLoaded() then return end 

    local replaceAnimame ,isReplace = self:GetAnimationName(aniname)
    if isReplace then 
        aniname = replaceAnimame
        if aniname == EnumDef.CLIP.COMMON_RUN then 
            local baseSpeed,fightSpeed = self:GetBaseSpeedAndFightSpeed()
            aniname,aniSpeed = self:GetRunAnimationNameAndRate( baseSpeed,fightSpeed)
        elseif aniname == EnumDef.CLIP.BATTLE_RUN then 
            local baseSpeed,fightSpeed = self:GetBaseSpeedAndFightSpeed()
            aniname,aniSpeed = self:GetPlayAnimationRateInCombat(fightSpeed)
        end
    end

    local model = self:GetCurModel()
    if model ~= nil then        
        model:PlayAnimation(aniname, fade_time, is_queued, life_time, aniSpeed)
    end
end

-- 存储人物动画替换(清空数据后在保存)
def.method("table").SaveReplaceAnimations = function (self, animationTable)
    
    if animationTable == nil or #animationTable == 0 then 
        self._AnimationReplaceTable = nil
        return
    end
    self._AnimationReplaceTable = {}
    for i,v in ipairs(animationTable) do
        self._AnimationReplaceTable[#self._AnimationReplaceTable + 1] = {}
        self._AnimationReplaceTable[#self._AnimationReplaceTable].NewAniname = v.ReplaceAnimation
        self._AnimationReplaceTable[#self._AnimationReplaceTable].OldAniname = v.OriginalAnimation

        --warn("==>", v.OriginalAnimation, "->", v.ReplaceAnimation)
    end
end

def.method("table").SaveReplaceAnimationsAndPlay = function(self, animationTable)
    self:SaveReplaceAnimations(animationTable)
    local nowAniname,time = self:GetCurAniClip()
    if nowAniname ~= nil then 
        self:PlayAnimation(nowAniname, EnumDef.SkillFadeTime.MonsterOther,false, 0, 1)
    end
end

-- 播一个半身动作
def.method("string").PlayPartialAnimation = function (self, aniname) 
    if not self:IsModelLoaded() then return end 
    if self:IsDead() and aniname ~= EnumDef.CLIP.COMMON_DIE then return end
    local model = self:GetCurModel()
    if model ~= nil then
        model:PlayPartialAnimation(aniname)
    end
end

-- 停止播放半身动作
def.method("string").StopPartialAnimation = function (self, aniname) 
    if not self:IsModelLoaded() then return end 
    if self:IsDead() and aniname ~= EnumDef.CLIP.COMMON_DIE then return end
    local model = self:GetCurModel()
    if model ~= nil then
        model:StopPartialAnimation(aniname)
    end
end

def.method("string", "number").StopAnimation = function (self, aniname, layer) 
    if not self:IsModelLoaded() then return end 
    if self:IsDead() and aniname ~= EnumDef.CLIP.COMMON_DIE then return end
    local model = self:GetCurModel()
    if model ~= nil then
        model:StopAnimation(aniname, layer)
    end
end

-- 禁掉animation
def.virtual("boolean").EnableAnimationComponent = function (self, state)
    if not self:IsModelLoaded() then return end 
    if self:IsDead() then return end
    local model = self:GetCurModel()
    if model ~= nil then
        model:EnableAnimationComponent(state)
    end
end

def.method("=>", "boolean").IsPlayerType = function (self)    
    local role_type = self:GetObjectType()
    return (role_type == OBJ_TYPE.HOSTPLAYER or role_type == OBJ_TYPE.ELSEPLAYER or role_type == OBJ_TYPE.PLAYERMIRROR)
end

def.method("=>", "boolean").IsElsePlayer = function (self)    
    local role_type = self:GetObjectType()
    return (role_type == OBJ_TYPE.ELSEPLAYER or role_type == OBJ_TYPE.PLAYERMIRROR)
end

-- 状态切换 停住受击, 受击在layer 1
def.virtual().StopHurAnimation = function (self) 
    self:StopAnimation(EnumDef.CLIP.NORMAL_HURT, 1)
    self:StopAnimation(EnumDef.CLIP.ADDITIVE_HURT, 1)
end

def.virtual("number", "=>", "string").GetAudioResPathByType = function (self, audio_type) 
    return ""
end

def.method("boolean").PlayDieAnimation = function (self, onlyLastFrame)
    if not self:IsModelLoaded() then return end 
    local model = self:GetCurModel()
    if model ~= nil then
        model:PlayDieAnimation(onlyLastFrame)
    end
    CSoundMan.Instance():Play3DAudio(self:GetAudioResPathByType(EnumDef.EntityAudioType.DeadAudio), self:GetPos(), 0)
end

def.method("string", "number", "boolean", "number").PlayClampForeverAnimation = function(self, aniname, fade_time, is_queued, life_time)
    if not self:IsModelLoaded() then return end 
    if self:IsDead() and aniname ~= EnumDef.CLIP.COMMON_DIE then return end
    local model = self:GetCurModel()
    if model ~= nil then
        model:PlayClampForeverAnimation(aniname, fade_time, is_queued, life_time)
    end
end

def.method("number", "boolean", "=>", "number").BluntCurAnimation = function(self, last_time, correct_when_end)
    if not self:IsModelLoaded() or self:IsDead() or last_time == 0 then return 1 end 
    local model = self:GetCurModel()
    if model ~= nil then
        return model:BluntCurAnimation(last_time, correct_when_end)
    else
        return 1
    end
end

def.virtual().UpdateWingAnimation = function (self)
end

def.virtual("string", "number", "boolean", "number", "number", "boolean").PlayWingAnimation = function (self, aniname, fade_time, is_queued, life_time, aniSpeed, is_lock_rotation)
end

def.method("string", "=>", "number").GetAnimationLength = function(self, aniname)
    local model = self:GetCurModel()
    if model ~= nil then
        return model:GetAniLength(aniname)
    end
    return 0
end

def.virtual(CFSMStateBase, "=>", "boolean").ChangeState = function(self, state)
    if not self._IsReady then
        return true
    end

    if self._FSM ~= nil then
        self:SyncPosWhenStateChange(self._FSM:GetCurrentState(), state)
        self._FSM:ChangeState(state)
    end

    return true
end

def.method(CFSMStateBase, CFSMStateBase).SyncPosWhenStateChange = function (self, oldstate, newstate)
    
    --如果结束了一个移动，则判断是否需要同步位置
    if oldstate ~= nil and oldstate._Type == FSM_STATE_TYPE.MOVE and newstate ~= nil and newstate._Type ~= FSM_STATE_TYPE.MOVE then 
        if self._StopMovePos ~= nil then 
            --warn("11111111111111", self._ID, self._StopMovePos.x, self._StopMovePos.z)
            self:SetPos(self._StopMovePos)
        end   
    end
    self._StopMovePos = nil
end

def.method("number", "boolean", "function", "=>", "number").AddTimer = function(self, ttl, once, cb)
    if self._GameObject == nil then
        --warn("Fail to Add Timer, because this object's gameonject is null")
        return 0
    end

    local id = TimerUtil.AddTimer(self._GameObject, ttl, once, cb, _G.GetDebugLineInfo(4))
    return id
end

def.method("number").RemoveTimer = function(self, id)
    if self._GameObject == nil then
        --warn("Fail to Remove Timer, because this object's gameonject is null")
        return
    end

    TimerUtil.RemoveTimer(self._GameObject, id)
end

def.virtual().OnClick = function (self)
    if not self:CanBeSelected() then return end
    
    game:RaiseNotifyClickEvent(self)
    --self:OnTalkPopTopChange(true, "Hello guy Hello guy Hello guy Hello guy Hello guy")
end

def.virtual("=>", "boolean", "table").GetNormalMovingInfo = function(self)

end

def.virtual("number", "table").OnPhysicsTriggerEvent = function (self, attacker_id, hitpos)
end

-- 爆点特效最低级
def.virtual(CEntity, "number", "dynamic", "boolean").OnBeHitted = function (self, attacker, hitActorId, hitPos, playHurt)
    -- 击中光效
    if self:IsPlayerType() and self._InfoData._Prof == EnumDef.Profession.Lancer and self:GetChangePoseState() then
        local _, newActorId =  self:GetChangePoseHurtData()
        hitActorId = newActorId
    end

    for i = #self._HitGfxs, 1, -1 do
        local v = self._HitGfxs[i]
        if v ~= nil and not v:IsPlaying() then
            table.remove(self._HitGfxs, i)
        end
    end

    local actor = CElementSkill.GetActor(hitActorId)
    if actor ~= nil and attacker ~= nil then
        local hitgfx = actor.GfxAssetPath
        local dir = self:GetPos() - attacker:GetPos()
        dir.y = 0
        local angle_y = Vector3.Angle(dir, Vector3.right)
        if dir.z < 0 then angle_y = 360 - angle_y end
        local rot = Quaternion.Euler(actor.GfxRotationX, (270-angle_y + actor.GfxRotationY), actor.GfxRotationZ)
        local hook = self:GetHangPoint("HangPoint_Hurt")
        if actor.FollowWithHook then  
            if hook ~= nil then
                local gfx = CFxMan.Instance():PlayAsChild(hitgfx, hook, Vector3.zero, rot, actor.Lifetime/1000,  actor.NotRotateAroundHook, -1,  EnumDef.CFxPriority.Ignore)
                self._HitGfxs[#self._HitGfxs + 1] = gfx
            end
        elseif not actor.FollowWithHook then
            local attPos = nil
            local GfxPosition_Type =  require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitGfxPosition
            if hitPos == GfxPosition_Type.Foot then
                attPos = self:GetPos()
            elseif hook ~= nil then
                attPos = hook.position
            end
            if attPos ~= nil then
                local gfx = CFxMan.Instance():Play(hitgfx, attPos, rot, actor.Lifetime/1000, -1, EnumDef.CFxPriority.Ignore)
                self._HitGfxs[#self._HitGfxs + 1] = gfx
            end
        end
    end

    -- 受伤动作
    if playHurt then
        self:PlayHurtAnimation()
    end

    -- 闪白
    local CVisualEffectMan = require "Effects.CVisualEffectMan"
    if self:IsHostPlayer() then
        CVisualEffectMan.StartTwinkleWhiteEffect(self)
    else
        if attacker and attacker:IsHostPlayer() then            
            CVisualEffectMan.StartTwinkleWhiteEffect(self)        
        end
    end

    if actor then
        local CSkillActorMan = require "Skill.CSkillActorMan"
        CSkillActorMan.Instance():ExecActorUnits(actor, self)   
    end    
end

-- 得到当前任务的基础移动速度和标准战斗速度
def.virtual("=>","number","number").GetBaseSpeedAndFightSpeed = function(self)   
    return 4,4
end

--计算速率(只用于run和run_battle)
def.method("number","=>","number").GetSpeedRate = function(self,standardSpeed) 
    local nowSpeed = self:GetMoveSpeed()
    local speedInt = math.floor(nowSpeed)
    if nowSpeed - speedInt > 0.5 then 
        nowSpeed = speedInt + 1
    else
        nowSpeed = speedInt
    end
    local rateMove = nowSpeed / standardSpeed
   
    if self._MaxMoveRate == 0 or self._MaxPlayAnimationRate == 0 or self._MinPlayAnimationRate == 0 then 
        self._MaxMoveRate = tonumber(CElementData.GetSpecialIdTemplate(222).Value)
        self._MaxPlayAnimationRate = tonumber(CElementData.GetSpecialIdTemplate(223).Value)
        self._MinPlayAnimationRate = tonumber(CElementData.GetSpecialIdTemplate(224).Value)
    end
    -- warn("rateMove",rateMove)
    return rateMove
end

--计算出当前移动倍率（当前速度与标准速度的比值）和动画播放速率的直线关系(只用于run和run_battle)
def.method("number","=>","number","number").GetMoveRateAndPlayAnimationRateFormula = function(self,rateMove)

    local a,b = 0,0
    if rateMove <= 1 then 
        b = self._MinPlayAnimationRate
        a = 1 - b
    else 
        a = (self._MaxPlayAnimationRate - 1) / (self._MaxMoveRate  - 1)
        b = 1 - a
    end
        
    return a,b
end


-- 检测移动动画是否被替换 如果替换跳过不计算速率
def.method("number","number","=>","string","number").CheckRunAnimation = function (self,standardSpeed,fightSpeed)
    local animation,isReplace = self:GetAnimationName(EnumDef.CLIP.COMMON_RUN)
    if isReplace then 
        return EnumDef.CLIP.COMMON_RUN,1
    end
    local animation,ratePlay = self:GetRunAnimationNameAndRate(standardSpeed,fightSpeed)
    return animation,ratePlay
end

def.method("number","=>","string","number").CheckRunBattleAnimation = function (self,fightSpeed)
    local animation,isReplace = self:GetAnimationName(EnumDef.CLIP.BATTLE_RUN)
    if isReplace then 
        return EnumDef.CLIP.BATTLE_RUN,1
    end
    local animation,ratePlay = self:GetPlayAnimationRateInCombat(fightSpeed)
    return animation,ratePlay
end

-- 根据速度变换动画速率和动画的功能 切换的是Run 和Run_battle 计算的也是针对二者的速率 不可用于其他动画
--非战斗状态下，根据当前角色速度得到当前动画枚举值和播放速率(主角的战斗速度等于基础移动速度)
def.virtual("number","number","=>", "string","number").GetRunAnimationNameAndRate = function(self,standardSpeed,fightSpeed)
    -- 默认播放速率为1
    local ratePlay = 1

    if standardSpeed == 0 or fightSpeed == 0 then 
        return EnumDef.CLIP.COMMON_STAND,ratePlay
    end

    local rateMove = self:GetSpeedRate(standardSpeed)
    if rateMove >= 0 and rateMove <= self._MaxMoveRate then
        local a,b = self:GetMoveRateAndPlayAnimationRateFormula(rateMove) 
        ratePlay = b  + a * rateMove 
        return EnumDef.CLIP.COMMON_RUN,ratePlay
    elseif rateMove > self._MaxMoveRate then 
        local animation = ''
        animation,ratePlay = self:GetPlayAnimationRateInCombat(fightSpeed)
        
        if self:IsHostPlayer() and not self:IsModelChanged() then
            return EnumDef.CLIP.COMMON_RUN,ratePlay
        end
        return animation,ratePlay
    end
end

-- 战斗状态下的动画播放速率
def.method('number',"=>","string","number").GetPlayAnimationRateInCombat = function(self,fightSpeed)
    local ratePlay = 1

    if fightSpeed == 0 then return  EnumDef.CLIP.BATTLE_STAND,ratePlay end

    if not self:HasAnimation(EnumDef.CLIP.BATTLE_RUN) then 
       ratePlay = self._MaxPlayAnimationRate
       return EnumDef.CLIP.COMMON_RUN,ratePlay
    end

    local rateMove = self:GetSpeedRate(fightSpeed)
    if rateMove > 0 and rateMove <= self._MaxMoveRate then
        local a,b = self:GetMoveRateAndPlayAnimationRateFormula(rateMove) 
        ratePlay = b  + a * rateMove 
    elseif rateMove > self._MaxPlayAnimationRate then
        ratePlay = self._MaxPlayAnimationRate
    end

    return EnumDef.CLIP.BATTLE_RUN,ratePlay
end

-- 获取上马时的站立动作
def.virtual("=>", "string").GetRideStandAnimationName = function (self)
    return EnumDef.CLIP.RIDE_STAND
end

-- 获取上马时的跑动动作
def.virtual("=>", "string").GetRideRunAnimationName = function (self)
    return EnumDef.CLIP.RIDE_RUN
end

def.virtual("table", "number", "function", "function").Move = function (self, pos, offset, successcb, failcb)
    if not self:CanMove() then return end
    if self._SkillHdl and self._SkillHdl:IsCastingSkill() then
        self._SkillHdl:DoMove(pos, offset, successcb, failcb)
    else
        self:NormalMove(pos, self:GetMoveSpeed(), offset, successcb, failcb)
    end
end

def.virtual().CreatePate = function (self)
end

def.virtual().OnPateCreate = function (self)
	if self._TopPate == nil then return end
	self._TopPate:MarkAsValid(true)
end

-- 更新头顶字
def.virtual("number").UpdateTopPate = function (self, updateType)
    if self._TopPate == nil then return end

    if updateType == EnumDef.PateChangeType.HP then
        self._TopPate:OnHPChange(self._InfoData._CurrentHp / self._InfoData._MaxHp)
    end
end

--  战斗头部显示部分更改
def.virtual("boolean").OnBattleTopChange= function(self,isShow)
end

--  说话气泡头部显示部分更改
def.virtual("boolean","string","number").OnTalkPopTopChange= function(self,isShow,text,time)
    if self._TopPate == nil then return end
    self._TopPate:TextPop(isShow,text,time)
end

def.method("boolean").InterruptSkill = function(self, change2stand)
    if self._SkillHdl ~= nil and self._SkillHdl:IsCastingSkill() then 
        self._SkillHdl:OnSkillInterruptted(change2stand) 
    end
end

local corpse_stay_duration = 3
def.virtual("number", "number", "number", "boolean").OnDie = function (self, killer_id, element_type, hit_type, play_ani)
    local ObjectDieEvent = require "Events.ObjectDieEvent"
    local event = ObjectDieEvent()
    event._ObjectID = self._ID
    CGame.EventManager:raiseEvent(nil, event)
    
    self:InterruptSkill(false)

    self:DestroyHeadEffectObject()

    self:EnableShadow(false)
    -- 冰冻 恢复可能的ani 禁用
    self:EnableAnimationComponent(true)

    local CVisualEffectMan = require "Effects.CVisualEffectMan"
    if hit_type > 0 then
        local killer = game._CurWorld:FindObject(killer_id)
        if element_type ~= ClinetData.ElementType.Ice and killer ~= nil then
            CVisualEffectMan.DoFlyingDie(self, killer:GetPos(), 100, 1, corpse_stay_duration, function()
            end) 
        end 
    end 

    self:OnHPChange(0, 0)
    if play_ani then
        self:Die(element_type, hit_type, corpse_stay_duration)
    end

    CVisualEffectMan.StopTwinkleWhiteEffect(self)
    --死亡状态设置
    self._DeathState = EDEATH_STATE.DEATH

    if self._HitEffectInfo ~= nil then
        self._HitEffectInfo:Clear()
    end
end

-- 溶解自己
def.virtual("number").DissolveSelf = function(self, duration)
    -- do nothing
end

-- 复活
def.virtual().OnResurrect = function(self)
    error("Entity can not resurrect, wrong entity id:" .. tostring(self._ID))
end


local function SendBuffChangeEvent(self, bIsAdd, buffID)
    local event = BuffChangeEvent()
    event._IsAdd = bIsAdd
    event._EntityID = self._ID
    event._BuffID = buffID
    CGame.EventManager:raiseEvent(nil, event)
end

local FIGHT_STATE_SKILL_CANCELED = 956
def.virtual("boolean", "number", "number", "number", 'table').UpdateState = function(self, add, state_id, duration, originId, info)   
    do  --第一步删除已有同一个的Buff状态，后重新添加
        local indexState = 0
        for i,v in ipairs(self._BuffStates) do
            if v._ID == state_id and v._OriginId == originId then
                indexState = i
                break
            end
        end
        
        if indexState > 0 then
            local buff = self._BuffStates[indexState]  --删除特效
            if buff ~= nil then
                buff:OnEnd()
                buff:Release()
            end
            table.remove(self._BuffStates, indexState)

            if buff:IsIconShown() then
                SendBuffChangeEvent(self, false, buff._ID)
            end
        end
    end

    if add then --增加新的Buff
        local buff = CBuff.new(self, state_id, duration, originId, info)
        table.insert(self._BuffStates, buff)

        --如果需要显示ICON
        if buff:IsIconShown() then
            SendBuffChangeEvent(self, true, buff._ID)
        end

		if state_id == FIGHT_STATE_SKILL_CANCELED then
			if self:IsHostPlayer() or originId == game._HostPlayer._ID then
				self:OnSkillCanceled()
			end
		end
    end
end

def.method("=>", "boolean").HasAnyState = function(self)
    return #self._BuffStates > 0
end

def.method("number", "=>", "boolean").HasState = function(self, stateId)
    for i,v in ipairs(self._BuffStates) do
        if v._ID == stateId then
            return true
        end
    end

    return false
end

-- 是否有状态组中的id
def.method("number", "=>", "boolean").HasStateInGroup = function(self, groupId)
    for i,v in ipairs(self._BuffStates) do
        local buffTemplate = CElementData.GetTemplate("State", v._ID)
        if buffTemplate and buffTemplate.StateGroupId == groupId then
            return true
        end
    end

    return false
end

-- 是否被沉默
def.method("=>", "boolean").HasSilenceState = function(self)
    for i,v in ipairs(self._BuffStates) do
        local buffTemplate = CElementData.GetTemplate("State", v._ID)
        if buffTemplate.SubType == StateSubType.Silence then
            return true
        end
    end
    return false
end

def.virtual("number", "=>", "table").GetTopShowStates = function(self, max)
    local TopShowStates = {}
    if #self._BuffStates > 0 and max > 0 then
        local count = #self._BuffStates
        
        if count > 0 then
            for i=1, count do
                local buff = self._BuffStates[count+1 - i]
                if buff._DisableIcon == false then
                    table.insert(TopShowStates, buff)
                end

                if #TopShowStates == max then
                    break
                end
            end
        end
    end

    return TopShowStates
end

-- 是否被系统控制
def.method("=>", "boolean").HasSystemControl = function(self)
    for i,v in ipairs(self._BuffStates) do
        local buffTemplate = CElementData.GetTemplate("State", v._ID)
        if buffTemplate.SubType == StateSubType.Controlled and buffTemplate.Type == StateType.System then
            return true
        end
    end
    return false
end

def.method("=>", "number").GetCurStateType = function(self)
    if self._FSM == nil or self._FSM._CurState == nil then return FSM_STATE_TYPE.NONE end
    return self._FSM._CurState._Type
end

def.method("=>", "number").GetControlStateType = function(self)
    if self:GetCurStateType() == FSM_STATE_TYPE.BE_CONTROLLED then
        return self._FSM._CurState._ControlType
    else
        return 0
    end
end

--hp如果是正数，则是当前HP
--hp如果是负数，则是差值
def.virtual("number", "number").OnHPChange = function (self, hp, max_hp)
    if self._InfoData ~= nil then
        if max_hp > 0 then 
            self._InfoData._MaxHp = max_hp
        else
            max_hp = self._InfoData._MaxHp
        end

        --TODO：这里有问题，血条显示问题
        if hp > 0 then
            self._InfoData._CurrentHp = hp
            if self._InfoData._CurrentHp > self._InfoData._MaxHp then
                self._InfoData._CurrentHp = self._InfoData._MaxHp            
            end
        else
            self._InfoData._CurrentHp = self._InfoData._CurrentHp + hp
            if self._InfoData._CurrentHp <= 0 then 
                self._InfoData._CurrentHp = 0
            end
            -- self:SendPropChangeEvent("TakeDamage")
        end
        self:UpdateTopPate(EnumDef.PateChangeType.HP)

        local EntityHPUpdateEvent = require "Events.EntityHPUpdateEvent"
        local event = EntityHPUpdateEvent()
        event._EntityId = self._ID
        CGame.EventManager:raiseEvent(nil, event)
    end
end

def.virtual("number", "number").OnHPChange_Simple = function (self, hp, max_hp)
    if self._InfoData ~= nil then
        if max_hp > 0 then 
            self._InfoData._MaxHp = max_hp
        else
            max_hp = self._InfoData._MaxHp
        end

        --TODO：这里有问题，血条显示问题
        if hp > 0 then
            self._InfoData._CurrentHp = hp
            if self._InfoData._CurrentHp > self._InfoData._MaxHp then
                self._InfoData._CurrentHp = self._InfoData._MaxHp            
            end
        else
            self._InfoData._CurrentHp = self._InfoData._CurrentHp + hp
            if self._InfoData._CurrentHp <= 0 then 
                self._InfoData._CurrentHp = 0
            end
        end
    end
end

def.method().SendPropChangeEvent = function(self)
    local NotifyPropEvent = require "Events.NotifyPropEvent"
    local event = NotifyPropEvent()
    event.ObjID = self._ID
    CGame.EventManager:raiseEvent(nil, event)
end

def.method("boolean").SendBaseStateChangeEvent = function(self, isEnter)
    local BaseStateChangeEvent = require "Events.BaseStateChangeEvent"
    local event = BaseStateChangeEvent()
    event.IsEnterState = isEnter
    CGame.EventManager:raiseEvent(nil, event)
end

def.virtual().ListenToQuestChangeEvent = function (self)
    local OnNotifyQuestDataChangeEvent = function(sender, event)        
		self:OnQuestStatusChange() 
    end

    CGame.EventManager:addHandler(NotifyQuestDataChangeEvent, OnNotifyQuestDataChangeEvent)  

    self._OnNotifyQuestDataChangeEvent = OnNotifyQuestDataChangeEvent
end

def.virtual().UnlistenToQuestChangeEvent = function(self)
    if self._OnNotifyQuestDataChangeEvent == nil then return end

    CGame.EventManager:removeHandler(NotifyQuestDataChangeEvent, self._OnNotifyQuestDataChangeEvent)  

    self._OnNotifyQuestDataChangeEvent = nil
end

def.virtual().OnQuestStatusChange = function (self)
end

-- 更新entity状态信息
def.virtual("table").UpdateSealInfo = function (self, data)
    if not self._SealInfo then
        self._SealInfo = CSkillSealInfo.new(self)
    end

    self._SealInfo:UpdateStates(data, self._ID)
    self:RefreshEntityState()
end

-- 维护一个敌对正营列表。
def.virtual("number").AddEnemyCampId = function (self, campId)  --enemy
    self:RemoveEnemyCampId(campId)
    self._EnemyCampTable[#self._EnemyCampTable + 1] = campId
end

def.virtual("number").RemoveEnemyCampId = function (self, campId)
    if #self._EnemyCampTable > 0 then
        for i=#self._EnemyCampTable, 1, -1 do
            if self._EnemyCampTable[i] == campId then
                table.remove(self._EnemyCampTable, i)
            end
        end
    end
end

def.virtual("number").ClearEnemyCampId = function (self, campId)
    self._EnemyCampTable = {}
end


-- 设置entity阵营ID
def.virtual("number").SetCampId = function (self, campId)
    self._CampId = campId
    
    if self._TopPate ~= nil then
        self._TopPate:UpdateName(true)
    end
end

-- 同步状态后 刷新状态
def.virtual().RefreshEntityState = function (self)
    -- 不能移动
    if not self:CanMove() then
        self:StopNaviCal()
    end
    -- ToDo
end

def.virtual("=>", "boolean").CanMove = function (self)
    if self:IsMagicControled() then 
        return false
    end

    if self._SealInfo ~= nil then
        return self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_MOVE)
    end

    return true
end

def.virtual("number", "=>", "boolean").CanCastSkill = function (self, skill_id)
    local skill = self:GetEntitySkill(skill_id)    
    if self._SealInfo ~= nil and skill then    
        -- 常规技能 和 终极技能
        if skill.Category == SkillCategory.Routine or skill.Category == SkillCategory.Ultimate or skill.Category == SkillCategory.SkillCategoryNone then
            if not self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_SKILL) then             
                -- 可以在受控时释放
                if skill.CanCastInControl then
                    -- 沉默状态下, 还是放不出
                    if self:HasSilenceState() or self:HasSystemControl() then
                        return false
                    else
                        return true                                           
                    end
                end
                -- 等待模板
                return false
            end            
        -- 普通攻击 或者 闪身
        elseif skill.Category == SkillCategory.NormalAttack or skill.Category == SkillCategory.Dodge then
            if not self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_NORMAL_SKILL) then
                return false
            end
        end
    end

    return true
end

def.virtual("=>", "table").GetUserSkillMap = function(self)
    return {}
end

-- 可以释放普通技能
def.virtual("=>", "boolean").CanCastNormalSkill = function (self)
    if self._SealInfo ~= nil then
        return self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_NORMAL_SKILL)
    end

    return true
end

def.virtual("=>", "boolean").CanBeSelected = function(self)
    if self._SealInfo ~= nil then
        return self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_BE_SELECTED)
    end
    return true
end

def.virtual("=>", "boolean").CanUseItem = function (self)
    if self._SealInfo ~= nil then
        return self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_USE_ITEM)
    end

    return true
end

def.virtual("=>", "boolean").CanBeAttacked = function(self)
    if self._SealInfo ~= nil then
        return self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_BE_ATTACKED)
    end

    return true
end

def.virtual("=>", "boolean").CanBeInteracted = function(self)
    if self._SealInfo ~= nil then
        return self._SealInfo:IsStateProper(EnumDef.EBASE_STATE.CAN_BE_INTERACTIVE)
    end

    return true
end

--是否是破绽
def.method("=>","boolean").IsFlaw = function(self)
    return self._IsFlaw
end

def.method("=>","boolean").IsAlwaysFlaw = function(self)
    return false
end

def.virtual("=>", "number", "number", "number").GetEnergy = function (self)
    -- warn("Only hostplayer has energy info")
    return -1, 0, 1
end

def.method("boolean").SetFlaw = function(self, isFlaw)
    self._IsFlaw = isFlaw
    if not self:IsAlwaysFlaw() then
        local CVisualEffectMan = require "Effects.CVisualEffectMan"
        CVisualEffectMan.FlashRed(self, isFlaw)
    end
end

def.virtual("boolean", "boolean", "number", "boolean", "boolean").UpdateCombatState = function(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)    
    if not is_client_state then
        self._IsInCombatState = is_in_combat_state
    end
end

def.virtual("=>", "number").GetObjectType = function (self)    
    return OBJ_TYPE.NONE
end

def.virtual("=>", "number").GetFaction = function(self)
    return -1
end

def.virtual("=>", "number").GetReputation = function(self)
    return -1
end

def.method("=>", "number").GetMoveSpeed = function(self)
    if self._InfoData ~= nil then
        return self._InfoData._MoveSpeed
    end
    warn("speed is not init")
    return 2
end

def.virtual("number").SetMoveSpeed = function(self, speed)
    if self._InfoData ~= nil then
        local curSpeed = self._InfoData._MoveSpeed
        if curSpeed ~= speed then
            self._InfoData._MoveSpeed = speed

            local cur_fsm_state = self:GetCurStateType()
            if cur_fsm_state == FSM_STATE_TYPE.MOVE then
                self._FSM:UpdateMoveStateAnimation()
            end
        end
    end
end

-- 获取特效的优先级
-- Always             = -1, 
-- Prior              =  0,
-- High               = 10,
-- Middle             = 20,
-- Common             = 30,
-- Low                = 40,
-- Last               = 50
-- Ignore             = 60,
-- fxtype  0 子物体 1 特效 2 爆点
def.method("number", "=>", "number").GetCfxPriority = function(self, fxtype)
    -- 是主角 优先级最大
    if self:IsHostPlayer() then
        return EnumDef.CFxPriority.Always
    end    

    local hate = game._HostPlayer:IsEntityHate(self._ID)
    local isPlayer  = self:IsPlayerType()
    local teamMan = require "Team.CTeamMan".Instance()  
    -- 子物体
    if fxtype == 0 then
        -- 与自身有仇恨的非玩家
        if hate and not isPlayer then
             return EnumDef.CFxPriority.Prior
        -- 与自身有仇恨的玩家的子物体   
        elseif hate and isPlayer then
            return EnumDef.CFxPriority.High
        -- 队友的子物体
        elseif teamMan and teamMan:IsTeamMember(self._ID) then
            return EnumDef.CFxPriority.Middle        
        end
    -- 特效
    elseif fxtype == 1 then
        -- 仇恨单位的非子物体特效
        if hate then
            return EnumDef.CFxPriority.Common    
        -- 队友的非子物体特效
        elseif teamMan and teamMan:IsTeamMember(self._ID) then
            return EnumDef.CFxPriority.Low
        -- 其他单位的所有 
        else
            return EnumDef.CFxPriority.Last
        end
    -- 爆点
    else
        return EnumDef.CFxPriority.Ignore        
    end

    return EnumDef.CFxPriority.Last
end

def.method("=>", "number").GetModelCfxPriority = function (self)
    if self:IsHostPlayer() then
        return EnumDef.CFxPriority.Always
    end  

    return EnumDef.CFxPriority.Common 
end

def.virtual("=>", "boolean").CanHostNaviTo = function(self)
    if self:IsHostPlayer() then
        return true
    end

    local host = game._HostPlayer
    local hostPosX, hostPosY, hostPosZ = host:GetPosXYZ()
    local posX, posY, posZ = self:GetPosXYZ()

    if not GameUtil.PathFindingCanNavigateToXYZ(hostPosX, hostPosY, hostPosZ, posX, posY, posZ, _G.NAV_STEP) then
        return false
    end
    return true
end

def.virtual("number", "number", "number", "number").StartCooldown = function(self, cd_id, accumulate_count, elapsed_time, max_time)
    if self._CDHdl == nil then warn("this object has no cooldown handler") end
    self._CDHdl:UpdateData(cd_id, accumulate_count, elapsed_time, max_time)
end

def.virtual("boolean").EnableShadow = function(self, on)
    if not self._IsReady then return end
    self._IsEnableShadow = on

    self:DoEnableShadow(on)    
end

def.method("boolean").DoEnableShadow = function (self, on)
    if not self._IsReady or (not self:IsVisible() and on) then return end
  
    if on then
        if IsNil(self._Shadow) then
            self._Shadow = self._GameObject:FindChild("Shadow")
        end
        if IsNil(self._Shadow) then
            local shadow = Object.Instantiate(_G.ShadowTemplate)
            GameUtil.SetLayerRecursively(shadow, EnumDef.RenderLayer.EntityAttached)
            shadow.parent = self._GameObject
            shadow.name = "Shadow"
            shadow.localPosition = Vector3.New(0, 0.09, 0)
            self._Shadow = shadow
        end 
        self._Shadow:SetActive(true)
    else
        if not IsNil(self._Shadow) then
            self._Shadow:SetActive(false)
        end
    end
end

def.method("boolean").EnableCastShadows = function (self, on)
    if self._Model ~= nil then
        local go = self._Model:GetGameObject()
        if go ~= nil and GameUtil.EnableCastShadows then
            GameUtil.EnableCastShadows(go, on)
        end
    end

    if self._TransformerModel ~= nil then
        local go = self._TransformerModel:GetGameObject()
        if go ~= nil and GameUtil.EnableCastShadows then
            GameUtil.EnableCastShadows(go, on)
        end
    end
end

def.virtual("number", "number", "=>", "boolean").OnCollideWithOther = function(self, colliderId, collideEntityType)
    return true
end


-- 与 大型怪碰撞
def.virtual("number", "=>", "boolean").OnCollidingHuge = function(self, collider_id)
    return false
end

def.virtual("boolean").Stealth = function(self, on)
    if self._TopPate then
        self._TopPate:SetVisible(not on)
    end

    local CVisualEffectMan = require "Effects.CVisualEffectMan"
    CVisualEffectMan.DoStealth(self, on)
    self._IsStealth = on

    self:EnableShadow(self._IsEnableShadow)     --刷新

    local layer = on and EnumDef.RenderLayer.Invisible or EnumDef.RenderLayer.Fx
    -- 技能特效
    if self._SkillHdl ~= nil then
        for k,v in pairs(self._SkillHdl._GfxList) do
            if v.Gfx and v.FollowWithHook and v.Gfx:GetGameObject() then
                GameUtil.SetLayerRecursively(v.Gfx:GetGameObject(), layer)
            end
        end
    end

    -- 状态特效
    for i,v in ipairs(self._BuffStates) do
        if v._GfxObject and v._GfxObject:GetGameObject() then
            GameUtil.SetLayerRecursively(v._GfxObject:GetGameObject(), layer)        
        end
        if v._GfxObject2 and v._GfxObject2:GetGameObject() then
            GameUtil.SetLayerRecursively(v._GfxObject2:GetGameObject(), layer)        
        end
    end
end

def.virtual("=>", "boolean").IsNeedHideHpBarAndName = function(self)
    return false
end

local factionRelationShipUnique = nil
local function GetFactionRelationship(a, b)
    if factionRelationShipUnique == nil then
        factionRelationShipUnique = CElementData.GetTemplate("FactionRelationship", 1)
    end

    local type = Template.FactionRelationship.FactionRelationType.Friendly
    if factionRelationShipUnique == nil then
        return type
    end

    if a > #factionRelationShipUnique.RelationshipLists or a <= 0 then
        return type
    end    

    local relationshipList = factionRelationShipUnique.RelationshipLists[a - 1 + 1]
    if b > #relationshipList.Relationships or b <= 0 then
        return type
    end

    local relationship = relationshipList.Relationships[b - 1 + 1]
    --warn("relationship: ", relationship.RelationType)
    return relationship.RelationType
end

local function GetShiLiRelation(a, b)
    local re = GetFactionRelationship(a, b) 
    local relation_desc_map = RelationDesc

    local relation = relation_desc_map[re]
    if relation ~= nil then
        return relation
    else
        return "Undefined"
    end
end

local function GetZhenYingRelation(a, b)
    if a == nil or b == nil then return "Undefined" end
    if a._InfoData == nil or b._InfoData == nil then return "Undefined" end 
    if a._CampId == 0 or b._CampId == 0 then return "Undefined" end 
    if a._CampId == b._CampId then  -- _CampId 相同友好，不同敌对。
        return RelationDesc[1]
    elseif a._CampId ~= b._CampId then
        return RelationDesc[2]
    else
        if #a._EnemyCampTable > 0 then
            for i,v in ipairs(a._EnemyCampTable) do
                if v == b._CampId then
                    return RelationDesc[2]
                end
            end
        end
        return "Undefined"
    end
end

def.method("table").PerformInitedSkill = function (self, SkillInfo)
    if self._SkillHdl == nil then return end
    self._SkillHdl:PerformInitedSkill(SkillInfo)
end

def.method("=>", "boolean").IsSkillMoving = function (self)
    if self._SkillHdl == nil then
        return false 
    else
        return self._SkillHdl._IsSkillMoving
    end

end

-- 仅做阵营和势力两种关系的判断
def.virtual(CEntity , "=>" , "string", "boolean").GetRelationWith = function(self, someone)
    local relation = GetZhenYingRelation(self, someone)
    local isZYFriend
    if relation == "Undefined" then
        local host_faction = someone:GetFaction()
        local self_faction = self:GetFaction()
        relation = GetShiLiRelation(host_faction, self_faction)
        isZYFriend = false
    else
        isZYFriend = true
    end
    return relation, isZYFriend
end

def.virtual("=>" , "string").GetRelationWithHost = function(self)
    local hp = game._HostPlayer
    local relation, _ = self:GetRelationWith(hp)
    return relation
end

--在 cur_state 的状态下，是否允许进入 hit_type 的状态
local constrains = nil
def.static("number", "number" ,"=>", "boolean").CanChangeControlState = function (hit_type, cur_state )
    if constrains == nil then
        constrains = {}
        for k,v in pairs(JudgementHitType) do
            constrains[v] = {}
        end

        --处于击退状态时
        constrains[JudgementHitType.Knockback][JudgementHitType.Knockdown] = true
        constrains[JudgementHitType.Knockback][JudgementHitType.KnockIntoTheAir] = true

        --处于硬直状态时
        constrains[JudgementHitType.Stiffness][JudgementHitType.Knockback] = true
        constrains[JudgementHitType.Stiffness][JudgementHitType.Knockdown] = true
        constrains[JudgementHitType.Stiffness][JudgementHitType.KnockIntoTheAir] = true

        --处于普攻状态时候
        for k,v in pairs(JudgementHitType) do
            constrains[JudgementHitType.Normal][v] = true
        end

        --初始化状态与普通攻击同样处理
        constrains[0] = constrains[JudgementHitType.Normal]
    end
    
    return (constrains[cur_state][hit_type] ~= nil)
end

-- @param radius:单位原始碰撞体半径（没有缩放）
def.virtual("number").SetRadius = function(self, radius)
    self._CollisionRadius = radius
end

def.virtual("=>", "number").GetRadius = function(self)
    return self._CollisionRadius
end

def.virtual("table", "table", "number", "table", "number", "boolean", "table").OnMove = function (self, curStepPos, facedir, movetype, movedir, speed, useDest, finalDstPos)
    self._StopMovePos = nil

    if not self._IsReady then
        self._InitPos = curStepPos
        self._InitDir = facedir  
        return
    end

    if self:IsDead() then return end
    if not self:CanMove() then return end  -- 状态不能移动

    self:SetMoveSpeed(speed)
    self._MoveType = movetype
    
    local ENTITY_MOVE_TYPE = require "PB.net".ENTITY_MOVE_TYPE
    if movetype == ENTITY_MOVE_TYPE.ForceSync then
        self:SetPos(curStepPos)
        self:SetDir(facedir)
    elseif movetype == ENTITY_MOVE_TYPE.Walking or movetype == ENTITY_MOVE_TYPE.Running then
        if speed < 0.01 then warn("Entity's move speed is near zero: ", speed, self._ID) end
        self:Move(finalDstPos, 0, nil, nil)
    elseif movetype == ENTITY_MOVE_TYPE.SkillMove then
        if speed < 0.01 then warn("Entity's skill move speed is near zero ", speed, self._ID) end
        local internal = Vector3.DistanceH(self:GetPos(), curStepPos)/speed
        GameUtil.AddDashBehavior(self:GetGameObject(), curStepPos, internal, true, false)
    elseif movetype == ENTITY_MOVE_TYPE.TeamFollowing then
        self:NormalMove(curStepPos, speed, 0, nil, nil)
    else
        -- warn("Object:OnMove, do nothing, movetype =", movetype)
    end
end 

def.virtual("table", "table", "number", "table", "number", "boolean", "table").OnMove_Simple = function (self, curStepPos, facedir, movetype, movedir, speed, useDest, finalDstPos)
    self._StopMovePos = nil

    if not self._IsReady then
        self._InitPos = curStepPos
        return
    end

    if self:IsDead() then return end
    if not self:CanMove() then return end  -- 状态不能移动

    self:SetMoveSpeed(speed)
    self._MoveType = movetype
    
    local ENTITY_MOVE_TYPE = require "PB.net".ENTITY_MOVE_TYPE
    if movetype == ENTITY_MOVE_TYPE.ForceSync then
        self:SetPos(curStepPos)
        self:SetDir(facedir)
    elseif movetype == ENTITY_MOVE_TYPE.Walking or movetype == ENTITY_MOVE_TYPE.Running then
        self:SetPos(finalDstPos)
    elseif movetype == ENTITY_MOVE_TYPE.SkillMove then
        self:SetPos(curStepPos)
    elseif movetype == ENTITY_MOVE_TYPE.TeamFollowing then
        self:SetPos(curStepPos)
    else
    end
end 

def.virtual("table", "number").OnSkillMoveJump = function (self, dest_pos, speed)
    if not self._IsReady then
        self._InitPos = dest_pos
        return
    end

    if not self:CanMove() then
        return 
    end

    if self:IsDead() then return end
    --warn("===================>>>> skill move ", Vector3.DistanceH(self:GetPos(), dest_pos))
    local internal = Vector3.DistanceH(self:GetPos(), dest_pos)/speed
    GameUtil.AddDashBehavior(self:GetGameObject(), dest_pos, internal, true, false)
end

def.virtual("table", "table", "number").OnStopMove = function (self, cur_pos, facedir, movetype)
    if not self._IsReady then
        self._InitPos = cur_pos
        self._InitDir = facedir
        return
    end
    if self:IsDead() then return end

    self._StopMovePos = nil

    local ENTITY_MOVE_TYPE = require "PB.net".ENTITY_MOVE_TYPE
    self._MoveType = movetype
    if movetype == ENTITY_MOVE_TYPE.Walking or movetype == ENTITY_MOVE_TYPE.Running then
        local function cb()
            self:StopNaviCal()
        end
        self:Move(cur_pos, 0, cb, cb)

        if not self:IsHostPlayer() then
            self._StopMovePos = Vector3.New(cur_pos.x, cur_pos.y, cur_pos.z)
        end
    elseif movetype == ENTITY_MOVE_TYPE.TeamFollowing then
        local function cb()
            self:StopNaviCal()
        end
        -- 如果跟随对象在是野外，MoveSpeed可能是0，会出现原地滑步的情况 added by lijian
        if self:GetMoveSpeed() <= 0 then self:SetMoveSpeed(4) end
        self:Move(cur_pos, 0, cb, cb)
    elseif movetype == ENTITY_MOVE_TYPE.SkillMove then
        if self._SkillHdl ~= nil then
            self._SkillHdl:ClearDashBehavior()
        end
        -- 冲锋过程中，本地先模拟，收到服务器消息后，强行同步
        self:SetPos(cur_pos)
    elseif movetype == ENTITY_MOVE_TYPE.ForceSync then
        self:SetPos(cur_pos)
        self:SetDir(facedir)
        self:StopMovementLogic()
        self:StopNaviCal()
    elseif movetype == ENTITY_MOVE_TYPE.MapTrans then--传送类型的停止
        self:StopNaviCal()
        self:SetPos(cur_pos)
        self:SetDir(facedir)
    end
end

--获取当前Entiy技能
def.virtual("number", "=>", "table").GetEntitySkill = function(self, skill_id)
    return CElementSkill.Get(skill_id)
end

def.virtual("string", "=>", "userdata").GetHangPoint = function(self, hang_point_name)
    if self._HangPointCache == nil then return nil end
    
    if self._HangPointCache[hang_point_name] ~= nil then
        return self._HangPointCache[hang_point_name]
    end

    if IsNil(self._GameObject) then return nil end

    local model = self:GetCurModel()
    if string.find(model._GameObject.name, "Empty") ~= nil then return nil end

    local result = nil
    local hang_point_id = EnumDef.HangPoint[hang_point_name]
    if hang_point_id ~= nil then
        result = GameUtil.GetHangPoint(model._GameObject, hang_point_id)
        if result == nil then 
            result = GameUtil.FindChild(model._GameObject, hang_point_name)
        end
    else
        result = GameUtil.FindChild(model._GameObject, hang_point_name)
    end

    if IsNil(result) then
        result = self._GameObject
        print("can not find HangPoint ", hang_point_name, model._GameObject.name)
    end
    
    if not self:IsModelChanged() then
        self._HangPointCache[hang_point_name] = result
    end

    return result
end

def.virtual("=>","string").GetEntityColorName = function(self)
    local name = self._InfoData._Name
    return name
end 

def.virtual("=>", "boolean").IsHostPlayer = function(self)
    return false
end

def.virtual("=>", "boolean").IsRole = function (self)
    return false
end

def.virtual("=>", "boolean").IsMonster = function(self)
    return false
end

def.virtual("=>", "boolean").IsMineral = function (self)
    return false 
end

-- 获取初始模型
def.virtual("=>", CModel).GetOriModel = function(self)
    return self._Model
end

-- 获取当前模型
def.virtual("=>", CModel).GetCurModel = function(self)
    -- 变身了
    if self:IsModelChanged() then
        return self._TransformerModel
    else
        return self._Model
    end
end

-- 是否变身状态
def.virtual("=>", "boolean").IsModelChanged = function(self)
    return (self._TransformID ~= 0 and (not self._IsModelChanging))
end

def.virtual("table").SkillMove = function (self, pos)
    self._StopMovePos = nil
end

def.virtual("number").SetCurrentTargetId = function(self, targetId)
    self._CurrentTargetId = targetId
end

def.virtual("=>", "number").GetCurrentTargetId = function(self)
    return self._CurrentTargetId
end

def.virtual("number").DoDisappearEffect = function (self, leaveType)
end

def.virtual("=>", "userdata").RequireStandBehaviourComp = function (self)
    return nil
end

def.virtual("=>", "userdata").GetStandBehaviourComp = function (self)
    return nil
end

def.virtual("=>", "userdata").RequireHorseStandBehaviourComp = function (self)
    return nil
end

def.virtual("=>", "userdata").GetHorseStandBehaviourComp = function (self)
    return nil
end

-- 摧毁头顶上的特效
def.method().DestroyHeadEffectObject = function(self)
    if not IsNil(self._HeadEffectObject) then 
        CFxMan.Instance():Stop(self._HeadEffectObject)
        self._HeadEffectObject = nil 
    end 
end 

-- 存储entiy头顶播放特效的指令数据（策划需求副本和大世界中都会用到）
def.method("table").SaveEntityHeadInstructionData = function(self,data)
    self._HeadInstructionTable = {}
    self._HeadInstructionTable.HeadInstructionOffSet = data.HeadInstructionOffSet
    self._HeadInstructionTable.IsHeadInstructionShow = data.IsHeadInstructionShow
    self._HeadInstructionTable.Scale = data.Scale
    if self._HeadEffectObject ~= nil then 
        self:DestroyHeadEffectObject()
    end
    if not self._HeadInstructionTable.IsHeadInstructionShow then 
        self:DestroyHeadEffectObject()
    else
        self:PlayEntityHeadEffect()
    end
end

--加载模型后回调 播放头顶特效（对于没有模型的目标 策划会配空模型）
def.method().PlayEntityHeadEffect = function (self)
    if self._HeadInstructionTable == nil then return end
    if not self._HeadInstructionTable.IsHeadInstructionShow then return end
    local effectPath = CElementData.GetSpecialIdTemplate(425).Value
    local yOffset = 0
    if self._HeadInstructionTable.HeadInstructionOffSet ~= 0 then 
        yOffset = self._HeadInstructionTable.HeadInstructionOffSet
    else
        yOffset = GameUtil.GetModelHeight(self._Model._GameObject)
    end
    local curPos = Vector3.New(0,yOffset,0)
    if effectPath == "" then warn(" Head Effecr Path Is nil") return end
    if self._HeadInstructionTable.Scale == nil then
        self._HeadInstructionTable.Scale = -1
    end
    self._HeadEffectObject = CFxMan.Instance():PlayAsChild(effectPath,self._GameObject,curPos,Quaternion.identity,-1,false, tonumber(self._HeadInstructionTable.Scale), EnumDef.CFxPriority.Always)
end

def.virtual().ReleaseBuffStates = function(self)
    for i, v in ipairs(self._BuffStates) do
        --v:OnEnd()
        v:Release()
        if self:IsHostPlayer() then
            local SkillTriggerEvent = require "Events.SkillTriggerEvent"
            local event = SkillTriggerEvent()
            event._StateId = v._ID
            event._SkillId = 0
            event._IsBegin = false
            CGame.EventManager:raiseEvent(nil, event)
        end
    end
    
    self._BuffStates = {}
end

def.virtual().Release = function (self)
    self:UnlistenToQuestChangeEvent()

    --self:ClearEntityEffect()  -- GameObject进入回收池时会做所有效果的处理，包含RimColor效果
    self._InfoData = nil
    self._InitPos = nil
    self._InitDir = nil
    self._SkillDestDir = nil
    self._InitRotation = nil

    self._HeightOffsetY = 0

    if self._FSM ~= nil then
        self._FSM:Release()
        self._FSM = nil
    end

    if self._HitEffectInfo ~= nil then
        self._HitEffectInfo:Release()
        self._HitEffectInfo = nil
    end

    if self._SealInfo then
        self._SealInfo:Release()
        self._SealInfo = nil
    end

    if self._TopPate ~= nil then 
        self._TopPate:Release() 
        self._TopPate = nil
    end

    if self._CDHdl then
        self._CDHdl:Release()
        self._CDHdl = nil
    end

    if self._SkillHdl then
        self._SkillHdl:Release()
        self._SkillHdl = nil
    end

    if self._MagicControlinfo then
        self._MagicControlinfo:Release()
        self._MagicControlinfo = nil
    end

    self:ReleaseBuffStates()

    for i,v in ipairs(self._HitGfxs) do
        v:Stop()
    end
    self._HitGfxs = {}

    self:EnableShadow(false)
    self._Shadow = nil

    self._HangPointCache = nil

    if self._HUDText ~= nil then
        self._HUDText:Release()
        self._HUDText = nil
    end

    if self._IsStealth then
        self:Stealth(false)
    end

    self._CurWeaponInfo = nil
    self._UserSkillMap = nil
    self._OnNotifyQuestDataChangeEvent = nil

    local ecm = self._Model
    if ecm ~= nil then        
        ecm:Destroy()
    end
    self._Model = nil
    self._OnLoadedCallbacks = nil

    if self._TransformerModel ~= nil then
        self._TransformerModel:Destroy()
        self._TransformerModel = nil
    end
    self._OnTransformerLoadedCallbacks = nil

    if not IsNil(self._GameObject) then
        GameUtil.RecycleEntityBaseRes(self._GameObject)
    end
    self._GameObject = nil

    self._IsReady = false
    self._IsReleased = true
    
    self._AnimationReplaceTable = nil
    self:DestroyHeadEffectObject()
    self._HeadInstructionTable = nil 
end

CEntity.Commit()
return CEntity