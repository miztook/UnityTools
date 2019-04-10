local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CEntity = require "Object.CEntity"
local CElementSkill = require "Data.CElementSkill"
local CElementData = require "Data.CElementData"
local SKILL_CATEGORY = require "Skill.SkillDef".SKILL_CATEGORY
local SkillCategory = require "PB.Template".Skill.SkillCategory

local CBattleServer = Lplus.Class("CBattleServer")
local def = CBattleServer.define

-- 战斗判定[伤害 死亡等]

local instance
def.static("=>",CBattleServer).Instance = function()
	if not instance then
		instance = CBattleServer()
	end
	return instance
end

local ConstData = nil

-- TODO: 废弃
--[[
def.method(CEntity, CEntity, "table", "=>", "number").CalculateStamina = function(self, attacker, target, skill)
	return calc_stamina_damage(attacker, target, skill)
end
]]

--[[--

判定区域内受伤目标筛选
@param caster_id - 技能释放者id
@param shapetype - 判定区域类型 0：rect  1：sector  2：circle
@param params[1] - type = 1时 为宽，其余时候为半径
@param params[2] - type = 1时 有效，为宽
@param params[3] - type = 2时 有效，为扇形半角
@param pos - 判定区域中心位置
@param dir - 判定区域朝向

@return 筛选后的对象列表

Template.ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementRangeType.Rectangle = 0
Template.ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementRangeType.Sector    = 1
Template.ExecutionUnit.ExecutionUnitEvent.EventJudgement.JudgementRangeType.Circle    = 2
]]
def.method("number", "table", "number", "number", "number", "number", "number", "number", "=>", "table").FilterVictim = function(self, caster_id, params, posX, posY, posZ, dirX, dirY, dirZ)
	local shapetype = params.RangeType
	if shapetype < 0 or shapetype > 2 then return {} end

	local caster = game._CurWorld:FindObject(caster_id) 
	if caster == nil then return {} end

	local victims = {}
	local rangeParams = {params.RangeParam1, params.RangeParam2, params.RangeParam3}
	local shape
	if shapetype == 1 then
		shape = SkillCollision.CreateShapeXYZ(shapetype, rangeParams[1], rangeParams[2], rangeParams[3]/2, posX, posY, posZ, dirX, dirY, dirZ)
	else
		shape = SkillCollision.CreateShapeXYZ(shapetype, rangeParams[1], rangeParams[2], rangeParams[3], posX, posY, posZ, dirX, dirY, dirZ)	
	end

	if params.TargetTypeSelf then
		local hp = game._HostPlayer
		local hostX, hostY, hostZ = hp:GetPosXYZ()
		local radius = hp:GetRadius()

		if shape:IsCollidedXYZ( hostX, hostY, hostZ, hp:GetRadius()) then
		--if SkillCollision.IsShapeCollidedXYZ(shapetype, rangeParams[1], rangeParams[2], angle, posX, posY, posZ, dirX, dirY, dirZ, hostX, hostY, hostZ, radius) then
			victims[1] = hp
		end
	end

	--npc目标
	if params.TargetTypeEnemyNoneRole then	
		local NPCs = game._CurWorld._NPCMan._EnemyNpcList
		for _,v in pairs(NPCs) do
			local vPosX, vPosY, vPosZ = v:GetPosXYZ()
			local radius = v:GetRadius()

			if shape:IsCollidedXYZ(vPosX, vPosY, vPosZ, radius) then
				victims[#victims+1] = v
			end
		end
	end

	if params.TargetTypeFriendNoneRole then
		local NPCs = game._CurWorld._NPCMan._FriendNpcList
		for _,v in pairs(NPCs) do
			local vPosX, vPosY, vPosZ = v:GetPosXYZ()
			local radius = v:GetRadius()

			if shape:IsCollidedXYZ(vPosX, vPosY, vPosZ, radius) then
				victims[#victims+1] = v
			end
		end
	end


	--player目标
	if params.TargetTypeEnemyRole then
		local Players = game._CurWorld._PlayerMan._EnemyPlayerList
		for _,v in pairs(Players) do
			if not v:IsDead() then
				local vPosX, vPosY, vPosZ = v:GetPosXYZ()
				local radius = v:GetRadius()

				if shape:IsCollidedXYZ(vPosX, vPosY, vPosZ, radius) then
					victims[#victims+1] = v
				end
			end
		end
	end

	if params.TargetTypeFriendRole or params.TargetTypeTeamMember then
		local Players = game._CurWorld._PlayerMan._FriendPlayerList
		for _,v in pairs(Players) do
			if not v:IsDead() then
				local vPosX, vPosY, vPosZ = v:GetPosXYZ()
				local radius = v:GetRadius()

				if shape:IsCollidedXYZ(vPosX, vPosY, vPosZ, radius) then
					victims[#victims+1] = v
				end
			end
		end
	end

	return victims
end

CBattleServer.Commit()

return CBattleServer
