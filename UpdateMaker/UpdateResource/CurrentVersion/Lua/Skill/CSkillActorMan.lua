local Lplus = require "Lplus"
local Template = require "PB.Template"
local CElementSkill = require "Data.CElementSkill"
local OBJ_TYPE = require "Main.CSharpEnum".OBJ_TYPE	
local CEntity = require "Object.CEntity"
local CFxObject = require "Fx.CFxObject"

local CSkillActorMan = Lplus.Class("CSkillActorMan")
local def = CSkillActorMan.define

local instance = nil
def.static("=>", CSkillActorMan).Instance = function ()
	if instance == nil then
		instance = CSkillActorMan()
	end
	return instance
end

local GFX_TYPE = 
	{
		NORMAL = 0,  -- 标准
		HIT = 1,  -- 爆点
		STATE = 2,  -- 状态
	}

local ACTOR_EVENT_TYPE = require "Skill.SkillDef".EVENT_TYPE

local EventCreateFunctions =
	{
		[ACTOR_EVENT_TYPE.GenerateActor] = require "Skill.ActorEvent.CActorGenActorEvent".new,
		[ACTOR_EVENT_TYPE.Audio] = require "Skill.ActorEvent.CActorSoundEvent".new,
		[ACTOR_EVENT_TYPE.SkillIndicator] = require "Skill.ActorEvent.CActorIndicatorEvent".new,
		[ACTOR_EVENT_TYPE.CameraShake] = require "Skill.ActorEvent.CActorCameraShakeEvent".new,
		[ACTOR_EVENT_TYPE.ActorBlur] = require "Skill.ActorEvent.CActorCameraBlurEvent".new,
	}

local function GetEventType(event)
	local event_type = 0
	if event.GenerateActor._is_present_in_parent then
		event_type = ACTOR_EVENT_TYPE.GenerateActor
	elseif event.Audio._is_present_in_parent then
		event_type = ACTOR_EVENT_TYPE.Audio
	elseif event.SkillIndicator._is_present_in_parent then
		event_type = ACTOR_EVENT_TYPE.SkillIndicator
	elseif event.CameraShake._is_present_in_parent then
		event_type = ACTOR_EVENT_TYPE.CameraShake
	elseif event.MotionBlur._is_present_in_parent then
		event_type = ACTOR_EVENT_TYPE.ActorBlur		
	end
	return event_type
end

local function MakeParams(host, subobject, target_id, gfx)
	local params = {}
	params.BelongedCreature = host
	params.BelongedSubobject = subobject 
	params.ClientActorGfx = gfx
	params.TargetId = target_id
	return params
end

local function GetColRadius(owner)
	local ret = 0.5
	if owner then
		if owner:GetObjectType() == OBJ_TYPE.MONSTER then
			ret = owner:GetRadius() / owner:GetEntityBodyScale()
		else
			ret = owner:GetRadius()
		end
	end
	return ret
end


local function CreateActorEvent(event, host, subobject, target, gfx)
	local e = nil
	local event_type = GetEventType(event)

	local create_func = EventCreateFunctions[event_type]
	if create_func ~= nil then
		local target_id = 0
		if target ~= nil then target_id = target._ID end
		local params = MakeParams(host, subobject, target_id, gfx)
		e = create_func(event, params)
	end
	return e
end

local function ProcessExecutionUnits(owner, subobject, target, execution_units, gfx)
	local host = subobject or owner	
	for _,v in ipairs(execution_units) do
		if v.Trigger.Timeline._is_present_in_parent then
			if host == nil then return end			
			host:AddTimer(v.Trigger.Timeline.StartTime/1000, true, function()
				local e = CreateActorEvent(v.Event, owner, subobject, target, gfx)
				if e ~= nil then 
					e:OnEvent() 
					-- 如果是子物体, 注册事件关联
					if subobject then
						subobject:RegistActiveEvent(e)
					end
				end
			end)
		-- 子物体不放
		elseif v.Trigger.Loop._is_present_in_parent and not subobject then
			if host == nil then return end
			for i = 1, v.Trigger.Loop.Count do
				local t = (v.Trigger.Loop.StartTime + (i-1) * v.Trigger.Loop.Interval)/1000				
				host:AddTimer(t, true, function()
						local e = CreateActorEvent(v.Event, owner, subobject, target)
						if e ~= nil then e:OnEvent() end
					end)
			end
		end
	end
end

local function GetHook(owner, target, birth_place, birth_place_param)
	local hook = nil

	local BirthPlaceType = Template.ExecutionUnit.ExecutionUnitEvent.EventGenerateActor.BirthPlaceType
	if birth_place == BirthPlaceType.Self and owner ~= nil then
		if birth_place_param ~= "" then
			hook = owner:GetHangPoint(birth_place_param)
		elseif owner ~= nil then
			hook = owner:GetGameObject()
		end
	elseif birth_place == BirthPlaceType.SkillTargetAttachPoint and target ~= nil then
		if birth_place_param ~= "" then
			hook = target:GetHangPoint(birth_place_param)
		else
			hook = target:GetGameObject()
		end
	elseif birth_place == BirthPlaceType.TargetPoint then
		return nil
	else 
		--warn("TODO: birth_place type can not find in BirthPlaceType")
	end

	if hook == nil and owner ~= nil then
		hook = owner:GetGameObject()
	end
	
	return hook
end

-- 
def.method("table", "dynamic").ExecActorUnits = function(self, template, info)
	local execution_units = template.ExecutionUnits
	if type(info) == "number" then
		local entity = game._CurWorld:FindObject(info)
		if entity then			
			ProcessExecutionUnits(entity, nil, nil, execution_units)
		end
	else
		ProcessExecutionUnits(info, nil, nil, execution_units)
	end
end

-- param.birth_place  演算体生成目标 1 自己  2 目标
-- param.birth_place_param  演算体生成骨骼名
def.method("table", "table", "=>", CFxObject).GenerateClientActor = function(self, template, param)
	if template == nil 
	 or template.Type ~= Template.Actor.ActorType.Gfx   -- 此接口仅限客户端特效
	 or template.SubType == GFX_TYPE.STATE then         -- 状态特效走 GenStateActor 接口
		return nil 
	end

	local belonged_creature = param.BelongedCreature
	local belonged_subobject = param.BelongedSubobject
	local owner = belonged_creature or belonged_subobject
	local target = game._CurWorld:FindObject(param.TargetId) or nil
	local gfx = template.GfxAssetPath
	local pos = Vector3.New(template.GfxOffsetX, template.GfxOffsetY, template.GfxOffsetZ)
	local rot = Quaternion.Euler(template.GfxRotationX, template.GfxRotationY, template.GfxRotationZ)
	local life_time = template.Lifetime/1000
	if life_time <= 0 then 
		life_time = -1 
	end

	local scale_num = template.Scale > 0 and template.Scale or 1
	if template.AutoAdjustScale and belonged_creature then
		scale_num = GetColRadius(belonged_creature) / 0.5
	end

	local gfxObj = nil
	local BirthPlaceType = Template.ExecutionUnit.ExecutionUnitEvent.EventGenerateActor.BirthPlaceType

	local priority = EnumDef.CFxPriority.Ignore
	if belonged_creature then
		priority = belonged_creature:GetCfxPriority(EnumDef.CFxSubType.ClientFx)
	end

	-- 普通特效时间以美术资源FxDuration长度为准，子物体特效以策划技能数据为准
	do
		if template.SubType == GFX_TYPE.NORMAL and owner ~= nil then
			if param.BirthPlace == BirthPlaceType.Self or param.BirthPlace == BirthPlaceType.SkillTargetAttachPoint then
				local hook = GetHook(owner, target, param.BirthPlace, param.BirthPlaceParam)
				if hook == nil then 
					return nil 
				end
				if template.FollowWithHook then						
					gfxObj = CFxMan.Instance():PlayAsChild(gfx, hook, pos, rot, life_time,  template.NotRotateAroundHook, scale_num, priority)
				else
					local position, rotation = nil, nil
					if owner:GetObjectType() == OBJ_TYPE.SUBOBJECT then
						position = owner:GetPos()
						if owner._GfxObject then
							rotation = owner._GfxObject.rotation	
						else
							rotation = Quaternion.identity
						end
					else	
						position = hook:TransformPoint(pos)							
						if owner._SkillDestDir then
							rotation = Quaternion.LookRotation(owner._SkillDestDir, Vector3.up) * rot
						else
							rotation = owner:GetGameObject().rotation * rot 
						end
					end					
					gfxObj = CFxMan.Instance():Play(gfx, position, rotation, life_time, scale_num, priority)
				end
			else
				gfxObj = CFxMan.Instance():Play(gfx, owner._SkillHdl._AttackPoint or owner:GetGameObject():TransformPoint(pos), rot, life_time, scale_num, priority)
			end
		elseif template.SubType == GFX_TYPE.HIT and target ~= nil then
			local position = target:GetPos()
			local rotation = target:GetGameObject().rotation * rot
			gfxObj = CFxMan.Instance():Play(gfx, position, rotation, life_time, scale_num, priority)
		end

		-- 状态特效不记录
		if owner._SkillHdl ~= nil and gfxObj ~= nil and template.SubType ~= GFX_TYPE.STATE then
			owner._SkillHdl._GfxList[#owner._SkillHdl._GfxList + 1] = 
				{
					StopWhenSkillInterrupted = template.DisappearConditionSkillInterrupted, 
					StopWhenPerformInterrupted = template.DisapperConditionPerformInterrupt, 
					StopWhenBackToPeace = template.DisappearConditionLeaveFighting,
					FollowWithHook = template.FollowWithHook, 
					Gfx = gfxObj,
				}
		end

		if gfxObj ~= nil then
			local execution_units = template.ExecutionUnits
			ProcessExecutionUnits(owner, nil, target, execution_units, gfxObj:GetGameObject())
		end
	end
    if owner ~= nil and gfxObj ~= nil then
        owner:AddToBelongToMeGfxTable(gfxObj)
    end
	return gfxObj  
end

-- 生成子物体 
def.method("table").GenerateSubobjectActor = function(self, subobj)
	local template = subobj._ActorTemplate  
	if template.Type ~= Template.Actor.ActorType.Subobject then 
		return 
	end

	local world = game._CurWorld
	local belonged_creature = world:FindObject(subobj._OwnerID)
	local belonged_subobject = world:FindObject(subobj._BelongedActorId) or nil
	local owner = belonged_subobject or belonged_creature   
	local target = world:FindObject(subobj._TrackId)

	local scale_num = template.Scale > 0 and template.Scale or 1
	if template.AutoAdjustScale and belonged_creature then
		scale_num = GetColRadius(belonged_creature) / 0.5
	end

	local gfxObj = nil
	local gfx = template.GfxAssetPath
	local followWithHook = false
	if gfx ~= "" then
		local pos = Vector3.New(template.GfxOffsetX, template.GfxOffsetY, template.GfxOffsetZ)
		local rot = Quaternion.Euler(template.GfxRotationX, template.GfxRotationY, template.GfxRotationZ)
		local life_time = template.Lifetime/1000
		if life_time <= 0 then life_time = -1 end
		
		local BirthPlaceType = Template.ExecutionUnit.ExecutionUnitEvent.EventGenerateActor.BirthPlaceType	
		local priority = EnumDef.CFxPriority.Ignore
		if belonged_creature then priority = belonged_creature:GetCfxPriority(EnumDef.CFxSubType.Actor) end

		local speed = template.Speed
		-- 连线
		if template.SubType == Template.Actor.SubobjectType.Chain then			
			if subobj._BirthPlace == BirthPlaceType.SkillTargetAttachPoint then
				owner = belonged_creature -- 连线只找角色
				if owner and target then
					-- 技能目标情况下, 取自身挂点. 区别于之前的技能目标挂点, 取目标的挂点
					local arcFrom = owner:GetHangPoint(subobj._BirthPlaceParam)
					local arcTo = target:GetHangPoint("HangPoint_Hurt")	 -- 目标的挂点写死	
					if arcFrom and arcTo then		 
						gfxObj = CFxMan.Instance():PlayArcFx(gfx, arcFrom, arcTo, priority)
					else
						warn("error occur to ownerTemplate.Actor.SubobjectType.Chain")
						return
					end
				end
			end
		elseif template.SubType == Template.Actor.SubobjectType.FixedPosition then
			local position = subobj._InitPos					
			local forward = subobj._InitDir
			if subobj._BirthPlace == BirthPlaceType.Self then							
				if template.FollowWithHook then
					local hook = GetHook(owner, target, subobj._BirthPlace, subobj._BirthPlaceParam)
					if hook == nil then return end
					
					gfxObj = CFxMan.Instance():PlayAsChild(gfx, hook, pos, rot, life_time, template.NotRotateAroundHook, scale_num, priority)
					followWithHook = true
				else
					if subobj._BelongedActorId then  -- 如果存在父子物体的id  使用父子物体的Y XZ还是使用服务器
						if belonged_subobject and belonged_subobject._GfxObject then -- 正常逻辑: 找到了父子物体 位置Y使用父子物体的Y位置 						
							if belonged_subobject:GetObjectType() == OBJ_TYPE.SUBOBJECT then
								local ownerTemplate = belonged_subobject._ActorTemplate
								if ownerTemplate.SubType == Template.Actor.SubobjectType.FixedFlight then -- 抛物线
									position.y = GameUtil.GetMapHeight(position)
								else
									position.y = GameUtil.GetMapHeight(position) + pos.y						
								end						
							else
								position.y = GameUtil.GetMapHeight(position) + pos.y					
							end
						else -- 异常逻辑 父子物体已经删除了使用服务器xz位置, 并修复Y轴					
							position.y = GameUtil.GetMapHeight(position) + pos.y
						end 
					else -- 不是父子物体生成, Y轴处理
						position.y = GameUtil.GetMapHeight(position) + pos.y
					end

					local rotation = Quaternion.LookRotation(forward, Vector3.up)
					gfxObj = CFxMan.Instance():Play(gfx, position, rotation, life_time, scale_num, priority)
				end	
			-- 暂时还没启用过
			elseif subobj._BirthPlace == BirthPlaceType.SkillTargetAttachPoint then						
				local hook = GetHook(owner, target, subobj._BirthPlace, subobj._BirthPlaceParam)
				if hook == nil then 
					return 
				end

				if template.FollowWithHook then
					-- 没有目标就不播放
					if not target then
						return
					end
					
					gfxObj = CFxMan.Instance():PlayAsChild(gfx, hook, pos, rot, life_time, template.NotRotateAroundHook, scale_num, priority)
					followWithHook = true
				else
					position = position + pos
					position.y = GameUtil.GetMapHeight(position)
					local rotation = Quaternion.LookRotation(forward, Vector3.up)
					gfxObj = CFxMan.Instance():Play(gfx, position , rotation, life_time, scale_num, priority)
				end
			-- 目标
			elseif subobj._BirthPlace == BirthPlaceType.TargetPoint then	
				-- 全用服务器的消息 
				position = subobj._InitPos 
				if target ~= nil then
					position.y = target:GetPos().y
				end

				if position ~= nil and owner ~= nil and not IsNil(owner:GetGameObject()) then
					position.y = GameUtil.GetMapHeight(position) + 0.1
					local rotation = Quaternion.LookRotation(forward, Vector3.up)
					gfxObj = CFxMan.Instance():Play(gfx, position, rotation, life_time, scale_num, priority)
				end
			end
		elseif template.SubType == Template.Actor.SubobjectType.StraightFlight then
			local hook = GetHook(owner, target, subobj._BirthPlace, subobj._BirthPlaceParam)
			local position = nil
			if hook == nil then 
				position = subobj._InitPos 
				position.y = GameUtil.GetMapHeight(position)
			else
				position = hook:TransformPoint(pos)
			end
			
			local dir = nil
			if target ~= nil then
				dir = (target:GetPos() - owner:GetPos()):Normalize()
			else
				dir = subobj._InitDir:Normalize()				
			end
			local fly_dir = Quaternion.Euler(0, 0, 0) * dir
			local dest = position + fly_dir * speed * life_time

			gfxObj = CFxMan.Instance():FlyAlongLine(gfx, position, dest, nil, speed, scale_num, priority)
		elseif template.SubType == Template.Actor.SubobjectType.TrackingFlight then			
			local hook = GetHook(owner, target, subobj._BirthPlace, subobj._BirthPlaceParam)
			if hook == nil then return end
			local position = hook:TransformPoint(pos)
	   		if target ~= nil and not target:IsDead() then
	   			local followTrans = GetHook(nil, target, BirthPlaceType.SkillTargetAttachPoint, "HangPoint_Hurt")
	   			if followTrans then
					gfxObj = CFxMan.Instance():FlyToTargetGameObject(gfx, position, followTrans, speed, 0, life_time, true, scale_num, priority)
				end
			else
				local dest = position + owner:GetGameObject().forward * speed * life_time
				gfxObj = CFxMan.Instance():FlyAlongLine(gfx,position, dest, nil, speed, scale_num, priority)
			end
		elseif template.SubType == Template.Actor.SubobjectType.ChainLightning then
			-- TODO:
		elseif template.SubType == Template.Actor.SubobjectType.FixedFlight then  -- 定点飞行子物体
			if owner and not owner:IsReleased() then  -- 视野外的人扔不处理
				local hud = owner:GetHangPoint(subobj._BirthPlaceParam)
				local position = nil
				if owner:IsHostPlayer() then
					position = owner._SkillHdl:GetModifiedTargetPos()
				end
				if position == nil then
					position = subobj._TargetPos
				end

				local rotation = Quaternion.LookRotation(owner:GetDir(), Vector3.up) * 	rot	
				local bullet = CFxMan.Instance():PlayBallCurvFx(gfx, position, rotation, hud, life_time, (-1*template.GfxRotationX), speed, template.CurveHeight, priority)		
				if bullet then
					subobj:SetGfxInfo(bullet, false) 
					local execution_units = template.ExecutionUnits
					ProcessExecutionUnits(owner, subobj, target, execution_units)	
				end
				return
			end
		end
	else
		--warn("---------------------------------")
	end

	do
		if gfxObj ~= nil then
			subobj:SetGfxInfo(gfxObj, followWithHook)
            if owner ~= nil then
                owner:AddToBelongToMeGfxTable(gfxObj)
            end
		end
		-- TODO: 添加actor event
		local execution_units = template.ExecutionUnits
		ProcessExecutionUnits(owner, subobj, target, execution_units)
	end
end

-- 状态特效添加
def.method("table", "table", "table", "=>", "dynamic").GenStateActor = function(self, template, param, buff)
	if buff == nil then return nil end
	if template.SubType ~= GFX_TYPE.STATE then return nil end

	local belonged_creature = param.BelongedCreature	
	local owner = belonged_creature
	local target = game._CurWorld:FindObject(param.TargetId or 0)
	local gfx = template.GfxAssetPath
	local pos = Vector3.New(template.GfxOffsetX, template.GfxOffsetY, template.GfxOffsetZ)
	local rot = Quaternion.Euler(template.GfxRotationX, template.GfxRotationY, template.GfxRotationZ)
	local life_time = template.Lifetime/1000
	if life_time <= 0 then 
		life_time = -1 
	end

	local scale_num = template.Scale > 0 and template.Scale or 1
	if template.AutoAdjustScale and belonged_creature then		
		scale_num = GetColRadius(belonged_creature) / 0.5
	end

	local priority = EnumDef.CFxPriority.Ignore
	if belonged_creature then
		priority = belonged_creature:GetCfxPriority(EnumDef.CFxSubType.ClientFx)
	end

	local gfxObj = nil

	-- 生成Gfx
	do
		local position = owner:GetPos()
		local rotation = Quaternion.identity
		local owner_h = GameUtil.GetModelHeight(owner._GameObject, true)
		local hook = owner:GetGameObject()
		local gain_h = 0
		-- 骨骼挂点优先级最高
		local EHook_Type =  require "PB.Template".Actor.EHook
		if template.HookName ~= "" then
			hook = owner:GetHangPoint(template.HookName)
			if hook ~= nil then position = hook.position end
		else
			if template.InitialHookPosition == EHook_Type.FOOT then 					
			-- 默认位置
			elseif template.InitialHookPosition == EHook_Type.HEAD then 
				gain_h = owner_h
				position.y = position.y + gain_h
			elseif template.InitialHookPosition == EHook_Type.BODY then 
				gain_h = owner_h/2
				position.y = position.y + gain_h
			end
		end

		-- 由于使用的是局部坐标, 重新组织
		if template.FollowWithHook then				
			position = pos	
			
			if template.HookName ~= "" then								
				gfxObj = CFxMan.Instance():PlayAsChild(gfx, hook, position, rot, life_time, template.NotRotateAroundHook, scale_num, priority)
			else
				position.y = position.y + gain_h					
				gfxObj = CFxMan.Instance():PlayAsChild(gfx, hook, position, rot, life_time, template.NotRotateAroundHook, scale_num, priority)
			end				
		-- 世界坐标
		else
			gfxObj = CFxMan.Instance():Play(gfx, position, rot, life_time, scale_num, priority)
		end
        if owner ~= nil and gfxObj ~= nil then
            owner:AddToBelongToMeGfxTable(gfxObj)
        end
	end
	
	-- 执行Actor事件	
	do
		local execution_units = template.ExecutionUnits
		for _,v in ipairs(execution_units) do
			if v.Trigger.Timeline._is_present_in_parent then			
				owner:AddTimer(v.Trigger.Timeline.StartTime/1000, true, function()
					local e = CreateActorEvent(v.Event, owner, nil, target)
					if e ~= nil then 
						e:OnEvent() 
						buff:RegistActiveEvent(e)
					end
				end)		
			end
		end
	end
	
	return gfxObj  
end

CSkillActorMan.Commit()
return CSkillActorMan