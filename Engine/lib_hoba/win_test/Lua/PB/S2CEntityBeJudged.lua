local PBHelper = require "Network.PBHelper"
local JudgementHitAnimationPlayType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitAnimationPlayType

local function OnEntityBeJudged(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then return end

	local attacker = game._CurWorld:FindObject(protocol.OriginId)

	local function play_hurt_animation()
		if attacker ~= nil then
			local is_other_attacker = not attacker:IsHostPlayer()
			local client_not_calc = true
			if not is_other_attacker and attacker._SkillHdl._ClientCalcVictims ~= nil then
			local victims = attacker._SkillHdl._ClientCalcVictims
				for i,v in ipairs(victims) do
					if v._ID == protocol.EntityId then
						client_not_calc = false
						break
					end
				end
			end

			if is_other_attacker or client_not_calc then
				if protocol.HitAnimationPlayType == JudgementHitAnimationPlayType.DoNotPlay then
					entity:PlayEntityGfx(protocol.HitActorId, protocol.HitGfxPosition)
				else
					entity:OnBeHitted(attacker, protocol.HitActorId, protocol.HitGfxPosition)
				end
			end
		end
	end


	-- 控制状态
	local controlledInfo = protocol.ControlledInfo
	if controlledInfo ~= nil and controlledInfo.ControlType ~= 0 and entity._HitEffectInfo ~= nil then
		if entity._SkillHdl ~= nil then entity._SkillHdl:OnSkillInterruptted() end
		entity:StopMovementLogic()
		play_hurt_animation()
		local hiteffect = entity._HitEffectInfo
		local hit_params = {controlledInfo.Param1, controlledInfo.Param2, controlledInfo.Param3}
		hiteffect:ChangeEffect(attacker, controlledInfo.ControlType, hit_params, controlledInfo.MovedDest)
	else
		play_hurt_animation()
	end

	-- 掉血、冒字
	entity:OnHPChange(-protocol.HpDamage, -1)
	entity:OnHurt(protocol.HpDamage, protocol.OriginId, protocol.CriticalHit)
end

PBHelper.AddHandler("S2CEntityBeJudged", OnEntityBeJudged)

-- 单纯魔法控制
-- required int32 EntityId
-- required int32 EffectControlType
-- required bool  IsAdd
-- optional int32 ControlTime
local function OnEntityBeEffectControlled(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then
		warn("error occur in OnEntityBeEffectControlled entity not exist ")
		return
	end
	-- 添加状态
	if protocol.IsAdd then	
		entity:UpdateMagicControl(protocol.EffectControlType)
	-- 删除状态
	else 
		entity:RemoveMagicControl(protocol.EffectControlType)
		-- 受控结束清除 缓存动作
		if entity:IsHostPlayer() then
			entity._CachedAction = nil 
		end
	end
	-- 刷新状态 写死
	entity:RefreshMagicControl(9999)
end

PBHelper.AddHandler("S2CEntityBeEffectControlled", OnEntityBeEffectControlled) 

local PBHelper = require "Network.PBHelper"
local function OnEntityBeHealed(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then return end
	local currentHp = entity._InfoData._CurrentHp + protocol.HpHealed
	entity:OnHPChange(currentHp, -1)

	local heal_type = 0
	local HEALED_TYPE = require "PB.net".HEALED_TYPE
	if protocol.SrcType == HEALED_TYPE.AUTO then
		heal_type = EnumDef.HUDType.hitrecoverey
	elseif protocol.SrcType == HEALED_TYPE.SKILL then
		heal_type = EnumDef.HUDType.heal
	elseif protocol.SrcType == HEALED_TYPE.BUFF then
		heal_type = EnumDef.HUDType.heal
	end
	entity:OnHealed(heal_type, protocol.HpHealed)
end
PBHelper.AddHandler("S2CEntityBeHealed", OnEntityBeHealed)

local function OnEntityDamage(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then return end
	entity:OnHPChange(-protocol.HpDamage, -1)	
	entity:OnHurt(-protocol.HpDamage, protocol.OriginId, protocol.CriticalHit)
end

PBHelper.AddHandler("S2CEntityDamage", OnEntityDamage)

local function OnDamageLog(sender, protocol)

	local attackBuffIds = ""
	for i,v in ipairs(protocol.BuffIds) do
		attackBuffIds = attackBuffIds .. " " .. v .. ","
	end

	local beattackedBuffIds = ""
	for i,v in ipairs(protocol.BeAttackedBuffIds) do
		beattackedBuffIds = beattackedBuffIds .. " " .. v .. ","
	end
	warn("=============================================================")
	local attackStr = string.format("攻击方: %d 最终攻击力：%f 技能ID：%d 生效元素：%d 该元素数值：%f 最终暴击率：%f 暴伤百分比: %f 最终追击几率：%f 最终精通几率：%f 基础加成：%f 最终加成：%f 元素穿透：%f 护甲穿透：%f BuffIds: %s", 
		protocol.AttackEntityId , protocol.FinalAttack, protocol.SkillId, protocol.ElementType, protocol.ElementValue, protocol.FinalCriticalRate,
		 protocol.FinalDamageRate, protocol.FinalChaseRate, protocol.FinalMasterRate, protocol.BaseAdditionRate, protocol.FinalAdditionRate , 
		 protocol.ElementPenetration, protocol.ArmerPenetration ,attackBuffIds)
	local beattackedStr = string.format("防守方: %d 最终防御力：%f 对应元素抗性：%d 最终抗暴率：%f 最终格挡几率：%f 基础减免：%f 最终减免：%f 格挡伤害百分比: %f 玩家身上BUFFID：%s ", 
		protocol.BeAttackedEntityId , protocol.BeAttackedDefense , protocol.BeAttackedElementDefense , protocol.BeAttackedFinalImmuneRate , protocol.BeAttackedFinalBlockRate ,
		 protocol.BeAttackedBaseReduceRate , protocol.BeAttackedFinalReduceRate , protocol.BeAttackedBlockDamageRate, beattackedBuffIds )
	local isStr = string.format("是否暴击:%s 是否格挡:%s 是否精通:%s 最终伤害:%f  是否追击:%s  追击伤害:%f, 技能伤害绝对值:%f, 技能伤害百分比:%f, 技能随机值:%f",  
		tostring(protocol.IsCritical) , tostring(protocol.IsBlock) , tostring(protocol.IsMaster) , protocol.FinalDamage , tostring(protocol.IsChase) , protocol.ChaseDamage ,
		protocol.DamageAbsolute, protocol.DamagePercent, protocol.RandomFactor )

	warn(attackStr)
	warn(beattackedStr)
	warn(isStr)
end

PBHelper.AddHandler("S2CDamageLog", OnDamageLog)



local function OnS2CEntityFightFeature(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then return end

	local FIGHT_FEATURE = require "PB.net".FIGHT_FEATURE
	local features = protocol.FightFeature
	if features ~= nil and #features > 0 then
		local is_absorb = false
		local is_block = false
		for i = 1, #features do
			local f = features[i]
			if f == FIGHT_FEATURE.ABSORB then
				is_absorb = true
			elseif f == FIGHT_FEATURE.BLOCK then
				is_block = true
			end
		end
		if is_absorb then
			entity:OnAbsorb()
		elseif is_block then
			entity:OnBlock()
		end
	end
end
PBHelper.AddHandler("S2CEntityFightFeature", OnS2CEntityFightFeature)


--  基础状态 EBASE_STATE
-- 	CAN_MOVE      		是否可以移动
-- 	CAN_SKILL    		是否可以释放技能
-- 	CAN_USE_ITEM 		是否可以使用物品
-- 	CAN_BE_SELECTED		是否可以被选中
-- 	CAN_BE_ATTACKED 	是否可以被攻击

--  msg 结构
-- 	required int32 EntityId					= 2; 
-- 	repeated bool  BaseStates				= 3; //UNIT_STATE	
local function OnS2CEntityBaseState(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity then
		entity:UpdateSealInfo(protocol.BaseStates)
	else
		--warn("can not find entity, id = "..tostring(protocol.EntityId))
		return 
	end
end
PBHelper.AddHandler("S2CEntityBaseState", OnS2CEntityBaseState)


