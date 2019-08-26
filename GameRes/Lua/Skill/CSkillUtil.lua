local Lplus = require "Lplus"
local CElementSkill = require "Data.CElementSkill"
local CElementData = require "Data.CElementData"
local ENUM_SKILLPROPERTY = require "PB.data".ENUM_SKILLPROPERTY

local CSkillUtil = Lplus.Class("CSkillUtil")
local def = CSkillUtil.define

--获取指定Id的Skill的Perform的index
local function GetSkillPerformIndex(performs, performId)
	for i, v in ipairs(performs) do
		if v.Id == performId then
			return i
		end
	end
	return -1
end


--获取指定Id的Skill的Perform的ExecutionUnit的index
local function GetSkillPerformExecutionUnitIndex(executionUnits, executionUnitId)
	for i,v in ipairs(executionUnits) do
		if v.Id == executionUnitId then
			return i
		end
	end
	warn("GetSkillPerformExecutionUnitIndex--Error:", executionUnitId)
	return -1
end

--更改技能数据
local function ChangeSkillProperty(skill, skillEnum, skillValue)
	if skillEnum == ENUM_SKILLPROPERTY.SKILL_StaminaPrecondition then
		skill.StaminaPrecondition = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_FuryPrecondition then
		skill.FuryPrecondition = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_CooldownDuration then
		skill.CooldownDuration = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_CooldownId then
		skill.CooldownId = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_MinRange then
		skill.MinRange = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_MaxRange then
		skill.MaxRange = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_IndicatorRangeParam1 then
		skill.IndicatorRangeParam1 = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_IndicatorRangeParam2 then
		skill.IndicatorRangeParam2 = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_IndicatorRangeParam3 then
		skill.IndicatorRangeParam3 = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_EnergyValue then
		skill.EnergyValue = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_FightPower then
		skill.SkillFightPower = tostring(skillValue)
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_EnergyPercent then
		skill.EnergyPercent = skillValue
	elseif skillEnum == ENUM_SKILLPROPERTY.SKILL_CanCastInControl then
		if skillValue > 0 then 
			skill.CanCastInControl = true
		else
			skill.CanCastInControl = false
		end	
	else
		warn("ChangeSkillProperty -- Unprocessed Enum:", skillEnum, skillValue)
	end
	return skill
end

--更改技能Perform数据
local function ChangeSkillPerformData(perform, performEnum, performValue)
	if performEnum == ENUM_SKILLPROPERTY.PERFORM_Duration then
		perform.Duration = performValue
	else
		warn("ChangeSkillPerformData--Error:", performEnum, performValue)
	end
	return perform
end

-- 注释掉的条目为服务器关心数据，客户端无需处理
local SkillPropertyKeys = 
{
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_TRIGGER_TIMELINE_StartTime] = {"Trigger", "Timeline", "StartTime"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_TRIGGER_LOOP_StartTime] = {"Trigger", "Loop", "StartTime"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_TRIGGER_LOOP_Interval] = {"Trigger", "Loop", "Interval"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_TRIGGER_LOOP_Count] = {"Trigger", "Loop", "Count"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_GENERATEACTOR_GenerateCount] = {"Event", "GenerateActor", "GenerateCount"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_GENERATEACTOR_GenerateAngle] = {"Event", "GenerateActor", "GenerateAngle"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_GENERATEACTOR_ActorId] = {"Event", "GenerateActor", "ActorId"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ANIMATION_FrameStartTime] = {"Event", "Animation", "FrameStartTime"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ANIMATION_PlaySpeed] = {"Event", "Animation", "PlaySpeed"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_RangeParam1] = {"Event", "Judgement", "RangeParam1"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_RangeParam2] = {"Event", "Judgement", "RangeParam2"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_RangeParam3] = {"Event", "Judgement", "RangeParam3"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_HitGfxActorId] = {"Event", "Judgement", "HitGfxActorId"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_BluntTime] = {"Event", "Judgement", "BluntTime"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SKIP_ConditionParam] = {"Event", "Skip", "ConditionParam"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SKIP_DestPerformId] = {"Event", "Skip", "DestPerformId"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SKILLMOVE_Speed] = {"Event", "SkillMove", "Speed"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SKILLMOVE_Duration] = {"Event", "SkillMove", "Duration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SKILLMOVE_Distance] = {"Event", "SkillMove", "Distance"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERASHAKE_Magnitude] = {"Event", "CameraShake", "Magnitude"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERASHAKE_Roughness] = {"Event", "CameraShake", "Roughness"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERASHAKE_FadeinDuration] = {"Event", "CameraShake", "FadeinDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERASHAKE_KeepMaxDuration] = {"Event", "CameraShake", "KeepMaxDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERASHAKE_FadeoutDuration] = {"Event", "CameraShake", "FadeoutDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_MOTIONBLUR_Level] = {"Event", "MotionBlur", "Level"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_MOTIONBLUR_FadeinDuration] = {"Event", "MotionBlur", "FadeinDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_MOTIONBLUR_KeepMaxDuration] = {"Event", "MotionBlur", "KeepMaxDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_MOTIONBLUR_FadeoutDuration] = {"Event", "MotionBlur", "FadeoutDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_MOTIONBLUR_IgnoreRange] = {"Event", "MotionBlur", "IgnoreRange"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERATRANSFORM_Distance] = {"Event", "CameraTransform", "Distance"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERATRANSFORM_ChangeDuration] = {"Event", "CameraTransform", "ChangeDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERATRANSFORM_ChangeBackDuration] = {"Event", "CameraTransform", "ChangeBackDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CAMERATRANSFORM_KeepDuration] = {"Event", "CameraTransform", "KeepDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_AFTERIMAGE_Duration] = {"Event", "AfterImage", "Duration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_AFTERIMAGE_GenerateInterval] = {"Event", "AfterImage", "GenerateInterval"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_AFTERIMAGE_Lifetime] = {"Event", "AfterImage", "Lifetime"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_ColorR] = {"Event", "ScreenEffect", "ColorR"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_ColorG] = {"Event", "ScreenEffect", "ColorG"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_ColorB] = {"Event", "ScreenEffect", "ColorB"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_ColorA] = {"Event", "ScreenEffect", "ColorA"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_FadeinDuration] = {"Event", "ScreenEffect", "FadeinDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_KeepDuration] = {"Event", "ScreenEffect", "KeepDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_SCREENEFFECT_FadeoutDuration] = {"Event", "ScreenEffect", "FadeoutDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CLOAK_FadeinDuration] = {"Event", "Cloak", "FadeinDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CLOAK_KeepDuration] = {"Event", "Cloak", "KeepDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_CLOAK_FadeoutDuration] = {"Event", "Cloak", "FadeoutDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ADDATTACHED_Id] = {"Event", "AddAttachedProperty", "Id"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ADDATTACHED_Value] = {"Event", "AddAttachedProperty", "Value"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ADDATTACHED_Duration] = {"Event", "AddAttachedProperty", "Duration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ADDFIGHTSPECIALITY_Duration] = {"Event", "AddFightSpeciality", "Duration"},
}

local ServerCarePropertyMap =
{
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_TargetCountLimit] = 1, --{"Event", "Judgement", "TargetCountLimit"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_StartPositionParam] = 1, --{"Event", "Judgement", "StartPositionParam"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_HitParam1] = 1, --{"Event", "Judgement", "HitParam1"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_HitParam2] = 1, --{"Event", "Judgement", "HitParam2"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_HitParam3] = 1, --{"Event", "Judgement", "HitParam3"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_AbsoluteDamage] = 1, --{"Event", "Judgement", "AbsoluteDamage"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_PercentDamage] = 1, --{"Event", "Judgement", "TargetCountLimit"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_StaminaDamage] = 1, --{"Event", "Judgement", "StaminaDamage"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_FuryIncrease] = 1, --{"Event", "Judgement", "FuryIncrease"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_JUDGEMENT_PhysicalJudgementDuration] = 1, --{"Event", "Judgement", "PhysicalJudgementDuration"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_DISPEL_StateId] = 1, --{"Event", "Dispel", "StateId"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ACCUMULATIVEFIGHTPROPERTYCHANGE_Offset] = 1, --{"Event", "AccumulativeFightPropertyChange", "Offset"},
	[ENUM_SKILLPROPERTY.EXECUTIONUNITE_EVENT_ADDSTATE_StateId] = 1, --{"Event", "AddState", "StateId"},
}
--更改技能Perform的ExecutionUnits的数据
local function ChangeSkillExecutionUnit(executionUnit, executionUnitEnum, executionUnitValue)
	local keys = SkillPropertyKeys[executionUnitEnum]
	if keys ~= nil then
		executionUnit[keys[1]][keys[2]][keys[3]] = executionUnitValue
	elseif ServerCarePropertyMap[executionUnitEnum] == nil then
		warn("ChangeSkillExecutionUnit--Error:", executionUnitEnum, executionUnitValue)
	end
	return executionUnit
end

--更改技能
local function makeUniqueSkillData(skillInfoData, role)
	local skill = CElementSkill.GetClone(skillInfoData.SkillId)
	local originSkill = skill

	local entity = role or game._HostPlayer

	for i,v in ipairs(entity._UserSkillMap) do
		if skillInfoData.SkillId == v.SkillId then
			skill = v.Skill
		end
	end
	--更改技能变化
	for j,w in ipairs(skillInfoData.ChangedDatas) do
		skill = ChangeSkillProperty(skill, w.propertyEnum, w.propertyValue)
	end
	--更改技能的Perform变化
	for j,w in ipairs(skillInfoData.Performs) do
		local indexP = GetSkillPerformIndex(skill.Performs, w.PerformId)
		if indexP == -1 then
			warn("Failed to GetSkillPerformIndex ", skillInfoData.SkillId, w.PerformId)
		else
			--warn("Performs--", w.PerformId)	
			for k,x in ipairs(w.ChangedDatas) do
				skill.Performs[indexP] = ChangeSkillPerformData(skill.Performs[indexP], x.propertyEnum, x.propertyValue)
			end
			--更改技能的Perform的ExecutionUnit的变化
			for k,x in ipairs(w.ExecutionUnitDatas) do
				local indexE = GetSkillPerformExecutionUnitIndex(skill.Performs[indexP].ExecutionUnits, x.ExecutionUnitId)
				if indexE ~= -1 then
					for l,y in ipairs(x.ChangedDatas) do
						skill.Performs[indexP].ExecutionUnits[indexE] = ChangeSkillExecutionUnit(skill.Performs[indexP].ExecutionUnits[indexE], y.propertyEnum, y.propertyValue)
					end
				end
			end

			if #w.ExecutionIds ~= 0 then
				--添加服务器新加的
				for i,remoteExecUnitId in ipairs(w.ExecutionIds) do
					local isHas = false;
					for _,localExecUnit in ipairs(skill.Performs[indexP].ExecutionUnits) do
						if localExecUnit.Id == remoteExecUnitId then
							isHas = true
						end
					end
					if not isHas then
						local exeUnit = nil
						if remoteExecUnitId > 10000 then
							exeUnit = CElementData.GetExecutionUnitTemplate(remoteExecUnitId)
						else
							for iE,vE in ipairs(originSkill.Performs[indexP].ExecutionUnits) do
								if vE.Id == remoteExecUnitId then
									exeUnit = originSkill.Performs[indexP].ExecutionUnits[iE]
								end
							end
						end
						if exeUnit ~= nil then
							table.insert(skill.Performs[indexP].ExecutionUnits, exeUnit)
						end			
					end
				end
				--删除本地多余的
				local delTablses = {}
				for i,localUnit in ipairs(skill.Performs[indexP].ExecutionUnits) do
					local isHas = false
					for _, remoteExecUnitId in ipairs(w.ExecutionIds) do
						if localUnit.Id == remoteExecUnitId then
							--warn("localUnit.Id", localUnit.Id, "remoteExecUnitId", remoteExecUnitId, isHas)
							isHas = true
							break
						end
					end
					if isHas then
						table.insert(delTablses, false)
					else
						table.insert(delTablses, true)
					end
				end

				for i = #delTablses, 1, -1 do
		    		if delTablses[i] then
		        		table.remove(skill.Performs[indexP].ExecutionUnits, i)
		    		end
				end
			end
		end
	end
	return skill
end

local SkillFuncId = 7
local RuneFuncId = 9
local MasteryFuncId = 64
local SoulFuncId = 2

local function isRuneCanLvUp()
	local game = game
	local hp = game._HostPlayer

	-- rune 纹章检查
	do
		if game._CFunctionMan:IsUnlockByFunTid(RuneFuncId) then

			local function HasValidRuneItem(runeID, runeLevel)
				local rune_data = CElementSkill.GetRune(runeID)
				local item_ids = string.split(rune_data.RuneUpdItems, "*")
				-- 升级所需物品ID
				local upd_itemid = item_ids[runeLevel]
				if not upd_itemid then
					return false
				end
				upd_itemid = tonumber(upd_itemid)
				-- 背包中现有数量
				local pack = game._HostPlayer._Package._NormalPack
				local bag_num = pack:GetItemCount(upd_itemid)
				-- 升级所需数量
				local upd_counts = string.split(rune_data.RuneUpdItemCount, "*")
				local upd_itemNeed = upd_counts[runeLevel]
				upd_itemNeed = tonumber(upd_itemNeed)
				return bag_num >= upd_itemNeed
			end

			local SkillInfo = {}
			local userSkillMap = game._HostPlayer._UserSkillMap
			for k, v in pairs(userSkillMap) do
				SkillInfo[v.SkillId] = v
			end
			
			local allRune = CElementData.GetAllTid("Rune")
			local DefaultRuneInfo = {}
			for i, v in ipairs(allRune) do
				local rune = CElementSkill.GetRune(v)
				DefaultRuneInfo[rune.SkillId .. rune.UiPos] = v
			end
			
			local hp = game._HostPlayer
			local skillPoseToInfo = hp._MainSkillIDList
			for k, v in pairs(skillPoseToInfo) do
				local skillInfo = SkillInfo[v]
				local runeInfo = {}
				if skillInfo then
					local isRuneWork = false
					local hasRune = false
					local SkillRuneInfoDatas = skillInfo.SkillRuneInfoDatas
					for m, n in ipairs(SkillRuneInfoDatas) do
						local rune = CElementSkill.GetRune(n.runeId)
						runeInfo[rune.UiPos] = n
						if HasValidRuneItem(n.runeId, n.level + 1) then
							return true
						end
						-- 在纹章槽有空，并且有可以镶嵌的纹章时，增加红点提示
						if rune.UiPos >= 1 and rune.UiPos <= 3 then
							hasRune = true
							if n.isActivity then
								isRuneWork = true
							end
						end
							
					end
					if hasRune and not isRuneWork then
						return true
					end
				end
				for i = 1, 3 do
					if not runeInfo[i] then
						if HasValidRuneItem(DefaultRuneInfo[v .. i], 1) then
							return true
						end
					end
				end

			end


		end
	end
	return false
end

local function isSkillCanLvUp()
	local game = game
	local hp = game._HostPlayer
	local mainSkills = hp._MainSkillIDList
	local hpLv = hp._InfoData._Level
	local hasGoldCnt = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold
	do 
		if game._CFunctionMan:IsUnlockByFunTid(SkillFuncId) then
			local learnedStates = hp._MainSkillLearnState
			for i,v in ipairs(mainSkills) do
				if learnedStates[v] ~= nil and learnedStates[v] then -- 已经学会
					local skillData = hp:GetSkillData(v)
					local lvUpConditions = hp:GetSkillLevelUpConditionMap(v)
					for i1,v1 in ipairs(lvUpConditions) do
						if (skillData.SkillLevel - skillData.TalentAdditionLevel)  == v1.SkillLevel and hpLv >= v1.RoleLevel and hasGoldCnt >= v1.NeedMoneyNum then
							return true					
						end			
					end
				end
			end
		end
	end
	return false
end

local function isMasteryCanLvUp( )
	local game = game
	local hp = game._HostPlayer
	local hpLv = hp._InfoData._Level
	local hasGoldCnt = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold	
	local normalPack = hp._Package._NormalPack

	if game._CFunctionMan:IsUnlockByFunTid(MasteryFuncId) then	
		local masteryInfos, _ = hp:GetSkillMasteryInfo()
		if masteryInfos ~= nil then
			for i = 1, #masteryInfos do
				local tmp = CElementData.GetSkillMasteryTemplate(masteryInfos[i].NextTid)
				if tmp ~= nil then
					local itemCount = normalPack:GetItemCount(tmp.CostItemId)	
					if itemCount >= tmp.CostItemCount and hpLv >= tmp.Level and hpLv >= masteryInfos[i].UnLockLevel and hasGoldCnt >= tmp.CostMoneyCount then
						return true
					end
				end
			end
		end
	end
	return false
end

local function getMasteryLevel()
	local game = game
	local hp = game._HostPlayer
	local hpLv = hp._InfoData._Level
	local hasGoldCnt = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold	
	local normalPack = hp._Package._NormalPack

	local levelCount = 0
	local masteryInfos, _ = hp:GetSkillMasteryInfo()
	if masteryInfos ~= nil then
		for i = 1, #masteryInfos do
			local tmp = CElementData.GetSkillMasteryTemplate(masteryInfos[i].Tid)
			if tmp ~= nil then
				levelCount = levelCount + tmp.Level
			end
		end
	end
	return levelCount
end

local function isSoulCanLvUp()
	if game._CFunctionMan:IsUnlockByFunTid(SoulFuncId) then	
		local CWingsMan = require "Wings.CWingsMan"
		if CWingsMan.Instance():IsTalentHasRedPoint() then
			return true
		end
	end
	return false
end

local function isSkillRuneMasteryCanLvUp()
	local game = game
	local hp = game._HostPlayer

	--[[
	local mainSkills = hp._MainSkillIDList
	local hpLv = hp._InfoData._Level
	local hasGoldCnt = game._AccountInfo._RoleList[game._AccountInfo._CurrentSelectRoleIndex].Gold	
	local normalPack = hp._Package._NormalPack
	]]
	
	-- skill 升级检查
	if isSkillCanLvUp() then
		return true
	end

	if isRuneCanLvUp() then
		return true
	end

	-- 技能专精检查
	if isMasteryCanLvUp() then
		return true
	end

	if isSoulCanLvUp() then
		return true
	end

	return false
end


local SkillFailedCodeList = 
{
	[0]  =  "OK",                 
	[1]  =  "Error",              
	[2]  =  "InCooldown",         
	[3]  =  "LackOfFury",         
	[4]  =  "LackOfMana",         
	[5]  =  "LackOfCombo",        
	[6]  =  "LackOfArrow",        
	[7]  =  "LackOfTarget",       
	[8]  =  "InvalidDistance",    
	[9]  =  "InvalidDirection",   
	[10] =  "InvalidPosition" ,   
	[11] =  "FarawayPosition",    
	[12] =  "NeedTurn",           
	[13] =  "NotMeetPreconditon", 
	[14] =  "InSkill",            
	[15] =  "Obstacle",           
	[16] =  "WrongId",            
	[17] =  "OtherSkillIsGoingOn",
	[18] =  "SkillMapIsNull",     
	[19] =  "NotHaveSkill",       
	[20] =  "InvalidSkill",       
	[21] =  "TemplateIsNull",     
	[22] =  "CUnitStateIsNull",   
	[23]  =  "InvalidRegionRule",  
	[24] =  "NotCanSkill",        
	[25] =  "Controlled",         
	[26] =  "NotCanNormalSkill",  
	[27] =  "TranformCategory",   
	[28] =  "InvalidSkillData",   
	[29] =  "NotImpl",            
	[30] =  "InterruptFail",      
	[31] =  "CheckFail",          
	[32] =  "ForceStop",
}

local function GetSkillFailedCodeEx(error_code)
	if SkillFailedCodeList[error_code] then
		return SkillFailedCodeList[error_code]
	end
	return ""
end

def.const("function").MakeUniqueSkillData 						= makeUniqueSkillData
def.const("function").IsSkillRuneMasteryCanLvUp 				= isSkillRuneMasteryCanLvUp
def.const("function").GetSkillFailedCodeEx 						= GetSkillFailedCodeEx
def.const("function").IsRuneCanLvUp 							= isRuneCanLvUp
def.const("function").IsSkillCanLvUp 							= isSkillCanLvUp
def.const("function").IsMasteryCanLvUp 							= isMasteryCanLvUp
def.const("function").IsSoulCanLvUp 							= isSoulCanLvUp
def.const("function").GetMasteryLevel 							= getMasteryLevel	

CSkillUtil.Commit()
return CSkillUtil