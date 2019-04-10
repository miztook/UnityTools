local Lplus = require "Lplus"
local CSkillEventBase = require "Skill.SkillEvent.CSkillEventBase"
local CEntity = require "Object.CEntity"
local ExecutionUnit = require "PB.Template".ExecutionUnit
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE

local CJudgementEvent = Lplus.Extend(CSkillEventBase, "CJudgementEvent")
local def = CJudgementEvent.define

def.field("table")._VictimsId = BlankTable
def.field("number")._GroupId = 0
def.field("number")._TotalCount = 0
def.field("number")._IndexInGroup = 0
def.field("number")._Interval = 0

def.static("table", "table", "=>", CJudgementEvent).new = function(event, params)
	local ETriggerJudgementType = ExecutionUnit.ExecutionUnitTrigger.TriggerJudgement.ETriggerJudgementType
	if event.Judgement.JudgementType ~= ETriggerJudgementType.Damage then 
		return nil 
	end

	local obj = CJudgementEvent()
	obj._Event = event.Judgement
	obj._Params = params
	return obj
end

local CameraShakeParams =
	{
		-- [lv] = { FadeinDuration, FadeoutDuration, KeepMaxDuration, Magnitude, Roughness}
		[1] = {0, 100, 100, 0.1, 10},
		[2] = {0, 100, 100, 0.3, 10},
		[3] = {0, 100, 100, 0.5, 10},
	}


local function GetSkillIgnoreObstacle(caster)
	if caster._SkillHdl then
		local ActiveSkill = caster._SkillHdl._ActiveCommonSkill
		if ActiveSkill then
			local skill = ActiveSkill._Skill
			if skill and skill.IgnoreObstacle ~= nil then
				return skill.IgnoreObstacle
			end
		end
	end	
end

-- 主角在鹰眼
local function IsHostCasterInHawkEye(caster)
	return (caster ~= nil and caster:IsHostPlayer() and caster:GetHawkEyeState())
end

local function ProcessHitted(caster, event, entity)
	local casterPos = caster:GetPos()
	-- 不无视阻挡  不直线可达 						
	if GetSkillIgnoreObstacle(caster) == false and not GameUtil.PathFindingIsConnected(casterPos, entity:GetPos()) then
		return
	end

	local JudgementHitAnimationPlayType = ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitAnimationPlayType
	local playHurt = (event.HitAnimationPlayType ~= JudgementHitAnimationPlayType.DoNotPlay)
	-- 鹰眼 主角
	if IsHostCasterInHawkEye(caster) then
		-- 敌方是怪物 且是鹰眼怪物 播出特效
		if entity:GetObjectType() == OBJ_TYPE.MONSTER and entity._MonsterTemplate.IsHawkEye then
			entity:OnBeHitted(caster, event.HitGfxActorId, event.HitPos, playHurt)
		end								
	else
		entity:OnBeHitted(caster, event.HitGfxActorId, event.HitPos, playHurt)
	end
end

local function GetJudgementCount(self, caster, entityId, groupId)
	if caster == nil or caster._SkillHdl == nil then return 0 end
	local group = caster._SkillHdl._JudgementEventsGroup[groupId]
	if group == nil then return 0 end

	local count = 0
	for i, v in ipairs(group) do
		for _, v1 in ipairs(v._VictimsId) do
			if v1 == entityId then
				count = count + 1
			end	
		end
	end

	return count
end

local function VictimHitPreJudge(self, caster, event, victims)
	if event.HitGfxActorId ~= 0 then
		local isJudgeCountLimit = event.SingleJudgementCount and (self._GroupId > 0)
		for i,v in ipairs(victims) do
			if isJudgeCountLimit then
				local judgeCount = GetJudgementCount(self, caster, v._ID, self._GroupId)
				if judgeCount <= event.SingleJudgementCount then 
					ProcessHitted(caster, event, v)
				end
				
				-- 最后一个tag event 执行过做清理
				if self._IndexInGroup == self._TotalCount then
					caster._SkillHdl._JudgementEventsGroup[self._GroupId] = nil
				end
			else
				ProcessHitted(caster, event, v)	
			end
		end
	end
end

local function GenerateVictimData(self, caster, battle_man, event, director)
	local victims = nil
	if caster ~= nil then
		local posX, posY, posZ = caster:GetPosXYZ()
		local dirX
		local dirY
		local dirZ
		if not director then
			dirX, dirY, dirZ = caster:GetDirXYZ()
		else
			dirX = director.x
			dirY = director.y
			dirZ = director.z
		end
		victims = battle_man:FilterVictim(caster._ID, event, posX, posY, posZ, dirX, dirY, dirZ)			
	end

	if victims == nil then return nil end

	-- 维护一张受击者表
	for k,v in ipairs(victims) do
		table.insert(self._VictimsId, v._ID)
	end

	return victims
end

def.method("number", "number", "number", "number").AddJudgementInfo = function(self, id, index, total, interval)
	self._GroupId = id
	self._IndexInGroup = index
	self._Interval = interval
	self._TotalCount = total
end

def.override().OnEvent = function(self)
	local caster = self._Params.BelongedCreature
	local event = self._Event
	local battle_man = require "LocalServer.CBattleServer".Instance()
	
	-- 旋转判定 策划规定和循环一起用
	local dir = nil
	if event.RotationAngle ~= 0 then
		local angle_speed = event.RotationAngle / event.RotationDurationTimeMS
		local index = self._IndexInGroup - 1
		if index < 0 then index = 0 end
		local face_angle = event.InitialOffsetAngle + index * angle_speed * self._Interval
		dir = GameUtil.RotateByAngle(face_angle, caster:GetGameObject())
	end
	local victims = GenerateVictimData(self, caster, battle_man, event, dir)

	-- 效果相关 不应该和 旋转判定相关
	if caster:IsHostPlayer() then
		-- 顿帧
		if event.BluntTime > 0 and #self._VictimsId > 0 then
			local bluntTime = event.BluntTime/1000
			local speed = caster:BluntCurAnimation(bluntTime, true)
			GameUtil.BluntAttachedFxs(caster:GetGameObject(), bluntTime, speed)
		end

		local p = CameraShakeParams[event.CameraShakeIntensity]
		if p ~= nil and #self._VictimsId > 0 then
			local CVisualEffectMan = require "Effects.CVisualEffectMan"
			CVisualEffectMan.ShakeCamera(p[1]/1000, p[2]/1000, p[3]/1000, p[4], p[5], "judge")
		end
	end

	-- 执行客户端受击等 预判播放特效和动作
	VictimHitPreJudge(self, caster, event, victims)
	
	local _, performId = caster._SkillHdl:GetCurSkillInfo()
	if performId then
		if caster._SkillHdl._ClientCalcVictims == nil then
			caster._SkillHdl._ClientCalcVictims = {}
		end
		caster._SkillHdl._ClientCalcVictims[performId] = victims
	end
end

def.override("number", "=>", "boolean").OnRelease = function(self, ctype)
	if self._GroupId > 0 then
		local caster = self._Params.BelongedCreature
		caster._SkillHdl._JudgementEventsGroup[self._GroupId] = nil
	end

	CSkillEventBase.OnRelease(self, ctype)
	return true
end

CJudgementEvent.Commit()
return CJudgementEvent
