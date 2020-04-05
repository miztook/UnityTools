
local PBHelper = require "Network.PBHelper"
local Lplus = require "Lplus"
local CGame = Lplus.ForwardDeclare("CGame")
local CElementData = require "Data.CElementData"
local CElementSkill = require "Data.CElementSkill"
local CPlayer = require "Object.CPlayer"
local Util = require "Utility.Util"
local EntityStatis = require "Profiler.CEntityStatistics"
--
-- S2CEnterGame
--
local function OnEnterGame( sender,msg )
	warn("EnterGame")

    local CQuest = require "Quest.CQuest"
	CQuest.Instance():Init()
end
PBHelper.AddHandler("S2CEnterGame", OnEnterGame)

--
-- S2CEnterGame
--
local function OnLeaveGame( sender,msg )
	warn("LeaveGame")
end
PBHelper.AddHandler("S2CLeaveGame", OnLeaveGame)

--
-- S2CEnterWorld
--

local function OnHostEnterMap( sender,msg )
	--warn("OnHostEnterMap")
	local pos = Vector3.New(msg.Position.x, 0, msg.Position.z)
	local dir = Vector3.New(msg.Orientation.x, 0, msg.Orientation.z)
	game:EnterGameWorld(msg.MapTemplateId, msg.MapInstanceId, pos, dir, msg.CgAssetId)

	local event = require("Events.EntityEnterEvent")()
	event._MapInstanceId = msg.MapInstanceId
	CGame.EventManager:raiseEvent(nil, event)
end

PBHelper.AddHandler("S2CEnterMap", OnHostEnterMap)

--
-- S2CLeaveWorld
--
local function OnHostLeaveMap( sender,msg )
	local CAutoFight = require "ObjHdl.CAutoFight"
	CAutoFight.Instance():Stop()
	game:ClearGameEntityInCurWord()
end

PBHelper.AddHandler("S2CLeaveMap", OnHostLeaveMap)


local function SetEntitySkills(entityid, skillInfoDatas)
	local object = game._CurWorld:FindObject(entityid)
	if object == nil then return "SetEntitySkills, object == nil" end

	local skills = {}
	for i,vv in ipairs(skillInfoDatas) do				
		skills[#skills + 1] = { SkillId = vv.SkillId, SkillLevel = vv.SkillLevel, Skill = CPlayer.DoSkillChange(vv) }
	end
	object._SkillHdl._Host._UserSkillMap = skills		
end

--
-- S2CRoleEnterSight
--
local function OnRoleEnterSight(sender, msg)
	local id = msg.RoleInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
	EntityStatis.Register("Player", id)
	local player_man = game._CurWorld._PlayerMan
	player_man:CreateElsePlayer(msg.RoleInfo)

	--SetEntitySkills(msg.RoleInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId, msg.RoleInfo.skillInfoRe.SkillInfoDatas)	
end

PBHelper.AddHandler("S2CRoleEnterSight", OnRoleEnterSight)

--
-- S2CMonsterEnterSight
--
local function OnMonsterEnterSight(sender, msg)
	local id = msg.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
	EntityStatis.Register("Monster", id)

	local tid = msg.MonsterInfo.MonsterTid
	if tid == 22200 then
		warn("TERA-3588: 怪物22200进入地图的消息收到了")
	end

	local monsterTemplate = CElementData.GetMonsterTemplate(msg.MonsterInfo.MonsterTid)
	if monsterTemplate == nil then
		warn("OnMonsterEnterSight monsterTemplate = nil", msg.MonsterInfo.MonsterTid)
		return
	end

	local createType = Util.CalcSightUpdateType(msg.SightUpdateData.type, msg.SightUpdateData.reason)
	local npc_man = game._CurWorld._NPCMan
	npc_man:CreateMonster(msg.MonsterInfo, createType)
end

PBHelper.AddHandler("S2CMonsterEnterSight",OnMonsterEnterSight)

--
-- S2CNpcEnterSight
--
local function OnNpcEnterSight(sender, msg)
	local id = msg.NpcInfo.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
	EntityStatis.Register("NPC", id)
	
	local createType = Util.CalcSightUpdateType(msg.SightUpdateData.type, msg.SightUpdateData.reason)
	local npc_man = game._CurWorld._NPCMan
	npc_man:CreateNpc(msg.NpcInfo, createType)
end

PBHelper.AddHandler("S2CNpcEnterSight", OnNpcEnterSight)

--
-- S2CPlayerMirrorEnterSight
--
local function OnPlayerMirrorEnterSight(sender, msg)
	warn("OnPlayerMirrorEnterSight")
	local npc_man = game._CurWorld._NPCMan
	npc_man:CreatePlayerMirror(msg.PlayerMirrorInfo)
end

PBHelper.AddHandler("S2CPlayerMirrorEnterSight", OnPlayerMirrorEnterSight)

--
-- S2CSubobjectEnterSight
--
local function OnSubobjectEnterSight(sender, msg)
	local man = game._CurWorld._SubobjectMan
	man:CreateSubobject(msg.SubobjectInfo)
end

PBHelper.AddHandler("S2CSubobjectEnterSight", OnSubobjectEnterSight)

--
-- S2CObstacleEnterSight
--
local function OnObstacleEnterSight(sender, msg)
	local man = game._CurWorld._DynObjectMan
	man:CreateDynObject(msg.ObstacleInfo)
end

PBHelper.AddHandler("S2CObstacleEnterSight", OnObstacleEnterSight)

--
-- S2CLootEnterSight
--
local function OnLootEnterSight(sender, msg)
	local man = game._CurWorld._LootObjectMan
	man:CreateLootObject(msg.LootInfo)
end

PBHelper.AddHandler("S2CLootEnterSight", OnLootEnterSight)

--
-- S2CMineEnterSight
--
local function OnMineEnterSight(sender, msg)
	--warn("OnMineEnterSight ...")
	local man = game._CurWorld._MineObjectMan
	man:CreateMineObject(msg.MineInfo)	
end

PBHelper.AddHandler("S2CMineEnterSight", OnMineEnterSight)

--
-- S2CPetEnterSight
--
local function OnS2CPetEnterSight(sender, msg)
	--warn("OnS2CPetEnterSight ...")
	local man = game._CurWorld._PetMan
	man:CreatePetObject(msg.PetInfo)
end

PBHelper.AddHandler("S2CPetEnterSight", OnS2CPetEnterSight)


--
-- S2CEntityInfoList
--

local function create_all_entity(sender, msg)
	--repeated RoleInfo RoleInfoList				= 2;
	if msg.RoleInfoList ~= nil and #msg.RoleInfoList > 0 then
		local player_man = game._CurWorld._PlayerMan
		for i,v in ipairs(msg.RoleInfoList) do
			local id = v.CreatureInfo.MovableInfo.EntityInfo.EntityId
			--EntityStatis.Register("Player", id)
			player_man:CreateElsePlayer(v)
			--warn("create_all_entity--", table.getn(game._CurWorld._PlayerMan))
			--SetEntitySkills(v.CreatureInfo.MovableInfo.EntityInfo.EntityId, v.skillInfoRe.SkillInfoDatas)
		end
	end
	--repeated MonsterInfo MonsterInfoList		= 3;
	local enterType = EnumDef.SightUpdateType.Unknown
	if msg.MonsterInfoList ~= nil and #msg.MonsterInfoList > 0 then
		local npc_man = game._CurWorld._NPCMan
		for i,v in ipairs(msg.MonsterInfoList) do
			local id = v.CreatureInfo.MovableInfo.EntityInfo.EntityId
			--EntityStatis.Register("Monster", id)
			npc_man:CreateMonster(v, enterType)

			-- for jira 3588
			local tid = v.MonsterTid
			if tid == 22200 then
				warn("TERA-3588: 怪物22200进入地图的消息收到了")
			end
		end
	end
	--repeated NpcInfo NpcInfoList				= 4;
	local npc_man = game._CurWorld._NPCMan
	if msg.NpcInfoList ~= nil and #msg.NpcInfoList > 0 then
		for i,v in ipairs(msg.NpcInfoList) do
			local id = v.MonsterInfo.CreatureInfo.MovableInfo.EntityInfo.EntityId
			--EntityStatis.Register("NPC", id)
			npc_man:CreateNpc(v, enterType)
		end
	end


	--repeated ObstacleInfo ObstacleInfoList		= 6;
	if msg.ObstacleInfoList ~= nil and #msg.ObstacleInfoList > 0 then
		local man = game._CurWorld._DynObjectMan
		for i,v in ipairs(msg.ObstacleInfoList) do
			man:CreateDynObject(v)
		end
	end

	--repeated LootInfo LootInfoList = 7;
	if msg.LootInfoList ~= nil and #msg.LootInfoList > 0 then
		local man = game._CurWorld._LootObjectMan
		for i,v in ipairs(msg.LootInfoList) do
			man:CreateLootObject(v)
		end
	end

	--	repeated MineInfo MineInfoList	= 8;
	if msg.MineInfoList ~= nil and #msg.MineInfoList > 0 then
		local man = game._CurWorld._MineObjectMan
		for i, v in ipairs( msg.MineInfoList ) do
			man:CreateMineObject(v)
		end
	end

	--	repeated PetInfo  PetInfoList = 9;
	if msg.PetInfoList ~= nil and #msg.PetInfoList > 0 then
		local man = game._CurWorld._PetMan
		for i, v in ipairs( msg.PetInfoList ) do
			man:CreatePetObject(v)
		end
	end

	if msg.PlayerMirrorInfoList ~= nil and #msg.PlayerMirrorInfoList > 0 then
		for i,v in ipairs(msg.PlayerMirrorInfoList) do
			npc_man:CreatePlayerMirror(v)
		end
	end


	--repeated SubobjectInfo SubobjectInfoList	= 5;
	if msg.SubobjectInfoList ~= nil and #msg.SubobjectInfoList > 0 then
		local man = game._CurWorld._SubobjectMan
		for i,v in ipairs(msg.SubobjectInfoList) do	
			man:CreateSubobject_Later(v)
		end
	end		
end

local function OnEntityInfoList( sender,msg )
	--TODO("OnEntityInfoList ...")

	create_all_entity(sender, msg)

	--[[if game._CurWorld ~= nil then
		game._CurWorld:AddLoadedCallback(create_all_entity)
	else
		warn("Game World is null, can not create entity in this world")
	end]]
end

PBHelper.AddHandler("S2CEntityInfoList",OnEntityInfoList)


local function OnS2CEnterRegion(sender, protocol)
	--warn("OnS2CEnterRegion", protocol.RegionId)
	game._HostPlayer:EnterRegion(protocol.RegionId)
end
PBHelper.AddHandler("S2CEnterRegion", OnS2CEnterRegion)


local function OnS2CLeaveRegion(sender, protocol)
	--warn("OnS2CLeaveRegion", protocol.RegionId)
	game._HostPlayer:LeaveRegion(protocol.RegionId)
end
PBHelper.AddHandler("S2CLeaveRegion", OnS2CLeaveRegion)