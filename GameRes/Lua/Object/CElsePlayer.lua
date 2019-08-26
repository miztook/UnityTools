local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CPlayer = require "Object.CPlayer"
local CStateMachine = require "FSM.CStateMachine"
local CModel = require "Object.CModel"
local CFSMStateBase = require "FSM.CFSMStateBase"
local CGame = Lplus.ForwardDeclare("CGame")
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local ObjectInfoList = require "Object.ObjectInfoList"
local CElementData = require "Data.CElementData"
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local PBHelper = require "Network.PBHelper"
local CGuild = require "Guild.CGuild"
local EPkMode = require "PB.data".EPkMode
local ECustomSet = require "PB.data".ECustomSet
local CTeamMan = require "Team.CTeamMan"
local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE

local CElsePlayer = Lplus.Extend(CPlayer, "CElsePlayer")
local def = CElsePlayer.define

def.field("boolean")._IsForbidRescue = false	--所在场景是否禁止救援复活
def.field("boolean")._IsUsingEmptyModelFirst = true   -- 开始时是否使用空模型

def.static("=>", CElsePlayer).new = function ()
	local obj = CElsePlayer()
	obj._FSM = CStateMachine.new()
	obj._SkillHdl = CObjectSkillHdl.new(obj)
	obj._HitEffectInfo = CHitEffectInfo.new(obj)
	obj._Guild = CGuild.new()
	obj._FadeOutWhenLeave = true
	obj._IsRedName = false
	obj._CurWeaponInfo = {}
	obj._UserSkillMap = {}
	return obj
end

def.override("table").Init = function (self, info)
	self:SetRoleInfoData(info)
    
	local player_man = game._CurWorld._PlayerMan
    if player_man:IsInCaredPlayerList(self._ID) then
        self._IsCullingVisible = true
        self._IsUsingEmptyModelFirst = false
	    self:Load()
    else
    	self._IsCullingVisible = false
        self._IsUsingEmptyModelFirst = true
        self:CreateEmptyBodyWithTopPate()
    end
end

def.method("table").SetRoleInfoData = function(self, info)
    self._ID = info.CreatureInfo.MovableInfo.EntityInfo.EntityId
	self._ProfessionTemplate = CElementData.GetProfessionTemplate(info.Profession)
	
	self._TeamId = info.TeamId
	self:SetPetId(info.PetId)

	CPlayer.Init(self,info)
	local creature_info = info.CreatureInfo
	self._InitPos = creature_info.MovableInfo.EntityInfo.Position
	self._InitDir = creature_info.MovableInfo.EntityInfo.Orientation

	self._InfoData = ObjectInfoList.CPlayerInfo()
    self._InfoData._MoveSpeed = creature_info.MovableInfo.MoveSpeed
	self._InfoData._Prof = info.Profession
	self._InfoData._Gender = Profession2Gender[info.Profession]

	self._InfoData._Name = creature_info.Name
	self._InfoData._Level = creature_info.Level
	self._CampId = creature_info.CampId
	self._InfoData._FactionId = creature_info.FactionId
	self._InfoData._MaxHp = creature_info.MaxHp
    self._InfoData._MaxStamina = creature_info.MaxStamina
	self._InfoData._CurrentHp = creature_info.CurrentHp
	self:SetCurrentTargetId(creature_info.CurrentTargetId)
	self._IsRedName = info.IsRedName
	self._InfoData._CurShield = creature_info.ShieldValue
	self._InfoData._PkMode = info.PkMode
    self._InfoData._EvilNum = info.Exterior.EvilNum
	self._IsForbidRescue = info.ForbidRescue == true
	self._InfoData._CustomImgSet = info.Exterior.CustomImgSet
	self._InfoData._DesignationId = info.DesignationId
	-- 隐藏获取自定义头像
	-- self:SetCustomImg(self._InfoData._CustomImgSet)

	self._EnemyCampTable = creature_info.EnemyCampList
	self._InfoData._TitleName = game._DesignationMan:GetColorDesignationNameByTID(info.DesignationId)
	self._InfoData._GuildConvoyFlag = info.GuildConvoyFlag
	
	if info.GuildName ~= nil and info.GuildID then
		self._Guild._GuildName = info.GuildName
		self._Guild._GuildID = info.GuildID
		if info.GuildIcon ~= nil then
			self._Guild._GuildIconInfo._BaseColorID = info.GuildIcon.BaseColorID
			self._Guild._GuildIconInfo._FrameID = info.GuildIcon.FrameID
			self._Guild._GuildIconInfo._ImageID = info.GuildIcon.ImageID
		end
		self:UpdateTopPate(EnumDef.PateChangeType.GuildName)
	end

	local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
	--	warn("creature_info.MaxMana = ", creature_info.MaxMana , "creature_info.CurrentMana = ", creature_info.CurrentMana)
	self._InfoData._FightProperty[ENUM.CURRENTMANA] = {creature_info.CurrentMana, 0}
	self._InfoData._FightProperty[ENUM.MAXMANA] = {creature_info.MaxMana, 0}
	self._InfoData._FightProperty[ENUM.FIGHTSCORE] = {creature_info.FightScore, 0}

	if info.Horse ~= nil then
		self._InfoData._HorseId = info.Horse.HorseID
		self._IsMountingHorse = info.Horse.IsOn
	end

	self._DeathState = creature_info.DeathState
	self._IsInCombatState = creature_info.CombatState
	self._IgnoreClientStateChange = (self._IsInCombatState == true)
	self:InitMagicControls(info.CreatureInfo.MagicControlStates)	

	if info.CreatureInfo and info.CreatureInfo.SkillInfo then
		self:PerformInitedSkill(info.CreatureInfo.SkillInfo)
	end

	-- 设置影响外观的模型参数，在加载模型前
	self:SetOutwardDatas(info.Exterior)
	self:InitStates(creature_info.BuffStates)
	self:UpdateSealInfo(info.CreatureInfo.BaseStates)
    self:OnHPChange(self._InfoData._CurrentHp, self._InfoData._MaxHp)
end

--def.method("userdata").AddEmptyGameObjectBoxCollider = function(self, go)
--    if self._InfoData._Prof == EnumDef.Profession.Warrior then
--        GameUtil.ResizeCollider(go, 0.8, 5, 0.8)
--    elseif self._InfoData._Prof == EnumDef.Profession.Aileen then
--        GameUtil.ResizeCollider(go, 0.8, 4, 0.8)
--    elseif self._InfoData._Prof == EnumDef.Profession.Assassin then
--        GameUtil.ResizeCollider(go, 0.8, 5, 0.8)
--    elseif self._InfoData._Prof == EnumDef.Profession.Archer then
--        GameUtil.ResizeCollider(go, 0.8, 5, 0.8)
--    elseif self._InfoData._Prof == EnumDef.Profession.Lancer then
--        GameUtil.ResizeCollider(go, 0.8, 4, 0.8)
--    else
--        GameUtil.ResizeCollider(go, 0.8, 4, 0.8)
--    end
--end

def.method().CreateEmptyBodyWithTopPate = function(self)
    local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()
    m._GameObject = GameObject.New("EmptyModel")
    m._Status = ModelStatus.NORMAL
    GameUtil.ResizeCollider(m._GameObject, 0.8, 4, 0.8)
	self._Model = m

    self:AddObjectComponent(false, 0.5)
	GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.Player)
    self:EnableShadow(false)

    self._IsCullingVisible = false
    self._IsReady = false
    self._IsModelLoaded = false

    if self._OnLoadedCallbacks then
        for i,v in ipairs(self._OnLoadedCallbacks) do
            v(self)
        end
        self._OnLoadedCallbacks = nil
    end

    --默认隐藏头部信息
    if not self:IsNeedHideHpBarAndName() then
        if self._TopPate ~= nil then 
            self._TopPate:Pool() 
            self._TopPate = nil
        end
        self:SetPateOffsetH(0--[[self:GetEmptyGameObjectTopPateOffset()]])

	    local CPlayerTopPate = require "GUI.CPate".CPlayerTopPate
	    local pate = CPlayerTopPate.new()
	    self._TopPate = pate
        self._TopPate:SetOffsetH(self._PateOffsetH)
	    pate:Init(self, nil, true)
        self._TopPate:SetMini(true)
	    self:OnPateCreate()
    end
end

def.override().CreatePate = function (self)
	local CPlayerTopPate = require "GUI.CPate".CPlayerTopPate
	local pate = CPlayerTopPate.new()
	self._TopPate = pate
    self._TopPate:SetOffsetH(self._PateOffsetH)
	pate:Init(self, nil, true)
    self._TopPate:SetMini(game._IsInWorldBoss)
	self:OnPateCreate()
end

def.method().Load = function (self)
	if self:IsModelLoaded() then return end
	
	self._IsReady = false
    self._IsModelLoaded = false

    if self._IsUsingEmptyModelFirst then
    	if self._Model ~= nil then
			local m = self._Model
	    	if m._GameObject ~= nil then
	       		GameObject.Destroy(m._GameObject)
	       		m._GameObject = nil
	       	end
	       self._Model:Destroy()
	       self._Model = nil
	    end

	    if self._TopPate ~= nil then 
	        self._TopPate:Pool() 
	        self._TopPate = nil
	    end
    end

    local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()

	self._Model = m
	self._OutwardParams = self:GetModelParams()
	self._IsReady = false
	m:LoadWithModelParams(self._OutwardParams, function()
		self:OnLoad()
	end)
end

def.method().OnLoad = function (self)
	local function _onload(self)
		if self._Model == nil then return end
		self._Model._GameObject.name = "Model"
		if self._IsUsingEmptyModelFirst then
			self:UpdateObjectComponent(false, 0)
		else
        	self:AddObjectComponent(false, 0.5)
        end

		GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.Player)

		GameUtil.AddFootStepTouch(self._Model._GameObject)

		self:SetCurWeaponInfo()
		self:SetCurWingModel()
		
		self._IsReady = true
		self:OnModelLoaded()		

		--坐骑状态
		self._IsMountEnterSight = self:IsServerMounting()
		self:MountOn(self:IsServerMounting())

		local go = self._Model._GameObject
		self._CombatStateChangeComp = go:GetComponent(ClassType.CombatStateChangeBehaviour)
		if self._CombatStateChangeComp == nil then
			self._CombatStateChangeComp = go:AddComponent(ClassType.CombatStateChangeBehaviour)
		end
		self._CombatStateChangeComp:ChangeState(true, self:IsInServerCombatState(), 0, 0)

		if self._FSM ~= nil and not self._FSM:UpdateCurStateWhenBecomeVisible() then
        	if self:IsDead() then
        		self:Dead()
        	else
        		self:Stand()
        	end
        end

        if not self:IsCullingVisible() then
			self:EnableCullingVisible(false)
		end
	end
	
	if self._IsReleased then
        if self._Model ~= nil then
		    self._Model:Destroy()
        end
	else
		_onload(self)
	end
end

def.method("boolean", "number").UpdateObjectComponent = function (self, is_host, radius)
    local root = self._GameObject

    if root == nil then 
    	warn("can not call UpdateObjectComponent when self._GameObject is nil")
    	return
    end

    local mainModelGo = self._Model._GameObject
    if mainModelGo ~= nil then
        mainModelGo.parent = root
        mainModelGo.localPosition = Vector3.zero
        mainModelGo.localRotation = Vector3.zero
    end

    --self._GameObject = root

    self._IsModelLoaded = true
    GameUtil.AddObjectComponent(self, root, self._ID, self:GetObjectType(), radius)
end

def.method("boolean", "dynamic").OnEnterOrLeaveHostCarePlayerList = function(self, isEnter, roleInfo)
    -- 如果是新进入careList的玩家需要更新下RoleInfo信息
    if roleInfo ~= nil then
        self:SetRoleInfoData(roleInfo)
    end

    if isEnter then
    	if not self._IsCullingVisible then
	        if not self._IsModelLoaded then  -- 模型尚未加载
	            if self._Model ~= nil and not self._Model:IsInLoading() then 
	            --if self._Model ~= nil and self._Model._Status ~= ModelStatus.LOADING then
	            	self._IsCullingVisible = true
	            	self:Load()
	            end
	        else
	            self:EnableCullingVisible(true)
	        end
	    end
    else
    	if not self._IsModelLoaded then
    		return
    	end

        if self._IsCullingVisible then
            self:EnableCullingVisible(false)
        end
    end
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.ELSEPLAYER
end

def.override(CFSMStateBase, "=>", "boolean").ChangeState = function(self, state)
    -- 这里不需要判断是否_IsReady, 以为角移动也需要ChangeState，如果只有头顶字也是需要移动的。
    -- 但是如果是正在加载中的模型并且没有空物体的不需要ChangeState，否则移动组件target会为空。
    if self._IsCullingVisible and not self._IsReady then return true end
    if self._FSM ~= nil then
        self:SyncPosWhenStateChange(self._FSM:GetCurrentState(), state)
        self._FSM:ChangeState(state)
    end

    return true
end

def.override("boolean").EnableCullingVisible = function (self, visible)
	if self._IsCullingVisible == visible then
		return
	end

	-- 处于model切换中，直接忽略，不做处理
	-- 可能存在的问题：该Player在下次同步前的战斗不同步
	if self._IsModelChanging then
		return
	end

	if not visible then
		self:DestroyHeadEffectObject()
	    	
    	-- 清理伤害字
        if self._HUDText ~= nil then
            self._HUDText:Release()
            self._HUDText = nil
        end
        -- 设置头顶字为Mini类型的
        if self._TopPate ~= nil then
            self._TopPate:SetMini(true)
        end
        --清理Buff状态
        self:ReleaseBuffStates()

        -- 移除坐骑出生动作计时器
        if self._MountBornAniTimer ~= 0 then
			self:RemoveTimer(self._MountBornAniTimer)
			self._MountBornAniTimer = 0
		end
		-- 进驻视野骑马状态
		self._IsMountEnterSight = false
		-- 特效清理
		for i,v in ipairs(self._HitGfxs) do
        v:Stop()
	    end
	    self._HitGfxs = {}
	    for i,v in ipairs(self._BelongToMeSkillGfxs) do
	        v:Stop()
	    end
	    self._BelongToMeSkillGfxs = {}

	    --技能相关处理
	    if self._SkillHdl ~= nil then
	    	self._SkillHdl:Cleanup()
	    end

	    if self._LvUpFx ~= nil then
			self._LvUpFx:Stop()
			self._LvUpFx = nil
		end
		if self._FightFx ~= nil then
			self._FightFx:Stop()
			self._FightFx = nil
		end
		if self._MountHorseFx ~= nil then
			self._MountHorseFx:Stop()
			self._MountHorseFx = nil
		end
		if self._ResurrectFx ~= nil then
			self._ResurrectFx:Stop()
			self._ResurrectFx = nil
		end
        if self._FSM ~= nil then
            self._FSM:Release()
        end
	else
    	if self._CombatStateChangeComp ~= nil then
	    	self._CombatStateChangeComp:ChangeState(true, self:IsInServerCombatState(), 0, 0)
		end
        --更新头顶字信息如果有的话
        if self._TopPate ~= nil then
            self._TopPate:SetMini(false)
        end
	end

    --控制播放头顶特效
    self:PlayEntityHeadEffect()
    --加载后是否立刻显示
    self:SetActive(self._LoadedIsShow)
    --更新头顶字信息如果有的话
    self:OnPateCreate()
    
    if self._MagicControlinfo ~= nil then
        self._MagicControlinfo:Refresh()
    end

    self._HangPointCache ={}

    self._IsCullingVisible = visible

	if self._TransformerModel then
		self._TransformerModel:SetVisible(self:IsVisible())
	end
    if self._MountModel then
		self._MountModel:SetVisible(self:IsVisible())
	end
    if self._Model ~= nil then
		self._Model:SetVisible(self:IsVisible())
	end
    if visible and self._WingModel ~= nil and not self._IsWingModelVisible then 
		self._WingModel:SetVisible(false)
	end

    self:EnableShadow(visible)     --刷新

    -- 需要重新判断骑马、翅膀、外观
    self:SyncAllExterior()

    if self._FSM ~= nil and not self._FSM:UpdateCurStateWhenBecomeVisible() then
        if self:IsDead() then
        	self:Dead()
        else
        	self:Stand()
        end
    end
end

def.override().OnClick = function (self)
	CPlayer.OnClick(self)
	local hostplayer = game._HostPlayer
	local hostskillhdl = hostplayer._SkillHdl
	if self:IsDead() then
	--[[
		救援功能 注释 2018-09-20

		hostplayer:UpdateTargetInfo(self, true)

		if self._IsForbidRescue then
			--场景限制
			game._GUIMan:ShowTipText( StringTable.Get(1110), false)
		elseif self:CanRescue() then
			if self:IsFriendly() then
				--战斗状态不能救援
				if hostplayer:IsInServerCombatState() then
    				TeraFuncs.SendFlashMsg( StringTable.Get(1108), false)
    			else
					local CSpecialIdMan = require  "Data.CSpecialIdMan"
					local  skill_id = CSpecialIdMan.Get("ResurrentSkillId")
					hostplayer:UpdateTargetInfo(self, true)
					hostskillhdl:CastSkill(skill_id, false)
				end
			else
				--不能救援，提示玩家
				game._GUIMan:ShowTipText( StringTable.Get( 1107 ), false)
			end
		else
			--已经被救援过，提示玩家
			game._GUIMan:ShowTipText( StringTable.Get( 1106 ), false)
		end
	]]
	else
		hostplayer:UpdateTargetInfo(self, true)
	end	
end

def.override("number", "number").OnHPChange = function (self, hp, max_hp)
	CEntity.OnHPChange(self, hp, max_hp)

	if CTeamMan.Instance():InSameTeam(self._TeamId) then
		local event = TeamInfoChangeEvent()
		event._Type = EnumDef.TeamInfoChangeType.Hp
		event._ChangeInfo = 
		{ 
			roleId = self._ID,
			HP = self._InfoData._CurrentHp,
			MaxHp = max_hp
		}

		CGame.EventManager:raiseEvent(nil, event)
	end
end

def.override("number", "number").OnHPChange_Simple = function (self, hp, max_hp)
	CEntity.OnHPChange_Simple(self, hp, max_hp)

	if CTeamMan.Instance():InSameTeam(self._TeamId) then
		local event = TeamInfoChangeEvent()
		event._Type = EnumDef.TeamInfoChangeType.Hp
		event._ChangeInfo = 
		{ 
			roleId = self._ID,
			HP = self._InfoData._CurrentHp,
			MaxHp = max_hp
		}

		CGame.EventManager:raiseEvent(nil, event)
	end
end

--是否敌对
def.override("=>", "boolean").IsHostile = function(self)
	return self:GetRelationWithHost() == "Enemy"
end

--是否友善
def.override("=>", "boolean").IsFriendly = function(self)
	return self:GetRelationWithHost() == "Friendly"
end

-- _G.RelationDesc = { [0] = "Neutral", [1] = "Friendly", [2] = "Enemy" }
def.override("=>", "string").GetRelationWithHost = function(self)  -- 仇恨列表 > 队伍 > 阵营 > 公会 > PK关系 
	-- 先做仇恨列表判断，如果在仇恨列表中，即为敌人
	local hp = game._HostPlayer
	
	if hp:IsEntityHate(self._ID) then
		return RelationDesc[2]
	end
    
	if self._InfoData == nil then 
		--warn(debug.traceback()) 
		return RelationDesc[0] 
	end

	local hostPlayerPKMode = hp._InfoData._PkMode
	local selfPKMode = self._InfoData._PkMode

    -- 本队伍成员始终相互友善
    if CTeamMan.Instance():InSameTeam(self._TeamId) then
		if hostPlayerPKMode == selfPKMode then			
			if hostPlayerPKMode == EPkMode.EPkMode_Guild and (not game._GuildMan:IsGuildMember(self._Guild._GuildID)) then
				return RelationDesc[0]
			else
				return RelationDesc[1]
			end    		
    	else
    		return RelationDesc[0]
    	end
    end

	-- 阵营 势力关系判断
    local relation, IsZYFriend = CEntity.GetRelationWith(self, hp)
	if IsZYFriend then 	-- 如果有阵营，判断阵营是否友好和敌对
		if relation == "Enemy" or relation == "Friendly" then
			return relation
		end
	end

    -- 本公会成员PK模式相同时相互友善,不同时相互中立    
    if game._GuildMan:IsGuildMember(self._Guild._GuildID) then
    	if hostPlayerPKMode == selfPKMode then
    		return RelationDesc[1]
    	else
    		return RelationDesc[0]
    	end
    end

    -- PK 关系判断
    do
    	-- LRL:取消紫名必敌对规则    lidaming  2018/07/13
    	-- if self:GetEvilValue() >= 100 then
    	-- 	return RelationDesc[2]
    	-- end

    	-- PK模式
    	if hostPlayerPKMode == EPkMode.EPkMode_Peace then
			if selfPKMode == EPkMode.EPkMode_Peace then
				return RelationDesc[1]
			elseif selfPKMode == EPkMode.EPkMode_Massacre then
				return RelationDesc[2]
			else
				if self._IsRedName == true then
					return RelationDesc[2]
				else
					return RelationDesc[0]
				end
			end
		elseif hostPlayerPKMode == EPkMode.EPkMode_Guild then
			if selfPKMode == EPkMode.EPkMode_Peace then
				return RelationDesc[0]
			else 
				return RelationDesc[2]
			end 
		elseif hostPlayerPKMode == EPkMode.EPkMode_Massacre then
			return RelationDesc[2]
		end
	end
    return RelationDesc[1]
end

def.override("=>","string").GetEntityColorName = function(self)
	local name = self._InfoData._Name
	 
	if self._IsRedName == true then
		name = "<color=#C03DF6>"..name.."</color>" 
	-- elseif CTeamMan.Instance():InSameTeam(self._TeamId) then
	-- 	name = "<color=#65D2FF>"..name.."</color>" 
	else
		if game._HostPlayer:IsEntityHate(self._ID) then
			name = "<color=#FA3319>"..name.."</color>"
		end

		local relation = self:GetRelationWithHost()
		if relation == "Neutral" then
			name = "<color=#E7CF89>"..name.."</color>"
		elseif relation == "Friendly" then
			name = "<color=#65D2FF>"..name.."</color>"
		elseif relation == "Enemy" then
			name = "<color=#FA3319>"..name.."</color>"
		end
	end
    return name
end

def.override("string", "=>","string").GetPetColorName = function(self, name)
	if self._IsRedName == true then
		name = "<color=#C03DF6>"..name.."</color>" 
	-- elseif CTeamMan.Instance():InSameTeam(self._TeamId) then
	-- 	name = "<color=#65D2FF>"..name.."</color>" 
	else
		if game._HostPlayer:IsEntityHate(self._ID) then
			name = "<color=#FA3319>"..name.."</color>"
		end

		local relation = self:GetRelationWithHost()
		if relation == "Neutral" then
			name = "<color=#E7CF89>"..name.."</color>"
		elseif relation == "Friendly" then
			name = "<color=#65D2FF>"..name.."</color>"
		elseif relation == "Enemy" then
			name = "<color=#FA3319>"..name.."</color>"
		end
	end
    return name
end

-- 模型加载完成后刷新脚底光圈
def.override().OnModelLoaded = function (self)
    self:SetPateOffsetH(0)
	CPlayer.OnModelLoaded(self)	

	self:EnableShadow(true)
end

def.override().UpdateTopPateHpLine= function(self)
	if self._TopPate == nil then return end

	local hp = game._HostPlayer
	if hp:In3V3Fight() then
		if self._CampId == hp._CampId then
			self._TopPate:SetHPLineIsShow(true, EnumDef.HPColorType.Green)
		else
			self._TopPate:SetHPLineIsShow(not self:IsDead(), EnumDef.HPColorType.Red)
		end
	elseif hp:InEliminateFight() then
		--	判断是否在队伍中 在队伍中 显示血条
		local bInTeam = (self:InTeam() and CTeamMan.Instance():IsTeamMember(self._ID))
		if bInTeam then
			self._TopPate:SetHPLineIsShow(true, EnumDef.HPColorType.Green)
		else
			self._TopPate:SetHPLineIsShow(not self:IsDead(), EnumDef.HPColorType.Red)
		end
	else
		if hp:IsEntityHate(self._ID) then
			self._TopPate:SetHPLineIsShow(true,EnumDef.HPColorType.Red)
		else
			--	判断是否在队伍中 在队伍中 显示血条
			local bShow = (self:InTeam() and CTeamMan.Instance():IsTeamMember(self._ID))

			if bShow then
				self._TopPate:SetHPLineIsShow(true, EnumDef.HPColorType.Green )
			else
				self._TopPate:SetHPLineIsShow(false, EnumDef.HPColorType.None)
			end
		end
	end
end

def.override("boolean").OnBattleTopChange= function(self,isShow)
	if self._TopPate == nil then return end
    if isShow then
        self._TopPate:SetHPLineIsShow(true,EnumDef.HPColorType.Red)
    else
        self._TopPate:SetHPLineIsShow(false,EnumDef.HPColorType.None)
    end
end

def.override().UpdateTopPateRescue= function(self)
    -- 先判断场景限制
    if self._IsForbidRescue then return end
    CPlayer.UpdateTopPateRescue(self)
end

def.override("=>", "number").GetRenderLayer = function (self)
    return EnumDef.RenderLayer.Player
end

def.method("number").SetPKMode = function(self, pkmode)
	self._InfoData._PkMode = pkmode
	if self._TopPate ~= nil then
		self._TopPate:UpdateName(true)
		self:UpdatePetName()
		--self._TopPate:SetPKIconIsShow( self:GetPkMode() == EPkMode.EPkMode_Massacre )
		self:UpdateTopPateRescue()
	end
end

def.method("boolean").SetEvilNum = function(self, evilNum)
	self._IsRedName = evilNum
	if self._TopPate ~= nil then
		self._TopPate:UpdateName(true)
		self:UpdatePetName()
	end
end

-- 设置角色阵营ID
def.override("number").SetCampId = function(self, campId)
	CEntity.SetCampId(self, campId)
	self:UpdatePetName()
end

--Host Camp ID Changed
def.method().OnHostCampUpdate = function(self)
    if self._TopPate ~= nil then
        self._TopPate:UpdateName(true)
        self:UpdatePetName()
        self:UpdateTopPate(EnumDef.PateChangeType.Rescue)
    end
end


-- 返回角色称号ID 
def.override("=>", "number").GetDesignationId = function(self)
	return self._InfoData._DesignationId
end

--非战斗状态下，根据当前角色速度得到当前动画枚举值和播放速率(主角的战斗速度等于基础移动速度)
def.override("number","number","=>", "string","number").GetRunAnimationNameAndRate = function(self,standardSpeed,fightSpeed)
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
        if self:IsModelChanged() then 
        	return animation,ratePlay
        end
        return EnumDef.CLIP.COMMON_RUN,ratePlay
    end
end

-- 设置玩家自定义头像
--[[
def.override("number").SetCustomImg = function(self, CustomImg)	
	local path = ""
	if CustomImg == ECustomSet.ECustomSet_Defualt	--默认职业头像
	or CustomImg == ECustomSet.ECustomSet_Review then	--审核中  	
		path = ""
		self._InfoData._CustomPicturePath = path
		self._InfoData._CustomImgSet = CustomImg
	elseif CustomImg == ECustomSet.ECustomSet_HaveSet then	--获取自定义头像
		local callback = function(strFileName ,retCode, error)	
			if retCode == 0 then
				path =  GameUtil.GetCustomPicDir().."/"..self._ID
				local C2SCustomImgSet = require "PB.net".C2SCustomImgSet
				local msg = C2SCustomImgSet()
				msg.CustomImgSet = ECustomSet.ECustomSet_HaveSet
				PBHelper.Send(msg)
				self._InfoData._CustomImgSet = ECustomSet.ECustomSet_HaveSet
			elseif retCode == 4 then  -- error: 1、参数不匹配 2、没有用户 3、审核中 4、审核未通过 5、文件不存在 6、md5一致
				local C2SCustomImgSet = require "PB.net".C2SCustomImgSet
				local msg = C2SCustomImgSet()
				msg.CustomImgSet = ECustomSet.ECustomSet_Defualt
				PBHelper.Send(msg)
				path = ""
				self._InfoData._CustomImgSet = ECustomSet.ECustomSet_Defualt
			elseif retCode == 6 then
				path =  GameUtil.GetCustomPicDir().."/"..self._ID
				self._InfoData._CustomImgSet = CustomImg
			else
				-- warn("lidaming ---->>>  DownloadPicture callback retCode == ", retCode, "error == ", error)
				path = ""
				self._InfoData._CustomImgSet = CustomImg
			end				
			self._InfoData._CustomPicturePath = path	

			--头像服和游戏服 头像数据通信之后可更新头像。
			local NotifyPropEvent = require "Events.NotifyPropEvent"
			local event = NotifyPropEvent()
			event.ObjID = self._ID
			event.Type = "CustomImg"
			CGame.EventManager:raiseEvent(nil, event)				
		end
		GameUtil.DownloadPicture(tostring(self._ID), callback)						
	end			
end
]]

def.override("number", "number", "number", "number").OnLevelUp = function (self, currentLevel, currentExp, currentParagonLevel, currentParagonExp)
	CPlayer.OnLevelUp(self, currentLevel, currentExp, currentParagonLevel, currentParagonExp)
    
    if not self:IsCullingVisible() then return end

	local ElsePlayerLevelChangeEvent = require "Events.ElsePlayerLevelChangeEvent"
	local event = ElsePlayerLevelChangeEvent()
	event._EntityId = self._ID
	CGame.EventManager:raiseEvent(nil, event)
end

def.override().OnResurrect = function(self)
	CPlayer.OnResurrect(self)
	if self._TopPate ~= nil then
		self._TopPate:SetVisible(true)
		self:UpdateTopPate(EnumDef.PateChangeType.Rescue)
	end
end

def.override("table").SetPos = function (self, pos)
    if pos == nil then
        warn("SetPos's pos is nil", debug.traceback())
        return
    end
    
    if self._IsCullingVisible and not self._IsReady then
        self._InitPos = pos
        return
    end

    pos.y = GameUtil.GetMapHeight(pos) + self._HeightOffsetY

    self._GameObject.position = pos
end

def.override("table", "table", "number", "table", "number", "boolean", "table").OnMove = function (self, curStepPos, facedir, movetype, movedir, speed, useDest, finalDstPos)
    self._StopMovePos = nil
    if not self._IsReady then
        self._InitPos = curStepPos
        self._InitDir = facedir  
    end

    if self._IsCullingVisible and not self._IsReady then
        -- 如果是以在关注列表里面创建的玩家，模型还没有加载好。它的self._GameObject是空，因此不能移动
        return
    end

    if self:IsDead() then return end
    if not self:CanMove() then return end  -- 状态不能移动

    self:SetMoveSpeed(speed)
    self._MoveType = movetype

    local game = game
	local hp = game._HostPlayer
	if not self._IsCullingVisible and Vector3.DistanceH(hp:GetPos(), self:GetPos()) > 15 then
		self:SetPos(curStepPos)
    	return
	end

    local ENTITY_MOVE_TYPE = require "PB.net".ENTITY_MOVE_TYPE
    if movetype == ENTITY_MOVE_TYPE.ForceSync then
        self:SetPos(curStepPos)
        self:SetDir(facedir)
    elseif movetype == ENTITY_MOVE_TYPE.Walking or movetype == ENTITY_MOVE_TYPE.Running then
        if speed < 0.01 then warn("Entity's move speed is near zero: ", speed, self._ID) end
        -- player同步消息比较频繁，需要使用预测方式
        if not useDest or Vector3.SqrDistanceH(curStepPos, finalDstPos) > 0.16 then
            local predictCurpos = curStepPos + movedir * speed * 0.2
            self:Move(predictCurpos, 0, nil, nil)
        else
            self:Move(finalDstPos, 0, nil, nil)
        end
    elseif movetype == ENTITY_MOVE_TYPE.SkillMove then
        if speed < 0.01 then warn("Entity's skill move speed is near zero ", speed, self._ID) end
        local internal = Vector3.DistanceH(self:GetPos(), finalDstPos)/speed
        GameUtil.AddDashBehavior(self:GetGameObject(), finalDstPos, internal, true, false)
    elseif movetype == ENTITY_MOVE_TYPE.TeamFollowing then
        self:NormalMove(curStepPos, speed, 0, nil, nil)
    else
        -- warn("Object:OnMove, do nothing, movetype =", movetype)
    end
end 

CElsePlayer.Commit()
return CElsePlayer
