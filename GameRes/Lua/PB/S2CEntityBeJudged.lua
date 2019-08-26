local PBHelper = require "Network.PBHelper"
local JudgementHitAnimationPlayType = require "PB.Template".ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementHitAnimationPlayType
local ECHAT_CHANNEL_ENUM = require "PB.data".ChatChannel
local ChatManager = require "Chat.ChatManager"

-- 获得血量变化发送战斗消息提示
local function SendMsgToCombatChannel(entity, attacker, HpDamage, isTreatment)
	if attacker == nil then return nil end

	local chatContent = nil
	if attacker:IsHostPlayer() then
		if not isTreatment then
			chatContent = string.format(StringTable.Get(13039),entity._InfoData._Name, GUITools.FormatNumber(HpDamage))
		else
			chatContent = string.format(StringTable.Get(13040), GUITools.FormatNumber(HpDamage))
		end
	else
		if not isTreatment then
			chatContent = string.format(StringTable.Get(13042), attacker._InfoData._Name, GUITools.FormatNumber(HpDamage))
		else
			chatContent = string.format(StringTable.Get(13041), attacker._InfoData._Name, GUITools.FormatNumber(HpDamage))
		end
	end
	if chatContent ~= nil then
		ChatManager.Instance():ClientSendMsg(ECHAT_CHANNEL_ENUM.ChatChannelCombat, chatContent, false, 0, nil,nil)
	end
end

local function play_hurt_animation(entity, attacker, protocol)
	--local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil or (not entity:IsModelLoaded()) then return end

	if attacker ~= nil then			
		local client_not_calc = true
		local client_calc_victims = attacker._SkillHdl._ClientCalcVictims
		
		if not attacker:IsHostPlayer() then
			entity:OnBeHitted(attacker, protocol.HitActorId, protocol.HitGfxPosition, protocol.HitAnimationPlayType ~= JudgementHitAnimationPlayType.DoNotPlay)
		else
			if client_calc_victims and client_calc_victims[protocol.PerformId] ~= nil then
				local victims = client_calc_victims[protocol.PerformId]
				for i,v in ipairs(victims) do
					if v._ID == protocol.EntityId then
						client_not_calc = false
						break
					end
				end
			end

			if client_not_calc then 
				entity:OnBeHitted(attacker, protocol.HitActorId, protocol.HitGfxPosition, protocol.HitAnimationPlayType ~= JudgementHitAnimationPlayType.DoNotPlay)
			end
		end

		if client_calc_victims then
			client_calc_victims[protocol.PerformId] = nil
		end
	end
end

local function ChangeHateList (attacker, entity)	
	-- 判断仇恨列表中是否已经存在
	local hp = game._HostPlayer
	if hp == nil then return end
	if attacker == nil or entity == nil then return end
	
	local HateEntityId = 0
	local TargetEntity = nil
	if attacker:IsHostPlayer() then
		HateEntityId = entity._ID
		TargetEntity = entity
	elseif entity:IsHostPlayer() then
		HateEntityId = attacker._ID
		TargetEntity = attacker
	end
	-- 怪物死亡不需要加到仇恨列表里。
	if attacker:IsDead() or entity:IsDead() then return end
	local index = table.indexof(hp._HatedEntityMap, HateEntityId)
	if not index then -- 如果没有对应的id就添加
		table.insert(hp._HatedEntityMap, HateEntityId)		
		game:UpdateCameraLockState(HateEntityId, true)
		if hp._IsTargetLocked == false then
			hp:UpdateTargetInfo(TargetEntity, true)
		end
	end

	local UpdateEntity = game._CurWorld:FindObject(HateEntityId)
	if UpdateEntity == nil then return end

	if UpdateEntity:IsRole() then  -- 仇恨值变化只需要刷新名字颜色
		if not UpdateEntity:IsHostPlayer() then
			UpdateEntity:SetPKMode(UpdateEntity:GetPkMode())
		end
		if UpdateEntity._TopPate ~= nil then
			UpdateEntity:UpdateTopPate(EnumDef.PateChangeType.HPLine)
			UpdateEntity._TopPate:UpdateName(true)
			UpdateEntity:UpdatePetName()
		end
	else
		UpdateEntity:OnBattleTopChange(true)
	end
end

local function ProcessOneEntityBeJudged(protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then return end

	if not entity:IsCullingVisible() 
		or (game._IsInWorldBoss and not entity:IsHostPlayer() and math.random(1, 10) > 5) then
		if protocol.HpDamage > 0 then
			entity:OnHPChange_Simple(-protocol.HpDamage, -1)
		end
		return
	end

	local attacker = game._CurWorld:FindObject(protocol.OriginId)
	-- 控制状态
	local controlledInfo = protocol.ControlledInfo
	if controlledInfo ~= nil and controlledInfo.ControlType ~= 0 and entity._HitEffectInfo ~= nil then
		entity:InterruptSkill(false)
		entity:StopMovementLogic()
		if entity:IsHostPlayer() then 
			entity:SetAutoPathFlag(false)
		end
		play_hurt_animation(entity, attacker, protocol)
		local hiteffect = entity._HitEffectInfo
		local hit_params = {controlledInfo.Param1, controlledInfo.Param2, controlledInfo.Param3}
		hiteffect:ChangeEffect(attacker, controlledInfo.ControlType, hit_params, controlledInfo.MovedDest)
	else
		play_hurt_animation(entity, attacker, protocol)
	end
	
	if protocol.HpDamage > 0 then
		if (attacker ~= nil and attacker:IsHostPlayer()) or entity:IsHostPlayer() then 
			SendMsgToCombatChannel(entity, attacker, protocol.HpDamage, false)
			ChangeHateList(attacker, entity)
		end
		
		-- 掉血、冒字
		entity:OnHPChange(-protocol.HpDamage, -1)
		entity:OnHurt(protocol.HpDamage, protocol.OriginId, protocol.CriticalHit, protocol.ElementType)
	end
end

local function OnEntityBeJudged(sender, protocol)
	ProcessOneEntityBeJudged(protocol)

	if protocol.ProtoList ~= nil then
		for i,v in ipairs(protocol.ProtoList) do
			ProcessOneEntityBeJudged(v)
		end
	end
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
		entity:AddMagicControl(protocol.EffectControlType)
		--战斗状态控制应该走专门的协议 added by lj
		--entity:UpdateCombatState(entity._IsInCombatState, true, protocol.ControlTime, 0, true)
	-- 删除状态
	else 
		entity:RemoveMagicControl(protocol.EffectControlType)
		-- 受控结束清除 缓存动作
		if entity:IsHostPlayer() then
			entity:CancelCachedAction() 
		end
	end
end

PBHelper.AddHandler("S2CEntityBeEffectControlled", OnEntityBeEffectControlled) 

local PBHelper = require "Network.PBHelper"
local function OnEntityBeHealed(sender, protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity == nil then return end
	local currentHp = entity._InfoData._CurrentHp + protocol.HpHealed
	entity:OnHPChange(currentHp, -1)

	if entity:IsHostPlayer() then
		local attacker = game._CurWorld:FindObject(protocol.OriginId)
		if (attacker ~= nil and attacker:IsHostPlayer()) or entity:IsHostPlayer() then 
			SendMsgToCombatChannel(entity, attacker, protocol.HpHealed, true)
		end
	end

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

	if protocol.HpDamage > 0 then
		local attacker = game._CurWorld:FindObject(protocol.OriginId)
		if (attacker ~= nil and attacker:IsHostPlayer()) or entity:IsHostPlayer() then 
			SendMsgToCombatChannel(entity, attacker, protocol.HpDamage, false)
			ChangeHateList(attacker, entity)
		end
		entity:OnHPChange(-protocol.HpDamage, -1)	
		entity:OnHurt(protocol.HpDamage, protocol.OriginId, protocol.CriticalHit, protocol.ElementType)
	end
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

	local attackStr = string.format("攻击方: %d 最终攻击力：%f 技能ID：%d 生效元素：%d 该元素数值：%f 最终暴击率：%f 暴伤百分比: %f 最终追击几率：%f 最终精通几率：%f 基础加成：%f 最终加成：%f 元素穿透：%f 护甲穿透：%f BuffIds: %s  元素伤害加成比例: %f 治疗加成比例: %f 攻击方的破盾概率: %f", 
		protocol.AttackEntityId , protocol.FinalAttack, protocol.SkillId, protocol.ElementType, protocol.ElementValue, protocol.FinalCriticalRate,
		 protocol.FinalDamageRate, protocol.FinalChaseRate, protocol.FinalMasterRate, protocol.BaseAdditionRate, protocol.FinalAdditionRate , 
		 protocol.ElementPenetration, protocol.ArmerPenetration ,attackBuffIds, protocol.ElementDamageAdditionRatio, protocol.HealRate, protocol.BrokenShieldRate)
	local beattackedStr = string.format("防守方: %d 最终防御力：%f 对应元素抗性：%d 最终抗暴率：%f 最终格挡几率：%f 基础减免：%f 最终减免：%f 格挡伤害百分比: %f 玩家身上BUFFID：%s ", 
		protocol.BeAttackedEntityId , protocol.BeAttackedDefense , protocol.BeAttackedElementDefense , protocol.BeAttackedFinalImmuneRate , protocol.BeAttackedFinalBlockRate ,
		 protocol.BeAttackedBaseReduceRate , protocol.BeAttackedFinalReduceRate , protocol.BeAttackedBlockDamageRate, beattackedBuffIds )
	local isStr = string.format("是否暴击:%s 是否格挡:%s 是否精通:%s 最终伤害:%f  是否追击:%s  追击伤害:%f, 技能伤害绝对值:%f, 技能伤害百分比:%f, 技能随机值:%f",  
		tostring(protocol.IsCritical) , tostring(protocol.IsBlock) , tostring(protocol.IsMaster) , protocol.FinalDamage , tostring(protocol.IsChase) , protocol.ChaseDamage ,
		protocol.DamageAbsolute, protocol.DamagePercent, protocol.RandomFactor )

	local Str1 = string.format("玩家伤害增加百分比:%f 玩家伤害减少百分比:%f 暴击伤害减免百分:%f 目标玩家伤害增加:%f 目标玩家伤害减少百分比:%f  目标暴击伤害减免百分比:%f",
		protocol.PvpDamageAdditionRate , protocol.PvpDamageReduceRate , protocol.CriticalDamageReduceRate , protocol.BePvpDamageAdditionRate , protocol.BePvpDamageReduceRate , protocol.BeCriticalDamageReduceRate )
	
	warn(attackStr)
	warn(beattackedStr)
	warn(isStr)
	warn(Str1)
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
local function ProcessOneEntityBaseStateMsg(protocol)
	local entity = game._CurWorld:FindObject(protocol.EntityId) 
	if entity and entity:IsCullingVisible() then
		entity:UpdateSealInfo(protocol.BaseStates)
	end
end

local function OnS2CEntityBaseState(sender, protocol)
	ProcessOneEntityBaseStateMsg(protocol)
	if protocol.ProtoList ~= nil then
		for i,v in ipairs(protocol.ProtoList) do
			ProcessOneEntityBaseStateMsg(v)
		end
	end
end
PBHelper.AddHandler("S2CEntityBaseState", OnS2CEntityBaseState)

local function OnS2CDebugShowStates(sender, protocol)
	local prefix = "EntityId: " .. protocol.EntityId
	local buffIdStr = ""
	local hasStates = false
	for i,v in ipairs(protocol.DebugStateInfos) do
		buffIdStr = buffIdStr .. " " .. v.StateId .. ","
		hasStates = true
	end
	if hasStates then
		warn(prefix, "当前的状态：",buffIdStr)
	else
		warn(prefix, "当前没有状态")
	end
end
PBHelper.AddHandler("S2CDebugShowStates", OnS2CDebugShowStates)


