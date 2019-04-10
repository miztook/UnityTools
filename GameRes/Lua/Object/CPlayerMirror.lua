local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CNonPlayerCreature = require "Object.CNonPlayerCreature"
local CStateMachine = require "FSM.CStateMachine"
local CElementData = require "Data.CElementData"
local CElsePlayer = require "Object.CElsePlayer"
local CPlayer = require "Object.CPlayer"
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local CSkillSealInfo = require "Skill.CSkillSealInfo"
local CModel = require "Object.CModel"
local ObjectInfoList = require "Object.ObjectInfoList"
local ModelParams = require "Object.ModelParams"
local EquipChangeCompleteEvent = require "Events.EquipChangeCompleteEvent"
local CTeamMan = require "Team.CTeamMan"
local CGame = Lplus.ForwardDeclare("CGame")
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local TeamInfoChangeEvent = require "Events.TeamInfoChangeEvent"

local CPlayerMirror = Lplus.Extend(CNonPlayerCreature, "CPlayerMirror")
local def = CPlayerMirror.define

def.field(CPlayer)._PlayerComponent = nil
def.field("table")._Equipments = BlankTable
def.field("boolean")._IsModelHidden = false
def.field("userdata")._CombatStateChangeComp = nil
def.field("boolean")._IgnoreClientStateChange = false
def.field("number")._CombatStateClearTimerId = 0
def.field("boolean")._IsChangePose = false  		-- 是否在战斗姿态
def.field("table")._ChangePoseDate = nil 			-- 姿态动作相关

def.static("=>", CPlayerMirror).new = function ()
	local obj = CPlayerMirror()
	obj._FSM = CStateMachine.new()
	obj._SkillHdl = CObjectSkillHdl.new(obj)
	obj._HitEffectInfo = CHitEffectInfo.new(obj)
	obj._SealInfo = CSkillSealInfo.new(obj)
	return obj
end

local function PlayerComponentInit(self, info)
	local pc = CElsePlayer.new()
	CEntity.Init(pc, info.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo)
	
	local creature_info = info.MonsterInfo.CreatureInfo

	pc._InfoData = ObjectInfoList.CPlayerInfo()
	pc._InfoData._Prof = info.ProfessionId
	pc._InfoData._Gender = Profession2Gender[info.ProfessionId]
	pc._ProfessionTemplate = CElementData.GetProfessionTemplate(info.ProfessionId)
	pc._InfoData._CurShield = creature_info.ShieldValue
	if info.OriginParam < 0 then
		local npcName = CElementData.GetTextTemplate(tonumber(creature_info.Name))
		pc._InfoData._Name = npcName.TextContent
	else
		pc._InfoData._Name = creature_info.Name
	end
	pc._InfoData._Level = creature_info.Level
	pc._InfoData._MaxHp = creature_info.MaxHp
	pc._InfoData._CurrentHp = creature_info.CurrentHp
	pc._InfoData._MaxStamina = creature_info.MaxStamina
	pc._InfoData._CurrentStamina = creature_info.CurrentStamina
	pc._InfoData._TitleName = game._DesignationMan:GetColorDesignationNameByTID(info.Exterior.DesignationId)
	pc._TeamId = info.TeamId or 0
	pc._IsInCombatState = creature_info.CombatState

	if info.Exterior.guildName ~= nil then
		pc._Guild._GuildName = info.Exterior.guildName
		if info.Exterior.GuildIcon ~= nil then
			pc._Guild._GuildIconInfo._BaseColorID = info.Exterior.GuildIcon.BaseColorID
			pc._Guild._GuildIconInfo._FrameID = info.Exterior.GuildIcon.FrameID
			pc._Guild._GuildIconInfo._ImageID = info.Exterior.GuildIcon.ImageID
		end
		self:UpdateTopPate(EnumDef.PateChangeType.GuildName)
	end

	pc._IsReady = false

	self._PlayerComponent = pc
end

local function MonsterComponentInit(self, info)
	local creature_info = info.MonsterInfo.CreatureInfo
	local entity_info = creature_info.MovableInfo.EntityInfo
	CEntity.Init(self, entity_info)
	self._IsInCombatState = creature_info.CombatState
	self._MonsterTemplate = CElementData.GetMonsterTemplate(info.MonsterInfo.MonsterTid)

	self._InfoData = ObjectInfoList.CPlayerMirrorInfo()
	self._InfoData._Prof = info.ProfessionId
	self._InfoData._Gender = Profession2Gender[info.ProfessionId]
	if info.OriginParam < 0 then
		local npcName = CElementData.GetTextTemplate(tonumber(creature_info.Name))
		self._InfoData._Name = npcName.TextContent
	else
		self._InfoData._Name = creature_info.Name
	end

	self._InfoData._Level = creature_info.Level
	self._InfoData._MaxHp = creature_info.MaxHp
	self._InfoData._CurrentHp = creature_info.CurrentHp
	self._InfoData._MaxStamina = creature_info.MaxStamina
	self._InfoData._CurrentStamina = creature_info.CurrentStamina
	self._InfoData._AffixIds = creature_info.AffixIds
	-- 阵营相关

	self._CampId = creature_info.CampId
	self._InfoData._FactionId = creature_info.FactionId
	self:UpdateSealInfo(creature_info.BaseStates)
	self:InitMagicControls(creature_info.MagicControlStates)	
	self._EnemyCampTable = creature_info.EnemyCampList
end

def.override("table").Init = function (self, info)
	PlayerComponentInit(self, info)
	MonsterComponentInit(self, info)	
	
	local skills = {}
	local MakeSkillData = require "Skill.CSkillUtil".MakeUniqueSkillData
	for i,v in ipairs(info.SkillDatas) do				
		skills[#skills + 1] = { SkillId = v.SkillId, SkillLevel = v.SkillLevel, Skill = MakeSkillData(v, self) }
	end
	self._UserSkillMap = skills

	self._PlayerComponent:SetOutwardDatas(info.Exterior)
end

def.override("number").Load = function (self, enterType)
	self._PlayerComponent._OutwardParams = self:GetModelParams()

	local m = CModel.new()
	m._ModelFxPriority = self:GetModelCfxPriority()
	self._Model = m
	self._PlayerComponent._Model = m
	
	m:LoadWithModelParams(self._PlayerComponent._OutwardParams, function()
			self:OnLoad()
		end)
end

def.override("=>", "number").GetRadius = function (self)
	return self._PlayerComponent._ProfessionTemplate.CollisionRadius
end

def.override("=>", "number").GetFaction = function(self)
    return self._InfoData._FactionId
end

def.method().OnLoad = function (self)
	local function _onload(self)
		if self._Model == nil then return end
		self._Model._GameObject.name = "Model"
		self:AddObjectComponent(false, 0.5)

		GameUtil.SetLayerRecursively(self._GameObject, EnumDef.RenderLayer.Player)
		local go = self._Model._GameObject
		self._CombatStateChangeComp = go:GetComponent(ClassType.CombatStateChangeBehaviour)
		if self._CombatStateChangeComp == nil then
			self._CombatStateChangeComp = go:AddComponent(ClassType.CombatStateChangeBehaviour)
		end
		GameUtil.AddFootStepTouch(self._Model._GameObject)
		
		local pc = self._PlayerComponent
		pc:SetCurWeaponInfo()
		pc:SetCurWingModel()
		
		self._IsReady = true
		self:OnModelLoaded()		
		
		pc._IsReady = true
		if pc._OnLoadedCallbacks ~= nil and #pc._OnLoadedCallbacks > 0 then
	        for i,v in ipairs(pc._OnLoadedCallbacks) do
	            v(pc)
	        end
	        pc._OnLoadedCallbacks = nil
	    end
		
		self:Stand()
		self._CombatStateChangeComp:ChangeState(true, self._IsInCombatState, 0, 0)

		--self:EnableShadow(true)
		self:UpdateTopPateHpLine()
		self:UpdateTopPateGuildName()
		self:UpdateTopPateTitleName()
	end
	
	if self._IsReleased then
		self._Model:Destroy()
		self._Model = nil
	else
		_onload(self)
	end
end

def.override().OnModelLoaded = function(self)
	CNonPlayerCreature.OnModelLoaded(self)

	--关闭castShadow
	self:EnableCastShadows(false)

	self:EnableShadow(self._MonsterTemplate.IsShowShadow)
end

def.override("number", "number").OnHPChange = function (self, hp, max_hp)
	CEntity.OnHPChange(self, hp, max_hp)

	if CTeamMan.Instance():InSameTeam(self._PlayerComponent._TeamId) then
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

def.override("=>","string").GetEntityColorName = function(self)
	local name = self._InfoData._Name
	
	if game._HostPlayer:IsEntityHate(self._ID) then
		name = "<color=#FA3319>"..name.."</color>"
	end

	if self:InTeam() then
	-- 队伍里的镜像 是AI助战,逻辑跟人一致
		-- warn("队伍AI助战")
		local relation = self:GetRelationWithHost()
		if relation == "Neutral" then
			name = "<color=#E7CF89>"..name.."</color>"
		elseif relation == "Friendly" then
			name = "<color=#65D2FF>"..name.."</color>"
		elseif relation == "Enemy" then
			name = "<color=#FA3319>"..name.."</color>"
		end
	else
	-- 正常AI镜像
		-- warn("正常AI镜像")
		local relation = self:GetRelationWithHost()
		if relation == "Neutral" then
			name = "<color=#E7CF89>"..name.."</color>"
		elseif relation == "Friendly" then
			name = "<color=white>"..name.."</color>"
		elseif relation == "Enemy" then
			name = "<color=#FA3319>"..name.."</color>"
		end
	end

	return name
end

def.override("=>", "string").GetRelationWithHost = function(self)  -- 仇恨列表 > 队伍 > 阵营 > 公会 > PK关系 
	if self._InfoData == nil then return RelationDesc[0] end
	
	-- 先做仇恨列表判断，如果在仇恨列表中，即为敌人
	local hp = game._HostPlayer
	local hostPlayerPKMode = hp._InfoData._PkMode
	local selfPKMode = self._InfoData._PkMode
	
	if hp:IsEntityHate(self._ID) then
		return RelationDesc[2]
	end
    
    -- 本队伍成员始终相互友善
	if CTeamMan.Instance():InSameTeam(self._PlayerComponent._TeamId) then
		return RelationDesc[1]
	end
	
	-- 阵营 势力关系判断
	local relation, IsZYFriend = CEntity.GetRelationWith(self, hp)
	if relation == "Enemy" or relation == "Friendly" then
		return relation
	end
	
    return RelationDesc[0]
end

-- 获取模型数据
def.method("=>", ModelParams).GetModelParams = function(self)
	-- TODO: 缺少时装相关信息
	return self._PlayerComponent:GetModelParams()
end

def.override("=>", "boolean").GetChangePoseState = function(self)
	return self._IsChangePose
end

def.method("table").SetChangePoseDate = function(self, data)
	self._ChangePoseDate = data
	self._IsChangePose = (data ~= nil)
end

def.method("number", "=>", "string").GetChangePoseData = function(self, ani_type)
	local ret = ""
	if ani_type ==  EnumDef.PostureType.StandAction then		
		if self._ChangePoseDate[1] and self._ChangePoseDate[1] ~= "" then
			ret = self._ChangePoseDate[1]
		end
	elseif ani_type ==  EnumDef.PostureType.FightStandAction then
		if self._ChangePoseDate[2] and self._ChangePoseDate[2] ~= "" then
			ret = self._ChangePoseDate[2]
		end
	elseif ani_type ==  EnumDef.PostureType.MoveAction then
		if self._ChangePoseDate[3] and self._ChangePoseDate[3] ~= "" then
			ret = self._ChangePoseDate[3]
		end
	elseif ani_type ==  EnumDef.PostureType.FightMoveAction then
		if self._ChangePoseDate[4] and self._ChangePoseDate[4] ~= "" then
			ret = self._ChangePoseDate[4]
		end
	else 
		warn("error type occur in GetChangePoseData ",debug.traceback())		
	end
	return ret
end

def.method("boolean").ChangeWeaponHangpoint = function(self, isOnBack)
	warn("玩家镜像不能释放休闲技能")
end

def.override().CreatePate = function (self)
	local CPlayerMirrorTopPate = require "GUI.CPate".CPlayerMirrorTopPate
	local pate = CPlayerMirrorTopPate.new()
	self._TopPate = pate
	local callback = function()
		self:OnPateCreate()
	end
	pate:Create(self, callback)
end

def.override().OnPateCreate = function(self)
	CNonPlayerCreature.OnPateCreate(self)
	if self._TopPate == nil then return end

	self._TopPate:OnTitleNameChange(true,self:GetTitle())
	self:OnBattleTopChange(false)
end

def.override("number").UpdateTopPate = function (self, updateType)
	CNonPlayerCreature.UpdateTopPate(self, updateType)
	if self._TopPate == nil then return end

	if updateType == EnumDef.PateChangeType.TitleName then
		self:UpdateTopPateTitleName()
	elseif updateType == EnumDef.PateChangeType.GuildName then
		self:UpdateTopPateGuildName()
	elseif updateType == EnumDef.PateChangeType.HPLine then
		self:UpdateTopPateHpLine()
	end
end

def.method().UpdateTopPateHpLine = function(self)
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
			self._TopPate:SetHPLineIsShow(true, EnumDef.HPColorType.Red)
		else
			--	判断是否在队伍中 在队伍中 显示血条
			local bShow = (self:InTeam() and CTeamMan.Instance():IsTeamMember(self._ID))

			if bShow then
				self._TopPate:SetHPLineIsShow(true, EnumDef.HPColorType.Green)
			else
				self._TopPate:SetHPLineIsShow(false, EnumDef.HPColorType.None)
			end
		end
	end
end

def.method().UpdateTopPateGuildName = function(self)
	if self._TopPate == nil then return end
	if self._PlayerComponent._Guild._GuildName == "" then
		self._TopPate:OnGuildNameChange(false,self._PlayerComponent._Guild)
	else
		self._TopPate:OnGuildNameChange(true,self._PlayerComponent._Guild)
	end
end

def.method().UpdateTopPateTitleName = function(self)
	if self._TopPate == nil then return end
	if self._PlayerComponent._InfoData._TitleName == "" then
		self._TopPate:OnTitleNameChange(false,self._PlayerComponent._InfoData._TitleName)
	else
		self._TopPate:OnTitleNameChange(true,self._PlayerComponent._InfoData._TitleName)
	end
end

def.method("=>", "boolean").InTeam = function(self)
	return self._PlayerComponent._TeamId > 0
end

def.method("number").SetTeamId = function(self, teamId)
	self._PlayerComponent._TeamId = teamId
end

def.override("table").SkillMove = function (self, pos)
	self._StopMovePos = nil
    if not self:CanMove() then
        return 
    end
	self._SkillHdl:SkillMove(pos, nil, nil)
end

def.override("table", "number", "function", "function").Move = function (self, pos, offset, successcb, failcb)
	if self._SkillHdl:IsCastingSkill() then
		self._SkillHdl:DoMove(pos, offset, successcb, failcb)
	else
		self:NormalMove(pos, self:GetMoveSpeed(), offset, successcb, failcb)
	end
end

def.override("boolean").OnBattleTopChange= function(self,isShow)
	if self._TopPate == nil then return end
	if self:InTeam() then return end

    if isShow then
        self._TopPate:SetHPLineIsShow(true,EnumDef.HPColorType.Red)
    else
        self._TopPate:SetHPLineIsShow(false,EnumDef.HPColorType.None)
    end
end

-- 返回值：energy type, cur_energy, max_energy
def.override("=>", "number", "number", "number").GetEnergy = function (self)
    if self._InfoData == nil then return -1, 0, 1 end
    
    local ENUM = require "PB.data".ENUM_FIGHTPROPERTY
	local SkillEnergyType = require "PB.Template".Skill.SkillEnergyType
    local prof = self._InfoData._Prof
    local energy_type = -1
    local curIdx, maxIdx = ENUM.CURRENTMANA, ENUM.MAXMANA

	if curIdx ~= 0 then
		local max = self._InfoData._FightProperty[maxIdx][1]
		if max <= 0 then max = 1 end
		return energy_type, self._InfoData._FightProperty[curIdx][1], max
	end

	return -1, 0, 1
end

def.override("number", "=>", "table").GetEntitySkill = function(self, skill_id)
	local skill = nil
    for i,v in ipairs(self._UserSkillMap) do
		if v.SkillId == skill_id then
			skill = v.Skill
		end
	end
	return skill
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.PLAYERMIRROR
end

local function remove_combat_clear_timer(self)
    if self._CombatStateClearTimerId ~= 0 then
    	self:RemoveTimer(self._CombatStateClearTimerId)
    	self._CombatStateClearTimerId = 0
	end
end

local function add_combat_clear_timer(self, last_time)
    remove_combat_clear_timer(self)
    self._CombatStateClearTimerId = self:AddTimer(last_time, true, function()
            if not self._IsReady or self._IsReleased or self:IsDead() then return end
	    	self._IsInCombatState = false
            self._CombatStateClearTimerId = 0
			local prof = self._InfoData._Prof
            local weapon_pos_change_time = WeaponChangeCfg[prof][3]
        	local weapon_scale_change_time = WeaponChangeCfg[prof][2]
            self._CombatStateChangeComp:ChangeState(false, false, weapon_scale_change_time, weapon_pos_change_time)
			CSoundMan.Instance():Play3DAudio(WeaponChangeSoundCfg[prof][1], self:GetPos(), 0)
            self._SkillHdl:StopGfxPlay(EnumDef.EntityGfxClearType.BackToPeace)
        end)
end

def.override("boolean", "boolean", "number", "boolean", "boolean").UpdateCombatState = function(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)
	if is_client_state then
		--warn("logic error: Player Mirror can not change CombatState by client", debug.traceback())
	else
		self:AddLoadedCallback( function()
				if self._IsReleased then return end
				local old_combat_state = self._IsInCombatState
		        self._IsInCombatState = is_in_combat_state
		        self._PlayerComponent._IsInCombatState = is_in_combat_state  

		        if is_in_combat_state then 
		            self._IgnoreClientStateChange = true
		            remove_combat_clear_timer(self)
		            if not old_combat_state then
		            	if ignore_lerp then
		                	self._CombatStateChangeComp:ChangeState(true, true, 0, 0)
		                else
							local prof = self._InfoData._Prof
		                	local weapon_pos_change_time = WeaponChangeCfg[prof][4]
		            		local weapon_scale_change_time = WeaponChangeCfg[prof][1]    				
		            		self._CombatStateChangeComp:ChangeState(false, true, weapon_scale_change_time, weapon_pos_change_time)
					    	CSoundMan.Instance():Play3DAudio(WeaponChangeSoundCfg[prof][2], self:GetPos(), 0)
		                end
		            	self._PlayerComponent:PlayCurDressFightFx(EnumDef.PlayerDressPart.Weapon)
		            end
		            --self._SkillHdl:InterruptSpecialSkill()  -- 镜像没休闲技能
		        else
		            self._IgnoreClientStateChange = false
		            add_combat_clear_timer(self, 5)
		        end
			end)
	end
end

def.override("table", "function").ChangeAllPartShape = function(self, path_shape_map, callback)
	self._PlayerComponent:ChangeAllPartShape(path_shape_map, function ()
		-- 设置层级
		GameUtil.SetLayerRecursively(self:GetOriModel():GetGameObject(), EnumDef.RenderLayer.NPC)
		if callback ~= nil then
			callback()
		end
	end)
end

def.override("function").ResetPartShape = function(self, callback)
	self._PlayerComponent:ResetPartShape(function ()
		-- 设置层级
		GameUtil.SetLayerRecursively(self:GetOriModel():GetGameObject(), EnumDef.RenderLayer.NPC)
		if callback ~= nil then
			callback()
		end
	end)
end


def.override("number", "number", "number", "boolean").OnDie = function (self, killer_id, element_type, hit_type, play_ani)
	CEntity.OnDie(self, killer_id, element_type, hit_type, play_ani)

	if self._CombatStateChangeComp ~= nil then
		-- Player死亡时，需要将武器放在手上（此时与战斗状态时，武器在手上没关系，美术动作这么做的）
		self._CombatStateChangeComp:ChangeState(true, true, 0, 0)
	end
end

def.override("=>","number","number").GetBaseSpeedAndFightSpeed = function(self)
    return self._PlayerComponent._ProfessionTemplate.MoveSpeed,self._PlayerComponent._ProfessionTemplate.MoveSpeed
end

def.override("table", "boolean").UpdateFightProperty = function(self, properties, isNotifyFightScore)
	CEntity.UpdateFightProperty(self, properties, isNotifyFightScore)
	
	for i,v in ipairs(properties) do
		if v ~= nil and v.Index ~= nil and v.Value ~= nil then
			self._InfoData._FightProperty[v.Index] = {v.Value, 0}
		else
			warn("!!! empty property", v, v.Index, v.Value)
		end
	end

	self:UpdateTopPate(EnumDef.PateChangeType.HP)
	if self._TopPate ~= nil and self._InfoData._MaxStamina > 0 then
		self._TopPate:OnStaChange(self._InfoData._CurrentStamina / self._InfoData._MaxStamina)
	end
end

def.override("table", "boolean").UpdateFightProperty_Simple = function(self, properties, isNotifyFightScore)
    self:UpdateFightProperty(properties, isNotifyFightScore)

 --    local ENUM_FIGHTPROPERTY = require "PB.data".ENUM_FIGHTPROPERTY
	-- for i,v in ipairs(properties) do
	-- 	if v ~= nil and v.Index ~= nil and v.Value ~= nil then
	-- 		self._InfoData._FightProperty[v.Index] = {v.Value, 0}
	-- 	else
	-- 		warn("!!! empty property", v, v.Index, v.Value)
	-- 	end
	-- end
end

def.override("number", "=>", "string", "string", "number").GetEntityFsmAnimation = function (self, fsm_type)
    local animation, wingAnimation = "", ""
    local rate = 1
    if fsm_type == FSM_STATE_TYPE.IDLE then 
    	if self:IsInCombatState() then
            animation = EnumDef.CLIP.BATTLE_STAND
        else
            animation = EnumDef.CLIP.COMMON_STAND
        end 
        
        if self:GetChangePoseState() then            
    		local data = nil            
            if self:IsInCombatState() then
                data = self:GetChangePoseData(EnumDef.PostureType.FightStandAction)
            else
                data = self:GetChangePoseData(EnumDef.PostureType.StandAction)
            end

            if data and data ~= "" then
                animation = data
            end   
        end        
    elseif fsm_type == FSM_STATE_TYPE.MOVE then
    	local baseSpeed,fightSpeed = self:GetBaseSpeedAndFightSpeed()     
        if self:IsInCombatState() then                   
            animation, rate = self:CheckRunBattleAnimation(fightSpeed)   
        else
            animation, rate = self:CheckRunAnimation(baseSpeed,fightSpeed)            
        end
        
        if self:GetChangePoseState() then  
    		local data = nil            
            if self:IsInCombatState() then
                data = self:GetChangePoseData(EnumDef.PostureType.FightMoveAction)
            else
                data = self:GetChangePoseData(EnumDef.PostureType.MoveAction)
            end
            if data and data ~= "" then
                animation = data
                wingAnimation = EnumDef.CLIP.WING_COMMON_STAND
                rate = 1
            end
        end        
    else
        warn("only idle & move support in GetEntityFsmAnimation")
    end
    return animation, wingAnimation, rate
end

def.override().UpdateWingAnimation = function (self)
	self._PlayerComponent:UpdateWingAnimation()
end

def.override("string", "number", "boolean", "number", "number", "boolean").PlayWingAnimation = function (self, aniname, fade_time, is_queued, life_time, aniSpeed, is_lock_rotation)
	self._PlayerComponent:PlayWingAnimation(aniname, fade_time, is_queued, life_time, aniSpeed, is_lock_rotation)
end

def.method().UpdatePetName = function(self)
end

def.override().Release = function (self)
	self._PlayerComponent:Release()
	CEntity.Release(self)
end

CPlayerMirror.Commit()
return CPlayerMirror