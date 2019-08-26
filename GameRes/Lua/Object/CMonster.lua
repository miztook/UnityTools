local Lplus = require "Lplus"
local CEntity = require "Object.CEntity"
local CNonPlayerCreature = require "Object.CNonPlayerCreature"
local CStateMachine = require "FSM.CStateMachine"
local CElementData = require "Data.CElementData"
local CHitEffectInfo = require "Skill.CHitEffectInfo"
local CSkillSealInfo = require "Skill.CSkillSealInfo"
local ObjectInfoList = require "Object.ObjectInfoList"
local CSharpEnum = require "Main.CSharpEnum"
local CObjectSkillHdl = require "Skill.CObjectSkillHdl"
local CVisualEffectMan = require "Effects.CVisualEffectMan"
local JudgementHitType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitType
local CGame = Lplus.ForwardDeclare("CGame")
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE
local DebugTools = require "Main.DebugTools"

local CMonster = Lplus.Extend(CNonPlayerCreature, "CMonster")
local def = CMonster.define

def.field("number")._DissolveDeathTimer = 0
def.field("number")._ProgressCountMax = 1
def.field("boolean")._IsTopPateShown = false

def.static("=>", CMonster).new = function ()
	local obj = CMonster()
	obj._FSM = CStateMachine.new()
	obj._HitEffectInfo = CHitEffectInfo.new(obj)
	obj._SealInfo = CSkillSealInfo.new(obj)
	obj._SkillHdl = CObjectSkillHdl.new(obj)
	obj._FadeOutWhenLeave = true
	return obj
end

-- MonsterQuality
def.override("table").Init = function (self, info)
	CNonPlayerCreature.Init(self, info)

	if self._MonsterTemplate ~= nil then
		if info.GMFlag == true then
			-- warn("true Name ==", self._MonsterTemplate.TextDisplayName)
			self._InfoData._Name = self._MonsterTemplate.TextDisplayName .. " Debug"
		else
			-- warn("self._MonsterTemplate.TextDisplayName false ==", self._MonsterTemplate.TextDisplayName)
			self._InfoData._Name = self._MonsterTemplate.TextDisplayName
		end

		if info.CreatureInfo and info.CreatureInfo.SkillInfo then
			self:PerformInitedSkill(info.CreatureInfo.SkillInfo)
		end
	end

	self:InitProgressCountMax()
	
	self._CollisionRadius = info.CollisionRadius
end

def.override("=>","string").GetEntityColorName = function(self)
	local name = self._InfoData._Name
    return "<color=#FA3319>"..name.."</color>"
end

def.override().OnPateCreate = function(self)
	--CEntity.OnPateCreate(self)
	if self._TopPate == nil then return end

	self._TopPate:UpdateName(true)
	local titleStr = self:GetTitle()
	if titleStr ~= "" then
		self._TopPate:OnTitleNameChange(true, titleStr)
	end

	local percent = 0
	if self._InfoData._MaxStamina > 0 then
		percent = self._InfoData._CurrentStamina / self._InfoData._MaxStamina
		self._TopPate:OnStaChange(percent)
	end

	self._IsTopPateShown = false
	self:OnQuestStatusChange()
	if self._CurLogoType ~= EnumDef.EntityLogoType.Kill then
		self:OnBattleTopChange((self._MonsterTemplate.MonsterQuality == EnumDef.MonsterQuality.BEHEMOTH or
			self._MonsterTemplate.MonsterQuality == EnumDef.MonsterQuality.LEADER) or self:GetCurrentTargetId() == game._HostPlayer._ID)
	end
end

def.override("table").SetDir = function (self, dir)
    if dir == nil then
        warn("Setdir's dir is nil", debug.traceback())
    	return 
	end

    dir.y = 0
    dir = dir:Normalize()
    if not self._IsReady then
        self._InitDir = dir
        return
    end

    local function ResetDestDir()
    	self._SkillDestDir = nil
    end 

    self._SkillDestDir = dir
    -- skilling
    GameUtil.AddTurnBehavior(self._GameObject, dir, 720, ResetDestDir, false, 0)
end

def.override("table", "number").ChangeDirContinued = function (self, dir, speed)
    if dir == nil then
        warn("ChangeDir's dir is nil", debug.traceback())
    	return 
	end
    dir.y = 0
    dir = dir:Normalize()
    if not self._IsReady then
        self._InitDir = dir
        return
    end
    GameUtil.AddTurnBehavior(self._GameObject, dir, speed, nil, false, 0)
end

def.override("boolean").OnBattleTopChange = function(self, isShow)
    -- warn("OnBattleTopChange "..tostring(isShow)..tostring(self:IsVisible())..","..debug.traceback())

    if self._TopPate ~= nil then
        isShow = isShow and self:IsVisible() and not self:IsDead()

        --local is_first = not self._TopPate._IsContentValid
        if isShow then
            self._TopPate:MarkAsValid(true)
        end
        self._TopPate:SetVisible(isShow)

        if isShow and not self._IsTopPateShown then
            self._IsTopPateShown = true
            self._TopPate:SetHPLineIsShow(true, EnumDef.HPColorType.Red)
            self._TopPate:SetStaLineIsShow(self._InfoData._MaxStamina > 0)
            self._TopPate:UpdateName(true)
            self._TopPate:OnTitleNameChange(true, self:GetTitle())
        end
    end
end

def.override("=>", "string").GetModelPath = function (self)
	return self._MonsterTemplate.ModelAssetPath
end

def.virtual().InitProgressCountMax = function(self)
	if self:HasMutipleProgress() then
		local CSpecialIdMan = require  "Data.CSpecialIdMan"
		local str = CSpecialIdMan.Get("MutipleProgressCountRule")
		local infoList = string.split(str, "*")
		local lv = self:GetLevel()
		local index = math.floor(math.clamp(lv,10,lv)/10) % 10

		if #infoList >= index then
			self._ProgressCountMax = tonumber(infoList[index])
		else
			self._ProgressCountMax = 1
		end
	else
		self._ProgressCountMax = 1
	end
end

def.virtual("=>", "number").GetProgressCountMax = function(self)
	return self._ProgressCountMax
end

def.override("=>", "number").GetTemplateId = function(self)
	if self._MonsterTemplate ~= nil then
		return self._MonsterTemplate.Id
	else
		warn("can not get monster's tid")
		return 0
	end
end

def.override("number").SetRadius = function(self, radius)
	self._CollisionRadius = radius * self._MonsterTemplate.BodyScale

    local model = self:GetCurModel()
    if model ~= nil then
        local go = model:GetGameObject()
        if not IsNil(go) then
            GameUtil.SetEntityColliderRadius(go, radius)
        end
    end
end

-- 使用字段值，不使用静态模版值
-- def.override("=>", "number").GetRadius = function(self)
--     return self._MonsterTemplate.CollisionRadius * self._MonsterTemplate.BodyScale
-- end

def.override("=>", "number").GetEntityBodyScale = function(self)	
    return self._MonsterTemplate.BodyScale
end

-- 溶解自己
local param = {r = 255, g = 225, b = 40, a = 255}
def.method("number").DoDissolve = function(self, dissolveEffectduration)
	if self._DissolveDeathTimer > 0 then return end

	local delayTime = self:GetAnimationLength(EnumDef.CLIP.COMMON_DIE) + 3
	self._DissolveDeathTimer = self:AddTimer(delayTime, true, function()
			CVisualEffectMan.DissolveDie(self, dissolveEffectduration, param.r, param.g, param.b) 
			self._DissolveDeathTimer = self:AddTimer(dissolveEffectduration, true, function()
		        	if self:IsReleased() then return end
					self._DissolveDeathTimer = 0
					local model = self:GetCurModel()
					if model and model._GameObject then
						model._GameObject:SetActive(false)
					end
		    	end)
    	end)	
end

def.override().OnClick = function (self)
	if not self:CanHostNaviTo() and not game:IsInBeginnerDungeon() then return end -- 不可到达且不在新手副本

	CNonPlayerCreature.OnClick(self)

	if DebugTools.EnableEntityInfoDebug then
		local C2SGetMonsterDebugInfo = require "PB.net".C2SGetMonsterDebugInfo
		local protocol = C2SGetMonsterDebugInfo()
		protocol.entityId = self._ID
		local PBHelper = require "Network.PBHelper"
		PBHelper.Send(protocol)		
	end
end

def.override("number", "table").OnPhysicsTriggerEvent = function (self, attacker_id, hitpos)
	local attacker = game._CurWorld:FindObject(attacker_id)

	if attacker ~= nil and attacker._SkillHdl ~= nil and attacker._SkillHdl._JudgeParams ~= nil then
		local params = attacker._SkillHdl._JudgeParams

		-- 顿帧
		if params.BluntTime > 0 and attacker:IsHostPlayer() then
			local bluntTime = params.BluntTime/1000
			local speed = attacker:BluntCurAnimation(bluntTime, true)
			GameUtil.BluntAttachedFxs(attacker:GetGameObject(), bluntTime, speed)
		end

		self:OnBeHitted(attacker, params.HitGfx, hitpos, true)
	end
end


def.override().PlayHurtAnimation = function(self)
    if not self._IsReady or self:IsDead() then return end 
    --技能过程中不播受伤动作
    local cur_state = self:GetCurStateType()
    if cur_state == FSM_STATE_TYPE.SKILL or cur_state == FSM_STATE_TYPE.BE_CONTROLLED then return end

    local model = self:GetCurModel()
    local addtive = nil
    if cur_state == FSM_STATE_TYPE.IDLE then
        addtive = false
    elseif cur_state == FSM_STATE_TYPE.MOVE then
        addtive = true
    end

    if addtive == nil then 
        return 
    end

    if self:IsMagicControled() then
        return 
    end
 
    -- 大型和巨型 不播放挨打动作 EMonsterBodySize.BODYSIZE_HUGE = 3
    if not (self._MonsterTemplate.BodySize == EnumDef.EMonsterBodySize.BODYSIZE_HUGE ) then
	    model:PlayHurtAnimation(addtive, self:GetHurtAnimation()) 
	end
	CSoundMan.Instance():Play3DAudio(self:GetAudioResPathByType(EnumDef.EntityAudioType.HurtAudio), self:GetPos(), 0)
end

def.override().OnModelLoaded = function(self)
	CNonPlayerCreature.OnModelLoaded(self)
	--self:OnQuestStatusChange()
	self:ListenToQuestChangeEvent()
	self:SetEliteColor()

	--关闭castShadow
	self:EnableCastShadows(false)
	
	self:EnableShadow(self._MonsterTemplate.IsShowShadow)
end

def.override("=>", "number").GetObjectType = function (self)
    return OBJ_TYPE.MONSTER
end


def.method().SetEliteColor = function(self)
	if self._MonsterTemplate.MonsterQuality == EnumDef.MonsterQuality.ELITE then
		CVisualEffectMan.EliteBornColor(self, 30/255, 130/255, 220/255, 3) 	
	end
end


def.override("=>", "number").GetFaction = function(self)
    return self._MonsterTemplate.FactionId
end

def.override("=>", "number").GetReputation = function(self)
    return self._MonsterTemplate.ReputationId
end


def.override("boolean", "boolean", "number", "boolean", "boolean").UpdateCombatState = function(self, is_in_combat_state, is_client_state, origin_id, ignore_lerp, delay)
	if is_client_state then return end

	self._IsInCombatState = is_in_combat_state

	local cur_state = self:GetCurStateType()
	if cur_state == FSM_STATE_TYPE.IDLE then
		self:Stand()
	end
	if not self._IsInCombatState then
		self._SkillHdl:StopGfxPlay(EnumDef.EntityGfxClearType.BackToPeace)
	end
end

def.override("number", "number", "number", "boolean").OnDie = function (self, killer_id, element_type, hit_type, play_ani)
	CEntity.OnDie(self, killer_id, element_type, hit_type, play_ani)

	if self._SkillHdl ~= nil then
		self._SkillHdl:StopSkillIndicatorGfx()
	end

	-- 延迟3 + ANIMATION 时间 做溶解销毁
	self:DoDissolve(3)
	-- 怪物NPC死亡后 头部信息消失，
	if self._TopPate ~= nil then
		self._TopPate:SetVisible(false)
		self._TopPate:MarkAsValid(false)
		--self._IsTopPateShown = false
	end

	local go = self:GetGameObject()
	if not IsNil(go) then
		GameUtil.SetLayerRecursively( go, EnumDef.RenderLayer.Unblockable)
	end
end

def.method("=>", "string").GetPropertyString = function(self)
	local MonsterPropertyId = self._MonsterTemplate.MonsterGenus
	if MonsterPropertyId > 0 then
    	return StringTable.Get(1200+MonsterPropertyId)
    end

    return StringTable.Get(1199)
end

def.override().OnQuestStatusChange = function(self)
    if self._TopPate ~= nil then
        local CQuest = require "Quest.CQuest"
        if CQuest.Instance():IsMyKillTarget(self:GetTemplateId()) and self._CurLogoType ~= EnumDef.EntityLogoType.Kill then
            self:OnBattleTopChange(true)
            self._TopPate:OnLogoChange(EnumDef.EntityLogoType.Kill)
        end
    end
end

def.override("boolean", "number", "number", "number", "table").UpdateState = function(self, add, state_id, duration, originId, info)
    CEntity.UpdateState(self, add, state_id, duration, originId, info) 

	local CPageMonsterHead = require "GUI.CPageMonsterHead"
    CPageMonsterHead.Instance():TriggerPoZhanState(add, state_id, originId)
	local curLogoType = EnumDef.EntityLogoType.None

    --判断是否有破绽
    local dest_state_id = tonumber(CElementData.GetSpecialIdTemplate(93).Value)
    if dest_state_id == state_id then 
		if add then 
			self:UpdateTopPateCombatTip(EnumDef.EntityFightType.ENTER_WEAK_POINT,-1)
			if self._TopPate ~= nil then
				curLogoType = EnumDef.EntityLogoType.InWeakPoint
		
				if self._CurLogoType ~= curLogoType then
					self._TopPate:OnLogoChange(curLogoType)
				end
			end
	    else
			self:UpdateTopPateCombatTip(EnumDef.EntityFightType.None,-1)
			if self._TopPate ~= nil then
				self._TopPate:OnLogoChange(EnumDef.EntityLogoType.None)
			end
		end
	end

	-- 进入狂暴状态
	local violent_id = tonumber(CElementData.GetSpecialIdTemplate(437).Value)
	if violent_id == state_id then 
		if add then 
			if self._TopPate ~= nil then
				curLogoType = EnumDef.EntityLogoType.InViolent
				if self._CurLogoType ~= curLogoType then
					self._TopPate:OnLogoChange(curLogoType)
				end
			end
	    else
			if self._TopPate ~= nil then
				self._TopPate:OnLogoChange(EnumDef.EntityLogoType.None)
			end
		end
	end
end

def.override("=>", "boolean").IsMonster = function (self)
    return true 
end

def.override("table", "boolean").UpdateFightProperty = function(self, properties, isNotifyFightScore)
	CEntity.UpdateFightProperty(self, properties, isNotifyFightScore)

	self:UpdateTopPate(EnumDef.PateChangeType.HP)
	if self._TopPate ~= nil and self._InfoData._MaxStamina > 0 then
		self._TopPate:OnStaChange(self._InfoData._CurrentStamina / self._InfoData._MaxStamina)
	end
end

def.override("table", "boolean").UpdateFightProperty_Simple = function(self, properties, isNotifyFightScore)
	self:UpdateFightProperty(properties, isNotifyFightScore)
end

def.method("number").UpdateFightState = function (self,fightState)
 	self:UpdateTopPateCombatTip(fightState,tonumber(CElementData.GetSpecialIdTemplate(216).Value))
end

def.method("number","number").UpdateTopPateCombatTip = function (self,fightState,time)
	if self._TopPate == nil or self._MonsterTemplate.NotShowTip then return end

	if fightState == EnumDef.EntityFightType.None then 
		self._TopPate:CombatTipChange(EnumDef.EntityFightType.None,time)
	else
    	self._TopPate:CombatTipChange(EnumDef.EntityLogoType.Max + fightState,time)
    end
end

def.override("=>", "boolean").IsNeedHideHpBarAndName = function(self)
    return self._MonsterTemplate.BirthHideHpBarAndName
end


def.override("=>", "string").GetRelationWithHost = function(self)  -- 仇恨列表 > 队伍 > 阵营 > 公会 > PK关系 
	-- 阵营 势力关系判断
	local relation, IsZYFriend = CEntity.GetRelationWith(self, game._HostPlayer)
	local CTeamMan = require "Team.CTeamMan"
	local hostPlayerID = game._HostPlayer._ID
	local TeamList = CTeamMan.Instance():GetMemberList()
	if self._InfoData ~= nil and self._InfoData._CreaterId > 0 then
		if((TeamList ~= nil) and (table.nums(TeamList) > 0)) then
			for i,teamMemeber in pairs(TeamList) do 
				if teamMemeber ~= nil then
					if(teamMemeber._ID == self._InfoData._CreaterId) then
						relation = RelationDesc[2]
						return relation
					end			
				end
			end
		else
			if hostPlayerID == self._InfoData._CreaterId then
				relation = RelationDesc[2]
				return relation
			else
				relation = RelationDesc[1]
				return relation
			end
		end
	end	
    return relation
end

def.override().Release = function (self)
	--warn(self._ID, "CMonster Release ")	
	if self._DissolveDeathTimer ~= 0 then
		self:RemoveTimer(self._DissolveDeathTimer)
		self._DissolveDeathTimer = 0		
	end
	CEntity.Release(self) 
end

CMonster.Commit()
return CMonster
