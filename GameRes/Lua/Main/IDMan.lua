

--[[===============================================================
-- ID 分配原则
-- 使用32位无符号整形
-- 前四位用于区分对象类型
-- 后面27位用于实际ID，0为非法ID，用于校验（支持1亿量级对象数量）
-- 对于玩家27位中前8位表示服务器ID(支持256组，百万量级角色)
=====================================================================]]

local ID_MASK = 0xF8000000

local ROLE_ID_MASK = 0x00000000
local MONSTER_ID_MASK = 	0x08000000
local NPC_ID_MASK =     	0x10000000
local SUBOBJECT_ID_MASK = 	0x18000000
local OBSTACLE_ID_MASK = 	0x20000000
local LOOT_ID_MASK = 		0x28000000
local MINE_ID_MASK = 		0x30000000
local PET_ID_MASK = 		0x38000000
local PLAYER_MIRROR_ID_MASK = 0x40000000

local role_unique_id = 0
local monster_unique_id = 0
local npc_unique_id = 0
local subobject_unique_id = 0

local bit = require "bit"

local ISROLEID = function(id)
	return (bit.band(id, ID_MASK) == ROLE_ID_MASK)
end

local ISMONSTERID = function(id)
	return (bit.band(id, ID_MASK) == MONSTER_ID_MASK) or (bit.band(id, ID_MASK) == PLAYER_MIRROR_ID_MASK)
end

local ISNPCID = function(id)
	return (bit.band(id, ID_MASK) == NPC_ID_MASK)
end

local ISSUBOBJECTID = function(id)
	return (bit.band(id, ID_MASK) == SUBOBJECT_ID_MASK)
end

local ISOBSTACLETID = function(id)
	return (bit.band(id, ID_MASK) == OBSTACLE_ID_MASK)
end

local ISLOOTID = function (id)
	return (bit.band(id, ID_MASK) == LOOT_ID_MASK)
end

local ISMINEID = function(id)
	return (bit.band(id, ID_MASK) == MINE_ID_MASK)
end

local ISPETID = function(id)
	return (bit.band(id, ID_MASK) == PET_ID_MASK)
end

local GetEntityType = function (id)
	local v = bit.band(id, ID_MASK)
	if v == ROLE_ID_MASK then 
		return 1
	elseif v == MONSTER_ID_MASK or v == PLAYER_MIRROR_ID_MASK then
		return 2
	elseif v == NPC_ID_MASK then
		return 3
	elseif v == SUBOBJECT_ID_MASK then
		return 4
	elseif v == OBSTACLE_ID_MASK then
		return 5
	elseif v == LOOT_ID_MASK then
		return 6
	elseif v == MINE_ID_MASK then
		return 7
	elseif v == PET_ID_MASK then
		return 8
	else 
		return 0
	end
end

--TODO NewNPCID NewSubobjectID 是临时的
local NewNPCID = function()
	npc_unique_id = npc_unique_id + 1
	return bit.bor(npc_unique_id, NPC_ID_MASK) 
end

local NewSubobjectID = function()
	subobject_unique_id = subobject_unique_id + 1
	return bit.bor(subobject_unique_id, SUBOBJECT_ID_MASK) 
end

local CalcSubobjectFakeID = function(skillId, actorTid, index)
	return skillId * 1000000 + actorTid * 1000 + index
end

return 
	{
		ISROLEID = ISROLEID,
		ISMONSTERID = ISMONSTERID,
		ISNPCID = ISNPCID,
		ISSUBOBJECTID = ISSUBOBJECTID,
		ISOBSTACLETID = ISOBSTACLETID,
		ISLOOTID = ISLOOTID,
		ISMINEID = ISMINEID,
		ISPETID = ISPETID,
		
		NewNPCID = NewNPCID,
		NewSubobjectID = NewSubobjectID,

		CalcSubobjectFakeID = CalcSubobjectFakeID,
		GetEntityType = GetEntityType,
	}